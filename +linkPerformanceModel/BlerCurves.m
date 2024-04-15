classdef BlerCurves < tools.HiddenHandle
    % BLERCURVES holds the curves that map from CQI and SINR to block error ratio (BLER)
    %
    % see also parameters.transmissionParameters.TransmissionParameters
    %
    % initial author: Thomas Dittrich
    % extended by: Areen Shiyahin
    %
    % see also linkPerformanceModel.LinkPerformanceModel

    properties
        % list of SINR values in dB that are used for mapping from SINR to BLER
        % [1 x 1 x nRedundancyVersoins] cell containing list of SINR values
        sinrList

        % resolution of SINR list
        % [1x1]double SINR resolution
        sinrResolution = 0.05;

        % minimal SINR value
        % [nRedundancyVersoins x 1]double minimum SINR value in SINR list
        % for each redundancy version
        sinrMin

        % list of BLER values
        % [nCQI x 1 x nRedundancyVersoins]cell of interpolated bler values
        % Holds one BLER value for each combination of
        % CQI and SINR value in sinrList
        blerCurves

        % list of SINR values for mapping from BLER to SINR
        % [nCQI x 1 x nRedundancyVersoins] cell containing a list of SINR
        % values for each CQI and redundancy version
        invSinrLists

        % list of BLER values for mapping from BLER to SINR
        % [nCQI x 1 x nRedundancyVersoins] cell containing a list of BLER
        % values for each CQI and redundancy version
        invBlerCurves

        % indicator for fast block error rate mapping
        % [1x1]logical indicates if fast BLER mapping is used
        fastBlerMapping

        % number of CQI values and BLER Curves
        % [1x1]integer
        nCQI
    end

    methods
        function obj = BlerCurves(cqiParameters, fastBlerMapping, redundancyVersion, cqiParameterType)
            % BLERCURVES class constructor for BLER curves
            %
            % input:
            %   cqiParameters:      [1x1]handleObject parameters.transmissionParameters.CqiParameters
            %   fastBlerMapping:    [1x1]logical indicator for fast BLER mapping
            %   redundancyVersoin:  [1xnRedundancyVersions] double redundancy version of codewords
            %   cqiParameterType:   [1x1]enum parameters.setting.CqiParameterType

            % set number of CQIs
            obj.nCQI = cqiParameters.nCqi;

            % set fast BLER mapping indicator
            if exist('fastBlerMapping','var') && islogical(fastBlerMapping)
                obj.fastBlerMapping = fastBlerMapping;
            else
                obj.fastBlerMapping = false;
            end

            % use all redundancy versions when Cqi64QAM parameters are used
            if cqiParameterType == 1

                % load from file SINR and BLER for all redundancy versions and determine range of SINR
                nRedundancyVersoins  = size(redundancyVersion,2);
                blerCurveList        = cell(obj.nCQI,1,nRedundancyVersoins);
                sinrList = cell(obj.nCQI,1,nRedundancyVersoins);
                sinrMin  = [inf,inf,inf,inf];
                sinrMax  = [-inf,-inf,-inf,-inf];
                for iRV  = 1: nRedundancyVersoins
                    for iCQI = 2:obj.nCQI
                        if exist(cqiParameters.getBlerCurveFiles(iCQI-1,iRV),'file')
                            load(cqiParameters.getBlerCurveFiles(iCQI-1,iRV));
                        else
                            error('Bler file ''%s'' do not exist',cqiParameters.getBlerCurveFiles(iCQI-1,iRV));
                            % BLER = [.5 .5];
                            % SNR = [0 1];
                        end
                        blerCurveList{iCQI,:,iRV} = BLER;
                        sinrList{iCQI,:,iRV} = SNR;
                        sinrMin(iRV) = min(min(SNR),sinrMin(iRV));
                        sinrMax(iRV) = max(max(SNR),sinrMax(iRV));
                    end
                end

                [blerCurveList{1,:,1},blerCurveList{1,:,2},...
                    blerCurveList{1,:,3},blerCurveList{1,:,4}]  = deal([0 0],[0 0],[0 0],[0 0]);

                [sinrList{1,:,1}, sinrList{1,:,2},...
                    sinrList{1,:,3},sinrList{1,:,4}]  = deal([sinrMin(1) sinrMax(1)],[sinrMin(2) sinrMax(2)],...
                    [sinrMin(3) sinrMax(3)],[sinrMin(4) sinrMax(4)]);

                % generate equally spaced lists of SINR values over the
                % whole SINR range; generate interpolated BLER curves over the
                % whole SINR range
                obj.sinrMin    = sinrMin(:);
                obj.sinrList   = cell(1,1,nRedundancyVersoins);
                [obj.sinrList{1},obj.sinrList{2},obj.sinrList{3},obj.sinrList{4}] =...
                    deal(sinrMin(1):obj.sinrResolution:sinrMax(1),...
                    sinrMin(2):obj.sinrResolution:sinrMax(2),sinrMin(3):obj.sinrResolution:sinrMax(3),...
                    sinrMin(4):obj.sinrResolution:sinrMax(4));
                obj.blerCurves     = cell(obj.nCQI,1,nRedundancyVersoins);
                obj.invSinrLists   = cell(obj.nCQI,1,nRedundancyVersoins);
                obj.invBlerCurves  = cell(obj.nCQI,1,nRedundancyVersoins);

                for iRV  = 1: nRedundancyVersoins
                    for iCQI = 1:obj.nCQI
                        currentSinr = sinrList{iCQI,:,iRV};
                        currentBler = blerCurveList{iCQI,:,iRV};

                        % expand BLER curve to sinrMin with a constant value
                        if currentSinr(1)>sinrMin(iRV)
                            currentSinr = [sinrMin(iRV) currentSinr];
                            currentBler = [currentBler(1) currentBler];
                        end

                        % expand BLER curve to sinrMax with a constant value
                        if currentSinr(end)<sinrMax(iRV)
                            currentSinr = [currentSinr sinrMax(iRV)];
                            currentBler = [currentBler currentBler(end)];
                        end

                        % linear interpolation to get BLER value for all SINR
                        % values in obj.sinrList
                        obj.blerCurves{iCQI,:,iRV} = interp1(currentSinr,currentBler,obj.sinrList{iRV});
                        [invBlerCurve, iSinr]      = unique(currentBler);
                        % generate inverse mapping
                        invSinrList = currentSinr(iSinr);
                        obj.invSinrLists{iCQI,:,iRV}  = invSinrList;
                        obj.invBlerCurves{iCQI,:,iRV} = invBlerCurve;
                    end
                end

            else  % use redundancy version 0 when Cqi256QAM or Cqi1024QAM parameters are used
                % indicating HARQ is not activated

                % load from file SINR and BLER for all redundancy versions and determine range of SINR
                nRedundancyVersoins  = size(redundancyVersion,2);
                blerCurveList        = cell(obj.nCQI,1,nRedundancyVersoins);
                sinrList = cell(obj.nCQI,1,nRedundancyVersoins);
                sinrMin  = [inf,inf,inf,inf];
                sinrMax  = [-inf,-inf,-inf,-inf];
                for iRV  = 1
                    for iCQI = 2:obj.nCQI
                        if exist(cqiParameters.getBlerCurveFiles(iCQI-1,iRV),'file')
                            load(cqiParameters.getBlerCurveFiles(iCQI-1,iRV));
                        else
                            error('Bler file ''%s'' do not exist',cqiParameters.getBlerCurveFiles(iCQI-1,iRV));
                            % BLER = [.5 .5];
                            % SNR = [0 1];
                        end
                        blerCurveList{iCQI,:,iRV} = BLER;
                        sinrList{iCQI,:,iRV} = SNR;
                        sinrMin(iRV) = min(min(SNR),sinrMin(iRV));
                        sinrMax(iRV) = max(max(SNR),sinrMax(iRV));
                    end
                end

                blerCurveList{1,:,1} = [0 0];
                sinrList{1,:,1} = [sinrMin(1) sinrMax(1)];

                % generate equally spaced lists of SINR values over the
                % whole SINR range; generate interpolated BLER curves over the
                % whole SINR range
                obj.sinrMin    = sinrMin(:);
                obj.sinrList   = cell(1,1,nRedundancyVersoins);
                obj.sinrList{1} = sinrMin(1):obj.sinrResolution:sinrMax(1);
                obj.blerCurves     = cell(obj.nCQI,1,nRedundancyVersoins); % zeros(obj.nCQI,length(obj.sinrList));
                obj.invSinrLists   = cell(obj.nCQI,1,nRedundancyVersoins);
                obj.invBlerCurves  = cell(obj.nCQI,1,nRedundancyVersoins);

                for iRV  = 1
                    for iCQI = 1:obj.nCQI
                        currentSinr = sinrList{iCQI,:,iRV};
                        currentBler = blerCurveList{iCQI,:,iRV};

                        % expand BLER curve to sinrMin with a constant value
                        if currentSinr(1)>sinrMin(iRV)
                            currentSinr = [sinrMin(iRV) currentSinr];
                            currentBler = [currentBler(1) currentBler];
                        end

                        % expand BLER curve to sinrMax with a constant value
                        if currentSinr(end)<sinrMax(iRV)
                            currentSinr = [currentSinr sinrMax(iRV)];
                            currentBler = [currentBler currentBler(end)];
                        end

                        % linear interpolation to get BLER value for all SINR
                        % values in obj.sinrList
                        obj.blerCurves{iCQI,:,iRV} = interp1(currentSinr,currentBler,obj.sinrList{iRV});
                        [invBlerCurve, iSinr]      = unique(currentBler);
                        % generate inverse mapping
                        invSinrList = currentSinr(iSinr);
                        obj.invSinrLists{iCQI,:,iRV}  = invSinrList;
                        obj.invBlerCurves{iCQI,:,iRV} = invBlerCurve;
                    end
                end
            end
        end

        function bler = getBler(obj, sinr, cqi, rv)
            % GETBLER maps from SINR and CQI to a BLER value for a certain
            %   redundancy version. Very low SINR values are constantly mapped to a BLER
            %   of 1 and very high SINR values to a BLER of 0. For all the
            %   values in between linear interpolation is used.
            %
            % input:
            %   sinr: [1 x N]double effective SINR value for each input CQI value
            %   cqi:  [1 x N]integer CQI values in the range from 1 to obj.nCQI
            %   rv:   [1x1]double index of redundancy version of a codeword
            %
            % output:
            %   bler:   [1 x N]double block error rate for each CQI

            if any(size(sinr) ~= size(cqi))
                error('BlerCurves:invalidDimensions', 'Dimensions of input variables must match');
            end

            if ~(all(cqi>=1) && all(cqi <=(obj.nCQI)))
                error('BlerCurves:invalidCQIvalues', 'Input CQI values must be in the range from 1 to %d.', (obj.nCQI));
            end

            if obj.fastBlerMapping
                % map SINR values to indices of BLER mapping
                iSinr = round((sinr-obj.sinrMin(rv+1))/obj.sinrResolution) + 1;

                % get number of possible SINR values to map to
                nSinr = length(obj.sinrList{rv+1});

                % set high SINRs to highest value
                iSinr(iSinr > nSinr)	= nSinr;
                % set low SINRs to lowest value
                iSinr(iSinr < 1)        = 1;

                % get linear indices of BLER in BLER curves with all cqi values
                iBler = cqi + size(obj.blerCurves,1)*(iSinr-1);
                blerCurves = cell2mat(obj.blerCurves(:,:,rv+1));
                bler = blerCurves(iBler);
            else
                nCQIvalues = size(cqi, 2);
                % initialize output
                bler = zeros(1, nCQIvalues);

                % intialize sinr list and bler curve of the redundancy version
                sinrValues = obj.sinrList{rv+1};
                blerValues = cell2mat(obj.blerCurves(:,:,rv+1));

                for iCQI = 1:nCQIvalues
                    if sinr(iCQI) < sinrValues(1)
                        % very low sinr - no successful transmission
                        bler(iCQI) = 1;
                    elseif sinr(iCQI) > sinrValues(end)
                        % very high sinr - all transmissions succeed
                        bler(iCQI) = 0;
                    else
                        % interpolate between BLER values if SINR is in between
                        bler(iCQI) = interp1(sinrValues, blerValues(cqi(iCQI),:), sinr(iCQI));
                    end
                end % for all possible CQI values
            end % if fast mapping is used
        end

        function sinr = getSinr(obj, bler, cqi, rv)
            % GETSINR maps from BLER and CQI to a SINR value for a certain
            %   redundancy version. Very low BLER values are constantly mapped to an SINR of
            %   +inf and very high BLER values to an SINR of -inf. For all
            %   the values in between linear interpolation is used.
            %
            % input:
            %   bler: double array of any size
            %   cqi:  [1x1]integer in the range from 0 to obj.nCQI-1
            %   rv:   [1x1]double redundancy version of a codeword
            %
            % output:
            %   sinr: [size(bler)]double array of SINR values

            % check input values
            if length(cqi)~=1
                error('BlerCurves:invalidDimensions', 'Mapping only works for single CQI value');
            end

            if cqi<0 || cqi>15
                error('BlerCurves:invalidCQIvalue', 'Input CQI value must be in the range from 0 to %d.', (obj.nCQI-1));
            end

            invBlerCurve = obj.invBlerCurves{cqi+1,:,rv};
            invSinrList  = obj.invSinrLists{cqi+1,:,rv};
            if bler<invBlerCurve(1)
                sinr = inf; % bler of 0
            elseif bler>invBlerCurve(end)
                sinr = -inf; % bler of 1
            else
                sinr = interp1(invBlerCurve,invSinrList,bler);
            end
        end

        function plotBlerCurves(obj, cqiParameterType)
            %PLOTBLERCURVES plots the BLER curves for all modulation and coding schemes
            %
            % input:
            %   cqiParameterType:   [1x1]enum parameters.setting.CqiParameterType

            % get the number of rednudancy versions
            nRedundancyVersoins = size(obj.sinrMin,1);

            if cqiParameterType == 1
                % plot BLER curves for each rednudancy version
                for iRV  = 1: nRedundancyVersoins
                    blerCurve = obj.blerCurves(:,:,iRV);
                    figure()
                    semilogy(obj.sinrList{iRV},cell2mat(blerCurve));
                    grid on;
                    xlabel('SINR (dB)');
                    ylabel('BLER');
                    ylim([1e-6 1]);
                    title('AWGN Performance for all modulation and coding Schemes')
                end
            else
                iRV = 1;
                blerCurve = obj.blerCurves(:,:,iRV);
                semilogy(obj.sinrList{iRV}, cell2mat(blerCurve));
                grid on;
                xlabel('SINR (dB)');
                ylabel('BLER');
                ylim([1e-7 1]);
                title('AWGN Performance for all modulation and coding Schemes')
            end
        end
    end
end

