function [RI,PMISet] = riSelect(carrier,csirs,reportConfig,H,varargin)
% riSelect Rank indicator calculation
%   [RI,PMISET] = hRISelect(CARRIER,CSIRS,REPORTCONFIG,H) returns the
%   downlink channel rank indicator (RI) value RI and corresponding
%   precoding matrix indicator (PMI) values PMISET, as defined in TS 38.214
%   Section 5.2.2.2, for the specified carrier configuration CARRIER,
%   CSI-RS configuration CSIRS, channel state information (CSI) reporting
%   configuration REPORTCONFIG, and estimated channel information H.
%   
%   CARRIER is a carrier specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a>. Only these object properties are relevant for this
%   function:
%
%   SubcarrierSpacing - Subcarrier spacing in kHz
%   CyclicPrefix      - Cyclic prefix type
%   NSizeGrid         - Number of resource blocks (RBs) in
%                       carrier resource grid
%   NStartGrid        - Start of carrier resource grid relative to common
%                       resource block 0 (CRB 0)
%   NSlot             - Slot number
%   NFrame            - System frame number
%
%   CSIRS is a CSI-RS specific configuration object to specify one or more
%   CSI-RS resources, as described in <a href="matlab:help('nrCSIRSConfig')">nrCSIRSConfig</a>. Only these object
%   properties are relevant for this function:
%
%   CSIRSType           - Type of a CSI-RS resource {'ZP', 'NZP'}
%   CSIRSPeriod         - CSI-RS slot periodicity and offset
%   RowNumber           - Row number corresponding to a CSI-RS resource, as
%                         defined in TS 38.211 Table 7.4.1.5.3-1
%   Density             - CSI-RS resource frequency density
%   SymbolLocations     - Time-domain locations of a CSI-RS resource
%   SubcarrierLocations - Frequency-domain locations of a CSI-RS resource
%   NumRB               - Number of RBs allocated for a CSI-RS resource
%   RBOffset            - Starting RB index of CSI-RS allocation relative
%                         to carrier resource grid
%   For better results, it is recommended to use the same CSI-RS
%   resource(s) that are used for channel estimate, because the resource
%   elements (REs) that does not contain the CSI-RS may have the
%   interpolated channel estimates. Note that the CDM lengths and the
%   number of ports configured for all the CSI-RS resources must be same.
%
%   REPORTCONFIG is a structure of CQI and precoding matrix indicator (PMI)
%   reporting configurations with the following fields:
%   NSizeBWP        - Size of the bandwidth part (BWP) in terms of number
%                     of physical resource blocks (PRBs). It must be a
%                     scalar and the value must be in the range 1...275.
%                     Empty ([]) is also supported and it implies that the
%                     value of NSizeBWP is equal to the size of carrier
%                     resource grid
%   NStartBWP       - Starting PRB index of BWP relative to common resource
%                     block 0 (CRB 0). It must be a scalar and the value
%                     must be in the range 0...2473. Empty ([]) is also
%                     supported and it implies that the value of NStartBWP
%                     is equal to the start of carrier resource grid
%   CodebookType    - Optional. The type of codebooks according to which
%                     the CSI parameters must be computed. It must be a
%                     character array or a string scalar. It must be one of
%                     {'Type1SinglePanel', 'Type1MultiPanel'}. In case of
%                     'Type1SinglePanel', the PMI computation is performed
%                     using TS 38.214 Tables 5.2.2.2.1-1 to 5.2.2.2.1-12.
%                     In case of 'Type1MultiPanel', the PMI computation is
%                     performed using TS 38.214 Tables 5.2.2.2.2-1 to
%                     5.2.2.2.2-6. The default value is 'Type1SinglePanel'
%   PanelDimensions - Antenna panel configuration. 
%                        - When CodebookType field is specified as
%                          'Type1SinglePanel', this field is a two-element
%                          vector in the form of [N1 N2]. N1 represents the
%                          number of antenna elements in horizontal
%                          direction and N2 represents the number of
%                          antenna elements in vertical direction. Valid
%                          combinations of [N1 N2] are defined in TS 38.214
%                          Table 5.2.2.2.1-2. This field is not applicable
%                          when the number of CSI-RS ports is less than or
%                          equal to 2
%                        - When CodebookType field is specified as
%                          'Type1MultiPanel', this field is a three element
%                          vector in the form of [Ng N1 N2], where Ng
%                          represents the number of antenna panels. Valid
%                          combinations of [Ng N1 N2] are defined in TS
%                          38.214 Table 5.2.2.2.2-1
%   PMIMode         - Optional. It represents the mode of PMI reporting. It
%                     must be a character array or a string scalar. It must
%                     be one of {'Subband', 'Wideband'}. The default value
%                     is 'Wideband'
%   SubbandSize     - Subband size for PMI reporting, provided by the
%                     higher-layer parameter NSBPRB. It must be a positive
%                     scalar and must be one of two possible subband sizes,
%                     as defined in TS 38.214 Table 5.2.1.4-2. It is
%                     applicable only when the PMIMode is provided as
%                     'Subband' and the size of BWP is greater than or
%                     equal to 24 PRBs
%   CodebookMode    - Optional. It represents the codebook mode and it must
%                     be a scalar. The value must be one of {1, 2}. 
%                        - When CodebookType is specified as
%                          'Type1SinglePanel', this field is applicable
%                          only if the number of transmission layers is 1
%                          or 2 and number of CSI-RS ports is greater than
%                          2.
%                        - When CodebookType is specified as
%                          'Type1MultiPanel', this field is applicable for
%                          all the number of transmission layers and the
%                          CodebookMode value 2 is applicable only for the
%                          panel configurations with Ng value 2.
%                     The default value is 1
%   CodebookSubsetRestriction
%                   - Optional. It is a binary vector which represents the
%                     codebook subset restriction. When the number of
%                     CSI-RS ports is greater than 2, the length of the
%                     input vector must be N1*N2*O1*O2, where N1 and N2 are
%                     panel configurations obtained from PanelDimensions
%                     field and O1 and O2 are the respective discrete
%                     Fourier transform (DFT) oversampling factors obtained
%                     from TS.38.214 Table 5.2.2.2.1-2 for
%                     'Type1SinglePanel' codebook type or TS.38.214 Table
%                     5.2.2.2.2-1 for 'Type1MultiPanel' codebook type.
%                     When the number of CSI-RS ports is 2, the applicable
%                     codebook type is 'Type1SinglePanel' and the length of
%                     the input vector must be 6, as defined in TS 38.214
%                     Section 5.2.2.2.1. The default value is empty ([]),
%                     which means there is no codebook subset restriction
%   i2Restriction   - Optional. It is a binary vector which represents the
%                     restricted i2 values in a codebook. Length of the
%                     input vector must be 16. First element of the input
%                     binary vector corresponds to i2 as 0, second element
%                     corresponds to i2 as 1, and so on. Binary value 1
%                     indicates that the precoding matrix associated with
%                     the respective i2 is unrestricted and 0 indicates
%                     that the precoding matrix associated with the
%                     respective i2 is restricted. For a precoding matrices
%                     codebook, if the number of possible i2 values are
%                     less than 16, then only the required binary elements
%                     are considered and the trailing extra elements in the
%                     input vector are ignored. This field is applicable
%                     only when the number of CSI-RS ports is greater than
%                     2 and the CodebookType field is specified as
%                     'Type1SinglePanel'. The default value is empty ([]),
%                     which means there is no i2 restriction.
%   RIRestriction   - Optional. Binary vector to represent the restricted
%                     set of ranks. It is of length 8 when CodebookType is
%                     specified as 'Type1SinglePanel' and of length 4 when
%                     CodebookType is specified as 'Type1MultiPanel'. The
%                     first element corresponds to rank 1, second element
%                     corresponds to rank 2, and so on. The binary value 0
%                     represents that the corresponding rank is restricted
%                     and the binary value 1 represents that the
%                     corresponding rank is unrestricted. The default value
%                     is empty ([]), which means there is no rank
%                     restriction
%
%   H is the channel estimation matrix. It is of size
%   K-by-L-by-nRxAnts-by-Pcsirs, where K is the number of subcarriers in
%   the carrier resource grid, L is the number of orthogonal frequency
%   division multiplexing (OFDM) symbols spanning one slot, nRxAnts is the
%   number of receive antennas, and Pcsirs is the number of CSI-RS antenna
%   ports.
%
%   RI is a scalar which gives the best possible number of transmission
%   layers for the given channel and noise variance conditions. It is in
%   the range 1...8 when CodebookType is specified as 'Type1SinglePanel'
%   and in the range 1...4 when CodebookType is specified as
%   'Type1MultiPanel'.
%
%   PMISET output is a structure representing the set of PMI indices
%   (1-based) computed in the hDLPMISelect function. PMISET has these
%   fields:
%   i1 - Indicates wideband PMI (1-based). It is a three-element vector in
%        the form of [i11 i12 i13] when CodebookType is specified as
%        'Type1SinglePanel' and it is a six-element vector in the form of
%        [i11 i12 i13 i141 i142 i143] when CodebookType is specified as
%        'Type1MultiPanel'
%   i2 - Indicates subband PMI (1-based). 
%           - It is a vector of length equal to the number of subbands when
%             CodebookType is specified as 'Type1SinglePanel'.
%           - It is a matrix of size 3-by-number of subbands when
%             CodebookType is specified as 'Type1MultiPanel', where each
%             row indicates i20, i21 and i22 index values for all the
%             subbands respectively and each column represents the
%             [i20; i21; i22] set for each subband
%         Note that the number of subbands in 'wideband' PMIMode is 1.
%   The detailed explanation for the PMISet parameter is available in the
%   <a href="matlab:help('hDLPMISelect')">hDLPMISelect</a> function.
%
%   [RI,PMISET] = hRISelect(CARRIER,CSIRS,REPORTCONFIG,H,NVAR) specifies
%   the estimated noise variance at the receiver NVAR as a nonnegative
%   scalar. By default, the value of nVar is considered as 1e-10, if it is
%   not given as input.
%
%   The RI selection process uses the PMI selection (as performed by
%   <a href="matlab:help('hDLPMISelect')">hDLPMISelect</a>) for each possible rank value (the number of
%   transmission layers) and selects the rank that maximizes the signal to
%   interference and noise ratio (SINR) of the transmission with the
%   selected PMI, subject to a threshold which excludes layers with an
%   SINR < 0 dB.
%
%   Copyright 2021 The MathWorks, Inc.

    narginchk(4,5);
    if nargin == 4
        % Consider a small noise variance value by default, if the noise
        % variance is not given
        nVar = 1e-10;
    else
        nVar = varargin{1};
    end

    % Validate the input arguments
    [reportConfig,csirsInd,nVar] = validateInputs(carrier,csirs,reportConfig,H,nVar);

    % Calculate the number of subbands and size of each subband for the
    % given configuration
    PMISubbandInfo = getDownlinkPMISubbandInfo(reportConfig.PMIMode,reportConfig.NStartBWP,reportConfig.NSizeBWP,reportConfig.SubbandSize);

    % Get the number of CSI-RS ports and receive antennas from the
    % dimensions of the channel estimate
    Pcsirs = size(H,4);
    nRxAnts = size(H,3);

    % Calculate the maximum possible transmission rank according to
    % codebook type
    if strcmpi(reportConfig.CodebookType,'Type1SinglePanel')
        maxRank = min(nRxAnts,Pcsirs);
    else
        % Maximum possible rank in multipanel codebook type is 4
        maxRank = min(nRxAnts,4);
    end
    % Check the rank indicator restriction parameter and derive the
    % ranks that are not restricted from usage
    unRestrictedRanks = find(reportConfig.RIRestriction);

    % Compute the set of ranks that are unrestricted and are less than
    % or equal to the maximum possible rank
    validRanks = intersect(unRestrictedRanks,1:maxRank);
    if isempty(validRanks) || isempty(csirsInd)
        % Report the RI and PMI values as NaNs, if there are no valid
        % ranks or no CSI-RS resources present in the BWP
           if strcmpi(reportConfig.CodebookType,'Type1SinglePanel')
                PMISet.i1 = NaN(1,3);
                PMISet.i2 = NaN*ones(1,PMISubbandInfo.NumSubbands);
            else
                PMISet.i1 = NaN(1,6);
                PMISet.i2 = NaN*ones(3,PMISubbandInfo.NumSubbands);
            end
        RI = NaN;
    else
        % Initialize the best SINR value as -Inf and totalSINR
        % corresponding to each rank as NaN
        bestSINR = -Inf;
        totalSINR = NaN(1,maxRank);

        % For each valid rank, compute the PMI indices set along with the
        % corresponding best SINR values. Then, find the rank which gives
        % the maximum total SINR
        for rankIdx = validRanks
            % PMI selection
            [PMI,PMIInfo] = communication.phyLayer.dlPMISelect(carrier,csirs,reportConfig,rankIdx,H,nVar);

            % Initialize the SINRs parameter
            subbandSINRs = NaN(PMISubbandInfo.NumSubbands,rankIdx);
            if ~any(isnan(PMI.i1))
                % Extract the subband SINR values across all the layers
                % corresponding to the reported PMI
                for idx = 1:PMISubbandInfo.NumSubbands
                    if ~any(isnan((PMI.i2(:,idx))))
                        if strcmpi(reportConfig.CodebookType,'Type1SinglePanel')
                        subbandSINRs(idx,:) = PMIInfo.SINRPerSubband(idx,:,PMI.i2(idx),PMI.i1(1),PMI.i1(2),PMI.i1(3))*rankIdx;
                        else
                        subbandSINRs(idx,:) = PMIInfo.SINRPerSubband(idx,:,PMI.i2(1,idx),PMI.i2(2,idx),PMI.i2(3,idx),PMI.i1(1),PMI.i1(2),PMI.i1(3),PMI.i1(4),PMI.i1(5),PMI.i1(6))*rankIdx;
                        end
                    end
                end

                % Compute the mean value of the SINRs across all the subbands
                layerSINRs =  mean(subbandSINRs,1,'omitnan');
                % Compute the total SINR as the sum of layerSINRs. Consider
                % only the layers with SINR value >= 0 dB or
                % linear value >= 1
                totalSINR(rankIdx) = sum(layerSINRs(layerSINRs>=1));
            end
            if totalSINR(rankIdx) > bestSINR + 0.1
                bestSINR = totalSINR(rankIdx);
                RI = rankIdx;
                PMISet = PMI;
            end
        end

        % Report the rank and PMI set as NaNs, if the totalSINR
        % corresponding to all ranks is NaN
        if all(isnan(totalSINR))
            RI = NaN;
            PMISet = PMI;
        end
    end
