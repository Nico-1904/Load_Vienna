classdef ZeroForcing < linkQualityModel.LinkQualityModel
    %ZEROFORCING xi, psi and theta for a zero forcing receiver
    % This object calculates the signal power fraction zeta, the inter
    % layer interference xi and the interference enhancement theta for a
    % zero forcing receive filter. These values can then be used by the
    % link quality model to calculate the post equalization SINR.
    %
    % see also linkQualityModel.LinkQualityModel
    %
    % inital author: Agnes Fastenbauer

    methods
        function obj = ZeroForcing(params, resourceGrid, antennaBSmapper, iniCache)
            % initializes the link quality model
            %
            % input:
            %   params:             [1x1]handleObject parameters.Parameters
            %   resourceGrid:       [1x1]handleObject resource grid parameters
            %   antennaBSmapper:    [1x1]handleObject tools.AntennaBsMapper
            %   iniFactors:         [1x1]handleObject linkQualityModel.IniCache
            %
            % set properties: properties set in initResourceGridSize

            % call superclass constructor
            obj = obj@linkQualityModel.LinkQualityModel(params, resourceGrid, antennaBSmapper, iniCache);
        end

        function c = copy(obj)
            % Create a shallow copy
            %
            % output:
            %   c: [1x1]linkQualityModel.LinkQualityModel copied object
            c = linkQualityModel.ZeroForcing(obj.params, obj.resourceGrid, obj.antennaBsMapper, obj.iniCache);
            c = copy@linkQualityModel.LinkQualityModel(obj, c);
        end

        function setReceiveFilter(obj)
            % calculates and sets receive filter
            % The receive filter is the pseudoinverse of the effective
            % channel matrix (i.e. the channel matrix including precoding,
            % which is represented by W here).
            %
            % used properties: nLayer, receiver.nRX, nDes, channel,
            % desired, precoder
            %
            % set properties: receiveFilter
            %
            %NOTE: short block fading and several SINR values per RB in
            %frequency are not implemented here

            % initialize receive filter
            obj.receiveFilter = ones(obj.nLayer, obj.receiver.nRX, obj.nRBscheduled, obj.nDes);

            % get desired channel matrices
            desH = obj.channel(1, obj.desired);
            % get desired precoders
            desW = obj.precoder(:, obj.desired);
            % get desired analog precoders
            desWa = obj.precoderAnalog(obj.desired);

            %NOTE: the time index for the channel matrix is always 1
            %because there is only one channel realization per slot and
            %short block fading is not considered yet
            timeH = 1;

            for iDes = 1:obj.nDes
                for iRB = 1:obj.nRBscheduled

                    % get frequency index of current resource block
                    iFreq = obj.receiver.scheduling.iRBFreq(iRB);

                    % effective channel matrix
                    HW = desH(1,iDes).H(:,:,timeH,iFreq)*desWa(iDes).W_a*desW(iRB,iDes).W;
                    % receiver filter
                    %F = (HW'*HW)^(-1)*HW';% = H^+ the pseudoinverse of HW
                    %F = (HW'*HW) \ HW';
                    %NOTE: (TD): this line is much faster than the
                    %commented line above. The result is the same,
                    %except if the condition number of HW is very
                    %large. In that case there exist minor numerical
                    %errors
                    F = HW\eye(obj.receiver.nRX);
                    obj.receiveFilter(:,:,iRB,iDes) = F;
                end % for all scheduled resource blocks
            end % for all transmit antennas transmitting a desired signal
        end

        function xi = getInterLayerInterference(obj)
            % sets the inter-layer interference xi
            %
            % output:
            %   xi:	[nLayer x nRBscheduled x nDes]double inter-layer interference

            % ZF receiver: inter-layer-interference stays 0
            xi = zeros(obj.nLayer, obj.nRBscheduled, obj.nDes);
        end

        function zeta = getSignalPowerFraction(obj)
            % sets fraction of power going to the signal part of the SINR
            %
            % output:
            %   zeta:   [nLayer x nRBscheduled x nDes]double power fraction between 0 and 1

            % all the transmit power is signal for a ZF receiver
            zeta =  ones(obj.nLayer, obj.nRBscheduled, obj.nDes);
        end
    end
end

