classdef ChannelFactory < tools.HiddenHandle
    % Contains routines needed for both PDP- and Winner-based chanel models.
    %
    %NOTE: The ChannelFactory was planned as a superclass for PDP based
    %channel models and the winner channel model. Since the winner channel
    %model will not be implemented this class is rather unnecessary and
    %could be put into the PDP channel factory, the ChannelFactory is kept
    %though, in case it could serve as a superclass for other channel trace
    %generation models and because it makes no sense to delte it, when it
    %already exists.
    %
    % initial auhtor: Agnes Fastenbauer
    % based on LTE DL SL simulator (c) Josep Colom Ikuno, INTHFT, 2011
    %
    % see also smallScaleFading.PDPchannelFactory, smallScaleFading.PDPcontainer

    properties
        % PDP channel trace container
        % [1x1]handleObject smallScaleFading.PDPcontainer
        % Collects all the channel traces for a chunk and the parameters
        % constant for the simulation.
        % see also smallScaleFading.PDPcontainer
        Container

        %% Configuration for current channel trace:

        % number of transmit antennas at the basestation
        % [1x1]double
        nTXelements
        % number of receive antennas at the user
        % [1x1]double
        nRX
        % [1x1]enum parameters.setting.ChannelModel
        % see also parameters.setting.ChannelModel
        channelModel
        % carrier frequency in Hz
        % [1x1]double center frequency in Hz
        freqCarrier
        % bandwidth in Hertz
        % [1x1]double carrier bandwidth in Hz
        % channel model type for the user
        bandwidthHz
        % subcarrierspacing in Hertz
        % [1x1]double carrier bandwidth in Hz
        % channel model type for the user
        subcarrierSpacingHz
        % numerology
        % [1x1]integer numerology
        numerology
        % user speed in meters per second
        % [1x1]double user speed used for PDP trace generation
        % For the generation of the channel traces the user is given a
        % speed for a slot, even though he is not moving during the
        % short time of a slot. The user speed is needed for creating a
        % realistic channel model.
        userSpeed
    end

    properties (Access = protected, Hidden)
        %% Constant parameters:

        % fixed bandwidth of resource block in Hz
        % [1x1]double size of a resource block in frequency domain in Hz
        sizeRbFreqHz
        % number of resource blocks in frequency in a slot
        % [1x1]integer number of resource blocks in a slot in frequency
        nRBFreq
        % total number of subcarriers not NULL
        % [1x1]double
        nSubcarrierSlot
        % this factor is always chosen so that the number of samples in frequency equals to nRBFreq
        fftSamplingInterval

        %% Dependent parameters

        % number of FFT points
        % [1x1]double
        nFFT
        % sampling frequency
        % [1x1]double
        samplingFrequency
    end

    methods (Access = protected)
        function obj = ChannelFactory(resourceGrid, thisAntennaConfig, Container)
            % class constructor for ChannelFactory
            %
            % input:
            %   resourceGrid:       [1x1]handleObject parameters.resourceGrid.ResourceGrid
            %       -nRBFreq:          [1x1]integer number of resource blocks in frequency in a slot
            %       -nSubcarrierSlot:  [1x1]integer number of subcarriers in a slot
            %       -sizeRbFreqHz:     [1x1]double size of a resource block in Hz
            %   thisAntennaConfig:  [1x1]handleObject smallScaleFading.TraceConfiguration
            %   Container:          [1x1]handleObject smallScaleFading.PDPcontainer
            %
            % set properties: Container, nTXelements, nRX,
            % channelModel, freqCarrier, bandwidthHz, nRBFreq,
            % nSubcarrierSlot, sizeRbFreqHz, nFFT, samplingFrequency,
            % fftSamplingInterval

            obj.Container           = Container;
            obj.nTXelements         = thisAntennaConfig.nTXelements;
            obj.nRX                 = thisAntennaConfig.nRX;
            obj.channelModel        = thisAntennaConfig.channelModel;
            obj.freqCarrier         = thisAntennaConfig.freqCarrierHz;
            obj.bandwidthHz         = thisAntennaConfig.bandwidthHz;
            obj.numerology          = thisAntennaConfig.numerology;
            obj.userSpeed           = thisAntennaConfig.speedDoppler;
            obj.subcarrierSpacingHz = resourceGrid.subcarrierSpacingHz(obj.numerology);
            obj.fftSamplingInterval = obj.Container.resourceGrid.nSubcarrierRb(obj.numerology) / obj.Container.nSampleRbFreq;

            obj.nRBFreq             = resourceGrid.nRBFreq;
            obj.nSubcarrierSlot     = resourceGrid.nSubcarrierSlot(obj.numerology);
            obj.sizeRbFreqHz        = resourceGrid.sizeRbFreqHz;

            if obj.bandwidthHz == 15e6
                if obj.subcarrierSpacingHz == 15e3
                    obj.nFFT = 1536;
                elseif obj.subcarrierSpacingHz == 7.5e3
                    obj.nFFT = 1536*2;
                end
            else
                obj.nFFT =  2^ceil(log2(obj.nSubcarrierSlot));
            end

            obj.samplingFrequency = obj.subcarrierSpacingHz * obj.nFFT;
        end

        function HfftRb = getRbTrace(obj, channel)
            % performs FFT and filters channel trace for selected subcarriers
            % Returns back a frequency channel trace jumping each
            % fftSamplingInterval subcarriers.
            %
            % input:
            %   channel:    [nRX x nTXelements x length(symbolTimes) x nLoopReals x tapDelays(end)+1]complexDouble
            %               channel in time domain
            % object properties used: nFFT, nSubcarrierSlot, fftSamplingInterval
            %       see also smallScaleFading.ChannelFactory class
            %       documentation for more information
            %
            % output:
            %   HfftRb: [nRX x nTXelements x length(sybolTimes) x nLoopReals x nSubcarrierSlot/fftSamplingInterval]complexDouble
            %           frequency channel trace for chosen subcarriers

            HfftLarge = fft(channel, obj.nFFT, 5);
            % Eliminate guardband
            Hfft       = HfftLarge(:, :, :, :, [(obj.nFFT - obj.nSubcarrierSlot/2 + 1):obj.nFFT 2:(obj.nSubcarrierSlot/2 + 1)]);
            % Do not return the channel for all subcarriers, but just a
            % subset of it
            % Specifiy out of the useful data subcarrier's FFT,
            % which ones to take (all of them take up too much memory)
            HfftRb    = Hfft(:,:,:,:,1:obj.fftSamplingInterval:end);
        end
    end
end

