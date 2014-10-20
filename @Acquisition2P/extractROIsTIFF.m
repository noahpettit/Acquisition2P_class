function [traces,roiList,roiMat] = extractROIsTIFF(obj,roiGroups,movNums,sliceNum,channelNum,doSubtraction)

% Function for extracting ROIs from movies using grouping assigned by
% selectROIs. This function motion corrected tiff files. See extractROI for a
% sometimes faster method using a memory mapped 'indexed' binary file instead.

%roiGroups is a scalar or vector of desired groupings to extract ROIs for, defaults to all grouping (1:9)
%movNums is a vector of movie numbers to use, defaults to all movies

%traces - matrix of n_cells x n_frames fluorescence values, using neuropil correction for ROIs with a matched neuropil ROI
%rawF - matrix of same size as traces, but without using neuropil correction
%roiList - vector of ROI numbers corresponding to extracted ROIs

%% Input Handling
if ~exist('sliceNum','var') || isempty(sliceNum)
    sliceNum = 1;
end
if ~exist('channelNum','var') || isempty(channelNum)
    channelNum = 1;
end
if ~exist('movNums','var') || isempty(movNums)
    movNums = 1:length(obj.correctedMovies.slice(sliceNum).channel(channelNum).fileName);
end
if ~exist('roiGroups','var') || isempty(roiGroups)
    roiGroups = 1:9;
end
if ~exist('doSubtraction','var') || isempty(doSubtraction)
    doSubtraction = 1;
end

%% ROI Extraction

%Find relevant ROIs
roiGroup = obj.roiInfo.slice(sliceNum).grouping;
roiList = find(ismember(roiGroup,roiGroups));

%Construct matrix of ROI values
roiMat = [];
for nROI = 1:length(roiList)
    mask = zeros(size(obj.roiInfo.slice(sliceNum).roiLabels));
    cellBodyInd = obj.roiInfo.slice(sliceNum).roi(roiList(nROI)).indBody;
    mask(cellBodyInd) = 1/length(cellBodyInd);
    if doSubtraction && ~isempty(obj.roiInfo.slice(sliceNum).roi(roiList(nROI)).indNeuropil)
        neuropilInd = obj.roiInfo.slice(sliceNum).roi(roiList(nROI)).indNeuropil;
        subCoef = obj.roiInfo.slice(sliceNum).roi(roiList(nROI)).subCoef;
        mask(neuropilInd) = -subCoef/length(neuropilInd);
    end
    roiMat(:,end+1) = reshape(mask,[],1);
end

%Loop over movie files, loading each individually and concatenating traces
traces = [];
for nMovie = movNums
    fprintf('Loading movie %03.0f of %03.0f\n',find(nMovie==movNums),length(movNums)),
    mov = readCor(obj,nMovie,'double');
    mov = reshape(mov,[],size(mov,3));
    traces = cat(2,traces,roiMat'*mov);
end

