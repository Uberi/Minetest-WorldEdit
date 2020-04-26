Chat Commands
-------------
For more information, see the [README](README.md).

Many commands also have shorter names that can be typed faster. For example, if we wanted to use `//move ? 5`, we could instead type `//m ? 5`. All shortened names are listed below:

| Short Name | Original Name      |
|:-----------|:-------------------|
| `//i`      | `//inspect`        |
| `//rst`    | `//reset`          |
| `//mk`     | `//mark`           |
| `//umk`    | `//unmark`         |
| `//1`      | `//pos1`           |
| `//2`      | `//pos2`           |
| `//fp`     | `//fixedpos`       |
| `//v`      | `//volume`         |
| `//s`      | `//set`            |
| `//r`      | `//replace`        |
| `//ri`     | `//replaceinverse` |
| `//hcube`  | `//hollowcube`     |
| `//hspr`   | `//hollowsphere`   |
| `//spr`    | `//sphere`         |
| `//hdo`    | `//hollowdome`     |
| `//do`     | `//dome`           |
| `//hcyl`   | `//hollowcylinder` |
| `//cyl`    | `//cylinder`       |
| `//hpyr`   | `//hollowpyramid`  |
| `//pyr`    | `//pyramid`        |

### `//about`

Get information about the WorldEdit mod.

    //about

### `//help [all/<cmd>]`

Get help for WorldEdit commands. `all` shows all WorldEdit commands, `<cmd>`
the help text for the given command.

    //help
    //help all
    //help hollowpyramid


### `//inspect [on/off/1/0/true/false/yes/no/enable/disable]`

Enable or disable node inspection.

    //inspect on
    //inspect off
    //inspect

### `//reset`

Reset the region so that it is empty.

    //reset

### `//mark`

Show markers at the region positions.

    //mark

### `//unmark`

Hide markers if currently shown.

    //unmark

### `//pos1`

Set WorldEdit region position 1 to the player's location.

    //pos1

### `//pos2`

Set WorldEdit region position 2 to the player's location.

    //pos2

### `//p set/set1/set2/get`

Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by
punching nodes, or print the current WorldEdit region.

    //p set
    //p set1
    //p set2
    //p get

### `//fixedpos set1/set2 <x> <y> <z>`

Set the WorldEdit region position 1 or 2 to the position (`<x>`, `<y>`, `<z>`).

    //fixedpos set1 0 0 0
    //fixedpos set1 -30 5 28
    //fixedpos set2 1004 -200 432

### `//volume`

Display the volume of the current WorldEdit region.

    //volume

### `//deleteblocks`

Delete the MapBlocks (16x16x16 units) that contain the selected region. This means that mapgen will be invoked for that area. As only whole MapBlocks get removed, the deleted area is usually larger than the selected one. Also, mapgen can trigger mechanisms like mud reflow or cavegen, which affects nodes (up to 112 nodes away) outside the MapBlock, so dont use this near buildings. Note that active entities are not part of a MapBlock and do not get deleted.

    //deleteblocks

### `//set <node>`

Set the current WorldEdit region to `<node>`.

    //set air
    //set cactus
    //set Blue Lightstone
    //set dirt with grass

### `//param2 <param2>`

Set the param2 value of all nodes in the current WorldEdit region to `<param2>`.

    //param2 8

### `//mix <node1> [count1] <node2> [count2] ...`

Fill the current WorldEdit region with a random mix of `<node1>`, `<node2>`, `...`.
Weightings can be optionally specified via the `[count1]`, `[count2]`, `...` parameters after a node name.

    //mix air
    //mix cactus stone glass sandstone
    //mix Bronze
    //mix default:cobble air
    //mix stone 3 dirt 2
    //mix cobblestone 8 stoneblock 2 stonebrick

### `//replace <search node> <replace node>`

Replace all instances of `<search node>` with `<replace node>` in the current WorldEdit region.

    //replace Cobblestone air
    //replace lightstone_blue glass
    //replace dirt Bronze Block
    //replace mesecons:wire_00000000_off flowers:flower_tulip

### `//replaceinverse <search node> <replace node>`

Replace all nodes other than `<search node>` with `<replace node>` in the current WorldEdit region.

    //replaceinverse Cobblestone air
    //replaceinverse flowers:flower_waterlily glass
    //replaceinverse dirt Bronze Block
    //replaceinverse mesecons:wire_00000000_off flowers:flower_tulip

### `//hollowcube <width> <height> <length> <node>`

Adds a hollow cube with its ground level centered at WorldEdit position 1 with
dimensions `<width>` x `<height>` x `<length>`, composed of `<node>`.

    //hollowcube 6 5 6 Diamond Block

### `//cube <width> <height> <length> <node>`

Adds a cube with its ground level centered at WorldEdit position 1 with
dimensions `<width>` x `<height>` x `<length>`, composed of `<node>`.

    //cube 6 5 6 Diamond Block
    //cube 7 2 1 default:cobble

### `//hollowsphere <radius> <node>`

Add hollow sphere centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    //hollowsphere 5 Diamond Block
    //hollowsphere 12 glass
    //hollowsphere 17 mesecons:wire_00000000_off

