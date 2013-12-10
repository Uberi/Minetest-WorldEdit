--wip: make back buttons images in all screens
--wip: support unified_inventory, it even seems to have some sort of API now

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

local pages = {} --mapping of identifiers to options
local identifiers = {} --ordered list of identifiers
worldedit.register_gui_function = function(identifier, options)
	pages[identifier] = options
	table.insert(identifiers, identifier)
end

local get_formspec = function(name, identifier)
	if pages[identifier] then
		return pages[identifier].get_formspec(name)
	end
	return pages["worldedit_gui"].get_formspec(name)
end

worldedit.show_page = function(name, page)
	--wip
	print("not implemented")
end

--add button to inventory_plus if it is installed
if inventory_plus then
	minetest.register_on_joinplayer(function(player)
		--ensure player has permission to perform action
		if minetest.check_player_privs(player:get_player_name(), {worldedit=true}) then
			inventory_plus.register_button(player, "worldedit_gui", "WorldEdit")
		end
	end)

	--show the form when the button is pressed
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()

		--ensure player has permission to perform action
		if not minetest.check_player_privs(name, {worldedit=true}) then
			return false
		end

		--check for showing of main GUI
		local next_page = nil
		if fields.worldedit_gui then --main page
			worldedit.show_page(name, "worldedit_gui")
			return true
		end
		return false
	end)

	worldedit.show_page = function(name, page)
		inventory_plus.set_inventory_formspec(minetest.get_player_by_name(name), get_formspec(name, page))
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then
		return false
	end

	--check for WorldEdit GUI main formspec button selection
	for identifier, entry in pairs(pages) do
		if fields[identifier] then
			local name = player:get_player_name()

			--ensure player has permission to perform action
			if entry.privs and not minetest.check_player_privs(name, entry.privs) then
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

worldedit.register_gui_function("worldedit_gui", {
	name = "WorldEdit GUI",
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid
		local buttons, x, y, index = {}, 0, 1, 0
		local width, height = 3, 0.8
		local columns = 5
		for i, identifier in pairs(identifiers) do
			if identifier ~= "worldedit_gui" then
				local entry = pages[identifier]
				table.insert(buttons, string.format((entry.get_formspec and "button" or "button_exit") ..
					"[%g,%g;%g,%g;%s;%s]", x, y, width, height, identifier, minetest.formspec_escape(entry.name)))

				index, x = index + 1, x + width
				if index == columns then --row is full
					x, y = 0, y + height
					index = 0
				end
			end
		end
		return string.format("size[%g,%g]", columns * width, y + 0.5) ..
			(inventory_plus and "button[0,0;2,0.5;main;Back]" or "button_exit[0,0;2,0.5;main;Exit]") ..
			"label[2,0;WorldEdit GUI]" ..
			table.concat(buttons)
	end,
})

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/functionality.lua")