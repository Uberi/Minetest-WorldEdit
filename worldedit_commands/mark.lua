worldedit.marker1 = {}
worldedit.marker2 = {}
worldedit.marker_region = {}

local init_sentinel = "new" .. tostring(math.random(99999))

--marks worldedit region position 1
worldedit.mark_pos1 = function(name, region_too)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

	if worldedit.marker1[name] ~= nil then --marker already exists
		worldedit.marker1[name]:remove() --remove marker
		worldedit.marker1[name] = nil
	end
	if pos1 ~= nil then
		--make area stay loaded
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos1, pos1)

		--add marker
		worldedit.marker1[name] = minetest.add_entity(pos1, "worldedit:pos1", init_sentinel)
		if worldedit.marker1[name] ~= nil then
			worldedit.marker1[name]:get_luaentity().player_name = name
		end
	end
	if region_too == nil or region_too then
		worldedit.mark_region(name)
	end
end

--marks worldedit region position 2
worldedit.mark_pos2 = function(name, region_too)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

	if worldedit.marker2[name] ~= nil then --marker already exists
		worldedit.marker2[name]:remove() --remove marker
		worldedit.marker2[name] = nil
	end
	if pos2 ~= nil then
		--make area stay loaded
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos2, pos2)

		--add marker
		worldedit.marker2[name] = minetest.add_entity(pos2, "worldedit:pos2", init_sentinel)
		if worldedit.marker2[name] ~= nil then
			worldedit.marker2[name]:get_luaentity().player_name = name
		end
	end
	if region_too == nil or region_too then
		worldedit.mark_region(name)
	end
end

worldedit.mark_region = function(name)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

	if worldedit.marker_region[name] ~= nil then --marker already exists
		for _, entity in ipairs(worldedit.marker_region[name]) do
			entity:remove()
		end
		worldedit.marker_region[name] = nil
	end

	if pos1 ~= nil and pos2 ~= nil then
		local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

		local vec = vector.subtract(pos2, pos1)
		local maxside = math.max(vec.x, math.max(vec.y, vec.z))
		local limit = tonumber(minetest.settings:get("active_object_send_range_blocks")) * 16
		if maxside > limit * 1.5 then
			-- The client likely won't be able to see the plane markers as intended anyway,
			-- thus don't place them and also don't load the area into memory
			return
		end

		local thickness = 0.2
		local sizex, sizey, sizez = (1 + pos2.x - pos1.x) / 2, (1 + pos2.y - pos1.y) / 2, (1 + pos2.z - pos1.z) / 2

		--make area stay loaded
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos1, pos2)

		local markers = {}

		--XY plane markers
		for _, z in ipairs({pos1.z - 0.5, pos2.z + 0.5}) do
			local entpos = {x=pos1.x + sizex - 0.5, y=pos1.y + sizey - 0.5, z=z}
			local marker = minetest.add_entity(entpos, "worldedit:region_cube", init_sentinel)
			if marker ~= nil then
				marker:set_properties({
					visual_size={x=sizex * 2, y=sizey * 2},
					collisionbox = {-sizex, -sizey, -thickness, sizex, sizey, thickness},
				})
				marker:get_luaentity().player_name = name
				table.insert(markers, marker)
			end
		end

		--YZ plane markers
		for _, x in ipairs({pos1.x - 0.5, pos2.x + 0.5}) do
			local entpos = {x=x, y=pos1.y + sizey - 0.5, z=pos1.z + sizez - 0.5}
			local marker = minetest.add_entity(entpos, "worldedit:region_cube", init_sentinel)
			if marker ~= nil then
				marker:set_properties({
					visual_size={x=sizez * 2, y=sizey * 2},
					collisionbox = {-thickness, -sizey, -sizez, thickness, sizey, sizez},
				})
				marker:set_yaw(math.pi / 2)
				marker:get_luaentity().player_name = name
				table.insert(markers, marker)
			end
		end

		worldedit.marker_region[name] = markers
	end
end

--convenience function that calls everything
worldedit.marker_update = function(name)
	worldedit.mark_pos1(name, false)
	worldedit.mark_pos2(name, false)
	worldedit.mark_region(name)
end

minetest.register_entity(":worldedit:pos1", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"worldedit_pos1.png", "worldedit_pos1.png",
			"worldedit_pos1.png", "worldedit_pos1.png",
			"worldedit_pos1.png", "worldedit_pos1.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		physical = false,
		static_save = false,
	},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= init_sentinel then
			-- we were loaded from before static_save = false was added
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		self.object:remove()
		worldedit.marker1[self.player_name] = nil
	end,
	on_blast = function(self, damage)
		return false, false, {} -- don't damage or knockback
	end,
})

minetest.register_entity(":worldedit:pos2", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"worldedit_pos2.png", "worldedit_pos2.png",
			"worldedit_pos2.png", "worldedit_pos2.png",
			"worldedit_pos2.png", "worldedit_pos2.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		physical = false,
		static_save = false,
	},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= init_sentinel then
			-- we were loaded from before static_save = false was added
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		self.object:remove()
		worldedit.marker2[self.player_name] = nil
	end,
	on_blast = function(self, damage)
		return false, false, {} -- don't damage or knockback
	end,
})

minetest.register_entity(":worldedit:region_cube", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"worldedit_cube.png"},
		visual_size = {x=10, y=10},
		physical = false,
		static_save = false,
	},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= init_sentinel then
			-- we were loaded from before static_save = false was added
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		local markers = worldedit.marker_region[self.player_name]
		if not markers then
			return
		end
		for _, entity in ipairs(markers) do
			entity:remove()
		end
		worldedit.marker_region[self.player_name] = nil
	end,
	on_blast = function(self, damage)
		return false, false, {} -- don't damage or knockback
	end,
})

