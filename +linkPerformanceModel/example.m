function example()
%EXAMPLE example function for the link performance model (LPM) package
% This function demonstrates how the link performance model can be used. At
% the beginning relevant parameters are set up, the LPM and SINR averager
% instantiated and depending on the chosen CQI parameter type the
% corresponding capacity and BLER curves are plotted. Then there are two
% different parts. In the first part the performance of a transmission with
% random CQI values is evaluated and the histogramm of throughput values as
% outputted from the LPM is shown. In the second part the LPM is used
% without feedback, i.e., the maximum possible throughput is calculated by
% choosing the best CQI for the current slot. At the end the spectral
% efficiency is plotted by dividing the resulting throughput through the
% occupied bandwidth.
%
% CQI: Channel Quality Indicator
% MIESM: Mutual Information Effective SINR Mapping
% SE: Spectral Efficiency
%
% initial author: Thomas Dittrich
% extended by: Agnes Fastenbauer, Thomas Lipovec
%
% see also linkQualityModel.LinkQualityModel, tools.MiesmAverager

%% create link performance model object
% set up parameters
params = parameters.Parameters;
% set CQI table to simulate
params.transmissionParameters.DL.cqiParameterType = parameters.setting.CqiParameterType.Cqi256QAM;
params.setDependentParameters;

% extract parameters relevant for link performance model
cqiParameters	= params.transmissionParameters.DL.cqiParameters;
blerCurves      = params.transmissionParameters.DL.blerCurves;
useBernoulli    = params.bernoulliExperiment; % = true (default value)
useFeedback     = params.useFeedback; % = true (default value)
fastAveraging   = false;

% create SINR averager
sinrAverager            = tools.MiesmAverager(...
    cqiParameters, 'dataFiles/BICM_capacity_tables_20000_realizations.mat',...
    fastAveraging);

% instantiate link performance model
lpm = linkPerformanceModel.LinkPerformanceModel(...
    sinrAverager, params.transmissionParameters.DL, useBernoulli, useFeedback);

%% show mutual information and BLER curves over SINR
figure(1)
sinrAverager.plotMutualInformationMatrix();

figure(2)
blerCurves.plotBlerCurves(params.transmissionParameters.DL.cqiParameterType);
ylim([5e-5 1]);

%% Part1: perform transmission with random CQI values and get throughput
% set up transmission
% transmission of 50 resource blocks
nRB         = 50;
% all resource blocks are allocated to this user
assignedRBs	= 1:nRB;
% 4 transmit antennas are used (they set the number of reference symbols
% that cannot be used for the transmission of data)
nTX         = 4;
% number of layers
nLayers     = 2;
% number of transmitted codewords
nCodeword	= 2;
% number of slots
nSlot       = 100;
% NOMA power share factor
alphaNoma = 1; % no NOMA
% redundaucy version of codewords
rv = [0,0];

% preallocate output
throughput          = zeros(1,nSlot);
throughputBestCqi   = zeros(1,nSlot);
effectiveSinr       = zeros(1,nSlot);
bler_codeword       = zeros(1,nSlot);

% get throughput and BLER for transmission in each slot
for iSlot = 1:nSlot
    % set random SINR value in the range -10 ... 30 dB
    sinr	= rand(nLayers,nRB)*40-10;
    % set random CQI for this transmission in the range of 1 ... 15
    % A random CQI value setting will not work very well. The
    % throughputBestCqi shows the maximum throughput achievable with the
    % SINR in this slot. The BLER indicates how many transmissions failed
    % with this combination of CQI and SINR.
    cqi     = ceil(rand(1, nCodeword) * 15);

    % calculate throughput and BLER
    [throughput(iSlot), throughputBestCqi(iSlot), ...
        effectiveSinr(iSlot), bler_codeword(iSlot)] = lpm.calculateThroughput(...
        cqi, sinr, nCodeword, iSlot, assignedRBs, nTX, nLayers, alphaNoma,rv);
end % for all slots

% show calculated throughput
% plot histogram of throughput values if enough throughput values have been calculated
if nSlot >= 10
    figure(3)
    histogram(throughput,'Normalization','pdf');
    xlabel('throughput in bits');
    ylabel('frequency');
    title('Histogram of Throughput Values');
end % if enough transmissions have been performed to make a histogram

% print out mean thoughput and standard deviation
fprintf('Mean throughput is %.2f bits.\n', mean(throughput));
fprintf('Standard deviation of throughput is %.2f bits.\n', std(throughput));

%% Part2: generate spectral efficiency plot
% turn off feedback to get effective SINR values for the best CQI
useFeedback = false;
% turn off Bernoulli experiment to get smooth spectral efficiency curve
useBernoulli = false;
% turn on fast averaging to speed up calculations
fastAveraging = true;
% increase number of simulated slots
nSlot = 2000;

% create SINR averager with fast averaging
sinrAverager            = tools.MiesmAverager(...
    cqiParameters, 'dataFiles/BICM_capacity_tables_20000_realizations.mat',...
    fastAveraging);

% instantiate link performance model
lpm = linkPerformanceModel.LinkPerformanceModel(...
    sinrAverager, params.transmissionParameters.DL, useBernoulli, useFeedback);

% preallocate output
throughputBestCqi   = zeros(1,nSlot);
effectiveSinr       = zeros(1,nSlot);
rv = [0,0];

% get throughput and BLER for transmission in each slot
for iSlot = 1:nSlot
    % set random SINR value that is constant over all RB so that the
    % resulting effective SINR covers the whole range -10 ... 35 dB
    sinr	= (rand()*45-10)*ones(nLayers,nRB);
    % CQI value does not matter as feedback is not used
    cqi     = [0, 0];
    % calculate throughput and BLER
    [~, throughputBestCqi(iSlot), ...
        effectiveSinr(iSlot), ~] = lpm.calculateThroughput(...
        cqi, sinr, nCodeword, iSlot, assignedRBs, nTX, nLayers, alphaNoma,rv);
end % for all slots

% plot Throughput vs. Effective SINR
figure(4)
[sinr, sortIndex] = sort(effectiveSinr);
% SE = throughput in Bit / time slot duration / bandwidth
BW = params.transmissionParameters.DL.resourceGrid.sizeRbFreqHz * ...
    params.transmissionParameters.DL.resourceGrid.nRBTot;
spectralEfficiency = throughputBestCqi(sortIndex)/params.time.slotDuration/BW;
plot(sinr,spectralEfficiency, 'LineWidth', 1)

hold on;

% plot Shannon capacity
snr = linspace(-10,30,100);
snr_lin = 10.^(snr/10);
shannonCapacity = log2(1+snr_lin); % in bit/s/Hz
plot(snr, shannonCapacity, 'LineWidth', 1)
xlim([-10,30])
ylim([0,10])

xlabel('Effective SINR (dB)')
ylabel('Spectral efficiency (bit/s/Hz)')

legend('Spectral Efficiency', 'Shannon capacity', 'Location', 'northwest');

end

