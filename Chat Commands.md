Chat Commands
-------------
For more information, see the [README](README.md).

### //reset

Reset the region so that it is empty.

    //reset

### //mark

Show markers at the region positions.

    //mark

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

    //set dirt
    //set default:glass
    //set mesecons:mesecon

### //replace <search node> <replace node>

Replace all instances of <search node> with <place node> in the current WorldEdit region.

    //replace cobble stone
    //replace default:steelblock glass
    //replace dirt flowers:flower_waterlily
    //replace flowers:flower_rose flowers:flower_tulip

### //hollowsphere <radius> <node>

Add hollow sphere at WorldEdit position 1 with radius <radius>, composed of <node>.

    //hollowsphere 5 dirt
    //hollowsphere 12 default:glass
    //hollowsphere 17 mesecons:mesecon

### //sphere <radius> <node>

Add sphere at WorldEdit position 1 with radius <radius>, composed of <node>.

    //sphere 5 dirt
    //sphere 12 default:glass
    //sphere 17 mesecons:mesecon

### //hollowcylinder x/y/z/? <length> <radius> <node>

Add hollow cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>.

    //hollowcylinder x +5 8 dirt
    //hollowcylinder y 28 10 default:glass
    //hollowcylinder z -12 3 mesecons:mesecon
    //hollowcylinder ? 2 4 stone

### //cylinder x/y/z/? <length> <radius> <node>

Add cylinder at WorldEdit position 1 along the x/y/z/? axis with length <length> and radius <radius>, composed of <node>.

    //cylinder x +5 8 dirt
    //cylinder y 28 10 default:glass
    //cylinder z -12 3 mesecons:mesecon
    //cylinder ? 2 4 stone
    
### //pyramid <height> <node>

Add pyramid at WorldEdit position 1 with height <height>, composed of <node>.

    //pyramid 8 dirt
    //pyramid 5 default:glass
    //pyramid 2 stone

### //spiral <width> <height> <spacer> <node>

Add spiral at WorldEdit position 1 with width <width>, height <height>, space between walls <spacer>, composed of <node>.

    //spiral 20 5 3 dirt
    //spiral 5 2 1 default:glass
    //spiral 7 1 5 stone

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

### //transpose x/y/z/? x/y/z/?

Transpose the current WorldEdit region along the x/y/z/? and x/y/z/? axes.

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

Rotate the current WorldEdit region along the x/y/z/? axis by angle <angle> (90 degree increment).

    //rotate x 90
    //rotate y 180
    //rotate z 270
    //rotate ? -90

### //dig

Dig the current WorldEdit region.

    //dig

## //hide

Hide all nodes in the current WorldEdit region non-destructively.

    //hide

### //suppress <node>

Suppress all <node> in the current WorldEdit region non-destructively.

    //suppress dirt
    //suppress default:glass
    //suppress mesecons:mesecon

### //find <node>

Find <node> in the current WorldEdit region by hiding everything else non-destructively.

    //find dirt
    //find default:glass
    //find mesecons:mesecon

### //restore

Restores nodes hidden with WorldEdit in the current WorldEdit region.

    //restore

### //save <file>

Save the current WorldEdit region to "(world folder)/schems/<file>.we".

    //save some random filename
    //save huge_base

### //load <file>

Load nodes from "(world folder)/schems/<file>.we" with position 1 of the current WorldEdit region as the origin.

    //load some random filename
    //load huge_base

### //metasave <file>

Save the current WorldEdit region including metadata to "(world folder)/schems/<file>.wem".

    //metasave some random filename
    //metasave huge_base

### //metaload <file>

Load nodes and metadata from "(world folder)/schems/<file>.wem" with position 1 of the current WorldEdit region as the origin.

    //metaload some random filename
    //metaload huge_base