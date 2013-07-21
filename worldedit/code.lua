worldedit = worldedit or {}
local minetest = minetest --local copy of global

--executes `code` as a Lua chunk in the global namespace, returning an error if the code fails or nil otherwise
worldedit.lua = function(code)
	local operation, message = loadstring(code)
	if operation == nil then --code parsing failed
		return message
	end
	local status, message = pcall(operation)
	if status == nil then --operation failed
		return message
	end
	return nil
end

--executes `code` as a Lua chunk in the global namespace with the variable pos available, for each node in a region defined by positions `pos1` and `pos2`, returning an error if the code fails or nil otherwise
worldedit.luatransform = function(pos1, pos2, code)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local factory, message = loadstring("return function(pos) " .. code .. " end")
	if factory == nil then --code parsing failed
		return message
	end
	local operation = factory()

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local status, message = pcall(operation, pos)
				if status == nil then --operation failed
					return message
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return nil
end