local register_test = worldedit.register_test
local types = {
	{"facedir", 24, 32, 0},
	{"colorfacedir", 24, 32, 224},
	{"wallmounted", 6, 8, 0},
	{"colorwallmounted", 6, 8, 248},
}
for _, spec in ipairs(types) do
	minetest.register_node("worldedit:test_" .. spec[1], {
		description = "Orientation test node",
		paramtype2 = spec[1],
		wallmounted_rotate_vertical = spec[2] == 6,
		groups = {not_in_creative_inventory = 1},
	})
end

local tops = {
	vector.new(0, 1, 0), vector.new(0, 0, 1), vector.new(0, 0, -1),
	vector.new(1, 0, 0), vector.new(-1, 0, 0), vector.new(0, -1, 0),
}
local function transform_dir(dir, operation, axis, angle)
	local out = vector.copy(dir)
	if operation == "flip" then
		out[axis] = -out[axis]
	else
		for _ = 1, (angle % 360) / 90 do
			if axis == "x" then
				out.y, out.z = out.z, -out.y
			elseif axis == "y" then
				out.x, out.z = out.z, -out.x
			else
				out.x, out.y = out.y, -out.x
			end
		end
	end
	return out
end

local function check_orientation(spec, old, node, operation, axis, angle)
	local orient = node.param2 % spec[3]
	local context = spec[1] .. " " .. operation .. " " .. axis .. " " .. angle .. " param2=" .. old
	assert(node.name == "worldedit:test_" .. spec[1], context .. ": node misplaced")
	assert(node.param2 - orient == spec[4], context .. ": palette changed")
	if spec[2] == 24 then
		assert(orient < 24, context .. ": invalid facedir")
		assert(vector.equals(minetest.facedir_to_dir(orient),
			transform_dir(minetest.facedir_to_dir(old), operation, axis, angle)), context .. ": front")
		assert(vector.equals(tops[math.floor(orient / 4) + 1],
			transform_dir(tops[math.floor(old / 4) + 1], operation, axis, angle)), context .. ": top")
	else
		assert(vector.equals(minetest.wallmounted_to_dir(orient),
			transform_dir(minetest.wallmounted_to_dir(old), operation, axis, angle)), context .. ": mounting direction")
	end
end

register_test("Transformations")
for _, operation in ipairs({"rotate", "flip"}) do
	register_test("worldedit." .. operation .. " orientations", function()
		local pos1, pos2 = area.get(3)
		local center = vector.add(pos1, 1)
		local offset = vector.new(1, -1, 0)
		local source = vector.add(center, offset)
		for _, axis in ipairs({"x", "y", "z"}) do
		for _, angle in ipairs(operation == "rotate" and {90, 180, 270, -90} or {0}) do
		for _, spec in ipairs(types) do
		for old = 0, spec[2] - 1 do
			worldedit.set(pos1, pos2, "air")
			minetest.set_node(source, {name = "worldedit:test_" .. spec[1], param2 = spec[4] + old})
			local token = spec[1] .. operation .. axis .. angle .. ":" .. old
			minetest.get_meta(source):set_string("test", token)
			if operation == "rotate" then
				worldedit.rotate(pos1, pos2, axis, angle, true)
			else
				worldedit.flip(pos1, pos2, axis, true)
			end
			local dest = vector.add(center, transform_dir(offset, operation, axis, angle))
			check_orientation(spec, old, minetest.get_node(dest), operation, axis, angle)
			assert(minetest.get_meta(dest):get_string("test") == token)
		end
		end
		end
		end
	end)
end

register_test("worldedit.orient legacy API", function()
	local pos = area.get(1)
	minetest.set_node(pos, {name = "worldedit:test_colorfacedir", param2 = 224})
	minetest.get_meta(pos):set_string("test", "preserved")
	assert(worldedit.orient(pos, pos, 90) == 1)
	assert(minetest.get_node(pos).param2 == 225)
	assert(minetest.get_meta(pos):get_string("test") == "preserved")
	assert(worldedit.orient(pos, pos, 360) == 0)
	assert(minetest.get_node(pos).param2 == 225)
end)

register_test("worldedit.orient directions", function()
	local pos = area.get(1)
	for _, operation in ipairs({"rotate", "flip"}) do
	for _, axis in ipairs({"x", "y", "z"}) do
	for _, angle in ipairs(operation == "rotate" and {90, 180, 270, -90} or {0}) do
	for _, spec in ipairs(types) do
	for old = 0, spec[2] - 1 do
		minetest.set_node(pos, {name = "worldedit:test_" .. spec[1], param2 = spec[4] + old})
		minetest.get_meta(pos):set_string("test", "preserved")
		assert(worldedit.orient(pos, pos, operation, axis, angle) == 1)
		check_orientation(spec, old, minetest.get_node(pos), operation, axis, angle)
		assert(minetest.get_meta(pos):get_string("test") == "preserved")
	end
	end
	end
	end
	end
end)

