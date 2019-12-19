--provides shorter names for the commands in `worldedit_commands`

worldedit.alias_command = function(alias, original)
	if not worldedit.registered_commands[original] then
		minetest.log("error", "worldedit_shortcommands: original " .. original .. " does not exist")
		return
	end
	if minetest.chatcommands["/" .. alias] then
		minetest.log("error", "worldedit_shortcommands: alias " .. alias .. " already exists")
		return
	end

	minetest.register_chatcommand("/" .. alias, minetest.chatcommands["/" .. original])
	worldedit.registered_commands[alias] = worldedit.registered_commands[original]
end

worldedit.alias_command("i", "inspect")
worldedit.alias_command("rst", "reset")
worldedit.alias_command("mk", "mark")
worldedit.alias_command("umk", "unmark")
worldedit.alias_command("1", "pos1")
worldedit.alias_command("2", "pos2")
worldedit.alias_command("fp", "fixedpos")
worldedit.alias_command("v", "volume")
worldedit.alias_command("s", "set")
worldedit.alias_command("r", "replace")
worldedit.alias_command("ri", "replaceinverse")
worldedit.alias_command("hcube", "hollowcube")
worldedit.alias_command("hspr", "hollowsphere")
worldedit.alias_command("spr", "sphere")
worldedit.alias_command("hdo", "hollowdome")
worldedit.alias_command("do", "dome")
worldedit.alias_command("hcyl", "hollowcylinder")
worldedit.alias_command("cyl", "cylinder")
worldedit.alias_command("hpyr", "hollowpyramid")
worldedit.alias_command("pyr", "pyramid")
worldedit.alias_command("spl", "spiral")
worldedit.alias_command("m", "move")
worldedit.alias_command("c", "copy")
worldedit.alias_command("stk", "stack")
worldedit.alias_command("sch", "stretch")
worldedit.alias_command("tps", "transpose")
worldedit.alias_command("fl", "flip")
worldedit.alias_command("rot", "rotate")
worldedit.alias_command("ort", "orient")
worldedit.alias_command("hi", "hide")
worldedit.alias_command("sup", "suppress")
worldedit.alias_command("hlt", "highlight")
worldedit.alias_command("rsr", "restore")
worldedit.alias_command("l", "lua")
worldedit.alias_command("lt", "luatransform")
worldedit.alias_command("clro", "clearobjects")
