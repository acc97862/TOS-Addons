local loaded = false;

function QUESTDUMPER_ON_INIT(addon, frame)
	if not loaded then
		addon:RegisterMsg("GAME_START_3SEC", "QUESTDUMPER_3SEC");
	end
end

function QUESTDUMPER_3SEC()
	loaded = true;
	local acutil = require("acutil");
	CHAT_SYSTEM('[questdumper:help] /questdumper]');
	acutil.slashCommand("/questdumper", QUESTDUMPER_DUMP);
end

function QUESTDUMPER_DUMP()
	local tbl = {};
	local txt = string.format("Questlog of %s %s on %s\n", GETMYPCNAME(), GETMYFAMILYNAME(), os.date("%b %d %Y %X"))
	local sObj = GET_MAIN_SOBJ();

	for i = 0, geQuestTable.GetQuestPropertyCount()-1 do
		if sObj[geQuestTable.GetQuestProperty(i)] == 300 then
			questCls = GetIES(geQuestTable.GetQuestObject(i));
			if not tbl[questCls.Level] then
				tbl[questCls.Level] = {}
			end
			table.insert(tbl[questCls.Level], dictionary.ReplaceDicIDInCompStr(questCls.Name))
		end
	end

	for k, t in pairs(tbl) do
		for _, v in pairs(t) do
			txt = txt .. "\n" .. k .. "\t" .. v
		end
	end

	local file = io.open("../addons/questdumper/questlog.txt", "w")
	file:write(txt)
	file:close()
end