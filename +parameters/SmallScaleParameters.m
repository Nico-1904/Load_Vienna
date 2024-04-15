classdef SmallScaleParameters < tools.HiddenHandle
    % SMALLSCALEPARAMETERS small scale fading parameters
    % Defines how the channel trace is generated.
    %
    % initial author: Lukas Nagel
    %
    % see also smallScaleFading, parameters.setting.ChannelModel,
    % parameters.user.Parameters.channelModel

    properties
        % flag indicating correlated fading
        % [1x1]logical correlated fading flag
        % true for correlated fading with Rosa Zheng parameters
        % false for uncorrelated fading
        % Calculate channel matrix for correlated fading according to
        % {
        % Yahong Rosa Zheng; Chengshan Xiao, "Simulation models with correct
        % statistical properties for Rayleigh fading channels,"
        % Communications, IEEE Transactions on , vol.51, no.6, pp. 920-928, June 2003
        % URL: http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=1209292&isnumber=27219
        % }
        correlatedFading        = true;

        % number of samples per resource block in frequency
        % [1x1]integer number of channel samples per resource block in frequency
        % This parameters indicates how often the channel changes within
        % the frequency bandwidth of a resource block. During the channel
        % trace generation one sample per subcarrier is calculated and
        % then all but nSampleRbFreq sample per resource block are
        % discarded.
        %NOTE: a value different of 1 is not useful yet, since the link
        %quality model cannot handle more than 1 channel value per RB.
        nSampleRbFreq           = 1;

        % Length of the trace in Slots
        % [1x1]integer length of trace in slots
        % Be wary of the size you choose, as it will be loaded in memory.
        traceLengthSlots        = 2000;

        % times for short block fading case
        % [1 x nSampleRbTime]double time at which a channel sample should be taken
        %
        %NOTE: a value different of 1 is not useful yet, since the link
        %quality model cannot handle more than 1 channel value per RB.
        symbolTimes             = 1;

        % regenerate channel trace
        % [1x1]logical flag for trace regeneration
        % true: channel traces are always generated
        % false: channel traces are only generated if there are none saved
        % in folder indicated by pregenFFfileName.
        regenerateChannelTrace  = false;

        % amount of feedback displayed to user during trace generation
        % [1x1]double feedback verbosity level
        % If this is set to <1 no feedback is given about the progress of
        % channel trace generation and loading, if this is a number >= 1,
        % textual progress reports are displayed in the command window
        % during the channel trace generation.
        verbosityLevel       	= 1;

        % folder in which channel traces are saved
        % []string name of folder for channel traces
        pregenFFfileName        = 'dataFiles/channelTraces/';
    end

    methods
        function checkParameters(obj, userParameters, baseStationParameters)
            % checks if parameters are coherent and possible with the simulator functionalities
            %
            % input:
            %   userParameters:         []containers.Map with parameters.user.Parameters
            %   baseStationParameters:  []containers.Map parameters.basestation.Parameters
            %
            % see also parameters.Parameters.checkParameters

            % check that no symbol times are set
            if obj.symbolTimes ~= 1
                warn = 'The LQM cannot handle more than 1 channel value per RB in time.';
                warning('warn:LQM', warn);
            end

            % check that channel realizations in frequency are compatible
            % with the LQM implementation
            if obj.nSampleRbFreq ~= 1
                warn = 'The LQM cannot handle more than 1 channel value per RB in frequency.';
                warning('warn:LQM', warn);
            end

            % check that channel trace exists
            if obj.traceLengthSlots <= 0
                warn = 'The trace lenth should be a rather big (at least 1000) positive value.';
                warning('warn:setting', warn);
            end

            % check that AWGN model is only used with SISO channels
            userKeys = userParameters.keys;
            nUserKey = length(userKeys);
            channelModels = zeros(1, nUserKey);
            for iUserKey = 1:nUserKey
                channelModels(iUserKey) = userParameters(userKeys{iUserKey}).channelModel;
            end

            if any(channelModels == parameters.setting.ChannelModel.AWGN) % if AWGN channel model is used
                nRX = zeros(1, nUserKey);
                nTX = zeros(1, nUserKey);
                for iUserKey = 1:nUserKey
                    nRX(iUserKey) = userParameters(userKeys{iUserKey}).nRX;
                    nTX(iUserKey) = userParameters(userKeys{iUserKey}).nTX;
                end

                if any(nRX > 1) || any(nTX > 1)
                    warnMessage = ['AWGN channel model can only be used for SISO transmission,'  ...
                        'some users have more than one transmit or receive antenna.'];
                    warning('warn:AWGNSISO', warnMessage);
                end

                bsKeys = baseStationParameters.keys;
                nBsKey = length(bsKeys);
                nTX = [];
                nRX = [];
                for iBsKey = 1:nBsKey
                    antennaParams = [baseStationParameters(bsKeys{iBsKey}).antenna];
                    nRX = [nRX, antennaParams.nRX];
                    nTX = [nTX, antennaParams.nTX];
                end

                if any(nRX > 1) || any(nTX > 1)
                    warnMessage = ['AWGN channel model can only be used for SISO transmission,'  ...
                        'some base station antennas have more than one transmit or receive antenna.'];
                    warning('warn:AWGNSISO', warnMessage);
                end
            end
        end
    end
end

