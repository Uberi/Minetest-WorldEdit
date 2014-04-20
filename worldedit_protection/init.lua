--if there's no protection mod, no worldedit means no editing, worldedit means editing anywhere (old behaviour)
--if there's a protection mod (and it's creative mode), no worldedit means editing only in your area, worldedit means editing in no-man's land too, and areas means editing anywhere.

--[[
--let the other mod load first
minetest.after(0, function()
	--I would use mod.soft_depend from commonlib, but there are multiple mods that could create owned land
	PROTECTION_MOD_EXISTS = minetest.is_protected ~= old_is_protected
	--else fall back to old behaviour, where
	--worldedit privilege is permission to edit everything
end)
--]]
local PROTECTION_MOD_EXISTS = false
mod.soft_depend("areas", function()
	PROTECTION_MOD_EXISTS = true
end)
--mod.soft_depend("other protection mod goes here", function()
--	PROTECTION_MOD_EXISTS = true
--end)

--[[
worldedit.privs replaces privs = {worldedit = true}, and also helps bypass volume permission checks.
Usage:
  In chatcommand:
    privs = {}
    func = worldedit.privs(function(name, param)...end)

  In if statement:
    name = minetest.get_player_name(node)
    if worldedit.privs() then

Returns:
  nil (      false) for no permission to worldedit           anywhere,
  1   (      true ) for    permission to worldedit at least somewhere, and
  2   (extra true ) for                  worldediting      everywhere without checking for further permission.
--]]
--I wanted this function to directly choose the privileges for the chat command, but it only applies once.
--privs={worldedit=true             [, server=true]}
--privs={worldedit=worldedit.priv() [, server=true]}
--instead, I had to wrap the rest of func = .
worldedit.privs = function(privsfunc) --returns a function (the argument function wrapped in another) which takes the arguments (name, param).
	if privsfunc == nil then
		privsfunc = function() --[[no-op]] end
	end

	--this silly syntax was copied from safe_region, which is actually executed on chatcommand registration, and must return a function instead of the result of a function.
	--The innermost anonymous function is declared. Then safe_region executes, adding a function wrapper around that function. Then worldedit.privs gets that as an argument, and adds another wrapper. The doubly-wrapped function is the one registered as a chatcommand.
	return function(name, param)
		if minetest.check_player_privs(name, {areas=true}) then
			--You can set areas, so you are allowed to worldedit them too.
			--The ability to set the whole world as owned by yourself is already potentially destructive, what's more destructive capability?
			privsfunc(name, param)
			return 2 --edit everywhere without checks
		end
		local is_creative = minetest.setting_getbool("creative_mode")
		if not is_creative or not PROTECTION_MOD_EXISTS then
			--no protection mod, or not the kind of world where people can just create nodes out of thin air,
			--worldedit privilege means editing anywhere
			if minetest.check_player_privs(name, {worldedit=true}) then
				privsfunc(name, param)
				return 2 --edit everywhere without checks
			else
				--default chatcommand failure message
				minetest.chat_send_player(name, "You don't have permission to run this command (missing privileges: worldedit)\nReasons:".. (is_creative and "" or " (not creative mode)") .. (PROTECTION_MOD_EXISTS and "" or " (no protection mod)"))
				--func(name, param) placeholder
				return nil --edit nowhere
			end
		else
			--protection mod, can edit inside your area without worldedit privilege
			--(worldedit and areas let you edit in no-man's land and other-owned area)
			privsfunc(name, param)
			return 1 --edit at least somewhere, with checks
		end
	end
end

--this is... within chatcommands that actually change land
--(should be the same functions as safe_region)
--also check for permission when region is set? no, //stack goes outside the boundaries.
--so the region is defined per-command on exec.
--//move has disconnected sections, so it's passed as a list of points.
--which are deduplicated.
worldedit.can_edit_volume = function(name, volume) --does not return a function like .privs does
	--volume is before func, unlike safe_region having func before count
	--because func may be removed to have can_edit_volume in an if statement
	--like worldedit.privs can be

	--worldedit.privs was run once to prevent safe_region large area warnings,
	--then safe_region was run to prevent unnecessary large-scale permission checks
	--then can_edit_volume is run before //set to honor areas
	--then worldedit.privs is run again to attempt skipping checks (resusing the same code)
	--then set is finally run.

	--<==>--local returnfunc = function(name, param)
		--worldedit.privs said that 'name' can use worldedit at least somewhere
		--	return value 1 (or 2) before this function was run.

		--Try skipping volume permission checks.
		local wp = worldedit.privs(nil)(name, nil)
		if wp == 2 then
			--volfunc(name, param)
			return true
		elseif wp == nil then
			--safety feature in case worldedit.can_edit_volume is ever run alone, without being surrounded by worldedit.privs()
			--Shouldn't ever get here.
			--Any volume-changing function is surrounded by this, then safe_region, then worldedit.privs()
			--volfunc(name, param) placeholder
			return false
		end

		--[[I need to use a special per-command region (think /stack, or even worse, /move), the same one safe_region uses, but corner points instead of count... instead of a for loop interpolating between pos1 and pos2]]--

		--cache the result of this function for later
		local has_worldedit = minetest.check_player_privs(name, {worldedit=true})

		--all or nothing here
		--volume may be a single region (//set) or two possibly overlapping regions (//move)
		--an overlapping //move is checked twice - any attempt to make it more efficient (by combining the volumes into a single two-pos one) may take into account that the format is //move axis amount, and break if the format is changed to //move xamount yamount zamount
		for v = 1,3,2 do         --volume[1] and volume[2]
		if volume[v] ~= nil then --volume[3] and volume[4]
		        volume[v],   volume[v+1] = worldedit.sort_pos(volume[v], volume[v+1])
		for y = volume[v].y, volume[v+1].y do
		for z = volume[v].z, volume[v+1].z do
		for x = volume[v].x, volume[v+1].x do
		local node = {x=x, y=y, z=z}
			--[[
			THIS SECTION IGNORES the distinction of area that is owned by someone else, but still editable
			this is treated as area owned by the editor, or no-man's land depending on if it's shared with one person or everyone

			If it was treated differently (it's not), then single edits would not be able to cross the border between someone else's editable land, and no-man's land, to prevent accidental writes. It may cross the border between multiple people's editable land (or should it?), such as to create a bridge between two skyscrapers that were previously built separately.

			This needs testing for the other changes first.
			--]]

			--Is it owned?
			if minetest.is_protected(node, "") then
				--Is it someone else's?
				if minetest.is_protected(node, name) then
					--already checked the ability to make it mine (areas)
					minetest.chat_send_player(name, "You don't have permission to run this command "..
						"(Region "..minetest.pos_to_string(volume[1]).."-"..minetest.pos_to_string(volume[2])..
						(volume[3] ~= nil and ("+"..minetest.pos_to_string(volume[3]).."-"..minetest.pos_to_string(volume[4])) or "")..
						" overlaps (first match) areaname: (x, y, z)-(x, y, z) owned by playername)"..
						"\nReasons: (missing areas privilege)"
					)
					--volfunc(name, param) placeholder
					return false
				end
				--it's mine
				--continue

			--no-man's land
			--can I edit that?
			elseif not has_worldedit then --using cached check
				minetest.chat_send_player(name, "You don't have permission to run this command (missing worldedit privilege)\nReasons: (At least part of this area is unowned (not owned by you)) (missing areas privilege)")
				--volfunc(name, param) placeholder
				return false
			end
		end -- for x
		end -- for z
		end -- for y
		end -- if not nil
		end -- for v

		--the whole thing is
		--a) owned by me, and/or
		--b) owned by no one and I have the worldedit privilege.
		--c) I have the areas privilege and it's possibly owned by someone else. (returned earlier)
		--volfunc(name, param)
		return true
	--<==>--end
end
