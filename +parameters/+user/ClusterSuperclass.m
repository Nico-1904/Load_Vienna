classdef ClusterSuperclass < parameters.user.Parameters
    %CLUSTERSUPERCLASS superclass for clustered distributions
    % Adding subclasses of these parameters to
    % parameters.Parameters.userParameters creates users with the indicated
    % properties in the simulation.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.user.GaussCluster, parameters.user.UniformCluster

    properties
        % density of the cluster centers in cluster per square meter
        % [1x1]double density of clusters in clusters per square meter
        density             = 0;

        % number of clusters to be placed
        % [1x1]integer number of clusters
        % This property is only used if density is set ot 0.
        nElements           = 0;

        % center coordinates of the clusters
        % [2xnElements] [x;y] coordinates
        % This property is only used if density is set ot 0.
        clusterCenters      = [];

        % radius of the cluster in m
        % [1x1]double radius of cluster in m
        clusterRadius       = 0;

        % x and y span of rectangular cluster in m
        % [2x1]double [x-span; y-span] of cluster in m
        % This property is only used if clusterRadius is set to 0.
        clusterSize         = 0;

        % user density in a cluster
        % [1x1]double density with which the users are placed in the cluster
        clusterDensity      = 0;

        % number of users in each cluster
        % [1x1]integer number of users to be placed in each cluster
        % This property is only used if clusterDensity is set to 0.
        %NOTE: network elements in a cluster that are outside of the ROI
        %are discarded, i.e. the number ofusers in a cluster can be smaller
        %than nClusterElements.
        nClusterElements	= 0;

        % height of users in interference region
        % [1x1]double position in z-coordinate of users
        height              = 1.5;

        % add femto base stations at cluster center
        % [1x1]logical if femto base stations should be generated
        withFemto           = true;

        % parameters for femto cells in cluster center
        % [1x1]handleObject parameters.basestation.PredefinedPositions
        % This creates omnidirectional antennas with default settings, if
        % withFemto is true.
        % The dafault values for this property are set in the class
        % constructor.
        %
        % see also parameters.basestation.PredefinedPositions,
        % parameters.basestation.antennas.Omnidirectional
        femtoParameters
    end

    methods
        function obj = ClusterSuperclass()
            %CLUSTERSUPERCLASS sets default parameters

            % call superclass constructor
            obj = obj@parameters.user.Parameters();

            % set default parameters for femto cells in cluster center
            obj.femtoParameters         = parameters.basestation.PredefinedPositions;
            obj.femtoParameters.antenna	= parameters.basestation.antennas.Omnidirectional;
            obj.femtoParameters.antenna.baseStationType = parameters.setting.BaseStationType.femto;
        end

        function nUsers = getEstimatedUserCount(obj, params)
            % Estimate the amount of users that will be generated.
            %
            % input: [1x1]parameters.Parameters
            % output: estimated number of users
            %
            % initial author: Alexander Bokor

            if obj.density == 0
                nClusters = obj.nElements;
            else
                proi = params.regionOfInterest.placementRegion;
                area = proi.xSpan * proi.ySpan;
                nClusters = area * obj.density;
            end

            if obj.clusterDensity == 0
                nUsers = obj.nClusterElements * nClusters;
            else
                nUsers = obj.getClusterArea() * obj.clusterDensity;
            end

            nUsers = ceil(nUsers * nClusters);
        end
    end

    methods(Access=private)
        function area = getClusterArea(obj)
            % Returns the area of one cluster
            if obj.clusterRadius == 0
                area = obj.clusterSize(1) * obj.clusterSize(2);
            else
                area = obj.clusterRadius^2 * pi;
            end
        end
    end
end

