local S = minetest.get_translator("worldedit_commands")

local safe_region_limit = tonumber(minetest.settings:get("worldedit_safe_region_limit") or "20000")

local safe_region_callback = {}

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local function safe_region(name, count, callback)
	if safe_region_limit <= 0 or count < safe_region_limit then
		return callback()
	end

	-- save callback to call later
	safe_region_callback[name] = callback

	local count_str = tostring(count)
	-- highlight millions, 1 mln <=> 100x100x100 cube
	if #count_str > 6 then
		count_str = minetest.colorize("#f33", count_str:sub(1, -7)) .. count_str:sub(-6, -1)
	end

	local yes_cmd = minetest.colorize("#0ff", "//y")
	local no_cmd = minetest.colorize("#0ff", "//n")
	local msg = S("WARNING: this operation could affect up to @1 nodes; type @2 to continue or @3 to cancel",
		count_str, yes_cmd, no_cmd)
	worldedit.player_notify(name, msg, "info")
end

local function reset_pending(name)
	safe_region_callback[name] = nil
end

minetest.register_chatcommand("/y", {
	params = "",
	description = S("Confirm a pending operation"),
	func = function(name)
		local callback = safe_region_callback[name]
		if not callback then
			worldedit.player_notify(name, S("no operation pending"), "error")
			return
		end

		reset_pending(name)
		callback(name)
	end,
})

minetest.register_chatcommand("/n", {
	params = "",
	description = S("Abort a pending operation"),
	func = function(name)
		if not safe_region_callback[name] then
			worldedit.player_notify(name, S("no operation pending"), "error")
			return
		end

		reset_pending(name)
	end,
})


return safe_region, reset_pending
