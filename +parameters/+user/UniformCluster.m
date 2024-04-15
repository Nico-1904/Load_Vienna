classdef UniformCluster < parameters.user.ClusterSuperclass
    %UNIFORMCLUSTER places users in uniform circular clusters
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkElements.ue.User,
    % networkGeometry.ClusteredDistribution

    properties (SetAccess = protected)
        % handle to the user generation function
        createUsersFunction = @parameters.user.UniformCluster.generateUniformCluster;
    end

    methods
        function obj = UniformCluster()
            % class constructor - calls superclass constructor

            % call superclass constructor
            obj@parameters.user.ClusterSuperclass;
        end
    end

    methods (Static)
        function newUsers = generateUniformCluster(userParameters, params, ~)
            % creates users placed in uniform round clusters
            %
            % input:
            %   userParameters:     [1x1]handleObject parameters.user.UniformCluster
            %   params:             [1x1]handleObject parameters.Parameters
            %   simulationSetup:    [1x1]handleObject simulation.SimulationSetup
            %
            % output:
            %   newUsers:   [1 x nUser]handleObject networkElements.ue.User
            %
            % see also simulation.SimulationSetup.prepareSimulation,
            % networkElements.ue.User, networkGeometry.UniformCluster

            % get user positions
            placementRegion	= params.regionOfInterest.placementRegion;
            positionCreator	= networkGeometry.UniformCluster(placementRegion, userParameters);
            locations       = positionCreator.getLocations();
            positions       = locations.locationMatrix;

            % get number of users
            nUser = size(positions, 2);

            % initialize users
            newUsers(1, nUser) = networkElements.ue.User;

            % set user positions
            for uu = 1:nUser
                % initialize position list
                newUsers(uu).positionList      = zeros(3, params.time.nSlotsTotal);
                % set positions
                newUsers(uu).positionList(:,1) = [positions(1, uu); positions(2, uu); userParameters.height];
            end

            % set femto base station positions
            if userParameters.withFemto
                %NOTE: For this to work the users have to be generated
                %before the base stations, which is handled by
                %simulation.SimulationSetup.prepareSimulation
                userParameters.femtoParameters.positions = locations.clusterCentres;
                userParameters.femtoParameters.positions(3,:) = userParameters.femtoParameters.antenna.height;
                params.baseStationParameters('femtoInClusterCenter') = userParameters.femtoParameters;
            end
        end
    end
end

