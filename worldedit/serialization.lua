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

--determines the version of serialized data `value`, returning the version as a positive integer or 0 for unknown versions
worldedit.valueversion = function(value)
	if value:find("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)") and not value:find("%{") then --previous list format
		return 3
	elseif value:find("^[^\"']+%{%d+%}") then
		if value:find("%[\"meta\"%]") then --previous meta flat table format
			return 2
		end
		return 1 --original flat table format
	elseif value:find("%{") then --current nested table format
		return 4
	end
	return 0 --unknown format
end

--converts the region defined by positions `pos1` and `pos2` into a single string, returning the serialized data and the number of nodes serialized
worldedit.serialize = function(pos1, pos2) --wip: check for ItemStacks and whether they can be serialized
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
					local meta = env:get_meta(pos):to_table()

					--convert metadata itemstacks to itemstrings
					for name, inventory in pairs(meta.inventory) do
						for index, stack in ipairs(inventory) do
							inventory[index] = stack.to_string and stack:to_string() or stack
						end
					end

					result[count] = {
						x = pos.x - pos1.x,
						y = pos.y - pos1.y,
						z = pos.z - pos1.z,
						name = node.name,
						param1 = node.param1,
						param2 = node.param2,
						meta = meta,
					}
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	result = minetest.serialize(result) --convert entries to a string
	return result, count
end

--determines the volume the nodes represented by string `value` would occupy if deserialized at `originpos`, returning the two corner positions and the number of nodes
--contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.allocate = function(originpos, value)
	local huge = math.huge
	local pos1x, pos1y, pos1z = huge, huge, huge
	local pos2x, pos2y, pos2z = -huge, -huge, -huge
	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	local version = worldedit.valueversion(value)
	if version == 1 or version == 2 then --flat table format
		--obtain the node table
		local get_tables = loadstring(value)
		if get_tables then --error loading value
			return originpos, originpos, count
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
		local nodes = tables[1]

		--check the node array
		count = #nodes
		if version == 1 then --original flat table format
			for index = 1, count do
				local entry = nodes[index]
				local pos = entry[1]
				local x, y, z = originx - pos.x, originy - pos.y, originz - pos.z
				if x < pos1x then pos1x = x end
				if y < pos1y then pos1y = y end
				if z < pos1z then pos1z = z end
				if x > pos2x then pos2x = x end
				if y > pos2y then pos2y = y end
				if z > pos2z then pos2z = z end
			end
		else --previous meta flat table format
			for index = 1, count do
				local entry = nodes[index]
				local x, y, z = originx - entry.x, originy - entry.y, originz - entry.z
				if x < pos1x then pos1x = x end
				if y < pos1y then pos1y = y end
				if z < pos1z then pos1z = z end
				if x > pos2x then pos2x = x end
				if y > pos2y then pos2y = y end
				if z > pos2z then pos2z = z end
			end
		end
	elseif version == 3 then --previous list format
		for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
			x, y, z = originx + tonumber(x), originy + tonumber(y), originz + tonumber(z)
			if x < pos1x then pos1x = x end
			if y < pos1y then pos1y = y end
			if z < pos1z then pos1z = z end
			if x > pos2x then pos2x = x end
			if y > pos2y then pos2y = y end
			if z > pos2z then pos2z = z end
			count = count + 1
		end
	elseif version == 4 then --current nested table format
		local nodes = minetest.deserialize(value)
		count = #nodes
		for index = 1, count do
			local entry = nodes[index]
			x, y, z = originx + entry.x, originy + entry.y, originz + entry.z
			if x < pos1x then pos1x = x end
			if y < pos1y then pos1y = y end
			if z < pos1z then pos1z = z end
			if x > pos2x then pos2x = x end
			if y > pos2y then pos2y = y end
			if z > pos2z then pos2z = z end
		end
	end
	local pos1 = {x=pos1x, y=pos1y, z=pos1z}
	local pos2 = {x=pos2x, y=pos2y, z=pos2z}
	return pos1, pos2, count
end

--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized
--contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.deserialize = function(originpos, value, env)
	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	if env == nil then env = minetest.env end
	local version = worldedit.valueversion(value)
	if version == 1 or version == 2 then --original flat table format
		--obtain the node table
		local get_tables = loadstring(value)
		if not get_tables then --error loading value
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
		local nodes = tables[1]

		--load the node array
		count = #nodes
		if version == 1 then --original flat table format
			for index = 1, count do
				local entry = nodes[index]
				local pos = entry[1]
				pos.x, pos.y, pos.z = originx - pos.x, originy - pos.y, originz - pos.z
				env:add_node(pos, entry[2])
			end
		else --previous meta flat table format
			for index = 1, #nodes do
				local entry = nodes[index]
				entry.x, entry.y, entry.z = originx + entry.x, originy + entry.y, originz + entry.z
				env:add_node(entry, entry) --entry acts both as position and as node
				env:get_meta(entry):from_table(entry.meta)
			end
		end
	elseif version == 3 then --previous list format
		local pos = {x=0, y=0, z=0}
		local node = {name="", param1=0, param2=0}
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
	elseif version == 4 then --current nested table format
		--wip: this is a filthy hack that works surprisingly well
		value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1)
		local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
		local startpos, startpos1, endpos = 1, 1
		local nodes = {}
		while true do
			startpos, endpos = escaped:find("},%s*{", startpos)
			if not startpos then
				break
			end
			local current = value:sub(startpos1, startpos)
			table.insert(nodes, minetest.deserialize("return " .. current))
			startpos, startpos1 = endpos, endpos
		end
		table.insert(nodes, minetest.deserialize("return " .. value:sub(startpos1)))

		--local nodes = minetest.deserialize(value) --wip: this is broken for larger tables in the current version of LuaJIT

		--load the nodes
		count = #nodes
		for index = 1, count do
			local entry = nodes[index]
			entry.x, entry.y, entry.z = originx + entry.x, originy + entry.y, originz + entry.z
			env:add_node(entry, entry) --entry acts both as position and as node
		end

		--load the metadata
		for index = 1, count do
			local entry = nodes[index]
			env:get_meta(entry):from_table(entry.meta)
		end
	end
	return count
end
