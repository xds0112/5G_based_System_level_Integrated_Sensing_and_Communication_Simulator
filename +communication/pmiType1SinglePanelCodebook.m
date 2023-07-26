function  W = pmiType1SinglePanelCodebook(reportConfig,nLayers)
%   W = pmiType1SinglePanelCodebook(REPORTCONFIG,NLAYERS) returns type-1
%   single panel precoder matrices W, as defined in TS 38.214 Tables
%   5.2.2.2.1-1 to 5.2.2.2.1-12 by considering the following inputs:
%
%   REPORTCONFIG is a CSI reporting configuration structure with the
%   following fields:
%      PanelDimensions            - Antenna pannel configuration as a
%                                   two-element vector ([N1 N2]). It is
%                                   not applicable for CSI-RS ports less
%                                   than or equal to 2
%      OverSamplingFactors        - DFT oversampling factors corresponds to
%                                   the panel configuration
%      CodebookMode               - Optional. Scalar (1,2). Applicable only
%                                   when the number of MIMO layers is 1 or
%                                   2 and number of CSI-RS ports is greater
%                                   than 2
%      CodebookSubsetRestriction  - Optional. Binary vector to represent
%                                   the codebook subset restriction. It is
%                                   of size N1*O1*N2*O2 reported by higher
%                                   layers, where N1 and N2 are panel
%                                   configurations obtained from
%                                   PanelDimensions and O1 and O2 are the
%                                   respective DFT oversampling factors
%                                   calculated from TS.38.214 Table
%                                   5.2.2.2-2. The default value is empty
%                                   ([]), which means there is no codebook
%                                   subset restriction
%      i2Restriction              - Optional. Binary vector to represent
%                                   the restricted i2 values. It is of
%                                   length 16, where the first element
%                                   corresponds to i2 as 0, second element
%                                   corresponds to i2 as 1, and so on. The
%                                   default value is empty ([]), which
%                                   means there is no i2 restriction
%   NLAYERS      - Number of transmission layers
%
%   W            - Multidimensional array containing unrestricted type-1
%                  single panel precoder matrices. It is of size
%                  NumCSIRSPorts-by-nLayers-by-i2Length-by-i11Length-by-i12Length-by-i13Length
%
%   Note that the resticted precoding matrices are returned as all zeros.

