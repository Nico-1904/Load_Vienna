classdef Random < parameters.precoders.Parameters
    %RANDOM Random precoders
    % This precoder creates a random precoding matrix. This precoder
    % can be used in combination with all feedback types, since it does
    % not use any feedback values to set the precoding matrix. This is also
    % the only feedback that is compatible with the minimum feedback.
    %
    % see also precoders.RandomPrecoder, feedback.MinimumFeedback
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
            precoder = precoders.PrecoderRandom();
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
            isValid = precoders.PrecoderRandom.checkConfig(transmissionParameters, baseStations);
        end
    end
end

