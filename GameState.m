classdef GameState < handle
    
    properties
        P1Score = 0
        P2Score = 0
        CurrentPlayer = 1
        TokenHolder = 0
        TargetNumber
        GameOver = false
        Winner = 0
    end

    methods
        function obj = GameState()  
            obj.TargetNumber = randi([20 30]);
        end
        function reset(obj)
            obj.PlayerScores = [0 0];
            obj.CurrentPlayer = 1;
            obj.TargetNumber = randi([20, 30]);
            obj.GameOver = false;
            obj.Winner = 0;
        end
        function roll = RollDice(obj)
            if obj.GameOver
                return;
            end

            roll = randi([1 6]);
            if obj.CurrentPlayer == 1
                obj.P1Score = roll + obj.P1Score
                % obj.TokenHolder = 2;

                return
            else
                obj.P2Score = roll + obj.P2Score
                return
            end

        end




    end
    
end
         