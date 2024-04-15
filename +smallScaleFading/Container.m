classdef Container
    % The Container class is an abstraction layer for all different types
    % of channel traces. It provides a unified frontend and hides the nasty
    % details of each channel type's peculiarities.
    %
    % initial author: Jan Nausner
    % see also: PDPcontainer, QuadrigaContainer

    properties
        % [1x1]smallScaleFading.PDPcontainer
        pdpContainer

        % [1x1]smallScaleFading.QuadrigaContainer
        quadrigaContainer
    end

    methods
        function obj = Container(chunkConfig, antennas, users)
            %determine which channel models are used in this simulation
            channelModels = unique(cat(2, chunkConfig.userList.channelModel));

            if any(channelModels == 'Quadriga') %if any user has the Quadriga channel model assigned to it
                %check for Quadriga source files
                if(isfolder('quadriga_src') && isfolder('quadriga_src\@qd_arrayant')) %check if Quadriga source folder is there and non-empty
                    if ~contains(path, 'quadriga_src') %if not on path, add it
                        addpath('quadriga_src');
                    end
                else %if Quadriga folder not present or empty
                    error('Please download the Quadriga Channel Model and put the quadriga_src folder in the main directory.')
                end
                obj.quadrigaContainer = smallScaleFading.QuadrigaContainer(chunkConfig);
                obj.quadrigaContainer.calculateChannelMatrix; %pre-compute channel matrix

            end

            if ~all(channelModels == 'Quadriga') %if not every user is assigned the Quadriga Channel Model, initialize the PDP models too
                % initialize Small Scale Fading

                % set up small scale fading container
                obj.pdpContainer = smallScaleFading.PDPcontainer;
                obj.pdpContainer.setPDPcontainer(chunkConfig.params, chunkConfig.params.transmissionParameters.DL.resourceGrid);
                obj.pdpContainer.loadChannelTraces(antennas, users);
            end
        end

        function H_array = getChannelDL(obj, user, antennaList, iSlot)
            % Get the downlink channel matrix of a specific user for all antennas
            % at a specific slot in time
            %
            % input:
            %   user:           [1x1]networkElements.ue.User current user
            %   antennaList:    [1 x nAntennas]handleObject networkElements.bs.Antenna
            %   iSlot:          [1x1]integer current slot
            %
            % output:
            %   H_array: [1 x nAntennas]struct channel for link quality model
            %       -H: [nRX x nTXelements x nTimeSamples x nFreqSamples]complex channel matrix

            % get donwlink channels between current user and all antennas
            if user.channelModel == parameters.setting.ChannelModel.Quadriga
                H_array = obj.quadrigaContainer.getChannelForAllAntennas(user, antennaList, iSlot);
            else % if a PDP-based channel model is used
                H_array = obj.pdpContainer.getChannelForAllAntennas(user, antennaList, iSlot);
            end
        end

        function channelPower = getLiteChannelPower(obj, user, antennaList, iSlot, iRBFreq)
            % get cheannel power for lite SINR calculation
            % For the lite SNR and SINR calculation one channel coefficient
            % of the channel matrix is used: the one between the first
            % transmit an the first receive antenna. Furthermore, the
            % channel realization of one randomly choden resource block in
            % frequency is selected.
            % The channel is normalized, such that each individual channel
            % has a mean power of 1, so a single channel can be taken from
            % the channel matrix and be used for the lite S(I)NR
            % calculation.
            %
            % input:
            %   user:           [1x1]networkElements.ue.User current user
            %   antennaList:    [1 x nAntennas]handleObject networkElements.bs.Antenna
            %   iSlot:          [1x1]integer index of current slot
            %   iRBFreq:        [1x1]integer index of randomly chosen resource block
            %
            % output:
            %   channelPower:   [1 x nAntennas]double power of lite channel (not in dB)

            % get number of channels
            nAnt = length(antennaList);

            % initialize channel power output
            channelPower = zeros(1, nAnt);

            % get channel matrices
            H = obj.getChannelDL(user, antennaList, iSlot);

            % calculate lite channel power
            for iAnt = 1:nAnt
                channelPower(iAnt) = abs(H(iAnt).H(1, 1, 1, iRBFreq)).^2;
            end
        end
    end
end

