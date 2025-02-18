local S = minetest.get_translator("worldedit_commands")

local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end


worldedit.register_command("copy", {
	params = "x/y/z/? <amount>",
	description = S("Copy the current WorldEdit region along the given axis by <amount> nodes"),
	category = S("Transformations"),
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
		return true, S("@1 nodes copied", count)
	end,
})

worldedit.register_command("move", {
	params = "x/y/z/? <amount>",
	description = S("Move the current WorldEdit region along the given axis by <amount> nodes"),
	category = S("Transformations"),
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
		return true, S("@1 nodes moved", count)
	end,
})

worldedit.register_command("stack", {
	params = "x/y/z/? <count>",
	description = S("Stack the current WorldEdit region along the given axis <count> times"),
	category = S("Transformations"),
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
			worldedit.player_notify(name, S("@1 nodes stacked", count), "ok")
		end)
	end,
})

worldedit.register_command("stack2", {
	params = "<count> <x> <y> <z>",
	description = S("Stack the current WorldEdit region <count> times by offset <x>, <y>, <z>"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local repetitions, incs = param:match("(%d+)%s*(.+)")
		if repetitions == nil then
			return false, S("invalid count: @1", param)
		end
		local x, y, z = incs:match("([+-]?%d+) ([+-]?%d+) ([+-]?%d+)")
		if x == nil then
			return false, S("invalid increments: @1", param)
		end

		return true, tonumber(repetitions), vector.new(tonumber(x), tonumber(y), tonumber(z))
	end,
	nodes_needed = function(name, repetitions, offset)
		return check_region(name) * repetitions
	end,
	func = function(name, repetitions, offset)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.volume(pos1, pos2) * repetitions
		worldedit.stack2(pos1, pos2, offset, repetitions, function()
			worldedit.player_notify(name, S("@1 nodes stacked", count), "ok")
		end)
	end,
})

worldedit.register_command("stretch", {
	params = "<stretchx> <stretchy> <stretchz>",
	description = S("Scale the current WorldEdit positions and region by a factor of <stretchx>, <stretchy>, <stretchz> along the X, Y, and Z axes, repectively, with position 1 as the origin"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, stretchx, stretchy, stretchz = param:find("^(%d+)%s+(%d+)%s+(%d+)$")
		if found == nil then
			return false
		end
		stretchx, stretchy, stretchz = tonumber(stretchx), tonumber(stretchy), tonumber(stretchz)
		if stretchx == 0 or stretchy == 0 or stretchz == 0 then
			return false, S("invalid scaling factors: @1", param)
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

		return true, S("@1 nodes stretched", count)
	end,
})

worldedit.register_command("transpose", {
	params = "x/y/z/? x/y/z/?",
	description = S("Transpose the current WorldEdit region along the given axes"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis1, axis2 = param:find("^([xyz%?])%s+([xyz%?])$")
		if found == nil then
			return false
		elseif axis1 == axis2 then
			return false, S("invalid usage: axes must be different")
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

		return true, S("@1 nodes transposed", count)
	end,
})

worldedit.register_command("flip", {
	params = "x/y/z/?",
	description = S("Flip the current WorldEdit region along the given axis"),
	category = S("Transformations"),
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
		return true, S("@1 nodes flipped", count)
	end,
})

worldedit.register_command("rotate", {
	params = "x/y/z/? <angle>",
	description = S("Rotate the current WorldEdit region around the given axis by angle <angle> (90 degree increment)"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local found, _, axis, angle = param:find("^([xyz%?])%s+([+-]?%d+)$")
		if found == nil then
			return false
		end
		angle = tonumber(angle)
		if angle % 90 ~= 0 or angle % 360 == 0 then
			return false, S("invalid usage: angle must be multiple of 90")
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

		return true, S("@1 nodes rotated", count)
	end,
})

worldedit.register_command("orient", {
	params = "<operation> x/y/z/? [<angle>]",
	description = S("Change orientation of all oriented nodes in the current WorldEdit region performing <operation> (rotate or flip) around the <axis> axis by angle <angle> (90 degree increment, unused for flip operation)"),
	category = S("Transformations"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local operation, axis, angle = unpack(param:split(" "))
		--~ return true, operation, axis, angle
		if (operation == 'flip' or operation == 'rotate') and (axis == 'x' or axis == 'y' or axis == 'z' or axis == '?') then
			if operation == 'rotate' then
				angle = tonumber(angle) or 90
				if angle % 90 ~= 0 then
					return false, S("invalid usage: angle must be multiple of 90")
				end
			end
			return true, operation, axis, angle
		end
	end,
	nodes_needed = check_region,
	func = function(name, operation, axis, angle)
		if axis == "?" then axis = worldedit.player_axis(name) end
		local count = worldedit.orient(worldedit.pos1[name], worldedit.pos2[name], operation, axis, angle)
		return true, S("@1 nodes oriented", count)
	end,
})

