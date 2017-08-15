--sysmenuaddonexample.lua

function SYSMENUADDONEXAMPLE_ON_INIT(addon, frame)
	addon:RegisterMsg("GAME_START_3SEC", "SYSMENUADDONEXAMPLE_CREATE_SYSMENU_ICONS");
end

function SYSMENUADDONEXAMPLE_OPEN()
end

function SYSMENUADDONEXAMPLE_CLOSE()
end

--Icon creating function name needs to be unique, so include your addon's name
function SYSMENUADDONEXAMPLE_CREATE_SYSMENU_ICONS()
	--Get frame
	local frame = ui.GetFrame("sysmenu");
	--Perform checks
	if not isAddon then
		if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
		and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
		then
			return;
		end
	end

	--Calculate extraBag, rightMargin and offsetX
	local extraBag = frame:GetChild('extraBag');
	local status = frame:GetChild("status");
	local offsetX = status:GetX() - extraBag:GetX();
	local rightMargin = 0;
	for idx = 0, frame:GetChildCount()-1 do
		local t = frame:GetChildByIndex(idx):GetMargin().right;
		if rightMargin < t then
			rightMargin = t;
		end
	end
	rightMargin = rightMargin + offsetX;

	--Your own icon creating code
	rightMargin = SYSMENU_CREATE_VARICON(frame, status, "sysmenuaddonexample", "sysmenuaddonexample", "sysmenu_mac", rightMargin, offsetX, "SYSMENU Addon Example");

	local sysmenuaddonexampleButton = GET_CHILD(frame, "sysmenuaddonexample", "ui::CButton");
	if sysmenuaddonexampleButton ~= nil then
		sysmenuaddonexampleButton:SetTextTooltip("{@st59}SYSMENU addon example");
	end
end