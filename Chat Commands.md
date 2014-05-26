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
| `//hspr`   | `//hollowsphere`   |
| `//spr`    | `//sphere`         |
| `//hdo`    | `//hollowdome`     |
| `//do`     | `//dome`           |
| `//hcyl`   | `//hollowcylinder` |
| `//co`     | `//correctorigin`  |
| `//oc`     | `//correctorigin`  |
| `//la`     | `//loadalign` |
| `//lao`    | `//loadalignoffset`|

### `//about`

Get information about the mod.

    //about

### `//inspect on/off/1/0/true/false/yes/no/enable/disable/<blank>`

Enable or disable node inspection.

    //inspect on
    //inspect off
    //inspect 1
    //inspect 0
    //inspect true
    //inspect false
    //inspect yes
    //inspect no
    //inspect enable
    //inspect disable
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

Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region.

    //p set
    //p set1
    //p set2
    //p get

### `//fixedpos set1 x y z`

Set a WorldEdit region position to the position at (`<x>`, `<y>`, `<z>`).

    //fixedpos set1 0  0 0
    //fixedpos set1 -30 5 28
    //fixedpos set2 1004 -200 432

### `//volume`

Display the volume of the current WorldEdit region.

    //volume

### `//set <node>`

Set the current WorldEdit region to `<node>`.

    //set air
    //set cactus
    //set Bronze Block
    //set mesecons:wire_00000000_off

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

### `//hollowcylinder x/y/z/? <length> <radius> <node>`

Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length `<length>` and radius `<radius>`, composed of `<node>`.

    //hollowcylinder x +5 8 Bronze Block
    //hollowcylinder y 28 10 glass
    //hollowcylinder z -12 3 mesecons:wire_00000000_off
    //hollowcylinder ? 2 4 default:stone

### `//cylinder x/y/z/? <length> <radius> <node>`

Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length `<length>` and radius `<radius>`, composed of `<node>`.

    //cylinder x +5 8 Bronze Block
    //cylinder y 28 10 glass
    //cylinder z -12 3 mesecons:wire_00000000_off
    //cylinder ? 2 4 default:stone
    
### `//pyramid x/y/z? <height> <node>`

Add pyramid centered at WorldEdit position 1 along the x/y/z/? axis with height `<height>`, composed of `<node>`.

    //pyramid x 8 Diamond Block
    //pyramid y -5 glass
    //pyramid z 2 mesecons:wire_00000000_off
    //pyramid ? 12 mesecons:wire_00000000_off

### `//spiral <length> <height> <spacer> <node>`

Add spiral centered at WorldEdit position 1 with side length `<length>`, height `<height>`, space between walls `<spacer>`, composed of `<node>`.

    //spiral 20 5 3 Diamond Block
    //spiral 5 2 1 glass
    //spiral 7 1 5 mesecons:wire_00000000_off

### `//copy x/y/z/? <amount>`

Copy the current WorldEdit region along the x/y/z/? axis by `<amount>` nodes.

    //copy x 15
    //copy y -7
    //copy z +4
    //copy ? 8

### `//move x/y/z/? <amount>`

Move the current WorldEdit positions and region along the x/y/z/? axis by `<amount>` nodes.

    //move x 15
    //move y -7
    //move z +4
    //move ? -1

### `//stack x/y/z/? <count>`

Stack the current WorldEdit region along the x/y/z/? axis `<count>` times.

    //stack x 3
    //stack y -1
    //stack z +5
    //stack ? 12

### `//scale <factor>`

Scale the current WorldEdit positions and region by a factor of positive integer `<factor>` with position 1 as the origin.

    //scale 2
    //scale 1
    //scale 10

### `//transpose x/y/z/? x/y/z/?`

Transpose the current WorldEdit positions and region along the x/y/z/? and x/y/z/? axes.

    //transpose x y
    //transpose x z
    //transpose y z
    //transpose ? y

### `//flip x/y/z/?`

Flip the current WorldEdit region along the x/y/z/? axis.

    //flip x
    //flip y
    //flip z
    //flip ?

### `//rotate x/y/z/? <angle>`

