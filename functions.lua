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

--fills a region defined by positions `pos1` and `pos2` with `nodename`, returning the number of nodes filled
worldedit.fill = function(pos1, pos2, nodename)
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

--copies the region defined by positions `pos1` and `pos2` along the `axis` axis by `amount` nodes, returning the number of nodes copied
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
					local node = env:get_node(pos, node)
					local value = pos[axis]
					pos[axis] = value - amount
					env:add_node(pos, node)
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
					local node = minetest.env:get_node(pos, node)
					local value = pos[axis]
					pos[axis] = value + amount
					minetest.env:add_node(pos, node)
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

--moves the region defined by positions `pos1` and `pos2` along the `axis` axis by `amount` nodes, returning the number of nodes moved
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
					local node = env:get_node(pos, node)
					env:remove_node(pos)
					local value = pos[axis]
					pos[axis] = value - amount
					env:add_node(pos, node)
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
					local node = minetest.env:get_node(pos, node)
					env:remove_node(pos)
					local value = pos[axis]
					pos[axis] = value + amount
					minetest.env:add_node(pos, node)
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

--duplicates the region defined by positions `pos1` and `pos2` along the `axis` axis `count` times, returning the number of nodes stacked
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