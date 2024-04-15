function phi = getAngle2D(baseStationPosition, userPosition, azimuth)
%GETANGLE2D gets angle between two NetworkElementWithPosition in degrees with -180 deg <= phi <= 180 deg
% Calculates the angle phi relative to the azimuth angle in which the base
% station antenna has the maximum gain.
%NOTE: nElements, the number of base station and user positions can be 1.
%
% input:
%   baseStationPosition:	[3 x nElements]double (x;y;z) network element positions
%   userPosition:           [3 x nElements]double (x;y;z) network element positions
%   azimuth:                [1 x 1]double azimuth angle in which base station antenna has the maximum gain
%
% output:
%   phi:  [1 x nElements]double angle between two positions -180 <= theta <= 180

% get (x;y) position of the user relative to the base station
ue_centered = userPosition(1:2,:) - baseStationPosition(1:2,:);

% convert to polar coordinates to get the angle of the realtive user position
[ue_phi, ~] = cart2pol(ue_centered(1,:), ue_centered(2,:));

% convert angle to angle in degrees
phi_degree = rad2deg(ue_phi);

% get phi in an angle ranging from -180 ... 180 and consider antenna azimuth
phi = tools.wrapAngleTo180(phi_degree - azimuth);
end

