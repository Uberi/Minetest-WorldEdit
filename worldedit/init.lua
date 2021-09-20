--- WorldEdit mod for the Minetest engine
-- @module worldedit
-- @release 1.3
-- @copyright 2012 sfan5, Anthony Zhang (Uberi/Temperest), and Brett O'Donnell (cornernote)
-- @license GNU Affero General Public License version 3 (AGPLv3)
-- @author sfan5
-- @author Anthony Zang (Uberi/Temperest)
-- @author Bret O'Donnel (cornernote)
-- @author ShadowNinja


worldedit = {}

local ver = {major=1, minor=3}
worldedit.version = ver
worldedit.version_string = string.format("%d.%d", ver.major, ver.minor)

local path = minetest.get_modpath(minetest.get_current_modname())

local function load_module(path)
	local file = io.open(path, "r")
	if not file then return end
	file:close()
	return dofile(path)
end

dofile(path .. "/common.lua")
load_module(path .. "/manipulations.lua")
load_module(path .. "/primitives.lua")
load_module(path .. "/visualization.lua")
load_module(path .. "/serialization.lua")
load_module(path .. "/code.lua")
load_module(path .. "/compatibility.lua")
load_module(path .. "/cuboid.lua")


if minetest.settings:get_bool("log_mods") then
	print("[WorldEdit] Loaded!")
end

if minetest.settings:get_bool("worldedit_run_tests") then
	dofile(path .. "/test.lua")
	minetest.after(0, worldedit.run_tests)
end
