classdef Precoder5GDL < precoders.Precoder
    % Implementation of the 5G DL codebook according to TS 38.214 (V15.3.0)
    % (see Table 5.2.2.2.1-1)
    %
    % for single panel arrays with codebookmode=1
    %
    % Compatible with antenna:  networkElements.bs.AntennaArray
    % Compatible with feedback: LTEDLFeedback
    % Features: up to 6 transmit chains and 4 user layers.
    %
    % To support single polarized antenna arrays changes were made to the
    % precoders. The changes are documented in the precoder generation
    % function.
    %
    % initial author: Alexander Bokor
    %
    % See also: parameters.precoders.Precoder5G, precoders.Precoder,
    % feedback.LTEDLFeedback

    properties (Access=public)
        % 2D cell array with codebooks for {N1, N2} configurations with
        % [1 x nLayers]cell with
        % [nTX x nLayers x nPrecoders]complex codebook
        % stores codebooks for antenna arrays with nTX > 2
        codebooks

        % [1x2]cell with
        % [1 x nLayers]cell with
        % [nTX x nLayers x nPrecoders]complex codebook
        % stores codebooks for array with nTX <= 2
        basic_codebooks
    end

    properties (Constant,Access=private)
        % supported nTX configurations
        % [4x2]integer supported antenna configuration with [N1, N2] rows
        supportedConfigs = [[4,1];[6,1];[2,2];[3,2]];
    end

    methods
        function obj = Precoder5GDL()
            % Precalculate codebooks

            % codebooks for nTX <= 2
            obj.basic_codebooks{1} = {1};
            obj.basic_codebooks{2} = obj.calculateBasicCodebooks();
            % Codebooks for nTX > 2
            obj.codebooks = obj.calculateArrayCodebooks();
        end

        function codebook = getCodebook(obj, antennas)
            % get codebook for an antenna
            %
            % input:
            %   antennas: [nAnt x1]handleObject networkElements.bs.Atenna antenna
            % ouput:
            %   codebook:  [1 x nLayers]cell with
            %              [nTX x nLayers x nPrecoders]complex codebook

            %consider Distributed Antenna Systems with multiple antennas
            %per BS and Precoder

            if size(antennas,2) == 1
                %normal mode
                if antennas.nTX <= 2
                    codebook = obj.basic_codebooks{antennas(1).nTX};
                else
                    codebook = obj.codebooks{antennas(1).N1, antennas(1).N2};
                end
            else
                %DAS MODE

                %linearise antenna precoder into one dimension to allow
                %stacking
                if sum([antennas.nTX]) <= 2
                    codebook = obj.basic_codebooks{sum([antennas.nTX])};
                else
                    codebook = obj.codebooks{sum([antennas.nTX],2),1};
                end

            end
        end

    end

    methods (Access=protected)
        function precoder = calculatePrecoder(obj, assignedRBs, nLayer, antennas, feedback, iAntenna)
            % Calculates precoding matrix for each assigned RB.
            % The matrix is normalized such that the power of the output signal
            % is equal to the power of the input signal.
            % Gets called by the public getPrecoder(...) method.
            %
            % input:
            %   assignedRBs: [Nx1]integer specifies the index of RBs that are scheduled for the currently considered user
            %   nLayer:      [Nx1]integer specifies the number of layers in the assigned RBs
            %   antennas:    [NAntx1]handleObject networkElements.bs.Antenna antennas used in simulation
            %   feedback:    [1x1]feedback.FeedbackSuperclass feedback from currently considered user
            %   iAntenna:    [1x1]integer index of the antenna in the feedback
            %
            % output:
            %   precoder:    [Nx1]struct containing the precoders for all the scheduled RBs
            %       -W: [nTX x nLayer]complex precoder for this resource block
            %
            % where N is the number of allocated resource blocks

            switch feedback.txModeIndex
                case 1 % SISO
                    precoder(1:length(assignedRBs), 1) = struct('W', 1);

                case 4 % MIMO
                    % preallocate precoder struct
                    precoder(1:length(assignedRBs), 1) = struct('W', []);

                    % set precoder for each assigned resource block
                    for iRB = 1:length(assignedRBs)
                        PMI = feedback.PMI(assignedRBs(iRB));
                        cbook = obj.getCodebook(antennas);
                        bsPrecoder= cbook{nLayer(iRB)}(:, :, PMI + 1);
                        %get desired antenna precoder
                        precoder(iRB).W = obj.getDASAntennaPrecoder(antennas,iAntenna,bsPrecoder);
                    end % for all assigned resource block

                otherwise
                    error('PRECODERS:wrongTxMode', 'This txMode not yet implemented.');
            end
        end
    end

    methods (Access = private)
        function codebooks = calculateBasicCodebooks(~)
            % Calculate codebooks for 2 nTX.
            %
            % output: [1x2]cell with
            %         [nTX x nLayers x nPrecoders]complex codebook

            % 1 layer
            p1 = zeros(2, 1, 4);
            p1(:, :, 1) = 1/sqrt(2) * [1;  1 ];
            p1(:, :, 2) = 1/sqrt(2) * [1;  1i];
            p1(:, :, 3) = 1/sqrt(2) * [1; -1 ];
            p1(:, :, 4) = 1/sqrt(2) * [1; -1i];

            % 2 layers
            p2 = zeros(2, 2, 2);
            p2(:, :, 1) = 1/2 * [1, 1;  1, -1 ];
            p2(:, :, 2) = 1/2 * [1, 1; 1i, -1i];

            codebooks = {p1, p2};
        end

        function codebooks = calculateArrayCodebooks(obj)
            % Calculate codebooks for antenna arrays for each supported
            % configuration.
            %
            % output:
            %   codebook: 2D cell array with codebooks for {N1,N2} configurations with
            %             [1 x nLayers]cell array with
            %             [nTX x nLayers x nPrecoders]complex codebook
            % nTX = N1 * N2

            codebooks = cell(max(obj.supportedConfigs(:, 1)), ...
                max(obj.supportedConfigs(:, 2)));

            for iConfig = 1:size(obj.supportedConfigs,1)
                N1 = obj.supportedConfigs(iConfig, 1);
                N2 = obj.supportedConfigs(iConfig, 2);

                codebooks{N1, N2} = calculateCodebook_single_polarized(obj, N1, N2);

            end
        end

        function codebook = calculateCodebook_single_polarized(obj, N1, N2)
            % Calculate codebooks for an antenna array for up to 4 layers
            % according to TS 38.214 (V15.3.0) with codebookmode = 1
            %
            % Code paragraphs which introduce changes for compatbility with
            % single polarized antennas are marked with the MODIFICATION
            % tag.
            %
            % input:
            %   N1: number of rf chains in horizontal direction
            %   N2: number of rf chains in vertical direction
            % output:
            %   codebook: [1 x nLayers]cell array with
            %             [nTx x nLayers x nPrecoders]complex codebook
            %
            % usage: codebook for L layers and PMI = i: codebook{L}(:,:,i)

            % calculate parameters O1 and O2
            O1 = 4;
            if N2 > 1
                O2 = 4;
            else
                O2 = 1;
            end

            % calculate P_{CSI - RS}
            % MODIFICATION: This is only half (just one polarization)
            P = N1 * N2;

            % get mapping
            mapping = obj.getMapping(N1, N2, O1, O2);

            % values needed for codebook
            u = @(m) exp(2i * pi * m / (O2 * N2) * (0:N2 - 1));
            v = @(l,m) kron(exp(2i * pi * l / (O1 * N1) * (0:N1 - 1)), u(m))';
            v_tilda = @(l,m) kron(exp(4i * pi * l / (O1 * N1) * (0:(N1 / 2) - 1)), u(m))';
            theta = @(p) exp(1i * pi * p / 4);

            % Codebook for 1 layer
            % MODIFICATION: i2 not needed
            index = 1;
            for i12 = 0:(N2 * O2 - 1)
                for i11 = 0:(N1 * O1 - 1)
                    vlm = v(i11, i12);
                    codebook{1}(:, :, index) = 1/sqrt(P) * vlm;
                    index = index + 1;
                end
            end


            % 2 Layers
            index = 1;
            % MODIFICATION: i2 not needed
            % MODIFICATION: start at i13 = 2
            for i13 = 2:size(mapping{1}.i13, 2)
                k1 =  mapping{1}.i13{i13}(1);
                k2 =  mapping{1}.i13{i13}(2);
                for i12 = 0:(N2 * O2 - 1)
                    for i11 = 0:(N1 * O1 - 1)
                        vlm = v(i11, i12);
                        vlm_prim = v(i11 + k1, i12 + k2);
                        % MODIFICATION: only take the upper half matrix
                        codebook{2}(:, :, index) = 1/sqrt(2 * P) * [vlm, vlm_prim];
                        index = index + 1;
                    end
                end
            end


            % 3 Layers
            % MODIFICATION: only consider P >= 16
            index = 1;
            % MODIFICATION: i2 not needed
            % MODIFICATION: only consider i13 = 0
            for i13 = 0
                for i12 = 0:(N2 * O2 - 1)
                    for i11 = 0:(N1 * O1 - 1)
                        vlm_tilda = v_tilda(i11, i12);
                        vlm_tilda_hat = v_tilda(i11 + O1, i12 + O2);
                        thetap = theta(0);
                        % MODIFICATION: only take the upper half matrix
                        codebook{3}(:, :, index) = 1/sqrt(3 * P) * [vlm_tilda, vlm_tilda_hat, vlm_tilda; ...
                            thetap * vlm_tilda, thetap * vlm_tilda_hat, -thetap * vlm_tilda];

                        index = index + 1;
                    end
                end
            end


            % 4 Layers
            % MODIFICATION: only consider P >= 16
            index = 1;

            thetap = theta(0);
            for i13 = 0
                % MODIFICATION: only consider i13=0
                for i12 = 0:(N2*O2-1)
                    for i11 = 0:(N1*O1/2-1)
                        vlm_tilda = v_tilda(i11,i12);
                        vlm_tilda_hat = v_tilda(i11+O1,i12+O2);
                        % MODIFICATION: only take the upper half matrix
                        codebook{4}(:,:,index)= 1/sqrt(4*P)*[vlm_tilda,vlm_tilda,vlm_tilda_hat,vlm_tilda_hat;...
                            thetap*vlm_tilda,-thetap*vlm_tilda,thetap*vlm_tilda_hat,-thetap*vlm_tilda_hat];
                        index = index + 1;

                    end
                end
            end

        end

        function codebook = calculateCodebook(obj, N1, N2)
            % Calculate codebooks for an antenna array for up to 8 layers
            % according to TS 38.214 (V15.3.0) with codebookmode = 1
            %
            % input:
            %   N1: number of rf chains in horizontal direction
            %   N2: number of rf chains in vertical direction
            % output:
            %   codebook: [1x8]cell with
            %             [nTx x nLayers x nPrecoders]complex codebook
            %
            % This function is for future use, since we don't support
            % dual polarized arrays yet.
            % usage: codebook for L layers and PMI = i: codebook{L}(:,:,i)

            % calculate parameters O1 and O2
            O1 = 4;
            if N2 > 1
                O2 = 4;
            else
                O2 = 1;
            end

            % calculate P_{CSI-RS}
            P = 2 * N1 * N2;

            % get mapping
            mapping = obj.getMapping(N1, N2, O1, O2);

            % values needed for codebook
            u = @(m) exp(2i * pi * m / (O2 * N2) * (0:N2 - 1));
            v = @(l,m) kron(exp(2i * pi * l / (O1 * N1) * (0:N1 - 1)),u(m))';
            v_tilda = @(l,m) kron(exp(4i * pi * l / (O1 * N1) * (0:(N1 / 2) - 1)),u(m))';
            phi = @(n) exp(1i * pi * n / 2);
            theta = @(p) exp(1i * pi * p/4);

            % 1 Layer
            index = 1;
            for i2 = 0:3
                for i12 = 0:(N2 * O2 - 1)
                    for i11 = 0:(N1 * O1 - 1)
                        vlm = v(i11, i12);
                        codebook{1}(:, :, index) = 1/sqrt(P) * [vlm; phi(i2) * vlm];
                        index = index + 1;
                    end
                end
            end

            % 2 Layers
            index = 1;
            for i2 = 0:1
                for i13 = 1:size(mapping{1}.i13,2)
                    k1 =  mapping{1}.i13{i13}(1);
                    k2 =  mapping{1}.i13{i13}(2);
                    for i12 = 0:(N2 * O2 - 1)
                        for i11 = 0:(N1 * O1 - 1)
                            vlm = v(i11, i12);
                            vlm_prim = v(i11 + k1, i12 + k2);
                            codebook{2}(:,:,index) = 1/sqrt(2 * P) * [vlm, vlm_prim; ...
                                phi(i2) * vlm, -phi(i2) * vlm_prim];
                            index = index + 1;
                        end
                    end
                end
            end

            % 3 Layers
            index = 1;
            for i2 = 0:1
                if P < 16
                    for i13 = 0:size(mapping{2}.i13,2)-1
                        k1 =  mapping{2}.i13{i13 + 1}(1);
                        k2 =  mapping{2}.i13{i13 + 1}(2);
                        for i12 = 0:(N2 * O2 - 1)
                            for i11 = 0:(N1 * O1 - 1)
                                vlm = v(i11, i12);
                                vlm_prim = v(i11 + k1, i12 + k2);
                                phin = phi(i2);
                                codebook{3}(:, :, index) = 1/sqrt(3 * P) * [vlm, vlm_prim, vlm; ...
                                    phin * vlm, phin * vlm_prim, -phin * vlm];
                                index = index + 1;
                            end
                        end
                    end
                else
                    for i13 = 0:3
                        for i12 = 0:(N2 * O2 - 1)
                            for i11 = 0:(N1 * O1 / 2 - 1)
                                vlm_tilda = v_tilda(i11, i12);
                                phin = phi(i13);
                                thetap = theta(i2);
                                codebook{3}(:, :, index) = 1/sqrt(3 * P) * [vlm_tilda, vlm_tilda, vlm_tilda; ...
                                    thetap * vlm_tilda, -thetap * vlm_tilda, thetap * vlm_tilda; ...
                                    phin * vlm_tilda, phin * vlm_tilda, -phin * vlm_tilda; ...
                                    phin * thetap * vlm_tilda, -phin * thetap * vlm_tilda, -phin * thetap * vlm_tilda];
                                index = index + 1;

                            end
                        end
                    end
                end
            end

            % 4 Layers
            index = 1;
            for i2 = 0:1
                if P < 16
                    for i13 = 0:size(mapping{2}.i13,2) - 1
                        k1 =  mapping{2}.i13{i13 + 1}(1);
                        k2 =  mapping{2}.i13{i13 + 1}(2);
                        for i12 = 0:(N2 * O2 - 1)
                            for i11 = 0:(N1 * O1 - 1)
                                vlm = v(i11,i12);
                                vlm_prim = v(i11 + k1, i12 + k2);
                                codebook{4}(:, :, index) = 1/sqrt(4 * P) * [vlm, vlm_prim, vlm, vlm_prim; ...
                                    phi(i2) * vlm, phi(i2) * vlm_prim, -phi(i2) * vlm, -phi(i2) * vlm_prim];
                                index = index + 1;
                            end
                        end
                    end
                else
                    for i13 = 0:3
                        for i12 = 0:(N2 * O2 - 1)
                            for i11 = 0:(N1 * O1 / 2 - 1)
                                vlm_tilda = v_tilda(i11, i12);
                                phin = phi(i13);
                                thetap = theta(i2);
                                codebook{4}(:, :, index)= 1/sqrt(4 * P) * [vlm_tilda, vlm_tilda, vlm_tilda, vlm_tilda; ...
                                    thetap * vlm_tilda, -thetap * vlm_tilda, thetap * vlm_tilda, -thetap * vlm_tilda; ...
                                    phin * vlm_tilda, phin * vlm_tilda, -phin * vlm_tilda, -phin * vlm_tilda; ...
                                    phin * thetap * vlm_tilda, -phin * thetap * vlm_tilda, -phin * thetap * vlm_tilda, phin * thetap * vlm_tilda];
                                index = index + 1;

                            end
                        end
                    end
                end
            end % end 4 layers


            % 5 Layers
            index = 1;
            for i2 = 0:1
                phin = phi(i2);
                for i12 = 0:(N2 * O2 - 1)
                    for i11 = 0:(N1 * O1 - 1)
                        vlm = v(i11, i12);
                        vlm_p = v(i11 + O1, i12);
                        if N1 > 2 && N2 == 1
                            vlm_pp = v(i11 + 2 * O1, 0);
                        else
                            vlm_pp = v(i11 + O1, i12 + O2);
                        end
                        codebook{5}(:, :, index) = 1/sqrt(5 * P) * [vlm, vlm, vlm_p, vlm_p, vlm_pp; ...
                            phin * vlm, -phin * vlm, vlm_p, -vlm_p, vlm_pp];

                        index = index + 1;
                    end
                end
            end % end 5 layers

            % 6 Layers
            index = 1;
            for i2 = 0:1
                phin = phi(i2);
                for i12 = 0:(N2 * O2 - 1)
                    for i11 = 0:(N1 * O1 - 1)
                        vlm = v(i11, i12);
                        vlm_p = v(i11 + O1, i12);
                        if N1 > 2 && N2 == 1
                            vlm_pp = v(i11 + 2 * O1, 0);
                        else
                            vlm_pp = v(i11 + O1, i12 + O2);
                        end
                        codebook{6}(:, :, index) = 1/sqrt(6 * P) * [vlm, vlm, vlm_p, vlm_p, vlm_pp, vlm_pp; ...
                            phin * vlm, -phin * vlm, phin * vlm_p, -phin * vlm_p, vlm_pp, -vlm_pp];
                        index = index + 1;
                    end
                end
            end % end 6 layers

            % 7 Layers
            index = 1;
            if N1 == 4 && N2 == 1
                ni11 = N1 * O1 / 2 - 1;
            else
                ni11 = N1 * O1 - 1;
            end
            if N1 > 2 && N2 == 2
                ni12 = N2 * O2 / 2 - 1;
            else
                ni12 = N2 * O2 - 1;
            end
            for i2 = 0:1
                phin = phi(i2);

                for i12 = 0:ni12
                    for i11 = 0:ni11
                        if N2 == 1
                            vlm = v(i11, i12);
                            vlm_p = v(i11 + O1, 0);
                            vlm_pp = v(i11 + 2 * O1, 0);
                            vlm_ppp = v(i11 + 3 * O1, 0);
                        else
                            vlm = v(i11, i12);
                            vlm_p = v(i11 + O1, i12);
                            vlm_pp = v(i11, i12 + O2);
                            vlm_ppp = v(i11 + O1, i12 + O2);
                        end

                        codebook{7}(:, :, index) = 1/sqrt(7 * P) * [vlm, vlm, vlm_p, vlm_pp, vlm_pp, vlm_ppp, vlm_ppp; ...
                            phin * vlm, -phin * vlm, phin * vlm_p, vlm_pp, -vlm_pp, vlm_ppp, -vlm_ppp];
                        index = index + 1;
                    end
                end
            end % end 7 layers

            % 8 Layers
            index = 1;
            for i2 = 0:1
                phin = phi(i2);

                for i12 = 0:ni12
                    for i11 = 0:ni11
                        if N2 == 1
                            vlm = v(i11, i12);
                            vlm_p = v(i11 + O1, 0);
                            vlm_pp = v(i11 + 2 * O1, 0);
                            vlm_ppp = v(i11 + 3 * O1, 0);
                        else
                            vlm = v(i11, i12);
                            vlm_p = v(i11 + O1, i12);
                            vlm_pp = v(i11, i12 + O2);
                            vlm_ppp = v(i11 + O1, i12 + O2);
                        end


                        codebook{8}(:, :, index) = 1/sqrt(7 * P) * [vlm, vlm, vlm_p, vlm_p, vlm_pp, vlm_pp, vlm_ppp, vlm_ppp; ...
                            phin * vlm, -phin * vlm, phin * vlm_p, -phin * vlm_p, vlm_pp, -vlm_pp, vlm_ppp, -vlm_ppp];
                        index = index + 1;
                    end
                end
            end % end 8 layers
        end

        function mapping = getMapping(~, N1, N2, O1, O2)
            % Calculate mappings from i13 to [k1, k2]
            % according to 3GPP TS 38.214 Table 5.2.2.2.1-3 and 5.2.2.2.1-4
            %
            % input:
            %   N1: number of horizontal rf chains
            %   N2: number of vertical rf chains
            %   O1: oversampling factor horizontal
            %   O2: oversampling factor vertical
            %
            % output:
            %   mapping: [1x2]cell array with
            %            mapping{1} ... mapping for 1,2 layers
            %            mapping{2} ... mapping for 3,4 layers

            % Layer 1 and 2 3GPP TS 38.214 Table 5.2.2.2.1-3
            if N1 > N2 && N2 > 1
                mapping{1}.i13{1} = [0, 0];
                mapping{1}.i13{2} = [O1, 0];
                mapping{1}.i13{3} = [0, O2];
                mapping{1}.i13{4} = [2 * O1, 0];
            elseif N1 == N2
                mapping{1}.i13{1} = [0, 0];
                mapping{1}.i13{2} = [O1, 0];
                mapping{1}.i13{3} = [0, O2];
                mapping{1}.i13{4} = [O1, O2];
            elseif N1 == 2 && N2 == 1
                mapping{1}.i13{1} = [0, 0];
                mapping{1}.i13{2} = [O1, 0];
            else
                mapping{1}.i13{1} = [0, 0];
                mapping{1}.i13{2} = [O1, 0];
                mapping{1}.i13{3} = [2 * O1, 0];
                mapping{1}.i13{4} = [3 * O1, 0];
            end
            % Layer 3 and 4 3GPP TS 38.214 Table 5.2.2.2.1-4
            if N1 == 2 && N2 == 1
                mapping{2}.i13{1} = [O1, 0];
            elseif N1 == 4 && N2 == 1
                mapping{2}.i13{1} = [O1, 0];
                mapping{2}.i13{2} = [2 * O1, 0];
                mapping{2}.i13{3} = [3 * O1, 0];
            elseif N1 == 6 && N2 == 1
                mapping{2}.i13{1} = [O1,0];
                mapping{2}.i13{2} = [2*O1,0];
                mapping{2}.i13{3} = [3*O1,0];
                mapping{2}.i13{4} = [4*O1,0];
            elseif N1 == 2 && N2 == 2
                mapping{2}.i13{1} = [O1, 0];
                mapping{2}.i13{2} = [0, O2];
                mapping{2}.i13{3} = [O1, O2];
            elseif N1 == 3 && N2 == 2
                mapping{2}.i13{1} = [O1, 0];
                mapping{2}.i13{2} = [0, O2];
                mapping{2}.i13{3} = [O1, O2];
                mapping{2}.i13{4} = [2 * O1, 0];
            end
        end
    end

    methods (Static)
        function [isValid] = checkConfig(transmissionParameters, baseStations)
            % Checks if parameters are valid for this precoder type.
            %
            % input:
            %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
            %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
            %
            % output:
            %   isValid: [1x1]logical true if parameters are valid for this precoder
            %
            % see also: precoders.Precoder.checkConfigStatic

            isValid = true;

            if transmissionParameters.feedbackType == parameters.setting.FeedbackType.minimum
                warning("Minimum feedback is not compatible with the 5G or LTE precoders, currently it works with random precoder.");
                isValid = false;
                return;
            end

            antennaList = [baseStations.antennaList];

            for iBs = 1:length(baseStations)
                if size(baseStations(iBs).antennaList,2) > 1
                    % This Precoder is not designed to support multiple antenna configurations
                    warning("PRECODERS:distributedAntennaSystemSupport",...
                        ['The precoder Precoder5GDL might not work as intended with distributed antenna systems ',...
                        'if this is not intended select a different precoder or Antenna'])
                    isValid = false;
                end
            end

            if ~isa([antennaList.precoderAnalog],"precoders.analog.NoAnalogPrecoding")
                warning("PRECODERS:analogCompatibility", ...
                    "This digitial precoder is not tested for compatibility with the analog precoder. " + ...
                    "You may want to disable the analog precorder or select a different digital precoder.");
                isValid = false;
                return;
            end

            switch transmissionParameters.txModeIndex
                case 1 % SISO
                    % check if nTX is compatible with SISO transmission
                    nTX = unique([antennaList.nTX]);
                    if all(nTX ~= 1)
                        isValid = false;
                    end

                case 4 % MIMO
                    if ~isa(antennaList, "networkElements.bs.antennas.AntennaArray")
                        warning("PRECODERS:antennaCompatibility", ...
                            "This precoder is only compatible with antenna arrays.");
                        isValid = false;
                        return;
                    end
                    if ~all([antennaList.nPV] == 1 & [antennaList.nPH] == 1)
                        warning("PRECODERS:multipanelCompatibility", ...
                            "This precoder is not compatible with multi panel antenna arrays");
                        isValid = false;
                        return;
                    end
                    % check if configuration is supported
                    for i = 1:length(antennaList)
                        config = [antennaList(i).nH, antennaList(i).nV];
                        supported = false;
                        for j = 1:size(precoders.Precoder5GDL.supportedConfigs,1)
                            if all(precoders.Precoder5GDL.supportedConfigs(j,:) == config)
                                supported = true;
                                break;
                            end
                        end

                        if supported == false
                            warning("PRECODERS:invalidAntennaConf", ...
                                "This number of horizontal and vertical antennas is not supported");
                            isValid = false;
                        end
                    end

                otherwise
                    isValid = false;
            end % switch between transmit modes
        end
    end

end

