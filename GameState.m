classdef GameState < handle
    
    properties
        P1Score = 0
        P2Score = 0
        CurrentPlayer = 1
        TokenHolder = 0
        TargetNumber
        GameOver = false
        Winner = 0
        RoundNum = 0
        Network = []
        LastRoll = 0

        % Exist for Player Skips
        RollsRemainingThisTurn = 1   % How many rolls player must do this turn (1 normally, 2 if penalized)
        P1PenaltyNext = false        % Does Player 1 have to roll twice next turn?
        P2PenaltyNext = false        % Does Player 2 have to roll twice next turn?
    end

    methods
        function obj = GameState()  
            obj.TargetNumber = randi([20 30]);
        end
        function reset(obj)
            obj.P1Score = 0;
            obj.P2Score = 0;
            obj.CurrentPlayer = 1;
            obj.TargetNumber = randi([20, 30]);
            obj.GameOver = false;
            obj.Winner = 0;
            obj.RoundNum = 0;
            obj.LastRoll = 0;
            obj.RollsRemainingThisTurn = 1;
            obj.P1PenaltyNext = false;
            obj.P2PenaltyNext = false;
            obj.publishThingSpeakState(0);
        end
        function enableThingSpeak(obj, channelID, writeKey, readKey, publishInitialState)
            if nargin < 5
                publishInitialState = false;
            end
            if nargin < 2
                obj.Network = NetworkMessanger();
            elseif nargin < 3
                obj.Network = NetworkMessanger(channelID);
            elseif nargin < 4
                obj.Network = NetworkMessanger(channelID, writeKey);
            else
                obj.Network = NetworkMessanger(channelID, writeKey, readKey);
            end
            if publishInitialState
                obj.publishThingSpeakState(0);
            end
        end
        function roll = RollDice(obj)
            if obj.GameOver
                return;
            end



            roll = randi([1 6]);
            obj.LastRoll = roll;

            if obj.CurrentPlayer == 1
                obj.P1Score = roll + obj.P1Score;
                obj.TokenHolder = obj.TokenHolder + 1;
            else
                obj.P2Score = roll + obj.P2Score;
                obj.TokenHolder = obj.TokenHolder + 1;
            end

            %Check Win Condition
            if obj.CurrentPlayer == 1 && obj.P1Score >= obj.TargetNumber
                obj.Winner = 2;
                obj.GameOver = true;
                obj.publishThingSpeakState(roll);
                return;
            elseif obj.CurrentPlayer == 2 && obj.P2Score >= obj.TargetNumber
                obj.Winner = 1;
                obj.GameOver = true;
                obj.publishThingSpeakState(roll);
                return;
            end

            obj.RollsRemainingThisTurn = obj.RollsRemainingThisTurn - 1;
            if obj.RollsRemainingThisTurn <= 0
                obj.switchTurn();
            end

            obj.publishThingSpeakState(roll);

        end
        function switchTurn(obj)
            obj.CurrentPlayer = 3 - obj.CurrentPlayer;

            if (obj.CurrentPlayer == 1) && (obj.P1PenaltyNext == true)
                obj.P1PenaltyNext = false; % Reset penalty for Player 1
                obj.RollsRemainingThisTurn = 2;
            elseif obj.CurrentPlayer == 2 && obj.P2PenaltyNext
                obj.RollsRemainingThisTurn = 2;
                obj.P2PenaltyNext = false;  % Consume the penalty
            else
                obj.RollsRemainingThisTurn = 1;
            end

            obj.RoundNum = obj.RoundNum + 1;


        end
                
        function skipTurn(obj)
            if obj.GameOver; return; end
            obj.LastRoll = 0;
            
            % Apply penalty to current player for their NEXT turn
            if obj.CurrentPlayer == 1
                obj.P1PenaltyNext = true;
            else
                obj.P2PenaltyNext = true;
            end
            
            % Switch turns immediately (skip this turn without rolling)
            obj.switchTurn();
            obj.publishThingSpeakState(0);
            
        end


        function remaining = getRollsRemaining(obj)
            remaining = obj.RollsRemainingThisTurn;
        end
        function status = getTurnStatus(obj)
            % Helper for UI to display game status
            if obj.GameOver == true
                status = sprintf('Game Over! Player %d wins!', obj.Winner);

            elseif obj.RollsRemainingThisTurn == 2
                status = sprintf('Player %d - Must roll TWICE this turn (penalty from previous skip)', obj.CurrentPlayer);
            else
                status = sprintf('Player %d - Roll once then turn ends', obj.CurrentPlayer);
            end
            
        end

        function publishThingSpeakState(obj, lastRoll)
            if isempty(obj.Network)
                return;
            end
            try
                obj.Network.publishGameState(obj, lastRoll);
            catch ME
                warning('GameState:ThingSpeakWriteFailed', ...
                    'Could not write game state to ThingSpeak: %s', ME.message);
            end
        end

        function didUpdate = readThingSpeakState(obj)
            didUpdate = false;
            if isempty(obj.Network)
                return;
            end
            try
                remoteState = obj.Network.readLatestGameState();
                if isempty(remoteState)
                    return;
                end
                if remoteState.RoundNum >= obj.RoundNum
                    obj.Network.applyRemoteState(obj, remoteState);
                    didUpdate = true;
                end
            catch ME
                warning('GameState:ThingSpeakReadFailed', ...
                    'Could not read game state from ThingSpeak: %s', ME.message);
            end
        end
            
    end
    
end
         
