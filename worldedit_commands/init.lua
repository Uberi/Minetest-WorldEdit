minetest.register_privilege("worldedit", "Can use WorldEdit commands")

--wip: fold the hollow stuff into the main functions and add a hollow flag at the end, then add the compatibility stuff

worldedit.set_pos = {}
worldedit.inspect = {}

worldedit.pos1 = {}
worldedit.pos2 = {}
if minetest.place_schematic then
	worldedit.prob_pos = {}
	worldedit.prob_list = {}
end

dofile(minetest.get_modpath("worldedit_commands") .. "/mark.lua")
dofile(minetest.get_modpath("worldedit_commands") .. "/safe.lua")

local get_position = function(name)
	local pos1 = worldedit.pos1[name]
	if pos1 == nil then
		worldedit.player_notify(name, "no position 1 selected")
	end
	return pos1
end

local get_node = function(name, nodename)
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		worldedit.player_notify(name, "invalid node name: " .. nodename)
		return nil
	end
	return node
end

worldedit.player_notify = function(name, message)
	minetest.chat_send_player(name, "WorldEdit -!- " .. message, false)
end

--determines whether `nodename` is a valid node name, returning a boolean
worldedit.normalize_nodename = function(nodename)
	if nodename == "" then return nil end
	local fullname = ItemStack({name=nodename}):get_name() --resolve aliases of node names to full names
	if minetest.registered_nodes[fullname] or fullname == "air" then --directly found node name or alias of nodename
		return fullname
	end
	for key, value in pairs(minetest.registered_nodes) do
		if key:find(":" .. nodename, 1, true) then --found in mod
			return key
		end
	end
	nodename = nodename:lower() --lowercase both for case insensitive comparison
	for key, value in pairs(minetest.registered_nodes) do
		if value.description:lower() == nodename then --found in description
			return key
		end
	end
	return nil
end

--determines the axis in which a player is facing, returning an axis ("x", "y", or "z") and the sign (1 or -1)
worldedit.player_axis = function(name)
	local dir = minetest.get_player_by_name(name):get_look_dir()
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

minetest.register_chatcommand("/about", {
	params = "",
	description = "Get information about the mod",
	func = function(name, param)
		worldedit.player_notify(name, "WorldEdit " .. worldedit.version_string .. " is available on this server. Type /help to get a list of commands, or get more information at https://github.com/Uberi/MineTest-WorldEdit/")
	end,
})

minetest.register_chatcommand("/inspect", {
	params = "on/off/1/0/true/false/yes/no/enable/disable/<blank>",
	description = "Enable or disable node inspection",
	privs = {},
	func = worldedit.privs(function(name, param)
		if param == "on" or param == "1" or param == "true" or param == "yes" or param == "enable" or param == "" then
			worldedit.inspect[name] = true
			local axis, sign = worldedit.player_axis(name)
			worldedit.player_notify(name, string.format("inspector: inspection enabled for %s, currently facing the %s axis",
				name, axis .. (sign > 0 and "+" or "-")))
		elseif param == "off" or param == "0" or param == "false" or param == "no" or param == "disable" then
			worldedit.inspect[name] = nil
			worldedit.player_notify(name, "inspector: inspection disabled")
		else
			worldedit.player_notify(name, "invalid usage: " .. param)
		end
	end),
})

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if worldedit.inspect[name] then
		if worldedit.privs() then
			local axis, sign = worldedit.player_axis(name)
			message = string.format("inspector: %s at %s (param1=%d, param2=%d) punched by %s facing the %s axis",
				node.name, minetest.pos_to_string(pos), node.param1, node.param2, name, axis .. (sign > 0 and "+" or "-"))
		else
			message = "inspector: worldedit privileges required"
			worldedit.inspect[name] = nil
		end
		worldedit.player_notify(name, message)
	end
end)

minetest.register_chatcommand("/reset", {
	params = "",
	description = "Reset the region so that it is empty",
	privs = {},
	func = worldedit.privs(function(name, param)
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.set_pos[name] = nil
		worldedit.player_notify(name, "region reset")
	end),
})

minetest.register_chatcommand("/mark", {
	params = "",
	description = "Show markers at the region positions",
	privs = {},
	func = worldedit.privs(function(name, param)
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, "region marked")
	end),
})

minetest.register_chatcommand("/unmark", {
	params = "",
	description = "Hide markers if currently shown",
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.player_notify(name, "region unmarked")
	end),
})

