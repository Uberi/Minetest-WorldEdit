WorldEdit v1.3
==============
The ultimate in-game world editing tool for [Minetest](http://minetest.net/)! Tons of functionality to help with building, fixing, and more.

For more information, see the [forum topic](https://forum.minetest.net/viewtopic.php?id=572) at the Minetest forums.

# New users should see the [tutorial](Tutorial.md).

![Screenshot](http://i.imgur.com/lwhodrv.png)

Installing
----------

There is a nice installation guide over at the [Minetest Wiki](http://wiki.minetest.com/wiki/Installing_mods). Here is a short summary:

1. Download the mod from the [official releases page](https://github.com/Uberi/Minetest-WorldEdit/releases). The download links are labelled "Source Code". If you are using Windows, you'll want to download the ZIP version.
2. You should have a file named `Minetest-WorldEdit-x.x.zip`.
3. Extract this file using your archiver of choice. If you are using Windows, open the ZIP file and move the folder inside to a safe place outside of the ZIP file.
4. Make sure that you now have a folder with a file named README.md inside it. If you just have another folder inside this folder, use the nested folder instead.
5. Move this folder into the `MINETEST_FOLDER/mods` folder, where `MINETEST_FOLDER` is the folder Minetest is located in.
6. Open Minetest to a world selection screen.
7. Select a world you want to use WorldEdit in by left clicking on it once and press the **Configure** button.
8. You should have a mod selection screen. Select the one named something like `Minetest-WorldEdit` by left clicking once and press the **Enable Modpack** button.
9. Press the **Save** button. You can now use WorldEdit in that world. Repeat steps 7 to 9 to enable WorldEdit for other worlds too.

If you are having trouble, try asking for help in the [IRC channel](https://web.libera.chat/#minetest) (faster but may not always have helpers online)
or ask on the [forum topic](https://forum.minetest.net/viewtopic.php?id=572) (slower but more likely to get help).

Usage
-----
WorldEdit works primarily through the WorldEdit GUI and chat commands. Depending on your key bindings, you can invoke chat entry with the "T" key and open the chat console with the "F10" key.

WorldEdit has a huge potential for abuse by untrusted players. Therefore, users will not be able to use WorldEdit unless they have the `worldedit` privilege.
This is available by default in singleplayer, but in multiplayer the permission must be explicitly given by someone with the right credentials,
using the following chat command: `/grant <player name> worldedit`. This privilege can later be removed using the following chat command: `/revoke <player name> worldedit`.

Certain functions/commands such as WorldEdit `//lua` and `//luatransform` chat commands additionally require the `server` privilege.
This is because it is extremely dangerous to give access to these commands to untrusted players, since they essentially are able to control the computer the server is running on.
Give this privilege only to people you trust with your computer.

For in-game information about these commands, type `//help <command name>` in the chat. For example, to learn more about the `//copy` command, simply type `//help copy` to display information relevant to copying a region.

Interface
---------
WorldEdit is accessed in-game in two main ways.

The GUI adds a screen to each player's inventory that gives access to various WorldEdit functions. The [tutorial](Tutorial.md) may be helpful in learning to use it.

The chat interface adds many chat commands that perform various WorldEdit powered tasks. It is documented in the [Chat Commands Reference](ChatCommands.md).

Compatibility
-------------
This mod supports Minetest versions 5.0 and newer. Older versions of WorldEdit may work with older versions of Minetest, but are not recommended or supported.

WorldEdit works quite well with other mods and does not have any known mod conflicts.

WorldEdit GUI requires one of [sfinv](https://github.com/minetest/minetest_game/tree/master/mods/sfinv) (included in minetest_game),
[Unified Inventory](https://forum.minetest.net/viewtopic.php?t=12767),
[Inventory++](https://forum.minetest.net/viewtopic.php?id=6204) or [Smart Inventory](https://forum.minetest.net/viewtopic.php?t=16597).

If you use any other inventory manager mods, note that they may conflict with the WorldEdit GUI. If this is the case, it may be necessary to disable them.

WorldEdit API
-------------
WorldEdit exposes all significant functionality in a simple Lua interface.

Adding WorldEdit as a dependency to your mod gives you access to all of the `worldedit` functions. The API is useful for tasks such as high-performance node manipulation, alternative interfaces and map creation.

AGPLv3 compatible mods may further include WorldEdit files in their own mods. This can be useful if a modder wishes to completely avoid any dependency on WorldEdit. Note that it is required to give credit to the authors in this case.

This API is documented in the [WorldEdit API Reference](WorldEdit%20API.md).

Axes
----
The coordinate system is the same as that used by Minetest; positive Y is upwards, positive X is rightwards, and positive Z is forwards, if a player is facing North (positive Z axis).

When an axis is specified in a WorldEdit chat command, it is specified as one of the following values: `x`, `y`, `z`, or `?`.

In the GUI, there is a dropdown menu for this purpose. The "Look direction" option has the same effect as `?` does in chat commands.

The value `?` represents the axis the player is currently facing. If the player is facing more than one axis, the axis the player face direction is closest to will be used.

Nodes
-----
Node names are required for many types of commands that identify or modify specific types of nodes. They can be specified in a number of ways.

First, by description - the tooltip that appears when hovering over the item in an inventory. This is case insensitive and includes values such as "Cobblestone" and "bronze block".
Note that certain commands (namely, `//replace` and `//replaceinverse`) do not support descriptions that contain spaces in the `<searchnode>` field.

Second, by name - the node name that is defined by code, but without the mod name prefix. This is case sensitive and includes values such as "piston_normal_off" and "cactus".
If there are multiple possible nodes (such as "a:celery" and "b:celery"), one is chosen in no particular order.

Finally, by full name - the unambiguous identifier of the node, prefixes and all. This is case sensitive and includes values such as "default:stone" and "mesecons:wire_00000000_off".

The node name "air" can be used anywhere a normal node name can and acts as a blank node. This is useful for clearing or removing nodes.
For example, `//set air` would remove all the nodes in the current WorldEdit region. Similarly, `//sphere 10 air`, when WorldEdit position 1 underground, would dig a large sphere out of the ground.

Regions
-------
Most WorldEdit commands operate on regions. Regions are a set of two positions that define a 3D cuboid. They are local to each player and chat commands affect only the region for the player giving the commands.

Each positions together define two opposing corners of the cube. With two opposing corners it is possible to determine both the location and dimensions of the region.

Regions are not saved between server restarts. They start off as empty regions and cannot be used with most WorldEdit commands until they are set to valid values.

Markers
-------
Entities are used to mark the location of the WorldEdit regions. They appear as boxes containing the number 1 or 2 and represent the first and second position of the WorldEdit region, respectively.

To remove the entities, simply punch them. This does not reset the positions themselves.

Schematics
----------
WorldEdit supports two different types of schematics.

The first is the WorldEdit Schematic format, with the file extension ".we", and in some older versions, ".wem".
There have been several previous versions of the WorldEdit Schematic format, but WorldEdit is capable of loading any past versions, and will always support them - there is no need to worry about schematics becoming obsolete.

As of version 5, WorldEdit schematics include a header. The header is seperated from the content by a colon (`:`). It may contain fields seperated by commas (`,`).
Currently only one field is used, which contains the version as an ASCII decimal.

The current version of the WorldEdit Schematic format is essentially an array of node data tables in Lua 5.1 table syntax preceded by a header.
Specifically it looks like this:

	5:return {
		{
			y      = <y-axis coordinate>,
			x      = <x-axis coordinate>,
			z      = <z-axis coordinate>,
			name   = <node name>,
			param1 = <param1 value>,
			param2 = <param2 value>,
			meta   = <metadata table>,
		},
		<...>
	}


The ordering of the values and minor aspects of the syntax, such as trailing commas or newlines, are not guaranteed to stay the same in future versions.

The WorldEdit Schematic format is accessed via the WorldEdit API, or WorldEdit serialization chat commands such as `//serialize` and `//deserialize`.

The second is the Minetest Schematic format (MTS). The details of this format may be found in the Minetest documentation and are out of the scope of this document.
Access to this format is done via specialized MTS commands such as `//mtschemcreate` and `//mtschemplace`.

Authors
-------
WorldEdit would not be possible without the contributions of many developers and designers. Below, they are listed alphabetically:

    Alexander Weber
    ANAND
    beyondlimits
    Carter Kolwey
    cornernote
    Cy
    Daniel Sosa
    electricface
    est31
    Eugen Wesseloh
    h3ndrik
    HybridDog
    Isidor Zeuner
    Jean-Patrick Guerrero
    Joseph Pickard
    kaeza
    kilbith
    KodexKy
    Kyle
    MT-Modder
    Niwla23
    Panquesito7
    Pedro Gimeno
    Rui
    Sebastien Ponce
    sfan5
    ShadowNinja
    shivajiva101
    spillz
    Starbeamrainbowlabs
    TalkLounge
    tenplus1
    Uberi/Temperest
    Wuzzy

License
-------
Copyright (c) 2012 sfan5, Anthony Zhang (Uberi/Temperest), and Brett O'Donnell (cornernote).

This mod is licensed under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html).

Basically, this means everyone is free to use, modify, and distribute the files, as long as these modifications are also licensed the same way.
Most importantly, the Affero variant of the GPL requires you to publish your modifications in source form, even if the mod is run only on the server, and not distributed.
