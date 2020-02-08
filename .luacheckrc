unused_args = false
allow_defined_top = true
max_line_length = 999

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "vector", "unified_inventory",
    "smart_inventory", "sfinv",

    "VoxelArea", "inventory_plus",
    "ItemStack", "minetest",
}
