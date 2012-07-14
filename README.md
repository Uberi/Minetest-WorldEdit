WorldEdit v1.0 for MineTest 0.4
===============================
In-game world editing for [MineTest](http://minetest.net/)! Tons of chat commands to help with building, fixing, and more.

For more information, see the [forum topic](http://minetest.net/forum/viewtopic.php?id=572) at the MineTest forums.

Usage
-----
WorldEdit works primarily through chat commands. Depending on your key bindings, you can invoke chat entry with the "t" key, and open the chat console with the "F10" key.

WorldEdit has a huge potential for abuse by untrusted players. Therefore, users will not be able to use WorldEdit unless they have the "worldedit" privelege. This is available by default in single player, but in multiplayer the permission must be explicitly given by someone with the right credentials, using the follwoing chat command: `/grant <player name> worldedit`. This privelege can later be removed using the following chat command: `/revoke <player name> worldedit`.

For in-game information about these commands, type `/help <command name>` in the chat. For example, to learn more about the `//copy` command, simply type `/help /copy` to display information relevant to copying a region.

Commands
--------

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

License
-------
Copyright 2012 sfan5 and Anthony Zhang (Temperest)

This mod is licensed under the [GNU Affero General Public License](http://www.gnu.org/licenses/agpl-3.0.html).

Basically, this means everyone is free to use, modify, and distribute the files, as long as these modifications are also licensed the same way.

Most importantly, the Affero variant of the GPL requires you to publish your modifications in source form, even if the mod is run only on the server, and not distributed.