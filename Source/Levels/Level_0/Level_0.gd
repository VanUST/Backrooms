# res://Source/Levels/Level_0/Level_0.gd
extends LevelBase
class_name  Level_0

func _init() -> void:
	pass

# The main generation method. It should call generation methods for level_graph, pruning for distant chunks and thread physical generation of node
func _physics_process(delta: float) -> void:
	pass
	
func thread_objects_generation() -> void:
	pass

func define_node_bbox() -> void:
	pass

func define_node_conectors():
	pass

func generate_physical_node():
	pass

