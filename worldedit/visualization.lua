worldedit = worldedit or {}

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
worldedit.hide = function(pos1, pos2, tenv)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	if env == nil then env = minetest.env end

	local pos = {x=pos1.x, y=0, z=0}
	local placeholder = {name="worldedit:placeholder", param1=0, param2=0}
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = env:get_node(pos)
				placeholder.param1, placeholder.param2 = node.param1, node.param2 --copy node's param1 and param2
				local data = env:get_meta(pos):to_table() --obtain metadata of original node
				env:add_node(pos, placeholder) --add placeholder node
				local meta = env:get_meta(pos) --obtain placeholder meta
				meta:from_table(data) --set placeholder metadata to the original node's metadata
				meta:set_string("worldedit_placeholder", node.name)  --add the node's name
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return worldedit.volume(pos1, pos2)
end

--suppresses all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes, returning the number of nodes suppressed
worldedit.suppress = function(pos1, pos2, nodename, tenv)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	if env == nil then env = minetest.env end

	if minetest.registered_nodes[nodename] == nil then
		nodename = "default:" .. nodename
	end

	local pos = {x=pos1.x, y=0, z=0}
	local placeholder = {name="worldedit:placeholder", param1=0, param2=0}
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = env:get_node(pos)
				if node.name == nodename then
					placeholder.param1, placeholder.param2 = node.param1, node.param2 --copy node's param1 and param2
					local data = env:get_meta(pos):to_table() --obtain metadata of original node
					env:add_node(pos, placeholder) --add placeholder node
					local meta = env:get_meta(pos) --obtain placeholder meta
					meta:from_table(data) --set placeholder metadata to the original node's metadata
					meta:set_string("worldedit_placeholder", nodename)  --add the node's name
					count = count + 1
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end

--highlights all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively hiding all other nodes, returning the number of nodes found
worldedit.highlight = function(pos1, pos2, nodename, tenv)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	if env == nil then env = minetest.env end

	if minetest.registered_nodes[nodename] == nil then
		nodename = "default:" .. nodename
	end

	local pos = {x=pos1.x, y=0, z=0}
	local placeholder = {name="worldedit:placeholder", param1=0, param2=0}
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = env:get_node(pos)
				if node.name == nodename then --node found
					count = count + 1
				else --hide other nodes
					placeholder.param1, placeholder.param2 = node.param1, node.param2 --copy node's param1 and param2
					local data = env:get_meta(pos):to_table() --obtain metadata of original node
					env:add_node(pos, placeholder) --add placeholder node
					local meta = env:get_meta(pos) --obtain placeholder meta
					meta:from_table(data) --set placeholder metadata to the original node's metadata
					meta:set_string("worldedit_placeholder", node.name)  --add the node's name
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
worldedit.restore = function(pos1, pos2, tenv)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	if env == nil then env = minetest.env end

	local pos = {x=pos1.x, y=0, z=0}
	local node = {name="", param1=0, param2=0}
	local count = 0
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local currentnode = env:get_node(pos)
				if currentnode.name == "worldedit:placeholder" then
					node.param1, node.param2 = currentnode.param1, currentnode.param2 --copy node's param1 and param2
					local data = env:get_meta(pos):to_table() --obtain node metadata
					node.name = data.fields.worldedit_placeholder --set node name
					data.fields.worldedit_placeholder = nil --delete old nodename
					env:add_node(pos, node) --add original node
					env:get_meta(pos):from_table(data) --set original node metadata
					count = count + 1
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	return count
end
