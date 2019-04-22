--statget.lua

local loaded = false
local statget = {}

statget.MHP = function(self)
    local monHPCount = TryGetProp(self, "HPCount", 0);
    if monHPCount > 0 then
        return monHPCount--math.floor(monHPCount);
    end
    
    local fixedMHP = TryGetProp(self, "FIXMHP_BM", 0);
    if fixedMHP > 0 then
        return fixedMHP--math.floor(fixedMHP);
    end
    
    local lv = TryGetProp(self, "Lv", 1);
    
    
    
    local standardMHP = math.max(30, lv);
    local byLevel = (standardMHP / 4) * lv;
    
    local stat = TryGetProp(self, "CON", 1);
    
    local byStat = (byLevel * (stat * 0.0015)) + (byLevel * (math.floor(stat / 10) * 0.005));
    
    local value = standardMHP + byLevel + byStat;
    
    local statTypeRate = 100;
    local statType = TryGetProp(self, "StatType", "None");
    if statType ~= nil and statType ~= 'None' then
        local statTypeClass = GetClass("Stat_Monster_Type", statType);
        if statTypeClass ~= nil then
            statTypeRate = TryGetProp(statTypeClass, "MHP", statTypeRate);
        end
    end
    
    statTypeRate = statTypeRate / 100;
    value = value * statTypeRate;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "MHP");
    value = value * raceTypeRate;
    
