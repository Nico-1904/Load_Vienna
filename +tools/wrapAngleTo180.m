function angle_180 = wrapAngleTo180(angle_degree)
% wraps angle to [-180, 180[ range by mapping it to 0...360 deg range
%
% input:
%   angle_degree:   [] angle to wrap in degree
%
% output:
%   angle_180:  [] angle wrapped to -180 ... 180° range
%
%NOTE: this function should be used in order to avoid the toolbox function
%wrapTo180.
%NOTE: As opposed to the matlab toolbox function that wraps to [-180 180],
%this function wraps to [-180 180[.

angle_180 = mod(angle_degree + 180, 360) - 180;
end

