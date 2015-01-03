minetest.register_chatcommand(
   "/outset",
   {
      params = "<amount> [h|v]",
      description = "outset the selection",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, dir = param:find("^(%d+)[%s+]?([hv]?)$")

	 if find == nil then
	    return false, "invalid usage: " .. param
	 end

	 local pos1 = worldedit.pos1[name]
	 local pos2 = worldedit.pos2[name]
	 
	 if pos1 == nil or pos2 == nil then
	    return false, "Undefined region. Region must be defined beforehand."
	 end

	 local dirs = worldedit.get_outset_directions(pos1, pos2)

	 if dir == 'h' then
	    worldedit.move_marker(name, 1, 'x', amount * dirs.x1)
	    worldedit.move_marker(name, 1, 'z', amount * dirs.z1)

	    worldedit.move_marker(name, 2, 'x', amount * dirs.x2)
	    worldedit.move_marker(name, 2, 'z', amount * dirs.z2)
	    message = "area outset by " .. amount .. " blocks horizontally"
	 elseif dir == 'v' then
	    worldedit.move_marker(name, 1, 'y', amount * dirs.y1)
	    worldedit.move_marker(name, 2, 'y', amount * dirs.y2)
	    message = "area outset by " .. amount .. " blocks vertically"
	 else
	    worldedit.move_marker(name, 1, 'x', amount * dirs.x1)
	    worldedit.move_marker(name, 1, 'y', amount * dirs.y1)
	    worldedit.move_marker(name, 1, 'z', amount * dirs.z1)

	    worldedit.move_marker(name, 2, 'x', amount * dirs.x2)
	    worldedit.move_marker(name, 2, 'y', amount * dirs.y2)
	    worldedit.move_marker(name, 2, 'z', amount * dirs.z2)
	    message = "area outset by " .. amount .. " blocks in all axes"
	 end

	 worldedit.update_markers(name)
	 return true, message
      end,
   }
)

minetest.register_chatcommand(
   "/inset",
   {
      params = "<amount> [h|v]",
      description = "inset the selection",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, dir = param:find("^(%d+)[%s+]?([hv]?)$")

	 if find == nil then
	    return false, "invalid usage: " .. param
	 end

	 local pos1 = worldedit.pos1[name]
	 local pos2 = worldedit.pos2[name]
	 
	 if pos1 == nil or pos2 == nil then
	    return false, "Undefined region. Region must be defined beforehand."
	 end

	 local dirs = worldedit.get_outset_directions(pos1, pos2)
	 amount = -amount
	 
	 if dir == 'h' then
	    worldedit.move_marker(name, 1, 'x', amount * dirs.x1)
	    worldedit.move_marker(name, 1, 'z', amount * dirs.z1)

	    worldedit.move_marker(name, 2, 'x', amount * dirs.x2)
	    worldedit.move_marker(name, 2, 'z', amount * dirs.z2)
	    message = "area inset by " .. amount .. " blocks horizontally"
	 elseif dir == 'v' then
	    worldedit.move_marker(name, 1, 'y', amount * dirs.y1)
	    worldedit.move_marker(name, 2, 'y', amount * dirs.y2)
	    message = "area inset by " .. amount .. " blocks vertically"
	 else
	    worldedit.move_marker(name, 1, 'x', amount * dirs.x1)
	    worldedit.move_marker(name, 1, 'y', amount * dirs.y1)
	    worldedit.move_marker(name, 1, 'z', amount * dirs.z1)

	    worldedit.move_marker(name, 2, 'x', amount * dirs.x2)
	    worldedit.move_marker(name, 2, 'y', amount * dirs.y2)
	    worldedit.move_marker(name, 2, 'z', amount * dirs.z2)
	    message = "area inset by " .. amount .. " blocks in all axes"
	 end

	 worldedit.update_markers(name)
	 return true, message
      end,
   }
)

worldedit.get_outset_directions = function(mark1, mark2)
   if mark1 == nil or mark2 == nil then return
   end
   
   local dirs =
      {
	 x1 = 0,
	 x2 = 0,
	 y1 = 0,
	 y2 = 0,
	 z1 = 0,
	 z2 = 0
      }
   
   if mark1.x < mark2.x then
      dirs.x1 = -1
      dirs.x2 = 1
   else
      dirs.x1 = 1
      dirs.x2 = -1
   end

   if mark1.y < mark2.y then
      dirs.y1 = -1
      dirs.y2 = 1
   else
      dirs.y1 = 1
      dirs.y2 = -1
   end

   if mark1.z < mark2.z then
      dirs.z1 = -1
      dirs.z2 = 1
   else
      dirs.z1 = 1
      dirs.z2 = -1
   end

   return dirs
