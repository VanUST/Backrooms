extends Node3D
class_name ShapesGenerator
# CLASS FOR BASIC SHAPES GENERATION

const COLLISION_MAPPING := {
	"Entities":1,
	"World":2,
}

static func gen_box(
			start_pos: Vector3,
			end_pos: Vector3,
			parent_node: Node,
			texture: Texture = null,
			material_override: Material = null,
			uv_scale: Vector3 = Vector3.ZERO,
			collision_layer_names: Array = ["World"],
			collision_mask_names: Array = ["Entities"]
		) -> Dictionary:
	# fallback parent
	if not parent_node:
		push_warning("GEN RECTANGLE: No parent node, aborting.")
		return {"mesh": null, "collision": null}

	# size & center
	var size_vec = end_pos - start_pos
	var center = (start_pos + end_pos) * 0.5

	# —— MeshInstance3D setup —— #
	var mesh_inst = MeshInstance3D.new()
	var box_mesh  = BoxMesh.new()
	box_mesh.size = Vector3(abs(size_vec.x), abs(size_vec.y), abs(size_vec.z))
	mesh_inst.mesh = box_mesh

	if material_override:
		mesh_inst.material_override = material_override
	elif texture:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = texture
		if uv_scale == Vector3.ZERO:
			uv_scale = size_vec
		mat.uv1_scale = uv_scale
		mesh_inst.material_override = mat
		
	else:
		push_warning("GEN RECTANGLE: No material or texture provided, aborting.")
		return {"mesh": null, "collision": null}

	mesh_inst.global_transform.origin = center
	parent_node.add_child(mesh_inst)

	# —— Collision body & shape —— #
	# create the actual physics body
	var body = StaticBody3D.new()
	# body.name = "GeneratedCollision"
	body.global_transform.origin = center

	# set layers & masks
	body.set_collision_layer_value(1,false) #remove default layers
	body.set_collision_mask_value(1,false)
	for layer_name in collision_layer_names:
		body.set_collision_layer_value(COLLISION_MAPPING.get(layer_name), true)
	for mask_name in collision_mask_names:
		body.set_collision_mask_value(COLLISION_MAPPING.get(mask_name), true)

	# create & attach the shape
	var col_shape = CollisionShape3D.new()
	var box_col   = BoxShape3D.new()
	box_col.size  = Vector3(abs(size_vec.x), abs(size_vec.y), abs(size_vec.z))
	col_shape.shape = box_col
	body.add_child(col_shape)

	parent_node.add_child(body)

	return {"mesh": mesh_inst, "collision": body}
