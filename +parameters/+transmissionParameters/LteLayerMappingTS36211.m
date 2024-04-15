classdef LteLayerMappingTS36211 < parameters.transmissionParameters.LayerMapping
    % LTELAYERMAPPINGTS36211 maps codewords to layers according to TS36 211 V13.1.0 (2016-04).
    %
    % It is only possible to use at most two codewords, each codeword can
    % use at most 4 layers.
    % If there are two codewords and the number of layers is odd, the
    % second codeword uses one layer more than the first codeword.
    %
    % initial author: Thomas Dittrich
    %
    % see also linkPerformanceModel.LinkPerformanceModel.layerMapping

    methods (Static)
        function [mapping] = getMapping(nCodewords, nLayers)
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

            if nCodewords < 1 || nLayers < nCodewords
                error('LayerMapping:invalidParameters','nCodewords and nLayers must be > 0 and nCodewords >= nLayers')
            end

            % mapping cannot be a matrix because the rows would have different length
            mapping = cell(1,min(nCodewords,2));

            switch nCodewords
                case 1
                    if nLayers > 4
                        error('LayerMapping:invalidParameters','too many layers');
                    end
                    mapping(1) = {(1:nLayers)};

                case 2
                    if nLayers > 8
                        error('LayerMapping:invalidParameters','too many layers');
                    end
                    mapping(1) = {(1:floor(nLayers/2))};
                    mapping(2) = {(floor(nLayers/2)+1:nLayers)};

                otherwise
                    error('LayerMapping:invalidParameters','At most 2 codewords allowed');
            end
        end

        function [nLayersPerCodeword] = getNLayersPerCodeword(nCodewords, nLayers)
            % GETNLAYERSPERCODEWORD calculates the number of layers that are used for each codeword
            % nLayersPerCodeword(i)=j ... codeword i uses j layers
            %
            % input:
            %   nCodewords: [1x1] integer number of codewords
            %   nLayers:    [1x1] integer number of transmission layers
            %
            % output:
            %   nLayersPerCodeword: [1 x nCodewords] integer number of layers that are assigned to each of the codewords

            if nCodewords < 1 || nLayers < nCodewords || nLayers > 8
                error('LayerMapping:invalidParameters','nCodewords and nLayers must be > 0 and nCodewords >= nLayers')
            end

            switch nCodewords
                case 1
                    nLayersPerCodeword = nLayers;
                case 2
                    nLayersPerCodeword = [floor(nLayers/2) ceil(nLayers/2)];
                otherwise
                    error('LayerMapping:invalidParameters','At most 2 codewords allowed');
            end
        end

        function [nLayers, nCodewords] = decideForNLayer(txModeIndex, rankIndicator)
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
            %   nCodewords:	[1x1]integer number of codewords

            if txModeIndex==1 || txModeIndex==2 || txModeIndex==7
                % SIXO, TxD, beamforming
                nLayers    = 1;
                nCodewords = 1;
            else
                % OLSM, CLSM, and others
                nLayers    = rankIndicator;
                nCodewords = min(2, nLayers);
            end
        end
    end
end

