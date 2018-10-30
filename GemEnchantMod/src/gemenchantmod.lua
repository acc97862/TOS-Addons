--gemenchantmod.lua

local is_opened_msg_box = false
local item_obj = nil
local item_obj2 = nil;
local item_slot = nil;

local function get_exp_from_slot()
    local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"));
    local totalCount = 0
    local addExp = 0

    local cnt = slots:GetSlotCount();
    for i = 0 , cnt - 1 do
        local slot = slots:GetSlotByIndex(i);
        local icon = slot:GetIcon();
        local matItem, matItemcount = GET_SLOT_ITEM(slot);
        if matItem ~= nil then
            matItem = GetIES(matItem:GetObject());
            local matExp = matItemcount * GET_MIX_MATERIAL_EXP(matItem);
            addExp = addExp + matExp;           
        end
    end

    return addExp
end

local function get_item_level_exp(item, target_item, limit_level, count, current_slot_exp)
    local is_over = false
    local exceed_exp = 0
    local add_exp = target_item.ItemExp + current_slot_exp    
    local prop = geItemTable.GetProp(target_item.ClassID);
    local lv = 1
    for i = 1, count do        
        local exp = tonumber(GET_MIX_MATERIAL_EXP(item))
        add_exp = tonumber(math.add_for_lua(add_exp, exp))        
        lv = prop:GetLevel(add_exp)
        if lv >= limit_level then
            if prop:GetItemExp(GET_ITEM_MAX_LEVEL(target_item) - 1) == add_exp then
                is_over = false
            else
                exceed_exp = add_exp - prop:GetItemExp(GET_ITEM_MAX_LEVEL(target_item) - 1)
                is_over = true
            end
            return lv, i, is_over, exceed_exp
        end
    end
    return lv, count, is_over, exceed_exp
end

local function get_slot_exp_except_item(item)
    local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"))
    local cnt = slots:GetSlotCount()
    local addExp = 0

    for i = 0, cnt - 1 do
        local slot = slots:GetSlotByIndex(i)
        local matItem, matItemcount = GET_SLOT_ITEM(slot)
        if matItem ~= nil then            
            matItem = GetIES(matItem:GetObject());
            if matItem.ClassID ~= item.ClassID then
                local matExp = matItemcount * GET_MIX_MATERIAL_EXP(matItem);
                addExp = addExp + matExp;
            end
        end        
    end

    return addExp
end

local function get_reinforce_slot_index(item_class_id)
    local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"))
    local cnt = slots:GetSlotCount()

    for i = 0, cnt - 1 do
        local slot = slots:GetSlotByIndex(i)
        local matItem, matItemcount = GET_SLOT_ITEM(slot)
        if matItem ~= nil then            
            matItem = GetIES(matItem:GetObject());
            if matItem.ClassID == item_class_id then
                return i
            end
        end        
    end
    return -1
end

function GEMENCHANTMOD_ON_INIT(addon, frame)
	if OPEN_REINFORCE_BY_MIX_HOOKED ~= OPEN_REINFORCE_BY_MIX then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
			end
			_G[hookedFunctionStr] = newFunction;
		end

		setupHook(OPEN_REINFORCE_BY_MIX_HOOKED, "OPEN_REINFORCE_BY_MIX");
		setupHook(DECREASE_SELECTED_ITEM_COUNT_HOOKED, "DECREASE_SELECTED_ITEM_COUNT");
		setupHook(REMAIN_SELECTED_ITEM_COUNT_HOOKED, "REMAIN_SELECTED_ITEM_COUNT");
		setupHook(REINFORCE_MIX_INV_RBTN_HOOKED, "REINFORCE_MIX_INV_RBTN");
	end
end

function OPEN_REINFORCE_BY_MIX_HOOKED(frame)
    frame:SetUserValue("EXECUTE_REINFORCE", 0);
    CLEAR_REINFORCE_BY_MIX(frame);
    ui.OpenFrame("inventory");
    is_opened_msg_box = false
    item_obj = nil
end

function DECREASE_SELECTED_ITEM_COUNT_HOOKED(slot_index, nowselectedcount, count, inven_item_count, item_class_id)    
    is_opened_msg_box = false    
    local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"));
    local slot = slots:GetSlotByIndex(slot_index)
    local tgtItem = GET_REINFORCE_MIX_ITEM()

    count = count - 1    
    if count == 0 then
        local index = get_reinforce_slot_index(item_class_id)        
        local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"))
        REINFORCE_BY_MIX_SLOT_RBTN(nil, slots:GetSlotByIndex(index))
        return
    end
    if nowselectedcount  == count then
        if count <= inven_item_count then                
            local reinfFrame = ui.GetFrame("reinforce_by_mix");
            local icon = slot:GetIcon();            
            if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, item_obj, count)  then            
                imcSound.PlaySoundEvent("icon_get_down");
                if icon ~= nil and count == inven_item_count then                    
                    icon:SetColorTone("AA000000");
                end
            end
        end 
    else
        if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
            ui.SysMsg(ClMsg("ArriveInMaxLevel"))
            item_obj = nil
            return
        end

        if nowselectedcount < inven_item_count then            
            local reinfFrame = ui.GetFrame("reinforce_by_mix");
            local icon = slot:GetIcon();            
            if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, item_obj, nowselectedcount + 1)  then            
                imcSound.PlaySoundEvent("icon_get_down");
                local nowselectedcount = slot:GetUserIValue("REINF_MIX_SELECTED")                       
                if icon ~= nil and nowselectedcount == inven_item_count then                    
                    icon:SetColorTone("AA000000");
                end
            end
        end
    end
    item_obj = nil
