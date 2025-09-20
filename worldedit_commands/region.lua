local S = minetest.get_translator("worldedit_commands")

worldedit.set_pos = {}
worldedit.inspect = {}


worldedit.register_command("inspect", {
	params = "[on/off/1/0/true/false/yes/no/enable/disable]",
	description = S("Enable or disable node inspection"),
	privs = {worldedit=true},
	parse = function(param)
		if param == "on" or param == "1" or param == "true" or param == "yes" or param == "enable" or param == "" then
			return true, true
		elseif param == "off" or param == "0" or param == "false" or param == "no" or param == "disable" then
			return true, false
		end
		return false
	end,
	func = function(name, enable)
		if enable then
			worldedit.inspect[name] = true
			local axis, sign = worldedit.player_axis(name)
			worldedit.player_notify(name, S(
				"inspector: inspection enabled for @1, currently facing the @2 axis",
				name,
				axis .. (sign > 0 and "+" or "-")
			), "info")
		else
			worldedit.inspect[name] = nil
			worldedit.player_notify(name, S("inspector: inspection disabled"), "info")
		end
	end,
})

local VEC_6DIRS = {
	vector.new( 1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new( 0, 1, 0),
	vector.new( 0,-1, 0),
	vector.new( 0, 0, 1),
	vector.new( 0, 0,-1),
}
local function get_node_rlight(pos)
	local ret = 0
	for _, v in ipairs(VEC_6DIRS) do
		ret = math.max(ret, minetest.get_node_light(vector.add(pos, v)))
	end
	return ret
end

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if worldedit.inspect[name] then
		local axis, sign = worldedit.player_axis(name)
		local message = S(
			"inspector: @1 at @2 (param1=@3, param2=@4, received light=@5) punched facing the @6 axis",
			node.name,
			minetest.pos_to_string(pos),
			node.param1,
			node.param2,
			get_node_rlight(pos),
			axis .. (sign > 0 and "+" or "-")
		)
		worldedit.player_notify(name, message, "info")
	end
end)


worldedit.register_command("mark", {
	params = "",
	description = S("Show markers at the region positions"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		worldedit.marker_update(name)
		return true, S("region marked")
	end,
})

worldedit.register_command("unmark", {
	params = "",
	description = S("Hide markers if currently shown"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		return true, S("region unmarked")
	end,
})

local function set_pos1(name, pos)
	assert(pos)
	pos = vector.round(pos)
	worldedit.pos1[name] = pos
	worldedit.mark_pos1(name)
	worldedit.player_notify(name, S("position @1 set to @2", 1, minetest.pos_to_string(pos)), "ok")
end

local function set_pos2(name, pos)
	assert(pos)
	pos = vector.round(pos)
	worldedit.pos2[name] = pos
	worldedit.mark_pos2(name)
	worldedit.player_notify(name, S("position @1 set to @2", 2, minetest.pos_to_string(pos)), "ok")
end

worldedit.register_command("pos1", {
	params = "",
	description = S("Set WorldEdit region position @1 to the player's location", 1),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		set_pos1(name, player:get_pos())
	end,
})

worldedit.register_command("pos2", {
	params = "",
	description = S("Set WorldEdit region position @1 to the player's location", 2),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		set_pos2(name, player:get_pos())
	end,
})

worldedit.register_command("p", {
	params = "set/set1/set2/get",
	description = S("Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region"),
	category = S("Region operations"),
	privs = {worldedit=true},
	parse = function(param)
		if param == "set" or param == "set1" or param == "set2" or param == "get" then
			return true, param
		end
		return false, S("unknown subcommand: @1", param)
	end,
	func = function(name, param)
		local msg
		if param == "set" then --set both WorldEdit positions
			worldedit.set_pos[name] = "pos1"
			msg = S("select positions by punching two nodes")
		elseif param == "set1" then --set WorldEdit position 1
			worldedit.set_pos[name] = "pos1only"
			msg = S("select position @1 by punching a node", 1)
		elseif param == "set2" then --set WorldEdit position 2
			worldedit.set_pos[name] = "pos2"
			msg = S("select position @1 by punching a node", 2)
		elseif param == "get" then --display current WorldEdit positions
			if worldedit.pos1[name] ~= nil then
				msg = S("position @1: @2", 1, minetest.pos_to_string(worldedit.pos1[name]))
			else
				msg = S("position @1 not set", 1)
			end
			msg = msg .. "\n"
			if worldedit.pos2[name] ~= nil then
				msg = msg .. S("position @1: @2", 2, minetest.pos_to_string(worldedit.pos2[name]))
			else
				msg = msg .. S("position @1 not set", 2)
			end
		end
		if msg then
			worldedit.player_notify(name, msg, "info")
		end
	end,
})

worldedit.register_command("fixedpos", {
	params = "set1/set2 <x> <y> <z>",
	description = S("Set a WorldEdit region position to the position at (<x>, <y>, <z>)"),
	category = S("Region operations"),
	privs = {worldedit=true},
	parse = function(param)
		local found, _, flag, x, y, z = param:find("^(set[12])%s+(~?[+-]?%d+)%s+(~?[+-]?%d+)%s+(~?[+-]?%d+)$")
		if not found then
			return false
		end
		return true, flag, x, y, z
	end,
	func = function(name, flag, x, y, z)
		-- Parse here, since player name isn't known in parse()
		local pos = worldedit.parse_coordinates(x, y, z, name)
		if not pos then
			return false, S("invalid position")
		end
		if flag == "set1" then
			set_pos1(name, pos)
		else --flag == "set2"
			set_pos2(name, pos)
		end
	end,
})

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if name ~= "" and worldedit.set_pos[name] ~= nil then --currently setting position
		if worldedit.set_pos[name] == "pos1" then --setting position 1
			set_pos1(name, pos)
			worldedit.set_pos[name] = "pos2" --set position 2 on the next invocation
		elseif worldedit.set_pos[name] == "pos1only" then --setting position 1 only
			set_pos1(name, pos)
			worldedit.set_pos[name] = nil --finished setting positions
		elseif worldedit.set_pos[name] == "pos2" then --setting position 2
			set_pos2(name, pos)
			worldedit.set_pos[name] = nil --finished setting positions
		elseif worldedit.set_pos[name] == "prob" then --setting Minetest schematic node probabilities
			worldedit.prob_pos[name] = pos
			minetest.show_formspec(name, "prob_val_enter", "field[text;;]")
		end
	end
end)

worldedit.register_command("volume", {
	params = "",
	description = S("Display the volume of the current WorldEdit region"),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

		local volume = worldedit.volume(pos1, pos2)
		local abs = math.abs
		worldedit.player_notify(name, S(
			"current region has a volume of @1 nodes (@2*@3*@4)",
			volume,
			abs(pos2.x - pos1.x) + 1,
			abs(pos2.y - pos1.y) + 1,
			abs(pos2.z - pos1.z) + 1
		), "info")
	end,
})
