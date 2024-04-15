function newIndices = ind2BigInd(indices, arrayDimOld, arrayDimNew)
% maps linear indices from two dimensional matrix to three dimensional matrix
% This function returns linear indexing for an array of dimension
% [arrayDimOld(1) x arrayDimOld(2) x arrayDimNew] for the given linear
% indices in arrayDimOld.
%
% Example:
% We have the linear indices [3, 5] of an array of size arrayDimOld [2x4].
% We now want to map them to linear indexing for a larger array of size
% arrayDimNew [arrayDimOld x 3]=[2x4x3]. This means we want to get
% [3, 5, 11, 13, 19, 21] as linearIndicesArbitraryDimension.
%
% input:
%   indices:        [nElements x 1]integer indices in arrayDimOld
%   arrayDimOld:    [1x2]integer dimension of array of indices
%   arrayDimNew:    [1x1]integer size of additional dimension
%
% output:
%   newIndices: [nElements*arrayDimNew x 1]integer linear indices in new array
%
% initial author: Agnes Fastenbauer

nInd = length(indices);
[ind1, ind2] = ind2sub(arrayDimOld, indices);
newIndices = sub2ind([arrayDimOld, arrayDimNew], ...
    repmat(ind1, arrayDimNew, 1), repmat(ind2, arrayDimNew, 1), ...
    repelem(1:arrayDimNew, 1, nInd)');
end

