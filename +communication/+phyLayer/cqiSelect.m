function [CQI,PMISet,CQIInfo,PMIInfo] = cqiSelect(carrier,varargin)
% cqiSelect PDSCH Channel quality indicator calculation
%   [CQI,PMISET,CQIINFO,PMIINFO] = hCQISelect(CARRIER,CSIRS,REPORTCONFIG,NLAYERS,H)
%   returns channel quality indicator (CQI) values CQI and precoding matrix
%   indicator (PMI) values PMISET, as defined in TS 38.214 Section 5.2.2.2,
%   for the specified carrier configuration CARRIER, CSI-RS configuration
%   CSIRS, channel state information (CSI) reporting configuration
%   REPORTCONFIG, number of transmission layers NLAYERS, and estimated
%   channel information H. The function also returns the additional
%   information about the signal to interference and noise ratio (SINR)
%   values that are used for the CQI computation and PMI computation.
%
%   CARRIER is a carrier specific configuration object.
%   Only these object properties are relevant for this
%   function:
%
%   SubcarrierSpacing - Subcarrier spacing in kHz
%   CyclicPrefix      - Cyclic prefix type
%   NSizeGrid         - Number of resource blocks (RBs) 
%                       carrier resource grid
%   NStartGrid        - Start of carrier resource grid relative to common
%                       resource block 0 (CRB 0)
%   NSlot             - Slot number
%   NFrame            - System frame number
%
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
%   REPORTCONFIG is a CSI reporting configuration structure with these
%   fields:
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
%   CQIMode         - Optional. It represents the mode of CQI reporting. It
%                     must be a character array or a string scalar. It must
%                     be one of {'Subband', 'Wideband'}. The default value
%                     is 'Wideband'
%   PMIMode         - Optional. It represents the mode of PMI reporting. It
%                     must be a character array or a string scalar. It must
%                     be one of {'Subband', 'Wideband'}. The default value
%                     is 'Wideband'
%   SubbandSize     - Subband size for CQI or PMI reporting, provided by
%                     the higher-layer parameter NSBPRB. It must be a
%                     positive scalar and must be one of two possible
%                     subband sizes, as defined in TS 38.214 Table
%                     5.2.1.4-2. It is applicable only when either CQIMode
%                     or PMIMode are provided as 'Subband' and the size of
%                     BWP is greater than or equal to 24 PRBs
%   PRGSize         - Optional. Precoding resource block group (PRG) size
%                     for CQI calculation, provided by the higher-layer
%                     parameter pdsch-BundleSizeForCSI. This field is
%                     applicable to the CSI report quantity cri-RI-i1-CQI,
%                     as defined in TS 38.214 Section 5.2.1.4.2. This
%                     report quantity expects only the i1 set of PMI to be
%                     reported as part of CSI parameters and PMI mode is
%                     expected to be 'Wideband'. But, for the computation
%                     of the CQI in this report quantity, PMI i2 values are
%                     needed for each PRG. Hence, the PMI output, when this
%                     field is configured, is given as a set of i2 values,
%                     one for each PRG of the specified size. It must be a
%                     scalar and it must be one of {2, 4}. Empty ([]) is
%                     also supported to represent that this field is not
%                     configured by higher layers. If it is present and not
%                     configured as empty, the CQI values are computed
%                     according to the configured CQIMode and the PMI value
%                     is reported for each PRG irrespective of PMIMode.
%                     This field is applicable only when the CodebookType
%                     is configured as 'Type1SinglePanel'. The default
%                     value is []
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
%
%   The detailed explanation of the CodebookSubsetRestriction field is
%   present in <a href="matlab:help('hDLPMISelect')">hDLPMISelect</a> function.
%
%   NLAYERS is a scalar representing the number of transmission layers.
%   When CodebookType is specified as 'Type1SinglePanel', its value must be
%   in the range of 1...8. When CodebookType is specified as
%   'Type1MultiPanel', its value must be in the range of 1...4.
%
%   H is the channel estimation matrix. It is of size
%   K-by-L-by-nRxAnts-by-Pcsirs, where K is the number of subcarriers in
%   the carrier resource grid, L is the number of orthogonal frequency
%   division multiplexing (OFDM) symbols spanning one slot, nRxAnts is the
%   number of receive antennas, and Pcsirs is the number of CSI-RS antenna
%   ports. Note that the number of transmission layers provided must be
%   less than or equal to min(nRxAnts,Pcsirs).
%
%   CQI output is a 2-dimensional matrix of size 1-by-numCodewords when CQI
%   reporting mode is 'Wideband' and (numSubbands+1)-by-numCodewords when
%   CQI reporting mode is 'Subband'. numSubbands is the number of subbands
%   and numCodewords is the number of codewords. The first row consists of
%   'Wideband' CQI value and if the CQI mode is 'Subband', the 'Wideband'
%   CQI value is followed by the subband differential CQI values for each
%   subband. The subband differential values are scalars ranging from 0 to
%   3 and these values are computed based on the offset level, as defined
%   in TS 38.214 Table 5.2.2.1-1, where
%   subband CQI offset level = subband CQI index - wideband CQI index.
%
%   Note that when the PRGSize field in the reportConfig is configured as
%   other than empty, it is assumed that the report quantity as reported by
%   the higher layers is 'cri-RI-i1-CQI'. In this case the SINR values for
%   the CQI computation are chosen based on the i1 values reported in
%   PMISet and a valid random i2 value from all the reported i2 values in
%   the PMISet. In this case, i2 values reported in the PMISet correspond
%   to each PRG. When CQI reporting mode is 'Wideband', one i2 value is
%   chosen randomly, for the entire BWP, from the set of i2 values of all
%   PRGs. When CQI reporting mode is subband, one i2 value is chosen
%   randomly, for each subband, from the set of PRGs that span the
%   particular subband. Considering this set of i2 values for indexing, the
%   corresponding SINR values are used for CQI computation.
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
%           - It is a vector of length equal to the number of subbands or
%             number of PRGs when CodebookType is specified as
%             'Type1SinglePanel'.
%           - It is a matrix of size 3-by-numSubbands when
%             CodebookType is specified as 'Type1MultiPanel', where each
%             row indicates i20, i21, and i22 index values for all the
%             subbands respectively and each column represents the
%             [i20; i21; i22] set for each subband.
%   The detailed explanation for the PMISet parameter is available in the
%   <a href="matlab:help('hDLPMISelect')">hDLPMISelect</a> function.
%
%   CQIINFO is an output structure for the CQI information with these
%   fields:
%   SINRPerSubbandPerCW - It represents the linear SINR values in each
%                         subband for all the codewords. It is a
%                         two-dimensional matrix of size
%                            - 1-by-numCodewords, when CQI reporting mode
%                              is 'Wideband'
%                            - (numSubbands + 1)-by-numCodewords, when
%                              CQI reporting mode is 'Subband'
%                         Each column of the matrix contains wideband SINR
%                         value (the average SINR value across all
%                         subbands) followed by the SINR values of each
%                         subband. The SINR value in each subband is taken
%                         as an average of SINR values of all the REs
%                         across the particular subband spanning one slot
%   SINRPerRBPerCW      - It represents the linear SINR values in each
%                         RB for all the codewords. It is a
%                         three-dimensional matrix of size
%                         NSizeBWP-by-L-by-numCodewords. The SINR value in
%                         each RB is taken as an average of SINR values of
%                         all the REs across the RB spanning one slot
%   SubbandCQI          - It represents the subband CQI values. It is a
%                         two-dimensional matrix of size
%                            - 1-by-numCodewords, when CQI reporting mode
%                              is 'Wideband' 
%                            - (numSubbands + 1)-by-numCodewords, when
%                              CQI reporting mode is 'Subband'
%                         Each column of the matrix contains the absolute
%                         CQI value of wideband followed by the absolute
%                         CQI values corresponding to each subband
%
%   Note that the CQI output and all the fields of CQIINFO are returned as
%   NaNs for these cases:
%      - When CSI-RS is not present in the operating slot or in the BWP
%      - When the reported PMISet is all NaNs
%   Also note that the subband differential CQI value or SubbandCQI value
%   is reported as NaNs in the subbands where CSI-RS is not present.
%
%   PMIINFO is an output structure with these fields:
%   SINRPerRE      - It represents the linear SINR values in each RE
%                    within the BWP for all the layers and all the
%                    precoding matrices.
%                    When CodebookType is specified as 'Type1SinglePanel',
%                    it is a multidimensional array of size
%                       - N-by-L-by-nLayers-by-i2Length-by-i11Length-by-i12Length-by-i13Length
%                         when the number of CSI-RS ports is greater than 2
%                       - N-by-L-by-nLayers-by-i2Length when the number of
%                         CSI-RS ports is 2
%                       - N-by-L when the number of CSI-RS ports is 1
%                    N is the number of subcarriers in the BWP resource
%                    grid, i2Length is the maximum number of possible i2
%                    values and i11Length, i12Length, i13Length are the
%                    maximum number of possible i11, i12, and i13 values
%                    for the given report configuration respectively. When
%                    CodebookType is specified as 'Type1MultiPanel', it is
%                    a multidimensional array of size
%                    N-by-L-by-nLayers-by-i20Length-by-i21Length-by-i22Length-by-i11Length-by-i12Length-by-i13Length-by-i141Length-by-i142Length-by-i143Length
%                    i20Length, i21Length, i22Length, i141Length,
%                    i142Length and i143Length are the maximum number of
%                    possible i20, i21, i22, i141, i142, and i143 values
%                    for the given configuration respectively
%   SINRPerSubband - It represents the linear SINR values in each subband
%                    for all the layers. SINR value in each subband is
%                    formed by averaging SINRPerRE estimates across each
%                    subband (i.e. in the appropriate region of the N
%                    dimension and across the L dimension).
%                    When CodebookType is specified as 'Type1SinglePanel',
%                    it is a multidimensional array of size
%                       - numSubbands-by-nLayers-by-i2Length-by-i11Length-by-i12Length-by-i13Length
%                         when the number of CSI-RS ports is greater than 2
%                       - numSubbands-by-nLayers-by-i2Length when the
%                         number of CSI-RS ports is 2
%                       - numSubbands-by-1 when the number of CSI-RS ports is 1
%                    When CodebookType is specified as 'Type1MultiPanel',
%                    it is a multidimensional array of size
%                       - numSubbands-by-nLayers-by-i20Length-by-i21Length-by-i22Length-by-i11Length-by-i12Length-by-i13Length-by-i141Length-by-i142Length-by-i143Length
%   W              - Multidimensional array containing precoding matrices
%                    based on the CSI reporting configuration.
%                    When CodebookType is specified as 'Type1SinglePanel',
%                    it is a multidimensional array of size
%                       - Pcsirs-by-nLayers-by-i2Length-by-i11Length-by-i12Length-by-i13Length
%                         when the number of CSI-RS ports is greater than 2
%                       - 2-by-nLayers-by-i2Length when the number of
%                         CSI-RS ports is 2
%                       - 1-by-1 with the value 1 when the number of CSI-RS
%                         ports is 1
%                    When CodebookType is specified as 'Type1MultiPanel',
%                    it is a multidimensional array of size
%                       - Pcsirs-by-nLayers-by-i20Length-by-i21Length-by-i22Length-by-i11Length-by-i12Length-by-i13Length-by-i141Length-by-i142Length-by-i143Length
%                    Note that the restricted precoding matrices as per the
%                    report configuration are returned as all zeros
%
%   Note that the PMIInfo output contains the SINR values corresponding to
%   all the precoding matrix indices. Index the SINRPerRE and
%   SINRPerSubband variables with PMISet indices to extract the SINR values
%   corresponding to the PMISet.
%
%   [CQI,PMISET,CQIINFO,PMIINFO] = hCQISelect(CARRIER,CSIRS,REPORTCONFIG,NLAYERS,H,NVAR)
%   specifies the estimated noise variance at the receiver NVAR as a
%   nonnegative scalar. By default, the value of nVar is considered as
%   1e-10, if it is not given as input.
%
%   [CQI,PMISET,CQIINFO,PMIINFO] = hCQISelect(CARRIER,CSIRS,REPORTCONFIG,NLAYERS,H,NVAR,SINRTABLE)
%   also specifies the SINR lookup table SINRTABLE as input.
%
%   SINRTABLE is a vector of 15 SINR values in decibels (dB), each value
%   corresponding to a CQI value that is computed according to the block
%   error rate (BLER) condition as mentioned in TS 38.214 Section 5.2.2.1.
%   By default, the SINR values for 10 percent BLER condition corresponding
%   to TS 38.214 Table 5.2.2.1-2, are taken by performing BLER simulations
%   for an additive white Gaussian noise (AWGN) channel for single input
%   single output (SISO) scenario.
%
%   [CQI,PMISET,CQIINFO,PMIINFO] = hCQISelect(CARRIER,BWP,CQICONFIG,CSIRSIND,H,NVAR) 
%   returns CQI and PMI values along with SINR related information by
%   considering these inputs. This syntax only supports the SISO case.
%
%   BWP is a structure with these fields:
%   NStartBWP      - The starting PRB index of the BWP relative to the
%                    CRB 0
%   NSizeBWP       - The size of BWP in terms of number of PRBs
%
%   CQICONFIG is a structure of configuration parameters required for CQI
%   reporting with these fields:
%   CQIMode        - Optional. It represents the mode of CQI reporting. It
%                    must be a character array or a string scalar. It must
%                    be one of {'Subband', 'Wideband'}. The default value
%                    is 'Wideband'
%   NSBPRB         - Subband size, as provided by the higher layers, is
%                    one of two possible subband sizes according to TS
%                    38.214 Table 5.2.1.4-2. This field is applicable only
%                    when CQIMode is 'Subband'
%   SINR90pc       - Optional. Vector of 15 SINR values in dB. Each value
%                    corresponds to a CQI value at which the BLER must be a
%                    maximum of 0.1. This condition implies that the
%                    throughput must be a minimum of 90 percent when
%                    operated at the SINR. By default, SINR values
%                    corresponding to all CQI values, are taken by
%                    performing BLER simulations for an AWGN channel SISO
%                    scenario
%   Note that NSBPRB and SINR90pc fields are equivalent to SubbandSize and
%   SINRTable inputs respectively, when CSI-RS object is specified as an
%   input in the syntax.
%
%   CSIRSIND are the CSI-RS indices spanning one slot. These indices are
%   1-based and are in concatenated format. It is recommended to give the
%   CSI-RS indices corresponding to row numbers 1 or 2 (since this
%   syntax supports only SISO) and that are used to compute the channel
%   estimate for better results.
%
%   Note that the noise variance NVAR is a mandatory input in this syntax.
%
%   CQI by definition, is a scalar value ranging from 0 to 15 which
%   indicates highest modulation and coding scheme (MCS), suitable for the
%   downlink transmission in order to achieve the required BLER condition.
%
%   According to TS 38.214 Section 5.2.2.1, the user equipment (UE) reports
%   highest CQI index which satisfies the condition where a single physical
%   downlink shared channel (PDSCH) transport block with a combination of
%   modulation scheme, target code rate and transport block size
%   corresponding to the CQI index, and occupying a group of downlink PRBs
%   termed the CSI reference resource (as defined in TS 38.214 Section
%   5.2.2.5), could be received with a transport block error probability
%   not exceeding:
%      -   0.1, when the higher layer parameter cqi-Table in
%          CSI-ReportConfig configures 'table1' (corresponding to TS 38.214
%          Table 5.2.2.1-2), or 'table2' (corresponding to TS 38.214 Table
%          5.2.2.1-3)
%      -   0.00001, when the higher layer parameter cqi-Table in
%          CSI-ReportConfig configures 'table3' (corresponding to TS 38.214
%          Table 5.2.2.1-4).
%
%   The CQI indices and their interpretations are given in TS 38.214 Table
%   5.2.2.1-2 or TS 38.214 Table 5.2.2.1-4, for reporting CQI based on
%   QPSK, 16QAM, 64QAM. The CQI indices and their interpretations are given
%   in TS 38.214 Table 5.2.2.1-3, for reporting CQI based on QPSK, 16QAM,
%   64QAM and 256QAM.
%
%   Note that the function only supports the multiple input multiple output
%   (MIMO) scenario with PMI using type 1 single panel codebooks and type 1
%   multipanel codebooks.
%
%   Copyright 2019-2021 The MathWorks, Inc.

    narginchk(5,7)
    % Extract the input arguments 
    [reportConfig,nLayers,H,nVar,SINRTable,isCSIRSObjSyntax,nTxAnts,csirsInd,csirs] = parseInputs(carrier,varargin);

    % Validate the input arguments
    [reportConfig,SINRTable,nVar] = validateInputs(carrier,reportConfig,nLayers,H,nVar,SINRTable,nTxAnts,csirsInd,isCSIRSObjSyntax);
 
    % Calculate the number of subbands and size of each subband for the
    % given CQI configuration and the PMI configuration. If PRGSize
    % parameter is present and configured with a value other than empty,
    % the PMISubbandInfo consists of PRG related information, otherwise it
    % contains PMI subbands related information
    [CQISubbandInfo,PMISubbandInfo] = getDownlinkCSISubbandInfo(reportConfig);

    % Calculate the number of codewords for the given number of layers. For
    % number of layers greater than 4, there are two codewords, else one
    % codeword
    numCodewords = ceil(nLayers/4);

    if ~isCSIRSObjSyntax
        % Calculate the SINR and CQI values according to the syntax with
        % CSI-RS indices. It supports the computation of the CQI values for
        % SISO case

        % Consider W as 1 in SISO case
        W = 1;

        % Calculate the start of BWP relative to the carrier
        bwpStart = reportConfig.NStartBWP - carrier.NStartGrid;
        % Consider only the unique positions for all CSI-RS ports to avoid
        % repetitive calculation
        csirsInd = unique(csirsInd);

        % Convert CSI-RS indices to subscripts in 1-based notation
        [csirsIndSubs_k,csirsIndSubs_l,~] = ind2sub([carrier.NSizeGrid*12 carrier.SymbolsPerSlot nTxAnts],csirsInd);
        % Consider the CSI-RS indices present only in the BWP
        csirsIndSubs_k = csirsIndSubs_k((csirsIndSubs_k >= bwpStart*12 + 1) & csirsIndSubs_k <= (bwpStart + reportConfig.NSizeBWP)*12);
        csirsIndSubs_l = csirsIndSubs_l((csirsIndSubs_k >= bwpStart*12 + 1) & csirsIndSubs_k <= (bwpStart + reportConfig.NSizeBWP)*12);
        % Make the CSI-RS subscripts relative to BWP start
        csirsIndSubs_k = csirsIndSubs_k - bwpStart*12;
        if isempty(csirsIndSubs_k) || (nVar == 0)
            % Report PMI related outputs as all NaNs, if there are no
            % CSI-RS resources present in the BWP or the noise variance
            % value is zero
            PMISet.i1 = [NaN NaN NaN];
            PMISet.i2 = NaN(1,PMISubbandInfo.NumSubbands);

            PMIInfo.SINRPerSubband = NaN(PMISubbandInfo.NumSubbands,nLayers);
            PMIInfo.SINRPerRE = NaN(reportConfig.NSizeBWP*12,carrier.SymbolsPerSlot,nLayers);
            PMIInfo.W = W;
        else
            sigma = sqrt(nVar);
            K = reportConfig.NSizeBWP*12;
            L = carrier.SymbolsPerSlot;
            % Create an SINR grid of NaNs to calculate SINR for each RE
            SINRsperRE = NaN(K,L);
            % Loop over all the REs in which CSI-RS is present
            for reIdx = 1: numel(csirsIndSubs_k)
                prgIdx = csirsIndSubs_k(reIdx);
                l = csirsIndSubs_l(reIdx);
                Htemp = H(prgIdx,l);
                % Compute the SINR values at each subcarrier location where
                % CSI-RS is present
                SINRsperRE(prgIdx,l) = hPrecodedSINR(Htemp,sigma,W);
            end

            % Consider the PMI indices as all ones for SISO case
            PMI.i1 = [1 1 1];
            PMI.i2 = 1*ones(1,CQISubbandInfo.NumSubbands);

            % Compute the SINR values in subband level granularity
            % according to CQI mode
            SINRperSubbandperCW = getSubbandSINR(SINRsperRE,PMI,CQISubbandInfo); % Corresponds to single codeword

            % Compute wideband SINR as a mean of subband SINR values and
            % place it in position 1
            SINRperSubbandperCW = [mean(SINRperSubbandperCW,'omitnan'); SINRperSubbandperCW];

            % Get the SINR value per RB spanning one slot
            SINRsperRBperCW = getSINRperRB(SINRsperRE,PMI,CQISubbandInfo.SubbandSizes);

            % This syntax does not consider the PMI mode. The PMISet and
            % PMIInfo output are returned by considering the PMI mode as
            % 'Wideband'
            PMISet.i1 = PMI.i1;
            PMISet.i2 = 1;

            PMIInfo.SINRPerRE = SINRsperRE;
            PMIInfo.SINRPerSubband = SINRperSubbandperCW(1,:);
            PMIInfo.W = W;
        end
    else
        % Calculate the SINR and CQI values according to the syntax with
        % the CSI-RS configuration object

        % Get the PMI and SINR values from the PMI selection function
        [PMISet,PMIInfo] = communication.phyLayer.dlPMISelect(carrier,csirs,reportConfig,nLayers,H,nVar);

        SINRperSubband = NaN(CQISubbandInfo.NumSubbands,nLayers);
        if isfield(reportConfig,'PRGSize') && ~isempty(reportConfig.PRGSize)
            % When PRGSize field is configured as other than empty, the CQI
            % computation is done by choosing one random i2 value from all
            % the i2 values corresponding to the PRGs spanning the subband
            % or the wideband based on the CQI mode, as defined in TS
            % 38.214 Section 5.2.1.4.2
            rng(0); % Set RNG state for repeatability
            randomi2 = zeros(1,CQISubbandInfo.NumSubbands);
            if strcmpi(reportConfig.CQIMode,'Subband')
                % Map the PRGs to subbands
                index = 1;
                thisSubbandSize = CQISubbandInfo.SubbandSizes(1);
                % Get the starting position of each PRG with respect to the
                % current subband. It helps to compute the number of PRGs
                % in the respective subband
                startPRG = ones(1,CQISubbandInfo.NumSubbands+1);
                for prgIdx = 1:numel(PMISubbandInfo.SubbandSizes)
                    if (thisSubbandSize - PMISubbandInfo.SubbandSizes(prgIdx) == 0) && (index < CQISubbandInfo.NumSubbands)
                        % Go to the next subband index and replace the
                        % current subband size
                        index = index + 1;
                        thisSubbandSize = CQISubbandInfo.SubbandSizes(index);
                        % Mark the corresponding PRG index as the start of
                        % subband
                        startPRG(index) = prgIdx + 1;
                    else
                        thisSubbandSize = thisSubbandSize - PMISubbandInfo.SubbandSizes(prgIdx);
                    end
                end
                % Append the total number of PRGs + 1 value to the
                % startPRG vector. The value points to the last PRG at the
                % end of the BWP, to know the number of PRGs in the last
                % subband
                startPRG(index+1) = PMISubbandInfo.NumSubbands+1;
                % Loop over all the subbands and choose an i2 value
                % randomly from the i2 values corresponding to all the PRGs
                % spanning each subband
                for idx = 2:numel(startPRG)
                    i2Set = PMISet.i2(startPRG(idx-1):startPRG(idx)-1);
                    randomi2(idx-1) = i2Set(randi(numel(i2Set)));
                    if ~isnan(randomi2(idx-1))
                        SINRperSubband(idx-1,:) = mean(PMIInfo.SINRPerSubband(startPRG(idx-1):startPRG(idx)-1,:,randomi2(idx-1),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3)),'omitnan');
                    end
                end
            else
                % Choose an i2 value randomly from the i2 values other than
                % NaNs corresponding to all the PRGs in the BWP
                i2Set = PMISet.i2(~isnan(PMISet.i2));
                randomi2 = i2Set(randi(numel(i2Set)));
                SINRperSubband(:,:) = mean(PMIInfo.SINRPerSubband(:,:,randomi2,PMISet.i1(1),PMISet.i1(2),PMISet.i1(3)),'omitnan');
            end
            randomPMISet.i1 = PMISet.i1;
            randomPMISet.i2 = randomi2;
            % Get the SINR values in RB level granularity, based on the
            % random i2 values selected. These values are not directly used
            % for CQI computation. These are just for information purpose
            SINRsperRBperCW = getSINRperRB(PMIInfo.SINRPerRE,randomPMISet,CQISubbandInfo.SubbandSizes);
        else
            % If PRGSize is not configured, the output from PMI selection
            % function is either in wideband or subband level granularity
            % based on the PMIMode

            % Get the SINR values corresponding to the PMISet in RB level
            % granularity. These values are not directly used for CQI
            % computation. These are just for information purpose
            SINRsperRBperCW = getSINRperRB(PMIInfo.SINRPerRE,PMISet,PMISubbandInfo.SubbandSizes);

            % Deduce the SINR values for the CQI computation based on the
            % CQI mode, as the SINRPerSubband field in the PMI information
            % output has the SINR values according to the PMIMode
            if strcmpi(reportConfig.PMIMode,'Wideband')
                % If PMI mode is 'Wideband', only one i2 value is reported
                % and the SINR values are obtained for the entire BWP in
                % the SINRPerSubband field of PMIInfo output. In this case
                % compute the SINR values corresponding to subband or
                % wideband based on the CQI mode. Choose the same i2 value
                % for all subbands
                PMI = PMISet;
                PMI.i2 = PMISet.i2.*ones(1,CQISubbandInfo.NumSubbands);
                SINRperSubband = getSubbandSINR(PMIInfo.SINRPerRE,PMI,CQISubbandInfo);
            else
                % If PMI mode is 'Subband', when codebook type is specified
                % as 'Type1SinglePanel', one i2 value is reported per
                % subband and when codebook type is specified as
                % 'Type1MultiPanel', a set of three indices [i20; i21; i22]
                % are reported per subband. The SINR values are obtained in
                % subband level granularity from PMI selection function.
                % Extract the SINR values accordingly
                for subbandIdx = 1:size(PMISet.i2,2)
                    if ~any(isnan(PMISet.i2(:,subbandIdx)))
                        if strcmpi(reportConfig.CodebookType,'Type1MultiPanel')
                            SINRperSubband(subbandIdx,:) = PMIInfo.SINRPerSubband(subbandIdx,:,PMISet.i2(1,subbandIdx),PMISet.i2(2,subbandIdx),PMISet.i2(3,subbandIdx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3),PMISet.i1(4),PMISet.i1(5),PMISet.i1(6));
                        else
                            SINRperSubband(subbandIdx,:) = PMIInfo.SINRPerSubband(subbandIdx,:,PMISet.i2(subbandIdx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3));
                        end
                    end
                end
            end
        end

        SINRperSubbandperCW = zeros(size(SINRperSubband,1),numCodewords);
        for subbandIdx = 1:size(SINRperSubband,1)
            % Get the SINR values per layer and calculate the SINR values
            % corresponding to each codeword
            layerSINRs = squeeze(SINRperSubband(subbandIdx,:));

            if ~any(isnan(layerSINRs))
                codewordSINRs = cellfun(@sum,nrLayerDemap(layerSINRs));
            else
                % If the linear SINR values of the codeword are NaNs, which
                % implies, there are no CSI-RS resources in the current
                % subband. So, the SINR values for the codewords are
                % considered as NaNs for the particular subband
                codewordSINRs = NaN(1,numCodewords);
            end
            SINRperSubbandperCW(subbandIdx,:) = codewordSINRs;
        end

        % Compute the wideband SINR value as a mean of the subband SINRs,
        % if either CQI or PMI are configured in subband mode
        if size(SINRperSubbandperCW,1) > 1
            SINRperSubbandperCW = [mean(SINRperSubbandperCW,1,'omitnan'); SINRperSubbandperCW];
        end
    end

    if all(isnan(PMISet.i1)) && all(isnan(PMISet.i2(:)))
        % If PMISet contains only NaN values, it means that there are no
        % CSI-RS indices present in the slot or the value of nVar is zero
        if CQISubbandInfo.NumSubbands == 1
            % Convert the numSubbands to 0 to report only the wideband CQI
            % index in case of wideband mode
            numSubbands = 0;
        else
            numSubbands = CQISubbandInfo.NumSubbands;
        end
        % Report CQI and the CQI information structure parameters as NaN
        CQI = NaN(numSubbands+1,numCodewords);
        CQIInfo.SINRPerSubbandPerCW = NaN(numSubbands+1,numCodewords);
        CQIInfo.SINRPerRBPerCW = NaN(reportConfig.NSizeBWP,carrier.SymbolsPerSlot,numCodewords);
        CQIInfo.SubbandCQI = NaN(numSubbands+1,numCodewords);
    else
        % Get the CQI value
        CQIForAllSubbands = arrayfun(@(x)getCQI(x,SINRTable),SINRperSubbandperCW);

        % Compute the subband differential CQI value in case of subband
        % mode
        if strcmpi(reportConfig.CQIMode,'Subband')
            % Map the subband CQI values to their subband differential
            % value as defined in TS 38.214 Table 5.2.2.1-1. According to
            % this table, a subband differential CQI value is reported for
            % each subband based on the offset level, where the offset
            % level = subband CQI index - wideband CQI index
            CQIdiff = CQIForAllSubbands(2:end,:) - CQIForAllSubbands(1,:);

            % If the CQI value in any subband is NaN, consider the
            % corresponding subband differential CQI as NaN. It indicates
            % that there are no CSI-RS resources present in that particular
            % subband
            CQIOffset(isnan(CQIdiff)) = NaN;
            CQIOffset(CQIdiff == 0) = 0;
            CQIOffset(CQIdiff == 1) = 1;
            CQIOffset(CQIdiff >= 2) = 2;
            CQIOffset(CQIdiff <= -1) = 3;

            CQIOffset = reshape(CQIOffset,[],numCodewords);
            % Form an output CQI array to include wideband CQI value
            % followed by subband differential values
            CQI = [CQIForAllSubbands(1,:); CQIOffset];
        else
            % In 'Wideband' CQI mode, report only the wideband CQI index
            CQI = CQIForAllSubbands(1,:);
        end

        % Form the output CQI information structure
        CQIInfo.SINRPerRBPerCW = SINRsperRBperCW;
        CQIInfo.SINRPerSubbandPerCW = SINRperSubbandperCW;
        if strcmpi(reportConfig.CQIMode,'Wideband')
            % Output wideband CQI value, if CQIMode is 'Wideband'
            CQIInfo.SubbandCQI = CQIForAllSubbands(1,:);
            CQIInfo.SINRPerSubbandPerCW = SINRperSubbandperCW(1,:);
        else
            % Output wideband CQI value followed by subband CQI values, if
            % CQIMode is 'Subband'
            CQIInfo.SubbandCQI = CQIForAllSubbands;
        end
    end
