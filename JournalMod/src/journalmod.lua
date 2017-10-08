--journalmod.lua

function JOURNALMOD_ON_INIT(addon, frame)
	if ADVENTURE_BOOK_SEARCH_PROP_BY_CLASSID_FUNC_HOOKED ~= ADVENTURE_BOOK_SEARCH_PROP_BY_CLASSID_FUNC then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
			end
			_G[hookedFunctionStr] = newFunction;
		end

		setupHook(ADVENTURE_BOOK_SEARCH_PROP_BY_CLASSID_FUNC_HOOKED, "ADVENTURE_BOOK_SEARCH_PROP_BY_CLASSID_FUNC");
		setupHook(IS_QUEST_NEED_TO_SHOW_HOOKED, "IS_QUEST_NEED_TO_SHOW");
		setupHook(ADVENTURE_BOOK_QUEST_DROPLIST_INIT_HOOKED, "ADVENTURE_BOOK_QUEST_DROPLIST_INIT");
		setupHook(ADVENTURE_BOOK_CHECK_STATE_FILTER_HOOKED, "ADVENTURE_BOOK_CHECK_STATE_FILTER");
		if ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC_OLD == nil then
			ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC_OLD = ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC;
		end
		ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC = ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC_HOOKED;
		if ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_OLD == nil then
			ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_OLD = ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE;
		end
		ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE = ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_HOOKED;
	end
end

function ADVENTURE_BOOK_SEARCH_PROP_BY_CLASSID_FUNC_HOOKED(clsID, idSpace, propName, searchText)
    if searchText == nil or searchText == '' then
        return true;
    end

    local cls = GetClassByType(idSpace, clsID)
    local prop = TryGetProp(cls, propName);
    if prop == nil then
        return false;
    end
    
	prop = dictionary.ReplaceDicIDInCompStr(prop);
    prop = string.lower(prop);
    searchText = string.lower(searchText);
    
    if string.find(prop, searchText) == nil then
        return false;
    else
        return true;
    end
end

function ADVENTURE_BOOK_CRAFT_CONTENT.SEARCH_PROP_BY_TARGET_ITEM_FUNC_HOOKED(craftPair, propName, searchText)
    if searchText == nil or searchText == '' then
        return true;
    end

    local targetItemCls = GetClass("Item", craftPair['target'])

    local prop = TryGetProp(targetItemCls, propName);
    if prop == nil then
        return false;
    end
    
	prop = dictionary.ReplaceDicIDInCompStr(prop);
    prop = string.lower(prop);
    searchText = string.lower(searchText);
    
    if string.find(prop, searchText) == nil then
        return false;
    else
        return true;
    end
end

function ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_HOOKED(mapClsID)
	if ADVENTURE_BOOK_MAP_CONTENT.IS_COMPLETE(mapClsID) then
        return false;
	elseif ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_DETECTED(mapClsID) then
        return false;
    else
        return true;
    end
end

function IS_QUEST_NEED_TO_SHOW_HOOKED(frame, questCls, mapName, searchText)
    if mapName ~= nil and questCls.StartMap ~= mapName then
        return false;
    end 
    if questCls.Level == 9999 then
        return false;
    end
    if questCls.Lvup == -9999 then
        return false;
    end

    if questCls.PeriodInitialization ~= 'None' then
        return false;
    end

    local questMode = questCls.QuestMode;
    if questMode == 'KEYITEM' or questMode == 'PARTY' then
        return false;
    end

	local page_quest = GET_CHILD_RECURSIVELY(frame, 'page_quest');
	local questCateDrop = page_quest:GetChild('questCateDrop');
	tolua.cast(questCateDrop, "ui::CDropList");
    local cateIndex = questCateDrop:GetSelItemIndex();
    if cateIndex == 1 and questCls.QuestMode ~= 'MAIN' then -- main
        return false;
    elseif cateIndex == 2 and questCls.QuestMode ~= 'SUB' then -- sub
        return false;
    elseif cateIndex == 3 and (questCls.QuestMode == 'MAIN' or questCls.QuestMode == 'SUB') then -- etc
        return false;
    end

	local questLevelDrop = page_quest:GetChild('questLevelDrop');
	tolua.cast(questLevelDrop, "ui::CDropList");
    local lvIndex = questLevelDrop:GetSelItemIndex();
	if lvIndex ~= 0 and math.floor(questCls.Level / 100) + 1 ~= lvIndex then
        return false;
    end

	local questStateDrop = page_quest:GetChild('questStateDrop');
	tolua.cast(questStateDrop, "ui::CDropList");
	local stateIndex = questStateDrop:GetSelItemIndex();
	if stateIndex ~= 0 then
		local pc = GetMyPCObject();
		local result = SCR_QUEST_CHECK_C(pc, questCls.ClassName);
		if stateIndex == 1 and result ~= 'COMPLETE' then
			return false
		elseif stateIndex == 2 and result == 'COMPLETE' then
			return false
		end
	end

	local questname = dictionary.ReplaceDicIDInCompStr(questCls.Name);
	questname = string.lower(questname);
	searchText = string.lower(searchText);
	if searchText == '' or string.find(questname, searchText) ~= nil then
		return true
	end
	local mapname = questCls.StartMap;
	if mapname and mapname ~= "None" then
		mapname = GetClass("Map", mapname).Name;
		mapname = string.lower(dictionary.ReplaceDicIDInCompStr(mapname));
		if string.find(mapname, searchText) ~= nil then
			return true
		end
	end

	return false
