local function above_or_under(placer, pointed_thing)
	if placer:get_player_control().sneak then
		return pointed_thing.above
	else
		return pointed_thing.under
	end
end

local punched_air_time = {}

minetest.register_tool(":worldedit:wand", {
	description = "WorldEdit Wand tool\nLeft-click to set 1st position, right-click to set 2nd",
	inventory_image = "worldedit_wand.png",
	stack_max = 1, -- there is no need to have more than one
	liquids_pointable = true, -- ground with only water on can be selected as well

	on_use = function(itemstack, placer, pointed_thing)
		if placer == nil or pointed_thing == nil then return end
		local name = placer:get_player_name()
		if pointed_thing.type == "node" then
			-- set and mark pos1
			worldedit.pos1[name] = above_or_under(placer, pointed_thing)
			worldedit.mark_pos1(name)
		elseif pointed_thing.type == "nothing" then
			local now = minetest.get_us_time()
			if now - (punched_air_time[name] or 0) < 1000 * 1000 then
				-- reset markers
				worldedit.registered_commands["reset"].func(name)
			end
			punched_air_time[name] = now
		elseif pointed_thing.type == "object" then
			local entity = pointed_thing.ref:get_luaentity()
			if entity and entity.name == "worldedit:pos2" then
				-- set pos1 = pos2
				worldedit.pos1[name] = worldedit.pos2[name]
				worldedit.mark_pos1(name)
			end
		end
	end,

	on_place = function(itemstack, placer, pointed_thing)
		if placer == nil or (pointed_thing or {}).type ~= "node" then
			return itemstack
		end
		local name = placer:get_player_name()
		-- set and mark pos2
		worldedit.pos2[name] = above_or_under(placer, pointed_thing)
		worldedit.mark_pos2(name)
		return itemstack -- nothing consumed, nothing changed
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		if user == nil or (pointed_thing or {}).type ~= "object" then
			return itemstack
		end
		local name = user:get_player_name()
		local entity = pointed_thing.ref:get_luaentity()
		if entity and entity.name == "worldedit:pos1" then
			-- set pos2 = pos1
			worldedit.pos2[name] = worldedit.pos1[name]
			worldedit.mark_pos2(name)
		end
		return itemstack -- nothing consumed, nothing changed
	end,
})
