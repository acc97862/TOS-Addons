--statviewer.lua

local addonName = "STATVIEWER";
local addonNameLower = string.lower(addonName);

_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][addonName] = _G["ADDONS"][addonName] or {};
local g = _G["ADDONS"][addonName];

local acutil = require('acutil');
local loaded = false;
local settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);
local frameitemsFileLoc = string.format("../addons/%s/frameitems.json", addonNameLower);
local isDragging = false;
local statframe;

function STATVIEWER_ON_INIT(addon, frame)
	statframe = frame;
	addon:RegisterMsg("PC_PROPERTY_UPDATE", "STATVIEWER_UPDATE");
	frame:SetEventScript(ui.LBUTTONDOWN, "STATVIEWER_START_DRAG");
	frame:SetEventScript(ui.LBUTTONUP, "STATVIEWER_END_DRAG");

	if not loaded then
		loaded = true;
		acutil.slashCommand(string.format("/%s", addonNameLower), STATVIEWER_CHAT);
		STATVIEWER_LOADSETTINGS();
	end

	STATVIEWER_UPDATE();

	if g.settings.enable then
		frame:ShowWindow(1);
	else
		frame:ShowWindow(0);
	end
end

function STATVIEWER_LOADSETTINGS()
	local t, err = acutil.loadJSON(settingsFileLoc);
	if err then
		g.settings = {enable = true, displayzero = true, position = {x = 0, y = 0}};
		CHAT_SYSTEM(string.format('[%s] Cannot load settings file', addonName));
	else
		g.settings = t;
	end

	t, err = acutil.loadJSON(frameitemsFileLoc);
	if err then
		g.frameitems = {{PATK = "PATK"}, {MATK = "MATK"}, {MHR = "MAMP"},
		                {EATK = "EATK"}, {DEF = "PDEF"}, {MDEF ="MDEF"},
		                {MSPD = "MSPD"}, {RHP = "HP REC"}, {RSP = "SP REC"}};
		CHAT_SYSTEM(string.format('[%s] Cannot load frame items file', addonName));
	else
		g.frameitems = t;
	end
end

function STATVIEWER_SAVESETTINGS()
	acutil.saveJSON(settingsFileLoc, g.settings);
	acutil.saveJSON(frameitemsFileLoc, g.frameitems);
end

function STATVIEWER_CHAT(tbl)
	if #tbl == 0 then
		STATVIEWER_TOGGLE_FRAME();
	elseif string.lower(tbl[1]) == "zero" then
		STATVIEWER_TOGGLE_ZERO();
	elseif string.lower(tbl[1]) == "reload" then
		STATVIEWER_LOADSETTINGS();
		STATVIEWER_UPDATE();
		if g.settings.enable then
			statframe:ShowWindow(1);
		else
			statframe:ShowWindow(0);
		end
	else
		CHAT_SYSTEM(string.format("[%s:toggle frame] /%s{nl}[%s:toggle zero display] /%s zero{nl}[%s:reload] /%s reload", addonNameLower, addonNameLower, addonNameLower, addonNameLower, addonNameLower, addonNameLower));
	end
end

function STATVIEWER_TOGGLE_FRAME()
	if statframe:IsVisible() == 0 then
		statframe:ShowWindow(1);
		g.settings.enable = true;
	else
		statframe:ShowWindow(0);
		g.settings.enable = false;
	end
	STATVIEWER_SAVESETTINGS();
end

function STATVIEWER_TOGGLE_ZERO()
	g.settings.displayzero = not g.settings.displayzero;
	if g.settings.displayzero then
		CHAT_SYSTEM(string.format("[%s] zeros displayed", addonNameLower));
	else
		CHAT_SYSTEM(string.format("[%s] zeros hidden", addonNameLower));
	end
	STATVIEWER_SAVESETTINGS();
	STATVIEWER_UPDATE();
end

function STATVIEWER_START_DRAG()
	isDragging = true;
end

function STATVIEWER_END_DRAG()
	isDragging = false;
	g.settings.position.x = statframe:GetX();
	g.settings.position.y = statframe:GetY();
	STATVIEWER_SAVESETTINGS();
end

local function STATVIEWER_CALCULATE_ELEMENTAL_ATTACK(pc)
	local elementalAttack = 0;

	elementalAttack = elementalAttack + pc["Fire_Atk"];
	elementalAttack = elementalAttack + pc["Ice_Atk"];
	elementalAttack = elementalAttack + pc["Lightning_Atk"];
	elementalAttack = elementalAttack + pc["Earth_Atk"];
	elementalAttack = elementalAttack + pc["Poison_Atk"];
	elementalAttack = elementalAttack + pc["Holy_Atk"];
	elementalAttack = elementalAttack + pc["Dark_Atk"];
	elementalAttack = elementalAttack + pc["Soul_Atk"];

	return elementalAttack;
end

local function STATVIEWER_UPDATE_STAT(statString, dimensions)
	dimensions.count = dimensions.count + 1;
	local statRichText = statframe:CreateOrGetControl("richtext", "text_" .. dimensions.count, dimensions.x, dimensions.y, 100, 25);
	tolua.cast(statRichText, "ui::CRichText");
	statRichText:SetGravity(ui.LEFT, ui.TOP);
	statRichText:SetTextAlign("left", "center");
	statRichText:SetText(statString);
	statRichText:SetFontName("white_16_ol");
	statRichText:EnableHitTest(0);
	statRichText:ShowWindow(1);

	dimensions.y = dimensions.y + statRichText:GetHeight() - 7;

	if dimensions.maxwidth < statRichText:GetWidth() then
		dimensions.maxwidth = statRichText:GetWidth();
	end
end

function STATVIEWER_UPDATE()
	local pc = GetMyPCObject();
	local dimensions = {x = 5, y = 5, maxwidth = 0, count = 0};
	local val = 0;

	for _, tbl in pairs(g.frameitems) do
		for stat, str in pairs(tbl) do
			if stat == "PATK" then
				STATVIEWER_UPDATE_STAT(str .. ": " .. pc["MINPATK"] .. "~" .. pc["MAXPATK"], dimensions);
			elseif stat == "PATK_SUB" then
				STATVIEWER_UPDATE_STAT(str .. ": " .. pc["MINPATK_SUB"] .. "~" .. pc["MAXPATK_SUB"], dimensions);
			elseif stat == "MATK" then
				STATVIEWER_UPDATE_STAT(str .. ": " .. pc["MINMATK"] .. "~" .. pc["MAXMATK"], dimensions);
			else
				if stat == "EATK" then
					val = STATVIEWER_CALCULATE_ELEMENTAL_ATTACK(pc);
				else
					val = pc[stat]
				end

				if (g.settings.displayzero or val ~= 0) and val ~= nil then
					STATVIEWER_UPDATE_STAT(str .. ": " .. val, dimensions);
				end
			end
		end
	end

	for t = statframe:GetChildCount() - 1, dimensions.count, -1 do
		statframe:RemoveChildByIndex(t);
	end

	if dimensions.count > 0 then
		statframe:Resize(dimensions.maxwidth + 10, dimensions.y + 10);
	else
		statframe:Resize(0, 0);
	end

	if not isDragging then
		statframe:Move(0, 0);
		statframe:SetOffset(g.settings.position.x, g.settings.position.y);
	end
end