--- Functions for creating primitive shapes.
-- @module worldedit.primitives

local mh = worldedit.manip_helpers


--- Adds a cube
-- @param pos Position of ground level center of cube
-- @param width Cube width. (x)
-- @param height Cube height. (y)
-- @param length Cube length. (z)
-- @param node_name Name of node to make cube of.
-- @param hollow Whether the cube should be hollow.
-- @return The number of nodes added.
function worldedit.cube(pos, width, height, length, node_name, hollow)
	-- Set up voxel manipulator
	local basepos = vector.subtract(pos, {x=math.floor(width/2), y=0, z=math.floor(length/2)})
	local manip, area = mh.init(basepos, vector.add(basepos, {x=width, y=height, z=length}))
	local data = mh.get_empty_data(area)

	-- Add cube
	local node_id = minetest.get_content_id(node_name)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = vector.subtract(basepos, area.MinEdge)
	local count = 0

	for z = 0, length-1 do
		local index_z = (offset.z + z) * stride.z + 1 -- +1 for 1-based indexing
		for y = 0, height-1 do
			local index_y = index_z + (offset.y + y) * stride.y
			for x = 0, width-1 do
				local is_wall = z == 0 or z == length-1
					or y == 0 or y == height-1
					or x == 0 or x == width-1
				if not hollow or is_wall then
					local i = index_y + (offset.x + x)
					data[i] = node_id
					count = count + 1
				end
			end
		end
	end

	mh.finish(manip, data)
	return count
end

--- Adds a sphere of `node_name` centered at `pos`.
-- @param pos Position to center sphere at.
-- @param radius Sphere radius.
-- @param node_name Name of node to make shere of.
-- @param hollow Whether the sphere should be hollow.
-- @return The number of nodes added.
function worldedit.sphere(pos, radius, node_name, hollow)
	local manip, area = mh.init_radius(pos, radius)

	local data = mh.get_empty_data(area)

	-- Fill selected area with node
	local node_id = minetest.get_content_id(node_name)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local stride_z, stride_y = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		-- Offset contributed by z plus 1 to make it 1-indexed
		local new_z = (z + offset_z) * stride_z + 1
		for y = -radius, radius do
			local new_y = new_z + (y + offset_y) * stride_y
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared <= max_radius and (not hollow or squared >= min_radius) then
					-- Position is on surface of sphere
					local i = new_y + (x + offset_x)
					data[i] = node_id
					count = count + 1
				end
			end
		end
	end

	mh.finish(manip, data)

	return count
end


--- Adds a dome.
-- @param pos Position to center dome at.
-- @param radius Dome radius.  Negative for concave domes.
-- @param node_name Name of node to make dome of.
-- @param hollow Whether the dome should be hollow.
-- @return The number of nodes added.
-- TODO: Add axis option.
function worldedit.dome(pos, radius, node_name, hollow)
	local min_y, max_y = 0, radius
	if radius < 0 then
		radius = -radius
		min_y, max_y = -radius, 0
	end

	local manip, area = mh.init_axis_radius(pos, "y", radius)
	local data = mh.get_empty_data(area)

	-- Add dome
	local node_id = minetest.get_content_id(node_name)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local stride_z, stride_y = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local new_z = (z + offset_z) * stride_z + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = min_y, max_y do
			local new_y = new_z + (y + offset_y) * stride_y
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared <= max_radius and (not hollow or squared >= min_radius) then
					-- Position is in dome
					local i = new_y + (x + offset_x)
					data[i] = node_id
					count = count + 1
				end
			end
		end
	end

	mh.finish(manip, data)

	return count
end

--- Adds a cylinder.
-- @param pos Position to center base of cylinder at.
-- @param axis Axis ("x", "y", or "z")
-- @param length Cylinder length.
-- @param radius1 Cylinder base radius.
-- @param radius2 Cylinder top radius.
-- @param node_name Name of node to make cylinder of.
-- @param hollow Whether the cylinder should be hollow.
-- @return The number of nodes added.
function worldedit.cylinder(pos, axis, length, radius1, radius2, node_name, hollow)
	local other1, other2 = worldedit.get_axis_others(axis)

	-- Backwards compatibility
	if type(radius2) == "string" then
		hollow = node_name
		node_name = radius2
		radius2 = radius1 -- straight cylinder
	end

	-- Handle negative lengths
	local current_pos = {x=pos.x, y=pos.y, z=pos.z}
	if length < 0 then
		length = -length
		current_pos[axis] = current_pos[axis] - length
		radius1, radius2 = radius2, radius1
	end

	-- Set up voxel manipulator
	local manip, area = mh.init_axis_radius_length(current_pos, axis, math.max(radius1, radius2), length)
	local data = mh.get_empty_data(area)

	-- Add desired shape (anything inbetween cylinder & cone)
	local node_id = minetest.get_content_id(node_name)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = {
		x = current_pos.x - area.MinEdge.x,
		y = current_pos.y - area.MinEdge.y,
		z = current_pos.z - area.MinEdge.z,
	}
	local count = 0
	for i = 0, length - 1 do
		-- Calulate radius for this "height" in the cylinder
		local radius = radius1 + (radius2 - radius1) * (i + 1) / length
		radius = math.floor(radius + 0.5) -- round
		local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)

		for index2 = -radius, radius do
			-- Offset contributed by other axis 1 plus 1 to make it 1-indexed
			local new_index2 = (index2 + offset[other1]) * stride[other1] + 1
			for index3 = -radius, radius do
				local new_index3 = new_index2 + (index3 + offset[other2]) * stride[other2]
				local squared = index2 * index2 + index3 * index3
				if squared <= max_radius and (not hollow or squared >= min_radius) then
					-- Position is in cylinder, add node here
					local vi = new_index3 + (offset[axis] + i) * stride[axis]
					data[vi] = node_id
					count = count + 1
				end
			end
		end
	end

	mh.finish(manip, data)

	return count
