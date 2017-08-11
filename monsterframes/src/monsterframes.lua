--monsterframes.lua

local loaded = false;
local settings = {
	showRaceType = false;
	showAttribute = true;
	showArmorMaterial = true;
	showMoveType = true;
	showEffectiveAtkType = false;
	showTargetSize = true;
	showMaxHp = true;
	showKillCount = true;
};

function MONSTERFRAMES_ON_INIT(addon, frame)
	if not loaded then
		local acutil = require('acutil');
		acutil.setupHook(TGTINFO_TARGET_SET_HOOKED, "TGTINFO_TARGET_SET");
		acutil.setupHook(TARGETINFO_ON_MSG_HOOKED, "TARGETINFO_ON_MSG");
		acutil.setupHook(TARGETINFOTOBOSS_TARGET_SET_HOOKED, "TARGETINFOTOBOSS_TARGET_SET");
		acutil.setupHook(TARGETINFOTOBOSS_ON_MSG_HOOKED, "TARGETINFOTOBOSS_ON_MSG");
		local t, err = acutil.loadJSON("../addons/monsterframes/settings.json");
		if err then
			acutil.saveJSON("../addons/monsterframes/settings.json", settings);
		else
			settings = t;
		end
		loaded = true;
	end
end

local function SHOW_PROPERTY_WINDOW(frame, monCls, targetInfoProperty, monsterPropertyIcon, x, y, spacingX, spacingY)
	local propertyType = frame:CreateOrGetControl("picture", monsterPropertyIcon .. "_icon", 0, 0, 100, 40);
	tolua.cast(propertyType, "ui::CPicture");
	if (targetInfoProperty == nil and monsterPropertyIcon == "EffectiveAtkType") or (targetInfoProperty ~= nil) then
		propertyType:SetGravity(ui.LEFT, ui.TOP);
		propertyType:SetImage(GET_MON_PROPICON_BY_PROPNAME(monsterPropertyIcon, monCls));
		propertyType:SetOffset((x + spacingX), (y - spacingY));
		propertyType:ShowWindow(1);
	else
		propertyType:ShowWindow(0);
	end
end