end
function CQI = getCQI(linearSINR,SINRTable)
%   CQI = getCQI(LINEARSINR,SINRTABLE) returns the maximum CQI value that
%   corresponds to 90 percent throughput by considering these inputs:
%
%   LINEARSINR - The SINR value in linear scale for which the CQI value has
%                to be computed
%   SINRTABLE  - The SINR lookup table using which the CQI value is reverse
%                mapped

    % Convert the SINR values to decibels
    SINRatRxdB  = 10*log10(linearSINR);

    % The measured SINR value is compared with the SINRs in the lookup
    % table. The CQI index corresponding to the maximum SINR value from the
    % table, which is less than the measured value is reported by the UE
    cqiTemp = find(SINRTable(SINRTable <= SINRatRxdB),1,'last');
    if all(isnan(SINRatRxdB))
        CQI = NaN;
    elseif isempty(cqiTemp)
        % If there is no CQI value that corresponds to 90 percent
        % throughput, CQI value is chosen as 0
        CQI = 0;
    else
        CQI = cqiTemp;
    end
end

function SINRsperRBperCW = getSINRperRB(SINRsperRE,PMISet,subbandSizes)
%   SINRSPERRBPERCW = getSINRperRB(SINRSPERRE,PMISET,SUBBANDSIZES) returns
%   the SINR values corresponding to the PMISet in RB level granularity
%   spanning one slot, by considering these inputs:
%
%   SINRSPERRE   - The SINR values per RE for all PMI indices
%   PMISET       - The PMI value reported
%   SUBBANDSIZES - The array representing size of each subband

    numSubbands = size(PMISet.i2,2);
    % Get SINR values per RE based on the PMI values
    start = 0;
    SINRsperRECQI = NaN(size(SINRsperRE,1),size(SINRsperRE,2),size(SINRsperRE,3));
    for idx = 1:numSubbands
        if ~any(isnan(PMISet.i2(:,idx)))
            if numel(PMISet.i1) == 6
               % In this case the codebook type is 'Type1MultiPanel'
               SINRsperRECQI(start*12 + 1:(start + subbandSizes(idx))*12,:,:) = SINRsperRE(start*12 + 1:(start + subbandSizes(idx))*12,:,:,PMISet.i2(1,idx),PMISet.i2(2,idx),PMISet.i2(3,idx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3),PMISet.i1(4),PMISet.i1(5),PMISet.i1(6));
            else
               SINRsperRECQI(start*12 + 1:(start + subbandSizes(idx))*12,:,:) = SINRsperRE(start*12 + 1:(start + subbandSizes(idx))*12,:,:,PMISet.i2(idx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3));
            end
        end
        start = start + subbandSizes(idx);
    end

    % Calculate SINR value per RE per each codeword
    nLayers = size(SINRsperRECQI,3);
    numCodewords = ceil(nLayers/4);
    SINRsperREperCW = NaN(size(SINRsperRECQI,1),size(SINRsperRECQI,2),numCodewords);
    for k = 1:size(SINRsperRECQI,1)
        for l = 1:size(SINRsperRECQI,2)
            temp = reshape(SINRsperRECQI(k,l,:),1,[]);
            if ~all(isnan(temp))
                SINRsperREperCW(k,l,:) = cellfun(@sum,nrLayerDemap(temp));
            end
        end
    end

    % Calculate the SINR value per RB by averaging the SINR values per
    % RE within RB spanning one slot
    SINRsperRBperCW = zeros(size(SINRsperREperCW,1)/12,size(SINRsperREperCW,2),size(SINRsperREperCW,3));
    for RBidx = 0:(size(SINRsperREperCW,1)/12)-1
        % Consider the mean of SINR values over each RB
        RBSINRs = SINRsperREperCW((1:12)+RBidx*12,:,:);
        SINRsperRBperCW(RBidx+1,:,:) = mean(RBSINRs,1,'omitnan');
    end
