function [phi, theta] = getAngle3D(baseStationPosition, userPosition, azimuth, elevation)
%GETANGLE3D gets angles between two NetworkElementWithPosition in degrees with -180 deg <= theta,phi <= 180 deg
% Calculates the angle phi relative to the azimuth and the angle theta
% relative to the elevation where base station antenna has its max gain.
%NOTE: nElements, the number of base station and user positions can be 1.
%
% input:
%   baseStationPosition:	[3 x nElements]double (x;y;z) network element positions
%   userPosition:           [3 x nElements]double (x;y;z) network element positions
%   azimuth:                [1 x 1]double azimuth angle in which base station antenna has the maximum gain
%   elevation:              [1 x 1]double elevation angle in which base station antenna has the maximum gain
%
% output:
%   phi:    [1 x nElements]double angle between two positions -180 <= phi <= 180
%   theta:  [1 x nElements]double angle between two positions -180 <= theta <= 180

% get (x;y;z) position of the user realtive to the base station
ue_centered = userPosition(1:3,:) - baseStationPosition(1:3,:);

% convert to spherical coordinates to get the angle of the relative user position
[ue_phi, ue_theta, ~] = cart2sph(ue_centered(1,:), ue_centered(2,:), ue_centered(3,:));

% convert angle to angle in degrees
phi_degree     = rad2deg(ue_phi);
theta_degree   = rad2deg(ue_theta);

% Matlab defines theta = 0 pointing to the horizon and theta = 90
% pointing to the zenith
% convert elevation angle to the way defined in 3GPP standards (see TR 38.901 Definition 7.1.1)
% 3GPP defines theta = 0 pointing to the zenith and theta = 90 pointing
% to the horizon
theta_degree = 90 - theta_degree;

% get phi and theta in an angle ranging from -180 ... 180 and consider antenna azimuth and elevation
phi = tools.wrapAngleTo180(phi_degree - azimuth);
theta = tools.wrapAngleTo180(theta_degree - elevation); %NOTE: elevation angle following 3GPP's definition
end

