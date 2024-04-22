local S = minetest.get_translator("worldedit_commands")


local check_cube = function(param)
	local found, _, w, h, l, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(w), tonumber(h), tonumber(l), node
end

worldedit.register_command("hollowcube", {
	params = "<width> <height> <length> <node>",
	description = S("Add a hollow cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>."),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node, true)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("cube", {
	params = "<width> <height> <length> <node>",
	description = S("Add a cube with its ground level centered at WorldEdit position 1 with dimensions <width> x <height> x <length>, composed of <node>."),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cube,
	nodes_needed = function(name, w, h, l, node)
		return w * h * l
	end,
	func = function(name, w, h, l, node)
		local count = worldedit.cube(worldedit.pos1[name], w, h, l, node)
		return true, S("@1 nodes added", count)
	end,
})

local check_sphere = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowsphere", {
	params = "<radius> <node>",
	description = S("Add hollow sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node, true)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("sphere", {
	params = "<radius> <node>",
	description = S("Add sphere centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_sphere,
	nodes_needed = function(name, radius, node)
		return math.ceil((4 * math.pi * (radius ^ 3)) / 3) --volume of sphere
	end,
	func = function(name, radius, node)
		local count = worldedit.sphere(worldedit.pos1[name], radius, node)
		return true, S("@1 nodes added", count)
	end,
})

local check_dome = function(param)
	local found, _, radius, nodename = param:find("^(%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, tonumber(radius), node
end

worldedit.register_command("hollowdome", {
	params = "<radius> <node>",
	description = S("Add hollow dome centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node, true)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("dome", {
	params = "<radius> <node>",
	description = S("Add dome centered at WorldEdit position 1 with radius <radius>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_dome,
	nodes_needed = function(name, radius, node)
		return math.ceil((2 * math.pi * (radius ^ 3)) / 3) --volume of dome
	end,
	func = function(name, radius, node)
		local count = worldedit.dome(worldedit.pos1[name], radius, node)
		return true, S("@1 nodes added", count)
	end,
})

local check_cylinder = function(param)
	-- two radii
	local found, _, axis, length, radius1, radius2, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
	if found == nil then
		-- single radius
		found, _, axis, length, radius1, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(%d+)%s+(.+)$")
		radius2 = radius1
	end
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, axis, tonumber(length), tonumber(radius1), tonumber(radius2), node
end

worldedit.register_command("hollowcylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = S("Add hollow cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node, true)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("cylinder", {
	params = "x/y/z/? <length> <radius1> [radius2] <node>",
	description = S("Add cylinder at WorldEdit position 1 along the given axis with length <length>, base radius <radius1> (and top radius [radius2]), composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_cylinder,
	nodes_needed = function(name, axis, length, radius1, radius2, node)
		local radius = math.max(radius1, radius2)
		return math.ceil(math.pi * (radius ^ 2) * length)
	end,
	func = function(name, axis, length, radius1, radius2, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			length = length * sign
		end
		local count = worldedit.cylinder(worldedit.pos1[name], axis, length, radius1, radius2, node)
		return true, S("@1 nodes added", count)
	end,
})

local check_pyramid = function(param)
	local found, _, axis, height, nodename = param:find("^([xyz%?])%s+([+-]?%d+)%s+(.+)$")
	if found == nil then
		return false
	end
	local node = worldedit.normalize_nodename(nodename)
	if not node then
		return false, S("invalid node name: @1", nodename)
	end
	return true, axis, tonumber(height), node
end

worldedit.register_command("hollowpyramid", {
	params = "x/y/z/? <height> <node>",
	description = S("Add hollow pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node, true)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("pyramid", {
	params = "x/y/z/? <height> <node>",
	description = S("Add pyramid centered at WorldEdit position 1 along the given axis with height <height>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = check_pyramid,
	nodes_needed = function(name, axis, height, node)
		return math.ceil(((height * 2 + 1) ^ 2) * height / 3)
	end,
	func = function(name, axis, height, node)
		if axis == "?" then
			local sign
			axis, sign = worldedit.player_axis(name)
			height = height * sign
		end
		local count = worldedit.pyramid(worldedit.pos1[name], axis, height, node)
		return true, S("@1 nodes added", count)
	end,
})

worldedit.register_command("spiral", {
	params = "<length> <height> <space> <node>",
	description = S("Add spiral centered at WorldEdit position 1 with side length <length>, height <height>, space between walls <space>, composed of <node>"),
	category = S("Shapes"),
	privs = {worldedit=true},
	require_pos = 1,
	parse = function(param)
		local found, _, length, height, space, nodename = param:find("^(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
		if found == nil then
			return false
		end
		local node = worldedit.normalize_nodename(nodename)
		if not node then
			return false, S("invalid node name: @1", nodename)
		end
		return true, tonumber(length), tonumber(height), tonumber(space), node
	end,
	nodes_needed = function(name, length, height, space, node)
		return (length + space) * height -- TODO: this is not the upper bound
	end,
	func = function(name, length, height, space, node)
		local count = worldedit.spiral(worldedit.pos1[name], length, height, space, node)
		return true, S("@1 nodes added", count)
	end,
})
