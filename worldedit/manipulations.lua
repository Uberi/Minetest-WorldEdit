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

--- Sets param2 of a region.
-- @param pos1
-- @param pos2
-- @param param2 Value of param2 to set
-- @return The number of nodes set.
function worldedit.set_param2(pos1, pos2, param2)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local manip, area = mh.init(pos1, pos2)
	local param2_data = manip:get_param2_data()

	-- Set param2 for every node
	for i in area:iterp(pos1, pos2) do
		param2_data[i] = param2
	end

	-- Update map
	manip:set_param2_data(param2_data)
	manip:write_to_map()
	manip:update_map()

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


local function deferred_execution(next_one, finished)
	-- Allocate 100% of server step for execution (might lag a little)
	local allocated_usecs =
		tonumber(minetest.settings:get("dedicated_server_step")) * 1000000
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
	pos1 = table.copy(pos1)
	pos2 = table.copy(pos2)
	direction = table.copy(direction)

	local i = 0
	local translated = {x=0, y=0, z=0}
	local function step()
		translated.x = translated.x + direction.x
		translated.y = translated.y + direction.y
		translated.z = translated.z + direction.z
		worldedit.copy2(pos1, pos2, translated)
		i = i + 1
		return i >= amount
	end
	deferred_execution(step, finished)

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

	-- Decide if we need to copy stuff backwards (only applies to metadata)
	local backwards = amount > 0 and amount < (pos2[axis] - pos1[axis] + 1)

	local off = {x=0, y=0, z=0}
	off[axis] = amount
	return worldedit.copy2(pos1, pos2, off, backwards)
end

--- Copies a region by offset vector `off`.
-- @param pos1
-- @param pos2
-- @param off
-- @param meta_backwards (not officially part of API)
-- @return The number of nodes copied.
function worldedit.copy2(pos1, pos2, off, meta_backwards)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local src_manip, src_area = mh.init(pos1, pos2)
	local src_stride = {x=1, y=src_area.ystride, z=src_area.zstride}
	local src_offset = vector.subtract(pos1, src_area.MinEdge)

	local dpos1 = vector.add(pos1, off)
	local dpos2 = vector.add(pos2, off)
	local dim = vector.add(vector.subtract(pos2, pos1), 1)

	local dst_manip, dst_area = mh.init(dpos1, dpos2)
	local dst_stride = {x=1, y=dst_area.ystride, z=dst_area.zstride}
	local dst_offset = vector.subtract(dpos1, dst_area.MinEdge)

	local function do_copy(src_data, dst_data)
		for z = 0, dim.z-1 do
			local src_index_z = (src_offset.z + z) * src_stride.z + 1 -- +1 for 1-based indexing
			local dst_index_z = (dst_offset.z + z) * dst_stride.z + 1
			for y = 0, dim.y-1 do
				local src_index_y = src_index_z + (src_offset.y + y) * src_stride.y
				local dst_index_y = dst_index_z + (dst_offset.y + y) * dst_stride.y
				-- Copy entire row at once
				local src_index_x = src_index_y + src_offset.x
				local dst_index_x = dst_index_y + dst_offset.x
				for x = 0, dim.x-1 do
					dst_data[dst_index_x + x] = src_data[src_index_x + x]
				end
			end
		end
	end

	-- Copy node data
	local src_data = src_manip:get_data()
	local dst_data = dst_manip:get_data()
	do_copy(src_data, dst_data)
	dst_manip:set_data(dst_data)

	-- Copy param1
	src_manip:get_light_data(src_data)
	dst_manip:get_light_data(dst_data)
	do_copy(src_data, dst_data)
	dst_manip:set_light_data(dst_data)

	-- Copy param2
	src_manip:get_param2_data(src_data)
	dst_manip:get_param2_data(dst_data)
	do_copy(src_data, dst_data)
	dst_manip:set_param2_data(dst_data)

	mh.finish(dst_manip)
	src_data = nil
	dst_data = nil

	-- Copy metadata
	local get_meta = minetest.get_meta
	if meta_backwards then
	for z = dim.z-1, 0, -1 do
		for y = dim.y-1, 0, -1 do
			for x = dim.x-1, 0, -1 do
				local pos = {x=pos1.x+x, y=pos1.y+y, z=pos1.z+z}
				local meta = get_meta(pos):to_table()
				pos = vector.add(pos, off)
				get_meta(pos):from_table(meta)
			end
		end
	end
	else
	for z = 0, dim.z-1 do
		for y = 0, dim.y-1 do
			for x = 0, dim.x-1 do
				local pos = {x=pos1.x+x, y=pos1.y+y, z=pos1.z+z}
				local meta = get_meta(pos):to_table()
				pos = vector.add(pos, off)
				get_meta(pos):from_table(meta)
			end
		end
	end
	end

	return worldedit.volume(pos1, pos2)
