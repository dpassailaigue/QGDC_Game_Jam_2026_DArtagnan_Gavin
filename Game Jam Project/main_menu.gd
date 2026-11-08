extends Control

const GAME_SCENE := "res://survivors_game.tscn"
const MENU_MUSIC := preload("res://main_theme.mp3")


func _ready() -> void:
	get_tree().paused = false
	%PlayButton.grab_focus()
	_play_music()


# Main theme loops for as long as the menu is open (the music player is freed
# with the menu when the game scene loads, so the music stops there)
func _play_music() -> void:
	var stream: AudioStreamMP3 = MENU_MUSIC.duplicate()
	stream.loop = true
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.stream = stream
	add_child(music)
	music.play()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
