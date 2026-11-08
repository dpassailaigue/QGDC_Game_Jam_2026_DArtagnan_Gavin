extends CharacterBody2D

signal died

const BURN_TICK_INTERVAL := 0.5
const SLOW_MULTIPLIER := 0.75 # flat 25% speed decrease

var speed = randf_range(200, 300)
var health = 3.0
var dead := false

# Boss settings (set is_boss before adding the mob to the scene)
const BOSS_SCALE := 1.0
const BOSS_HEALTH_MULTIPLIER := 500.0
const TREE_CRUSH_RADIUS := 150.0
var is_boss := true

# Status effects
var burn_time_left := 0.0
var burn_damage_per_tick := 0.0
var burn_tick_timer := 0.0
var slow_time_left := 0.0

# Dash settings
const DASH_SPEED := 1100.0
const DASH_DURATION := 0.35
const DASH_COOLDOWN := 5.0
const DASH_WINDUP := 0.6
const DASH_DAMAGE := 15.0

var dash_cooldown_timer := 3.0
var dash_timer := 0.0
var dash_windup_timer := 0.0
var dash_direction := Vector2.ZERO

# AOE settings
const AOE_RADIUS := 300.0
const AOE_DAMAGE := 20.0
const AOE_COOLDOWN := 8.0
const AOE_WINDUP := 1.2

var aoe_cooldown_timer := 5.0
var aoe_windup_timer := 0.0

# Attack states
enum AttackState {
	CHASING,
	DASH_WINDUP,
	DASHING,
	AOE_WINDUP
}

var attack_state = AttackState.CHASING

@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")


func _ready():
	add_to_group("mobs")
	%BossSlime.play_walk()
	if is_boss:
		health *= BOSS_HEALTH_MULTIPLIER
		%BossSlime.scale *= BOSS_SCALE
		$CollisionShape2D.scale *= BOSS_SCALE
		$CollisionShape2D.position *= BOSS_SCALE
		# Walk straight through trees (they get crushed instead)
		for tree in get_tree().get_nodes_in_group("environment"):
			add_collision_exception_with(tree)


func _physics_process(delta):
	_process_status_effects(delta)
	if dead:
		return
	if is_boss:
		_crush_nearby_trees()
		_process_boss_attacks(delta)
	else:
		
		var current_speed = speed
		if slow_time_left > 0.0:
			current_speed *= SLOW_MULTIPLIER
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * current_speed
	move_and_slide()

func _process_boss_attacks(delta):
	dash_cooldown_timer -= delta
	aoe_cooldown_timer -= delta

	match attack_state:
		AttackState.CHASING:
			var current_speed = speed
			if slow_time_left > 0.0:
				current_speed *= SLOW_MULTIPLIER
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * current_speed

			if aoe_cooldown_timer <= 0.0:
				_start_aoe()
			elif dash_cooldown_timer <= 0.0:
				_start_dash()

		AttackState.DASH_WINDUP:
			velocity = Vector2.ZERO
			dash_windup_timer -= delta

			if dash_windup_timer <= 0.0:
				attack_state = AttackState.DASHING
				dash_timer = DASH_DURATION

		AttackState.DASHING:
			velocity = dash_direction * DASH_SPEED
			dash_timer -= delta

			if dash_timer <= 0.0:
				attack_state = AttackState.CHASING

		AttackState.AOE_WINDUP:
			velocity = Vector2.ZERO
			aoe_windup_timer -= delta
			queue_redraw()

			if aoe_windup_timer <= 0.0:
				_execute_aoe()
				attack_state = AttackState.CHASING
				queue_redraw()

func _start_dash():
	attack_state = AttackState.DASH_WINDUP
	dash_windup_timer = DASH_WINDUP
	dash_cooldown_timer = DASH_COOLDOWN

	dash_direction = global_position.direction_to(player.global_position)

func _start_aoe():
	attack_state = AttackState.AOE_WINDUP
	aoe_windup_timer = AOE_WINDUP
	aoe_cooldown_timer = AOE_COOLDOWN
	velocity = Vector2.ZERO
	queue_redraw()

func _execute_aoe():
	var distance = global_position.distance_to(player.global_position)

	if distance <= AOE_RADIUS:
		# take_damage (not health -=) so the health bar updates and the
		# player actually dies if this finishes them off
		player.take_damage(AOE_DAMAGE)

	_spawn_smoke(global_position)

func _crush_nearby_trees():
	for tree in get_tree().get_nodes_in_group("environment"):
		if tree.is_queued_for_deletion():
			continue
		if global_position.distance_to(tree.global_position) <= TREE_CRUSH_RADIUS:
			_spawn_smoke(tree.global_position)
			tree.queue_free()

func _draw():
	if attack_state == AttackState.AOE_WINDUP:
		var progress = 1.0 - (aoe_windup_timer / AOE_WINDUP)

		# Transparent red warning area
		draw_circle(
			Vector2.ZERO,
			AOE_RADIUS,
			Color(1.0, 0.0, 0.0, 0.15 + progress * 0.25)
		)

		# Red outline
		draw_arc(
			Vector2.ZERO,
			AOE_RADIUS,
			0,
			TAU,
			64,
			Color.RED,
			5.0
		)


func _spawn_smoke(pos: Vector2):
	var smoke = preload("res://smoke_explosion/smoke_explosion.tscn").instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = pos


func _process_status_effects(delta):
	if slow_time_left > 0.0:
		slow_time_left -= delta

	if burn_time_left > 0.0:
		burn_time_left -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= BURN_TICK_INTERVAL:
			burn_tick_timer -= BURN_TICK_INTERVAL
			take_damage(burn_damage_per_tick)

	# Tint: orange while burning, blue while slowed
	if burn_time_left > 0.0:
		%BossSlime.modulate = Color(1.0, 0.55, 0.3)
	elif slow_time_left > 0.0:
		%BossSlime.modulate = Color(0.55, 0.75, 1.0)
	else:
		%BossSlime.modulate = Color.WHITE


# Called by bullets on hit, applies whichever on-hit upgrades the player owns.
func apply_hit_effects():
	if game.fire_level > 0:
		burn_time_left = game.get_burn_duration()
		burn_damage_per_tick = game.get_burn_damage_per_tick()
		burn_tick_timer = 0.0
	if game.slow_level > 0:
		slow_time_left = game.get_slow_duration()


func take_damage(amount: float):
	if dead:
		return
	%BossSlime.play_hurt()
	health -= amount

	if health <= 0:
		die()

func die():
	dead = true
	remove_from_group("mobs")
	died.emit()
	_spawn_smoke(global_position)
	if game.explode_level > 0:
		# Deferred so chain reactions don't recurse deeply in one call stack
		game.explode_at.call_deferred(global_position)
	queue_free()
