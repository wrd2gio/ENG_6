classdef NetworkMessanger < handle
    % ThingSpeak helper for sharing dice game state between two devices.

    properties
        ChannelID = 3383747
        WriteAPIKey = '7OOJBDU1FXB2AAU5'
        ReadAPIKey = '3FLYFWUQZSVKN5W3'
        MinimumWriteInterval = 16
        LastWriteTimer = []
    end

    methods
        function obj = NetworkMessanger(channelID, writeKey, readKey)
            if nargin >= 1 && ~isempty(channelID)
                obj.ChannelID = channelID;
            end
            if nargin >= 2 && ~isempty(writeKey)
                obj.WriteAPIKey = writeKey;
            end
            if nargin >= 3 && ~isempty(readKey)
                obj.ReadAPIKey = readKey;
            end
        end

        function entryID = publishGameState(obj, game, lastRoll)
            if nargin < 3 || isempty(lastRoll)
                lastRoll = 0;
            end

            fields = 1:8;
            stateCode = game.Winner * 100 + ...
                game.RollsRemainingThisTurn * 10 + ...
                double(game.P1PenaltyNext) * 2 + ...
                double(game.P2PenaltyNext);

            values = [ ...
                game.CurrentPlayer, ...
                lastRoll, ...
                game.RoundNum, ...
                game.P1Score, ...
                game.P2Score, ...
                game.TargetNumber, ...
                double(game.GameOver), ...
                stateCode ...
            ];

            obj.waitForThingSpeakWriteSlot();

            entryID = thingSpeakWrite(obj.ChannelID, values, ...
                'Fields', fields, ...
                'WriteKey', obj.WriteAPIKey);
            obj.LastWriteTimer = tic;

        end

        function remoteState = readLatestGameState(obj)
            data = thingSpeakRead(obj.ChannelID, ...
                'Fields', 1:8, ...
                'NumPoints', 1, ...
                'ReadKey', obj.ReadAPIKey);

            if isempty(data) || all(isnan(data))
                remoteState = [];
                return;
            end

            stateCode = data(8);
            winner = floor(stateCode / 100);
            stateCode = stateCode - winner * 100;
            rollsRemaining = floor(stateCode / 10);
            stateCode = stateCode - rollsRemaining * 10;
            p1PenaltyNext = stateCode >= 2;
            p2PenaltyNext = mod(stateCode, 2) == 1;

            remoteState = struct( ...
                'CurrentPlayer', data(1), ...
                'LastRoll', data(2), ...
                'RoundNum', data(3), ...
                'P1Score', data(4), ...
                'P2Score', data(5), ...
                'TargetNumber', data(6), ...
                'GameOver', logical(data(7)), ...
                'Winner', winner, ...
                'RollsRemainingThisTurn', rollsRemaining, ...
                'P1PenaltyNext', p1PenaltyNext, ...
                'P2PenaltyNext', p2PenaltyNext);
        end

        function applyRemoteState(~, game, remoteState)
            if isempty(remoteState)
                return;
            end

            game.CurrentPlayer = remoteState.CurrentPlayer;
            game.P1Score = remoteState.P1Score;
            game.P2Score = remoteState.P2Score;
            game.RoundNum = remoteState.RoundNum;
            game.TargetNumber = remoteState.TargetNumber;
            game.GameOver = remoteState.GameOver;
            game.Winner = remoteState.Winner;
            game.RollsRemainingThisTurn = remoteState.RollsRemainingThisTurn;
            game.P1PenaltyNext = remoteState.P1PenaltyNext;
            game.P2PenaltyNext = remoteState.P2PenaltyNext;
            game.LastRoll = remoteState.LastRoll;
        end

        function waitForThingSpeakWriteSlot(obj)
            if isempty(obj.LastWriteTimer)
                return;
            end

            elapsedSeconds = toc(obj.LastWriteTimer);
            waitSeconds = obj.MinimumWriteInterval - elapsedSeconds;
            if waitSeconds > 0
                pause(waitSeconds);
            end
        end
    end
end
