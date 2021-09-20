---------------------
-- Helpers
---------------------

local vec = vector.new
local vecw = function(axis, n, base)
	local ret = vec(base)
	ret[axis] = n
	return ret
end
local pos2str = minetest.pos_to_string
local get_node = minetest.get_node
local set_node = minetest.set_node

---------------------
-- Nodes
---------------------
local air = "air"
local testnode1
local testnode2
local testnode3
-- Loads nodenames to use for tests
local function init_nodes()
	testnode1 = minetest.registered_aliases["mapgen_stone"]
	testnode2 = minetest.registered_aliases["mapgen_dirt"]
	testnode3 = minetest.registered_aliases["mapgen_cobble"] or minetest.registered_aliases["mapgen_dirt_with_grass"]
	assert(testnode1 and testnode2 and testnode3)
end
-- Writes repeating pattern into given area
local function place_pattern(pos1, pos2, pattern)
	local pos = vec()
	local node = {name=""}
	local i = 1
	for z = pos1.z, pos2.z do
		pos.z = z
	for y = pos1.y, pos2.y do
		pos.y = y
	for x = pos1.x, pos2.x do
		pos.x = x
		node.name = pattern[i]
		set_node(pos, node)
		i = i % #pattern + 1
	end
	end
	end
end


---------------------
-- Area management
---------------------
assert(minetest.get_mapgen_setting("mg_name") == "singlenode")
local area = {}
do
	local areamin, areamax
	local off
	local c_air = minetest.get_content_id(air)
	local vbuffer = {}
	-- Assign a new area for use, will emerge and then call ready()
	area.assign = function(min, max, ready)
		areamin = min
		areamax = max
		minetest.emerge_area(min, max, function(bpos, action, remaining)
			assert(action ~= minetest.EMERGE_ERRORED)
			if remaining > 0 then return end
			minetest.after(0, function()
				area.clear()
				ready()
			end)
		end)
	end
	-- Reset area contents and state
	area.clear = function()
		local vmanip = minetest.get_voxel_manip(areamin, areamax)
		local vpos1, vpos2 = vmanip:get_emerged_area()
		local vcount = (vpos2.x - vpos1.x + 1) * (vpos2.y - vpos1.y + 1) * (vpos2.z - vpos1.z + 1)
		if #vbuffer ~= vcount then
			vbuffer = {}
			for i = 1, vcount do
				vbuffer[i] = c_air
			end
		end
		vmanip:set_data(vbuffer)
		vmanip:write_to_map()
		off = vec(0, 0, 0)
	end
	-- Returns an usable area [pos1, pos2] that does not overlap previous ones
	area.get = function(sizex, sizey, sizez)
		local size
		if sizey == nil or sizez == nil then
			size = {x=sizex, y=sizex, z=sizex}
		else
			size = {x=sizex, y=sizey, z=sizez}
		end
		local pos1 = vector.add(areamin, off)
		local pos2 = vector.subtract(vector.add(pos1, size), 1)
		if pos2.x > areamax.x or pos2.y > areamax.y or pos2.z > areamax.z then
			error("Internal failure: out of space")
		end
		off = vector.add(off, size)
		return pos1, pos2
	end
	-- Returns an axis and count (= n) relative to the last-requested area that is unoccupied
	area.dir = function(n)
		local pos1 = vector.add(areamin, off)
		if pos1.x + n <= areamax.x then
			off.x = off.x + n
			return "x", n
		elseif pos1.x + n <= areamax.y then
			off.y = off.y + n
			return "y", n
		elseif pos1.z + n <= areamax.z then
			off.z = off.z + n
			return "z", n
		end
		error("Internal failure: out of space")
	end
	-- Returns [XYZ] margin (list of pos pairs) of n around last-requested area
	-- (may actually be larger but doesn't matter)
	area.margin = function(n)
		local pos1, pos2 = area.get(n)
		return {
			{ vec(areamin.x, areamin.y, pos1.z), pos2 }, -- X/Y
			{ vec(areamin.x, pos1.y, areamin.z), pos2 }, -- X/Z
			{ vec(pos1.x, areamin.y, areamin.z), pos2 }, -- Y/Z
		}
	end
end
-- Split an existing area into two non-overlapping [pos1, half1], [half2, pos2] parts; returns half1, half2
area.split = function(pos1, pos2)
	local axis
	if pos2.x - pos1.x >= 1 then
		axis = "x"
	elseif pos2.y - pos1.y >= 1 then
		axis = "y"
	elseif pos2.z - pos1.z >= 1 then
		axis = "z"
	else
		error("Internal failure: area too small to split")
	end
	local hspan = math.floor((pos2[axis] - pos1[axis] + 1) / 2)
	local half1 = vecw(axis, pos1[axis] + hspan - 1, pos2)
	local half2 = vecw(axis, pos1[axis] + hspan, pos2)
	return half1, half2
end


---------------------
-- Checks
---------------------
local check = {}
-- Check that all nodes in [pos1, pos2] are the node(s) specified
check.filled = function(pos1, pos2, nodes)
	if type(nodes) == "string" then
		nodes = { nodes }
	end
	local _, counts = minetest.find_nodes_in_area(pos1, pos2, nodes)
	local total = worldedit.volume(pos1, pos2)
	local sum = 0
	for _, n in pairs(counts) do
		sum = sum + n
	end
	if sum ~= total then
		error((total - sum) .. " " .. table.concat(nodes, ",") .. " nodes missing in " ..
			pos2str(pos1) .. " -> " .. pos2str(pos2))
	end
end
-- Check that none of the nodes in [pos1, pos2] are the node(s) specified
check.not_filled = function(pos1, pos2, nodes)
	if type(nodes) == "string" then
		nodes = { nodes }
	end
	local _, counts = minetest.find_nodes_in_area(pos1, pos2, nodes)
	for nodename, n in pairs(counts) do
		if n ~= 0 then
			error(counts[nodename] .. " " .. nodename .. " nodes found in " ..
				pos2str(pos1) .. " -> " .. pos2str(pos2))
		end
	end
end
-- Check that all of the areas are only made of node(s) specified
check.filled2 = function(list, nodes)
	for _, pos in ipairs(list) do
		check.filled(pos[1], pos[2], nodes)
	end
end
-- Check that none of the areas contain the node(s) specified
check.not_filled2 = function(list, nodes)
	for _, pos in ipairs(list) do
		check.not_filled(pos[1], pos[2], nodes)
	end
end
-- Checks presence of a repeating pattern in [pos1, po2] (cf. place_pattern)
check.pattern = function(pos1, pos2, pattern)
	local pos = vec()
	local i = 1
	for z = pos1.z, pos2.z do
		pos.z = z
	for y = pos1.y, pos2.y do
		pos.y = y
	for x = pos1.x, pos2.x do
		pos.x = x
		local node = get_node(pos)
		if node.name ~= pattern[i] then
			error(pattern[i] .. " not found at " .. pos2str(pos) .. " (i=" .. i .. ")")
		end
		i = i % #pattern + 1
	end
	end
	end
end


---------------------
-- The actual tests
---------------------
local tests = {}
local function register_test(name, func, opts)
	assert(type(name) == "string")
	assert(func == nil or type(func) == "function")
	if not opts then
		opts = {}
	else
		opts = table.copy(opts)
	end
	opts.name = name
	opts.func = func
	table.insert(tests, opts)
end
-- How this works:
--   register_test registers a test with a name and function
--   The function should return if the test passes or otherwise cause a Lua error
--   The basic structure is: get areas + do operations + check results
-- Helpers:
--   area.get must be used to retrieve areas that can be operated on (these will be cleared before each test)
--   check.filled / check.not_filled can be used to check the result
--   area.margin + check.filled2 is useful to make sure nodes weren't placed too far
--   place_pattern + check.pattern is useful to test ops that operate on existing data


register_test("Internal self-test")
register_test("is area loaded?", function()
	local pos1, _ = area.get(1)
	assert(get_node(pos1).name == "air")
end, {dry=true})

register_test("area.split", function()
	for i = 2, 6 do
		local pos1, pos2 = area.get(1, 1, i)
		local half1, half2 = area.split(pos1, pos2)
		assert(pos1.x == half1.x and pos1.y == half1.y)
		assert(half1.x == half2.x and half1.y == half2.y)
		assert(half1.z + 1 == half2.z)
		if i % 2 == 0 then
			assert((half1.z - pos1.z) == (pos2.z - half2.z)) -- divided equally
		end
	end
end, {dry=true})

register_test("check.filled", function()
	local pos1, pos2 = area.get(1, 2, 1)
	set_node(pos1, {name=testnode1})
	set_node(pos2, {name=testnode2})
	check.filled(pos1, pos1, testnode1)
	check.filled(pos1, pos2, {testnode1, testnode2})
	check.not_filled(pos1, pos1, air)
	check.not_filled(pos1, pos2, {air, testnode3})
end)

register_test("pattern", function()
	local pos1, pos2 = area.get(3, 2, 1)
	local pattern = {testnode1, testnode3}
	place_pattern(pos1, pos2, pattern)
	assert(get_node(pos1).name == testnode1)
	check.pattern(pos1, pos2, pattern)
end)


register_test("Generic node manipulations")
register_test("worldedit.set", function()
	local pos1, pos2 = area.get(10)
	local m = area.margin(1)

	worldedit.set(pos1, pos2, testnode1)

	check.filled(pos1, pos2, testnode1)
	check.filled2(m, air)
end)

register_test("worldedit.set mix", function()
	local pos1, pos2 = area.get(10)
	local m = area.margin(1)

	worldedit.set(pos1, pos2, {testnode1, testnode2})

	check.filled(pos1, pos2, {testnode1, testnode2})
	check.filled2(m, air)
end)

register_test("worldedit.replace", function()
	local pos1, pos2 = area.get(10)
	local half1, half2 = area.split(pos1, pos2)

	worldedit.set(pos1, half1, testnode1)
	worldedit.set(half2, pos2, testnode2)
	worldedit.replace(pos1, pos2, testnode1, testnode3)

	check.not_filled(pos1, pos2, testnode1)
	check.filled(pos1, half1, testnode3)
	check.filled(half2, pos2, testnode2)
end)

register_test("worldedit.replace inverse", function()
	local pos1, pos2 = area.get(10)
	local half1, half2 = area.split(pos1, pos2)

	worldedit.set(pos1, half1, testnode1)
	worldedit.set(half2, pos2, testnode2)
	worldedit.replace(pos1, pos2, testnode1, testnode3, true)

	check.filled(pos1, half1, testnode1)
	check.filled(half2, pos2, testnode3)
end)

-- FIXME?: this one looks overcomplicated
register_test("worldedit.copy", function()
	local pos1, pos2 = area.get(4)
	local axis, n = area.dir(2)
	local m = area.margin(1)
	local b = pos1[axis]

	-- create one slice with testnode1, one with testnode2
	worldedit.set(pos1, vecw(axis, b + 1, pos2), testnode1)
	worldedit.set(vecw(axis, b + 2, pos1), pos2, testnode2)
	worldedit.copy(pos1, pos2, axis, n)

	-- should have three slices now
	check.filled(pos1, vecw(axis, b + 1, pos2), testnode1)
	check.filled(vecw(axis, b + 2, pos1), pos2, testnode1)
	check.filled(vecw(axis, b + 4, pos1), vector.add(pos2, vecw(axis, n)), testnode2)
	check.filled2(m, "air")
end)

register_test("worldedit.copy2", function()
	local pos1, pos2 = area.get(6)
	local m1 = area.margin(1)
	local pos1_, pos2_ = area.get(6)
	local m2 = area.margin(1)

	local pattern = {testnode1, testnode2, testnode3, testnode1, testnode2}
	place_pattern(pos1, pos2, pattern)
	worldedit.copy2(pos1, pos2, vector.subtract(pos1_, pos1))

	check.pattern(pos1, pos2, pattern)
	check.pattern(pos1_, pos2_, pattern)
	check.filled2(m1, "air")
	check.filled2(m2, "air")
end)

register_test("worldedit.move (overlap)", function()
	local pos1, pos2 = area.get(7)
	local axis, n = area.dir(2)
	local m = area.margin(1)

	local pattern = {testnode2, testnode1, testnode2, testnode3, testnode3}
	place_pattern(pos1, pos2, pattern)
	worldedit.move(pos1, pos2, axis, n)

	check.filled(pos1, vecw(axis, pos1[axis] + n - 1, pos2), "air")
	check.pattern(vecw(axis, pos1[axis] + n, pos1), vecw(axis, pos2[axis] + n, pos2), pattern)
	check.filled2(m, "air")
end)

register_test("worldedit.move", function()
	local pos1, pos2 = area.get(10)
	local axis, n = area.dir(10)
	local m = area.margin(1)

	local pattern = {testnode1, testnode3, testnode3, testnode2}
	place_pattern(pos1, pos2, pattern)
	worldedit.move(pos1, pos2, axis, n)

	check.filled(pos1, pos2, "air")
	check.pattern(vecw(axis, pos1[axis] + n, pos1), vecw(axis, pos2[axis] + n, pos2), pattern)
	check.filled2(m, "air")
end)

-- TODO: the rest (also testing param2 + metadata)


---------------------
-- Main function
---------------------
worldedit.run_tests = function()
	do
		local v = minetest.get_version()
		print("Running " .. #tests .. " tests for WorldEdit " ..
			worldedit.version_string .. " on " .. v.project .. " " .. (v.hash or v.string))
	end

	init_nodes()

	-- emerge area from (0,0,0) ~ (56,56,56) and keep it loaded
	-- Note: making this area smaller speeds up tests
	local wanted = vec(56, 56, 56)
	for x = 0, math.floor(wanted.x/16) do
	for y = 0, math.floor(wanted.y/16) do
	for z = 0, math.floor(wanted.z/16) do
		assert(minetest.forceload_block({x=x*16, y=y*16, z=z*16}, true))
	end
	end
	end
	area.assign(vec(0, 0, 0), wanted, function()

		local failed = 0
		for _, test in ipairs(tests) do
			if not test.func then
				local s = "---- " .. test.name .. " "
				print(s .. string.rep("-", 60 - #s))
			else
				if not test.dry then
					area.clear()
				end
				local ok, err = pcall(test.func)
				print(string.format("%-60s %s", test.name, ok and "pass" or "FAIL"))
				if not ok then
					print("   " .. err)
					failed = failed + 1
				end
			end
		end

		print("Done, " .. failed .. " tests failed.")
		if failed == 0 then
			io.close(io.open(minetest.get_worldpath() .. "/tests_ok", "w"))
		end
		minetest.request_shutdown()
	end)
end

-- for debug purposes
minetest.register_on_joinplayer(function(player)
	minetest.set_player_privs(player:get_player_name(),
		minetest.string_to_privs("fly,fast,noclip,basic_debug,debug,interact"))
end)
minetest.register_on_punchnode(function(pos, node, puncher)
	minetest.chat_send_player(puncher:get_player_name(), pos2str(pos))
end)
