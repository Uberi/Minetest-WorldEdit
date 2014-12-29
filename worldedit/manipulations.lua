worldedit = worldedit or {}
local minetest = minetest --local copy of global

-- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- Returns the new positions.
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
worldedit.set = function(pos1, pos2, nodenames)
	if type(nodenames) == "string" then
		nodenames = {nodenames}
	end

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

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
	local node_ids = {}
	for i,v in ipairs(nodenames) do
		node_ids[i] = minetest.get_content_id(nodenames[i])
	end
	if #node_ids == 1 then --only one type of node
		local id = node_ids[1]
		for i in area:iterp(pos1, pos2) do nodes[i] = id end --fill area with node
	else --several types of nodes specified
		local id_count, rand = #node_ids, math.random
		for i in area:iterp(pos1, pos2) do nodes[i] = node_ids[rand(id_count)] end --fill randomly with all types of specified nodes
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return worldedit.volume(pos1, pos2)
end

--replaces all instances of `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`, returning the number of nodes replaced
worldedit.replace = function(pos1, pos2, searchnode, replacenode)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	local nodes = manip:get_data()
	local searchnode_id = minetest.get_content_id(searchnode)
	local replacenode_id = minetest.get_content_id(replacenode)
	local count = 0
	for i in area:iterp(pos1, pos2) do --replace searchnode with replacenode
		if nodes[i] == searchnode_id then
			nodes[i] = replacenode_id
			count = count + 1
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--replaces all nodes other than `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`, returning the number of nodes replaced
worldedit.replaceinverse = function(pos1, pos2, searchnode, replacenode)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--set up voxel manipulator
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	local nodes = manip:get_data()
	local searchnode_id = minetest.get_content_id(searchnode)
	local replacenode_id = minetest.get_content_id(replacenode)
	local count = 0
	for i in area:iterp(pos1, pos2) do --replace anything that is not searchnode with replacenode
		if nodes[i] ~= searchnode_id then
			nodes[i] = replacenode_id
			count = count + 1
		end
	end

	--update map nodes
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	return count
end

--copies the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes, returning the number of nodes copied
worldedit.copy = function(pos1, pos2, axis, amount) --wip: replace the old version below
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	if amount == 0 then
		return
	end

	local other1, other2
	if axis == "x" then
		other1, other2 = "y", "z"
	elseif axis == "y" then
		other1, other2 = "x", "z"
	else --axis == "z"
		other1, other2 = "x", "y"
	end

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	--prepare slice along axis
	local extent = {
		[axis] = 1,
		[other1]=pos2[other1] - pos1[other1] + 1,
		[other2]=pos2[other2] - pos1[other2] + 1,
	}
	local nodes = {}
	local schematic = {size=extent, data=nodes}

	local currentpos = {x=pos1.x, y=pos1.y, z=pos1.z}
	local stride = {x=1, y=extent.x, z=extent.x * extent.y}
	local get_node = minetest.get_node
	for index1 = 1, extent[axis] do --go through each slice
		--copy slice into schematic
		local newindex1 = (index1 + offset[axis]) * stride[axis] + 1 --offset contributed by axis plus 1 to make it 1-indexed
		for index2 = 1, extent[other1] do
			local newindex2 = newindex1 + (index2 + offset[other1]) * stride[other1]
			for index3 = 1, extent[other2] do
				local i = newindex2 + (index3 + offset[other2]) * stride[other2]
				local node = get_node(pos)
				node.param1 = 255 --node will always appear
				nodes[i] = node
			end
		end

		--copy schematic to target
		currentpos[axis] = currentpos[axis] + amount
		place_schematic(currentpos, schematic)

		--wip: copy meta

		currentpos[axis] = currentpos[axis] + 1
	end
	return worldedit.volume(pos1, pos2)
end

