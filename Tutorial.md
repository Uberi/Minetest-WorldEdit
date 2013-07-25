WorldEdit Tutorial
==================
This is a step-by-step tutorial outlining the basic usage of WorldEdit. For more information, see the [README](README.md).

Let's start with a few assumptions:

* You have a compatible version of Minetest working.
  * See the [README](README.md) for compatibility information.
* You have WorldEdit installed as a mod.
  * If using Windows, [MODSTER](https://forum.minetest.net/viewtopic.php?pid=101463) makes installing mods totally painless.
  * Simply download the file, extract the archive, and move it to the correct mod folder for Minetest.
* You are familiar with the basics of the game.
  * How to walk, jump, and climb.
  * How to dig, place, and punch blocks.
  * How to type into the chat and read text from it.

Overview
--------
WorldEdit has a "region", which is simply a cuboid area defined by two markers, both of which the player can move around. Every player can have their own region with their own two markers.

WorldEdit chat commands can work inside the region selected, or around the first marker.

Step 1: Selecting a region
--------------------------
In the chat prompt, enter `//p set`. In the chat, you are prompted to punch two nodes to set the positions of the two markers.

Punch a nearby node. Be careful of breakable ones such as torches. A black cube reading "1" will appear around the node. This is the marker for WorldEdit position 1.

Walk away from the node you just punched. Now, punch another node. A black cube reading "2" will appear around the node. This is the marker for WorldEdit position 2.

Step 2: Region commands
-----------------------
In the chat prompt, enter `//set mese`. In the chat, you will see a message showing the number of nodes set after a small delay.

Look at the place between the two markers: it is now filled with MESE blocks!

The `//set <node>` command fills the region with whatever node you want. It is a region-oriented command, which means it works inside the WorldEdit region only.

Now, try a few different variations, such as `//set torch`, `//set cobble`, and `//set water`.

Step 3: Position commands
-------------------------
In the chat prompt, enter `//hollowdome 30 glass`. In the chat, you will see a message showing the number of nodes set after a small delay.

Look around marker 1: it is now surrounded by a hollow glass dome!

The `//hollowdome <radius> <node>` command creates a hollow dome centered around marker 1, made of any node you want. It is a position-oriented command, which means it works around marker 1 and can go outside the WorldEdit region.

Step 4: Other commands
----------------------
There are many more commands than what is shown here. See the [Chat Commands Reference](Chat Commands.md) for a detailed list of them, along with descriptions and examples for every single one.

If you're in-game and forgot how a command works, just use the `/help <command name>` command, without the first forward slash. For example, to see some information about the `//set <node>` command mentioned earlier, simply use `/help /set`.

A very useful command to check out is the `//save <schematic>` command, which can save everything inside the WorldEdit region to a file, stored on the computer hosting the server (the player's computer, in single player mode). You can then later use `//load <schematic>` to load the data in a file into a world, even another world on another computer.