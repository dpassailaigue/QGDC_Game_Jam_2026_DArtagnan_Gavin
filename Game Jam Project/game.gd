extends Node2D

signal xp
signal upgrade_select(upgrade_name: String)

signal countdown_finished

const COUNTDOWN_DURATION := 5.0 * 60.0
const WAVE_DURATION := 60.0
const MIN_SPAWN_RATE := 1.0 # spawns per second at the start of each minute
const MAX_SPAWN_RATE := 10.0 # spawns per second at the end of each minute

const ALL_UPGRADES := ["DAMAGE", "SPEED", "CHAIN", "FIRE", "EXPLODE", "SLOW"]

@onready var buttons = [%Button1, %Button2, %Button3]

var time_left := COUNTDOWN_DURATION
var countdown_label: Label

# Upgrade stats (SPEED lives on the player)
var damage := 1.0
var chain_length := 2
var fire_level := 0
var explode_level := 0
var slow_level := 0

func _ready() -> void:
	for button in buttons:
		# Read the text at press time, since it changes every level-up
		button.pressed.connect(func(): _on_button_pressed(button.text))
	_create_countdown_label()
	_update_spawn_rate()

func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = max(time_left - delta, 0.0)
	_update_countdown_label()
	if time_left == 0.0:
		$Timer.stop()
		countdown_finished.emit()
		spawn_boss()

# Spawn rate ramps linearly from MIN to MAX over each minute, then resets.
func _update_spawn_rate() -> void:
	var elapsed := COUNTDOWN_DURATION - time_left
	var wave_progress := fmod(elapsed, WAVE_DURATION) / WAVE_DURATION
	var rate := lerpf(MIN_SPAWN_RATE, MAX_SPAWN_RATE, wave_progress)
	$Timer.wait_time = 1.0 / rate

func _create_countdown_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	countdown_label = Label.new()
	countdown_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	countdown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.position.y = 16
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	countdown_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(countdown_label)
	_update_countdown_label()

func _update_countdown_label() -> void:
	var total := int(ceil(time_left))
	countdown_label.text = "%d:%02d" % [floori(total / 60.0), total % 60]

func spawn_mob(is_boss := false):
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	new_mob.is_boss = is_boss
	new_mob.died.connect(_on_mob_died)
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	return new_mob

func spawn_boss():
	var boss = spawn_mob(true)
	boss.died.connect(_on_boss_died)

func _on_boss_died():
	# The boss kill can also trigger a level-up; the win screen takes priority
	%UpgradeScreen.hide()
	%WinScreen.show()
	get_tree().paused = true

func _on_timer_timeout():
	if time_left <= 0.0:
		return
	spawn_mob()
	_update_spawn_rate()


func _on_player_health_depleted():
	%GameOver.show()
	get_tree().paused = true

func _on_mob_died():
	xp.emit()


func _on_player_upgraded() -> void:
	var options := ALL_UPGRADES.duplicate()
	options.shuffle()
	for i in buttons.size():
		buttons[i].text = options[i]
	%UpgradeScreen.show()
	get_tree().paused = true


func _on_button_pressed(upgrade_name) -> void:
	match upgrade_name:
		"DAMAGE": damage += 1.0
		"CHAIN": chain_length += 1
		"FIRE": fire_level += 1
		"EXPLODE": explode_level += 1
		"SLOW": slow_level += 1
	upgrade_select.emit(upgrade_name)
	%UpgradeScreen.hide()
	get_tree().paused = false


# --- Upgrade effect formulas ---

# Fire: 2s burn dealing 0.25/tick at level 1; each level adds +0.5s and +0.1/tick
func get_burn_duration() -> float:
	return 2.0 + 0.5 * (fire_level - 1)

func get_burn_damage_per_tick() -> float:
	return 0.25 + 0.1 * (fire_level - 1)

# Slow: 1.5s at level 1; each level adds +0.75s
func get_slow_duration() -> float:
	return 1.5 + 0.75 * (slow_level - 1)

# Explode: damage = player damage; radius 150 at level 1, +50 per level
func get_explosion_radius() -> float:
	return 150.0 + 50.0 * (explode_level - 1)

func explode_at(pos: Vector2) -> void:
	var radius := get_explosion_radius()
	for mob in get_tree().get_nodes_in_group("mobs"):
		if mob.global_position.distance_to(pos) <= radius:
			mob.take_damage(damage)


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
