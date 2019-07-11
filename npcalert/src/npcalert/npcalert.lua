--npcalert.lua

local acutil = require("acutil")
local loaded = false
local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
local alarm = 0
local logging = false
local tracking = false
local initObj = {}
local mapname = ""
local settings = {showName = true, showClassName = true, showClassID = true}

local function NPCALERT_GET_TIME()
	local curTime = geTime.GetServerSystemTime()
	return string.format("%02d %s %04d\t%02d:%02d:%02d", curTime.wDay, months[curTime.wMonth], curTime.wYear, curTime.wHour, curTime.wMinute, curTime.wSecond)
end

local function NPCALERT_SAVE_TEXT(txt)
	if txt ~= "" then
		local file = io.open("../addons/npcalert/logs.txt", "a")
		file:write(txt .. "\n")
		file:flush()
		file:close()
	end
end

local function NPC_ALERT_CREATE_TEXTBOX(frame, idx, maxX, height, show, text)
	if show then
		local textbox = frame:CreateOrGetControl("richtext", "textbox" .. idx, 0, height, 220, 40)
		textbox:SetGravity(ui.CENTER_HORZ, ui.TOP)
		textbox:SetText("{s16}{#B81313}{ol}" .. text)
		idx = idx + 1
		maxX = math.max(maxX, textbox:GetWidth())
		height = height + textbox:GetHeight()
	end
	return idx, maxX, height
end

local function NPCALERT_CREATE_TRACKING_FRAME(handle)
	local frame = ui.GetFrame("npcalert_" .. handle)
	if frame == nil then
		frame = ui.CreateNewFrame("npcalertimg", "npcalert_" .. handle)
		if frame == nil then
			return
		end
	end
	local idx, maxX, height = 1, 120, 120
	idx, maxX, height = NPC_ALERT_CREATE_TEXTBOX(frame, idx, maxX, height, settings.showName, initObj[handle][3])
	idx, maxX, height = NPC_ALERT_CREATE_TEXTBOX(frame, idx, maxX, height, settings.showClassName, initObj[handle][2])
	idx, maxX, height = NPC_ALERT_CREATE_TEXTBOX(frame, idx, maxX, height, settings.showClassID, initObj[handle][1])
	frame:Resize(maxX, height)
	FRAME_AUTO_POS_TO_OBJ(frame, handle, -maxX / 2, -60, 3, 1)
	frame:SetVisible(1)
end

local function NPCALERT_START(btn)
	btn:SetText("{@st41b}Stop " .. btn:GetName())
	if alarm == 0 and logging == false and tracking == false then
		initObj = {}
		local objList, objCount = SelectBaseObject(GetMyPCObject(), 500, "ALL", 1)
		for i = 1, objCount do
			local actor = tolua.cast(objList[i], "CFSMActor")
			local faction = actor:GetFactionStr()
			if faction ~= "Monster" and actor:GetObjType() ~= GT_ITEM and faction ~= "Pet" and faction ~= "Summon" and faction ~= "RootCrystal" then
				local obj = GetBaseObjectIES(objList[i])
				if obj.ClassName ~= "PC" then
					initObj[actor:GetHandleVal()] = {obj.ClassID, obj.ClassName, obj.Name}
				end
			end
		end
	end
end

local function NPCALERT_STOP(btn)
	btn:SetText("{@st41b}Start " .. btn:GetName())
	if alarm == 0 and logging == false and tracking == false then
		initObj = {}
	end
end

function NPCALERT_ALARM_TOGGLE(ctrl, btn, argStr, argNum)
	if alarm == 0 then
		NPCALERT_START(btn)
		alarm = 1
	else
		alarm = 0
		NPCALERT_STOP(btn)
	end
end

function NPCALERT_LOG_TOGGLE(ctrl, btn, argStr, argNum)
	if logging then
		logging = false
		NPCALERT_STOP(btn)
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. "\tStopped logging\n")
	else
		NPCALERT_START(btn)
		logging = true
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. "\tStarted logging")
	end
end

