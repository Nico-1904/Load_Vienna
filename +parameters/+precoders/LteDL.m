classdef LteDL < parameters.precoders.Parameters
    %LTEDL LTE downlink precoder according to TS36.211
    % Table 6.3.4.2.3-1 and Table 6.3.4.2.3-2
    % Supports up to 4 transmit chains and 4 layers.
    %
    % This is a codebook based precoder. It utilizes the PMI from the
    % LTE feedback to choose a codebook entry.
    %
    % see also precoders.PrecoderLTEDL, feedback.FeedbackLTE,
    % feedback.LTEDLFeedback
    % initial author: Alexander Bokor

    methods
        function precoder = generatePrecoder(~, transmissionParameters, ~)
            % Generate a precoder object for the given transmission parameters.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   ~
            %
            % output:
            %   obj: [1x1]handleObject precoders.Precoder
            %
            % see also: parameters.precoders
            precoder = precoders.PrecoderLTEDL(transmissionParameters);
        end

        function isValid = checkConfig(~, transmissionParameters, baseStations)
            % Checks if parameters are valid for this precoder type.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % output:
            %   isValid: [1x1]logical true if parameters are valid for this precoder
            %
            % see also: parameters.precoders
            isValid = precoders.PrecoderLTEDL.checkConfig(transmissionParameters, baseStations);
        end
    end
end

