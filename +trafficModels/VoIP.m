classdef VoIP < trafficModels.PacketProcessing
    %VoIP Class for voice over Internet Protocol traffic model simulation.
    % The voice activity model is represented with simple two-state
    % Markov model. Adaptive multi-rate (AMR) audio codec is used for this model,
    % which is an audio compression format optimized for speech coding.
    % VoIP packets are generated during the voice activity period
    % and Silence Insertion Descriptor (SID) packets are generated
    % during the silence period
    %
    % initial author: Areen Shiyahin
    %
    % see also trafficModels.PacketProcessing
    % networkElements.ue.User
    % parameters.user.Parameters

    properties
        % parameter c
        % [1x1]double transition probability from inactive state to
        % active state
        c

        % parameter d
        % [1x1]double the probability of remaining in the active state
        d

        % encoder frame length
        % [1x1]double encoder frame length in seconds,
        % it is the inter-arrival time between VoIP packets during voice
        % activity period
        encoderFrameLength

        % silence duration
        % [1x1]double inter-arrival time between SID packets during
        % silence period
        silenceDuration

        % voice payload
        % [1x1]double VoIP packet size in bits
        voicePayload

        % Silence Insertion Descriptor payload
        % [1x1]double SID packet size in bits
        SIDPayload

        % voice activity state
        % [1x1]logical initial voice activity state in two-Markov Model
        state

        % initial time
        % [1x1]double random generation time for the initial VoIP packet
        initialTime

        % initial time SID
        % [1x1]double random generation time for the initial SID packet ,
        % it is being updated during the simulation duration
        initialTimeSID

        % counter
        % [1x1]double counter used to update the initial time of SID
        % packets generation
        counter
    end

    methods
        function obj = VoIP()
            % class constructor

            % call superclass constructor
            obj = obj@trafficModels.PacketProcessing();

            % set parameters
            obj.c                    = 0.01;
            obj.d                    = 0.99;
            obj.encoderFrameLength   = 20e-3;
            obj.silenceDuration      = 160e-3;
            obj.voicePayload         = 40*8;
            obj.SIDPayload           = 15*8;
            obj.state                = true;
            obj.counter              = 1;

            % set initial time for in msec, it is equal to
            % number of slots that are necessary for the packet generation
            obj.initialTime = randi(obj.encoderFrameLength * 1e3);

            % set initial time for SID packet generation
            obj.initialTimeSID = obj.initialTime;

            % check parameters
            obj.checkParametersVoIP;
        end

        function checkNewPacket(obj,iSlot)
            % check if new packet generation is necessary in the current slot
            %
            % input:
            %   iSlot: [1x1]double index of current slot

            % set parameters
            voicePayloadArrival  = obj.encoderFrameLength * 1e3;
            SIDPayloadArrival    = obj.silenceDuration * 1e3;

            % update voice activity state
            if ~mod(iSlot - obj.initialTime, voicePayloadArrival)
                randomCheck = rand;
                if obj.state
                    if randomCheck < obj.d
                        obj.state = true;
                    else
                        obj.state = false;
                    end
                else
                    if randomCheck < obj.c
                        obj.state = true;
                    else
                        obj.state = false;
                    end
                end

                % generate VoIP packets
                if obj.state
                    checkNewPacket@trafficModels.PacketProcessing(obj,obj.voicePayload, voicePayloadArrival, iSlot, obj.initialTime);
                    obj.initialTimeSID = obj.initialTimeSID + (voicePayloadArrival * obj.counter);
                    obj.counter = 1;
                else
                    % generate SID packets
                    checkNewPacket@trafficModels.PacketProcessing(obj,obj.SIDPayload, SIDPayloadArrival, iSlot, obj.initialTimeSID);
                    obj.counter = obj.counter + 1;
                end
            end
        end

        function [bufferedPackets, remainingBits, generationSlot] = getBufferState(obj)
            % get various information about packets
            %
            % output:
            %   bufferedPackets: [1x1]double number of buffered packets
            %   remainingBits:   [1xnPackets]double remaining number of
            %                     bits for each packet
            %   generationSlot : [1xnPackets]double generation time for
            %                     each packet

            [bufferedPackets, remainingBits, generationSlot] = getBufferState@trafficModels.PacketProcessing(obj);
        end

        function updateAfterTransmit(obj,sentBits,iSlot)
            % update data in buffer according to the user throughput
            %
            % input:
            %   sentBits:  [1x1]double number of transmitted bits in
            %                  current slot
            %   iSlot:     [1x1]double index of current slot

            updateAfterTransmit@trafficModels.PacketProcessing(obj,sentBits,iSlot);
        end

        function latency = getTransmissionLatency(obj)
            % compute packets transmission latency
            %
            % output:
            %   latency: [1xnPackets]double transmission delay of packets

            latency = getTransmissionLatency@trafficModels.PacketProcessing(obj);
        end

        function clearBuffer(obj)
            % clear packets buffer
            clearBuffer@trafficModels.PacketProcessing(obj);
        end

        function checkParametersVoIP(obj)
            % check parameters compability

            if obj.c ~= 0.01
                warning("VoIP:c_Compatibility", ...
                    "Transition probability must equal the default value.");
            end

            if obj.d ~= 0.99
                warning("VoIP:d_Compatibility", ...
                    "Transition probability must equal the default value.");
            end

            if obj.encoderFrameLength ~= 20e-3
                warning("VoIP:EncoderFrameLengthCompatibility", ...
                    "Encoder frame length must equal the default value.");
            end

            if obj.silenceDuration ~= 160e-3
                warning("VoIP:SilenceDurationCompatibility", ...
                    "Inter-arrival time in silence period must equal the default value.");
            end

            if obj.voicePayload ~= 40*8
                warning("VoIP:VoicePayloadCompatibility", ...
                    "Voice payload must equal the default value.");
            end

            if obj.SIDPayload ~= 15*8
                warning("VoIP:SIDPayloadCompatibility", ...
                    "SID payload must equal the default value.");
            end

            if obj.state ~= true
                warning("VoIP:VoiceActivityStateCompatibility", ...
                    "Initial voice activity state must equal the default value.");
            end

            if obj.counter ~= 1
                warning("VoIP:CounterCompatibility", ...
                    "Counter of initial SID packet generation time must equal the default value.");
            end
        end
    end
end