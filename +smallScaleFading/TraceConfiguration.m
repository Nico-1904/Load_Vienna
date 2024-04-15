classdef TraceConfiguration
    %TRACECONFIGURATION collects parameters from user-antenna pairs
    % This class collects the parameters of a user-antenna pair for the
    % generation and loading of small scale channel traces.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also: smallScaleFading.PDPcontainer,
    % smallScaleFading.PDPchannelFactory

    properties
        % number of antenna elements at the base station
        % [1x1]integer number of antennas at the base station
        nTXelements

        % number of antenna elements at the user
        % [1x1]integer number of antennas at the user
        nRX

        % small scale fading channel model
        % [1x1]integer parameters.setting.ChannelModel
        channelModel

        % carrier frequency in Hertz
        % [1x1]double center frequency in Hz
        freqCarrierHz

        % bandwidth used for transmission in Hertz
        % [1x1]double transmission bandwidth in Hz
        bandwidthHz

        % carrier identification number
        % [1x1]integer carrier ID for this simulation
        carrierNo

        % supported numerology
        % [1x1]integer numerology
        numerology

        % user speed in meter per second
        % [1x1]double user speed in m/s
        speedDoppler
    end

    methods
        function obj = TraceConfiguration()
            % empty class constructor
        end
    end

    methods (Static)
        function traceConfigs = setTraceArray(antConfMatrix)
            % write trace configurations from matrix in array of objects
            %
            % input:
            %   antConfMatrix:  [nAntConf x 8]double matrix with antenna configurations
            %       -[:,1]integer number of antennas in antenna array
            %       -[:,2]double carrier frequency in GHz
            %       -[:,3]double bandwidth in MHz
            %       -[:,4]integer carrier identification number
            %       -[:,5]integer number of antennas at the user
            %       -[:,6]integer number of channel model type
            %       -[:,7]double user speed in m/s
            %       -[:,8]integer numerology
            %
            % output:
            %   traceConfigs: [1 x nconfigs]object channel trace configurations
            %
            %NOTE: this class and this function are to ease documentation
            %and to make parameters more easily accessible.

            % get total number of trace configurations
            nConf = size(antConfMatrix, 1);

            % preallocate trace configurations
            traceConfigs(nConf) = smallScaleFading.TraceConfiguration;

            % write trace parameters in object
            for iConf = 1:nConf
                traceConfigs(iConf).nTXelements = antConfMatrix(iConf, 1);
                traceConfigs(iConf).freqCarrierHz = antConfMatrix(iConf, 2) * 1e9;
                traceConfigs(iConf).bandwidthHz = antConfMatrix(iConf, 3) .* 1e6;
                traceConfigs(iConf).carrierNo = antConfMatrix(iConf, 4);
                traceConfigs(iConf).nRX = antConfMatrix(iConf, 5);
                traceConfigs(iConf).channelModel = antConfMatrix(iConf, 6);
                traceConfigs(iConf).speedDoppler = antConfMatrix(iConf, 7);
                traceConfigs(iConf).numerology = antConfMatrix(iConf, 8);
            end
        end
    end
end

