local path = minetest.get_modpath("worldedit")

local loadmodule = function(path)
	return pcall(function()
		dofile(path)
	end)
end

loadmodule(path .. "/manipulations.lua")
loadmodule(path .. "/primitives.lua")
loadmodule(path .. "/visualization.lua")
loadmodule(path .. "/serialization.lua")
loadmodule(path .. "/code.lua")
loadmodule(path .. "/compatibility.lua")
loadmodule(path .. "/queue.lua")
