classdef MinimumFeedback < feedback.Feedback
    % MINIMUMFEEDBACK minimum feedback for random precoding
    %
    % inital author: Thomas Dittrich
    % extended by: Alexander Bokor
    %
    % see also feedback.Feedback, feedback FeedbackMinimum

    methods
        function obj = MinimumFeedback(feedbackType, cqiParameters, txModeIndex)
            % class constructor - calls superclass constructor
            %
            % input:
            %   feedbackType:   [1x1]enum parameters.setting.FeedbackType
            %   cqiParameters:  [1x1]handleObject parameters.transmissionParameters.CqiParameters
            %   txModeIndex:	[1x1]integer transmit mode

            obj = obj@feedback.Feedback(feedbackType, cqiParameters, txModeIndex);
        end
    end

    methods (Static, Access = protected)
        function feedbackObject = generateEmptyFeedback()
            % create an empty feedback object according to the type of feedback used
            %
            % output:
            %   feedbackObject: [1x1]object feedback.FeedbackMinimum
            %
            % see also feedback.FeedbackMinimum

            feedbackObject = feedback.FeedbackMinimum;
        end
    end

    methods (Access = protected)
        function feedbackObject = calculateFeedback(obj, linkQualityModel, ~)
            % calculate feedback
            % The feedback is calculated with the help of the link quality
            % model. The LQM is only calculating SINR values for scheduled
            % RBs. The function creates a copy of the LQM and schedules the
            % user temporarily in all RBs. The SINR is calculated and the
            % LQM copy is dropped. Note that new precoders are generated
            % for all scheduled RBs. This only works with precoders that
            % do not rely on feedback. For example: PrecoderRandom
            %
            % input:
            %   linkQualityModel:  [1x1]handleObject linkQualityModel.LinkQualityModel
            %
            % output:
            %   feedback:  [1x1]handleObject feedback.FeedbackMinimum
            %
            % see also feedback.Feedback, feedback.FeedbackMinimum
            %
            % extended by: Alexander Bokor

            feedbackObject = obj.generateEmptyFeedback();
            feedbackObject(1).txModeIndex	= obj.txModeIndex;
            feedbackObject(1).isValid       = true;

            % determine rank
            nRX     = linkQualityModel.receiver.nRX;
            nTX     = sum([linkQualityModel.antenna(linkQualityModel.desired).nTX]);
            maxRank	= min(nRX, nTX);

            % create shallow copy of the LQM
            lqm = linkQualityModel.copy();

            % change scheduling such that user is assigned in all RBs
            userId = lqm.receiver.id;
            lqm.receiver.scheduling.setUserAllocation(userId * ones(lqm.resourceGrid.nRBFreq, lqm.resourceGrid.nRBTime), userId);

            % notify LQM to apply scheduling changes
            lqm.updateSmallScale(lqm.channel);

            % overwrite precoders to obtain a valid precoder in each
            % assigned resource block
            for iAnt = find(lqm.desired)
                antenna = lqm.antenna(iAnt);
                lqm.precoder(:, iAnt)= obj.precoder.getPrecoder(1:lqm.nRBscheduled, ones(lqm.nRBscheduled)*lqm.nLayer, antenna, feedbackObject, 0);
            end

            % update receive filter since precoders changed
            lqm.setReceiveFilter();

            % get common SINR values for all layers
            sinr = lqm.getPostEqSinr();
            SinrValues = shiftdim(min(sinr,[],1),1);

            % set redundancy version of new transmissions to be used in the
            % following sinr to cqi mapping
            newTransmissionRV  = 0;
            % set feedback
            feedbackObject(1).rankIndicator	= maxRank;
            feedbackObject(1).estimatedCQI	= obj.cqiParameters.sinrToCqi(SinrValues,newTransmissionRV);
        end

        function feedback = calculateSimplifiedFeedback(obj, linkQualityModel, sinr)
            % calculate simplified feedback for boundary region users
            %
            % input:
            %   linkQualityModel:  [1x1]handleObject linkQualityModel.LinkQualityModel
            %   sinr:              [nLayer x nRBFreq x nRBTime]double post equalization SINR
            %
            % output:
            %   feedback: [1x1]handleObject feedback.FeedbackMinimum
            %
            % see also feedback.Feedback, feedback.FeedbackMinimum

            % call normal feedback function, since this is already minimum feedback
            feedback = obj.calculateFeedback(linkQualityModel, sinr);
        end
    end
end

