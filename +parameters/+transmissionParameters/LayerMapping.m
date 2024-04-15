classdef LayerMapping < handle
    % LAYERMAPPING superclass for codewords to layer mapping functions
    %
    % initial author: Thomas Dittrich
    %
    % see also parameters.setting.LayerMappingType

    methods (Static, Abstract)
        % GETMAPPING returns a vector of layers for each codeword
        % mapping(i)=J ... codeword i is mapped to layers J (where J is
        % a vector)
        %
        % input:
        %   nCodewords: [1x1] integer number of codewords
        %   nLayers:    [1x1] integer number of transmission layers
        %
        % output:
        %   mapping: [1 x nCodewords] cell containing integer vectors that specify the assigned layers for each codeword
        [mapping] = getMapping(this, nCodewords, nLayers);

        % GETNLAYERSPERCODEWORD calculates the number of layers that are used for each codeword
        % nLayersPerCodeword(i)=j ... codeword i uses j layers
        %
        % input:
        %   nCodewords: [1x1] integer number of codewords
        %   nLayers:    [1x1] integer number of transmission layers
        %
        % output:
        %   nLayersPerCodeword: [1 x nCodewords] integer number of layers that are assigned to each of the codewords
        [nLayersPerCodeword] = getNLayersPerCodeword(this, nCodewords, nLayers);


        % DECIDEFORNLAYER decides for a number of transmission layers
        % and codewords based on the transmit mode and the rank
        % indicator feedback
        %
        % input:
        %   txModeIndex:	[1x1]integer transmit mode
        %   rankIndicator:	[1x1]integer feedback value
        %
        % output:
        %   nLayers:    [1x1]integer number of transmission layers
        %   nCodewords: [1x1]integer number of codewords
        [nLayers, nCodewords] = decideForNLayer(this, txModeIndex, rankIndicator)
    end

    methods (Static)
        function layerMapping = generateLayerMapping(type)
            % generates a layer mapping class according to settings
            %
            % input:
            %   type:   [1x1]enum parameters.setting.LayerMappingType
            %
            % output:
            %   layerMapping:   [1x1]handleObject parameters.transmissionParameters.LayerMapping

            switch type
                case parameters.setting.LayerMappingType.TS36211
                    layerMapping = parameters.transmissionParameters.LteLayerMappingTS36211();
                otherwise
                    error('LAYERMAPPING:unsupportetType', 'Please select a layer mapping type from parameters.setting.LayerMappingType.');
            end
        end
    end
end

