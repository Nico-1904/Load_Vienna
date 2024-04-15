classdef ClusteredDistribution < networkGeometry.NodeDistribution
    %CLUSTEREDDISTRIBUTION superclass for clustered distribution of network elements
    %   Takes care of the distribution of cluster centres and serves as
    %   superclass for distributions within the clusters.
    %   The cluster centres distribution is a homogenous poisson point
    %   process with the option of setting a fix number of elements to
    %   distribute with the networkGeometry.UniformDistribution class.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkGeometry.NodeDistribution,
    % networkGeometry.UniformDistribution, networkGeometry.GaussCluster,
    % networkGeometry.UniformCluster

    properties
        %% cluster centre properties

        % density of the centres of clusters
        % [1x1]double average number of clusters per sq m
        centreDensity

        % positions of cluster centres
        % [2 x nCluster]double [x; y] positions of cluster centres
        clusterCentres

        %% cluster properties

        % density of elements within a cluster
        % [1x1]double average number of elements per sq m in each cluster
        clusterDensity

        % shape of the cluster
        % []char shape that the cluster has, can be 'round' or 'rectangular'
        % For rectangular shape clusterSize has to be set, for round shape
        % a clusterRadius has to be set.
        clusterShape

        % number of network elements in a cluster
        % [1 x nCluster]integer number of elements in each cluster
        % If nClusterElements is set in GridParameters, then the number of
        % elements is fixed for all clusters.
        %NOTE: network elements in a cluster that are outside of the ROI
        %are discarded.
        nClusterElements

        % length or radius of the cluster
        % [1x1]double size of the cluster
        % This parameter is set to clusterSize(1) for rectangular clusters
        % and to clusterRadius for round clusters.
        clusterSize1

        % width or angle of the cluster
        % [1x1]double size of the cluster
        % This parameter is set to clusterWidth for rectangular clusters
        % and to 2*PI for round clusters.
        clusterSize2
    end

    properties (Access = protected)
        % surface of the cluster
        % [1x1]double area of a cluster
        clusterArea
        % coordinates for ccordinate transform to place cluster elements around their centre
        % [2 x 1]double [x; y] coordinates to move cluster elements around centre
        cluster2zero
    end

    methods (Abstract)
        % get the locations of the network elements in all clusters
        clusterLocations = getClusterLocations(obj);
    end

    methods
        function obj = ClusteredDistribution(placementRegion, GridParameters)
            % class constructor for clustered distribution
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameter:      [1x1]handleObject parameters.user.UniformCluster/GaussCluster

            %call superclass contructor
            obj = obj@networkGeometry.NodeDistribution(placementRegion);

            % set centre density
            obj.centreDensity = GridParameters.density;

            % get centre locations
            if isempty(GridParameters.clusterCenters)
                CentreDistribution = networkGeometry.UniformDistribution(placementRegion, GridParameters);
                Locations = CentreDistribution.getLocations;
                obj.clusterCentres = Locations.locationMatrix;
            elseif GridParameters.density == 0 && GridParameters.nElements ~= 0
                obj.clusterCentres = GridParameters.clusterCenters;
                nCenters = size(obj.clusterCentres);
                if nCenters ~= GridParameters.nElements
                    error('error:missingSettings', 'Please set similiar number of cluster center coordinates and network elements.');
                end
            else
                error('error:missingSettings', 'Please set only fixed number of elements for fixed cluster centers.');
            end

            % set cluster properties
            if GridParameters.clusterRadius == 0 && length(GridParameters.clusterSize) == 2
                obj.clusterShape = 'rectangular';
                obj.clusterSize1 = GridParameters.clusterSize(1);
                obj.clusterSize2 = GridParameters.clusterSize(2);
                obj.clusterArea  = obj.clusterSize1 * obj.clusterSize2;
                obj.cluster2zero = 0.5 * [obj.clusterSize1; obj.clusterSize2];
            elseif GridParameters.clusterRadius ~= 0
                obj.clusterShape = 'round';
                obj.clusterSize1 = GridParameters.clusterRadius;
                obj.clusterSize2 = 2 * pi;
                obj.clusterArea  = pi * obj.clusterSize1^2;
                obj.cluster2zero = [0; 0];
            else
                error('error:missingSettings', 'Please specify a cluster size for clustered distribution.');
            end

            if GridParameters.clusterDensity ~= 0
                obj.clusterDensity = GridParameters.clusterDensity;
                obj.nClusterElements = poissrnd(obj.clusterDensity * obj.clusterArea, [1, size(obj.clusterCentres, 2)]);
            else
                obj.nClusterElements = GridParameters.nClusterElements * ones(1, size(obj.clusterCentres, 2));
            end
        end

        function Locations = getLocations(obj)
            % create locations of cluster elements and return cluster locations
            %
            % used properties: length, width, clusterCentres
            %
            % calls getClusterLocations
            %
            % output:
            %   Locations:  [1x1]struct with locations of network elements
            %       -locationMatrix:    [2 x nPositions]double array with
            %                           (x;y)-postitions of network elements
            %       -clusterCentres:    [2 x nClusters]double array with
            %                           (x;y)-postitions of cluster centres

            % get cluster locations
            clusterLocations = obj.getClusterLocations;

            % discard locations outside of ROI
            clusterLocations(:,(clusterLocations(1,:) > obj.xMax | clusterLocations(1,:) < obj.xMin)) = [];
            clusterLocations(:,(clusterLocations(2,:) > obj.yMax | clusterLocations(2,:) < obj.yMin)) = [];

            % set output
            Locations.clusterCentres = obj.clusterCentres;
            Locations.locationMatrix = clusterLocations;
        end
    end
end

