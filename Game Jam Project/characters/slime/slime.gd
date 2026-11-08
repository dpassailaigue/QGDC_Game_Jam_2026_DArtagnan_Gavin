extends Node2D

@onready var player = get_node("/root/Game/Player")

# Face the player: flip when they're to the left, unflip when they're to the
# right again (otherwise a mob stays flipped forever once the player passes it)
func _process(_delta: float) -> void:
	$AnimatedSprite2D.flip_h = player.global_position.x < global_position.x

func play_walk():
	%AnimationPlayer.play("walk")


func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("walk")


func play_explosion():
	%AnimationPlayer.play("explosion")
	%AnimationPlayer.queue("hurt")


func play_attack():
	%AnimationPlayer.play("attack")
	%AnimationPlayer.queue("walk")
