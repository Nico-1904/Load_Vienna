classdef Parameters < tools.HiddenHandle & matlab.mixin.Heterogeneous
    %PARAMETERS superclass for base station placement scenarios
    % This is the superclass for the different placement methods for base
    % stations. It contains all parameters necessary for base station
    % creation.
    %
    % initial author: Lukas Nagel
    % extended by: Thomas Lipovec, Add new property nSectors
    %
    % see also parameters.basestation.GaussCluster,
    % parameters.basestation.HexGrid,
    % parameters.basestation.MacroOnBuildings,
    % parameters.basestation.Poisson2D,
    % parameters.basestation.PredefinedPositions,
    % parameters.basestation.antennas.Parameters,
    % parameters.setting.BaseStationType, networkGeometry.NodeDistribution,
    % networkElements.bs.BaseStation

    properties
        % antenna parameters
        % [1 x nAnt]handleObject parameters.basestation.antennas.Parameters
        antenna = parameters.basestation.antennas.Omnidirectional;

        % number of sectors at the basestation
        % [1x1]integer
        % For each sector a base station object will be created in the same
        % spot and equipped with sector antennas with different azimuth
        % according to the number of sectors.
        nSectors = 1;

        % baseband precoder parameters used for this base station
        % [1x1]struct with baseband precoder
        %   -DL:    [1x1]handleObject parameters.precoders.Precoder
        % see also parameters.precoders.Precoder
        precoder
    end

    properties (SetAccess = protected)
        % the indices of the realised base stations
        % [1 x nBS]integer indices of base stations of this type
        indices
    end

    methods (Abstract)
        % Estimate the number of base stations.
        % Useful to estimate final result size.
        % input:  [1x1]parameters.Parameters
        % output: [1x1]double number of basestation
        %
        % initial author: Alexander Bokor
        nBs = getEstimatedBaseStationCount(obj, params)

        % check parameters function
        checkParameters(obj)

        % Create basestation network elements from this basestation
        % parameters.
        %
        % input:
        %   params:               [1 x 1]parameters.Parameters
        %   buildingList:         [1 x nBuilding]blockages.Building
        %
        % output:
        %   basestationList:      [1 x nBasestations]networkElements.bs.BaseStation
        createBaseStations(obj, params, buildingList)
    end

    methods
        function obj = Parameters()
            obj.precoder = struct();
            obj.precoder.DL = parameters.precoders.LteDL;
        end

        function setIndices(obj, firstIndex, lastIndex)
            % setIndices sets the indices of the realised base stations
            %
            % input:
            %   firstIndex: [1x1]integer first index of base stations of this type
            %   lastIndex:  [1x1]integer last index of base stations of this type

            obj.indices = firstIndex:1:lastIndex;
        end

        function copyPrivate(obj, old)
            % copy old object to this object
            %
            % input:
            %   old:    [1x1]handleObject parameters.basestation.Parameters

            % copy class properties
            obj.indices                     = old.indices;
        end
    end

    methods(Static)
        function newBaseStations = convCompositeBSTech(newBaseStations)
            % This function converts a normal BS to a compositeBS splitting
            % the antennas based on the networkelementSplitter defined in
            % the composite BS class
            %
            % input:
            %   newBaseStations [1 x nBs] networkElements.bs.BaseStation
            % output:
            %   newBaseStations [1 x nBs] networkElements.bs.BaseStation or
            %                             networkElements.bs.compositeBsTyps.CompositeBsTech
            %
            % See also: networkElements.bs.compositeBsTyps.CompositeBsTech
            % networkElements.bs.CompositeBastation,
            nBs = size(newBaseStations,2);
            for iBS = 1:nBs
                actBS = newBaseStations(iBS);
                %call the creator for composite BS if neccessary
                technologies = unique([actBS.antennaList.technology]);
                nTech = size(technologies,2);

                numerology = unique([actBS.antennaList.numerology]);
                nNum = size(numerology,2);
                if nTech > 1 || nNum > 1
                    newBaseStations(iBS) = networkElements.bs.compositeBsTyps.CompositeBsTech(actBS);
                end
            end
        end
    end

    methods (Access = protected)
        function newBaseStations = createBaseStationsCommon(obj, positions, params)
            % creates copies of a Basestation specified by obj and
            % params and places them at the positions
            %
            % input:
            %   positions [2 x nPos]double spatial distribution of the BSs
            %   params    [1 x 1]parameters.Parameters
            %
            % output:
            %   newBaseStations [1x nBS]handle networkElements.BaseStation

            %remap to positionList
            positionList = obj.getPositionList(positions,params.time.nSlotsTotal);

            % create BS
            newBaseStations = obj.mapAntennasToBS(positionList, obj.antenna,params);

            % create baseband precoders
            precoderDL = obj.precoder.DL.generatePrecoder(params.transmissionParameters.DL, newBaseStations);

            for iBs = 1:length(newBaseStations)
                newBaseStations(iBs).precoder.DL = precoderDL;
            end

            % convert BS to compositeBSTech if neccessary
            newBaseStations = obj.convCompositeBSTech(newBaseStations);
        end

        function positionList = getPositionList(~,positions,nSlotsTotal)
            % This function generates a PositionList over time and space
            % maps the input positions based on a non moving BS assumption
            %
            % input:
            %   positions [2 x nPos]double positions
            %   nSlotsTotal [1 x 1 ]integer number of total slots
            %
            % output:
            %   positionList [3 x nSlotsTotal x nPos]double position of the
            %                                       BS over time and space
            %

            nPositions = size(positions, 2);
            % 2D to 3D space mapping if neccessary
            dimPositions = size(positions,1);
            if dimPositions == 2
                positionList = [positions;zeros(1,nPositions)];
            else
                positionList = positions;
            end
            % separate the two positions in an extra dimension
            positionList = reshape(positionList,3,1,[]);
            % assume not moving Antennas over all the slots
            % duplicate possitionList entries over time
            positionList = repmat(positionList, 1,nSlotsTotal ,1);
        end

        function newBaseStations = mapAntennasToBS(obj, positionList, ~, params)
            % This function is used to create duplicated BS as needed
            % with sector antennas where each sector antenna can be
            % seen as a separate BS
            %
            % input:
            %   positionList [2 x nSlots x nPos]double spatial and temporal distribution of the BSs
            %   antennas     [1 x 1]handle   parameters.basestation.antennas.Parameters
            %   params       [1 x 1]parameters.Parameters
            %
            % output:
            %   newBaseStations [1x nBS]handle networkElements.BaseStation
            nPositions = size(positionList,3);

            % number of BS per position
            nBSpPos = obj.nSectors;

            % get total number of base stations to create
            % for each position and each sector one basestation object will be created
            nBS = nPositions * nBSpPos;

            % preallocate base stations
            newBaseStations(nBS) = networkElements.bs.BaseStation;

            % create antennas and attach them to the basestations
            sectorSize = 360 / obj.nSectors;
            iBS = 1;
            for iPos = 1:nPositions
                for iAntConfig = 1:size(obj.antenna,2)
                    % antenna azimuth for first sector
                    azimuthInit = obj.antenna(iAntConfig).azimuth;
                    % create antenna for each sector and attach it to the basestation
                    for iSector = 1:obj.nSectors
                        % set azimuth of the sector antenna
                        obj.antenna(iAntConfig).azimuth = double(tools.wrapAngleTo180(azimuthInit + (iSector-1)*sectorSize));
                        % create antenna and attach it to the basestation sector
                        obj.antenna(iAntConfig).createAntenna(obj.antenna(iAntConfig),positionList(:,:,iPos),...
                            newBaseStations(iBS+iSector-1), params);
                    end % for all sectors
                    % restore initial azimuth of antenna configuration
                    obj.antenna(iAntConfig).azimuth = azimuthInit;
                end % for all antenna configurations
                iBS = iBS  + nBSpPos;
            end % for all positions
        end

        function checkParametersSuperclass(obj)
            % check superclass parameters
            % assert antenna prameters and inform user
            sameTechMat = [obj.antenna.technology] == [obj.antenna.technology]';
            sameNumMat = [obj.antenna.numerology] == [obj.antenna.numerology]';
            antPerTechNum = sum(sameTechMat&sameNumMat,2);
            if  any(antPerTechNum > 1)
                warningMessage = 'The current implementation of DAS is not finished yet. Simulation may run into an error.';
                warning('BS:DASNotImplemented', warningMessage)
                % assert antenna prameters and inform user
                if (obj.nSectors*size(obj.antenna,2)>1 && size(obj.antenna,2)~= 1)
                    warning('BS:Ant2Pos',['This mapping from Antenna to BS of simulation might'...
                        ,' lead to unrealistic results. Check doc parameters.basestation.Parameters.createBaseStationsCommon'...
                        ,' for more information'])
                end
            end

            % check number of basestation sectors
            errorMessage = 'The number of sectors nSectors must be a integer between 1 and 6';
            if isnumeric(obj.nSectors) && isfinite(obj.nSectors) && obj.nSectors==floor(obj.nSectors)
                if(obj.nSectors < 1 || obj.nSectors > 6)
                    error('error:invalidSetting', errorMessage);
                end
            else
                error('error:invalidSetting', errorMessage);
            end

            sectorSize = 360 / obj.nSectors;
            for iAntenna = obj.antenna
                % check parameters of the antenna configurations
                iAntenna.checkParameters;
                % check sector size and horizontal antenna beam width
                warningMessage = 'The setting of number of sectors and antenna type might cause high interefence between sectors.';
                if obj.nSectors > 1
                    if isa(iAntenna, 'parameters.basestation.antennas.Omnidirectional')
                        warning('warning:SectorAntenna', warningMessage);
                    else
                        if 2*iAntenna.theta3dB>sectorSize*1.2
                            warning('warning:SectorAntenna', warningMessage);
                        end
                    end
                end
            end % for all antenna parameters
        end
    end
end

