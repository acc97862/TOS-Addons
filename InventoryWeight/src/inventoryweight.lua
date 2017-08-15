--inventoryweight.lua

local itemTbl = {};

function INVENTORYWEIGHT_ON_INIT(addon, frame)
	if INSERT_ITEM_TO_TREE_HOOKED ~= INSERT_ITEM_TO_TREE then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
				_G[hookedFunctionStr] = newFunction;
			else
				_G[hookedFunctionStr] = newFunction;
			end
		end

		setupHook(INSERT_ITEM_TO_TREE_HOOKED, "INSERT_ITEM_TO_TREE");
		setupHook(TEMP_INV_REMOVE_HOOKED, "TEMP_INV_REMOVE");
		setupHook(INV_SLOT_UPDATE_HOOKED, "INV_SLOT_UPDATE");
		setupHook(INVENTORY_LIST_GET_HOOKED, "INVENTORY_LIST_GET");
		setupHook(SET_SLOTSETTITLE_COUNT_HOOKED, "SET_SLOTSETTITLE_COUNT");
		setupHook(INVENTORY_TOTAL_LIST_GET_HOOKED, "INVENTORY_TOTAL_LIST_GET");
		INVENTORY_LIST_GET(ui.GetFrame("inventory"));
	end
end

function INSERT_ITEM_TO_TREE_HOOKED(frame, tree, invItem, itemCls, baseidcls)
	local treegroupname = baseidcls.TreeGroup;

	local treegroup = tree:FindByValue(treegroupname);
	if tree:IsExist(treegroup) == 0 then
		treegroup = tree:Add(baseidcls.TreeGroupCaption, baseidcls.TreeGroup);
		local treeNode = tree:GetNodeByTreeItem(treegroup);
		treeNode:SetUserValue("BASE_CAPTION", baseidcls.TreeGroupCaption);
		GROUP_NAMELIST[#GROUP_NAMELIST + 1] = treegroupname;
	end

	--슬롯셋 없으면 만들기
	local slotsetname = GET_SLOTSET_NAME(invItem.invIndex)
	local slotsetnode = tree:FindByValue(treegroup, slotsetname);
	if tree:IsExist(slotsetnode) == 0 then
		MAKE_INVEN_SLOTSET_AND_TITLE(tree, treegroup, slotsetname, baseidcls);
	end

	slotset = GET_CHILD(tree,slotsetname,'ui::CSlotSet');

	local slotCount = slotset:GetSlotCount();

	local slotindex = invItem.invIndex - GET_BASE_SLOT_INDEX(invItem.invIndex) - 1;

	local slot = nil;
	if cap == "" then
		slot = slotset:GetSlotByIndex(slotindex);
	else
		local cnt = GET_SLOTSET_COUNT(tree, baseidcls.ClassName);
		while slotCount <= cnt do
			slotset:ExpandRow();
			slotCount = slotset:GetSlotCount();
		end

		slot = slotset:GetSlotByIndex(cnt);
		cnt = cnt + 1;
		slotset:SetUserValue("SLOT_ITEM_COUNT", cnt);
	end

	slot:ShowWindow(1);
	UPDATE_INVENTORY_SLOT(slot, invItem, itemCls);

	INV_ICON_SETINFO(frame, slot, invItem, customFunc, scriptArg, remainInvItemCount);
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 1, invItem);

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

	local typeStr = "Item";
	if itemCls.ItemType == "Equip" then
		typeStr = itemCls.ItemType;
	end
	local tree = GET_CHILD_RECURSIVELY(frame, 'inventree_'..typeStr);
	local treegroup = tree:FindByValue(treegroupname);
	if tree:IsExist(treegroup) == 0 then
		return;
	end

	local treeNode = tree:GetNodeByTreeItem(treegroup);
	local slotsetname = GET_SLOTSET_NAME(invItem.invIndex);
	local slotsetnode = tree:FindByValue(treegroup, slotsetname);
	local slotset = GET_CHILD(tree,slotsetname,'ui::CSlotSet');

	local slot = GET_SLOT_FROMSLOTSET_BY_IESID(slotset, itemGuid);
	if slot == nil then
		return;
	end
	slot:SetText('{s18}{ol}{b}', 'count', 'right', 'bottom', -2, 1);
	local slotIndex = slot:GetSlotIndex();
	slotset:ClearSlotAndPullNextSlots(slotIndex, "ONUPDATE_SLOT_INVINDEX");
	
	local cnt = GET_SLOTSET_COUNT(tree, baseidcls.ClassName);
	cnt = cnt - 1;
	slotset:SetUserValue("SLOT_ITEM_COUNT", cnt);

	for i = 1 , #SLOTSET_NAMELIST do
		local slotset = GET_CHILD(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet');
		if slotset ~= nil then
			HIDE_EMPTY_SLOT(slotset);
		end
	end

	SET_SLOTSETTITLE_COUNT(tree, baseidcls, -1, invItem);

	if cnt == 0 then
		local titleName = "ssettitle_" .. baseidcls.ClassName;
		local hTitle = tree:FindByValue(titleName);

		REMOVE_FROM_SLOTSET(slotsetname);

		tree:Delete(hTitle);
		tree:Delete(slotsetnode);

		if treeNode:GetChildNodeCount() == 1 then
			tree:Delete(treegroup);

			REMOVE_FROM_TREEGROUP(treegroupname);

		end
	end
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

	local itemCls = GetClassByType("Item", invItem.type);
	local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex);
	local typeStr = "Item";
	if itemCls.ItemType == "Equip" then
		typeStr = itemCls.ItemType;
	end
	local tree = GET_CHILD_RECURSIVELY(frame, 'inventree_' .. typeStr);
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0, invItem);
end

function INVENTORY_LIST_GET_HOOKED(frame)
	itemTbl = {};
	INVENTORY_LIST_GET_OLD(frame);
end

function SET_SLOTSETTITLE_COUNT_HOOKED(tree, baseidcls, addCount, invItem)
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

	local addWeight = (remainInvItemCount-oldval) * obj.Weight;

	local clslist, cnt  = GetClassList("inven_baseid");
	local titlestr = "ssettitle_" .. baseidcls.ClassName;

	local textcls = GET_CHILD(tree, titlestr, 'ui::CRichText');
	local curCount = textcls:GetUserIValue("TOTAL_COUNT");
	local curWeight = textcls:GetUserIValue("TOTAL_WEIGHT");
	curCount = curCount + addCount;
	curWeight = curWeight + addWeight;
	textcls:SetUserValue("TOTAL_COUNT", curCount);
	textcls:SetUserValue("TOTAL_WEIGHT", curWeight);
	textcls:SetText(string.format("%s (%d) (@dicID_^*$UI_20150317_000281$*^: %d)", baseidcls.TreeSSetTitle, curCount, curWeight));

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

		tree:SetItemCaption(hGroup,string.format("%s (%d) (@dicID_^*$UI_20150317_000281$*^: %d)", newCaption, totalCount, totalWeight));

	end
end

function INVENTORY_TOTAL_LIST_GET_HOOKED(frame, setpos, isIgnorelifticon)

	local liftIcon 				= ui.GetLiftIcon();
	if nil == isIgnorelifticon then
		isIgnorelifticon = "NO";
	end
	
	if isIgnorelifticon ~= "NO" and liftIcon ~= nil then
		return
	end

	itemTbl = {};
	INVENTORY_TOTAL_LIST_GET_OLD(frame, setpos, isIgnorelifticon);
end