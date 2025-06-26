# res://Source/Core/LevelPicker.gd
extends Node
class_name LevelPicker

# ─── Inspector fields ─────────────────────────────────────────────────────────

# Base folder for all your levels
@export var levels_prefix: String = "res://Source/Levels"

# Map level index → relative scene path under `levels_prefix`.
# e.g. { 0: "Level_01/Level_01.tscn", 1: "Level_02/Level_02.tscn" }
@export var level_paths := {
	0: "Level_0/Level_0.tscn"
}

# ─── Internal state ──────────────────────────────────────────────────────────

var current_level_index: int = -1
var current_level_node: Node = null

signal level_changed(new_index)

# ─── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	if level_paths.size() > 0:
		pick_level(0)

# ─── Public API ──────────────────────────────────────────────────────────────

func pick_level(index: int) -> void:
	# sanity
	if not level_paths.has(index):
		Log.error("LevelPicker: Level Not Found")
		return

	# same-level?
	if index == current_level_index:
		Log.warn("LevelPicker: already at level %d, skipping reload" % index)
		return

	# debug
	Log.debug("LevelPicker: moving from level %s → %s"
		% [ str(current_level_index), str(index) ])

	# clean up old
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null

	# build full path and load
	var rel_path: String = level_paths[index]
	var full_path: String = levels_prefix.rstrip("/") + "/" + rel_path

	# Load it explicitly as a PackedScene
	var scene: PackedScene = ResourceLoader.load(full_path, "PackedScene") as PackedScene
	if scene == null:
		push_error("LevelPicker: failed to load PackedScene at '%s'" % full_path)
		return

	current_level_node = scene.instantiate()
	# Add it to the current scene (or to whatever node makes sense)
	get_tree().get_current_scene().add_child(current_level_node)

	# # kick off generate()
	# if current_level_node.has_method("generate"):
	# 	current_level_node.generate()
	# else:
	# 	Log.error("LevelPicker: scene root has no generate() method")

	# update state & signal
	current_level_index = index
	emit_signal("level_changed", index)


func next_level() -> void:
	if level_paths.is_empty():
		return
	var nxt = (current_level_index + 1) % level_paths.size()
	pick_level(nxt)


func reload_level() -> void:
	if current_level_index >= 0:
		pick_level(current_level_index)
