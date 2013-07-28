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

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = 0, radius do
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
worldedit.dome = function(pos, radius, nodename) --wip: use bresenham sphere for maximum speed
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

	--fill selected area with node
	local node_id = minetest.get_content_id(nodename)
	local max_radius = radius * (radius + 1)
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		local newz = (z + offsetz) * zstride + 1 --offset contributed by z plus 1 to make it 1-indexed
		for y = 0, radius do
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
worldedit.hollow_cylinder = function(pos, axis, length, radius, nodename) --wip: rewrite this using voxelmanip
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

	--create schematic for single node column along the axis
	local node = {name=nodename, param1=0, param2=0}
	local nodes = {}
	for i = 1, length do
		nodes[i] = node
	end
	local schematic = {size={[axis]=length, [other1]=1, [other2]=1}, data=nodes}

	--add columns in a circle around axis to form cylinder
	local place_schematic = minetest.place_schematic
	local count = 0
	local offset1, offset2 = 0, radius
	local delta = -radius
	while offset1 <= offset2 do
		--add node at each octant
		local first1, first2 = pos[other1] + offset1, pos[other1] - offset1
		local second1, second2 = pos[other2] + offset2, pos[other2] - offset2
		currentpos[other1], currentpos[other2] = first1, second1
		place_schematic(currentpos, schematic) --octant 1
		currentpos[other1] = first2
		place_schematic(currentpos, schematic) --octant 4
		currentpos[other2] = second2
		place_schematic(currentpos, schematic) --octant 5
		currentpos[other1] = first1
		place_schematic(currentpos, schematic) --octant 8
		local first1, first2 = pos[other1] + offset2, pos[other1] - offset2
		local second1, second2 = pos[other2] + offset1, pos[other2] - offset1
		currentpos[other1], currentpos[other2] = first1, second1
		place_schematic(currentpos, schematic) --octant 2
		currentpos[other1] = first2
		place_schematic(currentpos, schematic) --octant 3
		currentpos[other2] = second2
		place_schematic(currentpos, schematic) --octant 6
		currentpos[other1] = first1
		place_schematic(currentpos, schematic) --octant 7

		count = count + 8 --wip: broken because sometimes currentpos is repeated

		--move to next location
		delta = delta + (offset1 * 2) + 1
		if delta >= 0 then
			offset2 = offset2 - 1
			delta = delta - (offset2 * 2)
		end
		offset1 = offset1 + 1
	end
	count = count * length --apply the length to the number of nodes
	return count
end

--adds a cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.cylinder = function(pos, axis, length, radius, nodename, env)
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
	for axis1 = -radius, radius do
		local newaxis1 = (axis1 + offset[other1]) * stride[other1] + 1 --offset contributed by other axis 1 plus 1 to make it 1-indexed
		for axis2 = -radius, radius do
			local newaxis2 = newaxis1 + (axis2 + offset[other2]) * stride[other2]
			if axis1 * axis1 + axis2 * axis2 <= max_radius then
				for slice = min_slice, max_slice do
					local i = newaxis2 + slice * stride[axis] + 1
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
worldedit.pyramid = function(pos, height, nodename, env)
	local pos1 = {x=pos.x - height, y=pos.y, z=pos.z - height}
	local pos2 = {x=pos.x + height, y=pos.y + height, z=pos.z + height}

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
	height = height - 1
	local offsetx, offsety, offsetz = pos.x - emerged_pos1.x, pos.y - emerged_pos1.y, pos.z - emerged_pos1.z
	local zstride, ystride = area.zstride, area.ystride
	local count = 0
	for y = 0, height do --go through each level of the pyramid
		local newy = (y + offsety) * ystride + 1 --offset contributed by y plus 1 to make it 1-indexed
		for z = -height, height do
			local newz = newy + (z + offsetz) * zstride
			for x = -height, height do
				local i = newz + (x + offsetx)
				nodes[i] = node_id
			end
		end
		height = height - 1
		count = count + ((height - y) * 2 + 1) ^ 2
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--adds a spiral centered at `pos` with width `width`, height `height`, space between walls `spacer`, composed of `nodename`, returning the number of nodes added
worldedit.spiral = function(pos, width, height, spacer, nodename, env) --wip: clean this up
	-- spiral matrix - http://rosettacode.org/wiki/Spiral_matrix#Lua
	--wip: rewrite this whole thing, nobody can understand it anyways
	av, sn = math.abs, function(s) return s~=0 and s/av(s) or 0 end
	local function sindex(z, x) -- returns the value at (x, z) in a spiral that starts at 1 and goes outwards
		if z == -x and z >= x then return (2*z+1)^2 end
		local l = math.max(av(z), av(x))
		return (2*l-1)^2+4*l+2*l*sn(x+z)+sn(z^2-x^2)*(l-(av(z)==l and sn(z)*x or sn(x)*z)) -- OH GOD WHAT
	end
	local function spiralt(side)
		local ret, id, start, stop = {}, 0, math.floor((-side+1)/2), math.floor((side-1)/2)
		for i = 1, side do
			for j = 1, side do
				local id = side^2 - sindex(stop - i + 1,start + j - 1)
				ret[id] = {x=i,z=j}
			end
		end
		return ret
	end
	if env == nil then env = minetest.env end
	-- connect the joined parts
	local spiral = spiralt(width)
	height = tonumber(height)
	if height < 1 then height = 1 end
	spacer = tonumber(spacer)-1
	if spacer < 1 then spacer = 1 end
	local count = 0
	local node = {name=nodename}
	local np,lp
	for y=0,height do
		lp = nil
		for _,v in ipairs(spiral) do
			np = {x=pos.x+v.x*spacer, y=pos.y+y, z=pos.z+v.z*spacer}
			if lp~=nil then
				if lp.x~=np.x then 
					if lp.x<np.x then 
						for i=lp.x+1,np.x do
							env:add_node({x=i, y=np.y, z=np.z}, node)
							count = count + 1
						end
					else
						for i=np.x,lp.x-1 do
							env:add_node({x=i, y=np.y, z=np.z}, node)
							count = count + 1
						end
					end
				end
				if lp.z~=np.z then 
					if lp.z<np.z then 
						for i=lp.z+1,np.z do
							env:add_node({x=np.x, y=np.y, z=i}, node)
							count = count + 1
						end
					else
						for i=np.z,lp.z-1 do
							env:add_node({x=np.x, y=np.y, z=i}, node)
							count = count + 1
						end
					end
				end
			end
			lp = np
		end
	end
	return count
end
