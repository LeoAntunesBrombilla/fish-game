extends Node2D

# ── State machine ──────────────────────────────────────────────
enum State { MENU, IDLE, FISH_BITING, MINIGAME, RESULT, GAME_OVER }
var state: State = State.MENU

# ── Game data ──────────────────────────────────────────────────
var score: int = 0
var lives: int = 3
var current_fish: FishData.FishType = null

# ── Timers ─────────────────────────────────────────────────────
var idle_timer: float = 0.0
var idle_wait: float = 0.0
var bite_timer: float = 0.0
const BITE_WINDOW: float = 1.5   # harder: was 2.2

# ── Bobber world position ───────────────────────────────────────
const ROD_TIP     := Vector2(145, 416)
const WATER_Y     := 520.0
const WATER_X_MIN := 520.0
const WATER_X_MAX := 1060.0
var bobber_x: float = 800.0

# ── Minigame bar ───────────────────────────────────────────────
var bar_width: float = 300.0
var indicator_pos: float = 0.0
var indicator_dir: float = 1.0

# ── Ripple animation ───────────────────────────────────────────
var ripple_anim: float = 0.0

# ── Node refs ──────────────────────────────────────────────────
@onready var menu_panel     = $UI/MenuPanel
@onready var game_ui        = $UI/GameUI
@onready var status_label   = $UI/GameUI/HBox/StatusLabel
@onready var score_label    = $UI/GameUI/HBox/ScoreLabel
@onready var lives_label    = $UI/GameUI/HBox/LivesLabel
@onready var minigame_panel = $UI/MinigamePanel
@onready var bar_bg         = $UI/MinigamePanel/VBox/BarContainer/BarBG
@onready var catch_zone     = $UI/MinigamePanel/VBox/BarContainer/CatchZone
@onready var indicator      = $UI/MinigamePanel/VBox/BarContainer/Indicator
@onready var minigame_label = $UI/MinigamePanel/VBox/FishLabel
@onready var result_panel   = $UI/ResultPanel
@onready var result_label   = $UI/ResultPanel/ResultLabel
@onready var gameover_panel = $UI/GameOverPanel
@onready var gameover_label = $UI/GameOverPanel/VBox/GameOverLabel
@onready var bobber_node    = $World/Bobber
@onready var ripple_node    = $World/Ripple
@onready var fish_line      = $World/FishLine

# ── Ready ──────────────────────────────────────────────────────
func _ready():
	randomize()
	_show_menu()

# ── Input ──────────────────────────────────────────────────────
func _input(event):
	match state:
		State.FISH_BITING:
			if event is InputEventMouseButton and event.pressed:
				var click_rect = Rect2(bobber_x - 28, WATER_Y - 22, 56, 44)
				if click_rect.has_point(event.position):
					_start_minigame()
		State.MINIGAME:
			if event is InputEventKey and event.pressed and not event.echo:
				if event.keycode == KEY_SPACE:
					_evaluate_cast()

# ── Process ────────────────────────────────────────────────────
func _process(delta):
	match state:
		State.IDLE:
			idle_timer += delta
			if idle_timer >= idle_wait:
				_fish_bites()

		State.FISH_BITING:
			bite_timer += delta
			ripple_anim += delta * 10.0
			var s = 1.0 + sin(ripple_anim) * 0.3
			ripple_node.scale = Vector2(s, s)
			if bite_timer >= BITE_WINDOW:
				_miss()

		State.MINIGAME:
			indicator_pos += current_fish.bar_speed * indicator_dir * delta
			if indicator_pos >= bar_width - indicator.size.x:
				indicator_pos = bar_width - indicator.size.x
				indicator_dir = -1.0
			elif indicator_pos <= 0:
				indicator_pos = 0
				indicator_dir = 1.0
			indicator.position.x = indicator_pos

# ── Bobber + line helpers ───────────────────────────────────────
func _place_bobber(bx: float):
	bobber_x = bx
	bobber_node.position = Vector2(bx, WATER_Y)
	ripple_node.position = Vector2(bx, WATER_Y)
	fish_line.points = PackedVector2Array([ROD_TIP, Vector2(bx, WATER_Y - 4.0)])

