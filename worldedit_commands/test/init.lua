local register_test = worldedit.register_test

-- Basic test that just checks if certain parameter combinations
-- parse correctly (valid or invalid)
local make_parsing_test = function(cmd, valid, invalid)
	return function()
		local def = worldedit.registered_commands[cmd]
		assert(def, "Command not defined")
		for _, param in ipairs(valid or {}) do
			local parsed = {def.parse(param)}
			assert(parsed[1], string.format("Did not parse: %q", param))
		end
		for _, param in ipairs(invalid or {}) do
			local parsed = {def.parse(param)}
			assert(not parsed[1], string.format("Did parse: %q", param))
		end
	end
end

register_test("Command parsing")
register_test("//set", make_parsing_test("set", {
	"air",
	"mapgen_stone",
	minetest.registered_aliases["mapgen_dirt"],
}, {
	"this long text could not possibly ever match a node",
	"",
}))

register_test("//mix", make_parsing_test("mix", {
	"air",
	"air 2",
	"air mapgen_stone",
	"air 2 air 1 mapgen_stone 1",
}, {
	"this_will_never_match_any_node",
	"air 1 this_will_never_match_any_node",
	"air this_will_never_match_any_node",
	"",
}))

register_test("//fixedpos", make_parsing_test("fixedpos", {
	"set1 0 0 0",
	"set2 -10 20 31000",
	"set1 ~0 ~0 ~0",
	"set2 ~-5 2 ~+2",
}, {
	"set1 0 0",
	"set 1 2 3",
	"set2 ~ ~ ~",
	"set2 + 0 0",
	"",
}))

register_test("//copy", make_parsing_test("copy", {
	"x 10",
	"right +1",
	"? -4",
}, {
	"eee 1",
	"up 0",
	"",
}))

register_test("//rotate", make_parsing_test("rotate", {
	"z 90",
	"left -180",
}, {
	"x 0",
	"back 77",
	"",
}))

register_test("//flip", make_parsing_test("flip", {
	"y",
	"down",
	"?",
}, {
	"1",
	"",
}))


register_test("//inset", make_parsing_test("inset", {
	"h 1",
	"v 0",
	"hv 2",
	"vh 3",
}, {
	"x 4",
	"xyz 5",
	"v foo",
	"",
}))

register_test("//shift", make_parsing_test("shift", {
	"x 1",
	"x -4",
	"back 1",
	"? 1",
}, {
	"+z 1212",
	"-z 9",
	"xx -5",
	"?? 123",
	"",
}))

register_test("//expand", make_parsing_test("expand", {
	"x 1",
	"z 1 2",
	"? 1",
	"+? 1",
	"+left 1",
	"-right 1",
}, {
	"x -4",
	"? 4 -333",
	"stupid 5 5",
	"",
}))

register_test("//cubeapply", make_parsing_test("cubeapply", {
	"2 orient 90",
	"2 3 4 orient 90",
	"1 1 1 drain",
	"4 stack z 1",
}, {
	"1 1 1 orient",
	"0 drain",
	"4 stack z",
	"2 2 2 asasasasasas",
	"",
}))

register_test("//save", make_parsing_test("save", {
	"filename",
	"filename.abc",
}, {
	"\"hmm",
	"../../oops",
	"",
}))