minetest.register_chatcommand("/pos1", {
	params = "",
	description = "Set WorldEdit region position 1 to the player's location",
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos = minetest.get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)
		worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
	end),
})

minetest.register_chatcommand("/pos2", {
	params = "",
	description = "Set WorldEdit region position 2 to the player's location",
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos = minetest.get_player_by_name(name):getpos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
	end),
})

minetest.register_chatcommand("/p", {
	params = "set/set1/set2/get",
	description = "Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region",
	privs = {},
	func = worldedit.privs(function(name, param)
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
	end),
})

minetest.register_chatcommand("/fixedpos", {
	params = "set1/set2 x y z",
	description = "Set a WorldEdit region position to the position at (<x>, <y>, <z>)",
	privs = {},
	func = worldedit.privs(function(name, param)
		local found, _, flag, x, y, z = param:find("^(set[12])%s+([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		local pos = {x=tonumber(x), y=tonumber(y), z=tonumber(z)}
		if flag == "set1" then
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
		else --flag == "set2"
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
		end
	end),
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
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return nil
		end

		local volume = worldedit.volume(pos1, pos2)
		local abs = math.abs
		worldedit.player_notify(name, "current region has a volume of " .. volume .. " nodes ("
			.. abs(pos2.x - pos1.x) + 1 .. "*"
			.. abs(pos2.y - pos1.y) + 1 .. "*"
			.. abs(pos2.z - pos1.z) + 1 .. ")")
	end),
})

local check_set = function(name, param)
	local node = get_node(name, param)
	if not node then return nil end
	return check_region(name, param)
end

minetest.register_chatcommand("/set", {
	params = "<node>",
	description = "Set the current WorldEdit region to <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local node = get_node(name, param)
			local count = worldedit.set(pos1, pos2, node)
			worldedit.player_notify(name, count .. " nodes set")
		end
	end, check_set)),
})

local check_replace = function(name, param)
	local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
	if found == nil then
		worldedit.player_notify(name, "invalid usage: " .. param)
		return nil
	end
	local newsearchnode = worldedit.normalize_nodename(searchnode)
	if not newsearchnode then
		worldedit.player_notify(name, "invalid search node name: " .. searchnode)
		return nil
	end
	local newreplacenode = worldedit.normalize_nodename(replacenode)
	if not newreplacenode then
		worldedit.player_notify(name, "invalid replace node name: " .. replacenode)
		return nil
	end
	return check_region(name, param)
end

minetest.register_chatcommand("/replace", {
	params = "<search node> <replace node>",
	description = "Replace all instances of <search node> with <replace node> in the current WorldEdit region",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
			local newsearchnode = worldedit.normalize_nodename(searchnode)
			local newreplacenode = worldedit.normalize_nodename(replacenode)
			local count = worldedit.replace(pos1, pos2, newsearchnode, newreplacenode)
			worldedit.player_notify(name, count .. " nodes replaced")
		end
	end, check_replace)),
})

minetest.register_chatcommand("/replaceinverse", {
	params = "<search node> <replace node>",
	description = "Replace all nodes other than <search node> with <replace node> in the current WorldEdit region",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
			local newsearchnode = worldedit.normalize_nodename(searchnode)
			local newreplacenode = worldedit.normalize_nodename(replacenode)
			local count = worldedit.replaceinverse(pos1, pos2, searchnode, replacenode)
			worldedit.player_notify(name, count .. " nodes replaced")
		end
	end, check_replace)),
})

local check_sphere = function(name, param)
	if worldedit.pos1[name] == nil then
		worldedit.player_notify(name, "no position 1 selected")
		return nil
	end
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		worldedit.player_notify(name, "invalid usage: " .. param)
		return nil
	end
	local node = get_node(name, nodename)
	if not node then return nil end
	return math.ceil((4 * math.pi * (tonumber(radius) ^ 3)) / 3) --volume of sphere
end

minetest.register_chatcommand("/hollowsphere", {
	params = "<radius> <node>",
	description = "Add hollow sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if worldedit.can_edit_volume(name, {{x=pos.x-radius, y=pos.y-radius, z=pos.z-radius}, {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}}) then
			local node = get_node(name, nodename)
			local count = worldedit.hollow_sphere(pos, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_sphere)),
})

