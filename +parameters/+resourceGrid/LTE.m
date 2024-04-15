classdef LTE < parameters.resourceGrid.ResourceGrid
    % resource grid for the LTE standard
    %
    % initial author: Agnes Fastenbauer (originally from ResourceGridLTE.m)
    % extended by: Alexander Bokor

    properties
        % cyclic prefix
        % [1x1]enum parameters.setting.CyclicPrefix
        % see also parameters.setting.CyclicPrefix
        cyclicPrefix

        % reference symbols used per resource block for number of transmit antennas
        % [1 x nAntenna]integer number of reference symbols in a resource block
        %  number of transmit antennas:  1  2  3  4   5  6  7  8
        referenceSymbolsPerRB =         [4, 8, 8, 12, 8, 8, 8, 8];

        % indicates resource blocks that contain synchronization signal
        % [1 x nRBFreq]logigal indicates presence of synchronization signal
        synchronizationRB
    end

    methods
        function obj = LTE(bandwidthHz, slotDuration)
            % class constructor sets a basic LTE scenario
            %
            % input:
            %   bandwidthHz:    [1x1]double simulation bandwidth in Hz {1.4MHz, 3MHz, 5MHz, 10MHz, 15MHz, 20MHz}
            %   slotDuration:   [1x1]double duration of a slot in seconds

            % check if bandwidth is compatible with LTE standard
            if ~any(bandwidthHz == [1.4e6, 3e6, 5e6, 10e6, 15e6, 20e6])
                warning('The bandwidth setting does not correspond to an LTE simulation. Possible bandwidth values are: 1.4MHz, 3MHz, 5MHz, 10MHz, 15MHz and 20MHz.');
            end

            % call superclass constructor
            obj = obj@parameters.resourceGrid.ResourceGrid(slotDuration, bandwidthHz);

            % set the special case for small bandwidth
            if bandwidthHz == 1.4e6
                obj.nRBFreq = 6;
            end

            % set cyclic prefix and its dependent parameters
            obj.cyclicPrefix = parameters.setting.CyclicPrefix.normal;
        end

        function set.cyclicPrefix(obj, newCyclicPrefix)
            % set cyclic prefix setting and nSymbolRb according to cyclic prefix length
            %
            % input:
            %   newCyclicPrefix:    [1x1]enum parameters.setting.CyclicPrefix
            %
            % set properties: cyclicPrefix, symbolDurationS

            % set cyclic prefix
            obj.cyclicPrefix = newCyclicPrefix;

            % set number of symbols per resource block according to cyclic prefix
            switch obj.cyclicPrefix
                case parameters.setting.CyclicPrefix.normal
                    obj.symbolDurationS_base = obj.sizeRbTimeS / 7;
                    cpDuration = 4.69e-6;
                    obj.cpRatio = cpDuration / (obj.symbolDurationS_base + cpDuration);
                case parameters.setting.CyclicPrefix.extended
                    obj.symbolDurationS_base = obj.sizeRbTimeS / 6;
                    cpDuration = 16.67e-6;
                    obj.cpRatio = cpDuration / (obj.symbolDurationS_base + cpDuration);
                otherwise
                    error('Unknown cyclic prefix option, see parameters.setting.CyclicPrefix.');
            end
        end

        function synchronizationRB = get.synchronizationRB(obj)
            % find indices of resource blocks with synchronization signal

            synchronizationRB = false(obj.nRBFreq,1);
            synchronizationRB(floor(obj.nRBFreq/2)-2:floor(obj.nRBFreq/2)+3) = true;
        end
    end
end

