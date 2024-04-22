local S = minetest.get_translator("worldedit_commands")

local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end


worldedit.register_command("deleteblocks", {
	params = "",
	description = S("Remove all MapBlocks (16x16x16) containing the selected area from the map"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local success = minetest.delete_area(pos1, pos2)
		if success then
			return true, S("Area deleted.")
		else
			return false, S("There was an error during deletion of the area.")
		end
	end,
})

worldedit.register_command("clearobjects", {
	params = "",
	description = S("Clears all objects within the WorldEdit region"),
	category = S("Node manipulation"), -- not really, but it doesn't fit anywhere else
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.clear_objects(worldedit.pos1[name], worldedit.pos2[name])
		return true, S("@1 objects cleared", count)
	end,
})

worldedit.register_command("set", {
	params = "<node>",
	description = S("Set the current WorldEdit region to <node>"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.set(worldedit.pos1[name], worldedit.pos2[name], node)
		return true, S("@1 nodes set", count)
	end,
})

worldedit.register_command("param2", {
	params = "<param2>",
	description = S("Set param2 of all nodes in the current WorldEdit region to <param2>"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local param2 = tonumber(param)
		if not param2 then
			return false
		elseif param2 < 0 or param2 > 255 then
			return false, S("Param2 is out of range (must be between 0 and 255 inclusive!)")
		end
		return true, param2
	end,
	nodes_needed = check_region,
	func = function(name, param2)
		local count = worldedit.set_param2(worldedit.pos1[name], worldedit.pos2[name], param2)
		return true, S("@1 nodes altered", count)
	end,
})

worldedit.register_command("mix", {
	params = "<node1> [count1] <node2> [count2] ...",
	description = S("Fill the current WorldEdit region with a random mix of <node1>, ..."),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local nodes = {}
		for nodename in param:gmatch("[^%s]+") do
			if tonumber(nodename) ~= nil and #nodes > 0 then
				local last_node = nodes[#nodes]
				for i = 1, tonumber(nodename) do
					nodes[#nodes + 1] = last_node
				end
			else
				local node = worldedit.normalize_nodename(nodename)
				if not node then
					return false, S("invalid node name: @1", nodename)
				end
				nodes[#nodes + 1] = node
			end
		end
		if #nodes == 0 then
			return false
		end
		return true, nodes
	end,
	nodes_needed = check_region,
	func = function(name, nodes)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		local count = worldedit.set(pos1, pos2, nodes)
		return true, S("@1 nodes set", count)
	end,
})

local check_replace = function(param)
	local found, _, searchnode, replacenode = param:find("^([^%s]+)%s+(.+)$")
	if found == nil then
		return false
	end
	local newsearchnode = worldedit.normalize_nodename(searchnode)
	if not newsearchnode then
		return false, S("invalid search node name: @1", searchnode)
	end
	local newreplacenode = worldedit.normalize_nodename(replacenode)
	if not newreplacenode then
		return false, S("invalid replace node name: @1", replacenode)
	end
	return true, newsearchnode, newreplacenode
end

worldedit.register_command("replace", {
	params = "<search node> <replace node>",
	description = S("Replace all instances of <search node> with <replace node> in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node)
		return true, S("@1 nodes replaced", count)
	end,
})

worldedit.register_command("replaceinverse", {
	params = "<search node> <replace node>",
	description = S("Replace all nodes other than <search node> with <replace node> in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = check_replace,
	nodes_needed = check_region,
	func = function(name, search_node, replace_node)
		local count = worldedit.replace(worldedit.pos1[name], worldedit.pos2[name],
				search_node, replace_node, true)
		return true, S("@1 nodes replaced", count)
	end,
})

worldedit.register_command("fixlight", {
	params = "",
	description = S("Fix the lighting in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.fixlight(worldedit.pos1[name], worldedit.pos2[name])
		return true, S("@1 nodes updated", count)
	end,
})

local drain_cache

local function drain(pos1, pos2)
	if drain_cache == nil then
		drain_cache = {}
		for name, d in pairs(minetest.registered_nodes) do
			if d.drawtype == "liquid" or d.drawtype == "flowingliquid" then
				drain_cache[name] = true
			end
		end
	end

	pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local count = 0

	local get_node, remove_node = minetest.get_node, minetest.remove_node
	for x = pos1.x, pos2.x do
	for y = pos1.y, pos2.y do
	for z = pos1.z, pos2.z do
		local p = vector.new(x, y, z)
		local n = get_node(p).name
		if drain_cache[n] then
			remove_node(p)
			count = count + 1
		end
	end
	end
	end
	return count
end

worldedit.register_command("drain", {
	params = "",
	description = S("Remove any fluid node within the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = drain(worldedit.pos1[name], worldedit.pos2[name])
		return true, S("@1 nodes updated", count)
	end,
})

local clearcut_cache

local function clearcut(pos1, pos2)
	-- decide which nodes we consider plants
	if clearcut_cache == nil then
		clearcut_cache = {}
		for name, def in pairs(minetest.registered_nodes) do
			local groups = def.groups or {}
			if (
				-- the groups say so
				groups.flower or groups.grass or groups.flora or groups.plant or
				groups.leaves or groups.tree or groups.leafdecay or groups.sapling or
				-- drawtype heuristic
				(def.is_ground_content and def.buildable_to and
					(def.sunlight_propagates or not def.walkable)
					and def.drawtype == "plantlike") or
				-- if it's flammable, it probably needs to go too
				(def.is_ground_content and not def.walkable and groups.flammable)
			) then
				clearcut_cache[name] = true
			end
		end
	end
	local plants = clearcut_cache

	local count = 0
	local prev, any

	local get_node, remove_node = minetest.get_node, minetest.remove_node
	for x = pos1.x, pos2.x do
	for z = pos1.z, pos2.z do
		prev = false
		any = false
		-- first pass: remove floating nodes that would be left over
		for y = pos1.y, pos2.y do
			local pos = vector.new(x, y, z)
			local n = get_node(pos).name
			if plants[n] then
				prev = true
				any = true
			elseif prev then
				local def = minetest.registered_nodes[n] or {}
				local groups = def.groups or {}
				if groups.attached_node or (def.buildable_to and groups.falling_node) then
					remove_node(pos)
					count = count + 1
				else
					prev = false
				end
			end
		end

		-- second pass: remove plants, top-to-bottom to avoid item drops
		if any then
			for y = pos2.y, pos1.y, -1 do
				local pos = vector.new(x, y, z)
				local n = get_node(pos).name
				if plants[n] then
					remove_node(pos)
					count = count + 1
				end
			end
		end
	end
	end

	return count
end

worldedit.register_command("clearcut", {
	params = "",
	description = S("Remove any plant, tree or foliage-like nodes in the selected region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local pos1, pos2 = worldedit.sort_pos(worldedit.pos1[name], worldedit.pos2[name])
		local count = clearcut(pos1, pos2)
		return true, S("@1 nodes removed", count)
	end,
})

worldedit.register_command("hide", {
	params = "",
	description = S("Hide all nodes in the current WorldEdit region non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.hide(worldedit.pos1[name], worldedit.pos2[name])
		return true, S("@1 nodes hidden", count)
	end,
})

worldedit.register_command("suppress", {
	params = "<node>",
	description = S("Suppress all <node> in the current WorldEdit region non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.suppress(worldedit.pos1[name], worldedit.pos2[name], node)
		return true, S("@1 nodes suppressed", count)
	end,
})

worldedit.register_command("highlight", {
	params = "<node>",
	description = S("Highlight <node> in the current WorldEdit region by hiding everything else non-destructively"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	parse = function(param)
		local node = worldedit.normalize_nodename(param)
		if not node then
			return false, S("invalid node name: @1", param)
		end
		return true, node
	end,
	nodes_needed = check_region,
	func = function(name, node)
		local count = worldedit.highlight(worldedit.pos1[name], worldedit.pos2[name], node)
		return true, S("@1 nodes highlighted", count)
	end,
})

worldedit.register_command("restore", {
	params = "",
	description = S("Restores nodes hidden with WorldEdit in the current WorldEdit region"),
	category = S("Node manipulation"),
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
	func = function(name)
		local count = worldedit.restore(worldedit.pos1[name], worldedit.pos2[name])
		return true, S("@1 nodes restored", count)
	end,
})
