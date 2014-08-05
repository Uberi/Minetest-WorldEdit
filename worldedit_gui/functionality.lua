--saved state for each player
local gui_nodename1 = {} --mapping of player names to node names (arbitrary strings may also appear as values)
local gui_nodename2 = {} --mapping of player names to node names (arbitrary strings may also appear as values)
local gui_axis1 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_axis2 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_distance1 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance2 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance3 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_count1 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count2 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count3 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_angle = {} --mapping of player names to an angle (one of 90, 180, 270, representing the angle in degrees clockwise)
local gui_filename = {} --mapping of player names to file names (arbitrary strings may also appear as values)
local gui_formspec = {} --mapping of player names to formspecs
local gui_code = {} --mapping of player names to formspecs

--set default values
setmetatable(gui_nodename1, {__index = function() return "Cobblestone" end})
setmetatable(gui_nodename2, {__index = function() return "Stone" end})
setmetatable(gui_axis1,     {__index = function() return 4 end})
setmetatable(gui_axis2,     {__index = function() return 1 end})
setmetatable(gui_distance1, {__index = function() return "10" end})
setmetatable(gui_distance2, {__index = function() return "5" end})
setmetatable(gui_distance3, {__index = function() return "2" end})
setmetatable(gui_count1,     {__index = function() return "3" end})
setmetatable(gui_count2,     {__index = function() return "6" end})
setmetatable(gui_count3,     {__index = function() return "4" end})
setmetatable(gui_angle,     {__index = function() return 90 end})
setmetatable(gui_filename,  {__index = function() return "building" end})
setmetatable(gui_formspec,  {__index = function() return "size[5,5]\nlabel[0,0;Hello, world!]" end})
setmetatable(gui_code,  {__index = function() return "minetest.chat_send_player(\"singleplayer\", \"Hello, world!\")" end})

local axis_indices = {["X axis"]=1, ["Y axis"]=2, ["Z axis"]=3, ["Look direction"]=4}
local axis_values = {"x", "y", "z", "?"}
setmetatable(axis_indices, {__index = function () return 4 end})
setmetatable(axis_values, {__index = function () return "?" end})

local angle_indices = {["90 degrees"]=1, ["180 degrees"]=2, ["270 degrees"]=3}
local angle_values = {90, 180, 270}
setmetatable(angle_indices, {__index = function () return 1 end})
setmetatable(angle_values, {__index = function () return 90 end})

--given multiple sets of privileges, produces a single set of privs that would have the same effect as requiring all of them at the same time
local combine_privs = function(...)
	local result = {}
	for i, privs in ipairs({...}) do
		for name, value in pairs(privs) do
			if result[name] ~= nil and result[name] ~= value then --the priv must be both true and false, which can never happen
				return {__fake_priv_that_nobody_has__=true} --priviledge table that can never be satisfied
			end
			result[name] = value
		end
	end
	return result
end

