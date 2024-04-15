classdef PredefinedPositions < parameters.user.Parameters
    %PREDEFINEDPOSITIONS places users on predefined positions
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.ue.User, networkGeometry.PredefinedPositions

    properties
        % positions of all users
        % [3 x nUsers]double (x;y;z)-user positions
        positions
    end

    properties (SetAccess = protected)
        % handle to the user generation function
        createUsersFunction = @parameters.user.PredefinedPositions.generatePredefinedPositions;
    end

    methods
        function obj = PredefinedPositions()
            % PredefinedPositions's constructor - calls superclass constructor

            obj = obj@parameters.user.Parameters();
        end

        function nUsers = getEstimatedUserCount(obj, ~)
            % Estimate the amount of users that will be generated.
            %
            % input: [1x1]parameters.Parameters
            % output: estimated number of users
            %
            % initial author: Alexander Bokor

            nUsers = size(obj.positions, 2);
        end
    end

    methods (Static)
        function newUsers = generatePredefinedPositions(userParameters, params, ~)
            % generatePredefinedPositions generates users on predefined positions
            % Creates user objects and sets initial position.
            %
            % input:
            %   userParameters:     [1x1]handleObject parameters.user.PoissonStreets
            %   params:             [1x1]handleObject parameters.Parameters
            %   simulationSetup:    [1x1]handleObject simulation.SimulationSetup
            %
            % output:
            %   newUsers:   [1 x nUser]handleObject networkElements.ue.User
            %
            % initial author: Lukas Nagel
            %
            % see also simulation.SimulationSetup.prepareSimulation,
            % networkElements.ue.User

            % get user positions
            userDistribution	= networkGeometry.PredefinedPositions(params.regionOfInterest, userParameters);
            locations           = userDistribution.getLocations;
            positions           = locations.locationMatrix;

            % get number of users
            nUser = size(positions, 2);

            %create user array
            newUsers(nUser) = networkElements.ue.User;

            % set user positions
            for uu = 1:nUser
                newUsers(uu).positionList      = zeros(3,params.time.nSlotsTotal);
                newUsers(uu).positionList(:,1) = [positions(1, uu); positions(2, uu); positions(3, uu)];
            end
        end
    end
end

