extends Node2D

const W       := 1152.0
const H       := 648.0
const LAND_X  := 440.0
const WATER_Y := 520.0

var wave_time   := 0.0
var cloud_ox    := [0.0, 80.0, 40.0, 120.0]

func _process(delta: float) -> void:
	wave_time += delta
	for i in cloud_ox.size():
		cloud_ox[i] = fmod(cloud_ox[i] + delta * 10.0, W + 200.0)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_clouds()
	_draw_mountains()
	_draw_land()
	_draw_trees()
	_draw_water()

# ── Sky ────────────────────────────────────────────────────────
func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.38, 0.68, 0.94))
	for i in range(8):
		var t   = float(i) / 8.0
		var y   = WATER_Y - 160.0 + i * 22.0
		draw_rect(Rect2(0, y, W, 22), Color(0.72, 0.90, 1.0, 0.06 * (1.0 - t)))

# ── Clouds ─────────────────────────────────────────────────────
func _draw_clouds() -> void:
	var defs = [[Vector2(160,68),62.0,24.0],[Vector2(420,44),46.0,18.0],
	            [Vector2(680,90),74.0,28.0],[Vector2(940,56),52.0,22.0]]
	for i in defs.size():
		_draw_cloud(defs[i][0] + Vector2(cloud_ox[i], 0.0), defs[i][1], defs[i][2])

func _draw_cloud(pos: Vector2, w: float, h: float) -> void:
	var c := Color(1, 1, 1, 0.88)
	draw_rect(Rect2(pos.x - w * 0.5, pos.y - h * 0.25, w, h * 0.85), c)
	draw_circle(pos + Vector2(-w * 0.28, 2), h * 0.66, c)
	draw_circle(pos + Vector2( w * 0.28, 4), h * 0.54, c)
	draw_circle(pos, h * 0.80, c)
	draw_circle(pos + Vector2(w * 0.12, -h * 0.22), h * 0.56, c)

# ── Mountains ──────────────────────────────────────────────────
func _draw_mountains() -> void:
	_draw_mtn(Vector2(580, WATER_Y+2), 340,175, Color(0.50,0.62,0.74,0.55))
	_draw_mtn(Vector2(800, WATER_Y+2), 290,148, Color(0.46,0.58,0.70,0.55))
	_draw_mtn(Vector2(1010,WATER_Y+2), 260,130, Color(0.50,0.62,0.74,0.55))
	_draw_mtn(Vector2(1140,WATER_Y+2), 220,105, Color(0.46,0.58,0.70,0.55))
	_draw_mtn(Vector2(640, WATER_Y+2), 270,145, Color(0.30,0.42,0.50))
	_draw_mtn(Vector2(880, WATER_Y+2), 240,124, Color(0.26,0.38,0.46))
	# snow caps
	_draw_mtn(Vector2(580, WATER_Y-130), 75, 60, Color(0.94,0.97,1.0,0.85))
	_draw_mtn(Vector2(1010,WATER_Y-96),  62, 48, Color(0.94,0.97,1.0,0.80))

func _draw_mtn(base: Vector2, w: float, h: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x - w*0.5, base.y),
		Vector2(base.x,          base.y - h),
		Vector2(base.x + w*0.5, base.y),
	]), col)

# ── Land ───────────────────────────────────────────────────────
func _draw_land() -> void:
	draw_rect(Rect2(0, WATER_Y-8,  LAND_X+8, H-WATER_Y+8), Color(0.48,0.32,0.16))
	draw_rect(Rect2(0, WATER_Y-20, LAND_X+8, 16),           Color(0.26,0.56,0.18))
	draw_rect(Rect2(0, WATER_Y-13, LAND_X+8, 8),            Color(0.33,0.67,0.22))
	draw_rect(Rect2(LAND_X-4, WATER_Y-14, 14, H-WATER_Y+14), Color(0.38,0.24,0.10))

# ── Trees ──────────────────────────────────────────────────────
func _draw_trees() -> void:
	for td in [[Vector2(338,WATER_Y-20),30.0,72.0],[Vector2(373,WATER_Y-20),23.0,56.0],
	           [Vector2(402,WATER_Y-20),27.0,65.0],[Vector2(214,WATER_Y-20),25.0,60.0],
	           [Vector2(168,WATER_Y-20),21.0,52.0],[Vector2(126,WATER_Y-20),18.0,46.0]]:
		_draw_tree(td[0], td[1], td[2])

func _draw_tree(base: Vector2, w: float, h: float) -> void:
	draw_rect(Rect2(base.x-4, base.y-14, 8, 16), Color(0.34,0.20,0.07))
	var c1 := Color(0.12,0.46,0.12)
	var c2 := Color(0.18,0.56,0.18)
	draw_colored_polygon(PackedVector2Array([Vector2(base.x-w,base.y-5),
		Vector2(base.x,base.y-h*0.42),Vector2(base.x+w,base.y-5)]), c1)
	draw_colored_polygon(PackedVector2Array([Vector2(base.x-w*0.76,base.y-h*0.38),
		Vector2(base.x,base.y-h*0.72),Vector2(base.x+w*0.76,base.y-h*0.38)]), c2)
	draw_colored_polygon(PackedVector2Array([Vector2(base.x-w*0.48,base.y-h*0.68),
		Vector2(base.x,base.y-h),Vector2(base.x+w*0.48,base.y-h*0.68)]), c1)

# ── Water ──────────────────────────────────────────────────────
func _draw_water() -> void:
	draw_rect(Rect2(LAND_X-4, WATER_Y, W-LAND_X+4, H-WATER_Y), Color(0.05,0.26,0.60))
	draw_rect(Rect2(LAND_X-4, WATER_Y, W-LAND_X+4, 45),         Color(0.09,0.36,0.74))
	draw_rect(Rect2(LAND_X-4, WATER_Y, W-LAND_X+4, 5),          Color(0.50,0.78,1.0,0.55))
	for i in range(7):
		var by  = WATER_Y + 14.0 + i * 16.0
		var col = Color(0.20,0.58,0.90, 0.34 - i*0.04)
		for x in range(int(LAND_X), int(W)-4, 5):
			var wy = by + sin(float(x)*0.04 + wave_time*2.1 + float(i)*1.3) * 2.5
			draw_rect(Rect2(x, wy, 16, 2), col)
	draw_rect(Rect2(LAND_X-4, H-28, W-LAND_X+4, 28), Color(0.02,0.16,0.40))
