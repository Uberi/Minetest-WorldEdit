--- Schematic serialization and deserialiation.
-- @module worldedit.serialization

worldedit.LATEST_SERIALIZATION_VERSION = 6

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
  6: Much more complicated but also better format
--]]


--- Reads the header of serialized data.
-- @param value Serialized WorldEdit data.
-- @return The version as a positive natural number, or 0 for unknown versions.
-- @return Extra header fields as a list of strings, or nil if not supported.
-- @return Content (data after header).
function worldedit.read_header(value)
	if value:find("^[0-9]+[,:]") then
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
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local get_node, get_meta, hash_node_position =
		minetest.get_node, minetest.get_meta, minetest.hash_node_position

	-- Find the positions which have metadata
	local has_meta = {}
	local meta_positions = minetest.find_nodes_with_meta(pos1, pos2)
	for i = 1, #meta_positions do
		has_meta[hash_node_position(meta_positions[i])] = true
	end

	-- Decide axis of saved rows
	local dim = vector.add(vector.subtract(pos2, pos1), 1)
	local axis
	if dim.x * dim.y < math.min(dim.y * dim.z, dim.x * dim.z) then
		axis = "z"
	elseif dim.x * dim.z < math.min(dim.x * dim.y, dim.y * dim.z) then
		axis = "y"
	elseif dim.y * dim.z < math.min(dim.x * dim.y, dim.x * dim.z) then
		axis = "x"
	else
		axis = "x" -- X or Z are usually most efficient
	end
	local other1, other2 = worldedit.get_axis_others(axis)

	-- Helper functions (1)
	local MATCH_DIST = 8
	local function match_init(array, first_value)
		array[1] = first_value
		return {first_value}
	end
	local function match_try(cache, prev_pushed, value)
		local i = #cache
		while i >= 1 do
			if cache[i] == value then
				local ret = -(#cache - i + 1)
				local was_value = type(prev_pushed) ~= "number" or prev_pushed >= 0
				return ret, (was_value and ret == -1) or prev_pushed == ret
			end
			i = i - 1
		end
		return nil, false
	end
	local function match_push(cache, match, value)
		if match ~= nil then -- don't advance cache
			return match
		end
		local idx = #cache + 1
		cache[idx] = value
		if idx > MATCH_DIST then
			table.remove(cache, 1)
		end
		return value
	end
	-- Helper functions (2)
	local function cur_new(pos, pos1)
		return {
			a = axis,
			p = {pos.x - pos1.x, pos.y - pos1.y, pos.z - pos1.z},
			c = 1,
			data = {},
			param1 = {},
			param2 = {},
			meta = {},
		}
	end
	local function is_emptyish(t)
		-- returns true if <t> contains only one element and that one element is == 0
		local seen = false
		for _, value in pairs(t) do
			if not seen then
				if value ~= 0 then
					return false
				end
				seen = true
			else
				return false
			end
		end
		return true
	end
	local function cur_finish(result, cur)
		if is_emptyish(cur.param1) then
			cur.param1 = nil
		end
		if is_emptyish(cur.param2) then
			cur.param2 = nil
		end
		if next(cur.meta) == nil then
			cur.meta = nil
		end
		result[#result + 1] = cur
	end

	-- Serialize stuff
	local pos = {}
	local count = 0
	local result = {}
	local cur
	local cache_data, cache_param1, cache_param2
	local prev_data, prev_param1, prev_param2
	pos[other1] = pos1[other1]
	while pos[other1] <= pos2[other1] do
		pos[other2] = pos1[other2]
		while pos[other2] <= pos2[other2] do
			pos[axis] = pos1[axis]
			while pos[axis] <= pos2[axis] do

				local node = get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then

					local meta
					if has_meta[hash_node_position(pos)] then
						meta = get_meta(pos):to_table()

						-- Convert metadata item stacks to item strings
						for _, invlist in pairs(meta.inventory) do
							for index = 1, #invlist do
								local itemstack = invlist[index]
								if itemstack.to_string then
									invlist[index] = itemstack:to_string()
								end
							end
						end
					end

					if cur == nil then -- Start a new row
						cur = cur_new(pos, pos1, axis, other1, other2)

						cache_data = match_init(cur.data, node.name)
						cache_param1 = match_init(cur.param1, node.param1)
						cache_param2 = match_init(cur.param2, node.param2)
						prev_data = cur.data[1]
						prev_param1 = cur.param1[1]
						prev_param2 = cur.param2[1]

						cur.meta[1] = meta
					else -- Append to existing row
						local next_c = cur.c + 1
						cur.c = next_c
						local value, m, can_omit

						value = node.name
						m, can_omit = match_try(cache_data, prev_data, node.name)
						if not can_omit then
							 prev_data = match_push(cache_data, m, value)
							 cur.data[next_c] = prev_data
						end

						value = node.param1
						m, can_omit = match_try(cache_param1, prev_param1, value)
						if not can_omit then
							prev_param1 = match_push(cache_param1, m, value)
							cur.param1[next_c] = prev_param1
						end

						value = node.param2
						m, can_omit = match_try(cache_param2, prev_param2, value)
						if not can_omit then
							prev_param2 = match_push(cache_param2, m, value)
							cur.param2[next_c] = prev_param2
						end

						cur.meta[next_c] = meta
					end
					count = count + 1
				else
					if cur ~= nil then -- Finish row
						cur_finish(result, cur)
						cur = nil
					end
				end
				pos[axis] = pos[axis] + 1

			end
			if cur ~= nil then -- Finish leftover row
				cur_finish(result, cur)
				cur = nil
			end
			pos[other2] = pos[other2] + 1
		end
		pos[other1] = pos[other1] + 1
	end

	-- Serialize entries
	result = minetest.serialize(result)
	return tonumber(worldedit.LATEST_SERIALIZATION_VERSION) .. "," ..
		string.format("%d,%d,%d:", dim.x, dim.y, dim.z) .. result, count
end

-- Contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile)
-- by ChillCode, available under the MIT license.
local function deserialize_workaround(content)
	local nodes
	if not minetest.global_exists("jit") then
		nodes = minetest.deserialize(content, true)
	else
		-- XXX: This is a filthy hack that works surprisingly well
		-- in LuaJIT, `minetest.deserialize` will fail due to the register limit
		nodes = {}
		content = content:gsub("^%s*return%s*{", "", 1):gsub("}%s*$", "", 1) -- remove the starting and ending values to leave only the node data
		-- remove string contents strings while preserving their length
		local escaped = content:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
		local startpos, startpos1 = 1, 1
		local endpos
		while true do -- go through each individual node entry (except the last)
			startpos, endpos = escaped:find("},%s*{", startpos)
			if not startpos then
				break
			end
			local current = content:sub(startpos1, startpos)
			local entry = minetest.deserialize("return " .. current, true)
			table.insert(nodes, entry)
			startpos, startpos1 = endpos, endpos
		end
		local entry = minetest.deserialize("return " .. content:sub(startpos1), true) -- process the last entry
		table.insert(nodes, entry)
	end
	return nodes
end

--- Loads the schematic in `value` into a node list in the latest format.
-- @return A node list in the latest format, or nil on failure.
local function legacy_load_schematic(version, header, content)
	local nodes = {}
	if version == 1 or version == 2 then -- Original flat table format
		local tables = minetest.deserialize(content, true)
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
				x = tonumber(x),
				y = tonumber(y),
				z = tonumber(z),
				name = name,
				param1 = param1 ~= 0 and param1 or nil,
				param2 = param2 ~= 0 and param2 or nil,
			})
		end
	elseif version == 4 or version == 5 then -- Nested table format
		nodes = deserialize_workaround(content)
	elseif version >= 6 then
		error("legacy_load_schematic called for non-legacy schematic")
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
function worldedit.allocate(origin_pos, value)
	local version, header, content = worldedit.read_header(value)
	if version == 6 then
		local content = deserialize_workaround(content)
		local pos2 = {
			x = origin_pos.x + tonumber(header[1]),
			y = origin_pos.y + tonumber(header[2]),
			z = origin_pos.z + tonumber(header[3]),
		}
		local count = 0
		for _, row in ipairs(content) do
			count = count + row.c
		end
		return origin_pos, pos2, count
	else
		local nodes = legacy_load_schematic(version, header, content)
		if not nodes or #nodes == 0 then return nil end
		return worldedit.legacy_allocate_with_nodes(origin_pos, nodes)
	end
