# Fish Game

A 2D fishing game built in **Godot 4.6** using **GDScript**.
Single scene, no external assets — everything is drawn with code.

---

## How to Play

| Action | Control |
|--------|---------|
| React to fish bite | **Mouse click** on the ripple in the water |
| Strike the bar | **Space bar** when the indicator is in the colored zone |

- You start with **3 lives**
- Missing the ripple or failing the bar = **-1 life**
- Lose all 3 lives = **Game Over**

---

## Project Structure

```
fish-game/
├── scenes/
│   └── Main.tscn          # The only scene in the game
├── scripts/
│   ├── Main.gd            # Brain of the game — state machine + logic
│   ├── FishData.gd        # Fish types, rarities, stats
│   ├── WorldDraw.gd       # Draws the background (sky, water, trees...)
│   ├── FishermanDraw.gd   # Draws the fisherman character
│   ├── BobberDraw.gd      # Draws the animated bobber
│   └── RippleDraw.gd      # Draws the ripple rings when fish bites
└── project.godot
```

---

## Scene Tree (Main.tscn)

```
Main  (Node2D)  ← Main.gd is attached here
├── World  (Node2D)
│   ├── WorldDraw     ← draws background via _draw()
│   ├── FishLine      ← Line2D, connects rod tip to bobber
│   ├── Fisherman     ← drawn via _draw(), animated pipe smoke
│   ├── Bobber        ← drawn via _draw(), bobs on water
│   └── Ripple        ← drawn via _draw(), visible only when fish bites
└── UI  (CanvasLayer)  ← all interface, draws on top of everything
    ├── MenuPanel      ← title screen
    ├── GameUI         ← HUD: lives / score / status
    ├── MinigamePanel  ← the catch bar
    ├── ResultPanel    ← catch/miss message (auto-hides after 1.6s)
    └── GameOverPanel  ← final score + restart button
```

**Why CanvasLayer for UI?**
`CanvasLayer` draws its children in their own 2D layer, always on top of
the world regardless of camera movement or world node positions.

---

## Main.gd — The State Machine

This is the most important file. The entire game runs through **6 states**:

```
MENU → IDLE → FISH_BITING → MINIGAME → RESULT → back to IDLE
                                                      ↓ (on 3rd fail)
                                                  GAME_OVER
```

### States explained

| State | What happens |
|-------|-------------|
| `MENU` | Title screen is visible, nothing ticks |
| `IDLE` | Waiting for a fish. A random timer counts down (2–5 sec) |
| `FISH_BITING` | Ripple appears. Player has **1.5 seconds** to click it |
| `MINIGAME` | The bar is shown. Space bar stops the indicator |
| `RESULT` | Shows win/lose message for 1.6 seconds, then back to IDLE |
| `GAME_OVER` | Shows final score and restart button |

### Key variables

```gdscript
var state: State          # which state we're in right now

var score: int            # total points accumulated
var lives: int            # starts at 3, game over at 0

var idle_timer: float     # counts up during IDLE
var idle_wait:  float     # random target (2–5s) — when reached, fish bites

var bite_timer: float     # counts up during FISH_BITING
const BITE_WINDOW = 1.5   # player has this many seconds to click the ripple

var bar_width:     float  # actual pixel width of the bar (read after layout)
var indicator_pos: float  # current X position of the yellow indicator (0..bar_width)
var indicator_dir: float  # +1 = moving right, -1 = moving left

var bobber_x: float       # current X position of the bobber in world space
const WATER_Y  = 520.0    # Y coordinate of the water surface
const ROD_TIP  = Vector2(145, 416)  # where the fishing line starts
```

### Key functions

```
_ready()              → called once at startup, shows the menu

_input(event)         → listens for:
                          - mouse click (FISH_BITING state) → checks if click hit ripple
                          - space bar   (MINIGAME state)    → evaluates bar position

_process(delta)       → called every frame, drives:
                          - IDLE:         counts idle_timer
                          - FISH_BITING:  counts bite_timer, animates ripple scale
                          - MINIGAME:     moves indicator left/right

_place_bobber(bx)     → moves bobber + ripple + redraws fishing line to new X position

_show_menu()          → switches to MENU state, shows menu panel
_start_game()         → resets score/lives, switches to IDLE
_go_idle()            → switches to IDLE, starts a new random wait timer
_fish_bites()         → picks a random X on the water, shows ripple
_miss()               → deducts a life, goes to RESULT or GAME_OVER
_start_minigame()     → picks a random fish, sets up the bar, switches to MINIGAME
_evaluate_cast()      → checks if indicator center is inside the catch zone
_show_result(msg)     → shows message panel, waits 1.6s, returns to IDLE
_game_over()          → shows game over panel
_update_hud()         → refreshes lives and score labels
```

### How _evaluate_cast works

```
Bar:  [-------|=====|----------]
       0    zone_start  zone_end   bar_width
                  ↑
            catch zone (colored)

indicator center = indicator_pos + 4  (half of 8px width)

if center is inside [zone_start, zone_end] → caught!
else → miss
```

---

## FishData.gd — Fish Types

Uses a **class_name** so it can be referenced anywhere without instancing.

```gdscript
class_name FishData          # registered globally in the project
enum Rarity { EASY, MEDIUM, RARE }

class FishType:              # inner class, like a data struct
    var name:         String
    var rarity:       Rarity
    var points:       int
    var zone_ratio:   float  # 0.0–1.0, fraction of bar that is "safe"
    var bar_speed:    float  # pixels/sec the indicator moves
    var spawn_weight: int    # probability weight
```

### Fish table

