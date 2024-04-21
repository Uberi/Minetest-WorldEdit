---------------------
local vec = vector.new
local vecw = function(axis, n, base)
	local ret = vec(base)
	ret[axis] = n
	return ret
end
local air = "air"
---------------------


worldedit.register_test("Generic node manipulations")
worldedit.register_test("worldedit.set", function()
	local pos1, pos2 = area.get(10)
	local m = area.margin(1)

	worldedit.set(pos1, pos2, testnode1)

	check.filled(pos1, pos2, testnode1)
	check.filled2(m, air)
end)

worldedit.register_test("worldedit.set mix", function()
	local pos1, pos2 = area.get(10)
	local m = area.margin(1)

	worldedit.set(pos1, pos2, {testnode1, testnode2})

	check.filled(pos1, pos2, {testnode1, testnode2})
	check.filled2(m, air)
end)

worldedit.register_test("worldedit.replace", function()
	local pos1, pos2 = area.get(10)
	local half1, half2 = area.split(pos1, pos2)

	worldedit.set(pos1, half1, testnode1)
	worldedit.set(half2, pos2, testnode2)
	worldedit.replace(pos1, pos2, testnode1, testnode3)

	check.not_filled(pos1, pos2, testnode1)
	check.filled(pos1, half1, testnode3)
	check.filled(half2, pos2, testnode2)
end)

worldedit.register_test("worldedit.replace inverse", function()
	local pos1, pos2 = area.get(10)
	local half1, half2 = area.split(pos1, pos2)

	worldedit.set(pos1, half1, testnode1)
	worldedit.set(half2, pos2, testnode2)
	worldedit.replace(pos1, pos2, testnode1, testnode3, true)

	check.filled(pos1, half1, testnode1)
	check.filled(half2, pos2, testnode3)
end)

-- FIXME?: this one looks overcomplicated
worldedit.register_test("worldedit.copy", function()
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
	check.filled2(m, air)
end)

worldedit.register_test("worldedit.copy2", function()
	local pos1, pos2 = area.get(6)
	local m1 = area.margin(1)
	local pos1_, pos2_ = area.get(6)
	local m2 = area.margin(1)

	local pattern = {testnode1, testnode2, testnode3, testnode1, testnode2}
	place_pattern(pos1, pos2, pattern)
	worldedit.copy2(pos1, pos2, vector.subtract(pos1_, pos1))

	check.pattern(pos1, pos2, pattern)
	check.pattern(pos1_, pos2_, pattern)
	check.filled2(m1, air)
	check.filled2(m2, air)
end)

worldedit.register_test("worldedit.move (overlap)", function()
	local pos1, pos2 = area.get(7)
	local axis, n = area.dir(2)
	local m = area.margin(1)

	local pattern = {testnode2, testnode1, testnode2, testnode3, testnode3}
	place_pattern(pos1, pos2, pattern)
	worldedit.move(pos1, pos2, axis, n)

	check.filled(pos1, vecw(axis, pos1[axis] + n - 1, pos2), air)
	check.pattern(vecw(axis, pos1[axis] + n, pos1), vecw(axis, pos2[axis] + n, pos2), pattern)
	check.filled2(m, air)
end)

worldedit.register_test("worldedit.move", function()
	local pos1, pos2 = area.get(10)
	local axis, n = area.dir(10)
	local m = area.margin(1)

	local pattern = {testnode1, testnode3, testnode3, testnode2}
	place_pattern(pos1, pos2, pattern)
	worldedit.move(pos1, pos2, axis, n)

	check.filled(pos1, pos2, air)
	check.pattern(vecw(axis, pos1[axis] + n, pos1), vecw(axis, pos2[axis] + n, pos2), pattern)
	check.filled2(m, air)
end)

-- TODO: the rest (also testing param2 + metadata)
