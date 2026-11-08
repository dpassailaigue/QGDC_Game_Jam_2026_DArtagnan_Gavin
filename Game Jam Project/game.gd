extends Node2D

signal xp
signal upgrade_select(upgrade_name: String)

signal countdown_finished

const COUNTDOWN_DURATION := 5.0 * 60.0
const WAVE_DURATION := 60.0
const MIN_SPAWN_RATE := 1.0 # spawns per second at the start of each minute
const MAX_SPAWN_RATE := 10.0 # spawns per second at the end of each minute

const ALL_UPGRADES := ["DAMAGE", "SPEED", "CHAIN", "FIRE", "EXPLODE", "SLOW", "ATTACK SPEED"]

@onready var buttons = [%Button1, %Button2, %Button3]

var time_left := COUNTDOWN_DURATION
var countdown_label: Label
var shown_seconds := -1 # last whole second drawn on the countdown label

var game_ended := false # set once the game-over or win screen is up
var pending_upgrades := 0 # level-ups waiting to be picked
var boss_spawned := false

# Max smoke effects spawned per frame, so a huge chain reaction doesn't
# create hundreds of shader nodes at once
const MAX_SMOKE_PER_FRAME := 12
var smoke_this_frame := 0
var explosion_shape := CircleShape2D.new()

# Upgrade stats (SPEED lives on the player)
var damage := 1.0
var chain_length := 2
var fire_level := 0
var explode_level := 0
var slow_level := 0
var attack_speed_level := 0

func _ready() -> void:
	for button in buttons:
		# Read the text at press time, since it changes every level-up
		button.pressed.connect(func(): _on_button_pressed(button.text))
	_create_countdown_label()
	_update_spawn_rate()
	_play_music()

# Battle theme loops for the whole run. PROCESS_MODE_ALWAYS keeps it playing
# while the tree is paused (upgrade screen, win/game over screens).
const BATTLE_MUSIC := preload("res://battle_theme.mp3")
# Where the music starts in the file (skips the MP3 encoder's ~30ms of silence),
# so each loop restarts right on the first beat. The file itself is trimmed to
# end exactly after bar 24 (150 BPM), so loops join with no gap.
const BATTLE_MUSIC_LOOP_START := 1259.0 / 44100.0
func _play_music() -> void:
	var stream: AudioStreamMP3 = BATTLE_MUSIC.duplicate()
	stream.loop = true
	stream.loop_offset = BATTLE_MUSIC_LOOP_START
	var music := AudioStreamPlayer.new()
	music.name = "Music"
	music.stream = stream
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.play()

# The floor sprite only covers a bit more than the screen. It follows the
# player in whole-tile steps, so the world looks endless and the tile pattern
# stays fixed to the ground instead of sliding along with the camera.
const FLOOR_TILE_WORLD_SIZE := 64.0 # 16px tile drawn at 4x
func _update_floor() -> void:
	var p: Vector2 = $Player.global_position
	%Floor.global_position = (p / FLOOR_TILE_WORLD_SIZE).floor() * FLOOR_TILE_WORLD_SIZE

func _process(delta: float) -> void:
	_update_floor()
	smoke_this_frame = 0
	# Countdown freezes once the run is over (e.g. the player died), so the
	# boss doesn't spawn over the Game Over screen
	if game_ended or time_left <= 0.0:
		return
	time_left = max(time_left - delta, 0.0)
	_update_countdown_label()
	if time_left <= 0.0:
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
	# Pixel font comes from the project theme (ui/pixel_theme.tres). A solid
	# drop shadow instead of an outline keeps it readable while staying blocky.
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	countdown_label.add_theme_constant_override("shadow_offset_x", 6)
	countdown_label.add_theme_constant_override("shadow_offset_y", 6)
	layer.add_child(countdown_label)
	_update_countdown_label()

func _update_countdown_label() -> void:
	var total := int(ceil(time_left))
	if total == shown_seconds:
		return
	shown_seconds = total
	countdown_label.text = "%d:%02d" % [floori(total / 60.0), total % 60]

enum MobType { NORMAL, EMPOWERED, ZIGZAG, EXPLODING, BOSS }

# Which enemies spawn in each minute of the countdown, as {type: weight}.
# Weights are relative chances: normal/empowered slimes make up 80% of
# spawns, special enemies (zigzag, exploding) the other 20%.
const MINUTE_SPAWN_TABLE := [
	{MobType.NORMAL: 8}, # 5:00 - 4:00
	{MobType.NORMAL: 8, MobType.ZIGZAG: 2}, # 4:00 - 3:00
	{MobType.NORMAL: 8, MobType.EXPLODING: 2}, # 3:00 - 2:00
	{MobType.NORMAL: 3, MobType.EMPOWERED: 5, MobType.ZIGZAG: 2}, # 2:00 - 1:00
	{MobType.EMPOWERED: 8, MobType.ZIGZAG: 1, MobType.EXPLODING: 1}, # 1:00 - 0:00
]

func spawn_mob(type: MobType):
	const MOB = preload("res://mob.tscn")
	const ZIGZAG_MOB = preload("res://zigzag_mob.tscn")
	const EXPLODING_MOB = preload("res://exploding_mob.tscn")
	const BIG_MOB = preload("res://big_mob.tscn")
	const BOSS = preload("res://boss.tscn")

	var scene: PackedScene = MOB

	match type:
		MobType.NORMAL:
			scene = MOB
		MobType.EMPOWERED:
			scene = BIG_MOB
		MobType.ZIGZAG:
			scene = ZIGZAG_MOB
		MobType.EXPLODING:
			scene = EXPLODING_MOB
		MobType.BOSS:
			scene = BOSS

	%PathFollow2D.progress_ratio = randf()

	var new_mob = scene.instantiate()

	if type == MobType.BOSS:
		new_mob.is_boss = true
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	new_mob.global_position = %PathFollow2D.global_position
	
	# XP for the kill comes from the enemy's xp_value (1 unless it says otherwise)
	var xp_reward = new_mob.get("xp_value")
	new_mob.died.connect(_on_mob_died.bind(xp_reward if xp_reward != null else 1))

	return new_mob

