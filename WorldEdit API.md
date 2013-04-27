WorldEdit API
=============
The WorldEdit API is composed of multiple modules, each of which is independent and can be used without the other. Each module is contained within a single file.

If needed, individual modules such as visualization.lua can be removed without affecting the rest of the program. The only file that cannot be removed is init.lua, which is necessary for the mod to run.

For more information, see the [README](README.md).

Manipulations
-------------
Contained in manipulations.lua, this module allows several node operations to be applied over a region.

### count = worldedit.set(pos1, pos2, nodename)

Sets a region defined by positions `pos1` and `pos2` to `nodename`. To clear to region, use "air" as the value of `nodename`.

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

### count = worldedit.move(pos1, pos2, axis, amount)

Moves the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") by `amount` nodes.

Returns the number of nodes moved.

### count = worldedit.stack(pos1, pos2, axis, count)

Duplicates the region defined by positions `pos1` and `pos2` along the `axis` axis ("x" or "y" or "z") `count` times.

Returns the number of nodes stacked.

### count, newpos1, newpos2 = worldedit.transpose(pos1, pos2, axis1, axis2)

Transposes a region defined by the positions `pos1` and `pos2` between the `axis1` and `axis2` axes ("x" or "y" or "z").

Returns the number of nodes transposed, the new position 1, and the new position 2.

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

Primitives
----------
Contained in primitives.lua, this module allows the creation of several geometric primitives.

### count = worldedit.hollow_sphere(pos, radius, nodename)

Adds a hollow sphere at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.sphere(pos, radius, nodename)

Adds a sphere at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.hollow_dome(pos, radius, nodename)

Adds a hollow dome at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.dome(pos, radius, nodename)

Adds a dome at `pos` with radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.hollow_cylinder(pos, axis, length, radius, nodename)

Adds a hollow cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.cylinder(pos, axis, length, radius, nodename)

Adds a cylinder at `pos` along the `axis` axis ("x" or "y" or "z") with length `length` and radius `radius`, composed of `nodename`.

Returns the number of nodes added.

### count = worldedit.pyramid(pos, height, nodename)

Adds a pyramid at `pos` with height `height`.

Returns the number of nodes added.

### count = worldedit.spiral(pos, width, height, spacer, nodename)

Adds a spiral at `pos` with width `width`, height `height`, space between walls `spacer`, composed of `nodename`.

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

### count = worldedit.suppress(pos1, pos2, nodename)

Suppresses all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively replacing them with invisible nodes.

Returns the number of nodes suppressed.

### count = worldedit.highlight(pos1, pos2, nodename)

Highlights all instances of `nodename` in a region defined by positions `pos1` and `pos2` by non-destructively hiding all other nodes.

Returns the number of nodes found.

### count = worldedit.restore(pos1, pos2)

Restores all nodes hidden with WorldEdit functions in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes restored.

Serialization
-------------
Contained in serialization.lua, this module allows regions of nodes to be serialized and deserialized to formats suitable for use outside MineTest.

### version = worldedit.valueversion(value)

Determines the version of serialized data `value`.

Returns the version as a positive integer or 0 for unknown versions.

### data, count = worldedit.serialize(pos1, pos2)

Converts the region defined by positions `pos1` and `pos2` into a single string.

Returns the serialized data and the number of nodes serialized.

### pos1, pos2, count = worldedit.allocate(originpos, value)

Determines the volume the nodes represented by string `value` would occupy if deserialized at `originpos`.

Returns the two corner positions and the number of nodes.

### count = worldedit.deserialize(originpos, value)

Loads the nodes represented by string `value` at position `originpos`.

Returns the number of nodes deserialized.

Code
----
Contained in code.lua, this module allows arbitrary Lua code to be used with WorldEdit.

### error = worldedit.lua(code)

Executes `code` as a Lua chunk in the global namespace.

Returns an error if the code fails or nil otherwise.

### error = worldedit.luatransform(pos1, pos2, code)

Executes `code` as a Lua chunk in the global namespace with the variable pos available, for each node in a region defined by positions `pos1` and `pos2`.

Returns an error if the code fails or nil otherwise.