-- QuickTP by ING

-- ##############################################################################################################

spawnFile      = "spawns.txt"
spawnHeight    = 200
spawnRandomize = Vector3(100, 100, 100)

-- ##############################################################################################################

spawns    = {}
spawnList = ""

QuickTP = function(args, player)
	-- Chat:Broadcast("QuickTP: " .. player:GetName() .. " to " .. args.target, Color(255, 255, 255))

	local vehicle = player:GetVehicle()
	local pos     = Vector3((math.random() - 0.5) * spawnRandomize.x, 
				(math.random() - 0.5) * spawnRandomize.y + spawnHeight, 
				(math.random() - 0.5) * spawnRandomize.z)

	player:SetPosition(spawns[args.target] + pos)

	if args.button == 2 and vehicle then
		vehicle:Teleport(player:GetPosition(), vehicle:GetAngle())
		player:EnterVehicle(vehicle, 0)
	end
end
Network:Subscribe("QuickTP", QuickTP)

SendTPList = function(args, player)
	if spawnList == "" then return end

	local args = {}
	args.list  = spawnList
	Network:Send(player, "TPList", args) 
end
Network:Subscribe("RequestTPList", SendTPList)

-- ##############################################################################################################
-- Copied and edited from the freeroam default script

-- Functions to parse the spawns
LoadSpawns = function( filename )
    local file = io.open( filename, "r" )

    if file == nil then
        print( "[QuickTP] No spawns.txt, aborting loading of spawns" )
        return
    end

    -- For each line, handle appropriately
    for line in file:lines() do
        if line:sub(1,1) == "T" then
            ParseTeleport( line )
        end
    end
    file:close()
end

ParseTeleport = function( line )
    -- Remove start, spaces
    line = line:sub( 3 )
    line = line:gsub( " ", "" )

    -- Split into tokens
    local tokens        = line:split( "," )
    -- Create table containing appropriate strings
    local pos_str       = { tokens[2], tokens[3], tokens[4] }
    -- Create vector
    local vector        = Vector3(   tonumber( pos_str[1] ), 
                                    tonumber( pos_str[2] ),
                                    tonumber( pos_str[3] ) )

    -- Save to teleports table
    spawns[ tokens[1] ] = vector

    if spawnList ~= "" then spawnList = spawnList .. "," end
    spawnList = spawnList .. tokens[1]
end
LoadSpawns(spawnFile)
