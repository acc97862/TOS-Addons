--skilllog.lua
--dofile("../skilllog.lua");

local logger = {};
local recording = false;
local updateTime = 0;
local linesShown = 0;

function SKILLLOG_ON_INIT(addon, frame)
	local acutil = require("acutil");
	linesShown = 0;
	acutil.addSysIcon("skilllog", "sysmenu_mac", "SkillLog", "SKILLLOG_TOGGLE_FRAME");
	addon:RegisterMsg("FPS_UPDATE", "SKILLLOG_CHECK_UPDATE");
	addon:RegisterMsg("SHOT_START", "SKILLLOG_SHOT_START");

	local textbox = ui.GetFrame("skilllog"):GetChild("textbox");
	tolua.cast(textbox, "ui::CTextView");
	textbox:Clear();
	SKILLLOG_UPDATE();

	if recording then
		frame:GetChild("startBtn"):SetText("{@st41b}Stop");
	else
		frame:GetChild("startBtn"):SetText("{@st41b}Start");
	end
end

function SKILLLOG_SAVELOG()
	if #logger > 0 then
		local datetime = os.date("%Y-%m-%d-%H-%M-%S");
		local file = io.open(string.format("../addons/skilllog/%s.txt", datetime), "w");
		local txt = string.format("Skilllog of %s %s on %s\n", GETMYPCNAME(), GETMYFAMILYNAME(), os.date("%b %d %Y %X"));
		
		for t = 1, #logger do
			txt = txt .. string.format("\n%s\t%s", logger[t].ctime, logger[t].name);
		end

		file:write(txt);
		file:flush();
		file:close();
		ui.SysMsg("Log saved");
	end
end

function SKILLLOG_STARTSTOP()
	local ctime = imcTime.GetAppTime();
	if recording then
		recording = false;
		table.insert(logger,{ctime = ctime, name = "Count end"});
		ui.GetFrame("skilllog"):GetChild("startBtn"):SetText("{@st41b}Start");
		SKILLLOG_UPDATE();
		linesShown = 0;
	else
		recording = true;
		logger = {{ctime = ctime, name = "Count start"}};
		updateTime = ctime;
		local textbox = ui.GetFrame("skilllog"):GetChild("textbox");
		tolua.cast(textbox, "ui::CTextView");
		textbox:Clear();
		ui.GetFrame("skilllog"):GetChild("startBtn"):SetText("{@st41b}Stop");
		SKILLLOG_UPDATE();
	end
	CHAT_SYSTEM("Skill recording " .. (recording and "started" or "stopped"));
	return 1
end

function SKILLLOG_SHOT_START()
	local actor = GetMyActor();
	if recording and actor then
		local ctime = imcTime.GetAppTime();
		local skill_id = actor:GetUseSkill();
		local skill_obj = GetSkill(GetMyPCObject(), GetClassByType("Skill", skill_id).ClassName);

		if skill_id ~= nil then
			table.insert(logger, {ctime = ctime, name = skill_obj.ClassName});
		end
	end
end

function SKILLLOG_OPEN()
end

function SKILLLOG_CLOSE()
end

function SKILLLOG_TOGGLE_FRAME()
	ui.ToggleFrame("skilllog");
end

function SKILLLOG_CHECK_UPDATE()
	local ctime = imcTime.GetAppTime();
	if recording and ctime > updateTime + 1 then
		updateTime = ctime;
		SKILLLOG_UPDATE();
	end
end

function SKILLLOG_UPDATE()
	local ctime = imcTime.GetAppTime();
	local initTime = logger[1].ctime;
	local casts = #logger - 1;
	if not recording then
		ctime = logger[#logger].ctime;
		casts = casts - 1;
	end

	local frame = ui.GetFrame("skilllog");
	local castcount = frame:GetChild("castcount");
	local timespent = frame:GetChild("timespent");
	local castspersec = frame:GetChild("castspersec");
	local textbox = frame:GetChild("textbox");

	tolua.cast(castcount, "ui::CRichText");
	tolua.cast(timespent, "ui::CRichText");
	tolua.cast(castspersec, "ui::CRichText");
	tolua.cast(textbox, "ui::CTextView");

	castcount:SetText("{@st43}Cast Count: " .. casts .. "{/}");
	timespent:SetText(string.format("{@st43}Time Taken: %.2f{/}", ctime - initTime));
	castspersec:SetText(string.format("{@st43}Casts per Second: %.2f{/}", casts/(ctime - initTime)));
	for t = linesShown + 1, #logger do
		textbox:AddText(string.format("%6.2f    %s", logger[t].ctime - initTime, logger[t].name), "white_20_ol");
	end
	linesShown = #logger;
end