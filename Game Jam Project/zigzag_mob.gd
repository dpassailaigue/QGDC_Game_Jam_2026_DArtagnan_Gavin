extends "res://mob.gd"

# Zigzags towards the player: walks 45 degrees off to one side, and the
# Timer flips which side every second.

var offset = PI / 4


func _init():
	default_color = Color.BLUE


func _get_move_direction() -> Vector2:
	return super().rotated(offset)


func _on_timer_timeout() -> void:
	offset = -offset
