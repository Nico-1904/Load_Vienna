classdef FeedbackMinimum < feedback.FeedbackSuperclass
    % contains properties and feedback values of minimum feedback
    %
    % initital author: Agnes Fastenbauer
    %
    % see also feedback.MinimumFeedback

    methods
        function FeedbackStruct = toStruct(obj)
            % returns the feedback values in a struct
            %
            % output:
            %	FeedbackStruct: [1x1]struct feedback values

            FeedbackStruct = struct(...
                'txModeIndex',      obj.txModeIndex,...
                'rankIndicator',	obj.rankIndicator,...
                'estimatedCQI',     obj.estimatedCQI, ...
                'isValid',          obj.isValid,...
                'ack',              obj.ack);
        end
    end
end

