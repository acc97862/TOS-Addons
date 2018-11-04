--inventoryweight.lua

local lastAddWeight = 0;
local itemTbl = {};
local invenTitleName = nil;

function INVENTORYWEIGHT_ON_INIT(addon, frame)
	if INSERT_ITEM_TO_TREE_HOOKED ~= INSERT_ITEM_TO_TREE then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
			end
			_G[hookedFunctionStr] = newFunction;
		end

		setupHook(INSERT_ITEM_TO_TREE_HOOKED, "INSERT_ITEM_TO_TREE");
		setupHook(TEMP_INV_REMOVE_HOOKED, "TEMP_INV_REMOVE");
		setupHook(REMOVE_FROM_SLOTSET_HOOKED, "REMOVE_FROM_SLOTSET");
		setupHook(INV_SLOT_UPDATE_HOOKED, "INV_SLOT_UPDATE");
		setupHook(SET_SLOTSETTITLE_COUNT_HOOKED, "SET_SLOTSETTITLE_COUNT");
		setupHook(INVENTORY_TOTAL_LIST_GET_HOOKED, "INVENTORY_TOTAL_LIST_GET");

		INVENTORY_TOTAL_LIST_GET(ui.GetFrame("inventory"));
	end
end

function INSERT_ITEM_TO_TREE_HOOKED(frame, tree, invItem, itemCls, baseidcls)
    --그룹 없으면 만들기
    local treegroupname = baseidcls.TreeGroup
    local treegroup = tree:FindByValue(treegroupname);
    if tree:IsExist(treegroup) == 0 then
        treegroup = tree:Add(baseidcls.TreeGroupCaption, baseidcls.TreeGroup);
        local treeNode = tree:GetNodeByTreeItem(treegroup);
        treeNode:SetUserValue("BASE_CAPTION", baseidcls.TreeGroupCaption);
        GROUP_NAMELIST[#GROUP_NAMELIST + 1] = treegroupname
    end
    

    --슬롯셋 없으면 만들기
    local slotsetname = GET_SLOTSET_NAME(invItem.invIndex)
    local slotsetnode = tree:FindByValue(treegroup, slotsetname);
    if tree:IsExist(slotsetnode) == 0 then
        MAKE_INVEN_SLOTSET_AND_TITLE(tree, treegroup, slotsetname, baseidcls);
    end                 
    slotset = GET_CHILD_RECURSIVELY(tree,slotsetname,'ui::CSlotSet');
    local slotCount = slotset:GetSlotCount();
    local slotindex = invItem.invIndex - GET_BASE_SLOT_INDEX(invItem.invIndex) - 1;

    --검색 기능
    local slot = nil;
    if cap == "" then
        slot = slotset:GetSlotByIndex(slotindex);
    else
        local cnt = GET_SLOTSET_COUNT(tree, baseidcls);
        -- 저장된 템의 최대 인덱스에 따라 자동으로 늘어나도록. 예를들어 해당 셋이 10000부터 시작하는데 10500 이 오면 500칸은 늘려야됨
        while slotCount <= cnt  do 
            slotset:ExpandRow()
            slotCount = slotset:GetSlotCount();
        end

        slot = slotset:GetSlotByIndex(cnt);
        cnt = cnt + 1;
        slotset:SetUserValue("SLOT_ITEM_COUNT", cnt)
    end

    slot:ShowWindow(1); 
    UPDATE_INVENTORY_SLOT(slot, invItem, itemCls);

    INV_ICON_SETINFO(frame, slot, invItem, customFunc, scriptArg, remainInvItemCount);
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 1, invItem)

    slotset:MakeSelectionList();
end

