minetest.register_privilege("worldedit", "Can use WorldEdit commands")

worldedit.set_pos = {}

worldedit.pos1 = {}
worldedit.pos2 = {}
worldedit.prob_pos  = {}
worldedit.prob_list = {}

dofile(minetest.get_modpath("worldedit_commands") .. "/mark.lua")

worldedit.player_notify = function(name, message)
	minetest.chat_send_player(name, "WorldEdit -!- " .. message, false)
end

--determines whether `nodename` is a valid node name, returning a boolean
worldedit.normalize_nodename = function(nodename)
	if minetest.registered_nodes[nodename] then --directly found node name
		return nodename
	elseif minetest.registered_nodes["default:" .. nodename] then --found node name in default
		return "default:" .. nodename
	end
	for key, value in pairs(minetest.registered_nodes) do
		if key:find(":" .. nodename, 1, true) then --found in mod
			return key
		end
	end
	for key, value in pairs(minetest.registered_nodes) do
		if value.description:lower() == nodename:lower() then --found in description
			return key
		end
	end
	return nil
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
		worldedit.set_pos[name] = nil
		worldedit.player_notify(name, "region reset")
	end,
})

minetest.register_chatcommand("/mark", {
	params = "",
	description = "Show markers at the region positions",
	privs = {worldedit=true},
	func = function(name, param)
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, "region marked")
	end,
})

minetest.register_chatcommand("/unmark", {
	params = "",
	description = "Hide markers if currently shown",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.player_notify(name, "region unmarked")
	end,
})

minetest.register_chatcommand("/pos1", {
	params = "",
	description = "Set WorldEdit region position 1 to the player's location",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = minetest.env:get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)
		worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
	end,
})

minetest.register_chatcommand("/pos2", {
	params = "",
	description = "Set WorldEdit region position 2 to the player's location",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = minetest.env:get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
	end,
})

minetest.register_chatcommand("/p", {
	params = "set/set1/set2/get",
	description = "Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		if param == "set" then --set both WorldEdit positions
			worldedit.set_pos[name] = "pos1"
			worldedit.player_notify(name, "select positions by punching two nodes")
		elseif param == "set1" then --set WorldEdit position 1
			worldedit.set_pos[name] = "pos1only"
			worldedit.player_notify(name, "select position 1 by punching a node")
		elseif param == "set2" then --set WorldEdit position 2
			worldedit.set_pos[name] = "pos2"
			worldedit.player_notify(name, "select position 2 by punching a node")
		elseif param == "get" then --display current WorldEdit positions
			if worldedit.pos1[name] ~= nil then
				worldedit.player_notify(name, "position 1: " .. minetest.pos_to_string(worldedit.pos1[name]))
			else
				worldedit.player_notify(name, "position 1 not set")
			end
			if worldedit.pos2[name] ~= nil then
				worldedit.player_notify(name, "position 2: " .. minetest.pos_to_string(worldedit.pos2[name]))
			else
				worldedit.player_notify(name, "position 2 not set")
			end
		else
			worldedit.player_notify(name, "unknown subcommand: " .. param)
		end
	end,
})

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if name ~= "" and worldedit.set_pos[name] ~= nil then --currently setting position
		if worldedit.set_pos[name] == "pos1" then --setting position 1
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.set_pos[name] = "pos2" --set position 2 on the next invocation
			worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
		elseif worldedit.set_pos[name] == "pos1only" then --setting position 1 only
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.set_pos[name] = nil --finished setting positions
			worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
		elseif worldedit.set_pos[name] == "pos2" then --setting position 2
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			worldedit.set_pos[name] = nil --finished setting positions
			worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
		elseif worldedit.set_pos[name] == "prob" then --setting Minetest schematic node probabilities
			worldedit.prob_pos[name] = pos
			minetest.show_formspec(puncher:get_player_name(), "prob_val_enter", "field[text;;]")
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
			worldedit.player_notify(name, "no region selected")
			return
		end

		local volume = worldedit.volume(pos1, pos2)
		worldedit.player_notify(name, "current region has a volume of " .. volume .. " nodes (" .. pos2.x - pos1.x .. "*" .. pos2.y - pos1.y .. "*" .. pos2.z - pos1.z .. ")")
	end,
})

minetest.register_chatcommand("/set", {
	params = "<node>",
	description = "Set the current WorldEdit region to <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local node = worldedit.normalize_nodename(param)
		if param == "" or not node then
			worldedit.player_notify(name, "invalid node name: " .. param)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end

		local count = worldedit.set(pos1, pos2, node, tenv)
		worldedit.player_notify(name, count .. " nodes set")
	end,
})

