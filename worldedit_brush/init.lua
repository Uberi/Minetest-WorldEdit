local S = minetest.get_translator("worldedit_brush")

local BRUSH_MAX_DIST = 150
local brush_on_use = function(itemstack, placer)
	local meta = itemstack:get_meta()
	local name = placer:get_player_name()

	local cmd = meta:get_string("command")
	if cmd == "" then
		worldedit.player_notify(name,
			S("This brush is not bound, use @1 to bind a command to it.",
			minetest.colorize("#0ff", "//brush")), "info")
		return false
	end

	local cmddef = worldedit.registered_commands[cmd]
	if cmddef == nil then return false end -- shouldn't happen as //brush checks this

	local has_privs, missing_privs = minetest.check_player_privs(name, cmddef.privs)
	if not has_privs then
		worldedit.player_notify(name,
			S("Missing privileges: @1", table.concat(missing_privs, ", ")), "error")
		return false
	end

	local raybegin = vector.add(placer:get_pos(),
		vector.new(0, placer:get_properties().eye_height, 0))
	local rayend = vector.add(raybegin, vector.multiply(placer:get_look_dir(), BRUSH_MAX_DIST))
	local ray = minetest.raycast(raybegin, rayend, false, true)
	local pointed_thing = ray:next()
	if pointed_thing == nil then
		worldedit.player_notify(name, S("Too far away."), "error")
		return false
	end

	assert(pointed_thing.type == "node")
	worldedit.pos1[name] = pointed_thing.under
	worldedit.pos2[name] = nil
	worldedit.marker_update(name)

	assert(cmddef.require_pos < 2)
	local parsed = {cmddef.parse(meta:get_string("params"))}
	if not table.remove(parsed, 1) then return false end -- shouldn't happen

	-- discard success messages
	local player_notify_old = worldedit.player_notify
	worldedit.player_notify = function(name, msg, typ)
		if typ == "ok" then return end
		return player_notify_old(name, msg, typ)
	end

	minetest.log("action", string.format("%s uses WorldEdit brush (//%s) at %s",
		name, cmd, minetest.pos_to_string(pointed_thing.under)))
	cmddef.func(name, unpack(parsed))

	worldedit.player_notify = player_notify_old
	return true
end

minetest.register_tool(":worldedit:brush", {
	description = S("WorldEdit Brush"),
	inventory_image = "worldedit_brush.png",
	stack_max = 1, -- no need to stack these (metadata prevents this anyway)
	range = 0,
	on_use = function(itemstack, placer, pointed_thing)
		brush_on_use(itemstack, placer)
		return itemstack -- nothing consumed, nothing changed
	end,
})

worldedit.register_command("brush", {
	privs = {worldedit=true},
	params = "none/<cmd> [parameters]",
	description = S("Assign command to WorldEdit brush item or clear assignment using 'none'"),
	parse = function(param)
		local found, _, cmd, params = param:find("^([^%s]+)%s+(.+)$")
		if not found then
			params = ""
			found, _, cmd = param:find("^(.+)$")
		end
		if not found then
			return false
		end
		return true, cmd, params
	end,
	func = function(name, cmd, params)
		local player = minetest.get_player_by_name(name)
		if not player then return end
		local itemstack = player:get_wielded_item()
		if itemstack == nil or itemstack:get_name() ~= "worldedit:brush" then
			return false, S("Not holding brush item.")
		end

		cmd = cmd:lower()
		local meta = itemstack:get_meta()
		if cmd == "none" then
			meta:from_table(nil)
			worldedit.player_notify(name, S("Brush assignment cleared."), "ok")
		else
			local cmddef = worldedit.registered_commands[cmd]
			if cmddef == nil or cmddef.require_pos ~= 1 then
				return false, S("@1 cannot be used with brushes",
					minetest.colorize("#0ff", "//"..cmd))
			end

			-- Try parsing command params so we can give the user feedback
			local ok, err = cmddef.parse(params)
			if not ok then
				err = err or S("invalid usage")
				return false, S("Error with command: @1", err)
			end

			meta:set_string("command", cmd)
			meta:set_string("params", params)
			local fullcmd = minetest.colorize("#0ff", "//"..cmd) .. " " .. params
			meta:set_string("description",
				minetest.registered_tools["worldedit:brush"].description .. ": " .. fullcmd)
			worldedit.player_notify(name, S("Brush assigned to command: @1", fullcmd), "ok")
		end
		player:set_wielded_item(itemstack)
	end,
})
