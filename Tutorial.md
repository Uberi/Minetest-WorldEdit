WorldEdit Tutorial
==================
This is a step-by-step tutorial outlining the basic usage of WorldEdit.

Let's start with a few assumptions:

* You have a compatible version of Minetest working, that is 5.0 or later.
* You have WorldEdit installed as a mod.
  * Simply download the file, extract the archive, and move it to the correct mod folder for Minetest.
  * See the installation instructions in [README](README.md) if you need more details.
* You are familiar with the basics of the game.
  * How to walk, jump, and climb.
  * How to dig, place, and punch blocks.
  * One of the following:
    * How to type into the chat and read text from it.
    * How to open the inventory screen and press buttons on it.

Overview
--------
WorldEdit has a "region", which is simply a cuboid area defined by two markers, both of which the player can move around. Every player can have their own region with their own two markers.

WorldEdit GUI buttons and chat commands generally work inside the region selected, or around the first marker.

If you are using the chat commands, follow the steps under **Chat Commands**. If you are using the WorldEdit GUI, follow the steps under **WorldEdit GUI**.

Step 1: Selecting a region
--------------------------
### Chat Commands

In the chat prompt, enter `//p set`. In the chat, you are prompted to punch two nodes to set the positions of the two markers.

Punch a nearby node. Be careful of breakable ones such as torches. A black cube reading "1" will appear around the node. This is the marker for WorldEdit position 1.

Walk away from the node you just punched. Now, punch another node. A black cube reading "2" will appear around the node. This is the marker for WorldEdit position 2.

### WorldEdit GUI

Open the main WorldEdit GUI from your inventory screen. The icon looks like a globe with a red dot in the center.

Press the "Get/Set Positions" button. On the new screen, press the "Set Position 1" button. The inventory screen should close.

Punch a nearby node. Be careful of breakable ones such as torches. A black cube reading "1" will appear around the node. This is the marker for WorldEdit position 1.

Walk away from the node you just punched. Open your inventory again. It should be on the same page as it was before.

Press the "Set Position 2" button. The inventory screen should close.

Now, punch another node. A black cube reading "2" will appear around the node. This is the marker for WorldEdit position 2.

Step 2: Region commands
-----------------------
### Chat Commands

In the chat prompt, enter `//set mese`. In the chat, you will see a message showing the number of nodes set after a small delay.

Look at the place between the two markers: it is now filled with MESE blocks!

The `//set <node>` command fills the region with whatever node you want. It is a region-oriented command, which means it works inside the WorldEdit region only.

Now, try a few different variations, such as `//set torch`, `//set cobble`, and `//set water source`.

### WorldEdit GUI

Open the main WorldEdit GUI from your inventory screen.

Press the "Set Nodes" button. You should see a new screen with various options for setting nodes.

Enter "mese" in the "Name" field. Press Search if you would like to see what the node you just entered looks like.

Press the "Set Nodes" button on this screen. In the chat, you will see a message showing the number of nodes set after a small delay.

Look at the place between the two markers: it is now filled with MESE blocks!

The "Set Nodes" function fills the region with whatever node you want. It is a region-oriented command, which means it works inside the WorldEdit region only.

Now, try a few different variations on the node name, such as "torch", "cobble", and "water source".

Step 3: Position commands
-------------------------
### Chat Commands

In the chat prompt, enter `//hollowdome 30 glass`. In the chat, you will see a message showing the number of nodes set after a small delay.

Look around marker 1: it is now surrounded by a hollow glass dome!

The `//hollowdome <radius> <node>` command creates a hollow dome centered around marker 1, made of any node you want. It is a position-oriented command, which means it works around marker 1 and can go outside the WorldEdit region.

### WorldEdit GUI

Open the main WorldEdit GUI from your inventory screen.

Press the "Sphere/Dome" button. You should see a new screen with various options for making spheres or domes.

Enter "glass" in the "Name" field. Press Search if you would like to see what the node you just entered looks like.

Enter "30" in the "Radius" field.

Press the "Hollow Dome" button on this screen. In the chat, you will see a message showing the number of nodes added after a small delay.

Look around marker 1: it is now surrounded by a hollow glass dome!

The "Hollow Dome" function creates a hollow dome centered around marker 1, made of any node you want. It is a position-oriented command, which means it works around marker 1 and can go outside the WorldEdit region.

Step 4: Other commands
----------------------
### Chat Commands

There are many more commands than what is shown here. See the [Chat Commands Reference](ChatCommands.md) for a detailed list of them, along with descriptions and examples for every single one.

If you're in-game and forgot how a command works, just use the `/help <command name>` command, without the first forward slash. For example, to see some information about the `//set <node>` command mentioned earlier, simply use `/help /set`.

A very useful command to check out is the `//save <schematic>` command, which can save everything inside the WorldEdit region to a file, stored on the computer hosting the server (the player's computer, in single player mode). You can then later use `//load <schematic>` to load the data in a file into a world, even another world on another computer.

### WorldEdit GUI

This only scratches the surface of what WorldEdit is capable of. Most of the functions in the WorldEdit GUI correspond to chat commands, and so the [Chat Commands Reference](ChatCommands.md) may be useful if you get stuck.

It is helpful to explore the various buttons in the interface and check out what they do. Learning the chat command interface is also useful if you use WorldEdit intensively - an experienced chat command user can usually work faster than an experienced WorldEdit GUI user.
