worldedit = worldedit or {}

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

	if minetest.registered_nodes[searchnode] == nil then
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
					local node = env:get_node(pos) --obtain current node
					local meta = env:get_meta(pos):to_table() --get meta of current node
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					env:add_node(pos, node) --copy node to new position
					env:get_meta(pos):from_table(meta) --set metadata of new node
					pos[axis] = value --restore old position
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
					local node = minetest.env:get_node(pos) --obtain current node
					local meta = env:get_meta(pos):to_table() --get meta of current node
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					minetest.env:add_node(pos, node) --copy node to new position
					env:get_meta(pos):from_table(meta) --set metadata of new node
					pos[axis] = value --restore old position
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
					local node = env:get_node(pos) --obtain current node
					local meta = env:get_meta(pos):to_table() --get metadata of current node
					env:remove_node(pos)
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					env:add_node(pos, node) --move node to new position
					env:get_meta(pos):from_table(meta) --set metadata of new node
					pos[axis] = value --restore old position
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
					local node = env:get_node(pos) --obtain current node
					local meta = env:get_meta(pos):to_table() --get metadata of current node
					env:remove_node(pos)
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					env:add_node(pos, node) --move node to new position
					env:get_meta(pos):from_table(meta) --set metadata of new node
					pos[axis] = value --restore old position
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
	if count < 0 then
		count = -count
		length = -length
	end
	local amount = 0
	local copy = worldedit.copy
	for i = 1, count do
		amount = amount + length
		copy(pos1, pos2, axis, amount)
	end
	return worldedit.volume(pos1, pos2)
end

--transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes, returning the number of nodes transposed, the new position 1, and the new position 2
worldedit.transpose = function(pos1, pos2, axis1, axis2)
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

	--calculate the new position 2 after transposition
	local newpos2 = {x=pos1.x, y=pos1.y, z=pos1.z}
	newpos2[axis1] = pos1[axis1] + extent2
	newpos2[axis2] = pos1[axis2] + extent1

	local pos = {x=pos1.x, y=0, z=0}
	local env = minetest.env
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local extent1, extent2 = pos[axis1] - pos1[axis1], pos[axis2] - pos1[axis2]
				if compare(extent1, extent2) then --transpose only if below the diagonal
					local node1 = env:get_node(pos)
					local meta1 = env:get_meta(pos):to_table()
					local value1, value2 = pos[axis1], pos[axis2] --save position values
					pos[axis1], pos[axis2] = pos1[axis1] + extent2, pos1[axis2] + extent1 --swap axis extents
					local node2 = env:get_node(pos)
					local meta2 = env:get_meta(pos):to_table()
					env:add_node(pos, node1)
					env:get_meta(pos):from_table(meta1)
					pos[axis1], pos[axis2] = value1, value2 --restore position values
					env:add_node(pos, node2)
					env:get_meta(pos):from_table(meta2)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2), pos1, newpos2
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
				local meta1 = env:get_meta(pos):to_table()
				local value = pos[axis]
				pos[axis] = start - value
				local node2 = env:get_node(pos)
				local meta2 = env:get_meta(pos):to_table()
				env:add_node(pos, node1)
				env:get_meta(pos):from_table(meta1)
				pos[axis] = value
				env:add_node(pos, node2)
				env:get_meta(pos):from_table(meta2)
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--rotates a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise around axis `axis` (90 degree increment), returning the number of nodes rotated
worldedit.rotate = function(pos1, pos2, axis, angle)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local axis1, axis2
	if axis == "x" then
		axis1, axis2 = "z", "y"
	elseif axis == "y" then
		axis1, axis2 = "x", "z"
	else --axis == "z"
		axis1, axis2 = "y", "x"
	end
	angle = angle % 360

	local count
	if angle == 90 then
		worldedit.flip(pos1, pos2, axis1)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2)
	elseif angle == 180 then
		worldedit.flip(pos1, pos2, axis1)
		count = worldedit.flip(pos1, pos2, axis2)
	elseif angle == 270 then
		worldedit.flip(pos1, pos2, axis2)
		count, pos1, pos2 = worldedit.transpose(pos1, pos2, axis1, axis2)
	end
	return count, pos1, pos2
end

--Fixes the Lightning in a region defined by positions `pos1` and `pos2`, returning the number of nodes dug
worldedit.fixlight = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local env = minetest.env
	local d = 0

	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do#
				local node = env:get_node(pos)
				if node.name == "air":
					env:dig_node(pos)
					d = d + 1
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return d
end