### `//sphere <radius> <node>`

Add sphere centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    //sphere 5 Diamond Block
    //sphere 12 glass
    //sphere 17 mesecons:wire_00000000_off

### `//hollowdome <radius> <node>`

Add hollow dome centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    //hollowdome 5 Diamond Block
    //hollowdome -12 glass
    //hollowdome 17 mesecons:wire_00000000_off

### `//dome <radius> <node>`

Add dome centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    //dome 5 Diamond Block
    //dome -12 glass
    //dome 17 mesecons:wire_00000000_off

### `//hollowcylinder x/y/z/? <length> <radius1> [radius2] <node>`

Add hollow cylinder at WorldEdit position 1 along the given axis with length `<length>`,
base radius `<radius1>` (and top radius `[radius2]`), composed of `<node>`.

Despite its name this command allows you to create cones (`radius2` = 0) as well as any shapes inbetween (0 < `radius2` < `radius1`).
Swapping `radius1` and `radius2` will create the same object but upside-down.

    //hollowcylinder x +5 8 Bronze Block
    //hollowcylinder y 28 10 glass
    //hollowcylinder z -12 3 mesecons:wire_00000000_off
    //hollowcylinder ? 2 4 default:stone

    //hollowcylinder y 10 10 0 walls:cobble
    //hollowcylinder x 6 0 5 Dirt
    //hollowcylinder z 20 10 20 default:desert_stone

### `//cylinder x/y/z/? <length> <radius1> [radius2] <node>`

Add cylinder at WorldEdit position 1 along the given axis with length `<length>`,
base radius `<radius1>` (and top radius `[radius2]`), composed of `<node>`.
Can also create shapes other than cylinders, e.g. cones (see documentation above).

    //cylinder x +5 8 Bronze Block
    //cylinder y 28 10 glass
    //cylinder z -12 3 mesecons:wire_00000000_off
    //cylinder ? 2 4 default:stone

    //cylinder y 10 10 0 walls:cobble
    //cylinder x 6 0 5 Dirt
    //cylinder z 20 10 20 default:desert_stone
    
### `//hollowpyramid x/y/z/? <height> <node>`

Add hollow pyramid centered at WorldEdit position 1 along the given axis with height `<height>` composed of `<node>`.

    //hollowpyramid x 8 Diamond Block
    //hollowpyramid y -5 glass
    //hollowpyramid z 2 mesecons:wire_00000000_off
    //hollowpyramid ? 12 mesecons:wire_00000000_off

### `//pyramid x/y/z/? <height> <node>`

Add pyramid centered at WorldEdit position 1 along the given axis with height `<height>` composed of `<node>`.

    //pyramid x 8 Diamond Block
    //pyramid y -5 glass
    //pyramid z 2 mesecons:wire_00000000_off
    //pyramid ? 12 mesecons:wire_00000000_off

### `//spiral <length> <height> <spacer> <node>`

Add spiral centered at WorldEdit position 1 with side length `<length>`,
height `<height>`, space between walls `<spacer>`, composed of `<node>`.

    //spiral 20 5 3 Diamond Block
    //spiral 5 2 1 glass
    //spiral 7 1 5 mesecons:wire_00000000_off

### `//copy x/y/z/? <amount>`

Copy the current WorldEdit region along the given axis by `<amount>` nodes.

    //copy x 15
    //copy y -7
    //copy z +4
    //copy ? 8

### `//move x/y/z/? <amount>`

Move the current WorldEdit positions and region along the given axis by `<amount>` nodes.

    //move x 15
    //move y -7
    //move z +4
    //move ? -1

### `//stack x/y/z/? <count>`

Stack the current WorldEdit region along the given axis `<count>` times.

    //stack x 3
    //stack y -1
    //stack z +5
    //stack ? 12

### `//stack2 <count> <x> <y> <z>`

Stack the current WorldEdit region `<count>` times by offset `<x>`, `<y>`, `<z>`.

    //stack2 5 3 8 2
    //stack2 1 -1 -1 -1

### `//stretch <stretchx> <stretchy> <stretchz>`

Scale the current WorldEdit positions and region by a factor of
`<stretchx>`, `<stretchy>`, `<stretchz>` along the X, Y, and Z axes,
respectively, with position 1 as the origin.

    //stretch 2 2 2
    //stretch 1 2 1
    //stretch 10 20 1

### `//transpose x/y/z/? x/y/z/?`

Transpose the current WorldEdit positions and region along given axes.

    //transpose x y
    //transpose y z
    //transpose ? y

### `//flip x/y/z/?`

Flip the current WorldEdit region along the given axis.

    //flip x
    //flip ?

### `//rotate x/y/z/? <angle>`

Rotate the current WorldEdit positions and region along the given axis by angle `<angle>` (90 degree increment).

    //rotate x 90
    //rotate y 180
    //rotate z 270
    //rotate ? -90

### `//orient <angle>`

Rotate oriented nodes in the current WorldEdit region around the Y axis by angle `<angle>` (90 degree increment)

    //orient 90
    //orient 180
    //orient 270
    //orient -90

### `//fixlight`

