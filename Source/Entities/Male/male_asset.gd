extends Node3D
class_name MaleAnimator

@onready var player: AnimationPlayer = $GeneralSkeleton/AnimationPlayer

var _current := ""  # remember last state

# -- public API ----------------------------------------------------------
# Each method now lets you override playback speed and blend time.
func idle(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Idle", blend, speed)

func walk(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Walk", blend, speed)

func run(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Sprint", blend, speed)

func in_air(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Jump", blend, speed)

func jump_start(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Jump_Start", blend, speed)

func jump_land(speed: float = 1.0, blend: float = 0.4) -> void:
	_travel_if_needed("humanoid_anim/Jump_Land", blend, speed)

# -- internals -----------------------------------------------------------
# Now accepts both a custom blend time and playback speed.
func _travel_if_needed(anim_name: String, blend: float = 0.4, speed: float = 1.0) -> void:
	if anim_name == _current:
		return
	_current = anim_name
	player.play(anim_name, blend, speed)