# Weighted random pick from the current minute's row of the spawn table
func _pick_mob_type() -> MobType:
	var elapsed := COUNTDOWN_DURATION - time_left
	var minute := clampi(floori(elapsed / WAVE_DURATION), 0, MINUTE_SPAWN_TABLE.size() - 1)
	var weights: Dictionary = MINUTE_SPAWN_TABLE[minute]
	var total := 0
	for weight in weights.values():
		total += weight
	var roll := randi_range(1, total)
	for type in weights:
		roll -= weights[type]
		if roll <= 0:
			return type
	return MobType.NORMAL

func spawn_boss():
	if boss_spawned:
		return

	boss_spawned = true
	var boss = spawn_mob(MobType.BOSS)
	boss.died.connect(_on_boss_died)

func _on_boss_died():
	_end_game(%WinScreen)

# Ends the run and shows the game-over or win screen. Whichever happens first
# wins, and any open upgrade screen is closed so it can't unpause the game
# behind it. With show_screen = false the run ends but the screen is left for
# later (player death shows it once the death animation finishes).
func _end_game(screen: CanvasLayer, pause := true, show_screen := true) -> void:
	if game_ended:
		return
	game_ended = true
	pending_upgrades = 0
	%UpgradeScreen.hide()
	if show_screen:
		screen.show()
	get_tree().paused = pause

func _on_timer_timeout():
	if time_left <= 0.0:
		return
	spawn_mob(_pick_mob_type())
	_update_spawn_rate()


# The game is not paused on death: enemies keep moving and spawning while the
# death animation plays, and the Game Over screen appears once it's done.
func _on_player_health_depleted():
	_end_game(%GameOver, false, false)

func _on_player_death_animation_finished():
	%GameOver.show()

# One xp signal per point, so a 2 XP kill that crosses a level boundary still
# triggers the level-up at the right point
func _on_mob_died(amount: int = 1):
	for i in amount:
		xp.emit()

func _on_player_upgraded() -> void:
	if game_ended:
		return
	pending_upgrades += 1
	# Already showing choices: this level-up waits its turn instead of
	# rerolling the current options
	if not %UpgradeScreen.visible:
		_show_upgrade_choices()

func _show_upgrade_choices() -> void:
	var options := ALL_UPGRADES.duplicate()
	options.shuffle()
	for i in buttons.size():
		buttons[i].text = options[i]
	%UpgradeScreen.show()
	get_tree().paused = true


func _on_button_pressed(upgrade_name) -> void:
	if game_ended:
		return
	match upgrade_name:
		"DAMAGE": damage += 1.0
		"CHAIN": chain_length += 1
		"FIRE": fire_level += 1
		"EXPLODE": explode_level += 1
		"SLOW": slow_level += 1
		"ATTACK SPEED": attack_speed_level += 1
	upgrade_select.emit(upgrade_name)
	pending_upgrades -= 1
	if pending_upgrades > 0:
		_show_upgrade_choices() # another level-up is queued
		return
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

# Attack speed: 1.1x at level 1, 1.2x at level 2, 1.3x at level 3, ...
func get_attack_speed_multiplier() -> float:
	return 1.0 + 0.1 * attack_speed_level

# Explode: damage = player damage; radius 150 at level 1, +50 per level
func get_explosion_radius() -> float:
	return 150.0 + 50.0 * (explode_level - 1)

# Called by a lightning bolt when it reaches the enemy it was fired at. The
# enemy may have died or been removed while the bolt was on its way.
func apply_lightning_hit(body: Node) -> void:
	if not is_instance_valid(body):
		return
	if body.has_method("apply_hit_effects"):
		body.apply_hit_effects()
	if body.has_method("take_damage"):
		body.take_damage(damage)

func explode_at(pos: Vector2) -> void:
	damage_mobs_in_radius(pos, get_explosion_radius(), damage)

# Shared by the explode upgrade and exploding slimes. Call it deferred from a
# death so chain reactions don't recurse deeply in one call stack.
# Uses a physics query so only nearby enemies are checked, not every enemy
# on the map (big chain reactions used to check every mob per explosion).
func damage_mobs_in_radius(pos: Vector2, radius: float, amount: float) -> void:
	explosion_shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = explosion_shape
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = 2 # enemies only
	query.collide_with_areas = false
	var radius_sq := radius * radius
	for result in get_world_2d().direct_space_state.intersect_shape(query, 512):
		var mob = result.collider
		# Same rule as before: the mob's centre must be inside the blast
		var in_blast: bool = mob.global_position.distance_squared_to(pos) <= radius_sq
		if in_blast and mob.has_method("take_damage"):
			mob.take_damage(amount) # already-dead mobs ignore this

# Called by mobs instead of spawning smoke directly; skips the effect once
# this frame's budget is used up. fiery = red/orange/yellow explosion cloud.
func spawn_smoke(pos: Vector2, fiery := false) -> void:
	if smoke_this_frame >= MAX_SMOKE_PER_FRAME:
		return
	smoke_this_frame += 1
	var smoke = preload("res://smoke_explosion/smoke_explosion.tscn").instantiate()
	smoke.fiery = fiery
	add_child(smoke)
	smoke.global_position = pos


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
