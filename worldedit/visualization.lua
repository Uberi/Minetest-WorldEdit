--- Functions for visibly hiding nodes
-- @module worldedit.visualization

minetest.register_node("worldedit:placeholder", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	diggable = false,
	pointable = false,
	walkable = false,
	groups = {not_in_creative_inventory=1},
})

--- Hides all nodes in a region defined by positions `pos1` and `pos2` by
-- non-destructively replacing them with invisible nodes.
-- @return The number of nodes hidden.
function worldedit.hide(pos1, pos2)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	local get_node, get_meta, swap_node = minetest.get_node,
			minetest.get_meta, minetest.swap_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name ~= "air" and node.name ~= "worldedit:placeholder" then
					-- Save the node's original name
					get_meta(pos):set_string("worldedit_placeholder", node.name)
					-- Swap in placeholder node
					node.name = "worldedit:placeholder"
					swap_node(pos, node)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--- Suppresses all instances of `node_name` in a region defined by positions
-- `pos1` and `pos2` by non-destructively replacing them with invisible nodes.
-- @return The number of nodes suppressed.
function worldedit.suppress(pos1, pos2, node_name)
	-- Ignore placeholder supression
	if node_name == "worldedit:placeholder" then
		return 0
	end

	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local nodes = minetest.find_nodes_in_area(pos1, pos2, node_name)
	local get_node, get_meta, swap_node = minetest.get_node,
			minetest.get_meta, minetest.swap_node
	for _, pos in ipairs(nodes) do
		local node = get_node(pos)
		-- Save the node's original name
		get_meta(pos):set_string("worldedit_placeholder", node.name)
		-- Swap in placeholder node
		node.name = "worldedit:placeholder"
		swap_node(pos, node)
	end
	return #nodes
end

--- Highlights all instances of `node_name` in a region defined by positions
-- `pos1` and `pos2` by non-destructively hiding all other nodes.
-- @return The number of nodes found.
function worldedit.highlight(pos1, pos2, node_name)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local pos = {x=pos1.x, y=0, z=0}
	local get_node, get_meta, swap_node = minetest.get_node,
			minetest.get_meta, minetest.swap_node
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name == node_name then -- Node found
					count = count + 1
				elseif node.name ~= "worldedit:placeholder" then -- Hide other nodes
					-- Save the node's original name
					get_meta(pos):set_string("worldedit_placeholder", node.name)
					-- Swap in placeholder node
					node.name = "worldedit:placeholder"
					swap_node(pos, node)
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end

-- Restores all nodes hidden with WorldEdit functions in a region defined
-- by positions `pos1` and `pos2`.
-- @return The number of nodes restored.
function worldedit.restore(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)

	worldedit.keep_loaded(pos1, pos2)

	local nodes = minetest.find_nodes_in_area(pos1, pos2, "worldedit:placeholder")
	local get_node, get_meta, swap_node = minetest.get_node,
			minetest.get_meta, minetest.swap_node
	for _, pos in ipairs(nodes) do
		local node = get_node(pos)
		local meta = get_meta(pos)
		local data = meta:to_table()
		node.name = data.fields.worldedit_placeholder
		data.fields.worldedit_placeholder = nil
		meta:from_table(data)
		swap_node(pos, node)
	end
	return #nodes
end

