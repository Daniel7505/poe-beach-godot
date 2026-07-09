extends Node
## Global run state: life, kills, score, XP / level.
## Autoloaded as GameManager.

signal health_changed(current: int, maximum: int)
signal kills_changed(kills: int)
signal score_changed(score: int)
signal xp_changed(xp: int, xp_to_next: int, level: int)
signal leveled_up(level: int)
signal player_died
signal healed(amount: int)

const PLAYER_BASE_MAX_HEALTH := 100
const BASE_XP_TO_LEVEL := 38

var player_max_health: int = PLAYER_BASE_MAX_HEALTH
var player_health: int = PLAYER_BASE_MAX_HEALTH
var kills: int = 0
var score: int = 0
var xp: int = 0
var level: int = 1
var player: Node2D = null

## Back-compat alias for older call sites
var PLAYER_MAX_HEALTH: int:
	get:
		return player_max_health


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	player_max_health = PLAYER_BASE_MAX_HEALTH
	player_health = player_max_health
	kills = 0
	score = 0
	xp = 0
	level = 1
	health_changed.emit(player_health, player_max_health)
	kills_changed.emit(kills)
	score_changed.emit(score)
	xp_changed.emit(xp, xp_to_next_level(), level)


func register_player(p: Node2D) -> void:
	player = p
	health_changed.emit(player_health, player_max_health)
	xp_changed.emit(xp, xp_to_next_level(), level)


func xp_to_next_level() -> int:
	return BASE_XP_TO_LEVEL + (level - 1) * 28


func increase_max_health(amount: int, also_heal: bool = true) -> void:
	player_max_health += amount
	if also_heal:
		player_health = mini(player_max_health, player_health + amount)
	health_changed.emit(player_health, player_max_health)


func apply_damage(amount: int) -> void:
	if player_health <= 0:
		return
	player_health = maxi(0, player_health - amount)
	health_changed.emit(player_health, player_max_health)
	if player_health <= 0:
		player_died.emit()


func heal(amount: int) -> void:
	if player_health <= 0:
		return
	var before := player_health
	player_health = mini(player_max_health, player_health + amount)
	var gained := player_health - before
	health_changed.emit(player_health, player_max_health)
	if gained > 0:
		healed.emit(gained)


func register_kill(points: int = 10) -> void:
	kills += 1
	score += points
	kills_changed.emit(kills)
	score_changed.emit(score)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	score += amount  # XP also feeds score slightly
	score_changed.emit(score)
	# Level loop (rare multi-level from big orbs)
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		heal(12)
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next_level(), level)