function TEMP_INV_REMOVE_HOOKED(frame, itemGuid)

    local invItem = session.GetInvItemByGuid(itemGuid);
    if invItem == nil then
        return;
    end

    local itemCls = GetClassByType("Item", invItem.type);
    local name = itemCls.ClassName;
    if name == "Vis" or name == "Feso" then
        DRAW_TOTAL_VIS(frame, 'invenZeny', 1);
        return;
    end

    local invIndex = invItem.invIndex;
    local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invIndex)

    local treegroupname = baseidcls.TreeGroup;

    
    local typeStr = GET_INVENTORY_TREEGROUP(baseidcls)

    local tree = GET_CHILD_RECURSIVELY(frame, 'inventree_'..typeStr)
    local treegroup = tree:FindByValue(treegroupname);
    if tree:IsExist(treegroup) == 0 then
        return;
    end

    local treeNode = tree:GetNodeByTreeItem(treegroup);
    local slotsetname = GET_SLOTSET_NAME(invItem.invIndex)
    local slotsetnode = tree:FindByValue(treegroup, slotsetname);
    local slotset = GET_CHILD_RECURSIVELY(tree,slotsetname,'ui::CSlotSet')  

    local slot = GET_SLOT_FROMSLOTSET_BY_IESID(slotset, itemGuid);
    if slot == nil then
        return;
    end
    slot:SetText('{s18}{ol}{b}', 'count', 'right', 'bottom', -2, 1);
    local slotIndex = slot:GetSlotIndex();
    slotset:ClearSlotAndPullNextSlots(slotIndex, "ONUPDATE_SLOT_INVINDEX");

    local cnt = GET_SLOTSET_COUNT(tree, baseidcls);
    cnt = cnt - 1;
    slotset:SetUserValue("SLOT_ITEM_COUNT", cnt)

    -- 아이템 없는 빈 슬롯은 숨겨라
    for i = 1 , #SLOTSET_NAMELIST do
        local slotset = GET_CHILD_RECURSIVELY(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')  
        if slotset ~= nil then
            HIDE_EMPTY_SLOT(slotset)
        end
    end

	SET_SLOTSETTITLE_COUNT(tree, baseidcls, -1, invItem);    

    if cnt == 0 then
        local titleName = "ssettitle_" .. baseidcls.ClassName;
        if baseidcls.MergedTreeTitle ~= "NO" then
            titleName = 'ssettitle_'..baseidcls.MergedTreeTitle
        end
        local hTitle = tree:FindByValue(titleName);

        REMOVE_FROM_SLOTSET(slotsetname);

        tree:Delete(hTitle);
        tree:Delete(slotsetnode);

        if treeNode:GetChildNodeCount() == 1 then
            tree:Delete(treegroup);

            REMOVE_FROM_TREEGROUP(treegroupname);
            
        end
    end

    ---------------------------
    typeStr = "All"

    tree = GET_CHILD_RECURSIVELY(frame, 'inventree_'..typeStr)
    treegroup = tree:FindByValue(treegroupname);
    if tree:IsExist(treegroup) == 0 then
        return;
    end

    treeNode = tree:GetNodeByTreeItem(treegroup);
    slotsetname = GET_SLOTSET_NAME(invItem.invIndex)
    slotsetnode = tree:FindByValue(treegroup, slotsetname);
    slotset = GET_CHILD_RECURSIVELY(tree,slotsetname,'ui::CSlotSet')    

    slot = GET_SLOT_FROMSLOTSET_BY_IESID(slotset, itemGuid);
    if slot == nil then
        return;
    end
    slot:SetText('{s18}{ol}{b}', 'count', 'right', 'bottom', -2, 1);
    slotIndex = slot:GetSlotIndex();
    slotset:ClearSlotAndPullNextSlots(slotIndex, "ONUPDATE_SLOT_INVINDEX");

    cnt = GET_SLOTSET_COUNT(tree, baseidcls);
    cnt = cnt - 1;
    slotset:SetUserValue("SLOT_ITEM_COUNT", cnt)

    -- 아이템 없는 빈 슬롯은 숨겨라
    for i = 1 , #SLOTSET_NAMELIST do
        local slotset = GET_CHILD_RECURSIVELY(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')  
        if slotset ~= nil then
            HIDE_EMPTY_SLOT(slotset)
        end
    end

	SET_SLOTSETTITLE_COUNT(tree, baseidcls, -1, invItem);    

    if cnt == 0 then
        local titleName = "ssettitle_" .. baseidcls.ClassName;
        if baseidcls.MergedTreeTitle ~= "NO" then
            titleName = 'ssettitle_'..baseidcls.MergedTreeTitle
        end
        local hTitle = tree:FindByValue(titleName);

        REMOVE_FROM_SLOTSET(slotsetname);

        tree:Delete(hTitle);
        tree:Delete(slotsetnode);

        if treeNode:GetChildNodeCount() == 1 then
            tree:Delete(treegroup);

            REMOVE_FROM_TREEGROUP(treegroupname);
            
        end
    end
    --------------------------------
        
end

function REMOVE_FROM_SLOTSET_HOOKED(slotsetname)

    local tempSlotSet = {};
    for i = 1 , #SLOTSET_NAMELIST do
        if SLOTSET_NAMELIST[i] ~= slotsetname then
            tempSlotSet[#tempSlotSet + 1] = SLOTSET_NAMELIST[i];
        end
    end
    SLOTSET_NAMELIST = tempSlotSet;
	CHECK_SLOTSET_NAMELIST[slotsetname] = nil;

end

function INV_SLOT_UPDATE_HOOKED(frame, invItem, itemSlot)    
    local customFunc = nil;
    local scriptName = frame:GetUserValue("CUSTOM_ICON_SCP");
    local scriptArg = nil;
    if scriptName ~= nil then
        customFunc = _G[scriptName];
        local getArgFunc = _G[frame:GetUserValue("CUSTOM_ICON_ARG_SCP")];
        if getArgFunc ~= nil then
            scriptArg = getArgFunc();            
        end
    end
    
    local remainInvItemCount = GET_REMAIN_INVITEM_COUNT(invItem);    
    INV_ICON_SETINFO(frame, itemSlot, invItem, customFunc, scriptArg, remainInvItemCount);      

	local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex);
	local treegroupname = baseidcls.TreeGroup;

	local typeStr = GET_INVENTORY_TREEGROUP(baseidcls);
	local tree = GET_CHILD_RECURSIVELY(frame, 'inventree_' .. typeStr);
	local treegroup = tree:FindByValue(treegroupname);
	if tree:IsExist(treegroup) == 0 then
		return
	end
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0, invItem);

	typeStr = "All"
	tree = GET_CHILD_RECURSIVELY(frame, 'inventree_'..typeStr);
	treegroup = tree:FindByValue(treegroupname);
	if tree:IsExist(treegroup) == 0 then
		return
	end
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0, invItem);
end

