classdef FeedbackSuperclass
    %FEEDBACKSUPERCLASS basic feedback values common to all feedback types
    %
    % initial author: Agnes Fastenbauer
    % extended by: Areen Shiyahin, added ACK paramater
    %
    % see also feedback.FeedbackLTE, feedback.MinimumFeedback

    properties
        % transmit mode
        % [1x1]integer transmit mode index
        txModeIndex

        % rank indicator
        % [1x1]integer indicates the rank of the MIMO channel
        % This is a measure of how many uncorrelated channels are
        % available.
        rankIndicator

        % estimated CQI
        % [nRBFreq x nRBTime x nCodewords]integer {0...15} estimated Channel Quality Indicator
        estimatedCQI

        % indicator for valid feedback
        % [1x1]logical indicates if this feedback is valid feedback
        isValid = false;

        % [1xnCodeword]logical indicates whether the codewords transmission
        % succeeds or fails
        ack
    end

    methods (Abstract)
        % returns the feedback values in a struct for postprocessing
        FeedbackStruct = toStruct(obj)
    end
end

