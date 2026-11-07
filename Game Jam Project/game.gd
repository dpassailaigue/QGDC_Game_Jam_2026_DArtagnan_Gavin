extends Node2D

signal xp
signal upgrade_select(upgrade_name: String)

@onready var buttons = [%Button1, %Button2, %Button3]

func _ready() -> void:
	for button in buttons:
		button.pressed.connect(_on_button_pressed.bind(button.text))

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


func _on_button_pressed(upgrade_name) -> void:
	upgrade_select.emit(upgrade_name)
	%UpgradeScreen.hide()
	get_tree().paused = false
