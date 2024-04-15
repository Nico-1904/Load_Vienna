classdef PrecoderTechnology < precoders.Precoder
    %PRECODERTECHNOLOGY A precoder that distinguishes between technologies.
    % This class should be used if a base stations has antennas with
    % different technologies.
    % For each technology a precoder can be specified.
    %
    % initial author: Alexander Bokor
    %
    % see also parameters.precoders.Technology, precoders.Precoder

    properties
        techToPrecoderMapping
    end

    methods
        function obj = PrecoderTechnology(techToPrecoderParameters)
            %TECHNOLOGY constructor
            obj.techToPrecoderMapping = techToPrecoderParameters;
        end

        function codebook = getCodebook(obj, antennas)
            %GETCODEBOOK get codebook for an antenna
            %
            % input:
            %   antennas: [nAnt x1]handleObject networkElements.bs.Atenna antenna
            % ouput:
            %   codebook:  [1 x nLayers]cell with
            %              [nTX x nLayers x nPrecoders]complex codebook

            % take the first antenna technology to select the tech

            precoderObj = obj.techToPrecoderMapping{antennas(1).technology};
            codebook = precoderObj.getCodebook(antennas);
        end
    end

    methods (Access = protected)
        function precoder = calculatePrecoder(obj, assignedRBs, nLayer, antenna, feedback, iAntenna)
            % returns a precoding matrix for each assigned RB
            % The precoding matrix is normalized such that the power of the
            % output signal is equal to the power of the input signal. It
            % returns one precoder for each assigned RB.
            %
            % input:
            %   assignedRBs: [nAssignedRBs x 1]integer specifies the index of RBs that are scheduled for the currently considered user
            %   nLayer:      [nAssignedRBs x 1]integer specifies the number of layers in the assigned RBs
            %   antenna:     [1x1]handleObject networkElements.bs.Antenna
            %   feedback:    [1x1]feedback.FeedbackSuperclass feedback from currently considered user
            %   iAntenna:    [1x1]integer index of the antenna in the feedback
            %
            % output:
            %   precoder:    [nAssignedRBs x 1]struct for this scheduled RBs
            %       -W: [nTX x nLayer]complex baseband precoder


            precoderObj = obj.techToPrecoderMapping{antenna.technology};
            precoder = precoderObj.calculatePrecoder(assignedRBs, nLayer, antenna, feedback, iAntenna);
        end
    end

    methods (Static)
        function isValid = checkConfig(~, ~)
            % checks if the configuration is valid for this precoder
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   antennaList:            [1xnAnt]handleObject networkElements.bs.Antenna
            %
            % output:
            %   isValid:	[1x1]logical indicates if config is valid for this precoder

            % initialize isValid
            isValid = true;
        end
    end
end

