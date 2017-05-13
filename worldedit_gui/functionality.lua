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

-- given multiple sets of privileges, produces a single set of privs that would have the same effect as requiring all of them at the same time
local combine_privs = function(...)
	local result = {}
	for i, privs in ipairs({...}) do
		for name, value in pairs(privs) do
			if result[name] ~= nil and result[name] ~= value then --the priv must be both true and false, which can never happen
				return {__fake_priv_that_nobody_has__=true} --privilege table that can never be satisfied
			end
			result[name] = value
		end
	end
	return result
end

-- display node (or unknown_node image otherwise) at specified pos in formspec
local formspec_node = function(pos, nodename)
	return nodename and string.format("item_image[%s;1,1;%s]", pos, nodename)
		or string.format("image[%s;1,1;worldedit_gui_unknown.png]", pos)
end

-- two further priv helpers
local function we_privs(command)
	return minetest.chatcommands["/" .. command].privs
end

local function combine_we_privs(list)
	local args = {}
	for _, t in ipairs(list) do
		table.insert(args, we_privs(t))
	end
	return combine_privs(unpack(args))
end

worldedit.register_gui_function("worldedit_gui_about", {
	name = "About",
	privs = {interact=true},
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	name = "Toggle Inspect",
	privs = we_privs("inspect"),
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

worldedit.register_gui_function("worldedit_gui_region", {
	name = "Get/Set Region",
	privs = combine_we_privs({"p", "pos1", "pos2", "reset", "mark", "unmark", "volume", "fixedpos"}),
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
	name = "Set Nodes",
	privs = we_privs("set"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_set") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_set_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_set_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	if fields.worldedit_gui_set_search or fields.worldedit_gui_set_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
		worldedit.show_page(name, "worldedit_gui_set")
		if fields.worldedit_gui_set_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/set"].func(name, n)
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_replace", {
	name = "Replace Nodes",
	privs = combine_we_privs({"replace", "replaceinverse"}),
	get_formspec = function(name)
		local search, replace = gui_nodename1[name], gui_nodename2[name]
		local search_nodename, replace_nodename = worldedit.normalize_nodename(search), worldedit.normalize_nodename(replace)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_replace") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_replace_search;Name;%s]", minetest.formspec_escape(search)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_replace_search_search;Search]" ..
			formspec_node("5.5,1.1", search_nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_replace_replace;Name;%s]", minetest.formspec_escape(replace)) ..
			"button[4,2.18;1.5,0.8;worldedit_gui_replace_replace_search;Search]" ..
			formspec_node("5.5,2.1", replace_nodename) ..
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

		local submit = nil
		if fields.worldedit_gui_replace_submit then
			submit = "replace"
		elseif fields.worldedit_gui_replace_submit_inverse then
			submit = "replaceinverse"
		end
		if submit then
			local n1 = worldedit.normalize_nodename(gui_nodename1[name])
			local n2 = worldedit.normalize_nodename(gui_nodename2[name])
			if n1 and n2 then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s", n1, n2))
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_sphere_dome", {
	name = "Sphere/Dome",
	privs = combine_we_privs({"hollowsphere", "sphere", "hollowdome", "dome"}),
	get_formspec = function(name)
		local node, radius = gui_nodename1[name], gui_distance2[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,5]" .. worldedit.get_formspec_header("worldedit_gui_sphere_dome") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_sphere_dome_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_sphere_dome_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
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

		local submit = nil
		if fields.worldedit_gui_sphere_dome_submit_hollow then
			submit = "hollowsphere"
		elseif fields.worldedit_gui_sphere_dome_submit_solid then
			submit = "sphere"
		elseif fields.worldedit_gui_sphere_dome_submit_hollow_dome then
			submit = "hollowdome"
		elseif fields.worldedit_gui_sphere_dome_submit_solid_dome then
			submit = "dome"
		end
		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s", gui_distance2[name], n))
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_cylinder", {
	name = "Cylinder",
	privs = combine_we_privs({"hollowcylinder", "cylinder"}),
	get_formspec = function(name)
		local node, axis, length, radius = gui_nodename1[name], gui_axis1[name], gui_distance1[name], gui_distance2[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,5]" .. worldedit.get_formspec_header("worldedit_gui_cylinder") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_cylinder_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_cylinder_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
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

		local submit = nil
		if fields.worldedit_gui_cylinder_submit_hollow then
			submit = "hollowcylinder"
		elseif fields.worldedit_gui_cylinder_submit_solid then
			submit = "cylinder"
		end
		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], gui_distance2[name], n))
			end
		end
		return true
	end
	if fields.worldedit_gui_cylinder_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_cylinder_axis]
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_pyramid", {
	name = "Pyramid",
	privs = we_privs("pyramid"),
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_pyramid") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_pyramid_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_pyramid_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_pyramid_length;Length;%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[4,2.18;2.5;worldedit_gui_pyramid_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_pyramid_submit_hollow;Hollow Pyramid]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_pyramid_submit_solid;Solid Pyramid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_pyramid", function(name, fields)
	if fields.worldedit_gui_pyramid_search or fields.worldedit_gui_pyramid_submit_solid or fields.worldedit_gui_pyramid_submit_hollow or fields.worldedit_gui_pyramid_axis then
		gui_nodename1[name] = tostring(fields.worldedit_gui_pyramid_node)
		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_pyramid_length)
		worldedit.show_page(name, "worldedit_gui_pyramid")

		local submit = nil
		if fields.worldedit_gui_pyramid_submit_solid then
			submit = "pyramid"
		elseif fields.worldedit_gui_pyramid_submit_hollow then
			submit = "hollowpyramid"
		end
		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], n))
			end
		end
		return true
	end
	if fields.worldedit_gui_pyramid_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		worldedit.show_page(name, "worldedit_gui_pyramid")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_spiral", {
	name = "Spiral",
	privs = we_privs("spiral"),
	get_formspec = function(name)
		local node, length, height, space = gui_nodename1[name], gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,6]" .. worldedit.get_formspec_header("worldedit_gui_spiral") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_spiral_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_spiral_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
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
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/spiral"].func(name, string.format("%s %s %s %s", gui_distance1[name], gui_distance2[name], gui_distance3[name], n))
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_copy_move", {
	name = "Copy/Move",
	privs = combine_we_privs({"copy", "move"}),
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
	if fields.worldedit_gui_copy_move_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_copy_move_axis] or 4
		worldedit.show_page(name, "worldedit_gui_copy_move")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stack", {
	name = "Stack",
	privs = we_privs("stack"),
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
	if fields.worldedit_gui_stack_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_stack_axis]
		worldedit.show_page(name, "worldedit_gui_stack")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stretch", {
	name = "Stretch",
	privs = we_privs("stretch"),
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
	name = "Transpose",
	privs = we_privs("transpose"),
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
		worldedit.show_page(name, "worldedit_gui_transpose")
		minetest.chatcommands["/transpose"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], axis_values[gui_axis2[name]]))
		return true
	end
	if fields.worldedit_gui_transpose_axis1 then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_transpose_axis1]
		worldedit.show_page(name, "worldedit_gui_transpose")
		return true
	end
	if fields.worldedit_gui_transpose_axis2 then
		gui_axis2[name] = axis_indices[fields.worldedit_gui_transpose_axis2]
		worldedit.show_page(name, "worldedit_gui_transpose")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_flip", {
	name = "Flip",
	privs = we_privs("flip"),
	get_formspec = function(name)
		local axis = gui_axis1[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_flip") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_flip_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_flip_submit;Flip]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_flip", function(name, fields)
	if fields.worldedit_gui_flip_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_flip_axis]
		worldedit.show_page(name, "worldedit_gui_flip")
		minetest.chatcommands["/flip"].func(name, axis_values[gui_axis1[name]])
		return true
	end
	if fields.worldedit_gui_flip_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_flip_axis]
		worldedit.show_page(name, "worldedit_gui_flip")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_rotate", {
	name = "Rotate",
	privs = we_privs("rotate"),
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
	if fields.worldedit_gui_rotate_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_rotate_axis]
		worldedit.show_page(name, "worldedit_gui_rotate")
		return true
	end
	if fields.worldedit_gui_rotate_angle then
		gui_angle[name] = angle_indices[fields.worldedit_gui_rotate_angle]
		worldedit.show_page(name, "worldedit_gui_rotate")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_orient", {
	name = "Orient",
	privs = we_privs("orient"),
	get_formspec = function(name)
		local angle = gui_angle[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_orient") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_orient_angle;90 degrees,180 degrees,270 degrees;%s]", angle) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_orient_submit;Orient]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_orient", function(name, fields)
	if fields.worldedit_gui_orient_submit then
		gui_angle[name] = angle_indices[fields.worldedit_gui_orient_angle]
		worldedit.show_page(name, "worldedit_gui_orient")
		minetest.chatcommands["/orient"].func(name, tostring(angle_values[gui_angle[name]]))
		return true
	end
	if fields.worldedit_gui_orient_angle then
		gui_angle[name] = angle_indices[fields.worldedit_gui_orient_angle]
		worldedit.show_page(name, "worldedit_gui_orient")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_fixlight", {
	name = "Fix Lighting",
	privs = we_privs("fixlight"),
	on_select = function(name)
		minetest.chatcommands["/fixlight"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_hide", {
	name = "Hide Region",
	privs = we_privs("hide"),
	on_select = function(name)
		minetest.chatcommands["/hide"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_suppress", {
	name = "Suppress Nodes",
	privs = we_privs("suppress"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_suppress") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_suppress_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_suppress_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_suppress_submit;Suppress Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_suppress", function(name, fields)
	if fields.worldedit_gui_suppress_search or fields.worldedit_gui_suppress_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_suppress_node)
		worldedit.show_page(name, "worldedit_gui_suppress")
		if fields.worldedit_gui_suppress_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/suppress"].func(name, n)
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_highlight", {
	name = "Highlight Nodes",
	privs = we_privs("highlight"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_highlight") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_highlight_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_highlight_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_highlight_submit;Highlight Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_highlight", function(name, fields)
	if fields.worldedit_gui_highlight_search or fields.worldedit_gui_highlight_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_highlight_node)
		worldedit.show_page(name, "worldedit_gui_highlight")
		if fields.worldedit_gui_highlight_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/highlight"].func(name, n)
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_restore", {
	name = "Restore Region",
	privs = we_privs("restore"),
	on_select = function(name)
		minetest.chatcommands["/restore"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_save_load", {
	name = "Save/Load",
	privs = combine_we_privs({"save", "allocate", "load"}),
	get_formspec = function(name)
		local filename = gui_filename[name]
		return "size[6,4]" .. worldedit.get_formspec_header("worldedit_gui_save_load") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_save_filename;Filename;%s]", minetest.formspec_escape(filename)) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_save_load_submit_save;Save]" ..
			"button_exit[3,2.5;3,0.8;worldedit_gui_save_load_submit_allocate;Allocate]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_save_load_submit_load;Load]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_save_load", function(name, fields)
	if fields.worldedit_gui_save_load_submit_save or fields.worldedit_gui_save_load_submit_allocate or fields.worldedit_gui_save_load_submit_load then
		gui_filename[name] = tostring(fields.worldedit_gui_save_filename)
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
	privs = we_privs("lua"),
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
		gui_code[name] = fields.worldedit_gui_lua_code
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
	name = "Clear Objects",
	privs = we_privs("clearobjects"),
	on_select = function(name)
		minetest.chatcommands["/clearobjects"].func(name, "")
	end,
})
