classdef AntennaArray < networkElements.bs.Antenna
    %ANTENNAARRAY MIMO antennas according to 3GPP 3D TR 38.901
    % This antenna is modelled by a uniform rectangular panel array with
    % nPV*nPH panels. Antenna panels are uniformly spaced in the horizontal
    % direction with a spacing of dPH and in the vertical direction with a
    % spacing of dPV. On each antenna panel, nV*nH antenna elements are
    % uniformly spaced in the horizontal direction with a spacing of dH and
    % in the vertical direction with a spacing of dV. The antenna panel is
    % single polarized.
    %
    % see also parameters.basestation.antennas.AntennaArray

    properties
        % number of antenna elements per panel (vertical direction)
        % [1x1] integer
        nV

        % number of antenna elements per panel (horizontal direction)
        % [1x1] integer
        nH

        % number of panels (vertical direction)
        % [1x1] integer
        nPV

        % number of panels (horizontal direction)
        % [1x1] integer
        nPH

        % vertical element spacing
        % [1x1] double, divided by wavelength lambda
        dV

        % horizontal element spacing
        % [1x1] double, divided by wavelength lambda
        dH

        % vertical panel spacing
        % [1x1] double, divided by wavelength lambda
        dPV

        % horizontal panel spacing
        % [1x1] double, divided by wavelength lambda
        dPH

        % 3 dB beam width in degrees
        % [1x1]integer 3dB beam width as defined by standard
        theta3dB = 65;

        % 3 dB beam width in degrees
        % [1x1]integer 3dB beam width as defined by standard
        phi3dB = 65;

        % maximum attenuation in dB
        % [1x1]integer maximum attenuation as defined in standard
        maxAttenuation = 30;

        % horizontal tx chains (nTX = N1 * N2)
        % [1x1]integer number of tx chains in horizontal direction
        N1

        % vertical tx chains (nTX = N1 * N2)
        % [1x1]integer number of tx chains in vertical direction
        N2
    end

    methods
        function obj = AntennaArray()
            %ANTENNAARRAY calls superclass constructor and sets properties for Antenna Array

            % call superconstructor
            obj = obj@networkElements.bs.Antenna;
            % set maximum antenna gain according to 3GPP 38.901 Table 7.3-1
            obj.gaindBmax	= 8; % in dBi
        end

        function setGenericParameters(obj, antennaParameters, positionList, params)
            % set generic parameters with standardvalues for an antenna
            % and other parameters that are specific to antenna arrays
            %
            % input:
            %   antennaParameters:  [1x1]handleObject parameters.basestation.antennas.Parameters
            %   positionList:       [3 x nSlot]double position of antenna in each slot
            %   params:             [1x1]handleObject parameters.Parameters
            %
            % See Also: networkElements.bs.Antenna.setGenericParameters

            %set standard values
            setGenericParameters@networkElements.bs.Antenna(obj, antennaParameters, positionList, params)
            %set specific values
            obj.N1          = antennaParameters.N1;
            obj.N2          = antennaParameters.N2;
            obj.nV          = antennaParameters.nV;
            obj.nH          = antennaParameters.nH;
            obj.nPV         = antennaParameters.nPV;
            obj.nPH         = antennaParameters.nPH;
            obj.dV          = antennaParameters.dV;
            obj.dH          = antennaParameters.dH;
            obj.dPV         = antennaParameters.dPV;
            obj.dPH         = antennaParameters.dPH;
            obj.nTXelements = obj.nV*obj.nH*obj.nPV*obj.nPH;
        end

        function gaindB = gain(obj, Users, iSlot, iSegment)
            %GAIN gets antenna gain for the given user in the given slot
            %   Calculates the antenna gain in the direction of the given
            %   user according to 3GPP 38.901 Table 7.3-1.
            %
            % input:
            %   User:       [1 x nUser]handleObject user for which antenna gain is to be calculated
            %   iSlot:      [1x1]integer slot index for current user position
            %   iSegment:   [1x1]integer index of current segment
            %
            % output:
            %   gaindB: [1 x nUser]double antenna gain in direction of the given user in dB

            % get user positions
            userPositions = [Users.positionList];
            % get user positions for the i-th slot
            userPosition = userPositions(:, iSlot:size(Users(1).positionList,2):end);

            % prepare necessary parameters
            nUser       = length(Users);
            nAntenna	= size(Users(1).wrapIndicator,1);
            nSegments	= size(Users(1).wrapIndicator,2);

            % get wrapIndicator of all users
            wrapIndicator = reshape([Users.wrapIndicator], [nAntenna, nSegments, nUser]);

            % get angles in degree in which user is positioned relative to
            % where the antenna has its maximum gain, -180 deg <= phi, theta <= 180 deg
            [phi, theta] = tools.getAngle3D(obj.positionList(:, iSlot, wrapIndicator(obj.id, iSegment, :)), userPosition, obj.azimuth, obj.elevation);

            % calculate gain in dB (3GPP TR 38.901 Table 7.3-1)
            Av = -min(12*((theta-90)/obj.theta3dB).^2, obj.maxAttenuation);
            Ah = -min(12*(phi/obj.phi3dB).^2, obj.maxAttenuation);
            gaindB = -min(-(Av+Ah), obj.maxAttenuation) + obj.gaindBmax;
        end
    end
end

