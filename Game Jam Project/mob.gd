extends CharacterBody2D

signal died

const BURN_TICK_INTERVAL := 0.5
const SLOW_MULTIPLIER := 0.75 # flat 25% speed decrease
const BURN_COLOR := Color(1.0, 0.55, 0.3)
const SLOW_COLOR := Color(0.55, 0.75, 1.0)

var speed = randf_range(200, 300)
var health = 3.0
var dead := false
var xp_value := 1 # XP the player gets for killing this enemy
# The boss (boss.tscn/boss.gd) and the stronger enemy (big_mob.tscn/big_mob.gd)
# are their own scenes now.

# Status effects
var burn_time_left := 0.0
var burn_damage_per_tick := 0.0
var burn_tick_timer := 0.0
var slow_time_left := 0.0

@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")
@onready var slime = _find_slime() # cached: looked up every frame otherwise

# Tint when no status effect is active (mob variants set their own colour)
@export var default_color := Color.WHITE


# The slime visual this enemy animates. Variants with a different visual
# (e.g. big_mob's BigSlime) override this.
func _find_slime() -> Node2D:
	return %Slime


func _ready():
	add_to_group("mobs")
	slime.play_walk()


func _physics_process(delta):
	_process_status_effects(delta)
	if dead:
		return
	
	var current_speed = speed
	if slow_time_left > 0.0:
		current_speed *= SLOW_MULTIPLIER
	velocity = _get_move_direction() * current_speed
	move_and_slide()


# Walk straight at the player. Mob variants override this for other movement.
func _get_move_direction() -> Vector2:
	return global_position.direction_to(player.global_position)


func _spawn_smoke(pos: Vector2, fiery := false):
	game.spawn_smoke(pos, fiery)


# Whether this death is an explosion (fiery smoke instead of grey): a kill
# while the player has the explode-on-kill upgrade. Exploding slimes always are.
func _death_is_explosion(counts_as_kill: bool) -> bool:
	return counts_as_kill and game.explode_level > 0


func _process_status_effects(delta):
	if slow_time_left > 0.0:
		slow_time_left -= delta

	if burn_time_left > 0.0:
		burn_time_left -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= BURN_TICK_INTERVAL:
			burn_tick_timer -= BURN_TICK_INTERVAL
			take_damage(burn_damage_per_tick)

	# Tint: orange while burning, blue while slowed (only touch it on change)
	var tint := default_color
	if burn_time_left > 0.0:
		tint = BURN_COLOR
	elif slow_time_left > 0.0:
		tint = SLOW_COLOR
	if slime.modulate != tint:
		slime.modulate = tint


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
	slime.play_hurt()
	health -= amount

	if health <= 0:
		die()

# counts_as_kill = false for deaths the player didn't cause (e.g. an exploding
# slime blowing itself up): no XP, and no "explode on kill" upgrade trigger.
func die(counts_as_kill := true):
	dead = true
	remove_from_group("mobs")
	_spawn_smoke(global_position, _death_is_explosion(counts_as_kill))
	if not counts_as_kill:
		queue_free()
		return
	died.emit()
	if game.explode_level > 0:
		# Deferred so chain reactions don't recurse deeply in one call stack
		game.explode_at.call_deferred(global_position)
	queue_free()
