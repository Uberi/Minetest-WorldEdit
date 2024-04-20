--- Lua code execution functions.
-- @module worldedit.code

--- Executes `code` as a Lua chunk in the global namespace.
-- the code will be encapsulated into a function with parameters
--  * name (the name of the player issuing the //lua command)
--  * player (the player object of the player)
--  * pos (the position of the player rounded to integers)
-- @return string in case of error, tuple of nil, return of code as string in case of success
function worldedit.lua(code, name)
	local factory, err = loadstring("return function(name, player, pos)\n" .. code .. "\nend")
	if not factory then -- Syntax error
		return err
	end
	local func = factory()
	local player, pos
	if name then
		player = minetest.get_player_by_name(name)
		if player then
			pos = vector.round(player:get_pos())
		end
	end
	local good, err = pcall(func, name, player, pos)
	if not good then -- Runtime error
		return tostring(err)
	end
	return nil, dump(err)
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

	local pos = vector.new(pos1.x, 0, 0)
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local good, err = pcall(func, pos)
				if not good then -- Runtime error
					return tostring(err)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return nil
end

