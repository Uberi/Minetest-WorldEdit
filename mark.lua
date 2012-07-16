worldedit.marker1 = {}
worldedit.marker2 = {}

--marks worldedit region position 1
worldedit.mark_pos1 = function(name)
	local pos = worldedit.pos1[name]
	if worldedit.marker1[name] == nil then --marker does not yet exist
		if pos ~= nil then --add marker
			worldedit.marker1[name] = minetest.env:add_entity(pos, "worldedit:pos1")
		end
	else --marker already exists
		if pos == nil then --remove marker
			worldedit.marker1[name]:remove()
			worldedit.marker1[name] = nil
		else --move marker
			worldedit.marker1[name]:setpos(pos)
		end
	end
end

--marks worldedit region position 2
worldedit.mark_pos2 = function(name)
	local pos = worldedit.pos2[name]
	if worldedit.marker2[name] == nil then --marker does not yet exist
		if pos ~= nil then --add marker
			worldedit.marker2[name] = minetest.env:add_entity(pos, "worldedit:pos2")
		end
	else --marker already exists
		if pos == nil then --remove marker
			worldedit.marker2[name]:remove()
			worldedit.marker2[name] = nil
		else --move marker
			worldedit.marker2[name]:setpos(pos)
		end
	end
end

minetest.register_entity("worldedit:pos1", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"worldedit_pos1.png", "worldedit_pos1.png",
			"worldedit_pos1.png", "worldedit_pos1.png",
			"worldedit_pos1.png", "worldedit_pos1.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
	},
	on_punch = function(self, hitter)
		self.object:remove()
		local name = hitter:get_player_name()
		worldedit.marker1[name] = nil
	end,
})

minetest.register_entity("worldedit:pos2", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=1.1, y=1.1},
		textures = {"worldedit_pos2.png", "worldedit_pos2.png",
			"worldedit_pos2.png", "worldedit_pos2.png",
			"worldedit_pos2.png", "worldedit_pos2.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
	},
	on_punch = function(self, hitter)
		self.object:remove()
		local name = hitter:get_player_name()
		worldedit.marker2[name] = nil
	end,
})