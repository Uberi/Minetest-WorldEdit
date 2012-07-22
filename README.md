WorldEdit v0.5 for MineTest 0.4
===============================
In-game world editing for [MineTest](http://minetest.net/)! Tons of chat commands to help with building, fixing, and more.

For more information, see the [forum topic](http://minetest.net/forum/viewtopic.php?id=572) at the MineTest forums.

Usage
-----
WorldEdit works primarily through chat commands. Depending on your key bindings, you can invoke chat entry with the "t" key, and open the chat console with the "F10" key.

WorldEdit has a huge potential for abuse by untrusted players. Therefore, users will not be able to use WorldEdit unless they have the "worldedit" privelege. This is available by default in single player, but in multiplayer the permission must be explicitly given by someone with the right credentials, using the follwoing chat command: `/grant <player name> worldedit`. This privelege can later be removed using the following chat command: `/revoke <player name> worldedit`.

For in-game information about these commands, type `/help <command name>` in the chat. For example, to learn more about the `//copy` command, simply type `/help /copy` to display information relevant to copying a region.

Regions
-------
Most WorldEdit commands operate on regions. Regions are a set of two positions that define a 3D cube. They are local to each player and chat commands affect only the region for the player giving the commands.

Each positions together define two opposing corners of the cube. With two opposing corners it is possible to determine both the location and dimensions of the region.

Regions are not saved between server restarts. They start off as empty regions, and cannot be used with most WorldEdit commands until they are set to valid values.

Markers
-------
Entities are used to mark the location of the WorldEdit regions. They appear as boxes containing the number 1 or 2, and represent position 1 and 2 of the WorldEdit region, respectively.

To remove the entities, simply punch them. This does not reset the positions themselves.

Commands
--------

### //reset

Reset the region so that it is empty.

    //reset

### //mark

Show markers at the region positions.

    //mark

### //pos1

Set WorldEdit region position 1 to the player's location.

    //pos1

### //pos2

Set WorldEdit region position 2 to the player's location.

    //pos2

### //p set/get

Set WorldEdit region by punching two nodes, or display the current WorldEdit region.

    //p set
    //p get

### //volume

Display the volume of the current WorldEdit region.

    //volume

### //set <node>

Set the current WorldEdit region to <node>.

    //set dirt
    //set default:glass
    //set mesecons:mesecon

### //replace <search node> <replace node>

Replace all instances of <search node> with <place node> in the current WorldEdit region.

    //replace cobble stone
    //replace default:steelblock glass
    //replace dirt flowers:flower_waterlily
    //replace flowers:flower_rose flowers:flower_tulip

### //copy x/y/z <amount>

Copy the current WorldEdit region along the x/y/z axis by <amount> nodes.

    //copy x 15
    //copy y -7
    //copy z +4

### //move x/y/z <amount>

Move the current WorldEdit region along the x/y/z axis by <amount> nodes.

    //move x 15
    //move y -7
    //move z +4

### //stack x/y/z <count>

Stack the current WorldEdit region along the x/y/z axis <count> times.

    //stack x 3
    //stack y -1
    //stack z +5

### //transpose x/y/z x/y/z

Transpose the current WorldEdit region along the x/y/z and x/y/z axes.

    //transpose x y
    //transpose x z
    //transpose y z

### //flip x/y/z

Flip the current WorldEdit region along the x/y/z axis.

   //flip x
   //flip y
   //flip z

### //rotate

Rotate the current WorldEdit region around the y axis by angle <angle> (90 degree increment).

    //rotate 90
    //rotate 180
    //rotate 270

### //dig

Dig the current WorldEdit region.

    //dig

### //save <file>

Save the current WorldEdit region to "(world folder)/schems/<file>.we".

    //save some random filename
    //save huge_base

### //load <file>

Load nodes from "(world folder)/schems/<file>.we" with position 1 of the current WorldEdit region as the origin.

    //load some random filename
    //load huge_base

WorldEdit API
-------------
WorldEdit exposes all significant functionality in a simple interface. Adding WorldEdit to the file "depends.txt" in your mod gives you access to all of the `worldedit` functions. These are useful if you're looking for high-performance node manipulation without all the hassle of writing tons of code.

### worldedit.volume(pos1, pos2)

Determines the volume of the region defined by positions `pos1` and `pos2`.

Returns the volume.

### worldedit.set(pos1, pos2, nodename)

Sets a region defined by positions `pos1` and `pos2` to `nodename`. To clear to region, use "air" as the value of `nodename`.

Returns the number of nodes set.

### worldedit.replace(pos1, pos2, searchnode, replacenode)

Replaces all instances of `searchnode` with `replacenode` in a region defined by positions `pos1` and `pos2`.

Returns the number of nodes replaced.

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

License
-------
Copyright 2012 sfan5 and Anthony Zhang (Temperest)

This mod is licensed under the [GNU Affero General Public License](http://www.gnu.org/licenses/agpl-3.0.html).

Basically, this means everyone is free to use, modify, and distribute the files, as long as these modifications are also licensed the same way.

Most importantly, the Affero variant of the GPL requires you to publish your modifications in source form, even if the mod is run only on the server, and not distributed.