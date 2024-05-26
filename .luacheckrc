read_globals = {
	"minetest", "VoxelArea", "ItemStack",
	"unified_inventory", "sfinv", "smart_inventory", "inventory_plus",
	"dump",

	table = {fields = {"copy", "indexof", "insert_all"}},
	vector = {fields = {
		-- as of 5.0
		"new", "direction", "distance", "length", "normalize", "floor", "round",
		"apply", "equals", "sort", "add", "subtract", "multiply", "divide",
		-- polyfilled
		"copy"
	}},
}
globals = {"worldedit"}

-- Ignore these errors until someone decides to fix them
ignore = {"212", "213", "411", "412", "421", "422", "431", "432", "631"}

files["worldedit/common.lua"] = {
	globals = {"vector"},
}
files["worldedit/test"] = {
	read_globals = {"testnode1", "testnode2", "testnode3", "area", "check", "place_pattern"},
}
files["worldedit/test/init.lua"] = {
	globals = {"testnode1", "testnode2", "testnode3", "area", "check", "place_pattern"},
}
