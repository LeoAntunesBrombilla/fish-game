extends Node2D
# Node position set by Main.gd: Vector2(bobber_x, WATER_Y).
# Local (0,0) = water surface. Bobber floats at y ≈ -7.

var bob_time := 0.0

func _process(delta: float) -> void:
	bob_time += delta * 2.6
	queue_redraw()

func _draw() -> void:
	var bob    := sin(bob_time) * 2.2
	var center := Vector2(0.0, -7.0 + bob)
	var r      := 9.0

	# Antenna
	draw_line(Vector2(0, center.y - r), Vector2(0, center.y - r - 10.0),
			  Color(0.50, 0.32, 0.10), 2.5)

	# Red top half (angles PI → 2PI = upper screen half)
	var top_pts := PackedVector2Array()
	top_pts.append(center)
	for i in range(13):
		var a = PI + PI * float(i) / 12.0
		top_pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(top_pts, Color(0.88, 0.10, 0.10))

	# White bottom half (angles 0 → PI = lower screen half)
	var bot_pts := PackedVector2Array()
	bot_pts.append(center)
	for i in range(13):
		var a = PI * float(i) / 12.0
		bot_pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(bot_pts, Color(0.95, 0.95, 0.95))

	# Outline + center line
	draw_arc(center, r, 0, TAU, 28, Color(0.12, 0.08, 0.03), 1.5)
	draw_line(center + Vector2(-r, 0), center + Vector2(r, 0),
			  Color(0.12, 0.08, 0.03), 1.0)

	# Small water shadow beneath bobber
	draw_ellipse_approx(Vector2(0, 1.5 + bob * 0.3), 11.0, 3.5,
						Color(0.02, 0.18, 0.45, 0.35))

func draw_ellipse_approx(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a = TAU * float(i) / 16.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
