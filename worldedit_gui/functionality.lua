worldedit.register_gui_function("worldedit_gui_about", {
	name = "About",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	name = "Toggle Inspection",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

worldedit.register_gui_function("worldedit_gui_reset", {
	name = "Reset Region",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/reset"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_mark", {
	name = "Mark Region",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/mark"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_unmark", {
	name = "Unmark Region",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/unmark"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_pos1", {
	name = "Position 1 Here",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/pos1"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_pos2", {
	name = "Position 2 Here",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/pos2"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_p", {
	name = "Get/Set Positions",
	privs = {worldedit=1},
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

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then
		return false
	end

	local name = player:get_player_name()
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
	privs = {worldedit=1},
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

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then
		return false
	end

	if fields.worldedit_gui_fixedpos_submit then
		if tonumber(fields.worldedit_gui_fixedpos_pos1x) and tonumber(fields.worldedit_gui_fixedpos_pos1y) and tonumber(fields.worldedit_gui_fixedpos_pos1z) then
			minetest.chatcommands["/fixedpos"].func(player:get_player_name(), string.format("set1 %d %d %d",
				tonumber(fields.worldedit_gui_fixedpos_pos1x), tonumber(fields.worldedit_gui_fixedpos_pos1y), tonumber(fields.worldedit_gui_fixedpos_pos1z)))
		end
		if tonumber(fields.worldedit_gui_fixedpos_pos2x) and tonumber(fields.worldedit_gui_fixedpos_pos2y) and tonumber(fields.worldedit_gui_fixedpos_pos2z) then
			minetest.chatcommands["/fixedpos"].func(player:get_player_name(), string.format("set2 %d %d %d",
				tonumber(fields.worldedit_gui_fixedpos_pos2x), tonumber(fields.worldedit_gui_fixedpos_pos2y), tonumber(fields.worldedit_gui_fixedpos_pos2z)))
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_volume", {
	name = "Region Volume",
	privs = {worldedit=1},
	on_select = function(name)
		minetest.chatcommands["/volume"].func(name, "")
	end,
})

local search_nodes = {}
worldedit.register_gui_function("worldedit_gui_set", {
	name = "Set Nodes",
	privs = {worldedit=1},
	get_formspec = function(name)
		local value = search_nodes[name]
		local nodename
		if value then
			nodename = worldedit.normalize_nodename(value)
			if nodename then
				value = nodename
			end
		end
		return "size[6,3]" ..
			"button[0,0;2,0.5;worldedit_gui;Back]" ..
			"label[2,0;WorldEdit GUI > Set Nodes]" ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_set_node;Name;%s]", value and minetest.formspec_escape(value) or "") ..
			"button[4,1.17;2,0.8;worldedit_gui_set_search;Search]" ..
			(nodename and string.format("item_image[4.5,2;1,1;%s]", nodename) or "image[4.5,2;1,1;unknown_node.png]") ..
			"button_exit[0,2.5;4,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then
		return false
	end

	local name = player:get_player_name()
	if fields.worldedit_gui_set_search then
		search_nodes[name] = fields.worldedit_gui_set_node
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	elseif fields.worldedit_gui_set_submit then
		search_nodes[name] = fields.worldedit_gui_set_node
		minetest.chatcommands["/set"].func(name, fields.worldedit_gui_set_node)
		return true
	end
	return false
end)