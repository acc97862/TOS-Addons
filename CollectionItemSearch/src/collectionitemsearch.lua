--collectionitemsearch.lua

local hooks = {}
local collcls = nil

function COLLECTIONITEMSEARCH_ON_INIT(addon, frame)
	if next(hooks) == nil then
		hooks.CHECK_COLLECTION_INFO_FILTER = CHECK_COLLECTION_INFO_FILTER
		hooks.GET_COLLECTION_MAGIC_DESC = GET_COLLECTION_MAGIC_DESC
		CHECK_COLLECTION_INFO_FILTER = CHECK_COLLECTION_INFO_FILTER_HOOKED
		GET_COLLECTION_MAGIC_DESC = GET_COLLECTION_MAGIC_DESC_HOOKED
	end
end

function CHECK_COLLECTION_INFO_FILTER_HOOKED(collectionInfo, searchText, collectionClass, collection, ...)
	collcls = collectionClass
	local ret = {hooks.CHECK_COLLECTION_INFO_FILTER(collectionInfo, searchText, collectionClass, collection, ...)}
	collcls = nil
	return unpack(ret)
end

function GET_COLLECTION_MAGIC_DESC_HOOKED(...)
	local ret = {hooks.GET_COLLECTION_MAGIC_DESC(...)}
	if collcls ~= nil then
		local num = 1
		while true do
			local itemName = TryGetProp(collcls, "ItemName_" .. num)
			if itemName == nil or itemName == "None" then
				break
			end
			num = num + 1
			ret[num] = string.lower(dic.getTranslatedStr(GetClass("Item", itemName).Name))
		end
	end
	return table.concat(ret, "{nl}")
end