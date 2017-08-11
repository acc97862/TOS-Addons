local loaded = false;

function REMOVEEVENTBUTTON_ON_INIT(addon, frame)
	addon:RegisterMsg("GAME_START_3SEC", "REMOVEEVENTBUTTON_3SEC");
end

function REMOVEEVENTBUTTON_3SEC()
	local acutil = require('acutil');
	if not loaded then
		acutil.slashCommand('/event', OPEN_INGAME_EVENTBANNER_FRAME);
		CHAT_SYSTEM('[removeEventButton:help] /event');
		loaded = true;
	end

	ReserveScript('ui.CloseFrame("minimizedeventbanner");', 1);
end