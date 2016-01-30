--- Generic node manipulations.
-- @module worldedit.manipulations

-- List of diagonal symetric nodes. Node name as key
worldedit.diagonal_nodes = {}

local mh = worldedit.manip_helpers

local facedir_substitutions = {
	['flip'] = {
		['x'] = {[0]=0, 3, 2, 1, 4, 7, 6, 5, 8, 11, 10, 9, 16, 19, 18, 17, 12, 15, 14, 13, 20, 23, 22, 21},
		['y'] = {[0]=20, 23, 22, 21, 6, 5, 4, 7, 10, 9, 8, 11, 12, 15, 14, 13, 16, 19, 18, 17, 0, 3, 2, 1},
		['z'] = {[0]=2, 1, 0, 3, 10, 9, 8, 11, 6, 5, 4, 7, 14, 13, 12, 15, 18, 17, 16, 19, 22, 21, 20, 23},
		['diag'] = {
			['x'] = {[0]=1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 17, 16, 19, 18, 13, 12, 15, 14, 21, 20, 23, 22},
			['y'] = {[0]=21, 20, 23, 22, 7, 6, 5, 4, 11, 10, 9, 8, 13, 12, 15, 14, 17, 16, 19, 18, 1, 0, 3, 2},
			['z'] = {[0]=3, 2, 1, 0, 11, 10, 9, 8, 7, 6, 5, 4, 15, 14, 13, 12, 19, 18, 17, 16, 23, 22, 21, 20},
		}
	},
	['rotate'] = {
		['x'] = {
			[90] = {[0]=8, 9, 10, 11, 0, 1, 2, 3, 22, 23, 20, 21, 15, 12, 13, 14, 17, 18, 19, 16, 6, 7, 4, 5},
			[180] = {[0]=22, 23, 20, 21, 8, 9, 10, 11, 4, 5, 6, 7, 14, 15, 12, 13, 18, 19, 16, 17, 2, 3, 0, 1},
			[270] = {[0]=4, 5, 6, 7, 22, 23, 20, 21, 0, 1, 2, 3, 13, 14, 15, 12, 19, 16, 17, 18, 10, 11, 8, 9}
		},
		['y'] = {
			[90] = {[0]=1, 2, 3, 0, 13, 14, 15, 12, 17, 18, 19, 16, 9, 10, 11, 8, 5, 6, 7, 4, 23, 20, 21, 22},
			[180] = {[0]=2, 3, 0, 1, 10, 11, 8, 9, 6, 7, 4, 5, 18, 19, 16, 17, 14, 15, 12, 13, 22, 23, 20, 21},
			[270] = {[0]=3, 0, 1, 2, 19, 16, 17, 18, 15, 12, 13, 14, 7, 4, 5, 6, 11, 8, 9, 10, 21, 22, 23, 20}
		},
		['z'] = {
			[90] = {[0]=12, 13, 14, 15, 7, 4, 5, 6, 9, 10, 11, 8, 20, 21, 22, 23, 0, 1, 2, 3, 16, 17, 18, 19},
			[180] = {[0]=20, 21, 22, 23, 6, 7, 4, 5, 10, 11, 8, 9, 16, 17, 18, 19, 12, 13, 14, 15, 0, 1, 2, 3},
			[270] = {[0]=16, 17, 18, 19, 5, 6, 7, 4, 11, 8, 9, 10, 0, 1, 2, 3, 20, 21, 22, 23, 12, 13, 14, 15}
		}
	}
}

local wallmounted_substitutions = {
	['flip'] = {
		['x'] = {[0]=1, 0, 3, 2, 4, 5},
		['y'] = {[0]=0, 1, 2, 3, 4, 5},
		['z'] = {[0]=0, 1, 2, 3, 5, 4}
	},
	['rotate'] = {
		['x'] = {
			[90] = {[0]=5, 4, 2, 3, 0, 1},
			[180] = {[0]=1, 0, 2, 3, 5, 4},
			[270] = {[0]=4, 5, 2, 3, 1, 0}
		},
		['y'] = {
			[90] = {[0]=0, 1, 5, 4, 2, 3},
			[180] = {[0]=0, 1, 3, 2, 5, 4},
			[270] = {[0]=0, 1, 4, 5, 3, 2}
		},
		['z'] = {
			[90] = {[0]=2, 3, 1, 0, 4, 5},
			[180] = {[0]=1, 0, 3, 2, 4, 5},
			[270] = {[0]=3, 2, 0, 1, 4, 5}
		}
	}
}

