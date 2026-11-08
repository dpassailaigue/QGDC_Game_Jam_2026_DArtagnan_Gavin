extends Control

const GAME_SCENE := "res://survivors_game.tscn"
const MENU_MUSIC := preload("res://main_theme.mp3")
# Where the music starts in the file (skips the MP3 encoder's ~30ms of silence),
# so each loop restarts right on the first beat. The file itself is trimmed to
# end exactly after bar 40 (120 BPM), so loops join with no gap.
const MENU_MUSIC_LOOP_START := 1364.0 / 44100.0


func _ready() -> void:
	get_tree().paused = false
	%PlayButton.grab_focus()
	_play_music()


# Main theme loops for as long as the menu is open (the music player is freed
# with the menu when the game scene loads, so the music stops there)
func _play_music() -> void:
	var stream: AudioStreamMP3 = MENU_MUSIC.duplicate()
	stream.loop = true
	stream.loop_offset = MENU_MUSIC_LOOP_START
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.stream = stream
	add_child(music)
	music.play()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


# Credits page: shown in place of the main page (same scene, so the main
# theme keeps playing without restarting)
func _on_credits_button_pressed() -> void:
	%MainPage.hide()
	%CreditsPage.show()
	%BackButton.grab_focus()


func _on_back_button_pressed() -> void:
	%CreditsPage.hide()
	%MainPage.show()
	%CreditsButton.grab_focus()


# Escape / controller back also leaves the credits page
func _unhandled_input(event: InputEvent) -> void:
	if %CreditsPage.visible and event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()


# The artist's link on the credits page opens in the browser
func _on_credits_link_clicked(meta) -> void:
	OS.shell_open(str(meta))
