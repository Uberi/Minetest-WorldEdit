local safe_region_callback = {}
local safe_region_param = {}

check_region = function(name, param)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name] --obtain positions
	if pos1 == nil or pos2 == nil then
		worldedit.player_notify(name, "no region selected")
		return nil
	end
	return worldedit.volume(pos1, pos2)
end

--`callback` is a callback to run when the user confirms
--`nodes_needed` is a function accepting `param`, `pos1`, and `pos2` to calculate the number of nodes needed
safe_region = function(callback, nodes_needed)
	--default node volume calculation
	nodes_needed = nodes_needed or check_region

	return function(name, param)
		--check if the operation applies to a safe number of nodes
		local count = nodes_needed(name, param)
		if count == nil then return end --invalid command
		if count < 10000 then
			return callback(name, param)
		end

		--save callback to call later
		safe_region_callback[name], safe_region_param[name] = callback, param
		worldedit.player_notify(name, "WARNING: this operation could affect up to " .. count .. " nodes; type //y to continue or //n to cancel")
	end
end

minetest.register_chatcommand("/y", {
	params = "",
	description = "Confirm a pending operation",
	func = function(name)
		local callback, param = safe_region_callback[name], safe_region_param[name]
		if not callback then
			worldedit.player_notify(name, "no operation pending")
			return
		end

		--obtain positions
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		if pos1 == nil or pos2 == nil then
			worldedit.player_notify(name, "no region selected")
			return
		end

		safe_region_callback[name], safe_region_param[name] = nil, nil --reset pending operation
		callback(name, param, pos1, pos2)
	end,
})

minetest.register_chatcommand("/n", {
	params = "",
	description = "Confirm a pending operation",
	func = function(name)
		if not safe_region_callback[name] then
			worldedit.player_notify(name, "no operation pending")
			return
		end
		safe_region_callback[name], safe_region_param[name] = nil, nil
	end,
})
