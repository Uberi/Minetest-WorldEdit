WorldEdit API
-------------
For more information, see the [README](README.md).

### worldedit.volume(pos1, pos2)

Determines the volume of the region defined by positions `pos1` and `pos2`.

Returns the volume.

### worldedit.set(pos1, pos2, nodename)

Sets a region defined by positions `pos1` and `pos2` to `nodename`. To clear to region, use "air" as the value of `nodename`.

Returns the number of nodes set.

### worldedit.replace(pos1, pos2, searchnode, replacenode)

Replaces all instances of `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes replaced.

### worldedit.hollow_sphere = function(pos, radius, nodename)

Adds a hollow sphere at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### worldedit.sphere = function(pos, radius, nodename)

Adds a sphere at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### worldedit.hollow_cylinder(pos, axis, length, radius, nodename)

Adds a hollow cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### worldedit.cylinder(pos, axis, length, radius, nodename)

Adds a cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### worldedit.pyramid(pos, height, nodename)

Adds a pyramid at `pos` with height `height`.

Returns the number of nodes added.

### worldedit.spiral(pos, width, height, spacer, nodename)

Adds a spiral at `pos` with width `width`, height `height`, space between walls `spacer`, composed of `nodename`.

Returns the number of nodes added.

### worldedit.copy(pos1, pos2, axis, amount)

Copies the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes.

Returns the number of nodes copied.

### worldedit.move(pos1, pos2, axis, amount)

Moves the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes.

Returns the number of nodes moved.

### worldedit.stack(pos1, pos2, axis, count)

Duplicates the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") `count` times.

Returns the number of nodes stacked.

### worldedit.transpose(pos1, pos2, axis1, axis2)

Transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes ("x" or "y" or "z").

Returns the number of nodes transposed.

### worldedit.flip(pos1, pos2, axis)

Flips a region defined by the positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z").

Returns the number of nodes flipped.

### worldedit.rotate(pos1, pos2, angle)

Rotates a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise around the y axis (supporting 90 degree increments only).

Returns the number of nodes rotated.

### worldedit.dig(pos1, pos2)

Digs a region defined by positions `pos1` and `pos2`.

Returns the number of nodes dug.

### worldedit.serialize(pos1, pos2)

Converts the region defined by positions `pos1` and `pos2` into a single string.

Returns the serialized data and the number of nodes serialized.

### worldedit.deserialize(originpos, value)

Loads the nodes represented by string `value` at position `originpos`.

Returns the number of nodes deserialized.

### worldedit.deserialize_old(originpos, value)

Loads the nodes represented by string `value` at position `originpos`, using the older table-based WorldEdit format.

This function is deprecated, and should not be used unless there is a need to support legacy WorldEdit save files.

Returns the number of nodes deserialized.

### worldedit.metasave(pos1, pos2, file)

Saves the nodes and meta defined by positions `pos1` and `pos2` into a file.

Returns the number of nodes saved.

### worldedit.metaload(pos1, file)

Loads the nodes and meta from `file` to position `pos1`.

Returns the number of nodes loaded.