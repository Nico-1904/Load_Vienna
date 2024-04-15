% +LOSDECISION
%
% Files
%   Geometry         - parameter class that defines how to decide if the users and
%   Random           - los/nlos property is decided randomly with a set probability
%   Static           - LOS/NLOS decision for users is constant
%   RuralMacro5G     - LOS probability from 3GPP TR 38.901 table 7.4.2-1 to the isLOS parameter
%   UrbanMacro3D     - LOS based on 3GPP TR 36.873 (V12.0.0) Table 7.2-2 Page 22
%   UrbanMacro5G     - LOS based on 3GPP TR 38.901 (V 14.0.0) Release 14 Page 28 Table 7.4.2-1
%   UrbanMicro3D     - calculate LOS based on 3GPP TR 36.873 (V12.0.0) Table 7.2-2  Page 22
%   UrbanMicro5G     - LOS based on 3GPP TR 38.901 Table 7.4.2-1 (V 14.0.0) Release 14 Page 28
%   losDecisionSuper - MODEL NLOS LOS property is decided based on the defined pathloss model

