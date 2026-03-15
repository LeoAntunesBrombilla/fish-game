extends Node2D
# Position set by Main.gd (same as bobber).
# Draws expanding elliptical ripple rings at water surface.

var rtime := 0.0

func _process(delta: float) -> void:
	rtime += delta
	queue_redraw()

func _draw() -> void:
	for i in range(3):
		var phase := fmod(rtime * 1.8 + float(i) * 0.65, 2.0) / 2.0
		var rx    := 8.0 + phase * 36.0
		var ry    := rx * 0.38
		var alpha := (1.0 - phase) * 0.80
		_draw_ring(Vector2.ZERO, rx, ry, Color(0.72, 0.92, 1.0, alpha), 2.0)

func _draw_ring(center: Vector2, rx: float, ry: float,
				col: Color, width: float) -> void:
	var steps := 28
	var prev  := center + Vector2(rx, 0.0)
	for i in range(1, steps + 1):
		var a    = TAU * float(i) / float(steps)
		var curr = center + Vector2(cos(a) * rx, sin(a) * ry)
		draw_line(prev, curr, col, width)
		prev = curr
