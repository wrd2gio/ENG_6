matlab
function game_logic(varargin)
% GAME_LOGIC  Card memory (concentration) game with optional ThingSpeak
% integration for online play.
%
% Usage:
%   game_logic()                     % start local single-player game
%   game_logic('Pairs',8)            % start local game with 8 pairs
%   game_logic('ThingSpeak',opts)    % enable ThingSpeak online moves
%
% ThingSpeak options (struct fields):
%   ChannelID  - numeric channel id
%   WriteKey   - write API key (to publish moves)
%   ReadKey    - read API key (to read opponent moves)
%   PollSec    - polling interval in seconds (default 5)

% Example:
%   opts.ChannelID = 12345;
%   opts.WriteKey = 'ABCDE';
%   opts.ReadKey  = 'VWXYZ';
%   game_logi('Pairs',6,'ThingSpeak',opts)

% Minimal standalone implementation: creates a GUI with buttons as cards,
% supports flipping, matching and optional ThingSpeak exchange of moves.

% Parse inputs
p = inputParser;
addParameter(p,'Pairs',8,@(x)isnumeric(x)&&isscalar(x)&&x>0);
addParameter(p,'ThingSpeak',struct(),@isstruct);
parse(p,varargin{:});
nPairs = p.Results.Pairs;
tsOpts = p.Results.ThingSpeak;

% Game state
N = nPairs*2;
deck = repmat(1:nPairs,1,2);
deck = deck(randperm(N));
state = zeros(1,N); % 0=face down, 1=face up, 2=matched
firstIdx = [];
busy = false;
scoreLocal = 0;
scoreRemote = 0;

% ThingSpeak state
useTS = isfield(tsOpts,'ChannelID') && ~isempty(tsOpts.ChannelID) && isfield(tsOpts,'WriteKey') && isfield(tsOpts,'ReadKey');
if useTS
	channelID = tsOpts.ChannelID;
	writeKey = tsOpts.WriteKey;
	readKey = tsOpts.ReadKey;
	pollSec = ifelse(isfield(tsOpts,'PollSec'),tsOpts.PollSec,5);
else
	channelID = []; writeKey = ''; readKey = ''; pollSec = 5;
end

% Create GUI
fig = figure('Name','Card Memory - game_logi','NumberTitle','off','MenuBar','none','ToolBar','none','Resize','off');
cols = ceil(sqrt(N));
rows = ceil(N/cols);
btnW = 80; btnH = 60; pad = 10;
figWidth = cols*(btnW+pad)+pad; figHeight = rows*(btnH+pad)+120;
fig.Position(3:4) = [figWidth figHeight];

cards = gobjects(1,N);
for i=1:N
	r = ceil(i/cols); c = mod(i-1,cols)+1;
	x = pad + (c-1)*(btnW+pad);
	y = figHeight - (pad + r*(btnH+pad));
	cards(i) = uicontrol(fig,'Style','pushbutton','String','',... 
		'Position',[x y btnW btnH], 'FontSize',18, 'UserData',i, ...
		'Callback',@cardCallback);
end

lblScore = uicontrol(fig,'Style','text','String',sprintf('You: %d  Opponent: %d',scoreLocal,scoreRemote),... 
	'Position',[10,10,figWidth-20,30],'FontSize',12,'HorizontalAlignment','left');

btnReset = uicontrol(fig,'Style','pushbutton','String','Reset','Position',[figWidth-80,10,70,30],'Callback',@resetGame);

% ThingSpeak polling timer
if useTS
	t = timer('ExecutionMode','fixedSpacing','Period',pollSec,'TimerFcn',@pollThingSpeak);
	start(t);
else
	t = [];
end

