-- Expands or contracts the cuboid in all axes by amount (positive or negative)
worldedit.cuboid_volumetric_expand = function(name, amount)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	
	if pos1 == nil or pos2 == nil then
		return false, "Undefined cuboid"
	end
	
	local delta1 = vector.new()
	local delta2 = vector.new()
	local delta_dir1
	local delta_dir2
	
	delta1 = vector.add(delta1, amount)
	delta2 = vector.add(delta2, amount)
	delta_dir1, delta_dir2 = worldedit.get_expansion_directions(pos1, pos2)
	delta1 = vector.multiply(delta1, delta_dir1)
	delta2 = vector.multiply(delta2, delta_dir2)
	worldedit.pos1[name] = vector.add(pos1, delta1)
	worldedit.pos2[name] = vector.add(pos2, delta2)
	
	return true
end


-- Expands or contracts the cuboid in a single axis by amount (positive or negative)
worldedit.cuboid_linear_expand = function(name, axis, direction, amount)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	
	if pos1 == nil or pos2 == nil then
		return false, "undefined cuboid"
	end
	
	if direction ~= 1 and direction ~= -1 then
		return false, "invalid marker"
	end
	
	local marker = worldedit.marker_get_closest_to_axis(name, axis, direction)
	local deltavect = vector.new()
	
	if axis == 'x' then
		deltavect.x = amount * direction
	elseif axis == 'y' then
		deltavect.y = amount * direction
	elseif axis == 'z' then
		deltavect.z = amount * direction
	else
		return false, "invalid axis"
	end
	
	worldedit.marker_move(name, marker, deltavect)
	return true
end


-- Shifts the cuboid by '+-amount' in axis 'axis'
worldedit.cuboid_shift = function(name, axis, amount)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	
	if pos1 == nil or pos2 == nil then
		return false, "undefined cuboid"
	end
	
	if axis == 'x' then
		worldedit.pos1[name].x = pos1.x + amount
		worldedit.pos2[name].x = pos2.x + amount
	elseif axis == 'y' then
		worldedit.pos1[name].y = pos1.y + amount
		worldedit.pos2[name].y = pos2.y + amount
	elseif axis == 'z' then
		worldedit.pos1[name].z = pos1.z + amount
		worldedit.pos2[name].z = pos2.z + amount
	else
		return false, "invalid axis"
	end
	
	return true
end


-- Moves the location of a single marker by adding deltavector
worldedit.marker_move = function(name, marker, deltavector)
	if marker ~= 1 and marker ~= 2 then
		return false
	end
	
	if marker == 1 then
		local pos = worldedit.pos1[name]
		worldedit.pos1[name] = vector.add(deltavector, pos)
	else
		local pos = worldedit.pos2[name]
		worldedit.pos2[name] = vector.add(deltavector, pos)
	end
	
	return true
end

-- Updates the location ingame of the markers
worldedit.marker_update = function(name, marker)
	if marker == nil then
		worldedit.mark_pos1(name)
		worldedit.mark_pos2(name)
	elseif marker == 1 then
		worldedit.mark_pos1(name)
	elseif marker == 2 then
		worldedit.mark_pos2(name)
	else
		minetest.debug(
			"worldedit: Invalid execution of function update_markers")
	end
end


-- Returns two vectors with the directions for volumetric expansion
worldedit.get_expansion_directions = function(mark1, mark2)
	if mark1 == nil or mark2 == nil then
		return
	end
	local dir1 = vector.new()
	local dir2 = vector.new()

	if mark1.x < mark2.x then
		dir1.x = -1
		dir2.x = 1
	else
		dir1.x = 1
		dir2.x = -1
	end
	if mark1.y < mark2.y then
		dir1.y = -1
		dir2.y = 1
	else
		dir1.y = 1
		dir2.y = -1
	end
	if mark1.z < mark2.z then
		dir1.z = -1
		dir2.z = 1
	else
		dir1.z = 1
		dir2.z = -1
	end
	return dir1, dir2
end


-- Return the marker that is closest to the player
worldedit.marker_get_closest_to_player = function(name)
	local playerpos = minetest.get_player_by_name(name):getpos()
	local dist1 = vector.distance(playerpos, worldedit.pos1[name])
	local dist2 = vector.distance(playerpos, worldedit.pos2[name])
	
	if dist1 < dist2 then
		return 1
	else
		return 2
	end
end


-- Returns the closest marker to the specified axis and direction
worldedit.marker_get_closest_to_axis = function(name, axis, direction)
	local pos1 = vector.new()
	local pos2 = vector.new()
	
	if direction ~= 1 and direction ~= -1 then
		return nil
	end

	if axis == 'x' then
		pos1.x = worldedit.pos1[name].x * direction
		pos2.x = worldedit.pos2[name].x * direction
		if pos1.x > pos2.x then
			return 1
		else
			return 2
		end
	elseif axis == 'y' then
		pos1.y = worldedit.pos1[name].y * direction
		pos2.y = worldedit.pos2[name].y * direction
		if pos1.y > pos2.y then
			return 1
		else
			return 2
		end
	elseif axis == 'z' then
		pos1.z = worldedit.pos1[name].z * direction
		pos2.z = worldedit.pos2[name].z * direction
		if pos1.z > pos2.z then
			return 1
		else
			return 2
		end
	else
		return nil
	end
end


-- Translates up, down, left, right, front, back to their corresponding axes and 
-- directions according to faced direction
worldedit.translate_direction = function(name, direction)
	local axis, dir = worldedit.player_axis(name)
	local resaxis, resdir
	
	if direction == "up" then
		return 'y', 1
	end
	
	if direction == "down" then
		return 'y', -1
	end
	
	if direction == "front" then
		if axis == "y" then
			resaxis = nil
			resdir = nil
		else
			resaxis = axis
			resdir = dir
		end
	end
	
	if direction == "back" then
		if axis == "y" then
			resaxis = nil
			resdir = nil
		else
			resaxis = axis
			resdir = -dir
		end
	end
	
	if direction == "left" then
		if axis == 'x' then
			resaxis = 'z'
			resdir = dir
		elseif axis == 'z' then
			resaxis = 'x'
			resdir = -dir
		end
	end
	
	if direction == "right" then
		if axis == 'x' then
			resaxis = 'z'
			resdir = -dir
		elseif axis == 'z' then
			resaxis = 'x'
			resdir = dir
		end
	end
	
	return resaxis, resdir
end