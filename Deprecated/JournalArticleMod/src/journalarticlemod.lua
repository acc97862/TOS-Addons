--journalarticlemod.lua

local MAX_LINES_PER_PAGE = 200;
local curviewing;
local curpage;
local viewtype;
local viewpage;
local article_tbl = {quest = {}, npc = {}, collection = {}, achieve = {}, mission = {}};

function JOURNALARTICLEMOD_ON_INIT(addon, frame)
	if CREATE_JOURNAL_ARTICLE_CONTENTS_HOOKED ~= CREATE_JOURNAL_ARTICLE_CONTENTS then
		local function setupHook(newFunction, hookedFunctionStr)
			local storeOldFunc = hookedFunctionStr .. "_OLD";
			if _G[storeOldFunc] == nil then
				_G[storeOldFunc] = _G[hookedFunctionStr];
				_G[hookedFunctionStr] = newFunction;
			else
				_G[hookedFunctionStr] = newFunction;
			end
		end

		setupHook(CREATE_JOURNAL_ARTICLE_CONTENTS_HOOKED, "CREATE_JOURNAL_ARTICLE_CONTENTS");
		setupHook(JOURNAL_CONTENTS_QUEST_HOOKED, "JOURNAL_CONTENTS_QUEST");
		setupHook(JOURNAL_CONTENTS_NPC_HOOKED, "JOURNAL_CONTENTS_NPC");
		setupHook(JOURNAL_CONTENTS_COLLECTION_HOOKED, "JOURNAL_CONTENTS_COLLECTION");
		setupHook(JOURNAL_CONTENTS_ACHIEVE_HOOKED, "JOURNAL_CONTENTS_ACHIEVE");
		setupHook(JOURNAL_CONTENTS_MGAME_HOOKED, "JOURNAL_CONTENTS_MGAME");
	end
end

local function JOURNALARTICLEMOD_CREATE_OBJECTS(frame, queue)
	local groupbox = queue:CreateOrGetControl('groupbox', 'groupbox', 0, 0, 550, 40);
	groupbox:SetSkinName("");

	viewtype = groupbox:CreateOrGetControl("droplist", "viewtype", 30, 0, 200, 40);
	tolua.cast(viewtype, "ui::CDropList");
	viewtype:SetSkinName("droplist_normal2");
	viewtype:AddItem("quest",  ClMsg("Quest"), 0);
	viewtype:AddItem("npc",  "NPC", 0);
	viewtype:AddItem("collection",  ClMsg("Collection"), 0);
	viewtype:AddItem("achieve",  ClMsg("Achieve"), 0);
	viewtype:AddItem("mission",  ClMsg("Mission"), 0);
	viewtype:SelectItem(0);
	curviewing = "quest";
	viewtype:SetVisibleLine(5);
	viewtype:SetSelectedScp("JOURNALARTICLEMOD_SEL_DROPLIST");

	viewpage = groupbox:CreateOrGetControl("droplist", "viewpage", 300, 0, 100, 40);
	tolua.cast(viewpage, "ui::CDropList");
	viewpage:SetSkinName("droplist_normal2");
	viewpage:AddItem(1, 1, 0);
	curpage = 1;
	viewpage:SelectItem(0);
	viewpage:SetSelectedScp("JOURNALARTICLEMOD_SEL_DROPLIST");

	local boxheight = frame:GetChild("contents"):GetHeight();
	local subctrlset = queue:CreateControlSet('journal_contents', "subctrlset", 10, 0);
	DESTROY_CHILD_BYNAME(subctrlset, "sub_");
	subctrlset:Resize(subctrlset:GetWidth(), boxheight-165);
	local textbox = subctrlset:CreateOrGetControl("textview", "textbox", 10, 70, 510, boxheight-240);
	textbox:SetAlpha(0);
end

