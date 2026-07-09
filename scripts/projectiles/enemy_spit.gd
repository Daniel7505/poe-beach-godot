extends Area2D
## Simple enemy spit bolt — damages the player on contact.

@export var speed: float = 210.0
@export var lifetime: float = 2.2
@export var damage: int = 9

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Visual spin
	if has_node("Visual"):
		var tw := create_tween().set_loops()
		tw.tween_property($Visual, "rotation", TAU, 0.4).as_relative()


func launch(from: Vector2, dir: Vector2, dmg: int = 9) -> void:
	global_position = from
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = dmg
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
