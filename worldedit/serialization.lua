worldedit = worldedit or {}

dofile(minetest.get_modpath("worldedit") .. "/table_save.lua") --wip: remove dependency

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
	result = table.concat(result, "\n") --join all node entries into single string
	return result, count
end

--determines the volume the nodes represented by string `value` would occupy if deserialized at `originpos`, returning the two corner positions and the number of nodes
worldedit.allocate = function(originpos, value)
	local huge = math.huge
	local pos1 = {x=huge, y=huge, z=huge}
	local pos2 = {x=-huge, y=-huge, z=-huge}
	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
		x, y, z = originx + tonumber(x), originy + tonumber(y), originz + tonumber(z)
		if x < pos1.x then
			pos1.x = x
		end
		if y < pos1.y then
			pos1.y = y
		end
		if z < pos1.z then
			pos1.z = z
		end
		if x > pos2.x then
			pos2.x = x
		end
		if y > pos2.y then
			pos2.y = y
		end
		if z > pos2.z then
			pos2.z = z
		end
		count = count + 1
	end
	return pos1, pos2, count
end

--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized
worldedit.deserialize = function(originpos, value)
	local pos = {x=0, y=0, z=0}
	local node = {name="", param1=0, param2=0}
	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	local env = minetest.env
	for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
		pos.x = originx + tonumber(x)
		pos.y = originy + tonumber(y)
		pos.z = originz + tonumber(z)
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
worldedit.metasave = function(pos1, pos2, file) --wip: simply work with strings instead of doing IO
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
worldedit.metaload = function(pos1, file) --wip: simply work with strings instead of doing IO
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