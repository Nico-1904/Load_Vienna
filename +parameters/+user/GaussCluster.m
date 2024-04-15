classdef GaussCluster < parameters.user.ClusterSuperclass
    %GAUSSCLUSTER a parameter class for base stations with clustered antennas
    % Adding these parameters to parameters.Parameters.userParameters
    % creates users with the indicated properties in the simulation.
    % Defines a scenario for randomly placed base stations that have
    % clusters of users around them.
    %
    % initial author: Lukas Nagel
    %
    % see also networkGeometry.GaussCluster,
    % networkElements.bs.BaseStation, parameters.user.ClusterSuperclass

    properties
        % mean value of the Gauss distribution
        % [1x1]double mean value of Guassian distribution
        mu = 0;

        % standard deviation of the Gauss distribution
        % [1x1]double standard deviation of gaussian distribution
        sigma = 1;
    end

    properties (SetAccess = protected)
        % handle to the user generation function
        createUsersFunction = @parameters.user.GaussCluster.generateGaussCluster;
    end

    methods
        function obj = GaussCluster()
            % GaussCluster calls superclass constructor

            % call superclass constructor
            obj@parameters.user.ClusterSuperclass;
        end
    end

    methods (Static)
        function newUsers = generateGaussCluster(userParameters, params, ~)
            % creates users objects placed in Gauss clusters and sets initial position
            %
            % input:
            %   userParameters:     [1x1]handleObject parameters.user.GaussCluster
            %   params:             [1x1]handleObject parameters.Parameters
            %   simulationSetup:    [1x1]handleObject simulation.SimulationSetup
            %
            % output:
            %   newUsers:   [1 x nUser]handleObject networkElements.ue.User
            %
            % see also simulation.SimulationSetup.prepareSimulation,
            % networkGeometry.GaussCluster, networkElements.ue.User

            % get region in which to place users
            placementRegion = params.regionOfInterest.placementRegion;

            % create user positions
            positionCreator	= networkGeometry.GaussCluster(placementRegion, userParameters);
            locations       = positionCreator.getLocations();
            userPositions	= locations.locationMatrix;

            % get number of users
            nUser = size(userPositions, 2);

            % initialize users
            newUsers(1, nUser) = networkElements.ue.User;

            % set user positions
            for uu = 1:nUser
                % initialize position list
                newUsers(uu).positionList      = zeros(3, params.time.nSlotsTotal);
                % set position
                newUsers(uu).positionList(:,1) = [userPositions(1, uu); userPositions(2, uu); userParameters.height];
            end

            % set femto base station parameters for femto base station creation
            if userParameters.withFemto
                %NOTE: For this to work the users have to be generated
                %before the base stations, which is handled by
                %simulation.SimulationSetup.prepareSimulation
                userParameters.femtoParameters.positions        = locations.clusterCentres;
                userParameters.femtoParameters.positions(3,:)	= userParameters.femtoParameters.antenna.height;
                params.baseStationParameters('femtoInGaussClusterCenter') = userParameters.femtoParameters;
            end
        end
    end
end

