function Locations = example
% nodeDistributionExample is the example function for creating a node distribution
% This function shows the parameters to set for each node distribution
% type.
% This function first sets the ROI, then the GridParmaeters for each grid
% type and then calls the getLocations function. It also creates a
% figure to show the node distribution.
%
% output:
%   Locations:  [1x1]struct with positions of the grid elements
%       -locationMatrix:    [2 x nPositions]double positions of the placed
%                           network elements
%       -clusterCentres:    [2 x nClusters]double locations of the centres
%                           of the clusters for clustered distribution
%
%
% see also parameters.basestation.HexGrid,
% parameters.basestation.MacroOnBuildings,
% parameters.basestation.Poisson2D,
% parameters.basestation.PredefinedPositions,
% parameters.user.InterferenceRegion, parameters.user.GaussCluster,
% parameters.user.Poisson2D, parameters.user.PredefinedPositions,
% parameters.user.PoissonStreets, parameters.user.UniformCluster,
% networkElements.ue.User.generateStatic2D,
% networkElements.ue.User.generateStaticStreets,
% networkElements.ue.User.generateUniformCluster,
% networkElements.ue.User.generateGaussCluster,
% networkElements.ue.User.generatePredefinedPositions,
% networkElements.ue.User.generateInterferenceRegion,
% networkGeometry.GaussCluster, networkGeometry.HexagonalGrid,
% networkGeometry.ManhattanGrid, networkGeometry.ClusteredDistribution,
% networkGeometry.PredefinedPositions, networkGeometry.UniformCluster,
% networkGeometry.UniformDistribution, networkGeometry.NodeDistribution,
% networkGeometry.RectangularGrid,
% networkGeometry.InterferenceRegionUniform
%
% initial author: Agnes Fastenbauer

%% create ROI (rectangular)
roi = parameters.regionOfInterest.RegionOfInterest;
roi.xSpan = 1000;
roi.ySpan = 1000;
roi.zSpan = 100;
roi.origin2D = [10; 20];
roi.createInterferenceRegion;

%% set parameters for each distribution
%NOTE: uncomment the distribution to use

% % HexGrid
GridParameters = parameters.basestation.HexGrid;
GridParameters.interBSdistance = 240;
positionCreator = networkGeometry.HexagonalGrid(roi, GridParameters);

% % Poisson2D - base station and user
% GridParameters = parameters.basestation.Poisson2D;
% % GridParameters = parameters.user.Poisson2D;
% GridParameters.density = 20e-6;
% % or
% % GridParameters.nElements = 30;
% positionCreator = networkGeometry.UniformDistribution(roi, GridParameters);

% % PredefinedPositions - base station and user
% GridParameters = parameters.basestation.PredefinedPositions;
% % GridParameters = parameters.user.PredefinedPositions;
% GridParameters.positions = [-490:100:510, 250, -250; -480:100:520 -250, 250]; % creates position (1,1) (2,2) (3,3) (4,4) and (5,5)
% positionCreator = networkGeometry.PredefinedPositions(roi, GridParameters);

% GaussCluster
% GridParameters = parameters.user.GaussCluster;
% GridParameters.density          = 1e-5;
% % or
% % GridParameters.nElements = 30;
% GridParameters.clusterRadius    = 50;
% % or
% % GridParameters.clusterSize = [50;50];
% GridParameters.clusterDensity   = 5e-3;
% GridParameters.withFemto        = true;
% GridParameters.mu               = 0;
% GridParameters.sigma            = 1;
% positionCreator = networkGeometry.GaussCluster(roi, GridParameters);

% % UniformCluster
% GridParameters = parameters.user.UniformCluster;
% GridParameters.density          = 2e-5;
% % or
% % GridParameters.nElements = 30;
% GridParameters.clusterRadius    = 50;
% % or
% % GridParameters.clusterSize = [50;50];
% GridParameters.clusterDensity   = 1e-3;
% GridParameters.withFemto        = true;
% positionCreator = networkGeometry.UniformCluster(roi, GridParameters);

% node distribution function for which no network element creation function
% has been defined yet

% %% manhattan grid
% GridParameters = struct();
% GridParameters.streetWidth = 20;	% width of street
% GridParameters.xSize = 140;	        % x-size of buildings
% GridParameters.ySize = 80;          % y-size of buildings
% positionCreator = networkGeometry.ManhattanGrid(roi, GridParameters);

% %% rectangular grid
% GridParameters.xDistance = 50;  % horizontal distance between two network elements
% GridParameters.yDistance = 100;  % vertical distance between two network elements
% positionCreator = networkGeometry.RectangularGrid(roi, GridParameters);

%% hexagonal rings
% % rings of base stations
% GridParameters = parameters.basestation.HexRing;
% GridParameters.interBSdistance = 140;
% GridParameters.nRing = 2;
% positionCreator = networkGeometry.HexGridRing(roi, GridParameters);

%% create locations
Locations = positionCreator.getLocations();

%% create figure
hold on;
if isa(GridParameters, 'parameters.user.UniformCluster') || isa(GridParameters, 'parameters.user.GaussCluster')
    [vx, vy] = voronoi(Locations.clusterCentres(1,:), Locations.clusterCentres(2,:));
    %     hold off;
    for iV = 1:length(vx)
        p1 = tools.drawLine2D([vx(1,iV), vy(1,iV)], [vx(2,iV), vy(2,iV)], tools.myColors.matlabOrange);
        hold on;
    end
    p2 = scatter(Locations.locationMatrix(1,:), Locations.locationMatrix(2,:), 'LineWidth', 1, 'MarkerFaceColor', [0, 0.4470, 0.7410], 'MarkerEdgeColor', [0, 0.4470, 0.7410]);
    p3 = scatter(Locations.clusterCentres(1,:), Locations.clusterCentres(2,:), 'LineWidth', 3, 'MarkerFaceColor', tools.myColors.matlabRed, 'MarkerEdgeColor', tools.myColors.matlabRed);
    legend([p3 p2, p1], {'base station position', 'user position', 'cell edge'})
    placementRegion = roi;
elseif isa(GridParameters, 'parameters.user.InterferenceRegion')
    scatter(Locations.locationMatrix(1,:), Locations.locationMatrix(2,:), 'LineWidth', 5);
    roi.createInterferenceRegion;
    placementRegion = roi.interferenceRegion;
else
    [vx, vy] = voronoi(Locations.locationMatrix(1,:), Locations.locationMatrix(2,:));
    hold off;
    for iV = 1:length(vx)
        p1 = tools.drawLine2D([vx(1,iV), vy(1,iV)], [vx(2,iV), vy(2,iV)], tools.myColors.matlabOrange);
        hold on;
    end
    p2 = scatter(Locations.locationMatrix(1,:), Locations.locationMatrix(2,:), 'LineWidth', 1, 'MarkerFaceColor', tools.myColors.matlabRed, 'MarkerEdgeColor', tools.myColors.matlabRed);
    legend([p2 p1], {'base station position', 'cell edge'})
    placementRegion = roi.interferenceRegion;
    hold off
end

axis([placementRegion.xMin, placementRegion.xMax, placementRegion.yMin, placementRegion.yMax]);
xlabel('x');
ylabel('y');
grid off

end

