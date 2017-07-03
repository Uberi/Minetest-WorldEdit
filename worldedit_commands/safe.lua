local area_protection = {}

if minetest.get_modpath("areas") then
    area_protection.areas = areas
end

area_protection.interaction_restrictions = function(
	area_protection,
	player_name
)
	if area_protection.areas then
		if minetest.check_player_privs(name, {areas = true}) then
			return false
		end
		return true
	end
	return false
end

area_protection.interaction_allowed = function(
	area_protection,
	description,
	pos1,
	pos2,
	player_name
)
	if area_protection.areas then
		local allowed, conflicting = area_protection.areas:canInteractInArea(
			pos1,
			pos2,
			player_name,
			false
		)
		if not allowed then
			worldedit.player_notify(
				player_name,
				description .. " conflicts with non-owned region " .. conflicting
			)
		end
		return allowed
	end
	return true
end

local safe_region_callback = {}
local safe_region_param = {}

local function check_region(name, param)
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name] --obtain positions
	if pos1 == nil or pos2 == nil then
		worldedit.player_notify(name, "no region selected")
		return nil
	end
	local allowed = area_protection:interaction_allowed(
		"region",
		pos1,
		pos2,
		name
	)
	if not allowed then
		return nil
	end
	return worldedit.volume(pos1, pos2)
end

--`callback` is a callback to run when the user confirms
--`nodes_needed` is a function accepting `param`, `pos1`, and `pos2` to calculate the number of nodes needed
local function safe_region(callback, nodes_needed)
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

local function reset_pending(name)
	safe_region_callback[name], safe_region_param[name] = nil, nil
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

		safe_region_callback[name], safe_region_param[name] = nil, nil --reset pending operation
		callback(name, param)
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


return safe_region, check_region, reset_pending, area_protection
