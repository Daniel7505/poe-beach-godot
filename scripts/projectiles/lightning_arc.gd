extends Node2D
## Level-4 unlock: instant arcs from player to nearest enemies.

@export var max_targets: int = 3
@export var range_px: float = 160.0
@export var damage: int = 22

var _age: float = 0.0
var _lifetime: float = 0.28
var _lines: Array[PackedVector2Array] = []


func activate(from: Vector2, dmg: int, max_t: int = 3, range: float = 160.0) -> void:
	global_position = from
	damage = dmg
	max_targets = max_t
	range_px = range
	_find_and_hit()
	queue_redraw()


func _find_and_hit() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var candidates: Array = []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d <= range_px:
			candidates.append({"n": e, "d": d})
	candidates.sort_custom(func(a, b): return a["d"] < b["d"])

	var count := mini(max_targets, candidates.size())
	var origin := Vector2.ZERO  # local
	for i in count:
		var enemy: Node2D = candidates[i]["n"]
		var to_local: Vector2 = to_local(enemy.global_position)
		_lines.append(PackedVector2Array([origin, to_local]))
		if enemy.has_method("apply_damage"):
			var dir := (enemy.global_position - global_position).normalized()
			enemy.apply_damage(damage, dir * 100.0)
		origin = to_local  # chain visually to next


func _process(delta: float) -> void:
	_age += delta
	modulate.a = 1.0 - (_age / _lifetime)
	queue_redraw()
	if _age >= _lifetime:
		queue_free()


func _draw() -> void:
	for line in _lines:
		if line.size() < 2:
			continue
		# Jagged lightning
		var a: Vector2 = line[0]
		var b: Vector2 = line[1]
		var mid := a.lerp(b, 0.5)
		var perp := (b - a).orthogonal().normalized() * randf_range(-10.0, 10.0)
		var jag := mid + perp
		draw_line(a, jag, Color(0.7, 0.9, 1.0, 0.95), 2.5)
		draw_line(jag, b, Color(0.55, 0.8, 1.0, 0.9), 2.2)
		draw_circle(b, 4.0, Color(0.85, 0.95, 1.0, 0.8))
