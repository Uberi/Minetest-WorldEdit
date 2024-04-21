--- Node transformations.
-- @module worldedit.transformations

worldedit.deferred_execution = function(next_one, finished)
	-- Allocate 80% of server step for execution
	local allocated_usecs =
		tonumber(minetest.settings:get("dedicated_server_step"):split(" ")[1]) * 1000000 * 0.8
	local function f()
		local deadline = minetest.get_us_time() + allocated_usecs
		repeat
			local is_done = next_one()
			if is_done then
				if finished then
					finished()
				end
				return
			end
		until minetest.get_us_time() >= deadline
		minetest.after(0, f)
	end
	f()
end

--- Duplicates a region `amount` times with offset vector `direction`.
-- Stacking is spread across server steps.
-- @return The number of nodes stacked.
function worldedit.stack2(pos1, pos2, direction, amount, finished)
	-- Protect arguments from external changes during execution
	pos1 = vector.copy(pos1)
	pos2 = vector.copy(pos2)
	direction = vector.copy(direction)

	local i = 0
	local translated = vector.new()
	local function step()
		translated.x = translated.x + direction.x
		translated.y = translated.y + direction.y
		translated.z = translated.z + direction.z
		worldedit.copy2(pos1, pos2, translated)
		i = i + 1
		return i >= amount
	end
	worldedit.deferred_execution(step, finished)

	return worldedit.volume(pos1, pos2) * amount
end


--- Duplicates a region along `axis` `amount` times.
-- Stacking is spread across server steps.
-- @param pos1
-- @param pos2
-- @param axis Axis direction, "x", "y", or "z".
-- @param count
-- @return The number of nodes stacked.
function worldedit.stack(pos1, pos2, axis, count, finished)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local length = pos2[axis] - pos1[axis] + 1
	if count < 0 then
		count = -count
		length = -length
	end

	local i, distance = 0, 0
	local function step()
		distance = distance + length
		worldedit.copy(pos1, pos2, axis, distance)
		i = i + 1
		return i >= count
	end
	worldedit.deferred_execution(step, finished)

	return worldedit.volume(pos1, pos2) * count
end


--- Stretches a region by a factor of positive integers along the X, Y, and Z
-- axes, respectively, with `pos1` as the origin.
-- @param pos1
-- @param pos2
-- @param stretch_x Amount to stretch along X axis.
-- @param stretch_y Amount to stretch along Y axis.
-- @param stretch_z Amount to stretch along Z axis.
-- @return The number of nodes scaled.
-- @return The new scaled position 1.
-- @return The new scaled position 2.
function worldedit.stretch(pos1, pos2, stretch_x, stretch_y, stretch_z)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	-- Prepare schematic of large node
	local get_node, get_meta, place_schematic = minetest.get_node,
			minetest.get_meta, minetest.place_schematic
	local placeholder_node = {name="", param1=255, param2=0}
	local nodes = {}
	for i = 1, stretch_x * stretch_y * stretch_z do
		nodes[i] = placeholder_node
	end
	local schematic = {size=vector.new(stretch_x, stretch_y, stretch_z), data=nodes}

	local size_x, size_y, size_z = stretch_x - 1, stretch_y - 1, stretch_z - 1

	local new_pos2 = {
		x = pos1.x + (pos2.x - pos1.x) * stretch_x + size_x,
		y = pos1.y + (pos2.y - pos1.y) * stretch_y + size_y,
		z = pos1.z + (pos2.z - pos1.z) * stretch_z + size_z,
	}
	worldedit.keep_loaded(pos1, new_pos2)

	local pos = vector.new(pos2.x, 0, 0)
	local big_pos = vector.new()
	while pos.x >= pos1.x do
		pos.y = pos2.y
		while pos.y >= pos1.y do
			pos.z = pos2.z
			while pos.z >= pos1.z do
				local node = get_node(pos) -- Get current node
				local meta = get_meta(pos):to_table() -- Get meta of current node

				-- Calculate far corner of the big node
				local pos_x = pos1.x + (pos.x - pos1.x) * stretch_x
				local pos_y = pos1.y + (pos.y - pos1.y) * stretch_y
				local pos_z = pos1.z + (pos.z - pos1.z) * stretch_z

				-- Create large node
				placeholder_node.name = node.name
				placeholder_node.param2 = node.param2
				big_pos.x, big_pos.y, big_pos.z = pos_x, pos_y, pos_z
				place_schematic(big_pos, schematic)

				-- Fill in large node meta
				if next(meta.fields) ~= nil or next(meta.inventory) ~= nil then
					-- Node has meta fields
					for x = 0, size_x do
					for y = 0, size_y do
					for z = 0, size_z do
						big_pos.x = pos_x + x
						big_pos.y = pos_y + y
						big_pos.z = pos_z + z
						-- Set metadata of new node
						get_meta(big_pos):from_table(meta)
					end
					end
					end
				end
				pos.z = pos.z - 1
			end
			pos.y = pos.y - 1
		end
		pos.x = pos.x - 1
	end
	return worldedit.volume(pos1, pos2) * stretch_x * stretch_y * stretch_z, pos1, new_pos2
end


