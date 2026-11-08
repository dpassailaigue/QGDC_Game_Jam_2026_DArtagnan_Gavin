extends StaticBody2D

# Each tree picks one of the 5 trees from Layer_02.png at random when it's
# created. The images were cut out of that sheet into res://trees/tree_*.png.

const SCALE := 1.5

# base = centre of the trunk's bottom row, in image pixels. It's placed on this
# node's origin, so the tree y-sorts by where it touches the ground.
# trunk = trunk width in image pixels, used to size the collision.
# Only the two big trees from the sheet are used.
const VARIANTS := [
	{"texture": preload("res://trees/tree_round_large.png"), "base": Vector2(49.5, 151), "trunk": 21},
	{"texture": preload("res://trees/tree_square_large.png"), "base": Vector2(69.5, 183), "trunk": 25},
]


func _ready() -> void:
	var variant: Dictionary = VARIANTS.pick_random()

	$Sprite.texture = variant.texture
	$Sprite.scale = Vector2(SCALE, SCALE)
	$Sprite.position = -variant.base * SCALE

	# Each tree gets its own shape (a shared one would resize every tree)
	var trunk_width: float = variant.trunk * SCALE
	var shape := CircleShape2D.new()
	shape.radius = maxf(trunk_width * 0.8, 10.0)
	$CollisionShape2D.shape = shape
