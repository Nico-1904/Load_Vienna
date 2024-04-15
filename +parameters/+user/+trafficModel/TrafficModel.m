classdef TrafficModel < tools.HiddenHandle
    %TrafficModel contains all traffic model parameters
    %
    % initial author: Areen Shiyahin
    %
    % see also parameters.setting.TrafficModelType,
    % parameters.user.Parameters, networkElements.ue.User

    properties
        % packet size
        % [1x1]double packet size in bits for Constant Rate model
        % The default value corresponds to the number of bits transmitted
        % in a regular LTE resource block with modulation and coding for a
        % CQI of 6.
        size = 94;

        % constant rate packet generation rate
        % [1x2]double number of slots that is necessary
        % for new packet generation for Constant Rate models.
        %
        % see also parameters.setting.TrafficModelType
        numSlots = 2;

        % time of first packet for constant rate and full buffer traffic model in slots
        % [1x1]integer slot of first packet transmission
        % If this is set to 0, the initial transmission takes place at a
        % random slot between 1 and numSlots.
        initialTime = 0;
    end

    methods
        function checkParameters(obj)
            % check parameters compability

            if floor(obj.size) ~= obj.size || obj.size <= 0
                warning("CONSTANTRATE:PacketSizeCompatibility", ...
                    "Packet size must be positive integer.");
            end

            if floor(obj.numSlots) ~= obj.numSlots || obj.numSlots <= 0
                warning("CONSTANTRATE:NumOfSlotsCompatibility", ...
                    "Number of slots that are necessary for packet generation must be positive integer.");
            end

            if floor(obj.initialTime) ~= obj.initialTime || obj.initialTime < 0
                warning("CONSTANTRATE:InitialTimeCompatibility", ...
                    "Initial packet generation time must be positive integer or zero.");
            end
        end
    end
end

