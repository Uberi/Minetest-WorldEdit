local S = minetest.get_translator("worldedit_commands")

local VALID_DIR = worldedit.valid_directions

worldedit.register_command("outset", {
	params = "[h/v] <amount>",
	description = S("Outset the selected region."),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, dir, amount = param:find("^(%a*)%s+([+-]?%d+)$")
		if find == nil then
			return false
		end

		local hv_test = dir:find("[^hv]+")
		if hv_test ~= nil then
			return false, S("Invalid direction: @1", dir)
		end

		return true, dir, tonumber(amount)
	end,
	func = function(name, dir, amount)
		if dir == "" or dir == "hv" or dir == "vh" then
			assert(worldedit.cuboid_volumetric_expand(name, amount))
		elseif dir == "h" then
			assert(worldedit.cuboid_linear_expand(name, 'x', 1, amount))
			assert(worldedit.cuboid_linear_expand(name, 'x', -1, amount))
			assert(worldedit.cuboid_linear_expand(name, 'z', 1, amount))
			assert(worldedit.cuboid_linear_expand(name, 'z', -1, amount))
		elseif dir == "v" then
			assert(worldedit.cuboid_linear_expand(name, 'y', 1, amount))
			assert(worldedit.cuboid_linear_expand(name, 'y', -1, amount))
		else
			return false, S("Invalid number of arguments")
		end

		worldedit.marker_update(name)
		return true, S("Region outset by @1 nodes", amount)
      end,
})


worldedit.register_command("inset", {
	params = "[h/v] <amount>",
	description = S("Inset the selected region."),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, dir, amount = param:find("^(%a*)%s+([+-]?%d+)$")
		if find == nil then
			return false
		end
		if dir:find("[^hv]") ~= nil then
			return false, S("Invalid direction: @1", dir)
		end

		return true, dir, tonumber(amount)
	end,
	func = function(name, dir, amount)
		if dir == "" or dir == "vh" or dir == "hv" then
			assert(worldedit.cuboid_volumetric_expand(name, -amount))
		elseif dir == "h" then
			assert(worldedit.cuboid_linear_expand(name, 'x', 1, -amount))
			assert(worldedit.cuboid_linear_expand(name, 'x', -1, -amount))
			assert(worldedit.cuboid_linear_expand(name, 'z', 1, -amount))
			assert(worldedit.cuboid_linear_expand(name, 'z', -1, -amount))
		elseif dir == "v" then
			assert(worldedit.cuboid_linear_expand(name, 'y', 1, -amount))
			assert(worldedit.cuboid_linear_expand(name, 'y', -1, -amount))
		else
			return false, S("Invalid number of arguments")
		end

		worldedit.marker_update(name)
		return true, S("Region inset by @1 nodes", amount)
      end,
})


worldedit.register_command("shift", {
	params = tostring(VALID_DIR) .. " [+/-]<amount>",
	description = S("Shifts the selection area without moving its contents"),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, direction, amount = param:find("^([^%s]+)%s+([+-]?%d+)$")
		if find == nil or not VALID_DIR[direction] then
			return false
		end

		return true, direction, tonumber(amount)
	end,
	func = function(name, direction, amount)
		local axis, dir = worldedit.player_direction(name, direction)
		if axis == nil or dir == nil then
			return false, S("Invalid if looking straight up or down")
		end

		assert(worldedit.cuboid_shift(name, axis, amount * dir))
		worldedit.marker_update(name)

		return true, S("Region shifted by @1 nodes", amount)
      end,
})


