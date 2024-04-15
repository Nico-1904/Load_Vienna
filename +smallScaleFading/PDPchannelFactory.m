classdef PDPchannelFactory < smallScaleFading.ChannelFactory
    % Wraps the functions needed to generate a PDP-based channel trace.
    % Creates a channel trace with the antenna configuration and the
    % parameters in the PDPcontainer given to the class constructor.
    %
    % initial auhtor: Agnes Fastenbauer
    % based on LTE DL SL simulator (c) Josep Colom Ikuno, Michal Simko, INTHFT, 2011
    %
    % The generated trace has the following structure:
    % Trace:  [1x1]struct of channel trace with given antenna configuration
    % 	H:                  [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complexDouble channel matrix
    %	nTXelements:        [1x1]double number receive antennas
    %	nRX:                [1x1]double number transmit antennas
    %	channelModel:	    [1x1]enum channel model see also parameters.setting.ChannelModel
    %	freqCarrier:        [1x1]double carrier frequency in Hz
    %	bandwidthHz:        [1x1]double carrier bandwidth
    %	userSpeed:          [1x1]double user speed
    %	correlatedFading:   [1x1]logical flag for correlated fading trace
    %	subcarrierSpacing:  [1x1]double subcarrier spacing
    %	symbolTimes:        [1 x s]double times for block fading scenario
    %
    % PDP: Power Delay Profile
    %
    % see also smallScaleFading.PDPcontainer, smallScaleFading.ChannelFactory

    properties
        corrTX = 1;      % correlation matrix transmitter for correlatedFading
        corrRX = 1;      % correlation matrix receiver
        % parameter for rosa zheng model
        % [1x1]double M = 15
        RosaZhengM

        % number of different channel realizations in time
        %[1x1]integer number of samples in time
        % In general the channel is assumed constant over a slot, in case
        % this is not a true short block fading scenario is implemented,
        % where more than one channel realization is calculated for each
        % slot. The number of samples is saved here and the times at which
        % a channel realization is calculated are saved in
        % PDPcontainer.symbolTimes and PDPcontainer.symbolTimesIndex.
        nTimeSamples = 1;

        % number of channel realizations in frequency
        %[1x1]integer number of channel samples in frequency
        %
        %NOTE: for use in the 5G SLS, this should be equal to
        %parameters.resourceGrid.ResourceGrid.nRBFreq, otherwise the LQM
        %cannot handle the channel trace (it assumes a constant channel for
        %each resource block (RB)).
        %
        % The channel is assumed constant over several subcarriers, this
        % number indicates how many channel samples are taken in the
        % frequency domain. It is calculated with the number of subcarriers
        % in a slot and the fft sampling interval that indicates which
        % values of the channel trace in the frequency domain are kept.
        nFreqSamples
    end

    properties (Access = private)
        tapDelays           % tap delays
        tapPosition         % tap position
        nTaps               % number of taps
        tapPowers           % tap powers
        tapPowersUsed       % used tap powers

        nTotReals           % total number of realizations

        % number of realizations per loop = chunk of realizations made at
        % once: this is limited to avoid memory problems
        nLoopReals = 1000;
        % current loop offset: this parameter is set to avoid unnecessary
        % function input by giving it through several functions
        loopOffset
    end

    methods (Access = private)
        % parameter initialization functions
        function setChanModParams(obj)
            % set the config parameters for the channel model
            %
            % used properties: channelModel, nRX, nTXelements, fs, tapDelays
            %
            % set properties:
            %  	corrRX:         [size(PDPdB,2) x nRX x nRX] correlation matrix receiver
            %  	corrTX:         [size(PDPdB,2) x nRX x nRX] correlation matrix transmitter
            %	tapPowers:      [size(PDPdB,2)] tap powers
            %	tapDelays:      [size(PDPdB,2)] tap delays
            %	tapPosition:	[] tap position
            %   and properties set in getPDPdBnormH

            % get power delay profile
            [PDPdB, normH] = obj.getPDPdBnormH;

            % get number of samples in time
            obj.nTimeSamples = length(obj.Container.symbolTimes);
            % get number of samples in frequency
            obj.nFreqSamples = obj.nSubcarrierSlot / obj.fftSamplingInterval;

            % Power of taps in linear and normalized to 1
            obj.tapPowers     = sqrt(10.^(PDPdB(1,:)./10)) / normH;
            obj.tapDelays     = round(PDPdB(2,:)*obj.samplingFrequency);
            obj.tapPosition   = [1, find(diff(obj.tapDelays)) + 1];

            if obj.Container.correlatedFading && obj.channelModel ~= 10
                % Channel parameters dependent - load Correlation Matrices
                obj.corrRX = ones(size(PDPdB,2),obj.nRX,obj.nRX);
                obj.corrTX = ones(size(PDPdB,2),obj.nTXelements,obj.nTXelements);
                for kk = 1:size(PDPdB,2)
                    obj.corrRX(kk,:,:) = eye(obj.nRX);
                    obj.corrTX(kk,:,:) = eye(obj.nTXelements);
                end
            end % if correlated fading is active and it is not an AWGN channel
        end

        function [PDPdB, normH] = getPDPdBnormH(obj)
            % Chooses and sets PDPdB and normH according to the channel
            % model type.
            %
            % input:
            %   used properties: channelModel
            %
            %output:
            %   PDPdB:  [2 x depending on channel model]double (=powers and delays)
            %           the first row vector is the average power in dB
            %           the second row vector is the delay in seconds
            %           the length of the row vectors depends on the chosen
            %           channel model type
            %   normH:  [1x1]double average power (not in dB!)

            switch obj.channelModel
                case parameters.setting.ChannelModel.PedA
                    PDPdB = [0 -9.7 -19.2 -22.8; %average power in dB
                        [ 0 110 190 410 ]*1e-9 ]; %delay in s
                case parameters.setting.ChannelModel.PedB
                    PDPdB = [0   -0.9  -4.9  -8    -7.8  -23.9; %average power in dB
                        [ 0 200 800 1200 2300 3700 ]*1e-9 ]; %delay in s
                case parameters.setting.ChannelModel.extPedB
                    % ITU-T extended PedestrianB channel model. From
                    % "Extension of the ITU Channel Models for Wideband
                    % (OFDM) Systems", Troels B. S?rensen, Preben E.
                    % Mogensen, Frank Frederiksen
                    PDPdB = [0 -0.1 -3.7 -3.0 -0.9 -2.5 -5.0 -4.8 -20.9; %average power in dB
                        [ 0 30 120 200 260 800 1200 2300 3700 ]*1e-9 ]; %delay in s
                case parameters.setting.ChannelModel.VehA
                    PDPdB = [0   -1  -9  -10    -15  -20; %average power in dB
                        [ 0 310 710 1090 1730 2510 ]*1e-9 ]; %delay in s
                case parameters.setting.ChannelModel.VehB
                    PDPdB = [-2.5   0  -12.8  -10    -25.2  -16; %average power in dB
                        [ 0 300 8900 12900 17100 20000 ]*1e-9]; %delay in s
                case parameters.setting.ChannelModel.TU
                    PDPdB = [...
                        -5.7000     -7.6000     -10.1000    -10.2000    -10.2000 ... %average power in dB
                        -11.5000    -13.4000    -16.3000    -16.9000    -17.1000 ...
                        -17.4000,   -19.0000    -19.0000    -19.8000    -21.5000 ...
                        -21.6000    -22.1000    -22.6000    -23.5000    -24.3000;
                        0       0.2170	0.5120	0.5140	0.5170...   %delay in us
                        0.6740  0.8820	1.2300  1.2870  1.3110...
                        1.3490  1.5330	1.5350  1.6220  1.8180...
                        1.8360  1.8840	1.9430  2.0480  2.1400];
                    PDPdB(2,:) = PDPdB(2,:)*1e-6; % delay in seconds
                case parameters.setting.ChannelModel.RA
                    PDPdB = [...
                        -5.2000     -6.4000     -8.4000     -9.3000     -10.0000... %average power in dB
                        -13.1000    -15.3000    -18.5000    -20.4000    -22.4000;
                        0           0.0420      0.1010      0.1290      0.1490... %delay in us
                        0.2450      0.3120      0.4100      0.4690      0.5280];
                    PDPdB(2,:) = PDPdB(2,:)*1e-6; % delay in seconds
                case parameters.setting.ChannelModel.HT
                    PDPdB = [...
                        -3.6000     -8.9000     -10.2000    -11.5000    -11.8000... %average power in dB
                        -12.7000    -13.0000    -16.2000    -17.3000    -17.700...
                        -17.6000    -22.7000    -24.1000    -25.8000    -25.8000...
                        -26.2000    -29.0000    -29.9000    -30.0000    -30.7000;
                        0           0.3560      0.4410      0.5280      0.5460... %delay in us
                        0.6090      0.6250      0.8420      0.9160      0.9410...
                        15.0000     16.1720     16.4920     16.8760     16.8820,...
                        16.9780     17.6150      17.827      17.8490   	18.0160];
                    PDPdB(2,:) = PDPdB(2,:)*1e-6; % delay in seconds
                case {parameters.setting.ChannelModel.Rayleigh, parameters.setting.ChannelModel.AWGN}
                    % AWGN is just set here similar to Ralyeigh to avoid
                    % crashing of the simulator; later it is replaced with
                    % all-ones channels
                    PDPdB = [0;0];
                otherwise
                    warning('The channel model %s is not implemented.', obj.channelModel);
            end
            normH = sqrt(sum(10.^(PDPdB(1,:)/10)));
        end

        % channel trace computation functions
        function X = computeRosaZhengX(obj)
            % Calculates X for correlated fading according to
            %{
            % Yahong Rosa Zheng; Chengshan Xiao, "Simulation models
            % with correct statistical properties for Rayleigh fading
            % channels," Communications, IEEE Transactions on , vol.51,
            % no.6, pp. 920-928, June 2003
            % URL:
            % http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=1209292&isnumber=27219
            %}
            %
            % used properties: tapDelays, tapPosition, nTaps, nLoopReals,
            % symbolTimes, nRX, nTXelements, samplingFrequency, loopOffset,
            % slotDuration, userSpeed, corrRX, corrTX
            %
            % output:
            %   X:      [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complexDouble
            %   set properties: properties set in rosaZhengParamsGenerator

            % Maximum radian Doppler frequency
            w_d   = 2*pi * obj.userSpeed * obj.freqCarrier / parameters.Constants.SPEED_OF_LIGHT;

            % Rosa-Zheng parameters
            obj.RosaZhengM     = 15;
            % initalization
            psi_n = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, obj.RosaZhengM);
            theta = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, obj.RosaZhengM);
            phi   = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, obj.RosaZhengM);
            % for the generation of the rosa zheng weights
            psi_n(:,:,1, :, :)   = rand(obj.nRX, obj.nTXelements, obj.nTaps, obj.RosaZhengM);
            phi(  :,:,1, :, :)   = rand(obj.nRX, obj.nTXelements, obj.nTaps, obj.RosaZhengM);
            theta(:,:,1, :, :)   = repmat(rand(obj.nRX, obj.nTXelements, obj.nTaps, 1),[1 1 1 obj.RosaZhengM]);

            % Preallocation of the Time matrix
            timei = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, obj.RosaZhengM);
            timeiHelp = obj.tapDelays(obj.tapPosition) / obj.samplingFrequency;
            timeiHelp = kron(timeiHelp, ones(obj.nTotReals,1)) ...
                + (kron(ones(1,obj.nLoopReals),obj.Container.symbolTimes) ...
                + kron((0:(obj.nLoopReals-1)) ...
                + obj.loopOffset,ones(1,obj.nTimeSamples))).'*ones(1,length(timeiHelp))*obj.Container.slotDuration;
            timei(1,1,:,:,1) = timeiHelp;
            timei = repmat(timei(1, 1, :, :, 1), [obj.nRX, obj.nTXelements, 1, 1, obj.RosaZhengM]);

            for iTap = 1:obj.nTaps
                for iM = 1:obj.RosaZhengM
                    R_X =  sqrtm(squeeze(obj.corrRX(iTap,:,:)));
                    T_X = (sqrtm(squeeze(obj.corrTX(iTap,:,:)))).';
                    psi_n(:, :, 1, iTap, iM) = R_X * psi_n(:, :, 1, iTap, iM) * T_X;
                    phi(:, :, 1, iTap, iM) = R_X *   phi(:, :, 1, iTap, iM) * T_X;
                    theta(:, :, 1, iTap, iM) = R_X * theta(:, :, 1, iTap, iM) * T_X;
                end
            end

            % Calculation of H
            psi_n(:, :, 1, :, :) = (psi_n(:, :, 1, :, :)*2 - 1) * pi;
            phi(  :, :, 1, :, :) = (  phi(:, :, 1, :, :)*2 - 1) * pi;
            theta(:, :, 1, :, :) = (theta(:, :, 1, :, :)*2 - 1) * pi;

            psi_n = repmat(psi_n(:, :, 1, :, :), [1, 1, obj.nTotReals, 1, 1]);
            phi   = repmat(  phi(:, :, 1, :, :), [1, 1, obj.nTotReals, 1, 1]);
            theta = repmat(theta(:, :, 1, :, :), [1, 1, obj.nTotReals, 1, 1]);

            PImat = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, obj.RosaZhengM);
            PImat(1, 1, 1, 1, :) = (1:obj.RosaZhengM)*2*pi;
            PImat = repmat(PImat(1,1,1,1,:), [obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps, 1]);
            alpha_n = (PImat - pi + theta) / (4*obj.RosaZhengM);

            X_c = cos(psi_n).*cos(w_d.*timei.*cos(alpha_n) + phi);
            X_s = sin(psi_n).*cos(w_d.*timei.*cos(alpha_n) + phi);
            X = 2/sqrt(2*obj.RosaZhengM) * sum(X_c + 1i*X_s,5);
        end

        function Hfft = getHfft(obj)
            % Generate fast fading coefficients for the simulation.
            %
            % based on (c) Michal Simko, INTHFT, 2009
            %
            % input:
            %   used properties: Container.correlatedFading, nRX, nTXelements,
            %   nTotReals, nTaps, tapPowersUsed, tapDelays, tapPosition,
            %   nLoopReals and calls computeRosaZhengX, getRbTrace
            %
            %output:
            %   Hfft:   [nRX x nTXelements x nTimeSamples x nLoopsReals x nFreqSamples]complexDouble
            %           channel matrix

            if obj.Container.correlatedFading
                X = obj.computeRosaZhengX;
            else % uncorrelated fading
                X =    ( randn(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps) ...
                    + 1i*randn(obj.nRX, obj.nTXelements, obj.nTotReals, obj.nTaps) )/sqrt(2);
            end

            weightMatrix = zeros(obj.nRX, obj.nTXelements,obj.nTotReals,obj.nTaps);
            weightMatrix(1,1,:,:) = kron(obj.tapPowersUsed(unique(obj.tapDelays+1)), ones(obj.nTotReals,1));
            weightMatrix = repmat(weightMatrix(1,1,:,:),[obj.nRX, obj.nTXelements, 1, 1]);

            Htemp = zeros(obj.nRX, obj.nTXelements, obj.nTotReals, obj.tapDelays(end)+1);
            Htemp(:, :, :, obj.tapDelays(obj.tapPosition)+1) = X .* weightMatrix;

            H = reshape(Htemp, obj.nRX, obj.nTXelements, obj.nTimeSamples, obj.nLoopReals, obj.tapDelays(end)+1);

            % Trace in frequency domain
            Hfft = obj.getRbTrace(H);
        end

        function pregenHtrace = generateFFtrace(obj)
            % generate fast fading coefficients for the simulation
            % This function returns a struct containing the sampled channel
            % model.
            %
            % In this function the generation is splitted up for better
            % memory usage due to memory issues.
            %
            % based on LTE DL SL simulator (c) Michal Simko, modified by Josep Colom Ikuno, INTHFT, 2009
            %
            % object properties used: Container.traceLengthSlots, nFFT,
            % nLoopReals
            % object functions called: getHfft
            %
            % output:
            %   pregenHtrace:   [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complexDouble
            %                   with pregenerated fast fading channel
            %                   coefficients

            %% Separate the number of slots in smaller chunks to avoid memory problems
            simSegmentation = obj.nLoopReals * ones(1, floor(obj.Container.traceLengthSlots/obj.nLoopReals));
            remanent = rem(obj.Container.traceLengthSlots, obj.nLoopReals);

            if remanent > 0
                simSegmentation = [simSegmentation remanent];
            end

            nLoops = length(simSegmentation);
            beginPos = zeros(size(simSegmentation));
            endPos   = beginPos;
            beginPos(1) = 1;
            endPos(1)   = simSegmentation(1);

            for iLoop = 2:nLoops
                beginPos(iLoop) = endPos(iLoop-1) + 1;
                endPos(iLoop)   = endPos(iLoop-1) + simSegmentation(iLoop);
            end

            %% Generate channel coefficients
            % Separates the channel coefficient generation in several loops
            % so as not to eat up all of the memory.
            iPrint = unique(floor(linspace(1, nLoops, 10)));
            iCurrent = 1;
            pregenHtrace = zeros(obj.nRX, obj.nTXelements, obj.nTimeSamples, obj.Container.traceLengthSlots, obj.nFreqSamples);
            for loopIdx = 1:nLoops
                if loopIdx == iPrint(iCurrent) && obj.Container.verbosityLevel >=1
                    percentage = loopIdx/nLoops*100;
                    fprintf([num2str(percentage,'%3.2f') '%% ']);
                    iCurrent = iCurrent + 1;
                end
                samples = beginPos(loopIdx):endPos(loopIdx);
                obj.loopOffset = beginPos(loopIdx)-1;
                Hfft = obj.getHfft;
                pregenHtrace(:,:,:,samples,:) = Hfft(:,:,:,1:length(samples),:);
            end
            if obj.Container.verbosityLevel >= 1
                fprintf('\n');
            end
        end
    end

    methods
        function obj = PDPchannelFactory(resourceGrid, thisAntennaConfig, Container)
            % Class constructor for PDPchannelFactory
            %
            % input:
            %   resourceGrid:       [1x1]handleObject parameters.resourceGrid.ResourceGrid
            %   thisAntennaConfig:	[1x1]object smallScaleFading.TraceConfiguration
            %   Container:          [1x1]handleObject smallScaleFading.PDPcontainer
            %
            % set properties:
            %  	tapPowersUsed:  [1 x max(obj.tapDelays+1)]double used tap
            %                   powers
            % 	nTaps:          [1x1]double number of taps
            % and properties set in superclass constructor, setChanModParams

            % Call superclass constructor
            obj = obj@smallScaleFading.ChannelFactory(resourceGrid, thisAntennaConfig, Container);

            % set channel model and channel model dpendent parameters
            obj.setChanModParams;

            obj.nTaps       = length(obj.tapPosition);
            obj.nTotReals   = obj.nLoopReals * obj.nTimeSamples;

            % Sum up all of the taps that merge (sum power!):
            % nearest neighbor interpolation
            obj.tapPowersUsed = zeros(1, max(obj.tapDelays+1));
            for tapIdx = unique(obj.tapDelays)
                tapsToSum = obj.tapDelays==tapIdx;
                obj.tapPowersUsed(tapIdx+1) = sqrt(sum(obj.tapPowers(tapsToSum).^2));
            end
        end

        function Trace = generateChannelMatrix(obj, filename)
            % generates and saves the desired and interfering trace for the
            % given antenna configuration and puts them together in a
            % struct with all other needed parameters
            %
            %NOTE: each MIMO channel is normalized to a mean power of one
            %
            % input:
            % used properties: obj.Container.verbosityLevel, nTXelements, nRX,
            % channelModel, freqCarrier, bandwidthHz,
            % Container.traceLengthSlots, userSpeed,
            % Container.correlatedFading, Container.subcarrierSpacing,
            % Container.symbolTimes
            %
            % see also smallScaleFading.PDPchannelFactory,
            % smallScaleFading.ChannelFactory,
            % smallScaleFading.PDPcontainer,
            % parameters.setting.ChannelModel
            %
            % calls generateFFtrace
            %
            % output:
            %   Trace:  [1x1]struct of channel trace with given antenna
            %           configuration
            %       -H:                 [nRX x nTXelements x nTimeSamples x nFreqSamples]complexDouble channel matrix
            %       -nTXelements:               [1x1]double number receive antennas
            %       -nRX:               [1x1]double number transmit antennas
            %       -channelModel:      [1x1]enum channel model
            %       -freqCarrier:       [1x1]double carrier frequency in Hz
            %       -bandwidthHz        [1x1]double carrier bandwidth in Hz
            %       -userSpeed:         [1x1]double user speed
            %       -correlatedFading:  [1x1]logical flag for correlated fading
            %       -subcarrierSpacing: [1x1]double subcarrier spacing
            %       -symbolTimes:       [1 x nSampleRbTime]double times for block fading scenario

            if obj.Container.verbosityLevel >= 1
                fprintf('Generating UE fast fading and saving to %s\n', filename);
                fprintf('Generating %dx%d channel trace of length %3.2fslots\n', obj.nTXelements, obj.nRX, obj.Container.traceLengthSlots);
            end

            traceH0 = obj.generateFFtrace;

            % for AWGN channel model
            if obj.channelModel == parameters.setting.ChannelModel.AWGN
                traceH0 = ones(size(traceH0));
            end

            Trace.H                 = traceH0;
            Trace.nRX               = obj.nRX;
            Trace.nTXelements       = obj.nTXelements;
            Trace.freqCarrier       = obj.freqCarrier;
            Trace.bandwidthHz       = obj.bandwidthHz;
            Trace.channelModel      = obj.channelModel;
            Trace.userSpeed         = obj.userSpeed;
            Trace.correlatedFading  = obj.Container.correlatedFading;
            Trace.subcarrierSpacing = obj.subcarrierSpacingHz;
            Trace.symbolTimes       = obj.Container.symbolTimes;

            % save trace
            try
                % this is to warn if a file is overwritten
                if exist(filename,'file') && obj.Container.verbosityLevel >= 1
                    fprintf('The cache file already exists and is overwritten.\n');
                end
                save(filename, 'Trace');
            catch err
                fprintf('Channel trace could not be saved. (%s).\n',err.message);
            end
        end
    end
end

