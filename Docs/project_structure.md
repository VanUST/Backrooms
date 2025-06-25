res://
├── Assets/                    ← art, meshes, materials, sounds…
│
├── Scenes/
│   ├── WorldRoot.tscn         ← your “game” entry-point; holds a WorldManager
│   └── Common/                ← any non-generator scenes you reuse
│
└── Source/
	├── Core/                  ← base interfaces, manager, utilities
	│   ├── IGenerator.gd      ← interface: `func generate(): void`
	│   ├── BaseGenerator.gd   ← abstract Node that implements IGenerator,
	│   │                        common life-cycle, export `seed` etc.
	│   └── GenerationManager.gd ← autoload, picks current Level and runs it
	│
	├── Generators/
	│   ├── Abstract/           ← low-level shape generators
	│   │   ├── ShapeGenerator.gd      ← pure API: carve a shape in space
	│   │   └── RectangleGenerator.gd  ← extends ShapeGenerator: rects
	│   │
	│   ├── Concrete/           ← domain-specific generators
	│   │   ├── WallGenerator.gd       ← extends RectangleGenerator
	│   │   ├── FloorGenerator.gd      ← extends ShapeGenerator
	│   │   └── DoorGenerator.gd       ← extends ShapeGenerator
	│   │
	│   └── Utils/              ← perlin/noise, random helpers…
	│       ├── NoiseSampler.gd
	│       └── RandomUtils.gd
	│
	├── Levels/                 ← one folder per level, plus base classes
	│   ├── LevelBase.gd        ← extends Node; holds & orchestrates a set of child generators
	│   ├── LevelParams.gd      ← `class_name LevelParams` extends Resource
	│   │                           — declares export vars: room_size_range, wall_height_range, sparsity, etc.
	│   │
	│   ├── Level_01_Fluorescent/
	│   │   ├── Level01Params.tres  ← a Resource file you tweak in-editor
	│   │   ├── Level01Generator.gd ← extends LevelBase, plugs in WallGenerator, NoiseSampler, etc.
	│   │   └── Level01.tscn        ← scene that has your Level01Generator as root
	│   │
	│   └── Level_02_Mossy/
	│       ├── Level02Params.tres
	│       ├── Level02Generator.gd
	│       └── Level02.tscn
	│
	└── Entities/              ← your player, NPCs, items…
		└── Player/ …

 How It Works

Core

IGenerator.gd defines a simple API:

func generate() -> void: pass
BaseGenerator.gd implements common plumbing (random seed, node-lifetime, a generate() hook you override).

GenerationManager.gd (autoload) picks a Level by name or index, instantiates its .tscn, calls generate().

Abstract vs. Concrete

Abstract/ contains shape generators (e.g. RectangleGenerator) that know nothing about “walls” or “floors.” They just carve out geometry or spawn mesh instances in a given Rect3/Volume.

Concrete/ extends those abstract shapes into domain concepts: WallGenerator says “I will generate walls along that shape—use this mesh, this height, this material.” You only ever tweak your mesh or thickness via exported vars on WallGenerator.

Level Layer

LevelParams.gd (a Resource) holds all the “hyperparameters” for a level (e.g. min/max room-size, ceiling-height noise scale, door frequency). You create one .tres per level in its folder, tweak it in the inspector.

Each LevelXXGenerator.gd extends LevelBase and in its _ready() (or a tool-enabled editor method) it:

loads its LevelXXParams.tres

instantiates a handful of WallGenerator, FloorGenerator, DoorGenerator children

sets their exported hyperparameters from the Resource

calls their generate() in the right order

Finally you wrap that in a LevelXX.tscn scene so you can drag–drop it in the editor if you want.

WorldRoot & Manager

WorldRoot.tscn has one script, WorldManager.gd, which is your “level loader.” It queries GenerationManager for “what level do I load now?”, instantiates that level’s scene, and parent it under WorldRoot.

Reusability & Scalability

Want a new kind of wall? Subclass WallGenerator once, give it new mesh presets, override one method.

Want a new level? Copy one of the Level folders, tweak its .tres and LevelXXGenerator.gd logic.

Every basic building block lives in Abstract/ and Concrete/; you never duplicate low-level code.

Hyperparameters & Variation

All per-level tweakables live in a single Resource (LevelXXParams.tres), not spread across dozens of scripts.

Inside your level logic you can sample Perlin noise (from NoiseSampler.gd) or random ranges to vary e.g. ceiling height, room sparsity, door placement—driven by those exported params.

I need implement an algorithm that will generate a level proceduraly. The level itsef could be described as a LevelGraph. The LevelGraph should handle generation of LevelNode instances. LevelNode has attributes:
 type, bbox, child object nodes array to store child objects , and connectors array to store LevelConnector objects. 

LevelConnector object is used to determine 2 regions in 3D space that new LevelNodes could be attached to (Those are 2 regions of same size right next to each other. When new LevelConnector is created, the first region should be inside the node's bbox it is initialized with, and one outside the bbox right next to it). It should probably store its type (box, cylinder e.t.c), associaited bboxes and nodes that are attached to it. One connector can have only two nodes attached to it

The graph generation algorithm goes like this:
1) Init first Node. It must have at least two connectors.
2) For each active connector of current Node (The connector is active has only 1 Node attached to it):
a) Find a bbox in which new node could be spawned while connected to current connector (that means new node should physically contain the bbox of the connector)

To find such a region ind 3D space use this approach:
The whole level could be split into chunks: 3d boxes of size CHUNK_SIZE. The check for the bbox should only happen for graph inside the current chunk. This can be done via bruteforce check for all the nodes which gives better region, or it could be done by storing the "global" bbox of the current chunk (the bbox that contains all the node's bboxes of graph in the current chunk and extended for newly added nodes (via BBox.extend() method), which is faster as requires check with only one "global" bbox for each new generated node). The new node's bbox should not intercept other nodes in current chunk (or "global" bbox of current chunk depending on method) for more than interception safe margin volume (probably should depend on node type), and the upper bound for size of bbox is MAX_NODE_BBOX_SIZE. We do not check for interceptions with the chunk itself for nodes. Instead, if node generated in two chunks at the same time, just assign it for both of them.

If the found bbox is bigger than MIN_NODE_BBOX_SIZE:

b1) Inside that found bbox generate a node based on set of arguements (will be specified further). That
c1) Generate connectors for the node
d1) Include the generated node into current chunk graph and include it into an array of active nodes if it has at least one active connector (not tied to chunk, separate array). 
e1) Initiate physical generation of LevelNode and its children in a separate thread (not in main thread)

else:
b2) Generate fallback node. Basically a dead end.

3) For all the ACTIVE nodes that are less than MAX_GENERATION_DISTANCE away from the player (probably should track players world coordinate and make it globally available via making a singleton, this is what I will do), find the closest to the player and make it new current node.
4) For memory release, consider doing it in chunks. If player is further than MAX_PLAYER_TO_CHUNK_DISTANCE away from some chunk (consider chunk's center), free the graph of this chunk
4) Repeat step 2.

