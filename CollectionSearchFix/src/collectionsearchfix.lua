--collectionsearchfix.lua

REMOVE_ITEM_SKILL = 7

local collectionStatus = {
    isNormal = 0,			-- 기본
	isNew  = 1,				-- 새로등록됨
	isComplete = 2,			-- 완성
	isAddAble = 3			-- 수집가능
};

local collectionView = {
    isUnknown  = 0,			-- 미확인
	isIncomplete = 1,		-- 미완성
	isComplete = 2,			-- 완성
};

local collectionSortTypes = {
	default = 0,			-- 기본값: 기본 콜렉션 순서
	name = 1,				-- 이름순: 콜렉션의 이름순서
	status = 2				-- 상태  : 기본(0), 새로등록(1), 완성(2), 수집가능(3) << 수치가 높을수록 아래로감 >>
};

local collectionViewOptions = {
	showCompleteCollections = true,
	showUnknownCollections = false,
	showIncompleteCollections = true,
	sortType = collectionSortTypes.default
};

local collectionViewCount = {
	showCompleteCollections = 0,
	showUnknownCollections = 0,
	showIncompleteCollections = 0
};

function COLLECTIONSEARCHFIX_ON_INIT(addon, frame)
	if COLLECTION_TYPE_CHANGE_HOOKED ~= COLLECTION_TYPE_CHANGE then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
				_G[hookedFunctionStr] = newFunction;
			else
				_G[hookedFunctionStr] = newFunction;
			end
		end

		setupHook(COLLECTION_TYPE_CHANGE_HOOKED, "COLLECTION_TYPE_CHANGE");
		setupHook(UPDATE_COLLECTION_LIST_HOOKED, "UPDATE_COLLECTION_LIST");
		setupHook(CHECK_COLLECTION_INFO_FILTER_HOOKED, "CHECK_COLLECTION_INFO_FILTER");
		setupHook(UPDATE_COLLECTION_OPTION_HOOKED, "UPDATE_COLLECTION_OPTION");
		setupHook(GET_COLLECTION_INFO_HOOKED, "GET_COLLECTION_INFO");
		setupHook(VIEW_COLLECTION_ALL_STATUS_HOOKED, "VIEW_COLLECTION_ALL_STATUS");
	end
end

-- 콜렉션 정렬 드롭다운리스트 갱신
function COLLECTION_TYPE_CHANGE_HOOKED(frame, ctrl)
	
	local alignoption = tolua.cast(ctrl, "ui::CDropList");
	if alignoption ~= nil then
		collectionViewOptions.sortType  = alignoption:GetSelItemIndex();
	end
	
	local topFrame = frame:GetTopParentFrame();
	if topFrame ~= nil then
		UPDATE_COLLECTION_LIST(topFrame);
	end
end