end


-- Internal
function worldedit.legacy_allocate_with_nodes(origin_pos, nodes)
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
function worldedit.deserialize(origin_pos, value)
	local version, header, content = worldedit.read_header(value)
	if version == 6 then
		local content = deserialize_workaround(content)
		local pos2 = {
			x = origin_pos.x + tonumber(header[1]),
			y = origin_pos.y + tonumber(header[2]),
			z = origin_pos.z + tonumber(header[3]),
		}
		worldedit.keep_loaded(origin_pos, pos2)

		return worldedit.deserialize_with_content(origin_pos, content)
	else
		local nodes = legacy_load_schematic(version, header, content)
		if not nodes or #nodes == 0 then return nil end

		local pos1, pos2 = worldedit.legacy_allocate_with_nodes(origin_pos, nodes)
		worldedit.keep_loaded(pos1, pos2)

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
end

-- Internal
function worldedit.deserialize_with_content(origin_pos, content)
	-- Helper functions
	local function resolve_refs(array)
		-- find (and cache) highest index
		local max_i = 1
		for i, _ in pairs(array) do
			if i > max_i then max_i = i end
		end
		array.max_i = max_i
		-- resolve references
		local cache = {}
		for i = 1, max_i do
			local v = array[i]
			if v ~= nil then
				if type(v) == "number" and v < 0 then -- is a reference
					array[i] = cache[#cache + v + 1]
				else
					cache[#cache + 1] = v
				end
			end
		end
	end
	local function read_in_array(array, idx)
		if idx > array.max_i then
			return array[array.max_i]
		end
		-- go backwards until we find something
		repeat
			local v = array[idx]
			if v ~= nil then
				return v
			end
			idx = idx - 1
		until idx == 0
		assert(false)
	end

	-- Actually deserialize
	local count = 0
	local entry = {}
	local add_node, get_meta = minetest.add_node, minetest.get_meta
	for _, row in ipairs(content) do
		local axis = row.a
		local pos = {
			x = origin_pos.x + row.p[1],
			y = origin_pos.y + row.p[2],
			z = origin_pos.z + row.p[3],
		}
		if row.param1 == nil then row.param1 = {0} end
		if row.param2 == nil then row.param2 = {0} end
		if row.meta == nil then row.meta = {} end
		resolve_refs(row.data)
		resolve_refs(row.param1)
		resolve_refs(row.param2)

		for i = 1, row.c do
			entry.name = read_in_array(row.data, i)
			entry.param1 = read_in_array(row.param1, i)
			entry.param2 = read_in_array(row.param2, i)
			add_node(pos, entry)

			local meta = row.meta[i]
			if meta then
				get_meta(pos):from_table(meta)
			end

			pos[axis] = pos[axis] + 1
		end

		count = count + row.c
	end
	return count
end
