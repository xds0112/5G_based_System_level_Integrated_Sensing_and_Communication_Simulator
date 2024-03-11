classdef rxIndicationInfo
    %rxIndicationInfo Represents the information sent by PHY to MAC along with the MAC PDU
    
    %   Copyright 2020 The MathWorks, Inc.

%#codegen

    properties

        %RNTI Radio network temporary identifier (RNTI) of the UE
        RNTI

        %HARQID HARQ process identifier
        HARQID

        %TBS Transport block size
        TBS
    end
end