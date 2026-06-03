classdef GestureDetector < handle

    properties
        Gesture
        Sensor
        ShakeThreshold = 3     % Mean dynamic acceleration for shake (m/s²)
        SkipThreshold = 1.25      % Mean dynamic acceleration for skip (m/s²)
        lastTriggerTime = 0
        CooldownSeconds = 1.5
    end
    methods
        function obj = GestureDetector(sensorObj)
            obj.Sensor = sensorObj;
        end
        
        function gesture = detect(obj)
            window = obj.Sensor.getSignal(); % Retrives Signal Data from sensorAnalyzer.m
            
            if isempty(window) || size(window,1) < 10
                gesture = "None"; % No gesture if not enough data
                return;
            end
            Ax = window(:,1);
            Ay = window(:,2);
            Az = window(:,3);

            A = sqrt(Ax.^2 + Ay.^2 + Az.^2); % Magnitude including gravity


            g = mean(A);
            A_dyn = abs(A - g); % Removes Gravity

            % Mean dynamic acceleration over the window
            mean_dyn = mean(A_dyn);

            % Cooldown to avoid repeated triggers
            currentTime = tic;
            if (currentTime - obj.lastTriggerTime) < obj.CooldownSeconds
                gesture = "None";
                return;
            end
            %% Classify Gestures
            if mean_dyn >= obj.ShakeThreshold
                gesture = "Shake";
                obj.lastTriggerTime = currentTime;
                disp(mean_dyn)
            elseif (mean_dyn < obj.ShakeThreshold) && (mean_dyn > obj.SkipThreshold)
                gesture = "Skip";
                obj.lastTriggerTime = currentTime;
                disp(mean_dyn)
            else
                gesture = "None";
                disp(mean_dyn)
            end

        end

    end

end
           
        
