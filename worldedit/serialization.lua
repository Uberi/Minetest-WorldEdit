worldedit = worldedit or {}
local minetest = minetest -- Local copy of global

worldedit.LATEST_SERIALIZATION_VERSION = 5
local LATEST_SERIALIZATION_HEADER = worldedit.LATEST_SERIALIZATION_VERSION .. ":"


--[[
Serialization version history:
  1: Original format.  Serialized Lua table with a weird linked format...
  2: Position and node seperated into sub-tables in fields `1` and `2`.
  3: List of nodes, one per line, with fields seperated by spaces.
      Format: <X> <Y> <Z> <Name> <Param1> <Param2>
  4: Serialized Lua table containing a list of nodes with `x`, `y`, `z`,
      `name`, `param1`, `param2`, and `meta` fields.
  5: Added header and made `param1`, `param2`, and `meta` fields optional.
      Header format: <Version>,<ExtraHeaderField1>,...:<Content>
--]]


--- Reads the header of serialized data.
-- @param value Serialized WorldEdit data.
-- @return The version as a positive natural number, or 0 for unknown versions.
-- @return Extra header fields as a list of strings, or nil if not supported.
-- @return Content (data after header).
function worldedit.read_header(value)
	if value:find("^[0-9]+[%-:]") then
		local header_end = value:find(":", 1, true)
		local header = value:sub(1, header_end - 1):split(",")
		local version = tonumber(header[1])
		table.remove(header, 1)
		local content = value:sub(header_end + 1)
		return version, header, content
	end
	-- Old versions that didn't include a header with a version number
	if value:find("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)") and not value:find("%{") then -- List format
		return 3, nil, value
	elseif value:find("^[^\"']+%{%d+%}") then
		if value:find("%[\"meta\"%]") then -- Meta flat table format
			return 2, nil, value
		end
		return 1, nil, value -- Flat table format
	elseif value:find("%{") then -- Raw nested table format
		return 4, nil, value
	end
	return nil
end


--- Converts the region defined by positions `pos1` and `pos2`
-- into a single string.
-- @return The serialized data.
-- @return The number of nodes serialized.
function worldedit.serialize(pos1, pos2)
	-- Keep area loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local count = 0
	local result = {}
	local get_node, get_meta = minetest.get_node, minetest.get_meta
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then
					count = count + 1
					local meta = get_meta(pos):to_table()

					local meta_empty = true
					-- Convert metadata item stacks to item strings
					for name, inventory in pairs(meta.inventory) do
						for index, stack in ipairs(inventory) do
							meta_empty = false
							inventory[index] = stack.to_string and stack:to_string() or stack
						end
					end
					for k in pairs(meta) do
						if k ~= "inventory" then
							meta_empty = false
							break
						end
					end

					result[count] = {
						x = pos.x - pos1.x,
						y = pos.y - pos1.y,
						z = pos.z - pos1.z,
						name = node.name,
						param1 = node.param1 ~= 0 and node.param1 or nil,
						param2 = node.param2 ~= 0 and node.param2 or nil,
						meta = not meta_empty and meta or nil,
					}
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	-- Serialize entries
	result = minetest.serialize(result)
	return LATEST_SERIALIZATION_HEADER .. result, count
end


