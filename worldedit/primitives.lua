worldedit = worldedit or {}

--adds a hollow sphere centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.hollow_sphere = function(pos, radius, nodename)
	local insert = table.insert
	local node = {name=nodename, param1=0, param2=0}
	local ignore = {name="ignore", param1=0, param2=0}
	local nodes = {}
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	for x = -radius, radius do
		for y = -radius, radius do
			for z = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared >= min_radius and squared <= max_radius then
					insert(nodes, node)
				else
					insert(nodes, ignore)
				end
			end
		end
	end
	minetest.place_schematic({x=pos.x - radius, y=pos.y - radius, z=pos.z - radius}, {size={x=radius * 2, y=radius * 2, z=radius * 2}, data=nodes})
	return #nodes
end

--adds a sphere centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.sphere = function(pos, radius, nodename)
	local insert = table.insert
	local node = {name=nodename, param1=0, param2=0}
	local ignore = {name="ignore", param1=0, param2=0}
	local nodes = {}
	local max_radius = radius * (radius + 1)
	for x = -radius, radius do
		for y = -radius, radius do
			for z = -radius, radius do
				if x * x + y * y + z * z <= max_radius then
					insert(nodes, node)
				else
					insert(nodes, ignore)
				end
			end
		end
	end
	minetest.place_schematic({x=pos.x - radius, y=pos.y - radius, z=pos.z - radius}, {size={x=radius * 2, y=radius * 2, z=radius * 2}, data=nodes})
	return #nodes
end

--adds a hollow dome centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.hollow_dome = function(pos, radius, nodename) --wip: use bresenham sphere for maximum speed
	local insert = table.insert
	local node = {name=nodename, param1=0, param2=0}
	local ignore = {name="ignore", param1=0, param2=0}
	local nodes = {}
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	for x = -radius, radius do
		for y = 0, radius do
			for z = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared >= min_radius and squared <= max_radius then
					insert(nodes, node)
				else
					insert(nodes, ignore)
				end
			end
		end
	end
	minetest.place_schematic({x=pos.x - radius, y=pos.y, z=pos.z - radius}, {size={x=radius * 2, y=radius * 2, z=radius * 2}, data=nodes})
	return #nodes
end

--adds a dome centered at `pos` with radius `radius`, composed of `nodename`, returning the number of nodes added
worldedit.dome = function(pos, radius, nodename) --wip: use bresenham sphere for maximum speed
	local insert = table.insert
	local node = {name=nodename, param1=0, param2=0}
	local ignore = {name="ignore", param1=0, param2=0}
	local nodes = {}
	local max_radius = radius * (radius + 1)
	for x = -radius, radius do
		for y = 0, radius do
			for z = -radius, radius do
				if x * x + y * y + z * z <= max_radius then
					insert(nodes, node)
				else
					insert(nodes, ignore)
				end
			end
		end
	end
	minetest.place_schematic({x=pos.x - radius, y=pos.y, z=pos.z - radius}, {size={x=radius * 2, y=radius * 2, z=radius * 2}, data=nodes})
	return #nodes
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

		count = count + (length *8) --wip: broken because sometimes currentpos is repeated

		--move to next location
		delta = delta + (offset1 * 2) + 1
		if delta >= 0 then
			offset2 = offset2 - 1
			delta = delta - (offset2 * 2)
		end
		offset1 = offset1 + 1
	end
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

	--wip: make this faster using the schematic method by adding columns in a circle pattern like in hollow_cylinder, or by adding whole 2D slices using custom sized schematics
	if env == nil then env = minetest.env end
	local currentpos = {x=pos.x, y=pos.y, z=pos.z}
	local node = {name=nodename}
	local count = 0
	local step = 1
	if length < 0 then
		length = -length
		step = -1
	end
	for i = 1, length do
		local offset1, offset2 = 0, radius
		local delta = -radius
		while offset1 <= offset2 do
			--connect each pair of octants
			currentpos[other1] = pos[other1] - offset1
			local second1, second2 = pos[other2] + offset2, pos[other2] - offset2
			for i = 0, offset1 * 2 do
				currentpos[other2] = second1
				env:add_node(currentpos, node) --octant 1 to 4
				currentpos[other2] = second2
				env:add_node(currentpos, node) --octant 5 to 8
				currentpos[other1] = currentpos[other1] + 1
			end
			currentpos[other1] = pos[other1] - offset2
			local second1, second2 = pos[other2] + offset1, pos[other2] - offset1
			for i = 0, offset2 * 2 do
				currentpos[other2] = second1
				env:add_node(currentpos, node) --octant 2 to 3
				currentpos[other2] = second2
				env:add_node(currentpos, node) --octant 6 to 7
				currentpos[other1] = currentpos[other1] + 1
			end

			count = count + (offset1 * 4) + (offset2 * 4) + 4 --wip: broken

			--move to next location
			delta = delta + (offset1 * 2) + 1
			offset1 = offset1 + 1
			if delta >= 0 then
				offset2 = offset2 - 1
				delta = delta - (offset2 * 2)
			end
		end
		currentpos[axis] = currentpos[axis] + step
	end
	return count
end

--adds a pyramid centered at `pos` with height `height`, composed of `nodename`, returning the number of nodes added
worldedit.pyramid = function(pos, height, nodename, env)
	local pos1x, pos1y, pos1z = pos.x - height, pos.y, pos.z - height
	local pos2x, pos2y, pos2z = pos.x + height, pos.y + height, pos.z + height
	local pos = {x=0, y=pos1y, z=0}

	--wip: make this faster using base sized schematics that are then resized while moving upwards, or if that's not possible, add new rows/columns while looping
	local count = 0
	local node = {name=nodename}
	if env == nil then env = minetest.env end
	while pos.y <= pos2y do --each vertical level of the pyramid
		pos.x = pos1x
		while pos.x <= pos2x do
			pos.z = pos1z
			while pos.z <= pos2z do
				env:add_node(pos, node)
				pos.z = pos.z + 1
			end
			pos.x = pos.x + 1
		end
		count = count + ((pos2y - pos.y) * 2 + 1) ^ 2
		pos.y = pos.y + 1

		pos1x, pos2x = pos1x + 1, pos2x - 1
		pos1z, pos2z = pos1z + 1, pos2z - 1

	end
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
