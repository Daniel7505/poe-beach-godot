extends Area2D
## XP orb dropped by enemies — magnetizes, grants XP/score on pickup.

const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")

@export var xp_amount: int = 8
@export var magnet_range: float = 90.0
@export var magnet_speed: float = 220.0

@onready var visual: Polygon2D = $Visual

var _bob_t: float = 0.0
var _picked: bool = false
var _spawn_delay: float = 0.15


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)
	scale = Vector2(0.4, 0.4)
	var pop := create_tween()
	pop.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	pop.tween_property(self, "scale", Vector2.ONE, 0.08)
	var pulse := create_tween().set_loops()
	pulse.tween_property(visual, "modulate", Color(1.4, 1.35, 0.8), 0.35)
	pulse.tween_property(visual, "modulate", Color(0.95, 0.9, 0.55), 0.35)


func setup(amount: int) -> void:
	xp_amount = amount
	# Scale orb slightly with value
	var s := clampf(0.85 + float(amount) * 0.02, 0.85, 1.35)
	scale = Vector2(s, s)


func _process(delta: float) -> void:
	if _picked:
		return
	_spawn_delay = maxf(0.0, _spawn_delay - delta)
	_bob_t += delta * 4.0
	visual.position.y = sin(_bob_t) * 2.5
	visual.rotation += delta * 1.5
	if _spawn_delay <= 0.0:
		_try_magnet(delta)


func _try_magnet(delta: float) -> void:
	var player := GameManager.player
	if player == null or not is_instance_valid(player):
		return
	var d: float = global_position.distance_to(player.global_position)
	if d < magnet_range and d > 1.5:
		var dir := (player.global_position - global_position).normalized()
		var pull := magnet_speed * (1.2 - d / magnet_range)
		global_position += dir * pull * delta


func _on_body_entered(body: Node2D) -> void:
	if _picked or _spawn_delay > 0.0:
		return
	if body.is_in_group("player"):
		_pickup()


func _pickup() -> void:
	_picked = true
	set_deferred("monitoring", false)
	GameManager.add_xp(xp_amount)
	if has_node("/root/Sfx"):
		Sfx.play("xp", randf_range(0.95, 1.1), -2.0)
	var vfx := get_tree().get_first_node_in_group("vfx_layer")
	if vfx == null:
		vfx = get_parent()
	if vfx:
		ParticleFactory.make_xp_burst(vfx, global_position)
		ParticleFactory.spawn_float_text(vfx, global_position, "+%d XP" % xp_amount, Color(1.0, 0.92, 0.45))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)
