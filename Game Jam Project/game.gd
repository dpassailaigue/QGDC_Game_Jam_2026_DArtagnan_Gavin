extends Node2D

signal xp

func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.died.connect(_on_mob_died)
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)

func _on_timer_timeout():
	spawn_mob()


func _on_player_health_depleted():
	%GameOver.show()
	get_tree().paused = true

func _on_mob_died():
	xp.emit()


func _on_player_upgraded() -> void:
	%UpgradeScreen.show()
	get_tree().paused = true


func _on_button_pressed() -> void:
	%UpgradeScreen.hide()
	get_tree().paused = false
