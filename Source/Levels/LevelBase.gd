# res://Source/Levels/LevelBase.gd
extends Node
class_name LevelBase
# Base Abstract class for other Level classes. Defines abstract
# functions for graph generation algorithm

func _init() -> void:
	assert(
		get_script() != LevelBase,
		"LevelBase - is an abstract class, cant instantiate it!"
	)

# The main generation method. It should call generation methods for level_graph, pruning for distant chunks and thread physical generation of node
func _process(_delta: float) -> void:
	_abstract_method("_process")
	
func thread_objects_generation() -> void:
	_abstract_method("thread_objects_generation")

func define_node_bbox() -> void:
	_abstract_method("define_node_bbox")

func define_node_conectors():
	_abstract_method("define_node_conectors")

func generate_physical_node():
	_abstract_method("generate_physical_node")

func _abstract_method(_name: String) -> void:
	assert(false, "Method '%s' has to be implemented!" % _name)