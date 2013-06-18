Chat Commands
-------------
For more information, see the [README](README.md).

### //reset

Reset the region so that it is empty.

    //reset

### //mark

Show markers at the region positions.

    //mark

### //unmark

Hide markers if currently shown.

    //unmark

### //pos1

Set WorldEdit region position 1 to the player's location.

    //pos1

### //pos2

Set WorldEdit region position 2 to the player's location.

    //pos2

### //p set/set1/set2/get

Set WorldEdit region, WorldEdit position 1, or WorldEdit position 2 by punching nodes, or display the current WorldEdit region.

    //p set
    //p set1
    //p set2
    //p get

### //volume

Display the volume of the current WorldEdit region.

    //volume

### //set <node>

Set the current WorldEdit region to <node>.

    //set cactus
    //set Bronze Block
    //set mesecons:wire_00000000_off

### //replace <search node> <replace node>

Replace all instances of <search node> with <replace node> in the current WorldEdit region.

    //replace Cobblestone cactus
    //replace lightstone_blue glass
    //replace dirt Bronze Block
    //replace mesecons:wire_00000000_off flowers:flower_tulip

### //replaceinverse <search node> <replace node>

Replace all nodes other than <search node> with <replace node> in the current WorldEdit region.

    //replaceinverse Cobblestone cactus
    //replaceinverse flowers:flower_waterlily glass
    //replaceinverse dirt Bronze Block
    //replaceinverse mesecons:wire_00000000_off flowers:flower_tulip

### //hollowsphere <radius> <node>

Add hollow sphere at WorldEdit position 1 with radius <radius>, composed of <node>.

    //hollowsphere 5 Diamond Block
    //hollowsphere 12 glass
    //hollowsphere 17 mesecons:wire_00000000_off

### //sphere <radius> <node>

Add sphere at WorldEdit position 1 with radius <radius>, composed of <node>.

    //sphere 5 Diamond Block
    //sphere 12 glass
    //sphere 17 mesecons:wire_00000000_off

### //hollowdome <radius> <node>

Add hollow dome at WorldEdit position 1 with radius <radius>, composed of <node>.

    //hollowdome 5 Diamond Block
    //hollowdome 12 glass
    //hollowdome 17 mesecons:wire_00000000_off

### //dome <radius> <node>

Add dome at WorldEdit position 1 with radius <radius>, composed of <node>.

    //dome 5 Diamond Block
    //dome 12 glass
    //dome 17 mesecons:wire_00000000_off

### //hollowcylinder x/y/z/? <length> <radius> <node>

Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>.

    //hollowcylinder x +5 8 Bronze Block
    //hollowcylinder y 28 10 glass
    //hollowcylinder z -12 3 mesecons:wire_00000000_off
    //hollowcylinder ? 2 4 default:stone

### //cylinder x/y/z/? <length> <radius> <node>

Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>.

    //cylinder x +5 8 Bronze Block
    //cylinder y 28 10 glass
    //cylinder z -12 3 mesecons:wire_00000000_off
    //cylinder ? 2 4 default:stone
    
### //pyramid <height> <node>

Add pyramid at WorldEdit position 1 with height <height>, composed of <node>.

    //pyramid 8 Diamond Block
    //pyramid 5 glass
    //pyramid 2 mesecons:wire_00000000_off

### //spiral <width> <height> <spacer> <node>

Add spiral at WorldEdit position 1 with width <width>, height <height>, space between walls <spacer>, composed of <node>.

    //spiral 20 5 3 Diamond Block
    //spiral 5 2 1 glass
    //spiral 7 1 5 mesecons:wire_00000000_off

### //copy x/y/z/? <amount>

Copy the current WorldEdit region along the x/y/z/? axis by <amount> nodes.

    //copy x 15
    //copy y -7
    //copy z +4
    //copy ? 8

### //move x/y/z/? <amount>

Move the current WorldEdit positions and region along the x/y/z/? axis by <amount> nodes.

    //move x 15
    //move y -7
    //move z +4
    //move ? -1

### //stack x/y/z/? <count>

Stack the current WorldEdit region along the x/y/z/? axis <count> times.

    //stack x 3
    //stack y -1
    //stack z +5
    //stack ? 12

### //scale <factor>

Scale the current WorldEdit positions and region by a factor of positive integer <factor> with position 1 as the origin.

    //scale 2
    //scale 1
    //scale 10

### //transpose x/y/z/? x/y/z/?

Transpose the current WorldEdit positions and region along the x/y/z/? and x/y/z/? axes.

    //transpose x y
    //transpose x z
    //transpose y z
    //transpose ? y

### //flip x/y/z/?

Flip the current WorldEdit region along the x/y/z/? axis.

    //flip x
    //flip y
    //flip z
    //flip ?

### //rotate x/y/z/? <angle>

Rotate the current WorldEdit positions and region along the x/y/z/? axis by angle <angle> (90 degree increment).

    //rotate x 90
    //rotate y 180
    //rotate z 270
    //rotate ? -90

### //orient <angle>

Rotate oriented nodes in the current WorldEdit region around the Y axis by angle <angle> (90 degree increment)

    //orient 90
    //orient 180
    //orient 270
    //orient -90

### //fixlight

Fixes the lighting in the current WorldEdit region.

    //fixlight

### //hide

Hide all nodes in the current WorldEdit region non-destructively.

    //hide

### //suppress <node>

Suppress all <node> in the current WorldEdit region non-destructively.

    //suppress Diamond Block
    //suppress glass
    //suppress mesecons:wire_00000000_off

### //highlight <node>

Highlight <node> in the current WorldEdit region by hiding everything else non-destructively.

    //highlight Diamond Block
    //highlight glass
    //highlight mesecons:wire_00000000_off

### //restore

Restores nodes hidden with WorldEdit in the current WorldEdit region.

    //restore

### //save <file>

Save the current WorldEdit region to "(world folder)/schems/<file>.we".

    //save some random filename
    //save huge_base

### //allocate <file>

Set the region defined by nodes from "(world folder)/schems/<file>.we" as the current WorldEdit region.

    //allocate some random filename
    //allocate huge_base

### //load <file>

Load nodes from "(world folder)/schems/<file>.we" with position 1 of the current WorldEdit region as the origin.

    //load some random filename
    //load huge_base

### //lua <code>

Executes <code> as a Lua chunk in the global namespace.

    //lua worldedit.pos1["singleplayer"] = {x=0, y=0, z=0}
    //lua worldedit.rotate(worldedit.pos1["singleplayer"], worldedit.pos2["singleplayer"], "y", 90)

### //luatransform <code>

Executes <code> as a Lua chunk in the global namespace with the variable pos available, for each node in the current WorldEdit region.

    //luatransform minetest.env:add_node(pos, {name="default:stone"})
    //luatransform if minetest.env:get_node(pos).name == "air" then minetest.env:add_node(pos, {name="default:water_source"})
