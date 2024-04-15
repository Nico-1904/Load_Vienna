classdef PoissonStreets < parameters.user.Parameters
    %POISSONSTREETS creates users randomly and statically placed on streets
    % Places users randomly in streets defined in the scenario file.
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.ue.User, parameters.city.Parameters

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

        % height of users in interference region
        % [1x1]double position in z-coordinate of users
        height = 1.5;

        % name of the street system the users are placed
        % []string name of a street system list set in the scenario file
        streetSystemName = '';
    end

    properties (SetAccess = protected)
        % function handle to the placement function
        createUsersFunction = @parameters.user.PoissonStreets.generateStaticStreets;
    end

    methods
        function obj = PoissonStreets()
            % PoissonStreets's constructor
            obj = obj@parameters.user.Parameters();
        end

        function nUsers = getEstimatedUserCount(obj, params)
            % Estimate the amount of users that will be generated.
            %
            % input: [1x1]parameters.Parameters
            % output: estimated number of users
            %
            % initial author: Alexander Bokor

            % we do not know the streets yet. we will assume the worst case
            % street area = roi area

            proi = params.regionOfInterest.placementRegion;
            area = proi.xSpan * proi.ySpan;
            nUsers = ceil(area * obj.density);
        end
    end

    methods (Static)
        function newUsers = generateStaticStreets(userParameters, params, simulationSetup)
            % generateStaticStreets generates static users that are randomly placed on the streets of a given StreetSystem
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
            % see also networkElements.ue.User, blockages.StreetSystem

            % get street system in which to place users
            streetIndex     = simulationSetup.params.streetNameToIndexMapping(userParameters.streetSystemName);
            streetSystem	= simulationSetup.streetSystemList(streetIndex);

            % get user positions
            if userParameters.density ~= 0 && userParameters.nElements == 0
                nUser = poissrnd(userParameters.density * streetSystem.totalArea);
            else
                nUser = userParameters.nElements;
            end
            randomPositions	= streetSystem.getRandomPositions2D(nUser);

            % create users
            newUsers(1, nUser) = networkElements.ue.User;

            % set user positions
            for uu = 1:nUser
                newUsers(uu).positionList      = zeros(3,params.time.nSlotsTotal);
                newUsers(uu).positionList(:,1) = [randomPositions(1, uu); randomPositions(2, uu); userParameters.height];
            end
        end
    end
end

