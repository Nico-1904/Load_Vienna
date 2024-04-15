classdef Kronecker < parameters.precoders.Parameters
    %KRONECKER Kronecker prodcuct based precoder
    % The number of precoders and layers can be adjusted in the
    % precoder parameters. Utilizes PIM  from the LTE Feedback to choose a
    % codebook entry.
    %
    % see also precoder.PrecoderKronecker, feedback.LTEDLFeedback
    %
    % initial author: Alexander Bokor

    properties
        % beta adjusts the vertical downtilt, this reduces the area covered
        % by the beams
        beta = 1;

        % maximum number of generated layers
        maxLayer = 8;

        % oversampling factors
        % higher oversampling leads to more precoders and higher resolution

        % horizontal oversampling factor
        % bigger values mean more precoders and higher horizontal resolution
        horizontalOversampling = 4;

        % horizontal oversampling factor
        % bigger values mean more precoders and higher vertical resolution
        verticalOversampling   = 4;
    end

    methods
        function precoder = generatePrecoder(obj, ~, baseStations)
            % Generate a precoder object for the given transmission parameters.
            %
            % input:
            %   ~
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % output:
            %   obj: [1x1]handleObject precoders.Precoder
            %
            % see also: parameters.precoders
            precoder = precoders.PrecoderKronecker(obj.beta, ...
                obj.maxLayer, obj.horizontalOversampling,  ...
                obj.verticalOversampling, baseStations);
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
            isValid = precoders.PrecoderKronecker.checkConfig(transmissionParameters, baseStations);
        end
    end
end

