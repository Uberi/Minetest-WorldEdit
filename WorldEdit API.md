WorldEdit API
=============
The WorldEdit API is composed of multiple modules, each of which is independent and can be used without the other. Each module is contained within a single file.

If needed, individual modules such as visualization.lua can be removed without affecting the rest of the program. The only file that cannot be removed is init.lua, which is necessary for the mod to run.

For more information, see the [README](README.md).

General
-------

### value = worldedit.version

Contains the current version of WorldEdit in a table of the form `{major=MAJOR_INTEGER, minor=MINOR_INTEGER}`, where `MAJOR_INTEGER` is the major version (the number before the period) as an integer, and `MINOR_INTEGER` is the minor version (the number after the period) as an integer. This is intended for version checking purposes.

### value = worldedit.version_string

Contains the current version of WorldEdit in the form of a string `"MAJOR_INTEGER.MINOR_INTEGER"`, where `MAJOR_INTEGER` is the major version (the number before the period) as an integer, and `MINOR_INTEGER` is the minor version (the number after the period) as an integer. This is intended for display purposes.

Manipulations
-------------
Contained in manipulations.lua, this module allows several node operations to be applied over a region.

### count = worldedit.set(pos1, pos2, node_name)

Sets a region defined by positions `pos1` and `pos2` to `node_name`. To clear a region, use "air" as the value of `node_name`.
If `node_name` is a list of nodes, each set node is randomly picked from it.

Returns the number of nodes set.

### `count = worldedit.set_param2(pos1, pos2, param2)`

Sets the param2 values of all nodes in a region defined by positions `pos1` and `pos2` to `param2`.

Returns the number of nodes set.

### count = worldedit.replace(pos1, pos2, searchnode, replacenode)

Replaces all instances of `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes replaced.

### count = worldedit.replaceinverse(pos1, pos2, searchnode, replacenode)

Replaces all nodes other than `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes replaced.

### count = worldedit.copy(pos1, pos2, axis, amount)

Copies the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes.

Returns the number of nodes copied.

### count = worldedit.copy2(pos1, pos2, off)

Copies the region defined by positions `pos1` and `pos2` by the offset vector `off`.
Note that the offset needs to be big enough that there is no overlap.

Returns the number of nodes copied.

### count = worldedit.move(pos1, pos2, axis, amount)

Moves the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes.

Returns the number of nodes moved.

### count = worldedit.stack(pos1, pos2, axis, count)

Duplicates the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") `count` times.

Returns the number of nodes stacked.

### count = worldedit.stack2(pos1, pos2, direction, amount)

Duplicates the region defined by positions `pos1` and `pos2` `amount` times with offset vector `direction`.
Note that the offset vector needs to be big enough that there is no overlap.

Returns the number of nodes stacked.

### count, newpos1, newpos2 = worldedit.stretch(pos1, pos2, stretchx, stretchy, stretchz)

Stretches the region defined by positions `pos1` and `pos2` by an factor of positive integers `stretchx`, `stretchy`. and `stretchz` along the X, Y, and Z axes, respectively, with `pos1` as the origin.

Returns the number of nodes stretched, the new scaled position 1, and the new scaled position 2.

### count, newpos1, newpos2 = worldedit.transpose(pos1, pos2, axis1, axis2)

Transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes ("x" or "y" or "z").

Returns the number of nodes transposed, the new transposed position 1, and the new transposed position 2.

### count = worldedit.flip(pos1, pos2, axis)

Flips a region defined by the positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z").

Returns the number of nodes flipped.

### count, newpos2, newpos2 = worldedit.rotate(pos1, pos2, angle)

Rotates a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise around the y axis (supporting 90 degree increments only).

Returns the number of nodes rotated, the new position 1, and the new position 2.

### count = worldedit.orient(pos1, pos2, angle)

Rotates all oriented nodes in a region defined by the positions `pos1` and `pos2` by `angle` degrees clockwise (90 degree increment) around the Y axis.