--- Transposes a region between two axes.
-- @return The number of nodes transposed.
-- @return The new transposed position 1.
-- @return The new transposed position 2.
function worldedit.transpose(pos1, pos2, axis1, axis2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local compare
	local extent1, extent2 = pos2[axis1] - pos1[axis1], pos2[axis2] - pos1[axis2]

	if extent1 > extent2 then
		compare = function(extent1, extent2)
			return extent1 > extent2
		end
	else
		compare = function(extent1, extent2)
			return extent1 < extent2
		end
	end

	-- Calculate the new position 2 after transposition
	local new_pos2 = vector.new(pos2)
	new_pos2[axis1] = pos1[axis1] + extent2
	new_pos2[axis2] = pos1[axis2] + extent1

	local upper_bound = vector.new(pos2)
	if upper_bound[axis1] < new_pos2[axis1] then upper_bound[axis1] = new_pos2[axis1] end
	if upper_bound[axis2] < new_pos2[axis2] then upper_bound[axis2] = new_pos2[axis2] end
	worldedit.keep_loaded(pos1, upper_bound)

	local pos = vector.new(pos1.x, 0, 0)
	local get_node, get_meta, set_node = minetest.get_node,
			minetest.get_meta, minetest.set_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local extent1, extent2 = pos[axis1] - pos1[axis1], pos[axis2] - pos1[axis2]
				if compare(extent1, extent2) then -- Transpose only if below the diagonal
					local node1 = get_node(pos)
					local meta1 = get_meta(pos):to_table()
					local value1, value2 = pos[axis1], pos[axis2] -- Save position values
					pos[axis1], pos[axis2] = pos1[axis1] + extent2, pos1[axis2] + extent1 -- Swap axis extents
					local node2 = get_node(pos)
					local meta2 = get_meta(pos):to_table()
					set_node(pos, node1)
					get_meta(pos):from_table(meta1)
					pos[axis1], pos[axis2] = value1, value2 -- Restore position values
					set_node(pos, node2)
					get_meta(pos):from_table(meta2)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2), pos1, new_pos2
end


--- Flips a region along `axis`.
-- @return The number of nodes flipped.
function worldedit.flip(pos1, pos2, axis)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	--- TODO: Flip the region slice by slice along the flip axis using schematic method.
	local pos = vector.new(pos1.x, 0, 0)
	local start = pos1[axis] + pos2[axis]
	pos2[axis] = pos1[axis] + math.floor((pos2[axis] - pos1[axis]) / 2)
	local get_node, get_meta, set_node = minetest.get_node,
			minetest.get_meta, minetest.set_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node1 = get_node(pos)
				local meta1 = get_meta(pos):to_table()
				local value = pos[axis] -- Save position
				pos[axis] = start - value -- Shift position
				local node2 = get_node(pos)
				local meta2 = get_meta(pos):to_table()
				set_node(pos, node1)
				get_meta(pos):from_table(meta1)
				pos[axis] = value -- Restore position
				set_node(pos, node2)
				get_meta(pos):from_table(meta2)
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end


--- Rotates a region clockwise around an axis.
-- @param pos1
-- @param pos2
-- @param axis Axis ("x", "y", or "z").
-- @param angle Angle in degrees (90 degree increments only).
-- @return The number of nodes rotated.
-- @return The new first position.
-- @return The new second position.
function worldedit.rotate(pos1, pos2, axis, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local other1, other2 = worldedit.get_axis_others(axis)
	angle = angle % 360

	local count
	if angle == 90 then
		worldedit.flip(pos1, pos2, other1)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, other1, other2)
	elseif angle == 180 then
		worldedit.flip(pos1, pos2, other1)
		count = worldedit.flip(pos1, pos2, other2)
	elseif angle == 270 then
		worldedit.flip(pos1, pos2, other2)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, other1, other2)
	else
		error("Only 90 degree increments are supported!")
	end
	return count, pos1, pos2
end


--- Rotates all oriented nodes in a region clockwise around the Y axis.
-- @param pos1
-- @param pos2
-- @param angle Angle in degrees (90 degree increments only).
-- @return The number of nodes oriented.
function worldedit.orient(pos1, pos2, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local registered_nodes = minetest.registered_nodes

	local wallmounted = {
		[90]  = {0, 1, 5, 4, 2, 3, 0, 0},
		[180] = {0, 1, 3, 2, 5, 4, 0, 0},
		[270] = {0, 1, 4, 5, 3, 2, 0, 0}
	}
	local facedir = {
		[90]  = { 1,  2,  3,  0, 13, 14, 15, 12, 17, 18, 19, 16,
				  9, 10, 11,  8,  5,  6,  7,  4, 23, 20, 21, 22},
		[180] = { 2,  3,  0,  1, 10, 11,  8,  9,  6,  7,  4,  5,
				 18, 19, 16, 17, 14, 15, 12, 13, 22, 23, 20, 21},
		[270] = { 3,  0,  1,  2, 19, 16, 17, 18, 15, 12, 13, 14,
				  7,  4,  5,  6, 11,  8,  9, 10, 21, 22, 23, 20}
	}

	angle = angle % 360
	if angle == 0 then
		return 0
	end
	if angle % 90 ~= 0 then
		error("Only 90 degree increments are supported!")
	end
	local wallmounted_substitution = wallmounted[angle]
	local facedir_substitution = facedir[angle]

	worldedit.keep_loaded(pos1, pos2)

	local count = 0
	local get_node, swap_node = minetest.get_node, minetest.swap_node
	local pos = vector.new(pos1.x, 0, 0)
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				local def = registered_nodes[node.name]
				if def then
					local paramtype2 = def.paramtype2
					if paramtype2 == "wallmounted" or
							paramtype2 == "colorwallmounted" then
						local orient = node.param2 % 8
						node.param2 = node.param2 - orient +
								wallmounted_substitution[orient + 1]
						swap_node(pos, node)
						count = count + 1
					elseif paramtype2 == "facedir" or
							paramtype2 == "colorfacedir" then
						local orient = node.param2 % 32
						node.param2 = node.param2 - orient +
								facedir_substitution[orient + 1]
						swap_node(pos, node)
						count = count + 1
					end
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end
