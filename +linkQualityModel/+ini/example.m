% INI calculator Example
% Uses the IniCalculator to calculate inter-numerology interference between
% to OFDM systems and plots the results.
%
% initial author: Alexander Bokor

clear;

% enable guard band
enableGuardBand = false;
showPlot = true;

% construct calculator
nRB = 100;
scs1 = 15e3;
nCarriersPerRB1 = 12;
scs2 = 30e3;
nCarriersPerRB2 = 6;
cp = 1/16;
oversampling = 1;

iniCalc = linkQualityModel.ini.IniCalculator(nRB, scs1, nCarriersPerRB1, scs2, nCarriersPerRB2, cp, oversampling);

% get factor matrix
[A_WSN_TO_NSN, A_NSN_TO_WSN] = iniCalc.getFactorMatrix();

% we need the power distribution in the system
% in this case we split the spectrum in half for num. 1 and 2
blocks = 1:nRB;
powerNSN = [ones(1, nRB/2), zeros(1, nRB/2)] / nCarriersPerRB1;
powerWSN = [zeros(1, nRB/2), ones(1, nRB/2)] / nCarriersPerRB2;

% enable a guard band
if enableGuardBand
    powerNSN(nRB/2) = 0;
    powerWSN(nRB/2+1) = 0;
end

% calculate the INI by multiplying the matrix with the power distribution
INI_NSN = A_WSN_TO_NSN * powerWSN';
INI_WSN = A_NSN_TO_WSN * powerNSN';

% get interference relative to the power of interest
INI_NSN = INI_NSN(powerNSN ~= 0); %./ powerNSN(powerNSN ~= 0)';
INI_WSN = INI_WSN(powerWSN ~= 0); %./ powerWSN(powerWSN ~= 0)';

maxVal = max([INI_NSN; INI_WSN]) * 1.1;

if showPlot
    % be aware to only consider interference in ressource blocks of different
    % numerology
    % normalized on send power
    fig = figure("Name", "INI Calculator Example");
    %fig.Position = [500, 500, 500, 250];
    subplot(1,2,1)
    bar(blocks(powerNSN ~= 0), INI_NSN);
    title("INI Power Numerology 0");
    xlabel("RB index")
    ylabel("P_I")
    ylim([0, maxVal])
    grid();
    subplot(1,2,2)
    bar(blocks(powerWSN ~= 0), INI_WSN);
    title("INI Power Numerology 1");
    xlabel("RB index")
    ylabel("P_I")
    grid()
    ylim([0, maxVal])

    fprintf("Total INI NSN: %f\n", sum(INI_NSN));
    fprintf("Total INI WSN: %f\n", sum(INI_WSN));
end