function SET_SLOTSETTITLE_COUNT_HOOKED(tree, baseidcls, addCount, invItem)
	if invItem == nil then
		SET_SLOTSETTITLE_COUNT_OLD(tree, baseidcls, addCount);
		return
	end

	local addWeight = 0;

	if string.sub(tree:GetName(), -3) == "All" then
		addWeight = lastAddWeight;
		lastAddWeight = 0;
	else
		local obj = GetIES(invItem:GetObject());
		local ClassID = obj.ClassID;
		local maxStack = GetClassByType("Item", invItem.type).MaxStack;

		local oldval = itemTbl[ClassID];
		if oldval == nil then
			oldval = 0;
		end

		local remainInvItemCount = GET_REMAIN_INVITEM_COUNT(invItem);

		if maxStack == 1 then
			remainInvItemCount = oldval + addCount;
		elseif addCount < 0 then
			remainInvItemCount = 0;
		end

		if remainInvItemCount == 0 then
			itemTbl[ClassID] = nil;
		else
			itemTbl[ClassID] = remainInvItemCount;
		end

		addWeight = (remainInvItemCount-oldval) * math.floor(obj.Weight * 10 + 0.5);
		lastAddWeight = addWeight;
	end

    --local clslist, cnt  = GetClassList("inven_baseid");--Unused
    local className = baseidcls.ClassName
    if baseidcls.MergedTreeTitle ~= "NO" then
        className = baseidcls.MergedTreeTitle
    end
    
    local titlestr = "ssettitle_" .. className; 
    local textcls = GET_CHILD_RECURSIVELY(tree, titlestr, 'ui::CRichText');
    textcls:SetEventScript(ui.LBUTTONUP, "SET_INVENTORY_SLOTSET_OPEN")
    textcls:SetEventScript(ui.DROP, "INVENTORY_ON_DROP")
    textcls:SetEventScriptArgString(ui.LBUTTONUP, className)
    local curCount = textcls:GetUserIValue("TOTAL_COUNT");
	local curWeight = textcls:GetUserIValue("TOTAL_WEIGHT");
    curCount = curCount + addCount;
	curWeight = curWeight + addWeight;
    textcls:SetUserValue("TOTAL_COUNT", curCount);
	textcls:SetUserValue("TOTAL_WEIGHT", curWeight);
	textcls:SetText('{img btn_minus 20 20} ' .. baseidcls.TreeSSetTitle..' (' .. curCount .. ')' .. string.format(" (@dicID_^*$UI_20150317_000281$*^: %g)", curWeight/10))

    local hGroup = tree:FindByValue(baseidcls.TreeGroup);
    if hGroup ~= nil then
        local treeNode = tree:GetNodeByTreeItem(hGroup);
        local newCaption = treeNode:GetUserValue("BASE_CAPTION");
        local totalCount = treeNode:GetUserIValue("TOTAL_ITEM_COUNT");
		local totalWeight = treeNode:GetUserIValue("TOTAL_ITEM_WEIGHT");
        totalCount = totalCount + addCount;     
		totalWeight = totalWeight + addWeight;
        treeNode:SetUserValue("TOTAL_ITEM_COUNT", totalCount);
		treeNode:SetUserValue("TOTAL_ITEM_WEIGHT", totalWeight);


        local isOptionApplied = CHECK_INVENTORY_OPTION_APPLIED(baseidcls)
        local isOptionAppliedText = ""
        if isOptionApplied == 1 then
            isOptionAppliedText = ClMsg("ApplyOption")
        end

		tree:SetItemCaption(hGroup,newCaption..' ('..totalCount..') '.. string.format("(@dicID_^*$UI_20150317_000281$*^: %g) ", totalWeight/10) .. isOptionAppliedText)

    end