% Nested callbacks
	function cardCallback(src,~)
		if busy; return; end
		idx = src.UserData;
		if state(idx)==2 || state(idx)==1; return; end
		state(idx)=1;
		updateButton(idx);
		if isempty(firstIdx)
			firstIdx = idx;
			% if online, optionally notify opponent of flip
			if useTS
				publishMove(struct('type','flip','idx',idx));
			end
		else
			busy = true;
			drawnow;
			pause(0.7);
			if deck(idx)==deck(firstIdx)
				state(idx)=2; state(firstIdx)=2;
				scoreLocal = scoreLocal + 1;
				updateScore();
				if useTS
					publishMove(struct('type','match','idx1',firstIdx,'idx2',idx));
				end
			else
				state(idx)=0; state(firstIdx)=0;
				if useTS
					publishMove(struct('type','mismatch','idx1',firstIdx,'idx2',idx));
				end
			end
			firstIdx = [];
			updateAllButtons();
			busy = false;
			checkWin();
		end
	end

	function updateButton(i)
		if state(i)==0
			set(cards(i),'String','');
		elseif state(i)==1
			set(cards(i),'String',num2str(deck(i)));
		elseif state(i)==2
			set(cards(i),'String',num2str(deck(i)),'Enable','inactive');
		end
	end

	function updateAllButtons()
		for k=1:N
			updateButton(k);
		end
	end

	function updateScore()
		set(lblScore,'String',sprintf('You: %d  Opponent: %d',scoreLocal,scoreRemote));
	end

	function checkWin()
		if all(state==2)
			msgbox(sprintf('Game over! You: %d  Opponent: %d',scoreLocal,scoreRemote),'Finished');
			if ~isempty(t) && isvalid(t); stop(t); delete(t); end
		end
	end

	function resetGame(~,~)
		deck = repmat(1:nPairs,1,2);
		deck = deck(randperm(N));
		state = zeros(1,N);
		firstIdx = [];
		busy = false;
		scoreLocal = 0; scoreRemote = 0;
		for k=1:N
			set(cards(k),'Enable','on','String','');
		end
		updateScore();
		if useTS
			try publishMove(struct('type','reset')); catch; end
		end
	end

	function publishMove(move)
		% move is a struct; convert to JSON-like string
		try
			s = jsonencode(move);
		catch
			s = sprintf('MATLAB_MOVE');
		end
		if isempty(writeKey) || isempty(channelID)
			return;
		end
		url = sprintf('https://api.thingspeak.com/update?api_key=%s&field1=%s',writeKey,urlencode(s));
		try
			webread(url);
		catch
			% non-fatal
		end
	end

	function pollThingSpeak(~,~)
		% read last feed and parse field1 (expects JSON string)
		if isempty(readKey) || isempty(channelID); return; end
		url = sprintf('https://api.thingspeak.com/channels/%d/feeds.json?api_key=%s&results=1',channelID,readKey);
		try
			data = webread(url);
			if isfield(data,'feeds') && ~isempty(data.feeds)
				f = data.feeds(1);
				if isfield(f,'field1') && ~isempty(f.field1)
					try
						move = jsondecode(f.field1);
						handleRemoteMove(move);
					catch
						% ignore parse errors
					end
				end
			end
		catch
			% ignore network errors
		end
	end

	function handleRemoteMove(move)
		% Process a move struct received from ThingSpeak
		if ~isstruct(move) || ~isfield(move,'type'); return; end
		switch move.type
			case 'flip'
				% show remote flip briefly
				idx = move.idx;
				if isempty(idx) || idx<1 || idx>numel(cards); return; end
				% show it without changing game logic
				set(cards(idx),'String',num2str(deck(idx)));
				pause(0.6);
				if state(idx)==0; set(cards(idx),'String',''); end
			case 'match'
				% opponent matched a pair
				if isfield(move,'idx1') && isfield(move,'idx2')
					i1 = move.idx1; i2 = move.idx2;
					state(i1)=2; state(i2)=2;
					scoreRemote = scoreRemote + 1;
					updateAllButtons(); updateScore(); checkWin();
				end
			case 'mismatch'
				% opponent tried and failed; no score change
			case 'reset'
				% opponent reset -> reset local board
				resetGame();
		end
	end

% Utility: inline ifelse
	function out = ifelse(cond,a,b)
		if cond; out = a; else out = b; end
	end

% Clean up timer on close
fig.CloseRequestFcn = @onClose;
	function onClose(~,~)
		if ~isempty(t) && isvalid(t)
			try stop(t); delete(t); catch; end
		end
		delete(fig);
	end

% initial draw
updateAllButtons(); updateScore();
end

