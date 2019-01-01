local addonName = "TOGGLEATTRIBUTE";
local author = 'MIRARARA';
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {};
local g = _G['ADDONS']['MIRARARA']['TOGGLEATTRIBUTE'];
local acutil = require('acutil');

g.settingsFileLoc = '../addons/toggleattribute/toggleattribute.json';

if not g.loaded then
	g.settings = {
		attribute = {};
	}
	
end

g.lastname = false;
g.lastid = false;

if not g.loaded then
	local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
	if err then
		acutil.saveJSON(g.settingsFileLoc, g.settings);
	else
		g.settings = t;
	end
	g.loaded = true;
end

function g.ta(arg)
	local g = _G['ADDONS']['MIRARARA']['TOGGLEATTRIBUTE'];
	local num = table.remove(arg,1);
	local name = g.settings.attribute[num]['name'];
	local id = g.settings.attribute[num]['id'];
	
	local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);
	
	-- geting the attribute instance
	local abil = session.GetAbility(id);
	
	if abil then
		local abilClass = GetIES(abil:GetObject());
		local state = abilClass.ActiveState;
		if state == 0 then
			ui.AddText("SystemMsgFrame", '{ds}{#00FF00}'..abilClass.Name..' is switched on.');
		elseif state == 1 then
			ui.AddText("SystemMsgFrame", '{ds}{#FF0000}'..abilClass.Name..' is switched off.');
		end
	end
	
	TOGGLE_ABILITY_ACTIVE(nil,nil,name,id);
end

function g.taset(arg)
	local num = table.remove(arg,1);
	
	local g = _G['ADDONS']['MIRARARA']['TOGGLEATTRIBUTE'];
	
	g.settings.attribute[num] = {};
	g.settings.attribute[num]['name'] = g.lastname;
	g.settings.attribute[num]['id'] = g.lastid;
	
	local abil = session.GetAbility(g.lastid);
	
	if abil then
		local abilClass = GetIES(abil:GetObject());
		CHAT_SYSTEM(abilClass.Name..' is saved to /ta '..num..'.');
	end
	
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function g.reloadta()
	dofile("../addons/toggleattribute/toggleattribute.lua");
	ui.SysMsg('[Toggle Attribute] Reloaded');
end

function g.tahelp()
	CHAT_SYSTEM('[Toggle Attribute]');
	CHAT_SYSTEM('/taset [num] - Set the last toggled attribute to set [num].');
	CHAT_SYSTEM('/ta [num] - Toggle the attribute saved in set [num].');
	CHAT_SYSTEM('Example:');
	CHAT_SYSTEM('1) Use Provoke attribute.');
	CHAT_SYSTEM('2) Type /taset 1');
	CHAT_SYSTEM('3) Type /ta 1 to toggle Provoke attribute. You can save this to macro for easier usage.');
end

function TOGGLE_ABILITY_ACTIVE_TA(frame, control, abilName, abilID)
	local g = _G['ADDONS']['MIRARARA']['TOGGLEATTRIBUTE'];
	
	g.lastname = abilName;
	g.lastid = abilID;
	
	TOGGLE_ABILITY_ACTIVE_OLD_TA(frame, control, abilName, abilID)
end

function g.setupHook(newFunction, hookedFunctionStr, name)
	name = name or "";
	local storeOldFunc = hookedFunctionStr .. "_OLD".."_"..name;
	if _G[storeOldFunc] == nil then
		_G[storeOldFunc] = _G[hookedFunctionStr];
		_G[hookedFunctionStr] = newFunction;
	else
		_G[hookedFunctionStr] = newFunction;
	end
end

acutil.slashCommand('/tareload', g.reloadta);
acutil.slashCommand('/taset', g.taset);
acutil.slashCommand('/tahelp', g.tahelp);
acutil.slashCommand('/ta', g.ta);

g.setupHook(TOGGLE_ABILITY_ACTIVE_TA,'TOGGLE_ABILITY_ACTIVE','TA');

CHAT_SYSTEM('[Toggle Attribute] beta loaded. /tahelp for help command. t.Comfy');

