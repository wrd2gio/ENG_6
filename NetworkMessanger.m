classdef NetworkMessanger < handle
    % ThingSpeak helper for sharing dice game state between two devices.

    properties
        ChannelID = 3383747
        WriteAPIKey = '7OOJBDU1FXB2AAU5'
        ReadAPIKey = '3FLYFWUQZSVKN5W3'
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
            values = [ ...
                game.CurrentPlayer, ...
                lastRoll, ...
                game.RoundNum, ...
                game.P1Score, ...
                game.P2Score, ...
                game.TargetNumber, ...
                double(game.GameOver), ...
                game.Winner ...
            ];

            entryID = thingSpeakWrite(obj.ChannelID, values, ...
                'Fields', fields, ...
                'WriteKey', obj.WriteAPIKey);

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

            remoteState = struct( ...
                'CurrentPlayer', data(1), ...
                'LastRoll', data(2), ...
                'RoundNum', data(3), ...
                'P1Score', data(4), ...
                'P2Score', data(5), ...
                'TargetNumber', data(6), ...
                'GameOver', logical(data(7)), ...
                'Winner', data(8));
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
        end
    end
end
