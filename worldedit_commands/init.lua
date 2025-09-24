local S = minetest.get_translator("worldedit_commands")

minetest.register_privilege("worldedit", S("Can use WorldEdit commands"))

worldedit.pos1 = {}
worldedit.pos2 = {}


local safe_region, reset_pending = dofile(minetest.get_modpath("worldedit_commands") .. "/safe.lua")

worldedit.registered_commands = {}

local function copy_state(which, name)
	if which == 0 then
		return {}
	elseif which == 1 then
		return {
			worldedit.pos1[name] and vector.copy(worldedit.pos1[name])
		}
	else
		return {
			worldedit.pos1[name] and vector.copy(worldedit.pos1[name]),
			worldedit.pos2[name] and vector.copy(worldedit.pos2[name])
		}
	end
end

local function compare_state(state, old_state)
	for i, v in ipairs(state) do
		if not (v == nil and old_state[i] == nil) and not vector.equals(v, old_state[i]) then
			return false
		end
	end
	return true
end

local function chatcommand_handler(cmd_name, name, param)
	local def = assert(worldedit.registered_commands[cmd_name])

	if def.require_pos == 2 then
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, S("no region selected"), "error")
			return
		end
	elseif def.require_pos == 1 then
		local pos1 = worldedit.pos1[name]
		if pos1 == nil then
			worldedit.player_notify(name, S("no position 1 selected"), "error")
			return
		end
	end

	param = param:trim()
	local parsed = {def.parse(param)}
	local success = table.remove(parsed, 1)
	if not success then
		worldedit.player_notify(name, parsed[1] or S("invalid usage"), "error")
		return
	end

	local run = function()
		local ok, msg = def.func(name, unpack(parsed))
		if msg then
			worldedit.player_notify(name, msg, ok and "ok" or "error")
		end
	end

	if not def.nodes_needed then
		-- no safe region check
		run()
		return
	end

	local count = def.nodes_needed(name, unpack(parsed))
	local old_state = copy_state(def.require_pos, name)
	safe_region(name, count, function()
		local state = copy_state(def.require_pos, name)
		if not compare_state(state, old_state) then
			worldedit.player_notify(name, S("ERROR: the operation was cancelled because the region has changed."), "error")
			return
		end

		run()
	end)
end

