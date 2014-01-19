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

The `on_select` function must not call `worldedit.show_page`
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

--implement worldedit.show_page(name, page) in different ways depending on the available APIs
if unified_inventory then --unified inventory installed
	local old_func = worldedit.register_gui_function
	worldedit.register_gui_function = function(identifier, options)
		old_func(identifier, options)
		unified_inventory.register_page(identifier, {get_formspec=function(player) return {formspec=options.get_formspec(player:get_player_name())} end})
	end

	unified_inventory.register_button("worldedit_gui", {
		type = "image",
		image = "inventory_plus_worldedit_gui.png",
	})

	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()
		if fields.worldedit_gui then --main page
			worldedit.show_page(name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			local player = minetest.get_player_by_name(name)
			if player then
				unified_inventory.set_inventory_formspec(player, "craft")
			end
			return true
		end
		return false
	end)

	worldedit.show_page = function(name, page)
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_inventory_formspec(get_formspec(name, page))
		end
	end
elseif inventory_plus then --inventory++ installed
	minetest.register_on_joinplayer(function(player)
		inventory_plus.register_button(player, "worldedit_gui", "WorldEdit")
	end)

	--show the form when the button is pressed and hide it when done
	local gui_player_formspecs = {}
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()
		if fields.worldedit_gui then --main page
			gui_player_formspecs[name] = player:get_inventory_formspec()
			worldedit.show_page(name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			if gui_player_formspecs[name] then
				inventory_plus.set_inventory_formspec(player, gui_player_formspecs[name])
			end
			return true
		end
		return false
	end)

	worldedit.show_page = function(name, page)
		local player = minetest.get_player_by_name(name)
		if player then
			inventory_plus.set_inventory_formspec(player, get_formspec(name, page))
		end
	end
else --fallback button
	local player_formspecs = {}

	local update_main_formspec = function(name)
		local formspec = player_formspecs[name]
		if not formspec then
			return
		end
		local player = minetest.get_player_by_name(name)
		if not player then --this is in case the player signs off while the media is loading
			return
		end
		if (minetest.check_player_privs(name, {creative=true}) or minetest.setting_getbool("creative_mode")) and creative_inventory then --creative_inventory is active, add button to modified formspec
			formspec = player:get_inventory_formspec() .. "image_button[6,0;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]"
		else
			formspec = formspec .. "image_button[0,0;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]"
		end
		player:set_inventory_formspec(formspec)
	end

	minetest.register_on_joinplayer(function(player)
		local name = player:get_player_name()
		minetest.after(1, function()
			if minetest.get_player_by_name(name) then --ensure the player is still signed in
				player_formspecs[name] = player:get_inventory_formspec()
				minetest.after(0.01, function()
					update_main_formspec(name)
				end)
			end
		end)
	end)

	minetest.register_on_leaveplayer(function(player)
		player_formspecs[player:get_player_name()] = nil
	end)

	local gui_player_formspecs = {}
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()
		if fields.worldedit_gui then --main page
			gui_player_formspecs[name] = player:get_inventory_formspec()
			worldedit.show_page(name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			if gui_player_formspecs[name] then
				player:set_inventory_formspec(gui_player_formspecs[name])
			end
			return true
		else --deal with creative_inventory setting the formspec on every single message
			minetest.after(0.01,function()
				update_main_formspec(name)
			end)
			return false --continue processing in creative inventory
		end
	end)

	worldedit.show_page = function(name, page)
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_inventory_formspec(get_formspec(name, page))
		end
	end
end

worldedit.register_gui_function("worldedit_gui", {
	name = "WorldEdit GUI",
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid
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
		if index == 0 then --empty row
			y = y - height
		end
		return string.format("size[%g,%g]", math.max(columns * width, 5), math.max(y + 0.5, 3)) ..
			"button[0,0;2,0.5;worldedit_gui_exit;Back]" ..
			"label[2,0;WorldEdit GUI]" ..
			table.concat(buttons)
	end,
})

worldedit.register_gui_handler("worldedit_gui", function(name, fields)
	for identifier, entry in pairs(worldedit.pages) do --check for WorldEdit GUI main formspec button selection
		if fields[identifier] and identifier ~= "worldedit_gui" then
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
