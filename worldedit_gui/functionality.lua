--saved state for each player
local gui_nodename1 = {} --mapping of player names to node names
local gui_nodename2 = {} --mapping of player names to node names
local gui_axis1 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_axis2 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_distance1 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance2 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance3 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_count1 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count2 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count3 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_angle = {} --mapping of player names to an angle (one of 90, 180, 270, representing the angle in degrees clockwise)
local gui_filename = {} --mapping of player names to file names
local gui_param2 = {} --mapping of player names to param2 values

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
setmetatable(gui_param2,    {__index = function() return "0" end})

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
	local ndef = nodename and minetest.registered_nodes[nodename]
	if nodename and ndef then
		return string.format("item_image[%s;1,1;%s]", pos, nodename) ..
			string.format("tooltip[%s;1,1;%s]", pos, minetest.formspec_escape(ndef.description))
	else
		return string.format("image[%s;1,1;worldedit_gui_unknown.png]", pos)
	end
end

-- two further priv helpers
local function we_privs(command)
	return worldedit.registered_commands[command].privs
end

local function combine_we_privs(list)
	local args = {}
	for _, t in ipairs(list) do
		table.insert(args, we_privs(t))
	end
	return combine_privs(unpack(args))
end

-- functions that handle value changing & page reshowing (without submitting)
local function copy_changes(name, fields, def)
	for field, into in pairs(def) do
		if into ~= true and fields[field] then
			local value = tostring(fields[field])
			if into == gui_axis1 or into == gui_axis2 then
				into[name] = axis_indices[value]
			elseif into == gui_angle then
				into[name] = angle_indices[value]
			else
				into[name] = value
			end
		end
	end
end

local function handle_changes(name, identifier, fields, def)
	local any = false
	for field, into in pairs(def) do
		if fields.key_enter_field == field then
			any = true
		end
		-- first condition: buttons (value not saved)
		-- others: dropdowns which will be sent when their value changes
		if into == true or into == gui_axis1 or into == gui_axis2 or into == gui_angle then
			if fields[field] then
				any = true
			end
		end
	end
	if not any then
		return false
	end

	any = false
	for field, into in pairs(def) do
		if into ~= true and fields[field] then
			local value = tostring(fields[field])
			if into == gui_axis1 or into == gui_axis2 then
				into[name] = axis_indices[value]
			elseif into == gui_angle then
				into[name] = angle_indices[value]
			else
				into[name] = value
			end

			if into == gui_nodename1 or into == gui_nodename2 then
				any = true
			end
		end
	end
	-- Only nodename fields change based on the value, so only re-show the page if necessary
	if any then
		worldedit.show_page(name, identifier)
	end
	return true
end

-- This has the same behaviour as the player invoking the chat command
local function execute_worldedit_command(command_name, player_name, params)
	local chatcmd = minetest.registered_chatcommands["/" .. command_name]
	assert(chatcmd, "unknown command: " .. command_name)
	local _, msg = chatcmd.func(player_name, params)
	if msg then
		 worldedit.player_notify(player_name, msg)
	end
end

