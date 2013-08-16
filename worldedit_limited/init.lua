do return end
do
	local MAX_VOLUME = 30 * 30 * 30

	local we = worldedit
	local volume = we.volume
	local safewrap = function(func)
		return function(pos1, pos2, ...)
			if validbox(pos1, pos2) then
				return func(pos1, pos2, ...)
			end
			return 0, pos1, pos2
		end
	end

	local validbox = function(pos1, pos2)
		tpos1, tpos2 = we.sort_pos(pos1, pos2)

		if volume(tpos1, tpos2) > MAX_VOLUME then
			return false
		end

		--check for ownership of area if ownership mod is installed
		if owner_defs then
			local inside = false
			for _, def in pairs(owner_defs) do
				--sort positions
				local tdef = {x1=def.x1, x2 = def.x2, y1=def.y1, y2=def.y2, z1=def.z1, z2=def.z2}
				if tdef.x1 > tdef.x2 then
					tdef.x1, tdef.x2 = tdef.x2, tdef.x1
				end
				if tdef.y1 > tdef.y2 then
					tdef.y1, tdef.y2 = tdef.y2, tdef.y1
				end
				if tdef.z1 > tdef.z2 then
					tdef.z1, tdef.z2 = tdef.z2, tdef.z1
				end

				--check ownership
				if tpos1.x >= tdef.x1 and tpos1.x <= tdef.x2
				and tpos2.x >= tdef.x1 and tpos2.x <= tdef.x2
				and tpos1.y >= tdef.y1 and tpos1.y <= tdef.y2
				and tpos2.y >= tdef.y1 and tpos2.y <= tdef.y2
				and tpos1.z >= tdef.z1 and tpos1.z <= tdef.z2
				and tpos2.z >= tdef.z1 and tpos2.z <= tdef.z2
				and name == def.owner then --wip: name isn't available here
					inside = true
					break
				end
			end
			if not inside then
				return false
			end
		end

		return true
	end

	worldedit = {
		sort_pos = we.sort_pos,

		set = safewrap(we.set),
		replace = safewrap(we.replace),
		replaceinverse = safewrap(we.replaceinverse),
		copy = function(pos1, pos2, axis, amount)
			tpos1, tpos2 = we.sort_pos(pos1, pos2)
			tpos1[axis] = tpos1[axis] + amount
			tpos2[axis] = tpos2[axis] + amount
			if validbox(pos1, pos2) and validbox(tpos1, tpos2) then
				we.copy(pos1, pos2, axis, amount)
			else
				return 0
			end
		end,
		move = function(pos1, pos2, axis, amount)
			tpos1, tpos2 = we.sort_pos(pos1, pos2)
			tpos1[axis] = tpos1[axis] + amount
			tpos2[axis] = tpos2[axis] + amount
			if validbox(pos1, pos2) and validbox(tpos1, tpos2) then
				we.move(pos1, pos2, axis, amount)
			else
				return 0
			end
		end,
		stack = function(pos1, pos2, axis, count)
			tpos1, tpos2 = we.sort_pos(pos1, pos2)
			local length = (tpos2[axis] - tpos1[axis] + 1) * count
			if count < 0 then
				tpos1[axis] = tpos1[axis] + length
			else
				tpos2[axis] = tpos2[axis] + length
			end
			if validbox(tpos1, tpos2) then
				we.stack(pos1, pos2, axis, amount)
			else
				return 0
			end
		end,
		--wip: add transpose, rotate safely
		flip = safewrap(we.flip),
		orient = safewrap(we.orient),
		fixlight = safewrap(we.fixlight),
		--wip: add primitives here
		volume = we.volume,
		hide = safewrap(we.hide),
		suppress = safewrap(we.suppress),
		highlight = safewrap(we.highlight),
		restore = safewrap(we.restore),
		serialize = safewrap(we.serialize),
		allocate = we.allocate,
		deserialize = function(originpos, value)
			local tpos1, tpos2 = we.allocate(originpos, value)
			if validbox(tpos1, tpos2) then
				we.deserialize(originpos, value)
			else
				return 0
			end
		end,
	}
end