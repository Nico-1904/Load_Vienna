classdef InterferenceRegion < parameters.basestation.Parameters
    %InterferenceRegion places base stations in the interference region
    % Placement of BS in the interference region is done according to a
    % homogenous poisson point process with fixed number of elements which
    % is determined by the density property.
    % Use when BS are placed with predefined positions in the ROI
    % and additional BS outside of the ROI are needed for generating interference.
    %
    % initial author: Thomas Lipovec
    %
    % see also networkElements.bs.BaseStation,
    % networkGeometry.InterferenceRegionUniform

    properties
        % density of base stations in the infererence region in BS*km^(-2)
        % [1x1]double number of BS per km^2
        % Determines the number of BS to distribute in the interference
        % region.
        density = 2;

        % number of base stations to place in the interference region
        % [1x1]integer number of base stations
        nElements = 0;
    end

    methods (Access = protected)
        function nBs = caculateNumberOfBS(obj, params)
            %caculateNumberOfBS Calculates the number of BS according to
            %the density property
            % input:
            %   params:             [1 x 1]handleObject parameters.Parameters
            % output:
            %   nBs:                [1 x 1]integer number of base stations

            roi = params.regionOfInterest;
            roni = params.regionOfInterest.interferenceRegion;
            % area of interference region in m^2
            area = roni.xSpan*roni.ySpan - roi.xSpan*roi.ySpan;
            nBs = ceil(area*10^-6 * obj.density);
        end
    end

    methods
        function obj = InterferenceRegion()
            %InterferenceRegion Construct an instance of this class

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters();
        end

        function newBaseStations = createBaseStations(obj, params, ~)
            % createBaseStations Creates base stations in the interference region
            %
            % input:
            %   params:             [1 x 1]handleObject parameters.Parameters
            %
            % output:
            %   newBaseStations:   [1 x nBasestations]handleObject networkElements.bs.BaseStation
            %
            % initial author: Thomas Lipovec
            %
            % networkElements.bs.BaseStation

            % set number of base stations to create
            if obj.density ~= 0 && obj.nElements == 0
                obj.nElements = obj.caculateNumberOfBS(params);
            end

            % create BS positions
            GridParameters.nElements = obj.nElements;
            InterferenceRegionUniform = networkGeometry.InterferenceRegionUniform(params.regionOfInterest, GridParameters);
            locations = InterferenceRegionUniform.getLocations();
            positions  = locations.locationMatrix;

            % create BS objects
            newBaseStations = obj.createBaseStationsCommon(positions, params);
        end

        function nBs = getEstimatedBaseStationCount(obj, params)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor
            nBs = obj.caculateNumberOfBS(params);
        end

        function checkParameters(obj)
            %checkParameters Check base station parameters

            % check superclass parameters
            obj.checkParametersSuperclass;

            % check density
            if obj.density <= 0
                warningMessage = ['The density of interfering BS has to be greater than zero.' ...
                    ' The default value of two BS per square kilometer will be used instead.'];
                warning('warning:invalidSetting', warningMessage);
                obj.density = 2;
            end
        end
    end
end