end

--- Deletes all node metadata in the region
-- @param pos1
-- @param pos2
-- @return The number of nodes that had their meta deleted.
function worldedit.delete_meta(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local meta_positions = minetest.find_nodes_with_meta(pos1, pos2)
	local get_meta = minetest.get_meta
	for _, pos in ipairs(meta_positions) do
		get_meta(pos):from_table(nil)
	end

	return #meta_positions
end

--- Moves a region along `axis` by `amount` nodes.
-- @return The number of nodes moved.
function worldedit.move(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local dim = vector.add(vector.subtract(pos2, pos1), 1)
	local overlap = math.abs(amount) < dim[axis]
	-- Decide if we need to copy metadata backwards
	local backwards = overlap and amount > 0

	local function nuke_area(my_off, my_dim)
		if my_dim.x == 0 or my_dim.y == 0 or my_dim.z == 0 then
			return
		end
		local my_pos1 = vector.add(pos1, my_off)
		local my_pos2 = vector.subtract(vector.add(my_pos1, my_dim), 1)
		worldedit.set(my_pos1, my_pos2, "air")
		worldedit.delete_meta(my_pos1, my_pos2)
	end

	-- Copy stuff to new location
	local off = {x=0, y=0, z=0}
	off[axis] = amount
	worldedit.copy2(pos1, pos2, off, backwards)
	-- Nuke old area
	if not overlap then
		nuke_area({x=0, y=0, z=0}, dim)
	else
		-- Source and destination region are overlapping, which means we can't
		-- blindly delete the [pos1, pos2] area
		local leftover = vector.new(dim) -- size of the leftover slice
		leftover[axis] = math.abs(amount)
		if amount > 0 then
			nuke_area({x=0, y=0, z=0}, leftover)
		else
			local top = {x=0, y=0, z=0} -- offset of the leftover slice from pos1
			top[axis] = dim[axis] - math.abs(amount)
			nuke_area(top, leftover)
		end
	end

	return worldedit.volume(pos1, pos2)
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
	deferred_execution(step, finished)

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
	local pos = {x=pos1.x, y=0, z=0}
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


--- Attempts to fix the lighting in a region.
-- @return The number of nodes updated.
function worldedit.fixlight(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local vmanip = minetest.get_voxel_manip(pos1, pos2)
	vmanip:write_to_map()
	vmanip:update_map() -- this updates the lighting

	return worldedit.volume(pos1, pos2)
end


--- Clears all objects in a region.
-- @return The number of objects cleared.
function worldedit.clear_objects(pos1, pos2)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local function should_delete(obj)
		-- Avoid players and WorldEdit entities
		if obj:is_player() then
			return false
		end
		local entity = obj:get_luaentity()
		return not entity or not entity.name:find("^worldedit:")
	end

	-- Offset positions to include full nodes (positions are in the center of nodes)
	local pos1x, pos1y, pos1z = pos1.x - 0.5, pos1.y - 0.5, pos1.z - 0.5
	local pos2x, pos2y, pos2z = pos2.x + 0.5, pos2.y + 0.5, pos2.z + 0.5

	local count = 0
	if minetest.get_objects_in_area then
		local objects = minetest.get_objects_in_area({x=pos1x, y=pos1y, z=pos1z},
			{x=pos2x, y=pos2y, z=pos2z})

		for _, obj in pairs(objects) do
			if should_delete(obj) then
				obj:remove()
				count = count + 1
			end
		end
		return count
	end

	-- Fallback implementation via get_objects_inside_radius
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
	for _, obj in pairs(minetest.get_objects_inside_radius(center, radius)) do
		if should_delete(obj) then
			local pos = obj:get_pos()
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

