worldedit = worldedit or {}

worldedit.queue = {}

worldedit.ENABLE_QUEUE = true
worldedit.BLOCKS_PER_GLOBALSTEP = 512

minetest.register_globalstep(function(dtime)
    i = 1
    while i <= #worldedit.queue and i <= worldedit.BLOCKS_PER_GLOBALSTEP do
        idx = (#worldedit.queue + 1) - i -- we use the last entry, so we don't spend days moving stuff in the table because we removed the first entry
        if worldedit.queue[idx].t == "set_node" then
            minetest.env:set_node(worldedit.queue[idx].pos, worldedit.queue[idx].node)
        elseif worldedit.queue[idx].t == "remove_node" then
            minetest.env:remove_node(worldedit.queue[idx].pos)
        elseif worldedit.queue[idx].t == "place_node" then
            minetest.env:place_node(worldedit.queue[idx].pos, worldedit.queue[idx].node)
        elseif worldedit.queue[idx].t == "dig_node" then
            minetest.env:dig_node(worldedit.queue[idx].pos)
        elseif worldedit.queue[idx].t == "add_entity" then
            minetest.env:add_entity(worldedit.queue[idx].pos, worldedit.queue[idx].name)
        elseif worldedit.queue[idx].t == "add_item" then
            minetest.env:add_item(worldedit.queue[idx].pos, worldedit.queue[idx].item)
        elseif worldedit.queue[idx].t == "meta_from_table" then
            minetest.env:get_meta(worldedit.queue[idx].pos):from_table(worldedit.queue[idx].table)
        else
            print("Unknown queue event type: " .. worldedit.queue[idx].t)
        end
        table.remove(worldedit.queue, idx)
        i = i + 1
    end
end)

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

local quene_setnode = function(self, pos_, node_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), node=table.copy(node_), t="set_node"})
end

local quene_removenode = function(self, pos_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), t="remove_node"})
end

local quene_placenode = function(self, pos_, node_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), node=table.copy(node_), t="place_node"})
end

local quene_dignode = function(self, pos_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), t="dig_node"})
end

local quene_addentity = function(self, pos_, name_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), name=name_.."", t="add_entity"})
end

local quene_additem = function(self, pos_, item_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), item=item_.."", t="add_item"})
end

local quene_setmeta = function(self, pos_, table_)
    table.insert(worldedit.queue, {pos=table.copy(pos_), table=table.copy(table_), t="meta_from_table"})
end

local aliasmeta = {
-- the other functions are left out because they are not used in worldedit
    to_table    = function(self) return minetest.env:get_meta(self._pos):to_table() end,
    set_string  = function(self, name_, value_) minetest.env:get_meta(self._pos):set_string(name_, value_) end,
    from_table  = function(self, tbl) quene_setmeta(nil, self._pos, tbl) end,
}

local get_meta_alias = function(self, pos)
    local am = table.copy(aliasmeta)
    am._pos = pos
    return am
end

worldedit.quene_aliasenv = {
-- ALL functions that are not just piped to the real minetest.env function must copy the arguments, not just reference them
    set_node        = quene_setnode,
    add_node        = quene_setnode,
    remove_node     = quene_removenode,
    get_node        = function(self, pos) return minetest.env:get_node(pos) end,
    get_node_or_nil = function(self, pos) return minetest.env:get_node_or_nil(pos) end,
    get_node_light  = function(self, pos, timeofday) return minetest.env:get_node_light(pos, timeofday) end,
    place_node      = quene_placenode,
    dig_node        = quene_dignode,
    punch_node      = function(self, pos) return minetest.env:punch_node(pos) end,
    get_meta        = get_meta_alias,
    get_node_timer  = function(self, pos) return minetest.env:get_node_timer(pos) end,
    add_entity      = quene_addentity,
    add_item        = quene_additem,
}

