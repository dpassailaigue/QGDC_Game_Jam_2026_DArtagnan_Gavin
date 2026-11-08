extends CharacterBody2D

signal health_depleted
signal upgraded

var health = 100.0
# Level-up curve: XP needed for the next level grows by a fixed step, capped.
# Spawns per minute are constant (~330), so XP supply doesn't grow over the
# run; what grows is the player's kill power. A linear step with a cap keeps
# level-ups roughly every 15-20s for the whole 5 minutes (~17 upgrades).
# Every enemy type gives 1 XP.
const FIRST_LEVEL_XP := 15
const LEVEL_XP_STEP := 10
const MAX_LEVEL_XP := 140

var xp = 0
var level = 1
var upgrade_need = FIRST_LEVEL_XP # total XP at which the next level-up happens

var speed = 600.0

func _ready():
	%Label.text = str(xp)

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed

	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
	
	# Taking damage
	const DAMAGE_RATE = 6.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		take_damage(DAMAGE_RATE * overlapping_mobs.size() * delta)

func take_damage(amount: float):
	health -= amount
	%HealthBar.value = health
	if health <= 0.0:
		health_depleted.emit()

func upgrade():
	level += 1
	upgrade_need += xp_for_level(level)
	upgraded.emit()

# XP needed to go from level-1 to level: 15, 25, 35, ... up to 140
func xp_for_level(target_level: int) -> int:
	return mini(FIRST_LEVEL_XP + LEVEL_XP_STEP * (target_level - 1), MAX_LEVEL_XP)

func _on_game_xp() -> void:
	xp += 1
	%Label.text = str(xp) # only redraw the XP label when it changes
	if xp >= upgrade_need:
		upgrade()


func _on_game_upgrade_select(upgrade_name: String) -> void:
	if upgrade_name == "SPEED":
		speed += 50.0
