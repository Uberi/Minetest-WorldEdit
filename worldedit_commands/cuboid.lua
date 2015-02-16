dofile(minetest.get_modpath("worldedit_commands") .. "/cuboidapi.lua")


minetest.register_chatcommand("/outset", {
	params = "[h|v] <amount>",
	description = "outset the selection",
	privs = {worldedit=true},
	func = function(name, param)
		local find, _, dir, amount = param:find("([hv]?)%s*([+-]?%d+)")
		
		if find == nil then
			return false, "invalid usage: " .. param
		end
		
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]
		
		if pos1 == nil or pos2 == nil then
			return false, 
				"Undefined region. Region must be defined beforehand."
		end
		
		if dir == "" then
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
			return false, "Unknown error"
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
		local find, _, dir, amount = param:find("([hv]?)%s*([+-]?%d+)")
		
		if find == nil then
			return false, "invalid usage: " .. param
		end
		
		local pos1 = worldedit.pos1[name]
		local pos2 = worldedit.pos2[name]
		
		if pos1 == nil or pos2 == nil then
			return false, 
				"Undefined region. Region must be defined beforehand."
		end
		
		if dir == "" then
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
			return false, "Unknown error"
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
		if direction ~= "?" then
			axis, dir = worldedit.translate_direction(name, direction)
		else
			axis, dir = worldedit.player_axis(name)
		end
		
		if axis == nil or dir == nil then
			return false, "Invalid"
		end
		
		assert(worldedit.cuboid_shift(name, axis, amount * dir))
		worldedit.marker_update(name)
		
		return true, "region shifted by " .. amount .. " nodes"
      end,
  }
)


minetest.register_chatcommand("/expand", {
	params = "<amount> [reverse-amount] [up|down|left|right|front|back]",
	description = "expand the selection in one or two directions at once",
	privs = {worldedit=true},
	func = function(name, param)
	local find, _, amount, arg2, arg3 = param:find("(%d+)%s*(%w*)%s*(%l*)")
	
	if find == nil then
		worldedit.player_notify(name, "invalid use: " .. param)
		return
	end
	
	if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
		worldedit.player_notify(name, 
		"Undefined region. Region must be defined beforehand.")
		return
	end
	
	local tmp = tonumber(arg2)
	local axis, dir
	local reverse_amount = 0
	
	axis,dir = worldedit.player_axis(name)
	
	if arg2 ~= "" then
		if tmp == nil then
			axis, dir = worldedit.translate_direction(name, arg2)
		else
			reverse_amount = tmp
		end
	end
	
	if arg3 ~= "" then
		axis, dir = worldedit.translate_direction(name, arg3)
	end
	
	worldedit.cuboid_linear_expand(name, axis, dir, amount)
	worldedit.cuboid_linear_expand(name, axis, -dir, reverse_amount)
	worldedit.marker_update(name)
      end,
  }
)


minetest.register_chatcommand("/contract", {
	params = "<amount> [reverse-amount] [up|down|left|right|front|back]",
	description = "contract the selection in one or two directions at once",
	privs = {worldedit=true},
	func = function(name, param)
	local find, _, amount, arg2, arg3 = param:find("(%d+)%s*(%w*)%s*(%l*)")
	
	if find == nil then
		worldedit.player_notify(name, "invalid use: " .. param)
		return
	end
	
	if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
		worldedit.player_notify(name, 
		"Undefined region. Region must be defined beforehand.")
		return
	end
	
	local tmp = tonumber(arg2)
	local axis, dir
	local reverse_amount = 0
	
	axis,dir = worldedit.player_axis(name)
	
	if arg2 ~= "" then
		if tmp == nil then
			axis, dir = worldedit.translate_direction(name, arg2)
		else
			reverse_amount = tmp
		end
	end
	
	if arg3 ~= "" then
		axis, dir = worldedit.translate_direction(name, arg3)
	end
	
	worldedit.cuboid_linear_expand(name, axis, dir, -amount)
	worldedit.cuboid_linear_expand(name, axis, -dir, -reverse_amount)
	worldedit.marker_update(name)
      end,
  }
)