end

function ADVENTURE_BOOK_QUEST_DROPLIST_INIT_HOOKED(page_quest)
     local questCateDrop = GET_CHILD_RECURSIVELY(page_quest, 'questCateDrop');
    if questCateDrop:GetItemCount() > 6 then
        return;
    end
    questCateDrop:ClearItems();
    questCateDrop:AddItem(0, ClMsg('PartyShowAll'));
    questCateDrop:AddItem(1, ClMsg('MAIN'));
    questCateDrop:AddItem(2, ClMsg('SUB'));
    questCateDrop:AddItem(3, ClMsg('WCL_Etc'));
    
	local levelText = GET_CHILD_RECURSIVELY(page_quest, 'levelText');
	levelText:SetMargin(194, 25, 20, 24);

    local questLevelDrop = GET_CHILD_RECURSIVELY(page_quest, 'questLevelDrop');
	questLevelDrop:SetMargin(194, 48, 178, 20);
    questLevelDrop:ClearItems();
	questLevelDrop:AddItem(0, ClMsg('Auto_MoDu_BoKi'));
	questLevelDrop:AddItem(1, 'Lv.1 ~ Lv.99');
	questLevelDrop:AddItem(2, 'Lv.100 ~ Lv.199');
	questLevelDrop:AddItem(3, 'Lv.200 ~ Lv.299');
	questLevelDrop:AddItem(4, 'Lv.300 ~ Lv.330');
	questLevelDrop:SetVisibleLine(5);

	local stateText = page_quest:CreateOrGetControl("richtext", "stateText", 378, 25, 20, 24);
	stateText:SetText("@dicID_^*$UI_20170912_002757$*^");
	stateText:SetFontName("black_16_b");

	local questStateDrop = page_quest:CreateOrGetControl("droplist", "questStateDrop", 378, 48, 178, 20);
	tolua.cast(questStateDrop, "ui::CDropList");
	questStateDrop:SetSkinName("droplist_normal");
	questStateDrop:ClearItems();
	questStateDrop:AddItem(0, ClMsg('Auto_MoDu_BoKi'), 0, 0, " ");
	questStateDrop:AddItem(1, ClMsg('Complete'), 0, 0, " ");
	questStateDrop:AddItem(2, ClMsg('NotComplete'), 0, 0, " ");
	questStateDrop:SetVisibleLine(3);
	questStateDrop:SetTextAlign("left","center");
	questStateDrop:SetSelectedScp("ADVENTURE_BOOK_QUEST_DROPLIST");
end

function ADVENTURE_BOOK_CHECK_STATE_FILTER_HOOKED(frame, collectionInfo, searchText, collectionClass, collection)    
    local collectionStateDropList = GET_CHILD_RECURSIVELY(frame, 'collectionStateDropList');
    local stateIndex = collectionStateDropList:GetSelItemIndex();
    if stateIndex == 1 and collectionInfo.view ~= 2 then -- 완성
        return false;
    elseif stateIndex == 2 and collectionInfo.view ~= 0 then -- 미확인
        return false;
    elseif stateIndex == 3 and collectionInfo.view ~= 1 then -- 미완성
        return false;
    end

    if searchText ~= nil and searchText ~= '' then
        local collectionName = ADVENTURE_BOOK_COLLECTION_REPLACE_NAME(collectionInfo.name);
        searchText = string.lower(searchText);
		collectionName = dic.getTranslatedStr(collectionName);
        collectionName = string.lower(collectionName);
		local desc = GET_COLLECTION_MAGIC_DESC(collectionClass.ClassID);
		desc = dic.getTranslatedStr(desc);
		desc = string.lower(desc);
		if string.find(collectionName, searchText) == nil and string.find(desc, searchText) == nil then
			local collectionList = session.GetMySession():GetCollection();
			local curCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collectionList:Get(collectionClass.ClassID));
			for num = 1, maxCount do
				local itemName = TryGetProp(collectionClass, "ItemName_" .. num);
				if itemName == nil or itemName == "None" then
					return false;
				end
				itemName = dictionary.ReplaceDicIDInCompStr(GetClass("Item", itemName).Name);
				itemName = string.lower(itemName);
				if string.find(itemName, searchText) ~= nil then
					return true;
				end
			end
            return false;
        end
    end

    return true;
end