extends Area2D
## Ground life flask — heals on pickup with particles + floating text.

const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")

@export var heal_amount: int = 35
@export var magnet_range: float = 42.0
@export var magnet_speed: float = 160.0

@onready var visual: Polygon2D = $Visual

var _bob_t: float = 0.0
var _picked: bool = false


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)
	var tw := create_tween().set_loops()
	tw.tween_property(visual, "modulate", Color(1.35, 1.15, 1.15), 0.45)
	tw.tween_property(visual, "modulate", Color.WHITE, 0.45)
	# Soft land pop
	scale = Vector2(0.6, 0.6)
	var pop := create_tween()
	pop.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12)
	pop.tween_property(self, "scale", Vector2.ONE, 0.1)


func _process(delta: float) -> void:
	if _picked:
		return
	_bob_t += delta * 3.2
	visual.position.y = sin(_bob_t) * 3.0
	visual.rotation = sin(_bob_t * 0.7) * 0.08
	_try_magnet(delta)


func _try_magnet(delta: float) -> void:
	var player := GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var d: float = global_position.distance_to(player.global_position)
	if d < magnet_range and d > 2.0:
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta * (1.0 - d / magnet_range)


func _on_body_entered(body: Node2D) -> void:
	if _picked:
		return
	if body.is_in_group("player"):
		_pickup()


func _pickup() -> void:
	_picked = true
	set_deferred("monitoring", false)
	GameManager.heal(heal_amount)
	if has_node("/root/Sfx"):
		Sfx.play("pickup", randf_range(0.95, 1.05), 0.0)
		Sfx.play("heal", 1.0, -4.0)
	var vfx := get_tree().get_first_node_in_group("vfx_layer")
	if vfx == null:
		vfx = get_parent()
	if vfx:
		ParticleFactory.make_heal_burst(vfx, global_position)
		ParticleFactory.spawn_float_text(vfx, global_position, "+%d" % heal_amount, Color(0.45, 1.0, 0.55))
	# Pop away
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)
