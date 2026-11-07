extends Area2D


func _process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	var closest_body = null
	var min_distance = INF
	for body in enemies_in_range:
		var dist = global_position.distance_to(body.global_position)
		if dist < min_distance:
			closest_body = body
			min_distance = dist
	if enemies_in_range.size() > 0:
		look_at(closest_body.global_position)


func shoot():
	const BULLET = preload("res://bullet_2d.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_transform = %ShootingPoint.global_transform
	%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
