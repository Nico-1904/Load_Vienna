classdef OpenStreetMapCity < blockages.City
    % city layout based on OpenStreetMap data using longitude and latitude coordinates
    %
    % initial author: Christoph Buchner
    % extended by: Jan Nausner

    properties
        % [2x1]double (lower, upper) lower and upper limit of latitude for data extraction
        latitude

        % [2x1]double (lower, upper) lower and upper limit of longitude for data extraction
        longitude

        % [1x1]double width of the street
        streetWidth

        % [1x1]double minimal height limit of the random generated height
        minBuildingHeight

        % [1x1]double maximal height limit of the random generated height
        maxBuildingHeight

        % [1x1]double loss added to a path when intersecting with a wall of the building
        % in dB
        wallLoss
    end

    methods
        function obj = OpenStreetMapCity(cityParameter, interferenceRegion)
            % OpenStreetMapCity's constructor that builds the city according to
            % the parameters passed through cityParameter
            %
            % input:
            %   cityParameter:      [1x1]handleObject parameters.city.Manhattan
            %   interferenceRegion: [1x1]handleObject parameters.regionOfInterest.Region
            %                       region in which blockages are placed
            %
            % see also blockages.StreetSystem

            % call superclass constructor
            obj = obj@blockages.City(cityParameter, interferenceRegion);

            % set properties
            obj.streetWidth       = cityParameter.streetWidth;
            obj.minBuildingHeight = cityParameter.minBuildingHeight;
            obj.maxBuildingHeight = cityParameter.maxBuildingHeight;
            obj.longitude         = cityParameter.longitude;
            obj.latitude          = cityParameter.latitude;
            obj.wallLoss          = cityParameter.wallLossdB;

            if ~isempty(obj.loadFile)
                obj.loadCityFromFile();
            else
                % get data from the OpenStreetMap database
                osmDataList           = getOpenStreetMapData(obj);
                % save buildings
                obj = obj.saveOsmBuildingList2Obj(osmDataList([osmDataList.isBuilding]));
                % save streetsystem
                obj = obj.saveOsmStreetList2Obj(osmDataList([osmDataList.isStreet]));
            end

            if ~isempty(obj.saveFile)
                obj.saveCityToFile();
            end
        end
    end

    methods (Static)
        function city = getCity(cityParameter, params)
            % getCity generates the City according to cityParameters
            % The parameters needed are specified in parameters.city.OpenStreetMapCity.
            %
            % input:
            %   cityParameter:	[1x1]handleObject parameters.city.OpenStreetMap
            %   params:         [1x1]handleObject parameters.Parameters
            % output:
            %   city:           [1x1]handleObject blockages.OpenSteetMapCity
            %
            % see also parameters.city.OpenStreetMap

            % create city
            city = blockages.OpenStreetMapCity(cityParameter, params.regionOfInterest.interferenceRegion);
        end
    end

    methods (Access = private)
        function coordsMeter = convArc2Meter(obj, coordsArc)
            % converts latitude and longitude coordinates into meters
            %
            % input:
            %   coordsArc.lat: [1x1]double latitude coordinate
            %   coordsArc.lon: [1x1]double longitude coordinate
            %
            % output:
            %   coordsMeter.x: [1x1]double carthesian coordinate in meter
            %   coordsMeter.y: [1x1]double carthesian coordinate in meter

            % correction term for dependecie between lat and long
            avgLatCorr   = cos((obj.latitude(1) + (obj.latitude(2)-obj.latitude(1))*1/2 )*pi /180);

            coordsMeter.y = coordsArc.lat * pi /180 * parameters.Constants.RAD_EARTH;
            coordsMeter.x = coordsArc.lon .* avgLatCorr * pi /180 * parameters.Constants.RAD_EARTH;
        end

        function reCentered = reCenterLatLon(obj, coordsArc)
            % recenter the area around the latitude and longitude
            %
            % input:
            %   coordsArc.lat: [1x1]double latitude coordinate
            %   coordsArc.lon: [1x1]double longitude coordinate
            %
            % output:
            %   reCentered.lat: [1x1]double shifted latitude so that the center is at (0,0)
            %   reCentered.lon: [1x1]double shifted longitude so that the center is at (0,0)

            reCentered.lon = [coordsArc.lon] - obj.longitude(2) + (obj.longitude(2)-obj.longitude(1))*1/2;
            reCentered.lat = [coordsArc.lat] - obj.latitude(2) + (obj.latitude(2)-obj.latitude(1))*1/2;
        end

        function resStruct = result2Struct(~, res)
            % saves the result of the HTTP query inside a struct array
            % Converts a Openstreetmap data element to list of lat, lon and
            % type
            %
            % input:
            %   res [1x1]struct OpenStreetMap data elements
            %
            % output:
            %  resStruct.lat:   [1 x nNodes]double latitude  coordinate of one node
            %  resStruct.lon:	[1 x nNodes]double longitude coordinate of one node
            %  resStruct.type:	[1x1]string type of data element

            % check the tags if the actual data element is a street or a
            % buidling
            name = "";
            if ~isfield(res,'tags')
                isStreet = false;
                isBuilding = true;
            elseif isfield(res.tags,'highway')
                isStreet = true;
                isBuilding = false;
                if isfield(res.tags,'name')
                    name = res.tags.name;
                end
            else
                isStreet = false;
                isBuilding = true;
                if isfield(res.tags,'addr_street') && isfield(res.tags,'addr_housenumber')
                    name = res.tags.addr_street + " " + res.tags.addr_housenumber;
                end
            end
            resStruct = struct( 'isBuilding',isBuilding,'isStreet',isStreet,'name',name,'lat',[res.geometry.lat],'lon',[res.geometry.lon]);
        end

        function osmDataList = getOpenStreetMapData(obj)
            % This function is used to exract all the buildings and streets from a given area via
            % OpenStreetMap using the Overpass Api.
            %
            % output:
            %   osmDataList =  [nBuilding + nStreets x 1]struct with
            %                   type: []string specify type of result 'street' or 'building'
            %                   lat:  [nNodes x 1]double latitude coordinates of nodes on the element
            %                   lon:  [nNodes x 1]double longitude coordinates of nodes on the element
            %
            % see also: blockages.OpenStreetMapCity.saveOsmStreetList2Obj,
            % blockages.OpenStreetMapCity.saveOsmBuildingList2Obj,
            % blockages.OpenStreetMapCity

            lonMin = obj.longitude(1);
            lonMax = obj.longitude(2);
            latMin = obj.latitude(1);
            latMax = obj.latitude(2);

            % create query
            % create bounding box for query
            bBox=sprintf('%f,%f,%f,%f',latMin,lonMin,latMax,lonMax);
            % specify output format JSON max 5 MB max 3 min
            outFormat = sprintf('[out:json][maxsize:5242880][timeout:180][bbox:%s]',bBox);
            % specify displayed elements
            elements = 'rel[building]->.a;(way(r.a:"outer");way[building];way[highway];)';
            % specify result type
            resType = 'out geom';

            % combine options to query buildings
            queryText = sprintf('data=%s;%s;%s;',outFormat, elements, resType);
            query = matlab.net.QueryParameter(queryText);

            % create uri for http request
            uriText = 'https://overpass-api.de/api/interpreter';
            uri = matlab.net.URI(uriText,query);

            % create empty requestmessage and send to uri automatic GET
            r = matlab.net.http.RequestMessage;
            resp = r.send(uri);

            % if error occured throw error msg
            if ~isequal(resp.StatusCode,matlab.net.http.StatusCode.OK)
                resp.show()
                error('Error in OSM HTTP query msg : %s',resp.StatusLine);
            end

            % Extract JSon Data from HTTP Body
            % ways correspond to a collection of nodes which represents the object

            % parse result depending on type so that return value is always the
            % same
            if isa(resp.Body.Data.elements,'cell')
                osmDataList  = cellfun(@obj.result2Struct,resp.Body.Data.elements);
            else
                osmDataList = cellfun(@obj.result2Struct,num2cell(resp.Body.Data.elements));
            end
        end

        function obj = saveOsmBuildingList2Obj(obj,osmBuildingsList)
            % This function converts the BuildingsList ( lat lon nodes) of
            % each building inside the boundry into blockages.Building
            % object with a random height.
            %
            % Input:
            % osmBuildingsList [1x nBuilding]struct with
            %       lat: [1x1]double latitude coordinate of a building node
            %       lon: [1x1]double longitude coordinate of a building node
            %
            % see also: blockages.Building,
            % blockages.OpenStreetMapCity,
            % blockages.OpenStreetMapCity.getOpenStreetMapData

            % create buildings with random height
            if isempty(osmBuildingsList)
                warning('No Building in OpenStreetMap found');
                return
            end
            for ii = 1:length(osmBuildingsList)

                % recenter Coordinates so that (0,0) is in the middle
                reCentered=obj.reCenterLatLon(osmBuildingsList(ii));
                % convert to carthesian Coordinates
                coords=obj.convArc2Meter(reCentered);
                buildingpath = [coords.x;coords.y] + obj.origin2D;

                % create a random height for each building
                height = rand(obj.randomHeightStream)*(obj.maxBuildingHeight-obj.minBuildingHeight) + obj.minBuildingHeight;
                name = osmBuildingsList(ii).name;
                newBuilding = blockages.Building(buildingpath, height, obj.wallLoss, name);

                obj.buildings = [obj.buildings, newBuilding];
            end
        end

        function obj = saveOsmStreetList2Obj(obj, osmStreetList)
            % This function converts the StreetList ( lat lon nodes) of
            % each Street inside the boundry into blockages.StreetSystem
            % object.
            %
            % Input:
            % osmStreetList [1x nStreets]struct with
            %   	lat: [1x1]double latitude coordinate of a street node
            %   	lon: [1x1]double longitude coordinate of a street node
            %
            % see also: blockages.StreetSystem,
            % blockages.OpenStreetMapCity,
            % blockages.OpenStreetMapCity.getOpenStreetMapData

            if isempty(osmStreetList)
                warning('No Street in OpenStreetMap found');
                return
            end
            % get number of nodes which discribe  the streetsystem
            nStreetNodes = length([osmStreetList.lat]);

            % recenter coordinates so that (0,0) is in the middel
            reCentered       = obj.reCenterLatLon(osmStreetList);
            % convert to carthesian coordinates
            coords           = obj.convArc2Meter(reCentered);

            % initialise container for Streetsystem
            connectionMatrix = diag(ones(nStreetNodes - 1, 1), -1);  % specifies succesor of actual node
            locationMatrix   = [coords.x; coords.y] + obj.origin2D;  % specifies coordinates of node
            labels           = 1:nStreetNodes;                       % maps node from ConnectionMatrix to LocationMatrix

            % delete connection after end of a street

            k = length(osmStreetList(1).lat);
            for ii = 2:length(osmStreetList)
                connectionMatrix(k+1,k) = 0;
                k = k+length(osmStreetList(ii).lat);
            end

            % create the streetSystem object
            obj.streetSystem = blockages.StreetSystem(locationMatrix, ...
                connectionMatrix, labels, obj.streetWidth);
        end
    end
end

