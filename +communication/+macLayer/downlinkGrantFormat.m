classdef downlinkGrantFormat
%downlinkGrantFormat Represents the downlink assignment information
% The downlink assignment information does not include all the fields of
% downlink control information (DCI) format 1_1 as per 3GPP standard. Grant
% packets containing only the information fields which feature as member of
% this class are assumed to be exchanged with UEs.

%   Copyright 2019-2020 The MathWorks, Inc.


   properties

      %SlotOffset Offset of the allocated slot from the current slot (k0)
      SlotOffset = []

      %RBGAllocationBitmap Resource block group (RBG) allocation represented as bit vector
      RBGAllocationBitmap = []

      %StartSymbol Location of first symbol
      StartSymbol = []

      %NumSymbols Number of symbols
      NumSymbols = []

      %MCS Modulation and coding scheme
      MCS = []

      %NDI New data indicator flag
      NDI = []

      %RV Redundancy version sequence number
      RV = []

      %HARQID HARQ process identifier
      HARQID = []

      %FeedbackSlotOffset Slot offset of PDSCH feedback (ACK/NACK) w.r.t PDSCH transmission (k1)
      FeedbackSlotOffset = []
      
      %DMRSLength DM-RS length 
      DMRSLength = []
      
      %MappingType Mapping type 
      MappingType = []

      %NumLayers Number of PDSCH transmission layers (1...8)
      NumLayers = 1

      %NumCDMGroupsWithoutData Number of demodulation reference signal (DM-RS) code division multiplexing (CDM) groups without data (1...3)
      % Number of DM-RS CDM groups that are not used to transmit data, as a
      % scalar positive integer. The value must be one of {1, 2, 3},
      % corresponding to CDM groups {{0}, {0,1}, {0,1,2}}, respectively as
      % per TS 38.214 Section 5.1.6.2
      NumCDMGroupsWithoutData
   end
end