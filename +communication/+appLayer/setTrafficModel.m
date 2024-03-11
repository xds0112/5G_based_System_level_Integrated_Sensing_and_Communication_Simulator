function [dlApp,ulApp] = setTrafficModel(simuParams, ueIdx)
%SETTRAFFICMODEL
%   Set traffic model, supported traffic models: 'On-Off', 'FTP', 
%   'VoIP', and 'VideoConference'.
%   To use this function, first download the Communications Toolbox
%   Wireless Network Simulation Library add-on.
        switch simuParams.trafficModel
            case 'On-Off'
                dlApp = networkTrafficOnOff('GeneratePacket', true, 'OnTime', simuParams.numFrames*10e-3, 'OffTime', 0, 'DataRate', simuParams.dlAppDataRate(ueIdx));
                ulApp = networkTrafficOnOff('GeneratePacket', true, 'OnTime', simuParams.numFrames*10e-3, 'OffTime', 0, 'DataRate', simuParams.ulAppDataRate(ueIdx));
            case 'FTP'
                dlApp = networkTrafficFTP('GeneratePacket', true);
                ulApp = networkTrafficFTP('GeneratePacket', true);
            case 'VoIP'
                dlApp = networkTrafficVoIP('GeneratePacket', true);
                ulApp = networkTrafficVoIP('GeneratePacket', true);
            case 'VideoConference'
                dlApp = networkTrafficVideoConference('GeneratePacket', true);
                ulApp = networkTrafficVideoConference('GeneratePacket', true);
            otherwise
                error('Supported traffic models are: ''On-Off'', ''FTP'', ''VoIP'', and ''VideoConference'' ')
        end
end

