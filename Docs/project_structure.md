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
