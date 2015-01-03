minetest.register_chatcommand(
   "/outset",
   {
      params = "<amount> [h|v]",
      description = "expand the selection",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, dir = param:find("^(%d+)[%s+]?([hv]?)$")
	 local message

	 if find == nil then
	    worldedit.player_notify(name, "invalid usage: " .. param)
	    return
	 end
	 
	 if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
	    message = "Undefined region. Region must be defined beforehand."
	 else
	    amount = tonumber(amount)
	    local curpos1 = worldedit.pos1[name]
	    local curpos2 = worldedit.pos2[name]

	    local dirs = worldedit.get_outset_directions(curpos1, curpos2)

	    if dir == 'h' then
	       worldedit.pos1[name].x = curpos1.x + (amount * dirs.x1)
	       worldedit.pos1[name].z = curpos1.z + (amount * dirs.z1)

	       worldedit.pos2[name].x = curpos2.x + (amount * dirs.x2)
	       worldedit.pos2[name].z = curpos2.z + (amount * dirs.z2)

	       message = "area expanded by " .. amount .. " blocks horizontally"
	    elseif dir == 'v' then
	       worldedit.pos1[name].y = curpos1.y + (amount * dirs.y1)
	       worldedit.pos2[name].y = curpos2.y + (amount * dirs.y2)

	       message = "area expanded by " .. amount .. " blocks vertically"
	    else
	       worldedit.pos1[name].x = curpos1.x + (amount * dirs.x1)
	       worldedit.pos1[name].z = curpos1.z + (amount * dirs.z1)
	       worldedit.pos1[name].y = curpos1.y + (amount * dirs.y1)

	       worldedit.pos2[name].x = curpos2.x + (amount * dirs.x2)
	       worldedit.pos2[name].z = curpos2.z + (amount * dirs.z2)
	       worldedit.pos2[name].y = curpos2.y + (amount * dirs.y2)

	       message = "area expanded by " .. amount .. " blocks in all axes"
	    end

	    worldedit.mark_pos1(name)
	    worldedit.mark_pos2(name)
	 end

	 worldedit.player_notify(name, message)
      end,
   }
)

