classdef Poisson2D < parameters.user.Parameters
    %POISSON2D configures a static user placement scenario according to a PPP
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.ue.User

    properties
        % density of the users in UE*m^(-2)
        % [1x1]double user density in users per square meter
        density = 0;

        % number of users
        % [1x1]integer number of user to be placed in the ROI
        % If density and nElements are set to a value other than 0, density
        % is used for user placement.
        % To use nElements as setting, make sure that density is set to 0,
        % otherwise the nElements property is overwritten.
        nElements = 0;

        % height of all users
        % [1x1]double user height for this user type
        height = 1.5;
    end

    properties (SetAccess = protected)
        % function handle that creates the users
        createUsersFunction = @parameters.user.Poisson2D.generateStatic2D;
    end

    methods
        function obj = Poisson2D()
            % Poisson2D's constructor

            % call superclass constructor
            obj = obj@parameters.user.Parameters();
        end

        function nUsers = getEstimatedUserCount(obj, params)
            % Estimate the amount of users that will be generated.
            %
            % input: [1x1]parameters.Parameters
            % output: estimated number of users
            %
            % initial author: Alexander Bokor
            if obj.density == 0
                nUsers = obj.nElements;
            else
                proi = params.regionOfInterest.placementRegion;
                area = proi.xSpan * proi.ySpan;
                nUsers = ceil(area * obj.density);
            end
        end
    end

    methods (Static)
        function newUsers = generateStatic2D(userParameters, params, ~)
            % generateStatic2D generates users according to a PPP in the region of interest
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
            % networkElements.ue.User, networkGeometry.UniformDistribution

            % get user positions
            placementRegion	= params.regionOfInterest.placementRegion;
            positionCreator	= networkGeometry.UniformDistribution(placementRegion, userParameters);
            locationStruct	= positionCreator.getLocations();
            positions       = locationStruct.locationMatrix;

            % get number of users
            nUser = size(positions, 2);

            % create users
            newUsers(1, nUser) = networkElements.ue.User;

            for uu = 1:nUser
                % set position
                newUsers(uu).positionList      = zeros(3,params.time.nSlotsTotal);
                newUsers(uu).positionList(:,1) = [positions(1, uu); positions(2, uu); userParameters.height];
            end
        end
    end
end

