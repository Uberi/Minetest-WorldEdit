-- Load Table-Save/Load Library | http://lua-users.org/wiki/SaveTableToFile
print("[WorldEdit] Loading Table-Save/Load Library...")
dofile(minetest.get_modpath("worldedit").."/table_save-load.lua")
assert(table.save ~= nil)
assert(table.load ~= nil)
-- Functions
function get_tmp(name)
    local f = io.open("wetemp_" .. name .. ".txt", "r")
    if f == nil then
        return ""
    else
        return f:read("*all")
    end
end
function set_tmp(name,text)
    local f = io.open("wetemp_" .. name .. ".txt", "w")
    if f == nil then
        return false
    else
        f:write(text)
        f:close()
        return true
    end
end
function to_pos(s)
    local pos = {0,0,0}
    i = 1
    string.gsub(s,"{(.-)}", function(a)
        pos[i] = tonumber(a)
        i = i + 1
    end)
    return pos
end
function to_pos_str(x,y,z)
    return "{" .. x .. "}{" .. y .. "}{" .. z .. "}"
end
function to_pos_userstr(p)
    return "(" .. p[1] .. "," .. p[2] .. "," .. p[3] .. ")"
end
function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end
function check_player_we_perms(pname)
    local fi = ""
    local f = io.open("weperms.txt", "r")
    if f ~= nil then
        fi = f:read("*all")
        f:close()
    else
        return false
    end
    local list = {}
    i = 1
    string.gsub(fi,"{(.-)}", function(a)
        list[i] = a
        i = i + 1
    end)
    for n = 1, table.getn(list), 1 do
        if list[n] == pname then
            return true
        end
    end
    return false
end
function sort_pos(pos1,pos2)
    if pos1[1] >= pos2[1] then
        local temp = pos2[1]
        pos2[1] = pos1[1]
        pos1[1] = temp
        temp = nil
    end
    if pos1[2] >= pos2[2] then
        local temp = pos2[2]
        pos2[2] = pos1[2]
        pos1[2] = temp
        temp = nil
    end
    if pos1[3] >= pos2[3] then
        local temp = pos2[3]
        pos2[3] = pos1[3]
        pos1[3] = temp
        temp = nil
    end
    return {pos1,pos2}
end
function get_we_pos(pname)
    return to_pos(get_tmp("pos1_"..pname)),to_pos(get_tmp("pos2_"..pname))
