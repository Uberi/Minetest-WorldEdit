local path = minetest.get_modpath(minetest.get_current_modname())

local loadmodule = function(path)
	local results = {pcall(function()
		return dofile(path)
	end)}
	if results[1] then --successfully loaded module
		table.remove(results, 1) --remove status indicator
		return unpack(results) --return all results
	else --load error
		print(results[2])
	end
end

loadmodule(path .. "/manipulations.lua")
loadmodule(path .. "/primitives.lua")
loadmodule(path .. "/visualization.lua")
loadmodule(path .. "/serialization.lua")
loadmodule(path .. "/code.lua")
loadmodule(path .. "/compatibility.lua")
loadmodule(path .. "/queue.lua")
