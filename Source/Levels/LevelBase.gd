# res://Source/Core/LevelBase.gd
extends Node
class_name LevelBase

const shapes_generator = preload("res://Source/WorldGenerators/Primitives/ShapesGenerator.gd")

func _ready() -> void:
	Log.debug("Base Node Ready")

# Abstract to call from children to generate node
func _queue_node_generation(node: Node) -> void:
	pass