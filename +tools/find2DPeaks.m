function [rowIndex, colIndex] = find2DPeaks(dataMatrix, numPeaks)
% Function to find peaks in a 2D matrix.
% Find at most D dominant peaks from 2D matrix X and return their
% corresponding row and column indexes. The returned peaks are in
% descending order in peak heights.
%
% Input parameters:
%   dataMatrix: 2D data matrix containing the data to find peaks.

        % Find all regional peaks.
        xbk = findpeaks2D(dataMatrix);
        [rows, cols] = find(xbk);

        % Identify at most D dominant peaks.
        pkvalues  = dataMatrix(sub2ind(size(dataMatrix), rows, cols));
        [~, locs] = sort(pkvalues, 'descend');
        D         = min(numPeaks, length(locs));
        assert(D <= numPeaks);
        locs = locs(1:D);

        % Extract their indexes
        rowIndex = rows(locs);
        colIndex = cols(locs);

end

function peakmatrix = findpeaks2D(X, edge_flag, minpeakheight)
% peakmatrix = findpeaks2D(X,varargin)
%
% This function finds regional peaks in a 2 dimensional data matrix. If
% only the data matrix is given as an input, then edge points are not
% included as peaks (similar to findpeaks in one dimension). If another
% input is also given, then the edge points of the matrix are considered as
% potential peaks. The first matrix index of each multi-point peak is given
% as the location of the multi-point point peak.
%
% [...] = FINDPEAKS2D(X) gives the peak locations, not including edge
% points of the matrix.
%
% [...] = FINDPEAKS2D(X,1) gives the peak locations, including the edge
% points of the matrix by padding the input matrix with -inf.
% 
% [...] = FINDPEAKS2D(X,[],MINPEAKHEIGHT) gives the peak locations, not
% including the edge points, that have peak values above MINPEAKHEIGHT.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen
phased.internal.narginchk(1,3,nargin);

    if nargin < 3
        minpeakheight = -inf;
    end
    
    if nargin < 2
        edge_flag = false;
    end
    
    if(isempty(edge_flag)) 
        edge_flag = false;
    end
    
    if(edge_flag == true)
        [M, N]= size(X);        % if a second input is specified, include
        Y = -inf;               % edge points as potential peaks by padding
        Y = Y(ones(M+2,N+2));   % the input matrix with -inf.
        Y(2:M+1,2:N+1) = X;
        X = Y;
    end

    X(X < minpeakheight) = -inf;

    [M, N]= size(X); % recheck size in case they included edge points, and
                     % the input matrix has been padded with -infs
    peakmatrix = zeros(M,N);
    if M<3 || N<3
        return; % no interior points
    end

    %% Find Single-Point Peaks
    % this section implements an 8 connect version of imregionalmax,
    % but it does not include multi-point peaks. For
    % example, data block [0 0 1 2 2 0] will return no peaks.
    
    connectmatrix = zeros(M-2,N-2,8); % 8 connect subtraction matrix for
                                      % interior points
    a = X(2:M-1,2:N-1); % interior point matrix
    connectmatrix(:,:,1) = a - X(1:M-2,1:N-2); % top left
    connectmatrix(:,:,2) = a - X(1:M-2,2:N-1); % top
    connectmatrix(:,:,3) = a - X(1:M-2,3:N); % top right
    connectmatrix(:,:,4) = a - X(2:M-1,1:N-2); % left
    connectmatrix(:,:,5) = a - X(2:M-1,3:N); % right
    connectmatrix(:,:,6) = a - X(3:M,1:N-2); % bottom left
    connectmatrix(:,:,7) = a - X(3:M, 2:N-1); % bottom
    connectmatrix(:,:,8) = a - X(3:M, 3:N); % bottom right
    
    peakmatrix(2:M-1,2:N-1) = all(connectmatrix > 0,3);
    % the above line identifies single-point peaks
    
    
    %% Find Multi-Point Peaks
    % this section finds just the mult-point peaks
    
    multipeakmatrix = zeros(M,N); % This matrix has the locations of multi-
                                  % point peaks
    
    possmatrix = zeros(M,N);  % This possibility matrix has all groups of 
                           % points that could possibly qualify as a
                           % multi-point peak.
    possmatrix(2:M-1,2:N-1) = min(connectmatrix,[],3) == 0;
    % the above line identified flat spots (potential multi-point peaks) in
    % the input matrix
    possmatrix(X==-inf) = 0;
    possmatrixsave = possmatrix;
    
    if(sum(sum(possmatrix))>0)
        connectposs = zeros(M-2,N-2,8); % 8 connect matrix for interior points
        connectposs(:,:,1) = possmatrix(1:M-2,1:N-2); % left top
        connectposs(:,:,2) = possmatrix(1:M-2,2:N-1); % top
        connectposs(:,:,3) = possmatrix(1:M-2,3:N); % right top
        connectposs(:,:,4) = possmatrix(2:M-1,1:N-2); % left
        connectposs(:,:,5) = possmatrix(2:M-1,3:N); % right
        connectposs(:,:,6) = possmatrix(3:M,1:N-2); % left bottom
        connectposs(:,:,7) = possmatrix(3:M, 2:N-1); % bottom
        connectposs(:,:,8) = possmatrix(3:M, 3:N); % right bottom
        
        connectmatrix(connectposs==1) = 1;
        % The above line artificially makes each potential multi-point peak
        % value appear to be greater than it's surrounding potential multi-
        % point peak values. This is necessary to distinguish between real
        % multi-point peaks and flat groups (that aren't peaks) in the
        % following line.
        possmatrix(2:M-1,2:N-1) = -possmatrix(2:M-1,2:N-1) + 2*all(connectmatrix > 0,3);
        possmatrix = possmatrix.*possmatrixsave;
        % possmatrix now carries 1's for potential flat peak elements and
        % -1's in groups that are not flat peaks (infected)
        
        if(sum(sum(possmatrix>0))>0) %if there are still potential multi-point
                                  %peaks  
            vec = find(possmatrix==1);
            possmatrix(vec) = vec;        % Replace possible peak
            possmatrixsave = possmatrix;  % placeholders with their matrix
                                          % index value
            AllAdjacentPositiveAreNotEqual_flag = true;
            PositiveValues_flag = true;       
            layermin = zeros(M,N); % the minimum positive values of each
                                   % element and it's surrounding elements
            connectposs = zeros(M-2,N-2,9);
            while(PositiveValues_flag && AllAdjacentPositiveAreNotEqual_flag)
                % find infections and the indeces they will spread to.
                % They will spread to all adjacent elements with positive
                % values.
                [infectedRows, infectedCols] = find(possmatrix==-1); 
                step = numel(infectedRows);
                nextInfRows = zeros(step*8,1);
                nextInfCols = nextInfRows;
                nextInfRows(1:step) = infectedRows-1;
                nextInfCols(1:step) = infectedCols-1; % top left
                nextInfRows(step+1:2*step) = infectedRows-1;
                nextInfCols(step+1:2*step) = infectedCols; % top
                nextInfRows(2*step+1:3*step) = infectedRows-1;
                nextInfCols(2*step+1:3*step) = infectedCols+1; % top right
                nextInfRows(3*step+1:4*step) = infectedRows;
                nextInfCols(3*step+1:4*step) = infectedCols-1; % left
                nextInfRows(4*step+1:5*step) = infectedRows;
                nextInfCols(4*step+1:5*step) = infectedCols+1; % right
                nextInfRows(5*step+1:6*step) = infectedRows+1;
                nextInfCols(5*step+1:6*step) = infectedCols-1; % bottom left
                nextInfRows(6*step+1:7*step) = infectedRows+1;
                nextInfCols(6*step+1:7*step) = infectedCols; % bottom
                nextInfRows(7*step+1:8*step) = infectedRows+1;
                nextInfCols(7*step+1:8*step) = infectedCols+1; % bottom left
                nextInfections = sub2ind([M N],nextInfRows,nextInfCols);
                % kill infected and spread infection
                if possmatrix(nextInfections) == 0
                    possmatrix(infectedRows, infectedCols)=0;
                end
                possmatrix(nextInfections) = (-1)*(possmatrix(nextInfections)>0);
                           
                % Create 8-connect of the current possibility matrix
                connectposs(:,:,1) = possmatrix(1:M-2,1:N-2); % left top
                connectposs(:,:,2) = possmatrix(1:M-2,2:N-1); % top
                connectposs(:,:,3) = possmatrix(1:M-2,3:N); % right top
                connectposs(:,:,4) = possmatrix(2:M-1,1:N-2); % left
                connectposs(:,:,5) = possmatrix(2:M-1,3:N); % right
                connectposs(:,:,6) = possmatrix(3:M,1:N-2); % left bottom
                connectposs(:,:,7) = possmatrix(3:M, 2:N-1); % bottom
                connectposs(:,:,8) = possmatrix(3:M, 3:N); % right bottom
                connectposs(:,:,9) = possmatrix(2:M-1,2:N-1); % center
                
                % test if it is finished by seeing if all members of the 
                % same multi-point group have the same positive value
                % (index). Do this by seeing if the minimum of each
                % positive element and its adjacent elements is the same as
                % the maximum of each positive element and its adjacent
                % element
                finishtestmax = max(connectposs,[],3);
                connectposs(connectposs<=0) = inf;
                finishtestmin = min(connectposs,[],3);
                finishtestmax(possmatrix(2:M-1,2:N-1) <= 0) = 0;
                finishtestmin(possmatrix(2:M-1,2:N-1) <= 0) = 0;
                if(isequal(finishtestmin,finishtestmax)...
                       && sum(sum(possmatrix<0)) == 0)
                    AllAdjacentPositiveAreNotEqual_flag = false;
                end
                
                % Spread minimum index to adjacent members of the same
                % group. This is done after the finishing flag test above
                % because it would require extra steps in each loop to put
                % it before. This is because I am comparing the minimum
                % positive value to the maximum positive value, so it would
                % require to set all non-positive values to inf, then set
                % them back to zero after the spread. I am avoiding this by
                % putting it after.
                layermin(2:M-1,2:N-1) = min(connectposs,[],3);
                % FIXuse a saved logical possmatrix>0 for next 3 calls
                possmatrix(possmatrix>0) = layermin(possmatrix>0);

                if(sum(sum(possmatrix>0))==0) % check if any possible multi-
                    PositiveValues_flag = false;       % point peaks remain
                end
            end
            % once the iterations are done, get the peak location of each
            % multi-point peak
            possmatrix(possmatrix<1) = -inf;
            multipeakmatrix = double(ismember(possmatrixsave,possmatrix)); % peak locations
        end
    end
    %% Combine Single-Point and Multi-Point to Get All Peaks

    peakmatrix = peakmatrix + multipeakmatrix;
    
    if( edge_flag == true ) % fix the size if they included edge points
         peakmatrix = peakmatrix(2:M-1,2:N-1);
    end
             
end

