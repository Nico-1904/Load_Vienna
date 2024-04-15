classdef NetworkElementWithPosition < tools.HiddenHandle
    %NETWORKELEMENT superclass for antennas and users (= network elements that are positioned in the ROI)
    %   This class collects the functions that deal with positions and are
    %   used in several network elements. It also contains the function to
    %   calculate thermal noise power, which is also used for all network
    %   elements.
    %   This is basically the superclass for antennas, user equipment
    %   antennas and base station antennas.
    %
    % see also networkElements.ue.User, networkElements.bs.Antenna,
    % networkElements.bs.antennas, parameters.basestation.antennas,
    % parameters.user
    %
    % extended by: Christoph Buchner added technology parameter

    properties
        % indicator for whether network element is in ROI or not
        % [1 x nSlots]logical indicates if network element is in ROI or in the interference region
        % true if the network element is in the region of interest
        % false if the network element is in the interference region
        % For antennas in DL this is only set to false if all antennas of
        % the base station and all their users are in the interference
        % region.
        isInROI

        % matrix with positions for all times
        % [3 x nTimes]double (x;y;z) coordinates of the different times
        % positionList contains network element's position over time
        % It is defined as a matrix. Each column contains the (x,y,z) - of
        % the network element (user or antenna) at one point in time.
        % for users:
        %   [3 x nTimes]double (x;y;z) coordinates of the different times
        %   positionList contains network element's position over time
        %   It is defined as a matrix. Each column contains the (x,y,z) -
        %   of the antenna at one point in time.
        % for antennas
        %   [3 x nTimes x 9]double (x;y;z) coordinates of the different times
        %   positionList contains network element's position over time for
        %   each wrapping region, the positions in the center regions are
        %   saved in (:,:,1) and the other regions in the following manner:
        %   |2|3|4|
        %   |5|1|6|
        %   |7|8|9|
        positionList = [0;0;0];

        % receiver noise figure in dB
        % [1x1]double receiver noise figure in dB
        %
        % see also parameters.Constants.NOISE_FLOOR,
        % networkElements.NetworkElementWithPosition.setThermalNoisePower
        rxNoiseFiguredB = 0;

        % receiver noise power in a resource block in dB
        % [1x1]double thermal noise experienced in a resource block
        %
        % see also
        % networkElements.NetworkElementWithPosition.rxNoiseFiguredB,
        % networkElements.NetworkElementWithPosition.setThermalNoisePower
        thermalNoisedB

        % total transmit power in Watt
        % [1x1]double total transmit power for transmission of signal in Watt
        % This is the total antenna transmit power for data in Watt.
        transmitPower

        % defines the technology used by this networkelement
        % [1x1]string
        % See also: parameters.setting.NetworkElementTechnology,
        %   simulation.ChunkSimulation.cellAssociation
        technology = parameters.setting.NetworkElementTechnology.LTE;

        % numerology parameter
        % [1x1]integer
        numerology = 0;
    end

    methods
        function checkRegionOfInterest(obj, ROI)
            % checkRegionOfInterest checks if the network element is in the given ROI and sets isInROI property
            %
            % input:
            %   ROI:    [1x1]handleObject parameters.regionOfInterest.Region
            %
            % used properties: positionList
            %
            % set properties: isInROI
            %
            %NOTE: this is only used by users

            % get positions
            x = obj.positionList(1, :);
            y = obj.positionList(2, :);
            z = obj.positionList(3, :);

            % check if positions are in ROI
            obj.isInROI =	(ROI.xMin <= x & x <= ROI.xMax ) ...
                &   (ROI.yMin <= y & y <= ROI.yMax ) ...
                &   (0 <= z        & z <= ROI.zSpan);
        end

        function setThermalNoisePower(obj, sizeRbFreqHz)
            % calculates the thermal noise power per subcarrier in dB for this network element
            % The thermal noise power is constant for each network element
            % if the bandwidth of a resource block is constant. The thermal
            % noise power is used in the linkQualityModel.
            %
            % input:
            %  	sizeRbFreqHz:	[1x1]double bandwidth of a resource block in Hz
            %                   see also parameters.resourceGrid.ResourceGrid.sizeRbFreqHz
            %
            % author: Agnes Fastenbauer
            % based on LTE DL SL LTE_init_generate_users_and_add_schedulers

            % thermal receiver noise in dB
            obj.thermalNoisedB = parameters.Constants.NOISE_FLOOR + tools.todB(sizeRbFreqHz) + obj.rxNoiseFiguredB;
        end
    end

    methods (Static)
        function noisePowers = getNoisePowerW(networkElementList, resourceGrid)
            % get noise powers for whole bandwidth for all network elements in Watt
            %
            % input:
            %   networkElementList: [1 x nElement]handleObject networkElements.NetworkElementWithPosition can be users or antennas
            %   resourceGrid:       [1x1]handleObject parameters.resourceGrid.ResourceGrid
            %
            % output:
            %   noisePowers:	[1 x nElement]double noise powers over bandwidth of networkElementList in W
            %
            % see also parameters.resourceGrid.ResourceGrid,
            % parameters.Constants

            % calculate user noise powers
            noisePowers = tools.dBto([networkElementList.thermalNoisedB]) * resourceGrid.nRBFreq;
        end
    end
end

