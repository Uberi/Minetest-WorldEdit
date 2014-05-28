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

--determines the version of serialized data `value`, returning the version as a positive integer or 0 for unknown versions
worldedit.valueversion = function(value)
	if value:find("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)") and not value:find("%{") then --previous list format
		return 3
	elseif value:find("^[^\"']+%{%d+%}") then
		if value:find("%[\"meta\"%]") then --previous meta flat table format
			return 2
		end
		return 1 --original flat table format
	elseif value:find("%{") then --current nested table format
		return 4
	end
	return 0 --unknown format
end

--converts the region defined by positions `pos1` and `pos2` into a single string, returning the serialized data and the number of nodes serialized
worldedit.serialize = function(pos1, pos2)
	--make area stay loaded
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	local pos = {x=pos1.x, y=0, z=0}
	local count = 0
	local result = {}
	local get_node, get_meta = minetest.get_node, minetest.get_meta
	while pos.x <= pos2.x do
		pos.y = pos1.y
		while pos.y <= pos2.y do
			pos.z = pos1.z
			while pos.z <= pos2.z do
				local node = get_node(pos)
				if node.name ~= "air" and node.name ~= "ignore" then
					count = count + 1
					local meta = get_meta(pos):to_table()

					--convert metadata itemstacks to itemstrings
					for name, inventory in pairs(meta.inventory) do
						for index, stack in ipairs(inventory) do
							inventory[index] = stack.to_string and stack:to_string() or stack
						end
					end

					result[count] = {
						x = pos.x - pos1.x,
						y = pos.y - pos1.y,
						z = pos.z - pos1.z,
						name = node.name,
						param1 = node.param1,
						param2 = node.param2,
						meta = meta,
					}
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
	result = minetest.serialize(result) --convert entries to a string
	return result, count
end

--determines the volume the nodes represented by string `value` would occupy if deserialized at `originpos`, returning the two corner positions and the number of nodes
--contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.allocate = function(originpos, value)
	local huge = math.huge
	local pos1x, pos1y, pos1z = huge, huge, huge
	local pos2x, pos2y, pos2z = -huge, -huge, -huge
	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	local version = worldedit.valueversion(value)
	if version == 1 or version == 2 then --flat table format
		--obtain the node table
		local get_tables = loadstring(value)
		if get_tables then --error loading value
			return originpos, originpos, count
		end
		local tables = get_tables()

		--transform the node table into an array of nodes
		for i = 1, #tables do
			for j, v in pairs(tables[i]) do
				if type(v) == "table" then
					tables[i][j] = tables[v[1]]
				end
			end
		end
		local nodes = tables[1]

		--check the node array
		count = #nodes
		if version == 1 then --original flat table format
			for index = 1, count do
				local entry = nodes[index]
				local pos = entry[1]
				local x, y, z = originx - pos.x, originy - pos.y, originz - pos.z
				if x < pos1x then pos1x = x end
				if y < pos1y then pos1y = y end
				if z < pos1z then pos1z = z end
				if x > pos2x then pos2x = x end
				if y > pos2y then pos2y = y end
				if z > pos2z then pos2z = z end
			end
		else --previous meta flat table format
			for index = 1, count do
				local entry = nodes[index]
				local x, y, z = originx - entry.x, originy - entry.y, originz - entry.z
				if x < pos1x then pos1x = x end
				if y < pos1y then pos1y = y end
				if z < pos1z then pos1z = z end
				if x > pos2x then pos2x = x end
				if y > pos2y then pos2y = y end
				if z > pos2z then pos2z = z end
			end
		end
	elseif version == 3 then --previous list format
		for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
			x, y, z = originx + tonumber(x), originy + tonumber(y), originz + tonumber(z)
			if x < pos1x then pos1x = x end
			if y < pos1y then pos1y = y end
			if z < pos1z then pos1z = z end
			if x > pos2x then pos2x = x end
			if y > pos2y then pos2y = y end
			if z > pos2z then pos2z = z end
			count = count + 1
		end
	elseif version == 4 then --current nested table format
		--wip: this is a filthy hack that works surprisingly well
		value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1)
		local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
		local startpos, startpos1, endpos = 1, 1
		local nodes = {}
		while true do
			startpos, endpos = escaped:find("},%s*{", startpos)
			if not startpos then
				break
			end
			local current = value:sub(startpos1, startpos)
			table.insert(nodes, minetest.deserialize("return " .. current))
			startpos, startpos1 = endpos, endpos
		end
		table.insert(nodes, minetest.deserialize("return " .. value:sub(startpos1)))

		--local nodes = minetest.deserialize(value) --wip: this is broken for larger tables in the current version of LuaJIT

		count = #nodes
		for index = 1, count do
			local entry = nodes[index]
			x, y, z = originx + entry.x, originy + entry.y, originz + entry.z
			if x < pos1x then pos1x = x end
			if y < pos1y then pos1y = y end
			if z < pos1z then pos1z = z end
			if x > pos2x then pos2x = x end
			if y > pos2y then pos2y = y end
			if z > pos2z then pos2z = z end
		end
	end
	local pos1 = {x=pos1x, y=pos1y, z=pos1z}
	local pos2 = {x=pos2x, y=pos2y, z=pos2z}
	return pos1, pos2, count
