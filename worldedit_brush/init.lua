if minetest.raycast == nil then
	error(
		"worldedit_brush requires at least Minetest 5.0"
	)
end

local BRUSH_MAX_DIST = 150
local BRUSH_ALLOWED_COMMANDS = {
	-- basically everything that only needs pos1
	"cube",
	"cylinder",
	"dome",
	"hollowcube",
	"hollowcylinder",
	"hollowdome",
	"hollowpyramid",
	"hollowsphere",
	"load",
	"pyramid",
	"sphere",
	"spiral",

	"cyl",
	"do",
	"hcube",
	"hcyl",
	"hdo",
	"hpyr",
	"hspr",
	"l",
	"pyr",
	"spr",
	"spl",
}
local brush_on_use = function(itemstack, placer)
	local meta = itemstack:get_meta()
	local name = placer:get_player_name()

	local cmd = meta:get_string("command")
	if cmd == "" then
		worldedit.player_notify(name,
			"This brush is not bound, use //brush to bind a command to it.")
		return false
	end
	local cmddef = minetest.registered_chatcommands["/" .. cmd]
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
	worldedit.mark_region(name)
	-- is this a horrible hack? oh yes.
	worldedit._override_safe_regions = true
	local player_notify_old = worldedit.player_notify
	worldedit.player_notify = function(name, msg)
		if string.match(msg, "^%d") then return end -- discard "1234 nodes added."
		return player_notify_old(name, msg)
	end

	minetest.log("action", string.format("%s uses WorldEdit brush (//%s) at %s",
		name, cmd, minetest.pos_to_string(pointed_thing.under)))
	cmddef.func(name, meta:get_string("params"))

	worldedit._override_safe_regions = false
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

minetest.register_chatcommand("/brush", {
	privs = {worldedit=true},
	params = "none/<cmd> [parameters]",
	description = "Assign command to WorldEdit brush item",
	func = function(name, param)
		local found, _, cmd, params = param:find("^([^%s]+)%s+(.+)$")
		if not found then
			params = ""
			found, _, cmd = param:find("^(.+)$")
		end
		if not found then
			worldedit.player_notify(name, "Invalid usage.")
			return
		end

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
			local cmddef
			if table.indexof(BRUSH_ALLOWED_COMMANDS, cmd) ~= -1 then
				cmddef = minetest.registered_chatcommands["/" .. cmd]
			else
				cmddef = nil
			end
			if cmddef == nil then
				worldedit.player_notify(name, "Invalid command for brush use: //" .. cmd)
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
