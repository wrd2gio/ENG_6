classdef GestureDetector < handle

    properties
        Gesture
        Sensor
        ShakeThreshold = 10;
        SwipeThreshold = 5;
        SkipThreshold = 1;
    end
    methods
        function obj = GestureDetector(sensorObj)
            obj.Sensor = sensorObj;
        end
        function gestures = detect(obj)

            window = obj.Sensor.getSignal(); % Retrives Signal Data from sensorAnalyzer.m
            
            if isempty(window)
                gestures = []; % Initialize gestures array
                return;
            end
            Ax = window(:,1);
            Ay = window(:,2);
            Az = window(:,3);

            A = sqrt(Ax.^2 + Ay.^2 + Az.^2);
            % Detect gestures based on acceleration magnitude
            if(mean(movmean(A, 5)) >= obj.ShakeThreshold)
                gestures = "Shake";
            elseif (mean(movmean(A, 5)) < obj.ShakeThreshold) && (mean(movmean(A,5)) > obj.SwipeThreshold)
                gestures = "Swipe";
            elseif (mean(movmean(A, 5)) > obj.SkipThreshold) && (mean(movmean(A,5)) < obj.SwipeThreshold)
                gestures = "Skip";
            else
                gestures = "None";
            end

        end

    end

end
           
        
