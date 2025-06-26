# res://Source/WorldGenerators/LevelGraph.gd
extends Node
class_name LevelGraph
# This class should provide general api for graph generation algorithm.
# It defines most of the graph functionality except for exact node generation. 
# This should be further defined by each level class.


# Configuration constants
var CHUNK_SIZE:Vector3 = Vector3(100, 100, 100)
var MAX_NODE_BBOX_SIZE:Vector3i = Vector3i(50, 50, 50)
var MIN_NODE_BBOX_SIZE:Vector3i = Vector3i(3, 3, 3)
var MAX_NODE_GENERATION_DISTANCE:int = 200
var MAX_NODE_RENDERING_DISTANCE:int = 1000
var SAFE_MARGIN_VOLUME:float = 5

# State         
var active_nodes: Array = []       # Nodes with active connectors
var chunks: Dictionary = {}        # grid_pos (Vector3i) -> Chunk

class Chunk:
	var grid_pos: Vector3i               # integer grid coordinates
	var center: Vector3 = Vector3.ZERO  # world-space center
	var bbox: BBox = null               # chunk bounds
	var nodes: Array = []
	var size: Vector3 = Vector3.ONE

	func _init(_grid_pos: Vector3i, _size: Vector3) -> void:
		# Store integer grid coordinates
		grid_pos = _grid_pos
		var _grid_pos_f = Vector3(_grid_pos.x, _grid_pos.y, _grid_pos.z)
		# Compute world center from grid
		center = _grid_pos_f * _size
		# Build bounding box around center
		var half = _size * 0.5
		nodes = []
		bbox = BBox.new(center - half, center + half)

# Initialized graph generation parameters. Specified by each level
func _init(chunk_size,max_node_bbox_size,min_node_bbox_size,
		max_generation_distance,max_node_rendering_distance,safe_margin_volume) -> void:
	CHUNK_SIZE = chunk_size
	MAX_NODE_BBOX_SIZE = max_node_bbox_size
	MIN_NODE_BBOX_SIZE = min_node_bbox_size
	MAX_NODE_GENERATION_DISTANCE = max_generation_distance
	MAX_NODE_RENDERING_DISTANCE = max_node_rendering_distance
	SAFE_MARGIN_VOLUME = safe_margin_volume


func _ready() -> void:
	# Initialize generation
	initialize_chunk()
	generate_initial_node()

func initialize_chunk(grid_pos: Vector3i = Vector3i.ZERO) -> void:
	# Create initial chunk at grid (0,0,0)
	var initial = Chunk.new(grid_pos,CHUNK_SIZE )
	chunks[grid_pos] = initial
    
func generate_initial_node(pos: Vector3 = Vector3.ZERO) -> void:
    # Create node centered in the chunk
	var world_center = pos * CHUNK_SIZE
	var init_bbox = BBox.new(world_center - (MIN_NODE_BBOX_SIZE * 0.5), world_center + (MIN_NODE_BBOX_SIZE * 0.5))
	var start_node = LevelNode.new(init_bbox)
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
				var gp = Vector3i(int(x), int(y), int(z))
				var chunk = null
				# Create chunk if not exists
				if not chunks.has(gp):
					initialize_chunk(gp)
				else:
					chunk = chunks[gp]
				chunk.nodes.append(node)
				node.assign_parent_chunk(gp)

# Iterates through active nodes and generates on them
func process_active_nodes() -> void:
	var current_active_nodes_amount = active_nodes.size()
	for current_active_node_idx in range(current_active_nodes_amount):
		var current_active_node = active_nodes[current_active_node_idx]
		generate_on_active_node(current_active_node)


