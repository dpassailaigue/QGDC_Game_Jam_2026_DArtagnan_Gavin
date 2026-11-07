extends Area2D

const SPEED = 10000
const RANGE = 12000
# Chain targets must be within the gun's range of the player, so chains stay on screen
const MAX_TARGET_RANGE = preload("res://gun.gd").MAX_RANGE

var travelled_distance = 0
var hit_bodies := {} # bodies this bullet already hit, so nothing gets hit twice

@onready var game = get_node("/root/Game")
@onready var player = get_node("/root/Game/Player")
@onready var chain = game.chain_length

func _physics_process(delta):
	var motion = Vector2.RIGHT.rotated(rotation) * SPEED * delta

	# The bullet moves ~170px per frame, so it can jump clean over an enemy
	# between frames. Raycast along this frame's path to catch those hits.
	var hit = _sweep(global_position, global_position + motion)
	if hit:
		global_position = hit.position
		_hit(hit.collider)
		return # direction may have changed (chaining); continue next frame

	position += motion
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _sweep(from: Vector2, to: Vector2) -> Dictionary:
	var query = PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	var exclude: Array[RID] = [player.get_rid()]
	for body in hit_bodies:
		if is_instance_valid(body):
			exclude.append(body.get_rid())
	query.exclude = exclude
	return get_world_2d().direct_space_state.intersect_ray(query)

func find_enemy():
	var enemies_in_range = %EnemyScanner.get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF
	for body in enemies_in_range:
		if body in hit_bodies:
			continue
		if player.global_position.distance_to(body.global_position) > MAX_TARGET_RANGE:
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist < min_distance and dist >= 100:
			closest_body = body
			min_distance = dist
	if closest_body:
		look_at(closest_body.global_position)

func _on_body_entered(body):
	_hit(body)

func _hit(body):
	if body == player or body in hit_bodies or is_queued_for_deletion():
		return
	hit_bodies[body] = true
	chain -= 1
	if chain <= 0:
		queue_free()
	else:
		find_enemy()
	if body.has_method("apply_hit_effects"):
		body.apply_hit_effects()
	if body.has_method("take_damage"):
		body.take_damage(game.damage)