end

function REMAIN_SELECTED_ITEM_COUNT_HOOKED(slot_index, nowselectedcount, count, inven_item_count)
    is_opened_msg_box = false
    local slots = GET_MAT_SLOT(ui.GetFrame("reinforce_by_mix"));
    local slot = slots:GetSlotByIndex(slot_index)
    local tgtItem = GET_REINFORCE_MIX_ITEM()

    if nowselectedcount + 1 == count then
        if count <= inven_item_count then                
            local reinfFrame = ui.GetFrame("reinforce_by_mix");
            local icon = slot:GetIcon();            
            if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, item_obj, count)  then            
                imcSound.PlaySoundEvent("icon_get_down");
                if icon ~= nil and count == inven_item_count then                    
                    icon:SetColorTone("AA000000");
                end
            end
        end 
    else
        if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
            ui.SysMsg(ClMsg("ArriveInMaxLevel"))
            item_obj = nil
            return
        end

        if nowselectedcount < inven_item_count then            
            local reinfFrame = ui.GetFrame("reinforce_by_mix");
            local icon = slot:GetIcon();            
            if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, item_obj, nowselectedcount + 1)  then            
                imcSound.PlaySoundEvent("icon_get_down");
                local nowselectedcount = slot:GetUserIValue("REINF_MIX_SELECTED")                       
                if icon ~= nil and nowselectedcount == inven_item_count then                    
                    icon:SetColorTone("AA000000");
                end
            end
        end
    end
    item_obj = nil
end

function REINFORCE_MIX_INV_RBTN_HOOKED(itemObj, slot, selectall)    
    local invitem = session.GetInvItemByGuid(GetIESID(itemObj))    
    if nil == invitem then        
        return;
    end

    if IS_KEY_ITEM(itemObj) == true or IS_KEY_MATERIAL(itemObj) == true or itemObj.ItemLifeTimeOver ~= 0 then
        ui.SysMsg(ClMsg("CanNotBeUsedMaterial"));
        return;
    end
    
    if IS_MECHANICAL_ITEM(itemObj) == true then
        ui.SysMsg(ClMsg("IS_MechanicalItem"));
        return;
    end

    local reinfItem = GET_REINFORCE_MIX_ITEM();
    local reinforceCls = GetClass("Reinforce", reinfItem.Reinforce_Type);
    if 1 == _G[reinforceCls.MaterialScript](reinfItem, itemObj) then
        if true == invitem.isLockState then
            ui.SysMsg(ClMsg("MaterialItemIsLock"));
            return;
        end

		if keyboard.IsKeyPressed("LSHIFT") == 1 then
			local maxCnt = invitem.count;
			item_obj2 = itemObj;
			item_slot = slot;
			INPUT_NUMBER_BOX(ui.GetFrame("reinforce_by_mix"), ScpArgMsg("InputCount"), "GEMENCHANTMOD_EXEC", maxCnt, 1, maxCnt, nil, nil, 1);
			return
		end

        local nowselectedcount = slot:GetUserIValue("REINF_MIX_SELECTED")
          
        if selectall == 'YES' then            
            nowselectedcount = invitem.count -1;
        end

        local exp = get_exp_from_slot()
        local lv = 1
        local tgtItem = GET_REINFORCE_MIX_ITEM()
        local lv = GET_ITEM_LEVEL_EXP(tgtItem, exp + tgtItem.ItemExp)
        if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
            ui.SysMsg(ClMsg("ArriveInMaxLevel"))            
            return
        end
        
        local lv, count, is_over, exceed_exp = get_item_level_exp(itemObj, tgtItem, GET_ITEM_MAX_LEVEL(tgtItem), nowselectedcount + 1, get_slot_exp_except_item(itemObj))
        nowselectedcount = count - 1
        
        if is_over == true then
            if is_opened_msg_box == false then    
                local noScp = string.format("DECREASE_SELECTED_ITEM_COUNT(%d, %d, %d, %d, %d)", slot:GetSlotIndex(), nowselectedcount, count, invitem.count, itemObj.ClassID)
                local yesScp = string.format("REMAIN_SELECTED_ITEM_COUNT(%d, %d, %d, %d)", slot:GetSlotIndex(), nowselectedcount, count, invitem.count)
                item_obj = itemObj
                ui.MsgBox(ScpArgMsg('ExceedExpOverMaxLevel{EXCEED_EXP}', "EXCEED_EXP", exceed_exp) , yesScp, noScp)
                is_opened_msg_box = true
            end            
        end
        
        if nowselectedcount + 1 == count then
            if count <= invitem.count then                
                local reinfFrame = ui.GetFrame("reinforce_by_mix");
                local icon = slot:GetIcon();            
                if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, itemObj, count)  then            
                    imcSound.PlaySoundEvent("icon_get_down");
                    slot:SetUserValue("REINF_MIX_SELECTED", count);
                    local count = slot:GetUserIValue("REINF_MIX_SELECTED")                      
                    if icon ~= nil and count == invitem.count then                    
                        icon:SetColorTone("AA000000");
                    end
                end
            end 
        else
            if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
                ui.SysMsg(ClMsg("ArriveInMaxLevel"))
                return
            end

            if nowselectedcount < invitem.count then
                local reinfFrame = ui.GetFrame("reinforce_by_mix");
                local icon = slot:GetIcon();            
                if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, itemObj, nowselectedcount + 1)  then            
                    imcSound.PlaySoundEvent("icon_get_down");
                    slot:SetUserValue("REINF_MIX_SELECTED", nowselectedcount + 1);
                    local nowselectedcount = slot:GetUserIValue("REINF_MIX_SELECTED")                       
                    if icon ~= nil and nowselectedcount == invitem.count then                    
                        icon:SetColorTone("AA000000");
                    end
                end
            end
        end
    end 
