worldedit = worldedit or {}
local minetest = minetest -- local copy of global

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

-- Executes `code` as a Lua chunk in the global namespace,
-- returning an error if the code fails, or nil otherwise.
worldedit.lua = function(code)
	local func, err = loadstring(code)
	if not func then  -- Syntax error
		return err
	end
	local good, err = pcall(func)
	if not good then  -- Runtime error
		return err
	end
	return nil
end

-- Executes `code` as a Lua chunk in the global namespace with the variable
-- pos available, for each node in a region defined by positions `pos1` and
-- `pos2`, returning an error if the code fails, or nil otherwise
worldedit.luatransform = function(pos1, pos2, code)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local factory, err = loadstring("return function(pos) " .. code .. " end")
	if not factory then  -- Syntax error
		return err
	end
	local func = factory()

	-- Keep area loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local good, err = pcall(func, pos)
				if not good then -- Runtime error
					return err
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return nil
end

