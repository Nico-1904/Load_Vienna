classdef FeedbackLTE < feedback.FeedbackSuperclass
    %FEEDBACKLTE contains properties and feedback values of LTE feedback
    %
    % initital author: Agnes Fastenbauer
    %
    % see also feedback.LTEDLFeedback

    properties
        % Precoding Matrix Indicator
        % [nRBFreq x nRBTime]integer Precoding Matrix Indicator
        PMI
    end

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
                'PMI',              obj.PMI, ...
                'isValid',          obj.isValid,...
                'ack',              obj.ack);
        end
    end
end

