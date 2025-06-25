extends Node
class_name LevelGraph

# Configuration constants
const CHUNK_SIZE = Vector3(100, 100, 100)
const MAX_NODE_BBOX_SIZE = Vector3(50, 50, 50)
const MIN_NODE_BBOX_SIZE = Vector3(3, 3, 3)
const MAX_GENERATION_DISTANCE = 200
const MAX_PLAYER_TO_CHUNK_DISTANCE = 300
const SAFE_MARGIN_VOLUME = 5

# State         
var active_nodes: Array = []       # Nodes with active connectors
var chunks: Dictionary = {}        # grid_pos (Vector3i) -> Chunk

class Chunk:
	var grid_pos: Vector3i               # integer grid coordinates
	var center: Vector3 = Vector3.ZERO  # world-space center
	var bbox: BBox = null               # chunk bounds
	var nodes: Array = []

	func _init(_grid_pos: Vector3i) -> void:
		# Store integer grid coordinates
		grid_pos = Vector3i(int(_grid_pos.x), int(_grid_pos.y), int(_grid_pos.z))
		# Compute world center from grid
		center = grid_pos * CHUNK_SIZE
		# Build bounding box around center
		var half = CHUNK_SIZE * 0.5
		bbox = BBox.new(center - half, center + half)

func _ready() -> void:
	# Initialize generation
	initialize_chunk()
	generate_initial_node()

func initialize_chunk(grid_pos: Vector3i = Vector3i.ZERO) -> void:
	# Create initial chunk at grid (0,0,0)
	var initial = Chunk.new(grid_pos)
	chunks[grid_pos] = initial
    
func generate_initial_node(pos: Vector3i = Vector3i.ZERO) -> void:
    # Create node centered in the chunk
	var world_center = pos * CHUNK_SIZE
	var init_bbox = BBox.new(world_center - (MIN_NODE_BBOX_SIZE * 0.5), world_center + (MIN_NODE_BBOX_SIZE * 0.5))
	var start_node = LevelNode.new(init_bbox , "start")
	if start_node.is_active():
			active_nodes.append(start_node)
	add_child(start_node)
	assign_node_to_chunks(start_node)

func generate_node(connector: LevelNodeConnector, bbox: BBox ) -> void:
	var new_node: LevelNode = LevelNode.new(bbox,connector) 
	if new_node.is_active():
		active_nodes.append(new_node)
	add_child(new_node)
	assign_node_to_chunks(new_node)

func assign_node_to_chunks(node: LevelNode) -> void:
	# Compute grid-range spanned by node bbox
	var half = CHUNK_SIZE * 0.5
	var min_idx = Vector3(
		floor((node.bbox.min_x() + half.x) / CHUNK_SIZE.x),
		floor((node.bbox.min_y() + half.y) / CHUNK_SIZE.y),
		floor((node.bbox.min_z() + half.z) / CHUNK_SIZE.z)
	)
	var max_idx = Vector3(
		floor((node.bbox.max_x() + half.x) / CHUNK_SIZE.x),
		floor((node.bbox.max_y() + half.y) / CHUNK_SIZE.y),
		floor((node.bbox.max_z() + half.z) / CHUNK_SIZE.z)
	)
	# Iterate integer grid positions
	for x in range(int(min_idx.x), int(max_idx.x) + 1):
		for y in range(int(min_idx.y), int(max_idx.y) + 1):
			for z in range(int(min_idx.z), int(max_idx.z) + 1):
				var gp = Vector3(x, y, z)
				var chunk = null
				# Create chunk if not exists
				if not chunks.has(gp):
					initialize_chunk(gp)
				else:
					chunk = chunks[gp]
				# Assign if intersects
				if BBox.are_intersecting(node.bbox, chunk.bbox):
					chunk.nodes.append(node)

func process_active_nodes() -> void:
	current_active_nodes_amount = active_nodes.size()
	for current_active_node_idx in range(current_active_nodes_amount):
		current_active_node = active_nodes[current_active_node_idx]
		for conn in current_active_node.get_active_connectors():
			process_active_node(current_active_node, conn)
		# Cleanup distant chunks
		prune_chunks()
		# Select new current node: closest active to player
		current_node = _get_closest_active_to_player()
		if not current_node:
			break

# EVERYTHING BELOW TO REWORK!
func process_active_node(current_active_node:LevelNode, connector:LevelNodeConnector) -> void:
	var region = conn.outside_bbox
	# Clamp region size if exceeding max
	region = _clamp_bbox(region, MAX_NODE_BBOX_SIZE)
	# Validate region does not heavily intersect existing geometry
	if not _is_region_valid(region):
		return
	var size = region.end_pos - region.start_pos
	if size.x >= MIN_NODE_BBOX_SIZE.x and size.y >= MIN_NODE_BBOX_SIZE.y and size.z >= MIN_NODE_BBOX_SIZE.z:
		# Spawn new room node
		var new_node = LevelNode.new("room", region)
		# Connect both ends
		conn.attach_node(new_node)
		for nc in new_node.connectors:
			if nc.inside_bbox.start_pos == region.start_pos and nc.inside_bbox.end_pos == region.end_pos:
				nc.attach_node(current_node)
				break
		nodes.append(new_node)
		if new_node.get_active_connectors().size() > 0:
			active_nodes.append(new_node)
		add_child(new_node)
		assign_node_to_chunks(new_node)
		# Offload physics/build workload
		var th = Thread.new()
		th.start(self, "_thread_generate_physics", new_node)
	else:
		# Fallback dead-end
		var dead = LevelNode.new("dead_end", region)
		nodes.append(dead)
		add_child(dead)
		assign_node_to_chunks(dead)
		# no active connectors, so automatically a leaf

func _is_region_valid(region:BBox) -> bool:
	# Check each overlapping chunk
	for key in _get_chunks_for_bbox(region):
		if chunks.has(key):
			for other in chunks[key]:
				if _bbox_intersects(other.bbox, region):
					var vol = _intersection_volume(other.bbox, region)
					if vol > SAFE_MARGIN_VOLUME:
						return false
	return true


func _get_closest_active_to_player() -> LevelNode:
    var ppos = GB_PlayerParams.
    var closest:LevelNode = null
    var best = INF
    for n in active_nodes:
        var d = n.bbox.start_pos.linear_interpolate(n.bbox.end_pos, 0.5).distance_to(ppos)
        if d < best and d <= MAX_GENERATION_DISTANCE:
            best = d
            closest = n
    if closest:
        active_nodes.erase(closest)
    return closest

func prune_chunks() -> void:
    var player = get_node("/root/Player")
    var ppos = player.global_transform.origin
    var to_remove = []
    for key in chunks.keys():
        var center = (key * CHUNK_SIZE) + CHUNK_SIZE * 0.5
        if center.distance_to(ppos) > MAX_PLAYER_TO_CHUNK_DISTANCE:
            for node in chunks[key]:
                _free_node(node)
            to_remove.append(key)
    for k in to_remove:
        chunks.erase(k)

func _free_node(node:LevelNode) -> void:
    if node.get_parent():
        node.get_parent().remove_child(node)
    nodes.erase(node)
    active_nodes.erase(node)
    node.queue_free()

# Offloaded thread for heavy scene instantiation
func _thread_generate_physics(node:LevelNode) -> void:
    # TODO: instantiate meshes, static bodies, colliders, children objects
    pass