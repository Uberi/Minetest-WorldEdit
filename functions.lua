--modifies positions `pos1` and `pos2` so that each component of `pos1` is less than or equal to its corresponding conent of `pos2`, returning two new positions
worldedit.sort_pos = function(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--determines the volume of the region defined by positions `pos1` and `pos2`, returning the volume
worldedit.volume = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	return (pos2.x - pos1.x + 1) * (pos2.y - pos1.y + 1) * (pos2.z - pos1.z + 1)
end

--sets a region defined by positions `pos1` and `pos2` to `nodename`, returning the number of nodes filled
worldedit.set = function(pos1, pos2, nodename)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env

	local node = {name=nodename}
	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				env:add_node(pos, node)
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--replaces all instances of `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`, returning the number of nodes replaced
worldedit.replace = function(pos1, pos2, searchnode, replacenode)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env

	if searchnode:find(":") == nil then
		searchnode = "default:" .. searchnode
	end

	local pos = {x=pos1.x, y=0, z=0}
	local node = {name=replacenode}
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				if env:get_node(pos).name == searchnode then
					env:add_node(pos, node)
					count = count + 1
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end

--adds a hollow cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, returning the number of nodes added
worldedit.hollow_cylinder = function(pos, axis, length, radius, nodename)
	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	local env = minetest.env
	local currentpos = {x=pos.x, y=pos.y, z=pos.z}
	local node = {name=nodename}
	local count = 0
	for i = 1, length do
		local offset1, offset2 = 0, radius
		local delta = -radius
		while offset1 <= offset2 do
			--add node at each octant
			local first1, first2 = pos[other1] + offset1, pos[other1] - offset1
			local second1, second2 = pos[other2] + offset2, pos[other2] - offset2
			currentpos[other1], currentpos[other2] = first1, second1
			env:add_node(currentpos, node) --octant 1
			currentpos[other1] = first2
			env:add_node(currentpos, node) --octant 4
			currentpos[other2] = second2
			env:add_node(currentpos, node) --octant 5
			currentpos[other1] = first1
			env:add_node(currentpos, node) --octant 8
			local first1, first2 = pos[other1] + offset2, pos[other1] - offset2
			local second1, second2 = pos[other2] + offset1, pos[other2] - offset1
			currentpos[other1], currentpos[other2] = first1, second1
			env:add_node(currentpos, node) --octant 2
			currentpos[other1] = first2
			env:add_node(currentpos, node) --octant 3
			currentpos[other2] = second2
			env:add_node(currentpos, node) --octant 6
			currentpos[other1] = first1
			env:add_node(currentpos, node) --octant 7

			count = count + 8 --wip: broken

			--move to next location
			delta = delta + (offset1 * 2) + 1
			if delta >= 0 then
				offset2 = offset2 - 1
				delta = delta - (offset2 * 2)
			end
			offset1 = offset1 + 1
		end
		currentpos[axis] = currentpos[axis] + 1
	end
	return count
end

--adds a cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, returning the number of nodes added
worldedit.cylinder = function(pos, axis, length, radius, nodename)
	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	local env = minetest.env
	local currentpos = {x=pos.x, y=pos.y, z=pos.z}
	local node = {name=nodename}
	local count = 0
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
		currentpos[axis] = currentpos[axis] + 1
	end
	return count
end

--adds a spiral at `pos` with size `size`, returning the number of nodes changed
worldedit.spiral = function(pos, size, nodename)
	local shift_x, shift_y
	sa = spiralt(size)
	shift_y = #sa -- "Height" of the Array
	local fe = sa[1]
	shift_x = #fe -- "Width" of the Array
	fe = nil

	local count = 0
	local node = {name=nodename}
	for x, v in ipairs(sa) do
		for y, z in ipairs(v) do
			minetest.env:add_node({x=pos.x - shift_x + x,y=pos.y - shift_y + y,z=pos.z + z}, node)
			count = count + 1
		end
	end
	return count
end

--wip: 
sign = function(s)
	if s > 0 then
		return 1
	end
	if s < 0 then
		return -1
	end
	return 0
end

--wip: needs to be faster
function spiral_index(y, x) -- returns the value at (x, y) in a spiral that starts at 1 and goes outwards
	if y == -x and y >= x then
		return (2 * y + 1) ^ 2
	end
	local l = math.max(math.abs(y), math.abs(x))
	local value
	if math.abs(y) == l then
		value = x
		if y < 0 then
			value = -value
		end
	else
		value = y
		if x < 0 then
			value = -value
		end
	end
	t1 = l * 2
	if x + y < 0 then
		t1 = -t1
	end
	t2 = y ^ 2 - x ^ 2
	if t2 < 0 then
		t2 = -t2
	end
	return ((2 * l - 1) ^ 2) + (l * 4) + t1 + (t2 * (l - value))
end

--wip: needs to be faster
function spiralt(side)
	local spiral = {}
	local start, stop = math.floor((-side+1)/2), math.floor((side-1)/2)
	for i = 1, side do
		spiral[i] = {}
		for j = 1, side do
			spiral[i][j] = side ^ 2 - spiral_index(stop - i + 1,start + j - 1) --moves the coordinates so (0,0) is at the center of the spiral
		end
	end
	return spiral
end

--copies the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes, returning the number of nodes copied
worldedit.copy = function(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env

	if amount < 0 then
		local pos = {x=pos1.x, y=0, z=0}
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = env:get_node(pos)
					local meta1 = env:get_meta(pos):to_table()
					local value = pos[axis]
					pos[axis] = value + amount
					env:add_node(pos, node)
					local meta2 = env:get_meta(pos)
					meta2:from_table(meta1)
					pos[axis] = value
					pos.z = pos.z + 1
				end
				pos.y = pos.y + 1
			end
			pos.x = pos.x + 1
		end
	else
		local pos = {x=pos2.x, y=0, z=0}
		while pos.x >= pos1.x do
			pos.y = pos2.y
			while pos.y >= pos1.y do
				pos.z = pos2.z
				while pos.z >= pos1.z do
					local node = minetest.env:get_node(pos)
					local meta1 = env:get_meta(pos):to_table()
					local value = pos[axis]
					pos[axis] = value + amount
					minetest.env:add_node(pos, node)
					local meta2 = env:get_meta(pos)
					meta2:from_table(meta1)
					pos[axis] = value
					pos.z = pos.z - 1
				end
				pos.y = pos.y - 1
			end
			pos.x = pos.x - 1
		end
	end
	return worldedit.volume(pos1, pos2)
end

--moves the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes, returning the number of nodes moved
worldedit.move = function(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env

	if amount < 0 then
		local pos = {x=pos1.x, y=0, z=0}
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = env:get_node(pos)
					local meta1 = env:get_meta(pos):to_table()
					env:remove_node(pos)
					local value = pos[axis]
					pos[axis] = value + amount
					env:add_node(pos, node)
					local meta2 = env:get_meta(pos)
					meta2:from_table(meta1)
					pos[axis] = value
					pos.z = pos.z + 1
				end
				pos.y = pos.y + 1
			end
			pos.x = pos.x + 1
		end
	else
		local pos = {x=pos2.x, y=0, z=0}
		while pos.x >= pos1.x do
			pos.y = pos2.y
			while pos.y >= pos1.y do
				pos.z = pos2.z
				while pos.z >= pos1.z do
					local node = env:get_node(pos)
					local meta1 = env:get_meta(pos):to_table()
					env:remove_node(pos)
					local value = pos[axis]
					pos[axis] = value + amount
					env:add_node(pos, node)
					local meta2 = env:get_meta(pos)
					meta2:from_table(meta1)
					pos[axis] = value
					pos.z = pos.z - 1
				end
				pos.y = pos.y - 1
			end
			pos.x = pos.x - 1
		end
	end
	return worldedit.volume(pos1, pos2)
end

--duplicates the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") `count` times, returning the number of nodes stacked
worldedit.stack = function(pos1, pos2, axis, count)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local length = pos2[axis] - pos1[axis] + 1
	local amount = 0
	local copy = worldedit.copy
	if count < 0 then
		count = -count
		length = -length
	end
	for i = 1, count do
		amount = amount + length
		copy(pos1, pos2, axis, amount)
	end
	return worldedit.volume(pos1, pos2)
end

--transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes, returning the number of nodes transposed
worldedit.transpose = function(pos1, pos2, axis1, axis2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	local env = minetest.env
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local extent1, extent2 = pos[axis1] - pos1[axis1], pos[axis2] - pos1[axis2]
				if extent1 < extent2 then
					local node1 = env:get_node(pos)
					local meta1a = env:get_meta(pos):to_table()
					local value1, value2 = pos[axis1], pos[axis2]
					pos[axis1], pos[axis2] = pos1[axis1] + extent2, pos1[axis2] + extent1
					local node2 = env:get_node(pos)
					local meta2a = env:get_meta(pos):to_table()
					env:add_node(pos, node1)
					local meta1b = env:get_meta(pos)
					meta1b:from_table(meta1a)
					pos[axis1], pos[axis2] = pos1[axis1] + extent1, pos1[axis2] + extent2
					env:add_node(pos, node2)
					local meta2b = env:get_meta(pos)
					meta2b:from_table(meta2a)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--flips a region defined by the positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z"), returning the number of nodes flipped
worldedit.flip = function(pos1, pos2, axis)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	local start = pos1[axis] + pos2[axis]
	pos2[axis] = pos1[axis] + math.floor((pos2[axis] - pos1[axis]) / 2)
	local env = minetest.env
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node1 = env:get_node(pos)
				local meta1a = env:get_meta(pos):to_table()
				local value = pos[axis]
				pos[axis] = start - value
				local node2 = env:get_node(pos)
				local meta2a = env:get_meta(pos):to_table()
				env:add_node(pos, node1)
				local meta1b = env:get_meta(pos)
				meta1b:from_table(meta1a)
				pos[axis] = value
				env:add_node(pos, node2)
				local meta2b = env:get_meta(pos)
				meta2b:from_table(meta2a)
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--rotates a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise (if you are looking in the negative direction) around the `axis` (supporting 90 degree increments only), returning the number of nodes rotated
worldedit.rotate = function(pos1, pos2, axis, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	if axis == 'x' then
		axes = {'z', 'y'}
	elseif axis == 'y' then
		axes = {'x', 'z'}
	else--if axis == 'z' then
		axes = {'y', 'x'}
	end
	angle = angle % 360

	local pos = {x=pos1.x, y=0, z=0}
	local newpos = {x=0, y=0, z=0}
	local offsetx, offsetz
	local env = minetest.env

	if angle == 90 then
		worldedit.transpose(pos1, pos2, axes[1], axes[2])
		worldedit.flip(pos1, pos2, axes[2])
	elseif angle == 180 then
		worldedit.flip(pos1, pos2, axes[1])
		worldedit.flip(pos1, pos2, axes[2])
	elseif angle == 270 then
		worldedit.transpose(pos1, pos2, axes[1], axes[2])
		worldedit.flip(pos1, pos2, axes[1])
	else
		return 0
	end
	return worldedit.volume(pos1, pos2)
end

--digs a region defined by positions `pos1` and `pos2`, returning the number of nodes dug
worldedit.dig = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env

	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				env:dig_node(pos)
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--converts the region defined by positions `pos1` and `pos2` into a single string, returning the serialized data and the number of nodes serialized
worldedit.serialize = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local count = 0
	local result = {}
	local env = minetest.env
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = env:get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then
					count = count + 1
					result[count] = pos.x - pos1.x .. " " .. pos.y - pos1.y .. " " .. pos.z - pos1.z .. " " .. node.name .. " " .. node.param1 .. " " .. node.param2
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	result = table.concat(result, "\n")
	return result, count
end

--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized
worldedit.deserialize = function(originpos, value)
	local pos = {x=0, y=0, z=0}
	local node = {name="", param1=0, param2=0}
	local count = 0
	local env = minetest.env
	for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do
		pos.x = originpos.x + tonumber(x)
		pos.y = originpos.y + tonumber(y)
		pos.z = originpos.z + tonumber(z)
		node.name = name
		node.param1 = param1
		node.param2 = param2
		env:add_node(pos, node)
		count = count + 1
	end
	return count
end

--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized
--based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.deserialize_old = function(originpos, value)
	--obtain the node table
	local count = 0
	local get_tables = loadstring(value)
	if get_tables == nil then --error loading value
		return count
	end
	local tables = get_tables()

	--transform the node table into an array of nodes
	for i = 1, #tables do
		for j, v in pairs(tables[i]) do
			if type(v) == "table" then
				tables[i][j] = tables[v[1]]
			end
		end
	end

	--load the node array
	local env = minetest.env
	for i, v in ipairs(tables[1]) do
		local pos = v[1]
		pos.x, pos.y, pos.z = originpos.x + pos.x, originpos.y + pos.y, originpos.z + pos.z
		env:add_node(pos, v[2])
		count = count + 1
	end
	return count
end

--saves the nodes and meta defined by positions `pos1` and `pos2` into a file, returning the number of nodes saved
worldedit.metasave = function(pos1, pos2, file)
	local path = minetest.get_worldpath() .. "/schems"
	local filename = path .. "/" .. file .. ".wem"
	os.execute("mkdir \"" .. path .. "\"") --create directory if it does not already exist
	local rows = {}
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local count = 0
	local result = {}
	local env = minetest.env
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = env:get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then
					count = count + 1
					local row = {
						x = pos.x-pos1.x,
						y = pos.y-pos1.y,
						z = pos.z-pos1.z,
						name = node.name,
						param1 = node.param1,
						param2 = node.param2,
						meta = env:get_meta(pos):to_table(),
					}
					table.insert(rows, row)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	local err = table.save(rows,filename)
	if err then return _,err end
	return count
end

--loads the nodes and meta from `file` to position `pos1`, returning the number of nodes loaded
worldedit.metaload = function(pos1, file)
	local filename = minetest.get_worldpath() .. "/schems/" .. file .. ".wem"
	local rows, err = table.load(filename)
	if err then return _,err end
	local pos = {x=0, y=0, z=0}
	local node = {name="", param1=0, param2=0}
	local count = 0
	local env = minetest.env
	for i,row in pairs(rows) do
		pos.x = pos1.x + tonumber(row.x)
		pos.y = pos1.y + tonumber(row.y)
		pos.z = pos1.z + tonumber(row.z)
		node.name = row.name
		node.param1 = row.param1
		node.param2 = row.param2
		env:add_node(pos, node)
		env:get_meta(pos):from_table(row.meta)
		count = count + 1
	end
	return count
end