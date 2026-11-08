extends Area2D

# Max distance (from the player) an enemy can be targeted at. The screen is
# 1920x1080 with the camera on the player: 750 reaches well toward the sides,
# but slightly past the top/bottom edges (540px from the player).
# The detection circle in gun.tscn must be at least this big.
const MAX_RANGE := 750.0

var target: Node2D = null

@onready var player: Node2D = get_parent()
@onready var game = get_node("/root/Game")
@onready var base_fire_interval: float = $Timer.wait_time


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
	# Shots come out of the wizard's staff tip. The bullet also sweeps from the
	# player's centre to the tip, so enemies hugging the player still get hit.
	var origin: Vector2 = player.get_staff_tip_position()
	var angle := origin.direction_to(target.global_position).angle()
	new_bullet.sweep_from = player.global_position
	player.get_parent().add_child(new_bullet)
	new_bullet.global_position = origin
	new_bullet.global_rotation = angle


func _on_timer_timeout() -> void:
	shoot()
	# Picks up attack speed upgrades from the next shot onwards
	$Timer.wait_time = base_fire_interval / game.get_attack_speed_multiplier()
