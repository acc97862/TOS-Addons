--fletchercraftmod.lua

function FLETCHERCRAFTMOD_ON_INIT(addon, frame)
	if SET_ITEM_CRAFT_UINAME_HOOKED ~= SET_ITEM_CRAFT_UINAME then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
			end
			_G[hookedFunctionStr] = newFunction;
		end

		setupHook(SET_ITEM_CRAFT_UINAME_HOOKED, "SET_ITEM_CRAFT_UINAME");
	end
end

function SET_ITEM_CRAFT_UINAME_HOOKED(uiName)
	SET_ITEM_CRAFT_UINAME_OLD(uiName);
	if uiName == "itemcraft_fletching" then
		g_craftRecipe_detail_item = "craftRecipe_detail_item";
	end
end