worldedit.register_gui_function("worldedit_gui_about", {
	name = "About", privs = minetest.chatcommands["/about"].privs,
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	name = "Toggle Inspect", privs = minetest.chatcommands["/inspect"].privs,
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

worldedit.register_gui_function("worldedit_gui_region", {
	name = "Get/Set Region", privs = combine_privs(minetest.chatcommands["/p"].privs, minetest.chatcommands["/pos1"].privs, minetest.chatcommands["/pos2"].privs, minetest.chatcommands["/reset"].privs, minetest.chatcommands["/mark"].privs, minetest.chatcommands["/unmark"].privs, minetest.chatcommands["/volume"].privs, minetest.chatcommands["/fixedpos"].privs),
	get_formspec = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[9,7]" .. worldedit.get_formspec_header("worldedit_gui_region") ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;Get Positions]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set1;Choose Position 1]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set2;Choose Position 2]" ..
			"button_exit[0,2;3,0.8;worldedit_gui_pos1;Position 1 Here]" ..
			"button_exit[3,2;3,0.8;worldedit_gui_pos2;Position 2 Here]" ..
			"button_exit[6,2;3,0.8;worldedit_gui_reset;Reset Region]" ..
			"button_exit[0,3;3,0.8;worldedit_gui_mark;Mark Region]" ..
			"button_exit[3,3;3,0.8;worldedit_gui_unmark;Unmark Region]" ..
			"button_exit[6,3;3,0.8;worldedit_gui_volume;Region Volume]" ..
			"label[0,4.7;Position 1]" ..
			string.format("field[2,5;1.5,0.8;worldedit_gui_fixedpos_pos1x;X ;%s]", pos1 and pos1.x or "") ..
			string.format("field[3.5,5;1.5,0.8;worldedit_gui_fixedpos_pos1y;Y ;%s]", pos1 and pos1.y or "") ..
			string.format("field[5,5;1.5,0.8;worldedit_gui_fixedpos_pos1z;Z ;%s]", pos1 and pos1.z or "") ..
			"button_exit[6.5,4.68;2.5,0.8;worldedit_gui_fixedpos_pos1_submit;Set Position 1]" ..
			"label[0,6.2;Position 2]" ..
			string.format("field[2,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;X ;%s]", pos2 and pos2.x or "") ..
			string.format("field[3.5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Y ;%s]", pos2 and pos2.y or "") ..
			string.format("field[5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Z ;%s]", pos2 and pos2.z or "") ..
			"button_exit[6.5,6.18;2.5,0.8;worldedit_gui_fixedpos_pos2_submit;Set Position 2]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_region", function(name, fields)
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
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_pos2 then
		minetest.chatcommands["/pos2"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_reset then
		minetest.chatcommands["/reset"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_mark then
		minetest.chatcommands["/mark"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_unmark then
		minetest.chatcommands["/unmark"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_volume then
		minetest.chatcommands["/volume"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos1_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set1 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos1x),
			tostring(fields.worldedit_gui_fixedpos_pos1y),
			tostring(fields.worldedit_gui_fixedpos_pos1z)))
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos2_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set2 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos2x),
			tostring(fields.worldedit_gui_fixedpos_pos2y),
			tostring(fields.worldedit_gui_fixedpos_pos2z)))
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_set", {
	name = "Set Nodes", privs = minetest.chatcommands["/set"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name]
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
	if fields.worldedit_gui_set_search or fields.worldedit_gui_set_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
		worldedit.show_page(name, "worldedit_gui_set")
		if fields.worldedit_gui_set_submit then
			minetest.chatcommands["/set"].func(name, gui_nodename1[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_replace", {
	name = "Replace Nodes", privs = combine_privs(minetest.chatcommands["/replace"].privs, minetest.chatcommands["/replaceinverse"].privs),
	get_formspec = function(name)
		local search, replace = gui_nodename1[name], gui_nodename2[name]
		local search_nodename, replace_nodename = worldedit.normalize_nodename(search), worldedit.normalize_nodename(replace)
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
	if fields.worldedit_gui_replace_search_search or fields.worldedit_gui_replace_replace_search
	or fields.worldedit_gui_replace_submit or fields.worldedit_gui_replace_submit_inverse then
		gui_nodename1[name] = tostring(fields.worldedit_gui_replace_search)
		gui_nodename2[name] = tostring(fields.worldedit_gui_replace_replace)
		worldedit.show_page(name, "worldedit_gui_replace")
		if fields.worldedit_gui_replace_submit then
			minetest.chatcommands["/replace"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		elseif fields.worldedit_gui_replace_submit_inverse then
			minetest.chatcommands["/replaceinverse"].func(name, string.format("%s %s", gui_nodename1[name], gui_nodename2[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_sphere_dome", {
	name = "Sphere/Dome", privs = combine_privs(minetest.chatcommands["/hollowsphere"].privs, minetest.chatcommands["/sphere"].privs, minetest.chatcommands["/hollowdome"].privs, minetest.chatcommands["/dome"].privs),
	get_formspec = function(name)
		local node, radius = gui_nodename1[name], gui_distance2[name]
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
	if fields.worldedit_gui_sphere_dome_search
	or fields.worldedit_gui_sphere_dome_submit_hollow or fields.worldedit_gui_sphere_dome_submit_solid
	or fields.worldedit_gui_sphere_dome_submit_hollow_dome or fields.worldedit_gui_sphere_dome_submit_solid_dome then
		gui_nodename1[name] = tostring(fields.worldedit_gui_sphere_dome_node)
		gui_distance2[name] = tostring(fields.worldedit_gui_sphere_dome_radius)
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		if fields.worldedit_gui_sphere_dome_submit_hollow then
			minetest.chatcommands["/hollowsphere"].func(name, string.format("%s %s", gui_distance2[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_sphere_dome_submit_solid then
			minetest.chatcommands["/sphere"].func(name, string.format("%s %s", gui_distance2[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_sphere_dome_submit_hollow_dome then
			minetest.chatcommands["/hollowdome"].func(name, string.format("%s %s", gui_distance2[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_sphere_dome_submit_solid_dome then
			minetest.chatcommands["/dome"].func(name, string.format("%s %s", gui_distance2[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_cylinder", {
	name = "Cylinder", privs = combine_privs(minetest.chatcommands["/hollowcylinder"].privs, minetest.chatcommands["/cylinder"].privs),
	get_formspec = function(name)
		local node, axis, length, radius = gui_nodename1[name], gui_axis1[name], gui_distance1[name], gui_distance2[name]
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

worldedit.register_gui_handler("worldedit_gui_cylinder", function(name, fields)
	if fields.worldedit_gui_cylinder_search
	or fields.worldedit_gui_cylinder_submit_hollow or fields.worldedit_gui_cylinder_submit_solid then
		gui_nodename1[name] = tostring(fields.worldedit_gui_cylinder_node)
		gui_axis1[name] = axis_indices[fields.worldedit_gui_cylinder_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_cylinder_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_cylinder_radius)
		worldedit.show_page(name, "worldedit_gui_cylinder")
		if fields.worldedit_gui_cylinder_submit_hollow then
			minetest.chatcommands["/hollowcylinder"].func(name, string.format("%s %s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], gui_distance2[name], gui_nodename1[name]))
		elseif fields.worldedit_gui_cylinder_submit_solid then
			minetest.chatcommands["/cylinder"].func(name, string.format("%s %s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], gui_distance2[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_pyramid", {
	name = "Pyramid", privs = minetest.chatcommands["/pyramid"].privs,
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_pyramid") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_pyramid_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_pyramid_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_pyramid_length;Length;%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[4,2.18;2.5;worldedit_gui_pyramid_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_pyramid_submit;Pyramid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_pyramid", function(name, fields)
	if fields.worldedit_gui_pyramid_search or fields.worldedit_gui_pyramid_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_pyramid_node)
		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_pyramid_length)
		worldedit.show_page(name, "worldedit_gui_pyramid")
		if fields.worldedit_gui_pyramid_submit then
			minetest.chatcommands["/pyramid"].func(name, string.format("%s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_spiral", {
	name = "Spiral", privs = minetest.chatcommands["/spiral"].privs,
	get_formspec = function(name)
		local node, length, height, space = gui_nodename1[name], gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,6]" .. worldedit.get_formspec_header("worldedit_gui_spiral") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_spiral_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_spiral_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_spiral_length;Side Length;%s]", minetest.formspec_escape(length)) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_spiral_height;Height;%s]", minetest.formspec_escape(height)) ..
			string.format("field[0.5,4.5;4,0.8;worldedit_gui_spiral_space;Wall Spacing;%s]", minetest.formspec_escape(space)) ..
			"button_exit[0,5.5;3,0.8;worldedit_gui_spiral_submit;Spiral]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_spiral", function(name, fields)
	if fields.worldedit_gui_spiral_search or fields.worldedit_gui_spiral_submit then
		gui_nodename1[name] = fields.worldedit_gui_spiral_node
		gui_distance1[name] = tostring(fields.worldedit_gui_spiral_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_spiral_height)
		gui_distance3[name] = tostring(fields.worldedit_gui_spiral_space)
		worldedit.show_page(name, "worldedit_gui_spiral")
		if fields.worldedit_gui_spiral_submit then
			minetest.chatcommands["/spiral"].func(name, string.format("%s %s %s %s", gui_distance1[name], gui_distance2[name], gui_distance3[name], gui_nodename1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_copy_move", {
	name = "Copy/Move", privs = combine_privs(minetest.chatcommands["/copy"].privs, minetest.chatcommands["/move"].privs),
	get_formspec = function(name)
		local axis = gui_axis1[name] or 4
		local amount = gui_distance1[name] or "10"
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_copy_move") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_copy_move_amount;Amount;%s]", minetest.formspec_escape(amount)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_copy_move_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_copy_move_copy;Copy Region]" ..
			"button_exit[3.5,2.5;3,0.8;worldedit_gui_copy_move_move;Move Region]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_copy_move", function(name, fields)
	if fields.worldedit_gui_copy_move_copy or fields.worldedit_gui_copy_move_move then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_copy_move_axis] or 4
		gui_distance1[name] = tostring(fields.worldedit_gui_copy_move_amount)
		worldedit.show_page(name, "worldedit_gui_copy_move")
		if fields.worldedit_gui_copy_move_copy then
			minetest.chatcommands["/copy"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_distance1[name]))
		else --fields.worldedit_gui_copy_move_move
			minetest.chatcommands["/move"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_distance1[name]))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stack", {
	name = "Stack", privs = minetest.chatcommands["/stack"].privs,
	get_formspec = function(name)
		local axis, count = gui_axis1[name], gui_count1[name]
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_stack") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stack_count;Count;%s]", minetest.formspec_escape(count)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_stack_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_stack_submit;Stack]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stack", function(name, fields)
	if fields.worldedit_gui_stack_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_stack_axis]
		gui_count1[name] = tostring(fields.worldedit_gui_stack_count)
		worldedit.show_page(name, "worldedit_gui_stack")
		minetest.chatcommands["/stack"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_count1[name]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stretch", {
	name = "Stretch", privs = minetest.chatcommands["/stretch"].privs,
	get_formspec = function(name)
		local stretchx, stretchy, stretchz = gui_count1[name], gui_count2[name], gui_count3[name]
		return "size[5,5]" .. worldedit.get_formspec_header("worldedit_gui_stretch") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stretch_x;Stretch X;%s]", minetest.formspec_escape(stretchx)) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_stretch_y;Stretch Y;%s]", minetest.formspec_escape(stretchy)) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_stretch_z;Stretch Z;%s]", minetest.formspec_escape(stretchz)) ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_stretch_submit;Stretch]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stretch", function(name, fields)
	if fields.worldedit_gui_stretch_submit then
		gui_count1[name] = tostring(fields.worldedit_gui_stretch_x)
		gui_count2[name] = tostring(fields.worldedit_gui_stretch_y)
		gui_count3[name] = tostring(fields.worldedit_gui_stretch_z)
		worldedit.show_page(name, "worldedit_gui_stretch")
		minetest.chatcommands["/stretch"].func(name, string.format("%s %s %s", gui_count1[name], gui_count2[name], gui_count3[name]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_transpose", {
	name = "Transpose", privs = minetest.chatcommands["/transpose"].privs,
	get_formspec = function(name)
		local axis1, axis2 = gui_axis1[name], gui_axis2[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_transpose") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_transpose_axis1;X axis,Y axis,Z axis,Look direction;%d]", axis1) ..
			string.format("dropdown[3,1;2.5;worldedit_gui_transpose_axis2;X axis,Y axis,Z axis,Look direction;%d]", axis2) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_transpose_submit;Transpose]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_transpose", function(name, fields)
	if fields.worldedit_gui_transpose_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_transpose_axis1]
		gui_axis2[name] = axis_indices[fields.worldedit_gui_transpose_axis2]
		worldedit.show_page(name, "worldedit_gui_transpose")
		minetest.chatcommands["/transpose"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], axis_values[gui_axis2[name]]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_flip", {
	name = "Flip", privs = minetest.chatcommands["/flip"].privs,
	get_formspec = function(name)
		local axis = gui_axis2[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_flip") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_flip_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_flip_submit;Flip]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_flip", function(name, fields)
	if fields.worldedit_gui_flip_submit then
		gui_axis2[name] = axis_indices[fields.worldedit_gui_flip_axis]
		worldedit.show_page(name, "worldedit_gui_flip")
		minetest.chatcommands["/flip"].func(name, axis_values[gui_axis2[name]])
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_rotate", {
	name = "Rotate", privs = minetest.chatcommands["/rotate"].privs,
	get_formspec = function(name)
		local axis, angle = gui_axis1[name], gui_angle[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_rotate") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_rotate_angle;90 degrees,180 degrees,270 degrees;%s]", angle) ..
			string.format("dropdown[3,1;2.5;worldedit_gui_rotate_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_rotate_submit;Rotate]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_rotate", function(name, fields)
	if fields.worldedit_gui_rotate_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_rotate_axis]
		gui_angle[name] = angle_indices[fields.worldedit_gui_rotate_angle]
		worldedit.show_page(name, "worldedit_gui_rotate")
		minetest.chatcommands["/rotate"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], angle_values[gui_angle[name]]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_orient", {
	name = "Orient", privs = minetest.chatcommands["/orient"].privs,
	get_formspec = function(name)
		local angle = gui_angle[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_orient") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_rotate_angle;90 degrees,180 degrees,270 degrees;%s]", angle) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_orient_submit;Orient]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_orient", function(name, fields)
	if fields.worldedit_gui_orient_submit then
		gui_angle[name] = angle_indices[fields.worldedit_gui_orient_angle]
		worldedit.show_page(name, "worldedit_gui_orient")
		minetest.chatcommands["/orient"].func(name, angle_values[gui_angle[name]])
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_fixlight", {
	name = "Fix Lighting", privs = minetest.chatcommands["/fixlight"].privs,
	on_select = function(name)
		minetest.chatcommands["/fixlight"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_hide", {
	name = "Hide Region", privs = minetest.chatcommands["/hide"].privs,
	on_select = function(name)
		minetest.chatcommands["/hide"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_suppress", {
	name = "Suppress Nodes", privs = minetest.chatcommands["/suppress"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_suppress") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_suppress_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_suppress_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_suppress_submit;Suppress Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_suppress", function(name, fields)
	if fields.worldedit_gui_suppress_search or fields.worldedit_gui_suppress_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_suppress_node)
		worldedit.show_page(name, "worldedit_gui_suppress")
		if fields.worldedit_gui_suppress_submit then
			minetest.chatcommands["/suppress"].func(name, gui_nodename1[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_highlight", {
	name = "Highlight Nodes", privs = minetest.chatcommands["/highlight"].privs,
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_highlight") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_highlight_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_highlight_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.1;1,1;%s]", nodename)
				or "image[5.5,1.1;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_highlight_submit;Highlight Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_highlight", function(name, fields)
	if fields.worldedit_gui_highlight_search or fields.worldedit_gui_highlight_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_highlight_node)
		worldedit.show_page(name, "worldedit_gui_highlight")
		if fields.worldedit_gui_highlight_submit then
			minetest.chatcommands["/highlight"].func(name, gui_nodename1[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_restore", {
	name = "Restore Region", privs = minetest.chatcommands["/restore"].privs,
	on_select = function(name)
		minetest.chatcommands["/restore"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_save_load", {
	name = "Save/Load", privs = combine_privs(minetest.chatcommands["/save"].privs, minetest.chatcommands["/allocate"].privs, minetest.chatcommands["/load"].privs),
	get_formspec = function(name)
		local filename = gui_filename[name]
		return "size[6,4]" .. worldedit.get_formspec_header("worldedit_gui_save_load") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_save_filename;Filename;%s]", minetest.formspec_escape(filename)) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_save_load_submit_save;Save]" ..
			"button_exit[3,2.5;3,0.8;worldedit_gui_save_load_submit_allocate;Allocate]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_save_load_submit_load;Load]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_save", function(name, fields)
	if fields.worldedit_gui_save_load_submit_save or worldedit_gui_save_load_submit_allocate or worldedit_gui_save_load_submit_load then
		gui_filename[name] = tostring(fields.worldedit_gui_save_axis)
		worldedit.show_page(name, "worldedit_gui_save_load")
		if fields.worldedit_gui_save_load_submit_save then
			minetest.chatcommands["/save"].func(name, gui_filename[name])
		elseif fields.worldedit_gui_save_load_submit_allocate then
			minetest.chatcommands["/allocate"].func(name, gui_filename[name])
		else --fields.worldedit_gui_save_load_submit_load
			minetest.chatcommands["/load"].func(name, gui_filename[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_lua", {
	name = "Run Lua",
	get_formspec = function(name)
		local code = gui_code[name]
		return "size[8,6.5]" .. worldedit.get_formspec_header("worldedit_gui_lua") ..
			string.format("textarea[0.5,1;7.5,5.5;worldedit_gui_lua_code;Lua Code;%s]", minetest.formspec_escape(code)) ..
			"button_exit[0,6;3,0.8;worldedit_gui_lua_run;Run Lua]" ..
			"button_exit[5,6;3,0.8;worldedit_gui_lua_transform;Lua Transform]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_lua", function(name, fields)
	if fields.worldedit_gui_lua_run or fields.worldedit_gui_lua_transform then
		gui_code[name] = fields.worldedit_gui_lua_value
		worldedit.show_page(name, "worldedit_gui_lua")
		if fields.worldedit_gui_lua_run then
			minetest.chatcommands["/lua"].func(name, gui_code[name])
		else --fields.worldedit_gui_lua_transform
			minetest.chatcommands["/luatransform"].func(name, gui_code[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_clearobjects", {
	name = "Clear Objects", privs = minetest.chatcommands["/clearobjects"].privs,
	on_select = function(name)
		minetest.chatcommands["/clearobjects"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_formspec_tester", {
	name = "Formspec Tester",
	get_formspec = function(name)
		local value = gui_formspec[name]
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
