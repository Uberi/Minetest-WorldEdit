worldedit = worldedit or {}

worldedit.allocate_old = worldedit.allocate
worldedit.deserialize_old = worldedit.deserialize
worldedit.metasave = function(pos1, pos2, filename)
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data, count = worldedit.serialize(pos1, pos2)
	file:write(data)
	file:close()
	return count
end
worldedit.metaload = function(originpos, filename)
	filename = minetest.get_worldpath() .. "/schems/" .. file .. ".wem"
	local file, err = io.open(filename, "wb")
	if err then return 0 end
	local data = file:read("*a")
	return worldedit.deserialize(originpos, data)
end