minetest.register_chatcommand("/sphere", {
	params = "<radius> <node>",
	description = "Add sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if worldedit.can_edit_volume(name, {{x=pos.x-radius, y=pos.y-radius, z=pos.z-radius}, {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}}) then
			local node = get_node(name, nodename)
			local count = worldedit.sphere(pos, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_sphere)),
})

local check_dome = function(name, param)
	if worldedit.pos1[name] == nil then
		worldedit.player_notify(name, "no position 1 selected")
		return nil
	end
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		worldedit.player_notify(name, "invalid usage: " .. param)
		return nil
	end
	local node = get_node(name, nodename)
	if not node then return nil end
	return math.ceil((2 * math.pi * (tonumber(radius) ^ 3)) / 3) --volume of dome
end

minetest.register_chatcommand("/hollowdome", {
	params = "<radius> <node>",
	description = "Add hollow dome centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if worldedit.can_edit_volume(name, {{x=pos.x-radius, y=pos.y, z=pos.z-radius}, {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}}) then
			local node = get_node(name, nodename)
			local count = worldedit.hollow_dome(pos, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_dome)),
})

minetest.register_chatcommand("/dome", {
	params = "<radius> <node>",
	description = "Add dome centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
		if worldedit.can_edit_volume(name, {{x=pos.x-radius, y=pos.y, z=pos.z-radius}, {x=pos.x+radius, y=pos.y+radius, z=pos.z+radius}}) then
			local node = get_node(name, nodename)
			local count = worldedit.dome(pos, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_dome)),
})

local check_cylinder = function(name, param)
	if worldedit.pos1[name] == nil then
		worldedit.player_notify(name, "no position 1 selected")
		return nil
	end
	local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		worldedit.player_notify(name, "invalid usage: " .. param)
		return nil
	end
	local node = get_node(name, nodename)
	if not node then return nil end
	return math.ceil(math.pi * (tonumber(radius) ^ 2) * tonumber(length))
end

minetest.register_chatcommand("/hollowcylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		length = tonumber(length)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		if worldedit.can_edit_volume(name, {{x=pos.x-(axis~="x" and radius or 0), y=pos.y-(axis~="y" and radius or 0), z=pos.z-(axis~="z" and radius or 0)}, {x=pos.x+(axis~="x" and radius or length), y=pos.y+(axis~="y" and radius or length-1*sign), z=pos.z+(axis~="z" and radius or length-1*sign)}}) then
			local node = get_node(name, nodename)
			local count = worldedit.hollow_cylinder(pos, axis, length, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_cylinder)),
})

minetest.register_chatcommand("/cylinder", {
	params = "x/y/z/? <length> <radius> <node>",
	description = "Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, axis, length, radius, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		length = tonumber(length)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		if worldedit.can_edit_volume(name, {{x=pos.x-(axis~="x" and radius or 0), y=pos.y-(axis~="y" and radius or 0), z=pos.z-(axis~="z" and radius or 0)}, {x=pos.x+(axis~="x" and radius or length-1*sign), y=pos.y+(axis~="y" and radius or length-1*sign), z=pos.z+(axis~="z" and radius or length-1*sign)}}) then
			local node = get_node(name, nodename)
			local count = worldedit.cylinder(pos, axis, length, tonumber(radius), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end, check_cylinder)),
})

minetest.register_chatcommand("/pyramid", {
	params = "x/y/z/? <height> <node>",
	description = "Add pyramid centered at WorldEdit position 1 along the x/y/z/? axis with height <height>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = get_position(name)
		local found, _, axis, height, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(.+)$")
		height = tonumber(height)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		if worldedit.can_edit_volume(name, {{x=pos.x-(axis~="x" and height-1*sign or 0), y=pos.y-(axis~="y" and height-1*sign or 0), z=pos.z-(axis~="y" and height-1*sign or 0)}, {x=pos.x+height-1*sign, y=pos.y+height-1*sign, z=pos.z+height-1*sign}}) then
			local node = get_node(name, nodename)
			local count = worldedit.pyramid(pos, axis, height, node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end,
	function(name, param)
		if worldedit.pos1[name] == nil then
			worldedit.player_notify(name, "no position 1 selected")
			return nil
		end
		local found, _, axis, height, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		local node = get_node(name, nodename)
		if not node then return nil end
		height = tonumber(height)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end)),
})

