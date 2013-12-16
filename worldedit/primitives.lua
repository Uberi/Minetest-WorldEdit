worldedit = worldedit or {}
local minetest = minetest --local copy of global

--adds a hollow sphere centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.hollow_sphere = function(pos, radius, nodename)
	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {x=pos.x - radius, y=pos.y - radius, z=pos.z - radius}
	local pos2 = {x=pos.x + radius, y=pos.y + radius, z=pos.z + radius}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = -radius, radius do
			local newy = newz + (y + offsety) * ystride
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared >= min_radius and squared <= max_radius then --position is on surface of sphere
					local i = newy + (x + offsetx)
					nodes[i] = node_id
					count = count + 1
				end
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a sphere centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.sphere = function(pos, radius, nodename)
	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {x=pos.x - radius, y=pos.y - radius, z=pos.z - radius}
	local pos2 = {x=pos.x + radius, y=pos.y + radius, z=pos.z + radius}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local max_radius = radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = -radius, radius do
			local newy = newz + (y + offsety) * ystride
			for x = -radius, radius do
				if x * x + y * y + z * z <= max_radius then --position is inside sphere
					local i = newy + (x + offsetx)
					nodes[i] = node_id
					count = count + 1
				end
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a hollow dome centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.hollow_dome = function(pos, radius, nodename)
	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {x=pos.x - radius, y=pos.y, z=pos.z - radius}
	local pos2 = {x=pos.x + radius, y=pos.y + radius, z=pos.z + radius}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	local miny, maxy = 0, radius
	if radius < 0 then
		radius = -radius
		miny, maxy = -radius, 0
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = miny, maxy do
			local newy = newz + (y + offsety) * ystride
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared >= min_radius and squared <= max_radius then --position is on surface of sphere
					local i = newy + (x + offsetx)
					nodes[i] = node_id
					count = count + 1
				end
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a dome centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.dome = function(pos, radius, nodename)
	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {x=pos.x - radius, y=pos.y, z=pos.z - radius}
	local pos2 = {x=pos.x + radius, y=pos.y + radius, z=pos.z + radius}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	local miny, maxy = 0, radius
	if radius < 0 then
		radius = -radius
		miny, maxy = -radius, 0
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local max_radius = radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = miny, maxy do
			local newy = newz + (y + offsety) * ystride
			for x = -radius, radius do
				if x * x + y * y + z * z <= max_radius then --position is inside sphere
					local i = newy + (x + offsetx)
					nodes[i] = node_id
					count = count + 1
				end
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a hollow cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.hollow_cylinder = function(pos, axis, length, radius, nodename)
	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	--handle negative lengths
	local currentpos = {x=pos.x, y=pos.y, z=pos.z}
	if length < 0 then
		length = -length
		currentpos[axis] = currentpos[axis] - length
	end

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {
		[axis]=currentpos[axis],
		[other1]=currentpos[other1] - radius,
		[other2]=currentpos[other2] - radius
	}
	local pos2 = {
		[axis]=currentpos[axis] + length - 1,
		[other1]=currentpos[other1] + radius,
		[other2]=currentpos[other2] + radius
	}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = {x=currentpos.x - emerged_pos1.x, y=currentpos.y - emerged_pos1.y, z=currentpos.z - emerged_pos1.z}
	local min_slice, max_slice = offset[axis], offset[axis] + length - 1
	local count = 0
	for index2 = -radius, radius do
		local newindex2 = (index2 + offset[other1]) * stride[other1] + 1 --offset contributed by other axis 1 plus 1 to make it 1-indexed
		for index3 = -radius, radius do
			local newindex3 = newindex2 + (index3 + offset[other2]) * stride[other2]
			local squared = index2 * index2 + index3 * index3
			if squared >= min_radius and squared <= max_radius then --position is on surface of cylinder
				for index1 = min_slice, max_slice do --add column along axis
					local i = newindex3 + index1 * stride[axis]
					nodes[i] = node_id
				end
				count = count + length
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.cylinder = function(pos, axis, length, radius, nodename)
	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	--handle negative lengths
	local currentpos = {x=pos.x, y=pos.y, z=pos.z}
	if length < 0 then
		length = -length
		currentpos[axis] = currentpos[axis] - length
	end

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local pos1 = {
		[axis]=currentpos[axis],
		[other1]=currentpos[other1] - radius,
		[other2]=currentpos[other2] - radius
	}
	local pos2 = {
		[axis]=currentpos[axis] + length - 1,
		[other1]=currentpos[other1] + radius,
		[other2]=currentpos[other2] + radius
	}
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local max_radius = radius * (radius + 1)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = {x=currentpos.x - emerged_pos1.x, y=currentpos.y - emerged_pos1.y, z=currentpos.z - emerged_pos1.z}
	local min_slice, max_slice = offset[axis], offset[axis] + length - 1
	local count = 0
	for index2 = -radius, radius do
		local newindex2 = (index2 + offset[other1]) * stride[other1] + 1 --offset contributed by other axis 1 plus 1 to make it 1-indexed
		for index3 = -radius, radius do
			local newindex3 = newindex2 + (index3 + offset[other2]) * stride[other2]
			if index2 * index2 + index3 * index3 <= max_radius then --position is within cylinder
				for index1 = min_slice, max_slice do --add column along axis
					local i = newindex3 + index1 * stride[axis]
					nodes[i] = node_id
				end
				count = count + length
			end
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a pyramid centered at `pos` with height `height`, composed of `nodename`, returning the number of nodes added
worldedit.pyramid = function(pos, axis, height, nodename)
	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	local pos1 = {x=pos.x - height, y=pos.y - height, z=pos.z - height}
	local pos2 = {x=pos.x + height, y=pos.y + height, z=pos.z + height}

	--handle inverted pyramids
	local startaxis, endaxis, step
	if height > 0 then
		height = height - 1
		step = 1
		pos1[axis] = pos[axis] --upper half of box
	else
		height = height + 1
		step = -1
		pos2[axis] = pos[axis] --lower half of box
	end

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offset = {x=pos.x - emerged_pos1.x, y=pos.y - emerged_pos1.y, z=pos.z - emerged_pos1.z}
	local size = height * step
	local count = 0
	for index1 = 0, height, step do --go through each level of the pyramid
		local newindex1 = (index1 + offset[axis]) * stride[axis] + 1 --offset contributed by axis plus 1 to make it 1-indexed
		for index2 = -size, size do
			local newindex2 = newindex1 + (index2 + offset[other1]) * stride[other1]
			for index3 = -size, size do
				local i = newindex2 + (index3 + offset[other2]) * stride[other2]
				nodes[i] = node_id
			end
		end
		count = count + (size * 2 + 1) ^ 2
		size = size - 1
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a spiral centered at `pos` with side length `length`, height `height`, space between walls `spacer`, composed of `nodename`, returning the number of nodes added
worldedit.spiral = function(pos, length, height, spacer, nodename)
	local extent = math.ceil(length / 2)
	local pos1 = {x=pos.x - extent, y=pos.y, z=pos.z - extent}
	local pos2 = {x=pos.x + extent, y=pos.y + height, z=pos.z + extent}

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	--fill emerged area with ignore
	local nodes = {}
	local ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(emerged_pos1, emerged_pos2) do
		nodes[i] = ignore
	end

	--set up variables
	local node_id = minetest.get_content_id(nodename)
	local stride = {x=1, y=area.ystride, z=area.zstride}
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local i = offsetz * stride.z + offsety * stride.y + offsetx + 1

	--add first column
	local count = height
	local column = i
	for y = 1, height do
		nodes[column] = node_id
		column = column + stride.y
	end

	--add spiral segments
	local strideaxis, strideother = stride.x, stride.z
	local sign = -1
	local segment_length = 0
	spacer = spacer + 1
	for segment = 1, math.floor(length / spacer) * 2 do --go through each segment except the last
		if segment % 2 == 1 then --change sign and length every other turn starting with the first
			sign = -sign
			segment_length = segment_length + spacer
		end
		for index = 1, segment_length do --fill segment
			i = i + strideaxis * sign --move along the direction of the segment
			local column = i
			for y = 1, height do --add column
				nodes[column] = node_id
				column = column + stride.y
			end
		end
		count = count + segment_length * height
		strideaxis, strideother = strideother, strideaxis --swap axes
	end

	--add shorter final segment
	sign = -sign
	for index = 1, segment_length do
		i = i + strideaxis * sign
		local column = i
		for y = 1, height do --add column
			nodes[column] = node_id
			column = column + stride.y
		end
	end
	count = count + segment_length * height

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end