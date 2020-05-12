minetest.register_privilege("worldedit", "Can use WorldEdit commands")

worldedit.pos1 = {}
worldedit.pos2 = {}

worldedit.set_pos = {}
worldedit.inspect = {}
worldedit.prob_pos = {}
worldedit.prob_list = {}



local safe_region, reset_pending = dofile(minetest.get_modpath("worldedit_commands") .. "/safe.lua")

function worldedit.player_notify(name, message)
	minetest.chat_send_player(name, "WorldEdit -!- " .. message, false)
end

worldedit.registered_commands = {}

local function chatcommand_handler(cmd_name, name, param)
	local def = assert(worldedit.registered_commands[cmd_name])

	if def.require_pos == 2 then
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end
	elseif def.require_pos == 1 then
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			worldedit.player_notify(name, "no position 1 selected")
			return
		end
	end

	local parsed = {def.parse(param)}
	local success = table.remove(parsed, 1)
	if not success then
		worldedit.player_notify(name, parsed[1] or "invalid usage")
		return
	end

	if def.nodes_needed then
		local count = def.nodes_needed(name, unpack(parsed))
		safe_region(name, count, function()
			local success, msg = def.func(name, unpack(parsed))
			if msg then
				minetest.chat_send_player(name, msg)
			end
		end)
	else
		-- no "safe region" check
		local success, msg = def.func(name, unpack(parsed))
		if msg then
			minetest.chat_send_player(name, msg)
		end
	end
end

