worldedit = rawget(_G, "worldedit") or {}
local minetest = minetest --local copy of global

local get_pointed = function(pos, nearest, distance)
	if distance > 100 then
		return false
	end

	--check for collision with node
	local nodename = minetest.get_node(pos).name
	if nodename ~= "air"
	and nodename ~= "default:water_source"
	and nodename ~= "default:water_flowing" then
		if nodename ~= "ignore" then
			return nearest
		end
		return false
	end
end

local use = function(itemstack, user, pointed_thing)
	if pointed_thing.type == "nothing" then --pointing at nothing
		local placepos = worldedit.raytrace(user:getpos(), user:get_look_dir(), get_pointed)
		if placepos then --extended reach
			pointed_thing.type = "node"
			pointed_thing.under = nil --wip
			pointed_thing.above = nil --wip
		end
	end
	return minetest.item_place_node(itemstack, user, pointed_thing)
end
--

worldedit.raytrace = function(pos, dir, callback)
	local base = {x=math.floor(pos.x), y=math.floor(pos.y), z=math.floor(pos.z)}
	local stepx, stepy, stepz = 0, 0, 0
	local componentx, componenty, componentz = 0, 0, 0
	local intersectx, intersecty, intersectz = 0, 0, 0

	if dir.x == 0 then
		intersectx = math.huge
	elseif dir.x > 0 then
		stepx = 1
		componentx = 1 / dir.x
		intersectx = ((base.x - pos.x) + 1) * componentx
	else
		stepx = -1
		componentx = 1 / -dir.x
		intersectx = (pos.x - base.x) * componentx
	end
	if dir.y == 0 then
		intersecty = math.huge
	elseif dir.y > 0 then
		stepy = 1
		componenty = 1 / dir.y
		intersecty = ((base.y - pos.y) + 1) * componenty
	else
		stepy = -1
		componenty = 1 / -dir.y
		intersecty = (pos.y - base.y) * componenty
	end
	if dir.z == 0 then
		intersectz = math.huge
	elseif dir.z > 0 then
		stepz = 1
		componentz = 1 / dir.z
		intersectz = ((base.z - pos.z) + 1) * componentz
	else
		stepz = -1
		componentz = 1 / -dir.z
		intersectz = (pos.z - base.z) * componentz
	end

	local distance = 0
	local nearest = {x=base.x, y=base.y, z=base.z}
	while true do
		local values = {callback(base, nearest, distance)}
		if #values > 0 then
			return unpack(values)
		end

		nearest.x, nearest.y, nearest.z = base.x, base.y, base.z
		if intersectx < intersecty then
			if intersectx < intersectz then
				base.x = base.x + stepx
				distance = intersectx
				intersectx = intersectx + componentx
			else
				base.z = base.z + stepz
				distance = intersectz
				intersectz = intersectz + componentz
			end
		elseif intersecty < intersectz then
			base.y = base.y + stepy
			distance = intersecty
			intersecty = intersecty + componenty
		else
			base.z = base.z + stepz
			distance = intersectz
			intersectz = intersectz + componentz
		end
	end
end
