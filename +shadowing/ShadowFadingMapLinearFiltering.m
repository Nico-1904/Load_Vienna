classdef ShadowFadingMapLinearFiltering < tools.HiddenHandle
    % SHADOWFADINGMAPLINEARFILTERING generates a space-correlated shadow fading map by applying a linear filter to two dimensional gaussian noise
    %
    % This class is implemented according to the paper:
    % T. Dittrich, M. Taranetz and M. Rupp, "An Efficient Method for
    % Avoiding Shadow Fading Maps in System Level Simulations," WSA 2017;
    % 21th International ITG Workshop on Smart Antennas, Berlin, Germany,
    % 2017, pp. 1-8.
    % URL: http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=7956005&isnumber=7955935
    %
    % initial author: Thomas Dittrich

    properties (SetAccess=private,GetAccess=public)
        % ALPHA This is ln(2) divided by the decorrelation distance.
        % The decorrelation distance is the distance, for which the
        % autocorrelation function has decreased to 0.5. [meter]
        alpha

        % MEANSFV The average pathloss due to shadowing
        meanSFV

        % STDDEVSFV The standard deviation of the pathloss due to shadowing
        stdDevSFV

        % NMAPS Number of maps. This is typically equal to the number of BS
        nMaps

        % MAPCORR Correlation among maps for different BS
        mapCorr

        % RESOLUTION Resolution for quantization of the ROI. [meter/pixel]
        resolution

        % SIZEX Number of pixel in x-direction
        sizeX

        % SIZEY Number of pixel in y-direction
        sizeY
    end

    properties (Access=private)
        autocorrelation
        pathlossMapSpectra
        psd

        pathlossMaps
        isMapCalculated
    end

    methods
        function this = ShadowFadingMapLinearFiltering(sizeX,sizeY,nMaps,resolution, mapCorr, meanSFV, stdDevSFV, decorrDist)
            % input:
            %   sizeX      [1x1] integer number of pixels in x-direction
            %   sizeY      [1x1] integer number of pixels in y-direction
            %   nMaps      [1x1] integer number of generated SF maps
            %   resolution [1x1] double size of each pixel in meter
            %   mapCorr    [1x1] double correlation among different maps
            %   meanSFV    [1x1] double mean value of the gaussian
            %     shadow fading values
            %   stdDevSFV  [1x1] double standard deviation of the gaussian
            %     shadow fading values
            %   decorrDist [1x1] double decorrelation distance within a
            %     map, i.e., the distance at which the correlation has
            %     decayed to 0.5
            if exist('decorrDist','var')
                this.alpha = log(2)/decorrDist;
            else
                this.alpha = 1/20;
            end

            this.sizeX = sizeX;
            this.sizeY = sizeY;

            this.nMaps = nMaps;

            this.meanSFV	= meanSFV;
            this.stdDevSFV	= stdDevSFV;
            this.mapCorr	= mapCorr;

            this.resolution = resolution;

            distanceMap = zeros(sizeX*2, sizeY*2);

            % the implementation with meshgrid is equivalent to the
            % commented approach with the two for-loops, but it is faster
            [iX, iY] = meshgrid(1:sizeX+1,1:sizeY+1);
            distanceMap(1:sizeX+1,1:sizeY+1) = sqrt((iX'-1).^2+(iY'-1).^2);

            % use symmetry of map to safe computation time
            distanceMap(sizeX+2:end,1:(sizeY+1))=distanceMap(sizeX:-1:2,1:(sizeY+1));
            distanceMap(sizeX+2:end,sizeY+2:end)=distanceMap(sizeX:-1:2,sizeY:-1:2);
            distanceMap(1:(sizeX+1),sizeY+2:end)=distanceMap(1:(sizeX+1),sizeY:-1:2);
            this.autocorrelation = exp(-this.alpha*distanceMap*resolution);
            % energy spectral density of filter
            this.psd = fft2(this.autocorrelation);
            % neglect imaginary part of PSD if it is small enough. Indeed
            % the PSD should be purely real because the autocorrelation is
            % an even function.
            threshold = 1e3;
            if ~isreal(this.psd(:)) && min(abs(real(this.psd(:))))<threshold*max(abs(imag(this.psd(:))))
                fprintf('imaginary part of PSD too big to be neglected \n');
            else
                this.psd = real(this.psd);
                if find(this.psd<0,1)
                    % for small map sizes it occurs that the esd is negativ in
                    % some points.
                    warning('taking abs of PSD');
                    this.psd(this.psd<0) = 0;
                end
            end

            % normalize PSD so that the energy of the filter is 1
            s           = sum(this.psd(:));
            beta        = 4 * sizeX * sizeY/s;
            this.psd	= beta * this.psd;

            % gaussian noise maps need to be twice as big in every
            % dimension as the pathloss map. Otherwise there would be a
            % correlation between points that are far away from each other
            % due to the periodicity of the autocorrelation

            % generate white gaussian maps in frequency domain to get rid
            % of the fft calculation
            this.generateNewSpectra();
        end

        function generateNewSpectra(this)
            % GENERATENEWSPECTRA Generates a new random spectrum. A new set of correlated shadow fading values can be generated by calling this function without instantiating a new ShadowFadingMapLinearFiltering object

            % whiteGaussianMaps(:,:,this.nMaps+1) is the common map that is
            % used to generate the crosscorrelation between the maps
            whiteGaussianMaps = zeros(2*this.sizeX,2*this.sizeY,this.nMaps+1);
            whiteGaussianMaps(:,1:this.sizeY+1,:)          = sqrt(4*this.sizeX*this.sizeY/2)*complex(randn(2*this.sizeX,this.sizeY+1,this.nMaps+1),randn(2*this.sizeX,this.sizeY+1,this.nMaps+1));
            whiteGaussianMaps(1,1,:)                       = sqrt(4*this.sizeX*this.sizeY)*randn(1,1,this.nMaps+1);
            whiteGaussianMaps(1,this.sizeY+1,:)            = sqrt(4*this.sizeX*this.sizeY)*randn(1,1,this.nMaps+1);
            whiteGaussianMaps(this.sizeX+1,1,:)            = sqrt(4*this.sizeX*this.sizeY)*randn(1,1,this.nMaps+1);
            whiteGaussianMaps(this.sizeX+1,this.sizeY+1,:) = sqrt(4*this.sizeX*this.sizeY)*randn(1,1,this.nMaps+1);
            whiteGaussianMaps(this.sizeX+2:end,1,:)            = conj(whiteGaussianMaps(this.sizeX:-1:2,1,:));
            whiteGaussianMaps(this.sizeX+2:end,this.sizeY+1,:) = conj(whiteGaussianMaps(this.sizeX:-1:2,this.sizeY+1,:));
            whiteGaussianMaps(1,this.sizeY+2:end,:)            = conj(whiteGaussianMaps(1,this.sizeY:-1:2,:));
            whiteGaussianMaps(2:end,this.sizeY+2:end,:)        = conj(whiteGaussianMaps(end:-1:2,this.sizeY:-1:2,:));

            % correlate the maps
            this.pathlossMapSpectra = this.stdDevSFV*(sqrt(this.mapCorr)*whiteGaussianMaps(:,:,(this.nMaps+1)*ones(this.nMaps,1))...
                +sqrt(1-this.mapCorr)*whiteGaussianMaps(:,:,1:this.nMaps))...
                .* sqrt(this.psd(:,:,ones(this.nMaps,1)));

            % add mean to constant part of the map
            this.pathlossMapSpectra(1,1) = this.pathlossMapSpectra(1,1) + 4*this.sizeX*this.sizeY*this.meanSFV;

            this.isMapCalculated = false(this.nMaps,1);
        end

        function [sfm] = getPathlossMap(this, iMap, varargin)
            % GETPATHLOSSMAP Returns the full map of correlated shadow fading values.
            %
            % input:
            %   iMap:     [1x1] integer index of the map that should be
            %     calculated. If it doesn't exist or is empty, all maps are
            %     calculated.
            %   varargin: [1x1] cell
            % output:
            %   sfm: [sizeX x sizeY x 1] double map of correlated SFVs
            %        or
            %        [sizeX x sizeY x nMaps] double set of maps of
            %     correlated SFVs

            if exist('iMap','var') && ~isempty(iMap)
                if ~find(this.isMapCalculated)
                    this.pathlossMaps = zeros(this.sizeX,this.sizeY,this.nMaps);
                end
                if ~this.isMapCalculated(iMap)
                    map = ifft2(this.pathlossMapSpectra(:,:,iMap));
                    this.pathlossMaps(:,:,iMap) = map(1:this.sizeX,1:this.sizeY);
                    this.isMapCalculated(iMap) = true;
                end

                % only for debugging
                for i=1:length(varargin)
                    if ischar(varargin{i}) && strcmp(varargin{i},'checkSymmetry')
                        M=2*this.sizeX;
                        N=2*this.sizeY;
                        for iX = 1:2*this.sizeX
                            for iY = 1:2*this.sizeY
                                % check for conjugate symmetry
                                if this.pathlossMapSpectra(iX,iY,iMap) ~= conj(this.pathlossMapSpectra(mod(M-iX+1, M) + 1, mod(N-iY+1, N) + 1,iMap))
                                    fprintf('no conjugate symmetry at x=%i, y=%i, iMap=%i\n',iX,iY,iMap);
                                end
                            end
                        end
                    end
                end
                sfm = this.pathlossMaps(:,:,iMap);
            else
                sfm = zeros(this.sizeX,this.sizeY,this.nMaps);
                for iMap=1:this.nMaps
                    sfm(:,:,iMap) = this.getPathlossMap(iMap,varargin{:});
                end
            end
        end

        function [sfv] = getPathlossPoint(this, x, y, iMap)
            % GETPATHLOSSPOINT Calculates the correlated random values for
            % every coordinate P=(x(i),y(i)). For coordinates that do not
            % lie on the quantized grid, an interpolation is calculated by
            % means of zero padding.
            %
            % input:
            % x:    [Nx1] double x coordinates of the points for which the
            %   SFVs should be calculated. These coordinates are given in
            %   meters relative to leftmost position of the region of
            %   interest
            % y:    [Nx1] double y coordinates of the points for which the
            %   SFVs should be calculated. These coordinates are given in
            %   meters relative to leftmost position of the region of
            %   interest
            % iMap: [1x1] integer index of the map that should be
            %     calculated. If it doesn't exist or is empty, all maps are
            %     calculated.
            % output: [Nx1] double set of correlated SFVs for the specified
            %   points
            %         or
            %         [N x nMaps] double set of correlated SFVs for the
            %   specified points calculated once for every map
            if size(x,1)==1
                x=x';
            end
            if size(y,1)==1
                y=y';
            end
            if (size(x,1)~=size(y,1)) || size(x,2)~=1 || size(y,2)~=1
                error('The parameters x and y have to be vectors of same size\n\tsize(x)=[%i,%i]\n\tsize(y)=[%i,%i]',size(x,1),size(x,2),size(y,1),size(y,2));
            end
            if exist('iMap','var')
                fx=[0:this.sizeX,(this.sizeX+1:2*this.sizeX-1)-2*this.sizeX];
                fy=[0:this.sizeY,(this.sizeY+1:2*this.sizeY-1)-2*this.sizeY];
                Wx=exp(1i*pi*x/(this.resolution*this.sizeX)*fx);
                Wy=exp(1i*pi*y/(this.resolution*this.sizeY)*fy);
                S = this.pathlossMapSpectra(:,:,iMap);
                d = sum(Wx*S.*Wy,2);
                sfv = real(1/(4*this.sizeX*this.sizeY)*d+this.meanSFV);
            else
                sfv = zeros(length(x),this.nMaps);
                for iMap = 1:this.nMaps
                    sfv(:,iMap)=this.getPathlossPoint(x,y,iMap);
                end
            end
        end

        function [esd] = getESD(this)
            esd=this.psd;
        end

        function plotESD(this,fig)
            if exist('fig','var')
                figure(fig);
            else
                figure
            end
            surf(log10(this.psd),'EdgeAlpha',0);
        end

        function plotACF(this,fig,x0,y0)
            % GETACF Plots the desired correlation of the map to the point P=(x0,y0). If the point is not specified, it is set to the center of the map.
            if exist('fig','var')
                figure(fig);
            else
                figure
            end
            if exist('x0','var') && exist('y0','var')
                surf(this.getACF(x0,y0),'EdgeAlpha',0);
            else
                surf(this.getACF(floor(this.sizeX/2),floor(this.sizeY/2)),'EdgeAlpha',0);
            end
        end

        function acf = getACF(this,x0,y0)
            % GETACF Returns the desired correlation of the map to the point P=(x0,y0). If the point is not specified, it is set to the center of the map.
            if exist('x0','var') && exist('y0','var')
                acf = fftshift(this.autocorrelation);
                acf = acf((this.sizeX-x0+2):(2*this.sizeX-x0+1),(this.sizeY-y0+2):(2*this.sizeY-y0+1));
            else
                acf = this.autocorrelation;
            end
        end

        function plotMapSpectra(this,nMap,fig)
            if exist('fig','var')
                figure(fig);
            else
                figure
            end
            subplot(1,2,1)
            surf(real(this.pathlossMapSpectra(:,:,nMap)),'EdgeAlpha',0);
            view(0,90);
            subplot(1,2,2)
            surf(imag(this.pathlossMapSpectra(:,:,nMap)),'EdgeAlpha',0);
            view(0,90);
        end

        function plotPathlossMap(this,iMap,fig,varargin)
            if exist('fig','var') && ~isempty(fig)
                figure(fig);
            else
                figure
            end

            if exist('iMap','var') && ~isempty(iMap)
                surf((1:this.sizeX)*this.resolution,(1:this.sizeY)*this.resolution,this.getPathlossMap(iMap,varargin{:})','EdgeAlpha',0);
                view(0,90);
                grid on
                xlim([1, this.sizeX]*this.resolution);
                ylim([1, this.sizeY]*this.resolution);
            else
                m = ceil(sqrt(this.nMaps));
                n = ceil(this.nMaps/m);
                for iMap=1:this.nMaps
                    subplot(n,m,iMap)
                    surf((1:this.sizeX)*this.resolution,(1:this.sizeY)*this.resolution,this.getPathlossMap(iMap,varargin{:})','EdgeAlpha',0);
                    view(0,90);
                    grid on
                    xlim([1, this.sizeX]*this.resolution);
                    ylim([1, this.sizeY]*this.resolution);
                end
            end
            set(gcf,'NextPlot','add');
        end
    end
end

