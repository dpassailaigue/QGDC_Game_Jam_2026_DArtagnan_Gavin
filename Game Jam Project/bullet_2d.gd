extends Area2D

const SPEED = 10000
# The bullet starts at the player (centre of the screen), and the screen corner is
# ~1100px away, so missed shots vanish at the screen edge instead of flying
# 12000px and hitting enemies far off-screen.
const RANGE = 1100
# Chain targets must be within the gun's range of the player, so chains stay on screen
const MAX_TARGET_RANGE = preload("res://gun.gd").MAX_RANGE

var travelled_distance = 0
# Bodies this bullet already hit, so nothing gets hit twice. Stored as
# instance IDs / RIDs, NOT the nodes themselves: a Dictionary keyed by nodes
# that later get freed can hang or crash Godot when it's read again.
var hit_ids := {}
var ray_exclude: Array[RID] = []

@onready var game = get_node("/root/Game")
@onready var player = get_node("/root/Game/Player")
@onready var chain = game.chain_length

func _ready():
	ray_exclude.append(player.get_rid())

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
	query.exclude = ray_exclude
	return get_world_2d().direct_space_state.intersect_ray(query)

func find_enemy():
	var enemies_in_range = %EnemyScanner.get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF
	for body in enemies_in_range:
		if hit_ids.has(body.get_instance_id()):
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
	if body == player or hit_ids.has(body.get_instance_id()) or is_queued_for_deletion():
		return
	hit_ids[body.get_instance_id()] = true
	ray_exclude.append(body.get_rid())
	chain -= 1
	if chain <= 0:
		queue_free()
	else:
		find_enemy()
	if body.has_method("apply_hit_effects"):
		body.apply_hit_effects()
	if body.has_method("take_damage"):
		body.take_damage(game.damage)
