classdef Parameters < tools.HiddenHandle
    % PARAMETERS main class where all parameters are defined
    % The default parameters are set in the properties definition, in the
    % class constructor and in setDefaults.
    %
    % initial author: Lukas Nagel
    %
    % see also: parameters.Time,
    % parameters.regionOfInterest.RegionOfInterest,
    % parameters.user.Parameters, parameters.basestation.Parameters,
    % parameters.city.Parameters, parameters.building.Parameters,
    % parameters.WallBlockage.Parameters,
    % parameters.PathlossModelContainer, parameters.Carrier,
    % parameters.ShadowFadingParameters, parameters.SchedulerParameters,
    % parameters.SpectrumSchedulerParameters, parameters.Noma,
    % parameters.SmallScaleParameters, parameters.SaveObject

    properties
        % time structure defining parameters
        % [1x1]handleObject parameters.Time
        %
        % see also parameters.Time,
        % parameters.Parameters.maximumCorrelationDistance
        time

        % class that defines the region of interest
        % [1x1]handleObject parameters.regionOfInterest.RegionOfInterest
        %
        % see also parameters.regionOfInterest.RegionOfInterest,
        % parameters.regionOfInterest.Region,
        % parameters.user.InterferenceRegion
        regionOfInterest

        % map for the user scenarios
        % To create users, add objects of the class
        % parameters.user.Parameters to this map, these users will then be
        % generated in simulation.SimulationSetup.createUsers.
        %
        % see also parameters.user.Parameters,
        % parameters.user.InterferenceRegion, parameters.user.GaussCluster,
        % parameters.user.Poisson2D, parameters.user.PoissonStreets,
        % parameters.user.PredefinedPositions,
        % parameters.user.UniformCluster,
        % simulation.SimulationSetup.createUsers,
        % parameters.setting.UserMovementType
        userParameters

        % map for the base station scenarios
        % To create base stations, add objects of the class
        % parameters.basestation.Parameters to this map, these base
        % stations will then be generated in
        % simulation.SimulationSetup.createBaseStations.
        %
        % see also simulation.SimulationSetup.createBaseStations,
        % parameters.basestation.HexGrid,
        % parameters.basestation.MacroOnBuildings,
        % parameters.basestation.Poisson2D,
        % parameters.basestation.PredefinedPositions,
        % parameters.basestation.antennas.Omnidirectional,
        % parameters.basestation.antennas.SixSector,
        % parameters.basestation.antennas.ThreeSector,
        % parameters.basestation.antennas.ThreeSectorBerger,
        % parameters.basestation.antennas
        baseStationParameters

        % map for the city scenarios
        % To create cities (i.e. buildings and streets), add objects of the
        % class parameters.city.Parameters to this map, these cities will
        % then be generated in
        % simulation.SimulationSetup.createCitiesAndBuildings.
        %
        % see also simulation.SimulationSetup.createCitiesAndBuildings,
        % parameters.city.Manhattan
        cityParameters

        % map for the building scenarios
        % To create buildings, add objects of the class
        % parameters.building.Parameters to this map, these buildings will
        % then be generated in
        % simulation.SimulationSetup.createCitiesAndBuildings.
        %
        % see also simulation.SimulationSetup.createCitiesAndBuildings,
        % parameters.building.PredefinedPositions
        buildingParameters

        % map for wall scenarios
        % To create walls, add objects of the class
        % parameters.WallBlockage.Parameters to this map, these walls will
        % then be generated in
        % simulation.SimulationSetup.createWallBlockages.
        %
        % see also simulation.SimulationSetup.createWallBlockages,
        % parameters.WallBlockage.PredefinedPositions
        wallParameters

        % maps the street names to their indices
        % This is to create users positioned on streets.
        %
        % see also parameters.user.PoissonStreets
        streetNameToIndexMapping

        % pathloss model mapping
        % Table mapping linktypes to pathloss models.
        % [1x1]handleObject parameters.PathlossModelContainer
        % see also parameters.PathlossModelContainer
        pathlossModelContainer

        % downlink component carrier
        % [1x1]handleObject object with downlink carrier information
        % for now all simulations use the same frequency this might change in the future
        %
        % see also parameters.Carrier
        carrierDL

        % how the users should be associated to the base stations
        % [1x1]enum parameters.setting.CellAssociationStrategy
        % see also parameters.setting.CellAssociationStrategy
        cellAssociationStrategy = parameters.setting.CellAssociationStrategy.maxSINR;

        % shadow fading settings
        % [1x1]handleObject parameters.ShadowFadingParameters
        %
        % see also parameters.ShadowFadingParameters
        shadowFading

        % scheduler parameters
        % [1x1]handleObject parameters.SchedulerParameters
        %
        % see also parameters.SchedulerParameters
        schedulerParameters

        % scheduler parameters
        % [1x1]handleObject parameters.SpectrumSchedulerParameters
        spectrumSchedulerParameters

        % [1x1]struct with parameters regarding the transmission scheme
        %   -DL: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        %
        % see also parameters.transmissionParameters.TransmissionParameters
        transmissionParameters

        % parameters for NOMA transmisison
        % [1x1]handleObject parameters.Noma
        %
        % see also parameters.Noma,
        % linkQualityModel.LinkQualityModel.successiveInterferenceCancellation
        noma

        % parameters for small scale channel fading
        % [1x1]handleObject parameters.SmallScaleParameters
        %
        % see also parameters.SmallScaleParameters
        smallScaleParameters

        % parameters for channel models
        % for now used only for the Quadriga Channel Model (intended to be expanded
        % when other channel models are added in the future)
        % [1x1] parameters.channelModel.QuadrigaParameters
        channelModelParameters

        % this object configures which objects should be saved additionally
        % [1x1]handleObject parameters.SaveObject
        % see also parameters.SaveObject
        save

        % the simulation result will be saved with this name
        filename

        % postprocessor - processes the simulation results
        % The postprocessor handles the results: puts them in a useful
        % format, discards results, that are not of interest and saves the
        % slot results in a results class.
        % The choice of the posprocessor decides which simulation.results
        % class will be used for the simulation results.
        % [1x1]handleObject simulation.postprocessing.PostprocessorSuperclass
        %
        % see also simulation.postprocessing.FullPP,
        % simulation.postprocessing.LiteNoNetworkPP,
        % simulation.postprocessing.LiteWithNetworkPP,
        % simulation.postprocessing.MaximumFlexibilityPP,
        % simulation.results
        postprocessor = simulation.postprocessing.FullPP;

        % FASTAVERAGING specifies if fast averaging should be used in tools.MiesmAverager
        % [1x1] logical true if fast averaging is used, false else
        %
        % see also tools.MiesmAverager
        fastAveraging = true;

        % BERNOULLIEXPERIMENT defines the method for how the LPM handles
        % the block error ratio. When this variable is set to true, the
        % LPM flips a coin that determines if all bits are correct or none
        % [1x1]logical indicator for Bernoulli experiment in link performance model
        %
        % see also linkPerformanceModel.LinkPerformanceModel
        bernoulliExperiment = true;

        % maximum distance for which large scale parameters are constant
        % [1x1]double maximum distance in meters
        % If any user moves further than this distance, the simulator
        % starts a new segment and the macroscopic parameters are updatet.
        maximumCorrelationDistance = 1;

        % use Feedback
        % [1x1]logical use feedback for link performance model
        %
        % see also linkPerformanceModel.LinkPerformanceModel
        useFeedback = true;

        % calculate ini
        % [1x1]logical consider inter-numerology interference
        %
        % see also linkQualityModel.ini.IniCache,
        % linkQualityModel.ini.IniCalculator,
        % linkQualityModel.LinkQualityModel,
        calculateIni = false;

        % FFT oversampling factor for INI
        % [1x1]logical set which FFT oversampling factor shall be
        % considered for the inter-numerology interference calculation
        %
        % see also linkQualityModel.ini.IniCache,
        % linkQualityModel.ini.IniCalculator,
        % linkQualityModel.LinkQualityModel,
        iniOversampling = 1;

        % use HARQ
        % [1x1]logical use HARQ
        %
        % HARQ cannot be used in combination with:
        %   - feedback delay larger than 1
        %   - NOMA
        %   - 256-QAM and 1024-QAM mapping tables
        %   - dynamic user and trafic spectrum scheduling
        % HARQ is disabled if one of the above features is used.
        %
        % see also scheduler.Scheduler, scheduler.signaling.HARQ
        useHARQ = true;
    end

    properties (SetAccess = private)
        % set by obj.setDependentParameters or in the constructor

        % matrix form of the timeline - time in seconds in each slot for each chunk
        % [numberOfChunks x slotsPerChunk]double with time in seconds
        % The time matrix gives the absolute time in seconds of the
        % simulation.
        timeMatrix

        % lite or full simulation
        % [1x1]logical indicates if simulation is a lite simulation
        % In lite simulations a simplified scheduler and a simplified link
        % performance model is used. Use lite simulations to save
        % complexity if the scheduling and LPM effects are not of interest
        % for the simulation results.
        liteSimulation = false;
    end

    methods
        function obj = Parameters()
            % class constructor that sets default values
            % The class constructor initializes the class and the attached
            % parmeter classes. Geometry and network element related
            % parameters are stored in containers.
            %
            % initial author: Lukas Nagel

            % initialize attached classes
            obj.time                        = parameters.Time;
            obj.regionOfInterest            = parameters.regionOfInterest.RegionOfInterest;
            obj.noma                        = parameters.Noma;
            obj.smallScaleParameters        = parameters.SmallScaleParameters;
            obj.shadowFading                = parameters.ShadowFadingParameters;
            obj.schedulerParameters         = parameters.SchedulerParameters;
            obj.spectrumSchedulerParameters	= parameters.SpectrumSchedulerParameters;
            obj.pathlossModelContainer      = parameters.PathlossModelContainer;
            obj.channelModelParameters      = parameters.channelModel.QuadrigaParameters;
            obj.save                        = parameters.SaveObject;

            % initialize map containers
            obj.userParameters              = containers.Map();
            obj.baseStationParameters       = containers.Map();
            obj.cityParameters              = containers.Map();
            obj.buildingParameters          = containers.Map();
            obj.wallParameters              = containers.Map();
            obj.streetNameToIndexMapping	= containers.Map();

            % set default parameters
            obj.setDefaults();
        end

        function checkParameters(obj)
            % checks parameter compatibility and gives warning for unusual parameter setting and error for impossible settings
            %
            % see also parameters.regionOfInterest.RegionOfInterest.checkParameters,
            % parameters.Time.checkParameters,
            % parameters.PathlossModelContainer.checkParameters,
            % parameters.SmallScaleParameters.checkParameters,
            % parameters.Carrier.checkParameters,
            % parameters.basestation.Parameters.checkParameters,
            % parameters.basestation.antennas.Parameters.checkParameters

            % Estimate result size
            estimatedResultSize = obj.postprocessor.estimateResultSize(obj) / 1024 / 1024;
            if estimatedResultSize > 1000
                fprintf('Estimated result size: %.2f MB\n', estimatedResultSize)
                warning(['The simulation will need a lot of storage space. ' ...
                    'Consider reducing the amount of saved results ',  ...
                    'by selecting fewer additional results ', ...
                    'if this is not intended.']);
            end

            % call check parameters for subclasses
            obj.time.checkParameters;
            obj.smallScaleParameters.checkParameters(obj.userParameters, obj.baseStationParameters);
            obj.regionOfInterest.checkParameters;
            obj.carrierDL.checkParameters;
            obj.pathlossModelContainer.checkParameters;
            obj.transmissionParameters.DL.checkParameters;
            obj.spectrumSchedulerParameters.checkParameters;

            % call other check functions
            obj.checkBaseStationParameters;
            obj.checkUserParameters;
            obj.checkTechnologyParameters;

            % check other parameters
            if obj.carrierDL.bandwidthHz ~= obj.transmissionParameters.DL.bandwidthHz
                warn = 'The bandwith set is not consistent.';
                warning('warn:Bandwidth', warn);
            end

            % check if resource grid supports numerologies
            obj.transmissionParameters.DL.resourceGrid.checkConfig(obj);

            % check if HARQ can be used
            if obj.useHARQ == true && ~obj.liteSimulation
                if obj.time.feedbackDelay > 1
                    warning('warn:HARQdisabled', 'HARQ cannot be used with feedback delay > 1.');
                    obj.useHARQ = false;
                end
                if obj.spectrumSchedulerParameters.type == parameters.setting.SpectrumSchedulerType.dynamicTraffic
                    warning('warn:HARQdisabled', 'HARQ cannot be used in combination with dynamic traffic spectrum scheduler.');
                    obj.useHARQ = false;
                end
                if obj.spectrumSchedulerParameters.type == parameters.setting.SpectrumSchedulerType.dynamicUser
                    warning('warn:HARQdisabled', 'HARQ cannot be used in combination with dynamic user spectrum scheduler.');
                    obj.useHARQ = false;
                end
                if obj.noma.mustIdx ~= 0
                    warning('warn:HARQdisabled', 'HARQ cannot be used in combination with NOMA.');
                    obj.useHARQ = false;
                end
                if obj.transmissionParameters.DL.cqiParameterType ~= parameters.setting.CqiParameterType.Cqi64QAM
                    warning('warn:HARQdisabled', 'HARQ can only used with 64-QAM modulation table.');
                    obj.useHARQ = false;
                end
            end
        end

        function setDependentParameters(obj)
            % sets dependent parameters and user transmission parameters

            % generates the timeline matrix
            obj.timeMatrix = obj.time.generateTimeMatrix();

            % create interference region according to ROI and interferenceRegion factor
            obj.regionOfInterest.createInterferenceRegion();

            % set dependent transmission parameters
            obj.transmissionParameters.DL.setDependentParameters(obj);

            % set carrier bandwidth
            obj.carrierDL.bandwidthHz = obj.transmissionParameters.DL.bandwidthHz;

            % check if postprocessor and simulation type match
            if ~isa(obj.postprocessor, 'simulation.postprocessing.FullPP')
                % lite postprocessor
                obj.liteSimulation = true;
            else
                % full postprocessor
                obj.liteSimulation = false;
            end
        end

        function maxSpeed = findMaximumSpeed(obj)
            % find the maximum speed any user uses in the simulation
            % This speed is used to generate the channel traces
            %
            % output:
            %   maxSpeed:   [1x1]double maximum user speed in simulation
            %
            % initial author: Areen Shiyahin

            % get different user types in this simulation
            userKeys = obj.userParameters.keys;

            if ~isempty(userKeys)
                % get number of different users
                nUserTypes = length(userKeys);

                % initialize an array for users speeds
                speed = zeros(1, nUserTypes);

                for iUE = 1:nUserTypes
                    speed(iUE) = obj.userParameters(userKeys{iUE}).speed;
                end

                % get maximum user speed
                maxSpeed = max(speed);
            else
                maxSpeed = 5/3.6;
            end
        end

        function setFilename(obj)
            date = clock;

            if obj.liteSimulation
                simulation_mode = 'LitePP';
            else
                simulation_mode = 'FullPP';
            end

            freqDL	= int2str(obj.carrierDL.centerFrequencyGHz);
            BW_DL	= int2str(obj.transmissionParameters.DL.bandwidthHz/1e6);

            obj.filename= sprintf('%sGHz_freq_%sMHz_BW_%s_%04d-%02d-%02d_%02dh%02dm%02ds',...
                freqDL,...
                BW_DL,...
                simulation_mode,...
                date(1),...                     % Date: year
                date(2),...                     % Date: month
                date(3),...                     % Date: day
                date(4),...                     % Date: hour
                date(5),...                     % Date: minutes
                floor(date(6)));                % Date: seconds
        end
    end

    methods (Access = private)
        function setDefaults(obj)
            % set default values that cannot be set in property definition or class constructor
            %
            %NOTE: other default values are set in the different parameter
            %classes, check the class constructor to see which parameter
            %classes are instantiated and check the property definitions in
            %the class files to see the default parameters.

            % transmission mode
            obj.transmissionParameters = struct;
            obj.transmissionParameters.DL = parameters.transmissionParameters.TransmissionParameters.getDownlinkTransmissionParameters;

            % component carriers
            obj.carrierDL                       = parameters.Carrier;
            obj.carrierDL.carrierNo             = 1;

            % set filename
            obj.setFilename;
        end

        function checkTechnologyParameters(obj)
            % check if there is at least one compatible user for each
            % antenna and vice versa

            % get user technologies
            users       = values(obj.userParameters,obj.userParameters.keys);
            usedTechUe  = cellfun(@(userparam)[userparam.technology], users ,'UniformOutput', false);
            usedTechUe  = unique([usedTechUe{:}]);

            % get antennas technologies
            baseStations = values(obj.baseStationParameters,obj.baseStationParameters.keys);
            antennas = cellfun(@(bs)[bs.antenna], baseStations ,'UniformOutput', false);
            usedTechAnt = cellfun(@(ant)[ant.technology], antennas ,'UniformOutput', false);
            usedTechAnt = unique([usedTechAnt{:}]);

            if ~all(usedTechAnt == usedTechUe)
                if size(usedTechAnt,2) > size(usedTechUe,2)
                    warning('TECHNOLOGY:Mapping','Some antennas have no users with the same technology.')
                else
                    error('TECHNOLOGY:Mapping','Some users have no antennas with the same technology.')
                    % if not thrown here LQM fails to calculate precoder and
                    % other properties
                end
            end
        end

        function checkBaseStationParameters(obj)
            % check base station and precoder parameters

            % check base staiton parameters for all base station types
            bsKeys = obj.baseStationParameters.keys;
            for iBSkey = bsKeys
                bsParam = obj.baseStationParameters(iBSkey{1});
                bsParam.checkParameters;
            end
        end

        function checkUserParameters(obj)
            % check user parameters

            userKeys = obj.userParameters.keys;
            for iUEkey = userKeys
                userParam = obj.userParameters(iUEkey{1});
                userParam.checkParameters;
            end
        end
    end
end

