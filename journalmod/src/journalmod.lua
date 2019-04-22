--journalmod.lua

local loaded = false

function JOURNALMOD_ON_INIT(addon, frame)
	if not loaded then
		loaded = true
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD"
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr]
			end
			_G[hookedFunctionStr] = newFunction
		end

		setupHook(ADVENTURE_BOOK_CHECK_STATE_FILTER_HOOKED, "ADVENTURE_BOOK_CHECK_STATE_FILTER")
		setupHook(SCR_QUEST_SHOW_ZONE_LIST_HOOKED, "SCR_QUEST_SHOW_ZONE_LIST")
		setupHook(ADVENTURE_BOOK_QUEST_CREATE_MAP_QUEST_TREE_HOOKED, "ADVENTURE_BOOK_QUEST_CREATE_MAP_QUEST_TREE")
		setupHook(IS_QUEST_NEED_TO_SHOW_HOOKED, "IS_QUEST_NEED_TO_SHOW")
		setupHook(ADVENTURE_BOOK_QUEST_DROPLIST_INIT_HOOKED, "ADVENTURE_BOOK_QUEST_DROPLIST_INIT")
		if ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_OLD == nil then
			ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_OLD = ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE
		end
		ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE = ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_HOOKED
	end
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
        collectionName = dic.getTranslatedStr(collectionName)
        collectionName = string.lower(collectionName);
		local desc = GET_COLLECTION_MAGIC_DESC(collectionClass.ClassID)
		desc = string.lower(dic.getTranslatedStr(desc))
		if string.find(collectionName, searchText) == nil and string.find(desc, searchText) == nil then
			local collectionList = session.GetMySession():GetCollection()
			local curCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collectionList:Get(collectionClass.ClassID))
			for num = 1, maxCount do
				local itemName = TryGetProp(collectionClass, "ItemName_" .. num)
				if itemName == nil or itemName == "None" then
					return false
				end
				itemName = dic.getTranslatedStr(GetClass("Item", itemName).Name)
				itemName = string.lower(itemName)
				if string.find(itemName, searchText) ~= nil then
					return true
				end
			end
            return false;
        end
    end

    return true;
end

function ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_COMPLETE_HOOKED(mapClsID)
	local t = ADVENTURE_BOOK_MAP_CONTENT.IS_COMPLETE(mapClsID)
	if t == true or t == 1 then
        return false;
	end
	t = ADVENTURE_BOOK_MAP_CONTENT.IS_NOT_DETECTED(mapClsID)
	if t == true or t == 1 then
        return false;
    else
        return true;
    end
end