function CREATE_JOURNAL_ARTICLE_CONTENTS_HOOKED(frame, grid, key, text, iconImage, callback)

	CREATE_JOURNAL_ARTICLE(frame, grid, key, text, iconImage, callback);
	local group = GET_CHILD(frame, 'contents', 'ui::CGroupBox');
	group:SetUserValue("CATEGORY", "Contents");

	local queue = group:CreateOrGetControl('queue', 'queue', 0, 0, ui.NONE_HORZ, ui.TOP, 20, 50, 0, 0);
	queue = tolua.cast(queue, "ui::CQueue");
	queue:SetSpaceY(15);
	queue:SetSkinName("None");
	queue:SetBorder(0, 10, 10, 0);
	queue:RemoveAllChild();

	JOURNALARTICLEMOD_CREATE_OBJECTS(frame, queue);

	local totalScore = 0;
	totalScore = totalScore + JOURNAL_CONTENTS_QUEST(frame, group);
	totalScore = totalScore + JOURNAL_CONTENTS_NPC(frame, group);
	totalScore = totalScore + JOURNAL_CONTENTS_COLLECTION(frame, group);
	totalScore = totalScore + JOURNAL_CONTENTS_ACHIEVE(frame, group);
	totalScore = totalScore + JOURNAL_CONTENTS_MGAME(frame, group);

	local ctrlset = group:GetChild("ctrlset");
	ctrlset:GetChild("scoretext"):SetTextByKey("score", totalScore);

	group:UpdateData();
	JOURNALARTICLEMOD_REFRESH(frame, true);
	group:Invalidate();
end

function JOURNALARTICLEMOD_SEL_DROPLIST(frame, ctrl)
	local topFrame = frame:GetTopParentFrame();
	local viewing = viewtype:GetSelItemKey();
	local page = tonumber(viewpage:GetSelItemKey());
	if topFrame ~= nil then
		if curviewing ~= viewing then
			curviewing = viewing;
			curpage = 1;
			JOURNALARTICLEMOD_REFRESH(topFrame, true);
		elseif curpage ~= page then
			curpage = page;
			JOURNALARTICLEMOD_REFRESH(topFrame);
		end
	end
end