--- Sets a region to `node_names`.
-- @param pos1
-- @param pos2
-- @param node_names Node name or list of node names.
-- @return The number of nodes set.
function worldedit.set(pos1, pos2, node_names)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local manip, area = mh.init(pos1, pos2)
	local data = mh.get_empty_data(area)

	if type(node_names) == "string" then -- Only one type of node
		local id = minetest.get_content_id(node_names)
		-- Fill area with node
		for i in area:iterp(pos1, pos2) do
			data[i] = id
		end
	else -- Several types of nodes specified
		local node_ids = {}
		for i, v in ipairs(node_names) do
			node_ids[i] = minetest.get_content_id(v)
		end
		-- Fill area randomly with nodes
		local id_count, rand = #node_ids, math.random
		for i in area:iterp(pos1, pos2) do
			data[i] = node_ids[rand(id_count)]
		end
	end

	mh.finish(manip, data)

	return worldedit.volume(pos1, pos2)
end


--- Replaces all instances of `search_node` with `replace_node` in a region.
-- When `inverse` is `true`, replaces all instances that are NOT `search_node`.
-- @return The number of nodes replaced.
function worldedit.replace(pos1, pos2, search_node, replace_node, inverse)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local manip, area = mh.init(pos1, pos2)
	local data = manip:get_data()

	local search_id = minetest.get_content_id(search_node)
	local replace_id = minetest.get_content_id(replace_node)

	local count = 0

	--- TODO: This could be shortened by checking `inverse` in the loop,
	-- but that would have a speed penalty.  Is the penalty big enough
	-- to matter?
	if not inverse then
		for i in area:iterp(pos1, pos2) do
			if data[i] == search_id then
				data[i] = replace_id
				count = count + 1
			end
		end
	else
		for i in area:iterp(pos1, pos2) do
			if data[i] ~= search_id then
				data[i] = replace_id
				count = count + 1
			end
		end
	end

	mh.finish(manip, data)

	return count
end


--- Duplicates a region `amount` times with offset vector `direction`.
-- Stacking is spread across server steps, one copy per step.
-- @return The number of nodes stacked.
function worldedit.stack2(pos1, pos2, direction, amount, finished)
	local i = 0
	local translated = {x=0, y=0, z=0}
	local function next_one()
		if i < amount then
			i = i + 1
			translated.x = translated.x + direction.x
			translated.y = translated.y + direction.y
			translated.z = translated.z + direction.z
			worldedit.copy2(pos1, pos2, translated)
			minetest.after(0, next_one)
		else
			if finished then
				finished()
			end
		end
	end
	next_one()
	return worldedit.volume(pos1, pos2) * amount
end


