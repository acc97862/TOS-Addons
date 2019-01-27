-- Functions ZOOMY_CLAMP(), ZOOMY_IN(), ZOOMY_OUT(), and the "Zoomy" name are taken from Excrulon's Zoomy v1.0.0 addon.
_G["ZOOMYPLUS"] = {};
_G["ZOOMYPLUS"]["settings"] = {
	display = 1;
	displayX = 510;
	displayY = 880;
	lock = 1;
	defaultX = 45;
	defaultY = 38;
	defaultZoom = 236;
	scaling = 5;
};
local settings = _G["ZOOMYPLUS"]["settings"];
local acutil = require("acutil");
local mapInit = 0;
local zoomyplusFrame;
local XY_MULTIPLIER = 5;
local currentX = 45;
local currentY = 38;
local currentZoom = 236;
local MINIMUM_ZOOM = 50;
local MAXIMUM_ZOOM = 1500;
local MINIMUM_XY = 0;
local MAXIMUM_XY = 359;
CHAT_SYSTEM("Zoomy Plus loaded! Help: /zplus help");

local function scaleup(num)
	return math.floor(num * settings.scaling);
end

local function scaledown(num)
	return math.floor(num / settings.scaling + 0.5);
end

currentX = scaleup(currentX);
currentY = scaleup(currentY);

function ZOOMYPLUS_IS_TBL_MAP()
	return (session.GetMapName() == "pvp_tournament")
end

function ZOOMYPLUS_ON_INIT(addon, frame)
	zoomyplusFrame = frame;
	mapInit = 1;
	acutil.slashCommand("/zplus",ZOOMYPLUS_CMD);
	ZOOMYPLUS_SET_LOCK(settings.lock, true);
	frame:SetOffset(settings.displayX, settings.displayY);
	frame:SetVisible(settings.display);
	frame:RunUpdateScript("ZOOMY_KEYPRESS", 0, 0, 0, 1);
	addon:RegisterMsg("FPS_UPDATE", "ZOOMYPLUS_UPDATE")
end

function ZOOMYPLUS_UPDATE()
	if mapInit > 0 then
		mapInit = mapInit - 1;
		if ZOOMYPLUS_IS_TBL_MAP() then return end
		camera.CamRotate(scaledown(currentY), scaledown(currentX));
		camera.CustomZoom(currentZoom, 0);
		ZOOMYPLUS_SETTEXT();
	end
end

function ZOOMYPLUS_LOADSETTINGS()
	acutil.loadJSON("../addons/zoomyplus/settings.json", settings);
	currentX = scaleup(settings.defaultX);
	currentY = scaleup(settings.defaultY);
	currentZoom = settings.defaultZoom;
end

function ZOOMYPLUS_LOAD_KEYPRESS()
	pcall(dofile, "../addons/zoomyplus/keypress.lua");
end

function ZOOMYPLUS_SAVESETTINGS()
	acutil.saveJSON("../addons/zoomyplus/settings.json", settings);
end

function ZOOMYPLUS_SAVEDEFAULTS()
	settings.defaultX = scaledown(currentX);
	settings.defaultY = scaledown(currentY);
	settings.defaultZoom = currentZoom;
	ZOOMYPLUS_SAVESETTINGS();
end

function ZOOMYPLUS_END_DRAG()
	settings.displayX = zoomyplusFrame:GetX();
	settings.displayY = zoomyplusFrame:GetY();
	ZOOMYPLUS_SAVESETTINGS();
end

function ZOOMYPLUS_SETTEXT()
	zoomyplusFrame:GetChild("zoomyplusZText"):SetText("{s16}{#B81313}{ol}Z : " .. currentZoom);
	zoomyplusFrame:GetChild("zoomyplusXText"):SetText("{s16}{#B81313}{ol}X : " .. scaledown(currentX));
	zoomyplusFrame:GetChild("zoomyplusYText"):SetText("{s16}{#B81313}{ol}Y : " .. scaledown(currentY));
end

function ZOOMYPLUS_SET_LOCK(num, skip)
	settings.lock = num;
	zoomyplusFrame:EnableHitTest(1 - num);
	if not skip then
		CHAT_SYSTEM("Coordinate display " .. (num == 1 and "" or "un") .. "locked.");
	end
end

function ZOOMY_ROTATE(x, y, relative)
	if ZOOMYPLUS_IS_TBL_MAP() then return end
	if relative then
		local maxXY = scaleup(MAXIMUM_XY + 1);
		currentX = (currentX + x) % maxXY;
		currentY = (currentY + y) % maxXY;
		x = scaledown(currentX);
		y = scaledown(currentY);
	else
		if x < MINIMUM_XY or y < MINIMUM_XY or x > MAXIMUM_XY or y > MAXIMUM_XY then
			CHAT_SYSTEM("Invalid x y values. Minimum for both is " .. MINIMUM_XY .. " and maximum for both is " .. MAXIMUM_XY .. ".");
			return;
		end
		currentX = scaleup(x);
		currentY = scaleup(y);
	end

	camera.CamRotate(y, x);
	ZOOMYPLUS_SETTEXT();
end

function ZOOMY_ZOOM(num, relative, time)
	if ZOOMYPLUS_IS_TBL_MAP() then return end
	if relative then
		currentZoom = currentZoom + num;
		if currentZoom < MINIMUM_ZOOM then
			currentZoom = MINIMUM_ZOOM;
		elseif currentZoom > MAXIMUM_ZOOM then
			currentZoom = MAXIMUM_ZOOM;
		end
	else
		if num < MINIMUM_ZOOM or num > MAXIMUM_ZOOM then
			CHAT_SYSTEM("Invalid zoom level. Minimum is " .. MINIMUM_ZOOM .. " and maximum is " .. MAXIMUM_ZOOM .. ".");
			return;
		end
		currentZoom = num;
	end

	if type(time) == "number" then
		camera.CustomZoom(currentZoom, time);
	else
		camera.CustomZoom(currentZoom);
	end
	ZOOMYPLUS_SETTEXT();
