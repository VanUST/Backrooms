# File: LevelNode.gd
# A bulding block for LevelGraph. Represents a 3d region in which static 
# objects will be generated (children objects). Also stores connectors 
# for new nodes to generate on. Stores connector bboxes that are inside current node

extends Node
class_name LevelNode

# Attributes
var bbox: BBox = BBox.new()
var connectors: Array = []
var connector_bboxes: Array = []

# There real physical objects live:
var children_objects: Array = []

func _init(_bbox:BBox, connector: LevelNodeConnector = null) -> void:
	if _bbox:
		# Copy provided bbox
		bbox = BBox.new(_bbox.start_pos,_bbox.end_pos)
		# Attach or generate connectors
		if connector:
			attach_connector(connector)
		else:
			init_connectors()
	else:
		Log.error("No bbox for node was provided!")

func attach_connector(connector: LevelNodeConnector) -> void:
	connectors.append(connector)
	connector_bboxes.append(connector.attach_node(self))

# Fo inital nodes with no previous nodes and connectors
func init_connectors() -> void:
	connectors.clear()
	var connector_bbox_1 = BBox.new(Vector3(bbox.min_x(),bbox.min_y(),bbox.min_z()),\
							  Vector3(bbox.min_x(),bbox.max_y(),bbox.max_z()))
	var connector_bbox_2 = BBox.new(Vector3(bbox.min_x(),bbox.min_y(),bbox.min_z()),\
							  Vector3(bbox.max_x(),bbox.max_y(),bbox.min_z()))
	var conn1 = LevelNodeConnector.new(connector_bbox_1 , Vector3(1,0,0), self)  
	var conn2 = LevelNodeConnector.new(connector_bbox_2 , Vector3(0,0,1), self)  
	connectors.append(conn1)
	connectors.append(conn2)
	connectors.append(connector_bbox_1)
	connectors.append(connector_bbox_2)

func _exit_tree() -> void:
	for c in connectors:
		c.detach_node(self)
	connectors.clear()
	connector_bboxes.clear()

func is_active() -> bool:
	for c in connectors:
		if c.is_active():
			return true
	return false

# Return only connectors with exactly one attachment
func get_active_connectors() -> Array:
	var out = []
	for c in connectors:
		if c.is_active():
			out.append(c)
	return out