end

--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized
--contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.deserialize = function(originpos, value)
	--make area stay loaded
	local pos1, pos2 = worldedit.allocate(originpos, value)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)

	local originx, originy, originz = originpos.x, originpos.y, originpos.z
	local count = 0
	local add_node, get_meta = minetest.add_node, minetest.get_meta
	local version = worldedit.valueversion(value)
	if version == 1 or version == 2 then --original flat table format
		--obtain the node table
		local get_tables = loadstring(value)
		if not get_tables then --error loading value
			return count
		end
		local tables = get_tables()

		--transform the node table into an array of nodes
		for i = 1, #tables do
			for j, v in pairs(tables[i]) do
				if type(v) == "table" then
					tables[i][j] = tables[v[1]]
				end
			end
		end
		local nodes = tables[1]

		--load the node array
		count = #nodes
		if version == 1 then --original flat table format
			for index = 1, count do
				local entry = nodes[index]
				local pos = entry[1]
				pos.x, pos.y, pos.z = originx - pos.x, originy - pos.y, originz - pos.z
				add_node(pos, entry[2])
			end
		else --previous meta flat table format
			for index = 1, #nodes do
				local entry = nodes[index]
				entry.x, entry.y, entry.z = originx + entry.x, originy + entry.y, originz + entry.z
				add_node(entry, entry) --entry acts both as position and as node
				get_meta(entry):from_table(entry.meta)
			end
		end
	elseif version == 3 then --previous list format
		local pos = {x=0, y=0, z=0}
		local node = {name="", param1=0, param2=0}
		for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
			pos.x, pos.y, pos.z = originx + tonumber(x), originy + tonumber(y), originz + tonumber(z)
			node.name, node.param1, node.param2 = name, param1, param2
			add_node(pos, node)
			count = count + 1
		end
	elseif version == 4 then --current nested table format
		--wip: this is a filthy hack that works surprisingly well
		value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1)
		local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
		local startpos, startpos1, endpos = 1, 1
		local nodes = {}
		while true do
			startpos, endpos = escaped:find("},%s*{", startpos)
			if not startpos then
				break
			end
			local current = value:sub(startpos1, startpos)
			table.insert(nodes, minetest.deserialize("return " .. current))
			startpos, startpos1 = endpos, endpos
		end
		table.insert(nodes, minetest.deserialize("return " .. value:sub(startpos1)))

		--local nodes = minetest.deserialize(value) --wip: this is broken for larger tables in the current version of LuaJIT

		--load the nodes
		count = #nodes
		for index = 1, count do
			local entry = nodes[index]
			entry.x, entry.y, entry.z = originx + entry.x, originy + entry.y, originz + entry.z
			add_node(entry, entry) --entry acts both as position and as node
		end

		--load the metadata
		for index = 1, count do
			local entry = nodes[index]
			get_meta(entry):from_table(entry.meta)
		end
	end
	return count
end

-- create a copy of a node added by worldedit.deserializeAligned, then rotate it and replace the original with the correctly aligned copy
--   hopefully this function is not required, but is included as it may aid/improve backward compatibility if worldedit.getNewRotation doesn't work properly
worldedit.screwdriver_handler = function(pos, axisChange)
	-- This function is hopefully not needed, but is included just in case (for old file formats)
	-- the basis of this is the minetest screwdriver function
	-- it would probably 
	if axisChange == "Z" then return end

	-- create a copy of the node
	local nodeRot = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

	-- Get ready to set the param2
	local n = nodeRot.param2

	-- screwdriver uses axis direction. not sure why, but leave it there just in case...
	local axisdir = math.floor(n / 4)
	local rotation = n - axisdir * 4
	-- screwdriver uses a separate function rather than modulus. Not sure why, but this seems to work
	if axisChange == "X" then
		n = axisdir * 4 + ((rotation + 1) % 4)
	elseif axisChange == "z" then
		n = axisdir * 4 + ((rotation + 2) % 4)
	elseif axisChange == "x" then
		n = axisdir * 4 + ((rotation + 3) % 4)
	else
		n = axisdir * 4
	end

	-- now replace the node with the copied one
	nodeRot.param2 = n
	minetest.swap_node({x=pos.x, y=pos.y, z=pos.z}, nodeRot)
		