end

function [reportConfigOut,csirsInd,nVar] = validateInputs(carrier,csirs,reportConfig,H,nVar)
%   [REPORTCONFIGOUT,CSIRSIND,NVAR] = validateInputs(CARRIER,CSIRS,REPORTCONFIG,H,NVAR)
%   validates the inputs arguments and returns the validated CSI report
%   configuration structure REPORTCONFIGOUT along with the CSI-RS indices
%   CSIRSIND, and the noise variance NVAR.

    fcnName = 'hRISelect';
    validateattributes(carrier,{'nrCarrierConfig'},{'scalar'},fcnName,'CARRIER');
    % Validate 'csirs'
    validateattributes(csirs,{'nrCSIRSConfig'},{'scalar'},fcnName,'CSIRS');
    if ~isscalar(unique(csirs.NumCSIRSPorts))
        error('nr5g:hRISelect:InvalidCSIRSPorts',...
            'All the CSI-RS resources must be configured to have the same number of CSI-RS ports.');
    end
    if ~iscell(csirs.CDMType)
        cdmType = {csirs.CDMType};
    else
        cdmType = csirs.CDMType;
    end
    if ~all(strcmpi(cdmType,cdmType{1}))
        error('nr5g:hRISelect:InvalidCSIRSCDMTypes',...
            'All the CSI-RS resources must be configured to have the same CDM lengths.');
    end

    % Validate 'reportConfig'
    % Validate 'NSizeBWP'
    if ~isfield(reportConfig,'NSizeBWP')
        error('nr5g:hRISelect:NSizeBWPMissing','NSizeBWP field is mandatory.');
    end
    nSizeBWP = reportConfig.NSizeBWP;
    if ~(isnumeric(nSizeBWP) && isempty(nSizeBWP))
        validateattributes(nSizeBWP,{'double','single'},{'scalar','integer','positive','<=',275},fcnName,'the size of BWP');
    else
        nSizeBWP = carrier.NSizeGrid;
    end
    % Validate 'NStartBWP'
    if ~isfield(reportConfig,'NStartBWP')
        error('nr5g:hRISelect:NStartBWPMissing','NStartBWP field is mandatory.');
    end
    nStartBWP = reportConfig.NStartBWP;
    if ~(isnumeric(nStartBWP) && isempty(nStartBWP))
        validateattributes(nStartBWP,{'double','single'},{'scalar','integer','nonnegative','<=',2473},fcnName,'the start of BWP');
    else
        nStartBWP = carrier.NStartGrid;
    end
    if nStartBWP < carrier.NStartGrid
        error('nr5g:hRISelect:InvalidNStartBWP',...
            ['The starting resource block of BWP ('...
            num2str(nStartBWP) ') must be greater than '...
            'or equal to the starting resource block of carrier ('...
            num2str(carrier.NStartGrid) ').']);
    end
    % Check whether BWP is located within the limits of carrier or not
    if (nSizeBWP + nStartBWP)>(carrier.NStartGrid + carrier.NSizeGrid)
        error('nr5g:hRISelect:InvalidBWPLimits',['The sum of starting resource '...
            'block of BWP (' num2str(nStartBWP) ') and the size of BWP ('...
            num2str(nSizeBWP) ') must be less than or equal to '...
            'the sum of starting resource block of carrier ('...
            num2str(carrier.NStartGrid) ') and size of the carrier ('...
            num2str(carrier.NSizeGrid) ').']);
    end
    reportConfigOut.NStartBWP = nStartBWP;
    reportConfigOut.NSizeBWP = nSizeBWP;

    % Check for the presence of 'CodebookType' field
    if isfield(reportConfig,'CodebookType')
        reportConfigOut.CodebookType = validatestring(reportConfig.CodebookType,{'Type1SinglePanel','Type1MultiPanel'},fcnName,'CodebookType field');
    else
        reportConfigOut.CodebookType = 'Type1SinglePanel';
    end

    % Check for the presence of panel dimensions parameter and add it to
    % the reportConfig structure, if present. This parameter is used to
    % obtain the precoding matrices and is validated in hDLPMISelect
    % function
    if isfield(reportConfig,'PanelDimensions')
        reportConfigOut.PanelDimensions = reportConfig.PanelDimensions;
    end

    % Validate 'PMIMode'
    if isfield(reportConfig,'PMIMode')
        reportConfigOut.PMIMode = validatestring(reportConfig.PMIMode,{'Wideband','Subband'},fcnName,'PMIMode field');
    else
        reportConfigOut.PMIMode = 'Wideband';
    end

    % Validate 'SubbandSize'
    NSBPRB = [];
    if strcmpi(reportConfigOut.PMIMode,'Subband')
        if nSizeBWP >= 24
            if ~isfield(reportConfig,'SubbandSize')
                error('nr5g:hRISelect:SubbandSizeMissing',...
                    ['For the subband mode, SubbandSize field is '...
                    'mandatory when the size of BWP is more than 24 PRBs.']);
            end
            validateattributes(reportConfig.SubbandSize,{'double','single'},...
                {'real','scalar'},fcnName,'SubbandSize field');
            NSBPRB = reportConfig.SubbandSize;
        end
    end
    reportConfigOut.SubbandSize = NSBPRB;

    % If 'PRGSize' field is present, update it as empty, since it is not
    % required for RI computation
    if isfield(reportConfig,'PRGSize')
        reportConfigOut.PRGSize = [];
    end

    if strcmpi(reportConfigOut.PMIMode,'Subband')
        if nSizeBWP >= 24
            % Validate the subband size, based on the size of BWP
            % BWP size ranges
            nSizeBWPRange = [24  72;
                73  144;
                145 275];
            % Possible values of subband size
            nSBPRBValues = [4  8;
                8  16;
                16 32];
            bwpRangeCheck = (nSizeBWP >= nSizeBWPRange(:,1)) & (nSizeBWP <= nSizeBWPRange(:,2));
            validNSBPRBValues = nSBPRBValues(bwpRangeCheck,:);
            if ~any(NSBPRB == validNSBPRBValues)
                error('nr5g:hRISelect:InvalidSubbandSize',['For the configured BWP size (' num2str(nSizeBWP) ...
                    '), subband size (' num2str(NSBPRB) ') must be ' num2str(validNSBPRBValues(1)) ...
                    ' or ' num2str(validNSBPRBValues(2)) '.']);
            end
        end
    end

    % Check for the presence of 'CodebookMode' field
    if isfield(reportConfig,'CodebookMode')
        reportConfigOut.CodebookMode = reportConfig.CodebookMode;
    end

    % Check for the presence of 'CodebookSubsetRestriction'
    if isfield(reportConfig,'CodebookSubsetRestriction')
        reportConfigOut.CodebookSubsetRestriction = reportConfig.CodebookSubsetRestriction;
    end

    % Check for the presence of 'i2Restriction'
    if isfield(reportConfig,'i2Restriction')
        reportConfigOut.i2Restriction = reportConfig.i2Restriction;
    end

    % Validate RIRestriction
    if strcmpi(reportConfigOut.CodebookType,'Type1SinglePanel')
        % When CodebookType is specified as 'Type1SinglePanel',
        % RIRestriction parameter must be a binary vector of length 8
        reportConfigOut.RIRestriction = ones(1,8);
        if isfield(reportConfig,'RIRestriction') && ~isempty(reportConfig.RIRestriction)
            validateattributes(reportConfig.RIRestriction,{'numeric'},{'vector','binary','numel',8},fcnName,'RIRestriction field in type 1 single panel codebook type');
            reportConfigOut.RIRestriction = reportConfig.RIRestriction;
        end
    else
        % When CodebookType is specified as 'Type1MultiPanel',
        % RIRestriction parameter must be a binary vector of length 4
        reportConfigOut.RIRestriction = ones(1,4);
        if isfield(reportConfig,'RIRestriction') && ~isempty(reportConfig.RIRestriction)
            validateattributes(reportConfig.RIRestriction,{'numeric'},{'vector','binary','numel',4},fcnName,'RIRestriction field in type 1 multipanel codebook type');
            reportConfigOut.RIRestriction = reportConfig.RIRestriction;
        end
    end

    % Validate 'H'
    validateattributes(H,{'double','single'},{},fcnName,'H');
    validateattributes(numel(size(H)),{'double'},{'>=',2,'<=',4},fcnName,'number of dimensions of H');

    % Ignore zero-power (ZP) CSI-RS resources, as they are not used for CSI
    % estimation
    if ~iscell(csirs.CSIRSType)
        csirs.CSIRSType = {csirs.CSIRSType};
    end

    numZPCSIRSRes = sum(strcmpi(csirs.CSIRSType,'zp'));
    tempInd = nrCSIRSIndices(carrier,csirs,"IndexStyle","subscript","OutputResourceFormat","cell");
    tempInd = tempInd(numZPCSIRSRes+1:end)';
    csirsInd = zeros(0,3);
    if ~isempty(tempInd)
        csirsInd = cell2mat(tempInd);
    end
    if ~isempty(csirsInd)
        K = carrier.NSizeGrid*12;
        L = carrier.SymbolsPerSlot;
        NumCSIRSPorts = csirs.NumCSIRSPorts(1);
        validateattributes(H,{class(H)},{'size',[K L NaN NumCSIRSPorts]},fcnName,'H');
    end

    % Validate 'nVar'
    validateattributes(nVar,{'double','single'},{'scalar','real','nonnegative','finite'},fcnName,'NVAR');
    % Clip nVar to a small noise variance to avoid +/-Inf outputs
    if nVar < 1e-10
        nVar = 1e-10;
    end
