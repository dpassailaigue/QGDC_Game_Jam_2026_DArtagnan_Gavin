extends CharacterBody2D

signal died

var speed = randf_range(200, 300)
static var damage = 1
var health = 3

@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")


func _ready():
	%Slime.play_walk()
	game.upgrade_select.connect(_on_upgrade_select)


func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()


func take_damage():
	%Slime.play_hurt()
	health -= damage

	if health <= 0:
		var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = smoke_scene.instantiate()
		died.emit()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		queue_free()

static func _on_upgrade_select(upgrade_name):
	if upgrade_name == "DAMAGE":
		damage += 1
