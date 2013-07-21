local path = minetest.get_modpath(minetest.get_current_modname())

local loadmodule = function(path)
	return pcall(function()
		return dofile(path)
	end)
end

loadmodule(path .. "/manipulations.lua")
loadmodule(path .. "/primitives.lua")
loadmodule(path .. "/visualization.lua")
loadmodule(path .. "/serialization.lua")
loadmodule(path .. "/code.lua")
loadmodule(path .. "/compatibility.lua")
loadmodule(path .. "/queue.lua")