worldedit.register_command("expand", {
	params = "[+/-]" .. tostring(VALID_DIR) .. " <amount> [reverse amount]",
	description = S("Expands the selection in the selected absolute or relative axis"),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, sign, direction, amount,
				rev_amount = param:find("^([+-]?)([^%s]+)%s+(%d+)%s*(%d*)$")
		if find == nil or not VALID_DIR[direction] then
			return false
		end

		if rev_amount == "" then
			rev_amount = "0"
		end

		return true, sign, direction, tonumber(amount), tonumber(rev_amount)
	end,
	func = function(name, sign, direction, amount, rev_amount)
		local axis, dir = worldedit.player_direction(name, direction)
		if axis == nil or dir == nil then
			return false, S("Invalid if looking straight up or down")
		end
		if sign == "-" then
			dir = -dir
		end

		worldedit.cuboid_linear_expand(name, axis, dir, amount)
		worldedit.cuboid_linear_expand(name, axis, -dir, rev_amount)
		worldedit.marker_update(name)
		return true, S("Region expanded by @1 nodes", amount + rev_amount)
	end,
})


worldedit.register_command("contract", {
	params = "[+/-]" .. tostring(VALID_DIR) .. " [reverse amount]",
	description = S("Contracts the selection in the selected absolute or relative axis"),
	category = S("Region operations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, sign, direction, amount,
				rev_amount = param:find("^([+-]?)([^%s]+)%s+(%d+)%s*(%d*)$")
		if find == nil or not VALID_DIR[direction] then
			return false
		end

		if rev_amount == "" then
			rev_amount = "0"
		end

		return true, sign, direction, tonumber(amount), tonumber(rev_amount)
	end,
	func = function(name, sign, direction, amount, rev_amount)
		local axis, dir = worldedit.player_direction(name, direction)
		if axis == nil or dir == nil then
			return false, S("Invalid if looking straight up or down")
		end
		if sign == "-" then
			dir = -dir
		end

		worldedit.cuboid_linear_expand(name, axis, dir, -amount)
		worldedit.cuboid_linear_expand(name, axis, -dir, -rev_amount)
		worldedit.marker_update(name)
		return true, S("Region contracted by @1 nodes", amount + rev_amount)
	end,
})

worldedit.register_command("cubeapply", {
	params = "<size>/(<sizex> <sizey> <sizez>) <command> [parameters]",
	description = S("Select a cube with side length <size> around position 1 and run <command> on region"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		local found, _, sidex, sidey, sidez, cmd, args =
			param:find("^(%d+)%s+(%d+)%s+(%d+)%s+([^%s]+)%s*(.*)$")
		if found == nil then
			found, _, sidex, cmd, args = param:find("^(%d+)%s+([^%s]+)%s*(.*)$")
			if found == nil then
				return false
			end
			sidey = sidex
			sidez = sidex
		end
		sidex = tonumber(sidex)
		sidey = tonumber(sidey)
		sidez = tonumber(sidez)
		if sidex < 1 or sidey < 1 or sidez < 1 then
			return false
		end
		local cmddef = worldedit.registered_commands[cmd]
		if cmddef == nil or cmddef.require_pos ~= 2 then
			return false, S("invalid usage: @1 cannot be used with cubeapply",
				minetest.colorize("#0ff", "//"..cmd))
		end
		-- run parsing of target command
		local parsed = {cmddef.parse(args)}
		if not table.remove(parsed, 1) then
			return false, parsed[1]
		end
		return true, sidex, sidey, sidez, cmd, parsed
	end,
	nodes_needed = function(name, sidex, sidey, sidez, cmd, parsed)
		-- its not possible to defer to the target command at this point
		-- FIXME: why not?
		return sidex * sidey * sidez
	end,
	func = function(name, sidex, sidey, sidez, cmd, parsed)
		local cmddef = assert(worldedit.registered_commands[cmd])
		local success, missing_privs = minetest.check_player_privs(name, cmddef.privs)
		if not success then
			return false, S("Missing privileges: @1", table.concat(missing_privs, ", "))
		end

		-- update region to be the cuboid the user wanted
		local half = vector.divide(vector.new(sidex, sidey, sidez), 2)
		local sizea, sizeb = vector.apply(half, math.floor), vector.apply(half, math.ceil)
		local center = worldedit.pos1[name]
		worldedit.pos1[name] = vector.subtract(center, sizea)
		worldedit.pos2[name] = vector.add(center, vector.subtract(sizeb, 1))
		worldedit.marker_update(name)

		-- actually run target command
		return cmddef.func(name, unpack(parsed))
	end,
})
