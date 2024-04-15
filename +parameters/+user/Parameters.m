classdef Parameters < tools.HiddenHandle & matlab.mixin.Heterogeneous
    %PARAMETERS superclass of all user scenario parameters
    % Default parmaeters for general user settings are set here.
    % Adding subclasses of these parameters to
    % parameters.Parameters.userParameters creates users with the indicated
    % properties in the simulation.
    %
    % initial author: Lukas Nagel
    % extended by: Christoph Buchner, added technology parameter
    % extended by: Areen Shiyahin, added traffic model parameters
    % extended by: Jan Nausner, added scheduling weight parameter
    % see also networkElements.ue.User

    properties
        % number of receive antennas of this user type
        % [1x1]integer number of receive antennas
        nRX = 1;

        % number of transmit antennas of this user type
        % [1x1]integer number of transmit antennas
        nTX = 1;

        % speed in meters per second of this user type
        % [1x1]double speed of user
        speed = 0;

        % how the users indoor outdoor property should be decided options
        % [1x1]enum parameters.indoorDecision
        %
        % see also parameters.indoorDecision
        indoorDecision = parameters.indoorDecision.Geometry();

        % how the users los nlos property should be decided options
        % [1x1]enum parameters.losDecision
        %
        % see also parameters.losDecision
        losDecision = parameters.losDecision.Geometry;

        % how the user-movement should be generated
        % [1x1]struct with user movement model parameters
        %   -type:  [1x1]enum parameters.setting.UserMovementType
        %
        % see also parameters.setting.UserMovementType
        userMovement

        % transmit power for this user type in Watt
        % [1x1]double transmit power in Watt
        transmitPower = 1;

        % receiver noise figure in dB for this user type
        % [1x1]double receiver noise figure in dB
        % 9 dB is the default value for UEs.
        %
        % see also parameters.Constants.NOISE_FLOOR,
        % networkElements.NetworkElementWithPosition.setThermalNoisePower
        rxNoiseFiguredB = 9;

        % channel model for this user type
        % [1x1]enum parameters.setting.ChannelModel
        channelModel = parameters.setting.ChannelModel.AWGN;

        % numerology supported by this user group
        % [1x1]integer numerology indicator 0 ... 5
        numerology = 0;

        % technology used for this NetworkElement
        % [1x1]enum parameters.setting.NetworkElementTechnology
        %
        % see also: simulation.ChunkSimulation.cellAssociation
        technology = parameters.setting.NetworkElementTechnology.LTE;

        % traffic models parameters for this user
        % [1x1]handleObject parameters.user.trafficModel.TrafficModel
        %
        % see also trafficModels.ConstantRate
        % trafficModels.FullBuffer
        trafficModel

        % list of possible traffic models for this user
        % [1x1]enum parameters.setting.TrafficModelType
        %
        % see also trafficModels.ConstantRate
        % trafficModels.FullBuffer
        % trafficModels.FTP
        % trafficModels.HTTP
        % trafficModels.VideoStreaming
        % trafficModels.Gaming
        % trafficModels.VoIP
        trafficModelType = parameters.setting.TrafficModelType.FullBuffer;

        % number of resources the user gets when scheduled with Round Robin
        % [1x1]integer
        schedulingWeight = 1;

        % indices of users created with this parameter set
        % [1 x nUser]integer indices of the realisations
        % where nUser is the number of users with this type of parameters.
        indices
    end

    properties (Abstract, SetAccess = protected)
        % function that generates the users in networkElements.ue.User
        createUsersFunction
    end

    methods (Abstract)
        % Estimate the amount of users that will be generated.
        %
        % input: [1x1]parameters.Parameters
        % output: estimated number of users
        %
        % initial author: Alexander Bokor
        nUsers = getEstimatedUserCount(obj, params)
    end

    methods
        function obj = Parameters()
            % empty class constructor for easy object construction
            %
            % For default values see properties in class file.

            %NOTE: this needs to be defined here in order to not overwrite
            %parameters from other user types
            obj.trafficModel = parameters.user.trafficModel.TrafficModel;

            obj.userMovement.type = parameters.setting.UserMovementType.ConstPosition;
        end

        function setIndices(obj, firstIndex, lastIndex)
            % setIndices sets the indices of the user realizations
            %
            % input:
            %   firstIndex: [1x1]integer index of first user created with this parameter set
            %   lastIndex:  [1x1]integer index of last user created with this parameter set
            %
            % set properties: indices

            obj.indices = firstIndex:1:lastIndex;
        end

        function copyPrivate(obj, old)
            % copies indices and user creation function handle
            %
            % input:
            %   old:    [1x1]handleObject parameters.user.Parameters

            % copy properties
            obj.createUsersFunction = old.createUsersFunction;
            obj.indices = old.indices;
        end

        function checkParameters(obj)
            % check user parameters

            obj.trafficModel.checkParameters;
        end
    end
end