worldedit.copy2 = function(pos1, pos2, direction, volume)
	-- the overlap shouldn't matter as long as we
	-- 1) start at the furthest separated corner
	-- 2) complete an edge before moving inward, either edge works
	-- 3) complete a face before moving inward, similarly
	--
	-- to do this I
	-- 1) find the furthest destination in the direction, of each axis
	-- 2) call those the furthest separated corner
	-- 3) make sure to iterate inward from there
	-- 4) nested loop to make sure complete edge, complete face, then complete cube.

	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	local somemeta = get_meta(pos1) -- hax lol
	local to_table = somemeta.to_table
	local from_table = somemeta.from_table
	somemeta = nil

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local sx, sy, sz -- direction sign
	local ix, iy, iz -- initial destination
	local ex, ey, ez -- final destination
	local originalx, originaly, originalz -- source
	-- vim -> :'<,'>s/\<\([ioes]\?\)x\>/\1y/g
	if direction.x > 0 then
		originalx = pos2.x
		ix = originalx + direction.x
		ex = pos1.x + direction.x
		sx = -1
	elseif direction.x < 0 then
		originalx = pos1.x
		ix = originalx + direction.x
		ex = pos2.x + direction.x
		sx = 1
	else
		originalx = pos1.x
		ix = originalx -- whatever
		ex = pos2.x
		sx = 1
	end

	if direction.y > 0 then
		originaly = pos2.y
		iy = originaly + direction.y
		ey = pos1.y + direction.y
		sy = -1
	elseif direction.y < 0 then
		originaly = pos1.y
		iy = originaly + direction.y
		ey = pos2.y + direction.y
		sy = 1
	else
		originaly = pos1.y
		iy = originaly -- whatever
		ey = pos2.y
		sy = 1
	end

	if direction.z > 0 then
		originalz = pos2.z
		iz = originalz + direction.z
		ez = pos1.z + direction.z
		sz = -1
	elseif direction.z < 0 then
		originalz = pos1.z
		iz = originalz + direction.z
		ez = pos2.z + direction.z
		sz = 1
	else
		originalz = pos1.z
		iz = originalz -- whatever
		ez = pos2.z
		sz = 1
	end
	-- print('copy',originalx,ix,ex,sx,originaly,iy,ey,sy,originalz,iz,ez,sz)

	local ox,oy,oz

	ox = originalx
	for x = ix, ex, sx do
		oy = originaly
		for y = iy, ey, sy do
			oz = originalz
			for z = iz, ez, sz do
				-- reusing pos1/pos2 as source/dest here
				pos1.x, pos1.y, pos1.z = ox, oy, oz
				pos2.x, pos2.y, pos2.z = x, y, z
				local node = get_node(pos1)
				local meta = to_table(get_meta(pos1)) --get meta of current node
				add_node(pos2,node)
				from_table(get_meta(pos2),meta)
				oz = oz + sz
			end
			oy = oy + sy
		end
		ox = ox + sx
	end
end

--duplicates the region defined by positions `pos1` and `pos2` `amount` times with offset vector `direction`, returning the number of nodes stacked
worldedit.stack2 = function(pos1, pos2, direction, amount, finished)
	local i = 0
	local translated = {x=0,y=0,z=0}
	local function nextone()
		if i < amount then
			i = i + 1
			translated.x = translated.x + direction.x
			translated.y = translated.y + direction.y
			translated.z = translated.z + direction.z
			worldedit.copy2(pos1, pos2, translated, volume)
			minetest.after(0, nextone)
		else
			if finished then
				finished()
			end
		end
	end
	nextone()
	return worldedit.volume(pos1, pos2) * amount
end

--copies the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes, returning the number of nodes copied
worldedit.copy = function(pos1, pos2, axis, amount)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	if amount < 0 then
		local pos = {x=pos1.x, y=0, z=0}
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = get_node(pos) --obtain current node
					local meta = get_meta(pos):to_table() --get meta of current node
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					add_node(pos, node) --copy node to new position
					get_meta(pos):from_table(meta) --set metadata of new node
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
					local node = get_node(pos) --obtain current node
					local meta = get_meta(pos):to_table() --get meta of current node
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					add_node(pos, node) --copy node to new position
					get_meta(pos):from_table(meta) --set metadata of new node
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

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	--wip: move slice by slice using schematic method in the move axis and transfer metadata in separate loop (and if the amount is greater than the length in the axis, copy whole thing at a time and erase original after, using schematic method)
	local get_node, get_meta, add_node, remove_node = minetest.get_node, minetest.get_meta, minetest.add_node, minetest.remove_node
	if amount < 0 then
		local pos = {x=pos1.x, y=0, z=0}
		while pos.x <= pos2.x do
			pos.y = pos1.y
			while pos.y <= pos2.y do
				pos.z = pos1.z
				while pos.z <= pos2.z do
					local node = get_node(pos) --obtain current node
					local meta = get_meta(pos):to_table() --get metadata of current node
					remove_node(pos)
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					add_node(pos, node) --move node to new position
					get_meta(pos):from_table(meta) --set metadata of new node
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
					local node = get_node(pos) --obtain current node
					local meta = get_meta(pos):to_table() --get metadata of current node
					remove_node(pos)
					local value = pos[axis] --store current position
					pos[axis] = value + amount --move along axis
					add_node(pos, node) --move node to new position
					get_meta(pos):from_table(meta) --set metadata of new node
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
	local i = 1
	function nextone()
		if i <= count then
			i = i + 1
			amount = amount + length
			copy(pos1, pos2, axis, amount)
			minetest.after(0, nextone)
		end
	end
	nextone()
	return worldedit.volume(pos1, pos2) * count
