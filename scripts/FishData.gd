extends Node

class_name FishData

enum Rarity { EASY, MEDIUM, RARE }

class FishType:
	var name: String
	var rarity: Rarity
	var points: int
	var zone_ratio: float  # fraction of bar that is the catch zone (0.0 - 1.0)
	var bar_speed: float   # pixels per second
	var spawn_weight: int  # higher = more common

	func _init(n: String, r: Rarity, p: int, z: float, s: float, w: int):
		name = n
		rarity = r
		points = p
		zone_ratio = z
		bar_speed = s
		spawn_weight = w

static func get_all() -> Array:
	return [
		FishType.new("Peixe Comum",   Rarity.EASY,   10, 0.32, 220.0, 70),
		FishType.new("Baixo",         Rarity.MEDIUM,  25, 0.17, 340.0, 25),
		FishType.new("Carpa Dourada", Rarity.RARE,    50, 0.08, 500.0,  5),
	]

static func pick_random() -> FishType:
	var all := get_all()
	var total := 0
	for f in all:
		total += f.spawn_weight
	var roll := randi() % total
	var acc := 0
	for f in all:
		acc += f.spawn_weight
		if roll < acc:
			return f
	return all[0]
