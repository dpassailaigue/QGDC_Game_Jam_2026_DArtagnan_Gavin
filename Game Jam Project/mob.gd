extends CharacterBody2D

signal died

const BURN_TICK_INTERVAL := 0.5
const SLOW_MULTIPLIER := 0.75 # flat 25% speed decrease

var speed = randf_range(200, 300)
var health = 3.0
var dead := false

# Status effects
var burn_time_left := 0.0
var burn_damage_per_tick := 0.0
var burn_tick_timer := 0.0
var slow_time_left := 0.0

@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")


func _ready():
	add_to_group("mobs")
	%Slime.play_walk()


func _physics_process(delta):
	_process_status_effects(delta)
	if dead:
		return

	var current_speed = speed
	if slow_time_left > 0.0:
		current_speed *= SLOW_MULTIPLIER
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * current_speed
	move_and_slide()


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
		%Slime.modulate = Color(1.0, 0.55, 0.3)
	elif slow_time_left > 0.0:
		%Slime.modulate = Color(0.55, 0.75, 1.0)
	else:
		%Slime.modulate = Color.WHITE


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
	%Slime.play_hurt()
	health -= amount

	if health <= 0:
		die()


func die():
	dead = true
	remove_from_group("mobs")
	var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
	var smoke = smoke_scene.instantiate()
	died.emit()
	get_parent().add_child(smoke)
	smoke.global_position = global_position
	if game.explode_level > 0:
		# Deferred so chain reactions don't recurse deeply in one call stack
		game.explode_at.call_deferred(global_position)
	queue_free()
