worldedit = worldedit or {}

worldedit.queue = {}

worldedit.ENABLE_QUEUE = true --enable the WorldEdit block queue
worldedit.MAXIMUM_TIME = 0.08 --maximum time each step alloted for WorldEdit operations

minetest.register_globalstep(function(dtime)
    local i = 1
    local elapsed = 0
    local env = minetest.env
    while i <= #worldedit.queue and elapsed <= worldedit.MAXIMUM_TIME do
	local idx = (#worldedit.queue + 1) - i
	local entry = worldedit.queue[idx] --we use the last entry, so we don't spend days moving stuff in the table because we removed the first entry
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

