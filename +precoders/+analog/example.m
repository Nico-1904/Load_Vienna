function W_a = example()
% returns an analog precoding matrix and an analog precoder
% This example shows how to use the analog precoder package. It is shown
% which parameters are necessary to create an analog precoder and which
% parameters are necessary to calculate an analog precoding matrix.
%
% output:
%   W_a:            [nTXelemnts x nTX]complex analog precoding matrix
%
% initial author: Agnes Fastenbauer
%
% see also parameters.setting.PrecoderAnalogType, precoders.analog,
% precoders.analog.MIMO, precoders.analog.NoAnalogPrecoding

%% setup

% create an antenna array for which the analog precoding matrix W_a is to
% be calculated
antenna = networkElements.bs.antennas.AntennaArray;

% set the antenna array dimensions
% one panel
antenna.nPV = 2;
antenna.nPH = 2;
% 4 x 4 antenna elements per panel
antenna.nV = 4;
antenna.nH = 4;
% set distances between panels and antenna elements
antenna.dV = 0.5;
antenna.dH = 0.5;
antenna.dPV = 2;
antenna.dPH = 2;

% set beam angle
antenna.elevation       = 0;
antenna.elevationOffset = -pi/4;

% set number of RF chains and antenna elements
antenna.nTX = 4;
antenna.nTXelements = antenna.nPV * antenna.nPH * antenna.nV * antenna.nH;

%% create an analog precoder
analogPrecoder = precoders.analog.MIMO;

%% calculate analog precoding matrix
W_a = analogPrecoder.calculatePrecoder(antenna);

end

