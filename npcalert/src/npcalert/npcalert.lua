--npcalert.lua

local loaded = false
local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
local alarm = 0
local logging = false
local tracking = false
local initObj = {}

local function NPCALERT_GET_TIME()
	local curTime = geTime.GetServerSystemTime()
	return string.format("%02d %s %04d, %02d:%02d:%02d", curTime.wDay, months[curTime.wMonth], curTime.wYear, curTime.wHour, curTime.wMinute, curTime.wSecond)
end

local function NPCALERT_SAVE_TEXT(txt)
	if txt ~= "" then
		local file = io.open("../addons/npcalert.txt", "a")
		file:write(txt .. "\n")
		file:flush()
		file:close()
	end
end

local function NPCALERT_CREATE_TRACKING_FRAME(handle)
	local frame = ui.GetFrame("npcalert_" .. handle)
	if frame == nil then
		frame = ui.CreateNewFrame("npcalertimg", "npcalert_" .. handle)
		if frame == nil then
			return
		end
	end
	frame:SetVisible(1)
	FRAME_AUTO_POS_TO_OBJ(frame, handle, -60, 60, 3, 1)
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
					initObj[actor:GetHandleVal()] = {obj.ClassID, obj.ClassName}
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
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. " Stopped logging\n")
	else
		NPCALERT_START(btn)
		logging = true
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. " Started logging")
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
	local file = io.open("../addons/npcalert.txt", "r")
	local content = file:read("*a")
	file:close()
	CHAT_SYSTEM(string.gsub(content, "\n", "{nl}"))
end

function NPCALERT_TOGGLE_FRAME()
	ui.ToggleFrame("npcalert")
end

function NPCALERT_ON_INIT(addon,frame)
	if not loaded then
		loaded = true
		local acutil = require("acutil")
		acutil.addSysIcon("npcalert", "sysmenu_mac", "NpcAlert", "NPCALERT_TOGGLE_FRAME")
	end
	addon:RegisterMsg("FPS_UPDATE", "NPCALERT_UPDATE")
	initObj = {}
	alarm = 0
	if tracking then
		frame:GetChild("tracking"):SetText("{@st41b}Stop tracking")
	end
	if logging then
		logging = false
		NPCALERT_SAVE_TEXT(NPCALERT_GET_TIME() .. " Switched map\n")
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
					initObj[handle] = {obj.ClassID, obj.ClassName}
					if alarm == 1 then
						alarm = 2
					end
					if logging then
						txtTbl[#txtTbl + 1] = string.format("%s %6s %s appeared", timeStr, obj.ClassID, obj.ClassName)
					end
					if tracking then
						NPCALERT_CREATE_TRACKING_FRAME(handle)
					end
				end
			end
		end

		for handle in pairs(removeTbl) do
			if logging then
				txtTbl[#txtTbl + 1] = string.format("%s %6s %s disappeared", timeStr, initObj[handle][1], initObj[handle][2])
			end
			initObj[handle] = nil
		end
		NPCALERT_SAVE_TEXT(table.concat(txtTbl,"\n"))
	end

	if alarm == 2 then
		imcSound.PlaySoundEvent("sys_quest_message")
	end
end