end

--stretches the region defined by positions `pos1` and `pos2` by an factor of positive integers `stretchx`, `stretchy`. and `stretchz` along the X, Y, and Z axes, respectively, with `pos1` as the origin, returning the number of nodes scaled, the new scaled position 1, and the new scaled position 2
worldedit.stretch = function(pos1, pos2, stretchx, stretchy, stretchz) --wip: test this
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--prepare schematic of large node
	local get_node, get_meta, place_schematic = minetest.get_node, minetest.get_meta, minetest.place_schematic
	local placeholder_node = {name="", param1=255, param2=0}
	local nodes = {}
	for i = 1, stretchx * stretchy * stretchz do
		nodes[i] = placeholder_node
	end
	local schematic = {size={x=stretchx, y=stretchy, z=stretchz}, data=nodes}

	local sizex, sizey, sizez = stretchx - 1, stretchy - 1, stretchz - 1

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	local new_pos2 = {
		x=pos1.x + (pos2.x - pos1.x) * stretchx + sizex,
		y=pos1.y + (pos2.y - pos1.y) * stretchy + sizey,
		z=pos1.z + (pos2.z - pos1.z) * stretchz + sizez,
	}
	manip:read_from_map(pos1, new_pos2)

	local pos = {x=pos2.x, y=0, z=0}
	local bigpos = {x=0, y=0, z=0}
	while pos.x >= pos1.x do
		pos.y = pos2.y
		while pos.y >= pos1.y do
			pos.z = pos2.z
			while pos.z >= pos1.z do
				local node = get_node(pos) --obtain current node
				local meta = get_meta(pos):to_table() --get meta of current node

				--calculate far corner of the big node
				local posx = pos1.x + (pos.x - pos1.x) * stretchx
				local posy = pos1.y + (pos.y - pos1.y) * stretchy
				local posz = pos1.z + (pos.z - pos1.z) * stretchz

				--create large node
				placeholder_node.name = node.name
				placeholder_node.param2 = node.param2
				bigpos.x, bigpos.y, bigpos.z = posx, posy, posz
				place_schematic(bigpos, schematic)

				--fill in large node meta
				if next(meta.fields) ~= nil or next(meta.inventory) ~= nil then --node has meta fields
					for x = 0, sizex do
						for y = 0, sizey do
							for z = 0, sizez do
								bigpos.x, bigpos.y, bigpos.z = posx + x, posy + y, posz + z
								get_meta(bigpos):from_table(meta) --set metadata of new node
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
	return worldedit.volume(pos1, pos2) * stretchx * stretchy * stretchz, pos1, new_pos2
end

--transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes, returning the number of nodes transposed, the new transposed position 1, and the new transposed position 2
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
	local new_pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	new_pos2[axis1] = pos1[axis1] + extent2
	new_pos2[axis2] = pos1[axis2] + extent1

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	local upperbound = {x=pos2.x, y=pos2.y, z=pos2.z}
	if upperbound[axis1] < new_pos2[axis1] then upperbound[axis1] = new_pos2[axis1] end
	if upperbound[axis2] < new_pos2[axis2] then upperbound[axis2] = new_pos2[axis2] end
	manip:read_from_map(pos1, upperbound)

	local pos = {x=pos1.x, y=0, z=0}
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local extent1, extent2 = pos[axis1] - pos1[axis1], pos[axis2] - pos1[axis2]
				if compare(extent1, extent2) then --transpose only if below the diagonal
					local node1 = get_node(pos)
					local meta1 = get_meta(pos):to_table()
					local value1, value2 = pos[axis1], pos[axis2] --save position values
					pos[axis1], pos[axis2] = pos1[axis1] + extent2, pos1[axis2] + extent1 --swap axis extents
					local node2 = get_node(pos)
					local meta2 = get_meta(pos):to_table()
					add_node(pos, node1)
					get_meta(pos):from_table(meta1)
					pos[axis1], pos[axis2] = value1, value2 --restore position values
					add_node(pos, node2)
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

