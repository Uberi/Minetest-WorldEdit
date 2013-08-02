WorldEdit v1.0 for MineTest 0.4.8+
==================================
The ultimate in-game world editing tool for [Minetest](http://minetest.net/)! Tons of functionality to help with building, fixing, and more.

For more information, see the [forum topic](https://forum.minetest.net/viewtopic.php?id=572) at the Minetest forums.

# New users should see the [tutorial](Tutorial.md).

Usage
-----
WorldEdit works primarily through chat commands. Depending on your key bindings, you can invoke chat entry with the "t" key, and open the chat console with the "F10" key.

WorldEdit has a huge potential for abuse by untrusted players. Therefore, users will not be able to use WorldEdit unless they have the "worldedit" privelege. This is available by default in single player, but in multiplayer the permission must be explicitly given by someone with the right credentials, using the follwoing chat command: `/grant <player name> worldedit`. This privelege can later be removed using the following chat command: `/revoke <player name> worldedit`.

For in-game information about these commands, type `/help <command name>` in the chat. For example, to learn more about the `//copy` command, simply type `/help /copy` to display information relevant to copying a region.

Chat Commands
-------------
WorldEdit is accessed in-game through an interface. By default, the mod distribution includes a chat interface for this purpose. It is documented in the [Chat Commands Reference](Chat Commands.md).

If visual manipulation of nodes is desired, the [WorldEdit GUI](https://forum.minetest.net/viewtopic.php?id=3112) mod provides a simple interface with buttons and text entry fields for this purpose.

Compatibility
-------------
This mod supports Minetest versions 0.4.8 and newer. Older versions of WorldEdit may work with older versions of Minetest, but are not recommended.

WorldEdit works quite well with other mods, and does not have any known mod conflicts.

WorldEdit API
-------------
WorldEdit exposes all significant functionality in a simple Lua interface. Adding WorldEdit to the file "depends.txt" in your mod gives you access to all of the `worldedit` functions. The API is useful for tasks such as high-performance node manipulation, alternative interfaces, and map creation.

If you don't add WorldEdit to your "depends.txt" file, each file in the WorldEdit mod is also independent. For example, one may import the WorldEdit primitives API using the following code:

    dofile(minetest.get_modpath("worldedit").."/primitives.lua")

AGPLv3 compatible mods may further include WorldEdit files in their own mods. This may be useful if a modder wishes to completely avoid any dependencies on WorldEdit. Note that it is required to give credit to the authors.

This API is documented in the [WorldEdit API Reference](WorldEdit API.md).

Axes
----
The coordinate system is the same as that used by MineTest; Y is upwards, X is perpendicular, and Z is parallel.

When an axis is specified in a WorldEdit command, it is specified as one of the following values: x, y, z, or ?.

The value ? represents the axis the player is currently facing. If the player is facing more than one axis, the axis the player face direction is closest to will be used.

Nodes
-----
Node names are required for many types of commands that identify or modify specific types of nodes. They can be specified in a number of ways.

First, by description - the tooltip that appears when hovering over the item in an inventory. This is case insensitive and includes values such as "Cobblestone" and "bronze block". Note that certain commands (namely, `//replace` and `//replaceinverse`) do not support descriptions that contain spaces in the `<searchnode>` field.

Second, by name - the node name that is defined by code, but without the mod name prefix. This is case sensitive and includes values such as "piston_normal_off" and "cactus". Nodes defined in the `default` mod always take precedence over other nodes when searching for the correct one, and if there are multiple possible nodes (such as "a:celery" and "b:celery"), one is chosen in no particular order.

Finally, by full name - the unambiguous identifier of the node, prefixes and all. This is case sensitive and includes values such as "default:stone" and "mesecons:wire_00000000_off".

The node name "air" can be used anywhere a normal node name can, and acts as a blank node. This is useful for clearing or removing nodes. For example, `//set air` would remove all the nodes in the current WorldEdit region. Similarly, `//sphere 10 air`, when WorldEdit position 1 underground, would dig a large sphere out of the ground.

Regions
-------
Most WorldEdit commands operate on regions. Regions are a set of two positions that define a 3D cuboid. They are local to each player and chat commands affect only the region for the player giving the commands.

Each positions together define two opposing corners of the cube. With two opposing corners it is possible to determine both the location and dimensions of the region.

Regions are not saved between server restarts. They start off as empty regions, and cannot be used with most WorldEdit commands until they are set to valid values.

Markers
-------
Entities are used to mark the location of the WorldEdit regions. They appear as boxes containing the number 1 or 2, and represent position 1 and 2 of the WorldEdit region, respectively.

To remove the entities, simply punch them. This does not reset the positions themselves.

Schematics
----------
WorldEdit supports two different types of schematics.

The first is the WorldEdit Schematic format, with the file extension ".we", and in some older versions, ".wem". There have been several previous versions of the WorldEdit Schematic format, but WorldEdit is capable of loading any past versions, and will always support them - there is no need to worry about schematics becoming obselete.

The current version of the WorldEdit Schematic format, internally known as version 4, is essentially an array of node data tables in Lua 5.2 table syntax. Specifically:

    return {
        {
            ["y"]      = <y-axis coordinate>,
            ["x"]      = <x-axis coordinate>,
            ["name"]   = <node name>,
            ["z"]      = <z-axis coordinate>,
            ["meta"]   = <metadata table>,
            ["param2"] = <param2 value>,
            ["param1"] = <y-axis coordinate>,
        },
        <...>
    }

Value ordering and minor aspects of the syntax, such as trailing commas or newlines, are not guaranteed.

The WorldEdit Schematic format is accessed via the WorldEdit API, or WorldEdit serialization chat commands such as `//serialize` and `//deserialize`.

The second is the Minetest Schematic format (MTS). The details of this format may be found in the Minetest documentation and are out of the scope of this document. Access to this format is done via specialized MTS commands such as `//mtschemcreate` and `//mtschemplace`.

License
-------
Copyright 2013 sfan5, Anthony Zhang (Uberi/Temperest), and Brett O'Donnell (cornernote).

This mod is licensed under the [GNU Affero General Public License](http://www.gnu.org/licenses/agpl-3.0.html).

Basically, this means everyone is free to use, modify, and distribute the files, as long as these modifications are also licensed the same way.

Most importantly, the Affero variant of the GPL requires you to publish your modifications in source form, even if the mod is run only on the server, and not distributed.
