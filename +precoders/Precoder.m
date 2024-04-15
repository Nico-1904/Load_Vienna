classdef (Abstract) Precoder < tools.HiddenHandle
    % Superclass for baseband precoders.
    % The baseband precoder maps the user layers (user streams)
    % to transmit RF chains.
    % The baseband precoder is chosen for each resource block.
    % The precoder for each scheduled resource block is set in the
    % scheduler.
    % Resource blocks that are not assigned get the default precoder.
    %
    % initial author: Thomas Dittrich
    % extended by: Alexander Bokor, added documentation
    %
    % see also parameters.precoders, precoders.PrecoderRandom,
    % precoders.Precoder5GDL, precoders.PrecoderKronecker
    % scheduler.Scheduler

    methods (Abstract, Access = protected)
        % Calculates precoding matrix for each assigned resourceblock (RB).
        % The matrix is normalized such that the power of the output signal
        % is equal to the power of the input signal.
        % Gets called by the public getPrecoder(...) method.
        %
        % input:
        %   assignedRBs: [Nx1]integer specifies the index of RBs that are scheduled for the currently considered user
        %   nLayer:      [Nx1]integer specifies the number of layers in the assigned RBs
        %   antenna:     [1x1]handleObject networkElements.bs.Antenna
        %   feedback:    [1x1]feedback.FeedbackSuperclass feedback from currently considered user
        %   iAntenna:    [1x1]integer index of the antenna in the feedback
        %
        % output:
        %   precoder:    [Nx1]struct containing the precoders for all the scheduled RBs
        %       -W: [nTX x nLayer]complex precoder for this resource block
        % where N is the number of allocated resource blocks
        [precoder] = calculatePrecoder(obj, assignedRBs, nLayer, antenna, feedback, iAntenna)
    end

    methods
        function precoder = getPrecoder(obj, assignedRBs, nLayer, antenna, feedback, iAntenna)
            % Wrapper function for the calculation of the precoder.
            % This function calculates the precoder and notifies the user
            % of the simulator of a possible incompatibility of the
            % precoder and the feedback.
            %
            % input:
            %   assignedRBs: [Nx1]integer specifies the index of RBs that are scheduled for the currently considered user
            %   nLayer:      [Nx1]integer specifies the number of layers in the assigned RBs
            %   antenna:     [1x1]handleObject networkElements.bs.Antenna
            %   feedback:    [1x1]feedback.FeedbackSuperclass feedback from currently considered user
            %   iAntenna:    [1x1]integer index of the antenna in the feedback
            %
            % output:
            %   precoder:    [Nx1]struct containing the precoders for all the scheduled RBs
            %       -W: [nTX x nLayer]complex precoder for this resource block
            %
            % where N is the number of allocated resource blocks

            try
                precoder = obj.calculatePrecoder(assignedRBs, nLayer, antenna, feedback, iAntenna);
            catch exc
                fprintf('\nCalculation of Precoder errored. Most likely this precoder class is not compatible to the selected FeedbackType.\n');
                exc.rethrow();
            end
        end

        function antPrecoder = getDASAntennaPrecoder(obj, antennas,iAntenna,bsPrecoder)
            % This functions splits the precoder which was selected based
            % on all antennas on the desired Basestation to the specific
            % Precoder for the antenna at the position iAntenna. Needed for
            % DAS which are considered as one big antenna.
            %
            %
            % input:
            %   antennas:    [NAntx1]handleObject networkElements.bs.Antennas
            %   iAntenna:    [1x1]integer index of the antenna in the feedback
            %   bsPrecoder:  [sum(antennas.nTX)x nLayer] precoder for the whole BS
            % output:
            %   antPrecoder: [ant.NTX x nLayer] precoder for the antenna on
            %                                   position iAntenna
            %
            %   initial Author: Christoph Buchner

            %determin the rows for antenna iAntenna in the bsPrecoder
            splitter = cumsum([antennas.nTX]);

            if(iAntenna == 1)
                lower = 1;
            else
                lower = splitter(iAntenna-1) +1;
            end
            upper = splitter(iAntenna);

            % return the sliced bsPrecoder
            antPrecoder = bsPrecoder(lower:upper,:);

            % the Precoder is recombined in the LQM
            % needed because LQM works based on antennas so antenna based
            % precoders are more convenient
        end
    end

    methods (Abstract, Static)
        % Checks if transmission parameters are valid for this precoder.
        %
        % input:
        %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation base stations using this precoder
        %
        % output:
        %   isValid:    [1x1]logical true if parameters are valid
        %
        % see also: precoders.Precoder.checkConfigStatic
        [isValid] = checkConfig(transmissionParameters, baseStations);
    end
end

