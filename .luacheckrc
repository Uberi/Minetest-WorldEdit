read_globals = {"minetest", "vector", "VoxelArea", "ItemStack",
	"table",
	"unified_inventory", "sfinv", "smart_inventory", "inventory_plus",
	"dump"
}
globals = {"worldedit"}
-- Ignore these errors until someone decides to fix them
ignore = {"212", "213", "411", "412", "421", "422", "431", "432", "631"}

files["worldedit/test"] = {
	read_globals = {"testnode1", "testnode2", "testnode3", "area", "check", "place_pattern"},
}
files["worldedit/test/init.lua"] = {
	globals = {"testnode1", "testnode2", "testnode3", "area", "check", "place_pattern"},
}
