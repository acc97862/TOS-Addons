--inventoryweight.lua
--deleting slot glitches out main, also doesn't decrease itemCls
--all slot broken when adding/removing

local hooks = {}
local addWeight10 = 0        -- 10 times of weight change
local reuseOldWeight = false -- Unused로 설정된 것은 안보임 for INSERT_ITEM_TO_TREE in INVENTORY_TOTAL_LIST_GET
local itemTbl = {}           -- itemTbl[typeStr][ClassID] == number of items

function INVENTORYWEIGHT_ON_INIT(addon, frame)
	if next(hooks) == nil then
		local function setupHook(newFunc, oldFuncStr)
			hooks[oldFuncStr] = _G[oldFuncStr]
			_G[oldFuncStr] = newFunc
		end

		setupHook(INSERT_ITEM_TO_TREE_HOOKED, "INSERT_ITEM_TO_TREE")
		setupHook(TEMP_INV_ADD_HOOKED, "TEMP_INV_ADD")
		setupHook(TEMP_INV_REMOVE_HOOKED, "TEMP_INV_REMOVE")
		setupHook(INVENTORY_UPDATE_ITEM_BY_GUID_HOOKED, "INVENTORY_UPDATE_ITEM_BY_GUID")
		setupHook(SET_SLOTSETTITLE_COUNT_HOOKED, "SET_SLOTSETTITLE_COUNT")
		setupHook(INVENTORY_TOTAL_LIST_GET_HOOKED, "INVENTORY_TOTAL_LIST_GET")

		addon:RegisterMsg("GAME_START_3SEC", "INVENTORY_TOTAL_LIST_GET")
	end
end

local function INVENTORYWEIGHT_SET_CHANGE(invItem, typeStr, addCount)
	-- Calculates change in weight and updates addWeight10 and itemTbl
	-- addCount: -1 for remove, 0 for change, 1 for insert/add
	local obj = GetIES(invItem:GetObject())
	local ClassID = obj.ClassID

	if itemTbl[typeStr] == nil then
		itemTbl[typeStr] = {}
	end
	local typeTbl = itemTbl[typeStr]
	local oldval = typeTbl[ClassID] or 0
	local remainInvItemCount = 0

	if obj.MaxStack == 1 then
		remainInvItemCount = oldval + addCount
	elseif addCount >= 0 then
		remainInvItemCount = GET_REMAIN_INVITEM_COUNT(invItem)
	end

	typeTbl[ClassID] = remainInvItemCount
	addWeight10 = (remainInvItemCount - oldval) * math.floor(obj.Weight * 10 + 0.5)
end

local function INVENTORYWEIGHT_DOUBLE_SLOTSETTITLE(frame, invItem, addCount)
	-- Calls SET_SLOTSETTITLE_COUNT on treeGbox_ and treeGbox_All
	-- Called by INSERT_ITEM_TO_TREE_HOOKED, TEMP_INV_ADD_HOOKED, TEMP_INV_REMOVE_HOOKED
	-- addCount set to 0 since the counter is already updated by the original game code
	local itemCls = GetClassByType("Item", invItem.type)
	local name = itemCls.ClassName
	if name == "Vis" or name == "Feso" then
		return
	end

	local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex)
	local typeStr = GET_INVENTORY_TREEGROUP(baseidcls)
	local group = GET_CHILD_RECURSIVELY(frame, 'inventoryGbox', 'ui::CGroupBox')
	INVENTORYWEIGHT_SET_CHANGE(invItem, typeStr, addCount)

	local tree_box = GET_CHILD_RECURSIVELY(group, 'treeGbox_'.. typeStr,'ui::CGroupBox')
	local tree = GET_CHILD_RECURSIVELY(tree_box, 'inventree_'.. typeStr,'ui::CTreeControl')
	if tree ~= nil then
		SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0)
	end

	tree_box = GET_CHILD_RECURSIVELY(group, 'treeGbox_All','ui::CGroupBox')
	tree = GET_CHILD_RECURSIVELY(tree_box, 'inventree_All','ui::CTreeControl')
	if tree ~= nil then
		SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0)
	end
end

function INSERT_ITEM_TO_TREE_HOOKED(frame, tree, invItem, itemCls, baseidcls, ...)
	-- In INVENTORY_TOTAL_LIST_GET, if (invenTypeStr == nil or invenTypeStr == typeStr), the first INSERT_ITEM_TO_TREE is skipped.
	-- reuseOldWeight will be set to false in this case, updating itemTbl
	if reuseOldWeight then
		reuseOldWeight = false
	else
		reuseOldWeight = (string.sub(tree:GetName(), -4) ~= "_All")
		local typeStr = GET_INVENTORY_TREEGROUP(baseidcls)
		INVENTORYWEIGHT_SET_CHANGE(invItem, typeStr, 1)
	end

	return hooks.INSERT_ITEM_TO_TREE(frame, tree, invItem, itemCls, baseidcls, ...)
