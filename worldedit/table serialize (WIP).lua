serialize_meta = function(pos)
	local insert, format, concat = table.insert, string.format, table.concat
	--wip: do recursive serialize

	local meta = env:get_meta(pos):to_table()
	local fields = {}
	for key, value in pairs(meta.fields) do
		insert(fields, format("%q", key) .. format("%q", value))
	end
	return concat(meta.inventory, ",") .. concat(fields)
end

deserialize_meta = function(value)
	--wip
end