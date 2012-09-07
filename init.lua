minetest.register_privilege("worldedit", "Can use WorldEdit commands")

worldedit = {}

worldedit.set_pos = {}

worldedit.pos1 = {}
worldedit.pos2 = {}

dofile(minetest.get_modpath("worldedit") .. "/functions.lua")
dofile(minetest.get_modpath("worldedit") .. "/mark.lua")
dofile(minetest.get_modpath("worldedit") .. "/table_save.lua")

--determines whether `nodename` is a valid node name, returning a boolean
worldedit.node_is_valid = function(temp_pos, nodename)
	return minetest.registered_nodes[nodename] ~= nil
	or minetest.registered_nodes["default:" .. nodename] ~= nil
end

--determines the axis in which a player is facing, returning an axis ("x", "y", or "z") and the sign (1 or -1)
worldedit.player_axis = function(name)
	local dir = minetest.env:get_player_by_name(name):get_look_dir()
	local x, y, z = math.abs(dir.x), math.abs(dir.y), math.abs(dir.z)
	if x > y then
		if x > z then
			return "x", dir.x > 0 and 1 or -1
		end
	elseif y > z then
		return "y", dir.y > 0 and 1 or -1
	end
	return "z", dir.z > 0 and 1 or -1
end

minetest.register_chatcommand("/reset", {
	params = "",
	description = "Reset the region so that it is empty",
	privs = {worldedit=true},
	func = function(name, param)
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		minetest.chat_send_player(name, "WorldEdit region reset")
	end,
})

minetest.register_chatcommand("/mark", {
	params = "",
	description = "Show markers at the region positions",
	privs = {worldedit=true},
	func = function(name, param)
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		minetest.chat_send_player(name, "WorldEdit region marked")
	end,
})

minetest.register_chatcommand("/pos1", {
	params = "",
	description = "Set WorldEdit region position 1 to the player's location",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = minetest.env:get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)
		minetest.chat_send_player(name, "WorldEdit position 1 set to " .. minetest.pos_to_string(pos))
	end,
})

minetest.register_chatcommand("/pos2", {
	params = "",
	description = "Set WorldEdit region position 2 to the player's location",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = minetest.env:get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)
		minetest.chat_send_player(name, "WorldEdit position 2 set to " .. minetest.pos_to_string(pos))
	end,
})

minetest.register_chatcommand("/p", {
	params = "set/get",
	description = "Set WorldEdit region by punching two nodes, or display the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		if param == "set" then --set both WorldEdit positions
			worldedit.set_pos[name] = 1
			minetest.chat_send_player(name, "Select positions by punching two nodes")
		elseif param == "get" then --display current WorldEdit positions
			if worldedit.pos1[name] ~= nil then
				minetest.chat_send_player(name, "WorldEdit position 1: " .. minetest.pos_to_string(worldedit.pos1[name]))
			else
				minetest.chat_send_player(name, "WorldEdit position 1 not set")
			end
			if worldedit.pos2[name] ~= nil then
				minetest.chat_send_player(name, "WorldEdit position 2: " .. minetest.pos_to_string(worldedit.pos2[name]))
			else
				minetest.chat_send_player(name, "WorldEdit position 2 not set")
			end
		else
			minetest.chat_send_player(name, "Unknown subcommand: " .. param)
		end
	end,
})

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if name ~= "" and worldedit.set_pos[name] ~= nil then --currently setting position
		if worldedit.set_pos[name] == 1 then --setting position 1
			worldedit.set_pos[name] = 2 --set position 2 on the next invocation
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			minetest.chat_send_player(name, "WorldEdit region position 1 set to " .. minetest.pos_to_string(pos))
		else --setting position 2
			worldedit.set_pos[name] = nil --finished setting positions
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			minetest.chat_send_player(name, "WorldEdit region position 2 set to " .. minetest.pos_to_string(pos))
		end
	end
end)

minetest.register_chatcommand("/volume", {
	params = "",
	description = "Display the volume of the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local volume = worldedit.volume(pos1, pos2)
		minetest.chat_send_player(name, "Current WorldEdit region has a volume of " .. volume .. " nodes (" .. pos2.x - pos1.x .. "*" .. pos2.y - pos1.y .. "*" .. pos2.z - pos1.z .. ")")
	end,
})

minetest.register_chatcommand("/set", {
	params = "<node>",
	description = "Set the current WorldEdit region to <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		if param == "" or not worldedit.node_is_valid(pos1, param) then
			minetest.chat_send_player(name, "Invalid node name: " .. param)
			return
		end

		local count = worldedit.set(pos1, pos2, param)
		minetest.chat_send_player(name, count .. " nodes set")
	end,
})

minetest.register_chatcommand("/replace", {
	params = "<search node> <replace node>",
	description = "Replace all instances of <search node> with <place node> in the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+([^%s]+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if not worldedit.node_is_valid(pos1, searchnode) then
			minetest.chat_send_player(name, "Invalid search node name: " .. searchnode)
			return
		end
		if not worldedit.node_is_valid(pos1, replacenode) then
			minetest.chat_send_player(name, "Invalid replace node name: " .. replacenode)
			return
		end

		local count = worldedit.replace(pos1, pos2, searchnode, replacenode)
		minetest.chat_send_player(name, count .. " nodes replaced")
	end,
})

