function myEcdf(data, varargin)
% plots ECDF of data
%
% input:
%   data:       [1 x N]double array of data values for which ECDF should be plotted
%   varargin:   [] line specification
%
% ECDF: Empirical Cumulative Distribution Function
%
% initial author: Agnes Fastenbauer
%
% see also tools.myEccdf, stairs, histcounts

hold on;

data = data(:); % vectorize
data(isnan(data)) = []; % remove nans
sortedData = sort(data);
sortedData(end+1) = inf;

[N, edges] = histcounts(data, sortedData);

if isempty(varargin)
    stairs([-inf edges(1:end-1)'], [0 cumsum(N)/(length(N))]);
else
    stairs([-inf edges(1:end-1)'], [0 cumsum(N)/(length(N))], varargin{:});
end
hold on;
ylim([0, 1]);
hold off;
end

