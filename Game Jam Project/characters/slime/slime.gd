extends Node2D

@onready var player = get_node("/root/Game/Player")

func _process(float) -> void:
	if player.global_position.x < global_position.x:
		$AnimatedSprite2D.flip_h = true

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
