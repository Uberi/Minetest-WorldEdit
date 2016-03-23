minetest.register_tool("worldedit:wand", {
	description = "WorldEdit wand tool. Left-click to set the 1st position, Right-click to set the 2nd position.",
	inventory_image = "worldedit_wand.png",
	liquids_pointable = true, -- ground with only water on can be selected as well

	on_use = function(itemstack, placer, pointed_thing)
		if not placer
		or not pointed_thing then
			return
		end
		local name = placer:get_player_name()
		local pos  = minetest.get_pointed_thing_position( pointed_thing, false ) -- not above

		if not pos then
			return itemstack
		end

		worldedit.pos1[name] = pos
		worldedit.mark_pos1(name)

		return itemstack -- nothing consumed, nothing changed
	end,

	on_place = function(itemstack, placer, pointed_thing) -- Left Click
		if not placer
		or not pointed_thing then
			return
		end
		local name = placer:get_player_name()
		local pos  = minetest.get_pointed_thing_position( pointed_thing, false ) -- not above

		if not pos then
			return itemstack
		end

		worldedit.pos2[name] = pos
		worldedit.mark_pos2(name)

		return itemstack -- nothing consumed, nothing changed
	end,
})