end


minetest.register_chatcommand(
   "/shift",
   {
      params = "<amount> [up|down|left|right|front|back]",
      description = "Moves the selection region. Does not move contents.",
      privs = {worldedit=true},
      func = function(name, param)
	 local pos1 = worldedit.pos1[name]
	 local pos2 = worldedit.pos2[name]
	 local find, _, amount, direction = param:find("(%d+)%s*(%l*)")

	 if find == nil then
	    worldedit.player_notify(name, "invalid usage: " .. param)
	    return
	 end
	 
	 if pos1 == nil or pos2 == nil then
	    worldedit.player_notify(name, "Undefined region. Region must be defined beforehand.")
	    return
	 end

	 local axis, dirsign
	 
	 if direction ~= "" then
	    axis, dirsign = worldedit.translate_direction(name, direction)
	 else
	    axis, dirsign = worldedit.player_axis(name)
	 end

	 if axis == nil or dirsign == nil then
	    return false, "Invalid usage: " .. param
	 end
	 
	 worldedit.move_marker(name, 1, axis, amount * dirsign)
	 worldedit.move_marker(name, 2, axis, amount * dirsign)
	 worldedit.update_markers(name)

	 worldedit.player_notify(name, "Area shifted by " .. amount .. " in " .. direction .. " axis")
      end,
   }
)

minetest.register_chatcommand(
   "/expand",
   {
      params = "<amount> [reverse-amount] [up|down|left|right|front|back]",
      description = "expand the selection in one or two directions at once",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, arg2, arg3 = param:find("(%d+)%s*(%w*)%s*(%l*)")

	 if find == nil then
	    worldedit.player_notify(name, "invalid use: " .. param)
	    return
	 end

	 if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
	    worldedit.player_notify(name, "Undefined region. Region must be defined beforehand.")
	    return
	 end

	 local axis, direction, mark

	 axis, direction = worldedit.player_axis(name)
	 mark = worldedit.get_marker_in_axis(name, axis, direction)

	 if arg3 ~= "" then
	    axis, direction = worldedit.translate_direction(name, arg3)
	    mark = worldedit.get_marker_in_axis(name, axis, direction)
	 end
	 
	 if arg2 ~= "" then
	    local tmp = tonumber(arg2)

	    if tmp == nil then
	       axis, direction = worldedit.translate_direction(name, arg2)
	       mark = worldedit.get_marker_in_axis(name, axis, direction)
	    else
	       local tmpmark
	       if mark == 1 then
		  tmpmark = 2
	       else
		  tmpmark = 1
	       end

	       if axis == nil or direction == nil then
		  return false, "Invalid use: " .. param
	       end

	       worldedit.move_marker(name, tmpmark, axis, tmp * direction * -1)
	    end
	 end

	 if axis == nil or direction == nil then
	    return false, "Invalid use: " .. param
	 end

	 worldedit.move_marker(name, mark, axis, amount * direction)	 
	 worldedit.update_markers(name)
	 worldedit.player_notify(name, "Area expanded by " .. amount)
      end,
   }
)

minetest.register_chatcommand(
   "/contract",
   {
      params = "<amount> [reverse-amount] [up|down|left|right|front|back]",
      description = "contract the selection in one or two directions at once",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, arg2, arg3 = param:find("(%d+)%s*(%w*)%s*(%l*)")

	 if find == nil then
	    worldedit.player_notify(name, "invalid use: " .. param)
	    return
	 end

	 if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
	    worldedit.player_notify(name, "Undefined region. Region must be defined beforehand.")
	    return
	 end

	 local axis, direction, mark

	 axis, direction = worldedit.player_axis(name)
	 mark = worldedit.get_marker_in_axis(name, axis, direction)

	 if arg3 ~= "" then
	    axis, direction = worldedit.translate_direction(name, arg3)
	    mark = worldedit.get_marker_in_axis(name, axis, direction)
	 end
	 
	 if arg2 ~= "" then
	    local tmp = tonumber(arg2)

	    if tmp == nil then
	       axis, direction = worldedit.translate_direction(name, arg2)
	       mark = worldedit.get_marker_in_axis(name, axis, direction)
	    else
	       local tmpmark
	       if mark == 1 then
		  tmpmark = 2
	       else
		  tmpmark = 1
	       end

	       if axis == nil or direction == nil then
		  return false, "Invalid use: " .. param
	       end

	       worldedit.move_marker(name, tmpmark, axis, tmp * direction)
	    end
	 end

	 if axis == nil or direction == nil then
	    return false, "Invalid use: " .. param
	 end

	 worldedit.move_marker(name, mark, axis, amount * direction * -1)	 
	 worldedit.update_markers(name)
	 worldedit.player_notify(name, "Area contracted by " .. amount)
      end,
   }
)


