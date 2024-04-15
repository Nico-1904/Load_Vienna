classdef PrecoderRandom < precoders.Precoder
    % Precoder with randomly generated precoding matrix.
    % This precoder works with any kind of feedback as it doesn't use it.
    %
    % initial author: Thomas Dittrich
    % extended by: Alexander Bokor, added documentation
    %
    % see also parameters.precoders.Random, precoders.Precoder

    methods (Access = protected)
        function precoder = calculatePrecoder(obj, ~, nLayer, antenna, ~, ~)
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

            precoder = obj.calculateRandomPrecoder(nLayer, antenna.nTX);
        end
    end

    methods (Static)
        function isValid = checkConfig(~, baseStations)
            % checks if the configuration is valid for this precoder
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % output:
            %   isValid:	[1x1]logical indicates if config is valid for this precoder

            % initialize isValid
            isValid = false;

            antennaList = [baseStations.antennaList];

            % extract uniqe nTX
            nTX = unique([antennaList.nTX]);

            % check if there are transmit antennas
            if all(nTX > 0)
                isValid = true;
            end % if all transmit antennas exist
        end
    end

    methods (Static)
        function precoder = calculateRandomPrecoder(nLayer, nTX)
            % returns a precoding matrix for each assigned RB
            % The precoding matrix is normalized such that the power of the
            % output signal is equal to the power of the input signal. It
            % returns one precoder for each assigned RB.
            %
            % input:
            %   nLayer:	[nAssignedRBs x 1]integer specifies the number of layers in the assigned RBs
            %   nTX:	[1x1]integer number of transmit antennas
            %
            % output:
            %   precoder:	[nAssignedRBs x 1]struct for this scheduled RBs
            %       -W:	[nTX x nLayer]complex baseband precoder

            % get number of precoders to set
            nRB = length(nLayer);

            % preallocate precoders
            precoder(1:nRB) = struct('W',[]);

            % set random precoder for all assigned resource blocks
            for iRB = 1:nRB
                W = randn(nTX, nLayer(iRB));
                % assuming uniform power allocation among different layers
                W = W/norm(W, 'fro');
                %NOTE: for non-uniform power allocation we would have
                %something like (and also a function that does the power
                %allocation)
                %M = nLayer
                %sigma1 to sigmaM being the allocated powers
                %Sigma = [sigma1;...;sigmaM]
                %W = norm(Sigma)*W/norm(W*diag(Sigma),'fro')
                precoder(iRB).W = W;
            end % for all assigned resource blocks
        end
    end
end

