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
# Set by the gun: the bullet spawns at the staff tip, so on its first frame it
# also checks the gap between the player's centre and the tip for enemies
var sweep_from = null

# The bullet itself is invisible and only finds what gets hit, almost
# instantly. What you see is a lightning bolt per link (staff -> enemy, then
# enemy -> enemy for each chain), each launching when the previous one lands.
# Damage is dealt by the bolt when it reaches its enemy.
const LIGHTNING_BOLT = preload("res://lightning_bolt.tscn")
var link_start = null # where the current link's bolt starts (set on 1st frame)
var prev_bolt = null # the previous link's bolt; the next one launches when it lands
var link_source = null # what the current link's bolt comes from (player, then enemies)

@onready var game = get_node("/root/Game")
@onready var player = get_node("/root/Game/Player")
@onready var chain = game.chain_length

func _ready():
	ray_exclude.append(player.get_rid())

func _physics_process(delta):
	if link_start == null:
		link_start = global_position # the staff tip
	if sweep_from != null:
		var close_hit = _sweep(sweep_from, global_position)
		sweep_from = null
		if close_hit:
			global_position = close_hit.position
			_hit(close_hit.collider)
			return

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
		# Missed everything: the bolt fizzles out where the shot ended. After a
		# hit with no enemy left to chain to, the lightning just ends there.
		if hit_ids.is_empty():
			_spawn_bolt(null)
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
	# The bolt for this link deals the damage when it visually lands
	_spawn_bolt(body)
	chain -= 1
	if chain <= 0:
		queue_free()
	else:
		find_enemy()

# Bolt from the current link's start to here; the next link starts here
func _spawn_bolt(target: Node) -> void:
	if link_start == null:
		link_start = global_position
	if prev_bolt == null:
		link_source = player # first link comes out of the staff
	var bolt = LIGHTNING_BOLT.instantiate()
	game.add_child(bolt)
	# A previous enemy that's already gone just leaves the start where it was
	var source = link_source if is_instance_valid(link_source) else null
	bolt.setup(link_start, global_position, target, prev_bolt, source)
	link_start = global_position
	link_source = target
	prev_bolt = bolt