end

-- return the correct orientation for a node within a region being loaded by worldedit.deserializeAligned
worldedit.getNewRotation = function(param2, axisChange)
	-- the basis of this is the minetest screwdriver function
	if axisChange == "Z" then return param2 end

	-- screwdriver uses axisdir. not sure why, but leave it there just in case...
	local axisdir = math.floor(param2 / 4)
	local rotation = param2 - axisdir * 4
	-- screwdriver uses a separate function rather than modulus. Not sure why, but modulus seems to work without the extra call
	if axisChange == "X" then
		param2 = axisdir * 4 + ((rotation + 1) % 4)
	elseif axisChange == "z" then
		param2 = axisdir * 4 + ((rotation + 2) % 4)
	elseif axisChange == "x" then
		param2 = axisdir * 4 + ((rotation + 3) % 4)
	end

	-- now return the new param2
	return param2
end

-- returns true if mod is known, else false. Accepts either a mod, or a mod:node 
worldedit.knownMod = function(modName, missingMods)
	local colonLoc = string.find(modName, ":")
	if colonLoc ~= nil then modName = modName:sub(0,colonLoc-1) end
	if not string.find(missingMods, (modName.. ";")) then
		if not minetest.get_modpath(modName) then
			missingMods = missingMods.. modName.. "; "
			print("unknown mod: ".. modName)
			return false, missingMods
		else
			return true, missingMods
		end
	else
		return false, missingMods
	end
end

worldedit.minmax = function(posToCheck,posMin,posMax)
	if posToCheck.x < posMin.x then posMin.x = posToCheck.x end
	if posToCheck.y < posMin.y then posMin.y = posToCheck.y end
	if posToCheck.z < posMin.z then posMin.z = posToCheck.z end
	if posToCheck.x > posMax.x then posMax.x = posToCheck.x end
	if posToCheck.y > posMax.y then posMax.y = posToCheck.y end
	if posToCheck.z > posMax.z then posMax.z = posToCheck.z end
	
	return posMin, posMax
	
end


--loads the nodes represented by string `value` at position `originpos`, returning the number of nodes deserialized, and locations
-- it is essentially an enhancement of worldedit.load with the addition of aligning load to a particular axis, tracking missingmods
--   not attempting (and failing) to add nodes to unknown mods, monitoring the bounds of the load region

--   Use .deserializeAlign to replace .deserialize by running with axis="Z":-
--worldedit.deserialize = function(originpos, value)
--	count = worldedit.deserializeAlign(originpos, value, "Z", false)
--	return count
--end

--   Use .deserializeAlign to replace .allocate by running with  axis="Z" and runTest=true (as is done internally)
--worldedit.allocate(originpos, value)
--	count, posMin, posMax, unknownModCnt, missingMods = worldedit.deserializeAlign(originpos, value, "Z", true)
--	return 	posMin, posMax, count
--end

--contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile) by ChillCode, available under the MIT license (GPL compatible)
worldedit.deserializeAlign = function(originpos, value, axis, runTest)
	local huge = math.huge
	local posMin = {x=huge, y=huge, z=huge}
	local posMax = {x=-huge, y=-huge, z=-huge}
	local count = 0

	if not runTest then
		--make area stay loaded
		-- loop deserializeAlign once to identify posMin and posMax for loading (and holding) the region with voxel_manip
		local count, posMin, posMax = worldedit.deserializeAlign(originpos, value, axis, true)
		local manip = minetest.get_voxel_manip()
		manip:read_from_map(posMin, posMax)
	end

	local add_node, get_meta = minetest.add_node, minetest.get_meta
	local version = worldedit.valueversion(value)
	local unknownModCnt = 0
	local missingMods = ""

