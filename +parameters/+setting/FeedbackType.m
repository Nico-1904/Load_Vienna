classdef FeedbackType < uint32
    %FEEDBACKTYPE enum of implemented feedback types
    %
    % initial author: Thomas Dittrich
    %
    % see also feedback.Feedback

    enumeration
        % LTE feedback for downlink
        % see also feedback.LTEDLFeedback
        LTEDL   (1)

        % minimum feedback
        % creates the feedback necessary for the scheduler
        %
        % see also feedback.MinimumFeedback
        minimum (3)
    end
end

