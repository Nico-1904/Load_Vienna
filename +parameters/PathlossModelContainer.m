classdef PathlossModelContainer < tools.HiddenHandle
    %PATHLOSSMODELCONTAINER maps link types to pathloss models
    % Maps the different link properties (macro/femto base station,
    % indoor/outdoor user, LOS/nLOS link) to a pathloss model. This class
    % is implemented to be able to use different pathloss models for
    % different link types. To use different pathloss models, set them in
    % the scenario file of the simulation in this container.
    %
    % initial author: Lukas Nagel
    % extended by: Christoph Buchner
    %
    % see also parameters.Parameters.pathlossModelContainer,
    % parameters.setting.Indoor, parameters.setting.BaseStationType,
    % parameters.setting.Los

    properties
        % path loss model parameters for all link types
        % [bsType x indoorType x losType]cell for combinations of macro/femto BSs - indoor/outdoor links - LOS/NLOS links
        % Each cell contains the parameters for the path loss model for
        % this link type.
        modelMap

        % minimum coupling loss for each base station type
        % [1 x nBStypes]double minimum coupling loss for a link
        % The minimal coupling loss sets a minimum value for the
        % macroscopic pathloss (including wall loss) plus antenna gain.
        % The default values for this property are set in the class
        % constructor.
        %
        % Values based on 3GPP TR 25.951 v.8.0.0
        % For Macro cell base stations minimum coulping loss is 70 dB
        % For Micro cell base stations minimum coulping loss is 53 dB
        % For local area base stations (femto, pico) minimum coulping loss is 45 dB
        %
        % see also linkQualityModel.LinkQualityModel,
        % linkQualityModel.LinkQualityModel.updateMacroscopic,
        % parameters.setting.BaseStationType, macroscopicPathlossModel,
        % networkElements.bs.antennas, networkElements.bs.antennas.gain
        minimumCouplingLossdB

        % bias for small cell cell association
        % [1 x nBStypes]double additional macroscopic metric considered for cell association
        % Small cell base stations transmit with lower transmit powers,
        % favoring cell association towards macroscopic base stations. To
        % increase the likelihood of user association to nearby small
        % cells, a cell association bias is introduced that is added to the
        % macroscopic fading metric utilized to choose the most suitable
        % base station.
        % The default values for this property are set in the class
        % constructor.
        cellAssociationBiasdB
    end

    methods
        function obj = PathlossModelContainer()
            % class constructor construct a map and sets default parameters

            % Values based on 3GPP TR 25.951 v.8.0.0
            % For Macro cell base stations minimum coulping loss is 70 dB
            % For Micro cell base stations minimum coulping loss is 53 dB
            % For local area base stations (femto, pico) minimum coulping loss is 45 dB
            obj.minimumCouplingLossdB(parameters.setting.BaseStationType.macro) = 70;
            obj.minimumCouplingLossdB(parameters.setting.BaseStationType.pico)	= 53;
            obj.minimumCouplingLossdB(parameters.setting.BaseStationType.femto) = 45;

            obj.cellAssociationBiasdB(parameters.setting.BaseStationType.macro)   = 0;
            obj.cellAssociationBiasdB(parameters.setting.BaseStationType.pico)    = 0;
            obj.cellAssociationBiasdB(parameters.setting.BaseStationType.femto)   = 0;

            % initialize parameter storage for pathloss models
            obj.modelMap = cell( ...
                parameters.setting.BaseStationType.getLength(), ...
                parameters.setting.Indoor.getLength(), ...
                parameters.setting.Los.getLength() );

            % set free space model as default for all link types
            macro   = parameters.setting.BaseStationType.macro;
            pico    = parameters.setting.BaseStationType.pico;
            femto   = parameters.setting.BaseStationType.femto;
            indoor  = parameters.setting.Indoor.indoor;
            outdoor = parameters.setting.Indoor.outdoor;
            los     = parameters.setting.Los.LOS;
            nlos    = parameters.setting.Los.NLOS;
            obj.modelMap{macro, indoor,     los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{macro, indoor,     nlos}   = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{macro, outdoor,    los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{macro, outdoor,    nlos}   = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{pico,  indoor,     los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{pico,  indoor,     nlos}   = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{pico,  outdoor,    los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{pico,  outdoor,    nlos}   = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{femto, indoor,     los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{femto, indoor,     nlos}   = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{femto, outdoor,    los}    = parameters.pathlossParameters.FreeSpace;
            obj.modelMap{femto, outdoor,    nlos}   = parameters.pathlossParameters.FreeSpace;
        end

        function checkParameters(obj)
            % check parameters of the set models

            % check if cell association bias is defined for all base station types
            if length(obj.cellAssociationBiasdB) < parameters.setting.BaseStationType.getLength
                warn = 'Not all base station types have a minimum coupling loss defined.';
                warning('warn:noFemto', warn);
            end

            % check if minimum coupling loss is defined for all base station types
            if length(obj.cellAssociationBiasdB) < parameters.setting.BaseStationType.getLength
                warn = 'Not all base station types have a cell association bias defined.';
                warning('warn:noFemto', warn);
            end
        end
    end
end

