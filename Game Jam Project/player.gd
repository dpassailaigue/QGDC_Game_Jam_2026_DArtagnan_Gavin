extends CharacterBody2D

signal health_depleted
signal upgraded

var health = 100.0
var xp = 0
var upgrade_need = 4
var level = 1

var speed = 600.0

func _physics_process(delta):
	%Label.text = str(xp)
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


func _on_game_upgrade_select(upgrade_name: String) -> void:
	if upgrade_name == "SPEED":
		speed += 200.0