minetest.register_chatcommand("/spiral", {
	params = "<length> <height> <space> <node>",
	description = "Add spiral centered at WorldEdit position 1 with side length <length>, height <height>, space between walls <space>, composed of <node>",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos = worldedit.pos1[name]
		local found, _, length, height, space, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		local extent = math.ceil(length / 2)
		if worldedit.can_edit_volume(name, {{x=0.5+pos.x-0.5-extent, y=pos.y, z=0.5+pos.z-0.5-extent}, {x=0.5+pos.x+0.5+extent, y=pos.y+height-1, z=0.5+pos.z+0.5+extent}}) then
			local node = get_node(name, nodename)
			local count = worldedit.spiral(pos, tonumber(length), tonumber(height), tonumber(space), node)
			worldedit.player_notify(name, count .. " nodes added")
		end
	end,
	function(name, param)
		if worldedit.pos1[name] == nil then
			worldedit.player_notify(name, "no position 1 selected")
			return nil
		end
		local found, _, length, height, space, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		local node = get_node(name, nodename)
		if not node then return nil end
		return check_region(name, param)
	end)),
})

minetest.register_chatcommand("/copy", {
	params = "x/y/z/? <amount>",
	description = "Copy the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		amount = tonumber(amount)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end
		if worldedit.can_edit_volume(name, {{x=pos1.x+(axis=="x" and amount or 0), y=pos1.y+(axis=="y" and amount or 0), z=pos1.z+(axis=="z" and amount or 0)}, {x=pos2.x+(axis=="x" and amount or 0), y=pos2.y+(axis=="y" and amount or 0), z=pos2.z+(axis=="z" and amount or 0)}}) then
			local count = worldedit.copy(pos1, pos2, axis, amount)
			worldedit.player_notify(name, count .. " nodes copied")
		end
	end,
	function(name, param)
		local volume = check_region(name, param)
		return volume and volume * 2 or volume
	end)),
})

minetest.register_chatcommand("/move", {
	params = "x/y/z/? <amount>",
	description = "Move the current WorldEdit region along the x/y/z/? axis by <amount> nodes",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		amount = tonumber(amount)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end
		if worldedit.can_edit_volume(name, {pos1, pos2, {x=pos1.x+(axis=="x" and amount or 0), y=pos1.y+(axis=="y" and amount or 0), z=pos1.z+(axis=="z" and amount or 0)}, {x=pos2.x+(axis=="x" and amount or 0), y=pos2.y+(axis=="y" and amount or 0), z=pos2.z+(axis=="z" and amount or 0)}}) then
			local count = worldedit.move(pos1, pos2, axis, amount)

			pos1[axis] = pos1[axis] + amount
			pos2[axis] = pos2[axis] + amount
			worldedit.mark_pos1(name)
			worldedit.mark_pos2(name)
			worldedit.player_notify(name, count .. " nodes moved")
		end
	end, check_region)),
})

minetest.register_chatcommand("/stack", {
	params = "x/y/z/? <count>",
	description = "Stack the current WorldEdit region along the x/y/z/? axis <count> times",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, axis, repetitions = param:find("^([xyz%?])%s+([+-]?%d+)$")
		repetitions = tonumber(repetitions)
		if axis == "?" then
			axis, sign = worldedit.player_axis(name)
			repetitions = repetitions * sign
		end
		if worldedit.can_edit_volume(name, {{x=(axis=="x" and pos2.x+1*sign or pos1.x), y=(axis=="y" and pos2.y+1*sign or pos1.x), z=(axis=="z" and pos2.z+1*sign or pos1.z)}, {x=pos2.x+repetitions*(axis=="x" and pos2.x-pos1.x+1*sign or 0), y=pos2.y+repititions*(axis=="y" and pos2.y-pos1.y+1*sign or 0), z=pos2.z+repititions*(axis=="z" and pos2.z-pos1.z+1*sign or 0)}}) then
			local count = worldedit.stack(pos1, pos2, axis, repetitions)
			worldedit.player_notify(name, count .. " nodes stacked")
		end
	end,
	function(name, param)
		local found, _, axis, repetitions = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
		end
		local count = check_region(name, param)
		if count then return (tonumber(repetitions) + 1) * count end
		return nil
	end)),
})

