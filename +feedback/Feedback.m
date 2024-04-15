classdef Feedback < tools.HiddenHandle
    %FEEDBACK superclass for all different feedback types
    % Here general feedback properties and abstract feedback calculation
    % functions are defined. The calculated feedback values are collected
    % in feedback.FeedbackSuperclass and its subclasses.
    %
    % initial author: Thomas Dittrich
    % extended by: Areen Shiyahin, added ACK paramater
    %
    % see also feedback.FeedbackSuperclass, feedback.LTEDLFeedback,
    % feedback.MinimumFeedback

    properties
        % last feedback values
        % [1x1]integer time (in slots) of last valid feedback
        feedbackLastTime

        % feedback values of current slot
        % [1 x feedbackDelay]object feedback.FeedbackSuperclass
        feedbackValues

        % feedback type
        % [1x1]enum parameters.setting.FeedbackType
        type

        % CQI parameters
        % [1x1]handleObject parameters.transmissionParameters.CqiParameters
        cqiParameters

        % transmit mode
        % [1x1]integer transmit mode used
        txModeIndex

        % precoder
        % [1x1]handleObject precoder.Precoder
        precoder

        % SINR averager
        % [1x1]handleObject tools.MiesmAverager
        sinrAverager
    end

    methods (Abstract, Access = protected)
        % calculate feedback
        %
        % input:
        %   linkQualityModel:	[1x1]handleObject linkQualityModel.LinkQualityModel
        %                    	or [1x1]struct mockup link quality model with fields:
        %                         	-receiver.nRX:  [1x1]integer nRX
        %                       	-antenna.nTX:   [1x1]integer nTX
        %  sinr:                [nLayer x nRBFreq x nRBTime]double post equalization SINR
        %
        % output:
        %   feedback: [1x1]handleObject feedback.FeedbackSuperclass
        %
        % see also feedback.LTEDLFeedback, feedback.MinimumFeedback
        feedback = calculateFeedback(obj, linkQualityModel, sinr)

        % calculate simplified feedback for boundary region users
        %
        % input:
        %   linkQualityModel:	[1x1]handleObject linkQualityModel.LinkQualityModel
        %                    	or [1x1]struct mockup link quality model with fields:
        %                         	-receiver.nRX:  [1x1]integer nRX
        %                       	-antenna.nTX:   [1x1]integer nTX
        %  sinr:                [nLayer x nRBFreq x nRBTime]double post equalization SINR
        %
        % output:
        %   feedback: [1x1]handleObject feedback.FeedbackSuperclass
        %
        % see also feedback.LTEDLFeedback, feedback.MinimumFeedback
        feedback = calculateSimplifiedFeedback(obj, linkQualityModel, sinr)
    end

    methods (Abstract, Access = protected, Static)
        % create an empty feedback object according to the type of feedback used
        % Calls the class constructor for the FeedbackSuperclass object for
        % each feedback. This function is used in the Feedback class and
        % calls different class constructor depending on the feedback type.
        %
        % output:
        %   feedbackObject: [1x1]handleObject feedback.FeedbackSuperclass
        [feedbackObject] = generateEmptyFeedback()
    end

    methods
        function obj = Feedback(feedbackType, cqiParameters, txModeIndex)
            % This constructor initializes the properties feedbackLastTime,
            % type, cqiParameters, txMode and feedbackValues.
            % The properties precoder and sinrAverager have to be set with
            % setter functions setPrecoder, setTools after construction.
            %
            % input:
            %   feedbackType:   [1x1]enum parameters.setting.FeedbackType
            %   cqiParameters:  [1x1]handleObject parameters.transmissionParameters.CqiParameters
            %   txModeIndex:	[1x1]integer transmit mode

            % set properties, that do not need a setter function
            obj.type              	= feedbackType;
            obj.cqiParameters       = cqiParameters;
            obj.txModeIndex         = txModeIndex;
            obj.feedbackLastTime	= -1;
            obj.feedbackValues      = obj.generateEmptyFeedback();
        end

        function obj = clone(old)
            % clone Feedback class
            %
            % input:
            %    old:   [1x1]handleObject feedback.Feedback
            %
            % output:
            %   obj:    [1x1]handleObject feedback.Feedback

            % create new feedback object
            obj = feedback.Feedback.generateFeedback(old.type, old.cqiParameters, old.txModeIndex);

            % set feedback values
            obj.feedbackLastTime	= old.feedbackLastTime;
            obj.feedbackValues      = old.feedbackValues;
        end

        function calculateFeedbackSafe(obj, currentTime, linkQualityModel, sinr, useInterferenceFeedback)
            % calculates feedback in a try-catch block
            %
            % input:
            %   currentTime:                [1x1]integer current slot
            %   linkQualityModel:           [1x1]handleObject link quality model for this link
            %   sinr:                       [nLayer x nRBFreq x nRBTime]double post equalization SINR
            %   useInterferenceFeedback:    [1x1]logical indicates if simplified feedback is used

            if currentTime > obj.feedbackLastTime
                if exist('useInterferenceFeedback','var') && useInterferenceFeedback
                    % calculate feedback for boundary region users
                    feedback = obj.calculateSimplifiedFeedback(linkQualityModel, sinr);
                else
                    % calculate feedback for regular users
                    feedback = obj.calculateFeedback(linkQualityModel, sinr);
                end

                % get index for current feedback
                if currentTime == 1
                    % if no old feedback exists
                    index = 1;
                else
                    % if feedback from previous slots exists
                    index = length(obj.feedbackValues) + 1;
                end

                % set feedback values
                obj.feedbackValues(index) = feedback;
                obj.feedbackLastTime = currentTime;
            end % if feedback should be calculated
        end

        function getAck(obj, linkPerformanceModel)
            % get link performance model acknowledgment parameter which
            % indicates whether a transmission succeeded or failed
            %
            % input:
            %
            %   currentTime: [1x1]integer current slot
            %
            % initial author: Areen Shiyahin
            %
            % see also feedback.LTEDLFeedback, feedback.MinimumFeedback

            % get index for current feedback
            index = length(obj.feedbackValues);

            % set ack value
            obj.feedbackValues(index).ack = linkPerformanceModel.ack;
        end

        function feedback = getFeedback(obj, feedbackDelay)
            % returns the delayed feedback values
            %
            % input:
            %   feedbackDelay:	[1x1]integer feedback delay in slots
            %
            % output:
            %   feedback:   [1x1]object feedback.FeeedbackSuperclass

            if (length(obj.feedbackValues) >= feedbackDelay) ...	% if there is feedback
                    && obj.feedbackValues(end).isValid ...          % if the feedback is valid
                    % if there is already feedback return it
                feedback = obj.feedbackValues(end-(feedbackDelay-1));
            else
                % else return empty feedback
                feedback = obj.generateEmptyFeedback();
            end
        end

        function clearFeedbackBuffer(obj)
            % clear feedback buffer

            % clear all feedback values
            obj.feedbackValues = obj.generateEmptyFeedback();
        end
    end

    methods (Static)
        function userFeedback = generateFeedback(feedbackType, cqiParameters, txModeIndex)
            % creates a feedback object according to settings
            %
            % input:
            %   feedbackType:   [1x1]enum parameters.setting.FeedbackType
            %   cqiParameters:  [1x1]handleObject parameters.transmissionParameters.CqiParameters
            %   txModeIndex:	[1x1]integer transmit mode
            %
            % output:
            %   userFeedback:   [1x1]handleObject feedback.Feedback

            switch feedbackType
                case parameters.setting.FeedbackType.minimum
                    userFeedback = feedback.MinimumFeedback(feedbackType, cqiParameters, txModeIndex);
                case parameters.setting.FeedbackType.LTEDL
                    userFeedback = feedback.LTEDLFeedback(feedbackType, cqiParameters, txModeIndex);
                otherwise
                    error('FEEDBACK:unknown','Unknown Feedback Type: %s', feedbackType);
            end
        end
    end
end

