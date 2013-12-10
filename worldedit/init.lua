worldedit = worldedit or {}
worldedit.version = {major=1, minor=0}
worldedit.version_string = "1.0"

assert(minetest.get_voxel_manip, string.rep(">", 300) .. "HEY YOU! YES, YOU OVER THERE. THIS VERSION OF WORLDEDIT REQUIRES MINETEST 0.4.8 OR LATER! YOU HAVE AN OLD VERSION." .. string.rep("<", 300))

local path = minetest.get_modpath(minetest.get_current_modname())

local loadmodule = function(path)
	local file = io.open(path)
	if not file then
		return
	end
	file:close()
	return dofile(path)
end

loadmodule(path .. "/manipulations.lua")
loadmodule(path .. "/primitives.lua")
loadmodule(path .. "/visualization.lua")
loadmodule(path .. "/serialization.lua")
loadmodule(path .. "/code.lua")
loadmodule(path .. "/compatibility.lua")

print("[MOD] WorldEdit loaded!")
