--saved state per player
local gui_nodename1 = {}
local gui_nodename2 = {}
local gui_radius = {}
local gui_formspec = {}

local register_gui_chatcommand = function(identifier, name, command, callback)
	callback = callback or function(name, command) command(name, "") end
	worldedit.register_gui_function(identifier, {
		name = name,
		privs = minetest.chatcommands[command].privs,
		on_select = function(name)
			return callback(name, minetest.chatcommands[command].func)
		end,
	})
end

register_gui_chatcommand("worldedit_gui_about", "About", "/about")
register_gui_chatcommand("worldedit_gui_inspect", "Toggle Inspection", "/inspect", function(name, command)
	command(name, worldedit.inspect[name] and "disable" or "enable")
end)
register_gui_chatcommand("worldedit_gui_reset", "Reset Region", "/reset")
register_gui_chatcommand("worldedit_gui_mark", "Mark Region", "/mark")
register_gui_chatcommand("worldedit_gui_unmark", "Unmark Region", "/unmark")

worldedit.register_gui_function("worldedit_gui_p", {
	name = "Get/Set Positions", privs = minetest.chatcommands["/p"].privs,
	get_formspec = function(name)
		return "size[9,2.5]" .. worldedit.get_formspec_header("worldedit_gui_p") ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;Get Positions]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set1;Set Position 1]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set2;Set Position 2]" ..
			"button_exit[0,2;3,0.8;worldedit_gui_pos1;Position 1 Here]" ..
			"button_exit[3,2;3,0.8;worldedit_gui_pos2;Position 2 Here]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_p", function(name, fields)
	if fields.worldedit_gui_p_get then
		minetest.chatcommands["/p"].func(name, "get")
		return true
	elseif fields.worldedit_gui_p_set1 then
		minetest.chatcommands["/p"].func(name, "set1")
		return true
	elseif fields.worldedit_gui_p_set2 then
		minetest.chatcommands["/p"].func(name, "set2")
		return true
	elseif fields.worldedit_gui_pos1 then
		minetest.chatcommands["/pos1"].func(name, "")
		return true
	elseif fields.worldedit_gui_pos2 then
		minetest.chatcommands["/pos2"].func(name, "")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_fixedpos", { --wip: combine this with get/set positions
	name = "Fixed Positions", privs = minetest.chatcommands["/fixedpos"].privs,
	get_formspec = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_fixedpos") ..
			"label[0,1.2;Position 1]" ..
			string.format("field[2,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1x;Axis X;%s]", pos1 and pos1.x or "") ..
			string.format("field[3.5,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1y;Axis Y;%s]", pos1 and pos1.y or "") ..
			string.format("field[5,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1z;Axis Z;%s]", pos1 and pos1.z or "") ..
			"label[0,2.2;Position 2]" ..
			string.format("field[2,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;Axis X;%s]", pos2 and pos2.x or "") ..
			string.format("field[3.5,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Axis Y;%s]", pos2 and pos2.y or "") ..
			string.format("field[5,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Axis Z;%s]", pos2 and pos2.z or "") ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_fixedpos_submit;Set Positions]"
	end
})

worldedit.register_gui_handler("worldedit_gui_fixedpos", function(name, fields)
	if fields.worldedit_gui_fixedpos_submit then
		local x1, y1, z1 = tonumber(fields.worldedit_gui_fixedpos_pos1x), tonumber(fields.worldedit_gui_fixedpos_pos1y), tonumber(fields.worldedit_gui_fixedpos_pos1z)
		if x1 and y1 and z1 then
			minetest.chatcommands["/fixedpos"].func(name, string.format("set1 %d %d %d", x1, y1, z1))
		end
		local x2, y2, z2 = tonumber(fields.worldedit_gui_fixedpos_pos2x), tonumber(fields.worldedit_gui_fixedpos_pos2y), tonumber(fields.worldedit_gui_fixedpos_pos2z)
		if x2 and y2 and z2 then
			minetest.chatcommands["/fixedpos"].func(name, string.format("set2 %d %d %d", x2, y2, z2))
		end
		return true
	end
	return false
end)

register_gui_chatcommand("worldedit_gui_volume", "Region Volume", "/volume")