-- Registers a chatcommand for WorldEdit
-- name = "about" -- Name of the chat command (without any /)
-- def = {
--     privs = {}, -- Privileges needed
--     params = "", -- Human readable parameter list (optional)
--         -- setting params = "" will automatically provide a parse() if not given 
--     description = "", -- Description
--     require_pos = 0, -- Number of positions required to be set (optional)
--     parse = function(param)
--         return true, foo, bar, ...
--         -- or
--         return false
--         -- or
--         return false, "error message"
--     end,
--     nodes_needed = function(name, foo, bar, ...), -- (optional)
--         return n
--     end,
--     func = function(name, foo, bar, ...)
--         return success, "message"
--     end,
-- }
function worldedit.register_command(name, def)
	local def = table.copy(def)
	assert(name and #name > 0)
	assert(def.privs)
	def.require_pos = def.require_pos or 0
	assert(def.require_pos >= 0 and def.require_pos < 3)
	if def.params == "" and not def.parse then
		def.parse = function(param) return true end
	else
		assert(def.parse)
	end
	assert(def.nodes_needed == nil or type(def.nodes_needed) == "function")
	assert(def.func)

	-- for development
	--[[if def.require_pos == 2 and not def.nodes_needed then
		minetest.log("warning", "//" .. name .. " might be missing nodes_needed")
	end--]]

	minetest.register_chatcommand("/" .. name, {
		privs = def.privs,
		params = def.params,
		description = def.description,
		func = function(player_name, param)
			return chatcommand_handler(name, player_name, param)
		end,
	})
	worldedit.registered_commands[name] = def
end



dofile(minetest.get_modpath("worldedit_commands") .. "/cuboid.lua")
dofile(minetest.get_modpath("worldedit_commands") .. "/mark.lua")
dofile(minetest.get_modpath("worldedit_commands") .. "/wand.lua")


local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end

-- Strips any kind of escape codes (translation, colors) from a string
-- https://github.com/minetest/minetest/blob/53dd7819277c53954d1298dfffa5287c306db8d0/src/util/string.cpp#L777
local function strip_escapes(input)
	local s = function(idx) return input:sub(idx, idx) end
	local out = ""
	local i = 1
	while i <= #input do
		if s(i) == "\027" then -- escape sequence
			i = i + 1
			if s(i) == "(" then -- enclosed
				i = i + 1
				while i <= #input and s(i) ~= ")" do
					if s(i) == "\\" then
						i = i + 2
					else
						i = i + 1
					end
				end
			end
		else
			out = out .. s(i)
		end
		i = i + 1
	end
	--print(("%q -> %q"):format(input, out))
	return out
end

local function string_endswith(full, part)
	return full:find(part, 1, true) == #full - #part + 1
end

local description_cache = nil

-- normalizes node "description" `nodename`, returning a string (or nil)
worldedit.normalize_nodename = function(nodename)
	nodename = nodename:gsub("^%s*(.-)%s*$", "%1") -- strip spaces
	if nodename == "" then return nil end

	local fullname = ItemStack({name=nodename}):get_name() -- resolve aliases
	if minetest.registered_nodes[fullname] or fullname == "air" then -- full name
		return fullname
	end
	nodename = nodename:lower()

	for key, _ in pairs(minetest.registered_nodes) do
		if string_endswith(key:lower(), ":" .. nodename) then -- matches name (w/o mod part)
			return key
		end
	end

	if description_cache == nil then
		-- cache stripped descriptions
		description_cache = {}
		for key, value in pairs(minetest.registered_nodes) do
			local desc = strip_escapes(value.description):gsub("\n.*", "", 1):lower()
			if desc ~= "" then
				description_cache[key] = desc
			end
		end
	end

	for key, desc in pairs(description_cache) do
		if desc == nodename then -- matches description
			return key
		end
	end
	for key, desc in pairs(description_cache) do
		if desc == nodename .. " block" then
			-- fuzzy description match (e.g. "Steel" == "Steel Block")
			return key
		end
	end

	local match = nil
	for key, value in pairs(description_cache) do
		if value:find(nodename, 1, true) ~= nil then
			if match ~= nil then
				return nil
			end
			match = key -- substring description match (only if no ambiguities)
		end
	end
	return match
end

-- Determines the axis in which a player is facing, returning an axis ("x", "y", or "z") and the sign (1 or -1)
function worldedit.player_axis(name)
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

local function check_filename(name)
	return name:find("^[%w%s%^&'@{}%[%],%$=!%-#%(%)%%%.%+~_]+$") ~= nil
end


worldedit.register_command("about", {
	privs = {},
	params = "",
	description = "Get information about the WorldEdit mod",
	func = function(name)
		worldedit.player_notify(name, "WorldEdit " .. worldedit.version_string..
			" is available on this server. Type //help to get a list of "..
			"commands, or get more information at "..
			"https://github.com/Uberi/Minetest-WorldEdit")
	end,
})

-- mostly copied from builtin/chatcommands.lua with minor modifications
worldedit.register_command("help", {
	privs = {},
	params = "[all/<cmd>]",
	description = "Get help for WorldEdit commands",
	parse = function(param)
		return true, param
	end,
	func = function(name, param)
		local function format_help_line(cmd, def)
			local msg = minetest.colorize("#00ffff", "//"..cmd)
			if def.params and def.params ~= "" then
				msg = msg .. " " .. def.params
			end
			if def.description and def.description ~= "" then
				msg = msg .. ": " .. def.description
			end
			return msg
		end

		if not minetest.check_player_privs(name, "worldedit") then
			return false, "You are not allowed to use any WorldEdit commands."
		end
		if param == "" then
			local msg = ""
			local cmds = {}
			for cmd, def in pairs(worldedit.registered_commands) do
				if minetest.check_player_privs(name, def.privs) then
					cmds[#cmds + 1] = cmd
				end
			end
			table.sort(cmds)
			return true, "Available commands: " .. table.concat(cmds, " ") .. "\n"
					.. "Use '//help <cmd>' to get more information,"
					.. " or '//help all' to list everything."
		elseif param == "all" then
			local cmds = {}
			for cmd, def in pairs(worldedit.registered_commands) do
				if minetest.check_player_privs(name, def.privs) then
					cmds[#cmds + 1] = format_help_line(cmd, def)
				end
			end
			table.sort(cmds)
			return true, "Available commands:\n"..table.concat(cmds, "\n")
		else
			local def = worldedit.registered_commands[param]
			if not def then
				return false, "Command not available: " .. param
			else
				return true, format_help_line(param, def)
			end
		end
	end,
})

worldedit.register_command("inspect", {
	params = "[on/off/1/0/true/false/yes/no/enable/disable]",
	description = "Enable or disable node inspection",
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
			worldedit.player_notify(name, string.format("inspector: inspection enabled for %s, currently facing the %s axis",
				name, axis .. (sign > 0 and "+" or "-")))
		else
			worldedit.inspect[name] = nil
			worldedit.player_notify(name, "inspector: inspection disabled")
		end
	end,
})

local function get_node_rlight(pos)
	local vecs = { -- neighboring nodes
		{x= 1, y= 0, z= 0},
		{x=-1, y= 0, z= 0},
		{x= 0, y= 1, z= 0},
		{x= 0, y=-1, z= 0},
		{x= 0, y= 0, z= 1},
		{x= 0, y= 0, z=-1},
	}
	local ret = 0
	for _, v in ipairs(vecs) do
		ret = math.max(ret, minetest.get_node_light(vector.add(pos, v)))
	end
	return ret
end

minetest.register_on_punchnode(function(pos, node, puncher)
	local name = puncher:get_player_name()
	if worldedit.inspect[name] then
		local axis, sign = worldedit.player_axis(name)
		local message = string.format("inspector: %s at %s (param1=%d, param2=%d, received light=%d) punched facing the %s axis",
			node.name, minetest.pos_to_string(pos), node.param1, node.param2, get_node_rlight(pos), axis .. (sign > 0 and "+" or "-"))
		worldedit.player_notify(name, message)
	end
end)

worldedit.register_command("reset", {
	params = "",
	description = "Reset the region so that it is empty",
	privs = {worldedit=true},
	func = function(name)
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.set_pos[name] = nil
		--make sure the user does not try to confirm an operation after resetting pos:
		reset_pending(name)
		worldedit.player_notify(name, "region reset")
	end,
})

worldedit.register_command("mark", {
	params = "",
	description = "Show markers at the region positions",
	privs = {worldedit=true},
	func = function(name)
		worldedit.marker_update(name)
		worldedit.player_notify(name, "region marked")
	end,
})

worldedit.register_command("unmark", {
	params = "",
	description = "Hide markers if currently shown",
	privs = {worldedit=true},
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.player_notify(name, "region unmarked")
	end,
})

worldedit.register_command("pos1", {
	params = "",
	description = "Set WorldEdit region position 1 to the player's location",
	privs = {worldedit=true},
	func = function(name)
		local pos = minetest.get_player_by_name(name):get_pos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)
		worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
	end,
})

worldedit.register_command("pos2", {
	params = "",
	description = "Set WorldEdit region position 2 to the player's location",
	privs = {worldedit=true},
	func = function(name)
		local pos = minetest.get_player_by_name(name):get_pos()
		pos.x, pos.y, pos.z = math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), math.floor(pos.z + 0.5)
		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)
		worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
	end,
})