--- Loads the schematic in `value` into a node list in the latest format.
-- Contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile)
-- by ChillCode, available under the MIT license.
-- @return A node list in the latest format, or nil on failure.
function worldedit.load_schematic(value)
	local version, header, content = worldedit.read_header(value)
	local nodes = {}
	if version == 1 or version == 2 then -- Original flat table format
		local tables = minetest.deserialize(content)
		if not tables then return nil end

		-- Transform the node table into an array of nodes
		for i = 1, #tables do
			for j, v in pairs(tables[i]) do
				if type(v) == "table" then
					tables[i][j] = tables[v[1]]
				end
			end
		end
		nodes = tables[1]

		if version == 1 then --original flat table format
			for i, entry in ipairs(nodes) do
				local pos = entry[1]
				entry.x, entry.y, entry.z = pos.x, pos.y, pos.z
				entry[1] = nil
				local node = entry[2]
				entry.name, entry.param1, entry.param2 = node.name, node.param1, node.param2
				entry[2] = nil
			end
		end
	elseif version == 3 then -- List format
		for x, y, z, name, param1, param2 in content:gmatch(
				"([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+" ..
				"([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do
			param1, param2 = tonumber(param1), tonumber(param2)
			table.insert(nodes, {
				x = originx + tonumber(x),
				y = originy + tonumber(y),
				z = originz + tonumber(z),
				name = name,
				param1 = param1 ~= 0 and param1 or nil,
				param2 = param2 ~= 0 and param2 or nil,
			})
		end
	elseif version == 4 or version == 5 then -- Nested table format
		if not jit then
			-- This is broken for larger tables in the current version of LuaJIT
			nodes = minetest.deserialize(content)
		else
			-- XXX: This is a filthy hack that works surprisingly well - in LuaJIT, `minetest.deserialize` will fail due to the register limit
			nodes = {}
			value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1) -- remove the starting and ending values to leave only the node data
			local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
			local startpos, startpos1, endpos = 1, 1
			while true do -- go through each individual node entry (except the last)
				startpos, endpos = escaped:find("},%s*{", startpos)
				if not startpos then
					break
				end
				local current = value:sub(startpos1, startpos)
				local entry = minetest.deserialize("return " .. current)
				table.insert(nodes, entry)
				startpos, startpos1 = endpos, endpos
			end
			local entry = minetest.deserialize("return " .. value:sub(startpos1)) -- process the last entry
			table.insert(nodes, entry)
		end
	else
		return nil
	end
	return nodes
end

--- Determines the volume the nodes represented by string `value` would occupy
-- if deserialized at `origin_pos`.
-- @return Low corner position.
-- @return High corner position.
-- @return The number of nodes.
worldedit.allocate = function(origin_pos, value)
	local nodes = worldedit.load_schematic(value)
	if not nodes then return nil end
	return worldedit.allocate_with_nodes(origin_pos, nodes)
end


-- Internal
worldedit.allocate_with_nodes = function(origin_pos, nodes)
	local huge = math.huge
	local pos1x, pos1y, pos1z = huge, huge, huge
	local pos2x, pos2y, pos2z = -huge, -huge, -huge
	local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
	for i, entry in ipairs(nodes) do
		local x, y, z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
		if x < pos1x then pos1x = x end
		if y < pos1y then pos1y = y end
		if z < pos1z then pos1z = z end
		if x > pos2x then pos2x = x end
		if y > pos2y then pos2y = y end
		if z > pos2z then pos2z = z end
	end
	local pos1 = {x=pos1x, y=pos1y, z=pos1z}
	local pos2 = {x=pos2x, y=pos2y, z=pos2z}
	return pos1, pos2, #nodes
end


--- Loads the nodes represented by string `value` at position `origin_pos`.
-- @return The number of nodes deserialized.
worldedit.deserialize = function(origin_pos, value)
	local nodes = worldedit.load_schematic(value)
	if not nodes then return nil end

	-- Make area stay loaded
	local pos1, pos2 = worldedit.allocate_with_nodes(origin_pos, nodes)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local origin_x, origin_y, origin_z = origin_pos.x, origin_pos.y, origin_pos.z
	local count = 0
	local add_node, get_meta = minetest.add_node, minetest.get_meta
	for i, entry in ipairs(nodes) do
		entry.x, entry.y, entry.z = origin_x + entry.x, origin_y + entry.y, origin_z + entry.z
		-- Entry acts as both position and node
		add_node(entry, entry)
		if entry.meta then
			get_meta(entry):from_table(entry.meta)
		end
	end
	return #nodes
end