Fixes the lighting in the current WorldEdit region.

    //fixlight

### `//drain`

Removes any fluid node within the current WorldEdit region.

    //drain

### `//clearcut`

Removes any plant, tree or foilage-like nodes in the selected region.
The idea is to remove anything that isn't part of the terrain, leaving a "natural" empty space ready for building.

    //clearcut

### `//hide`

Hide all nodes in the current WorldEdit region non-destructively.

    //hide

### `//suppress <node>`

Suppress all `<node>` in the current WorldEdit region non-destructively.

    //suppress Diamond Block
    //suppress glass
    //suppress mesecons:wire_00000000_off

### `//highlight <node>`

Highlight `<node>` in the current WorldEdit region by hiding everything else non-destructively.

    //highlight Diamond Block
    //highlight glass
    //highlight mesecons:wire_00000000_off

### `//restore`

Restores nodes hidden with WorldEdit in the current WorldEdit region.

    //restore

### `//save <file>`

Save the current WorldEdit region to "(world folder)/schems/`<file>`.we".

    //save some random filename
    //save huge_base

### `//allocate <file>`

Set the region defined by nodes from "(world folder)/schems/`<file>`.we" as the current WorldEdit region.

    //allocate some random filename
    //allocate huge_base

### `//load <file>`

Load nodes from "(world folder)/schems/`<file>`.we" with position 1 of the current WorldEdit region as the origin.

    //load some random filename
    //load huge_base

### `//lua <code>`

Executes `<code>` as a Lua chunk in the global namespace.

    //lua worldedit.pos1["singleplayer"] = {x=0, y=0, z=0}
    //lua worldedit.rotate(worldedit.pos1["singleplayer"], worldedit.pos2["singleplayer"], "y", 90)

### `//luatransform <code>`

Executes `<code>` as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region.

    //luatransform minetest.swap_node(pos, {name="default:stone"})
    //luatransform if minetest.get_node(pos).name == "air" then minetest.add_node(pos, {name="default:water_source"}) end

### `//mtschemcreate <file>`

Save the current WorldEdit region using the Minetest Schematic format to "(world folder)/schems/`<file>`.mts".

    //mtschemcreate some random filename
    //mtschemcreate huge_base

### `//mtschemplace <file>`

Load nodes from "(world folder)/schems/`<file>`.mts" with position 1 of the current WorldEdit region as the origin.

    //mtschemplace some random filename
    //mtschemplace huge_base

### `//mtschemprob start/finish/get`

After using `//mtschemprob start` all nodes punched will bring up a text field where a probablity can be entered.
This mode can be left with `//mtschemprob finish`. `//mtschemprob get` will display the probabilities saved for the nodes.

    //mtschemprob get

### `//clearobjects`

Clears all objects within the WorldEdit region.

    //clearobjects
    
### `//shift x/y/z/?/up/down/left/right/front/back [+/-]<amount>`

Shifts the selection area by `[+|-]<amount>` without moving its contents.
The shifting axis can be absolute (`x/y/z`) or relative (`up/down/left/right/front/back`). 

		//shift left 5

### `//expand [+/-]x/y/z/?/up/down/left/right/front/back <amount> [reverse amount]`

Expands the selection by `<amount>` in the selected absolute or relative axis.
If specified, the selection can be expanded in the opposite direction over the same axis by `[reverse amount]`.

		//expand right 7 5
		
### `//contract [+/-]x/y/z/?/up/down/left/right/front/back <amount> [reverse amount]`

Contracts the selection by `<amount>` in the selected absolute or relative axis.
If specified, the selection can be contracted in the opposite direction over the same axis by `[reverse amount]`.

		//expand right 7 5
		
### `//outset [h/v] <amount>`

Expands the selection in all directions by `<amount>`. If specified,
the selection can be expanded horizontally in the x and z axes using `h`
or vertically in the y axis using `v`.

		//outset v 5
		
### `//inset [h/v] <amount>`

Contracts the selection in all directions by `<amount>`. If specified,
the selection can be contracted horizontally in the x and z axes using `h`
or vertically in the y axis using `v`.

		//inset h 5

### `//brush none/(<command> [parameters])`

Assigns the given `<command>` to the currently held brush item, it will be ran with the first pointed solid node (as determined via raycast) as
WorldEdit position 1 when using that specific brush item.
Passing `none` instead clears the command assigned to the currently held brush item.
Note that this functionality requires the `worldedit_brush` mod enabled.

		//brush cube 8 8 8 Cobblestone
		//brush spr 12 glass
		//brush none

### `//cubeapply <size>/(<sizex> <sizey> <sizez>) <command> [parameters]`

Selects a cube with side length of `<size>` around the WorldEdit position 1 and runs the given `<command>` on the newly selected region.
If `<sizex>`, `<sizey>` and `<sizez>` are given, they instead specify the length of the cuboid in X, Y, Z direction.
This is mostly useful for brushes since it allows commands such as `//replace` to be ran, but it can also be used standalone.

		//cubeapply 10 replaceinverse air default:water_source
		//brush cubeapply 15 drain
		//brush cubeapply 12 3 12 drain
		//brush cubeapply 1 deleteblocks
