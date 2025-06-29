local S = minetest.get_translator("worldedit_commands")

-- Strips any kind of escape codes (translation, colors) from a string
-- https://github.com/minetest/minetest/blob/53dd7819277c53954d1298dfffa5287c306db8d0/src/util/string.cpp#L777
local function strip_escapes(input)
	local s = function(idx) return input:sub(idx, idx) end
	local out = ""
	local i = 1
	while i <= #input do
		if s(i) == "\027" then -- escape sequence
			i = i + 1
			if s(i) == "(" then -- enclosed
				i = i + 1
				while i <= #input and s(i) ~= ")" do
					if s(i) == "\\" then
						i = i + 2
					else
						i = i + 1
					end
				end
			end
		else
			out = out .. s(i)
		end
		i = i + 1
	end
	--print(("%q -> %q"):format(input, out))
	return out
end

local function string_endswith(full, part)
	return full:find(part, 1, true) == #full - #part + 1
end

local description_cache = nil

-- normalizes node "description" `nodename`. Return a string (or nil), with the second return value being the error message if the first value is nil.
-- playername contain the name of the player. It may be nil, in which case it won’t detect the wielded item when appropriate
worldedit.normalize_nodename = function(nodename, playername)
	nodename = nodename:gsub("^%s*(.-)%s*$", "%1") -- strip spaces
	if nodename == "" then return nil end

	if nodename == "wielded" or nodename == "w" then
		if not playername then
			return nil, S("no player executing command")
		end

		local player = minetest.get_player_by_name(playername)
		if not player then
			return nil, S("no player found: @1", playername)
		end

		local wielded = player:get_wielded_item()
		if not wielded then
			return nil, S("no wielded item: @1", playername)
		end
		
		if minetest.registered_nodes[wielded:get_name()] then
			return wielded:get_name()
		else
			return nil, S("not a node: @1", wielded:get_name())
		end
	end

	local fullname = ItemStack({name=nodename}):get_name() -- resolve aliases
	if minetest.registered_nodes[fullname] or fullname == "air" then -- full name
		return fullname
	end
	nodename = nodename:lower()

	for key, _ in pairs(minetest.registered_nodes) do
		if string_endswith(key:lower(), ":" .. nodename) then -- matches name (w/o mod part)
			return key
		end
	end

	if description_cache == nil then
		-- cache stripped descriptions
		description_cache = {}
		for key, value in pairs(minetest.registered_nodes) do
			local desc = strip_escapes(value.description):gsub("\n.*", "", 1):lower()
			if desc ~= "" then
				description_cache[key] = desc
			end
		end
	end

	for key, desc in pairs(description_cache) do
		if desc == nodename then -- matches description
			return key
		end
	end
	for key, desc in pairs(description_cache) do
		if desc == nodename .. " block" then
			-- fuzzy description match (e.g. "Steel" == "Steel Block")
			return key
		end
	end

	local match = nil
	for key, value in pairs(description_cache) do
		if value:find(nodename, 1, true) ~= nil then
			if match ~= nil then
				return nil, S("invalid node name: @1", nodename)
			end
			match = key -- substring description match (only if no ambiguities)
		end
	end

	if match then
		return match
	end

	return nil, S("invalid node name: @1", nodename)
end