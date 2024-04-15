classdef Sector < networkElements.bs.Antenna
    %SECTOR superclass for sectorized antennas
    %   This class contains the gain calculation function for sectorized
    %   antennas.
    %
    %NOTE: no min max gain function has been implemented in the 5G
    %simulator, for this antenna the minimum gain is at theta = 180 deg, which
    %is equivalent to maxAttenuation + gaindBmax
    %
    % see also networkElements.bs.Antenna,
    % networkElements.bs.antennas.ThreeSector,
    % networkElements.bs.antennas.SixSector,
    % networkElements.bs.antennas.ThreeSectorBerger

    properties
        % 3 dB beam width
        % [1x1]integer 3dB beam width as defined by standard
        theta3dB = 65;

        % maximum attenuation in dB
        % [1x1]integer maximum attenuation as defined in standard
        maxAttenuation = 20;
    end

    methods
        function obj = Sector()
            %SECTOR calls superclass constructor

            % call superclass constructor
            obj = obj@networkElements.bs.Antenna;
        end

        function gaindB = gain(obj, User, iSlot, iSegment)
            %GAIN gets antenna gain for the given user in the given slot
            %   Calculates the antenna gain in the direction of the given
            %   user according to 3GPP 36.942 subclause 4.2.1.
            %
            % input:
            %   User:       [1 x nUser]handleObject user for which antenna gain is to be calculated
            %   iSlot:      [1x1]integer slot index for current user position
            %   iSegment:   [1x1]integer index of current segment
            %
            % output:
            %   gaindB: [1 x nUser]double antenna gain in direction of the given user in dB

            % get user positions for all slots
            userPositions = [User.positionList];
            % get user positions for the i-th slot
            userPosition = userPositions(:, iSlot:size(User(1).positionList,2):end);

            % prepare necessary parameters
            nUser       = length(User);
            nAntenna	= size(User(1).wrapIndicator,1);
            nSegments	= size(User(1).wrapIndicator,2);

            % get wrapIndicator of all users
            wrapIndicator = reshape([User.wrapIndicator], [nAntenna, nSegments, nUser]);

            % get polar angle in degree in which user is positioned relative to
            % where the antenna has its maximum gain, -180 deg <= theta <= 180 deg
            theta = tools.getAngle2D(obj.positionList(:, iSlot, wrapIndicator(obj.id, iSegment, :)), userPosition, obj.azimuth);

            % calculate gain in dB
            gaindB = -min(12.*(theta./obj.theta3dB).^2, obj.maxAttenuation) + obj.gaindBmax;
        end
    end
end