--flips a region defined by the positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z"), returning the number of nodes flipped
worldedit.flip = function(pos1, pos2, axis)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	--wip: flip the region slice by slice along the flip axis using schematic method
	local pos = {x=pos1.x, y=0, z=0}
	local start = pos1[axis] + pos2[axis]
	pos2[axis] = pos1[axis] + math.floor((pos2[axis] - pos1[axis]) / 2)
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node1 = get_node(pos)
				local meta1 = get_meta(pos):to_table()
				local value = pos[axis]
				pos[axis] = start - value
				local node2 = get_node(pos)
				local meta2 = get_meta(pos):to_table()
				add_node(pos, node1)
				get_meta(pos):from_table(meta1)
				pos[axis] = value
				add_node(pos, node2)
				get_meta(pos):from_table(meta2)
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

--rotates all oriented nodes in a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise (90 degree increment) around the Y axis, returning the number of nodes oriented
worldedit.orient = function(pos1, pos2, angle) --wip: support 6D facedir rotation along arbitrary axis
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local registered_nodes = minetest.registered_nodes

	local wallmounted = {
		[90]={[0]=0, [1]=1, [2]=5, [3]=4, [4]=2, [5]=3},
		[180]={[0]=0, [1]=1, [2]=3, [3]=2, [4]=5, [5]=4},
		[270]={[0]=0, [1]=1, [2]=4, [3]=5, [4]=3, [5]=2}
	}
	local facedir = {
		[90]={[0]=1, [1]=2, [2]=3, [3]=0},
		[180]={[0]=2, [1]=3, [2]=0, [3]=1},
		[270]={[0]=3, [1]=0, [2]=1, [3]=2}
	}

	angle = angle % 360
	if angle == 0 then
		return 0
	end
	local wallmounted_substitution = wallmounted[angle]
	local facedir_substitution = facedir[angle]

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local count = 0
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
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
						add_node(pos, node)
						get_meta(pos):from_table(meta)
						count = count + 1
					elseif def.paramtype2 == "facedir" then
						node.param2 = facedir_substitution[node.param2]
						local meta = get_meta(pos):to_table()
						add_node(pos, node)
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

--fixes the lighting in a region defined by positions `pos1` and `pos2`, returning the number of nodes updated
worldedit.fixlight = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local nodes = minetest.find_nodes_in_area(pos1, pos2, "air")
	local dig_node = minetest.dig_node
	for _, pos in ipairs(nodes) do
		dig_node(pos)
	end
	return #nodes
end

--clears all objects in a region defined by the positions `pos1` and `pos2`, returning the number of objects cleared
worldedit.clearobjects = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1x, pos1y, pos1z = pos1.x, pos1.y, pos1.z
	local pos2x, pos2y, pos2z = pos2.x + 1, pos2.y + 1, pos2.z + 1
	local center = {x=(pos1x + pos2x) / 2, y=(pos1y + pos2y) / 2, z=(pos1z + pos2z) / 2} --center of region
	local radius = ((center.x - pos1x + 0.5) + (center.y - pos1y + 0.5) + (center.z - pos1z + 0.5)) ^ 0.5 --bounding sphere radius
	local count = 0
	for _, obj in pairs(minetest.get_objects_inside_radius(center, radius)) do --all objects in bounding sphere
		local entity = obj:get_luaentity()
		if not (entity and entity.name:find("^worldedit:")) then --avoid WorldEdit entities
			local pos = obj:getpos()
			if pos.x >= pos1x and pos.x <= pos2x
			and pos.y >= pos1y and pos.y <= pos2y
			and pos.z >= pos1z and pos.z <= pos2z then --inside region
				obj:remove()
				count = count + 1
			end
		end
	end
	return count
end
