unused_args = false
allow_defined_top = true
max_line_length = 999

ignore = {
    "pos1", "pos2",
    "extent1", "extent2",
    "header", "count",

    "err", "state",
    "filename", "def",
    "file", "name",
}

globals = {
	"minetest"
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "vector", "unified_inventory",
    "smart_inventory", "sfinv",

    "VoxelArea", "inventory_plus",
    "ItemStack",
}
