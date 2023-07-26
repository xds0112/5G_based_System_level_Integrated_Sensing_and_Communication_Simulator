classdef parameters
    %PARAMETERS traffic model parameters
    %  Application traffic configuration
    % Set the periodic DL and UL application traffic pattern for UEs.
    %
    % see also: communication.appLayer.setTrafficModel
    
    properties
        % Supported traffic models: 'On-Off',
        % 'FTP', 'VoIP', and 'VideoConference'
        trafficModel = 'On-Off'

        % attached UEs
        attachedUEs

        % DL application data rate in kbps per UE
        %[1x1] double
        dlAppDataRate

        % UL application data rate in kbps per UE
        %[1x1] double
        ulAppDataRate
    end

    methods
        function obj = parameters()
            %PARAMETERS
            % creates scheduling parameters class
        end
    end
end

