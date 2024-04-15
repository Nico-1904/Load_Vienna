classdef QuadrigaContainer < tools.HiddenHandle
    %QuadrigaContainer handles the generation of the channel matrix using the Quadriga Channel Model
    %
    % initial author: Armand Nabavi

    properties
        %Quadriga layout
        %[1x1] qd_layout
        layout

        %channel matrix per user
        %[nRX x nTXelements x nTimeSamples x nFreqSamples x nUser x nBasestation] complex
        %double
        channel

        % fft sampling interval
        % [1x1] integer
        fftSamplingInterval

        % bandwidth
        % [1x1] integer
        bandwidthHz

        % center frequency
        % [1x1] integer
        centerFrequencyGHz

        % subcarrier spacing
        % [1x1] integer
        subcarrierSpacing
    end

    properties (Access = protected, Hidden)
        %% Constant parameters:

        % fixed bandwidth of resource block in Hz
        % [1x1]double size of a resource block in frequency domain in Hz
        sizeRbFreqHz
        % number of resource blocks in frequency in a slot
        % [1x1]integer number of resource blocks in a slot in frequency
        nRBFreq

        % total number of subcarriers not NULL
        % [1x1]double
        nSubcarrierSlot

        %% Dependent parameters

        % number of FFT points
        % [1x1]double
        nFFT
        % sampling frequency
        % [1x1]double
        fs
    end

    methods
        function obj = QuadrigaContainer(chunkConfig)
            %Creates object, sets Quadriga parameters and specifies layout
            %as well as network elements
            obj.createLayout(chunkConfig);
        end

        function calculateChannelMatrix(obj)
            cb = obj.layout.init_builder(1,0); %create channel builder, format nScenarios x 1
            %NOTE: the second input argument (split_tx) set to zero means
            %that only one channel builder is created for all BSs instead of
            %a separate one for each BS. According to the documentation,
            %this is required for achieving spatial consistency among the
            %BSs.
            %NOTE: nScenarios assumed to be 1 for now

            cb = cb(1); %disregard all but the first scenario in case several are accounted for by accident

            %disable everything except small scale fading
            cb.scenpar.SF_sigma =  0; %disable shadow fading
            cb.scenpar.KF_mu    =  0; %0 dB K factor
            cb.scenpar.KF_sigma =  0; %no K factor variation
            cb.plpar            = []; %disable macroscopic path loss

            %cb.scenpar.SC_lambda = 0;
            cb.gen_parameters;                                     %generate LSF and SSF parameters
            tempChannel              = cb.get_channels;            %compute channels
            %            for c_ = 1:numel(tempChannel)
            %                tempChannel(c_).individual_delays = 0;
            %            end
            tempChannelMerged        = tempChannel.merge([],0);        %merge and write to cell array
            clear tempChannel;

            %rearrange and combine channel objects so as to get one channel
            %matrix per user

            tempChannelPerUserAndBS = reshape(tempChannelMerged, [obj.layout.no_rx, obj.layout.no_tx]);
            coeffSize = size(tempChannelPerUserAndBS(1,1).coeff); %channel matrix size (for the first link)

            clear tempChannelMerged;
            %extract coefficients, process and compute frequency response

            for jj = 1:obj.layout.no_rx
                for kk = 1:obj.layout.no_tx
                    temp_coeff = tempChannelPerUserAndBS(jj,kk).coeff;
                    for ll = 1:coeffSize(1) %for all rx antennas
                        for mm = 1:coeffSize(2) %for all tx antennas
                            temp_delay = squeeze(tempChannelPerUserAndBS(jj,kk).delay(ll,mm,:,1));
                            temp_delay = round(temp_delay(:)*obj.fs);

                            channel_matrix_size = [1, 1, size(temp_coeff,3), size(temp_coeff,4)];
                            channel_matrix_size(3) = max(temp_delay)+1;

                            channel_out = zeros(channel_matrix_size);

                            for tap_i = 1:channel_matrix_size(3)
                                tap_positions = find(temp_delay == tap_i-1);
                                if sum(tap_positions)>0
                                    channel_out(:,:,tap_i,:) = sum(temp_coeff(ll,mm,tap_positions,:),3);
                                end
                            end

                            channel_out = permute(channel_out,[1 2 4 3]);

                            %insert singleton dimension for compatibility
                            size_channel_out = size(channel_out);
                            channel_out = reshape(channel_out,[size_channel_out(1),size_channel_out(2),1,size_channel_out(3),size_channel_out(4:end)]);

                            channel_out_Rb = obj.getRbTrace(channel_out);

                            obj.channel(ll,mm,:,:,jj,kk) = reshape(channel_out_Rb, [size(channel_out_Rb,1), size(channel_out_Rb,2), size(channel_out_Rb,4), size(channel_out_Rb,5)]);
                            clear channel_out
                            clear temp_delay
                        end
                    end
                end
            end

            clear tempChannelperUser;
        end

        function smallScaleFading = getChannelForAllAntennas(obj, Receiver, Transmitters, iSlot)
            % gets the channel realizations for all links for the LQM
            %
            % input:
            %   Receiver:       [1x1]handleObject receiver
            %                   see also networkElements.NetworkElementWithPosition
            %   Transmitters:	[1 x nTransmitters]handleObject all transmitters
            %                   see also networkElements.NetworkElementWithPosition
            %   iSlot:          [1x1]integer index of current slot
            %
            % output:
            %   smallScaleFading: [1 x nAnt]struct channel for link quality model
            %       -H: [nRX x nTXelements x nTimeSamples x nFreqSamples]complex channel matrix

            % get total number of transmitters
            nTransmitters = length(Transmitters);

            % initialize output
            smallScaleFading(1, nTransmitters) = struct('H', []);

            % read out channel matrix
            for iTransmitter = 1:nTransmitters
                smallScaleFading(1,iTransmitter).H =  obj.channel(:,:,iSlot,:,Receiver.id, iTransmitter);
            end % for all transmit antennas
        end
    end

    methods (Access = private)
        function l = createLayout(obj, chunkConfig)
            %check user nRX (only nRX=1 supported for now)
            if any(cat(2, chunkConfig.userList.nRX) > 1)
                error('Quadriga Interface only supports users with nRX = 1 for now.')
            end

            %extract params (shorthand)
            params = chunkConfig.params;

            obj.centerFrequencyGHz  = params.carrierDL.centerFrequencyGHz;
            obj.bandwidthHz         = params.transmissionParameters.DL.bandwidthHz;

            %get numerology used by BS
            tempBsAntennaList = cat(2, chunkConfig.baseStationList.antennaList); %list all antennas
            numerology = unique(cat(2, tempBsAntennaList.numerology)); %get unique list of numerologies

            obj.subcarrierSpacing   = params.transmissionParameters.DL.resourceGrid.subcarrierSpacingHz(numerology(1)); %assume single numerology for now
            obj.nSubcarrierSlot     = params.transmissionParameters.DL.resourceGrid.nSubcarrierSlot(numerology(1));
            obj.sizeRbFreqHz        = params.transmissionParameters.DL.resourceGrid.sizeRbFreqHz;
            obj.nRBFreq             = params.transmissionParameters.DL.resourceGrid.nRBFreq;
            obj.fftSamplingInterval = params.transmissionParameters.DL.resourceGrid.nSubcarrierRb(numerology(1)) / params.smallScaleParameters.nSampleRbFreq;

            obj.setProperties;

            %create Quadriga layout
            l = qd_layout;

            %set parameters
            l.simpar.center_frequency        = params.carrierDL.centerFrequencyGHz;
            l.simpar.show_progress_bars      = false;
            l.simpar.use_3GPP_baseline       = params.channelModelParameters.enable3gppPreset;

            %create base stations
            tx_position                                     = zeros(3, numel(chunkConfig.baseStationList));
            tx_array(1, numel(chunkConfig.baseStationList)) = qd_arrayant('omni'); %only set for preallocation purposes

            for bb = 1:numel(chunkConfig.baseStationList)
                [tx_array(bb), tx_position(:, bb)]       = obj.createQuadrigaAntennaObject(chunkConfig.baseStationList(bb).antennaList); %qd_arrayant('omni'); %TO DO: set correct antenna type
            end

            l.tx_position = tx_position;
            l.tx_array    = tx_array;

            %             l.tx_position = cat(2,chunkConfig.baseStationList(1).antennaList(1).positionList(:,1)); %assumed to have fixed position
            %             l.tx_array    = qd_arrayant('dipole'); %TO DO: set up function to select the correct antenna pattern

            %set user tracks
            for uu = 1:numel(chunkConfig.userList)
                t = qd_track;
                t.initial_position = chunkConfig.userList(uu).positionList(:,1);
                t.positions = chunkConfig.userList(uu).positionList-chunkConfig.userList(uu).positionList(:,1); %relative to initial position
                t.name = sprintf('track%ld', uu); %unique track name required for each track

                l.rx_track(uu) = copy(t); %set track for each user
            end


            %set scenario
            l.set_scenario(params.channelModelParameters.scenario);

            obj.layout = l;
        end

        function setProperties(obj)
            % sets the properties dependent on bandwidth, subcarrierSpacing
            % and nSubcarrierSlot which are nFFT and fs
            %
            % input:
            %   used properties: bandwidthHz, Container.subcarrierSpacing,
            %   nFFT, nSubcarrierSlot
            %       see also smallScaleFading.ChannelFactory and
            %   smallScaleFading.PDPcontainer class documentation for
            %   more information
            %
            %   set properties:
            %       nFFT:               [1x1]double number of FFT points
            %       fs:                 [1x1]double sampling frequency

            if obj.bandwidthHz == 15e6
                if obj.subcarrierSpacing == 15e3
                    obj.nFFT = 1536;
                elseif obj.subcarrierSpacing == 7.5e3
                    obj.nFFT = 1536*2;
                end
            else
                obj.nFFT =  2^ceil(log2(obj.nSubcarrierSlot));
            end

            obj.fs = obj.subcarrierSpacing*obj.nFFT;
        end

        function [antennaArray, antennaPositions] = createQuadrigaAntennaObject(obj, antennaList)
            %create a qd_arrayant object according to the antenna
            %configuration set for a base station

            switch class(antennaList) %TO DO: add other antenna types here
                case 'networkElements.bs.antennas.AntennaArray'
                    antennaArray = qd_arrayant('omni');
                    antennaArray.no_elements = antennaList.nTXelements;

                    antennaArray.center_frequency = obj.centerFrequencyGHz*1e9;
                    lambda = 299792458 / antennaArray.center_frequency;

                    %shortcuts
                    nV  =  antennaList.nV;
                    nH  =  antennaList.nH;
                    nPV =  antennaList.nPV;
                    nPH =  antennaList.nPH;
                    dV  =  antennaList.dV;
                    dH  =  antennaList.dH;
                    dPV =  antennaList.dPV;
                    dPH =  antennaList.dPH;

                    % set element positions
                    %element indexing row by row
                    % x axis is the horizontal direction
                    xCoord = (0:(nH-1))*dH*lambda;
                    for ph = 2:nPH %expand list of x coords when using multiple panels
                        xCoord = [xCoord xCoord+(ph-1)*dPH*lambda];
                    end
                    xCoord = repmat(xCoord, 1, nV*nPV); %repeat for all rows
                    yCoord = zeros(size(xCoord));

                    zCoord = (0:(nV-1))*dV*lambda;
                    for pv = 2:nPV %expand list of z coords when using multiple panels
                        zCoord = [zCoord zCoord+(pv-1)*dPV*lambda];
                    end
                    zCoord = repelem(zCoord, 1, nH*nPH);

                    antennaArray.element_position = [xCoord; yCoord; zCoord];

                    %rotate pattern (e.g. for sector antennas)
                    antennaArray.rotate_pattern(antennaList.azimuth, 'z');

                    antennaPositions(:, 1) = antennaList.positionList(:, 1);

                otherwise
                    antennaArray = qd_arrayant('omni');
                    antennaArray.no_elements = antennaList.nTX;
                    antennaArray.center_frequency = obj.centerFrequencyGHz*1e9;
                    lambda = 299792458 / antennaArray.center_frequency;
                    extra_spacing_factor = 1; %this factor times lambda/2 element spacing
                    antennaArray.element_position = [repelem(0, 1, antennaList.nTX);0:(extra_spacing_factor*lambda/2):((antennaList.nTX-1)*(extra_spacing_factor*lambda/2)) ;repelem(0, 1, antennaList.nTX)]; %space out elements by lambda/2 in y direction
                    antennaPositions(:, 1) = antennaList.positionList(:, 1);
            end
        end

        function HfftRb = getRbTrace(obj, channel)
            % performs fft and filters channel trace for selected
            % subcarriers
            % Returns back a frequency channel trace jumping each
            % fftSamplingInterval subcarriers.
            %
            %input:
            %   channel:    [nRX x nTXelements x length(symbolTimes) x nLoopReals x tapDelays(end)+1]complexDouble
            %               channel in time domain
            %   object properties used: nFFT, nSubcarrierSlot, fftSamplingInterval
            %       see also smallScaleFading.ChannelFactory class
            %       documentation for more information
            %
            %output:
            %   HfftRb: [nRX x nTXelements x length(sybolTimes) x nLoopReals x nSubcarrierSlot/fftSamplingInterval]complexDouble
            %           frequency channel trace for chosen subcarriers

            HfftLarge = fft(channel, obj.nFFT, 5);
            % Eliminate guardband
            Hfft       = HfftLarge(:, :, :, :, [(obj.nFFT - obj.nSubcarrierSlot/2 + 1):obj.nFFT 2:(obj.nSubcarrierSlot/2 + 1)]);
            % Do not return the channel for all subcarriers, but just a
            % subset of it
            % Specifiy out of the useful data subcarrier's FFT,
            % which ones to take (all of them take up too much memory)
            HfftRb    = Hfft(:,:,:,:,1:obj.fftSamplingInterval:end);
        end
    end
end

