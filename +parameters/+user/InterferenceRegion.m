classdef InterferenceRegion < parameters.user.Parameters
    %INTERFERENCEREGION places users in the interference region
    % The users in interference region are considered in cell association
    % and scheduling, but the LQM and LPM are not called for them. They
    % serve to create interference at the border.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkElements.ue.User

    properties
        % number of users in interference region
        % [1x1]integer number of interference region users
        nElements = 50;

        % height of users in interference region
        % [1x1]double position in z-coordinate of interference region users
        height = 1.5;
    end

    properties (SetAccess = protected)
        createUsersFunction % handle to the user generation function
    end

    methods
        function obj = InterferenceRegion()
            % InterferenceRegion's constructor

            % call superclass constructor
            obj = obj@parameters.user.Parameters();

            % set handle for user generation function
            obj.createUsersFunction = @parameters.user.InterferenceRegion.generateInterferenceRegion;

            % set constant parameters
            obj.indoorDecision = parameters.indoorDecision.Random(0.5);

        end

        function nUsers = getEstimatedUserCount(obj, ~)
            % Estimate the amount of users that will be generated.
            %
            % input:
            %   params: [1 x 1]handleObject parameters.Parameters
            % output:
            %   nUsers: [1 x 1]integer estimated number of users
            %
            % initial author: Alexander Bokor

            nUsers = obj.nElements;
        end
    end

    methods (Static)
        function newUsers = generateInterferenceRegion(userParameters, params, ~)
            % creates user objects in the interference region and sets initial position
            %
            % input:
            %   userParameters:     [1x1]handleObject parameters.user.PoissonStreets
            %   params:             [1x1]handleObject parameters.Parameters
            %   simulationSetup:    [1x1]handleObject simulation.SimulationSetup
            %
            % output:
            %   newUsers:   [1 x nUser]handleObject networkElements.ue.User
            %
            % initial author: Agnes Fastenbauer
            %
            % see also simulation.SimulationSetup.prepareSimulation,
            % networkElements.ue.User

            % check if interference region setting matches interference user creation
            if params.regionOfInterest.interference ~= parameters.setting.Interference.regionIndependentUser
                warning('warn:intReg', 'Interference users are placed in the interference region, even though they should not be.');
            end

            % get number of users to create
            nUser = userParameters.nElements;

            % get user locations
            userDistribution = networkGeometry.InterferenceRegionUniform(params.regionOfInterest, userParameters);
            locations = userDistribution.getLocations;
            positions = locations.locationMatrix;

            % initialize user array
            newUsers(nUser) = networkElements.ue.User;

            % set user properties
            for uu = 1:nUser
                newUsers(uu).positionList      = zeros(3,params.time.nSlotsTotal);
                newUsers(uu).positionList(:,1) = [positions(1, uu); positions(2, uu); userParameters.height];
            end
        end
    end
end

