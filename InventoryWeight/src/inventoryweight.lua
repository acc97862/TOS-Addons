--inventoryweight.lua

local hooks = {}
local addWeight = 0
local reuseOldWeight = false
local itemTbl = {}

function INVENTORYWEIGHT_ON_INIT(addon, frame)
	if next(hooks) == nil then
		local function setupHook(newFunc, oldFuncStr)
			hooks[oldFuncStr] = _G[oldFuncStr]
			_G[oldFuncStr] = newFunc
		end

		setupHook(INSERT_ITEM_TO_TREE_HOOKED, "INSERT_ITEM_TO_TREE")
		setupHook(TEMP_INV_REMOVE_HOOKED, "TEMP_INV_REMOVE")
		setupHook(INV_SLOT_UPDATE_HOOKED, "INV_SLOT_UPDATE")
		setupHook(SET_SLOTSETTITLE_COUNT_HOOKED, "SET_SLOTSETTITLE_COUNT")
		setupHook(INVENTORY_TOTAL_LIST_GET_HOOKED, "INVENTORY_TOTAL_LIST_GET")

		INVENTORY_TOTAL_LIST_GET(ui.GetFrame("inventory"))
	end
end

local function INVENTORYWEIGHT_SET_CHANGE(invItem, addCount)
	local obj = GetIES(invItem:GetObject())
	local ClassID = obj.ClassID

	local oldval = itemTbl[ClassID] or 0
	local remainInvItemCount = 0

	if obj.MaxStack == 1 then
		remainInvItemCount = oldval + addCount
	elseif addCount >= 0 then
		remainInvItemCount = GET_REMAIN_INVITEM_COUNT(invItem)
	end

	itemTbl[ClassID] = remainInvItemCount
	addWeight = (remainInvItemCount - oldval) * math.floor(obj.Weight * 10 + 0.5)
end

function INSERT_ITEM_TO_TREE_HOOKED(frame, tree, invItem, itemCls, baseidcls, ...)
	if reuseOldWeight then
		reuseOldWeight = false
	else
		reuseOldWeight = (string.sub(tree:GetName(), -4) ~= "_All")
		INVENTORYWEIGHT_SET_CHANGE(invItem, 1)
	end

	return hooks.INSERT_ITEM_TO_TREE(frame, tree, invItem, itemCls, baseidcls, ...)
end

function TEMP_INV_REMOVE_HOOKED(frame, itemGuid, ...)

    local invItem = session.GetInvItemByGuid(itemGuid);
    if invItem == nil then
        return;
    end

    local itemCls = GetClassByType("Item", invItem.type);
    local name = itemCls.ClassName;

	if name ~= "Vis" and name ~= "Feso" then
		INVENTORYWEIGHT_SET_CHANGE(invItem, -1)
	end

	return hooks.TEMP_INV_REMOVE(frame, itemGuid, ...)
end

function INV_SLOT_UPDATE_HOOKED(frame, invItem, itemSlot, ...)
	local ret = hooks.INV_SLOT_UPDATE(frame, invItem, itemSlot, ...)

	INVENTORYWEIGHT_SET_CHANGE(invItem, 0)
	if addWeight == 0 then
		return ret
	end

    local baseidcls = GET_BASEID_CLS_BY_INVINDEX(invItem.invIndex)
	local treegroupname = baseidcls.TreeGroup;

    local typeStr = GET_INVENTORY_TREEGROUP(baseidcls)
    local tree = GET_CHILD_RECURSIVELY(frame, 'inventree_' .. typeStr)
    local treegroup = tree:FindByValue(treegroupname);
    if tree:IsExist(treegroup) == 0 then
		return ret
    end
	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0)

    typeStr = "All"
    tree = GET_CHILD_RECURSIVELY(frame, 'inventree_'..typeStr)
    treegroup = tree:FindByValue(treegroupname);
    if tree:IsExist(treegroup) == 0 then
		return ret
    end

	SET_SLOTSETTITLE_COUNT(tree, baseidcls, 0)

	return ret
end

function SET_SLOTSETTITLE_COUNT_HOOKED(tree, baseidcls, addCount)

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
	local curWeight = textcls:GetUserIValue("TOTAL_WEIGHT")
    curCount = curCount + addCount;
	curWeight = curWeight + addWeight
    textcls:SetUserValue("TOTAL_COUNT", curCount);
	textcls:SetUserValue("TOTAL_WEIGHT", curWeight)
	textcls:SetText(string.format('{img btn_minus 20 20} %s (%d) (@dicID_^*$UI_20150317_000281$*^: %g)', baseidcls.TreeSSetTitle, curCount, curWeight/10))

    local hGroup = tree:FindByValue(baseidcls.TreeGroup);
    if hGroup ~= nil then
        local treeNode = tree:GetNodeByTreeItem(hGroup);
        local newCaption = treeNode:GetUserValue("BASE_CAPTION");
        local totalCount = treeNode:GetUserIValue("TOTAL_ITEM_COUNT");
		local totalWeight = treeNode:GetUserIValue("TOTAL_ITEM_WEIGHT")
        totalCount = totalCount + addCount;     
		totalWeight = totalWeight + addWeight
        treeNode:SetUserValue("TOTAL_ITEM_COUNT", totalCount);
		treeNode:SetUserValue("TOTAL_ITEM_WEIGHT", totalWeight)


        local isOptionApplied = CHECK_INVENTORY_OPTION_APPLIED(baseidcls)
        local isOptionAppliedText = ""
        if isOptionApplied == 1 then
            isOptionAppliedText = ClMsg("ApplyOption")
        end

		tree:SetItemCaption(hGroup,string.format("%s (%d) (@dicID_^*$UI_20150317_000281$*^: %g) %s", newCaption, totalCount, totalWeight/10, isOptionAppliedText))

    end
end

function INVENTORY_TOTAL_LIST_GET_HOOKED(frame, setpos, isIgnorelifticon, invenTypeStr, ...)
    local frame = ui.GetFrame("inventory")

    local liftIcon              = ui.GetLiftIcon();
    if nil == isIgnorelifticon then
        isIgnorelifticon = "NO";
    end
    
    if isIgnorelifticon ~= "NO" and liftIcon ~= nil then
        return
    end

	addWeight = 0
	reuseOldWeight = false
	itemTbl = {}
	return hooks.INVENTORY_TOTAL_LIST_GET(frame, setpos, isIgnorelifticon, invenTypeStr, ...)
end