end

function SubbandSINRs = getSubbandSINR(SINRsperRE,PMISet,SubbandInfo)
%   SUBBANDSINRS = getSubbandSINR(SINRSPERRE,PMISET,SUBBANDINFO) returns
%   the SINR values per subband by averaging the SINR values across all the
%   REs within the subband spanning one slot, corresponding to the reported
%   PMI indices, by considering these inputs:
%
%   SINRSPERRE     - SINR values per RE for all PMI indices
%   PMISET         - The PMI indices according to which SINRs must be
%                    extracted
%   SUBBANDINFO    - Subband information related structure with these 
%   fields:
%      NumSubbands  - Number of subbands
%      SubbandSizes - Size of each subband

    SubbandSINRs = NaN(SubbandInfo.NumSubbands,size(SINRsperRE,3));
    % Consider the starting position of first subband as start of BWP
    subbandStart = 0;
    for SubbandIdx = 1:SubbandInfo.NumSubbands
        if ~any(isnan(PMISet.i2(:,SubbandIdx)))
            if numel(PMISet.i1) == 6
               % In this case the codebook type is 'Type1MultiPanel'
               SubbandSINRs(SubbandIdx,:) = squeeze(mean(mean(SINRsperRE((subbandStart*12 + 1):(subbandStart+ SubbandInfo.SubbandSizes(SubbandIdx))*12,:,:,PMISet.i2(1,SubbandIdx),PMISet.i2(2,SubbandIdx),PMISet.i2(3,SubbandIdx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3),PMISet.i1(4),PMISet.i1(5),PMISet.i1(6)),'omitnan'),'omitnan'));
            else
               SubbandSINRs(SubbandIdx,:) = squeeze(mean(mean(SINRsperRE((subbandStart*12 + 1):(subbandStart+ SubbandInfo.SubbandSizes(SubbandIdx))*12,:,:,PMISet.i2(SubbandIdx),PMISet.i1(1),PMISet.i1(2),PMISet.i1(3)),'omitnan'),'omitnan'));
            end
        end
        subbandStart = subbandStart+ SubbandInfo.SubbandSizes(SubbandIdx);
    end