end

local function CHECK_INVENTORY_OPTION_EQUIP(itemCls)
    if itemCls == nil then
        return 0
    end

    local itemGrade = itemCls.ItemGrade
    local optionConfig = 1
    if itemGrade == 1 then
        optionConfig = config.GetXMLConfig("InvOption_Equip_Normal")
    elseif itemGrade == 2 then
        optionConfig = config.GetXMLConfig("InvOption_Equip_Magic")
    elseif itemGrade == 3 then
        optionConfig = config.GetXMLConfig("InvOption_Equip_Rare")
    elseif itemGrade == 4 then
        optionConfig = config.GetXMLConfig("InvOption_Equip_Unique")
    elseif itemGrade == 5 then
        optionConfig = config.GetXMLConfig("InvOption_Equip_Legend")
    end

    if config.GetXMLConfig("InvOption_Equip_All") == 1 then
        optionConfig = 1
    end

    if optionConfig == 0 then
        return
    end

    local itemTranscend = TryGetProp(itemCls, "Transcend")
    local itemReinforce = TryGetProp(itemCls, "Reinforce_2")
    local itemAppraisal = TryGetProp(itemCls, "NeedAppraisal")
    local itemRandomOption = TryGetProp(itemCls, "NeedRandomOption")

    if config.GetXMLConfig("InvOption_Equip_Upgrade") == 1 then
        if itemTranscend ~= nil and itemTranscend == 0 and itemReinforce ~= nil and itemReinforce == 0 then
            optionConfig = 0
        end
    end

    if config.GetXMLConfig("InvOption_Equip_Random") == 1 then
        if itemAppraisal ~= nil and itemAppraisal == 0 and itemRandomOption ~= nil and itemRandomOption == 0 then
            optionConfig = 0
        end
    end

    return optionConfig
end

