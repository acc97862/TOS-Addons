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