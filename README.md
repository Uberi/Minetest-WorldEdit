WorldEdit v0.6 for MineTest 0.4
===============================
In-game world editing for [MineTest](http://minetest.net/)! Tons of functionality to help with building, fixing, and more.

For more information, see the [forum topic](http://minetest.net/forum/viewtopic.php?id=572) at the Minetest forums.

Usage
-----
WorldEdit works primarily through chat commands. Depending on your key bindings, you can invoke chat entry with the "t" key, and open the chat console with the "F10" key.

WorldEdit has a huge potential for abuse by untrusted players. Therefore, users will not be able to use WorldEdit unless they have the "worldedit" privelege. This is available by default in single player, but in multiplayer the permission must be explicitly given by someone with the right credentials, using the follwoing chat command: `/grant <player name> worldedit`. This privelege can later be removed using the following chat command: `/revoke <player name> worldedit`.

For in-game information about these commands, type `/help <command name>` in the chat. For example, to learn more about the `//copy` command, simply type `/help /copy` to display information relevant to copying a region.

Axes
----
The coordinate system is the same as that used by MineTest; Y is upwards, X is perpendicular, and Z is parallel.

When an axis is specified in a WorldEdit command, it is specified as one of the following values: x, y, z, or ?.

The value ? represents the axis the player is currently facing. If the player is facing more than one axis, the axis the player face direction is closest to will be used.

Regions
-------
Most WorldEdit commands operate on regions. Regions are a set of two positions that define a 3D cube. They are local to each player and chat commands affect only the region for the player giving the commands.

Each positions together define two opposing corners of the cube. With two opposing corners it is possible to determine both the location and dimensions of the region.

Regions are not saved between server restarts. They start off as empty regions, and cannot be used with most WorldEdit commands until they are set to valid values.

Markers
-------
Entities are used to mark the location of the WorldEdit regions. They appear as boxes containing the number 1 or 2, and represent position 1 and 2 of the WorldEdit region, respectively.

To remove the entities, simply punch them. This does not reset the positions themselves.

Chat Commands
-------------
WorldEdit is accessed in-game through an interface. By default, the mod distribution includes a chat interface for this purpose. It is documented in the [Chat Commands Reference](Chat Commands.md).

If visual manipulation of nodes is desired, the [WorldEdit GUI](http://minetest.net/forum/viewtopic.php?id=3112) mod provides a simple interface with buttons and text entry fields for this purpose.

WorldEdit API
-------------
WorldEdit exposes all significant functionality in a simple interface. Adding WorldEdit to the file "depends.txt" in your mod gives you access to all of the `worldedit` functions. The API is useful for tasks such as high-performance node manipulation, alternative interfaces, and map creation.

This API is documented in the [WorldEdit API Reference](WorldEdit API.md).

License
-------
Copyright 2013 sfan5, Anthony Zhang (Temperest), and Brett O'Donnell (cornernote).

This mod is licensed under the [GNU Affero General Public License](http://www.gnu.org/licenses/agpl-3.0.html).

Basically, this means everyone is free to use, modify, and distribute the files, as long as these modifications are also licensed the same way.

Most importantly, the Affero variant of the GPL requires you to publish your modifications in source form, even if the mod is run only on the server, and not distributed.
