extends Node2D
## Main entry: coast setup, varied enemy packs, day/night binding.

const PlayerScene := preload("res://scenes/player/player.tscn")
const CrabScene := preload("res://scenes/enemies/crab.tscn")
const ZombieScene := preload("res://scenes/enemies/zombie.tscn")
const SpitScene := preload("res://scenes/enemies/spit_crawler.tscn")
const ChargerScene := preload("res://scenes/enemies/sand_charger.tscn")
const LifeFlaskScene := preload("res://scenes/loot/life_flask.tscn")

@onready var coast_map: Node2D = $CoastMap
@onready var hud: CanvasLayer = $HUD
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var day_night: Node = $DayNightCycle

const CRAB_COUNT := 7
const ZOMBIE_COUNT := 4
const SPITTER_COUNT := 4
const CHARGER_COUNT := 3
const FLASK_COUNT := 5


func _ready() -> void:
	await get_tree().process_frame
	_setup_day_night()
	_spawn_player()
	_spawn_enemies()
	_spawn_flasks()


func _setup_day_night() -> void:
	var sky: Array = []
	if coast_map.has_method("get_atmosphere"):
		var atm = coast_map.get_atmosphere()
		if atm and atm.has_method("get_sky_nodes"):
			sky = atm.get_sky_nodes()
	if day_night.has_method("setup"):
		day_night.setup(canvas_modulate, null, sky)


func _spawn_player() -> void:
	var player := PlayerScene.instantiate()
	coast_map.get_entities_root().add_child(player)
	player.global_position = coast_map.player_spawn
	player.setup(coast_map.get_projectiles_root(), coast_map)
	if hud.has_method("bind_player"):
		hud.bind_player(player)
	if player.has_node("HeroLight") and day_night.has_method("bind_hero_light"):
		day_night.bind_hero_light(player.get_node("HeroLight"))


func _spawn_enemies() -> void:
	var total := CRAB_COUNT + ZOMBIE_COUNT + SPITTER_COUNT + CHARGER_COUNT + 10
	var spawn_pts: Array[Vector2] = coast_map.find_sand_positions(
		total,
		coast_map.player_spawn,
		160.0  # farther clear radius with 64px tiles
	)
	var i := 0
	i = _spawn_batch(CrabScene, CRAB_COUNT, spawn_pts, i)
	i = _spawn_batch(ZombieScene, ZOMBIE_COUNT, spawn_pts, i)
	i = _spawn_batch(SpitScene, SPITTER_COUNT, spawn_pts, i)
	i = _spawn_batch(ChargerScene, CHARGER_COUNT, spawn_pts, i)


func _spawn_batch(scene: PackedScene, count: int, pts: Array[Vector2], start_i: int) -> int:
	var i := start_i
	for n in count:
		if i >= pts.size():
			break
		var e := scene.instantiate()
		coast_map.get_entities_root().add_child(e)
		e.global_position = pts[i]
		i += 1
	return i


func _spawn_flasks() -> void:
	var pts: Array[Vector2] = coast_map.find_sand_positions(
		FLASK_COUNT + 4,
		coast_map.player_spawn,
		80.0
	)
	for i in mini(FLASK_COUNT, pts.size()):
		var flask := LifeFlaskScene.instantiate()
		coast_map.get_loot_root().add_child(flask)
		flask.global_position = pts[i]
