@tool
extends Control

# A progress bar drawn as chunky pixel art: everything is laid out on a grid
# of pixel_size x pixel_size blocks. A dark outline with cut corners, a dark
# inside, and a fill (with a lighter top row and darker bottom row) that grows
# in whole blocks. Used for the health bar and XP bar.

@export var max_value := 100.0:
	set(v):
		max_value = v
		queue_redraw()
@export var value := 100.0:
	set(v):
		value = v
		queue_redraw()
@export var pixel_size := 4
@export var fill_color := Color(0.62, 0.87, 0.32)
@export var back_color := Color(0.08, 0.09, 0.13, 0.85)
@export var outline_color := Color(0.02, 0.02, 0.05)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var p := float(pixel_size)
	var cols := int(size.x / p)
	var rows := int(size.y / p)
	if cols < 3 or rows < 3:
		return
	# Outline, leaving the four corner blocks empty for a rounded pixel look
	draw_rect(Rect2(p, 0, (cols - 2) * p, p), outline_color)
	draw_rect(Rect2(p, (rows - 1) * p, (cols - 2) * p, p), outline_color)
	draw_rect(Rect2(0, p, p, (rows - 2) * p), outline_color)
	draw_rect(Rect2((cols - 1) * p, p, p, (rows - 2) * p), outline_color)
	# Inside
	var inner_cols := cols - 2
	var inner_rows := rows - 2
	draw_rect(Rect2(p, p, inner_cols * p, inner_rows * p), back_color)
	# Fill, in whole blocks
	var ratio := clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var fill_cols := int(round(inner_cols * ratio))
	if fill_cols <= 0:
		return
	var fill_w := fill_cols * p
	draw_rect(Rect2(p, p, fill_w, inner_rows * p), fill_color)
	if inner_rows >= 3:
		draw_rect(Rect2(p, p, fill_w, p), fill_color.lightened(0.35))
		draw_rect(Rect2(p, inner_rows * p, fill_w, p), fill_color.darkened(0.3))
