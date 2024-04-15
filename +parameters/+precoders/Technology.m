classdef Technology < parameters.precoders.Parameters
    %TECHNOLOGY Special precoder for spectrum sharing.
    % If multiple antennas of different technolgies are connected to a base
    % station, this precoder can be used. Each technology can be assigned
    % an individual antenna.
    %
    % see also parameters.precoders
    %
    % initial author: Alexander Bokor

    properties (Access = private)
        tech2PrecoderParams
    end

    methods
        function obj = Technology()
            % set default values to LTE and 5G precoder
            obj.setTechPrecoder( ...
                parameters.setting.NetworkElementTechnology.LTE, ...
                parameters.precoders.LteDL() ...
                );
            obj.setTechPrecoder( ...
                parameters.setting.NetworkElementTechnology.NRMN_5G, ...
                parameters.precoders.Precoder5G() ...
                );
        end

        function setTechPrecoder(obj, technology, precoder)
            % Set precoder parameters for technology
            % input:
            %   technology: [1x1]enum parameters.setting.NetworkElementTechnology
            %   precoder:   [1x1]handle parameters.precdoders.Parameters
            obj.tech2PrecoderParams{technology} = precoder;
        end

        function techPrecoder = getTechPrecoder(obj, technology)
            % Get precoder parameters for technology
            % input:
            %   technology: [1x1]enum parameters.setting.NetworkElementTechnology
            techPrecoder = obj.tech2PrecoderParams{technology};
        end

        function precoder = generatePrecoder(obj, transmissionParameters, baseStations)
            % Generate a precoder object for the given transmission parameters.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %   networkElements.bs.BaseStation base stations used with this
            %   precoder
            %
            % output:
            %   obj: [1x1]handleObject precoders.Precoder
            %
            % see also: parameters.precoders
            tech2Precoder = cell(1, length(obj.tech2PrecoderParams));
            for i = 1:length(obj.tech2PrecoderParams)
                if ~isempty(obj.tech2PrecoderParams{i})
                    tech2Precoder{i} = obj.tech2PrecoderParams{i}.generatePrecoder(transmissionParameters, baseStations);
                end
            end

            precoder = precoders.PrecoderTechnology(tech2Precoder);
        end

        function isValid = checkConfig(obj, transmissionParameters, baseStations)
            % Checks if parameters are valid for this precoder type.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % output:
            %   isValid: [1x1]logical true if parameters are valid for this precoder
            %
            % see also: parameters.precoders

            % if composite base stations are in use, get the sub base stations
            % only sub base stations are intersting for the precoders
            if isa(baseStations, "networkElements.bs.CompositeBasestation")
                baseStationList = baseStations.subBaseStationList;
            else
                baseStationList = baseStations;
            end

            bsTech = zeros(1, length(baseStationList));
            % check if all base stations have antennas of same technology
            for iBs = 1:length(baseStationList)
                if [baseStationList(iBs).antennaList.technology] ~= baseStationList(iBs).antennaList(1).technology
                    error("Something wrong happened in the composite base station creations.");
                end

                bsTech(iBs) = baseStationList(iBs).antennaList(1).technology;
            end

            antennaList = [baseStationList.antennaList];
            usedTechs = unique([antennaList.technology]);

            isValid = true;
            for i = 1:length(usedTechs)
                precoderParameter = obj.tech2PrecoderParams{usedTechs(i)};
                techBs = baseStationList(bsTech == usedTechs(i));
                isValid = isValid | precoderParameter.checkConfig(transmissionParameters, techBs);
            end
        end
    end
end