minetest.register_chatcommand(
   "/inset",
   {
      params = "<amount> [h|v]",
      description = "contract",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, dir = param:find("^(%d+)[%s+]?([hv]?)$")
	 local message = ""

	 if find == nil then
	    worldedit.player_notify(name, "invalid usage: " .. param)
	    return
	 end
	 
	 if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
	    message = "Undefined region. Region must be defined beforehand."
	 else
	    amount = tonumber(amount)
	    local curpos1 = worldedit.pos1[name]
	    local curpos2 = worldedit.pos2[name]

	    local dirs = worldedit.get_outset_directions(curpos1, curpos2)

	    if dir == 'h' then
	       worldedit.pos1[name].x = curpos1.x - (amount * dirs.x1)
	       worldedit.pos1[name].z = curpos1.z - (amount * dirs.z1)

	       worldedit.pos2[name].x = curpos2.x - (amount * dirs.x2)
	       worldedit.pos2[name].z = curpos2.z - (amount * dirs.z2)

	       message = "area contracted by " .. amount .. " blocks horizontally"
	    elseif dir == 'v' then
	       worldedit.pos1[name].y = curpos1.y - (amount * dirs.y1)
	       worldedit.pos2[name].y = curpos2.y - (amount * dirs.y2)

	       message = "area contracted by " .. amount .. " blocks vertically"
	    else
	       worldedit.pos1[name].x = curpos1.x - (amount * dirs.x1)
	       worldedit.pos1[name].z = curpos1.z - (amount * dirs.z1)
	       worldedit.pos1[name].y = curpos1.y - (amount * dirs.y1)

	       worldedit.pos2[name].x = curpos2.x - (amount * dirs.x2)
	       worldedit.pos2[name].z = curpos2.z - (amount * dirs.z2)
	       worldedit.pos2[name].y = curpos2.y - (amount * dirs.y2)

	       message = "area contracted by " .. amount .. " blocks in all axes"
	    end

	    worldedit.mark_pos1(name)
	    worldedit.mark_pos2(name)
	 end

	 worldedit.player_notify(name, message)
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
      params = "[+|-]<amount> [x|y|z]",
      description = "Moves the selection region. Does not move contents.",
      privs = {worldedit=true},
      func = function(name, param)
	 local pos1 = worldedit.pos1[name]
	 local pos2 = worldedit.pos2[name]
	 local find, _, sign, amount, axis = param:find("^([+-]?)(%d+)[%s+]?([xyz]?)$")

	 if find == nil then
	    minetest.debug("entering if")
	    worldedit.player_notify(name, "invalid usage: " .. param)
	    return
	 end
	 
	 if pos1 == nil or pos2 == nil then
	    worldedit.player_notify(name, "Undefined region. Region must be defined beforehand.")
	    return
	 end

	 amount = tonumber(amount)

	 local direction = ""

	 if sign ~= nil and sign == '-' then
	    amount = amount * -1
	 end
	 
	 if axis == "" then
	    direction, _ = worldedit.player_axis(name)
	    amount = amount * _
	 else
	    direction = axis
	 end
	 
	 if direction == 'x' then
	    worldedit.pos1[name].x = pos1.x + amount
	    worldedit.pos2[name].x = pos2.x + amount
	 elseif direction == 'y' then
	    worldedit.pos1[name].y = pos1.y + amount
	    worldedit.pos2[name].y = pos2.y + amount
	 elseif direction == 'z' then
	    worldedit.pos1[name].z = pos1.z + amount
	    worldedit.pos2[name].z = pos2.z + amount
	 else
	    worldedit.player_notify(name, "unexpected error. direction = " .. direction)
	 end

	 worldedit.mark_pos1(name)
	 worldedit.mark_pos2(name)

	 worldedit.player_notify(name, "Area shifted by " .. amount .. " in " .. direction .. " axis")
      end,
   }
)

minetest.register_chatcommand(
   "/expand",
   {
      params = "<amount> [reverse-amount] [direction]",
      description = "expand the selection in one or two directions at once",
      privs = {worldedit=true},
      func = function(name, param)
	 local find, _, amount, arg2, arg3 = param:find("^(%d+)[%s+]?([%w+]?)[%s+]?([xyz]?)$")

	 if find == nil then
	    worldedit.player_notify(name, "invalid use: " .. param)
	    return
	 end

	 if worldedit.pos1[name] == nil or worldedit.pos2[name] == nil then
	    worldedit.player_notify(name, "Undefined region. Region must be defined beforehand.")
	    return
	 end

	 local pos1 = worldedit.pos1[name]
	 local pos2 = worldedit.pos2[name]
	 local axis, dir

	 if arg2 == "" and arg3 == "" then
	    axis, dir = worldedit.player_axis(name)
	    if worldedit.get_closest_marker(name) == 1 then
	       if axis == 'x' then
		  worldedit.pos2[name].x = pos2.x + (amount * dir)
	       elseif axis == 'y' then
		  worldedit.pos2[name].y = pos2.y + (amount * dir)
	       elseif axis == 'z' then
		  worldedit.pos2[name].z = pos2.z + (amount * dir)
	       end

	       worldedit.mark_pos2(name)
	    else
	       if axis == 'x' then
		  worldedit.pos1[name].x = pos1.x + (amount * dir)
	       elseif axis == 'y' then
		  worldedit.pos1[name].y = pos1.y + (amount * dir)
	       elseif axis == 'z' then
		  worldedit.pos1[name].z = pos1.z + (amount * dir)
	       end

	       worldedit.mark_pos1(name)
	    end
	 elseif arg2 ~= "" and arg3 == "" then
	    -- TODO
	 elseif arg2 ~= "" and arg3 ~= "" then
	    -- TODO
	 end

	 worldedit.player_notify(name, "Area expanded by " .. amount .. " on " .. axis)
      end,
   }
)

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