end

function ZOOMY_KEYPRESS(frame)
	if keyboard.IsKeyPressed("NEXT") == 1 then
			ZOOMY_ZOOM(2, true);
	elseif keyboard.IsKeyPressed("PRIOR") == 1 then
			ZOOMY_ZOOM(-2, true);
	end
	if keyboard.IsKeyPressed("LCTRL") == 1 then
		if mouse.IsRBtnPressed() == 1 then
			ZOOMYPLUS_XY();
		end
		if keyboard.IsKeyPressed("NEXT") == 1 then
			ZOOMY_ZOOM(10, true);
		elseif keyboard.IsKeyPressed("PRIOR") == 1 then
			ZOOMY_ZOOM(-10, true);
		end
	end
	return 1;
end

function ZOOMYPLUS_XY()
	if ZOOMYPLUS_IS_TBL_MAP() then return end
	local maxXY = scaleup(MAXIMUM_XY + 1);
	currentX = (currentX - mouse.GetDeltaX()) % maxXY;
	currentY = (currentY + mouse.GetDeltaY()) % maxXY;
	camera.CamRotate(scaledown(currentY), scaledown(currentX));
	camera.CustomZoom(currentZoom, 0);
	ZOOMYPLUS_SETTEXT();
end

function ZOOMYPLUS_CMD(command)
	local a, b, c, d = unpack(command);
	if a == "help" then
		CHAT_SYSTEM("Zoomy Plus Help:{nl}Use Page Up to zoom in and Page Down to zoom out. Doing so while holding Left Ctrl makes zooming in and out 5 times faster. Also while holding Left Ctrl you can press and hold Right Click to rotate the camera by moving the mouse!{nl}'/zplus zoom <num>' to go to a specific zoom level anywhere between 50 and 1500!{nl}Example: /zplus zoom 800{nl}'/zplus swap <num1> <num2>' or '/zplus switch <num1> <num2>' to swap/switch between two zoom levels!{nl}Example: /zplus swap 350 500{nl}'/zplus rotate <x> <y>' to rotate camera to specific coordinates between 0 and 359!{nl}Example: /zplus rotate 90 10{nl}'/zplus reset' to restore default xy positioning and zoom level.{nl}'/zplus reset xy' to restore default positioning to xy only.{nl}'/zplus display' to show/hide the coordinate display.{nl}'/zplus lock' to unlock/lock the coordinate display in order to move it around.{nl}'/zplus default' to restore coordinate display to its default location.");
		return;
	end
	if a == "zoom" then
		b = tonumber(b);
		if b then
			ZOOMY_ZOOM(b);
		end
		return;
	end
	if a == "swap" or a == "switch" then
		b = tonumber(b);
		c = tonumber(c);
		if b and c then
			if currentZoom == b then
				ZOOMY_ZOOM(c);
			else
				ZOOMY_ZOOM(b);
			end
		end
		return;
	end
	if a == "rotate" then
		b = tonumber(b);
		c = tonumber(c);
		if b and c then
			ZOOMY_ROTATE(b, c);
			camera.CustomZoom(currentZoom, 0);
		end
		return;
	end
	if a == "reset" then
		if b == "full" then
			ZOOMY_ROTATE(45, 38);
			ZOOMY_ZOOM(236);
			settings.displayX = 510;
			settings.displayY = 880;
			settings.display = 1;
			ZOOMYPLUS_SET_LOCK(1, true);
			zoomyplusFrame:SetOffset(510, 880);
			zoomyplusFrame:SetVisible(1);
			ZOOMYPLUS_SAVEDEFAULTS();
			return;
		end
		ZOOMY_ROTATE(settings.defaultX, settings.defaultY);
		if b ~= "xy" then
			ZOOMY_ZOOM(settings.defaultZoom);
		end
		return;
	end
	if a == "display" then
		settings.display = 1 - settings.display;
		zoomyplusFrame:SetVisible(settings.display);
		ZOOMYPLUS_SAVESETTINGS();
		return;
	end
	if a == "lock" then
		ZOOMYPLUS_SET_LOCK(1 - settings.lock);
		ZOOMYPLUS_SAVESETTINGS();
		return;
	end
	if a == "default" then
		settings.displayX = 510;
		settings.displayY = 880;
		settings.display = 1;
		ZOOMYPLUS_SET_LOCK(1, true);
		zoomyplusFrame:SetOffset(510, 880);
		zoomyplusFrame:SetVisible(1);
		ZOOMYPLUS_SAVESETTINGS();
		return;
	end
	if a == "set" then
		b = tonumber(b);
		c = tonumber(b);
		d = tonumber(c);
		if b and c and d then
			ZOOMY_ROTATE(c, d);
			ZOOMY_ZOOM(b);
		end
		return;
	end
	if a == "save" then
		ZOOMYPLUS_SAVEDEFAULTS();
		return;
	end
	CHAT_SYSTEM("Invalid command. Available commands:{nl}/zplus help{nl}/zplus zoom <num>{nl}/zplus swap <num1> <num2>{nl}/zplus switch <num1> <num2>{nl}/zplus rotate <x> <y>{nl}/zplus reset{nl}/zplus reset xy{nl}/zplus display{nl}/zplus lock{nl}/zplus default");
end

ZOOMYPLUS_LOADSETTINGS();
ZOOMYPLUS_LOAD_KEYPRESS();