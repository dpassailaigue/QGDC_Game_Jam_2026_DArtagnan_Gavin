extends Area2D

var chain_length = 2
var chain = chain_length
var travelled_distance = 0


func _physics_process(delta):
	const SPEED = 10000
	const RANGE = 12000

	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func find_enemy():
	var enemies_in_range = %EnemyScanner.get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF
	for body in enemies_in_range:
		var dist = global_position.distance_to(body.global_position)
		if dist < min_distance and dist >= 100:
			closest_body = body
			min_distance = dist
	if closest_body:
		look_at(closest_body.global_position)

func _on_body_entered(body):
	chain -= 1
	if chain <= 0:
		queue_free()
	else:
		find_enemy()
	if body.has_method("take_damage"):
		body.take_damage()
