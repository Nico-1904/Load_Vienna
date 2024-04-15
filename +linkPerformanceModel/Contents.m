% +LINKPERFORMANCEMODEL
% The link performance model averages the post-equalization SINR values
% into an effective SINR value, then can then be mapped to a BLER value
% through the BLER curves. CQI, RB size and number of signaling symbols per
% RB are then considered to calculate the throughput achieved by a user
% transmission. A throughput value according to the CQI provided by the
% feedback is calculated as well as an optimal throughput value considering
% the highest CQI that still leads to a successful transmission are
% calculated.
%
% RB: resource block
%
% Files
%   BlerCurves           - holds the curves that map from CQI and SINR to block error ratio (BLER)
%   LinkPerformanceModel - calculates the throughput based on effective SINR and CQI
%   example              - example function for the link performance model (LPM) package