register_test("worldedit transforms legacy API", function()
	local pos1, pos2 = area.get(3)
	local center = vector.add(pos1, 1)
	local offset = vector.new(1, -1, 0)
	for _, axis in ipairs({"x", "y", "z"}) do
	for _, operation in ipairs({"rotate", "flip"}) do
	for _, orient_nodes in ipairs({false, "omitted"}) do
		worldedit.set(pos1, pos2, "air")
		local source = vector.add(center, offset)
		minetest.set_node(source, {name = "worldedit:test_colorfacedir", param2 = 225})
		minetest.get_meta(source):set_string("test", "preserved")
		if operation == "rotate" then
			if orient_nodes == "omitted" then
				worldedit.rotate(pos1, pos2, axis, 90)
			else
				worldedit.rotate(pos1, pos2, axis, 90, false)
			end
		else
			if orient_nodes == "omitted" then
				worldedit.flip(pos1, pos2, axis)
			else
				worldedit.flip(pos1, pos2, axis, false)
			end
		end
		local dest = vector.add(center, transform_dir(offset, operation, axis, 90))
		assert(minetest.get_node(dest).param2 == 225)
		assert(minetest.get_meta(dest):get_string("test") == "preserved")
	end
	end
	end
end)

register_test("//rotate and //flip orientations", function()
	local name = "worldedit_orientation_test"
	local pos = area.get(1)
	for _, operation in ipairs({"rotate", "flip"}) do
	for _, axis in ipairs({"x", "y", "z"}) do
	for _, spec in ipairs(types) do
		worldedit.pos1[name], worldedit.pos2[name] = pos, pos
		minetest.set_node(pos, {name = "worldedit:test_" .. spec[1], param2 = spec[4] + 1})
		minetest.get_meta(pos):set_string("test", "preserved")
		assert(worldedit.registered_commands[operation].func(name, axis, 90))
		check_orientation(spec, 1, minetest.get_node(pos), operation, axis, 90)
		assert(minetest.get_meta(pos):get_string("test") == "preserved")
	end
	end
	end
	worldedit.pos1[name], worldedit.pos2[name] = nil, nil
	worldedit.marker_update(name)
end)

register_test("worldedit.rotate non-cubic region", function()
	local pos1, pos2 = area.get(2, 3, 4)
	local center = vector.divide(vector.add(pos1, pos2), 2)
	local offset = vector.subtract(pos2, center)
	for _, axis in ipairs({"x", "y", "z"}) do
	for _, angle in ipairs({90, 180, 270}) do
		worldedit.set(pos1, pos2, "air")
		minetest.set_node(pos2, {name = "worldedit:test_colorfacedir", param2 = 225})
		local token = axis .. angle
		minetest.get_meta(pos2):set_string("test", token)
		local _, newpos1, newpos2 = worldedit.rotate(pos1, pos2, axis, angle, true)
		local newcenter = vector.divide(vector.add(newpos1, newpos2), 2)
		local dest = vector.add(newcenter, transform_dir(offset, "rotate", axis, angle))
		check_orientation(types[2], 1, minetest.get_node(dest), "rotate", axis, angle)
		assert(minetest.get_meta(dest):get_string("test") == token)
		worldedit.set(newpos1, newpos2, "air")
	end
	end
end)

register_test("worldedit.orient unmapped wallmounted states", function()
	local pos = area.get(1)
	for _, spec in ipairs({types[3], types[4]}) do
	for old = 6, 7 do
	for _, axis in ipairs({"x", "y", "z"}) do
	for _, operation in ipairs({"rotate", "flip"}) do
	for _, angle in ipairs(operation == "rotate" and {90, 180, 270, -90} or {0}) do
		local node = {name = "worldedit:test_" .. spec[1], param2 = spec[4] + old}
		local token = spec[1] .. old .. axis .. operation .. angle
		minetest.set_node(pos, node)
		minetest.get_meta(pos):set_string("test", token)
		assert(worldedit.orient(pos, pos, operation, axis, angle) == 1)
		assert(minetest.get_node(pos).param2 == node.param2, token .. ": orientation lost")
		if operation == "flip" then
			worldedit.flip(pos, pos, axis, true)
			worldedit.flip(pos, pos, axis, true)
		else
			worldedit.rotate(pos, pos, axis, angle, true)
		end
		assert(minetest.get_node(pos).name == node.name)
		assert(minetest.get_node(pos).param2 == node.param2, token .. ": API orientation lost")
		assert(minetest.get_meta(pos):get_string("test") == token)
	end
	end
	end
		for _, angle in ipairs({90, 180, 270}) do
			minetest.set_node(pos, {name = "worldedit:test_" .. spec[1], param2 = spec[4] + old})
			assert(worldedit.orient(pos, pos, angle) == 1)
			assert(minetest.get_node(pos).param2 == spec[4] + old)
		end
	end
	end
end)
