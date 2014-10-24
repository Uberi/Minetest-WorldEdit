Chat Commands
-------------
For more information, see the [README](README.md).

Many commands also have shorter names that can be typed faster. For example,
if we wanted to use `/we-move ? 5`, we could instead type `/m ? 5`.
All shortened names are listed below:

| Short Name | Original Name       |
|:-----------|:--------------------|
| `i`        | `we-inspect`        |
| `rst`      | `we-reset`          |
| `mk`       | `we-mark`           |
| `umk`      | `we-unmark`         |
| `1`        | `we-pos1`           |
| `2`        | `we-pos2`           |
| `fp`       | `we-fixedpos`       |
| `v`        | `we-volume`         |
| `s`        | `we-set`            |
| `r`        | `we-replace`        |
| `ri`       | `we-replaceinverse` |
| `hspr`     | `we-hollowsphere`   |
| `spr`      | `we-sphere`         |
| `hdo`      | `we-hollowdome`     |
| `do`       | `we-dome`           |
| `hcyl`     | `we-hollowcylinder` |

### `/we-about`

Get information about the mod.

    /we-about

### `/we-inspect on/off/1/0/true/false/yes/no/enable/disable/<blank>`

Enable or disable node inspection.

    /we-inspect on
    /we-inspect off
    /we-inspect 1
    /we-inspect 0
    /we-inspect true
    /we-inspect false
    /we-inspect yes
    /we-inspect no
    /we-inspect enable
    /we-inspect disable
    /we-inspect

### `/we-reset`

Reset the region so that it is empty.

    /we-reset

### `/we-mark`

Show markers at the region positions.

    /we-mark

### `/we-unmark`

Hide markers if currently shown.

    /we-unmark

### `/we-pos1`

Set WorldEdit region position 1 to the player's location.

    /we-pos1

### `/we-pos2`

Set WorldEdit region position 2 to the player's location.

    /we-pos2

### `/we-p set/set1/set2/get`

Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region.

    /we-p set
    /we-p set1
    /we-p set2
    /we-p get

### `/we-fixedpos set1 x y z`

Set a WorldEdit region position to the position at (`<x>`, `<y>`, `<z>`).

    /we-fixedpos set1 0  0 0
    /we-fixedpos set1 -30 5 28
    /we-fixedpos set2 1004 -200 432

### `/we-volume`

Display the volume of the current WorldEdit region.

    /we-volume

### `/we-set <node>`

Set the current WorldEdit region to `<node>`.

    /we-set air
    /we-set cactus
    /we-set Blue Lightstone
    /we-set dirt with grass

### `/we-mix <node1> ...`

Fill the current WorldEdit region with a random mix of `<node1>`, `...`.

    /we-mix air
    /we-mix cactus stone glass sandstone
    /we-mix Bronze
    /we-mix default:cobble air

### `/we-replace <search node> <replace node>`

Replace all instances of `<search node>` with `<replace node>` in the current WorldEdit region.

    /we-replace Cobblestone air
    /we-replace lightstone_blue glass
    /we-replace dirt Bronze Block
    /we-replace mesecons:wire_00000000_off flowers:flower_tulip

### `/we-replaceinverse <search node> <replace node>`

Replace all nodes other than `<search node>` with `<replace node>` in the current WorldEdit region.

    /we-replaceinverse Cobblestone air
    /we-replaceinverse flowers:flower_waterlily glass
    /we-replaceinverse dirt Bronze Block
    /we-replaceinverse mesecons:wire_00000000_off flowers:flower_tulip

### `/we-hollowsphere <radius> <node>`

Add hollow sphere centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    /we-hollowsphere 5 Diamond Block
    /we-hollowsphere 12 glass
    /we-hollowsphere 17 mesecons:wire_00000000_off

### `/we-sphere <radius> <node>`

Add sphere centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    /we-sphere 5 Diamond Block
    /we-sphere 12 glass
    /we-sphere 17 mesecons:wire_00000000_off

### `/we-hollowdome <radius> <node>`

Add hollow dome centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    /we-hollowdome 5 Diamond Block
    /we-hollowdome -12 glass
    /we-hollowdome 17 mesecons:wire_00000000_off

### `/we-dome <radius> <node>`

Add dome centered at WorldEdit position 1 with radius `<radius>`, composed of `<node>`.

    /we-dome 5 Diamond Block
    /we-dome -12 glass
    /we-dome 17 mesecons:wire_00000000_off

### `/we-hollowcylinder x/y/z/? <length> <radius> <node>`

Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length `<length>` and radius `<radius>`, composed of `<node>`.

    /we-hollowcylinder x +5 8 Bronze Block
    /we-hollowcylinder y 28 10 glass
    /we-hollowcylinder z -12 3 mesecons:wire_00000000_off
    /we-hollowcylinder ? 2 4 default:stone

### `/we-cylinder x/y/z/? <length> <radius> <node>`

Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length `<length>` and radius `<radius>`, composed of `<node>`.

    /we-cylinder x +5 8 Bronze Block
    /we-cylinder y 28 10 glass
    /we-cylinder z -12 3 mesecons:wire_00000000_off
    /we-cylinder ? 2 4 default:stone
    
### `/we-pyramid x/y/z? <height> <node>`

