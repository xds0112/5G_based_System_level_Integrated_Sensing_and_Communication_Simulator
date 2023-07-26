classdef puschInfo
    %puschInfo MAC-to-PHY information for PUSCH transmission and reception
    %   This information contains the parameters required by PHY from MAC,
    %   to do the PUSCH transmission and reception. UE MAC sends it to PHY
    %   for PUSCH transmission and gNB MAC sends it to PHY for PUSCH
    %   reception. The information includes parameters required for uplink
    %   shared channel (UL-SCH) processing and PUSCH processing.
    %
    %   puschInfo properties:
    %       NSlot          - Slot number of PUSCH transmission/reception in
    %                        the 10ms frame 
    %       HARQID         - HARQ process identifier
    %       RV             - Redundancy version
    %       TargetCodeRate - Target code rate for PUSCH transmission/reception
    %       TBS            - Transport block size in bytes
    %       PUSCHConfig    - PUSCH configuration object
    
    %   Copyright 2020 The MathWorks, Inc.

    
    properties
        
        %NSlot Slot number of PUSCH transmission/reception in the 10ms frame
        NSlot
        
        %HARQID HARQ process identifier
        HARQID
        
        %RV Redundancy version
        RV
        
        %TargetCodeRate Target code rate for PUSCH transmission/reception
        TargetCodeRate
        
        %TBS Transport block size in bytes
        TBS
        
        %PUSCHConfig PUSCH configuration object as described in <a href="matlab:help('nrPUSCHConfig')">nrPUSCHConfig</a>
        PUSCHConfig = nrPUSCHConfig;
    end
        
end