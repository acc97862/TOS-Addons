--questdumper.lua

local loaded = false

function QUESTDUMPER_ON_INIT(addon, frame)
	if not loaded then
		addon:RegisterMsg("GAME_START_3SEC", "QUESTDUMPER_3SEC")
	end
end

function QUESTDUMPER_3SEC()
	loaded = true
	local acutil = require("acutil")
	CHAT_SYSTEM('[questdumper:help] /questdumper]')
	acutil.slashCommand("/questdumper", QUESTDUMPER_DUMP)
end

function QUESTDUMPER_DUMP()
	local tbl = {}
	local lvltbl = {}
	local txttbl = {string.format("Questlog of %s %s on %s\n", GETMYPCNAME(), GETMYFAMILYNAME(), os.date("%b %d %Y %X"))}
	local sObj = GET_MAIN_SOBJ()

	for i = 0, geQuestTable.GetQuestPropertyCount()-1 do
		if sObj[geQuestTable.GetQuestProperty(i)] == 300 then
			local questCls = GetIES(geQuestTable.GetQuestObject(i))
			local lvl = questCls.Level
			if tbl[lvl] == nil then
				tbl[lvl] = {}
				lvltbl[#lvltbl+1] = lvl
			end
			tbl[lvl][#tbl[lvl]+1] = dic.getTranslatedStr(questCls.Name)
		end
	end

	table.sort(lvltbl)

	local i = 1
	for s = 1, #lvltbl do
		local lvl = lvltbl[s]
		for t = 1, #tbl[lvl] do
			i = i+1
			txttbl[i] = lvl .. "\t" .. tbl[lvl][t]
		end
	end

	local file = io.open("../addons/questdumper/questlog.txt", "w")
	file:write(table.concat(txttbl, "\n"))
	file:flush()
	file:close()
end