worldedit.register_command("p", {
	params = "set/set1/set2/get",
	description = "Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region",
	privs = {worldedit=true},
	parse = function(param)
		if param == "set" or param == "set1" or param == "set2" or param == "get" then
			return true, param
		end
		return false, "unknown subcommand: " .. param
	end,
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
		end
	end,
})

worldedit.register_command("fixedpos", {
	params = "set1/set2 <x> <y> <z>",
	description = "Set a WorldEdit region position to the position at (<x>, <y>, <z>)",
	privs = {worldedit=true},
	parse = function(param)
		local found, _, flag, x, y, z = param:find("^(set[12])%s+([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		return true, flag, {x=tonumber(x), y=tonumber(y), z=tonumber(z)}
	end,
	func = function(name, flag, pos)
		if flag == "set1" then
			worldedit.pos1[name] = pos
			worldedit.mark_pos1(name)
			worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos))
		else --flag == "set2"
			worldedit.pos2[name] = pos
			worldedit.mark_pos2(name)
			worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos))
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

worldedit.register_command("volume", {
	params = "",
	description = "Display the volume of the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

		local volume = worldedit.volume(pos1, pos2)
		local abs = math.abs
		worldedit.player_notify(name, "current region has a volume of " .. volume .. " nodes ("
			.. abs(pos2.x - pos1.x) + 1 .. "*"
			.. abs(pos2.y - pos1.y) + 1 .. "*"
			.. abs(pos2.z - pos1.z) + 1 .. ")")
	end,
})

worldedit.register_command("deleteblocks", {
	params = "",
	description = "remove all MapBlocks (16x16x16) containing the selected area from the map",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local success = minetest.delete_area(pos1, pos2)
		if success then
			worldedit.player_notify(name, "Area deleted.")
		else
			worldedit.player_notify(name, "There was an error during deletion of the area.")
		end
	end,
})

worldedit.register_command("set", {
	params = "<node>",
	description = "Set the current WorldEdit region to <node>",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, "invalid node name: " .. param
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.set(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, count .. " nodes set")
	end,
})

