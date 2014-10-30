--- Lua code execution functions.
-- @module worldedit.code

--- Executes `code` as a Lua chunk in the global namespace.
-- @return An error message if the code fails, or nil on success.
function worldedit.lua(code)
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


--- Executes `code` as a Lua chunk in the global namespace with the variable
-- pos available, for each node in a region defined by positions `pos1` and
-- `pos2`.
-- @return An error message if the code fails, or nil on success.
function worldedit.luatransform(pos1, pos2, code)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	local factory, err = loadstring("return function(pos) " .. code .. " end")
	if not factory then  -- Syntax error
		return err
	end
	local func = factory()

	worldedit.keep_loaded(pos1, pos2)

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

