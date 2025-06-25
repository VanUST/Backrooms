extends CharacterBody3D
class_name Player

@onready var anim: MaleAnimator = $male_asset
@onready var head_camera: Camera3D = $Camera3D

# ————— Character Parameters —————
@export var speed: float = 3.0 

@export var sprint_mul: float = 1.75 

@export var jump_vel: float = 2.5 

@export var mouse_sensitivity: float = 0.002 

@export var blend_time: float = 0.6 

# ————— Setters & Getters —————
func set_speed(v: float) -> void:       speed = v
func get_speed() -> float:              return speed

func set_sprint_mul(v: float) -> void:  sprint_mul = v
func get_sprint_mul() -> float:         return sprint_mul

func set_jump_vel(v: float) -> void:    jump_vel = v
func get_jump_vel() -> float:           return jump_vel

func set_mouse_sensitivity(v: float) -> void:  mouse_sensitivity = v
func get_mouse_sensitivity() -> float:          return mouse_sensitivity

func set_blend_time(v: float) -> void:  blend_time = v
func get_blend_time() -> float:         return blend_time

# gravity & look state
var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
var yaw: float = 0.0
var pitch: float = 0.0   # clamped −π/2…π/2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GB_PlayerParams.player = self

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch  = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		rotation.y = yaw
		head_camera.rotation.x = pitch
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_animation()

func _handle_movement(delta: float) -> void:
	var dir = Vector3.ZERO
	dir.z -= Input.get_action_strength("move_forward")  - Input.get_action_strength("move_backward")
	dir.x -= Input.get_action_strength("move_left")     - Input.get_action_strength("move_right")
	if dir != Vector3.ZERO:
		dir = (global_transform.basis * dir).normalized()

	# calculate if we're moving forward for sprint
	var forward_vec := -global_transform.basis.z
	var forward_dot := forward_vec.dot(dir)
	var is_sprinting = Input.is_action_pressed("sprint") and forward_dot > 0.0

	# apply horizontal velocity
	var speed_multiplier = sprint_mul if is_sprinting else 1.0 
	var current_base_speed = speed * speed_multiplier
	var target_vel = dir * current_base_speed
	velocity.x = target_vel.x
	velocity.z = target_vel.z

	# jump vs gravity
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_vel
			anim.jump_start(1.0, blend_time)
	else:
		velocity.y -= grav * delta

	move_and_slide()

func _update_animation() -> void:
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	var is_in_air = not is_on_floor()
	var is_sprinting = Input.is_action_pressed("sprint") \
					and horiz_speed > 0.0 \
					and (-global_transform.basis.z).dot(Vector3(velocity.x, 0, velocity.z)) > 0.0

	if is_in_air:
		anim.in_air(1.0, blend_time)
	elif horiz_speed < 0.1:
		anim.idle(1.0, blend_time)
	else:
		# normalize animation speed to current movement vs base
		var speed_multiplier = sprint_mul if is_sprinting else 1.0 
		var current_base_speed = speed * speed_multiplier
		var speed_ratio = horiz_speed / current_base_speed
		if is_sprinting:
			anim.run(speed_ratio, blend_time)
		else:
			anim.walk(speed_ratio, blend_time)