Add pyramid centered at WorldEdit position 1 along the x/y/z/? axis with height `<height>`, composed of `<node>`.

    /we-pyramid x 8 Diamond Block
    /we-pyramid y -5 glass
    /we-pyramid z 2 mesecons:wire_00000000_off
    /we-pyramid ? 12 mesecons:wire_00000000_off

### `/we-spiral <length> <height> <spacer> <node>`

Add spiral centered at WorldEdit position 1 with side length `<length>`, height `<height>`, space between walls `<spacer>`, composed of `<node>`.

    /we-spiral 20 5 3 Diamond Block
    /we-spiral 5 2 1 glass
    /we-spiral 7 1 5 mesecons:wire_00000000_off

### `/we-copy x/y/z/? <amount>`

Copy the current WorldEdit region along the x/y/z/? axis by `<amount>` nodes.

    /we-copy x 15
    /we-copy y -7
    /we-copy z +4
    /we-copy ? 8

### `/we-move x/y/z/? <amount>`

Move the current WorldEdit positions and region along the x/y/z/? axis by `<amount>` nodes.

    /we-move x 15
    /we-move y -7
    /we-move z +4
    /we-move ? -1

### `/we-stack x/y/z/? <count>`

Stack the current WorldEdit region along the x/y/z/? axis `<count>` times.

    /we-stack x 3
    /we-stack y -1
    /we-stack z +5
    /we-stack ? 12

### `/we-stack2 <count> <x> <y> <z>`

Stack the current WorldEdit region `<count>` times by offset `<x>`, `<y>`, `<z>`.

    /we-stack2 5 3 8 2
    /we-stack2 1 -1 -1 -1

### `/we-scale <factor>`

Scale the current WorldEdit positions and region by a factor of positive integer `<factor>` with position 1 as the origin.

    /we-scale 2
    /we-scale 1
    /we-scale 10

### `/we-transpose x/y/z/? x/y/z/?`

Transpose the current WorldEdit positions and region along the x/y/z/? and x/y/z/? axes.

    /we-transpose x y
    /we-transpose x z
    /we-transpose y z
    /we-transpose ? y

### `/we-flip x/y/z/?`

Flip the current WorldEdit region along the x/y/z/? axis.

    /we-flip x
    /we-flip y
    /we-flip z
    /we-flip ?

### `/we-rotate x/y/z/? <angle>`

Rotate the current WorldEdit positions and region along the x/y/z/? axis by angle `<angle>` (90 degree increment).

    /we-rotate x 90
    /we-rotate y 180
    /we-rotate z 270
    /we-rotate ? -90

### `/we-orient <angle>`

Rotate oriented nodes in the current WorldEdit region around the Y axis by angle `<angle>` (90 degree increment)

    /we-orient 90
    /we-orient 180
    /we-orient 270
    /we-orient -90

### `/we-fixlight`

Fixes the lighting in the current WorldEdit region.

    /we-fixlight

### `/we-hide`

Hide all nodes in the current WorldEdit region non-destructively.

    /we-hide

### `/we-suppress <node>`

Suppress all <node> in the current WorldEdit region non-destructively.

    /we-suppress Diamond Block
    /we-suppress glass
    /we-suppress mesecons:wire_00000000_off

### `/we-highlight <node>`

Highlight <node> in the current WorldEdit region by hiding everything else non-destructively.

    /we-highlight Diamond Block
    /we-highlight glass
    /we-highlight mesecons:wire_00000000_off

### `/we-restore`

Restores nodes hidden with WorldEdit in the current WorldEdit region.

    /we-restore

### `/we-save <file>`

Save the current WorldEdit region to "(world folder)/schems/`<file>`.we".

    /we-save some random filename
    /we-save huge_base

### `/we-allocate <file>`

Set the region defined by nodes from "(world folder)/schems/`<file>`.we" as the current WorldEdit region.

    /we-allocate some random filename
    /we-allocate huge_base

### `/we-load <file>`

Load nodes from "(world folder)/schems/`<file>`.we" with position 1 of the current WorldEdit region as the origin.

    /we-load some random filename
    /we-load huge_base

### `/we-lua <code>`

Executes `<code>` as a Lua chunk in the global namespace.

    /we-lua worldedit.pos1["singleplayer"] = {x=0, y=0, z=0}
    /we-lua worldedit.rotate(worldedit.pos1["singleplayer"], worldedit.pos2["singleplayer"], "y", 90)

### `/we-luatransform <code>`

Executes `<code>` as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region.

    /we-luatransform minetest.add_node(pos, {name="default:stone"})
    /we-luatransform if minetest.get_node(pos).name == "air" then minetest.add_node(pos, {name="default:water_source"})

### `/we-mtschemcreate <file>`

Save the current WorldEdit region using the Minetest Schematic format to "(world folder)/schems/`<file>`.mts".

    /we-mtschemcreate some random filename
    /we-mtschemcreate huge_base

### `/we-mtschemplace <file>`

Load nodes from "(world folder)/schems/`<file>`.mts" with position 1 of the current WorldEdit region as the origin.

    /we-mtschemplace some random filename
    /we-mtschemplace huge_base

### `/we-mtschemprob start/finish/get`

After using `/we-mtschemprob start` all nodes punched will bring up a text field where a probablity can be entered.
This mode can be left with `/we-mtschemprob finish`. `/we-mtschemprob get` will display the probabilities saved for the nodes.

    /we-mtschemprob get

### `/we-clearobjects`

Clears all objects within the WorldEdit region.

    /we-clearobjects
