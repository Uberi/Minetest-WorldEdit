--saved state for each player
local gui_nodename1 = {}
local gui_nodename2 = {}
local gui_radius = {}
local gui_axis = {}
local gui_length = {}
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
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[9,6]" .. worldedit.get_formspec_header("worldedit_gui_p") ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;Get Positions]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set1;Choose Position 1]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set2;Choose Position 2]" ..
			"button_exit[0,2;3,0.8;worldedit_gui_pos1;Position 1 Here]" ..
			"button_exit[3,2;3,0.8;worldedit_gui_pos2;Position 2 Here]" ..
			"label[0,3.7;Position 1]" ..
			string.format("field[2,4;1.5,0.8;worldedit_gui_fixedpos_pos1x;X ;%s]", pos1 and pos1.x or "") ..
			string.format("field[3.5,4;1.5,0.8;worldedit_gui_fixedpos_pos1y;Y ;%s]", pos1 and pos1.y or "") ..
			string.format("field[5,4;1.5,0.8;worldedit_gui_fixedpos_pos1z;Z ;%s]", pos1 and pos1.z or "") ..
			"button_exit[6.5,3.68;2.5,0.8;worldedit_gui_fixed_pos1_submit;Set Position 1]" ..
			"label[0,5.2;Position 2]" ..
			string.format("field[2,5.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;X ;%s]", pos2 and pos2.x or "") ..
			string.format("field[3.5,5.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Y ;%s]", pos2 and pos2.y or "") ..
			string.format("field[5,5.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Z ;%s]", pos2 and pos2.z or "") ..
			"button_exit[6.5,5.18;2.5,0.8;worldedit_gui_fixed_pos2_submit;Set Position 2]"
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
		worldedit.show_page(name, "worldedit_gui_p")
		return true
	elseif fields.worldedit_gui_pos2 then
		minetest.chatcommands["/pos2"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_p")
		return true
	elseif fields.worldedit_gui_fixedpos_pos1_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set1 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos1x),
			tostring(fields.worldedit_gui_fixedpos_pos1y),
			tostring(fields.worldedit_gui_fixedpos_pos1z)))
		worldedit.show_page(name, "worldedit_gui_p")
		return true
	elseif fields.worldedit_gui_fixedpos_pos2_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set2 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos2x),
			tostring(fields.worldedit_gui_fixedpos_pos2y),
			tostring(fields.worldedit_gui_fixedpos_pos2z)))
		worldedit.show_page(name, "worldedit_gui_p")
		return true
	end
	return false
end)

register_gui_chatcommand("worldedit_gui_volume", "Region Volume", "/volume")

worldedit.register_gui_function("worldedit_gui_set", {
	name = "Set Nodes", privs = minetest.chatcommands["/set"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name] or "Cobblestone"
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_set") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_set_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_set_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	if fields.worldedit_gui_set_search then
		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	elseif fields.worldedit_gui_set_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
		worldedit.show_page(name, "worldedit_gui_set")
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
		gui_nodename1[name] = tostring(fields.worldedit_gui_replace_search)
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_replace_search then
		gui_nodename2[name] = tostring(fields.worldedit_gui_replace_replace)
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_submit or fields.worldedit_gui_replace_submit_inverse then
		gui_nodename1[name] = tostring(fields.worldedit_gui_replace_search)
		gui_nodename2[name] = tostring(fields.worldedit_gui_replace_replace)
		worldedit.show_page(name, "worldedit_gui_replace")
		if fields.worldedit_gui_replace_submit then
			minetest.chatcommands["/replace"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		else
			minetest.chatcommands["/replaceinverse"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_sphere_dome", {
	name = "Sphere/Dome", privs = minetest.chatcommands["/sphere"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name] or "Cobblestone"
		local radius = gui_radius[name] or "5"
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,5]" .. worldedit.get_formspec_header("worldedit_gui_sphere_dome") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_sphere_dome_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_sphere_dome_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_sphere_dome_radius;Radius;%s]", minetest.formspec_escape(radius)) ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow;Hollow Sphere]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_sphere_dome_submit_solid;Solid Sphere]" ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow_dome;Hollow Dome]" ..
			"button_exit[3.5,4.5;3,0.8;worldedit_gui_sphere_dome_submit_solid_dome;Solid Dome]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_sphere_dome", function(name, fields)
	if fields.worldedit_gui_sphere_dome_search then
		gui_nodename1[name] = tostring(fields.worldedit_gui_sphere_dome_node)
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		return true
	elseif fields.worldedit_gui_sphere_dome_submit_hollow or fields.worldedit_gui_sphere_dome_submit_solid
	or fields.worldedit_gui_sphere_dome_submit_hollow_dome or fields.worldedit_gui_sphere_dome_submit_solid_dome then
		gui_nodename1[name] = tostring(fields.worldedit_gui_sphere_dome_node)
		gui_radius[name] = tostring(fields.worldedit_gui_sphere_dome_radius)
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		if fields.worldedit_gui_sphere_dome_submit_hollow then
			minetest.chatcommands["/hollowsphere"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_sphere_dome_submit_solid then
			minetest.chatcommands["/sphere"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_sphere_dome_submit_hollow_dome then
			minetest.chatcommands["/hollowdome"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		else --fields.worldedit_gui_sphere_dome_submit_solid_dome
			minetest.chatcommands["/dome"].func(name, string.format("%s %s", gui_radius[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_cylinder", {
	name = "Cylinder", privs = minetest.chatcommands["/cylinder"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name] or "Cobblestone"
		local axis = gui_axis[name] or 4
		local length = gui_length[name] or "10"
		local radius = gui_radius[name] or "5"
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,5]" .. worldedit.get_formspec_header("worldedit_gui_cylinder") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_cylinder_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_cylinder_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_cylinder_length;Length;%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[4,2.18;2.5;worldedit_gui_cylinder_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_cylinder_radius;Radius;%s]", minetest.formspec_escape(radius)) ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_cylinder_submit_hollow;Hollow Cylinder]" ..
			"button_exit[3.5,4.5;3,0.8;worldedit_gui_cylinder_submit_solid;Solid Cylinder]"
	end,
})

local axis_indices = {["X axis"]=1, ["Y axis"]=2, ["Z axis"]=3, ["Look direction"]=4}
local axis_values = {"x", "y", "z", "?"}

worldedit.register_gui_handler("worldedit_gui_cylinder", function(name, fields)
	if fields.worldedit_gui_cylinder_search then
		gui_nodename1[name] = fields.worldedit_gui_cylinder_node
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true
	elseif fields.worldedit_gui_cylinder_submit_hollow or fields.worldedit_gui_cylinder_submit_solid then
		gui_nodename1[name] = tostring(fields.worldedit_gui_cylinder_node)
		gui_axis[name] = axis_indices[fields.worldedit_gui_cylinder_axis] or 4
		gui_length[name] = tostring(fields.worldedit_gui_cylinder_length)
		gui_radius[name] = tostring(fields.worldedit_gui_cylinder_radius)
		worldedit.show_page(name, "worldedit_gui_cylinder")
		if fields.worldedit_gui_cylinder_submit_hollow then
			minetest.chatcommands["/hollowcylinder"].func(name, string.format("%s %s %s %s", axis_values[gui_axis[name]], gui_length[name], gui_radius[name], gui_nodename1[name]))
		else --fields.worldedit_gui_cylinder_submit_solid
			minetest.chatcommands["/cylinder"].func(name, string.format("%s %s %s %s", axis_values[gui_axis[name]], gui_length[name], gui_radius[name], gui_nodename1[name]))
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