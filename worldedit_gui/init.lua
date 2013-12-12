--wip: make back buttons images in all screens
--wip: support unified_inventory, it even seems to have some sort of API now
--wip: make it look good with image buttons and stuff

worldedit = worldedit or {}

--[[
Example:

    worldedit.register_gui_function("worldedit_gui_hollow_cylinder", {
    	name = "Make Hollow Cylinder",
    	privs = {worldedit=true},
    	get_formspec = function(name) return "some formspec here" end,
    	on_select = function(name) print(name .. " clicked the button!") end,
    })

Use `nil` for the `options` parameter to unregister the function associated with the given identifier.

Use `nil` for the `get_formspec` field to denote that the function does not have its own screen.

Use `nil` for the `privs` field to denote that no special privileges are required to use the function.

If the identifier is already registered to another function, it will be replaced by the new one.
]]

worldedit.pages = {} --mapping of identifiers to options
local identifiers = {} --ordered list of identifiers
worldedit.register_gui_function = function(identifier, options)
	worldedit.pages[identifier] = options
	table.insert(identifiers, identifier)
end

--[[
Example:

    worldedit.register_gui_handler("worldedit_gui_hollow_cylinder", function(name, fields)
    	print(minetest.serialize(fields))
    end)
]]

worldedit.register_gui_handler = function(identifier, handler)
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		--ensure the form is not being exited since this is a duplicate message
		if fields.quit then
			return false
		end
		
		local name = player:get_player_name()
		
		--ensure the player has permission to perform the action
		local entry = worldedit.pages[identifier]
		if entry and minetest.check_player_privs(name, entry.privs or {}) then
			return handler(name, fields)
		end
		return false
	end)
end

worldedit.get_formspec_header = function(identifier)
	local entry = worldedit.pages[identifier] or {}
	return "button[0,0;2,0.5;worldedit_gui;Back]" ..
		string.format("label[2,0;WorldEdit GUI > %s]", entry.name or "")
end

local get_formspec = function(name, identifier)
	if worldedit.pages[identifier] then
		return worldedit.pages[identifier].get_formspec(name)
	end
	return worldedit.pages["worldedit_gui"].get_formspec(name) --default to showing main page if an unknown page is given
end

worldedit.show_page = function(name, page)
	--wip
	print("not implemented")
end

--add button to inventory_plus if it is installed
if inventory_plus then
	minetest.register_on_joinplayer(function(player)
		inventory_plus.register_button(player, "worldedit_gui", "WorldEdit")
	end)

	--show the form when the button is pressed
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if fields.worldedit_gui then --main page
			worldedit.show_page(player:get_player_name(), "worldedit_gui")
			return true
		end
		return false
	end)

	worldedit.show_page = function(name, page)
		inventory_plus.set_inventory_formspec(minetest.get_player_by_name(name), get_formspec(name, page))
	end
end

worldedit.register_gui_function("worldedit_gui", {
	name = "WorldEdit GUI",
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid --wip: show only buttons that the player has privs for
		local buttons, x, y, index = {}, 0, 1, 0
		local width, height = 3, 0.8
		local columns = 5
		for i, identifier in pairs(identifiers) do
			if identifier ~= "worldedit_gui" then
				local entry = worldedit.pages[identifier]
				table.insert(buttons, string.format((entry.get_formspec and "button" or "button_exit") ..
					"[%g,%g;%g,%g;%s;%s]", x, y, width, height, identifier, minetest.formspec_escape(entry.name)))

				index, x = index + 1, x + width
				if index == columns then --row is full
					x, y = 0, y + height
					index = 0
				end
			end
		end
		return string.format("size[%g,%g]", math.max(columns * width, 5), math.max(y + 0.5, 3)) ..
			(inventory_plus and "button[0,0;2,0.5;main;Back]" or "button_exit[0,0;2,0.5;main;Exit]") ..
			"label[2,0;WorldEdit GUI]" ..
			table.concat(buttons)
	end,
})

worldedit.register_gui_handler("worldedit_gui", function(name, fields)
	--check for WorldEdit GUI main formspec button selection
	for identifier, entry in pairs(worldedit.pages) do
		if fields[identifier] then
			--ensure player has permission to perform action
			local has_privs, missing_privs = minetest.check_player_privs(name, entry.privs or {})
			if not has_privs then
				worldedit.player_notify(name, "you are not allowed to use this function (missing privileges: " .. table.concat(missing_privs, ", ") .. ")")
				return false
			end
			if entry.on_select then
				entry.on_select(name)
			end
			if entry.get_formspec then
				worldedit.show_page(name, identifier)
			end
			return true
		end
	end
	return false
end)

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/functionality.lua")