end

function GEMENCHANTMOD_EXEC(frame, ret)
	local nowselectedcount = tonumber(ret) - 1;
	local itemObj = item_obj2;
	local invitem = session.GetInvItemByGuid(GetIESID(itemObj));
	local slot = item_slot;
	item_obj2 = nil;
	item_slot = nil;

	local exp = get_exp_from_slot()
	local lv = 1
	local tgtItem = GET_REINFORCE_MIX_ITEM()
	local lv = GET_ITEM_LEVEL_EXP(tgtItem, exp + tgtItem.ItemExp)
	if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
		ui.SysMsg(ClMsg("ArriveInMaxLevel"))            
		return
	end
	
	local lv, count, is_over, exceed_exp = get_item_level_exp(itemObj, tgtItem, GET_ITEM_MAX_LEVEL(tgtItem), nowselectedcount + 1, get_slot_exp_except_item(itemObj))
	nowselectedcount = count - 1
	
	if is_over == true then
		if is_opened_msg_box == false then    
			local noScp = string.format("DECREASE_SELECTED_ITEM_COUNT(%d, %d, %d, %d, %d)", slot:GetSlotIndex(), nowselectedcount, count, invitem.count, itemObj.ClassID)
			local yesScp = string.format("REMAIN_SELECTED_ITEM_COUNT(%d, %d, %d, %d)", slot:GetSlotIndex(), nowselectedcount, count, invitem.count)
			item_obj = itemObj
			ui.MsgBox(ScpArgMsg('ExceedExpOverMaxLevel{EXCEED_EXP}', "EXCEED_EXP", exceed_exp) , yesScp, noScp)
			is_opened_msg_box = true
		end            
	end
	
	if nowselectedcount + 1 == count then
		if count <= invitem.count then                
			local reinfFrame = ui.GetFrame("reinforce_by_mix");
			local icon = slot:GetIcon();            
			if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, itemObj, count)  then            
				imcSound.PlaySoundEvent("icon_get_down");
				slot:SetUserValue("REINF_MIX_SELECTED", count);
				local count = slot:GetUserIValue("REINF_MIX_SELECTED")                      
				if icon ~= nil then                    
					if count == invitem.count then                    
						icon:SetColorTone("AA000000");
					else
						icon:SetColorTone("FFFFFFFF");
					end
				end
			end
		end 
	else
		if lv == GET_ITEM_MAX_LEVEL(tgtItem) then
			ui.SysMsg(ClMsg("ArriveInMaxLevel"))
			return
		end

		if nowselectedcount < invitem.count then
			local reinfFrame = ui.GetFrame("reinforce_by_mix");
			local icon = slot:GetIcon();            
			if 1 == REINFORCE_BY_MIX_ADD_MATERIAL(reinfFrame, itemObj, nowselectedcount + 1)  then            
				imcSound.PlaySoundEvent("icon_get_down");
				slot:SetUserValue("REINF_MIX_SELECTED", nowselectedcount + 1);
				local nowselectedcount = slot:GetUserIValue("REINF_MIX_SELECTED")                       
				if icon ~= nil then
					if nowselectedcount == invitem.count then                    
						icon:SetColorTone("AA000000");
					else
						icon:SetColorTone("FFFFFFFF");
					end
				end
			end
		end
	end
end