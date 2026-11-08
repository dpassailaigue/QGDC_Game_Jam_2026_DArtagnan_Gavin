extends "res://mob.gd"

# Rushes the player. Once the player is inside its blast radius it slows
# down, and after the Timer (2s) it explodes on its own (not a kill: no XP).
# If the player kills it first it still explodes (and counts as a kill), so
# shooting it early can clear out nearby enemies.
# Either way, the explosion hurts the player and other enemies in range.

const EXPLOSION_DAMAGE := 10.0 # to the player
const ENEMY_EXPLOSION_DAMAGE := 3.0 # to other enemies (a normal slime has 3 health)
const FUSE_SPEED := 150.0


func _init():
	default_color = Color.RED
	speed = randf_range(400, 500)


func _on_explosion_area_body_entered(body: Node2D) -> void:
	# Only light the fuse once, so walking in and out can't keep resetting it
	if body == player and $Timer.is_stopped():
		speed = FUSE_SPEED
		$Timer.start()


func _on_timer_timeout() -> void:
	if dead:
		return
	die(false) # blew itself up, so it doesn't count as a kill


func die(counts_as_kill := true):
	_explode()
	super(counts_as_kill)


func _explode():
	if $ExplosionArea.overlaps_body(player):
		player.take_damage(EXPLOSION_DAMAGE)
	var blast_shape: CollisionShape2D = $ExplosionArea/CollisionShape2D
	# Leave our own group first so the blast doesn't hit this slime again
	remove_from_group("mobs")
	game.damage_mobs_in_radius.call_deferred(
		blast_shape.global_position, blast_shape.shape.radius, ENEMY_EXPLOSION_DAMAGE
	)
