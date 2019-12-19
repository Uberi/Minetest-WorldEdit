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
