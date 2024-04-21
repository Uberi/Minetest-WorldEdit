---------------------
local vec = vector.new
local air = "air"
---------------------


local function output_weird(numbers, body)
	local s = {"return {"}
	for _, parts in ipairs(numbers) do
		s[#s+1] = "{"
		for _, n in ipairs(parts) do
			s[#s+1] = string.format("   {%d},", n)
		end
		s[#s+1] = "},"
	end
	return table.concat(s, "\n") .. table.concat(body, "\n") .. "}"
end

local fmt1p = '{\n   ["x"]=%d,\n   ["y"]=%d,\n   ["z"]=%d,\n},'
local fmt1n = '{\n   ["name"]="%s",\n},'
local fmt4 = '{ ["x"] = %d, ["y"] = %d, ["z"] = %d, ["meta"] = { ["fields"] = {  }, ["inventory"] = {  } }, ["param2"] = 0, ["param1"] = 0, ["name"] = "%s" }'
local fmt5 = '{ ["x"] = %d, ["y"] = %d, ["z"] = %d, ["name"] = "%s" }'
local fmt51 = '{[r2]=0,x=%d,y=%d,z=%d,name=r%d}'
local fmt52 = '{x=%d,y=%d,z=%d,name=_[%d]}'

local test_data = {
	-- used by WorldEdit 0.2 (first public release)
	{
		name = "v1", ver = 1,
		gen = function(pat)
			local numbers = {
				{2, 3, 4, 5, 6},
				{7, 8}, {9, 10}, {11, 12},
				{13, 14}, {15, 16}
			}
			return output_weird(numbers, {
				fmt1p:format(0, 0, 0),
				fmt1n:format(pat[1]),
				fmt1p:format(0, 1, 0),
				fmt1n:format(pat[3]),
				fmt1p:format(1, 1, 0),
				fmt1n:format(pat[1]),
				fmt1p:format(1, 0, 1),
				fmt1n:format(pat[3]),
				fmt1p:format(0, 1, 1),
				fmt1n:format(pat[1]),
			})
		end
	},

	-- v2: missing because I couldn't find any code in my archives that actually wrote this format

	{
		name = "v3", ver = 3,
		gen = function(pat)
			assert(pat[2] == air)
			return table.concat({
			"0 0 0 " .. pat[1] .. " 0 0",
			"0 1 0 " .. pat[3] .. " 0 0",
			"1 1 0 " .. pat[1] .. " 0 0",
			"1 0 1 " .. pat[3] .. " 0 0",
			"0 1 1 " .. pat[1] .. " 0 0",
			}, "\n")
		end
	},

	{
		name = "v4", ver = 4,
		gen = function(pat)
			return table.concat({
			"return { " .. fmt4:format(0, 0, 0, pat[1]),
			fmt4:format(0, 1, 0, pat[3]),
			fmt4:format(1, 1, 0, pat[1]),
			fmt4:format(1, 0, 1, pat[3]),
			fmt4:format(0, 1, 1, pat[1]) .. " }",
			}, ", ")
		end
	},

	-- like v4 but no meta and param (if empty)
	{
		name = "v5 (pre-5.6)", ver = 5,
		gen = function(pat)
			return table.concat({
			"5:return { " .. fmt5:format(0, 0, 0, pat[1]),
			fmt5:format(0, 1, 0, pat[3]),
			fmt5:format(1, 1, 0, pat[1]),
			fmt5:format(1, 0, 1, pat[3]),
			fmt5:format(0, 1, 1, pat[1]) .. " }",
			}, ", ")
		end
	},

	-- reworked engine serialization in 5.6
	{
		name = "v5 (5.6)", ver = 5,
		gen = function(pat)
			return table.concat({
			'5:r1="' .. pat[1] .. '";r2="param1";r3="' .. pat[3] .. '";return {'
			.. fmt51:format(0, 0, 0, 1),
			fmt51:format(0, 1, 0, 3),
			fmt51:format(1, 1, 0, 1),
			fmt51:format(1, 0, 1, 3),
			fmt51:format(0, 1, 1, 1) .. "}",
			}, ",")
		end
	},

	-- small changes on engine side again
	{
		name = "v5 (post-5.7)", ver = 5,
		gen = function(pat)
			return table.concat({
			'5:local _={};_[1]="' .. pat[1] .. '";_[3]="' .. pat[3] .. '";return {'
			.. fmt52:format(0, 0, 0, 1),
			fmt52:format(0, 1, 0, 3),
			fmt52:format(1, 1, 0, 1),
			fmt52:format(1, 0, 1, 3),
			fmt52:format(0, 1, 1, 1) .. "}",
			}, ",")
		end
	},
}


worldedit.register_test("Schematics")
worldedit.register_test("worldedit.read_header", function()
	local value = '5,foo,BAR,-1,234:the content'
	local version, header, content = worldedit.read_header(value)
	assert(version == 5)
	assert(#header == 4)
	assert(header[1] == "foo" and header[2] == "BAR")
	assert(header[3] == "-1" and header[4] == "234")
	assert(content == "the content")
end)

worldedit.register_test("worldedit.allocate", function()
	local value = '3:-1 0 0 dummy 0 0\n0 0 4 dummy 0 0\n0 1 0 dummy 0 0'
	local pos1, pos2, count = worldedit.allocate(vec(1, 1, 1), value)
	assert(vector.equals(pos1, vec(0, 1, 1)))
	assert(vector.equals(pos2, vec(1, 2, 5)))
	assert(count == 3)
end)

for _, e in ipairs(test_data) do
	worldedit.register_test("worldedit.deserialize " .. e.name, function()
		local pos1, pos2 = area.get(2)
		local m = area.margin(1)

		local pat = {testnode3, air, testnode2}
		local value = e.gen(pat)
		assert(type(value) == "string")

		local version = worldedit.read_header(value)
		assert(version == e.ver, "version: got " .. tostring(version) .. " expected " .. e.ver)
		local count = worldedit.deserialize(pos1, value)
		assert(count ~= nil and count > 0)

		check.pattern(pos1, pos2, pat)
		check.filled2(m, air)
	end)
end
