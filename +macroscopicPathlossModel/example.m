function pathloss = example()
% example function for the macroscopicPathloss package
% This function shows how to use the macroscopic pathloss package as a
% stand-alone package.

% choose path loss model
pathLossModel = macroscopicPathlossModel.Indoor;

distance2Dm = 0:0.1:250;
distance3Dm = distance2Dm;
nLinks = length(distance3Dm);
frequencyGHz = 2 * ones(1, nLinks);
userHeightm = 1.5 * ones(1, nLinks);
antennaHeightm = 30 * ones(1, nLinks);
pathloss = pathLossModel.getPathloss(frequencyGHz, distance2Dm, distance3Dm, userHeightm, antennaHeightm);

% the same procedure can be carried out with every pathloss model supported
% by the SLS for more details on the possible parametrisation
% see also : parameters.pathlossParameters
figure(1);
plot(distance3Dm, pathloss, 'LineWidth', 2);
xlabel('User - Base Station Distance in m');
ylabel('Path Loss in dB');
grid on;
hold on;
end

