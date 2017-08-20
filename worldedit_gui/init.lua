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

The `privs` field may not be `nil`.

If the identifier is already registered to another function, it will be replaced by the new one.

The `on_select` function must not call `worldedit.show_page`
]]

worldedit.pages = {} --mapping of identifiers to options
local identifiers = {} --ordered list of identifiers
worldedit.register_gui_function = function(identifier, options)
	if options.privs == nil or next(options.privs) == nil then
		error("privs unset")
	end
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
	local enabled = true
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if not enabled then return false end
		enabled = false
		minetest.after(0.2, function() enabled = true end)
		local name = player:get_player_name()

		--ensure the player has permission to perform the action
		local entry = worldedit.pages[identifier]
		if entry and minetest.check_player_privs(name, entry.privs) then
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
if rawget(_G, "unified_inventory") then --unified inventory installed
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
elseif rawget(_G, "inventory_plus") then --inventory++ installed
	minetest.register_on_joinplayer(function(player)
		local can_worldedit = minetest.check_player_privs(player:get_player_name(), {worldedit=true})
		if can_worldedit then
			inventory_plus.register_button(player, "worldedit_gui", "WorldEdit")
		end
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
				inventory_plus.set_inventory_formspec(player, inventory_plus.get_formspec(player, "main"))
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
elseif rawget(_G, "sfinv") then --sfinv installed (part of minetest_game since 0.4.15)
	assert(sfinv.enabled)
	local orig_get = sfinv.pages["sfinv:crafting"].get
	sfinv.override_page("sfinv:crafting", {
		get = function(self, player, context)
			local can_worldedit = minetest.check_player_privs(player, {worldedit=true})
			local fs = orig_get(self, player, context)
			return fs .. (can_worldedit and "image_button[0,0;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]" or "")
		end
	})

	--compatibility with pre-0.4.16 sfinv
	local set_page = sfinv.set_page or function(player, name)
		--assumptions: src pg has no leave callback, dst pg has no enter callback
		local ctx = {page=name}
		sfinv.contexts[player:get_player_name()] = ctx
		sfinv.set_player_inventory_formspec(player, ctx)
	end

	--show the form when the button is pressed and hide it when done
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if fields.worldedit_gui then --main page
			worldedit.show_page(player:get_player_name(), "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			set_page(player, "sfinv:crafting")
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
else
	error(
		"worldedit_gui requires a supported \"gui management\" mod to be installed\n"..
		"To use the GUI you need to either\n"..
		"* Use minetest_game (at least 0.4.15) or a subgame with compatible sfinv\n"..
		"* Install Unified Inventory or Inventory++\n"..
		"If you do not want to use worldedit_gui, disable it by editing world.mt or from the Main Menu"
	)
end

worldedit.register_gui_function("worldedit_gui", {
	name = "WorldEdit GUI",
	privs = {interact=true},
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
			local has_privs, missing_privs = minetest.check_player_privs(name, entry.privs)
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
