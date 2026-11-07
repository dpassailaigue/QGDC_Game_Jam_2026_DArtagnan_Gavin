extends Area2D

# Max distance (from the player) an enemy can be targeted at. The screen is
# 1920x1080 with the camera on the player, so 500 keeps targets on screen.
const MAX_RANGE := 500.0

var target: Node2D = null

@onready var player: Node2D = get_parent()


func _process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	var closest_body = null
	var min_distance = MAX_RANGE
	for body in enemies_in_range:
		var dist = player.global_position.distance_to(body.global_position)
		if dist <= min_distance:
			closest_body = body
			min_distance = dist
	target = closest_body
	if target:
		look_at(target.global_position)


func shoot():
	# Only shoot when an enemy is within range
	if not is_instance_valid(target):
		return
	const BULLET = preload("res://bullet_2d.tscn")
	var new_bullet = BULLET.instantiate()
	# Fire from the player's center so enemies between the gun and the player still get hit
	var origin := player.global_position
	var angle := origin.direction_to(target.global_position).angle()
	player.get_parent().add_child(new_bullet)
	new_bullet.global_position = origin
	new_bullet.global_rotation = angle


func _on_timer_timeout() -> void:
	shoot()
