if minetest.raycast == nil then
	error(
		"worldedit_brush requires at least Minetest 5.0"
	)
end

local BRUSH_MAX_DIST = 150
local brush_on_use = function(itemstack, placer)
	local meta = itemstack:get_meta()
	local name = placer:get_player_name()

	local cmd = meta:get_string("command")
	if cmd == "" then
		worldedit.player_notify(name,
			"This brush is not bound, use //brush to bind a command to it.")
		return false
	end

	local cmddef = worldedit.registered_commands[cmd]
	if cmddef == nil then return false end -- shouldn't happen as //brush checks this

	local has_privs, missing_privs = minetest.check_player_privs(name, cmddef.privs)
	if not has_privs then
		worldedit.player_notify(name,
			"Missing privileges: " .. table.concat(missing_privs, ", "))
		return false
	end

	local raybegin = vector.add(placer:get_pos(),
		{x=0, y=placer:get_properties().eye_height, z=0})
	local rayend = vector.add(raybegin, vector.multiply(placer:get_look_dir(), BRUSH_MAX_DIST))
	local ray = minetest.raycast(raybegin, rayend, false, true)
	local pointed_thing = ray:next()
	if pointed_thing == nil then
		worldedit.player_notify(name, "Too far away.")
		return false
	end

	assert(pointed_thing.type == "node")
	worldedit.pos1[name] = pointed_thing.under
	worldedit.pos2[name] = nil
	worldedit.marker_update(name)

	-- this isn't really clean...
	local player_notify_old = worldedit.player_notify
	worldedit.player_notify = function(name, msg)
		if string.match(msg, "^%d") then return end -- discard "1234 nodes added."
		return player_notify_old(name, msg)
	end

	assert(cmddef.require_pos < 2)
	local parsed = {cmddef.parse(meta:get_string("params"))}
	if not table.remove(parsed, 1) then return false end -- shouldn't happen

	minetest.log("action", string.format("%s uses WorldEdit brush (//%s) at %s",
		name, cmd, minetest.pos_to_string(pointed_thing.under)))
	cmddef.func(name, unpack(parsed))

	worldedit.player_notify = player_notify_old
	return true
end

minetest.register_tool(":worldedit:brush", {
	description = "WorldEdit Brush",
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
	description = "Assign command to WorldEdit brush item",
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
		local itemstack = minetest.get_player_by_name(name):get_wielded_item()
		if itemstack == nil or itemstack:get_name() ~= "worldedit:brush" then
			worldedit.player_notify(name, "Not holding brush item.")
			return
		end

		cmd = cmd:lower()
		local meta = itemstack:get_meta()
		if cmd == "none" then
			meta:from_table(nil)
			worldedit.player_notify(name, "Brush assignment cleared.")
		else
			local cmddef = worldedit.registered_commands[cmd]
			if cmddef == nil or cmddef.require_pos ~= 1 then
				worldedit.player_notify(name, "//" .. cmd .. " cannot be used with brushes")
				return
			end

			-- Try parsing command params so we can give the user feedback
			local ok, err = cmddef.parse(params)
			if not ok then
				err = err or "invalid usage"
				worldedit.player_notify(name, "Error with brush command: " .. err)
				return
			end

			meta:set_string("command", cmd)
			meta:set_string("params", params)
			local fullcmd = "//" .. cmd .. " " .. params
			meta:set_string("description",
				minetest.registered_tools["worldedit:brush"].description .. ": " .. fullcmd)
			worldedit.player_notify(name, "Brush assigned to command: " .. fullcmd)
		end
		minetest.get_player_by_name(name):set_wielded_item(itemstack)
	end,
})
