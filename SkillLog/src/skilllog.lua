--skilllog.lua

local loaded = false
local logger = {}
local recording = false
local linesShown = 0

function SKILLLOG_ON_INIT(addon, frame)
	if not loaded then
		loaded = true
		local acutil = require("acutil")
		acutil.addSysIcon("skilllog", "sysmenu_mac", "SkillLog", "SKILLLOG_TOGGLE_FRAME")
	end
	addon:RegisterMsg("FPS_UPDATE", "SKILLLOG_UPDATE")
	addon:RegisterMsg("SHOT_START", "SKILLLOG_SHOT_START")
	linesShown = 0
	SKILLLOG_UPDATE(true)

	if recording then
		frame:GetChild("startBtn"):SetText("{@st41b}Stop")
	else
		frame:GetChild("startBtn"):SetText("{@st41b}Start")
	end
end

function SKILLLOG_SAVELOG()
	if #logger > 0 then
		local txtTbl = {string.format("Skilllog of %s %s on %s\n", GETMYPCNAME(), GETMYFAMILYNAME(), os.date("%b %d %Y %X"))}

		for t = 1, #logger do
			txtTbl[t + 1] = string.format("%s\t%s", logger[t][1], logger[t][2])
		end

		local file = io.open(string.format("../addons/skilllog/%s.txt", os.date("%Y-%m-%d-%H-%M-%S")), "w")
		file:write(table.concat(txtTbl))
		file:flush()
		file:close()
		ui.SysMsg("Log saved")
	end
end

function SKILLLOG_STARTSTOP()
	if recording then
		recording = false
		logger[#logger + 1] = {imcTime.GetAppTime(), "Count end"}
		ui.GetFrame("skilllog"):GetChild("startBtn"):SetText("{@st41b}Start")
		SKILLLOG_UPDATE(true)
	else
		recording = true
		logger = {{imcTime.GetAppTime(), "Count start"}}
		local textbox = ui.GetFrame("skilllog"):GetChild("textbox")
		tolua.cast(textbox, "ui::CTextView")
		textbox:Clear()
		linesShown = 0
		ui.GetFrame("skilllog"):GetChild("startBtn"):SetText("{@st41b}Stop")
		SKILLLOG_UPDATE(true)
	end
	CHAT_SYSTEM("Skill recording " .. (recording and "started" or "stopped"))
end

function SKILLLOG_SHOT_START()
	local actor = GetMyActor()
	if recording and actor then
		local skill_id = actor:GetUseSkill()
		local skill_obj = GetSkill(GetMyPCObject(), GetClassByType("Skill", skill_id).ClassName)

		if skill_id ~= nil then
			logger[#logger + 1] = {imcTime.GetAppTime(), skill_obj.ClassName}
		end
	end
end

function SKILLLOG_TOGGLE_FRAME()
	ui.ToggleFrame("skilllog")
end

function SKILLLOG_UPDATE(runonce)
	if not recording and not runonce then
		return
	end

	local ctime = imcTime.GetAppTime()
	local initTime = logger[1][1]
	local casts = #logger - 1
	if not recording then
		ctime = logger[#logger][1]
		casts = casts - 1
	end

	local frame = ui.GetFrame("skilllog")
	local castcount = frame:GetChild("castcount")
	local timespent = frame:GetChild("timespent")
	local castspersec = frame:GetChild("castspersec")
	local textbox = frame:GetChild("textbox")
	tolua.cast(textbox, "ui::CTextView")

	castcount:SetText("{@st43}Cast Count: " .. casts .. "{/}")
	timespent:SetText(string.format("{@st43}Time Taken: %.2f{/}", ctime - initTime))
	castspersec:SetText(string.format("{@st43}Casts per Second: %.2f{/}", casts/(ctime - initTime)))
	local txtTbl = {}
	for t = 1, #logger - linesShown do
		txtTbl[t] = string.format("%6.2f    %s", logger[linesShown + t][1] - initTime, logger[linesShown + t][2])
	end
	textbox:AddText(table.concat(txtTbl, "{nl}"), "white_20_ol")
	textbox:Invalidate()
	linesShown = #logger
end