local S = minetest.get_translator("worldedit_commands")

worldedit.prob_pos = {}
worldedit.prob_list = {}

local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end

local function check_filename(name)
	return name:find("^[%w%s%^&'@{}%[%],%$=!%-#%(%)%%%.%+~_]+$") ~= nil
end

local function open_schematic(name, param)
	-- find the file in the world path
	local testpaths = {
		minetest.get_worldpath() .. "/schems/" .. param,
		minetest.get_worldpath() .. "/schems/" .. param .. ".we",
		minetest.get_worldpath() .. "/schems/" .. param .. ".wem",
	}
	local file, err
	for index, path in ipairs(testpaths) do
		file, err = io.open(path, "rb")
		if not err then
			break
		end
	end
	if err then
		worldedit.player_notify(name, S("Could not open file \"@1\"", param))
		return
	end
	local value = file:read("*a")
	file:close()

	local version = worldedit.read_header(value)
	if version == nil or version == 0 then
		worldedit.player_notify(name, S("Invalid file format!"))
		return
	elseif version > worldedit.LATEST_SERIALIZATION_VERSION then
		worldedit.player_notify(name, S("Schematic was created with a newer version of WorldEdit."))
		return
	end

	return value
end

local function detect_misaligned_schematic(name, pos1, pos2)
	pos1 = worldedit.sort_pos(pos1, pos2)
	-- Check that allocate/save can position the schematic correctly
	-- The expected behaviour is that the (0,0,0) corner of the schematic stays
	-- at pos1, this only works when the minimum position is actually present
	-- in the schematic.
	local node = minetest.get_node(pos1)
	local have_node_at_origin = node.name ~= "air" and node.name ~= "ignore"
	if not have_node_at_origin then
		worldedit.player_notify(name,
			S("Warning: The schematic contains excessive free space and WILL be "..
			"misaligned when allocated or loaded. To avoid this, shrink your "..
			"area to cover exactly the nodes to be saved.")
		)
	end
end


worldedit.register_command("save", {
	params = "<file>",
	description = S("Save the current WorldEdit region to \"(world folder)/schems/<file>.we\""),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local result, count = worldedit.serialize(worldedit.pos1[name],
				worldedit.pos2[name])
		detect_misaligned_schematic(name, worldedit.pos1[name], worldedit.pos2[name])

		local path = minetest.get_worldpath() .. "/schems"
		-- Create directory if it does not already exist
		minetest.mkdir(path)

		local filename = path .. "/" .. param .. ".we"
		local file, err = io.open(filename, "wb")
		if err ~= nil then
			worldedit.player_notify(name, S("Could not save file to \"@1\"", filename))
			return
		end
		file:write(result)
		file:flush()
		file:close()

		worldedit.player_notify(name, S("@1 nodes saved", count))
	end,
})

worldedit.register_command("allocate", {
	params = "<file>",
	description = S("Set the region defined by nodes from \"(world folder)/schems/<file>.we\" as the current WorldEdit region"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local value = open_schematic(name, param)
		if not value then
			return false
		end

		local nodepos1, nodepos2, count = worldedit.allocate(pos, value)
		if not nodepos1 then
			worldedit.player_notify(name, S("Schematic empty, nothing allocated"))
			return false
		end

		worldedit.pos1[name] = nodepos1
		worldedit.pos2[name] = nodepos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, S("@1 nodes allocated", count))
	end,
})

worldedit.register_command("load", {
	params = "<file>",
	description = S("Load nodes from \"(world folder)/schems/<file>[.we[m]]\" with position 1 of the current WorldEdit region as the origin"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local value = open_schematic(name, param)
		if not value then
			return false
		end

		local count = worldedit.deserialize(pos, value)
		if count == nil then
			worldedit.player_notify(name, S("Loading failed!"))
			return false
		end
		worldedit.player_notify(name, S("@1 nodes loaded", count))
	end,
})


worldedit.register_command("mtschemcreate", {
	params = "<file>",
	description = S("Save the current WorldEdit region using the Minetest "..
		"Schematic format to \"(world folder)/schems/<filename>.mts\""),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local path = minetest.get_worldpath() .. "/schems"
		-- Create directory if it does not already exist
		minetest.mkdir(path)

		local filename = path .. "/" .. param .. ".mts"
		local ret = minetest.create_schematic(worldedit.pos1[name],
				worldedit.pos2[name], worldedit.prob_list[name],
				filename)
		if ret == nil then
			worldedit.player_notify(name, S("Failed to create Minetest schematic"))
		else
			worldedit.player_notify(name, S("Saved Minetest schematic to @1", param))
		end
		worldedit.prob_list[name] = {}
	end,
})

worldedit.register_command("mtschemplace", {
	params = "<file>",
	description = S("Load nodes from \"(world folder)/schems/<file>.mts\" with position 1 of the current WorldEdit region as the origin"),
	category = S("Schematics"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, S("Disallowed file name: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local path = minetest.get_worldpath() .. "/schems/" .. param .. ".mts"
		if minetest.place_schematic(pos, path) == nil then
			worldedit.player_notify(name, S("failed to place Minetest schematic"))
		else
			worldedit.player_notify(name, S("placed Minetest schematic @1 at @2", param, minetest.pos_to_string(pos)))
		end
	end,
})

worldedit.register_command("mtschemprob", {
	params = "start/finish/get",
	description = S("Begins node probability entry for Minetest schematics, gets the nodes that have probabilities set, or ends node probability entry"),
	category = S("Schematics"),
	privs = {worldedit=true},
	parse = function(param)
		if param ~= "start" and param ~= "finish" and param ~= "get" then
			return false, S("unknown subcommand: @1", param)
		end
		return true, param
	end,
	func = function(name, param)
		if param == "start" then --start probability setting
			worldedit.set_pos[name] = "prob"
			worldedit.prob_list[name] = {}
			worldedit.player_notify(name, S("select Minetest schematic probability values by punching nodes"))
		elseif param == "finish" then --finish probability setting
			worldedit.set_pos[name] = nil
			worldedit.player_notify(name, S("finished Minetest schematic probability selection"))
		elseif param == "get" then --get all nodes that had probabilities set on them
			local text = ""
			local problist = worldedit.prob_list[name]
			if problist == nil then
				return
			end
			for k,v in pairs(problist) do
				local prob = math.floor(((v.prob / 256) * 100) * 100 + 0.5) / 100
				text = text .. minetest.pos_to_string(v.pos) .. ": " .. prob .. "% | "
			end
			worldedit.player_notify(name, S("currently set node probabilities:"))
			worldedit.player_notify(name, text)
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "prob_val_enter" then
		local name = player:get_player_name()
		local problist = worldedit.prob_list[name]
		if problist == nil then
			return
		end
		local e = {pos=worldedit.prob_pos[name], prob=tonumber(fields.text)}
		if e.pos == nil or e.prob == nil or e.prob < 0 or e.prob > 256 then
			worldedit.player_notify(name, S("invalid node probability given, not saved"))
			return
		end
		problist[#problist+1] = e
	end
end)

