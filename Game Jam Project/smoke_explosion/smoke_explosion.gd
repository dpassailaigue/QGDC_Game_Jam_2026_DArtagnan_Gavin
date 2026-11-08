extends Node2D

# Set before adding to the scene: true for explosions (exploding slimes, the
# explode-on-kill upgrade) to get a red/orange/yellow cloud instead of grey
# smoke. The shader picks colours by how dense each part of the cloud is, so
# the hot yellow core shrinks to orange and red as the cloud fades.
var fiery := false

static var fire_gradient: GradientTexture1D


static func _get_fire_gradient() -> GradientTexture1D:
	if fire_gradient == null:
		var g := Gradient.new()
		g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT # hard pixel-art bands
		g.offsets = PackedFloat32Array([0.0, 0.62, 0.8])
		g.colors = PackedColorArray([
			Color(0.85, 0.15, 0.08), # red (outer edge)
			Color(1.0, 0.5, 0.1), # orange
			Color(1.0, 0.88, 0.3), # yellow (dense core)
		])
		fire_gradient = GradientTexture1D.new()
		fire_gradient.gradient = g
	return fire_gradient


func _ready():
	%Smoke.material.set_shader_parameter("texture_offset", Vector2(randfn(0.0, 1.0), randfn(0.0, 1.0)))
	if fiery:
		%Smoke.material.set_shader_parameter("color_gradient", _get_fire_gradient())
		# Full brightness (grey smoke is darkened via modulate); the animation
		# only fades the alpha, so this sticks
		%Smoke.modulate = Color(1, 1, 1, %Smoke.modulate.a)
	%AnimationPlayer.play("explosion")
	await %AnimationPlayer.animation_finished
	queue_free()