worldedit.register_gui_function("worldedit_gui_about", {
	name = "About",
	privs = {interact=true},
	on_select = function(name)
		execute_worldedit_command("about", name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	name = "Toggle Inspect",
	privs = we_privs("inspect"),
	on_select = function(name)
		execute_worldedit_command("inspect", name,
			worldedit.inspect[name] and "disable" or "enable")
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
		execute_worldedit_command("p", name, "get")
		return true
	elseif fields.worldedit_gui_p_set1 then
		execute_worldedit_command("p", name, "set1")
		return true
	elseif fields.worldedit_gui_p_set2 then
		execute_worldedit_command("p", name, "set2")
		return true
	elseif fields.worldedit_gui_pos1 then
		execute_worldedit_command("pos1", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_pos2 then
		execute_worldedit_command("pos2", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_reset then
		execute_worldedit_command("reset", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_mark then
		execute_worldedit_command("mark", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_unmark then
		execute_worldedit_command("unmark", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_volume then
		execute_worldedit_command("volume", name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos1_submit then
		execute_worldedit_command("fixedpos", name, ("set1 %s %s %s"):format(
			tostring(fields.worldedit_gui_fixedpos_pos1x),
			tostring(fields.worldedit_gui_fixedpos_pos1y),
			tostring(fields.worldedit_gui_fixedpos_pos1z)))
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos2_submit then
		execute_worldedit_command("fixedpos", name, ("set2 %s %s %s"):format(
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
			"field_close_on_enter[worldedit_gui_set_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_set_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	local cg = {
		worldedit_gui_set_search = true,
		worldedit_gui_set_node = gui_nodename1,
	}
	local ret = handle_changes(name, "worldedit_gui_set", fields, cg)
	if fields.worldedit_gui_set_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_set")

		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command("set", name, n)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_replace", {
	name = "Replace Nodes",
	privs = combine_we_privs({"replace", "replaceinverse"}),
	get_formspec = function(name)
		local search, replace = gui_nodename1[name], gui_nodename2[name]
		local search_nodename, replace_nodename = worldedit.normalize_nodename(search), worldedit.normalize_nodename(replace)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_replace") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_replace_search;Name;%s]", minetest.formspec_escape(search)) ..
			"field_close_on_enter[worldedit_gui_replace_search;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_replace_search_search;Search]" ..
			formspec_node("5.5,1.1", search_nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_replace_replace;Name;%s]", minetest.formspec_escape(replace)) ..
			"field_close_on_enter[worldedit_gui_replace_replace;false]" ..
			"button[4,2.18;1.5,0.8;worldedit_gui_replace_replace_search;Search]" ..
			formspec_node("5.5,2.1", replace_nodename) ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_replace_submit;Replace Nodes]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_replace_submit_inverse;Replace Inverse]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_replace", function(name, fields)
	local cg = {
		worldedit_gui_replace_search_search = true,
		worldedit_gui_replace_replace_search = true,
		worldedit_gui_replace_search = gui_nodename1,
		worldedit_gui_replace_replace = gui_nodename2,
	}
	local ret = handle_changes(name, "worldedit_gui_replace", fields, cg)
	if fields.worldedit_gui_replace_submit or fields.worldedit_gui_replace_submit_inverse then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_replace")

		local submit = "replace"
		if fields.worldedit_gui_replace_submit_inverse then
			submit = "replaceinverse"
		end
		local n1 = worldedit.normalize_nodename(gui_nodename1[name])
		local n2 = worldedit.normalize_nodename(gui_nodename2[name])
		if n1 and n2 then
			execute_worldedit_command(submit, name, n1 .. " " .. n2)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_sphere_dome", {
	name = "Sphere/Dome",
	privs = combine_we_privs({"hollowsphere", "sphere", "hollowdome", "dome"}),
	get_formspec = function(name)
		local node, radius = gui_nodename1[name], gui_distance2[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,5]" .. worldedit.get_formspec_header("worldedit_gui_sphere_dome") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_sphere_dome_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_sphere_dome_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_sphere_dome_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_sphere_dome_radius;Radius;%s]", minetest.formspec_escape(radius)) ..
			"field_close_on_enter[worldedit_gui_sphere_dome_radius;false]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow;Hollow Sphere]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_sphere_dome_submit_solid;Solid Sphere]" ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow_dome;Hollow Dome]" ..
			"button_exit[3.5,4.5;3,0.8;worldedit_gui_sphere_dome_submit_solid_dome;Solid Dome]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_sphere_dome", function(name, fields)
	local cg = {
		worldedit_gui_sphere_dome_search = true,
		worldedit_gui_sphere_dome_node = gui_nodename1,
		worldedit_gui_sphere_dome_radius = gui_distance2,
	}
	local ret = handle_changes(name, "worldedit_gui_sphere_dome", fields, cg)
	if fields.worldedit_gui_sphere_dome_submit_hollow or fields.worldedit_gui_sphere_dome_submit_solid
	or fields.worldedit_gui_sphere_dome_submit_hollow_dome or fields.worldedit_gui_sphere_dome_submit_solid_dome then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_sphere_dome")

		local submit = "hollowsphere"
		if fields.worldedit_gui_sphere_dome_submit_solid then
			submit = "sphere"
		elseif fields.worldedit_gui_sphere_dome_submit_hollow_dome then
			submit = "hollowdome"
		elseif fields.worldedit_gui_sphere_dome_submit_solid_dome then
			submit = "dome"
		end
		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command(submit, name,
				gui_distance2[name] .. " " .. n)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_cylinder", {
	name = "Cylinder",
	privs = combine_we_privs({"hollowcylinder", "cylinder"}),
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local radius1, radius2 = gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,6]" .. worldedit.get_formspec_header("worldedit_gui_cylinder") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_cylinder_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_cylinder_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_cylinder_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_cylinder_length;Length;%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[4,2.18;2.5;worldedit_gui_cylinder_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			string.format("field[0.5,3.5;2,0.8;worldedit_gui_cylinder_radius1;Base Radius;%s]", minetest.formspec_escape(radius1)) ..
			string.format("field[2.5,3.5;2,0.8;worldedit_gui_cylinder_radius2;Top Radius;%s]", minetest.formspec_escape(radius2)) ..
			"field_close_on_enter[worldedit_gui_cylinder_length;false]" ..
			"field_close_on_enter[worldedit_gui_cylinder_radius1;false]" ..
			"field_close_on_enter[worldedit_gui_cylinder_radius2;false]" ..
			"label[0.25,4;Equal base and top radius creates a cylinder,\n"..
				"zero top radius creates a cone.\nConsult documentation for more information.]"..
			"button_exit[0,5.5;3,0.8;worldedit_gui_cylinder_submit_hollow;Hollow Cylinder]" ..
			"button_exit[3.5,5.5;3,0.8;worldedit_gui_cylinder_submit_solid;Solid Cylinder]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cylinder", function(name, fields)
	local cg = {
		worldedit_gui_cylinder_search = true,
		worldedit_gui_cylinder_node = gui_nodename1,
		worldedit_gui_cylinder_axis = gui_axis1,
		worldedit_gui_cylinder_length = gui_distance1,
		worldedit_gui_cylinder_radius1 = gui_distance2,
		worldedit_gui_cylinder_radius2 = gui_distance3,
	}
	local ret = handle_changes(name, "worldedit_gui_cylinder", fields, cg)
	if fields.worldedit_gui_cylinder_submit_hollow or fields.worldedit_gui_cylinder_submit_solid then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_cylinder")

		local submit = "hollowcylinder"
		if fields.worldedit_gui_cylinder_submit_solid then
			submit = "cylinder"
		end
		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			local args = string.format("%s %s %s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], gui_distance2[name], gui_distance3[name], n)
			execute_worldedit_command(submit, name, args)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_pyramid", {
	name = "Pyramid",
	privs = we_privs("pyramid"),
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_pyramid") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_pyramid_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_pyramid_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_pyramid_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_pyramid_length;Length;%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[4,2.18;2.5;worldedit_gui_pyramid_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"field_close_on_enter[worldedit_gui_pyramid_length;false]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_pyramid_submit_hollow;Hollow Pyramid]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_pyramid_submit_solid;Solid Pyramid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_pyramid", function(name, fields)
	local cg = {
		worldedit_gui_pyramid_search = true,
		worldedit_gui_pyramid_node = gui_nodename1,
		worldedit_gui_pyramid_axis = gui_axis1,
		worldedit_gui_pyramid_length = gui_distance1,
	}
	local ret = handle_changes(name, "worldedit_gui_pyramid", fields, cg)
	if fields.worldedit_gui_pyramid_submit_solid or fields.worldedit_gui_pyramid_submit_hollow then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_pyramid")

		local submit = "pyramid"
		if fields.worldedit_gui_pyramid_submit_hollow then
			submit = "hollowpyramid"
		end
		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command(submit, name,
				string.format("%s %s %s", axis_values[gui_axis1[name]],
				gui_distance1[name], n))
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_spiral", {
	name = "Spiral",
	privs = we_privs("spiral"),
	get_formspec = function(name)
		local node, length, height, space = gui_nodename1[name], gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,6]" .. worldedit.get_formspec_header("worldedit_gui_spiral") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_spiral_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_spiral_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_spiral_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_spiral_length;Side Length;%s]", minetest.formspec_escape(length)) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_spiral_height;Height;%s]", minetest.formspec_escape(height)) ..
			string.format("field[0.5,4.5;4,0.8;worldedit_gui_spiral_space;Wall Spacing;%s]", minetest.formspec_escape(space)) ..
			"field_close_on_enter[worldedit_gui_spiral_length;false]" ..
			"field_close_on_enter[worldedit_gui_spiral_height;false]" ..
			"field_close_on_enter[worldedit_gui_spiral_space;false]" ..
			"button_exit[0,5.5;3,0.8;worldedit_gui_spiral_submit;Spiral]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_spiral", function(name, fields)
	local cg = {
		worldedit_gui_spiral_search = true,
		worldedit_gui_spiral_node = gui_nodename1,
		worldedit_gui_spiral_length = gui_distance1,
		worldedit_gui_spiral_height = gui_distance2,
		worldedit_gui_spiral_space = gui_distance3,
	}
	local ret = handle_changes(name, "worldedit_gui_spiral", fields, cg)
	if fields.worldedit_gui_spiral_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_spiral")

		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command("spiral", name,
				string.format("%s %s %s %s", gui_distance1[name],
				gui_distance2[name], gui_distance3[name], n))
		end
		return true
	end
	return ret
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
			"field_close_on_enter[worldedit_gui_copy_move_amount;false]" ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_copy_move_copy;Copy Region]" ..
			"button_exit[3.5,2.5;3,0.8;worldedit_gui_copy_move_move;Move Region]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_copy_move", function(name, fields)
	local cg = {
		worldedit_gui_copy_move_amount = gui_distance1,
		worldedit_gui_copy_move_axis = gui_axis1,
	}
	local ret = handle_changes(name, "worldedit_gui_spiral", fields, cg)
	if fields.worldedit_gui_copy_move_copy or fields.worldedit_gui_copy_move_move then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_copy_move")

		local submit = "copy"
		if fields.worldedit_gui_copy_move_move then
			submit = "move"
		end
		execute_worldedit_command(submit, name,
			axis_values[gui_axis1[name]] .. " " .. gui_distance1[name])
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_stack", {
	name = "Stack",
	privs = we_privs("stack"),
	get_formspec = function(name)
		local axis, count = gui_axis1[name], gui_count1[name]
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_stack") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stack_count;Count;%s]", minetest.formspec_escape(count)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_stack_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"field_close_on_enter[worldedit_gui_stack_count;false]" ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_stack_submit;Stack]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stack", function(name, fields)
	local cg = {
		worldedit_gui_stack_axis = gui_axis1,
		worldedit_gui_stack_count = gui_count1,
	}
	local ret = handle_changes(name, "worldedit_gui_stack", fields, cg)
	if fields.worldedit_gui_stack_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_stack")

		execute_worldedit_command("stack", name,
			axis_values[gui_axis1[name]] .. " " .. gui_count1[name])
		return true
	end
	return ret
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
			"field_close_on_enter[worldedit_gui_stretch_x;false]" ..
			"field_close_on_enter[worldedit_gui_stretch_y;false]" ..
			"field_close_on_enter[worldedit_gui_stretch_z;false]" ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_stretch_submit;Stretch]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stretch", function(name, fields)
	local cg = {
		worldedit_gui_stretch_x = gui_count1,
		worldedit_gui_stretch_y = gui_count2,
		worldedit_gui_stretch_z = gui_count3,
	}
	local ret = handle_changes(name, "worldedit_gui_stretch", fields, cg)
	if fields.worldedit_gui_stretch_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_stretch")

		execute_worldedit_command("stretch", name, string.format("%s %s %s",
			gui_count1[name], gui_count2[name], gui_count3[name]))
		return true
	end
	return ret
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
	local cg = {
		worldedit_gui_transpose_axis1 = gui_axis1,
		worldedit_gui_transpose_axis2 = gui_axis2,
	}
	local ret = handle_changes(name, "worldedit_gui_transpose", fields, cg)
	if fields.worldedit_gui_transpose_submit then
		copy_changes(name, fields, cg)

		execute_worldedit_command("transpose", name,
			axis_values[gui_axis1[name]] .. " " .. axis_values[gui_axis2[name]])
		return true
	end
	return ret
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
	local cg = {
		worldedit_gui_flip_axis = gui_axis1
	}
	local ret = handle_changes(name, "worldedit_gui_flip", fields, cg)
	if fields.worldedit_gui_flip_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_flip")

		execute_worldedit_command("flip", name, axis_values[gui_axis1[name]])
		return true
	end
	return ret
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
	local cg = {
		worldedit_gui_rotate_axis = gui_axis1,
		worldedit_gui_rotate_angle = gui_angle,
	}
	local ret = handle_changes(name, "worldedit_gui_rotate", fields, cg)
	if fields.worldedit_gui_rotate_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_rotate")

		execute_worldedit_command("rotate", name,
			axis_values[gui_axis1[name]] .. " " .. angle_values[gui_angle[name]])
		return true
	end
	return ret
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
	local cg = {
		worldedit_gui_orient_angle = gui_angle,
	}
	local ret = handle_changes(name, "worldedit_gui_orient", fields, cg)
	if fields.worldedit_gui_orient_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_orient")

		execute_worldedit_command("orient", name,
			tostring(angle_values[gui_angle[name]]))
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_fixlight", {
	name = "Fix Lighting",
	privs = we_privs("fixlight"),
	on_select = function(name)
		execute_worldedit_command("fixlight", name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_hide", {
	name = "Hide Region",
	privs = we_privs("hide"),
	on_select = function(name)
		execute_worldedit_command("hide", name, "")
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
			"field_close_on_enter[worldedit_gui_suppress_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_suppress_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_suppress_submit;Suppress Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_suppress", function(name, fields)
	local cg = {
		worldedit_gui_suppress_search = true,
		worldedit_gui_suppress_node = gui_nodename1,
	}
	local ret = handle_changes(name, "worldedit_gui_suppress", fields, cg)
	if fields.worldedit_gui_suppress_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_suppress")

		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command("suppress", name, n)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_highlight", {
	name = "Highlight Nodes",
	privs = we_privs("highlight"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_highlight") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_highlight_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_highlight_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_highlight_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_highlight_submit;Highlight Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_highlight", function(name, fields)
	local cg = {
		worldedit_gui_highlight_search = true,
		worldedit_gui_highlight_node = gui_nodename1,
	}
	local ret = handle_changes(name, "worldedit_gui_highlight", fields, cg)
	if fields.worldedit_gui_highlight_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_highlight")

		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			execute_worldedit_command("highlight", name, n)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_restore", {
	name = "Restore Region",
	privs = we_privs("restore"),
	on_select = function(name)
		execute_worldedit_command("restore", name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_save_load", {
	name = "Save/Load",
	privs = combine_we_privs({"save", "allocate", "load"}),
	get_formspec = function(name)
		local filename = gui_filename[name]
		return "size[6,4]" .. worldedit.get_formspec_header("worldedit_gui_save_load") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_save_filename;Filename;%s]", minetest.formspec_escape(filename)) ..
			"field_close_on_enter[worldedit_gui_save_filename;false]" ..
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
			execute_worldedit_command("save", name, gui_filename[name])
		elseif fields.worldedit_gui_save_load_submit_allocate then
			execute_worldedit_command("allocate", name, gui_filename[name])
		else --fields.worldedit_gui_save_load_submit_load
			execute_worldedit_command("load", name, gui_filename[name])
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_cube", {
	name = "Cube",
	privs = combine_we_privs({"hollowcube", "cube"}),
	get_formspec = function(name)
		local width, height, length = gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,4]" .. worldedit.get_formspec_header("worldedit_gui_cube") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_cube_node;Name;%s]", minetest.formspec_escape(node)) ..
			"field_close_on_enter[worldedit_gui_cube_node;false]" ..
			"button[4,1.18;1.5,0.8;worldedit_gui_cube_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			string.format("field[0.5,2.5;1,0.8;worldedit_gui_cube_width;Width;%s]", minetest.formspec_escape(width)) ..
			string.format("field[1.5,2.5;1,0.8;worldedit_gui_cube_height;Height;%s]", minetest.formspec_escape(height)) ..
			string.format("field[2.5,2.5;1,0.8;worldedit_gui_cube_length;Length;%s]", minetest.formspec_escape(length)) ..
			"field_close_on_enter[worldedit_gui_cube_width;false]" ..
			"field_close_on_enter[worldedit_gui_cube_height;false]" ..
			"field_close_on_enter[worldedit_gui_cube_length;false]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_cube_submit_hollow;Hollow Cuboid]" ..
			"button_exit[3.5,3.5;3,0.8;worldedit_gui_cube_submit_solid;Solid Cuboid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cube", function(name, fields)
	local cg = {
		worldedit_gui_cube_search = true,
		worldedit_gui_cube_node = gui_nodename1,
		worldedit_gui_cube_width = gui_distance1,
		worldedit_gui_cube_height = gui_distance2,
		worldedit_gui_cube_length = gui_distance3,
	}
	local ret = handle_changes(name, "worldedit_gui_cube", fields, cg)
	if fields.worldedit_gui_cube_submit_hollow or fields.worldedit_gui_cube_submit_solid then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_cube")

		local submit = "hollowcube"
		if fields.worldedit_gui_cube_submit_solid then
			submit = "cube"
		end
		local n = worldedit.normalize_nodename(gui_nodename1[name])
		if n then
			local args = string.format("%s %s %s %s", gui_distance1[name], gui_distance2[name], gui_distance3[name], n)
			execute_worldedit_command(submit, name, args)
		end
		return true
	end
	return ret
end)

worldedit.register_gui_function("worldedit_gui_clearobjects", {
	name = "Clear Objects",
	privs = we_privs("clearobjects"),
	on_select = function(name)
		execute_worldedit_command("clearobjects", name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_param2", {
	name = "Set Param2",
	privs = we_privs("param2"),
	get_formspec = function(name)
		local value = gui_param2[name] or "0"
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_param2") ..
			"textarea[0.5,1;5,2;;;Some values may break the node!]"..
			string.format("field[0.5,2.5;2,0.8;worldedit_gui_param2_value;New Param2;%s]", minetest.formspec_escape(value)) ..
			"field_close_on_enter[worldedit_gui_param2_value;false]" ..
			"button_exit[3.5,2.5;3,0.8;worldedit_gui_param2_submit;Set Param2]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_param2", function(name, fields)
	local cg = {
		worldedit_gui_param2_value = gui_param2,
	}
	local ret = handle_changes(name, "worldedit_gui_param2", fields, cg)
	if fields.worldedit_gui_param2_submit then
		copy_changes(name, fields, cg)
		worldedit.show_page(name, "worldedit_gui_param2")

		execute_worldedit_command("param2", name, gui_param2[name])
		return true
	end
	return ret
end)
