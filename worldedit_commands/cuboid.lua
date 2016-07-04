minetest.register_chatcommand("/outset", {
	params = "[h|v] <amount>",
	description = "outset the selection",
	privs = {worldedit=true},
	func = function(name, param)
		local find, _, dir, amount = param:find("(%a*)%s*([+-]?%d+)")
		
		if find == nil then
			return false, "invalid usage: " .. param
		end
		
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]
		
		if pos1 == nil or pos2 == nil then
			return false, 
				"Undefined region. Region must be defined beforehand."
		end
		
		local hv_test = dir:find("[^hv]+")
		
		if hv_test ~= nil then
			return false, "Invalid direction."
		end
		
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
  }
)


minetest.register_chatcommand("/inset", {
	params = "[h|v] <amount>",
	description = "inset the selection",
	privs = {worldedit=true},
	func = function(name, param)
		local find, _, dir, amount = param:find("(%a*)%s*([+-]?%d+)")
		
		if find == nil then
			return false, "invalid usage: " .. param
		end
		
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]
		
		if pos1 == nil or pos2 == nil then
			return false, 
				"Undefined region. Region must be defined beforehand."
		end
		
		local hv_test = dir:find("[^hv]+")
		
		if hv_test ~= nil then
			return false, "Invalid direction."
		end
		
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
  }
)


minetest.register_chatcommand("/shift", {
	params = "[x|y|z|?|up|down|left|right|front|back] [+|-]<amount>",
	description = "Moves the selection region. Does not move contents.",
	privs = {worldedit=true},
	func = function(name, param)
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]
		local find, _, direction, amount = param:find("([%?%l]+)%s*([+-]?%d+)")
		
		if find == nil then
			worldedit.player_notify(name, "invalid usage: " .. param)
			return
		end
		
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, 
				"Undefined region. Region must be defined beforehand.")
			return
		end
		
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
  }
)


minetest.register_chatcommand("/expand", {
	params = "[+|-]<x|y|z|?|up|down|left|right|front|back> <amount> [reverse-amount]",
	description = "expand the selection in one or two directions at once",
	privs = {worldedit=true},
	func = function(name, param)
	local find, _, sign, direction, amount, 
			rev_amount = param:find("([+-]?)([%?%l]+)%s*(%d+)%s*(%d*)")
	
	if find == nil then
		worldedit.player_notify(name, "invalid use: " .. param)
		return
	end
	
	if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
		worldedit.player_notify(name, 
		"Undefined region. Region must be defined beforehand.")
		return
	end
	
	local absolute = direction:find("[xyz?]")
	local dir, axis
	
	if rev_amount == "" then
		rev_amount = 0
	end
	
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
  }
)


minetest.register_chatcommand("/contract", {
	params = "[+|-]<x|y|z|?|up|down|left|right|front|back> <amount> [reverse-amount]",
	description = "contract the selection in one or two directions at once",
	privs = {worldedit=true},
	func = function(name, param)
	local find, _, sign, direction, amount, 
			rev_amount = param:find("([+-]?)([%?%l]+)%s*(%d+)%s*(%d*)")
	
	if find == nil then
		worldedit.player_notify(name, "invalid use: " .. param)
		return
	end
	
	if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
		worldedit.player_notify(name, 
		"Undefined region. Region must be defined beforehand.")
		return
	end
	
	local absolute = direction:find("[xyz?]")
	local dir, axis
	
	if rev_amount == "" then
		rev_amount = 0
	end
	
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
  }
)