# Process each active connector on a node to spawn new nodes
func generate_on_active_node(current_active_node: LevelNode) -> void:
	var player_pos = GB_PlayerParams.player.position
	# Skip entire node if it's too far from the player
	if current_active_node.bbox.center().distance_to(player_pos) > MAX_NODE_GENERATION_DISTANCE:
		return
	for conn in current_active_node.get_active_connectors():
		# 1) Compute the free region on the "other side" of this connector
		var available_bbox = estimate_available_bbox_for_connector(current_active_node, conn, chunks)

		# 2) Decide whether to spawn a full node or fallback
		if available_bbox.width() < MIN_NODE_BBOX_SIZE.x \
		or available_bbox.height() < MIN_NODE_BBOX_SIZE.y \
		or available_bbox.depth() < MIN_NODE_BBOX_SIZE.z:
			# Region too small → fallback
			get_parent().generate_fallback_node(conn, available_bbox)
		else:
			# Generate a normal node
			var new_bbox = get_parent().define_node_bbox(args)
			generate_node(new_bbox, conn)
			get_parent().define_node_conectors(new_node)
			get_parent().thread_generate_physics(new_node)


func estimate_available_bbox_for_connector(node: LevelNode,  connector: LevelNodeConnector, _chunks: Dictionary) -> BBox:
	# 1) Build initial available_bbox as union of all parent‐chunk bboxes
	var available: BBox = null
	for chunk_pos in node.parent_chunks_pos:
		var chunk_bbox : BBox = _chunks[chunk_pos].bbox
		if available == null:
			available = BBox.new(chunk_bbox.start_pos, chunk_bbox.end_pos)
		else:
			available.extend(chunk_bbox)
	# 2) Subtract out _other_ active‐connector bboxes
	var my_bbox = connector._compute_unactive_bbox()
	for other in node.get_active_connectors():
		if other == connector:
			continue
		var other_bbox = other._compute_unactive_bbox()
		if BBox.are_intersecting(available, other_bbox):
			BBox.shrink_around(available, other_bbox, my_bbox)
	# 3) Subtract out every node’s bbox in those chunks
	var all_nodes := []
	for chunk_pos in node.parent_chunks_pos:
		all_nodes.append_array(_chunks[chunk_pos].nodes)
	for n in all_nodes:
		var nb: BBox = n.bbox
		if BBox.are_intersecting(available, nb):
			BBox.shrink_around(available, nb, my_bbox)
		# 4) Bail out if we run out of space
		if available.width() < MIN_NODE_BBOX_SIZE.x \
		or available.height() < MIN_NODE_BBOX_SIZE.y \
		or available.depth() < MIN_NODE_BBOX_SIZE.z:
			break
	return available

# Remove distant chunks by freeing их ноды, но только border-ноды вызывают обновление active_nodes
func prune_chunks() -> void:
	var player_pos = GB_PlayerParams.player.position
	# проходим по всем чанкам
	for grid_pos in chunks.keys():
		var chunk = chunks[grid_pos]
		if chunk.center.distance_to(player_pos) > MAX_NODE_RENDERING_DISTANCE:
			# удаляем все ноды в чанке
			prune_chunk(chunk)
	return

func prune_chunk(chunk: Chunk) -> void:
	for node: LevelNode in chunk.nodes:
		if node.is_border_node():
			_update_neighboors_on_node_delete(node)
			_free_node(node)
		else:
			# interior node: free без обновления active_nodes
			_free_node(node)
	# очищаем список
	chunk.nodes.clear()

# Обновление статуса соседей для удаляемой ноды
func _update_neighboors_on_node_delete(node: LevelNode) -> void:
	# Для каждого коннектора проверяем, есть ли на другой стороне ещё нода
	for conn in node.connectors:
		if conn.connector_regions[1] != null and conn.connector_regions[2] != null:
			var reg1 = conn.connector_regions[1]
			var reg2 = conn.connector_regions[2]
			# Выбираем «выживший» регион
			var surviving_region = reg2 if reg1.node == node else reg1
			var neighbor = surviving_region.node
			if neighbor and not active_nodes.has(neighbor):
				active_nodes.append(neighbor)


func _free_node(node: LevelNode) -> void:
	# Удаляем ноду из сцены и active_nodes
	if node.get_parent():
		node.get_parent().remove_child(node)
	active_nodes.erase(node)
	node.queue_free()