--	print ("Debug info deserializeAligned: version: ".. version)
--	minetest.chat_send_all("Debug info deserializeAligned: version: ".. version)

	if version == 1 or version == 2 then --original flat table format
		--obtain the node table
		local get_tables = loadstring(value)
		if not get_tables then --error loading value
			return count
		end
		local tables = get_tables()

		--transform the node table into an array of nodes
		for i = 1, #tables do
			for j, v in pairs(tables[i]) do
				if type(v) == "table" then
					tables[i][j] = tables[v[1]]
				end
			end
		end
		local nodes = tables[1]

		--load the node array
		count = #nodes
		if version == 1 then --original flat table format
			print ("WorldEdit deserializeAligned: attempting to rotate untested file format version: 1")
			for index = 1, count do
				local entry = nodes[index]
				local pos = entry[1]
				if axis == "x" then
					pos.x, pos.y, pos.z = originpos.x + pos.z, originpos.y - pos.y, originpos.z - pos.x
				elseif axis == "X" then
					pos.x, pos.y, pos.z = originpos.x - pos.z, originpos.y - pos.y, originpos.z + pos.x
				elseif axis == "z" then
					pos.x, pos.y, pos.z = originpos.x + pos.x, originpos.y - pos.y, originpos.z + pos.z
				elseif axis == "Z" then
					pos.x, pos.y, pos.z = originpos.x - pos.x, originpos.y - pos.y, originpos.z - pos.z
				end
--				pos.x, pos.y, pos.z = originpos.x - pos.x, originpos.y - pos.y, originpos.z - pos.z

				posMin,posMax = worldedit.minmax(pos,posMin,posMax)	-- update max and min positions

				entry[2].param2 = worldedit.getNewRotation(entry[2].param2,axis)	-- adjust param2 (rotation of the node) to match the overall rotation of the load
												-- this has only been tested to work with version == 4
												-- I'm not sure of the format, so if it wouldn't work then disable and
												-- enable the worldedit.screwdriver_handler after the node has been added
				knownMod, missingMods = worldedit.knownMod(entry[2].name, missingMods) 
				if knownMod then
					if not runTest then add_node(pos, entry[2]) end
				else
					unknownModCnt = unknownModCnt +1
				end
				-- worldedit.screwdriver_handler({x=pos.x, y=pos.y, z=pos.z}, axis)		-- this would rotate the node after it's been placed (just in case needed for old format)
			end
		else --previous meta flat table format
			print ("WorldEdit deserializeAligned: attempting to rotate untested file format version: 2")
			for index = 1, #nodes do
				local entry = nodes[index]
				if axis == "x" then
					entry.x, entry.y, entry.z = originpos.x - entry.z, originpos.y + entry.y, originpos.z + entry.x
				elseif axis == "X" then
					entry.x, entry.y, entry.z = originpos.x + entry.z, originpos.y + entry.y, originpos.z - entry.x
				elseif axis == "z" then
					entry.x, entry.y, entry.z = originpos.x - entry.x, originpos.y + entry.y, originpos.z - entry.z
				elseif axis == "Z" then
					entry.x, entry.y, entry.z = originpos.x + entry.x, originpos.y + entry.y, originpos.z + entry.z
				end
--				entry.x, entry.y, entry.z = originpos.x + entry.x, originpos.y + entry.y, originpos.z + entry.z


				posMin,posMax = worldedit.minmax(entry,posMin,posMax)	-- update max and min positions
				entry.param2 = worldedit.getNewRotation(entry.param2,axis)	-- adjust param2 (rotation of the node) to match the overall rotation of the load
											-- this has only been tested to work with version == 4
											-- I'm not sure of the format, so if it wouldn't work then disable and
											-- enable the worldedit.screwdriver_handler after the node has been added

				knownMod, missingMods = worldedit.knownMod(entry.name, missingMods) 
				if knownMod then
					if not runTest then add_node(entry, entry) end	--entry acts both as position and as node
				else
					unknownModCnt = unknownModCnt +1
				end
				-- worldedit.screwdriver_handler({x=entry.x, y=entry.y, z=entry.z}, axis)		-- this would rotate the node after it's been placed (just in case needed for old format)

				get_meta(entry):from_table(entry.meta)
			end
		end
 	elseif version == 3 then --previous list format
		print ("WorldEdit deserializeAligned: attempting to rotate untested file format version: 3")
		local pos = {x=0, y=0, z=0}
		local node = {name="", param1=0, param2=0}
		for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do --match node entries
			if axis == "x" then
				pos.x, pos.y, pos.z = originpos.x - tonumber(z), originpos.y + tonumber(y), originpos.z + tonumber(x)
			elseif axis == "X" then
				pos.x, pos.y, pos.z = originpos.x + tonumber(z), originpos.y + tonumber(y), originpos.z - tonumber(x)
			elseif axis == "z" then
				pos.x, pos.y, pos.z = originpos.x - tonumber(x), originpos.y + tonumber(y), originpos.z - tonumber(z)
			elseif axis == "z" then
				pos.x, pos.y, pos.z = originpos.x + tonumber(x), originpos.y + tonumber(y), originpos.z + tonumber(z)
			end
