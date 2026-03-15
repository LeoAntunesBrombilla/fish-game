extends Node2D
# Node position should be Vector2(95, 516) in world space.
# Local (0, 0) = feet on ground.
# Rod tip local ≈ (50, -100) → world ≈ (145, 416).

var idle_time := 0.0

func _process(delta: float) -> void:
	idle_time += delta
	queue_redraw()

func _draw() -> void:
	var sway := sin(idle_time * 1.1) * 0.6

	var skin  := Color(0.94, 0.77, 0.58)
	var hat   := Color(0.26, 0.15, 0.05)
	var shirt := Color(0.16, 0.40, 0.68)
	var pant  := Color(0.20, 0.18, 0.36)
	var boot  := Color(0.09, 0.06, 0.02)
	var rod_c := Color(0.50, 0.30, 0.08)

	# Boots
	draw_rect(Rect2(-15, -10, 13, 10), boot)
	draw_rect(Rect2(2,   -10, 13, 10), boot)
	# Legs
	draw_rect(Rect2(-13, -33, 11, 25), pant)
	draw_rect(Rect2(2,   -33, 11, 25), pant)
	# Belt
	draw_rect(Rect2(-15, -36, 30, 5), Color(0.18, 0.12, 0.05))
	# Body / shirt
	draw_rect(Rect2(-15, -64, 30, 30), shirt)
	# Collar
	draw_rect(Rect2(-5, -64, 10, 7), Color(0.90, 0.88, 0.84))
	# Left arm (relaxed down)
	draw_line(Vector2(-14, -56), Vector2(-22, -38), skin, 7.0)
	draw_circle(Vector2(-22, -38), 5.0, skin)
	# Right arm (raised, holding rod)
	draw_line(Vector2(14, -56), Vector2(26, -72), skin, 7.0)
	draw_circle(Vector2(26, -72), 5.0, skin)
	# Head
	draw_circle(Vector2(sway, -80), 17.0, skin)
	# Eyes
	draw_circle(Vector2(sway - 5.5, -82), 2.5, Color(0.10, 0.08, 0.04))
	draw_circle(Vector2(sway + 5.5, -82), 2.5, Color(0.10, 0.08, 0.04))
	draw_circle(Vector2(sway - 4.5, -82), 1.0, Color(0.02, 0.02, 0.02))
	draw_circle(Vector2(sway + 6.5, -82), 1.0, Color(0.02, 0.02, 0.02))
	# Smile
	draw_arc(Vector2(sway, -75), 5, 0.15, PI - 0.15, 8, Color(0.42, 0.16, 0.08), 1.5)
	# Hat brim
	draw_rect(Rect2(sway - 22, -93,  44, 7),  hat)
	# Hat crown
	draw_rect(Rect2(sway - 14, -112, 28, 22), hat)
	# Hat band
	draw_rect(Rect2(sway - 14, -95,  28, 5),  Color(0.52, 0.30, 0.07))
	# Pipe stem
	draw_line(Vector2(sway + 7, -72), Vector2(sway + 20, -72),
			  Color(0.32, 0.18, 0.05), 2.5)
	# Pipe bowl
	draw_rect(Rect2(sway + 17, -79, 7, 9), Color(0.26, 0.14, 0.04))
	draw_rect(Rect2(sway + 18, -78, 5, 7), Color(0.18, 0.09, 0.02))
	# Smoke puffs (3 offset loops)
	for i in range(3):
		var phase := fmod(idle_time * 0.75 + float(i) * 0.42, 1.4) / 1.4
		var sx    := sway + 20.0 + sin(phase * TAU + float(i)) * 4.0
		var sy    := -80.0 - phase * 26.0
		var sr    := 2.2 + phase * 3.8
		var sa    := (1.0 - phase) * 0.55
		draw_circle(Vector2(sx, sy), sr, Color(0.88, 0.88, 0.88, sa))
	# Fishing rod (3 segments, tapering)
	draw_line(Vector2(26, -72), Vector2(36, -85), rod_c, 4.0)
	draw_line(Vector2(36, -85), Vector2(44, -95), rod_c, 3.0)
	draw_line(Vector2(44, -95), Vector2(50, -100), rod_c, 2.0)
