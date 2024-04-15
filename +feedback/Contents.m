% +FEEDBACK
% The feedback package calculates feedback values for optimal transmission
% in the next slot. A CQI and RI is set for the next transmission slot. In
% case of LTE feedback, a PMI is additonally set to indicate the optimal
% precoder to choose for the next transmission.
% The feedback is calculated for each resource block for each user to
% provide information for the best CQI scheduler.
%
% CQI: Channel Quality Indicator
% PMI: Precoding Matrix indicator
% RI: Rank Indicator
%
% see also parameters.setting.FeedbackType
%
% Files
%   Feedback           - superclass for all different feedback types
%   FeedbackLTE        - contains properties and feedback values of LTE feedback
%   FeedbackMinimum    - contains properties and feedback values of minimum feedback
%   FeedbackSuperclass - basic feedback values common to all feedback types
%   LTEDLFeedback      - downlink feedback according to LTE standard
%   MinimumFeedback    - minimum feedback for random precoding

