classdef Poisson2D < parameters.basestation.Parameters
    %POISSON2D scenario with PPP distributed base stations.
    %
    % PPP: Poisson point process
    %
    % initial author: Lukas Nagel
    %
    % see also networkElements.bs.BaseStation

    properties
        % density of the base stations
        % [1x1]double density of base stations
        density = 0;

        % number of base stations
        % [1x1]integer number of base stations to place
        nElements = 0;
    end

    methods
        function obj = Poisson2D()
            % Poisson2D's constructor

            % call superclass constructor
            obj = obj@parameters.basestation.Parameters;
        end

        function newBaseStations = createBaseStations(obj, params, ~)
            % Create basestation network elements from this basestation
            % parameters.
            %
            % input:
            %   params:               [1 x 1]parameters.Parameters
            %   ~
            %
            % output:
            %   basestationList:      [1 x nBasestations]networkElements.bs.BaseStation
            %
            % see also networkGeometry.UniformDistribution

            % create positions
            positionCreator = networkGeometry.UniformDistribution(params.regionOfInterest.interferenceRegion, obj);
            locationStruct = positionCreator.getLocations();
            positions = locationStruct.locationMatrix;

            newBaseStations = obj.createBaseStationsCommon(positions,params);
        end

        function nBs = getEstimatedBaseStationCount(obj, params)
            % Estimate the amount of basestations.
            % Useful to estimate final result size.
            % input:  [1x1]parameters.Parameters
            % output: [1x1]double number of basestation
            %
            % initial author: Alexander Bokor
            if obj.density == 0
                nBs = obj.nElements;
            else
                proi = params.regionOfInterest.placementRegion;
                area = proi.xSpan * proi.ySpan;
                nBs = ceil(area * obj.density);
            end
        end

        function checkParameters(obj)
            % check base station parameters

            % check superclass parameters
            obj.checkParametersSuperclass;

            % check that only density or nElements is set
            if obj.density ~= 0 && obj.nElements ~= 0
                error('poissonSetting:double', 'The density and number of elements is set for poisson distributed base station. Please only set one parameter.');
            end
        end
    end
end