Rotate the current WorldEdit positions and region along the x/y/z/? axis by angle `<angle>` (90 degree increment).

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

### `//hide`

Hide all nodes in the current WorldEdit region non-destructively.

    //hide

### `//suppress <node>`

Suppress all <node> in the current WorldEdit region non-destructively.

    //suppress Diamond Block
    //suppress glass
    //suppress mesecons:wire_00000000_off

### `//highlight <node>`

Highlight <node> in the current WorldEdit region by hiding everything else non-destructively.

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
Also display any mods which are not currently enabled in the world, but are referenced in the schem file.

    //allocate some random filename
    //allocate huge_base

### `//load <file>`

Load nodes from "(world folder)/schems/`<file>`.we" with position 1 of the current WorldEdit region as the origin.
NB is it suggested you do a dummy-run with //allocate to list referenced mods not currently enabled (which will cause errors)

    //load some random filename
    //load huge_base

### `//correctorigin`

Moves pos1 and pos2 so pos1 is at the origin of the region (ie pos1 located with minimum x,y,z, pos2 with maximum x,y,z)
This is ideally used before /save to decrease confusion with placement for /load and /loadalign
Shortcut of /co and /oc (to ease confusion) is set in worldedit_shortcommands/init.lua

    //correctorigin

### `//loadalignoffset [x y z]`

Set a global variable to enable an offset to the player location for /loadalign
-- This can be useful it a particular location is not easily accessible (eg if you want a file y-origin to be below ground level, or x- or z- inside a cliff)
-- the offset is cleared by using the command without params (=arguments)
-- Shortcut of /lao is set in worldedit_shortcommands/init.lua

    //load
    //load x y z

### `//loadalign <file>`

Load nodes from "(world folder)/schems/`<file>`.we" with player location as the origin. The loaded schem will be in a region to the front, right and above the players location.
NB is it suggested you do a dummy-run with //allocate to list referenced mods not currently enabled (which will cause errors)

If the location is not easily accessible (eg if you want a file y-origin to be below ground level, or x- or z- inside a cliff), you can set an offset with /loadalignoffset
The player is moved backwards one space to moved them out of the load zone (or more if there is and offset). This may mean the player ends up inside a node (if it suddenly gets dark). You may be able to step out. If not you'll have to teleport to an unblocked location.
The /save command saves the file with the origin at the xmin,ymin,zmin, irrespective of where pos1 and pos2 are. To reduce confusion it is suggested that you use the /correctorigin command before saving
  to move the markers to reflect this, but if you are copying a section one node wide, there are two possible orientations. 
  You need to be facing in the positive z direction to correctly orient yourself to the orientation when it is reloaded. 
  If you are using a schem regularly, and markers are not in your prefered orientation, it is best to do an initial /loadalign to get the correct orientation, then resave it
The loaded region is marked with pos1/pos2 with pos1 where the origin would have been when the schem was saved.
The function has only been tested with the current (version 4) schem files, so consider use with older schem files to be at your own risk. 
  The most likely bugs with untested versions are: either the entire region is incorrectly rotated or individual nodes are incorrectly oriented (so faces point in the incorrect direction)
The functions is a modifications of the original register //load to support alignment relative to player, so code from the screwdriver mod was used as a starter for node orientation.
  The main functions are in the WorldEdit/worldedit/serialization.lua (worldedit.deserializeAligned which also uses worldedit.getNewRotation, and might need worldedit.screwdriver_handler 
  depending on compatibility with old files)
Shortcut of /la is set in worldedit_shortcommands/init.lua

    //loadalign some random filename
    //loadalign huge_base

### `//lua <code>`

Executes `<code>` as a Lua chunk in the global namespace.

    //lua worldedit.pos1["singleplayer"] = {x=0, y=0, z=0}
    //lua worldedit.rotate(worldedit.pos1["singleplayer"], worldedit.pos2["singleplayer"], "y", 90)

### `//luatransform <code>`

Executes `<code>` as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region.

    //luatransform minetest.add_node(pos, {name="default:stone"})
    //luatransform if minetest.get_node(pos).name == "air" then minetest.add_node(pos, {name="default:water_source"})

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
