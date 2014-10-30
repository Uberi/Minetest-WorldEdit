--- Common functions [INTERNAL].  All of these functions are internal!
-- @module worldedit.common

--- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- Returns the new positions.
function worldedit.sort_pos(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
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


function worldedit.keep_loaded(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)
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
	for i = 1, worldedit.volume(area.MinEdge, area.MaxEdge) do
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
	manip:set_data(data)
	manip:write_to_map()
	manip:update_map()
end