function JOURNALARTICLEMOD_REFRESH(frame, newviewing)
	local subctrlset = GET_CHILD_RECURSIVELY(frame, "subctrlset", "ui::CGroupBox");
	tolua.cast(viewpage, "ui::CDropList");
	local textbox = subctrlset:GetChild("textbox");
	tolua.cast(textbox, "ui::CTextView");
	local tbl = article_tbl[curviewing];

	if newviewing then
		viewpage:ClearItems();
		for  v = 1, math.max(1, math.ceil(#tbl["text"]/MAX_LINES_PER_PAGE)) do
			viewpage:AddItem(v, v, 0);
		end
		viewpage:SelectItem(0);
		subctrlset:GetChild("scoretext"):SetTextByKey("score", tbl["point"]);
		subctrlset:GetChild("title"):SetTextByKey("categoryname", tbl["category"]);
		subctrlset:GetChild("totaltext"):SetTextByKey("text", tbl["countText"]);
	end

	if textbox ~= nil then
		textbox:Clear();
		if curviewing == "quest" or curviewing == "npc" then
			local form;
			viewpage:SetVisible(1);

			if curviewing == "quest" then
				form = "[%3d] %s";
			else
				form = "[%s] %s";
			end

			for line = (curpage-1)*MAX_LINES_PER_PAGE+1, curpage*MAX_LINES_PER_PAGE do
				local t = tbl["text"][line];
				if t ~= nil then
					textbox:AddText(string.format(form, t.k, t.v), "white_20_ol");
				else
					break;
				end
			end
			textbox:InitScrollPos();
		else
			viewpage:SetVisible(0);
		end
	end
end

function JOURNAL_CONTENTS_QUEST_HOOKED(frame, group)

	local sObj = GET_MAIN_SOBJ();
	local endCount = GET_END_QUEST_COUNT(sObj);
	local point = session.GetMyWikiScore(WIKI_QUEST);
	local tbl = {};
	local keytbl = {};

	local cnt = geQuestTable.GetQuestPropertyCount();
	for i = 0 , cnt - 1 do
		local propName = geQuestTable.GetQuestProperty(i);
		if sObj[propName] == 300 then
			local questCls = GetIES(geQuestTable.GetQuestObject(i));
			local lvl = questCls.Level;
			if not tbl[lvl] then
				tbl[lvl] = {};
				table.insert(keytbl, lvl);
			end
			table.insert(tbl[lvl], dictionary.ReplaceDicIDInCompStr(questCls.Name));
		end
	end

	table.sort(keytbl);
	article_tbl["quest"]["text"] = {};

	for t1 = 1, #keytbl do
		local k = keytbl[t1];
		for t2 = 1, #tbl[k] do
			table.insert(article_tbl["quest"]["text"], {k = k, v = tbl[k][t2]});
		end
	end

	article_tbl["quest"]["point"] = point;
	article_tbl["quest"]["category"] = ClMsg("Quest");
	article_tbl["quest"]["countText"] = ScpArgMsg("QuestClear_{Auto_1}_Count", "Auto_1", endCount);

	return point;
end

function JOURNAL_CONTENTS_NPC_HOOKED(frame, group)

	local pc = GetMyPCObject();
	local npcCount = GetNPCStateCount(pc);
	local point = session.GetMyWikiScore(WIKI_NPC);
	local tbl = {};
	local keytbl = {};

	local npcStates = session.GetNPCStateMap();
	local idx = npcStates:Head();
	while idx ~= npcStates:InvalidIndex() do

		local isExit = false;
		local mapName = npcStates:KeyPtr(idx):c_str();
		local mapCls = GetClass("Map", mapName);
		local npcList = npcStates:Element(idx);

		local npcIdx = npcList:Head();
		while npcIdx ~= npcList:InvalidIndex() do

			local type = npcList:Key(npcIdx);
			local genCls = GetGenTypeClass(mapName, type);

			if nil == genCls then
				break;
			end;

			npcIdx = npcList:Next(npcIdx);
			local name = GET_GENCLS_NAME(genCls);

			if string.find(name, '{nl}') ~= nil then
			    name = string.gsub(name, '{nl}',' ')
			    while 1 do
			        if string.find(name, '  ') ~= nil then
			            name = string.gsub(name, '  ',' ')
			        else
			            break;
			        end
			    end
			end

			local mapname = dictionary.ReplaceDicIDInCompStr(mapCls.Name);
			if not tbl[mapname] then
				tbl[mapname] = {};
				table.insert(keytbl, mapname);
			end
			table.insert(tbl[mapname], dictionary.ReplaceDicIDInCompStr(name));
		end

		if true == isExit then
			break;
		end

		idx = npcStates:Next(idx);
	end

	table.sort(keytbl);
	article_tbl["npc"]["text"] = {};

	for t1 = 1, #keytbl do
		local k = keytbl[t1];
		for t2 = 1, #tbl[k] do
			table.insert(article_tbl["npc"]["text"], {k = k, v = tbl[k][t2]});
		end
	end

	article_tbl["npc"]["point"] = point;
	article_tbl["npc"]["category"] = "NPC";
	article_tbl["npc"]["countText"] = ScpArgMsg("NPC_Meet_{Auto_1}_People", "Auto_1", npcCount);

	return point;
end

function JOURNAL_CONTENTS_COLLECTION_HOOKED(frame, group)

	local colls = session.GetMySession():GetCollection();
	local cnt = colls:Count();
	local satisCnt = colls:GetStatisfiedCount();
	local point = GET_WIKI_POINT_COLLECTION(cnt, satisCnt);
	local msg = ScpArgMsg("HaveCollection_{Auto_1}", "Auto_1", cnt) .. "{nl}" .. ScpArgMsg("CompleteCollection_{Auto_1}", "Auto_1", satisCnt);

	article_tbl["collection"]["point"] = point;
	article_tbl["collection"]["category"] = ClMsg("Collection");
	article_tbl["collection"]["countText"] = msg;
	article_tbl["collection"]["text"] = {};
	return point;
end

function JOURNAL_CONTENTS_ACHIEVE_HOOKED(frame, group)
	local pc = GetMyPCObject();
	local point = session.GetMyWikiScore(WIKI_ACHIEVE);
	local cnt, ncnt = GetAchieveCount(pc);

	article_tbl["achieve"]["point"] = point;
	article_tbl["achieve"]["category"] = ClMsg("Achieve");
	article_tbl["achieve"]["countText"] = ScpArgMsg("HaveAchieve_{Auto_1}", "Auto_1", cnt + ncnt);
	article_tbl["achieve"]["text"] = {};
	return point;
end

function JOURNAL_CONTENTS_MGAME_HOOKED(frame, group)
	local pc = GetMyPCObject();
	local point = session.GetMyWikiScore(WIKI_MGAME);
	local haveCnt = GetWikiListCountByCategory("MGame");
	local dd = ScpArgMsg("Clear_Mission{Auto_1}", "Auto_1", haveCnt);
	article_tbl["mission"]["point"] = point;
	article_tbl["mission"]["category"] = ClMsg("Mission");
	article_tbl["mission"]["countText"] = ScpArgMsg("Clear_Mission{Auto_1}", "Auto_1", haveCnt);
	article_tbl["mission"]["text"] = {};
	return point;
end
