worldedit = worldedit or {}
local minetest = minetest --local copy of global

--modifies positions `pos1` and `pos2` so that each component of `pos1` is less than or equal to its corresponding conent of `pos2`, returning two new positions
worldedit.sort_pos = function(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--determines the volume of the region defined by positions `pos1` and `pos2`, returning the volume
worldedit.volume = function(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	return (pos2.x - pos1.x + 1) * (pos2.y - pos1.y + 1) * (pos2.z - pos1.z + 1)
end

minetest.register_node("worldedit:placeholder", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	diggable = false,
	groups = {not_in_creative_inventory=1},
})

--hides all nodes in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes, returning the number of nodes hidden
worldedit.hide = function(pos1, pos2)
	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name ~= "worldedit:placeholder" then
					local data = get_meta(pos):to_table() --obtain metadata of original node
					data.fields.worldedit_placeholder = node.name --add the node's name
					node.name = "worldedit:placeholder" --set node name
					add_node(pos, node) --add placeholder node
					get_meta(pos):from_table(data) --set placeholder metadata to the original node's metadata
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--suppresses all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes, returning the number of nodes suppressed
worldedit.suppress = function(pos1, pos2, nodename)
	--ignore placeholder supression
	if nodename == "worldedit:placeholder" then
		return 0
	end

	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local nodes = minetest.find_nodes_in_area(pos1, pos2, nodename)
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	for _, pos in ipairs(nodes) do
		local node = get_node(pos)
		local data = get_meta(pos):to_table() --obtain metadata of original node
		data.fields.worldedit_placeholder = node.name --add the node's name
		node.name = "worldedit:placeholder" --set node name
		add_node(pos, node) --add placeholder node
		get_meta(pos):from_table(data) --set placeholder metadata to the original node's metadata
	end
	return #nodes
end

--highlights all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively hiding all other nodes, returning the number of nodes found
worldedit.highlight = function(pos1, pos2, nodename)
	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name == nodename then --node found
					count = count + 1
				elseif node.name ~= "worldedit:placeholder" then --hide other nodes
					local data = get_meta(pos):to_table() --obtain metadata of original node
					data.fields.worldedit_placeholder = node.name --add the node's name
					node.name = "worldedit:placeholder" --set node name
					add_node(pos, node) --add placeholder node
					get_meta(pos):from_table(data) --set placeholder metadata to the original node's metadata
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end

--restores all nodes hidden with WorldEdit functions in a region defined by positions `pos1` and `pos2`, returning the number of nodes restored
worldedit.restore = function(pos1, pos2)
	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local nodes = minetest.find_nodes_in_area(pos1, pos2, "worldedit:placeholder")
	local get_node, get_meta, add_node = minetest.get_node, minetest.get_meta, minetest.add_node
	for _, pos in ipairs(nodes) do
		local node = get_node(pos)
		local data = get_meta(pos):to_table() --obtain node metadata
		node.name = data.fields.worldedit_placeholder --set node name
		data.fields.worldedit_placeholder = nil --delete old nodename
		add_node(pos, node) --add original node
		get_meta(pos):from_table(data) --set original node metadata
	end
	return #nodes
end
