--statget.lua

local loaded = false
local statget = {}

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
    
    local byItem = SCR_MON_ITEM_ARMOR_CALC(self, lv);
    local basicGradeRatio, reinforceGradeRatio = SCR_MON_ITEM_GRADE_RATE(self, lv);
    
    local byReinforce = 0;
    local byTranscend = 1;
    
    local monStatType = TryGetProp(self, "StatType");
    if monStatType ~= nil and monStatType ~= 'None' then
        local cls = GetClass("Stat_Monster_Type", "type"..monStatType);
        if cls ~= nil then
            local reinforceValue = cls.ReinforceArmor;
            byReinforce = SCR_MON_ITEM_REINFORCE_ARMOR_CALC(self, lv, reinforceValue, reinforceGradeRatio);
            
            local transcendValue = cls.TranscendArmor;
            byTranscend = SCR_MON_ITEM_TRANSCEND_CALC(self, transcendValue);
        end
    end
    
    byItem = math.floor(byItem * basicGradeRatio);
    byItem = math.floor(byItem * byTranscend) + byReinforce;
    
    local value = byLevel + byItem;
    
    local byDEFRate = TryGetProp(self, "DEFRate")
    if byDEFRate == nil then
        byDEFRate = 100;
    end
    
    byDEFRate = byDEFRate / 100;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "DEF");
    
    value = value * (byDEFRate * raceTypeRate);
    
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
    
    return value--return math.floor(value)
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
    
    local byItem = SCR_MON_ITEM_ARMOR_CALC(self, lv);
    local basicGradeRatio, reinforceGradeRatio = SCR_MON_ITEM_GRADE_RATE(self, lv);
    
    local byReinforce = 0;
    local byTranscend = 1;
    
    local monStatType = TryGetProp(self, "StatType");
    if monStatType ~= nil and monStatType ~= 'None' then
        local cls = GetClass("Stat_Monster_Type", "type"..monStatType);
        if cls ~= nil then
            local reinforceValue = cls.ReinforceArmor;
            byReinforce = SCR_MON_ITEM_REINFORCE_ARMOR_CALC(self, lv, reinforceValue, reinforceGradeRatio);
            
            local transcendValue = cls.TranscendArmor;
            byTranscend = SCR_MON_ITEM_TRANSCEND_CALC(self, transcendValue);
        end
    end
    
    byItem = math.floor(byItem * basicGradeRatio);
    byItem = math.floor(byItem * byTranscend) + byReinforce;
    
    local value = byLevel + byItem;
    
    local byMDEFRate = TryGetProp(self, "MDEFRate")
    if byMDEFRate == nil then
        byMDEFRate = 100;
    end
    
    byMDEFRate = byMDEFRate / 100;
    
    local raceTypeRate = SCR_RACE_TYPE_RATE(self, "MDEF");
    
    value = value * (byMDEFRate * raceTypeRate);
    
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
    
    return value--return math.floor(value)
end

statget.BLK = function(self)
    if self.Blockable == 0 then
        return 0;
    end
    
    local lv = self.Lv;
    local byLevel = lv * 0.25;
    
    local stat = TryGetProp(self, "CON");
    if stat == nil then
        stat = 1;
    end
    
    local byStat = (stat * 0.5) + (math.floor(stat / 15) * 3);
    
    local monBlockRate = TryGetProp(self, "BlockRate");
    if monBlockRate == nil then
        monBlockRate = 100;
    end
    
    monBlockRate = (byLevel + byStat) * (monBlockRate * 0.01);
    
    local byBuff = TryGetProp(self, "BLK_BM");
    if byBuff == nil then
        byBuff = 0;
    end
    
    local value = byLevel + byStat + monBlockRate + byBuff;
    
    return value;
end

function STATGET_ON_INIT(addon,frame)
	if not loaded then
		loaded = true
		local acutil = require("acutil")
		acutil.slashCommand("/statget", STATGET)
	end
end

function STATGET(tbl)
	local handle = session.GetTargetHandle()
	local npc = CreateGCIES('Monster', info.GetMonsterClassName(handle))
	npc.Lv = info.GetLevel(handle)
	local targetinfo = info.GetTargetInfo(handle)
	if targetinfo.isBoss == 1 then
		npc.MonRank = "Boss"
	elseif targetinfo.isElite == 1 then
		npc.MonRank = "Elite"
	elseif info.GetMonRankbyHandle(handle) == 'Special' then
		npc.MonRank = "Special"
	else
		npc.MonRank = "Normal"
	end

	for i = 1, #tbl do
		local stattype = string.upper(tbl[i])
		local fn = statget[stattype]
		if fn ~= nil then
			ui.SysMsg(string.format("%s: %f", stattype, fn(npc)))
		end
	end
end