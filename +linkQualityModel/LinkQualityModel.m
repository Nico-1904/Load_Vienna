classdef LinkQualityModel < tools.HiddenHandle
    %LINKQUALITYMODEL generates the post-equalization SINR for one link
    % The link qualtiy model calculates the post equalization SINR on each
    % layer for each resource block allocated to the considered user.
    %
    % This class contains all necessary functions to get the post
    % equalization SINR for each resource block.
    %   posteqSinr:     [nLayer x nRBFreq x nRBTime]double post equalization SINR for each layer of each resource block
    %
    % To get the SINR values the linkQualityModel class has to be set up
    % with its class constructor, the macroscale parameters have to be set
    % with the updateMacroscopic function, the small scale parameters have
    % to be set with the updateSmallScale function and then the post
    % equalization SINR can be calculated with the getSinr function.
    % For each new slot the small scale parameters have to be updated to
    % their new values and for each new segment the macro scale parameters
    % have to be updated to their new values.
    %
    % Inter-numerology interferers are separated.
    %
    % Assumptions:
    %   -For now all calculations are for a zero force receiver.
    %   -The channel is assumed constant over a slot (small block fading
    %   as known from LTE DL SL simulator is not implemented).
    %   -It is assumed that there are several desired links to account for
    %   MBSFN, DAS, RRH and so on and that the user allocation and number
    %   of layers are identical for all desired antennas.
    %
    % For a description of the basic implementation see J. Colom Ikuno:
    % "System Level Modeling and Optimization of the LTE Downlink" Chapter
    % 3, section 3.1.1.
    %
    % see also linkQualityModel.example
    %
    % initial author: Agnes Fastenbauer

    properties
        % receiver network element
        % [1x1]handleObject receiver network element
        % This should be the receivering user for downlink and the
        % receiving base stion for uplink.
        %
        % used properties:
        %   -nRX:             	[1x1]integer number of receive antennas
        %   -thermalNoisedB:	[1x1]double thermal noise power of the antenna
        %   -scheduling:        [1x1]object scheduler.signaling.UserScheduling
        receiver

        % logical array indicating desired antennas
        % [1 x nAnt]logical vector indicating the desired links
        %
        % see also nDes
        desired

        % number of active interferers
        % [1x1]integer number of interferers
        % This is the number of antennas that are considered as interferers.
        %
        % see also interferer
        nInt

        % total number of antennas
        % [1x1]integer total number of antennas
        % This is the length of antenna.
        %
        % see also antenna
        nAnt

        % small scale fading of all links
        %[1 x nAnt]struct channel matrices for all antennas
        %   -H: [nRX x nTX x nTimeSamples x nFreqSamples]complex channel matrix
        %
        % The dimension nTimeSamples is usually 1, it is only bigger for
        % short block fading scenarios, where more than one channel
        % realization is necessary for one slot. In the normal case the
        % channel is assumed constant in time for the duration of a slot.
        %
        % The dimension nFreqSamples should in the normal case be the
        % number of resource blocks in frequency nRBFreq, it is set through
        % the nFFTsampling interval in the smallScaleFading package.
        %
        %NOTE: small block fading and variable number of samples in
        %frequency are not implemented
        channel

        % thermal noise power for one resource block in Watt
        % [1x1]double thermal noise power per reosurce block in W
        % The thermal noise power is assumed constant for a network
        % element.
        %
        % see also networkElements.NetworkElementWithPosition.thermalNoisedB,
        % networkElements.NetworkElementWithPosition.rxNoiseFiguredB
        noise

        % interference from other users in case of Successive Interference Cancellation in Watt
        % [nLayer x nRBscheduled]double additional interference power from other NOMA users in W
        sicInterference = 0;

        % macroscopic fading for each antenna in W
        % [1 x nAnt] macroscopic fading in W
        % This includes the pathloss with wall loss, the shadow fading and
        % the antenna gain.
        macroscopicFadingW

        % number of layers used for the desired links
        % [1x1]integer number of layers used
        % The number of layers is assumed to be the same for all desired
        % links.
        nLayer

        % transmit power attenuated by macroscopic fading for each resource block in Watt
        % [nLayer x nRBFreq x nRBTime x nAnt]double attenuated transmit power in Watt
        % This is the transmit power allocated by the scheduler attenuated
        % by large scale fading and distributed evenly to all layers.
        % This power is saved for each resource block for the calculations
        % in the feedback.
        %
        % see also feedback.LTEDLFeedback.calculatePMIlayer
        powerRB

        % receive power per resource block and layer in Watt
        % [nLayer x nRBscheduled x nAnt]double receive power per resource block distributed to layers in Watt
        % This is the transmit power allocated by the scheduler with macro
        % scale fading (pathloss, shadow fading and antenna gain).
        % The power allocation from the scheduler is divided by the number
        % of layers used by current receiver and replicated to all layers
        % used by the receiver here. nLayer is the same for all antennas,
        % because we divide by and replicate to the number of layers used
        % by desired link.
        rxPowerW

        % active interferers
        % [1 x nAnt]logical indicates if this antenna is considered an active interferer in this slot
        % userAllocation from scheduler in RB grid, is -1 if no user has
        % been scheduled. The isActive array is true for all antennas where
        % user Allocation is not set to -1 or alwaysOn is true.
        % The transmitters, that are not scheduled in the current slot are
        % not considered as interference unless the alwaysOn feature at the
        % antenna is activated.
        isActive

        % precoders for scheduled resource block
        % [nRBscheduled x nAnt]struct with different precoders
        %   -W: [nTX x nLayer]complex precoder for this resource block
        % Here nTX and nLayer are the number of transmit antennas and the
        % number of layers used by each transmitter and not those of the
        % receiver.
        precoder

        % analog precoder for each antenna
        % [1 x nAnt]struct with analog precoder for each antenna
        %	-W_a:	[nTX x nTXelements]complex analog precoder
        %NOTE: the initialization here is necessary, because MATLAB won't
        %accept the initializationn in setLinkParameters otherwise
        precoderAnalog

        % receive filter (linear)
        % [nLayer x nRX x nRBscheduled x nDes]complex receive filter
        % The number of layers is the number of layers used by the
        % receiver.
        receiveFilter
        %NOTE: This used to be called P in the DL SL simulator.

        % resource grid
        % [1x1]parameters.resourceGrid.ResourceGrid
        resourceGrid

        % calculate INI
        % [1x1]logical sets if inter-numerology interference shall be
        % considered in the LQM calculation
        calculateIni

        % Inter-numerolgoy factor cache
        % [1x1]handleObject linkQualityModel.IniCache Caches precalculated
        % inter-numerology interference factors for the LQM
        iniCache

        % Interference values for inter-numerology calculated by the LQM
        % This values are saved to be used in the Feedback
        % [nLayer x nRBFreq x nRBTime]double linear interference power
        interNumerologyInterference

        % parameters
        % [1x1]handleObject parameters.Parameters
        params
    end

    properties (Dependent)
        % number of transmitters that send desired signal
        % [1x1]integer number of desired signals
        %
        % see also desired
        nDes
    end

    properties (SetAccess = protected, GetAccess = public)
        % The following properties have restricted set acces to assure that
        % the number of links nDes and nInt are updated correctly.

        % array with all antennas that are transmitting in the current slot
        % [1 x nAnt]handleObject networkElements.bs.Antenna
        % This vector contains all antennas that are currently
        % transmitting, desired and interfering. They can be base station
        % antennas for downlink or user antennas for uplink.
        %
        % NOTE: this is used to get the number of antennas nTX and the
        % scheduler information.
        %
        % see also interferer, desired
        antenna

        % object that maps all antennas to the base station they belong to
        % [1x1]handleObject tools.AntennaBsMapper
        antennaBsMapper

        % logical array indicating interfering antennas
        % [1 x nAnt]logical array indicating the interfering links
        % Base stations that are not scheduled in the current slot are
        % filtered out as interferers and not marked as interferers in this
        % array.
        %
        % see also nInt, filterInactiveInterferers
        interferer

        % logical array indicating numerology interfering antennas
        % [1 x nAnt]logical array indicating the interfering links
        % These are all antennas using a subcarrier spacing different from
        % the receiver.
        % Base stations that are not scheduled in the current slot are
        % filtered out as interferers and not marked as interferers in this
        % array.
        %
        % see also nInt, filterInactiveInterferers
        numerologyInterferer

        % BLER curves mapping effective SINR values to block errror rates
        % [1x1]handleObject linkPerformanceModel.BlerCurves
        blerCurves

        % layer mapping
        % [1x1]handleObject parameters.transmissionParameters.LayerMapping
        layerMapping

        % NOMA interference cancellation factor
        % [1x1]double 0...1 remaining interference after SIC
        %
        % After successive interference cancellation (SIC), this factor
        % defines the amount of interference created by he far user  and
        % experienced by the near user.
        %
        % see also parameters.Noma.interferenceFactorSic
        nomaInterferenceFactor

        %% resource grid properties

        % absolute indices of scheduled RBs
        % [nRBscheduled x 1]integer absolute indices of scheduled RBs
        indexRB

        % total number of resource blocks scheduled for this user
        % [1x1]integer number of assigned RBs
        nRBscheduled
    end

    methods (Abstract)
        % sets the inter-layer interference xi
        %
        % output:
        %   xi:	[nLayer x nRBFreq x nRBTime x nDes]double inter-layer interference
        xi = getInterLayerInterference(obj)

        % sets fraction of power going to the signal part of the SINR
        %
        % output:
        %   zeta:   [nLayer x nRBFreq x nRBTime x nDes]double power fraction between 0 and 1
        zeta = getSignalPowerFraction(obj)
        % ZF receiver - all the transmit power is signal
        % --> should actually be an input for not-ZF-receiver

        % calculates and sets receive filter
        %
        % set properties: receiveFilter
        %
        % see also receiveFilter
        setReceiveFilter(obj)
    end

    methods
        % initialization functions
        function obj = LinkQualityModel(params, resourceGrid, antennaBSmapper, iniCache)
            % initializes the link quality model
            %
            % input:
            %   params:             [1x1]handleObject parameters.Parameters
            %   resourceGrid:       [1x1]handleObject resource grid parameters
            %   antennaBSmapper:    [1x1]handleObject tools.AntennaBsMapper
            %   iniFactors:         [1x1]handleObject linkQualityModel.IniCache

            % set resource grid parameters
            obj.resourceGrid = resourceGrid;

            obj.calculateIni = params.calculateIni;
            obj.iniCache = iniCache;

            %% parameters that are constant for a simulation
            % set parameters for successive interference cancellation for NOMA transmission
            obj.nomaInterferenceFactor	= params.noma.interferenceFactorSic;
            obj.blerCurves              = params.transmissionParameters.DL.blerCurves;
            obj.layerMapping            = params.transmissionParameters.DL.layerMapping;

            % save antanna base station mapping
            obj.antennaBsMapper = antennaBSmapper;

            obj.params = params;
        end

        function setLinkParameters(obj, antenna, receiver)
            % sets link parameters - receiver, transmitters, noise
            %
            %   antenna:        [1 x nAnt]handleObject all antennas in the network
            %   receiver:       [1x1]handleObject receiving network element

            % information about links
            % set receiver
            obj.receiver = receiver;
            % set antenna array with all antennas
            obj.setAntenna(antenna);
            % initialize desired antennas
            obj.desired = false(1, obj.nAnt);
            % initialize interferers
            obj.initInterferers;
            obj.interNumerologyInterference = 0;

            % set receiver noise power
            obj.noise = tools.dBto(obj.receiver.thermalNoisedB);
        end

        % update functions
        function updateMacroscopic(obj, desired, macroscopicFadingW)
            % updates macroscopic parameters that change for each segment
            % Sets path loss, antenna gain, and shadow fading for
            % a new segment and applies minimal coupling loss to pathloss
            % and antenna gain.
            %
            % input:
            %	desired:                [1 x nAnt]logical vector indicating desired transmitters
            %	macroscopicFadingW:     [1 x nAnt]double pathloss for all links

            %% macroscopic parameters that change for every segment

            % set desired and interfering transmitters
            obj.desired = desired;
            obj.initInterferers;
            obj.macroscopicFadingW = macroscopicFadingW;
        end

        function updateSmallScale(obj, smallScaleFading)
            % updates small scale parameters that change for every slot
            % Sets small scale fading, power allocation and user allocation
            % for new slot and updates the list of interferers according to
            % the new user allocation. This function assumes that the
            % scheduling information at each antenna has been updatet for
            % this slot.
            %
            % input:
            %   smallScaleFading:	[1 x nAnt]struct channel matrices for all antennas
            %       -H: [nRX x nTX x nTimeSamples x nFreqSamples]complex channel matrix

            % update channel information - small scale fading
            obj.channel = smallScaleFading;
            % update scheduling information
            obj.setScheduling;
            % set is active indicator
            obj.setIsActive;
            % filter out transmitters that are not interferers
            obj.filterInactiveInterferers;
            % set analog and baseband precoders
            obj.setPrecoder;
            % set the transmit power properties
            obj.setPower;
            % set receive filter
            obj.setReceiveFilter;
            % reset sicInterference
            obj.sicInterference = zeros(obj.nLayer, obj.nRBscheduled);
        end

        % calculation functions
        function posteqSinrdB = getPostEqSinr(obj)
            % calculates the post equalization SINR for each resource block
            %
            % output:
            %   posteqSinrdB:	[nLayer x nRBFreq x nRBTime]double post equalization SINR for each resource block
            %
            % see also
            % J. Colom Ikuno: "System Level Modeling and Optimization of
            % the LTE Downlink" 3. Physical Layer Modeling and LTE System
            % Level Simulation
            %
            % input:
            %    iniPower_: [nLayer x nRBscheduled x nAnt]double inter numerology interference
            %
            % SINR: Signal to Interference and Noise Ratio
            %
            %NOTE: in the LTE DL SL simulator there are different versions
            %of this functions for beamforming and svd precoding, here only
            %the basic version is implemented, the other versions can be
            %found in linkQualityModel.legacy

            % calculate inter-numerology interference
            iniPower = obj.getIniPower;

            %% initializations
            posteqSinr = zeros(obj.nLayer, obj.resourceGrid.nRBFreq, obj.resourceGrid.nRBTime);

            % inter-layer-interference and signal power fraction
            xi      = obj.getInterLayerInterference;
            zeta	= obj.getSignalPowerFraction;
            % noise enhancement
            psi     = obj.getNoiseEnhancement;
            % get interference enhancement
            theta	= obj.getInterferenceEnhancement;

            %% SIC
            obj.successiveInterferenceCancellation(psi, xi, zeta, theta, iniPower);

            %% calculate post equalization SINR
            % post equalization SINR for each resource block
            posteqSinr(:,obj.indexRB) = obj.calculatePostEqualizationSinr(...
                psi, xi, zeta, theta, obj.rxPowerW, ...
                obj.receiver.scheduling.nomaPowerShare, iniPower);

            % transform to dB - make sure initial 0 values are set to -Inf
            posteqSinrdB = tools.todB(posteqSinr);
        end

        function sinr = calculatePostEqualizationSinr(obj, psi, xi, zeta, theta, rxPower, nomaPowerShare, iniPower_)
            % calculates post equalization SINR for each RB from the given inputs
            %
            % input:
            %   psi:            [nLayer x nRB x nDes]double noise enhancement
            %   xi:             [nLayer x nRB x nDes]double inter-layer interference
            %   zeta:           [nLayer x nRB x nDes]double power fraction between 0 and 1
            %   theta:          [nLayer x nRB x nInt]double interference enhancement
            %   rxPower:        [nLayer x nRB x nAnt]double received power in W
            %   nomaPowerShare: [nLayer x 1]double 0...1 share of power assigned to the desired part of the signal for SIC
            %	iniPower_:      [nLayer x nRBscheduled x nAnt]double inter numerology interference
            %
            % output:
            %   sinr:   [nLayer x nRB]double post equalization SINR for each RB

            % get the signal power part for each resource block - sum over all desired links
            signal                  = sum(zeta .* rxPower(:,:,obj.desired), 3) .* nomaPowerShare;

            % inter layer interference over all antennas - sum over all desired links
            interLayerInterference  = sum(xi   .* rxPower(:,:,obj.desired), 3);
            % noise for each resource block (scalar) - sum over all desired links
            postEqNoise             = sum(psi  .* obj.noise, 3);
            % interference in each resource block - sum over all interfering links
            interference            = sum(theta.* (rxPower(:,:,obj.interferer) + iniPower_(:,:, obj.interferer)),3);
            % post equalization SINR for each layer on each resource block
            sinr = signal ./ (interLayerInterference + postEqNoise + interference + obj.sicInterference);
        end

        function theta = getInterferenceEnhancement(obj)
            % calculate theta, the interference enhancement
            %
            % output:
            %    theta: [nLayer x nRBscheduled x nInt]double interference enhancement theta
            %
            %NOTE: short block fading is not implemented here

            %% initialize variables
            % initialize interference enhancement
            theta = zeros(obj.nLayer, obj.nRBscheduled, obj.nInt);

            %% get channel and precoders for interfering signals
            % get interfering channels
            intH = obj.channel(1, obj.interferer);
            % get interfering precoders
            intW = obj.precoder(:, obj.interferer);
            % get interfering analog precoders
            intWa = obj.precoderAnalog(obj.interferer);

            %% calculate interference enhancement theta
            %NOTE: there is only one channel realization per slot, so
            %the time index for the channel is not considered yet
            timeH = 1;

            for iRB = 1:obj.nRBscheduled
                %NOTE: in the LTE-A simulator, there was an additional sum
                %over all users at each interferer. This should not be
                %necessary here as long as not more than one user is
                %scheduled per resource block

                % get frequency index of current resource block
                iFreq = obj.receiver.scheduling.iRBFreq(iRB);

                % performing the memory access outside of the loop is much faster
                F = obj.receiveFilter(:,:,iRB);

                for iInt = 1:obj.nInt
                    %NOTE: most of the simulation time is spent with
                    %this, any improvement in efficiency here pays off
                    % the sum is over all layers at the interferer
                    theta(:,iRB,iInt) = sum(abs(F * intH(1,iInt).H(:,:,timeH,iFreq) * intWa(iInt).W_a * intW(iRB,iInt).W).^2,2);
                end % for all interferering antennas
            end % for all scheduled resource blocks
        end

        function successiveInterferenceCancellation(obj, psi, xi, zeta, theta, iniPower_)
            % set sicInterference and perform SIC where it is necessary
            % This function performs SIC and sets the sicInterference
            % property for NOMA and OMA users. The sicInterference is 0 for
            % OMA users.
            % For NOMA near users that perform SIC, this function decodes
            % the signal of the far NOMA user received by the near NOMA
            % user and determines if SIC was successful and sets the
            % sicInterference property.
            %
            % input:
            %   psi:        [nLayer x nRBscheduled x nDes]double noise enhancement
            %   xi:         [nLayer x nRBscheduled x nDes]double inter-layer interference
            %   zeta:       [nLayer x nRBscheduled x nDes]double power fraction between 0 and 1
            %   theta:      [nLayer x nRBscheduled x nInt]double interference enhancement
            %   iniPower_:	[nLayer x nRBscheduled x nAnt]double inter numerology interference
            %
            % OMA:  Orthogonal Multiple Access = regular transmisssions
            % NOMA: Non-Orthogonal Multiple Access
            % SIC:  Successive Interference Cancellation
            %
            % see also linkQualityModel.LinkQualityModel.sicInterference,
            % parameters.Noma,
            % scheduler.signaling.UserScheduling.nomaPowerShare

            % get NOMA settings
            nomaPowerShare	= obj.receiver.scheduling.nomaPowerShare;
            epsilon         = 1; % full interference power from other user

            % perform SIC for NOMA near users
            if nomaPowerShare(1) < 0.5 % SIC needs to be performed
                %NOTE: it is assumed that SIC is performed on all resource
                %blocks if SIC is performed. Thus, it is sufficient to
                %check the nomaPowerShare on the first layer to find out if
                %this is a NOMA near user.

                % perform SIC
                % overwrite sicInterference for first step of SIC
                % sum power over desired antennas
                obj.sicInterference = nomaPowerShare .* sum(obj.rxPowerW(:,:,obj.desired),3);
                % calculate SINR for signal of other user
                SINR = obj.calculatePostEqualizationSinr(psi, xi, zeta, theta, obj.rxPowerW, 1-nomaPowerShare, iniPower_);

                % set power share to zero if SIC was unsuccessful
                if obj.failureSic(SINR)
                    obj.receiver.scheduling.nomaPowerShare = zeros(obj.nLayer, 1);
                end

                % set interference cancellation factor
                epsilon = obj.nomaInterferenceFactor;
            end % if this is a NOMA near user that performs SIC

            % set additional noise from other SIC user - sum power over desired antennas
            %NOTE: for OMA users nomaPowerShare is 1 and sicInterference is
            %0. For NOMA far users epsilon=1, i.e. no interference is
            %cancelled.
            obj.sicInterference = epsilon .* (1-nomaPowerShare) .* sum(obj.rxPowerW(:,:,obj.desired),3);
        end

        % getter and setter functions
        function setInterferers(obj, newInterferers, isInterfering)
            % setter function for interferer property, updates nInt
            % Sets the interferers indicated by newInterferers to
            % isInterfering and updates nInt to the new number of
            % interferers.
            %
            % input:
            %   newInterferers: [1 x nInterferers]logical indices for which
            %                   the interferer status should be changed
            %   isInterfering:  [1x1]logical interference status to set
            %                   true if interferers indicated by
            %                   newInterferers should be set as interferers
            %                   false if interferers indicated by
            %                   newInterferers should be set as non
            %                   interference
            %
            % set properties: interferer, nInt

            % set the new interferers to their new status
            obj.interferer(newInterferers) = isInterfering;

            % find antennas with same subcarrier spacings
            sameScs = [obj.antenna.numerology] == obj.receiver.numerology;

            % all interferer that have different subcarrier spacing are numerology interferers
            obj.numerologyInterferer = obj.interferer & ~sameScs;

            % update the number of interferers
            obj.nInt = sum(obj.interferer);
            % check that no desired antenna is set as interferer
            if any(obj.desired & obj.interferer) && any(~obj.interferer)
                %NOTE: the second statement makes sure that if the
                %interferers are reset to all interfering the warning is
                %not thrown
                warningMessage = 'Some antennas are set as interferers and desired signal at the same time, this is not possible.';
                warning('warning:desiredInterferer', warningMessage);
            end
        end

        function nDes = get.nDes(obj)
            % getter function for nDes, the number of desired antennas
            %
            % output:
            %   nDes:   [1x1]integer number of desired antennas
            %
            % used properties: desired

            % nDes is the total number of desired antennas
            nDes = sum(obj.desired);
        end

        function c = copy(obj, c)
            % Perform a shallow copy of the object
            %
            % input:
            %   c: [1x1]linkQualityModel.LinkQualityModel copied object
            %
            % ouput:
            %   c: [1x1]linkQualityModel.LinkQualityModel copied object

            c.receiver                  = obj.receiver.copy();
            c.desired                   = obj.desired;
            c.nInt                      = obj.nInt;
            c.nAnt                      = obj.nAnt;
            c.channel                   = obj.channel;
            c.noise                     = obj.noise;
            c.sicInterference           = obj.sicInterference;
            c.macroscopicFadingW        = obj.macroscopicFadingW;
            c.nLayer                    = obj.nLayer;
            c.powerRB                   = obj.powerRB;
            c.rxPowerW                  = obj.rxPowerW;
            c.isActive                  = obj.isActive;
            c.precoder                  = obj.precoder;
            c.precoderAnalog            = obj.precoderAnalog;
            c.receiveFilter             = obj.receiveFilter;
            c.resourceGrid              = obj.resourceGrid;
            c.calculateIni              = obj.calculateIni;
            c.iniCache                  = obj.iniCache;
            c.antenna                   = obj.antenna;
            c.antennaBsMapper           = obj.antennaBsMapper;
            c.interferer                = obj.interferer;
            c.numerologyInterferer      = obj.numerologyInterferer;
            c.blerCurves                = obj.blerCurves;
            c.layerMapping              = obj.layerMapping;
            c.nomaInterferenceFactor	= obj.nomaInterferenceFactor;
            c.indexRB                   = obj.indexRB;
            c.nRBscheduled              = obj.nRBscheduled;
        end
    end

    methods (Access = protected, Hidden = true)
        function initInterferers(obj)
            % sets interferers and filters out the desired antennas
            %   This function initializes interferer to all antennas that
            % are not desired.
            %
            % used properties: antenna
            %
            % set properties: desired
            %
            % calls setInterferers

            % set all antennas as non interferers
            obj.interferer = false(1, obj.nAnt);
            obj.numerologyInterferer = false(1, obj.nAnt);

            % set all antennas, that are not desired signal as interferers
            obj.setInterferers(~obj.desired, true);
        end

        function setAntenna(obj, antenna)
            % set antenna and nAnt
            % Sets antenna, the array with all antennas and the total
            % number of antennas.
            %
            % input:
            %   antenna:    [1 x nAnt]handleObject all antennas in the simulation
            %
            % set properties: antenna, nAnt

            % set antenna array
            obj.antenna = antenna;

            % set total number of antennas according to antenna array
            obj.nAnt = length(obj.antenna);
        end

        function filterInactiveInterferers(obj)
            % removes antennas that are not scheduled in this slot from interferers
            % This function resets the interferer array to all interferers
            % and then filters out the desired antennas and the antennas
            % that are not scheduled in this slot.
            %
            % used properties: nAnt, isActive, desired
            %
            % set properties: properties set in setInterferers

            % reset interferers - set all antennas as interferers
            obj.setInterferers(true(1, obj.nAnt), true);

            % adds desired antennas to non interferer array
            nonInterferer = ~obj.isActive | obj.desired;

            % removes non interfering antennas from interferer array
            obj.setInterferers(nonInterferer, false);
        end

        function psi = getNoiseEnhancement(obj)
            % calculate noise enhancement
            % The noise enhancement is the power of the receive filter.
            %
            % output:
            %   psi:    [nLayer x nRBscheduled x nDes]double noise enhancement
            %
            %NOTE: in this function nLayer always refers to the number of
            %layers used by the desired transmit antennas, which is assumed
            %to be the same for all desired transmit antennas.

            % initialize
            psi  = zeros(obj.nLayer, obj.nRBscheduled, obj.nDes);
            % calculate noise enhancement - sum over receive antennas nRX
            psi(:,:,:) = sum(abs(obj.receiveFilter).^2,2);
        end

        function iniPower = getIniPower(obj)
            % Calculates inter-numerology interference power.
            % NOTE: It is assumed that the RB grid of the desired and the
            % interfering antennas are of same size.
            %
            % output:
            %   iniPower: [nLayer x nRBScheduled x nAnt] INI power for all
            %   scheduled resource blocks
            %
            % initial author: Alexander Bokor

            % INI power in scheduled resource blocks
            iniPower = zeros(obj.nLayer, obj.nRBscheduled, obj.nAnt);

            % query ini antennas
            iniAntennaIndices = 1:obj.nAnt;
            iniAntennaIndices = iniAntennaIndices(obj.numerologyInterferer);

            % ini calculations can be skipped if no interferer are present
            if isempty(iniAntennaIndices) || ~obj.calculateIni
                return;
            end

            % numerology of the desired antenna
            numDes = obj.antenna(obj.desired).numerology;
            globalIniPower = zeros(obj.nLayer, obj.resourceGrid.nRBFreq, obj.resourceGrid.nRBTime);

            for iAnt = iniAntennaIndices
                % numerology of the interfering antenna
                interferingAnt = obj.antenna(iAnt);
                numInt = interferingAnt.numerology;

                % get inter-numerology interference factors from cache
                iniFactors = obj.iniCache.getFactors(numInt, numDes);

                % power of the interfering RBs
                % layers are concatenated to seconds dimension
                % [nRBFreq x nRBTime * nLayer]double
                interfererPower = reshape(permute(obj.powerRB(:, :, :, iAnt), [2,3,1]), obj.resourceGrid.nRBFreq, obj.resourceGrid.nRBTime * obj.nLayer);

                % calculate interference over all RBs and layers in one step
                allIniPower = iniFactors * interfererPower / obj.resourceGrid.nSubcarrierRb(numDes);

                % Undo concatenation of layers in second dimension
                % [nLayer x nRBFreq x nRBTime]double
                allIniPower = permute(reshape(allIniPower, obj.resourceGrid.nRBFreq, obj.resourceGrid.nRBTime, obj.nLayer), [3, 1, 2]);

                % interference for all resource block (also unscheduled)
                globalIniPower = globalIniPower + allIniPower;
                % only save interference of the scheduled RBs
                iniPower(:, :, iAnt) = allIniPower(:, obj.indexRB);
            end

            obj.interNumerologyInterference = globalIniPower;
        end

        function setIsActive(obj)
            % Sets the isActive indicator depending on user allocation and
            % isActive flag of the antenna
            %
            % see also: linkQualityModel.LinkQualityModel.updateSmallScale

            obj.isActive = [obj.antenna.alwaysOn];
            if any(~obj.isActive)
                antGrids = [obj.antenna(~obj.isActive).rbGrid];
                antAlloc = cat(3,antGrids.userAllocation);
                indAlloc = any(antAlloc>0,[1,2]);
                obj.isActive(~obj.isActive) = reshape(indAlloc,1,[]);
            end % if any transmitters are not alwaysOn
        end

        function setScheduling(obj)
            % Set scheduling information from receiver scheduling object
            % to LQM.
            % see also: linkQualityModel.LinkQualityModel.updateSmallScale
            %
            % initial author: Alexander Bokor

            obj.indexRB         = obj.receiver.scheduling.assignedRBs;
            obj.nRBscheduled	= obj.receiver.scheduling.nRBscheduled;
            obj.nLayer          = obj.receiver.scheduling.nLayer;
        end

        function setPower(obj)
            % updates all transmit powers for this slot
            % This function replicates the power for all layers of the
            % desired link and divides the power by the number of layers to
            % keep the correct total power.
            %
            % used properties: (incomplete list)
            %   antenna:    [1 x nAnt]handleObject transmit antenna
            %       -rbGrid:    [1x1]struct with scheduling information
            %           powerAllocation:    [nRBFreq x nRBTime]double transmit power for each resource block
            %
            % set properties: rxPowerW, powerRB
            %
            %NOTE: the power for all resource blocks powerRB is saved so it
            %can be reused in the feedback

            % initialize power arrays
            obj.rxPowerW	= zeros(obj.nLayer, max(1,obj.nRBscheduled), obj.nAnt);
            obj.powerRB     = zeros(obj.nLayer, obj.resourceGrid.nRBFreq, obj.resourceGrid.nRBTime, obj.nAnt);

            % extract scheduling information for all antennas
            for iAnt = 1:obj.nAnt
                % distribute received power evenly over all layers
                power = obj.macroscopicFadingW(iAnt) ./ obj.nLayer .* squeeze(obj.antenna(iAnt).rbGrid.powerAllocation(obj.antennaBsMapper.antennaBsMap(iAnt, 4),:,:));
                for iLayer = 1:obj.nLayer
                    obj.powerRB(iLayer,:,:,iAnt)	= power;
                    if obj.nRBscheduled
                        obj.rxPowerW(iLayer,:,iAnt) = power(obj.indexRB);
                    end
                end
            end
        end

        function setPrecoder(obj)
            % extracts digital precoders for the scheduled resource blocks
            % from the scheduling information and sets analog precoder for
            % all antennas
            %
            % used properties:
            %   antenna:    [1 x nAnt]handleObject transmit antenna
            %       -rbGrid:    [1x1]struct with scheduling information
            %           precoder:    [nRBFreq x nRBTime]struct precoder for each resource block
            %               -W: [nTX x nLayers]complex precoder used for this resoucre block
            %
            % set properties:
            %   precoder:       [nRBscheduled x nAnt]struct with different precoders
            %       -W: [nTX x nLayer]complex precoder for this resource block
            %   precoderAnalog:	[1 x nAnt]struct with analog precoder for each antenna
            %       -W_a:   [nTXelements x nTX]complex analog precoder

            % clear precoders from last slot
            obj.precoder = struct('W', []);
            obj.precoderAnalog = struct('W_a', []);

            % initialize precoders
            %NOTE: the max ensures that empty precoders are generated if
            %no RB is scheduled for this user
            obj.precoder(max(1,obj.nRBscheduled), obj.nAnt) = struct('W', []);
            obj.precoderAnalog(1:obj.nAnt) = struct('W_a', []);

            % set precoders for this slot
            for iAnt = 1:obj.nAnt
                if obj.nRBscheduled
                    % get all precoders for resource blocks this user is scheduled on and put them in a struct matrix
                    obj.precoder(:, iAnt) = obj.antenna(iAnt).rbGrid.getAntennaPrecoder(obj.antennaBsMapper.antennaBsMap(iAnt,4), obj.indexRB);
                end

                % get analog precoders and put them in a struct
                obj.precoderAnalog(iAnt).W_a = obj.antenna(iAnt).W_a;
            end % if any resource blocks are scheduled
        end

        function isFailure = failureSic(obj, sinr)
            % evaluates if the interference cancallation was a failure
            % Checks if far user signal can be decoded. If the far user
            % signal cannot be decoded the detection of the near user
            % signal will also fail.
            %
            % input:
            %   sinr: [nLayer x nRB]double sinr for the transmisison to cancel
            %
            % output:
            %   isFailure:  [1 x nRB]logical indicates if decoding of interference failed

            % initialize output
            isFailure = false;

            % get number of used codewords
            nCodeword = obj.receiver.scheduling.noma.nCodeword;

            % get layer mapping
            iLayer = obj.layerMapping.getMapping(nCodeword, obj.receiver.scheduling.nLayer);

            % get redundany version
            rv = obj.receiver.scheduling.HARQ.codewordRV;

            for iCodeword = 1:nCodeword
                % get SINR values for this codeword
                sinrCodeword = sinr(iLayer{iCodeword},:);

                % get CQI value for this codeword
                cqi = obj.receiver.scheduling.noma.CQI(iCodeword);

                % average SINR with sinrAverager and current CQI value
                effectiveSINR = obj.receiver.userFeedback.DL.sinrAverager.average(sinrCodeword(:)', cqi);

                % get BLER mapping from bler map
                bler = obj.blerCurves.getBler(effectiveSINR, cqi+1, rv(iCodeword));

                % make Bernoulli experiment to determine whether decoding was successful
                isFailure = isFailure | (rand() < bler);
            end % for all codewords
        end
    end
end

