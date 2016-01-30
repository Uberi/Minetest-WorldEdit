minetest.register_tool("worldedit:wand", {
	description = "WorldEdit wand tool. Left-click to set the 1st position, Right-click to set the 2nd position.",
	groups = {},
	inventory_image = "worldedit_wand.png",
	wield_image = "",
	wield_scale = {x=1,y=1,z=1},
	stack_max = 1, -- there is no need to have more than one
	liquids_pointable = true, -- ground with only water on can be selected as well
	-- the tool_capabilities are completely irrelevant here - no need to dig
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps={
			fleshy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
			snappy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
			choppy={times={[3]=0.90}, maxwear=0.05, maxlevel=0}
		}
	},
	node_placement_prediction = nil,

	on_use = function(itemstack, placer, pointed_thing)
	   if placer ~= nil and pointed_thing ~= nil then
		  local name = placer:get_player_name()
		  local pos  = minetest.get_pointed_thing_position( pointed_thing, false ) -- not above

		  if not pos then
			 return itemstack
		  end

		  worldedit.pos1[name] = pos
		  worldedit.mark_pos1(name)

	   end
	   return itemstack -- nothing consumed, nothing changed
	end,

	on_place = function(itemstack, placer, pointed_thing) -- Left Click
	   if placer ~= nil and pointed_thing ~= nil then
		  local name = placer:get_player_name()
		  local pos  = minetest.get_pointed_thing_position( pointed_thing, false ) -- not above

		  if not pos then
			 return itemstack
		  end

		  worldedit.pos2[name] = pos
		  worldedit.mark_pos2(name)
	   end
	   return itemstack -- nothing consumed, nothing changed
	end,
})
