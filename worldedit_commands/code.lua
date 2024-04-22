local S = minetest.get_translator("worldedit_commands")

local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end


worldedit.register_command("lua", {
	params = "<code>",
	description = S("Executes <code> as a Lua chunk in the global namespace"),
	category = S("Code"),
	privs = {worldedit=true, server=true},
	parse = function(param)
		if param == "" then
			return false
		end
		return true, param
	end,
	func = function(name, param)
		-- shorthand like in the Lua interpreter
		if param:sub(1, 1) == "=" then
			param = "return " .. param:sub(2)
		end
		local err, ret = worldedit.lua(param, name)
		if err == nil then
			minetest.log("action", name .. " executed " .. param)
			if ret ~= "nil" then
				worldedit.player_notify(name, "code successfully executed, returned " .. ret, "info")
			else
				worldedit.player_notify(name, "code successfully executed", "ok")
			end
		else
			minetest.log("action", name .. " tried to execute " .. param)
			worldedit.player_notify(name, "code error: " .. err, "error")
		end
	end,
})

worldedit.register_command("luatransform", {
	params = "<code>",
	description = S("Executes <code> as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region"),
	category = S("Code"),
	privs = {worldedit=true, server=true},
	require_pos = 2,
	parse = function(param)
		return true, param
	end,
	nodes_needed = check_region,
	func = function(name, param)
		local err = worldedit.luatransform(worldedit.pos1[name], worldedit.pos2[name], param)
		if err then
			worldedit.player_notify(name, "code error: " .. err, "error")
			minetest.log("action", name.." tried to execute luatransform "..param)
		else
			worldedit.player_notify(name, "code successfully executed", "ok")
			minetest.log("action", name.." executed luatransform "..param)
		end
	end,
})