--			pos.x, pos.y, pos.z = originpos.x + tonumber(x), originpos.y + tonumber(y), originpos.z + tonumber(z)
			node.name, node.param1, node.param2 = name, param1, param2

			posMin,posMax = worldedit.minmax(pos,posMin,posMax)	-- update max and min positions

			node.param2 = worldedit.getNewRotation(node.param2,axis)	-- adjust param2 (rotation of the node) to match the overall rotation of the load
										-- this has only been tested to work with version == 4
										-- I'm not sure of the format, so if it wouldn't work then disable and
										-- enable the worldedit.screwdriver_handler after the node has been added
			knownMod, missingMods = worldedit.knownMod(node.name, missingMods) 
			if knownMod then
				if not runTest then add_node(pos, node) end
			else
				unknownModCnt = unknownModCnt +1
			end
			-- worldedit.screwdriver_handler({x=pos.x, y=pos.y, z=pos.z}, axis)		-- this would rotate the node after it's been placed (just in case needed for old format)
			count = count + 1
		end
	elseif version == 4 then --current nested table format
		--wip: this is a filthy hack that works surprisingly well
		value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1)
		local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
		local startpos, startpos1, endpos = 1, 1
		local nodes = {}
		-- loop through the loaded file, and save each piece of node information to the node table
		while true do
			startpos, endpos = escaped:find("},%s*{", startpos)
			if not startpos then
				break
			end
			local current = value:sub(startpos1, startpos)
			table.insert(nodes, minetest.deserialize("return " .. current))
			startpos, startpos1 = endpos, endpos
		end
		table.insert(nodes, minetest.deserialize("return " .. value:sub(startpos1)))

		--local nodes = minetest.deserialize(value) --wip: this is broken for larger tables in the current version of LuaJIT

		--load the nodes
		count = #nodes
		for index = 1, count do
			local entry = nodes[index]
			print("Node: name: ".. entry.name)

			if axis == "x" then
				entry.x, entry.y, entry.z = originpos.x - entry.z, originpos.y + entry.y, originpos.z + entry.x
			elseif axis == "X" then
				entry.x, entry.y, entry.z = originpos.x + entry.z, originpos.y + entry.y, originpos.z - entry.x
			elseif axis == "z" then
				entry.x, entry.y, entry.z = originpos.x - entry.x, originpos.y + entry.y, originpos.z - entry.z
			elseif axis == "Z" then
				entry.x, entry.y, entry.z = originpos.x + entry.x, originpos.y + entry.y, originpos.z + entry.z
			end
--			entry.x, entry.y, entry.z = originpos.x + entry.x, originpos.y + entry.y, originpos.z + entry.z

			posMin,posMax = worldedit.minmax(entry,posMin,posMax)	-- update max and min positions

			entry.param2 = worldedit.getNewRotation(entry.param2,axis)	-- adjust param2 (rotation of the node) to match the overall rotation of the load
			knownMod, missingMods = worldedit.knownMod(entry.name, missingMods) 
			if knownMod then
				if not runTest then add_node(entry, entry) end		--entry acts both as position and as node
			else
				unknownModCnt = unknownModCnt +1
			end
		end

		--load the metadata
		for index = 1, count do
			local entry = nodes[index]
			get_meta(entry):from_table(entry.meta)
		end
	end

	-- Correct pos1 and pos2 location so markers appear as they would have without rotation (ie when saved with corrected origin)
	if axis == "x" then
		posMin.x, posMax.x = posMax.x, posMin.x
	elseif axis == "X" then
		posMin.z, posMax.z = posMax.z, posMin.z
	elseif axis == "z" then
		posMin.x, posMax.x = posMax.x, posMin.x
		posMin.z, posMax.z = posMax.z, posMin.z
	end
	return count, posMin, posMax, unknownModCnt, missingMods
end