function UPDATE_COLLECTION_LIST_HOOKED(frame, addType, removeType)
	
	-- frame이 활성중이 아니면 return
	if frame:IsVisible() == 0 then
		return;
	end
	
	-- collection gbox
	local col = GET_CHILD_RECURSIVELY(frame, "gb_col", "ui::CGroupBox");
	if col == nil then
		return;
	end
	
	-- check box
	local gbox_status = GET_CHILD_RECURSIVELY(frame,"gb_status", "ui::CGroupBox");
	if gbox_status == nil then
		return;
	end
	
	local chkComplete = GET_CHILD(gbox_status, "optionComplete", "ui::CCheckBox");
	local chkUnknown = GET_CHILD(gbox_status, "optionUnknown", "ui::CCheckBox");
	local chkIncomplete = GET_CHILD(gbox_status, "optionIncomplete", "ui::CCheckBox");
	
	if chkComplete == nil or chkUnknown == nil or chkIncomplete == nil then
		return ;
	end
	
	-- 콜렉션 상태 Check
	chkComplete:SetCheck(BOOLEAN_TO_NUMBER(collectionViewOptions.showCompleteCollections));
	chkUnknown:SetCheck(BOOLEAN_TO_NUMBER(collectionViewOptions.showUnknownCollections));
	chkIncomplete:SetCheck(BOOLEAN_TO_NUMBER(collectionViewOptions.showIncompleteCollections));

	---- 초기화
	-- 그룹박스내의 DECK_로 시작하는 항목들을 제거
	DESTROY_CHILD_BYNAME(col, 'DECK_');

	-- 콜렉션 VIEW 카운터 초기화
	collectionViewCount.showCompleteCollections = 0 ;
	collectionViewCount.showUnknownCollections = 0 ;
	collectionViewCount.showIncompleteCollections = 0;


	-- 콜렉션 정보를 만듬
	local pc = session.GetMySession();
	local collectionList = pc:GetCollection();
	local collectionClassList, collectionClassCount= GetClassList("Collection");
	local searchText = GET_COLLECTION_SEARCH_TEXT(frame);
	local etcObject = GetMyEtcObject();


	-- 보여줄 콜렉션 리스트를 만듬
	local collectionCompleteMagicList ={}; -- 완료된 총 효과 리스트.
	local collectionInfoList = {};
	local collectionInfoIndex = 1;
	for i = 0, collectionClassCount - 1 do
		local collectionClass = GetClassByIndexFromList(collectionClassList, i);
		local collection = collectionList:Get(collectionClass.ClassID);
		local collectionInfo = GET_COLLECTION_INFO(collectionClass, collection,etcObject, collectionCompleteMagicList);
		if CHECK_COLLECTION_INFO_FILTER(collectionInfo, searchText, collectionClass, collection) == true then
		    -- data input
			collectionInfoList[collectionInfoIndex] = {cls = collectionClass, 
													   coll = collection, 
													   info = collectionInfo };
			collectionInfoIndex = collectionInfoIndex +1;
		end
	end
	
	-- 콜렉션 효과 목록을 날려줌.
	SET_COLLECTION_MAIGC_LIST(frame, collectionCompleteMagicList, collectionViewCount.showCompleteCollections ) -- 활성화되어 있지 않다면 그냥반환.
	
	-- 콜렉션 상태 카운터 적용
	chkComplete:SetTextByKey("value", collectionViewCount.showCompleteCollections);
	chkUnknown:SetTextByKey("value", collectionViewCount.showUnknownCollections);
	chkIncomplete:SetTextByKey("value", collectionViewCount.showIncompleteCollections);

	-- sort option 적용
	if collectionViewOptions.sortType == collectionSortTypes.name then
		table.sort(collectionInfoList, SORT_COLLECTION_BY_NAME);
	elseif collectionViewOptions.sortType == collectionSortTypes.status then
		table.sort(collectionInfoList, SORT_COLLECTION_BY_STATUS);
	end
	
	-- 콜렉션 항목 입력
	local posY = 0;
	for index , v in pairs(collectionInfoList) do
		local ctrlSet = col:CreateOrGetControlSet('collection_deck', "DECK_" .. index, 0, posY );
		ctrlSet:ShowWindow(1);
		posY = SET_COLLECTION_SET(frame, ctrlSet, v.cls.ClassID, v.coll, posY) 
		posY = posY -tonumber(frame:GetUserConfig("DECK_SPACE")); -- 가까이 붙이기 위해 좀더 위쪽으로땡김
	end

	if addType ~= "UNEQUIP" and REMOVE_ITEM_SKILL ~= 7 then
		imcSound.PlaySoundEvent("quest_ui_alarm_2");
	end
end

-- 콜렉션 view를 카운트하고 필터도 검사한다.
function CHECK_COLLECTION_INFO_FILTER_HOOKED(collectionInfo,  searchText,  collectionClass, collection)

	-- view counter
	local checkOption = 0;
	if collectionInfo.view == collectionView.isUnknown then	
		-- 미확인
		collectionViewCount.showUnknownCollections = collectionViewCount.showUnknownCollections +1;
		checkOption = 1;
	elseif collectionInfo.view == collectionView.isComplete then 
		-- 완성
		collectionViewCount.showCompleteCollections = collectionViewCount.showCompleteCollections +1;
		checkOption = 2;
	else
		-- 미완성
		collectionViewCount.showIncompleteCollections = collectionViewCount.showIncompleteCollections +1;
		checkOption = 3;
	end
	
	-- option filter
	---- unknown
	if collectionViewOptions.showUnknownCollections == false and  checkOption == 1 then
		return false;
	end
	---- complete
	if collectionViewOptions.showCompleteCollections == false and  checkOption == 2 then
		return false;
	end
	---- incomplete
	if collectionViewOptions.showIncompleteCollections == false and  checkOption == 3 then
		return false;
	end


	-- text filter
	--- 검색문자열이 없거나 길이가 0이면 true리턴
	if searchText == nil or string.len(searchText) == 0 then
		return true;
	end

	-- 콜렉션 이름을 가져온다
	local collectionName = dictionary.ReplaceDicIDInCompStr(collectionInfo.name);
	collectionName = string.lower(collectionName); -- 소문자로 변경
	-- 콜렉션 효과에서도 필터링한다.
	local desc = dictionary.ReplaceDicIDInCompStr(GET_COLLECTION_MAGIC_DESC(collectionClass.ClassID));
	desc = string.lower(desc); -- 소문자로 변경

	-- 검색문자열 검색해서 nil이면 false
	if string.find(collectionName, searchText) == nil and string.find(desc, searchText) == nil then
		local collectionList = session.GetMySession():GetCollection();
		curCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collectionList:Get(collectionClass.ClassID));
		for num = 1, maxCount do
			local itemName = TryGetProp(collectionClass, "ItemName_" .. num);
			if itemName == nil or itemName == "None" then
				return false;
			end
			local name = dictionary.ReplaceDicIDInCompStr(GetClass("Item", itemName).Name);
			name = string.lower(name);
			if string.find(name, searchText) ~= nil then
				return true;
			end
		end
		return false;
	end 
	
	return true;
end

