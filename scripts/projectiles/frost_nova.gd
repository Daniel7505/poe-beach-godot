extends Area2D
## Q skill: expanding frost ring that damages and lightly knocks back enemies.

@export var max_radius: float = 78.0
@export var expand_time: float = 0.28
@export var lifetime: float = 0.4

var damage: int = 22
var owner_node: Node = null
var _age: float = 0.0
var _hit: Dictionary = {}  # instance_id -> true

@onready var visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true


func activate(from: Vector2, dmg: int, owner: Node = null, radius_scale: float = 1.0) -> void:
	global_position = from
	damage = dmg
	owner_node = owner
	_age = 0.0
	var rs := clampf(radius_scale, 0.75, 2.0)
	scale = Vector2(0.15, 0.15) * rs
	# Final expand still uses scale animation; bake radius into base scale target
	set_meta("radius_scale", rs)
	modulate = Color(0.55, 0.85, 1.0, 0.85)
	await get_tree().physics_frame
	_damage_overlaps()


func _physics_process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / expand_time, 0.0, 1.0)
	var rs: float = float(get_meta("radius_scale", 1.0))
	var s := lerpf(0.15, 1.0, ease(t, 0.35)) * rs
	scale = Vector2(s, s)
	modulate.a = lerpf(0.9, 0.0, clampf((_age - expand_time * 0.5) / maxf(lifetime - expand_time * 0.5, 0.01), 0.0, 1.0))
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _damage_overlaps() -> void:
	for body in get_overlapping_bodies():
		_try_hit(body)


func _try_hit(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target == owner_node or target.is_in_group("player"):
		return
	if not target.is_in_group("enemies"):
		return
	var id := target.get_instance_id()
	if _hit.has(id):
		return
	_hit[id] = true
	if target.has_method("apply_damage"):
		var dir: Vector2 = (target.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		target.apply_damage(damage, dir * 140.0)
		if has_node("/root/Sfx"):
			Sfx.play("hit", randf_range(1.05, 1.2), -4.0)
