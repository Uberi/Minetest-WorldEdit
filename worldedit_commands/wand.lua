minetest.register_tool(":worldedit:wand", {
	description = "WorldEdit Wand tool, Left-click to set 1st position, right-click to set 2nd",
	inventory_image = "worldedit_wand.png",
	stack_max = 1, -- there is no need to have more than one
	liquids_pointable = true, -- ground with only water on can be selected as well

	on_use = function(itemstack, placer, pointed_thing)
		if placer ~= nil and pointed_thing ~= nil and pointed_thing.type == "node" then
			local name = placer:get_player_name()
			worldedit.pos1[name] = pointed_thing.under
			worldedit.mark_pos1(name)
		end
		return itemstack -- nothing consumed, nothing changed
	end,

	on_place = function(itemstack, placer, pointed_thing) -- Left Click
		if placer ~= nil and pointed_thing ~= nil and pointed_thing.type == "node" then
			local name = placer:get_player_name()
			worldedit.pos2[name] = pointed_thing.under
			worldedit.mark_pos2(name)
		end
		return itemstack -- nothing consumed, nothing changed
	end,
})
