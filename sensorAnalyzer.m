% Write your name in here as a comment line
% Name: Daniel Salcedo


classdef sensorAnalyzer < handle


    % Public properties (mutable)
    properties 
        TargetSignal; % Acceleration signal
        TargetSignalTs; % Signal time stamp
        
    end

    % Private properties (immutable)
    properties(Access=private)
        mobileDevConnection;
    end

    % Callable methods
    methods
        
        function obj = sensorAnalyzer()
            obj.mobileDevConnection = mobiledev;
        end


        function window = getSignal(obj)
            obj.mobileDevConnection.Logging = 1;
            pause(2);
            obj.mobileDevConnection.Logging = 0;

            [a, t] = accellog(obj.mobileDevConnection);

            if isempty(a)
                window = [];
                return;
            end
            
            SensorData = [a(:,1), a(:,2), a(:,3),t];
            obj.TargetSignal = a;
            obj.TargetSignalTs = t;
            

            %% window size 
            N = 20;
            
            if size(a,1) > N
                window = a(end-N+1:end, :);
            else
                window = a;
            end
        end
        

    

    end
end
