% Write your name in here as a comment line
% Name: Daniel Salcedo


classdef sensorAnalyzer < handle


    % Public properties (mutable)
    properties 
        TargetSignal; % Acceleration signal
        TargetSignalTs; % Signal time stamp
        AccelData;
        
    end

    % Private properties (immutable)
    properties(Access=private)
        mobileDevConnection;
    end

    % Callable methods
    methods
        
        function obj = sensorAnalyzer()
                try
                    clear mobiledev;  % Clear from workspace
                catch
                end
            obj.mobileDevConnection = mobiledev;
        end
        function startLogging(obj)
            if isempty(obj.mobileDevConnection) || ~isvalid(obj.mobileDevConnection)
                obj.mobileDevConnection = mobiledev;
            end
            obj.mobileDevConnection.Logging = 1;
            pause(2);
            obj.mobileDevConnection.Logging = 0;


            % Retrieve raw acceleration data (Ax, Ay, Az, t)
            data = accellog(obj.mobileDevConnection);
            % data columns: [Ax, Ay, Az, t (in seconds)]
            obj.AccelData = data;
        end


        function window = getSignal(obj, windowSize)

            if nargin < 2
                windowSize = 20;
            end

            if isempty(obj.AccelData)
                window = [];
                return;
            end

            nSamples = size(obj.AccelData, 1);
             if nSamples >= windowSize
                window = obj.AccelData(end-windowSize+1:end, 1:3);
            else
                window = obj.AccelData(:, 1:3);
             end
        end


        function clearData(obj)
            obj.AccelData = [];    
        end
        

    

    end
end
