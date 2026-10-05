@tool
extends Control


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color.DIM_GRAY)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	
	draw_line(Vector2(16, 0), Vector2(24, 0), Color.RED, 3.0)
	draw_line(Vector2(-16, 0), Vector2(-24, 0), Color.RED, 3.0)
	draw_line(Vector2(0, 16), Vector2(0, 24), Color.RED, 3.0)
	draw_line(Vector2(0, -16), Vector2(0, -24), Color.RED, 3.0)
