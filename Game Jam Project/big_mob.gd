extends "res://mob.gd"

# The stronger regular enemy (big_mob.tscn): the BigSlime visual at 2x size
# with a big hitbox. It behaves like a normal slime (walks at the player, can
# burn/slow, gives XP, triggers the explode upgrade) but takes more hits.
# Spawned as MobType.EMPOWERED in game.gd.

const HEALTH_MULTIPLIER := 3.0


func _init():
	xp_value = 2 # twice a normal slime's XP


func _find_slime() -> Node2D:
	return %BigSlime


func _ready():
	health *= HEALTH_MULTIPLIER
	super()
