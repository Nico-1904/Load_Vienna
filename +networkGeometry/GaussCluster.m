classdef GaussCluster < networkGeometry.ClusteredDistribution
    %GAUSSCLUSTER cluster distribution with Thomas Cluster Process
    %   Creates a clustered distribution of points where the clusters are
    %   created with a homogenous poisson point process in the
    %   ClusteredDistribution class. Within the cluster the network
    %   elements are Gauss distributed for round or rectangular regions.
    %   The number of points in each cluster can be set to a fixed value or
    %   is calculated through a poisson random variable with the set
    %   density.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkGeometry.NodeDistribution,
    % networkGeometry.ClusteredDistribution, networkGeometry.UniformCluster

    properties
        % mean of the Gauss distribution
        % [1x1]double mean value of the distribution
        % For rectangular clusters the mean shifts the cluster elements
        % with the coordinate [mu; mu], for round clusters the mean pushes
        % the cluster elements away from the centre.
        mu

        % standard deviation of the Guass distribution
        % [1x1]double standard deviation of the distribution
        % For a standard deviation of zero all elements take the mean
        % value.
        sigma
    end

    methods
        function obj = GaussCluster(placementRegion, GridParameters)
            % class constructor for GaussCluster
            % Sets the mean an dthe standard deviation.
            %
            % input:
            %   placementRegion:	[1x1]handleObject parameters.RegionOfInterest.Region
            %   GridParameters:     [1x1]struct with grid parameters
            %       -mu:    [1x1]double mean value
            %       -sigma: [1x1]double standard deviation
            %
            % calls superclass constructor
            %
            % set properties: mu, sigma

            % call superclass constructor
            obj = obj@networkGeometry.ClusteredDistribution(placementRegion, GridParameters);

            % set distribution properties
            obj.mu = GridParameters.mu;
            obj.sigma = GridParameters.sigma;
        end

        function clusterLocations = getClusterLocations(obj)
            % creates locations for cluster elements
            % Gauss distributes network elements in each cluster.
            %
            % used properties: nClusterElements, clusterCentres,
            % clusterSize1, sigma, mu, clusterSize2
            %
            % output:
            %   clusterLocations:   [2 x totalClusterElements]double [x;y] cartesian coordinates of cluster elements

            % initialize clusterLocations vector
            clusterLocations = zeros(2, sum(obj.nClusterElements));

            % initialize cluster element counter
            iElement = 0;

            for iCluster = 1:size(obj.clusterCentres, 2)
                % Gauss distribute first coordinate: radius for round
                % cluster, x coordinate for rectangular cluster
                firstCoordinateArray = obj.clusterSize1 * obj.sigma * randn([1, obj.nClusterElements(iCluster)]) + obj.mu;

                % Distribute second coordinate
                % A distinction between rectangular and round clusters is
                % necessary because for polar coordinates the angle has to
                % be distributed and the coordinates have to be transformed
                % to cartesian coordinates
                if strcmp(obj.clusterShape, 'round')
                    % rond clusters
                    secondCoordinateArray = obj.clusterSize2 * rand([1, obj.nClusterElements(iCluster)]);
                    [xCoordinateArray, yCoordinateArray] = pol2cart(secondCoordinateArray, firstCoordinateArray);
                else
                    % rectangular clusters
                    xCoordinateArray = firstCoordinateArray;
                    yCoordinateArray = obj.clusterSize2 * obj.sigma * randn([1, obj.nClusterElements(iCluster)]) + obj.mu;
                end

                % Shift cluster coordinates to center them around the
                % cluster center
                xCoordinateArray = xCoordinateArray + obj.clusterCentres(1, iCluster) - obj.cluster2zero(1);
                yCoordinateArray = yCoordinateArray + obj.clusterCentres(2, iCluster) - obj.cluster2zero(2);

                % write elements in clusterLocations array
                clusterLocations(:, (iElement + 1):(iElement + obj.nClusterElements(iCluster))) = [xCoordinateArray; yCoordinateArray];

                % increment cluster element count
                iElement = iElement + obj.nClusterElements(iCluster);
            end % for all clusters
        end
    end
end