end


--- Adds a pyramid.
-- @param pos Position to center base of pyramid at.
-- @param axis Axis ("x", "y", or "z")
-- @param height Pyramid height.
-- @param node_name Name of node to make pyramid of.
-- @param hollow Whether the pyramid should be hollow.
-- @return The number of nodes added.
function worldedit.pyramid(pos, axis, height, node_name, hollow)
	local other1, other2 = worldedit.get_axis_others(axis)

	-- Set up voxel manipulator
	-- FIXME: passing negative <radius> causes mis-sorted pos to be passed
	-- into mh.init() which is technically not allowed but works
	local manip, area = mh.init_axis_radius(pos, axis, height)
	local data = mh.get_empty_data(area)

	-- Handle inverted pyramids
	local step
	if height > 0 then
		height = height - 1
		step = 1
	else
		height = height + 1
		step = -1
	end

	-- Add pyramid
	local node_id = minetest.get_content_id(node_name)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = {
		x = pos.x - area.MinEdge.x,
		y = pos.y - area.MinEdge.y,
		z = pos.z - area.MinEdge.z,
	}
	local size = math.abs(height * step)
	local count = 0
	-- For each level of the pyramid
	for index1 = 0, height, step do
		-- Offset contributed by axis plus 1 to make it 1-indexed
		local new_index1 = (index1 + offset[axis]) * stride[axis] + 1
		for index2 = -size, size do
			local new_index2 = new_index1 + (index2 + offset[other1]) * stride[other1]
			for index3 = -size, size do
				local i = new_index2 + (index3 + offset[other2]) * stride[other2]
				if (not hollow or size - math.abs(index2) < 2 or size - math.abs(index3) < 2) then
				       data[i] = node_id
				       count = count + 1
				end
			end
		end
		size = size - 1
	end

	mh.finish(manip, data)

	return count
end

--- Adds a spiral.
-- @param pos Position to center spiral at.
-- @param length Spral length.
-- @param height Spiral height.
-- @param spacer Space between walls.
-- @param node_name Name of node to make spiral of.
-- @return Number of nodes added.
-- TODO: Add axis option.
function worldedit.spiral(pos, length, height, spacer, node_name)
	local extent = math.ceil(length / 2)

	local manip, area = mh.init_axis_radius_length(pos, "y", extent, height)
	local data = mh.get_empty_data(area)

	-- Set up variables
	local node_id = minetest.get_content_id(node_name)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local i = offset_z * stride.z + offset_y * stride.y + offset_x + 1

	-- Add first column
	local count = height
	local column = i
	for y = 1, height do
		data[column] = node_id
		column = column + stride.y
	end

	-- Add spiral segments
	local stride_axis, stride_other = stride.x, stride.z
	local sign = -1
	local segment_length = 0
	spacer = spacer + 1
	-- Go through each segment except the last
	for segment = 1, math.floor(length / spacer) * 2 do
		-- Change sign and length every other turn starting with the first
		if segment % 2 == 1 then
			sign = -sign
			segment_length = segment_length + spacer
		end
		-- Fill segment
		for index = 1, segment_length do
			-- Move along the direction of the segment
			i = i + stride_axis * sign
			local column = i
			-- Add column
			for y = 1, height do
				data[column] = node_id
				column = column + stride.y
			end
		end
		count = count + segment_length * height
		stride_axis, stride_other = stride_other, stride_axis -- Swap axes
	end

	-- Add shorter final segment
	sign = -sign
	for index = 1, segment_length do
		i = i + stride_axis * sign
		local column = i
		-- Add column
		for y = 1, height do
			data[column] = node_id
			column = column + stride.y
		end
	end
	count = count + segment_length * height

	mh.finish(manip, data)

	return count
end
