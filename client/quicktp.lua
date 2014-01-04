-- QuickTP by ING

-- ##############################################################################################################

key        = "G"                  -- The assigned key to the menu
fontSize   = 40                   -- Base fontsize, it will be modified depending on the entrycount and screensize
fontColor  = Color(255, 255, 255) -- Textcolor
fontUpper  = true                 -- Upper the text

-- ##############################################################################################################

subRender  = nil
subMouse   = nil
subKey     = nil

spawns     = nil
spawnCount = nil
selection  = nil

menuOpen   = false

-- ##############################################################################################################

ReceiveTPList = function(args)
	spawns     = args.list:split(",")
	spawnCount = table.count(spawns)
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

MouseClick = function(args)
	sendArgs = {}
	sendArgs.target = spawns[selection + 1]
	sendArgs.button = args.button
	Network:Send("QuickTP", sendArgs)
	CloseMenu()
end

-- ##############################################################################################################

OpenMenu = function()
	subRender = Events:Subscribe("Render", RenderMenu)
	subMouse  = Events:Subscribe("MouseDown", MouseClick)

	Mouse:SetPosition(Vector2(Render.Width / 2, Render.Height / 2))
	Mouse:SetVisible(true)
	Input:SetEnabled(false)

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
	local size     = fontSize - spawnCount * 1.8 + Render.Width / 100
	if size < 12 then size = 12 end
	
	local radius   = Render.Height / 2 - fontSize
	local angle    = math.pi / spawnCount
	local center   = Vector2(Render.Width / 2, Render.Height / 2)
	local drawRad  = 1500

	local current  = 0
	local textSize = nil
	local coord    = Vector2()

	local mouseP   = Mouse:GetPosition()
	local mouseA   = math.atan2(mouseP.y - center.y, mouseP.x - center.x)
	selection      = math.floor(((mouseA + angle) / (math.pi * 2)) * spawnCount)

	if selection < 0 then selection = selection + spawnCount end

	Render:FillArea(Vector2(0, 0), Render.Size, Color(0,0,0,100))

	Render:FillTriangle(
		center,
		Vector2(math.cos(selection * (angle*2) - angle) * drawRad + center.x, math.sin(selection * (angle*2) - angle) * drawRad + center.y),
		Vector2(math.cos(selection * (angle*2) + angle) * drawRad + center.x, math.sin(selection * (angle*2) + angle) * drawRad + center.y),
		Color(255, 0, 0, 100)
	)

	for i,t in ipairs(spawns) do
		if fontUpper then t = string.upper(t) end

		textSize = Render:GetTextSize(t, size) 
		coord.x  = math.cos(current) * radius + center.x - textSize.x / 2
		coord.y  = math.sin(current) * radius + center.y - textSize.y / 2
		current  = current + angle
		
		Render:DrawText(coord, t, fontColor, size) 
		Render:DrawLine(center, Vector2(math.cos(current) * drawRad + center.x, math.sin(current) * drawRad + center.y), Color(255,255,255,100))
		current = current + angle
	end
end
