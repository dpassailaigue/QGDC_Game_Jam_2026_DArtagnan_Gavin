extends Control

const GAME_SCENE := "res://survivors_game.tscn"


func _ready() -> void:
	get_tree().paused = false
	%PlayButton.grab_focus()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
