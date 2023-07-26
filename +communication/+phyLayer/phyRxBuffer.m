classdef phyRxBuffer < handle
%phyRxBuffer Create a Phy signal reception buffer object. This class
%implements the buffering of received signals and adding of interfering
%signals to get the resultant signal
%
%   phyRxBuffer methods:
%
%   addWaveform           - Store the received waveform along with metadata
%
%   getReceivedWaveform   - Return the received waveform after applying
%                           interference
%
%   hNRPhyRxBuffer properties:
%
%   BufferSize   - Maximum number of signals to be stored in the buffer
%
%   WaveformExpirationTime - Waveforms older than WaveformExpirationTime
%  (in microseconds) are considered as obsolete
%
%   Example 1:
%   % Create a hNRPhyRxBuffer object with default properties.
%
%   rxBufferObj = hNRPhyRxBuffer
%
%   Example 2: % Create a hNRPhyRxBuffer object specifying a buffer size of
%   100 and buffer cleanup time of 500 (in microseconds).
%
%   rxBufferObj = hNRPhyRxBuffer('BufferSize', 100, 'WaveformExpirationTime', 500);
%
%   Example 3:
%   % Create a hNRPhyRxBuffer object.
%
%   rxBufferObj = hNRPhyRxBuffer;
%
%   % Create a sample signal and add it to the buffer
%
%   signalInfo = struct('Waveform', complex(randn(15360, 1),randn(15360, 1)),...
%   'NumSamples', 15360, 'SampleRate', 15360000, 'StartTime', 3000);
% 
%   addWaveform(rxBufferObj, signalInfo);
%
%   % Get the waveform from the buffer after applying interference. The
%   % reception start time is 3000 microseconds, reception duration is 1000
%   % microseconds, with a sample rate of 15360000
%
%   receivedWaveform = getReceivedWaveform(rxBufferObj, 3000, 1000, 15360000);

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    properties
        %BufferSize Maximum number of signals to be stored.
        % The default value is 500.
        %
        BufferSize {mustBeNonempty, mustBeInteger, mustBeGreaterThan(BufferSize, 0)} = 500

        %WaveformExpirationTime Waveform older than WaveformExpirationTime
        %(in microseconds) are considered as obsolete
        WaveformExpirationTime {mustBeNonempty, mustBeGreaterThan(WaveformExpirationTime, 0)} = 1000;

        %NRxAnts Number of Rx antennas
        NRxAnts(1, 1) {mustBeMember(NRxAnts, [1,2,4,8,16,32,64,128,256,512,1024])} = 1;
    end

    properties (Access = private)
        %ReceivedSignals Buffer to store the received signals
        ReceivedSignals
    end

    methods (Access = public)

        function obj = phyRxBuffer(varargin)
            %phyRxBuffer Construct an instance of this class

            % Set name-value pairs
            for idx = 1:2:nargin
                obj.(varargin{idx}) = varargin{idx+1};
            end

            % Initialize the signal structure
            signal = struct('Waveform', complex(0,0), ...
                'NumSamples', 0, ...
                'SampleRate', 0, ...
                'StartTime', 0, ...
                'EndTime', 0);
            signal.Waveform = complex(zeros(2, obj.NRxAnts));% To support codegen

            % To store the received signals and the associated metadata
            obj.ReceivedSignals = repmat(signal, obj.BufferSize, 1);
        end

        function addWaveform(obj, signalInfo)
            %addWaveform Add the received signal to the buffer
            %
            %   addWaveform(OBJ, SIGNALINFO) Adds the received signal to
            %   the buffer
            %
            %   SIGNALINFO is a structure with these fields:
            %       Waveform    : IQ samples of the received signal
            %                     represented as an M x N matrix. 'M'
            %                     is the number of IQ samples and 'N'
            %                     is the number of Rx antennas.
            %       NumSamples  : Length of the waveform (number of IQ
            %                     samples). It is a scalar and represents
            %                     the number of samples in the waveform
            %       SampleRate  : Sample rate of the waveform. It is a
            %                     scalar
            %       StartTime   : Current timestamp of the receiver at
            %                     signal entry (in microseconds). It is a
            %                     scalar

            removeObsoleteWaveforms(obj, signalInfo.StartTime-obj.WaveformExpirationTime);

            % Get an index in the signal buffer to store the received
            % signal
            idx = getStoreIndex(obj);

            if idx ~= 0
                % Store the signal along with metadata
                obj.ReceivedSignals(idx).Waveform = signalInfo.Waveform;
                obj.ReceivedSignals(idx).NumSamples = signalInfo.NumSamples;
                obj.ReceivedSignals(idx).SampleRate = signalInfo.SampleRate;
                obj.ReceivedSignals(idx).StartTime = signalInfo.StartTime;
                % Sample duration (in microseconds)
                sampleDuration = 1e6 * (1 / signalInfo.SampleRate);
                waveformDuration = signalInfo.NumSamples * sampleDuration;
                % Signal end time
                obj.ReceivedSignals(idx).EndTime = signalInfo.StartTime + waveformDuration - 1;
            else
                sprintf(['Reception buffer is full. Increase the current ',...
                'buffer size to greater than {%d}.'], int64(obj.BufferSize))
            end

        end

        function nrWaveform = getReceivedWaveform(obj, rxStartTime, rxDuration, sampleRate)
            %getReceivedWaveform Return the received waveform for the
            %reception duration
            %
            %   NRWAVEFORM = getReceivedWaveform(OBJ, RXSTARTTIME, RXDURATION, SAMPLERATE)
            %   Returns the NR waveform
            %
            %   RXSTARTTIME  - Reception start time of receiver (in microseconds)
            %
            %   RXDURATION   - Duration of reception (in microseconds). It
            %   is a scalar
            %
            %   SAMPLERATE - Sample rate of the waveform. It is a
            %   scalar
            %
            %   NRWAVEFORM - Represents resultant waveform. It is a MxN
            %   matrix of complex values. Here 'M' represents number of IQ
            %   samples and 'N' represents the number of Rx antennas.
                                
            % Reception end time (in microseconds)
            rxEndTime = rxStartTime + rxDuration - 1;
            % Get indices of the overlapping signals
            waveformIndices = getOverlappingSignalIdxs(obj, rxStartTime, rxEndTime);

            % Get the resultant waveform from interfering waveforms
            if isempty(waveformIndices)
                % Return the empty waveform
                nrWaveform = [];
            else
                % Calculate the number of samples per microsecond
                numSamples = sampleRate / 1e6;
                % Initialize the waveform
                waveformLength = round(rxDuration * numSamples);
                nrWaveform = complex(zeros(waveformLength, obj.NRxAnts));

                for idx = 1:length(waveformIndices)
                    % Fetch received signal
                    receivedSignal = obj.ReceivedSignals(waveformIndices(idx));
                    % Sample duration of the received signal
                    if sampleRate ~= receivedSignal.SampleRate
                        % Resample the waveform
                        receivedWaveform = resample(receivedSignal.Waveform, sampleRate, receivedSignal.SampleRate);
                    else
                        receivedWaveform = receivedSignal.Waveform;
                    end

                    % Calculate the number of overlapping samples
                    overlapStartTime = max(rxStartTime, receivedSignal.StartTime);
                    overlapEndTime = min(rxEndTime, receivedSignal.EndTime) + 1;
                    numOverlapSamples = round((overlapEndTime - overlapStartTime) * numSamples);

                    % Signal received after reception start
                    if rxStartTime < receivedSignal.StartTime

                        % Calculate the overlapping start and end index of
                        % the received waveform IQ samples
                        receivedSignalStartIdx = 1;
                        receivedSignalEndIdx = numOverlapSamples;

                        % Calculate the overlapping start and end index of the
                        % actual waveform IQ samples
                        if rxEndTime <= receivedSignal.EndTime
                            % Reception end time is less than or equal to the
                            % received signal end time
                            sampleStartIdx = waveformLength - numOverlapSamples + 1;
                            sampleEndIdx = waveformLength;
                        else
                            % Reception end time is greater than the received
                            % signal end time
                            sampleStartIdx = round((receivedSignal.StartTime - rxStartTime) * numSamples) + 1;
                            sampleEndIdx = sampleStartIdx + numOverlapSamples - 1;
                        end

                    else  % Signal received before reception start

                        % Calculate the overlapping start and end index of
                        % actual waveform IQ samples
                        sampleStartIdx = 1;
                        sampleEndIdx = numOverlapSamples;

                        % Calculate the overlapping start and end index of
                        % received waveform IQ samples
                        receivedSignalStartIdx = round((rxStartTime - receivedSignal.StartTime) * numSamples) + 1;
                        receivedSignalEndIdx = receivedSignalStartIdx + numOverlapSamples - 1;
                    end

                    % Combine the IQ samples
                    nrWaveform(sampleStartIdx:sampleEndIdx, :) = nrWaveform(sampleStartIdx:sampleEndIdx, :) + ...
                        receivedWaveform(receivedSignalStartIdx:receivedSignalEndIdx, :);
                end
            end
        end

    end

    methods (Access = private)

        function storeIdx = getStoreIndex(obj)
            %getStoreIndex Get an index to store the waveform in the buffer

            storeIdx = 0;
            for idx = 1:obj.BufferSize
                % Get a free index in the buffer
                if obj.ReceivedSignals(idx).NumSamples == 0
                    storeIdx = idx;
                    break;
                end
            end
        end

        function interferedIdxs = getOverlappingSignalIdxs(obj, startTime, endTime)
            %getOverlappingSignalIdxs Get indices of the received signals from stored
            %buffer based on reception start and end time

            % Initialize the vector to store indices of overlapping signals
            interferingIdxs = zeros(obj.BufferSize, 1);
            currentOverlapCount = 0;
            for idx = 1:obj.BufferSize
                % Fetch valid signals
                if obj.ReceivedSignals(idx).NumSamples > 0
                    % Fetch index of the overlapping signals based on the start time
                    % and end time
                    if (startTime <= obj.ReceivedSignals(idx).EndTime) && ...
                            endTime >= (obj.ReceivedSignals(idx).StartTime)
                        currentOverlapCount = currentOverlapCount + 1;
                        % Add the index of overlapping signal
                        interferingIdxs(currentOverlapCount) = idx;
                    end
                end
            end
            % Return the indices of the stored signals
            interferedIdxs = interferingIdxs(interferingIdxs>0);
        end

        function removeObsoleteWaveforms(obj, timestamp)
            %removeObsoleteWaveforms Remove the signals from the stored
            %buffer whose end time is less than the given timestamp

            for idx = 1:obj.BufferSize
                % Remove the signal
                if obj.ReceivedSignals(idx).NumSamples > 0 && obj.ReceivedSignals(idx).EndTime < timestamp
                    % Reset the NumSamples property of the signal, to
                    % indicate that the signal is obsolete
                    obj.ReceivedSignals(idx).NumSamples = 0;
                end
            end
        end
    end
end