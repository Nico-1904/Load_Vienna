classdef PDPcontainer < tools.HiddenHandle
    % PDPcontainer handles the PDPtraces matrix.
    % PDPtraces contains the PDP channel traces for one chunk of slots.
    % PDPcontainer initializes the channel traces for a simulation by
    % generating and saving (or checking that they are in memory) the
    % traces for all possible antenna configurations in a simulation.
    % PDPcontainer saves the channel parameters that are constant over a
    % simulation, the parameters that change over slots (e.g. cell
    % association) must be updatet before each slot.
    %
    % initial author: Agnes Fastenbauer
    %
    % PDP: Power Delay Profile
    %
    % see also PDPchannelFactory, ChannelFactory,
    % parameters.SmallScaleParameters

    properties
        %% PDPtraces

        % matrix with channel traces needed in the current slot
        % [max(nRX) x max(nTXelements) x max(carrierNo) x max(channelModel) x max(numerology) + 1]cell
        % The cells contain a struct with the channel trace or are empty
        % when the trace is not needed in the current slot.
        %   -Trace:  [1x1]struct of channel trace with given antenna configuration
        %       H:                  [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complexDouble channel matrix
        %       nTXelements:        [1x1]double number transmit antennas
        %       nRX:                [1x1]double number receive antennas
        %       channelModel:	    [1x1]enum channel model see also parameters.setting.ChannelModel
        %       freqCarrier:        [1x1]double carrier frequency in Hz
        %       bandwidthHz:        [1x1]double carrier bandwidth in Hz
        %       userSpeed:          [1x1]double user speed
        %       correlatedFading:   [1x1]logical flag for correlated fading trace
        %       subcarrierSpacing:  [1x1]double subcarrier spacing
        %       symbolTimes:        [1 x nSampleRbTime]double times for block fading scenario
        % see also generateChannelMatrix for information on the channel traces.
        PDPtraces

        % starting position in the channel trace of the last channel read
        % [nTransmitter x nReceiver]integer index of the last returned channel matrix
        % This is to get correlated channel realizations in consecutive
        % slots.
        startPosition

        %% antenna configuration parameters

        % struct with arrays with the needed antenna configs
        % [1x1]object smallScaleFading.TraceConfiguration
        antennaConfigs = smallScaleFading.TraceConfiguration;

        %% parameters constant over whole simulation

        % flag for correlated fading
        % [1x1]logical t/f indicating correlaed fading
        % If correlatedFading is set to true the Rosa Zheng model will be
        % used for channel trace generation.
        correlatedFading = true;

        % OFDM symbol times for short block fading case
        % [1 x nSampleRbTime]double times for which a channel realization should be calulated
        % Should range from 0 to slotDuration.
        % Indicates the times for the short block fading.
        % This value is the time corresponding to the symbol indices
        % indicated in the class setup config as symbolTimes. When
        % symbolTimes is not specified in the Config, then this value is
        % set to 0 and one channel realization in time is calculated for
        % each resource block.
        % see also parameters.SmallScaleParameters.symbolTimes
        symbolTimes = 0;

        % number of slots the channel trace is long
        % [1x1]integer length of channel trace in slots
        traceLengthSlots = 1000;

        % length of a slot in seconds
        % [1x1]double duration in time of a slot in seconds
        slotDuration = 1e-3;

        % number of samples in frequency per resource block
        % [1x1]integer number of samples per resource block in frequency
        nSampleRbFreq = 1;

        % Resource grid parameters
        % [1x1]parameters.resourceGrid.ResourceGrid
        resourceGrid

        %% Implementation parameters

        % feedback verbosity level
        % [1x1]double amount of user feedback given
        % A verbosityLevel of 0 means the channel trace generation produces
        % no feedback for the user of the simulator. Every value above 0
        % means feedback is given for the status of the channel trace
        % generation. If no value is specified in the Config of the class
        % setup, then a default value of 1 is chosen and feedback is given
        % on the progress of channel trace generation and loading.
        verbosityLevel = 1;

        % foldername where the channel traces are saved
        % []string name of folder where channel traces are saved
        % The default folder, if no other folder is specified in the Config
        % of the class setup function is 'dataFiles/channelTraces/'
        pregenFFfileName = 'dataFiles/channelTraces/';

        % flag for regeneration of the channel traces
        % If set to true channel traces will be regenerated even if they
        % are already saved, if set to false channel traces will only be
        % generated if necessary.
        regenerateChannelTrace
    end

    properties (Hidden)
        % OFDM symbol indices for short block fading case
        % [1 x nSampleRbTime]integer time indices of OFDM symbols for which a channel realization is calculated
        % Can take all integer values from 1 to nSymbolSlot.
        % Indicates the subcarriers for the block fading, setting it to 1
        % generates a fast fading scenario.
        symbolTimesIndex = 1;
    end

    methods (Access = private)
        function Trace = loadTrace(obj, thisAntConf)
            % loads the trace for the given antenna configuration
            % from the location determined in getFilename.
            %
            % input:
            %   thisAntConf:    [1x1]handleObject smallscaleFding.TraceConfiguration
            %
            % calls getFilename
            %
            % output:
            %   Trace:  [1x1]struct of channel trace with given antenna
            %           configuration
            %       -H:                 [nRX x nTXelements x length(sybolTimes) x nSubcarrierSlot/fftSamplingInterval]complexDouble
            %                           channel matrix. For nSubcarrierSlot and
            %                           FFTsampling interval see also
            %                           smallScaleFading.ChannelFactory.
            %       -nTXelements:       [1x1]double number receive antennas
            %       -nRX:               [1x1]double number transmit antennas
            %       -channelModel:      [1x1]enum parameters.setting.ChannelModel channel model
            %                           see also parameters.setting.ChannelModel
            %       -freqCarrier:       [1x1]double carrier frequency in Hz
            %       -bandwidthHz:       [1x1]double carrier bandwidth in Hz
            %       -userSpeed:         [1x1]double user speed
            %       -correlatedFading:  [1x1]logical flag for correlated
            %                           fading trace
            %       -subcarrierSpacing: [1x1]double subcarrier spacing in Hz
            %       -symbolTimes:       [1 x nSampleRbTime]double times for block fading scenario

            filename = obj.getFilename(thisAntConf);
            if obj.verbosityLevel >= 1
                fprintf('Loading UE fast fading from %s. \n',filename);
            end
            try
                loadedFile = load(filename, 'Trace');
                Trace = loadedFile.Trace;
            catch err
                fprintf('Channel trace could not be loaded.(%s).\n',err.message);
            end
        end

        function setAntennaConfigs(obj, AntennaArray, UserArray)
            % extracts all antenna configurations for the simulation
            % Finds all possible combinations of antenna configurations for
            % the simulation, i.e. of
            % channelModel-nTXelements-nRX-Carrier-numerology-DopplerSpeed
            % combinations that can appear during the simulation.
            %
            % input:
            %   AntennaArray:   [1 x nAntenna]handleObject networkElements.bs.Antenna
            %   UserArray:    	[1 x nUser]handleObject networkElements.ue.User
            %
            % calls getUserParameters, getAntennaParameters
            %
            % set properties: antennaConfigs
            %
            % see also parameters.setting.ChannelModel, parameters.Carrier

            % get unique user parameters, antenna parameters and numerologies
            [userParams, userNumerologies]          = obj.getUserParameters(UserArray);
            [antennaParams, antennaNumerologies]    = obj.getAntennaParameters(AntennaArray);
            numerologies = unique([userNumerologies; antennaNumerologies]);
            nUserParam = size(userParams, 1);
            nAntennaParam = size(antennaParams, 1);
            nNumerology = size(numerologies, 1);

            % preallocate matrix for all configurations
            %   antConfMatrix:  [nAntConf x 8]double matrix with antenna configurations
            %       -[:,1]integer number of antennas in antenna array
            %       -[:,2]double carrier frequency in GHz
            %       -[:,3]double bandwidth in MHz
            %       -[:,4]integer carrier identification number
            %       -[:,5]integer number of antennas at the user
            %       -[:,6]integer number of channel model type
            %       -[:,7]double user speed in m/s
            %       -[:,8]integer numerology
            antConfMatrix = zeros(nUserParam*nAntennaParam, 8);

            % replicate user and antenna parameters to get all possible antenna configurations
            antConfMatrix(:,1:4) = repmat(antennaParams, nUserParam, 1);
            antConfMatrix(:,5:7) = repelem(userParams, nAntennaParam ,1);

            % remove duplicate antenna configurations
            antConfMatrix = unique(antConfMatrix, 'rows');

            % replicate for all numerologies
            nConfigurations = size(antConfMatrix, 1);
            numerologies = repelem(numerologies, nConfigurations);
            antConfMatrix = repmat(antConfMatrix, nNumerology, 1);
            antConfMatrix(:,8) = numerologies;

            % set antennaConfigs
            obj.antennaConfigs = smallScaleFading.TraceConfiguration.setTraceArray(antConfMatrix);
        end

        function [userParams, userNumerologies] = getUserParameters(~, UserArray)
            % collects the user information from the given users in a matrix
            % getUserParameters creates an array for all existing channel
            % models for all users, fills in the information of the
            % existing channelModel-nXX information and then removes all
            % entries in the array, that have not been used to return a
            % [nConfigs x 2] array with all possible user settings.
            %
            % input:
            %   UserArray:	[1 x nUser]handleObject users to extract information from
            %               used properties: channelModel
            %
            % output:
            %   userParams:         [nConfigs x 2]double user parameters
            %       -[:,1]integer number of antennas at the user
            %       -[:,2]integer number of channel model type
            %       -[:,3]double user speed in m/s
            %   userNumerologies:   [nNumerology x 1]integer different numerologies used
            %
            % see also parameters.setting.ChannelModel

            % get number of users
            nUser = length(UserArray);

            % initialize parameters array for all possible channel model types
            userParams = zeros(nUser, 3);
            userNumerologies = zeros(nUser, 1);

            % collect user parameters
            userParams(:, 1)        = [UserArray.nRX];
            userParams(:, 2)        = [UserArray.channelModel];
            userParams(:, 3)        = [UserArray.speed];
            userNumerologies(:, 1)  = [UserArray.numerology];

            % remove duplicate antenna configurations
            userParams = unique(userParams, 'rows');
            userNumerologies = unique(userNumerologies);
        end

        function [antennaParams, antennaNumerologies] = getAntennaParameters(~, AntennaArray)
            % collects the antenna information in a matrix
            % This function works similar to getUserParameters: all antenna
            % configurations are collected in a matrix, that is dimensioned
            % big enough to hold all possible combinations, then the
            % configurations, that are not used are removed, and finally
            % the duplicate antenna configurations are removed to return a
            % matrix with all antenna configurations that can appear during
            % the simulation.
            %
            % input:
            %   AntennaArray:   [1 x nAntenna]handleObject networkElements.bs.Antenna
            %                   used properties: nTXelements, usedCCs, nCC,
            %                   numerology
            %
            % output:
            %   antennaParams:          [nCarrier x 3]double carrier information
            %       -[:, 1] number of antennas in antenna array
            %       -[:, 2] carrier frequency in GHz
            %       -[:, 3] bandwidth in MHz
            %       -[:, 4] carrier identification number
            %   antennaNumerologies:    [nNumerology x 1]integer different numerologies used

            % get total number of antennas
            nAnt = length(AntennaArray);
            % get maximum number of component carriers used
            nCC = max([AntennaArray.nCC]);

            % initialize array to a size that can fit all possible combinations
            antennaParams = zeros(nAnt * nCC, 4);
            antennaNumerologies = zeros(nAnt * nCC, 1);

            for iAnt = 1:nAnt
                for iCC = 1:AntennaArray(iAnt).nCC
                    iConfig = (iAnt-1)*nCC + iCC;
                    antennaParams(iConfig, 1) = AntennaArray(iAnt).nTXelements;
                    antennaParams(iConfig, 2) = AntennaArray(iAnt).usedCCs(iCC).centerFrequencyGHz;
                    antennaParams(iConfig, 3) = AntennaArray(iAnt).usedCCs(iCC).bandwidthHz .* 1e-6;
                    antennaParams(iConfig, 4) = AntennaArray(iAnt).usedCCs(iCC).carrierNo;
                    antennaNumerologies(iConfig, 1) = AntennaArray(iAnt).numerology;
                end
            end

            % remove combinations that do not appear in this simulation
            antennaParams(antennaParams(:,1) == 0, :) = [];
            % remove duplicates of combinations
            antennaParams = unique(antennaParams, 'rows');
            antennaNumerologies = unique(antennaNumerologies);
        end
    end

    methods
        function obj = PDPcontainer()
            % PDPcontainer empty class constructor
            %
            % input: no input is required for the class constructor. This
            % is implemented to ease testing and using only parts of its
            % functionality.
            %
            % see also setPDPcontainer

            % initialization of antennaConfigs
            obj.antennaConfigs = smallScaleFading.TraceConfiguration;
        end

        function setPDPcontainer(obj, Parameters, resourceGrid)
            % setter for object properties taken from config
            % Sets the parameters that are constant for a simulation and
            % the resource grid for either uplink or downlink.
            %
            % input:
            %   Parameters:     [1x1]handleObject parameters.Parameters
            %       -time.slotDuration:  	[1x1]double length of a slot in s
            %       -smallScaleParameters:	[1x1]handleObject parameters.smallScaleParameters
            %                               see also parameters.smallScaleParameters
            %           traceLengthSlots, nSampleRbFreq, userSpeed,
            %           correlatedFading, symbolTimes, pregenFFfileName,
            %           regenerateChannelTrace
            %	resourceGrid:   [1x1]handleObject parameters.resourceGrid.ResourceGrid resource grid parameters
            %                   Here the uplink or downlink resource grid should be given to the PDPcontainer, it is
            %                   set as an input parameter to enable a distinction between uplink and downlink.
            %                   see also parameters.resourceGrid.ResourceGrid
            %       -subcarrierSpacingHz, nSymbolRb, nRBTime, nSubcarrierRb
            %
            % set properties: traceLengthSlots, slotDuration, resourceGrid,
            % nSampleRbFreq, correlatedFading, symbolTimes, verbosityLevel,
            % symbolTimesIndex, pregenFFfileName, regenerateChannelTrace,
            %

            % set trace length properties
            obj.traceLengthSlots	= Parameters.smallScaleParameters.traceLengthSlots;
            obj.slotDuration     	= Parameters.time.slotDuration;

            obj.resourceGrid = resourceGrid;

            % set simulation properties
            obj.correlatedFading 	= Parameters.smallScaleParameters.correlatedFading;

            % OFDM symbol indices for short block fading case
            if ~(isempty(Parameters.smallScaleParameters.symbolTimes) || all(Parameters.smallScaleParameters.symbolTimes == 1))
                obj.symbolTimesIndex    = Parameters.smallScaleParameters.symbolTimes;
                obj.symbolTimes         = (obj.symbolTimesIndex-1)*1/(resourceGrid.nSymbolRb_base * resourceGrid.nRBTime);
            end

            % set frequency sampling interval
            if ~isempty(Parameters.smallScaleParameters.nSampleRbFreq)
                obj.nSampleRbFreq = Parameters.smallScaleParameters.nSampleRbFreq;
            end

            % set folder in which traces are saved
            if ~isempty(Parameters.smallScaleParameters.pregenFFfileName)
                obj.pregenFFfileName = Parameters.smallScaleParameters.pregenFFfileName;
            end

            obj.regenerateChannelTrace = Parameters.smallScaleParameters.regenerateChannelTrace;

            % set software settings
            if ~isempty(Parameters.smallScaleParameters.verbosityLevel)
                obj.verbosityLevel = Parameters.smallScaleParameters.verbosityLevel;
            end
        end

        function generateTraces(obj, AntennaArray, UserArray)
            % generate and save channel traces for all trace configurations
            % Gets and sets all antenna configurations and then generates
            % and saves the channel traces that are not yet saved or that
            % should be regenerated. The channel traces are saved in the
            % folder indicated by the path set in pregenFFfileName.
            %
            % input:
            %   TransmitterArray: 	[1 x nAntenna]handleObject networkElements.bs.Antenna
            %   ReceiverArray:     	[1 x nUser]handleObject networkElements.ue.User
            %
            % calls setAntennaConfigs, getFilename

            % get all antenna configurations
            obj.setAntennaConfigs(AntennaArray, UserArray);

            for iAntConf = obj.antennaConfigs
                % get file name for channel trace with this configuration
                filename = obj.getFilename(iAntConf);
                % generate trace
                if obj.regenerateChannelTrace || ~exist(filename,'file')
                    % set up channel factory
                    ChannelFactory = smallScaleFading.PDPchannelFactory(obj.resourceGrid, iAntConf, obj);
                    % generate and save channel trace
                    ChannelFactory.generateChannelMatrix(filename);
                end
            end
        end

        function loadChannelTraces(obj, AntennaArray, UserArray)
            % loads traces into PDPtraces matrix
            % Loads all needed traces for all users and antennas in this
            % chunk.
            %
            % input:
            %   AntennaArray:   [1 x nAntenna]handleObject with all antennas
            %   UserArray:      [1 x nUser]handleObject array with all users

            % get all antenna configurations
            obj.setAntennaConfigs(AntennaArray, UserArray);

            % initialization of PDPtraces
            % [max(nRX) x max(nTXelements) x max(carrierNo) x max(channelModel) x max(numerology) + 1]
            obj.PDPtraces = cell(...
                max([obj.antennaConfigs.nRX]), max([obj.antennaConfigs.nTXelements]),...
                max([obj.antennaConfigs.carrierNo]), max([obj.antennaConfigs.channelModel]), ...
                max([obj.antennaConfigs.numerology] + 1));

            % initialize startPosition
            obj.startPosition = floor(rand(max([AntennaArray.id]), max([UserArray.id])) * obj.traceLengthSlots) + 1;

            % load channel traces and save in PDPtraces
            for iAntConf = obj.antennaConfigs
                obj.PDPtraces{...
                    iAntConf.nRX, iAntConf.nTXelements, ...
                    iAntConf.carrierNo, iAntConf.channelModel, ...
                    iAntConf.numerology + 1} = obj.loadTrace(iAntConf);
            end
        end

        function H = getH(obj, Receiver, Transmitter, iSlot, iCarrier, channelModel)
            % returns small scale fading for current time and given link
            % getH reads out the channel trace and then extracts one
            % channel realization from the trace according to the property
            % startPosition, that is randomly regenerated in
            % smallScaleFading.PDPcontainer.loadChannelTraces.
            %
            % input:
            %   Receiver:       [1x1]handleObject user equipment
            %   Transmitter:	[1x1]handleObject antenna of the link
            %   iSlot:          [1x1]integer index of current slot
            %   iCarrier:       [1x1]integer number of carrier of transmission
            %                   see also parameters.Carrier, parameters.Carrier.carrierNo
            %   channelModel:	[1x1]integer number of used channel model
            %                   see also parameters.setting.ChannelModel
            %
            % output:
            %   H:  [nRX x nTXelements x nTimeSamples x nFreqSamples]complex channel matrix H

            % read out channel trace for this link
            % [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complex
            channelTrace = obj.PDPtraces{Receiver.nRX, Transmitter.nTXelements, iCarrier, channelModel, Receiver.numerology + 1};

            % get the index in the channel trace
            tracePosition	= iSlot + obj.startPosition(Transmitter.id,Receiver.id);
            if tracePosition > obj.traceLengthSlots
                % if the random position is at the end of the channel
                % trace, it is possible that with the time position the
                % tracePosition exceeds the trace length, this is taken
                % care of here
                tracePosition = mod(tracePosition, obj.traceLengthSlots) + 1;
            end % if the index is bigger than the trace length

            % get channel matrix at position
            H = channelTrace.H(:,:,:,tracePosition,:);

            % remove singleton dimension of trace position
            H = reshape(H, [size(H,1), size(H,2), size(H,3), size(H,5)]);
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

            % set carrier
            Carrier = Transmitters(1).usedCCs(1);

            % read out channel matrix
            for iTransmitter = 1:nTransmitters
                smallScaleFading(1,iTransmitter).H =  obj.getH(Receiver, Transmitters(iTransmitter), iSlot, Carrier.carrierNo, uint32(Receiver.channelModel));
            end % for all transmit antennas
        end

        function filename = getFilename(obj, AntennaConfig)
            % returns the filename for the channel trace
            % The filename contains the settings for the number of transmit
            % antennas, the number of receive antennas, the channel model
            % type, the carrier frequency, the bandwidth, the constant user
            % speed, the subcarrier spacing, the use of correlated fading
            % according to the Rosa Zheng model and the symbol times for
            % short block fading. The FFT sampling interval, the slot
            % length and the trace length in slots is assumed to be
            % constant over all simulations.
            % The information on the parameter settings is hashed. This has
            % the advantage, that floating point values and the length of
            % the symbol times vector cannot create invalid filenames.
            %
            % see also tools.DataHash
            %
            % input:
            %   AntennaConfig:  [1x1]handleObject smallScaleFading.TraceConfiguration
            %
            % used properties: symbolTimes, pregenFFfileName,
            % correlatedFading, subcarrierSpacing
            %
            % output:
            %   filename:   []char string containing the whole filename
            %               including the folders starting in the main
            %               5G_simulator folder

            % build struct to be hashed - cast types to make sure same
            % settings result in the same struct

            % link parameters
            structtohash.nTXelements        = double(round(AntennaConfig.nTXelements, 0));
            structtohash.nRX                = double(round(AntennaConfig.nRX, 0));
            structtohash.channelModel       = round(double(AntennaConfig.channelModel), 0);
            structtohash.freqCarrierGHz     = double(round(AntennaConfig.freqCarrierHz*1e-9, 3));
            structtohash.bandwidthMHz       = double(round(AntennaConfig.bandwidthHz*1e-6, 3));
            structtohash.userSpeed          = double(round(AntennaConfig.speedDoppler, 4));
            structtohash.numerology         = double(round(AntennaConfig.numerology, 0));

            % time and trace parameters
            structtohash.symbolTimes        = double(round(obj.symbolTimes, 4));
            structtohash.correlatedFading   = round(double(obj.correlatedFading), 0);
            structtohash.subcarrierSpacing  = obj.resourceGrid.subcarrierSpacingHz_base;
            structtohash.nSampleRbFreq      = double(round(obj.nSampleRbFreq, 1));
            structtohash.traceLengthSlots	= double(round(obj.traceLengthSlots, 1));
            structtohash.slotDuration       = double(round(obj.slotDuration, 4));
            structtohash.nRBFreq            = obj.resourceGrid.nRBFreq;

            % create hash from struct with
            hash = tools.DataHash.DataHash(structtohash, struct('Format', 'hex', 'Method', 'SHA-1'));
            % create complete filename
            filename = strcat(obj.pregenFFfileName, hash, '.mat');
        end

        function plotChannelTrace(obj, nRX, nTX, channelModel, numerology, iRBFreq)
            % plot absolute vale and angle of channel trace for each channel coefficient
            % Plot channel trace for the given channel, numerology and
            % resource block.
            %
            % input:
            %   nRX:            [1x1]integer number of antennas at the user
            %   nTX:            [1x1]integer number of antennas at the base station
            %   channelModel:   [1x1]enum channel model
            %   numerology:     [1x1]integer 1...numerology
            %   iRBFreq:        [1x1]integer index of resource block for which to plot channel

            % PDPtraces: [max(nRX) x max(nTXelements) x max(carrierNo) x max(channelModel) x max(numerology) + 1]
            % H: [nRX x nTXelements x nTimeSamples x traceLengthSlots x nFreqSamples]complexDouble
            H = obj.PDPtraces{nRX, nTX, 1, channelModel, numerology}.H;

            for iRX = 1:nRX
                for iTX = 1:nTX
                    iPlot = (iRX-1)*2 + (iTX + iRX -2)*2 + 1;
                    subplot(2*nRX, nTX, iPlot);
                    plot(1:obj.traceLengthSlots, squeeze(abs(H(iRX,iTX,1,:,iRBFreq))));
                    xlabel('slot index');
                    y = sprintf('|H_{%i%i}|', iRX, iTX);
                    ylabel(y);
                    grid on;
                    subplot(2*nRX, nTX, iPlot + 1);
                    plot(1:obj.traceLengthSlots, squeeze(angle(H(iRX,iTX,1,:,iRBFreq))));
                    xlabel('slot index');
                    y = sprintf('arg(H_{%i%i})', iRX, iTX);
                    ylim([-pi, pi]);
                    yticks([-pi,-pi/2, 0, pi/2, pi]);
                    yticklabels({'\pi','\pi/2', '0', '\pi/2', '\pi'});
                    ylabel(y);
                    grid on;
                end
            end
        end
    end

    methods (Static)
        function Container = setupContainer(Parameters, BSs, UEs)
            % returns a Fading Trace Container for the given constellation
            % This function helps to quickly set up a container for small
            % scale fading traces.
            %
            % input:
            %   Parameters: [1x1]handleObject parameters.Parameters
            %   BSs:        [1 x nBaseStation]handleObject networkElements.bs.BaseStation
            %   UEs:        [1 xnUser]handleObject networkElements.ue.User
            %
            % initial author: Agnes Fastenbauer

            % set up small scale fading container
            Container = smallScaleFading.PDPcontainer;
            Container.setPDPcontainer(Parameters, Parameters.transmissionParameters.DL.resourceGrid);
            Container.generateTraces([BSs.antennaList], UEs);
            Container.loadChannelTraces([BSs.antennaList], UEs);
        end
    end
end