local function CHECK_INVENTORY_OPTION_CARD(itemCls)
    if config.GetXMLConfig("InvOption_Card_All") == 1 then
        return 1
    end

    if itemCls == nil then
        return 0
    end

    local cardGroup = itemCls.MarketCategory
    local optionConfig = 1
    if cardGroup == "Card_CardRed" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Red")
    elseif cardGroup == "Card_CardBlue" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Blue")
    elseif cardGroup == "Card_CardGreen" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Green")
    elseif cardGroup == "Card_CardPurple" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Purple")
    elseif cardGroup == "Card_CardLeg" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Legend")
    elseif cardGroup == "Card_CardAddExp" then
        optionConfig = config.GetXMLConfig("InvOption_Card_Etc")
    end
    

    return optionConfig
end

local function CHECK_INVENTORY_OPTION_ETC(itemCls)
    if config.GetXMLConfig("InvOption_Etc_All") == 1 then
        return 1
    end

    if itemCls == nil then
        return 0
    end

    local itemCategory = itemCls.MarketCategory
    local optionConfig = 1
    if itemCategory == "Misc_Usual" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Usual")
    elseif itemCategory == "Misc_Quest" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Quest")
    elseif itemCategory == "Misc_Special" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Special")
    elseif itemCategory == "Misc_Collect" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Collect")
    elseif itemCategory == "Misc_Etc" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Etc")
    elseif itemCategory == "Misc_Mineral" then
        optionConfig = config.GetXMLConfig("InvOption_Etc_Mineral")
    end

    return optionConfig
end

local function CHECK_INVENTORY_OPTION_GEM(itemCls)
    if config.GetXMLConfig("InvOption_Gem_All") == 1 then
        return 1
    end

    if itemCls == nil then
        return 0
    end

    local cardGroup = itemCls.MarketCategory
    local optionConfig = 1
    if cardGroup == "Gem_GemRed" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Red")
    elseif cardGroup == "Gem_GemBlue" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Blue")
    elseif cardGroup == "Gem_GemGreen" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Green")
    elseif cardGroup == "Gem_GemYellow" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Yellow")
    elseif cardGroup == "Gem_GemLegend" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Legend")
    elseif cardGroup == "Gem_GemSkill" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_Skill")
    elseif cardGroup == "Gem_GemWhite" then
        optionConfig = config.GetXMLConfig("InvOption_Gem_White")
    end
    
    return optionConfig
end