function NPCALERT_TRACK_TOGGLE(ctrl, btn, argStr, argNum)
	if tracking then
		tracking = false
		for handle in pairs(initObj) do
			local frame = ui.GetFrame("npcalert_" .. handle)
			if frame ~= nil then
				frame:SetVisible(0)
			end
		end
		NPCALERT_STOP(btn)
	else
		NPCALERT_START(btn)
		tracking = true
		for handle in pairs(initObj) do
			NPCALERT_CREATE_TRACKING_FRAME(handle)
		end
	end
end

function NPCALERT_READ_BTN()
	local file = io.open("../addons/npcalert/logs.txt", "r")
	local data = file:read("*a")
	file:close()
	CHAT_SYSTEM(data:gsub("\n", "{nl}"):gsub("\t", " "))
end

function NPCALERT_CHAT_MAP(cmds)
	local map = table.remove(cmds, 1)
	local x = table.remove(cmds, 1)
	local z = table.remove(cmds, 1)
	local str = MAKE_LINK_MAP_TEXT(map, x, z)
	if #cmds == 0 then
		CHAT_SYSTEM(str)
	else
		if cmds[1] == "/s" then
			table.remove(cmds, 1)
		end
		cmds[#cmds+1] = str
		ui.Chat(table.concat(cmds, " "))
	end
end

function NPCALERT_TOGGLE_FRAME()
	ui.ToggleFrame("npcalert")
end

function NPCALERT_ON_INIT(addon,frame)
	if not loaded then
		loaded = true
		acutil.addSysIcon("npcalert", "sysmenu_mac", "NpcAlert", "NPCALERT_TOGGLE_FRAME")
		local t, err = acutil.loadJSON("../addons/npcalert/settings.json")
		if err then
			acutil.saveJSON("../addons/npcalert/settings.json", settings)
		else
			settings = t
		end
	end
	initObj = {}
	alarm = 0
	mapname = session.GetMapName()
	acutil.slashCommand("/npcalert", NPCALERT_CHAT_MAP)
	addon:RegisterMsg("FPS_UPDATE", "NPCALERT_UPDATE")
	if tracking then
		frame:GetChild("tracking"):SetText("{@st41b}Stop tracking")
	end
	if logging then
		logging = false
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. "\tSwitched map\n")
	end
end

function NPCALERT_UPDATE()
	if alarm == 1 or logging or tracking then
		local timeStr = NPCALERT_GET_TIME()
		local removeTbl = {}
		local txtTbl = {}

		for handle in pairs(initObj) do
			removeTbl[handle] = 1
		end

		local objList, objCount = SelectBaseObject(GetMyPCObject(), 500, "ALL", 1)
		for i = 1, objCount do
			local actor = tolua.cast(objList[i], "CFSMActor")
			local handle = actor:GetHandleVal()
			local faction = actor:GetFactionStr()
			if removeTbl[handle] ~= nil then
				removeTbl[handle] = nil
			elseif faction ~= "Monster" and actor:GetObjType() ~= GT_ITEM and faction ~= "Pet" and faction ~= "Summon" and faction ~= "RootCrystal" then
				local obj = GetBaseObjectIES(objList[i])
				if obj.ClassName ~= "PC" then
					initObj[handle] = {obj.ClassID, obj.ClassName, obj.Name}
					if alarm == 1 then
						alarm = 2
					end
					if logging then
						local pos = actor:GetPos()
						txtTbl[#txtTbl + 1] = string.format("%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d", timeStr, 'Appeared', obj.ClassID, obj.ClassName, mapname, pos.x, pos.y, pos.z)
					end
					if tracking then
						NPCALERT_CREATE_TRACKING_FRAME(handle)
					end
				end
			end
		end

		for handle in pairs(removeTbl) do
			if logging then
				txtTbl[#txtTbl + 1] = string.format("%s\t%s\t%s\t%s\t%s", timeStr, 'Disappeared', initObj[handle][1], initObj[handle][2], mapname)
			end
			initObj[handle] = nil
		end
		NPCALERT_SAVE_TEXT(table.concat(txtTbl,"\n"))
	end

	if alarm == 2 then
		imcSound.PlaySoundEvent("sys_quest_message")
	end
end