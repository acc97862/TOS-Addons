--Prepare function container for previous icon creating function
local PREVIOUS_SYSMENU_CREATE_ICON;

function SYSMENUADDONEXAMPLE_ON_INIT(addon, frame)
	--If function container contains nothing then
	if PREVIOUS_SYSMENU_CREATE_ICON == nil then

		--Load acutil
		local acutil = require('acutil');

		--Save previous icon creating function to container
		--WARNING: this MUST only be run ONCE, and NEVER AGAIN or else the game will PROBABLY CRASH
		PREVIOUS_SYSMENU_CREATE_ICON = SYSMENU_CHECK_HIDE_VAR_ICONS;

		--Setup hook to overwrite
		--Hook should only be run once to not break the chain
		acutil.setupHook(SYSMENUADDONEXAMPLE_SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED, "SYSMENU_CHECK_HIDE_VAR_ICONS");

		--Only need to recreate icons during the first run
		SYSMENU_CHECK_HIDE_VAR_ICONS(ui.GetFrame("sysmenu"));
	end
end

function SYSMENUADDONEXAMPLE_OPEN()
end

function SYSMENUADDONEXAMPLE_CLOSE()
end

--Icon creating function name needs to be unique, so include your addon's name
function SYSMENUADDONEXAMPLE_SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED(frame, isAddon)
	--If function calling you is not an addon, you need to perform checks
	--Otherwise, it should be safe to skip checks to improve speed
	if not isAddon then
		if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
		then
			return;
		end
	end

	--Run the previous sysmenu icon creating function, so that you do not prevent other addon creators from making their own sysmenu icons
	--The "true" shows that you are an addon and have done the checks above already
	--Also, try to get the previous rightMargin values to speed up code
	local extraBag, rightMargin, offsetX = PREVIOUS_SYSMENU_CREATE_ICON(frame, true);

	--If you do not receive rightMargin value, calculate them yourself
	if extraBag == nil or rightMargin == nil or offsetX == nil then
		extraBag = frame:GetChild('extraBag');
		status = frame:GetChild("status");
		offsetX = status:GetX() - extraBag:GetX();
		rightMargin = 0;
		for idx = 0, frame:GetChildCount()-1 do
			local t = frame:GetChildByIndex(idx):GetMargin().right;
			if rightMargin < t then
				rightMargin = t;
			end
		end
		rightMargin = rightMargin + offsetX;
	end

	--Your own icon creating code
    rightMargin = SYSMENU_CREATE_VARICON(frame, status, "sysmenuaddonexample", "sysmenuaddonexample", "sysmenu_mac", rightMargin, offsetX, "SYSMENU Addon Example");

    local sysmenuaddonexampleButton = GET_CHILD(frame, "sysmenuaddonexample", "ui::CButton");
    if sysmenuaddonexampleButton ~= nil then
        sysmenuaddonexampleButton:SetTextTooltip("{@st59}SYSMENU addon example");
    end

	--Remember to return extraBag, rightMargin, offsetX to speed up other's code
	return extraBag, rightMargin, offsetX
end