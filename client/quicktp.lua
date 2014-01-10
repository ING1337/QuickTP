-- QuickTP by ING

-- ##############################################################################################################

key             = "G"                       -- The assigned key to the menu
fontSize        = 50                        -- Fontsize, it will be scaled down depending on the entrycount
fontColor       = Color(255, 255, 255, 200) -- Textcolor
fontUpper       = true                      -- Upper the text
showGroupCount  = true                      -- Show entry count behind the group name

menuColor       = Color(255, 255, 255, 100)
backgroundColor = Color(0, 0, 0, 100)
highlightColor  = Color(255, 0, 0, 100)
innerRadius     = 60

-- ##############################################################################################################

collection  = nil
selection   = nil

subRender   = nil
subMouse    = nil
subKey      = nil

menuOpen    = false

-- ##############################################################################################################

ReceiveTPList = function(args)
	collection = args
	subKey     = Events:Subscribe("KeyDown", OnKeyDown)
	Network:Unsubscribe(subRecTP)
end

subRecTP = Network:Subscribe("TPList", ReceiveTPList) 
Network:Send("RequestTPList")

-- ##############################################################################################################

OnKeyDown = function(args)
	if args.key == string.byte(key) and Game:GetState() == GUIState.Game then
		Events:Unsubscribe(subKey)
		subKey = Events:Subscribe("KeyUp", OnKeyUp)
		OpenMenu()
	end
end

OnKeyUp = function(args)
	if args.key == string.byte(key) then
		Events:Unsubscribe(subKey)
		subKey = Events:Subscribe("KeyDown", OnKeyDown)
		if menuOpen then CloseMenu() end
	end
end

OnMouseClick = function(args)
	if type(menu[selection + 2]) == "table" then
		menu = menu[selection + 2]
		return
	end

	sendArgs = {}
	sendArgs.target = menu[selection + 2]
	sendArgs.button = args.button
	Network:Send("QuickTP", sendArgs)
	CloseMenu()
end

-- ##############################################################################################################

OpenMenu = function()
	subRender = Events:Subscribe("Render", RenderMenu)
	subMouse  = Events:Subscribe("MouseDown", OnMouseClick)

	Mouse:SetPosition(Vector2(Render.Width / 2, Render.Height / 2))
	Mouse:SetVisible(true)
	Input:SetEnabled(false)
	
	menu     = collection
	menuOpen = true
end

CloseMenu = function(args)
	Events:Unsubscribe(subRender)
	Events:Unsubscribe(subMouse)

	Mouse:SetVisible(false)
	Input:SetEnabled(true)

	menuOpen = false
end

RenderMenu = function(args)
	local count    = #menu - 1
	local size     = fontSize - count * 1.4
	if size < 12 then size = 12 end

	local radius   = (Render.Height / 2) - fontSize
	local angle    = math.pi / count
	local center   = Vector2(Render.Width / 2, Render.Height / 2)
	local drawRad  = 2200

	local current  = count % 2 == 1 and math.pi / 2 or 0
	local textSize = nil
	local coord    = Vector2()

	local mouseP   = Mouse:GetPosition()
	local mouseA   = math.atan2(mouseP.y - center.y, mouseP.x - center.x)
	selection      = math.floor(((mouseA + angle - current) / (math.pi * 2)) * count)

	if selection < 0 then selection = selection + count end

	Render:FillArea(Vector2(0, 0), Render.Size, backgroundColor)

	if count < 3 then Render:FillArea(
		Vector2((selection == 0 and count == 2) and center.x or 0, 0),
		Vector2(count == 1 and Render.Width or center.x, Render.Height),
		highlightColor
	) else Render:FillTriangle(
		center,
		Vector2(math.cos(selection * (angle*2) - angle + current) * drawRad, math.sin(selection * (angle*2) - angle + current) * drawRad) + center,
		Vector2(math.cos(selection * (angle*2) + angle + current) * drawRad, math.sin(selection * (angle*2) + angle + current) * drawRad) + center,
		highlightColor
	) end

	for i=2, #menu, 1 do
		local t = menu[i]
		if type(t) == "table" then t = t[1] .. (showGroupCount and " [" .. tostring(#t - 1) .. "]" or "") end
		if fontUpper then t = string.upper(t) end

		textSize = Render:GetTextSize(t, size) 
		coord.x  = math.cos(current) * radius + center.x - textSize.x / 2
		coord.y  = math.sin(current) * radius + center.y - textSize.y / 2
		current  = current + angle
		
		Render:DrawText(coord, t, fontColor, size) 
		Render:DrawLine(
			Vector2(math.cos(current) * innerRadius, math.sin(current) * innerRadius) + center, 
			Vector2(math.cos(current) * drawRad, math.sin(current) * drawRad) + center, 
			menuColor
		)
		current = current + angle
	end

	Render:FillCircle(center, innerRadius, backgroundColor)
	Render:DrawCircle(center, innerRadius, menuColor)
end
