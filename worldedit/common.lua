--- Common functions [INTERNAL].  All of these functions are internal!
-- @module worldedit.common

-- Polyfill for vector.copy (added in 5.5.0)
if not vector.copy then
	local vnew = vector.new
	vector.copy = function(v)
		return vnew(v.x, v.y, v.z)
	end
end


--- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- Returns the new positions.
function worldedit.sort_pos(pos1, pos2)
	pos1 = vector.copy(pos1)
	pos2 = vector.copy(pos2)
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end


--- Determines the volume of the region defined by positions `pos1` and `pos2`.
-- @return The volume.
function worldedit.volume(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	return (pos2.x - pos1.x + 1) *
		(pos2.y - pos1.y + 1) *
		(pos2.z - pos1.z + 1)
end


--- Gets other axes given an axis.
-- @raise Axis must be x, y, or z!
function worldedit.get_axis_others(axis)
	if axis == "x" then
		return "y", "z"
	elseif axis == "y" then
		return "x", "z"
	elseif axis == "z" then
		return "x", "y"
	else
		error("Axis must be x, y, or z!")
	end
end


-- Create a vmanip and read the area from map, this causes all
-- MapBlocks to be loaded into memory synchronously.
-- This doesn't actually *keep* them loaded, unlike the name implies.
function worldedit.keep_loaded(pos1, pos2)
	-- rough estimate, a MapNode is 4 bytes in the engine
	if worldedit.volume(pos1, pos2) > 268400000 then
		print("[WorldEdit] Requested to load an area bigger than 1GB, refusing. The subsequent operation may fail.")
		return
	end
	if minetest.load_area then
		-- same effect but without unnecessary data copying
		minetest.load_area(pos1, pos2)
	else
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos1, pos2)
	end
end


local mh = {}
worldedit.manip_helpers = mh


--- Generates an empty VoxelManip data table for an area.
-- @return The empty data table.
function mh.get_empty_data(area)
	-- Fill emerged area with ignore so that blocks in the area that are
	-- only partially modified aren't overwriten.
	local data = {}
	local c_ignore = minetest.get_content_id("ignore")
	for i = 1, area:getVolume() do
		data[i] = c_ignore
	end
	return data
end


function mh.init(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	return manip, area
end


function mh.init_radius(pos, radius)
	local pos1 = vector.subtract(pos, radius)
	local pos2 = vector.add(pos, radius)
	return mh.init(pos1, pos2)
end


function mh.init_axis_radius(base_pos, axis, radius)
	return mh.init_axis_radius_length(base_pos, axis, radius, radius)
end


function mh.init_axis_radius_length(base_pos, axis, radius, length)
	local other1, other2 = worldedit.get_axis_others(axis)
	local pos1 = {
		[axis]   = base_pos[axis],
		[other1] = base_pos[other1] - radius,
		[other2] = base_pos[other2] - radius
	}
	local pos2 = {
		[axis]   = base_pos[axis] + length,
		[other1] = base_pos[other1] + radius,
		[other2] = base_pos[other2] + radius
	}
	return mh.init(pos1, pos2)
end


function mh.finish(manip, data)
	-- Update map
	if data ~= nil then
		manip:set_data(data)
	end
	manip:write_to_map()
	if manip.close ~= nil then
		manip:close() -- explicitly free memory
	end
end


-- returns an iterator that returns voxelarea indices for a hollow cuboid
function mh.iter_hollowcuboid(area, minx, miny, minz, maxx, maxy, maxz)
	local i = area:index(minx, miny, minz) - 1
	local xrange = maxx - minx + 1
	local nextaction = i + 1 + xrange
	local do_hole = false

	local y = 0
	local ydiff = maxy - miny
	local ystride = area.ystride
	local ymultistride = ydiff * ystride

	local z = 0
	local zdiff = maxz - minz
	local zstride = area.zstride
	local zcorner = true

	return function()
		-- continue i until it needs to jump ystride
		i = i + 1
		if i ~= nextaction then
			return i
		end

		-- add the x offset if y (and z) are not 0 or maxy (or maxz)
		if do_hole then
			do_hole = false
			i = i + xrange - 2
			nextaction = i + 1
			return i
		end

		-- continue y until maxy is exceeded
		y = y+1
		if y ~= ydiff + 1 then
			i = i + ystride - xrange
			if zcorner
			or y == ydiff then
				nextaction = i + xrange
			else
				nextaction = i + 1
				do_hole = true
			end
			return i
		end

		-- continue z until maxz is exceeded
		z = z+1
		if z == zdiff + 1 then
			-- hollowcuboid finished, return nil
			return
		end

		-- set i to index(minx, miny, minz + z) - 1
		i = i + zstride - (ymultistride + xrange)
		zcorner = z == zdiff

		-- y is 0, so traverse the xs
		y = 0
		nextaction = i + xrange
		return i
	end
end

function mh.iterp_hollowcuboid(area, minp, maxp)
	return mh.iter_hollowcuboid(area, minp.x, minp.y, minp.z,
		maxp.x, maxp.y, maxp.z)
end
