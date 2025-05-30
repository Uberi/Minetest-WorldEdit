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
	mh.finish(manip)

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

	local off = vector.new()
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
	local src_stride = vector.new(1, src_area.ystride, src_area.zstride)
	local src_offset = vector.subtract(pos1, src_area.MinEdge)

	local dpos1 = vector.add(pos1, off)
	local dpos2 = vector.add(pos2, off)
	local dim = vector.add(vector.subtract(pos2, pos1), 1)

	local dst_manip, dst_area = mh.init(dpos1, dpos2)
	local dst_stride = vector.new(1, dst_area.ystride, dst_area.zstride)
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

	-- Copy metadata
	local get_meta = minetest.get_meta
	if meta_backwards then
	for z = dim.z-1, 0, -1 do
		for y = dim.y-1, 0, -1 do
			for x = dim.x-1, 0, -1 do
				local pos = vector.new(pos1.x+x, pos1.y+y, pos1.z+z)
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
				local pos = vector.new(pos1.x+x, pos1.y+y, pos1.z+z)
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
	local off = vector.new()
	off[axis] = amount
	worldedit.copy2(pos1, pos2, off, backwards)
	-- Nuke old area
	if not overlap then
		nuke_area(vector.new(), dim)
	else
		-- Source and destination region are overlapping, which means we can't
		-- blindly delete the [pos1, pos2] area
		local leftover = vector.new(dim) -- size of the leftover slice
		leftover[axis] = math.abs(amount)
		if amount > 0 then
			nuke_area(vector.new(), leftover)
		else
			local top = vector.new() -- offset of the leftover slice from pos1
			top[axis] = dim[axis] - math.abs(amount)
			nuke_area(top, leftover)
		end
	end

	return worldedit.volume(pos1, pos2)
end


--- Attempts to fix the lighting in a region.
-- @return The number of nodes updated.
function worldedit.fixlight(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local vmanip = minetest.get_voxel_manip(pos1, pos2)
	vmanip:write_to_map() -- this updates the lighting
	if vmanip.close ~= nil then
		vmanip:close()
	end

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
		return not (entity and entity.name:find("^worldedit:"))
	end

	-- Offset positions to include full nodes (positions are in the center of nodes)
	pos1 = vector.add(pos1, -0.5)
	pos2 = vector.add(pos2, 0.5)

	local count = 0
	if minetest.get_objects_in_area then
		local objects = minetest.get_objects_in_area(pos1, pos2)

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
		x = pos1.x + ((pos2.x - pos1.x) / 2),
		y = pos1.y + ((pos2.y - pos1.y) / 2),
		z = pos1.z + ((pos2.z - pos1.z) / 2)
	}
	-- Bounding sphere radius
	local radius = math.sqrt(
			(center.x - pos1.x) ^ 2 +
			(center.y - pos1.y) ^ 2 +
			(center.z - pos1.z) ^ 2)
	local objects = minetest.get_objects_inside_radius(center, radius)
	for _, obj in pairs(objects) do
		if should_delete(obj) then
			local pos = obj:get_pos()
			if pos.x >= pos1.x and pos.x <= pos2.x and
					pos.y >= pos1.y and pos.y <= pos2.y and
					pos.z >= pos1.z and pos.z <= pos2.z then
				-- Inside region
				obj:remove()
				count = count + 1
			end
		end
	end
	return count
end