end
function info = getDownlinkPMISubbandInfo(reportingMode,nStartBWP,nSizeBWP,NSBPRB)
%   INFO = getDownlinkPMISubbandInfo(REPORTINGMODE,NSTARTBWP,NSIZEBWP,NSBPRB)
%   returns the PMI subband INFO, as defined in TS 38.214 Table 5.2.1.4-2
%   by considering these inputs:
%
%   REPORTINGMODE - PMI reporting mode
%   NSTARTBWP     - Starting PRB index of BWP relative to CRB 0
%   NSIZEBWP      - Size of BWP in terms of number of PRBs
%   NSBPRB        - Subband size

    % Get the subband information
    if strcmpi(reportingMode,'Wideband') || nSizeBWP < 24
        % According to TS 38.214 Table 5.2.1.4-2, if the size of BWP is
        % less than 24 PRBs, the division of BWP into subbands is not
        % applicable. In this case, the number of subbands is considered as
        % 1 and the subband size is considered as the size of BWP
        numSubbands = 1;
        NSBPRB = nSizeBWP;
        subbandSizes = NSBPRB;
    else
        % Calculate the size of first subband
        firstSubbandSize = NSBPRB - mod(nStartBWP,NSBPRB);

        % Calculate the size of last subband
        if mod(nStartBWP + nSizeBWP,NSBPRB) ~= 0
            lastSubbandSize = mod(nStartBWP + nSizeBWP,NSBPRB);
        else
            lastSubbandSize = NSBPRB;
        end

        % Calculate the number of subbands
        numSubbands = (nSizeBWP - (firstSubbandSize + lastSubbandSize))/NSBPRB + 2;

        % Form a vector with each element representing the size of a subband
        subbandSizes = NSBPRB*ones(1,numSubbands);
        subbandSizes(1) = firstSubbandSize;
        subbandSizes(end) = lastSubbandSize;
    end
    % Place the number of subbands and subband sizes in the output
    % structure
    info.NumSubbands = numSubbands;
    info.SubbandSizes = subbandSizes;
end