--    value = value * JAEDDURY_MON_MHP_RATE;      -- JAEDDURY
    
    local byBuff = TryGetProp(self, "MHP_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    value = value + byBuff;
    
	local monClassName = TryGetProp(self, "ClassName", "None");
	local monOriginFaction = TryGetProp(GetClass("Monster", monClassName), "Faction");
    if monOriginFaction == "Summon" then
        value = value + 5000;   -- PC Summon Monster MHP Add
    end
    
    if value < 1 then
        value = 1;
    end
    
    return value--math.floor(value);
end

statget.STR = function(self)
    local statString = "STR";
    
    local lv = TryGetProp(self, "Lv")
    if lv == nil then
        lv = 1;
    end
    
    local byStat = GET_MON_STAT(self, lv, statString);
    if byStat == nil or byStat < 0 then
        byStat = 0;
    end
    
    local byBuff = TryGetProp(self, statString.."_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byStat + byBuff;
    
    return value--return math.floor(value);
end

statget.INT = function(self)
    local statString = "INT";
    
    local lv = TryGetProp(self, "Lv")
    if lv == nil then
        lv = 1;
    end
    
    local byStat = GET_MON_STAT(self, lv, statString);
    if byStat == nil or byStat < 0 then
        byStat = 0;
    end
    
    local byBuff = TryGetProp(self, statString.."_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byStat + byBuff;
    
    return value--return math.floor(value);
end

statget.CON = function(self)
    local statString = "CON";
    
    local lv = TryGetProp(self, "Lv")
    if lv == nil then
        lv = 1;
    end
    
    local byStat = GET_MON_STAT(self, lv, statString);
    if byStat == nil or byStat < 0 then
        byStat = 0;
    end
    
    local byBuff = TryGetProp(self, statString.."_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byStat + byBuff;
    
    return value--return math.floor(value);
end

statget.SPR = function(self)
    local statString = "MNA";
    
    local lv = TryGetProp(self, "Lv")
    if lv == nil then
        lv = 1;
    end
    
    local byStat = GET_MON_STAT(self, lv, statString);
    if byStat == nil or byStat < 0 then
        byStat = 0;
    end
    
    local byBuff = TryGetProp(self, statString.."_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byStat + byBuff;
    
    return value--return math.floor(value);
end

statget.DEX = function(self)
    local statString = "DEX";
    
    local lv = TryGetProp(self, "Lv")
    if lv == nil then
        lv = 1;
    end
    
    local byStat = GET_MON_STAT(self, lv, statString);
    if byStat == nil or byStat < 0 then
        byStat = 0;
    end
    
    local byBuff = TryGetProp(self, statString.."_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byStat + byBuff;
    
    return value--return math.floor(value);
end

statget.DEF = function(self)
    local fixedDEF = TryGetProp(self, "FixedDefence");
    if fixedDEF ~= nil and fixedDEF > 0 then
        return fixedDEF;
    end
    
    local lv = TryGetProp(self, "Lv");
    if lv == nil then
        lv = 1;
    end
    
    local byLevel = lv * 1.0;
    
    local stat = TryGetProp(self, "CON");
    if stat == nil then
        stat = 1;
    end
    
    local byStat = (stat * 2) + (math.floor(stat / 10) * (byLevel * 0.05));
    
    local byItem = SCR_MON_ITEM_ARMOR_DEF_CALC(self);
    
    local value = byLevel + byStat + byItem;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "DEF");
    
    value = value * raceTypeRate;
    
    local byBuff = TryGetProp(self, "DEF_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local byRateBuff = TryGetProp(self, "DEF_RATE_BM");
    if byRateBuff == nil then
        byRateBuff = 0;
    end
    
    byRateBuff = value * byRateBuff;
    
--    value = value * JAEDDURY_MON_DEF_RATE;      -- JAEDDURY
    
    value = value + byBuff + byRateBuff;
    
    if value < 0 then
        value = 0;
    end
    
    return value--math.floor(value)
end

statget.MDEF = function(self)
    local fixedDEF = TryGetProp(self, "FixedDefence");
    if fixedDEF ~= nil and fixedDEF > 0 then
        return fixedDEF;
    end
    
    local lv = TryGetProp(self, "Lv");
    if lv == nil then
        lv = 1;
    end
    
    local byLevel = lv * 1.0;
    
    local stat = TryGetProp(self, "CON");
    if stat == nil then
        stat = 1;
    end
    
    local byStat = (stat * 2) + (math.floor(stat / 10) * (byLevel * 0.05));
    
    local byItem = SCR_MON_ITEM_ARMOR_MDEF_CALC(self);
    
    local value = byLevel + byStat + byItem;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "MDEF");
    
    value = value * raceTypeRate;
    
    local byBuff = TryGetProp(self, "MDEF_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local byRateBuff = TryGetProp(self, "MDEF_RATE_BM");
    if byRateBuff == nil then
        byRateBuff = 0;
    end
    
    byRateBuff = value * byRateBuff;
    
--    value = value * JAEDDURY_MON_DEF_RATE;      -- JAEDDURY
    
    value = value + byBuff + byRateBuff;
    
    if value < 0 then
        value = 0;
    end
    
    return value--math.floor(value)
end

statget.DR = function(self)
    if self.HPCount > 0 then
        return 0;
    end
    
    local lv = TryGetProp(self, "Lv");
    if lv == nil then
        lv = 1;
    end
    
    local byLevel = lv * 1.0;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "DR");
    
    local value = byLevel * raceTypeRate;
    
    local byBuff = TryGetProp(self, "DR_BM", 0);
    
    local byRateBuff = TryGetProp(self, "DR_RATE_BM", 0);
    byRateBuff = math.floor(value * byRateBuff);
    
    value = value + byBuff + byRateBuff;
    
    if value < 0 then
        value = 0;
    end
    
    return value--math.floor(value);
end

statget.BLK = function(self)
    if TryGetProp(self, "BLKABLE", 0) == 0 then
        return 0;
    end
    
    local lv = self.Lv;
    
    local byLevel = lv * 1.0;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "BLK");
    
    local value = byLevel * raceTypeRate;
    
    local byBuff = TryGetProp(self, "BLK_BM", 0);
    
    local byRateBuff = TryGetProp(self, "BLK_RATE_BM", 0);
    byRateBuff = math.floor(value * byRateBuff);
    
    value = value + byBuff + byRateBuff;
    
    if value < 0 then
        value = 0;
    end
    
    return value--math.floor(value);
end

function STATGET_ON_INIT(addon, frame)
	if not loaded then
		local acutil = require("acutil")
		acutil.slashCommand("/statget", STATGET)
		loaded = true
	end
end

function STATGET(tbl)
	local handle = session.GetTargetHandle()
	if handle == 0 then return end
	local npc = CreateGCIES('Monster', info.GetMonsterClassName(handle))
	npc.Lv = info.GetLevel(handle)
	local baseHp = 0
	local targetinfo = info.GetTargetInfo(handle)
	if targetinfo.isBoss == 1 then
		npc.MonRank = "Boss"
	elseif targetinfo.isElite == 1 then
		baseHp = statget.MHP(npc)
		npc.MonRank = "Elite"
		npc.Size = "L"
	elseif info.GetMonRankbyHandle(handle) == 'Special' then
		npc.MonRank = "Special"
	else
		npc.MonRank = "Normal"
	end

	for i = 1, #tbl do
		local stattype = string.upper(tbl[i])
		local fn = statget[stattype]
		if fn ~= nil then
			local v = fn(npc)
			if targetinfo.isElite == 1 then
				if stattype == "MHP" then
					v = math.floor(v) + baseHp
				elseif stattype ~= "STR" and stattype ~= "CON" and stattype ~= "INT" and stattype ~= "MNA" and stattype ~= "DEX" then
					v = v * 2
				end
			end
			ui.SysMsg(string.format("%s: %f", stattype, v))
		end
	end
end
--halved hp and def for elite summons
--defense type monster *1.2def post flooring