minetest.register_chatcommand("/stretch", {
	params = "<stretchx> <stretchy> <stretchz>",
	description = "Scale the current WorldEdit positions and region by a factor of <stretchx>, <stretchy>, <stretchz> along the X, Y, and Z axes, repectively, with position 1 as the origin",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, stretchx, stretchy, stretchz = param:find("^(%d+)%s+(%d+)%s+(%d+)$")
		stretchx, stretchy, stretchz = tonumber(stretchx), tonumber(stretchy), tonumber(stretchz)
		if worldedit.can_edit_volume(name, {pos1, {x=pos1.x + (pos2.x - pos1.x) * stretchx, y=pos1.y + (pos2.y - pos1.y) * stretchy, z=pos1.z + (pos2.z - pos1.z) * stretchz}}) then
			local count, pos1, pos2 = worldedit.stretch(pos1, pos2, stretchx, stretchy, stretchz)

			--reset markers to scaled positions
			worldedit.pos1[name] = pos1
			worldedit.pos2[name] = pos2
			worldedit.mark_pos1(name)
			worldedit.mark_pos2(name)

			worldedit.player_notify(name, count .. " nodes stretched")
		end
	end,
	function(name, param)
		local found, _, stretchx, stretchy, stretchz = param:find("^(%d+)%s+(%d+)%s+(%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		stretchx, stretchy, stretchz = tonumber(stretchx), tonumber(stretchy), tonumber(stretchz)
		if stretchx == 0 or stretchy == 0 or stretchz == 0 then
			worldedit.player_notify(name, "invalid scaling factors: " .. param)
		end
		local count = check_region(name, param)
		if count then return tonumber(stretchx) * tonumber(stretchy) * tonumber(stretchz) * count end
		return nil
	end)),
})

minetest.register_chatcommand("/transpose", {
	params = "x/y/z/? x/y/z/?",
	description = "Transpose the current WorldEdit region along the x/y/z/? and x/y/z/? axes",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if axis1 == "?" then axis1 = worldedit.player_axis(name) end
		if axis2 == "?" then axis2 = worldedit.player_axis(name) end
		local notaxis = (axis1~="x" and axis2~="x") and "x" or (
			(axis1~="y" and axis2~="y") and "y" or (
				(axis1~="z" and axis2~="z") and "z" or (
					assert(0)
				)
			)
		)
		local side = math.max( --does not include pos1 in the length
			(axis2=="x" or "x"==axis1) and pos2.x-pos1.x or 0,
			(axis2=="y" or "y"==axis1) and pos2.y-pos1.y or 0,
			(axis2=="z" or "z"==axis1) and pos2.z-pos1.z or 0
		)
		if worldedit.can_edit_volume(name, {pos1, {x=notaxis=="x" and pos2.x or pos1.x+side, y=notaxis=="y" and pos2.y or pos1.y+side, z=notaxis=="z" and pos2.z or pos1.z+side}}) then
			local count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2)

			--reset markers to transposed positions
			worldedit.pos1[name] = pos1
			worldedit.pos2[name] = pos2
			worldedit.mark_pos1(name)
			worldedit.mark_pos2(name)

			worldedit.player_notify(name, count .. " nodes transposed")
		end
	end,
	function(name, param)
		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		if axis1 == axis2 then
			worldedit.player_notify(name, "invalid usage: axes must be different")
			return nil
		end
		return check_region(name, param)
	end)),
})

minetest.register_chatcommand("/flip", {
	params = "x/y/z/?",
	description = "Flip the current WorldEdit region along the x/y/z/? axis",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if param == "?" then param = worldedit.player_axis(name) end
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.flip(pos1, pos2, param)
			worldedit.player_notify(name, count .. " nodes flipped")
		end
	end,
	function(name, param)
		if param ~= "x" and param ~= "y" and param ~= "z" and param ~= "?" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		return check_region(name, param)
	end)),
})

minetest.register_chatcommand("/rotate", {
	params = "<axis> <angle>",
	description = "Rotate the current WorldEdit region around the axis <axis> by angle <angle> (90 degree increment)",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if axis == "?" then axis = worldedit.player_axis(name) end
		local side = math.max(
			axis~="x" and pos2.x-pos1.x or 0,
			axis~="y" and pos2.y-pos1.y or 0,
			axis~="z" and pos2.z-pos1.z or 0
		)
		if worldedit.can_edit_volume(name, {pos1, {x=axis=="x" and pos2.x or pos1.x+side, y=axis=="y" and pos22.y or pos1.y+side, z=axis=="z" and pos2.z or pos1.z+side}}) then
			local count, pos1, pos2 = worldedit.rotate(pos1, pos2, axis, angle)

			--reset markers to rotated positions
			worldedit.pos1[name] = pos1
			worldedit.pos2[name] = pos2
			worldedit.mark_pos1(name)
			worldedit.mark_pos2(name)

			worldedit.player_notify(name, count .. " nodes rotated")
		end
	end,
	function(name, param)
		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		if angle % 90 ~= 0 then
			worldedit.player_notify(name, "invalid usage: angle must be multiple of 90")
			return nil
		end
		return check_region(name, param)
	end)),
})

