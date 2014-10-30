--- Compatibility functions.
-- @module worldedit.compatibility

local function deprecated(new_func)
	local info = debug.getinfo(1, "n")
	local msg = "worldedit." .. info.name .. "() is deprecated."
	if new_func then
		msg = msg .. "  Use worldedit." .. new_func .. "() instead."
	end
	minetest.log("deprecated", msg)
end

worldedit.allocate_old = worldedit.allocate

worldedit.deserialize_old = worldedit.deserialize

function worldedit.metasave(pos1, pos2, filename)
	deprecated("save")
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data, count = worldedit.serialize(pos1, pos2)
	file:write(data)
	file:close()
	return count
end

function worldedit.metaload(originpos, filename)
	deprecated("load")
	filename = minetest.get_worldpath() .. "/schems/" .. file .. ".wem"
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data = file:read("*a")
	return worldedit.deserialize(originpos, data)
end

function worldedit.scale(pos1, pos2, factor)
	deprecated("stretch")
	return worldedit.stretch(pos1, pos2, factor, factor, factor)
end

function worldedit.valueversion(value)
	deprecated("read_header")
	local version = worldedit.read_header(value)
	if not version or version > worldedit.LATEST_SERIALIZATION_VERSION then
		return 0
	end
	return version
end

function worldedit.replaceinverse(pos1, pos2, search_node, replace_node)
	deprecated("replace")
	return worldedit.replace(pos1, pos2, search_node, replace_node, true)
end

function worldedit.clearobjects(...)
	deprecated("clear_objects")
	return worldedit.clear_objects(...)
end

function worldedit.hollow_sphere(pos, radius, node_name)
	deprecated("sphere")
	return worldedit.sphere(pos, radius, node_name, true)
end

function worldedit.hollow_dome(pos, radius, node_name)
	deprecated("dome")
	return worldedit.dome(pos, radius, node_name, true)
end

function worldedit.hollow_cylinder(pos, axis, length, radius, node_name)
	deprecated("cylinder")
	return worldedit.cylinder(pos, axis, length, radius, node_name, true)
end