end

function [reportConfigOut,SINRTable,nVar] = validateInputs(carrier,reportConfig,nLayers,H,nVar,SINRTable,numCSIRSPorts,csirsInd,isCSIRSObjSyntax)
%   [REPORTCONFIGOUT,SINRTABLE,NVAR] = validateInputs(CARRIER,REPORTCONFIG,NLAYERS,H,NVAR,SINRTABLE,NUMCSIRSPORTS,CSIRSIND,ISCSIRSOBJSYNTAX)
%   validates the inputs arguments and returns the validated CSI report
%   configuration structure REPORTCONFIGOUT along with the SINR lookup
%   table SINRTABLE for SINR to CQI mapping, and the noise variance NVAR.

    fcnName = 'hCQISelect';
    % Validate 'reportConfig'
    % Validate 'NSizeBWP'
    if ~isfield(reportConfig,'NSizeBWP')
        error('nr5g:hCQISelect:NSizeBWPMissing','NSizeBWP field is mandatory.');
    end
    nSizeBWP = reportConfig.NSizeBWP;
    if ~(isnumeric(nSizeBWP) && isempty(nSizeBWP))
        validateattributes(nSizeBWP,{'double','single'},{'scalar','integer','positive','<=',275},fcnName,'the size of BWP');
    else
        nSizeBWP = carrier.NSizeGrid;
    end
    % Validate 'NStartBWP'
    if ~isfield(reportConfig,'NStartBWP')
        error('nr5g:hCQISelect:NStartBWPMissing','NStartBWP field is mandatory.');
    end
    nStartBWP = reportConfig.NStartBWP;
    if ~(isnumeric(nStartBWP) && isempty(nStartBWP))
        validateattributes(nStartBWP,{'double','single'},{'scalar','integer','nonnegative','<=',2473},fcnName,'the start of BWP');
    else
        nStartBWP = carrier.NStartGrid;
    end
    if nStartBWP < carrier.NStartGrid
        error('nr5g:hCQISelect:InvalidNStartBWP',...
            ['The starting resource block of BWP ('...
            num2str(nStartBWP) ') must be greater than '...
            'or equal to the starting resource block of carrier ('...
            num2str(carrier.NStartGrid) ').']);
    end
    % BWP must lie within the limits of carrier
    if (nSizeBWP + nStartBWP)>(carrier.NStartGrid + carrier.NSizeGrid)
        error('nr5g:hCQISelect:InvalidBWPLimits',['The sum of starting resource '...
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
    % Check if CQI Mode is specified. Otherwise, by default, consider
    % 'Wideband' mode
    if isfield(reportConfig,'CQIMode')  
        reportConfigOut.CQIMode =  validatestring(reportConfig.CQIMode,{'Wideband','Subband'},...
            fcnName,'CQIMode field');
    else
        reportConfigOut.CQIMode = 'Wideband';
    end
    % Check if PMI Mode is specified. Otherwise, by default, consider
    % 'Wideband' mode
    if isfield(reportConfig,'PMIMode')
        reportConfigOut.PMIMode = validatestring(reportConfig.PMIMode,{'Wideband','Subband'},...
            fcnName,'PMIMode field');
    else
        reportConfigOut.PMIMode = 'Wideband';
    end

    % Validate 'PRGSize'
    if isfield(reportConfig,'PRGSize') && strcmpi(reportConfigOut.CodebookType,'Type1SinglePanel')
        if ~(isnumeric(reportConfig.PRGSize) && isempty(reportConfig.PRGSize))
            validateattributes(reportConfig.PRGSize,{'double','single'},...
                {'real','scalar'},fcnName,'PRGSize field');
        end
        if ~(isempty(reportConfig.PRGSize) || any(reportConfig.PRGSize == [2 4]))
            error('nr5g:hCQISelect:InvalidPRGSize',...
                ['PRGSize value (' num2str(reportConfig.PRGSize) ') must be [], 2, or 4.']);
        end
        reportConfigOut.PRGSize = reportConfig.PRGSize;
    else
        reportConfigOut.PRGSize = [];
    end

    % Validate 'SubbandSize'
    NSBPRB = [];
    if strcmpi(reportConfigOut.CQIMode,'Subband') ||...
            (isempty(reportConfigOut.PRGSize) && strcmpi(reportConfigOut.PMIMode,'Subband'))
        if nSizeBWP >= 24
            if isCSIRSObjSyntax
                fieldName = 'SubbandSize';
            else
                fieldName = 'NSBPRB';
            end
            if ~isfield(reportConfig,'SubbandSize')
                error('nr5g:hCQISelect:SubbandSizeMissing',...
                    ['For the subband mode, ' fieldName ' field is '...
                    'mandatory when the size of BWP is more than 24 PRBs.']);
            else
                validateattributes(reportConfig.SubbandSize,{'double','single'},...
                    {'real','scalar'},fcnName,fieldName);
                NSBPRB = reportConfig.SubbandSize;
            end
        end
    end
    reportConfigOut.SubbandSize = NSBPRB;

    if strcmpi(reportConfigOut.CQIMode,'Subband') ||...
            (isempty(reportConfigOut.PRGSize) && strcmpi(reportConfigOut.PMIMode,'Subband'))
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
                error('nr5g:hCQISelect:InvalidSubbandSize',['For the configured BWP size (' num2str(nSizeBWP) ...
                    '), subband size (' num2str(NSBPRB) ') must be ' num2str(validNSBPRBValues(1)) ...
                    ' or ' num2str(validNSBPRBValues(2)) '.']);
            end
        end
    end

    % Consider CodebookMode field, if present, for PMI selection
    if isfield(reportConfig,'CodebookMode')
        reportConfigOut.CodebookMode = reportConfig.CodebookMode;
    end

    % Consider CodebookSubsetRestriction field, if present, for
    % PMI selection
    if isfield(reportConfig,'CodebookSubsetRestriction')
        reportConfigOut.CodebookSubsetRestriction = reportConfig.CodebookSubsetRestriction;
    end

    % Consider i2Restriction field, if present, for PMI selection
    if isfield(reportConfig,'i2Restriction')
        reportConfigOut.i2Restriction = reportConfig.i2Restriction;
    end

    % Validate 'nLayers'
    if strcmpi(reportConfigOut.CodebookType,'Type1MultiPanel')
        validateattributes(nLayers,{'numeric'},{'scalar','integer','positive','<=',4},fcnName,['NLAYERS(' num2str(nLayers) ') when codebook type is "Type1MultiPanel"']);
    else
        validateattributes(nLayers,{'numeric'},{'scalar','integer','positive','<=',8},fcnName,['NLAYERS(' num2str(nLayers) ') when codebook type is "Type1SinglePanel"']);
    end

    % Validate the channel estimate and its dimensions
    validateattributes(numel(size(H)),{'double'},{'>=',2,'<=',4},fcnName,'number of dimensions of H');
    if ~isempty(csirsInd)
        nRxAnts = size(H,3);
        K = carrier.NSizeGrid*12;
        L = carrier.SymbolsPerSlot;
        if ~isCSIRSObjSyntax
            thirdDim = 1;
        else
            thirdDim = NaN;
        end
        validateattributes(H,{class(H)},{'size',[K L thirdDim numCSIRSPorts]},fcnName,'H');
        
        % Validate 'nLayers'
        maxNLayers = min(nRxAnts,numCSIRSPorts);
        if nLayers > maxNLayers
            error('nr5g:hCQISelect:InvalidNumLayers',...
                ['The given antenna configuration (' ...
                num2str(numCSIRSPorts) 'x' num2str(nRxAnts)...
                ') supports only up to (' num2str(maxNLayers) ') layers.']);
        end
    end

    % Validate noise variance
    validateattributes(nVar,{'double','single'},{'scalar','real','nonnegative','finite'},fcnName,'NVAR');
    % Clip nVar to a small noise variance to avoid +/-Inf outputs
    if nVar < 1e-10
        nVar = 1e-10;
    end
    % Validate SINRTable
    if isempty(SINRTable)
        % Default SINRTable is generated by running simulations for 100
        % frames for the CSI reference resource as defined in TS 38.214
        % Section 5.2.2.5, for an AWGN channel for SISO scenario,
        % considering 0.1 BLER condition and TS 38.214 Table 5.2.2.1-2
        SINRTable =  [-5.84  -4.20  -2.08  -0.23  1.66  3.08  5.03  7.02...
                       9.01  10.99  12.99  15.01  16.51  18.49  19.99];
    else
        if isCSIRSObjSyntax
            syntaxString = 'SINRTable';
        else
            syntaxString = 'SINR90pc field';
        end
        validateattributes(SINRTable,{'double','single'},{'vector','real','numel',15},fcnName,syntaxString);
    end
end

function [reportConfig,nLayers,H,nVar,SINRTable,isCSIRSObjSyntax,nTxAnts,csirsInd,csirs] = parseInputs(carrier,varargin)
%   [REPORTCONFIG,NLAYERS,H,NVAR,SINRTABLE,ISCSIRSOBJSYNTAX,NTXANTS,CSIRSIND,CSIRS] = parseInputs(CARRIER,CSIRS,REPORTCONFIG,NLAYERS,H,NVAR,SINRTABLE) 
%   returns the parsed arguments and other required parameters for the
%   syntax with CSI-RS configuration object by considering these inputs:
%   CARRIER      - Carrier configuration object
%   CSIRS        - CSI-RS configuration object
%   REPORTCONFIG - Structure of CSI reporting configuration
%   NLAYERS      - Number of transmission layers
%   H            - Estimated channel information 
%   NVAR         - Estimated noise variance
%   SINRTABLE    - SINR lookup table for SINR to CQI mapping
%
%   [REPORTCONFIG,NLAYERS,H,NVAR,SINRTABLE,ISCSIRSOBJSYNTAX,NTXANTS,CSIRSIND,CSIRS] = parseInputs(CARRIER,BWP,CQICONFIG,CSIRSIND,H,NVAR) 
%   returns the parsed arguments and other required parameters for the
%   syntax with CSI-RS indices by considering these inputs:
%   CARRIER      - Carrier configuration object
%   BWP          - Structure of BWP dimensions
%   CQICONFIG    - Structure of CQI reporting configuration
%   CSIRSIND     - CSI-RS indices
%   H            - Estimated channel information
%   NVAR         - Estimated noise variance

    % Validate the carrier configuration object
    validateattributes(carrier,{'nrCarrierConfig'},{'scalar'},'hCQISelect','CARRIER');
    variableInputArgs = varargin{1};
    if isstruct(variableInputArgs{1})
        % If the first variable argument is a structure, the syntax with
        % CSI-RS indices input is considered. This syntax supports CQI
        % computation only for SISO case. Move the required set of
        % parameters that can adapt into the syntax with CSI-RS
        % configuration object and bind them accordingly, in order to
        % enable easy validation

        % Extract bwp from the first variable input argument
        bwp = variableInputArgs{1};

        % Check if the size and start of BWP fields are present in the bwp
        % structure.
        if ~isfield(bwp,'NSizeBWP')
            error('nr5g:hCQISelect:NSizeBWPMissing','NSizeBWP field is mandatory.');
        end
        if ~isfield(bwp,'NStartBWP')
            error('nr5g:hCQISelect:NStartBWPMissing','NStartBWP field is mandatory.');
        end

        % Extract the CQI configuration related parameter, from the second
        % variable input argument
        reportConfig = variableInputArgs{2};
        % Bind the BWP dimensions into the reportConfig structure
        reportConfig.NStartBWP = bwp.NStartBWP;
        reportConfig.NSizeBWP = bwp.NSizeBWP;

        % Extract the CSI-RS indices from the third variable input argument
        csirsInd = variableInputArgs{3};
        % Validate CSI-RS indices
        validateattributes(csirsInd,{'numeric'},{'positive','integer'},'hCQISelect','CSIRSIND');

        % Extract the channel estimation matrix from fourth variable
        % argument
        H = variableInputArgs{4};

        % Extract the noise variance from fifth variable input argument.
        % For this syntax, the noise variance is a mandatory input. So
        % default value is not considered here
        nVar = variableInputArgs{5};

        % Consider the number of transmission layers as 1 for SISO case
        nLayers = 1;

        % Extract the subband size value NSBPRB, if present, and store it
        % as SubbandSize field (as in the syntax with CSI-RS configuration
        % object) in reportConfig structure
        if isfield(reportConfig,'NSBPRB')
            reportConfig.SubbandSize = reportConfig.NSBPRB;
        end

        % Extract the SINR lookup table SINR90pc, if present, and store it
        % as SINRTable
        if isfield(reportConfig,'SINR90pc')
            SINRTable = reportConfig.SINR90pc;
        else
            % If SINR lookup table is not configured, consider SINRTable as
            % empty
            SINRTable = [];
        end

        % Consider the number of transmit antennas as 1 for SISO case
        nTxAnts = 1;
        % Consider a variable to denote if this syntax considers CSI-RS
        % configuration object
        isCSIRSObjSyntax = false;

        % In case of the syntax with CSI-RS indices as an input, return the
        % CSI-RS configuration object related parameter as empty
        csirs = [];
    elseif isa(variableInputArgs{1},'nrCSIRSConfig')
        % If the first variable input argument is a CSI-RS configuration
        % object, consider the input arguments according to the syntax with
        % CSI-RS configuration object as an input

        % Extract the CSI-RS configuration object as csirs from the first
        % variable input argument
        csirs = variableInputArgs{1};

        % Validate the CSI-RS resources used for CQI computation. All the
        % CSI-RS resources used for the CQI computation must have same CDM
        % lengths and same number of ports according to TS 38.214 Section
        % 5.2.2.3.1
        validateattributes(csirs,{'nrCSIRSConfig'},{'scalar'},'hCQISelect','CSIRS');
        if ~isscalar(unique(csirs.NumCSIRSPorts))
            error('nr5g:hCQISelect:InvalidCSIRSPorts','All the CSI-RS resources must be configured to have same number of CSI-RS ports.');
        else
            % If all the CSI-RS resources have the same number of CSI-RS
            % ports, get the value as number of transmit antennas
            nTxAnts = unique(csirs.NumCSIRSPorts);
        end

        if ~iscell(csirs.CDMType)
            cdmType = {csirs.CDMType};
        else
            cdmType = csirs.CDMType;
        end
        % Check if all the CSI-RS resources are configured to have same
        % CDM lengths
        if ~all(strcmpi(cdmType,cdmType{1}))
            error('nr5g:hCQISelect:InvalidCSIRSCDMTypes','All the CSI-RS resources must be configured to have same CDM lengths.');
        end

        % Ignore zero-power (ZP) CSI-RS resources, as they are not used for
        % CSI estimation
        if ~iscell(csirs.CSIRSType)
            csirs.CSIRSType = {csirs.CSIRSType};
        end
        numZPCSIRSRes = sum(strcmpi(csirs.CSIRSType,'zp'));
        % Calculate the CSI-RS indices
        tempInd = nrCSIRSIndices(carrier,csirs,"IndexStyle","subscript","OutputResourceFormat","cell");
        tempInd = tempInd(numZPCSIRSRes+1:end)';
        csirsInd = cell2mat(tempInd);

        % Extract the CSI reporting related configuration from second
        % variable input argument
        reportConfig = variableInputArgs{2};

        % Extract the number of transmission layers value as nLayers from
        % the third variable input argument
        nLayers = variableInputArgs{3};

        % Extract the channel estimation matrix from the fourth variable
        % input argument
        H = variableInputArgs{4};

        % Get the number of variable input arguments
        numVarInputArgs = length(variableInputArgs);
        % Extract the noise variance and SINR lookup table
        if numVarInputArgs == 4
            nVar = 1e-10;
            SINRTable = [];
        elseif numVarInputArgs == 5
            nVar = variableInputArgs{5};
            SINRTable = [];
        elseif numVarInputArgs == 6
            nVar = variableInputArgs{5};
            SINRTable = variableInputArgs{6};
        end

        % Consider a variable to denote if this syntax considers CSI-RS
        % configuration object
        isCSIRSObjSyntax = true;
    else
        error('nr5g:hCQISelect:InvalidInputsToTheHelper','The second input argument can be either a structure or a CSI-RS configuration object.');
    end
end

function [cqiSubbandInfo,pmiSubbandInfo] = getDownlinkCSISubbandInfo(reportConfig)
%   [CQISUBBANDINFO,PMISUBBANDINFO] = getDownlinkCSISubbandInfo(REPORTCONFIG)
%   returns the CQI subband related information CQISUBBANDINFO and PMI
%   subband or precoding resource block group (PRG) related information
%   PMISUBBANDINFO, by considering CSI reporting configuration structure
%   REPORTCONFIG.

    % Validate 'SubbandSize'
    NSBPRB = reportConfig.SubbandSize;
    reportConfig.CQISubbandSize = NSBPRB;
    reportConfig.PMISubbandSize = NSBPRB;

    % If PRGSize is present, consider the subband size as PRG size
    if ~isempty(reportConfig.PRGSize)
        reportConfig.PMIMode = 'Subband';
        reportConfig.PMISubbandSize = reportConfig.PRGSize;
        reportConfig.ignoreBWPSize = true; % To ignore the BWP size for the validation of PRG size
    else
        reportConfig.ignoreBWPSize = false; % To consider the BWP size for the validation of subband size
    end

    % Get the subband information for CQI and PMI reporting
    cqiSubbandInfo = getSubbandInfo(reportConfig.CQIMode,reportConfig.NStartBWP,reportConfig.NSizeBWP,reportConfig.CQISubbandSize,false);
    pmiSubbandInfo = getSubbandInfo(reportConfig.PMIMode,reportConfig.NStartBWP,reportConfig.NSizeBWP,reportConfig.PMISubbandSize,reportConfig.ignoreBWPSize);
end

function info = getSubbandInfo(reportingMode,nStartBWP,nSizeBWP,NSBPRB,ignoreBWPSize)
%   INFO = getSubbandInfo(REPORTINGMODE,NSTARTBWP,NSIZEBWP,NSBPRB,IGNOREBWPSIZE)
%   returns the CSI subband information.

    % Get the subband information
    if strcmpi(reportingMode,'Wideband') || (~ignoreBWPSize && nSizeBWP < 24)
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