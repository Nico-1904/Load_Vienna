classdef Precoder5G < parameters.precoders.Parameters
    %PRECODER5G Adapted from TS 38.214 for single panel 5G codebooks
    % codebookMode=1
    % Compatible with LTE DL feedback up to 6 transmit chains and 4 layers.
    % Utilizes PIM  from the LTE Feedback to hoose a codebook entry.
    %
    % see also: precoder.Precoder5G, feedback.LTEDLFeedback
    % initial author: Alexander Bokor

    methods
        function precoder = generatePrecoder(~, ~, ~)
            % Generate a precoder object for the given transmission parameters.
            %
            % input:
            %   ~
            %   ~
            %
            % output:
            %   obj: [1x1]handleObject precoders.Precoder
            %
            % see also: parameters.precoders
            precoder = precoders.Precoder5GDL();
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
            isValid = precoders.Precoder5GDL.checkConfig(transmissionParameters, baseStations);
        end
    end
end

