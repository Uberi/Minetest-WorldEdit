-- Moves the location of a single marker by adding deltavector
local function marker_move(name, marker, deltavector)
	if marker == 1 then
		local pos = worldedit.pos1[name]
		worldedit.pos1[name] = vector.add(deltavector, pos)
	elseif marker == 2 then
		local pos = worldedit.pos2[name]
		worldedit.pos2[name] = vector.add(deltavector, pos)
	else
		assert(false)
	end
	return true
end


-- Returns two vectors with the directions for volumetric expansion
local function get_expansion_directions(mark1, mark2)
	assert(mark1 and mark2)
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


-- Returns the closest marker to the specified axis and direction
local function marker_get_closest_to_axis(name, axis, direction)
	assert(direction == 1 or direction == -1)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]

	if axis == "x" then
		if pos1.x * direction > pos2.x * direction then
			return 1
		else
			return 2
		end
	elseif axis == "y" then
		if pos1.y * direction > pos2.y * direction then
			return 1
		else
			return 2
		end
	elseif axis == "z" then
		if pos1.z * direction > pos2.z * direction then
			return 1
		else
			return 2
		end
	else
		assert(false)
	end
end


-- Expands or contracts the cuboid in all axes by amount (positive or negative)
worldedit.cuboid_volumetric_expand = function(name, amount)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]

	if pos1 == nil or pos2 == nil then
		return false, "Undefined cuboid"
	end

	local delta1 = vector.new(amount, amount, amount)
	local delta2 = vector.new(amount, amount, amount)
	local delta_dir1, delta_dir2 = get_expansion_directions(pos1, pos2)
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

	local marker = marker_get_closest_to_axis(name, axis, direction)
	local deltavect = vector.new()

	if axis == "x" then
		deltavect.x = amount * direction
	elseif axis == "y" then
		deltavect.y = amount * direction
	elseif axis == "z" then
		deltavect.z = amount * direction
	else
		return false, "invalid axis"
	end

	marker_move(name, marker, deltavect)
	return true
end


-- Shifts the cuboid by '+-amount' in axis 'axis'
worldedit.cuboid_shift = function(name, axis, amount)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]

	if pos1 == nil or pos2 == nil then
		return false, "undefined cuboid"
	end

	local delta = vector.new()
	if axis == "x" then
		delta.x = amount
	elseif axis == "y" then
		delta.y = amount
	elseif axis == "z" then
		delta.z = amount
	else
		return false, "invalid axis"
	end

	worldedit.pos1[name] = vector.add(pos1, delta)
	worldedit.pos2[name] = vector.add(pos2, delta)
	return true
end