function TGTINFO_TARGET_SET_HOOKED(frame, msg, argStr, argNum)
	if argStr == "None" then
		return;
	end
	
	local mypclevel = GETMYPCLEVEL();
	local levelcolor = ""
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

    -- birth buff
    local birth_buff_skin, birth_buff_img = TARGETINFO_GET_BIRTH_SKIN_ANG_IMG(frame, targetinfo, targetHandle);
	local birthBuffImgName = GET_BIRTH_BUFF_IMG_NAME(targetHandle);
	if birthBuffImgName == "None" then
		birth_buff_skin:ShowWindow(0)
		birth_buff_img:ShowWindow(0)
	else
		birth_buff_skin:ShowWindow(1)
		birth_buff_img:ShowWindow(1)
		birth_buff_img:SetImage(birthBuffImgName)
	end

	if mypclevel + 10 < targetinfo.level then
		levelcolor = frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_10");
	elseif mypclevel + 5 < targetinfo.level then
		levelcolor = frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_5");
	end
	
    -- gauge    
	local hpGauge = TARGETINFO_GET_HP_GAUGE(frame, targetinfo, targetHandle);
	frame:SetValue(session.GetTargetHandle());

	local stat = targetinfo.stat;

	if stat.HP ~= hpGauge:GetCurPoint() or stat.maxHP ~= hpGauge:GetMaxPoint() then    
		hpGauge:SetPoint(stat.HP, stat.maxHP);
		hpGauge:StopTimeProcess();
	else
		hpGauge:SetMaxPointWithTime(stat.HP, stat.maxHP, 0.2, 0.4);
	end

	if targetinfo.isInvincible ~= hpGauge:GetValue() then
		hpGauge:SetValue(targetinfo.isInvincible);
		if targetinfo.isInvincible == 1 then
			hpGauge:SetColorTone("FF111111");
		else
			hpGauge:SetColorTone("FFFFFFFF");
		end
	end
    local hpText = frame:GetChild('hpText');

	-- Edits made here
	if settings.showMaxHp then
		hpText:SetText(GetCommaedText(stat.HP) .. "/" .. GetCommaedText(stat.maxHP));
	else
		hpText:SetText(GET_COMMAED_STRING(stat.HP));
	end

    -- name	
	local targetSize = targetinfo.size;
	local eliteBuffMob = "";
	if targetSize ~= nil then		
		if targetinfo.isEliteBuff == 1 then
			eliteBuffMob = ClMsg("TargetNameElite") .. " ";
		end		
	end
    local nametext = GET_CHILD_RECURSIVELY(frame, "name", "ui::CRichText");
	local mypclevel = GETMYPCLEVEL();
    local levelColor = "";
    if mypclevel + 10 < targetinfo.level then
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_10"));
	elseif mypclevel + 5 < targetinfo.level then
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_5"));
    else
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_DEFAULT"));
	end
    nametext:SetTextByKey('lv', targetinfo.level);
    nametext:SetTextByKey('name', eliteBuffMob..targetinfo.name);
		
	-- race
    local monsterRaceSet = TARGETINFO_GET_RACE_CONTROL(frame, targetinfo, targetHandle);
    local racePic = monsterRaceSet:GetChild('racePic');
    local raceImg = TARGETINFO_GET_RACE_TYPE_IMAGE(monsterRaceSet, targetinfo.raceType);
    racePic = tolua.cast(racePic, 'ui::CPicture');
    racePic:SetImage(raceImg);	

	if ui.IsFrameVisible("targetinfotoboss") == 1 then
		frame:MoveFrame(TARGET_INFO_OFFSET_BOSS_X, TARGET_INFO_OFFSET_Y);
	else
		frame:MoveFrame(TARGET_INFO_OFFSET_X, TARGET_INFO_OFFSET_Y);
	end
	frame:ShowWindow(1);
	frame:Invalidate();	


	-- Edited monsterframes code here
	local monactor = world.GetActor(session.GetTargetHandle());
	local montype = monactor:GetType();
	local monCls = GetClassByType("Monster", montype);

	if monCls == nil then
		return;
	end

	local xPosition = 285;
	local yPosition = 17;
	local killxPosition = 180;
	local propertyWidth = 35;
	local positionIndex = 0;

	if targetinfo.isElite == 1 then
		xPosition = 195;
		yPosition = 13;
		killxPosition = 55;
	end

	if settings.showRaceType then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.raceType, "RaceType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showAttribute then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.attribute, "Attribute", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showArmorMaterial then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.armorType, "ArmorMaterial", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showMoveType then
		SHOW_PROPERTY_WINDOW(frame, monCls, monCls["MoveType"], "MoveType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showEffectiveAtkType then
		SHOW_PROPERTY_WINDOW(frame, monCls, nil, "EffectiveAtkType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end

	if settings.showTargetSize then
		local targetSizeText = frame:CreateOrGetControl("richtext", "targetSizeText", 0, 0, 100, 40);
		tolua.cast(targetSizeText, "ui::CRichText");
		if targetinfo.size ~= nil then
			targetSizeText:SetOffset(xPosition + (positionIndex * propertyWidth) + 10, yPosition - 8);
			targetSizeText:SetText("{@st41}{s28}" .. targetinfo.size);
			targetSizeText:ShowWindow(1);
			positionIndex = positionIndex + 1;
		else
			targetSizeText:ShowWindow(0);
		end
	end

	if settings.showKillCount then
		local wiki = GetWikiByName(monCls.Journal);

		if wiki ~= nil then
			local killCount = GetWikiIntProp(wiki, "KillCount");
			local jIES = GetClass('Journal_monkill_reward', monCls.Journal);

			local killCountText = frame:CreateOrGetControl("richtext", "killCountText", 0, 0, 100, 40);
			tolua.cast(killCountText, "ui::CRichText");
			if targetinfo.size ~= nil and jIES ~= nil then
				killCountText:SetOffset(killxPosition, 0);
				killCountText:SetFontName("white_16_ol");
				killCountText:SetText(GetCommaedText(killCount) .. " / " .. GetCommaedText(jIES.Count1));
				killCountText:ShowWindow(1);
			else
				killCountText:ShowWindow(0);
			end
		end
	end
end

function TARGETINFO_ON_MSG_HOOKED(frame, msg, argStr, argNum)

	if msg == 'TARGET_CLEAR' then
		frame:ShowWindow(0);
	end

	if msg == 'TARGET_UPDATE' then
		local stat = info.GetStat(session.GetTargetHandle());
		if stat == nil then
			return;
		end

        local targetHandle = session.GetTargetHandle();
		local targetinfo = info.GetTargetInfo(targetHandle);
		local hpGauge = TARGETINFO_GET_HP_GAUGE(frame, targetinfo, targetHandle);
		local beforeHP = hpGauge:GetCurPoint();
		if beforeHP > stat.HP then
			local damRate = (beforeHP - stat.HP) / stat.maxHP;
			if damRate >= 0.5 then
				UI_PLAYFORCE(frame, "gauge_damage");
			end
		end
		hpGauge:SetMaxPointWithTime(stat.HP, stat.maxHP, 0.2, 0.4);
        local hpText = frame:GetChild('hpText');

		--Edits made here
		if settings.showMaxHp then
			hpText:SetText(GetCommaedText(stat.HP) .. "/" .. GetCommaedText(stat.maxHP));
		else
			hpText:SetText(GET_COMMAED_STRING(stat.HP));
		end
		frame:Invalidate();
	 end
end

function TARGETINFOTOBOSS_TARGET_SET_HOOKED(frame, msg, argStr, argNum)
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

	local birth_buff_skin = GET_CHILD_RECURSIVELY(frame, "birth_buff_skin");
	local birth_buff_img = GET_CHILD_RECURSIVELY(frame, "birth_buff_img");

	local birthBuffImgName = GET_BIRTH_BUFF_IMG_NAME(session.GetTargetBossHandle());
	if birthBuffImgName == "None" then
		birth_buff_skin:ShowWindow(0)
		birth_buff_img:ShowWindow(0)
	else
		birth_buff_skin:ShowWindow(1)
		birth_buff_img:ShowWindow(1)
		birth_buff_img:SetImage(birthBuffImgName)
	end

	-- name
	local nametext = GET_CHILD_RECURSIVELY(frame, "name", "ui::CRichText");
	local mypclevel = GETMYPCLEVEL();
    local levelColor = "";
    if mypclevel + 10 < targetinfo.level then
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_10"));
	elseif mypclevel + 5 < targetinfo.level then
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_MORE_THAN_5"));
    else
        nametext:SetTextByKey('color', frame:GetUserConfig("MON_NAME_COLOR_DEFAULT"));
	end
    nametext:SetTextByKey('lv', targetinfo.level);
    nametext:SetTextByKey('name', targetinfo.name);
	
	-- race
	local raceTypeSet = GET_CHILD(frame, "race");    
    local image = raceTypeSet:GetChild('racePic');    
    local imageStr = TARGETINFO_GET_RACE_TYPE_IMAGE(raceTypeSet, targetinfo.raceType);
    image = tolua.cast(image, 'ui::CPicture');    
    image:SetImage(imageStr);

	-- hp
	local stat = targetinfo.stat;
	local hpGauge = GET_CHILD(frame, "hp", "ui::CGauge");
    local hpText = frame:GetChild('hpText');
	hpGauge:SetPoint(stat.HP, stat.maxHP);

	-- Edits made here
	if settings.showMaxHp then
		hpText:SetText(GetCommaedText(stat.HP) .. "/" .. GetCommaedText(stat.maxHP));
	else
		hpText:SetText(GET_COMMAED_STRING(stat.HP));
	end

	if targetinfo.isInvincible ~= hpGauge:GetValue() then
		hpGauge:SetValue(targetinfo.isInvincible);
		if targetinfo.isInvincible == 1 then
			hpGauge:SetColorTone("FF111111");
		else
			hpGauge:SetColorTone("FFFFFFFF");
		end
	end

	frame:ShowWindow(1);
	frame:Invalidate();
	frame:SetValue(argNum);	-- argNum 가 핸들임


	-- Edited monsterframes code here
	local monactor = world.GetActor(session.GetTargetBossHandle());
	local montype = monactor:GetType();
	local monCls = GetClassByType("Monster", montype);

	if monCls == nil then
		return;
	end

	local xPosition = 100;
	local yPosition = 25;
	local propertyWidth = 35;
	local positionIndex = 0;

	if settings.showRaceType then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.raceType, "RaceType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showAttribute then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.attribute, "Attribute", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showArmorMaterial then
		SHOW_PROPERTY_WINDOW(frame, monCls, targetinfo.armorType, "ArmorMaterial", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showMoveType then
		SHOW_PROPERTY_WINDOW(frame, monCls, monCls["MoveType"], "MoveType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end
	if settings.showEffectiveAtkType then
		SHOW_PROPERTY_WINDOW(frame, monCls, nil, "EffectiveAtkType", xPosition + (positionIndex * propertyWidth), yPosition, 10, 10);
		positionIndex = positionIndex + 1;
	end

	if settings.showTargetSize then
		local targetSizeText = frame:CreateOrGetControl("richtext", "targetSizeText", 0, 0, 100, 40);
		tolua.cast(targetSizeText, "ui::CRichText");
		if targetinfo.size ~= nil then
			targetSizeText:SetOffset(xPosition + (positionIndex * propertyWidth) + 10, yPosition - 8);
			targetSizeText:SetText("{@st41}{s28}" .. targetinfo.size);
			targetSizeText:ShowWindow(1);
			positionIndex = positionIndex + 1;
		else
			targetSizeText:ShowWindow(0);
		end
	end
end

function TARGETINFOTOBOSS_ON_MSG_HOOKED(frame, msg, argStr, argNum)

	if msg == 'TARGET_CLEAR_BOSS' then
		session.ResetTargetBossHandle();
		frame:SetVisible(0); -- visible값이 1이면 다른 몬스터 hp gauge offset이 옆으로 밀림.(targetinfo.lua 참조)
		frame:ShowWindow(0);
	end
	
	if msg == 'TARGET_UPDATE' or msg == 'TARGET_BUFF_UPDATE' then
		local target = session.GetTargetBossHandle();
		if target ~= 0 then
			if session.IsBoss( target ) == true then				
				TARGETINFOTOBOSS_TARGET_SET(frame, 'TARGET_SET_BOSS', "Enemy", target)
			end
		end
		
		local stat = info.GetStat(session.GetTargetBossHandle());	
		if stat ~= nil then
			local hpGauge = GET_CHILD(frame, "hp", "ui::CGauge");
			hpGauge:SetPoint(stat.HP, stat.maxHP);

            local hpText = frame:GetChild('hpText');

			-- Edits made here
			if settings.showMaxHp then
				hpText:SetText(GetCommaedText(stat.HP) .. "/" .. GetCommaedText(stat.maxHP));
			else
				hpText:SetText(GET_COMMAED_STRING(stat.HP));
			end

			if frame:IsVisible() == 0 then
				frame:ShowWindow(1)
			end
			frame:Invalidate();
		end
	end
end