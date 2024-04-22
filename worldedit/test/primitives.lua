---------------------
local vec = vector.new
local vecw = function(axis, n, base)
	local ret = vec(base)
	ret[axis] = n
	return ret
end
local air = "air"
---------------------


worldedit.register_test("Primitives")
worldedit.register_test("worldedit.cube", function()
	local pos1, pos2 = area.get(6, 5, 4)
	local m = area.margin(1)

	local center = vec(pos1.x + 3, pos1.y, pos1.z + 2)

	worldedit.cube(center, 6, 5, 4, testnode2)

	check.filled(pos1, pos2, testnode2)
	check.filled2(m, air)
end)

worldedit.register_test("worldedit.cube hollow small", function()
	for n = 1, 2 do
		local pos1, pos2 = area.get(n)
		local m = area.margin(1)

		local center = vec(pos1.x + math.floor(n/2), pos1.y, pos1.z + math.floor(n/2))

		worldedit.cube(center, n, n, n, testnode1, true)

		check.filled(pos1, pos2, testnode1) -- filled entirely
		check.filled2(m, air)
	end
end)

worldedit.register_test("worldedit.cube hollow", function()
	local pos1, pos2 = area.get(6, 5, 4)
	local m = area.margin(1)

	local center = vec(pos1.x + 3, pos1.y, pos1.z + 2)

	worldedit.cube(center, 6, 5, 4, testnode1, true)

	check.filled(vector.add(pos1, vec(1,1,1)), vector.subtract(pos2, vec(1,1,1)), air)
	check.filled2({
		{ vecw("x", pos2.x, pos1), pos2 },
		{ vecw("y", pos2.y, pos1), pos2 },
		{ vecw("z", pos2.z, pos1), pos2 },
		{ pos1, vecw("x", pos1.x, pos2) },
		{ pos1, vecw("y", pos1.y, pos2) },
		{ pos1, vecw("z", pos1.z, pos2) },
	}, testnode1)
	check.filled2(m, air)
end)


