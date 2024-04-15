function W = example()
% This example file shows the usage of the precoder classes.
%
% initial author: Alexander Bokor

%% KRONECKER PRECODER
% This example shows how to use the precoder class on the example of
% kronecker product precoders.
% We show:
%  * How to set the parameters to create a precoder.
%  * Call the check function to verify the parameters are valid.
%  * Obtain precoder matrices for a simple case.

% Set up parameters
% define transmission parameters
% the feedback has to be compatible with the precoder
transmissionParameters = parameters.transmissionParameters.TransmissionParameters;
transmissionParameters.txModeIndex = 4;
transmissionParameters.feedbackType = parameters.setting.FeedbackType.LTEDL;

% some precoders can be configured with more options in the
% precoderParameters. We will change the defaults to get more codebooks.
precoderParameters = parameters.precoders.Kronecker;
precoderParameters.horizontalOversampling = 4;
precoderParameters.verticalOversampling = 4;

% define antennas
antenna = networkElements.bs.antennas.AntennaArray;
antenna.nPV = 1; % single panel
antenna.nPH = 1; % single panel
antenna.nV = 2;
antenna.nH = 2;
antenna.N1 = 2;
antenna.N2 = 2;
antenna.nTX = antenna.N1 * antenna.N2;
antenna.precoderAnalog = precoders.analog.NoAnalogPrecoding;

antennaList(1) = antenna;

% define basestation
baseStation = networkElements.bs.BaseStation;
baseStation.antennaList = antennaList;

% Verify settings

% we can now check if our settings are valid for this precoder
isValid = precoderParameters.checkConfig(transmissionParameters, baseStation);
if ~isValid
    error("The precoder settings are invalid in the precoder example!");
end

% Create precoder

% call the static generate function to create a precoder
precoder = precoderParameters.generatePrecoder(transmissionParameters, baseStation);

% to obtain precoder matrices we pass the following arguments
%  * the indices of the assigned ressource blocks
%  * the amount of layers for each ressource block
%  * feedback object. In this case we create a dummy feedback with PMI and
%    basic txMode information
assignedRBs = [1, 2];
nLayers = [2, 2];
feedback = struct("PMI", ones(1,length(assignedRBs)), "txModeIndex", transmissionParameters.txModeIndex);
iAntenna = 1;

W = precoder.getPrecoder(assignedRBs, nLayers, antenna, feedback, iAntenna);

%% TECHNOLOGY PRECODER
% This example shows how a technology precoder shall be used.
% This type of precoder distinguishes between the technology of the used antenna.
% It is useful for base stations with antennas of different numerologies.

% First the precoder parameter is created
precoderParams = parameters.precoders.Technology;
% the class specifies default values
% The LTEDL Precoder is used for the LTE technology and the 5G Precoder for
% 5G technology.
% But this values can be overwritten using the setTechPrecoder(...) fct.
% For this the technology and the precoder for it needs to be specified.
precoderParams.setTechPrecoder(parameters.setting.NetworkElementTechnology.LTE, ...
    parameters.precoders.LteDL());
precoderParams.setTechPrecoder(parameters.setting.NetworkElementTechnology.NRMN_5G, ...
    parameters.precoders.Precoder5G());
end

