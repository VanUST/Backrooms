# File: LevelNodeConnector.gd
extends RefCounted
class_name LevelNodeConnector

# Represents a connection region between two LevelNode instances.
# Contains information about bboxes of connection regions and references to the nodes that are atteched to the connector.

var connector_regions: Dictionary = {1: null, 2:null}

class ConnectorRegion extends RefCounted:
	var bbox: BBox
	var direction: Vector3
	var node: LevelNode   # ← who’s currently plugged in here

	func _init(_bbox: BBox, _direction: Vector3, _node: LevelNode = null):
		bbox      = _bbox
		direction = _direction.normalized()
		node      = _node

func _init(connector_bbox: BBox, direction: Vector3, owner_node: LevelNode) -> void:
	# create the “side 1” region already tied to owner_node
	connector_regions[1] = ConnectorRegion.new(connector_bbox, direction, owner_node)

func _compute_unactive_bbox() -> BBox:
	var occupied_idx    = _compute_active_idx()
	var region        = connector_regions[occupied_idx]
	var bbox    = region.bbox
	var extent  = bbox.end_pos - bbox.start_pos
	var dir     = -region.direction
	var shift   = Vector3(dir.x * extent.x,
						dir.y * extent.y,
						dir.z * extent.z)
	return BBox.new(bbox.start_pos + shift,
					bbox.end_pos   + shift)

func _compute_unactive_idx() -> int:
	return 2 if connector_regions[1] != null else 1

func _compute_active_idx() -> int:
	return 1 if connector_regions[1] != null else 2

func _compute_active_direction() -> Vector3:
	var occupied_idx    =  _compute_active_idx()
	var region        = connector_regions[occupied_idx]
	var dir     = -region.direction.normalized()
	return dir

func _compute_unactive_direction() -> Vector3:
	var occupied_idx    =  _compute_unactive_idx()
	var region        = connector_regions[occupied_idx]
	var dir     = -region.direction.normalized()
	return dir

# Attach a node to this connector (max 2) Returns BBox of newly added connector region
func attach_node(new_node: LevelNode) -> BBox:
	# 1) compute the bbox of the “other side” just as before
	var unocc_bbox = _compute_unactive_bbox()
	var unocc_dir = _compute_active_direction()
	var unoccupied_idx = _compute_unactive_idx()

	# 2) Check if connector bbox is inside new_node bbox. Clamp it to be insied new node bbox
	unocc_bbox.clamp(new_node.bbox)

	# 3) create region 2 and tie it to our new node
	var new_region = ConnectorRegion.new(unocc_bbox, unocc_dir, new_node)
	connector_regions[unoccupied_idx] = new_region

	return unocc_bbox

func detach_node(node_to_remove: LevelNode) -> void:
	for idx in [1,2]:
		var reg = connector_regions[idx]
		if reg != null and reg.node == node_to_remove:
			# free that side
			connector_regions[idx] = null
			return

# A connector is active if exactly one node is attached
func is_active() -> bool:
	var a = connector_regions[1] != null and connector_regions[1].node != null
	var b = connector_regions[2] != null and connector_regions[2].node != null
	# active if exactly one is plugged
	return a != b
