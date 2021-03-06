--monsterframes.lua

local hooks = {}

local settings = {
	showRaceType = false,
	showAttribute = false,
	showArmorMaterial = true,
	showMoveType = true,
	showEffectiveAtkType = false,
	showTargetSize = true,
	showMaxHp = true,
	showHpPercent = true,
	showKillCount = true}

local posTable = {
	normal  = {x = 303, y = 17, killx = 180, killy = 0, width = 35},
	elite   = {x = 200, y = 13, killx =  55, killy = 0, width = 35},
	special = {x = 260, y = 17, killx = 180, killy = 0, width = 35},
	boss    = {x = 100, y = 25, killx =  35, killy = 5, width = 35}}

function MONSTERFRAMES_ON_INIT(addon, frame)
	if next(hooks) == nil then
		local function setupHook(newFunc, oldFuncStr)
			hooks[oldFuncStr] = _G[oldFuncStr]
			_G[oldFuncStr] = newFunc
		end

		setupHook(TGTINFO_TARGET_SET_HOOKED, "TGTINFO_TARGET_SET")
		setupHook(TARGETINFOTOBOSS_TARGET_SET_HOOKED, "TARGETINFOTOBOSS_TARGET_SET")
		setupHook(TARGETINFO_TRANS_HP_VALUE_HOOKED, "TARGETINFO_TRANS_HP_VALUE")

		local acutil = require('acutil')
		local t, err = acutil.loadJSON("../addons/monsterframes/settings.json")
		if err then
			acutil.saveJSON("../addons/monsterframes/settings.json", settings)
		else
			settings = t
		end
	end
end

local function SHOW_PROPERTY_PIC(frame, monCls, targetInfoProperty, monsterPropertyIcon, x, y, spacingX, spacingY)
	local propertyType = frame:CreateOrGetControl("picture", monsterPropertyIcon .. "_icon", x + spacingX, y - spacingY, 100, 40)
	tolua.cast(propertyType, "ui::CPicture")
	if targetInfoProperty ~= nil then
		propertyType:SetImage(GET_MON_PROPICON_BY_PROPNAME(monsterPropertyIcon, monCls))
		propertyType:ShowWindow(1)
		return 1
	else
		propertyType:ShowWindow(0)
		return 0
	end
end

local function SHOW_PROPERTY_TEXT(frame, propertyName, text, x, y, check)
	local propertyType = frame:CreateOrGetControl("richtext", propertyName .. "Text", x, y, 100, 40)
	tolua.cast(propertyType, "ui::CRichText")
	if check then
		propertyType:SetText(text)
		propertyType:ShowWindow(1)
		return 1
	else
		propertyType:ShowWindow(0)
		return 0
	end
end

local function SHOW_CUSTOM_ICONS(frame, targetHandle, targetinfo)
	local montype = world.GetActor(targetHandle):GetType()
	local monCls = GetClassByType("Monster", montype)

	if monCls == nil then
		return
	end

	local pos = posTable.normal
	if targetinfo.isBoss == 1 then
		pos = posTable.boss
	elseif targetinfo.isElite == 1 then
		pos = posTable.elite
	elseif info.GetMonRankbyHandle(targetHandle) == 'Special' then
		pos = posTable.special
	end

	local positionIndex = 0
	if settings.showRaceType then
		positionIndex = positionIndex + SHOW_PROPERTY_PIC(frame, monCls, targetinfo.raceType, "RaceType", pos.x + (positionIndex * pos.width), pos.y, 10, 10)
	end
	if settings.showAttribute then
		positionIndex = positionIndex + SHOW_PROPERTY_PIC(frame, monCls, targetinfo.attribute, "Attribute", pos.x + (positionIndex * pos.width), pos.y, 10, 10)
	end
	if settings.showArmorMaterial then
		positionIndex = positionIndex + SHOW_PROPERTY_PIC(frame, monCls, targetinfo.armorType, "ArmorMaterial", pos.x + (positionIndex * pos.width), pos.y, 10, 10)
	end
	if settings.showMoveType then
		positionIndex = positionIndex + SHOW_PROPERTY_PIC(frame, monCls, monCls["MoveType"], "MoveType", pos.x + (positionIndex * pos.width), pos.y, 10, 10)
	end
	if settings.showEffectiveAtkType then
		positionIndex = positionIndex + SHOW_PROPERTY_PIC(frame, monCls, 1, "EffectiveAtkType", pos.x + (positionIndex * pos.width), pos.y, 10, 10)
	end

	if settings.showTargetSize then
		positionIndex = positionIndex + SHOW_PROPERTY_TEXT(frame, "TargetSize", "{@st41}{s28}" .. targetinfo.size, pos.x + (positionIndex * pos.width) + 10, pos.y - 8, targetinfo.size ~= nil)
	end

	if settings.showKillCount then
		local curLv, curPoint, curMaxPoint = GET_ADVENTURE_BOOK_MONSTER_KILL_COUNT_INFO(monCls.MonRank == 'Boss', GetMonKillCount(pc, montype))
		SHOW_PROPERTY_TEXT(frame, "KillCount", string.format("{@st42}{s16}%d: %d/%d", curLv, curPoint, curMaxPoint), pos.killx, pos.killy, curMaxPoint ~= 0)
	end

	frame:Invalidate()
end

function TGTINFO_TARGET_SET_HOOKED(frame, msg, argStr, argNum, ...)
    if argStr == "None" then
        return;
    end

    if IS_IN_EVENT_MAP() == true then
        return;
    end

    local targetHandle = session.GetTargetHandle();
    local targetinfo = info.GetTargetInfo( targetHandle );
    if nil == targetinfo then
        return;
    end
    if targetinfo.TargetWindow == 0 then
        return;
    end
    if targetinfo.isBoss == 1 then
        return;
    end

	local ret = {hooks.TGTINFO_TARGET_SET(frame, msg, argStr, argNum, ...)}
	SHOW_CUSTOM_ICONS(frame, targetHandle, targetinfo)
	return unpack(ret)
end

function TARGETINFOTOBOSS_TARGET_SET_HOOKED(frame, msg, argStr, argNum, ...)
    if argStr == "None" or argNum == nil then
        return;
    end
    
    local targetinfo = info.GetTargetInfo(argNum);
    if targetinfo == nil then
        session.ResetTargetBossHandle();
        frame:ShowWindow(0);
        return;
    end
    
    if 0 == targetinfo.TargetWindow or targetinfo.isBoss == 0 then
        session.ResetTargetBossHandle();
        frame:ShowWindow(0);
        return;
    end

	local ret = {hooks.TARGETINFOTOBOSS_TARGET_SET(frame, msg, argStr, argNum, ...)}
	SHOW_CUSTOM_ICONS(frame, argNum, targetinfo)
	return unpack(ret)
end

function TARGETINFO_TRANS_HP_VALUE_HOOKED(handle, hp, fontStyle, ...)
	local ret = hooks.TARGETINFO_TRANS_HP_VALUE(handle, hp, fontStyle, ...)
	if info.IsPercentageHP(handle) ~= true then
		local stat = info.GetTargetInfo(handle).stat
		if settings.showMaxHp then
			ret = ret .. "/" .. tostring(math.floor(stat.maxHP)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
		end
		if settings.showHpPercent then
			ret = ret .. "(" .. (math.floor(stat.HP/stat.maxHP*100)) .. "%)"
		end
	end
	return ret
end