-- Return the marker that is closest to the player
worldedit.get_closest_marker = function(name)
   local playerpos = minetest.get_player_by_name(name):getpos()

   local dist1 = vector.distance(playerpos, worldedit.pos1[name])
   local dist2 = vector.distance(playerpos, worldedit.pos2[name])

   if dist1 < dist2 then
      return 1
   else
      return 2
   end
end


-- returns which marker is closest to the specified axis and direction
worldedit.get_marker_in_axis = function(name, axis, direction)
   local pos1 = {x = 0, y = 0, z = 0}
   local pos2 = {x = 0, y = 0, z = 0}

   if direction ~= 1 and direction ~= -1 then
      return nil
   end

   if axis == 'x' then
      pos1.x = worldedit.pos1[name].x * direction
      pos2.x = worldedit.pos2[name].x * direction
      if pos1.x > pos2.x then
	 return 1
      else
	 return 2
      end
   elseif axis == 'y' then
      pos1.y = worldedit.pos1[name].y * direction
      pos2.y = worldedit.pos2[name].y * direction
      if pos1.y > pos2.y then
	 return 1
      else
	 return 2
      end
   elseif axis == 'z' then
      pos1.z = worldedit.pos1[name].z * direction
      pos2.z = worldedit.pos2[name].z * direction
      if pos1.z > pos2.z then
	 return 1
      else
	 return 2
      end
   else
      minetest.debug("worldedit.get_marker_in_axis: invalid axis.")
   end
end

-- Moves the selected marker in a single axis by amount nodes
worldedit.move_marker = function(name, marker, axis, amount)
   local pos1 = worldedit.pos1[name]
   local pos2 = worldedit.pos2[name]
   
   if marker == 1 then
      if axis == 'x' then
	 worldedit.pos1[name].x = pos1.x + amount
      elseif axis == 'y' then
	 worldedit.pos1[name].y = pos1.y + amount
      elseif axis == 'z' then
	 worldedit.pos1[name].z = pos1.z + amount
      else
	 minetest.debug("worldedit: Invalid axis in move_marker.")
      end
   elseif marker == 2 then
      if axis == 'x' then
	 worldedit.pos2[name].x = pos2.x + amount
      elseif axis == 'y' then
	 worldedit.pos2[name].y = pos2.y + amount
      elseif axis == 'z' then
	 worldedit.pos2[name].z = pos2.z + amount
      else
	 minetest.debug("worldedit: Invalid axis in move_marker.")
      end
   else
      minetest.debug("Bad marker id at worldedit.move_marker")
   end
end

-- Updates the location ingame of the markers
worldedit.update_markers = function(name, marker)
   if marker == nil then
      worldedit.mark_pos1(name)
      worldedit.mark_pos2(name)
   elseif marker == 1 then
      worldedit.mark_pos1(name)
   elseif marker == 2 then
      worldedit.mark_pos2(name)
   else
      minetest.debug("worldedit: Invalid execution of function update_markers")
   end
end


-- Translates up, down, left, right, front, back to their corresponding axes and directions according to faced direction
worldedit.translate_direction = function(name, direction)
   local axis, dir = worldedit.player_axis(name)
   local resaxis, resdir

   if direction == "up" then
      return 'y', 1
   end

   if direction == "down" then
      return 'y', -1
   end

   if direction == "front" then
      resaxis = axis
      resdir = dir
   end

   if direction == "back" then
      resaxis = axis
      resdir = -dir
   end

   if direction == "left" then
      if axis == 'x' then
	 resaxis = 'z'
	 resdir = dir
      elseif axis == 'z' then
	 resaxis = 'x'
	 resdir = -dir
      end
   end

   if direction == "right" then
      if axis == 'x' then
	 resaxis = 'z'
	 resdir = -dir
      elseif axis == 'z' then
	 resaxis = 'x'
	 resdir = dir
      end
   end   

   return resaxis, resdir
   
end