%   Copyright 2020 The MathWorks, Inc.

    panelDimensions           = reportConfig.PanelDimensions;
    codebookMode              = reportConfig.CodebookMode;
    codebookSubsetRestriction = reportConfig.CodebookSubsetRestriction;
    i2Restriction             = reportConfig.i2Restriction;

    % Create function handle to compute the co-phasing factor value according to
    % TS 38.214 Section 5.2.2.2 considering the co-phasing factor index
    phi = @(x)exp(1i*pi*x/2);
    
    % Get the number of CSI-RS ports using panel dimensions
    Pcsirs = 2*panelDimensions(1)*panelDimensions(2);
    if Pcsirs == 2
        % Codebooks for 1-layer and 2-layer CSI reporting using antenna
        % ports 3000 to 3001 as per TS 38.214 Table 5.2.2.2.1-1
        if nLayers == 1
            W(:,:,1) = 1/sqrt(2).*[1; 1];
            W(:,:,2) = 1/sqrt(2).*[1; 1i];
            W(:,:,3) = 1/sqrt(2).*[1; -1];
            W(:,:,4) = 1/sqrt(2).*[1; -1i];
            restrictedIndices = find(~codebookSubsetRestriction);
            restrictedIndices = restrictedIndices(restrictedIndices <= 4);
            if ~isempty(restrictedIndices)
                restrictedSet = logical(sum(restrictedIndices == [1;2;3;4],2));
                W(:,:,restrictedSet) = 0;
            end
        elseif nLayers == 2
            W(:,:,1) = 1/2*[1 1;1 -1];
            W(:,:,2) = 1/2*[1 1; 1i -1i];
            restrictedIndices = find(~codebookSubsetRestriction);
            restrictedIndices = restrictedIndices(restrictedIndices > 4);
            if ~isempty(restrictedIndices)
                restrictedSet = logical(sum(restrictedIndices == [5;6],2));
                W(:,:,restrictedSet) = 0;
            end
        end
    elseif Pcsirs > 2
        N1 = panelDimensions(1);
        N2 = panelDimensions(2);
        O1 = reportConfig.OverSamplingFactors(1);
        O2 = reportConfig.OverSamplingFactors(2);

        % Select the codebook based on the number of layers, panel
        % configuration, and the codebook mode
        switch nLayers
            case 1 % Number of layers is 1
                % Codebooks for 1-layer CSI reporting using antenna ports
                % 3000 to 2999+P_CSIRS as per TS 38.214 Table 5.2.2.2.1-5
                if codebookMode == 1
                    i11_length = N1*O1;
                    i12_length = N2*O2;
                    i2_length = 4;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                    % Loop over all the values of i11, i12, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i2 = 0:i2_length-1
                                l = i11;
                                m = i12;
                                n = i2;
                                bitIndex = N2*O2*l+m;
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vlm = getVlm(N1,N2,O1,O2,l,m);
                                    phi_n = phi(n);
                                    W(:,:,i2+1,i11+1,i12+1) = (1/sqrt(Pcsirs))*[vlm ;...
                                                                                phi_n*vlm];
                                end
                            end
                        end
                    end
                else % codebookMode == 2
                    i11_length = N1*O1/2;
                    i12_length = N2*O2/2;
                    if N2 == 1
                        i12_length = 1;
                    end
                    i2_length = 16;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                    % Loop over all the values of i11, i12, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i2 = 0:i2_length-1
                                if N2 == 1
                                    l = 2*i11 + floor(i2/4);
                                    m = 0;
                                else % N2 > 1
                                    lmAddVals = [0 0; 1 0; 0 1;1 1];
                                    l = 2*i11 + lmAddVals(floor(i2/4)+1,1);
                                    m = 2*i12 + lmAddVals(floor(i2/4)+1,2);
                                end
                                n = mod(i2,4);
                                bitIndex = N2*O2*l+m;
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vlm = getVlm(N1,N2,O1,O2,l,m);
                                    phi_n = phi(n);
                                    W(:,:,i2+1,i11+1,i12+1) = (1/sqrt(Pcsirs))*[vlm;...
                                                                                phi_n*vlm];
                                end
                            end
                        end
                    end
                end
                
            case 2 % Number of layers is 2
                % Codebooks for 2-layer CSI reporting using antenna ports
                % 3000 to 2999+P_CSIRS as per TS 38.214 Table 5.2.2.2.1-6

                % Compute i13 parameter range and corresponding k1 and k2
                % as per TS 38.214 table 5.2.2.2.1-3
                if (N1 > N2) && (N2 > 1)
                    i13_length = 4;
                    k1 = [0 O1 0 2*O1];
                    k2 = [0 0 O2 0];
                elseif N1 == N2
                    i13_length = 4;
                    k1 = [0 O1 0 O1];
                    k2 = [0 0 O2 O2];
                elseif (N1 == 2) && (N2 == 1)
                    i13_length = 2;
                    k1 = [0 O1];
                    k2 = [0 0];
                else
                    i13_length = 4;
                    k1 = [0 O1 2*O1 3*O1];
                    k2 = [0 0 0 0] ;
                end

                if codebookMode == 1
                    i11_length = N1*O1;
                    i12_length = N2*O2;
                    i2_length = 2;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                    % Loop over all the values of i11, i12, i13, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i13 = 0:i13_length-1
                                for i2 = 0:i2_length-1
                                    l = i11;
                                    m = i12;
                                    n = i2;
                                    lPrime = i11+k1(i13+1);
                                    mPrime = i12+k2(i13+1);
                                    bitIndex = N2*O2*l+m;
                                    [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                    if ~(lmRestricted || i2Restricted)
                                        vlm = getVlm(N1,N2,O1,O2,l,m);
                                        vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                        phi_n = phi(n);
                                        W(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(2*Pcsirs))*[vlm        vlPrime_mPrime;...
                                                                phi_n*vlm  -phi_n*vlPrime_mPrime];
                                    end
                                end
                            end
                        end
                    end
                else % codebookMode == 2
                    i11_length = N1*O1/2;
                    if N2 == 1
                        i12_length = 1;
                    else
                        i12_length = N2*O2/2;
                    end
                    i2_length = 8;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                    % Loop over all the values of i11, i12, i13, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i2 = 0:i2_length-1
                                for i13 = 0:i13_length-1
                                    if N2 == 1
                                        l = 2*i11 + floor(i2/2);
                                        lPrime = 2*i11 + floor(i2/2)+k1(i13+1);
                                        m = 0;
                                        mPrime = 0;
                                    else % N2 > 1
                                        lmAddVals = [0 0; 1 0; 0 1;1 1];
                                        l = 2*i11 + lmAddVals(floor(i2/2)+1,1);
                                        lPrime =  2*i11 + k1(i13+1) + lmAddVals(floor(i2/4)+1,1);
                                        m = 2*i12 + lmAddVals(floor(i2/2)+1,2);
                                        mPrime =  2*i12 + k2(i13+1) + lmAddVals(floor(i2/4)+1,2);
                                    end
                                    n = mod(i2,2);
                                    bitIndex = N2*O2*l+m;
                                    [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                    if ~(lmRestricted || i2Restricted)
                                        vlm = getVlm(N1,N2,O1,O2,l,m);
                                        vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                        phi_n = phi(n);
                                        W(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(2*Pcsirs))*[vlm        vlPrime_mPrime;...
                                                                phi_n*vlm  -phi_n*vlPrime_mPrime];
                                    end
                                end
                            end
                        end
                    end
                end
                
            case {3,4} % Number of layers is 3 or 4
                if (Pcsirs < 16)
                    % For the number of CSI-RS ports less than 16, compute
                    % i13 parameter range, corresponding k1 and k2,
                    % according to TS 38.214 table 5.2.2.2.1-4
                    if (N1 == 2) && (N2 == 1)
                        i13_length = 1;
                        k1 = O1;
                        k2 = 0;
                    elseif (N1 == 4) && (N2 == 1)
                        i13_length = 3;
                        k1 = O1*(1:3);
                        k2 = [0 0 0];
                    elseif (N1 == 6) && (N2==1)
                        i13_length = 4;
                        k1 = O1*(1:4);
                        k2 = [0 0 0 0];
                    elseif (N1==2) && (N2 ==2)
                        i13_length = 3;
                        k1 = [O1 0 O1];
                        k2 = [0 O2 O2];
                    elseif (N1 == 3) && (N2 == 2)
                        i13_length = 4;
                        k1 = [O1 0 O1 2*O1];
                        k2 = [0 O2 O2 0];
                    end

                    % For 3 and 4 layers the procedure for computation of W is
                    % same, other than the dimensions of W. Compute W for either case
                    % accordingly
                    i11_length = N1*O1;
                    i12_length = N2*O2;
                    i2_length = 2;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                    % Loop over all the values of i11, i12, i13, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i13 = 0:i13_length-1
                                for i2 = 0:i2_length-1
                                    l = i11;
                                    lPrime = i11+k1(i13+1);
                                    m = i12;
                                    mPrime = i12+k2(i13+1);
                                    n = i2;
                                    bitIndex = N2*O2*l+m;
                                    [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                    if ~(lmRestricted || i2Restricted)
                                        vlm = getVlm(N1,N2,O1,O2,l,m);
                                        vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                        phi_n = phi(n);
                                        phi_vlm = phi_n*vlm;
                                        phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                                        if nLayers == 3
                                            % Codebook for 3-layer CSI
                                            % reporting using antenna ports
                                            % 3000 to 2999+P_CSIRS as per
                                            % TS 38.214 Table 5.2.2.2.1-7
                                            W(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                                (1/sqrt(3*Pcsirs))*[vlm      vlPrime_mPrime      vlm;...
                                                                    phi_vlm  phi_vlPrime_mPrime  -phi_vlm];
                                        else
                                            % Codebook for 4-layer CSI
                                            % reporting using antenna ports
                                            % 3000 to 2999+P_CSIRS as per
                                            % TS 38.214 Table 5.2.2.2.1-8
                                            W(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                                (1/sqrt(4*Pcsirs))*[vlm      vlPrime_mPrime      vlm       vlPrime_mPrime;...
                                                                    phi_vlm  phi_vlPrime_mPrime  -phi_vlm  -phi_vlPrime_mPrime];
                                        end
                                    end
                                end
                            end
                        end
                    end
                else % Number of CSI-RS ports is greater than or equal to 16
                    i11_length = N1*O1/2;
                    i12_length = N2*O2;
                    i13_length = 4;
                    i2_length = 2;
                    W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                    % Loop over all the values of i11, i12, i13, and i2
                    for i11 = 0:i11_length-1
                        for i12 = 0:i12_length-1
                            for i13 = 0:i13_length-1
                                for i2 = 0:i2_length-1
                                    theta = exp(1i*pi*i13/4);
                                    l = i11;
                                    m = i12;
                                    n = i2;
                                    phi_n = phi(n);
                                    bitValues = [mod(N2*O2*(2*l-1)+m,N1*O1*N2*O2), N2*O2*(2*l)+m, N2*O2*(2*l+1)+m];
                                    [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitValues,i2,i2Restriction);
                                    if ~(lmRestricted || i2Restricted)
                                        vbarlm = getVbarlm(N1,N2,O1,O2,l,m);
                                        theta_vbarlm = theta*vbarlm;
                                        phi_vbarlm = phi_n*vbarlm;
                                        phi_theta_vbarlm = phi_n*theta*vbarlm;
                                        if nLayers == 3
                                            % Codebook for 3-layer CSI
                                            % reporting using antenna ports
                                            % 3000 to 2999+P_CSIRS as per
                                            % TS 38.214 Table 5.2.2.2.1-7
                                            W(:,:,i2+1,i11+1,i12+1) = ...
                                                (1/sqrt(3*Pcsirs))*[vbarlm            vbarlm             vbarlm;...
                                                                    theta_vbarlm      -theta_vbarlm      theta_vbarlm;...
                                                                    phi_vbarlm        phi_vbarlm         -phi_vbarlm;...
                                                                    phi_theta_vbarlm  -phi_theta_vbarlm  -phi_theta_vbarlm];
                                        else
                                            % Codebook for 4-layer CSI
                                            % reporting using antenna ports
                                            % 3000 to 2999+P_CSIRS as per
                                            % TS 38.214 Table 5.2.2.2.1-8
                                            W(:,:,i2+1,i11+1,i12+1) = ...
                                                (1/sqrt(4*Pcsirs))*[vbarlm            vbarlm             vbarlm             vbarlm;...
                                                                    theta_vbarlm      -theta_vbarlm      theta_vbarlm       -theta_vbarlm;...
                                                                    phi_vbarlm        phi_vbarlm         -phi_vbarlm        -phi_vbarlm;...
                                                                    phi_theta_vbarlm  -phi_theta_vbarlm  -phi_theta_vbarlm  phi_theta_vbarlm];
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
            case {5,6} % Number of layers is 5 or 6
                i11_length = N1*O1;
                if N2 == 1
                    i12_length = 1;
                else % N2 > 1
                    i12_length = N2*O2;
                end
                i2_length = 2;
                W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                % Loop over all the values of i11, i12, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i2 = 0:i2_length-1
                            if N2 == 1
                                l = i11;
                                lPrime = i11+O1;
                                l_dPrime = i11+2*O1;
                                m = 0;
                                mPrime = 0;
                                m_dPrime = 0;
                            else % N2 > 1
                                l = i11;
                                lPrime = i11+O1;
                                l_dPrime = i11+O1;
                                m = i12;
                                mPrime = i12;
                                m_dPrime = i12+O2;
                            end
                            n = i2;
                            bitIndex = N2*O2*l+m;
                            [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                            if ~(lmRestricted || i2Restricted)
                                vlm = getVlm(N1,N2,O1,O2,l,m);
                                vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                vlDPrime_mDPrime = getVlm(N1,N2,O1,O2,l_dPrime,m_dPrime);
                                phi_n = phi(n);
                                phi_vlm = phi_n*vlm;
                                phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                                if nLayers == 5
                                    % Codebook for 5-layer CSI reporting
                                    % using antenna ports 3000 to
                                    % 2999+P_CSIRS as per TS 38.214 Table
                                    % 5.2.2.2.1-9
                                    W(:,:,i2+1,i11+1,i12+1) = ...
                                        1/(sqrt(5*Pcsirs))*[vlm       vlm        vlPrime_mPrime   vlPrime_mPrime    vlDPrime_mDPrime;...
                                                            phi_vlm   -phi_vlm   vlPrime_mPrime   -vlPrime_mPrime   vlDPrime_mDPrime];
                                else
                                    % Codebook for 6-layer CSI reporting
                                    % using antenna ports 3000 to
                                    % 2999+P_CSIRS as per TS 38.214 Table
                                    % 5.2.2.2.1-10
                                    W(:,:,i2+1,i11+1,i12+1) = ...
                                        1/(sqrt(6*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlPrime_mPrime        vlDPrime_mDPrime   vlDPrime_mDPrime;...
                                                            phi_vlm   -phi_vlm   phi_vlPrime_mPrime   -phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime];
                                end
                            end
                        end
                        
                    end
                end
                
            case{7,8} % Number of layers is 7 or 8
                if N2 == 1
                    i12_length = 1;
                    if N1 == 4
                        i11_length = N1*O1/2;
                    else % N1 > 4
                        i11_length = N1*O1;
                    end
                else % N2 > 1
                    i11_length = N1*O1;
                    if (N1 == 2 && N2 == 2) || (N1 > 2 && N2 > 2)
                        i12_length = N2*O2;
                    else % ( N1 > 2 && N2 == 2)
                        i12_length = N2*O2/2;
                    end
                end
                i2_length = 2;
                W = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                % Loop over all the values of i11, i12, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i2 = 0:i2_length-1
                            if N2 == 1
                                l = i11;
                                lPrime = i11+O1;
                                l_dPrime = i11+2*O1;
                                l_tPrime = i11+3*O1;
                                m = 0;
                                mPrime = 0;
                                m_dPrime = 0;
                                m_tPrime = 0;
                            else % N2 > 1
                                l = i11;
                                lPrime = i11+O1;
                                l_dPrime = i11;
                                l_tPrime = i11+O1;
                                m = i12;
                                mPrime = i12;
                                m_dPrime = i12+O2;
                                m_tPrime = i12+O2;
                            end
                            n = i2;
                            bitIndex = N2*O2*l+m;
                            [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                            if ~(lmRestricted || i2Restricted)
                                vlm = getVlm(N1,N2,O1,O2,l,m);
                                vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                vlDPrime_mDPrime = getVlm(N1,N2,O1,O2,l_dPrime,m_dPrime);
                                vlTPrime_mTPrime = getVlm(N1,N2,O1,O2,l_tPrime,m_tPrime);
                                phi_n = phi(n);
                                phi_vlm = phi_n*vlm;
                                phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                                if nLayers == 7
                                    % Codebook for 7-layer CSI reporting
                                    % using antenna ports 3000 to
                                    % 2999+P_CSIRS as per TS 38.214 Table
                                    % 5.2.2.2.1-11
                                    W(:,:,i2+1,i11+1,i12+1) = ...
                                        1/(sqrt(7*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlDPrime_mDPrime   vlDPrime_mDPrime    vlTPrime_mTPrime   vlTPrime_mTPrime;...
                                                            phi_vlm   -phi_vlm   phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime   vlTPrime_mTPrime   -vlTPrime_mTPrime];
                                else
                                    % Codebook for 8-layer CSI reporting
                                    % using antenna ports 3000 to
                                    % 2999+P_CSIRS as per TS 38.214 Table
                                    % 5.2.2.2.1-12
                                    W(:,:,i2+1,i11+1,i12+1) = ...
                                        1/(sqrt(8*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlPrime_mPrime        vlDPrime_mDPrime   vlDPrime_mDPrime    vlTPrime_mTPrime   vlTPrime_mTPrime;...
                                                            phi_vlm   -phi_vlm   phi_vlPrime_mPrime   -phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime   vlTPrime_mTPrime   -vlTPrime_mTPrime];
                                end
                            end
                        end
                    end
                end
        end
    end
end

function [vlmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,n,i2Restriction)
%   [VLMRESTRICTED,I2RESTRICTED] = isRestricted(CODEBOOKSUBSETRESTRICTION,BITINDEX,N,I2RESTRICTION)
%   returns the status of vlm or vbarlm restriction and i2 restriction for
%   a codebook index set, as defined in TS 38.214 Section 5.2.2.2.1 by
%   considering the following inputs:
%
%   CODEBOOKSUBSETRESTRICTION - Binary vector for vlm restriction
%   BITINDEX                  - Bit index (0-based) associated with all the
%                               precoders based on vlm
%   N                         - Co-phasing factor index
%   I2RESTRICTION             - Binary vector for i2 restriction

    % Get the restricted index positions from the codebookSubsetRestriction
    % binary vector
    restrictedIdx = reshape(find(~codebookSubsetRestriction)-1,1,[]);
    vlmRestricted = false;
    if any(sum(restrictedIdx == bitIndex(:),2))
        vlmRestricted = true;
    end

    restrictedi2List = find(~i2Restriction)-1;
    i2Restricted = false;
    if any(restrictedi2List == n)
        i2Restricted = true;
    end
end

function vbarlm = getVbarlm(N1,N2,O1,O2,l,m)
%   VBARLM = getVbarlm(N1,N2,O1,O2,L,M) computes vbarlm value according to
%   TS 38.214 Section 5.2.2.2 considering the panel configuration [N1, N2],
%   DFT oversampling factors [O1, O2], and vbarlm indices L and M.

    % Calculate vbarlm (DFT vector required to compute the precoder matrix)
    um = exp(2*pi*1i*m*(0:N2-1)/(O2*N2));
    ul = exp(2*pi*1i*l*(0:(N1/2)-1)/(O1*N1/2)).';
    vbarlm = reshape((ul.*um).',[],1);
end

function vlm = getVlm(N1,N2,O1,O2,l,m)
%   VLM = getVlm(N1,N2,O1,O2,L,M) computes vlm value according to TS 38.214
%   Section 5.2.2.2 considering the panel configuration [N1, N2], DFT
%   oversampling factors [O1, O2], and vlm indices L and M.

    um = exp(2*pi*1i*m*(0:N2-1)/(O2*N2));
    ul = exp(2*pi*1i*l*(0:N1-1)/(O1*N1)).';
    vlm =  reshape((ul.*um).',[],1);
end