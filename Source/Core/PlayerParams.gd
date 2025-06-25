# PlayerParams.gd
extends Node
class_name PlayerParams

# type-hint to your Player class
var player: Player = null

func get_player_position() -> Vector3:
	if player != null:
		return player.global_position
	else:
		return Vector3.ZERO