--if there's no protection mod, no worldedit means no editing, worldedit means editing anywhere (old behaviour)
--if there's a protection mod, no worldedit means editing only in your area, worldedit means editing in no-man's land too, areas means editing anywhere.

--let the other mod load first
minetest.after(0, function()
	--I would use mod.soft_depend from commonlib, but there are multiple mods that could create owned land
	PROTECTION_MOD_EXISTS = minetest.is_protected == old_is_protected
	--else fall back to old behaviour, where
	--worldedit privilege is permission to edit everything
end)

--this is privs={worldedit=this()} within chatcommands that actually change land
--(should be the same functions as safe_region)
function worldedit.priv()
	if not PROTECTION_MOD_EXISTS or not minetest.setting_getbool("creative_mode") then
		--no protection mod, or not the kind of world where people can just create nodes out of thin air,
		--worldedit privilege means editing anywhere
		return true
	end
	--protection mod, can edit inside your area without worldedit privilege
	--(worldedit and areas let you edit in no-man's land and other-owned area)
	return false
end

function worldedit.can_edit_volume(name)
	--old you-can-worldedit-everything behaviour
	if not PROTECTION_MOD_EXISTS then
		--then if you were able to run this command, then you have the worldedit privilege.
		return true
	end
	--new ownership-based behaviour

	--You can set areas, so you can worldedit them too.
	if minetest.check_player_privs(name, {areas=true}) then
		return true
	end

	--all-or-nothing here
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
	--pos1, pos2 = worldedit.sort_pos(pos1, pos2) --does this matter?
	for i in area:iterp(pos1, pos2) do

		--THIS SECTION IGNORES the distinction of area that is owned by someone else, but still editable
		--this is treated as area owned by the editor, or no-man's land depending on if it's shared with one person or everyone
		--
		--If it was treated differently (it's not), then single edits would not be able to cross the border between someone else's editable land, and no-man's land, to prevent accidental writes. It may cross the border between multiple people's editable land (or should it?), such as to create a bridge between two skyscrapers that were previously built separately.
		--
		--This needs testing for the other changes first.

		--Is it owned?
		if minetest.is_protected(i) then
			--Is it someone else's?
			if minetest.is_protected(i, name) then
				--already checked the ability to make it mine (areas)
				minetest.chat_send_player(name, "Someone else owns at least part of what you want to edit")
				return false
			end
			--it's mine
			--continue

		--no-man's land
		--can I edit that?
		elseif not minetest.check_player_privs(name, {worldedit=true}) then --cache this check?
			minetest.chat_send_player(name, "You can only edit area in which you own a plot (missing worldedit privilege)")
			return false
		end
	end

	--the whole thing is
	--a) owned by me,
	--b) owned by no one and I have the worldedit privilege, and/or
	--c) owned by someone else and I have the areas privilege.
	return true
end
