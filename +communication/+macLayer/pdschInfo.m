classdef pdschInfo
    %pdschInfo MAC-to-PHY information for PDSCH transmission and reception
    %   This information contains the parameters required by PHY from MAC,
    %   to do the PDSCH transmission and reception. gNB MAC sends it to PHY
    %   for PDSCH transmission and UE MAC sends it to PHY for PDSCH
    %   reception. The information includes parameters required for
    %   downlink shared channel (DL-SCH) processing and PDSCH processing.
    %
    %   pdschInfo properties:
    %       NSlot           - Slot number of PDSCH transmission/reception 
    %                         in the 10ms frame
    %       HARQID          - HARQ process identifier
    %       RV              - Redundancy version
    %       TargetCodeRate  - Target code rate for PDSCH transmission/reception
    %       TBS             - Transport block size in bytes
    %       PrecodingMatrix - Precoding matrix (only required for transmission)
    %       PDSCHConfig     - PDSCH configuration object
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties
        
        %NSlot Slot number of PDSCH transmission/reception in the 10ms frame
        NSlot
        
        %HARQID HARQ process identifier
        HARQID
        
        %RV Redundancy version
        RV
        
        %TargetCodeRate Target code rate for PDSCH transmission/reception
        TargetCodeRate
        
        %TBS Transport block size in bytes
        TBS

        %PrecodingMatrix Precoding matrix
        PrecodingMatrix
        
        %PDSCHConfig PDSCH configuration object as described in <a href="matlab:help('nrPDSCHConfig')">nrPDSCHConfig</a>
        PDSCHConfig = nrPDSCHConfig;
    end
    
end