minetest.register_chatcommand("/hollowcylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+([^%s]+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		if not worldedit.node_is_valid(pos, nodename) then
			minetest.chat_send_player(name, "Invalid node name: " .. param)
			return
		end

		local count = worldedit.hollow_cylinder(pos, axis, tonumber(length), tonumber(radius), nodename)
		minetest.chat_send_player(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/spiral", {
	params = "<size> <node>",
	description = "Add spiral at WorldEdit position 1 with size <size>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, size, nodename = param:find("(%d+)%s+([^%s]+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if not worldedit.node_is_valid(pos, nodename) then
			minetest.chat_send_player(name, "Invalid node name: " .. param)
			return
		end

		local count = worldedit.spiral(pos, tonumber(size), nodename)
		minetest.chat_send_player(name, count .. " nodes changed")
	end,
})

minetest.register_chatcommand("/cylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+([^%s]+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		if not worldedit.node_is_valid(pos, nodename) then
			minetest.chat_send_player(name, "Invalid node name: " .. param)
			return
		end

		local count = worldedit.cylinder(pos, axis, tonumber(length), tonumber(radius), nodename)
		minetest.chat_send_player(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/copy", {
	params = "x/y/z/? <amount>",
	description = "Copy the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local count = worldedit.copy(pos1, pos2, axis, tonumber(amount))
		minetest.chat_send_player(name, count .. " nodes copied")
	end,
})

minetest.register_chatcommand("/move", {
	params = "x/y/z/? <amount>",
	description = "Move the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local count = worldedit.move(pos1, pos2, axis, tonumber(amount))
		minetest.chat_send_player(name, count .. " nodes moved")
	end,
})

minetest.register_chatcommand("/stack", {
	params = "x/y/z/? <count>",
	description = "Stack the current WorldEdit region along the x/y/z/? axis <count> times",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, count = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			count = count * sign
		end

		local count = worldedit.stack(pos1, pos2, axis, tonumber(count))
		minetest.chat_send_player(name, count .. " nodes stacked")
	end,
})

minetest.register_chatcommand("/transpose", {
	params = "x/y/z/? x/y/z/?",
	description = "Transpose the current WorldEdit region along the x/y/z/? and x/y/z/? axes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis1 == "?" then
			axis1 = worldedit.player_axis(name)
		end
		if axis2 == "?" then
			axis2 = worldedit.player_axis(name)
		end
		if axis1 == axis2 then
			minetest.chat_send_player(name, "Invalid usage: axes are the same")
			return
		end

		local count = worldedit.transpose(pos1, pos2, axis1, axis2)
		minetest.chat_send_player(name, count .. " nodes transposed")
	end,
})

minetest.register_chatcommand("/flip", {
	params = "x/y/z/?",
	description = "Flip the current WorldEdit region along the x/y/z/? axis",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		if param == "?" then
			param = worldedit.player_axis(name)
		end
		if param ~= "x" and param ~= "y" and param ~= "z" then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end

		local count = worldedit.flip(pos1, pos2, param)
		minetest.chat_send_player(name, count .. " nodes flipped")
	end,
})

minetest.register_chatcommand("/rotate", {
	params = "<axis> <angle>",
	description = "Rotate the current WorldEdit region around the axis <axis> by angle <angle> (90 degree increment)",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis = worldedit.player_axis(name)
		end
		if angle % 90 ~= 0 then
			minetest.chat_send_player(name, "Invalid usage: angle must be multiple of 90")
			return
		end

		local count = worldedit.rotate(pos1, pos2, axis, angle)
		minetest.chat_send_player(name, count .. " nodes rotated")
	end,
})

minetest.register_chatcommand("/dig", {
	params = "",
	description = "Dig the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		local count = worldedit.dig(pos1, pos2)
		minetest.chat_send_player(name, count .. " nodes dug")
	end,
})

minetest.register_chatcommand("/save", {
	params = "<file>",
	description = "Save the current WorldEdit region to \"(world folder)/schems/<file>.we\"",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		if param == "" then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end

		local result, count = worldedit.serialize(pos1, pos2)

		local path = minetest.get_worldpath() .. "/schems"
		local filename = path .. "/" .. param .. ".we"
		os.execute("mkdir \"" .. path .. "\"") --create directory if it does not already exist
		local file, err = io.open(filename, "wb")
		if err ~= nil then
			minetest.chat_send_player(name, "Could not save file to \"" .. filename .. "\"")
			return
		end
		file:write(result)
		file:flush()
		file:close()

		minetest.chat_send_player(name, count .. " nodes saved")
	end,
})

minetest.register_chatcommand("/load", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>.we\" with position 1 of the current WorldEdit region as the origin",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end

		if param == "" then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end

		local filename = minetest.get_worldpath() .. "/schems/" .. param .. ".we"
		local file, err = io.open(filename, "rb")
		if err ~= nil then
			minetest.chat_send_player(name, "Could not open file \"" .. filename .. "\"")
			return
		end
		local value = file:read("*a")
		file:close()

		local count
		if value:find("{") then --old WorldEdit format
			count = worldedit.deserialize_old(pos1, value)
		else --new WorldEdit format
			count = worldedit.deserialize(pos1, value)
		end

		minetest.chat_send_player(name, count .. " nodes loaded")
	end,
})

minetest.register_chatcommand("/metasave", {
	params = "<file>",
	description = "Save the current WorldEdit region to \"(world folder)/schems/<file>.wem\"",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end
		if param == "" then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		local count, err = worldedit.metasave(pos1, pos2, param)
		if err then
			minetest.chat_send_player(name, "error loading file: " .. err)
		else
			minetest.chat_send_player(name, count .. " nodes saved")
		end
	end,
})

minetest.register_chatcommand("/metaload", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>.wem\" with position 1 of the current WorldEdit region as the origin",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			minetest.chat_send_player(name, "No WorldEdit region selected")
			return
		end
		if param == "" then
			minetest.chat_send_player(name, "Invalid usage: " .. param)
			return
		end
		local count, err = worldedit.metaload(pos1, param)
		if err then
			minetest.chat_send_player(name, "error loading file: " .. err)
		else
			minetest.chat_send_player(name, count .. " nodes loaded")
		end
	end,
})