worldedit.register_command("param2", {
	params = "<param2>",
	description = "Set param2 of all nodes in the current WorldEdit region to <param2>",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local param2 = tonumber(param)
		if not param2 then
			return false
		elseif param2 < 0 or param2 > 255 then
			return false, "Param2 is out of range (must be between 0 and 255 inclusive!)"
		end
		return true, param2
	end,
	nodes_needed = check_region,
	func = function(name, param2)
		local count = worldedit.set_param2(worldedit.pos1[name], worldedit.pos2[name], param2)
		worldedit.player_notify(name, count .. " nodes altered")
	end,
})

worldedit.register_command("mix", {
	params = "<node1> [count1] <node2> [count2] ...",
	description = "Fill the current WorldEdit region with a random mix of <node1>, ...",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local nodes = {}
		for nodename in param:gmatch("[^%s]+") do
			if tonumber(nodename) ~= nil and #nodes > 0 then
				local last_node = nodes[#nodes]
				for i = 1, tonumber(nodename) do
					nodes[#nodes + 1] = last_node
				end
			else
				local node = worldedit.normalize_nodename(nodename)
				if not node then
					return false, "invalid node name: " .. nodename
				end
				nodes[#nodes + 1] = node
			end
		end
		if #nodes == 0 then
			return false
		end
		return true, nodes
	end,
	nodes_needed = check_region,
	func = function(name, nodes)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.set(pos1, pos2, nodes)
		worldedit.player_notify(name, count .. " nodes set")
	end,
})

local check_replace = function(param)
	local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
	if found == nil then
		return false
	end
	local newsearchnode = worldedit.normalize_nodename(searchnode)
	if not newsearchnode then
		return false, "invalid search node name: " .. searchnode
	end
	local newreplacenode = worldedit.normalize_nodename(replacenode)
	if not newreplacenode then
		return false, "invalid replace node name: " .. replacenode
	end
	return true, newsearchnode, newreplacenode
end

worldedit.register_command("replace", {
	params = "<search node> <replace node>",
	description = "Replace all instances of <search node> with <replace node> in the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node)
		worldedit.player_notify(name, count .. " nodes replaced")
	end,
})

worldedit.register_command("replaceinverse", {
	params = "<search node> <replace node>",
	description = "Replace all nodes other than <search node> with <replace node> in the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node, true)
		worldedit.player_notify(name, count .. " nodes replaced")
	end,
})

local check_cube = function(param)
	local found, _, w, h, l, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, "invalid node name: " .. nodename
	end
	return true, tonumber(w), tonumber(h), tonumber(l), node
end

worldedit.register_command("hollowcube", {
	params = "<width> <height> <length> <node>",
	description = "Add a hollow cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>.",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node, true)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("cube", {
	params = "<width> <height> <length> <node>",
	description = "Add a cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>.",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

local check_sphere = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, "invalid node name: " .. nodename
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowsphere", {
	params = "<radius> <node>",
	description = "Add hollow sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node, true)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("sphere", {
	params = "<radius> <node>",
	description = "Add sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

local check_dome = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, "invalid node name: " .. nodename
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowdome", {
	params = "<radius> <node>",
	description = "Add hollow dome centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node, true)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("dome", {
	params = "<radius> <node>",
	description = "Add dome centered at WorldEdit position 1 with radius <radius>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

local check_cylinder = function(param)
	-- two radii
	local found, _, axis, length, radius1, radius2, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		-- single radius
		found, _, axis, length, radius1, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		radius2 = radius1
	end
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, "invalid node name: " .. nodename
	end
	return true, axis, tonumber(length), tonumber(radius1), tonumber(radius2), node
end

worldedit.register_command("hollowcylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = "Add hollow cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node, true)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("cylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = "Add cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

local check_pyramid = function(param)
	local found, _, axis, height, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, "invalid node name: " .. nodename
	end
	return true, axis, tonumber(height), node
end
     
worldedit.register_command("hollowpyramid", {
	params = "x/y/z/? <height> <node>",
	description = "Add hollow pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node, true)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("pyramid", {
	params = "x/y/z/? <height> <node>",
	description = "Add pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("spiral", {
	params = "<length> <height> <space> <node>",
	description = "Add spiral centered at WorldEdit position 1 with side length <length>, height <height>, space between walls <space>, composed of <node>",
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		local found, _, length, height, space, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			return false
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			return false, "invalid node name: " .. nodename
		end
		return true, tonumber(length), tonumber(height), tonumber(space), node
	end,
	nodes_needed = function(name, length, height, space, node)
		return (length + space) * height -- TODO: this is not the upper bound
	end,
	func = function(name, length, height, space, node)
		local count = worldedit.spiral(worldedit.pos1[name], length, height, space, node)
		worldedit.player_notify(name, count .. " nodes added")
	end,
})

worldedit.register_command("copy", {
	params = "x/y/z/? <amount>",
	description = "Copy the current WorldEdit region along the given axis by <amount> nodes",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		return true, axis, tonumber(amount)
	end,
	nodes_needed = function(name, axis, amount)
		return check_region(name) * 2
	end,
	func = function(name, axis, amount)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local count = worldedit.copy(worldedit.pos1[name], worldedit.pos2[name], axis, amount)
		worldedit.player_notify(name, count .. " nodes copied")
	end,
})

worldedit.register_command("move", {
	params = "x/y/z/? <amount>",
	description = "Move the current WorldEdit region along the given axis by <amount> nodes",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, amount = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		return true, axis, tonumber(amount)
	end,
	nodes_needed = function(name, axis, amount)
		return check_region(name) * 2
	end,
	func = function(name, axis, amount)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			amount = amount * sign
		end

		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.move(pos1, pos2, axis, amount)

		pos1[axis] = pos1[axis] + amount
		pos2[axis] = pos2[axis] + amount
		worldedit.marker_update(name)
		worldedit.player_notify(name, count .. " nodes moved")
	end,
})

worldedit.register_command("stack", {
	params = "x/y/z/? <count>",
	description = "Stack the current WorldEdit region along the given axis <count> times",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, repetitions = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		return true, axis, tonumber(repetitions)
	end,
	nodes_needed = function(name, axis, repetitions)
		return check_region(name) * math.abs(repetitions)
	end,
	func = function(name, axis, repetitions)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			repetitions = repetitions * sign
		end

		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.volume(pos1, pos2) * math.abs(repetitions)
		worldedit.stack(pos1, pos2, axis, repetitions, function()
			worldedit.player_notify(name, count .. " nodes stacked")
		end)
	end,
})

worldedit.register_command("stack2", {
	params = "<count> <x> <y> <z>",
	description = "Stack the current WorldEdit region <count> times by offset <x>, <y>, <z>",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local repetitions, incs = param:match("(%d+)%s*(.+)")
		if repetitions == nil then
			return false, "invalid count: " .. param
		end
		local x, y, z = incs:match("([+-]?%d+) ([+-]?%d+) ([+-]?%d+)")
		if x == nil then
			return false, "invalid increments: " .. param
		end

		return true, tonumber(repetitions), {x=tonumber(x), y=tonumber(y), z=tonumber(z)}
	end,
	nodes_needed = function(name, repetitions, offset)
		return check_region(name) * repetitions
	end,
	func = function(name, repetitions, offset)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.volume(pos1, pos2) * repetitions
		worldedit.stack2(pos1, pos2, offset, repetitions, function()
			worldedit.player_notify(name, count .. " nodes stacked")
		end)
	end,
})


worldedit.register_command("stretch", {
	params = "<stretchx> <stretchy> <stretchz>",
	description = "Scale the current WorldEdit positions and region by a factor of <stretchx>, <stretchy>, <stretchz> along the X, Y, and Z axes, repectively, with position 1 as the origin",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, stretchx, stretchy, stretchz = param:find("^(%d+)%s+(%d+)%s+(%d+)$")
		if found == nil then
			return false
		end
		stretchx, stretchy, stretchz = tonumber(stretchx), tonumber(stretchy), tonumber(stretchz)
		if stretchx == 0 or stretchy == 0 or stretchz == 0 then
			return false, "invalid scaling factors: " .. param
		end
		return true, stretchx, stretchy, stretchz
	end,
	nodes_needed = function(name, stretchx, stretchy, stretchz)
		return check_region(name) * stretchx * stretchy * stretchz
	end,
	func = function(name, stretchx, stretchy, stretchz)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count, pos1, pos2 = worldedit.stretch(pos1, pos2, stretchx, stretchy, stretchz)

		--reset markers to scaled positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, count .. " nodes stretched")
	end,
})

worldedit.register_command("transpose", {
	params = "x/y/z/? x/y/z/?",
	description = "Transpose the current WorldEdit region along the given axes",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			return false
		elseif axis1 == axis2 then
			return false, "invalid usage: axes must be different"
		end
		return true, axis1, axis2
	end,
	nodes_needed = check_region,
	func = function(name, axis1, axis2)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if axis1 == "?" then axis1 = worldedit.player_axis(name) end
		if axis2 == "?" then axis2 = worldedit.player_axis(name) end
		local count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2)

		--reset markers to transposed positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, count .. " nodes transposed")
	end,
})

worldedit.register_command("flip", {
	params = "x/y/z/?",
	description = "Flip the current WorldEdit region along the given axis",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param ~= "x" and param ~= "y" and param ~= "z" and param ~= "?" then
			return false
		end
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		if param == "?" then param = worldedit.player_axis(name) end
		local count = worldedit.flip(worldedit.pos1[name], worldedit.pos2[name], param)
		worldedit.player_notify(name, count .. " nodes flipped")
	end,
})

worldedit.register_command("rotate", {
	params = "x/y/z/? <angle>",
	description = "Rotate the current WorldEdit region around the given axis by angle <angle> (90 degree increment)",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		angle = tonumber(angle)
		if angle % 90 ~= 0 or angle % 360 == 0 then
			return false, "invalid usage: angle must be multiple of 90"
		end
		return true, axis, angle
	end,
	nodes_needed = check_region,
	func = function(name, axis, angle)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if axis == "?" then axis = worldedit.player_axis(name) end
		local count, pos1, pos2 = worldedit.rotate(pos1, pos2, axis, angle)

		--reset markers to rotated positions
		worldedit.pos1[name] = pos1
		worldedit.pos2[name] = pos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, count .. " nodes rotated")
	end,
})

worldedit.register_command("orient", {
	params = "<angle>",
	description = "Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle> (90 degree increment)",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, angle = param:find("^([+-]?%d+)$")
		if found == nil then
			return false
		end
		angle = tonumber(angle)
		if angle % 90 ~= 0 then
			return false, "invalid usage: angle must be multiple of 90"
		end
		return true, angle
	end,
	nodes_needed = check_region,
	func = function(name, angle)
		local count = worldedit.orient(worldedit.pos1[name], worldedit.pos2[name], angle)
		worldedit.player_notify(name, count .. " nodes oriented")
	end,
})

worldedit.register_command("fixlight", {
	params = "",
	description = "Fix the lighting in the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.fixlight(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, count .. " nodes updated")
	end,
})

worldedit.register_command("drain", {
	params = "",
	description = "Remove any fluid node within the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		-- TODO: make an API function for this
		local count = 0
		local pos1, pos2 = worldedit.sort_pos(worldedit.pos1[name], worldedit.pos2[name])
		for x = pos1.x, pos2.x do
		for y = pos1.y, pos2.y do
		for z = pos1.z, pos2.z do
			local n = minetest.get_node({x=x, y=y, z=z}).name
			local d = minetest.registered_nodes[n]
			if d ~= nil and (d["drawtype"] == "liquid" or d["drawtype"] == "flowingliquid") then
				minetest.remove_node({x=x, y=y, z=z})
				count = count + 1
			end
		end
		end
		end
		worldedit.player_notify(name, count .. " nodes updated")
	end,
})

local clearcut_cache

local function clearcut(pos1, pos2)
	-- decide which nodes we consider plants
	if clearcut_cache == nil then
		clearcut_cache = {}
		for name, def in pairs(minetest.registered_nodes) do
			local groups = def.groups or {}
			if (
				-- the groups say so
				groups.flower or groups.grass or groups.flora or groups.plant or
				groups.leaves or groups.tree or groups.leafdecay or groups.sapling or
				-- drawtype heuristic
				(def.is_ground_content and def.buildable_to and
					(def.sunlight_propagates or not def.walkable)
					and def.drawtype == "plantlike") or
				-- if it's flammable, it probably needs to go too
				(def.is_ground_content and not def.walkable and groups.flammable)
			) then
				clearcut_cache[name] = true
			end
		end
	end
	local plants = clearcut_cache

	local count = 0
	local prev, any

	for x = pos1.x, pos2.x do
	for z = pos1.z, pos2.z do
		prev = false
		any = false
		-- first pass: remove floating nodes that would be left over
		for y = pos1.y, pos2.y do
			local n = minetest.get_node({x=x, y=y, z=z}).name
			if plants[n] then
				prev = true
				any = true
			elseif prev then
				local def = minetest.registered_nodes[n] or {}
				local groups = def.groups or {}
				if groups.attached_node or (def.buildable_to and groups.falling_node) then
					minetest.remove_node({x=x, y=y, z=z})
					count = count + 1
				else
					prev = false
				end
			end
		end

		-- second pass: remove plants, top-to-bottom to avoid item drops
		if any then
			for y = pos2.y, pos1.y, -1 do
				local n = minetest.get_node({x=x, y=y, z=z}).name
				if plants[n] then
					minetest.remove_node({x=x, y=y, z=z})
					count = count + 1
				end
			end
		end
	end
	end

	return count
end

worldedit.register_command("clearcut", {
	params = "",
	description = "Remove any plant, tree or foilage-like nodes in the selected region",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.sort_pos(worldedit.pos1[name], worldedit.pos2[name])
		local count = clearcut(pos1, pos2)
		worldedit.player_notify(name, count .. " nodes removed")
	end,
})

worldedit.register_command("hide", {
	params = "",
	description = "Hide all nodes in the current WorldEdit region non-destructively",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.hide(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, count .. " nodes hidden")
	end,
})

worldedit.register_command("suppress", {
	params = "<node>",
	description = "Suppress all <node> in the current WorldEdit region non-destructively",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, "invalid node name: " .. param
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.suppress(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, count .. " nodes suppressed")
	end,
})

worldedit.register_command("highlight", {
	params = "<node>",
	description = "Highlight <node> in the current WorldEdit region by hiding everything else non-destructively",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, "invalid node name: " .. param
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.highlight(worldedit.pos1[name], worldedit.pos2[name], node)
		worldedit.player_notify(name, count .. " nodes highlighted")
	end,
})

worldedit.register_command("restore", {
	params = "",
	description = "Restores nodes hidden with WorldEdit in the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.restore(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, count .. " nodes restored")
	end,
})

local function detect_misaligned_schematic(name, pos1, pos2)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	-- Check that allocate/save can position the schematic correctly
	-- The expected behaviour is that the (0,0,0) corner of the schematic stays
	-- sat pos1, this only works when the minimum position is actually present
	-- in the schematic.
	local node = minetest.get_node(pos1)
	local have_node_at_origin = node.name ~= "air" and node.name ~= "ignore"
	if not have_node_at_origin then
		worldedit.player_notify(name,
			"Warning: The schematic contains excessive free space and WILL be "..
			"misaligned when allocated or loaded. To avoid this, shrink your "..
			"area to cover exactly the nodes to be saved."
		)
	end
end

worldedit.register_command("save", {
	params = "<file>",
	description = "Save the current WorldEdit region to \"(world folder)/schems/<file>.we\"",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, "Disallowed file name: " .. param
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
			worldedit.player_notify(name, "Could not save file to \"" .. filename .. "\"")
			return
		end
		file:write(result)
		file:flush()
		file:close()

		worldedit.player_notify(name, count .. " nodes saved")
	end,
})

worldedit.register_command("allocate", {
	params = "<file>",
	description = "Set the region defined by nodes from \"(world folder)/schems/<file>.we\" as the current WorldEdit region",
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, "Disallowed file name: " .. param
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local filename = minetest.get_worldpath() .. "/schems/" .. param .. ".we"
		local file, err = io.open(filename, "rb")
		if err ~= nil then
			worldedit.player_notify(name, "could not open file \"" .. filename .. "\"")
			return
		end
		local value = file:read("*a")
		file:close()

		local version = worldedit.read_header(value)
		if version == nil or version == 0 then
			worldedit.player_notify(name, "File is invalid!")
			return
		elseif version > worldedit.LATEST_SERIALIZATION_VERSION then
			worldedit.player_notify(name, "File was created with newer version of WorldEdit!")
			return
		end
		local nodepos1, nodepos2, count = worldedit.allocate(pos, value)

		if not nodepos1 then
			worldedit.player_notify(name, "Schematic empty, nothing allocated")
			return
		end

		worldedit.pos1[name] = nodepos1
		worldedit.pos2[name] = nodepos2
		worldedit.marker_update(name)

		worldedit.player_notify(name, count .. " nodes allocated")
	end,
})

worldedit.register_command("load", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>[.we[m]]\" with position 1 of the current WorldEdit region as the origin",
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, "Disallowed file name: " .. param
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

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

		local version = worldedit.read_header(value)
		if version == nil or version == 0 then
			worldedit.player_notify(name, "File is invalid!")
			return
		elseif version > worldedit.LATEST_SERIALIZATION_VERSION then
			worldedit.player_notify(name, "File was created with newer version of WorldEdit!")
			return
		end

		local count = worldedit.deserialize(pos, value)

		worldedit.player_notify(name, count .. " nodes loaded")
	end,
})

worldedit.register_command("lua", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace",
	privs = {worldedit=true, server=true},
	parse = function(param)
		return true, param
	end,
	func = function(name, param)
		local err = worldedit.lua(param)
		if err then
			worldedit.player_notify(name, "code error: " .. err)
			minetest.log("action", name.." tried to execute "..param)
		else
			worldedit.player_notify(name, "code successfully executed", false)
			minetest.log("action", name.." executed "..param)
		end
	end,
})

worldedit.register_command("luatransform", {
	params = "<code>",
	description = "Executes <code> as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region",
	privs = {worldedit=true, server=true},
	require_pos = 2,
	parse = function(param)
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local err = worldedit.luatransform(worldedit.pos1[name], worldedit.pos2[name], param)
		if err then
			worldedit.player_notify(name, "code error: " .. err, false)
			minetest.log("action", name.." tried to execute luatransform "..param)
		else
			worldedit.player_notify(name, "code successfully executed", false)
			minetest.log("action", name.." executed luatransform "..param)
		end
	end,
})

worldedit.register_command("mtschemcreate", {
	params = "<file>",
	description = "Save the current WorldEdit region using the Minetest "..
		"Schematic format to \"(world folder)/schems/<filename>.mts\"",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, "Disallowed file name: " .. param
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
			worldedit.player_notify(name, "Failed to create Minetest schematic")
		else
			worldedit.player_notify(name, "Saved Minetest schematic to " .. param)
		end
		worldedit.prob_list[name] = {}
	end,
})

worldedit.register_command("mtschemplace", {
	params = "<file>",
	description = "Load nodes from \"(world folder)/schems/<file>.mts\" with position 1 of the current WorldEdit region as the origin",
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		if param == "" then
			return false
		end
		if not check_filename(param) then
			return false, "Disallowed file name: " .. param
		end
		return true, param
	end,
	func = function(name, param)
		local pos = worldedit.pos1[name]

		local path = minetest.get_worldpath() .. "/schems/" .. param .. ".mts"
		if minetest.place_schematic(pos, path) == nil then
			worldedit.player_notify(name, "failed to place Minetest schematic")
		else
			worldedit.player_notify(name, "placed Minetest schematic " .. param ..
				" at " .. minetest.pos_to_string(pos))
		end
	end,
})

worldedit.register_command("mtschemprob", {
	params = "start/finish/get",
	description = "Begins node probability entry for Minetest schematics, gets the nodes that have probabilities set, or ends node probability entry",
	privs = {worldedit=true},
	parse = function(param)
		if param ~= "start" and param ~= "finish" and param ~= "get" then
			return false, "unknown subcommand: " .. param
		end
		return true, param
	end,
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
				local prob = math.floor(((v.prob / 256) * 100) * 100 + 0.5) / 100
				text = text .. minetest.pos_to_string(v.pos) .. ": " .. prob .. "% | "
			end
			worldedit.player_notify(name, "currently set node probabilities:")
			worldedit.player_notify(name, text)
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "prob_val_enter" and not (fields.text == "" or fields.text == nil) then
		local name = player:get_player_name()
		local prob_entry = {pos=worldedit.prob_pos[name], prob=tonumber(fields.text)}
		local index = table.getn(worldedit.prob_list[name]) + 1
		worldedit.prob_list[name][index] = prob_entry
	end
end)

worldedit.register_command("clearobjects", {
	params = "",
	description = "Clears all objects within the WorldEdit region",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.clear_objects(worldedit.pos1[name], worldedit.pos2[name])
		worldedit.player_notify(name, count .. " objects cleared")
	end,
})
