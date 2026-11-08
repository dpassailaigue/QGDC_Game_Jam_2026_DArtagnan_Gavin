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
var level_start_xp = 0 # total XP when the current level began

# XP bar along the bottom of the screen
const XP_BAR_HEIGHT := 10.0
const XP_BAR_WIDTH_RATIO := 0.6 # fraction of the screen width, centred
const XP_BAR_BOTTOM_MARGIN := 40.0 # gap between the bar and the bottom edge
const XP_BAR_BACK_COLOR := Color(0.5, 0.5, 0.5, 0.5) # grey, slightly see-through
const XP_BAR_FILL_COLOR := Color(0.55, 0.85, 1.0, 1.0) # light blue, opaque
var xp_bar_fill: ColorRect

var speed = 600.0

func _ready():
	_create_xp_bar()

func _create_xp_bar():
	var layer := CanvasLayer.new()
	add_child(layer)
	var back := ColorRect.new()
	back.color = XP_BAR_BACK_COLOR
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Centred horizontally (the camera follows the player, so this is centred
	# under the player), raised slightly off the bottom edge
	var half_width := (1.0 - XP_BAR_WIDTH_RATIO) / 2.0
	back.anchor_left = half_width
	back.anchor_right = 1.0 - half_width
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = 0.0
	back.offset_right = 0.0
	back.offset_top = -XP_BAR_BOTTOM_MARGIN - XP_BAR_HEIGHT
	back.offset_bottom = -XP_BAR_BOTTOM_MARGIN
	layer.add_child(back)
	xp_bar_fill = ColorRect.new()
	xp_bar_fill.color = XP_BAR_FILL_COLOR
	xp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fills the back bar from the left; anchor_right is the progress (0 to 1)
	xp_bar_fill.anchor_left = 0.0
	xp_bar_fill.anchor_top = 0.0
	xp_bar_fill.anchor_bottom = 1.0
	xp_bar_fill.offset_left = 0.0
	xp_bar_fill.offset_top = 0.0
	xp_bar_fill.offset_right = 0.0
	xp_bar_fill.offset_bottom = 0.0
	back.add_child(xp_bar_fill)
	_update_xp_bar()

# Fill = progress from the start of this level to the next level-up
func _update_xp_bar():
	var progress := float(xp - level_start_xp) / float(upgrade_need - level_start_xp)
	# Set anchor and offset together; setting the anchor alone makes Godot shift
	# the offset to keep the old width
	xp_bar_fill.set_anchor_and_offset(SIDE_RIGHT, clampf(progress, 0.0, 1.0), 0.0)

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
	level_start_xp = upgrade_need
	upgrade_need += xp_for_level(level)
	upgraded.emit()

# XP needed to go from level-1 to level: 15, 25, 35, ... up to 140
func xp_for_level(target_level: int) -> int:
	return mini(FIRST_LEVEL_XP + LEVEL_XP_STEP * (target_level - 1), MAX_LEVEL_XP)

func _on_game_xp() -> void:
	xp += 1
	if xp >= upgrade_need:
		upgrade()
	_update_xp_bar()


func _on_game_upgrade_select(upgrade_name: String) -> void:
	if upgrade_name == "SPEED":
		speed += 50.0
