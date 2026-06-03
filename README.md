# Card Memory Game - Sensor & ThingSpeak Integration

A MATLAB-based card memory (concentration) game with dual control: **GUI buttons** and **mobiledev sensor inputs** (accelerometer & orientation), with optional **ThingSpeak** online multiplayer support.

## Features

- **Local Play**: Single-player mode with GUI card buttons (basis for the functional multiplayer game)
- **Sensor Control**: Use device acceleration and/or orientation to select cards 
- **Online Play**: ThingSpeak-enabled multiplayer with real-time move synchronization
- **Score Tracking**: Local and remote opponent scores displayed live (possible leaderboard function??)

## Quick Start

### Local Play (GUI Only)
```matlab
game_logic()                % Default by MATLAB Code 8 pairs (16 cards)
game_logic('Pairs', 6)      % Custom gamemode (future reference) 6 pairs (12 cards)
game_logic('UseSensors', false)  % GUI buttons only, no sensors (copilot addition)
```

### Sensor-Controlled Play (Mobile Device)
```matlab
game_logic('UseSensors', true)   % Auto-enable sensors if available
```

**Sensor Mapping:** 
1. Warning this is a `estimation provided` by copilot 
- **Roll angle** (-90° to +90°): Selects column left to right
- **Pitch angle** (-90° to +90°): Selects row top to bottom
- **Acceleration magnitude** (>25 m/s²): Tap/shake to confirm selection

### Online Play (ThingSpeak)
```matlab
opts.ChannelID = 1854971;  % Modify as needed per channelID
opts.PollSec = 5;          % Check opponent moves every 5s good baseline
game_logic('ThingSpeak', opts, 'Pairs', 8)
```

**ThingSpeak API Keys** (hardcoded):
- **Write Key**: `7OOJBDU1FXB2AAU5` (publish your moves)
- **Read Key**: `3FLYFWUQZSVKN5W3` (receive opponent moves)
- **Channel ID**: `1854971` (default)

## Gameplay Rules

1. **Objective**: Match all pairs of cards by flipping two at a time
2. **Score**: Earn 1 point per successfully matched pair
3. **Turn**: If cards don't match, they flip back face-down
4. **Win**: All pairs matched; final score displayed

## Game Controls

| Method | Action |
|--------|--------|
| **GUI** | Click a button to flip a card |
| **Sensor** | Tilt device (roll/pitch) to move cursor; shake to confirm |
| **Reset** | Press "Reset" button to restart game |

## Files

- `game_logi.m` – Main game logic and GUI
- `README.md` – This file

## Troubleshooting

### Sensors Not Detected
If mobiledev initialization fails:
1. Ensure MATLAB Mobile is installed and running on your device
2. Verify device is paired with MATLAB
3. Run with `UseSensors=false` to use GUI only
4. Check: `mobiledev()` in MATLAB console
5. review the possible errors if the problem can not be found

### ThingSpeak Connection Issues
1. Verify internet connection
2. Check channel ID and API keys
3. Monitor ThingSpeak channel feeds for incoming data
4. Errors are logged silently; move forward without TS if offline

## Example Session

```matlab
% Start a 6-pair game with sensor control and ThingSpeak
opts.ChannelID = 1854971;
opts.PollSec = 3;
game_logic('Pairs', 6, 'UseSensors', true, 'ThingSpeak', opts)

% In another MATLAB instance/user, run the same to play together
```

## Notes

- Sensor polling runs at 100ms intervals (10 Hz) for responsive control
- ThingSpeak polling is configurable but defaults to 5 seconds
- All matched cards become inactive and cannot be re-selected
- Game automatically detects when all pairs are matched and displays final scores
