extends Area2D
## Shared projectile base: travels in a direction, damages enemies, then frees.

const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")

@export var speed: float = 420.0
@export var lifetime: float = 0.9
@export var pierce: int = 1
@export var knockback: float = 80.0
@export var spawn_hit_sparks: bool = true

var damage: int = 10
var direction: Vector2 = Vector2.RIGHT
var owner_node: Node = null
var _hits_left: int = 1
var _age: float = 0.0
var _hit_ids: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func launch(from: Vector2, dir: Vector2, dmg: int, owner: Node = null, pierce_override: int = -1) -> void:
	global_position = from
	direction = dir.normalized()
	damage = dmg
	owner_node = owner
	_hits_left = pierce if pierce_override < 0 else pierce_override
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _on_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent:
		_try_hit(parent)


func _try_hit(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target == owner_node:
		return
	if target.is_in_group("player"):
		return
	if not target.is_in_group("enemies"):
		if target is StaticBody2D:
			queue_free()
		return
	var id := target.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if target.has_method("apply_damage"):
		target.apply_damage(damage, direction * knockback)
		if has_node("/root/Sfx"):
			Sfx.play("hit", randf_range(0.92, 1.08), 0.0)
		if spawn_hit_sparks:
			_spawn_hit_fx(target.global_position if target is Node2D else global_position)
		_hits_left -= 1
		if _hits_left <= 0:
			queue_free()


func _spawn_hit_fx(at: Vector2) -> void:
	var parent: Node = get_tree().get_first_node_in_group("vfx_layer")
	if parent == null:
		parent = get_parent()
	if parent:
		ParticleFactory.make_hit_sparks(parent, at, direction)
