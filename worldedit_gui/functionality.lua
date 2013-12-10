worldedit.register_gui_function("worldedit_gui_about", {
	name = "About",
	privs = minetest.chatcommands["/about"].privs,
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	name = "Toggle Inspection",
	privs = minetest.chatcommands["/inspect"].privs,
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

worldedit.register_gui_function("worldedit_gui_reset", {
	name = "Reset Region",
	privs = minetest.chatcommands["/reset"].privs,
	on_select = function(name)
		minetest.chatcommands["/reset"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_mark", {
	name = "Mark Region",
	privs = minetest.chatcommands["/mark"].privs,
	on_select = function(name)
		minetest.chatcommands["/mark"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_unmark", {
	name = "Unmark Region",
	privs = minetest.chatcommands["/unmark"].privs,
	on_select = function(name)
		minetest.chatcommands["/unmark"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_pos1", {
	name = "Position 1 Here",
	privs = minetest.chatcommands["/pos1"].privs,
	on_select = function(name)
		minetest.chatcommands["/pos1"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_pos2", {
	name = "Position 2 Here",
	privs = minetest.chatcommands["/pos2"].privs,
	on_select = function(name)
		minetest.chatcommands["/pos2"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_p", {
	name = "Get/Set Positions",
	privs = minetest.chatcommands["/p"].privs,
	get_formspec = function(name)
		return "size[12,2]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Get/Set Positions]" ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;Get Positions]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set;Set Positions]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set1;Set Position 1]" ..
			"button_exit[9,1;3,0.8;worldedit_gui_p_set2;Set Position 2]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_p", function(name, fields)
	if fields.worldedit_gui_p_get then
		minetest.chatcommands["/p"].func(name, "get")
		return true
	elseif fields.worldedit_gui_p_set then
		minetest.chatcommands["/p"].func(name, "set")
		return true
	elseif fields.worldedit_gui_p_set1 then
		minetest.chatcommands["/p"].func(name, "set1")
		return true
	elseif fields.worldedit_gui_p_set2 then
		minetest.chatcommands["/p"].func(name, "set2")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_fixedpos", {
	name = "Fixed Positions",
	privs = minetest.chatcommands["/fixedpos"].privs,
	get_formspec = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[6.5,4]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Fixed Positions]" ..
			"label[0,1.2;Position 1]" ..
			string.format("field[2,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1x;Axis X;%s]", pos1 and pos1.x or "") ..
			string.format("field[3.5,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1y;Axis Y;%s]", pos1 and pos1.y or "") ..
			string.format("field[5,1.5;1.5,0.8;worldedit_gui_fixedpos_pos1z;Axis Z;%s]", pos1 and pos1.z or "") ..
			"label[0,2.2;Position 2]" ..
			string.format("field[2,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;Axis X;%s]", pos2 and pos2.x or "") ..
			string.format("field[3.5,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Axis Y;%s]", pos2 and pos2.y or "") ..
			string.format("field[5,2.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Axis Z;%s]", pos2 and pos2.z or "") ..
			"button_exit[0,3.5;4,0.8;worldedit_gui_fixedpos_submit;Set Fixed Positions]"
	end
})

worldedit.register_gui_handler("worldedit_gui_fixedpos", function(name, fields)
	if fields.worldedit_gui_fixedpos_submit then
		if tonumber(fields.worldedit_gui_fixedpos_pos1x) and tonumber(fields.worldedit_gui_fixedpos_pos1y) and tonumber(fields.worldedit_gui_fixedpos_pos1z) then
			minetest.chatcommands["/fixedpos"].func(name, string.format("set1 %d %d %d",
				tonumber(fields.worldedit_gui_fixedpos_pos1x), tonumber(fields.worldedit_gui_fixedpos_pos1y), tonumber(fields.worldedit_gui_fixedpos_pos1z)))
		end
		if tonumber(fields.worldedit_gui_fixedpos_pos2x) and tonumber(fields.worldedit_gui_fixedpos_pos2y) and tonumber(fields.worldedit_gui_fixedpos_pos2z) then
			minetest.chatcommands["/fixedpos"].func(name, string.format("set2 %d %d %d",
				tonumber(fields.worldedit_gui_fixedpos_pos2x), tonumber(fields.worldedit_gui_fixedpos_pos2y), tonumber(fields.worldedit_gui_fixedpos_pos2z)))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_volume", {
	name = "Region Volume",
	privs = minetest.chatcommands["/volume"].privs,
	on_select = function(name)
		minetest.chatcommands["/volume"].func(name, "")
	end,
})

local gui_nodename_set = {}
worldedit.register_gui_function("worldedit_gui_set", {
	name = "Set Nodes",
	privs = minetest.chatcommands["/set"].privs,
	get_formspec = function(name)
		local value = gui_nodename_set[name] or "Cobblestone"
		local nodename = worldedit.normalize_nodename(value)
		value = nodename or value
		return "size[6.5,3]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Set Nodes]" ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_set_node;Name;%s]", minetest.formspec_escape(value)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_set_search;Search]" ..
			(nodename and string.format("item_image[5.5,1.18;1,1;%s]", nodename)
				or "image[5.5,1.18;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;4,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	if fields.worldedit_gui_set_search then
		gui_nodename_set[name] = fields.worldedit_gui_set_node
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	elseif fields.worldedit_gui_set_submit then
		gui_nodename_set[name] = fields.worldedit_gui_set_node
		minetest.chatcommands["/set"].func(name, gui_nodename_set[name])
		return true
	end
	return false
end)

local gui_nodename_replace = {}
worldedit.register_gui_function("worldedit_gui_replace", {
	name = "Replace Nodes",
	privs = minetest.chatcommands["/replace"].privs,
	get_formspec = function(name)
		local search_value = gui_nodename_set[name] or "Cobblestone"
		local search_nodename = worldedit.normalize_nodename(search_value)
		search_value = search_nodename or search_value
		local replace_value, replace_nodename = gui_nodename_replace[name] or "Stone"
		local replace_nodename = worldedit.normalize_nodename(replace_value)
		replace_value = replace_nodename or replace_value
		return "size[6,4]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Replace Nodes]" ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_replace_search;Name;%s]", minetest.formspec_escape(search_value)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_replace_search_search;Search]" ..
			(search_nodename and string.format("item_image[5.5,1.18;1,1;%s]", search_nodename)
				or "image[5.5,1.18;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_replace_replace;Name;%s]", minetest.formspec_escape(replace_value)) ..
			"button[4,2.18;1.5,0.8;worldedit_gui_replace_replace_search;Search]" ..
			(replace_nodename and string.format("item_image[5.5,2.18;1,1;%s]", replace_nodename)
				or "image[5.5,2.18;1,1;unknown_node.png]") ..
			"button_exit[0,3.5;4,0.8;worldedit_gui_replace_submit;Replace Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_replace", function(name, fields)
	if fields.worldedit_gui_replace_search_search then
		gui_nodename_set[name] = fields.worldedit_gui_replace_search
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_replace_search then
		gui_nodename_replace[name] = fields.worldedit_gui_replace_replace
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	elseif fields.worldedit_gui_replace_submit then
		gui_nodename_set[name] = fields.worldedit_gui_replace_search
		gui_nodename_replace[name] = fields.worldedit_gui_replace_replace
		minetest.chatcommands["/replace"].func(name, string.format("%s %s", gui_nodename_set[name], gui_nodename_replace[name]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_replaceinverse", {
	name = "Replace Inverse",
	privs = minetest.chatcommands["/replaceinverse"].privs,
	get_formspec = function(name)
		local search_value = gui_nodename_set[name] or "Cobblestone"
		local search_nodename = worldedit.normalize_nodename(search_value)
		search_value = search_nodename or search_value
		local replace_value, replace_nodename = gui_nodename_replace[name] or "Stone"
		local replace_nodename = worldedit.normalize_nodename(replace_value)
		replace_value = replace_nodename or replace_value
		return "size[6,4]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Replace Inverse]" ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_replaceinverse_search;Name;%s]", minetest.formspec_escape(search_value)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_replaceinverse_search_search;Search]" ..
			(search_nodename and string.format("item_image[5.5,1.18;1,1;%s]", search_nodename)
				or "image[5.5,1.18;1,1;unknown_node.png]") ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_replaceinverse_replace;Name;%s]", minetest.formspec_escape(replace_value)) ..
			"button[4,2.18;1.5,0.8;worldedit_gui_replaceinverse_replace_search;Search]" ..
			(replace_nodename and string.format("item_image[5.5,2.18;1,1;%s]", replace_nodename)
				or "image[5.5,2.18;1,1;unknown_node.png]") ..
			"button_exit[0,3.5;4,0.8;worldedit_gui_replaceinverse_submit;Replace Inverse]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_replaceinverse", function(name, fields)
	if fields.worldedit_gui_replaceinverse_search_search then
		gui_nodename_set[name] = fields.worldedit_gui_replaceinverse_search
		worldedit.show_page(name, "worldedit_gui_replaceinverse")
		return true
	elseif fields.worldedit_gui_replaceinverse_replace_search then
		gui_nodename_replace[name] = fields.worldedit_gui_replaceinverse_replace
		worldedit.show_page(name, "worldedit_gui_replaceinverse")
		return true
	elseif fields.worldedit_gui_replaceinverse_submit then
		gui_nodename_set[name] = fields.worldedit_gui_replaceinverse_search
		gui_nodename_replace[name] = fields.worldedit_gui_replaceinverse_replace
		minetest.chatcommands["/replaceinverse"].func(name, string.format("%s %s", gui_nodename_set[name], gui_nodename_replace[name]))
		return true
	end
	return false
end)