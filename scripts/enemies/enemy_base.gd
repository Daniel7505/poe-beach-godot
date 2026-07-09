extends CharacterBody2D
## Coastal monster AI: idle → wander → chase → attack, with separation, leashing, and sprite anims.

signal died(enemy: Node)

enum State { IDLE, WANDER, CHASE, ATTACK, RECOVER }

@export var max_health: int = 30
@export var move_speed: float = 70.0
@export var contact_damage: int = 8
@export var score_value: int = 10
@export var aggro_range: float = 320.0
@export var leash_range: float = 420.0
@export var attack_range: float = 22.0
@export var attack_cooldown: float = 0.7
@export var attack_windup: float = 0.22
@export var prefer_flank: bool = false
@export var prefer_kite: bool = false
@export var kite_distance: float = 140.0
@export var charge_attack: bool = false
@export var charge_speed: float = 220.0
@export var death_tint: Color = Color(0.85, 0.4, 0.28)

var health: int = 30
var _state: State = State.IDLE
var _attack_cd: float = 0.0
var _windup_t: float = 0.0
var _state_t: float = 0.0
var _wander_dir: Vector2 = Vector2.RIGHT
var _knockback: Vector2 = Vector2.ZERO
var _alive: bool = true
var _flash: float = 0.0
var _spawn_pos: Vector2 = Vector2.ZERO
var _flank_sign: float = 1.0
var _face: float = 1.0
var _charge_dir: Vector2 = Vector2.ZERO
var _charging: bool = false

@onready var visual: Node2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar
@onready var sprite: AnimatedSprite2D = get_node_or_null("Visual/Sprite") as AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	health = max_health
	_spawn_pos = global_position
	_flank_sign = 1.0 if randf() > 0.5 else -1.0
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
	_style_health_bar()
	_update_health_bar()
	_enter(State.IDLE)


func _style_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.show_percentage = false
	# Compact dark red PoE-ish bar
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.08, 0.08, 0.85)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.75, 0.15, 0.12, 1)
	fill.set_corner_radius_all(2)
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)


func get_contact_damage() -> int:
	if not _alive or _attack_cd > 0.0:
		return 0
	_attack_cd = attack_cooldown
	return contact_damage


func apply_damage(amount: int, knock: Vector2 = Vector2.ZERO) -> void:
	if not _alive:
		return
	health = maxi(0, health - amount)
	_knockback = knock
	_flash = 0.12
	if _state == State.IDLE or _state == State.WANDER:
		_enter(State.CHASE)
	_update_health_bar()
	if health <= 0:
		_die()


func _die() -> void:
	_alive = false
	GameManager.register_kill(score_value)
	died.emit(self)
	if has_node("/root/Sfx"):
		Sfx.play("death", randf_range(0.9, 1.1), -1.0)
	_spawn_death_vfx()
	_drop_xp_orb()
	_maybe_drop_flask()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.parallel().tween_property(self, "scale", Vector2(1.15, 0.75), 0.15)
	tw.tween_callback(queue_free)


func _loot_root() -> Node:
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_method("get_loot_root"):
		return get_parent().get_parent().get_loot_root()
	if get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("Loot"):
		return get_parent().get_parent().get_node("Loot")
	return null


func _drop_xp_orb() -> void:
	const XpOrbScene = preload("res://scenes/loot/xp_orb.tscn")
	var loot_root := _loot_root()
	if loot_root == null:
		return
	# 1–2 orbs based on score value
	var count := 1 if score_value < 20 else 2
	for i in count:
		var orb := XpOrbScene.instantiate()
		loot_root.add_child(orb)
		orb.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-10, 10))
		var xp_amt := maxi(5, score_value / 2 + randi_range(0, 4))
		if orb.has_method("setup"):
			orb.setup(xp_amt)
		else:
			orb.xp_amount = xp_amt


func _maybe_drop_flask() -> void:
	if randf() > 0.16:
		return
	const LifeFlaskScene = preload("res://scenes/loot/life_flask.tscn")
	var loot_root := _loot_root()
	if loot_root == null:
		return
	var flask := LifeFlaskScene.instantiate()
	loot_root.add_child(flask)
	flask.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-4, 4))
	flask.heal_amount = 20


func _spawn_death_vfx() -> void:
	const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")
	var parent: Node = get_tree().current_scene
	var vfx := get_tree().get_first_node_in_group("vfx_layer")
	if vfx:
		parent = vfx
	elif get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("Vfx"):
		parent = get_parent().get_parent().get_node("Vfx")
	ParticleFactory.make_death_burst(parent, global_position, death_tint)


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = health < max_health


func _enter(s: State) -> void:
	_state = s
	_state_t = 0.0
	match s:
		State.IDLE:
			_state_t = randf_range(0.4, 1.2)
			_play_anim("idle")
		State.WANDER:
			_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
			_state_t = randf_range(0.8, 1.8)
			_play_anim("walk")
		State.CHASE:
			_play_anim("walk")
		State.ATTACK:
			_windup_t = attack_windup
			_charging = false
			velocity = Vector2.ZERO
			_play_anim("attack")
			if charge_attack and GameManager.player and is_instance_valid(GameManager.player):
				_charge_dir = (GameManager.player.global_position - global_position).normalized()
				if _charge_dir == Vector2.ZERO:
					_charge_dir = Vector2.RIGHT
		State.RECOVER:
			_state_t = 0.28
			_charging = false
		_:
			pass