function INVENTORY_TOTAL_LIST_GET_HOOKED(frame, setpos, isIgnorelifticon, invenTypeStr)    
    local frame = ui.GetFrame("inventory")

    local liftIcon              = ui.GetLiftIcon();
    if nil == isIgnorelifticon then
        isIgnorelifticon = "NO";
    end
    
    if isIgnorelifticon ~= "NO" and liftIcon ~= nil then
        return
    end

	itemTbl = {};

    local sortType = frame:GetUserIValue("SORT_TYPE")
    session.BuildInvItemSortedList();
    local sortedList = session.GetInvItemSortedList();
    local invItemCount = sortedList:size();

    if sortType == nil then
        sortType = 1
    end

    --local blinkcolor = frame:GetUserConfig("TREE_SEARCH_BLINK_COLOR");--Unused

    local group = GET_CHILD_RECURSIVELY(frame, 'inventoryGbox', 'ui::CGroupBox')
    for typeNo = 1, #g_invenTypeStrList do
        if invenTypeStr == nil or invenTypeStr == g_invenTypeStrList[typeNo] or typeNo == 1 then
            local tree_box = GET_CHILD_RECURSIVELY(group, 'treeGbox_'.. g_invenTypeStrList[typeNo],'ui::CGroupBox')
            local tree = GET_CHILD_RECURSIVELY(tree_box, 'inventree_'.. g_invenTypeStrList[typeNo],'ui::CTreeControl')

            local groupfontname = frame:GetUserConfig("TREE_GROUP_FONT");
            local tabwidth = frame:GetUserConfig("TREE_TAB_WIDTH");

            tree:Clear();
            tree:EnableDrawFrame(false)
            tree:SetFitToChild(true,60)
            tree:SetFontName(groupfontname);
            tree:SetTabWidth(tabwidth);

            for i = 1 , #SLOTSET_NAMELIST do
                SLOTSET_NAMELIST[i] = nil
            end

			CHECK_SLOTSET_NAMELIST = {};--Forces rebuild of SLOTSET_NAMELIST during MAKE_INVEN_SLOTSET

            for i = 1 , #GROUP_NAMELIST do
                GROUP_NAMELIST[i] = nil
            end

            local customFunc = nil;
            local scriptName = frame:GetUserValue("CUSTOM_ICON_SCP");
            local scriptArg = nil;
            if scriptName ~= nil then
                customFunc = _G[scriptName];
                local getArgFunc = _G[frame:GetUserValue("CUSTOM_ICON_ARG_SCP")];
                if getArgFunc ~= nil then
                    scriptArg = getArgFunc();
                end
            end
        end
    end

    
    --local baseidclslist, baseidcnt  = GetClassList("inven_baseid");--Moved
    


    local searchGbox = group:GetChild('searchGbox');
    local searchSkin = GET_CHILD_RECURSIVELY(searchGbox, "searchSkin",'ui::CGroupBox');
    local edit = GET_CHILD_RECURSIVELY(searchSkin, "ItemSearch", "ui::CEditControl");
    local cap = edit:GetText();
	--[[#SLOTSET_NAMELIST == 0 and tree:Clear(), so slotset == nil and slotset:RemoveAllChild() leads to an error
    if cap ~= "" then
        for i = 1 , #SLOTSET_NAMELIST do
            local slotset = GET_CHILD_RECURSIVELY(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')  
            slotset:RemoveAllChild();
            slotset:SetUserValue("SLOT_ITEM_COUNT", 0);
        end
    end
	]]

    local invItemList = {}
    local index_count = 1
    for i = 0, invItemCount - 1 do
        local invItem = sortedList:at(i);
        if invItem ~= nil then
            invItemList[index_count] = invItem
            index_count = index_count + 1
        end
    end


--1 등급순
--2 무게순
--3 이름순
--4 소지량순

    

    if sortType == 1 then
        table.sort(invItemList, INVENTORY_SORT_BY_GRADE)
    elseif sortType == 2 then
        table.sort(invItemList, INVENTORY_SORT_BY_WEIGHT)
    elseif sortType == 3 then
        table.sort(invItemList, INVENTORY_SORT_BY_NAME)
    elseif sortType == 4 then
        table.sort(invItemList, INVENTORY_SORT_BY_COUNT)
    else
        table.sort(invItemList, INVENTORY_SORT_BY_NAME)
    end
    
    if invenTitleName == nil then
		local baseidclslist, baseidcnt  = GetClassList("inven_baseid");
        invenTitleName = {} 
        for i = 1, baseidcnt do
            local baseidcls = GetClassByIndexFromList(baseidclslist, i-1)
            local tempTitle = baseidcls.ClassName
            if baseidcls.MergedTreeTitle ~= "NO" then
                tempTitle = baseidcls.MergedTreeTitle
            end

            if table.find(invenTitleName, tempTitle) == 0 then
                invenTitleName[#invenTitleName + 1] = tempTitle
            end
        end
    end



    local cls_inv_index = {}        
    local i_cnt = 0 
    for i = 1, #invenTitleName do
        local category = invenTitleName[i]
        for j = 1 , #invItemList do         
            local invItem = invItemList[j];
            if invItem ~= nil then
                local itemCls = GetIES(invItem:GetObject())
                if itemCls.MarketCategory ~= "None" then
                    local baseidcls = nil
                    if cls_inv_index[invItem.invIndex] == nil then
                        baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex)                        
                        cls_inv_index[invItem.invIndex] = baseidcls                     
                    else
                        baseidcls = cls_inv_index[invItem.invIndex]                     
                    end
                    
                    local titleName = baseidcls.ClassName
                    if baseidcls.MergedTreeTitle ~= "NO" then
                        titleName = baseidcls.MergedTreeTitle
                    end

                    if category == titleName then
                        local typeStr = GET_INVENTORY_TREEGROUP(baseidcls)                      
                        if itemCls ~= nil then
                            local makeSlot = true;
                            if cap ~= "" then
                                --인벤토리 안에 있는 아이템을 찾기 위한 로직
                                local itemname = string.lower(dictionary.ReplaceDicIDInCompStr(itemCls.Name));
                                --접두어도 포함시켜 검색해야되기 때문에, 접두를 찾아서 있으면 붙여주는 작업
                                local prefixClassName = TryGetProp(itemCls, "LegendPrefix")
                                if prefixClassName ~= nil and prefixClassName ~= "None" then
                                    local prefixCls = GetClass('LegendSetItem', prefixClassName)
                                    local prefixName = string.lower(dictionary.ReplaceDicIDInCompStr(prefixCls.Name));
                                    itemname = prefixName .. " " .. itemname;
                                end

                                local tempcap = string.lower(cap);
                                local a = string.find(itemname, tempcap);
                                if a == nil then
                                    makeSlot = false;
                                end         
                            end             

                            local viewOptionCheck = 1
                            if typeStr == "Equip" then
                                viewOptionCheck = CHECK_INVENTORY_OPTION_EQUIP(itemCls)
                            elseif typeStr == "Card" then
                                viewOptionCheck = CHECK_INVENTORY_OPTION_CARD(itemCls)
                            elseif typeStr == "Etc" then
                                viewOptionCheck = CHECK_INVENTORY_OPTION_ETC(itemCls)                   
                            elseif typeStr == "Gem" then
                                viewOptionCheck = CHECK_INVENTORY_OPTION_GEM(itemCls)
                            end                     

                            if makeSlot == true and viewOptionCheck == 1 then
                                
                        
                                if invItem.count > 0 and baseidcls.ClassName ~= 'Unused' then -- Unused로 설정된 것은 안보임
                                    if invenTypeStr == nil or invenTypeStr == typeStr then
                                        local tree_box = GET_CHILD_RECURSIVELY(group, 'treeGbox_'.. typeStr,'ui::CGroupBox')
                                        local tree = GET_CHILD_RECURSIVELY(tree_box, 'inventree_'.. typeStr,'ui::CTreeControl')                             
                                        INSERT_ITEM_TO_TREE(frame, tree, invItem, itemCls, baseidcls);
                                    end

                                    local tree_box_all = GET_CHILD_RECURSIVELY(group, 'treeGbox_All','ui::CGroupBox')
                                    local tree_all = GET_CHILD_RECURSIVELY(tree_box_all, 'inventree_All','ui::CTreeControl')    
                                    INSERT_ITEM_TO_TREE(frame, tree_all, invItem, itemCls, baseidcls);
                                end
                            else
                                if customFunc ~= nil then
                                    local slot = slotSet:GetSlotByIndex(i);
                                    if slot ~= nil then
                                        customFunc(slot, scriptArg, invItem, nil);                                        
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for typeNo = 1, #g_invenTypeStrList do
        local tree_box = GET_CHILD_RECURSIVELY(group, 'treeGbox_'.. g_invenTypeStrList[typeNo],'ui::CGroupBox')
        local tree = GET_CHILD_RECURSIVELY(tree_box, 'inventree_'.. g_invenTypeStrList[typeNo],'ui::CTreeControl')
    --아이템 없는 빈 슬롯은 숨겨라
        for i = 1 , #SLOTSET_NAMELIST do
            slotset = GET_CHILD_RECURSIVELY(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet');
            if slotset ~= nil then
                HIDE_EMPTY_SLOT(slotset);
            end         
        end

        ADD_GROUP_BOTTOM_MARGIN(frame,tree)

        tree:OpenNodeAll();

        --검색결과 스크롤 세팅은 여기서 하자. 트리 업데이트 후에 위치가 고정된 다음에.
        for i = 1 , #SLOTSET_NAMELIST do
            slotset = GET_CHILD_RECURSIVELY(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')

            local slotsetnode = tree:FindByValue(SLOTSET_NAMELIST[i]);
            if setpos == 'setpos' then

                local savedPos = frame:GetUserValue("INVENTORY_CUR_SCROLL_POS");
            
                if savedPos == 'None' then
                    savedPos = 0
                end
                    
                tree_box:SetScrollPos( tonumber(savedPos) )
            end
        end     
    end


end