end

function TEMP_INV_ADD_HOOKED(frame, invIndex, ...)
	-- Hook over function to modify weight infomation
	local rets = {hooks.TEMP_INV_ADD(frame, invIndex, ...)}
	local invItem = session.GetInvItem(invIndex)
	INVENTORYWEIGHT_DOUBLE_SLOTSETTITLE(frame, invItem, 1)
	return unpack(rets)
end

function TEMP_INV_REMOVE_HOOKED(frame, itemGuid, ...)
	-- Hook over function to modify weight infomation
	local rets = {hooks.TEMP_INV_REMOVE(frame, itemGuid, ...)}
	local invItem = session.GetInvItemByGuid(itemGuid)

	if invItem == nil then
		return;
	end

	INVENTORYWEIGHT_DOUBLE_SLOTSETTITLE(frame, invItem, -1)
	return unpack(rets)
end

function INVENTORY_UPDATE_ITEM_BY_GUID_HOOKED(frame, itemGuid, ...)
	-- Hook over function to modify weight infomation
	local rets = {hooks.INVENTORY_UPDATE_ITEM_BY_GUID(frame, itemGuid, ...)}
	local invItem = session.GetInvItemByGuid(itemGuid)

	if invItem == nil then
		return;
	end

	INVENTORYWEIGHT_DOUBLE_SLOTSETTITLE(frame, invItem, 0)
	return unpack(rets)
end

function SET_SLOTSETTITLE_COUNT_HOOKED(tree, baseidcls, addCount)
	-- Replace old function to include weight information
    local clslist, cnt  = GetClassList("inven_baseid");
    local className = baseidcls.ClassName
    if baseidcls.MergedTreeTitle ~= "NO" then
        className = baseidcls.MergedTreeTitle
    end
    
    local titlestr = "ssettitle_" .. className;
    local textcls = GET_CHILD_RECURSIVELY(tree, titlestr, 'ui::CRichText');
	if textcls ~= nil then
		textcls:SetEventScript(ui.LBUTTONUP, "SET_INVENTORY_SLOTSET_OPEN")
		textcls:SetEventScript(ui.DROP, "INVENTORY_ON_DROP")
		textcls:SetEventScriptArgString(ui.LBUTTONUP, className)
		local curCount = textcls:GetUserIValue("TOTAL_COUNT")
		curCount = curCount + addCount
		textcls:SetUserValue("TOTAL_COUNT", curCount)

		-- Add weight information
		local curWeight = textcls:GetUserIValue("TOTAL_WEIGHT")
		curWeight = curWeight + addWeight10
		textcls:SetUserValue("TOTAL_WEIGHT", curWeight)
		textcls:SetText(string.format('{img btn_minus 20 20} %s (%d) (@dicID_^*$UI_20150317_000281$*^: %g)', baseidcls.TreeSSetTitle, curCount, curWeight/10))
	end

    local hGroup = tree:FindByValue(baseidcls.TreeGroup);
    if hGroup ~= nil then
        local treeNode = tree:GetNodeByTreeItem(hGroup);
        local newCaption = treeNode:GetUserValue("BASE_CAPTION");
        local totalCount = treeNode:GetUserIValue("TOTAL_ITEM_COUNT");
        totalCount = totalCount + addCount;        
        treeNode:SetUserValue("TOTAL_ITEM_COUNT", totalCount);

        local isOptionApplied = CHECK_INVENTORY_OPTION_APPLIED(baseidcls)
        local isOptionAppliedText = ""
        if isOptionApplied == 1 then
            isOptionAppliedText = ClMsg("ApplyOption")
        end

		-- Add weight information
		local totalWeight = treeNode:GetUserIValue("TOTAL_ITEM_WEIGHT")
		totalWeight = totalWeight + addWeight10
		treeNode:SetUserValue("TOTAL_ITEM_WEIGHT", totalWeight)

		tree:SetItemCaption(hGroup,string.format("%s (%d) (@dicID_^*$UI_20150317_000281$*^: %g) %s", newCaption, totalCount, totalWeight/10, isOptionAppliedText))

    end
end

function INVENTORY_TOTAL_LIST_GET_HOOKED(frame, setpos, isIgnorelifticon, invenTypeStr, ...)
	-- Reset variables when function is called
    local frame = ui.GetFrame("inventory")
    if frame == nil then return; end

    local liftIcon = ui.GetLiftIcon();
    if nil == isIgnorelifticon then
        isIgnorelifticon = "NO";
    end
    
    if isIgnorelifticon ~= "NO" and liftIcon ~= nil then 
        return; 
    end
	-- Reset variables
	addWeight = 0
	reuseOldWeight = false
	if invenTypeStr == nil then
		itemTbl = {}
	else
		itemTbl[invenTypeStr] = {}
	end

	return hooks.INVENTORY_TOTAL_LIST_GET(frame, setpos, isIgnorelifticon, invenTypeStr, ...)
end
