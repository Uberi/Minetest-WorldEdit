local strip_escapes = minetest.strip_escapes or function(input)
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
	return out
end

local function string_endswith(full, part)
	if #full < #part then
		return false
	end
	return full:sub(-#part) == part
end

local function make_description_cache()
	local t = {}
	for key, def in pairs(minetest.registered_nodes) do
		local desc = def.short_description or (def.description or ""):gsub("\n.*", "", 1)
		desc = strip_escapes(desc):lower()
		if def.groups.not_in_creative_inventory ~= 1 and desc ~= "" then
			t[key] = desc
		end
	end
	return t
end

local description_cache = nil

-- normalizes node "description" `nodename`, returning a string (or nil)
worldedit.normalize_nodename = function(nodename)
	nodename = nodename:trim()
	if nodename == "" then
		return nil
	end

	if nodename:find(" ", 1, true) == nil then
		local fullname = ItemStack({name=nodename}):get_name() -- resolve aliases
		if minetest.registered_nodes[fullname] then -- full name
			return fullname
		end
	end

	local match
	for key, _ in pairs(minetest.registered_nodes) do
		if string_endswith(key, ":" .. nodename) then
			if match then
				match = nil
				break
			end
			match = key -- matches name w/o mod part (only if unique)
		end
	end
	if match then
		return match
	end

	nodename = nodename:lower()
	if description_cache == nil then
		-- Note: since we don't handle translations this will work only in the original
		-- language of the description (English)
		description_cache = make_description_cache()
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

	match = nil
	for key, value in pairs(description_cache) do
		if value:find(nodename, 1, true) ~= nil then
			if match then
				match = nil
				break
			end
			match = key -- substring description match (only if unique)
		end
	end

	return match
end