minetest.register_chatcommand("/replace", {
	params = "<search node> <replace node>",
	description = "Replace all instances of <search node> with <replace node> in the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local newsearchnode = worldedit.normalize_nodename(searchnode)
		if not newsearchnode then
			worldedit.player_notify(name, "invalid search node name: " .. searchnode)
			return
		end
		local newreplacenode = worldedit.normalize_nodename(replacenode)
		if not newreplacenode then
			worldedit.player_notify(name, "invalid replace node name: " .. replacenode)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.replace(pos1, pos2, newsearchnode, newreplacenode, tenv)
		worldedit.player_notify(name, count .. " nodes replaced")
	end,
})

minetest.register_chatcommand("/replaceinverse", {
	params = "<search node> <replace node>",
	description = "Replace all nodes other than <search node> with <replace node> in the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local newsearchnode = worldedit.normalize_nodename(searchnode)
		if not newsearchnode then
			worldedit.player_notify(name, "invalid search node name: " .. searchnode)
			return
		end
		local newreplacenode = worldedit.normalize_nodename(replacenode)
		if not newreplacenode then
			worldedit.player_notify(name, "invalid replace node name: " .. replacenode)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.replaceinverse(pos1, pos2, searchnode, replacenode, tenv)
		worldedit.player_notify(name, count .. " nodes replaced")
	end,
})