minetest.register_chatcommand("/orient", {
	params = "<angle>",
	description = "Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle> (90 degree increment)",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local found, _, angle = param:find("^([+-]?%d+)$")
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.orient(pos1, pos2, angle)
			worldedit.player_notify(name, count .. " nodes oriented")
		end
	end,
	function(name, param)
		local found, _, angle = param:find("^([+-]?%d+)$")
		if found == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return nil
		end
		if angle % 90 ~= 0 then
			worldedit.player_notify(name, "invalid usage: angle must be multiple of 90")
			return nil
		end
		return check_region(name, param)
	end)),
})

minetest.register_chatcommand("/fixlight", {
	params = "",
	description = "Fix the lighting in the current WorldEdit region",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.fixlight(pos1, pos2)
			worldedit.player_notify(name, count .. " nodes updated")
		end
	end)),
})

minetest.register_chatcommand("/hide", {
	params = "",
	description = "Hide all nodes in the current WorldEdit region non-destructively",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.hide(pos1, pos2)
			worldedit.player_notify(name, count .. " nodes hidden")
		end
	end)),
})

minetest.register_chatcommand("/suppress", {
	params = "<node>",
	description = "Suppress all <node> in the current WorldEdit region non-destructively",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local node = get_node(name, param)
			local count = worldedit.suppress(pos1, pos2, node)
			worldedit.player_notify(name, count .. " nodes suppressed")
		end
	end, check_set)),
})

minetest.register_chatcommand("/highlight", {
	params = "<node>",
	description = "Highlight <node> in the current WorldEdit region by hiding everything else non-destructively",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local node = get_node(name, param)
			local count = worldedit.highlight(pos1, pos2, node)
			worldedit.player_notify(name, count .. " nodes highlighted")
		end
	end, check_set)),
})

minetest.register_chatcommand("/restore", {
	params = "",
	description = "Restores nodes hidden with WorldEdit in the current WorldEdit region",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.restore(pos1, pos2)
			worldedit.player_notify(name, count .. " nodes restored")
		end
	end)),
})

minetest.register_chatcommand("/save", {
	params = "<file>",
	description = "Save the current WorldEdit region to \"(world folder)/schems/<file>.we\"",
	privs = {}, --worldedit, server
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if minetest.check_player_privs(name, {server=true}) then
			if param == "" then
				worldedit.player_notify(name, "invalid usage: " .. param)
				return
			end
			if not string.find(param, "^[%w \t.,+-_=!@#$%%^&*()%[%]{};'\"]+$") then
				worldedit.player_notify(name, "invalid file name: " .. param)
				return
			end
		else
			worldedit.player_notify(name, "saving as worldedit.we (missing privileges: server)")
			param = "worldedit"
		end

		local result, count = worldedit.serialize(pos1, pos2)

		local path = minetest.get_worldpath() .. "/schems"
		local filename = path .. "/" .. param .. ".we"
		filename = filename:gsub("\"", "\\\""):gsub("\\", "\\\\") --escape any nasty characters
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
	end)),
})

minetest.register_chatcommand("/allocate", {
	params = "<file>",
	description = "Set the region defined by nodes from \"(world folder)/schems/<file>.we\" as the current WorldEdit region",
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos = get_position(name)
		if pos == nil then return end

		if param == "" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if not string.find(param, "^[%w \t.,+-_=!@#$%%^&*()%[%]{};'\"]+$") then
			worldedit.player_notify(name, "invalid file name: " .. param)
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
		local nodepos1, nodepos2, count = worldedit.allocate(pos, value)

		worldedit.pos1[name] = nodepos1
		worldedit.mark_pos1(name)
		worldedit.pos2[name] = nodepos2
		worldedit.mark_pos2(name)

		worldedit.player_notify(name, count .. " nodes allocated")
	end),
})

