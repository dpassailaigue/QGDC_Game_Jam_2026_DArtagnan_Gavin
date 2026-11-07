extends CharacterBody2D

signal health_depleted
signal upgraded

var health = 100.0
var xp = 0
var upgrade_need = 4
var level = 1

func _physics_process(delta):
	%Label.text = str(xp)
	const SPEED = 600.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
	
	# Taking damage
	const DAMAGE_RATE = 6.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		%HealthBar.value = health
		if health <= 0.0:
			health_depleted.emit()

func upgrade():
	upgrade_need *= 2
	level += 1
	upgraded.emit()

func _on_game_xp() -> void:
	xp += 1
	if xp >= upgrade_need:
		upgrade()