minetest.register_chatcommand("/hollowsphere", {
	params = "<radius> <node>",
	description = "Add hollow sphere at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.hollow_sphere(pos, tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/sphere", {
	params = "<radius> <node>",
	description = "Add sphere at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.sphere(pos, tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/hollowdome", {
	params = "<radius> <node>",
	description = "Add hollow dome at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.hollow_dome(pos, tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/dome", {
	params = "<radius> <node>",
	description = "Add dome at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.dome(pos, tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/hollowcylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.hollow_cylinder(pos, axis, tonumber(length), tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/cylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.cylinder(pos, axis, tonumber(length), tonumber(radius), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/pyramid", {
	params = "<height> <node>",
	description = "Add pyramid at WorldEdit position 1 with height <height>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, size, nodename = param:find("(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.pyramid(pos, tonumber(size), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/spiral", {
	params = "<width> <height> <space> <node>",
	description = "Add spiral at WorldEdit position 1 with width <width>, height <height>, space between walls <space>, composed of <node>",
	privs = {worldedit=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, width, height, space, nodename = param:find("(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			worldedit.player_notify(name, "invalid node name: " .. nodename)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.spiral(pos, tonumber(width), tonumber(height), tonumber(space), node, tenv)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

minetest.register_chatcommand("/copy", {
	params = "x/y/z/? <amount>",
	description = "Copy the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.copy(pos1, pos2, axis, tonumber(amount), tenv)
		worldedit.player_notify(name, count .. " nodes copied")
	end,
})

minetest.register_chatcommand("/move", {
	params = "x/y/z/? <amount>",
	description = "Move the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.move(pos1, pos2, axis, tonumber(amount), tenv)

		pos1[axis] = pos1[axis] + amount
		pos2[axis] = pos2[axis] + amount
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, count .. " nodes moved")
	end,
})

minetest.register_chatcommand("/stack", {
	params = "x/y/z/? <count>",
	description = "Stack the current WorldEdit region along the x/y/z/? axis <count> times",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, count = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			count = count * sign
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.stack(pos1, pos2, axis, tonumber(count), tenv)
		worldedit.player_notify(name, count .. " nodes stacked")
	end,
})

minetest.register_chatcommand("/scale", {
	params = "<factor>",
	description = "Scale the current WorldEdit positions and region by a factor of positive integer <factor> with position 1 as the origin",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local factor = tonumber(param)
		if not factor or factor ~= math.floor(factor) or factor <= 0 then
			worldedit.player_notify(name, "invalid scaling factor: " .. param)
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count, pos1, pos2 = worldedit.scale(pos1, pos2, factor, tenv)

		--reset markers to scaled positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)

		worldedit.player_notify(name, count .. " nodes scaled")
	end,
})

minetest.register_chatcommand("/transpose", {
	params = "x/y/z/? x/y/z/?",
	description = "Transpose the current WorldEdit region along the x/y/z/? and x/y/z/? axes",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis1 == "?" then
			axis1 = worldedit.player_axis(name)
		end
		if axis2 == "?" then
			axis2 = worldedit.player_axis(name)
		end
		if axis1 == axis2 then
			worldedit.player_notify(name, "invalid usage: axes must be different")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2, tenv)

		--reset markers to transposed positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)

		worldedit.player_notify(name, count .. " nodes transposed")
	end,
})

minetest.register_chatcommand("/flip", {
	params = "x/y/z/?",
	description = "Flip the current WorldEdit region along the x/y/z/? axis",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		if param == "?" then
			param = worldedit.player_axis(name)
		end
		if param ~= "x" and param ~= "y" and param ~= "z" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.flip(pos1, pos2, param, tenv)
		worldedit.player_notify(name, count .. " nodes flipped")
	end,
})

minetest.register_chatcommand("/rotate", {
	params = "<axis> <angle>",
	description = "Rotate the current WorldEdit region around the axis <axis> by angle <angle> (90 degree increment)",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if axis == "?" then
			axis = worldedit.player_axis(name)
		end
		if angle % 90 ~= 0 then
			worldedit.player_notify(name, "invalid usage: angle must be multiple of 90")
			return
		end

		local count, pos1, pos2 = worldedit.rotate(pos1, pos2, axis, angle)

		--reset markers to rotated positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)

		worldedit.player_notify(name, count .. " nodes rotated")
	end,
})

minetest.register_chatcommand("/orient", {
	params = "<angle>",
	description = "Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle> (90 degree increment)",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local found, _, angle = param:find("^([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if angle % 90 ~= 0 then
			worldedit.player_notify(name, "invalid usage: angle must be multiple of 90")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.orient(pos1, pos2, angle, tenv)

		worldedit.player_notify(name, count .. " nodes oriented")
	end,
})

minetest.register_chatcommand("/fixlight", {
	params = "",
	description = "Fix the lighting in the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.fixlight(pos1, pos2, tenv)
		worldedit.player_notify(name, count .. " nodes updated")
	end,
})

minetest.register_chatcommand("/hide", {
	params = "",
	description = "Hide all nodes in the current WorldEdit region non-destructively",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.hide(pos1, pos2, tenv)
		worldedit.player_notify(name, count .. " nodes hidden")
	end,
})

minetest.register_chatcommand("/suppress", {
	params = "<node>",
	description = "Suppress all <node> in the current WorldEdit region non-destructively",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local node = worldedit.node_is_valid(param)
		if param == "" or not node then
			worldedit.player_notify(name, "invalid node name: " .. param)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.suppress(pos1, pos2, node, tenv)
		worldedit.player_notify(name, count .. " nodes suppressed")
	end,
})

minetest.register_chatcommand("/highlight", {
	params = "<node>",
	description = "Highlight <node> in the current WorldEdit region by hiding everything else non-destructively",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local node = worldedit.node_is_valid(param)
		if param == "" or not node then
			worldedit.player_notify(name, "invalid node name: " .. param)
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.highlight(pos1, pos2, node, tenv)
		worldedit.player_notify(name, count .. " nodes highlighted")
	end,
})

minetest.register_chatcommand("/restore", {
	params = "",
	description = "Restores nodes hidden with WorldEdit in the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.restore(pos1, pos2, tenv)
		worldedit.player_notify(name, count .. " nodes restored")
	end,
})

minetest.register_chatcommand("/save", {
	params = "<file>",
	description = "Save the current WorldEdit region to \"(world folder)/schems/<file>.we\"",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		if param == "" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end

		local result, count = worldedit.serialize(pos1, pos2)

		local path = minetest.get_worldpath() .. "/schems"
		local filename = path .. "/" .. param .. ".we"
		os.execute("mkdir \"" .. path .. "\"") --create directory if it does not already exist
		local file, err = io.open(filename, "wb")
		if err ~= nil then
			worldedit.player_notify(name, "could not save file to \"" .. filename .. "\"")
			return
		end
		file:write(result)
		file:flush()
		file:close()

		worldedit.player_notify(name, count .. " nodes saved")
	end,
})

minetest.register_chatcommand("/allocate", {
	params = "<file>",
	description = "Set the region defined by nodes from \"(world folder)/schems/<file>.we\" as the current WorldEdit region",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		if param == "" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end

		local filename = minetest.get_worldpath() .. "/schems/" .. param .. ".we"
		local file, err = io.open(filename, "rb")
		if err ~= nil then
			worldedit.player_notify(name, "could not open file \"" .. filename .. "\"")
			return
		end
		local value = file:read("*a")
		file:close()

		if worldedit.valueversion(value) == 0 then --unknown version
			worldedit.player_notify(name, "invalid file: file is invalid or created with newer version of WorldEdit")
			return
		end
		local nodepos1, nodepos2, count = worldedit.allocate(pos1, value)

		worldedit.pos1[name] = nodepos1
		worldedit.mark_pos1(name)
		worldedit.pos2[name] = nodepos2
		worldedit.mark_pos2(name)

		worldedit.player_notify(name, count .. " nodes allocated")
	end,
})

minetest.register_chatcommand("/load", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>[.we[m]]\" with position 1 of the current WorldEdit region as the origin",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		if param == "" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end

		--find the file in the world path
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
			worldedit.player_notify(name, "could not open file \"" .. param .. "\"")
			return
		end
		local value = file:read("*a")
		file:close()

		if worldedit.valueversion(value) == 0 then --unknown version
			worldedit.player_notify(name, "invalid file: file is invalid or created with newer version of WorldEdit")
			return
		end

		local tenv = minetest.env
		if worldedit.ENABLE_QUEUE then
			tenv = worldedit.queue_aliasenv
		end
		local count = worldedit.deserialize(pos1, value, tenv)

		worldedit.player_notify(name, count .. " nodes loaded")
	end,
})

minetest.register_chatcommand("/lua", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace",
	privs = {worldedit=true, server=true},
	func = function(name, param)
		local err = worldedit.lua(param)
		if err then
			worldedit.player_notify(name, "code error: " .. err)
		else
			worldedit.player_notify(name, "code successfully executed", false)
		end
	end,
})

minetest.register_chatcommand("/luatransform", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region",
	privs = {worldedit=true, server=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		local err = worldedit.luatransform(pos1, pos2, param)
		if err then
			worldedit.player_notify(name, "code error: " .. err, false)
		else
			worldedit.player_notify(name, "code successfully executed", false)
		end
	end,
})

minetest.register_chatcommand("/mtschemcreate", {
	params = "<filename>",
	description = "Creates a Minetest schematic of the box defined by position 1 and position 2, and saves it to <filename>",
	privs = {worldedit=true, server=true},
	func = function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end
		if param == nil then
			worldedit.player_notify(name, "no filename specified")
			return
		end

		local ret = minetest.create_schematic(pos1, pos2, worldedit.prob_list[name], tostring(param))
		if ret == nil then
			worldedit.player_notify(name, "Failed to create Minetest schematic", false)
		else
			worldedit.player_notify(name, "Saved Minetest schematic to " .. param, false)
		end
		worldedit.prob_list[name] = {}
	end,
})

minetest.register_chatcommand("/mtschemplace", {
	params = "<filename>",
	description = "Places the Minetest schematic identified by <filename> at WorldEdit position 1",
	privs = {worldedit=true, server=true},
	func = function(name, param)
		local pos = worldedit.pos1[name]
		if pos == nil then
			worldedit.player_notify(name, "no position selected")
			return
		end
		if param == nil then
			worldedit.player_notify(name, "no filename specified")
			return
		end

		if minetest.place_schematic(pos, param) == nil then
			worldedit.player_notify(name, "Failed to place Minetest schematic", false)
		else
			worldedit.player_notify(name, "Placed Minetest schematic " .. param ..
				" at " .. minetest.pos_to_string(pos), false)
		end
	end,
})

minetest.register_chatcommand("/mtschemprob", {
	params = "start/finish/get",
	description = "Begins node probability entry for Minetest schematics, gets the nodes that have probabilities set, or ends node probability entry",
	privs = {worldedit=true, server=true},
	func = function(name, param)
		if param == "start" then --start probability setting
			worldedit.set_pos[name] = "prob"
			worldedit.prob_list[name] = {}
			worldedit.player_notify(name, "select Minetest schematic probability values by punching nodes")
		elseif param == "finish" then --finish probability setting
			worldedit.set_pos[name] = nil
			worldedit.player_notify(name, "finished Minetest schematic probability selection")
		elseif param == "get" then --get all nodes that had probabilities set on them
			local text = ""
			local problist = worldedit.prob_list[name]
			if problist == nil then
				return
			end
			for k,v in pairs(problist) do
				local prob = math.floor(((v["prob"] / 256) * 100) * 100 + 0.5) / 100
				text = text .. minetest.pos_to_string(v["pos"]) .. ": " .. prob .. "% | "
			end
			worldedit.player_notify(name, "Currently set node probabilities:")
			worldedit.player_notify(name, text)
		else
			worldedit.player_notify(name, "unknown subcommand: " .. param)
		end
	end,
})

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		if (formname == "prob_val_enter") and (fields.text ~= "") then
			local name = player:get_player_name()
			local prob_entry = {pos=worldedit.prob_pos[name], prob=tonumber(fields.text)}
			local index = table.getn(worldedit.prob_list[name]) + 1
			worldedit.prob_list[name][index] = prob_entry
		end
	end
)