function SCR_QUEST_SHOW_ZONE_LIST_HOOKED(nowframe)
    local questList, cnt = GetClassList('QuestProgressCheck');
    local topFrame = nowframe:GetTopParentFrame();
    local questSearchEdit = GET_CHILD_RECURSIVELY(topFrame, 'questSearchEdit');
    local searchText = questSearchEdit:GetText();
    local zoneList = {}
	searchText = string.lower(searchText)
	local pc = GetMyPCObject()
	local questCateDrop = GET_CHILD_RECURSIVELY(topFrame, 'questCateDrop')
	local questLevelDrop = GET_CHILD_RECURSIVELY(topFrame, 'questLevelDrop')
	local questStateDrop = GET_CHILD_RECURSIVELY(topFrame, 'questStateDrop')
	local cateIndex = questCateDrop:GetSelItemIndex()
	local lvIndex = questLevelDrop:GetSelItemIndex()
	local stateIndex = (questStateDrop ~= nil) and questStateDrop:GetSelItemIndex() or 0
    
    for index = 0, cnt - 1 do
        local questCls = GetClassByIndexFromList(questList, index);
        if table.find(zoneList, questCls.StartMap) == 0 then
            if questCls.Level ~= 9999 then
                if questCls.Lvup ~= -9999 then
                    if questCls.PeriodInitialization == 'None' then
                        local questMode = questCls.QuestMode;
                        if questMode ~= 'KEYITEM' and questMode ~= 'PARTY' then
                            --local questCateDrop = GET_CHILD_RECURSIVELY(topFrame, 'questCateDrop');
                            --local cateIndex = questCateDrop:GetSelItemIndex();
                            if cateIndex == 0 or (cateIndex == 1 and questCls.QuestMode == 'MAIN') or (cateIndex == 2 and questCls.QuestMode == 'SUB') or (cateIndex == 3 and questCls.QuestMode ~= 'MAIN' and questCls.QuestMode ~= 'SUB') then
                                --local questLevelDrop = GET_CHILD_RECURSIVELY(topFrame, 'questLevelDrop');
                                --local lvIndex = questLevelDrop:GetSelItemIndex();    
								if lvIndex == 0 or math.ceil(questCls.Level / 100) == lvIndex then
									if searchText == '' or string.find(string.lower(dic.getTranslatedStr(questCls.Name)), searchText) ~= nil then
										local result = SCR_QUEST_CHECK_C(pc, questCls.ClassName)
										if stateIndex == 0 or (stateIndex == 1 and result == 'COMPLETE') or (stateIndex == 2 and result ~= 'COMPLETE') then
                                            zoneList[#zoneList + 1] = questCls.StartMap
										end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return zoneList
end

function ADVENTURE_BOOK_QUEST_CREATE_MAP_QUEST_TREE_HOOKED(questMapBox, mapCls, isSearchMode)
    local quest_tree = questMapBox:CreateOrGetControlSet('quest_tree', 'QUEST_MAP_'..mapCls.ClassID, 0, 0);      
    local text = quest_tree:GetChild('text');
    text:SetText(mapCls.Name);
    if isSearchMode == true then
        quest_tree = AUTO_CAST(quest_tree);
        local EXPAND_ON_IMG = quest_tree:GetUserConfig('EXPAND_ON_IMG');
        local expandBtn = GET_CHILD(quest_tree, 'expandBtn');
        expandBtn:SetImage(EXPAND_ON_IMG);
		quest_tree:SetUserValue('QUEST_MAP_CLASS_NAME', mapCls.ClassName)
		quest_tree:SetUserValue('IS_EXPAND', 1)
    else
        quest_tree:SetUserValue('QUEST_MAP_CLASS_NAME', mapCls.ClassName);
    end
    return quest_tree;
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
    
    if IS_ADVENTURE_BOOK_EXCEPT_QUEST(questCls.ClassName) == 'YES' then
        return false;
    end

    local questCateDrop = GET_CHILD_RECURSIVELY(frame, 'questCateDrop');
    local cateIndex = questCateDrop:GetSelItemIndex();
    if cateIndex == 1 and questCls.QuestMode ~= 'MAIN' then -- main
        return false;
    elseif cateIndex == 2 and questCls.QuestMode ~= 'SUB' then -- sub
        return false;
    elseif cateIndex == 3 and (questCls.QuestMode == 'MAIN' or questCls.QuestMode == 'SUB') then -- etc
        return false;
    end

    local questLevelDrop = GET_CHILD_RECURSIVELY(frame, 'questLevelDrop');
    local lvIndex = questLevelDrop:GetSelItemIndex();    
	if lvIndex ~= 0 and math.ceil(questCls.Level / 100) ~= lvIndex then
        return false;
    end

	local questStateDrop = GET_CHILD_RECURSIVELY(frame, 'questStateDrop')
	local stateIndex = questStateDrop:GetSelItemIndex()
	local result = SCR_QUEST_CHECK_C(GetMyPCObject(), questCls.ClassName)
	if stateIndex == 1 and result ~= 'COMPLETE' then
		return false
	elseif stateIndex == 2 and result == 'COMPLETE' then
		return false
	end

	local questname = string.lower(dic.getTranslatedStr(questCls.Name))
	searchText = string.lower(searchText)
	if searchText == '' or string.find(questname, searchText) ~= nil then
		return true
	end

	local mapname = questCls.StartMap
	if mapname and mapname ~= "None" then
		local mapnameText = GetClass("Map", mapname).Name
		mapnameText = string.lower(dic.getTranslatedStr(mapnameText))
		if string.find(mapnameText, searchText) ~= nil then
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
    questLevelDrop:ClearItems();
	questLevelDrop:SetMargin(194, 48, 178, 20)
	questLevelDrop:SetVisibleLine(7)
	questLevelDrop:AddItem(0, ClMsg('Auto_MoDu_BoKi'))
	questLevelDrop:AddItem(1, 'Lv.1 ~ Lv.100')
	questLevelDrop:AddItem(2, 'Lv.101 ~ Lv.200')
	questLevelDrop:AddItem(3, 'Lv.201 ~ Lv.300')
	questLevelDrop:AddItem(4, 'Lv.301 ~ Lv.400')
	questLevelDrop:AddItem(5, 'Lv.401 ~ Lv.500')
	questLevelDrop:AddItem(6, 'Lv.501 ~ Lv.600')

	local stateText = page_quest:CreateOrGetControl("richtext", "stateText", 378, 25, 20, 24)
	stateText:SetText("@dicID_^*$UI_20170912_002757$*^")
	stateText:SetFontName("black_16_b")

	local questStateDrop = page_quest:CreateOrGetControl("droplist", "questStateDrop", 378, 48, 178, 20)
	tolua.cast(questStateDrop, "ui::CDropList")
	questStateDrop:SetSkinName("droplist_normal")
	questStateDrop:SetSelectedScp("ADVENTURE_BOOK_QUEST_DROPLIST")
	questStateDrop:SetTextAlign("left","center")
	questStateDrop:ClearItems()
	questStateDrop:SetVisibleLine(3)
	questStateDrop:AddItem(0, ClMsg('Auto_MoDu_BoKi'), 0, 0, " ")
	questStateDrop:AddItem(1, ClMsg('Complete'), 0, 0, " ")
	questStateDrop:AddItem(2, ClMsg('NotComplete'), 0, 0, " ")
end