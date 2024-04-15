classdef InterferenceRegionUniform < networkGeometry.NodeDistribution
    %InterferenceRegionUniform homogenous poisson point distribution of network elements
    %   Creates the positions of network elements in the interference
    %   region according to a homogenous poisson point process with fixed
    %   number of elements.
    %
    % see also networkGeometry.NodeDistribution
    %
    % author: Agnes Fastenbauer

    properties
        % number of elements to be uniformly distributed in the ROI
        % [1x1]integer number of network elements to be distributed
        nElements

        % factor how much the interference region is larger
        %[1x1]double interference region factor >= 1
        interferenceRegionFactor
    end

    methods
        function obj = InterferenceRegionUniform(ROI, GridParameters)
            % class constructor for uniform distribution
            %NOTE: the ROI is the Region Of Interest, not the Interference Region
            %
            %   ROI:            [1x1]handleObject parameters.RegionOfInterest
            %   GridParameter:  [1x1]struct with grid parameters
            %       -nElements: [1x1]integer number of network elements to spatially distribute

            % call superclass constructor
            obj = obj@networkGeometry.NodeDistribution(ROI);

            % set number of elements
            obj.nElements                   = GridParameters.nElements;
            obj.interferenceRegionFactor	= ROI.interferenceRegionFactor;
        end

        function Locations = getLocations(obj)
            % returns a struct with uniformly distributed locations in the interference region
            %
            % output:
            %   Locations:  [1x1]struct with locations
            %       -locationMatrix: [2 x nNetworkElements]double locations of network elements
            %                   locationMatrix(1, :) are the x-coordinates
            %                   locationMatrix(2, :) are the y-ccordinates

            % create coordinates in a rectangle with length and width of
            % the interference region (without the ROI)
            xArray = (rand([1, obj.nElements])-0.5) * (obj.xSpan *(obj.interferenceRegionFactor-1));
            yArray = (rand([1, obj.nElements])-0.5) * (obj.ySpan *(obj.interferenceRegionFactor-1));

            % transform to polar coordinates
            [theta, rho] = cart2pol(xArray, yArray);

            % In the next part the created positions are partinioned in 4
            % regions, where, if width = length, region1 contains all
            % locations with angles between -pi/4 and pi/4, region2 all
            % locations with angles between pi/4 and 3*pi/4 and so on. Then
            % the positions in each region are pushed to the interference
            % region by adding the distance between the point (0,0) and the
            % border of the ROI on the axis with angle theta of the point
            % being pushed to interference region.

            % get angles demarking the different regions
            alpha1 = atan(obj.ySpan/obj.xSpan);
            alpha0 = -1*alpha1;
            alpha2 = pi - alpha1;
            alpha3 = -1*alpha2;
            % get insdices of each region
            region1 = (theta > alpha0 & theta < 0) | (theta <= alpha1 & theta >= 0);
            region2 = theta > alpha1 & theta <= alpha2;
            region3 = theta > alpha2 | theta <= alpha3;
            region4 = theta > alpha3 & theta <= alpha0;
            % move points to outer interference region
            rho(region1) = rho(region1) + (obj.xSpan/2)./cos(       theta(region1));
            rho(region2) = rho(region2) + (obj.ySpan/2)./cos(pi/2  -theta(region2));
            rho(region3) = rho(region3) + (obj.xSpan/2)./cos(pi    -theta(region3));
            rho(region4) = rho(region4) + (obj.ySpan/2)./cos(3*pi/2-theta(region4));

            % retransform to cartesian coordinates
            [xArray, yArray] = pol2cart(theta, rho);
            % transpose to origin2D center
            xArray = xArray + obj.origin2D(1);
            yArray = yArray + obj.origin2D(2);
            % set output struct
            Locations.locationMatrix = [xArray; yArray];
        end
    end
end

