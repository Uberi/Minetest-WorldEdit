local safe_region_callback = {}

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local function safe_region(name, count, callback)
	if count < 20000 then
		return callback()
	end

	--save callback to call later
	safe_region_callback[name] = callback
	worldedit.player_notify(name, "WARNING: this operation could affect up to " .. count .. " nodes; type //y to continue or //n to cancel")
end

local function reset_pending(name)
	safe_region_callback[name] = nil
end

minetest.register_chatcommand("/y", {
	params = "",
	description = "Confirm a pending operation",
	func = function(name)
		local callback = safe_region_callback[name]
		if not callback then
			worldedit.player_notify(name, "no operation pending")
			return
		end

		reset_pending(name)
		callback(name)
	end,
})

minetest.register_chatcommand("/n", {
	params = "",
	description = "Abort a pending operation",
	func = function(name)
		if not safe_region_callback[name] then
			worldedit.player_notify(name, "no operation pending")
			return
		end

		reset_pending(name)
	end,
})


return safe_region, reset_pending