func _play_anim(name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(name):
		return
	if sprite.animation != name or not sprite.is_playing():
		sprite.play(name)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_state_t = maxf(0.0, _state_t - delta)

	if _flash > 0.0:
		_flash -= delta
		if visual:
			visual.modulate = Color(2.0, 2.0, 2.0)
	else:
		if visual:
			visual.modulate = Color.WHITE

	var player := GameManager.player
	var to_player := Vector2.ZERO
	var dist := INF
	if player and is_instance_valid(player):
		to_player = player.global_position - global_position
		dist = to_player.length()

	var desired := Vector2.ZERO

	match _state:
		State.IDLE:
			desired = Vector2.ZERO
			if dist < aggro_range:
				_enter(State.CHASE)
			elif _state_t <= 0.0:
				_enter(State.WANDER)

		State.WANDER:
			desired = _wander_dir * move_speed * 0.45
			if dist < aggro_range:
				_enter(State.CHASE)
			elif _state_t <= 0.0:
				_enter(State.IDLE)

		State.CHASE:
			if player == null or not is_instance_valid(player):
				_enter(State.IDLE)
			elif dist > leash_range or global_position.distance_to(_spawn_pos) > leash_range * 1.1:
				var home := _spawn_pos - global_position
				if home.length() < 12.0:
					_enter(State.IDLE)
				else:
					desired = home.normalized() * move_speed * 0.8
			elif dist <= attack_range and _attack_cd <= 0.0:
				_enter(State.ATTACK)
			else:
				desired = _chase_steer(to_player, dist)

		State.ATTACK:
			_windup_t -= delta
			if visual:
				var w := clampf(1.0 - _windup_t / maxf(attack_windup, 0.01), 0.0, 1.0)
				visual.scale = Vector2(_face * (1.0 + w * 0.12), 1.0 - w * 0.08)
			if charge_attack:
				# Telegraph then sprint
				if _windup_t > 0.0:
					desired = Vector2.ZERO
				else:
					_charging = true
					desired = _charge_dir * charge_speed
					if player and is_instance_valid(player) and dist <= attack_range * 1.2:
						if player.has_method("take_hit"):
							player.take_hit(contact_damage)
						_knockback = _charge_dir * 40.0
						_attack_cd = attack_cooldown
						if visual:
							visual.scale = Vector2(_face, 1.0)
						_enter(State.RECOVER)
					elif _windup_t < -0.35:
						_attack_cd = attack_cooldown
						if visual:
							visual.scale = Vector2(_face, 1.0)
						_enter(State.RECOVER)
			else:
				desired = Vector2.ZERO
				if _windup_t <= 0.0:
					_on_melee_connect(player, to_player, dist)
					_attack_cd = attack_cooldown
					if visual:
						visual.scale = Vector2(_face, 1.0)
					_enter(State.RECOVER)

		State.RECOVER:
			desired = Vector2.ZERO
			if visual:
				visual.scale = visual.scale.lerp(Vector2(_face, 1.0), 10.0 * delta)
			if _state_t <= 0.0:
				_enter(State.CHASE if dist < aggro_range else State.IDLE)

	desired += _separation() * move_speed * 0.55

	if desired.x != 0.0 and _state != State.ATTACK:
		_face = -1.0 if desired.x < 0.0 else 1.0
		if sprite:
			sprite.flip_h = _face < 0.0
		if visual:
			visual.scale = Vector2(1.0, 1.0)

	velocity = desired + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()

	if _state == State.WANDER and get_slide_collision_count() > 0:
		_wander_dir = _wander_dir.rotated(randf_range(0.8, 2.4) * (1.0 if randf() > 0.5 else -1.0))


func _on_melee_connect(player: Node, to_player: Vector2, dist: float) -> void:
	if player and is_instance_valid(player) and dist <= attack_range * 1.35:
		if player.has_method("take_hit"):
			player.take_hit(contact_damage)
		if dist > 0.01:
			_knockback = to_player.normalized() * 90.0
	# Optional ranged override hook
	_try_ranged_attack(player)


func _try_ranged_attack(_player: Node) -> void:
	pass  # overridden by spitters


func _chase_steer(to_player: Vector2, dist: float) -> Vector2:
	if dist < 0.001:
		return Vector2.ZERO
	var forward := to_player.normalized()
	if prefer_kite:
		# Hold mid-range: back up if too close, close if too far
		if dist < kite_distance * 0.75:
			return -forward * move_speed
		if dist > kite_distance * 1.15:
			return forward * move_speed * 0.85
		var side := Vector2(-forward.y, forward.x) * _flank_sign
		return side * move_speed * 0.7
	if prefer_flank and dist < aggro_range * 0.65:
		var side := Vector2(-forward.y, forward.x) * _flank_sign
		return (forward * 0.45 + side * 0.9).normalized() * move_speed
	return forward * move_speed


func _separation() -> Vector2:
	var push := Vector2.ZERO
	var count := 0
	for n in get_tree().get_nodes_in_group("enemies"):
		if n == self or not is_instance_valid(n):
			continue
		var d: Vector2 = global_position - n.global_position
		var dist_sq := d.length_squared()
		if dist_sq > 0.01 and dist_sq < 36.0 * 36.0:
			push += d / dist_sq
			count += 1
			if count >= 6:
				break
	if push != Vector2.ZERO:
		return push.normalized()
	return Vector2.ZERO
