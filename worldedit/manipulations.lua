--- Generic node manipulations.
-- @module worldedit.manipulations

local mh = worldedit.manip_helpers


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
			worldedit.copy2(pos1, pos2, translated, volume)
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


--- Flips a region along `axis`.
-- @return The number of nodes flipped.
function worldedit.flip(pos1, pos2, axis)
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
-- TODO: Support 6D facedir rotation along arbitrary axis.
function worldedit.orient(pos1, pos2, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local registered_nodes = minetest.registered_nodes

	local wallmounted = {
		[90]  = {[0]=0, 1, 5, 4, 2, 3},
		[180] = {[0]=0, 1, 3, 2, 5, 4},
		[270] = {[0]=0, 1, 4, 5, 3, 2}
	}
	local facedir = {
		[90]  = {[0]=1, 2, 3, 0},
		[180] = {[0]=2, 3, 0, 1},
		[270] = {[0]=3, 0, 1, 2}
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
						node.param2 = facedir_substitution[node.param2]
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

