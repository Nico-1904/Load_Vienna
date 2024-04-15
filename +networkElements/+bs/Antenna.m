classdef Antenna < networkElements.NetworkElementWithPosition & matlab.mixin.Heterogeneous
    %ANTENNA of a base station
    % This is the superclass for base station antennas, which are actually
    % antenna arrays. Each antenna belongs to a base station.
    %
    % initial author: Lukas Nagel
    % extended by: Christoph Buchner added technology parameter
    %
    % see also networkElements.bs.BaseStation, tools.AntennaBsMapper,
    % parameters.basestation.antennas

    properties
        % global antenna index
        % [1x1] integer antenna id
        id

        % type of base station this antenna belongs to
        % [1x1]enum parameters.setting.BaseStationType
        % see also parameters.setting.BaseStationType
        baseStationType

        % carriers on which this basestation transmits
        % [1 x nCC]handleObject of parameters.Carrier
        % see also parameters.Carrier
        %NOTE: for now this is [1x2] for downlink and uplink carrier
        usedCCs

        % number of transmit antenna ports
        % [1x1] integer number of transmit antenna ports
        nTX

        % total number of antenna elements
        % [1x1] integer number of antenna elements
        % This number is at a multiple of nTX, depending on the number of
        % elements per port.
        nTXelements

        % number of receive antennas
        %[1x1]integer number of receive antennas
        nRX

        % indicates if the base station is an interferer if no users are scheduled
        % [1x1]logical indicates if base station is always transmitting
        % If this is true the antennas attached to this base station are
        % always transmitting and generating interference even if no users
        % are scheduled at the base station in this slot.
        %NOTE: This is applied in the link quality model, where the
        %antennas that do not generate interference are not added as
        %interference.
        alwaysOn = true;

        % scheduling information
        % [1x1]object scheduler.rbGrid
        % see also networkElements.bs.BaseStation.setDLsignaling
        rbGrid

        % maximum antenna gain in dBi
        %[1x1]double maximum antenna gain in dBi
        gaindBmax

        % analog precoder
        % [1x1]handleObject precoders.analog.AnalogPrecoderSuperclass
        precoderAnalog

        % analog precoder
        % [nTXelements x nTX]complex analog precoder
        % or [1x1]integer if no analog precoding is performed
        W_a = 1;

        % azimuth angle in which the antenna has its maximum gain in degrees
        % [1x1]double azimuth angle in radians in which this antenna has its maximum gain
        azimuth

        % elevation angle in which the antenna has its maximum gain in degrees
        % this is mainly for the Antenna array and 3D Beamforming
        % [1x1]double elevation angle in radians in which this antenna has its maximum gain
        elevation

        % elevation offset from elevation angle for fixed beam applications
        % Only relevant if you are using precoder mode 4(fixed beam) in
        % simulation.ChunkSimulation
        % The default values are hardcoded on purpose here
        % Default ist -45?, so that the beam goes to the ground
        % -> 0? is z=const, negative angles beam to the ground
        % [1x1]double elevation angle in radians
        elevationOffset = -pi/4;
    end

    properties (Dependent)
        % number of different component carriers supported by this antenna
        % [1x1]integer number of different carriers used
        nCC
    end

    methods (Abstract)
        % returns antenna gain as a function of user position(s)
        %
        % input:
        %   User:       [1 x nUser]handleObject networkElements.ue.User
        %   iSlot:      [1x1]integer index of current slot
        %   iSegment:   [1x1]integer index of current segment
        %
        % output:
        %   gaindB: [1 x nUser]double antenna gain in direction of the given user in dB
        gaindB = gain(obj, User, iSlot, iSegment)
    end

    methods (Static, Sealed, Access = protected)
        %NOTE: this is necessary to build arrays of different antenna
        %objects, i.e. Omnidirectional and ThreeSector, as is used in two
        %tier scenarios
        function default_object = getDefaultScalarElement
            default_object = networkElements.bs.antennas.Omnidirectional;
        end
    end

    methods
        function obj = Antenna()
            % Antenna's constructor sets default values for properties
            % inherited from networkElements.NetworkElementWithPosition
            % superclass.

            % set default values for superclass properties
            obj.isInROI         = true; % put all antennas in Region Of Interest
            obj.transmitPower	= 1;	% in W
        end

        function setGenericParameters(obj, antennaParameters, positionList, params)
            % sets antenna parameters
            % This function sets antenna parameters set in
            % parameters.basestation.antennas.Parameters for this antenna.
            % The antenna height is set in the base station creation
            % function, together with the other coordinates of the antenna.
            %
            % input:
            %   antennaParameters:  [1x1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   params:             [1x1]handleObject parameters.Parameters
            %
            % initial author: Agnes Fastenbauer
            %
            % see also networkElements.bs.BaseStation,
            % parameters.basestation.antennas.Parameters

            % set number of transmit antennas
            obj.nTX                   	= antennaParameters.nTX;

            % total number of antenna elements
            % For all other antenna types than antenna arrays there is one
            % element per port. NOTE: This parameter is only used for
            % antenna arrays but set anyways for consistency.
            obj.nTXelements             = obj.nTX;
            % set number of receive antennas
            obj.nRX                   	= antennaParameters.nRX;
            % set base station type
            obj.baseStationType         = antennaParameters.baseStationType;
            % set receiver noise figure
            obj.rxNoiseFiguredB         = antennaParameters.rxNoiseFiguredB;
            obj.setThermalNoisePower(params.transmissionParameters.DL.resourceGrid.sizeRbFreqHz);
            % set always on indicator
            obj.alwaysOn                = antennaParameters.alwaysOn;
            % add to position z the antenna height
            positionList(3,:) = positionList(3,:) + repmat(antennaParameters.height,1,size(positionList,2));
            % set positions
            obj.setPositionList(positionList, params);
            obj.checkRegionOfInterest(params.regionOfInterest);
            % set used CCs
            obj.usedCCs = params.carrierDL;
            % initialize precoder
            obj.precoderAnalog = precoders.analog.AnalogPrecoderSuperclass.generateAnalogPrecoder(antennaParameters);
            % technology
            obj.technology = antennaParameters.technology;
            obj.numerology = antennaParameters.numerology;
            % set azimuth
            obj.azimuth = antennaParameters.azimuth;
            % set elevation
            obj.elevation = antennaParameters.elevation;

            % set transmit power
            if isnan(antennaParameters.transmitPower)
                % set default values if transmit power is not specified
                switch obj.baseStationType
                    case parameters.setting.BaseStationType.macro
                        obj.transmitPower = 20;	% W
                    case parameters.setting.BaseStationType.pico
                        obj.transmitPower = 2;	% W
                    case parameters.setting.BaseStationType.femto
                        obj.transmitPower = 0.1; % W
                end
            else
                obj.transmitPower = antennaParameters.transmitPower;
            end
        end

        function setPositionList(obj, positionList, params)
            % sets the positionList for wraparound simulation
            % In the wraparound implementation the ROI is copied 8 times
            % around the central ROI and then, the closest BS realization
            % of these 9 ROIs is chosen for each user.
            %
            % input:
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   params:             [1x1]handleObject parameters.Parameters

            if params.regionOfInterest.interference == parameters.setting.Interference.wraparound

                % initalize positionList
                obj.positionList = zeros(3, size(positionList, 2), 9);

                % set positions for central region
                obj.positionList(:,:,1) = positionList;
                obj.positionList(:,:,2) = positionList + [-params.regionOfInterest.xSpan;  params.regionOfInterest.ySpan;   0];
                obj.positionList(:,:,3) = positionList + [ 0;                              params.regionOfInterest.ySpan;   0];
                obj.positionList(:,:,4) = positionList + [ params.regionOfInterest.xSpan;  params.regionOfInterest.ySpan;   0];
                obj.positionList(:,:,5) = positionList + [-params.regionOfInterest.xSpan;  0;                               0];
                obj.positionList(:,:,6) = positionList + [ params.regionOfInterest.xSpan;  0;                               0];
                obj.positionList(:,:,7) = positionList + [-params.regionOfInterest.xSpan; -params.regionOfInterest.ySpan;   0];
                obj.positionList(:,:,8) = positionList + [ 0;                             -params.regionOfInterest.ySpan;   0];
                obj.positionList(:,:,9) = positionList + [ params.regionOfInterest.xSpan; -params.regionOfInterest.ySpan;   0];
            else

                % initalize positionList
                obj.positionList = zeros(3, size(positionList, 2));

                % set positions for central region
                obj.positionList(:,:,1) = positionList;
            end
        end

        function handle = plot(obj, timeIndex, color)
            % plot plots the antenna in a color
            %
            % input:
            %   timeIndex:  [1x1]integer time index at which antenna should be plotted
            %   color:      either color triplet [r g b] or 'm', 'y' ...

            % get position to plot
            p = obj.positionList(:, timeIndex, 1);
            % plot antenna
            handle = scatter3(p(1), p(2), p(3), 50, color, 'filled');
        end

        function handle = plot2D(obj, timeIndex, color)
            % plot plots the antenna in a color
            %
            % input:
            %   timeIndex:  [1x1]integer time index at which antenna should be plotted
            %   color:      either color triplet [r g b] or 'm', 'y' ...

            % get position to plot
            p = obj.positionList(:, timeIndex, 1);
            % plot antenna
            handle = scatter(p(1), p(2), 50, color, 'filled');
        end

        function position = getAntennaPosition(obj, timeIndex, User)
            % gets the position of the antenna for the given user
            % In the wrap around implementation the antenna has 9 position
            % vectors and the user chooses the position that is closest to
            % him.
            %
            % input:
            %   timeIndex:  [1x1]integer index of current slot
            %   User:       [1x1]handleObject networkElements.ue.User
            %
            % output:
            %   position:   [3x1]double (x;y;z)-position of the antenna for the given user

            position = obj.positionList(:, timeIndex, User.antennaWrapRegion(obj.id));
        end

        function nCC = get.nCC(obj)
            % getter function for number of component carriers
            %
            % output:
            %   nCC:    [1x1]integer number of component carriers

            % get number of used component carriers
            nCC = length(obj.usedCCs);
        end

        function set.nCC(obj, nCC)
            % set method for number of component carriers
            %
            % input:
            %   nCC:    [1x1]integer number of component carriers
            %
            %NOTE: this function is necessary for the copy function in
            %tools.HiddenHandle

            if nCC ~= length(obj.usedCCs)
                warning('The number of component carriers cannot be set to something other than the number of used component carriers.');
            end
        end
    end

    methods (Static)
        function plotAntennaGainPattern(antenna)
            % plots the antenna gain pattern in a 2000x2000 grid
            % If no valid antenna is set, a ThreeSector antenna pattern is
            % plotted.
            %
            % input:
            %   antennaType:    []handleObject networkElements.bs.Antenna
            %
            % initial author: Agnes Fastenbauer

            if ~isa(antenna, 'networkElements.bs.Antenna')
                antenna = networkElements.bs.antennas.ThreeSector;
                antenna.azimuth = 300;
                antenna.gaindBmax = 15;
                antenna.positionList = [750; 433; 32];
            end

            x = meshgrid(0:2000, 0:1732);
            x =  x(:).';
            y = meshgrid(0:1732, 0:2000).';
            y = y(:).';

            nUser = length(x);
            user(1, nUser) = networkElements.ue.User;
            for iUser = 1:nUser
                user(iUser).positionList = [x(iUser); y(iUser); 1];
            end
            gain = antenna.gain(user, 1, 1);
            gain = reshape(gain, 1733, 2001);
            figure();
            imagesc(gain);
            colorbar;
        end
    end
end

