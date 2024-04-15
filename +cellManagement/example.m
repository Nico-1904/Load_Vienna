function example()
% example function for cellManagement package
% This script shows how to create a CellAssociation object and calculate
% the cell association table and wideband SINR.
%
% initial author: Christoph Buchner
%
% see also cellManagement.CellAssociation.setCellAssociationTable,
% cellManagement.CellAssociation, parameters.setting.CellAssociationStrategy

%% set up configuration
config = simulation.ChunkConfig;
config.params = parameters.Parameters;
[config.baseStationList, config.userList, config.antennaBsMapper] = networkElements.example;
% get useful parameters
nAntennas   = sum([config.baseStationList.nAnt],2);
nUser       = size(config.userList ,2);

% set up segments - cell association is calculated per segment
nSegments               = 4;
config.isNewSegment     = ones(1,nSegments);

% choose a cell association strategy
config.params.cellAssociationStrategy = parameters.setting.CellAssociationStrategy.maxSINR;

% set macroscopic fading for all links
macroscopicFadingW = ones(nAntennas, nUser, nSegments);

% set user noise power for all users
userNoisePowersW = zeros(1, nUser);

%% create cell management object
maxSINRAssignment = cellManagement.CellAssociation(config);

% compute user to BS assignment and calculate wideband SINR
[~, widebandSinrdB] = maxSINRAssignment.setCellAssociationTable(macroscopicFadingW, userNoisePowersW);

% show cell association table
disp('The user is associated to the following base station in the four segments:');
%NOTE: if several base stations present the same SINR, a random base
%station is chosen as serving base station, thus the user assignment
%changes randomly in this example.
disp(maxSINRAssignment.userToBSassignment);
disp('The wideband SINR is constant since the fading is the same for all antennas.');
disp(widebandSinrdB);
end