Returns the number of nodes oriented.

### count = worldedit.fixlight(pos1, pos2)

Fixes the lighting in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes updated.

### count = worldedit.clearobjects(pos1, pos2)

Clears all objects in a region defined by the positions `pos1` and `pos2`.

Returns the number of objects cleared.

Primitives
----------
Contained in primitives.lua, this module allows the creation of several geometric primitives.

### count = worldedit.cube(pos, width, height, length, node_name, hollow)

Adds a cube with its ground level centered at `pos`, the dimensions `width` x `height` x `length`, composed of `node_name`.

Returns the number of nodes added.

### count = worldedit.sphere(pos, radius, node_name, hollow)

Adds a sphere centered at `pos` with radius `radius`, composed of `node_name`.

Returns the number of nodes added.

### count = worldedit.dome(pos, radius, node_name, hollow)

Adds a dome centered at `pos` with radius `radius`, composed of `node_name`.

Returns the number of nodes added.

### count = worldedit.cylinder(pos, axis, length, radius1, radius2, node_name, hollow)

Adds a cylinder-like at `pos` along the `axis` axis ("x" or "y" or "z") with length `length`, base radius `radius1` and top radius `radius2`, composed of `node_name`.

Returns the number of nodes added.

### count = worldedit.pyramid(pos, axis, height, node_name, hollow)

Adds a pyramid centered at `pos` along the `axis` axis ("x" or "y" or "z") with height `height`, composed of `node_name`.

Returns the number of nodes added.

### count = worldedit.spiral(pos, length, height, spacer, node_name)

Adds a spiral centered at `pos` with side length `length`, height `height`, space between walls `spacer`, composed of `node_name`.

Returns the number of nodes added.

Visualization
-------------
Contained in visualization.lua, this module allows nodes to be visualized in different ways.

### volume = worldedit.volume(pos1, pos2)

Determines the volume of the region defined by positions `pos1` and `pos2`.

Returns the volume.

### count = worldedit.hide(pos1, pos2)

Hides all nodes in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes.

Returns the number of nodes hidden.

### count = worldedit.suppress(pos1, pos2, node_name)

Suppresses all instances of `node_name` in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes.

Returns the number of nodes suppressed.

### count = worldedit.highlight(pos1, pos2, node_name)

Highlights all instances of `node_name` in a region defined by positions `pos1` and `pos2` by non-destructively hiding all other nodes.

Returns the number of nodes found.

### count = worldedit.restore(pos1, pos2)

Restores all nodes hidden with WorldEdit functions in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes restored.

Serialization
-------------
Contained in serialization.lua, this module allows regions of nodes to be serialized and deserialized to formats suitable for use outside Minetest.

### version, extra_fields, content = worldedit.read_header(value)

Reads the header from serialized data `value`.

Returns the version as a positive integer (nil for unknown versions),
extra header fields (nil if not supported), and the content after the header.

### data, count = worldedit.serialize(pos1, pos2)

Converts the region defined by positions `pos1` and `pos2` into a single string.

Returns the serialized data and the number of nodes serialized, or nil.

### pos1, pos2, count = worldedit.allocate(origin_pos, value)

Determines the volume the nodes represented by string `value` would occupy if deserialized at `origin_pos`.

Returns the two corner positions and the number of nodes, or nil.

### count = worldedit.deserialize(origin_pos, value)

Loads the nodes represented by string `value` at position `origin_pos`.

Returns the number of nodes deserialized or nil.

Code
----
Contained in code.lua, this module allows arbitrary Lua code to be used with WorldEdit.

### error = worldedit.lua(code)

Executes `code` as a Lua chunk in the global namespace.

Returns an error if the code fails or nil otherwise.

### error = worldedit.luatransform(pos1, pos2, code)

Executes `code` as a Lua chunk in the global namespace with the variable `pos` available, for each node in a region defined by positions `pos1` and `pos2`.

Returns an error if the code fails or nil otherwise.
