classdef Carrier < tools.HiddenHandle
    %CARRIER component carrier information
    %   This class collects the frequency and bandwidth settings.
    %
    % initial author: Agnes Fastenbauer

    properties
        % carrier frequency in GHz
        % [1x1]double center frequency in GHz
        centerFrequencyGHz = 2;

        % carrier bandwidth in Hertz
        % [1x1]double bandwidth in Hz
        %NOTE: this parameter is a copy of the transmission parameters, the
        %bandwidth cannot be set here
        bandwidthHz

        % identification number of this carrier
        % [1x1]integer carrier id
        % The carrierNo is set arbitrarily for one simulation as an
        % identification number for the carrier.
        % This is to enable an easy way to identify a carrier and check if
        % two carriers are the same, without checking all of their
        % parameters.
        carrierNo
    end

    methods
        function checkParameters(obj)
            % checks parameter ranges
            %
            % see also parameters.Parameters.checkParameters

            % check frequency range
            if obj.centerFrequencyGHz > 1e6
                warn = 'A very large carrier frequency has been set, note that the carrier frequency is set in GHz.';
                warning('warn:soManyGHz', warn);
            end

            % check bandwidth range
            if obj.bandwidthHz < 1e5
                warn = 'A very small bandwidth has been set, note that the bandwidth is set in Hz.';
                warning('warn:soLittleHz', warn);
            end

            % check that carrier number is set
            if isempty(obj.carrierNo)
                warn = 'The carrier needs a carrierNo for identification purposes, you will probably run into errors.';
                warning('warn:NocarrierNo', warn);
            end
        end
    end
end