worldedit.register_gui_function("worldedit_gui_set", {
	name = "Set Nodes", privs = minetest.chatcommands["/set"].privs,
	get_formspec = function(name)
		local value = gui_nodename1[name] or "Cobblestone"
		local nodename = worldedit.normalize_nodename(value)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_set") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_set_node;Name;%s]", minetest.formspec_escape(value)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_set_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	if fields.worldedit_gui_set_search then
		gui_nodename1[name] = fields.worldedit_gui_set_node
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	elseif fields.worldedit_gui_set_submit then
		gui_nodename1[name] = fields.worldedit_gui_set_node
		minetest.chatcommands["/set"].func(name, gui_nodename1[name])
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_replace", {
	name = "Replace Nodes", privs = minetest.chatcommands["/replace"].privs,
	get_formspec = function(name)
		local search = gui_nodename1[name] or "Cobblestone"
		local search_nodename = worldedit.normalize_nodename(search)
		local replace = gui_nodename2[name] or "Stone"
		local replace_nodename = worldedit.normalize_nodename(replace)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_replace") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_replace_search;Name;%s]", minetest.formspec_escape(search)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_replace_search_search;Search]" ..
			(search_nodename and string.format("item_image[5.5,1.1;1,1;%s]", search_nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_replace_replace;Name;%s]", minetest.formspec_escape(replace)) ..
			"button[4,2.18;1.5,0.8;worldedit_gui_replace_replace_search;Search]" ..
			(replace_nodename and string.format("item_image[5.5,2.1;1,1;%s]", replace_nodename)
				or "image[5.5,2.1;1,1;unknown_node.png]") ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_replace_submit;Replace Nodes]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_replace_submit_inverse;Replace Inverse]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_replace", function(name, fields)
	if fields.worldedit_gui_replace_search_search then
		gui_nodename1[name] = fields.worldedit_gui_replace_search
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_replace_search then
		gui_nodename2[name] = fields.worldedit_gui_replace_replace
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_submit or fields.worldedit_gui_replace_submit_inverse then
		gui_nodename1[name] = fields.worldedit_gui_replace_search
		gui_nodename2[name] = fields.worldedit_gui_replace_replace
		if fields.worldedit_gui_replace_submit then
			minetest.chatcommands["/replace"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		else
			minetest.chatcommands["/replaceinverse"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_sphere", {
	name = "Sphere", privs = minetest.chatcommands["/sphere"].privs,
	get_formspec = function(name)
		local value = gui_nodename1[name] or "Cobblestone"
		local radius = gui_radius[name] or "5"
		local nodename = worldedit.normalize_nodename(value)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_sphere") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_sphere_node;Name;%s]", minetest.formspec_escape(value)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_sphere_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_sphere_radius;Radius;%s]", minetest.formspec_escape(radius)) ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_sphere_submit_hollow;Hollow Sphere]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_sphere_submit_solid;Solid Sphere]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_sphere", function(name, fields)
	if fields.worldedit_gui_sphere_search then
		gui_nodename1[name] = fields.worldedit_gui_sphere_node
		worldedit.show_page(name, "worldedit_gui_sphere")
		return true
	elseif fields.worldedit_gui_sphere_submit_hollow or fields.worldedit_gui_sphere_submit_solid then
		gui_nodename1[name] = fields.worldedit_gui_sphere_node
		gui_radius[name] = fields.worldedit_gui_sphere_radius
		print(minetest.serialize(fields))
		if fields.worldedit_gui_sphere_submit_hollow then
			minetest.chatcommands["/hollowsphere"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		else
			minetest.chatcommands["/sphere"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_formspec_tester", {
	name = "Formspec Tester",
	get_formspec = function(name)
		local value = gui_formspec[name] or ""
		return "size[8,6.5]" .. worldedit.get_formspec_header("worldedit_gui_formspec_tester") ..
			string.format("textarea[0.5,1;7.5,5.5;worldedit_gui_formspec_tester_value;Formspec Code;%s]", minetest.formspec_escape(value)) ..
			"button_exit[0,6;3,0.8;worldedit_gui_formspec_tester_show;Show Formspec]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_formspec_tester", function(name, fields)
	if fields.worldedit_gui_formspec_tester_show then
		gui_formspec[name] = fields.worldedit_gui_formspec_tester_value or ""
		worldedit.show_page(name, "worldedit_gui_formspec_tester")
		minetest.show_formspec(name, "worldedit:formspec_tester", gui_formspec[name])
		return true
	end
	return false
end)