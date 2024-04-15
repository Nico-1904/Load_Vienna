classdef RegionOfInterest < parameters.regionOfInterest.Region
    %REGIONOFINTEREST parameters that defines the simulation area
    % In this class all properties of the ROI are defined, including the
    % settings to construct a interference region.
    %
    % initial author: Lukas Nagel
    %
    % ROI: Region Of Interest
    %
    % see also parameters.regionOfInterest.Region

    properties
        % factor how much the interference region is larger
        % [1x1]double interference region factor >= 1
        % A factor of 1 correspondss to no interference region.
        % The size of the interference region corresponds to the length and
        % width of the ROI multiplied by this factor.
        interferenceRegionFactor = 1;

        % interference strategy
        % [1x1]enum parameters.setting.Interference
        %
        % see also parameters.setting.Interference
        interference = parameters.setting.Interference.none;
    end

    properties (SetAccess = private)
        % interference region
        % [1x1]handleObject parameters.regionOfInterest.Region
        % Addition to the ROI, where base stations producing interference
        % for users at the border the ROI are placed.
        interferenceRegion

        % placement region for the networkGeometry package
        % [1x1]handleObject parameters.regionOfInterest.Region
        % This is the Region of Interest either with or without the
        % interference region, depending on the interference property.
        placementRegion
    end

    methods
        function obj = RegionOfInterest()
            % calls superclass constructor nad default properties

            obj = obj@parameters.regionOfInterest.Region();
            obj.createInterferenceRegion;
        end

        function createInterferenceRegion(obj)
            % createInterferenceRegion creates the interference region based on the ROI and interferenceRegionFactor
            % Creates a interference region that is
            % interferenceRegionFactor times the size of the region of
            % interest.
            %
            %NOTE: the height of the interference region could also be the
            %same as the height of the ROI, as neither users nor base
            %stations are placed at heights bigger than the height of the
            %ROI, but the interference region is expanded in height by the
            %interferenceRegionFactor as are the other dimensions of the
            %ROI, which results in a much higher interference region
            %height, as there usually is no negative height.
            %
            % see also parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor

            % create interference region
            obj.interferenceRegion = parameters.regionOfInterest.Region();
            obj.interferenceRegion.origin2D	= obj.origin2D;
            obj.interferenceRegion.xSpan 	= obj.xSpan * obj.interferenceRegionFactor;
            obj.interferenceRegion.ySpan  	= obj.ySpan * obj.interferenceRegionFactor;
            obj.interferenceRegion.zSpan  	= obj.zSpan * obj.interferenceRegionFactor;
        end

        function placementRegion = get.placementRegion(obj)
            % determines the region in which users are placed according to interference
            %
            % initial author: Agnes Fastenbauer

            switch obj.interference
                case parameters.setting.Interference.regionContinuousUser
                    % users are placed in the ROI and interference region
                    % and the interference region users are then tagged as
                    % interference region users

                    placementRegion = obj.interferenceRegion;

                    % check that an interference region exists
                    if obj.interferenceRegionFactor <= 1
                        warn = 'No interference region is created, but network elements are placed in it.';
                        warning('warn:noInterfRegion', warn);
                    end

                case parameters.setting.Interference.regionIndependentUser
                    % the users are placed in the ROI and the users in the
                    % interference region are generated independently

                    placementRegion = obj;

                    % check that an interference region exists
                    if obj.interferenceRegionFactor <= 1
                        warn = 'No interference region is created, but network elements are placed in it.';
                        warning('warn:noInterfRegion', warn);
                    end

                case {parameters.setting.Interference.none, parameters.setting.Interference.wraparound}
                    placementRegion = obj;

                otherwise
                    warn = 'No interference region placement strategy has been chosen. No users will be placed in the interference region.';
                    warning('warning:intReg', warn);
                    placementRegion = obj;
            end
        end

        function checkParameters(obj)
            % compability check for the region of interest class
            % Checks if the interference region creation settings are
            % consistent.
            %
            % initial author Agnes Fastenbauer
            %
            % see also parameters.setting.Interference

            if (obj.interference == parameters.setting.Interference.none || obj.interference == parameters.setting.Interference.wraparound) ...
                    && obj.interferenceRegionFactor ~= 1
                % if no interference region is simulated, but an
                % interference region factor is set
                warning('warn:intReg', 'An interference region factor is set, but no interference region will be created.');
                obj.interferenceRegionFactor = 1;
            elseif (obj.interference == parameters.setting.Interference.regionContinuousUser ...
                    || obj.interference == parameters.setting.Interference.regionIndependentUser) ...
                    && obj.interferenceRegionFactor == 1
                % if an interference region should be simulated, but the
                % interference region factor is set to 1, which creates no
                % interference region
                warn = 'Interference region is chosen as border interference strategy, but the interference region factor is set to 1.\n';
                warn = [warn 'No interference region will be created.'];
                warning('warn:intReg', warn);
                obj.interference = parameters.setting.Interference.none;
            end

            if obj.interferenceRegionFactor < 1
                error('err:intReg', 'The interference region cannot be smaller than the region of interest.');
            end % if the interference region factor is smaller than 1

            if obj.xSpan <= 0 || obj.ySpan <= 0
                warn = 'The size of the region of interest shoulb be a positive number.';
                warning('warn:ROIsize', warn);
            end % if the interference region has no area

            if obj.zSpan <= 0
                warn = 'The height of the ROI is 0 or smaller. All NEs with a height ~= 0 will be outside the ROI.';
                warning('warn:ROIsize', warn);
            end
        end

        function plotRoiBorder(obj, color)
            % draw the outline of the region of interest
            %
            % input:
            %   color:  [1x3]double RGB triplet of the color or matlab color option

            hold on;
            tools.drawLine2D([obj.xMin obj.yMin], [obj.xMin obj.yMax], color);
            tools.drawLine2D([obj.xMin obj.yMin], [obj.xMax obj.yMin], color);
            tools.drawLine2D([obj.xMax obj.yMin], [obj.xMax obj.yMax], color);
            tools.drawLine2D([obj.xMax obj.yMax], [obj.xMin obj.yMax], color);
            xlim([obj.interferenceRegion.xMin obj.interferenceRegion.xMax]);
            ylim([obj.interferenceRegion.yMin obj.interferenceRegion.yMax]);
        end
    end
end