--- Copies a region along `axis` by `amount` nodes.
-- @param pos1
-- @param pos2
-- @param axis Axis ("x", "y", or "z")
-- @param amount
-- @return The number of nodes copied.
function worldedit.copy(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local get_node, get_meta, set_node = minetest.get_node,
			minetest.get_meta, minetest.set_node
	-- Copy things backwards when negative to avoid corruption.
	-- FIXME: Lots of code duplication here.
	if amount < 0 then
		local pos = {}
		pos.x = pos1.x
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = get_node(pos) -- Obtain current node
					local meta = get_meta(pos):to_table() -- Get meta of current node
					local value = pos[axis] -- Store current position
					pos[axis] = value + amount -- Move along axis
					set_node(pos, node) -- Copy node to new position
					get_meta(pos):from_table(meta) -- Set metadata of new node
					pos[axis] = value -- Restore old position
					pos.z = pos.z + 1
				end
				pos.y = pos.y + 1
			end
			pos.x = pos.x + 1
		end
	else
		local pos = {}
		pos.x = pos2.x
		while pos.x >= pos1.x do
			pos.y = pos2.y
			while pos.y >= pos1.y do
				pos.z = pos2.z
				while pos.z >= pos1.z do
					local node = get_node(pos) -- Obtain current node
					local meta = get_meta(pos):to_table() -- Get meta of current node
					local value = pos[axis] -- Store current position
					pos[axis] = value + amount -- Move along axis
					set_node(pos, node) -- Copy node to new position
					get_meta(pos):from_table(meta) -- Set metadata of new node
					pos[axis] = value -- Restore old position
					pos.z = pos.z - 1
				end
				pos.y = pos.y - 1
			end
			pos.x = pos.x - 1
		end
	end
	return worldedit.volume(pos1, pos2)
end

--- Copies a region by offset vector `off`.
-- @param pos1
-- @param pos2
-- @param off
-- @return The number of nodes copied.
function worldedit.copy2(pos1, pos2, off)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local get_node, get_meta, set_node = minetest.get_node,
			minetest.get_meta, minetest.set_node
	local pos = {}
	pos.x = pos2.x
	while pos.x >= pos1.x do
		pos.y = pos2.y
		while pos.y >= pos1.y do
			pos.z = pos2.z
			while pos.z >= pos1.z do
				local node = get_node(pos) -- Obtain current node
				local meta = get_meta(pos):to_table() -- Get meta of current node
				local newpos = vector.add(pos, off) -- Calculate new position
				set_node(newpos, node) -- Copy node to new position
				get_meta(newpos):from_table(meta) -- Set metadata of new node
				pos.z = pos.z - 1
			end
			pos.y = pos.y - 1
		end
		pos.x = pos.x - 1
	end
	return worldedit.volume(pos1, pos2)
end

--- Moves a region along `axis` by `amount` nodes.
-- @return The number of nodes moved.
function worldedit.move(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	--- TODO: Move slice by slice using schematic method in the move axis
	-- and transfer metadata in separate loop (and if the amount is
	-- greater than the length in the axis, copy whole thing at a time and
	-- erase original after, using schematic method).
	local get_node, get_meta, set_node, remove_node = minetest.get_node,
			minetest.get_meta, minetest.set_node, minetest.remove_node
	-- Copy things backwards when negative to avoid corruption.
	--- FIXME: Lots of code duplication here.
	if amount < 0 then
		local pos = {}
		pos.x = pos1.x
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = get_node(pos) -- Obtain current node
					local meta = get_meta(pos):to_table() -- Get metadata of current node
					remove_node(pos) -- Remove current node
					local value = pos[axis] -- Store current position
					pos[axis] = value + amount -- Move along axis
					set_node(pos, node) -- Move node to new position
					get_meta(pos):from_table(meta) -- Set metadata of new node
					pos[axis] = value -- Restore old position
					pos.z = pos.z + 1
				end
				pos.y = pos.y + 1
			end
			pos.x = pos.x + 1
		end
	else
		local pos = {}
		pos.x = pos2.x
		while pos.x >= pos1.x do
			pos.y = pos2.y
			while pos.y >= pos1.y do
				pos.z = pos2.z
				while pos.z >= pos1.z do
					local node = get_node(pos) -- Obtain current node
					local meta = get_meta(pos):to_table() -- Get metadata of current node
					remove_node(pos) -- Remove current node
					local value = pos[axis] -- Store current position
					pos[axis] = value + amount -- Move along axis
					set_node(pos, node) -- Move node to new position
					get_meta(pos):from_table(meta) -- Set metadata of new node
					pos[axis] = value -- Restore old position
					pos.z = pos.z - 1
				end
				pos.y = pos.y - 1
			end
			pos.x = pos.x - 1
		end
	end
	return worldedit.volume(pos1, pos2)
end


--- Duplicates a region along `axis` `amount` times.
-- Stacking is spread across server steps, one copy per step.
-- @param pos1
-- @param pos2
-- @param axis Axis direction, "x", "y", or "z".
-- @param count
-- @return The number of nodes stacked.
function worldedit.stack(pos1, pos2, axis, count)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local length = pos2[axis] - pos1[axis] + 1
	if count < 0 then
		count = -count
		length = -length
	end
	local amount = 0
	local copy = worldedit.copy
	local i = 1
	function next_one()
		if i <= count then
			i = i + 1
			amount = amount + length
			copy(pos1, pos2, axis, amount)
			minetest.after(0, next_one)
		end
	end
	next_one()
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
	local schematic = {size={x=stretch_x, y=stretch_y, z=stretch_z}, data=nodes}

	local size_x, size_y, size_z = stretch_x - 1, stretch_y - 1, stretch_z - 1

	local new_pos2 = {
		x = pos1.x + (pos2.x - pos1.x) * stretch_x + size_x,
		y = pos1.y + (pos2.y - pos1.y) * stretch_y + size_y,
		z = pos1.z + (pos2.z - pos1.z) * stretch_z + size_z,
	}
	worldedit.keep_loaded(pos1, new_pos2)

	local pos = {x=pos2.x, y=0, z=0}
	local big_pos = {x=0, y=0, z=0}
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
	local new_pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	new_pos2[axis1] = pos1[axis1] + extent2
	new_pos2[axis2] = pos1[axis2] + extent1

	local upper_bound = {x=pos2.x, y=pos2.y, z=pos2.z}
	if upper_bound[axis1] < new_pos2[axis1] then upper_bound[axis1] = new_pos2[axis1] end
	if upper_bound[axis2] < new_pos2[axis2] then upper_bound[axis2] = new_pos2[axis2] end
	worldedit.keep_loaded(pos1, upper_bound)

	local pos = {x=pos1.x, y=0, z=0}
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


--- Flips a region along `axis`. Flips only nodes, no change on nodes orientations
-- @return The number of nodes flipped.
function worldedit.flip_nodes(pos1, pos2, axis)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	--- TODO: Flip the region slice by slice along the flip axis using schematic method.
	local pos = {x=pos1.x, y=0, z=0}
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

--- Change orientation of all oriented nodes in a region.
-- @param pos1
-- @param pos2
-- @param operation Kind of operation: flip or rotate.
-- @param axis Orientation axis: x, y or z
-- @param angle Angle in degrees (90 degree increments only).
-- @return The number of nodes oriented.
--- TODO: When flipping, try to manage diametral symetric nodes (should be rotated instead of flipped)
function worldedit.orient(pos1, pos2, operation, axis, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local registered_nodes = minetest.registered_nodes

	if axis ~= 'x' and axis ~= 'y' and axis ~= 'z' then
		error("Axis should be 'x', 'y' or 'z'!")
	end

	local facedir_substitution
	local wallmounted_substitution

	if operation == "rotate" then	
		angle = angle % 360
		if angle == 0 then
			return
		else
			if angle % 90 ~= 0 then
				error("Only 90 degree increments are supported!")
			end
			facedir_substitution = facedir_substitutions[operation][axis][angle]
			wallmounted_substitution = wallmounted_substitutions[operation][axis][angle]
		end
  	elseif operation == "flip" then
		facedir_substitution = facedir_substitutions[operation][axis]
		wallmounted_substitution = wallmounted_substitutions[operation][axis]
	else
		error("Operation should be 'rotate' or 'flip'!")
	end

	worldedit.keep_loaded(pos1, pos2)

	local count = 0
	local set_node, get_node, get_meta, swap_node = minetest.set_node,
			minetest.get_node, minetest.get_meta, minetest.swap_node
	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				local def = registered_nodes[node.name]
				if def then
					if def.paramtype2 == "wallmounted" then
						node.param2 = wallmounted_substitution[node.param2]
						local meta = get_meta(pos):to_table()
						set_node(pos, node)
						get_meta(pos):from_table(meta)
						count = count + 1
					elseif def.paramtype2 == "facedir" then
						if operation == 'flip' and worldedit.diagonal_nodes[node.name] then
							node.param2 = facedir_substitutions[operation]['diag'][axis][node.param2]
						else
							node.param2 = facedir_substitution[node.param2]
						end
						local meta = get_meta(pos):to_table()
						set_node(pos, node)
						get_meta(pos):from_table(meta)
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

--- Rotates a region clockwise around an axis. Oriented nodes are rotated accordingly.
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
		worldedit.flip_nodes(pos1, pos2, other1)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, other1, other2)
	elseif angle == 180 then
		worldedit.flip_nodes(pos1, pos2, other1)
		count = worldedit.flip_nodes(pos1, pos2, other2)
	elseif angle == 270 then
		worldedit.flip_nodes(pos1, pos2, other2)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, other1, other2)
	else
		error("Only 90 degree increments are supported!")
	end
	worldedit.orient(pos1, pos2, "rotate", axis, angle)
	return count, pos1, pos2
end

--- Flips a region along `axis`. Oriented nodes are flipped accordingly.
-- @param pos1
-- @param pos2
-- @param axis Axis ("x", "y", or "z").
-- @return The number of nodes flipped.
function worldedit.flip(pos1, pos2, axis)
	local count
	count = worldedit.flip_nodes(pos1, pos2, axis)
	worldedit.orient(pos1, pos2, "flip", axis, 0)
	return count
end

--- Attempts to fix the lighting in a region.
-- @return The number of nodes updated.
function worldedit.fixlight(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local nodes = minetest.find_nodes_in_area(pos1, pos2, "air")
	local dig_node = minetest.dig_node
	for _, pos in ipairs(nodes) do
		dig_node(pos)
	end
	return #nodes
end


--- Clears all objects in a region.
-- @return The number of objects cleared.
function worldedit.clear_objects(pos1, pos2)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	-- Offset positions to include full nodes (positions are in the center of nodes)
	local pos1x, pos1y, pos1z = pos1.x - 0.5, pos1.y - 0.5, pos1.z - 0.5
	local pos2x, pos2y, pos2z = pos2.x + 0.5, pos2.y + 0.5, pos2.z + 0.5

	-- Center of region
	local center = {
		x = pos1x + ((pos2x - pos1x) / 2),
		y = pos1y + ((pos2y - pos1y) / 2),
		z = pos1z + ((pos2z - pos1z) / 2)
	}
	-- Bounding sphere radius
	local radius = math.sqrt(
			(center.x - pos1x) ^ 2 +
			(center.y - pos1y) ^ 2 +
			(center.z - pos1z) ^ 2)
	local count = 0
	for _, obj in pairs(minetest.get_objects_inside_radius(center, radius)) do
		local entity = obj:get_luaentity()
		-- Avoid players and WorldEdit entities
		if not obj:is_player() and (not entity or
				not entity.name:find("^worldedit:")) then
			local pos = obj:getpos()
			if pos.x >= pos1x and pos.x <= pos2x and
					pos.y >= pos1y and pos.y <= pos2y and
					pos.z >= pos1z and pos.z <= pos2z then
				-- Inside region
				obj:remove()
				count = count + 1
			end
		end
	end
	return count
end

function worldedit.load_diag_nodes_inventory ()

	-- Moreblocks / Circular saw nodes
	local circular_saw_diag_names = {
		'micro_%s_1', 'micro_%s_2', 'micro_%s_4', 'micro_%s', 'micro_%s_12', 'micro_%s_14', 'micro_%s_15',
		'stair_%s_outer', 'stair_%s_inner',
		'slope_%s_outer', 'slope_%s_outer_half', 'slope_%s_outer_half_raised',
		'slope_%s_inner', 'slope_%s_inner_half', 'slope_%s_inner_half_raised',
		'slope_%s_inner_cut', 'slope_%s_inner_cut_half', 'slope_%s_inner_cut_half_raised',
		'slope_%s_outer_cut', 'slope_%s_outer_cut_half', 'slope_%s_outer_cut_half_raised',
		'slope_%s_cut'}

	if circular_saw then
		for _, name_parts  in ipairs(circular_saw.known_nodes) do
			for _, name_format in ipairs(circular_saw_diag_names) do
				local modname  = name_parts[1] or ""
				local material = name_parts[2] or ""
				local name = modname..":"..string.format(name_format, material)
				worldedit.diagonal_nodes[name] = name
			end
		end
	end

	-- Homedecor roof blocks
	if minetest.get_modpath("homedecor") then
		local homedecor_nodes = {
			"shingle_outer_corner_wood", "shingle_outer_corner_asphalt",
			"shingle_outer_corner_terracotta", "shingle_inner_corner_wood",
			"shingle_inner_corner_asphalt", "shingle_inner_corner_terracotta"
			}
		for _, name in ipairs(homedecor_nodes) do
			worldedit.diagonal_nodes["homedecor:"..name] = "homedecor"..name
		end
	end

	-- Trunks roof blocks
	if minetest.get_modpath("trunks") then
		worldedit.diagonal_nodes["trunks:twigs_roof_corner"] = "trunks:twigs_roof_corner"
		worldedit.diagonal_nodes["trunks:twigs_roof_corner_2"] = "trunks:twigs_roof_corner_2"
	end

	-- Dryplants roof blocks
	if minetest.get_modpath("dryplants") then
		worldedit.diagonal_nodes["dryplants:reed_roof_corner"] = "dryplants:reed_roof_corner"
		worldedit.diagonal_nodes["dryplants:reed_roof_corner_2"] = "dryplants:reed_roof_corner_2"
		worldedit.diagonal_nodes["dryplants:wetreed_roof_corner"] = "dryplants:wetreed_roof_corner"
		worldedit.diagonal_nodes["dryplants:wetreed_roof_corner_2"] = "dryplants:wetreed_roof_corner_2"
	end

	-- Technics CNC nodes
	if minetest.get_modpath("technic") then
		local cnc_materials = {
			"default:dirt", "default:wood", "default:stone", "default:cobble", 
			"default:brick", "default:sandstone", "default:leaves", "default:tree",
			"default:steelblock", "default:bronzeblock", 
			"technic:stainless_steel_block", "technic:marble", "technic:granite"}

		local cnc_suffixes = {
			"_technic_cnc_slope_inner_edge", "_technic_cnc_slope_inner_edge_upsdown",
			"_technic_cnc_slope_edge_upsdown", "_technic_cnc_twocurvededge",
			"_technic_cnc_element_edge_double", "_technic_cnc_element_edge"}
		
		for _, material in ipairs(cnc_materials) do
			for _, suffix in ipairs(cnc_suffixes) do
				worldedit.diagonal_nodes[material..suffix] = material..suffix
			end
		end
	end
end