-- 옵션체크
function UPDATE_COLLECTION_OPTION_HOOKED(parent, ctrl)
	local frame = parent:GetTopParentFrame();
	if frame == nil then
	 return 
	end
	
	-- check box
	local gbox_status = GET_CHILD_RECURSIVELY(frame,"gb_status", "ui::CGroupBox");
	if gbox_status == nil then
		return;
	end

	local chkComplete = GET_CHILD(gbox_status, "optionComplete", "ui::CCheckBox");
	local chkUnknown = GET_CHILD(gbox_status, "optionUnknown", "ui::CCheckBox");
	local chkIncomplete = GET_CHILD(gbox_status, "optionIncomplete", "ui::CCheckBox");
	
	if chkComplete == nil or chkUnknown == nil or chkIncomplete == nil then
		return ;
	end

	collectionViewOptions.showCompleteCollections = NUMBER_TO_BOOLEAN(chkComplete:IsChecked());
	collectionViewOptions.showUnknownCollections = NUMBER_TO_BOOLEAN(chkUnknown:IsChecked());
	collectionViewOptions.showIncompleteCollections = NUMBER_TO_BOOLEAN(chkIncomplete:IsChecked());

	UPDATE_COLLECTION_LIST(frame);
end

-- 콜렉션 정보를 리턴.
function GET_COLLECTION_INFO_HOOKED(collectionClass, collection, etcObject, collectionCompleteMagicList)
	-- view 
	local curCount, maxCount = GET_COLLECTION_COUNT(collectionClass.ClassID, collection);
	local collView = collectionView.isIncomplete;
	if collection == nil then
		collView = collectionView.isUnknown;
	elseif curCount >= maxCount then 
		collView = collectionView.isComplete;
	end

	-- status
	local cls = GetClassByType("Collection", collectionClass.ClassID);	
	local isread = TryGetProp(etcObject, 'CollectionRead_' .. cls.ClassID);
	local addNumCnt= GET_COLLECT_ABLE_ITEM_COUNT(collection,collectionClass.ClassID);
	local collStatus = collectionStatus.isNormal;

	if curCount >= maxCount then	-- 컴플리트
		collStatus = collectionStatus.isComplete;
		-- complete 상태면 magicList에 추가해줌.
		ADD_MAGIC_LIST(collectionClass.ClassID, collection, collectionCompleteMagicList );
	elseif isread == nil or isread == 0 then	-- 읽지 않음(new) etcObj의 항목에 1이 들어있으면 읽었다는 뜻.		
		if collection ~= nil then -- 미확인 상태가 아닐때만 new를 입력
			collStatus = collectionStatus.isNew;
		end
	end

	-- 위에 new/complete를 체크했는데 기본값이며 추가가능한지 확인. 이렇게 안하면 미확인에서 정렬 제대로 안됨.
	if collStatus == collectionStatus.isNormal then
		-- cnt가 0보다 크면 num아이콘활성화
		if addNumCnt > 0 then
			collStatus = collectionStatus.isAddAble;
		end
	end

	
	-- name
	local collectionName =  cls.Name;
	collectionName = string.gsub(collectionName, ClMsg("CollectionReplace"), ""); -- "콜렉션:" 을 공백으로 치환한다.
	
	
	return { 
			 name = collectionName,		-- "콜렉션:" 이 제거된 이름
			 status = collStatus,		-- 콜렉션 상태
			 view = collView,			-- 콜랙션 보여주기 상태
			 addNum = addNumCnt			-- 추가 가능한 아이템 개수.
			};
end

-- 총 효과보기 버튼 클릭시.
function VIEW_COLLECTION_ALL_STATUS_HOOKED(parent, ctrl)
	local frame = parent:GetTopParentFrame();
	if frame == nil then
	 return 
	end
	
	-- 콜렉션 VIEW 카운터 초기화
	collectionViewCount.showCompleteCollections = 0 ;
	collectionViewCount.showUnknownCollections = 0 ;
	collectionViewCount.showIncompleteCollections = 0;

	-- 콜렉션 정보를 만듬
	local pc = session.GetMySession();
	local collectionList = pc:GetCollection();
	local collectionClassList, collectionClassCount= GetClassList("Collection");
	local etcObject = GetMyEtcObject();


	-- 효과 리스트를 갱신
	local collectionCompleteMagicList ={}; -- 완료된 총 효과 리스트.
	for i = 0, collectionClassCount - 1 do
		local collectionClass = GetClassByIndexFromList(collectionClassList, i);
		local collection = collectionList:Get(collectionClass.ClassID);
		local collectionInfo = GET_COLLECTION_INFO(collectionClass, collection,etcObject, collectionCompleteMagicList);
		CHECK_COLLECTION_INFO_FILTER(collectionInfo, "", collectionClass,collection); -- 콜렉션 완료 개수를 카운트하기 위해 호출
	end
	
	-- 콜렉션 효과 목록을 날려줌.
	SET_COLLECTION_MAIGC_LIST(frame, collectionCompleteMagicList, collectionViewCount.showCompleteCollections) -- 활성화되어 있지 않다면 그냥반환.

	COLLECTION_MAGIC_OPEN(frame);
end