-- Registers a chatcommand for WorldEdit
-- name = "about" -- Name of the chat command (without any /)
-- def = {
--     privs = {}, -- Privileges needed
--     params = "", -- Human readable parameter list (optional)
--         -- if params = "" then a parse() implementation will automatically be provided
--     description = "", -- Description
--     category = "", -- Category of the command (optional)
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
	def.name = name
	assert(def.privs)
	def.category = def.category or ""
	def.require_pos = def.require_pos or 0
	assert(def.require_pos >= 0 and def.require_pos < 3)
	if def.params == "" and not def.parse then
		def.parse = function(param)
			return param == ""
		end
	else
		assert(def.parse)
	end
	assert(def.nodes_needed == nil or type(def.nodes_needed) == "function")
	assert(def.func)

	-- for development
	--[[if def.require_pos == 2 and not def.nodes_needed then
		minetest.log("warning", "//" .. name .. " might be missing nodes_needed")
	end--]]

	-- disable further modification
	setmetatable(def, {__newindex = function() end})

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

-- Notifies a player of something related to WorldEdit.
-- Message types:
-- "error" = An operation did not work as expected.
-- "ok" = An operation completed successfully. Because notifications of this type
-- can be filtered, use this ONLY for generic messages like "1234 nodes set".
-- "info" = Other informational messages
-- @param name Name of player
-- @param message Message text
-- @param typ Type of message (optional but strongly recommend)
function worldedit.player_notify(name, message, typ)
	local t = {
		"WorldEdit",
		"-!-",
		tostring(message)
	}
	if typ == "error" then
		t[2] = minetest.colorize("#f22", t[2])
	elseif typ == "ok" then
		t[2] = minetest.colorize("#2f2", t[2])
	end
	minetest.chat_send_player(name, table.concat(t, " "))
end

-- Determines the axis in which a player is facing
-- @return axis ("x", "y", or "z") and the sign (1 or -1)
-- @note Not part of API
function worldedit.player_axis(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		-- we promised to return something valid...
		return "y", -1
	end
	local dir = player:get_look_dir()
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

-- Look-up table of valid directions (for worldedit.player_direction)
-- Can be stringified for usage in help texts
-- @note Not part of API
worldedit.valid_directions = setmetatable({
	x = true, y = true, z = true,
	["?"] = true,
	up = true, down = true,
	front = true, back = true,
	left = true, right = true,
}, {
	__tostring = function()
		return "x/y/z/?/up/down/left/right/front/back"
	end
})

-- Accepts a valid directions as above
-- @return axis ("x", "y", or "z") and the sign (1 or -1) *or* nil for invalid combinations
-- @note Not part of API
worldedit.player_direction = function(name, str)
	if str == "x" or str == "y" or str == "z" then
		return str, 1
	elseif str == "up" then
		return "y", 1
	elseif str == "down" then
		return "y", -1
	end

	local axis, dir = worldedit.player_axis(name)

	if str == "?" then
		return axis, dir
	elseif str == "front" then
		if axis ~= "y" then
			return axis, dir
		end
	elseif str == "back" then
		if axis ~= "y" then
			return axis, -dir
		end
	elseif str == "left" then
		if axis == "x" then
			return "z", dir
		elseif axis == "z" then
			return "x", -dir
		end
	elseif str == "right" then
		if axis == "x" then
			return "z", -dir
		elseif axis == "z" then
			return "x", dir
		end
	end

	return nil, nil
end

-- Wrapper for the engine"s parse_coordinates
-- @return vector or nil
-- @note Not part of API
function worldedit.parse_coordinates(x, y, z, player_name)
	local relpos
	local player = minetest.get_player_by_name(player_name or "")
	if player then
		relpos = player:get_pos()
	end
	-- we don't bother to support ~ in the fallback path here
	if not minetest.parse_coordinates then
		x, y, z = tonumber(x), tonumber(y), tonumber(z)
		return x and y and z and vector.new(x, y, z)
	end
	return minetest.parse_coordinates(x, y, z, relpos)
end


worldedit.register_command("about", {
	privs = {},
	params = "",
	description = S("Get information about the WorldEdit mod"),
	func = function(name)
		worldedit.player_notify(name, S("WorldEdit @1"..
			" is available on this server. Type @2 to get a list of "..
			"commands, or find more information at @3",
			worldedit.version_string, minetest.colorize("#0ff", "//help"),
			"https://github.com/Uberi/Minetest-WorldEdit"
		), "info")
	end,
})

-- initially copied from builtin/chatcommands.lua
local function help_command(name, param)
	local function format_help_line(cmd, def, follow_alias)
		local msg = minetest.colorize("#0ff", "//"..cmd)
		if def.name ~= cmd then
			msg = msg .. ": " .. S("alias to @1",
				minetest.colorize("#0ff", "//"..def.name))
			if follow_alias then
				msg = msg .. "\n" .. format_help_line(def.name, def)
			end
		else
			if def.params and def.params ~= "" then
				msg = msg .. " " .. def.params
			end
			if def.description and def.description ~= "" then
				msg = msg .. ": " .. def.description
			end
		end
		return msg
	end
	-- @param cmds list of {cmd, def}
	local function sort_cmds(cmds)
		table.sort(cmds, function(c1, c2)
			local cmd1, cmd2 = c1[1], c2[1]
			local def1, def2 = c1[2], c2[2]
			-- by category (this puts the empty category first)
			if def1.category ~= def2.category then
				return def1.category < def2.category
			end
			-- put aliases last
			if (cmd1 ~= def1.name) ~= (cmd2 ~= def2.name) then
				return cmd2 ~= def2.name
			end
			-- then by name
			return c1[1] < c2[1]
		end)
	end

	if not minetest.check_player_privs(name, "worldedit") then
		return false, S("You are not allowed to use any WorldEdit commands.")
	end
	if param == "" then
		local list = {}
		for cmd, def in pairs(worldedit.registered_commands) do
			if minetest.check_player_privs(name, def.privs) then
				list[#list + 1] = cmd
			end
		end
		table.sort(list)
		local help = minetest.colorize("#0ff", "//help")
		return true, S("Available commands: @1@n"
				.. "Use '@2' to get more information,"
				.. " or '@3' to list everything.",
				table.concat(list, " "), help .. " <cmd>", help .. " all")
	elseif param == "all" then
		local cmds = {}
		for cmd, def in pairs(worldedit.registered_commands) do
			if minetest.check_player_privs(name, def.privs) then
				cmds[#cmds + 1] = {cmd, def}
			end
		end
		sort_cmds(cmds)
		local list = {}
		local last_cat = ""
		for _, e in ipairs(cmds) do
			if e[2].category ~= last_cat then
				last_cat = e[2].category
				list[#list + 1] = "---- " .. last_cat
			end
			list[#list + 1] = format_help_line(e[1], e[2])
		end
		return true, S("Available commands:@n") .. table.concat(list, "\n")
	else
		local def = worldedit.registered_commands[param]
		if not def then
			return false, S("Command not available: ") .. param
		else
			return true, format_help_line(param, def, true)
		end
	end
end

worldedit.register_command("help", {
	privs = {},
	params = "[all/<cmd>]",
	description = S("Get help for WorldEdit commands"),
	parse = function(param)
		return true, param
	end,
	func = function(name, param)
		local ok, msg = help_command(name, param)
		if msg then
			worldedit.player_notify(name, msg, ok and "info" or "error")
		end
	end,
})

-- needs to be here due to reset_pending()
worldedit.register_command("reset", {
	params = "",
	description = S("Reset the region so that it is empty"),
	category = S("Region operations"),
	privs = {worldedit=true},
	func = function(name)
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)
		worldedit.set_pos[name] = nil
		--make sure the user does not try to confirm an operation after resetting pos:
		reset_pending(name)
		return true, S("region reset")
	end,
})

-- Load the other parts
do
	local modpath = minetest.get_modpath("worldedit_commands")
	for _, name in ipairs({
		"code", "cuboid_funcs", "cuboid", "manipulations", "marker", "nodename",
		"primitives", "region", "schematics", "transform", "wand"
	}) do
		dofile(modpath .. "/" .. name .. ".lua")
	end

	if worldedit.register_test then
		dofile(modpath .. "/test/init.lua")
	end
end
