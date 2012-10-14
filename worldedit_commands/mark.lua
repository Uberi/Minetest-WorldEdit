worldedit.marker1 = {}
worldedit.marker2 = {}

--marks worldedit region position 1
worldedit.mark_pos1 = function(name)
	local pos = worldedit.pos1[name]
	if worldedit.marker1[name] ~= nil then --marker already exists
		worldedit.marker1[name]:remove() --remove marker
		worldedit.marker1[name] = nil
	end
	if pos ~= nil then --add marker
		worldedit.marker1[name] = minetest.env:add_entity(pos, "worldedit:pos1")
		worldedit.marker1[name]:get_luaentity().active = true
	end
end

--marks worldedit region position 2
worldedit.mark_pos2 = function(name)
	local pos = worldedit.pos2[name]
	if worldedit.marker2[name] ~= nil then --marker already exists
		worldedit.marker2[name]:remove() --remove marker
		worldedit.marker2[name] = nil
	end
	if pos ~= nil then --add marker
		worldedit.marker2[name] = minetest.env:add_entity(pos, "worldedit:pos2")
		worldedit.marker2[name]:get_luaentity().active = true
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