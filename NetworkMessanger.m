%ThinkSpeak Channel ID and API Key

%ChannelID = 3383934
%WriteAPIKey = NPMTEL19I4BXYDHS
%ReadAPIKey = RTC2OM3Q1X84MTGH

% ---Config--- %

ChannelID = 3383934; % Replace with your actual Channel ID
WriteAPIKey = 'NPMTEL19I4BXYDHS'; % Replace with your actual Write API Key
ReadAPIKey = 'RTC2OM3Q1X84MTGH'; % Replace with your actual Read API Key


% These parameters are used to send data to ThingsSpeak and read with the API key.
% and the apprioately numbered field to the correct data in said field.

params = [...
        "api_key",       writeAPIKey; ...
        "field1",        num2str(player_id); ...
        "field2",        num2str(dice_roll); ...
        "field3",        num2str(turn_number); ...
        "field4",        num2str(p1_score); ...
        "field5",        num2str(p2_score) ...
    ];

% inital write to thingspeak.
thinkspeakWrite (ChannelID,[player_id, dice_roll, turn_number, p1_score, p2_score],'WriteKey', WriteAPIKey);    

% Double check that everything was sent correctly.
response = thinkspeakWrite (ChannelID,[player_id, dice_roll, turn_number, p1_score, p2_score],'WriteKey', WriteAPIKey);

if isempty(response)
    disp('Failed to send data to ThingSpeak.');
end

% initial read to thingspeak.
thinkspeakRead(ChannelID, 'ReadKey', ReadAPIKey, 'NumPoints', 1); % Reads the most recent entry from the channel
