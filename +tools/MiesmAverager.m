classdef MiesmAverager < tools.HiddenHandle
    % MIESMAVERAGER Mutual Information Effective SINR Mapping
    %   Maps multiple SINR values to an effective SINR according to a method
    % called Mutual Information Effective SINR Mapping (MIESM). For a given
    % modulation and coding scheme the resulting effective SINR value
    % has equivalent AWGN BLER performance. The main part of the averaging
    % process is as follows:
    %   - For each SINR value the mutual information is calculated based on
    %     a calibrated capacity curve for a given modulation and coding scheme.
    %   - The transformed values are linearly averaged.
    %   - The averaged value is transformed back to the SINR domain where the
    %     result of this inverse transformation is called the effective SINR.
    %
    % see also linkPerformanceModel.LinkPerformanceModel
    %
    % initial author: Thomas Dittrich
    % extended by: Thomas Lipovec, additional code documentation

    properties (SetAccess = private, GetAccess = public)
        % MUTUALINFORMATIONMATRIX contains the mutual information (MI) curves
        % [N1xM1] double
        % The i-the row contains the mutual information (MI) curve for the
        % modulation type i. The number of modulation types depends on the
        % choosen CQI parameters.
        mutualInformationMatrix

        % INVERSESINRMATRIX contains the SINR values for the inverse mapping
        % [N2xM2]double
        % The i-th row contains the sinr value for the inverse mapping for
        % modulation type i.
        inverseSinrMatrix

        % SINRLIST contains the SINR values (in dB) of the MI curves
        % [1xM1]double
        sinrList

        % MILIST contains the MI values which are used for the inverse mapping
        % [1xM2]double
        miList

        % CQIPARAMETERS CQI parameters used for the SINR averaging
        % [1x1]parameters.transmissionParameters.CqiParameters
        cqiParameters

        % FASTAVERAGING specifies if fast averaging should be used or not
        % [1x1]logical
        % For fast averaging the given SINR values are mapped to the nearest
        % SINR values in the sinrList based on the sinrResolution. It
        % therefore avoids a interpolation between SINR values as it is
        % done when fastAveraging = false.
        fastAveraging

        % SINRRESOLUTION resolution of sinrList
        % [1x1]double
        sinrResolution

        % SINRMIN smallest sinr value in sinrList
        % [1x1]double
        sinrMin

        % MIRESOLUTION resolution of miList
        % [1x1]double
        miResolution

        % MIMIN smallest mutual information value in miList
        % [1x1]double
        miMin
    end

    methods
        function obj = MiesmAverager(cqiParameters, file, fastAveraging)
            % MIESMAVERAGER creates an SINR averager which uses MIESM to calculate the effective SINR
            % Sets the class properties based on the choosen CQI parameters
            % and loads the mutual information curves that are needed for
            % the averaging process.
            %
            % input:
            %   cqiParameters: [1x1] parameters.transmissionParameters.CqiParameters
            %   file:          [1xN] char path of the file that holds a table of mutual information values
            %   fastAveraging: [1x1] logical selects whether fast averaging should be used or not

            if length(cqiParameters.getBetaMIESMCalibration) < cqiParameters.nCqi
                error('MiesmAverager:invalidCalibrationParameters','property betaMIESMCalibration of cqiParameters must contain values');
            end

            obj.cqiParameters = cqiParameters;
            obj.sinrResolution = 0.01;

            if exist('file','var')
                obj.initializeMutualInformationMatrix(file);
            else
                obj.initializeMutualInformationMatrix();
            end

            if exist('fastAveraging','var') && islogical(fastAveraging)
                obj.fastAveraging = fastAveraging;
            else
                obj.fastAveraging = false;
            end
        end

        function effectiveSinrdB = average(obj, sinrListToAverage, cqiList)
            % AVERAGE calculates an effective SINR value
            % Translates a list of possibly varying SINR values to an
            % effective SINR value based on Mutual Information Effective
            % SINR Mapping (MIESM). Note that the averaging is w.r.t. the
            % mutual information and not the SINR itself.
            %
            % input:
            %   sinrListToAverage: [N x 1]double vector of SINR values in dB
            %   cqiList:           [1 x nCQI]integer cqi values for which the averaging should be performed
            %
            % output:
            %   effectiveSinrLogarithmic: [1x1]double effective SINR in dB

            % check CQI input values
            if ~(all(cqiList>=0) && all(cqiList <=15))
                error('MiesmAverager:invalidCQIvalues', 'Input CQI values must be in the range from 0 to 15.');
            end

            % reshape SINR to vector
            sinrListToAverage = reshape(sinrListToAverage,[],1);

            % get calibration parameters for all CQI parameters
            beta = obj.cqiParameters.getBetaMIESMCalibration(cqiList);
            betadB = 10*log10(beta);

            % get modulation type for all CQI parameters
            modulationType = obj.cqiParameters.getModulationType(cqiList);

            % calibrate sinr for all CQI parameters by dividing through the calibration parameters
            sinrListToAverage = repmat(sinrListToAverage, 1, length(betadB)) - repmat(betadB, length(sinrListToAverage), 1);

            if obj.fastAveraging
                % map SINR values to indices of the SINR list based on the SINR resolution
                iSinr = round((sinrListToAverage-obj.sinrMin)/obj.sinrResolution)+1;
                % number of possible SINR values
                nSinr = length(obj.sinrList);
                % limit range to possible indices of MI matrix
                iSinr(iSinr>nSinr) = nSinr;
                iSinr(iSinr<1)     = 1;
                % map SINR indices to indices of the corresponding mutual information for each modulation type
                iMi = repmat(modulationType, size(iSinr, 1), 1) + size(obj.mutualInformationMatrix,1)*(iSinr-1);
                % read out the MI values
                mi = obj.mutualInformationMatrix(iMi);
                % compute the average
                miMean = mean(mi,1);
                % map the average value to index for the inverse mapping
                iMi = round((miMean-obj.miMin)/obj.miResolution);
                % map back to SINR
                iSinr = modulationType+size(obj.inverseSinrMatrix,1)*iMi;
                effectiveSinrdB = obj.inverseSinrMatrix(iSinr);
            else
                % preallocate result
                effectiveSinrdB = zeros(size(cqiList));
                % limit range to possible SINR values
                sinrListToAverage(sinrListToAverage>obj.sinrList(end)) = obj.sinrList(end);
                sinrListToAverage(sinrListToAverage<obj.sinrList(1))   = obj.sinrList(1);
                % calculate effective SINR for each CQI value
                for i = 1:length(cqiList)
                    % read out mutual information values with linear interpolation
                    mi = interp1(obj.sinrList, obj.mutualInformationMatrix(modulationType(i),:), sinrListToAverage(:,i));
                    % compute the average
                    miMean = mean(mi);
                    % map back to SINR with linear interpolation
                    effectiveSinrdB(i) = interp1(obj.miList, obj.inverseSinrMatrix(modulationType(i),:), miMean);
                end
            end

            % recalibrate result
            effectiveSinrdB = reshape(effectiveSinrdB + betadB,size(cqiList));
        end

        function initializeMutualInformationMatrix(obj, file)
            % INITIALIZEMUTUALINFORMATIONMATRIX loads the mutual information or generates it
            % The file should include a variable of type struct named
            % 'BICM_capacity_tables' with the following three fields:
            %   - m_j: modulation order
            %   - SNR: SNR values for the capacity curves
            %   - I:   corresponding MI values
            %
            % input:
            %   file:   [1xN]char path of the file that holds a table of mutual information values

            if exist('file','var') && exist(file,'file')
                % load from file
                load(file, 'BICM_capacity_tables');

                % set first and last value of each curve to idealized
                % values
                for iBICMTable = 1:length(BICM_capacity_tables)
                    BICM_capacity_tables(iBICMTable).I(1) = 0;
                    BICM_capacity_tables(iBICMTable).I(end) = ceil(BICM_capacity_tables(iBICMTable).I(end));
                end

                % get parameters of all Modulation an Coding Schemes
                modulationOrderList = obj.cqiParameters.getModulationOrder;
                modulationTypeList  = obj.cqiParameters.getModulationType;

                % create a list of all possible modulation schemes
                [modulationTypeList, i] = unique(modulationTypeList);
                modulationOrderList = modulationOrderList(i);

                % determine the upper bound of the range in which all
                % modulation types are. 1 is the lower bound.
                modulationTypeRange = max(modulationTypeList);


                % generate SINR values for SINR-to-MI mapping
                minSinr = min(BICM_capacity_tables(1).SNR);
                maxSinr = max(BICM_capacity_tables(1).SNR);
                obj.sinrMin = minSinr;
                obj.sinrList = minSinr:obj.sinrResolution:maxSinr;

                % add capacity table for zero cqi
                BICM_capacity_tables = [BICM_capacity_tables, struct('m_j',0,'I',[0 0],'SNR',[minSinr maxSinr])];

                % generate MI values for SINR-to-MI mapping
                obj.mutualInformationMatrix = zeros(modulationTypeRange,length(obj.sinrList));
                for iModOrder = 1:length(modulationOrderList)
                    iBICMTable = find([BICM_capacity_tables.m_j]==modulationOrderList(iModOrder),1,'first');
                    obj.mutualInformationMatrix(modulationTypeList(iModOrder),:)=interp1(BICM_capacity_tables(iBICMTable).SNR, BICM_capacity_tables(iBICMTable).I, obj.sinrList);
                end

                % generate vector of mutual information values MI-to-SINR
                % mapping
                minimumMutualInformation = min(obj.mutualInformationMatrix(:));
                maximumMutualInformation = max(obj.mutualInformationMatrix(:));
                obj.miList = linspace(minimumMutualInformation,maximumMutualInformation,length(obj.sinrList));
                obj.miResolution = obj.miList(2)-obj.miList(1);
                obj.miMin = obj.miList(1);

                % generate SINR values for MI-to-SINR mapping
                obj.inverseSinrMatrix = zeros(modulationTypeRange,length(obj.sinrList));
                for iModOrder = 1:length(modulationOrderList)
                    [mi, i] = unique(obj.mutualInformationMatrix(modulationTypeList(iModOrder),:),'first');
                    inverseSinr = obj.sinrList(i);
                    if length(mi)>1
                        % this will be NaN for
                        % this.miList>modulationOrderList(iModOrder)
                        obj.inverseSinrMatrix(modulationTypeList(iModOrder),:)=interp1(mi,inverseSinr,obj.miList);

                        % make sure that maximum mutual information of each
                        % curve is within the interpolation range
                        maxMI = max(obj.mutualInformationMatrix(modulationTypeList(iModOrder),:));
                        iMaxMI = find(obj.miList>=maxMI,1,'first');
                        obj.inverseSinrMatrix(modulationTypeList(iModOrder), iMaxMI) = interp1(obj.miList(1:(iMaxMI-1)),...
                            obj.inverseSinrMatrix(modulationTypeList(iModOrder),1:(iMaxMI-1)),...
                            obj.miList(iMaxMI),...
                            'linear',...
                            'extrap');
                    else % for cqi=0 the mutual information curve is constant zero. For the inverse mapping we constantly map to -inf
                        obj.inverseSinrMatrix(modulationTypeList(iModOrder),:)=-inf;
                    end
                end

            else
                % dummy values
                nModulationTypes = 3; % get from config
                obj.sinrList = -10:30;
                miMatrix = zeros(nModulationTypes,length(obj.sinrList));
                l=2.^(0:nModulationTypes-1);
                for iModType = 1:nModulationTypes
                    miMatrix(iModType,:)=min(log2(1+10.^(obj.sinrList/10)),l(iModType)).*((sign(obj.sinrList).*(1-exp(-abs(obj.sinrList)/5))+1)/2);
                end
            end
        end

        function plotMutualInformationMatrix(obj)
            %PLOTMUTUALINFORMATIONMATRIX plots the MI curves for all modulation types

            plot(obj.sinrList, obj.mutualInformationMatrix(2:end, :), 'LineWidth', 1);
            grid on;
            xlabel('SINR (dB)');
            ylabel('Mutual Information (bit/s/Hz)');
            xlim([obj.sinrMin,max(obj.sinrList)])
            title('BICM capacity for various modulation orders')

            % get modulation names of all Modulation an Coding Schemes
            modulationNameList = obj.cqiParameters.getModulationName;
            [modulationNameList, ~] = unique(modulationNameList, 'stable');
            modulationNameList = modulationNameList(2:end);

            legend(modulationNameList, 'Location', 'northwest');
        end
    end
end

