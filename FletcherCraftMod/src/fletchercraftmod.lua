--fletchercraftmod.lua

local hooks = {}

function FLETCHERCRAFTMOD_ON_INIT(addon, frame)
	if next(hooks) == nil then
		hooks.SET_ITEM_CRAFT_UINAME = SET_ITEM_CRAFT_UINAME
		SET_ITEM_CRAFT_UINAME = SET_ITEM_CRAFT_UINAME_HOOKED
	end
end

function SET_ITEM_CRAFT_UINAME_HOOKED(uiName, ...)
	local ret = hooks.SET_ITEM_CRAFT_UINAME(uiName, ...)
	if uiName == "itemcraft_fletching" then
		g_craftRecipe_detail_item = "craftRecipe_detail_item"
	end
	return ret
end