# ── State transitions ──────────────────────────────────────────
func _show_menu():
	state = State.MENU
	menu_panel.visible    = true
	game_ui.visible       = false
	minigame_panel.visible = false
	result_panel.visible  = false
	gameover_panel.visible = false
	ripple_node.visible   = false
	_place_bobber(800.0)

func _start_game():
	score = 0
	lives = 3
	menu_panel.visible    = false
	gameover_panel.visible = false
	result_panel.visible  = false
	game_ui.visible       = true
	_update_hud()
	_go_idle()

func _go_idle():
	state = State.IDLE
	idle_timer = 0.0
	idle_wait  = randf_range(2.0, 5.0)   # harder: was 3-7
	ripple_node.visible    = false
	minigame_panel.visible = false
	result_panel.visible   = false
	status_label.text = "Aguardando..."

func _fish_bites():
	state = State.FISH_BITING
	bite_timer  = 0.0
	ripple_anim = 0.0
	var bx = randf_range(WATER_X_MIN, WATER_X_MAX)
	_place_bobber(bx)
	ripple_node.visible = true
	status_label.text = "Clique na bolha!"

func _miss():
	lives -= 1
	_update_hud()
	ripple_node.visible = false
	if lives <= 0:
		_game_over()
	else:
		_show_result("Voce perdeu o peixe!", Color.RED)

func _start_minigame():
	state = State.MINIGAME
	ripple_node.visible = false
	current_fish = FishData.pick_random()
	indicator_pos = 0.0
	indicator_dir = 1.0
	minigame_panel.visible = true
	await get_tree().process_frame
	bar_width = bar_bg.size.x
	var zone_w  = bar_width * current_fish.zone_ratio
	var zone_x  = randf_range(0.0, bar_width - zone_w)
	catch_zone.size     = Vector2(zone_w, bar_bg.size.y)
	catch_zone.position = Vector2(zone_x, 0.0)
	indicator.size      = Vector2(8.0, bar_bg.size.y)
	indicator.position  = Vector2(0.0, 0.0)
	# color zone by rarity
	match current_fish.rarity:
		FishData.Rarity.EASY:   catch_zone.modulate = Color(0.30, 1.00, 0.40)
		FishData.Rarity.MEDIUM: catch_zone.modulate = Color(0.35, 0.70, 1.00)
		FishData.Rarity.RARE:   catch_zone.modulate = Color(1.00, 0.82, 0.20)
	minigame_label.text = current_fish.name
	status_label.text   = "Pressione ESPACO na hora certa!"

func _evaluate_cast():
	var zone_start  = catch_zone.position.x
	var zone_end    = zone_start + catch_zone.size.x
	var ind_center  = indicator_pos + indicator.size.x / 2.0
	if ind_center >= zone_start and ind_center <= zone_end:
		score += current_fish.points
		_update_hud()
		_show_result(current_fish.name + "! +" + str(current_fish.points) + " pts", Color.GREEN)
	else:
		lives -= 1
		_update_hud()
		if lives <= 0:
			_game_over()
			return
		_show_result("Escapou! -1 vida", Color.RED)

func _show_result(msg: String, color: Color):
	state = State.RESULT
	minigame_panel.visible = false
	result_label.text     = msg
	result_label.modulate = color
	result_panel.visible  = true
	await get_tree().create_timer(1.6).timeout
	if state == State.RESULT:
		_go_idle()

func _game_over():
	state = State.GAME_OVER
	minigame_panel.visible = false
	result_panel.visible   = false
	game_ui.visible        = false
	gameover_label.text    = "Game Over!\nPontuacao: " + str(score)
	gameover_panel.visible = true

func _update_hud():
	score_label.text = "Pontos: " + str(score)
	var hearts = ""
	for i in lives:
		hearts += "<3 "
	lives_label.text = "Vidas: " + hearts.strip_edges()

# ── Button signals ─────────────────────────────────────────────
func _on_start_button_pressed():
	_start_game()

func _on_restart_button_pressed():
	_start_game()
