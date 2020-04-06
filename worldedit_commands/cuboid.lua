worldedit.register_command("outset", {
	params = "[h|v] <amount>",
	description = "Outset the selected region.",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, dir, amount = param:find("(%a*)%s*([+-]?%d+)")
		if find == nil then
			return false
		end

		local hv_test = dir:find("[^hv]+")
		if hv_test ~= nil then
			return false, "Invalid direction."
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
			return false, "Invalid number of arguments"
		end

		worldedit.marker_update(name)
		return true, "Region outset by " .. amount .. " blocks"
      end,
})


worldedit.register_command("inset", {
	params = "[h|v] <amount>",
	description = "Inset the selected region.",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, dir, amount = param:find("(%a*)%s*([+-]?%d+)")
		if find == nil then
			return false
		end

		local hv_test = dir:find("[^hv]+")
		if hv_test ~= nil then
			return false, "Invalid direction."
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
			return false, "Invalid number of arguments"
		end

		worldedit.marker_update(name)
		return true, "Region inset by " .. amount .. " blocks"
      end,
})


worldedit.register_command("shift", {
	params = "[x|y|z|?|up|down|left|right|front|back] [+|-]<amount>",
	description = "Moves the selection region. Does not move contents.",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, direction, amount = param:find("([%?%l]+)%s*([+-]?%d+)")
		if find == nil then
			return false
		end

		return true, direction, tonumber(amount)
	end,
	func = function(name, direction, amount)
		local axis, dir
		if direction == "x" or direction == "y" or direction == "z" then
			axis, dir = direction, 1
		elseif direction == "?" then
			axis, dir = worldedit.player_axis(name)
		else
			axis, dir = worldedit.translate_direction(name, direction)
		end

		if axis == nil or dir == nil then
			return false, "Invalid if looking straight up or down"
		end

		assert(worldedit.cuboid_shift(name, axis, amount * dir))
		worldedit.marker_update(name)

		return true, "Region shifted by " .. amount .. " nodes"
      end,
})


worldedit.register_command("expand", {
	params = "[+|-]<x|y|z|?|up|down|left|right|front|back> <amount> [reverse-amount]",
	description = "expand the selection in one or two directions at once",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, sign, direction, amount,
				rev_amount = param:find("([+-]?)([%?%l]+)%s*(%d+)%s*(%d*)")
		if find == nil then
			return false
		end

		if rev_amount == "" then
			rev_amount = "0"
		end

		return true, sign, direction, tonumber(amount), tonumber(rev_amount)
	end,
	func = function(name, sign, direction, amount, rev_amount)
		local absolute = direction:find("[xyz?]")
		local dir, axis

		if absolute == nil then
			axis, dir = worldedit.translate_direction(name, direction)

			if axis == nil or dir == nil then
				return false, "Invalid if looking straight up or down"
			end
		else
			if direction == "?" then
				axis, dir = worldedit.player_axis(name)
			else
				axis = direction
				dir = 1
			end
		end

		if sign == "-" then
			dir = -dir
		end

		worldedit.cuboid_linear_expand(name, axis, dir, amount)
		worldedit.cuboid_linear_expand(name, axis, -dir, rev_amount)
		worldedit.marker_update(name)
		return true, "Region expanded by " .. (amount + rev_amount) .. " nodes"
	end,
})


worldedit.register_command("contract", {
	params = "[+|-]<x|y|z|?|up|down|left|right|front|back> <amount> [reverse-amount]",
	description = "contract the selection in one or two directions at once",
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local find, _, sign, direction, amount,
				rev_amount = param:find("([+-]?)([%?%l]+)%s*(%d+)%s*(%d*)")
		if find == nil then
			return false
		end

		if rev_amount == "" then
			rev_amount = "0"
		end

		return true, sign, direction, tonumber(amount), tonumber(rev_amount)
	end,
	func = function(name, sign, direction, amount, rev_amount)
		local absolute = direction:find("[xyz?]")
		local dir, axis

		if absolute == nil then
			axis, dir = worldedit.translate_direction(name, direction)

			if axis == nil or dir == nil then
				return false, "Invalid if looking straight up or down"
			end
		else
			if direction == "?" then
				axis, dir = worldedit.player_axis(name)
			else
				axis = direction
				dir = 1
			end
		end

		if sign == "-" then
			dir = -dir
		end

		worldedit.cuboid_linear_expand(name, axis, dir, -amount)
		worldedit.cuboid_linear_expand(name, axis, -dir, -rev_amount)
		worldedit.marker_update(name)
		return true, "Region contracted by " .. (amount + rev_amount) .. " nodes"
	end,
})

worldedit.register_command("cubeapply", {
	params = "<size> <command> [parameters]",
	description = "Select a cube with side length <size> around position 1 and run <command> on region",
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		local found, _, side_length, cmd, args = param:find("^(%d+)%s+([^%s]+)%s*(.*)$")
		if found == nil then
			return false
		end
		side_length = tonumber(side_length)
		if side_length < 1 then
			return false
		end
		local cmddef = worldedit.registered_commands[cmd]
		if cmddef == nil or cmddef.require_pos ~= 2 then
			return false, "invalid usage: //" .. cmd .. " cannot be used with cubeapply"
		end
		-- run parsing of target command
		local parsed = {cmddef.parse(args)}
		if not table.remove(parsed, 1) then
			return false, parsed[1]
		end
		return true, side_length, cmd, parsed
	end,
	nodes_needed = function(name, side_length, cmd, parsed)
		-- its not possible to defer to the target command at this point
		return side_length * side_length * side_length
	end,
	func = function(name, side_length, cmd, parsed)
		local cmddef = assert(worldedit.registered_commands[cmd])
		local success, missing_privs = minetest.check_player_privs(name, cmddef.privs)
		if not success then
			worldedit.player_notify(name, "Missing privileges: " ..
				table.concat(missing_privs, ", "))
			return
		end

		-- update region to be the cube the user wanted
		local sizea, sizeb = math.floor(side_length / 2), math.ceil(side_length / 2)
		local center = worldedit.pos1[name]
		worldedit.pos1[name] = vector.subtract(center, sizea)
		worldedit.pos2[name] = vector.add(center, sizeb - 1)
		worldedit.marker_update(name)

		-- actually run target command
		return cmddef.func(name, unpack(parsed))
	end,
})
