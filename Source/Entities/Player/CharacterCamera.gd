extends Camera3D

@onready var head_pivot : BoneAttachment3D = $"../male_asset/GeneralSkeleton/HeadSocket"    # BoneAttachment3D

## --- Tuning knobs ----------------------------------------------------------
@export_range(0.01, 1.0, 0.01) var position_smooth_time := 0.01
@export var copy_head_rotation := false   # set true if you also want rotation smoothed
# ---------------------------------------------------------------------------

var _offset_local  : Vector3            # camera offset in head space
var _smoothed_pos  : Vector3            # running smoothed world position
var _smoothed_rot  : Quaternion         # running smoothed orientation (optional)

func _ready() -> void:
	print_tree()
	_offset_local = head_pivot.to_local(global_position)
	_smoothed_pos = global_position
	_smoothed_rot = global_basis.get_rotation_quaternion()

func _physics_process(delta: float) -> void:
	# --- target transform ---------------------------------------------------
	var target_pos : Vector3     = head_pivot.to_global(_offset_local)
	var target_rot : Quaternion  = head_pivot.global_basis.get_rotation_quaternion()

	# --- exponential smoothing factor (0‥1) --------------------------------
	# α = 1 - e^(−Δt / τ)
	var alpha := 1.0 - pow(2.7182818, -delta / position_smooth_time)

	# --- smooth position ----------------------------------------------------
	_smoothed_pos = _smoothed_pos.lerp(target_pos, alpha)
	global_position = _smoothed_pos

	# --- smooth rotation (optional) ----------------------------------------
	if copy_head_rotation:
		_smoothed_rot = _smoothed_rot.slerp(target_rot, alpha)
		global_basis = Basis(_smoothed_rot)
