worldedit.marker1 = {}
worldedit.marker2 = {}
worldedit.marker = {}

--wip: use this as a huge entity to make a full worldedit region box
minetest.register_entity(":worldedit:region_cube", {
	initial_properties = {
		visual = "upright_sprite",
		visual_size = {x=1.1, y=1.1},
		textures = {"worldedit_pos1.png"},
		visual_size = {x=10, y=10},
		physical = false,
	},
	on_step = function(self, dtime)
		if self.active == nil then
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		--wip: remove the entire region marker
	end,
})

--marks worldedit region position 1
worldedit.mark_pos1 = function(name)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

	if pos1 ~= nil then
		--make area stay loaded
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos1, pos1)
	end
	if worldedit.marker1[name] ~= nil then --marker already exists
		worldedit.marker1[name]:remove() --remove marker
		worldedit.marker1[name] = nil
	end
	if pos1 ~= nil then
		--add marker
		worldedit.marker1[name] = minetest.add_entity(pos1, "worldedit:pos1")
		worldedit.marker1[name]:get_luaentity().active = true
		if pos2 ~= nil then --region defined
			worldedit.mark_region(pos1, pos2)
		end
	end
end

--marks worldedit region position 2
worldedit.mark_pos2 = function(name)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]

	if pos2 ~= nil then
		--make area stay loaded
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(pos2, pos2)
	end
	if worldedit.marker2[name] ~= nil then --marker already exists
		worldedit.marker2[name]:remove() --remove marker
		worldedit.marker2[name] = nil
	end
	if pos2 ~= nil then
		--add marker
		worldedit.marker2[name] = minetest.add_entity(pos2, "worldedit:pos2")
		worldedit.marker2[name]:get_luaentity().active = true
		if pos1 ~= nil then --region defined
			worldedit.mark_region(pos1, pos2)
		end
	end
end

worldedit.mark_region = function(pos1, pos2)
	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	if worldedit.marker[name] ~= nil then --marker already exists
		--wip: remove markers
	end
	if pos1 ~= nil and pos2 ~= nil then
		--wip: place markers
	end
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
	},
	on_step = function(self, dtime)
		if self.active == nil then
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		self.object:remove()
		local name = hitter:get_player_name()
		worldedit.marker1[name] = nil
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
	},
	on_step = function(self, dtime)
		if self.active == nil then
			self.object:remove()
		end
	end,
	on_punch = function(self, hitter)
		self.object:remove()
		local name = hitter:get_player_name()
		worldedit.marker2[name] = nil
	end,
})