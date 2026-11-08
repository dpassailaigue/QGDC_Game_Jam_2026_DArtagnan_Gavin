extends AnimatedSprite2D

# One animated lightning bolt flying from one point to another. A shot makes
# one bolt per link: staff -> first enemy, then enemy -> next enemy for each
# chain. The art (Wizard Pack/lightning_v2_*) is a 104x22 bolt that grows from
# the left edge of the frame; the sprite's origin is that left edge (the tail)
# and it's turned to face where it's going. Every bolt is the same size.
# Frame order in lightning_bolt.tscn is 1,3,4,5,6,7,8,9,11,12,13,2 (sorted by
# how the bolt grows, slides forward and fades; _10 is a duplicate of _1 and
# isn't used). Three phases:
#   LAUNCH: frames up to HOLD_FRAME play at the source (staff tip or the enemy
#           being chained from) as the bolt forms.
#   FLY:    the animation holds on HOLD_FRAME while the bolt flies to the
#           target, homing in on it if it moves.
#   IMPACT: once the bolt's front reaches the target, the rest of the frames
#           play there. The enemy takes the hit as impact starts. A target
#           closer than the bolt is long gets hit straight after launch.
# A chain link waits for the previous link's bolt to arrive before launching.

signal arrived

const FRAME_WIDTH := 104.0
const SCALE := 2.0 # every bolt is drawn at 2x: 208px long
const LENGTH := FRAME_WIDTH * SCALE
const HOLD_FRAME := 5 # lightning_v2_7: the fully grown bolt
const FLY_SPEED := 2000.0 # px/s

enum Phase { WAITING, LAUNCH, FLY, IMPACT }
var phase := Phase.WAITING

var target: Node = null # the enemy this link hits (null for a miss)
var source: Node2D = null # the player (staff tip) or the enemy chained from
var start_point: Vector2
var end_point: Vector2
var source_offset := Vector2.ZERO
var target_offset := Vector2.ZERO
var impact_offset := Vector2.ZERO # bolt tail relative to the target during impact


# previous: the bolt for the previous chain link; this one launches when it lands
func setup(from: Vector2, to: Vector2, hit_target: Node, previous: Node = null,
		from_source: Node2D = null) -> void:
	start_point = from
	end_point = to
	target = hit_target
	source = from_source
	if source != null and not source.has_method("get_staff_tip_position"):
		source_offset = from - source.global_position
	if target is Node2D:
		target_offset = to - target.global_position
	frame_changed.connect(_on_frame_changed)
	animation_finished.connect(queue_free)
	hide()
	if previous != null and is_instance_valid(previous):
		await previous.arrived
	_launch()


func _launch() -> void:
	scale = Vector2(SCALE, SCALE)
	phase = Phase.LAUNCH
	_place_at_source()
	show()
	play("bolt")


func _process(delta: float) -> void:
	match phase:
		Phase.LAUNCH:
			_place_at_source()
		Phase.FLY:
			var goal := _target_point()
			var dir := global_position.direction_to(goal)
			rotation = dir.angle()
			# Fly until the bolt's front (tail + length) reaches the target.
			# A target closer than that is hit where the bolt already is.
			var remaining := global_position.distance_to(goal) - LENGTH
			var step := FLY_SPEED * delta
			if remaining <= step:
				if remaining > 0.0:
					global_position = goal - dir * LENGTH
				_impact()
			else:
				global_position += dir * step
		Phase.IMPACT:
			# Stay with the target while the impact frames play
			global_position = _target_point() + impact_offset


func _on_frame_changed() -> void:
	if phase == Phase.LAUNCH and frame >= HOLD_FRAME:
		pause() # hold the formed bolt while it flies
		phase = Phase.FLY


func _impact() -> void:
	phase = Phase.IMPACT
	impact_offset = global_position - _target_point()
	if target != null:
		get_node("/root/Game").apply_lightning_hit(target)
	arrived.emit() # the next chain link launches from here
	frame = HOLD_FRAME + 1
	play("bolt")


func _place_at_source() -> void:
	global_position = _source_point()
	rotation = global_position.angle_to_point(_target_point())


func _source_point() -> Vector2:
	if is_instance_valid(source):
		if source.has_method("get_staff_tip_position"):
			start_point = source.get_staff_tip_position()
		else:
			start_point = source.global_position + source_offset
	return start_point


func _target_point() -> Vector2:
	if is_instance_valid(target) and target is Node2D:
		end_point = target.global_position + target_offset
	return end_point
