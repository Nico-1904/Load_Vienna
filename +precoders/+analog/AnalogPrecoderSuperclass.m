classdef AnalogPrecoderSuperclass < tools.HiddenHandle &  matlab.mixin.Heterogeneous
    %ANALOGPRECODERSUPERCLASS maps transmit antennas to antenna ports
    %   The analog precoder is the link between the channel model and the
    %   baseband precoder. It maps the nTX transmit antennas to the antenna
    %   ports. In the 3GPP standards documents this is often referred to as
    %   TXRU virtualization.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also networkElements.bs.Antenna,
    % networkElements.bs.antennas.AntennaArray

    methods
        function obj = AnalogPrecoderSuperclass()
            %ANALOGPRECODERSUPERCLASS Construct an instance of this class

        end
    end

    methods (Abstract, Static)
        % CALCULATEPRECODER returns analog precoding matrix
        %
        % input:
        %   Antenna:    [1x1]handleObject networkElements.Antenna
        %
        % output:
        %   W_a:	[nTXelements x nTX]complex analog precoder
        W_a = calculatePrecoder(Antenna)
    end

    methods (Abstract, Static, Access = protected)
        % checks if the configuration is valid for each precoder
        %
        % input:
        %   antenna:	[1x1]handleObject networkElements.bs.Antenna
        checkConfig(antenna);
    end

    methods (Static)
        function obj = generateAnalogPrecoder(antennaParameters)
            % creates an analog precoder of the type set in transmission parameters
            %
            % input:
            %   antennaParameters:	[1x1]handleObject parameters.basestation.antennas.Parameters
            %
            % output:
            %   obj:	[1x1]handleObject precoders.analog.AnalogPrecoderSuperclass

            % create precoder according to settings
            switch antennaParameters.precoderAnalogType
                case parameters.setting.PrecoderAnalogType.MIMO
                    % MIMO precoder
                    obj = precoders.analog.MIMO();

                case parameters.setting.PrecoderAnalogType.none
                    % no precoder
                    obj = precoders.analog.NoAnalogPrecoding();

                otherwise
                    error('PRECODERS:notDefined','Unknown PrecoderAnalogType, see parameters.setting.PrecoderAnalogType for options.');
            end
        end

        function checkConfigStatic(baseStationList)
            % checks if parameters are valid for analog precoder type
            %
            % input:
            %   baseStationParameters:  [1 x nBS]handleObject networkElements.bs.BaseStation

            % for each base station type, we make a loop over all antennas
            % and check if the precoder config matches the antenna config
            for iBS = baseStationList

                % get all antenna parameters for this base station type
                antennaList = iBS.antennaList;

                for iAnt = antennaList
                    % check parameters for precoder type
                    iAnt.precoderAnalog.checkConfig(iAnt);
                end % for all antennas of this base station type

            end % for all types of base stations
        end
    end
end

