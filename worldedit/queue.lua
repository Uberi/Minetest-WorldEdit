worldedit = worldedit or {}
local minetest = minetest --local copy of global

worldedit.queue = {}
worldedit.lower = 1
worldedit.higher = 0

worldedit.ENABLE_QUEUE = true --enable the WorldEdit block queue
worldedit.MAXIMUM_TIME = 0.08 --maximum time each step alloted for WorldEdit operations

minetest.register_globalstep(function(dtime)
    local elapsed = 0
    local env = minetest.env
    while worldedit.lower <= worldedit.higher and elapsed <= worldedit.MAXIMUM_TIME do
        local entry = worldedit.queue[worldedit.lower]
        if entry.t == "set_node" then
            env:set_node(entry.pos, entry.node)
            elapsed = elapsed + 0.0002
        elseif entry.t == "remove_node" then
            env:remove_node(entry.pos)
            elapsed = elapsed + 0.0002
        elseif entry.t == "place_node" then
            env:place_node(entry.pos, entry.node)
            elapsed = elapsed + 0.001
        elseif entry.t == "dig_node" then
            env:dig_node(entry.pos)
            elapsed = elapsed + 0.001
        elseif entry.t == "add_entity" then
            env:add_entity(entry.pos, entry.name)
            elapsed = elapsed + 0.005
        elseif entry.t == "add_item" then
            env:add_item(entry.pos, entry.item)
            elapsed = elapsed + 0.005
        elseif entry.t == "meta_from_table" then
            env:get_meta(entry.pos):from_table(entry.table)
            elapsed = elapsed + 0.0002
        else
            print("Unknown queue event type: " .. entry.t)
        end
        worldedit.queue[worldedit.lower] = nil
        worldedit.lower = worldedit.lower + 1
    end
end)

worldedit.enqueue = function(value)
        worldedit.higher = worldedit.higher + 1
        worldedit.queue[worldedit.higher] = value
end

function table.copy(t, seen)
    seen = seen or {}
    if t == nil then return nil end
    if seen[t] then return seen[t] end

    local nt = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            nt[k] = table.copy(v, seen)
        else
            nt[k] = v
        end
    end
    seen[t] = nt
    return nt
end

local queue_setnode = function(self, pos_, node_)
    worldedit.enqueue({pos=table.copy(pos_), node=table.copy(node_), t="set_node"})
end

local queue_removenode = function(self, pos_)
    worldedit.enqueue({pos=table.copy(pos_), t="remove_node"})
end

local queue_placenode = function(self, pos_, node_)
    worldedit.enqueue({pos=table.copy(pos_), node=table.copy(node_), t="place_node"})
end

local queue_dignode = function(self, pos_)
    worldedit.enqueue({pos=table.copy(pos_), t="dig_node"})
end

local queue_addentity = function(self, pos_, name_)
    worldedit.enqueue({pos=table.copy(pos_), name=name_.."", t="add_entity"})
end

local queue_additem = function(self, pos_, item_)
    worldedit.enqueue({pos=table.copy(pos_), item=item_.."", t="add_item"})
end

local queue_setmeta = function(self, pos_, table_)
    worldedit.enqueue({pos=table.copy(pos_), table=table.copy(table_), t="meta_from_table"})
end

local aliasmeta = {
-- the other functions are left out because they are not used in worldedit
    to_table    = function(self) return minetest.env:get_meta(self._pos):to_table() end,
    set_string  = function(self, name_, value_) minetest.env:get_meta(self._pos):set_string(name_, value_) end,
    from_table  = function(self, tbl) queue_setmeta(nil, self._pos, tbl) end,
}

local get_meta_alias = function(self, pos)
    local am = table.copy(aliasmeta)
    am._pos = pos
    return am
end

worldedit.queue_aliasenv = {
-- ALL functions that are not just piped to the real minetest.env function must copy the arguments, not just reference them
    set_node        = queue_setnode,
    add_node        = queue_setnode,
    remove_node     = queue_removenode,
    get_node        = function(self, pos) return minetest.env:get_node(pos) end,
    get_node_or_nil = function(self, pos) return minetest.env:get_node_or_nil(pos) end,
    get_node_light  = function(self, pos, timeofday) return minetest.env:get_node_light(pos, timeofday) end,
    place_node      = queue_placenode,
    dig_node        = queue_dignode,
    punch_node      = function(self, pos) return minetest.env:punch_node(pos) end,
    get_meta        = get_meta_alias,
    get_node_timer  = function(self, pos) return minetest.env:get_node_timer(pos) end,
    add_entity      = queue_addentity,
    add_item        = queue_additem,
}
