--provides shorter names for the commands in `worldedit_commands`

--returns true if command could not be aliased, false otherwise
worldedit.alias_chatcommand = function(alias, original_command)
	if not minetest.chatcommands[original_command] then
		minetest.log("error", "worldedit_shortcommands: original command " .. original_command .. " does not exist")
		return true
	end
	if minetest.chatcommands[alias] then
		minetest.log("error", "worldedit_shortcommands: alias " .. alias .. " already exists")
		return true
	end
	minetest.register_chatcommand(alias, minetest.chatcommands[original_command])
	return false
end

worldedit.alias_chatcommand("/i", "/inspect")
worldedit.alias_chatcommand("/rst", "/reset")
worldedit.alias_chatcommand("/mk", "/mark")
worldedit.alias_chatcommand("/umk", "/unmark")
worldedit.alias_chatcommand("/1", "/pos1")
worldedit.alias_chatcommand("/2", "/pos2")
worldedit.alias_chatcommand("/fp", "/fixedpos")
worldedit.alias_chatcommand("/v", "/volume")
worldedit.alias_chatcommand("/s", "/set")
worldedit.alias_chatcommand("/r", "/replace")
worldedit.alias_chatcommand("/ri", "/replaceinverse")
worldedit.alias_chatcommand("/hspr", "/hollowsphere")
worldedit.alias_chatcommand("/spr", "/sphere")
worldedit.alias_chatcommand("/hdo", "/hollowdome")
worldedit.alias_chatcommand("/do", "/dome")
worldedit.alias_chatcommand("/hcyl", "/hollowcylinder")
worldedit.alias_chatcommand("/cyl", "/cylinder")
worldedit.alias_chatcommand("/hpyr", "/hollowpyramid")
worldedit.alias_chatcommand("/pyr", "/pyramid")
worldedit.alias_chatcommand("/spl", "/spiral")
worldedit.alias_chatcommand("/m", "/move")
worldedit.alias_chatcommand("/c", "/copy")
worldedit.alias_chatcommand("/stk", "/stack")
worldedit.alias_chatcommand("/sch", "/stretch")
worldedit.alias_chatcommand("/tps", "/transpose")
worldedit.alias_chatcommand("/fl", "/flip")
worldedit.alias_chatcommand("/rot", "/rotate")
worldedit.alias_chatcommand("/ort", "/orient")
worldedit.alias_chatcommand("/hi", "/hide")
worldedit.alias_chatcommand("/sup", "/suppress")
worldedit.alias_chatcommand("/hlt", "/highlight")
worldedit.alias_chatcommand("/rsr", "/restore")
worldedit.alias_chatcommand("/l", "/lua")
worldedit.alias_chatcommand("/lt", "/luatransform")
worldedit.alias_chatcommand("/clro", "/clearobjects")