| Fish | Rarity | Zone | Speed | Points | Spawn chance |
|------|--------|------|-------|--------|-------------|
| Peixe Comum | Easy | 32% of bar | 220 px/s | 10 | 70% |
| Baixo | Medium | 17% of bar | 340 px/s | 25 | 25% |
| Carpa Dourada | Rare | 8% of bar | 500 px/s | 50 | 5% |

### pick_random() — weighted random

```gdscript
# total weight = 70 + 25 + 5 = 100
# roll a number 0..99
# 0–69  → Peixe Comum
# 70–94 → Baixo
# 95–99 → Carpa Dourada
```

---

## Drawing Scripts

All visual elements are drawn in code using Godot's `_draw()` system.

### How _draw() works in Godot

```gdscript
func _draw():
    draw_rect(Rect2(x, y, width, height), color)
    draw_circle(Vector2(x, y), radius, color)
    draw_line(from, to, color, width)
    draw_colored_polygon(PackedVector2Array([...]), color)
    draw_arc(center, radius, start_angle, end_angle, segments, color, width)
```

`_draw()` runs once. To animate, call `queue_redraw()` every frame from `_process()`.

### WorldDraw.gd

Draws the entire background every frame (animated water + drifting clouds).

```
Sky       → big rect + subtle horizon glow bands
Clouds    → 4 clouds made of overlapping circles, slowly drift right
Mountains → draw_colored_polygon() triangles, layered (far=faded, near=dark)
            + small white snow cap triangles on the tallest peaks
Land      → dirt rect + two grass rects + cliff edge
Trees     → 6 pine trees, each with trunk rect + 3 triangle foliage layers
Water     → dark base rect + 7 rows of short animated wave rects
            (each row uses sin() with different phase for wavy motion)
```

**Wave animation:**
```gdscript
# For each wave row i, for each x position:
var wy = base_y + sin(x * 0.04 + wave_time * 2.1 + i * 1.3) * 2.5
# x * 0.04   → horizontal frequency (how many waves fit across screen)
# wave_time  → makes the waves move over time
# i * 1.3    → offsets each row so they don't all move in sync
```

### FishermanDraw.gd

Draws the fisherman character. Node is positioned at `Vector2(95, 516)` —
local `(0, 0)` = feet on the ground.

```
Boots → 2 dark brown rects
Legs  → 2 dark purple rects
Belt  → thin dark rect
Shirt → blue rect + white collar
Arms  → draw_line() (left arm hangs, right arm raised holding rod)
Head  → draw_circle() skin tone
Eyes  → 2 small circles + pupils
Smile → draw_arc() (partial circle)
Hat   → brim rect + crown rect + band rect
Pipe  → horizontal line (stem) + small rect (bowl)
Smoke → 3 animated circles rising from pipe, fading out
Rod   → 3 draw_line() segments, tapering in width (4→3→2 px)
```

**Idle sway:**
```gdscript
var sway := sin(idle_time * 1.1) * 0.6
# Applied to head, hat, eyes, pipe → subtle breathing/rocking motion
```

### BobberDraw.gd

Node positioned at `Vector2(bobber_x, WATER_Y)` by Main.gd.
Local `(0, 0)` = water surface.

```
Antenna → vertical line above bobber
Red top → PackedVector2Array semicircle (angles PI to 2*PI = upper half)
White bottom → PackedVector2Array semicircle (angles 0 to PI = lower half)
Outline → draw_arc() full circle
Center line → draw_line() horizontal separator
Shadow → flattened ellipse below bobber
```

**Bob animation:**
```gdscript
var bob := sin(bob_time) * 2.2   # ±2.2 pixels vertical movement
# Applied to the bobber center position each frame
```

### RippleDraw.gd

Same position as bobber. Visible only in `FISH_BITING` state.

```
3 rings drawn as ellipses (wide horizontally, flat vertically = water perspective)
Each ring has a different phase offset so they expand at different times
As phase goes 0→1: ring grows larger AND becomes more transparent
```

---

## Common Godot Concepts Used

**`@onready`** — gets a reference to a node when the scene is ready:
```gdscript
@onready var score_label = $UI/GameUI/HBox/ScoreLabel
# $ is shorthand for get_node()
# The path follows the scene tree from the script's node
```

**`delta`** — time since last frame (in seconds). Always multiply speeds by delta:
```gdscript
indicator_pos += bar_speed * indicator_dir * delta
# Without delta, the game runs faster/slower on different computers
```

**`await`** — pauses a function and resumes later:
```gdscript
await get_tree().create_timer(1.6).timeout   # wait 1.6 seconds
await get_tree().process_frame               # wait exactly one frame
```

**`match`** — like switch/case, used for the state machine:
```gdscript
match state:
    State.IDLE:
        # ...
    State.MINIGAME:
        # ...
```

**`randf_range(a, b)`** — random float between a and b
**`randi() % n`** — random integer from 0 to n-1

---

## Want to Tweak?

| What | Where | Variable/line |
|------|-------|---------------|
| Fish bite window | `Main.gd` | `BITE_WINDOW = 1.5` |
| Wait between bites | `Main.gd` | `randf_range(2.0, 5.0)` in `_go_idle()` |
| Fish spawn chances | `FishData.gd` | `spawn_weight` (70 / 25 / 5) |
| Bar speeds | `FishData.gd` | `bar_speed` (220 / 340 / 500) |
| Zone sizes | `FishData.gd` | `zone_ratio` (0.32 / 0.17 / 0.08) |
| Fish points | `FishData.gd` | `points` (10 / 25 / 50) |
| Add a new fish | `FishData.gd` | Add a line in `get_all()` |
| Water wave speed | `WorldDraw.gd` | `wave_time * 2.1` in `_draw_water()` |
| Bobber bob speed | `BobberDraw.gd` | `bob_time += delta * 2.6` |
# fish-game