minetest.register_chatcommand("/load", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>[.we[m]]\" with position 1 of the current WorldEdit region as the origin",
	privs = {},
	func = worldedit.privs(function(name, param)
		local pos = get_position(name)
		if pos == nil then return end

		if param == "" then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		if not string.find(param, "^[%w \t.,+-_=!@#$%%^&*()%[%]{};'\"]+$") then
			worldedit.player_notify(name, "invalid file name: " .. param)
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

		local nodepos1, nodepos2, _ = worldedit.allocate(pos, value)
		if worldedit.can_edit_volume(name, {nodepos1, nodepos2}) then
			local count = worldedit.deserialize(pos, value)

			worldedit.player_notify(name, count .. " nodes loaded")
		end
	end),
})

minetest.register_chatcommand("/lua", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace",
	privs = {server=true},
	func = worldedit.privs(function(name, param)
		local admin = minetest.setting_get("name")
		if not admin or not name == admin then
			worldedit.player_notify(name, "this command can only be run by the server administrator")
			return
		end
		local err = worldedit.lua(param)
		if err then
			worldedit.player_notify(name, "code error: " .. err)
		else
			worldedit.player_notify(name, "code successfully executed", false)
		end
	end),
})

minetest.register_chatcommand("/luatransform", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region",
	privs = {server=true},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local admin = minetest.setting_get("name")
		if not admin or not name == admin then
			worldedit.player_notify(name, "this command can only be run by the server administrator")
			return
		end

		local err = worldedit.luatransform(pos1, pos2, param)
		if err then
			worldedit.player_notify(name, "code error: " .. err, false)
		else
			worldedit.player_notify(name, "code successfully executed", false)
		end
	end)),
})

minetest.register_chatcommand("/mtschemcreate", {
	params = "<file>",
	description = "Save the current WorldEdit region using the Minetest Schematic format to \"(world folder)/schems/<filename>.mts\"",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if minetest.check_player_privs(name, {server=true}) then
			if param == nil then
				worldedit.player_notify(name, "No filename specified")
				return
			end
		else
			worldedit.player_notify(name, "saving as worldedit.mts (missing privileges: server)")
			param = "worldedit"
		end

		local path = minetest.get_worldpath() .. "/schems"
		local filename = path .. "/" .. param .. ".mts"
		filename = filename:gsub("\"", "\\\""):gsub("\\", "\\\\") --escape any nasty characters
		os.execute("mkdir \"" .. path .. "\"") --create directory if it does not already exist

		local ret = minetest.create_schematic(pos1, pos2, worldedit.prob_list[name], filename)
		if ret == nil then
			worldedit.player_notify(name, "failed to create Minetest schematic", false)
		else
			worldedit.player_notify(name, "saved Minetest schematic to " .. param, false)
		end
		worldedit.prob_list[name] = {}
	end)),
})

minetest.register_chatcommand("/mtschemplace", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>.mts\" with position 1 of the current WorldEdit region as the origin",
	privs = {},
	func = worldedit.privs(function(name, param)
		if param == nil then
			worldedit.player_notify(name, "no filename specified")
			return
		end

		local pos = get_position(name)
		if pos == nil then return end

		local path = minetest.get_worldpath() .. "/schems/" .. param .. ".mts"
		--if worldedit.can_edit_volume(name, {pos1, ?}) then
			if minetest.place_schematic(pos, path) == nil then
				worldedit.player_notify(name, "failed to place Minetest schematic", false)
			else
				worldedit.player_notify(name, "placed Minetest schematic " .. param ..
					" at " .. minetest.pos_to_string(pos), false)
			end
		--end
	end),
})

minetest.register_chatcommand("/mtschemprob", {
	params = "start/finish/get",
	description = "Begins node probability entry for Minetest schematics, gets the nodes that have probabilities set, or ends node probability entry",
	privs = {},
	func = worldedit.privs(function(name, param)
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
			worldedit.player_notify(name, "currently set node probabilities:")
			worldedit.player_notify(name, text)
		else
			worldedit.player_notify(name, "unknown subcommand: " .. param)
		end
	end),
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

minetest.register_chatcommand("/clearobjects", {
	params = "",
	description = "Clears all objects within the WorldEdit region",
	privs = {},
	func = worldedit.privs(safe_region(function(name, param)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if worldedit.can_edit_volume(name, {pos1, pos2}) then
			local count = worldedit.clearobjects(pos1, pos2)
			worldedit.player_notify(name, count .. " objects cleared")
		end
	end)),
})
