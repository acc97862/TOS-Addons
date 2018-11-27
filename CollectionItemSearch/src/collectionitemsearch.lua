--collectionitemsearch.lua

local collcls = nil;

function COLLECTIONITEMSEARCH_ON_INIT(addon, frame)
	if CHECK_COLLECTION_INFO_FILTER_HOOKED ~= CHECK_COLLECTION_INFO_FILTER then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
				_G[hookedFunctionStr] = newFunction;
			else
				_G[hookedFunctionStr] = newFunction;
			end
		end

		setupHook(CHECK_COLLECTION_INFO_FILTER_HOOKED, "CHECK_COLLECTION_INFO_FILTER");
		setupHook(GET_COLLECTION_MAGIC_DESC_HOOKED, "GET_COLLECTION_MAGIC_DESC");
	end
end

function CHECK_COLLECTION_INFO_FILTER_HOOKED(collectionInfo, searchText, collectionClass, collection)
	collcls = collectionClass;
	local ret = CHECK_COLLECTION_INFO_FILTER_OLD(collectionInfo, searchText, collectionClass, collection);
	collcls = nil;
	return ret
end

function GET_COLLECTION_MAGIC_DESC_HOOKED(type)
	local ret = GET_COLLECTION_MAGIC_DESC_OLD(type);
	if collcls ~= nil then
		local num = 0;
		while true do
			num = num + 1;
			local itemName = TryGetProp(collcls, "ItemName_" .. num);
			if itemName == nil or itemName == "None" then
				break
			end
			ret = ret .. "{nl}" .. string.lower(dic.getTranslatedStr(GetClass("Item", itemName).Name));
		end
	end
	return ret
end