end
-- Other Code
minetest.register_on_chat_message(function(name, message)
    local cmd = "//pos1"
    if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local pl = minetest.env:get_player_by_name(name)
            local p = pl:getpos()
            set_tmp("pos1_"..name, to_pos_str(p.x,p.y,p.z))
            minetest.chat_send_player(name, 'P1 was set to '..to_pos_userstr({p.x,p.y,p.z}))
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
        end
        return true
    end
    local cmd = "//pos2"
    if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local pl = minetest.env:get_player_by_name(name)
            local p = pl:getpos()
            set_tmp("pos2_"..name, to_pos_str(p.x,p.y,p.z))
            minetest.chat_send_player(name, 'P2 was set to '..to_pos_userstr({p.x,p.y,p.z}))
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
        end
        return true
    end
    local cmd = "//p"
	if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local ope = string.match(message, cmd.." (.*)")
            if ope == nil then
                minetest.chat_send_player(name, 'usage: '..cmd..' [get/set]')
                return true
            end
            if ope == "get" then
                local pos1,pos2 = get_we_pos(name)
                minetest.chat_send_player(name, "P1: "..to_pos_userstr(pos1))
                minetest.chat_send_player(name, "P2: "..to_pos_userstr(pos2))
                return true
            end
            if ope == "set" then
                set_tmp("postoset_"..name, "0")
                minetest.chat_send_player(name, "Please select P1 and P2")
                return true
            end
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
    end
    local cmd = "//set"
    if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local nn = string.match(message, cmd.." (.*)")
            if nn == nil then
                minetest.chat_send_player(name, 'usage: '..cmd..' [nodename]')
                return true
            end
            pos1,pos2 = get_we_pos(name)
            local temp = sort_pos(pos1,pos2)
            pos1 = temp[1]
            pos2 = temp[2]
            temp = nil
            local bc = 0
            for x = pos1[1], pos2[1], 1 do
                for y = pos1[2], pos2[2], 1 do
                    for z = pos1[3], pos2[3], 1 do
                        local np = {x=x, y=y, z=z}
                        minetest.env:add_node(np, {name=nn})
                        bc = bc + 1
                    end
                end
            end
            minetest.chat_send_player(name, bc..' Blocks changed')
            return true
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
    end
    local cmd = "//replace"
    if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local nn = {}
            local tmp = message:gsub(cmd.." ","")
            nn = tmp:split(",")
            tmp = nil
            if nn[2] == nil then
                minetest.chat_send_player(name, 'usage: '..cmd..' [nodename],[nodename2]')
                return true
            end
            pos1,pos2 = get_we_pos(name)
            local temp = sort_pos(pos1,pos2)
            pos1 = temp[1]
            pos2 = temp[2]
            temp = nil
            local bc = 0
            for x = pos1[1], pos2[1], 1 do
                for y = pos1[2], pos2[2], 1 do
                    for z = pos1[3], pos2[3], 1 do
                        local np = {x=x, y=y, z=z}
                        local n = minetest.env:get_node(np)
                        if n.name == "default:"..nn[1] or n.name == nn[1] then
                            minetest.env:add_node(np, {name=nn[2]})
                            bc = bc + 1
                        end
                    end
                end
            end
            minetest.chat_send_player(name, bc..' Blocks replaced')
            return true
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
        return true
    end
    local cmd = "//stack"
    if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) then
            local nn = {}
            local tmp = message:gsub(cmd.." ","")
            nn = tmp:split(",")
            if nn[2] == nil then
                minetest.chat_send_player(name, 'Usage: '..cmd..'  [direction],[count]')
                minetest.chat_send_player(name, 'Valid Directions are: x+ x- y+ y- z+ z-')
                return true
            end
            pos1,pos2 = get_we_pos(name)
            local temp = sort_pos(pos1,pos2)
            pos1 = temp[1]
            pos2 = temp[2]
            local bc = 0
            if nn[1] == "x+" then
                for c = 1, nn[2], 1 do
                    local offset_x = (pos2[1] - pos1[1] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x+offset_x, y=y, z=z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            if nn[1] == "x-" then
                for c = 1, nn[2], 1 do
                    local offset_x = (pos2[1] - pos1[1] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x-offset_x, y=y, z=z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            if nn[1] == "y+" then
                for c = 1, nn[2], 1 do
                    local offset_y = (pos2[2] - pos1[2] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x, y=y+offset_y, z=z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            if nn[1] == "y-" then
                for c = 1, nn[2], 1 do
                    local offset_y = (pos2[2] - pos1[2] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x, y=y-offset_y, z=z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            if nn[1] == "z+" then
                for c = 1, nn[2], 1 do
                    local offset_z = (pos2[3] - pos1[3] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x, y=y, z=z+offset_z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            if nn[1] == "z-" then
                for c = 1, nn[2], 1 do
                    local offset_z = (pos2[3] - pos1[3] + 1) * c
                    for x = pos1[1], pos2[1], 1 do
                        for y = pos1[2], pos2[2], 1 do
                            for z = pos1[3], pos2[3], 1 do
                                local n = minetest.env:get_node({x=x, y=y, z=z})
                                minetest.env:add_node({x=x, y=y, z=z-offset_z}, n)
                                bc = bc + 1
                            end
                        end
                    end
                end
            end
            minetest.chat_send_player(name, bc..' Blocks duplicated')
            return true
        else
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
    end
    local cmd = "//save"
	if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) == false then
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
        local fn = string.match(message, cmd.." (.*)")
        if fn == nil then
            minetest.chat_send_player(name, 'usage: '..cmd..' [filename]')
            return true
        end
        data = {}
        datai = 1
        ----------
        pos1,pos2 = get_we_pos(name)
        local temp = sort_pos(pos1,pos2)
        pos1 = temp[1]
        pos2 = temp[2]
        temp = nil
        local bs = 0
        for x = pos1[1], pos2[1], 1 do
            for y = pos1[2], pos2[2], 1 do
                for z = pos1[3], pos2[3], 1 do
                    local np = {x=x, y=y, z=z}
                    local np_rel = {x=pos1[1]-x, y=pos1[2]-y, z=pos1[3]-z} -- Relative Position
                    local n = minetest.env:get_node(np)
                    if n.name ~= "air" then -- Don't Save air
                        data[datai] = {np_rel,n} -- data[index] = {position,node_data}
                        datai = datai + 1
                        bs = bs + 1
                    end
                end
            end
        end
        ----------
        print(dump(data))
        table.save(data, fn)
        minetest.chat_send_player(name, bs..' Blocks saved to '..fn)
        return true
    end
    local cmd = "//load"
	if message:sub(0, #cmd) == cmd then
        if check_player_we_perms(name) == false then
            minetest.chat_send_player(name, 'You havent got the Permission for that')
            return true
        end
        local fn = string.match(message, cmd.." (.*)")
        if fn == nil then
            minetest.chat_send_player(name, 'usage: '..cmd..' [filename]')
            return true
        end
        data = {}
        data = table.load(fn)
        print(dump(data))
        ----------
        pos1 = to_pos(get_tmp("pos1_"..name))
        local bp = 0
        for i = 1, #data, 1 do
            local d = data[i]
            local np = {x=pos1[1]-d[1].x,y=pos1[2]-d[1].y,z=pos1[3]-d[1].z}
            minetest.env:add_node(np,d[2])
            bp = bp + 1
        end
        ----------
        minetest.chat_send_player(name, bp..' Blocks pasted at '..to_pos_userstr(pos1))
        return true
    end
end)
minetest.register_on_punchnode(function(p, node, puncher)
	if puncher:get_player_name() ~= nil then
		local pn = puncher:get_player_name()
		if check_player_we_perms(pn) == false then return end
		if get_tmp("postoset_"..pn) == "1" then
			set_tmp("pos2_"..pn, to_pos_str(p.x,p.y,p.z))
			set_tmp("postoset_"..pn, "-1")
            minetest.chat_send_player(pn, 'P2 was set to '..to_pos_userstr({p.x,p.y,p.z}))
		end
		if get_tmp("postoset_"..pn) == "0" then
			set_tmp("pos1_"..pn, to_pos_str(p.x,p.y,p.z))
			set_tmp("postoset_"..pn, "1")
            minetest.chat_send_player(pn, 'P1 was set to '..to_pos_userstr({p.x,p.y,p.z}))
		end
	end
end)
print("[WorldEdit] Loaded!")
