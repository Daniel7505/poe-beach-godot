extends CharacterBody2D
## Exile on The Coast: skills scale with level-up rewards.

signal died
signal attacked(skill_name: String)
signal skill_unlocked(reward: Dictionary)

const ProcSprites = preload("res://scripts/visual/proc_sprites.gd")
const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")
const SkillProgression = preload("res://scripts/player/skill_progression.gd")
const LightningArcScript = preload("res://scripts/projectiles/lightning_arc.gd")

const BASE_SPEED := 205.0
const ACCEL := 1500.0
const FRICTION := 1700.0
const WATER_SPEED_MULT := 0.55
const WATER_ACCEL_MULT := 0.65
const BASE_BASIC_CD := 0.23
const BASE_FIREBALL_CD := 0.72
const BASE_NOVA_CD := 2.7
const BASE_DASH_CD := 1.3
const BASE_ARC_CD := 2.4
const BASE_BASIC_DMG := 14
const BASE_FIREBALL_DMG := 32
const BASE_NOVA_DMG := 25
const BASE_ARC_DMG := 22
const BASE_DASH_SPEED := 580.0
const DASH_TIME := 0.13
const INVULN_TIME := 0.4

@export var basic_attack_scene: PackedScene
@export var fireball_scene: PackedScene
@export var frost_nova_scene: PackedScene

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var weapon: Polygon2D = $AimPivot/Weapon
@onready var camera: Camera2D = $Camera2D
@onready var slash_fx: Polygon2D = $AimPivot/SlashFx
@onready var light: PointLight2D = $HeroLight

var _basic_cd: float = 0.0
var _fireball_cd: float = 0.0
var _nova_cd: float = 0.0
var _dash_cd: float = 0.0
var _arc_cd: float = 0.0
var _invuln: float = 0.0
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _alive: bool = true
var _flash_t: float = 0.0
var _attack_anim_t: float = 0.0
var _coast_map: Node = null
var _facing: float = 1.0
var _was_in_water: bool = false
var _foot_dust: GPUParticles2D
var _water_wake: GPUParticles2D
var _splash_cd: float = 0.0
var _shake: float = 0.0
var _base_zoom: Vector2 = Vector2(1.05, 1.05)
var _hit_pulse: float = 0.0
var _level_glow: float = 0.0

# --- Progression stats (mutated by skill rewards) ---
var move_speed_mult: float = 1.0
var damage_mult: float = 1.0
var basic_dmg: int = BASE_BASIC_DMG
var basic_cd: float = BASE_BASIC_CD
var fireball_dmg: int = BASE_FIREBALL_DMG
var fireball_cd: float = BASE_FIREBALL_CD
var fireball_pierce: int = 3
var fireball_count: int = 1
var nova_dmg: int = BASE_NOVA_DMG
var nova_cd: float = BASE_NOVA_CD
var nova_radius: float = 1.0
var dash_cd: float = BASE_DASH_CD
var dash_speed: float = BASE_DASH_SPEED
var arc_unlocked: bool = false
var arc_dmg: int = BASE_ARC_DMG
var arc_cd_max: float = BASE_ARC_CD
var arc_targets: int = 3
var unlocked_ids: Array[String] = []

var projectiles_root: Node2D = null


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	floor_snap_length = 0.0
	safe_margin = 0.08

	sprite.sprite_frames = ProcSprites.exile_frames()
	sprite.play("idle")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_foot_dust = ParticleFactory.make_foot_dust(self)
	_water_wake = ParticleFactory.make_water_wake(self)

	GameManager.register_player(self)
	GameManager.player_died.connect(_on_player_died)
	GameManager.leveled_up.connect(_on_leveled_up)

	_setup_camera()
	_setup_light()
	slash_fx.visible = false


func setup(proj_root: Node2D, coast_map: Node = null) -> void:
	projectiles_root = proj_root
	_coast_map = coast_map
	if _coast_map and _coast_map.has_method("get_camera_limits"):
		var limits: Rect2 = _coast_map.get_camera_limits()
		camera.limit_left = int(limits.position.x)
		camera.limit_top = int(limits.position.y)
		camera.limit_right = int(limits.position.x + limits.size.x)
		camera.limit_bottom = int(limits.position.y + limits.size.y)
		camera.limit_smoothed = true


func _setup_camera() -> void:
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 12.0
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.07
	camera.drag_right_margin = 0.07
	camera.drag_top_margin = 0.07
	camera.drag_bottom_margin = 0.07
	_base_zoom = Vector2(1.05, 1.05)
	camera.zoom = _base_zoom


func _setup_light() -> void:
	if light.texture == null:
		light.texture = _soft_light_tex(96)
	light.color = Color(1.0, 0.88, 0.7)
	light.energy = 0.55
	light.texture_scale = 3.2
	light.shadow_enabled = false


func _soft_light_tex(size: int) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a *= a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_basic_cd = maxf(0.0, _basic_cd - delta)
	_fireball_cd = maxf(0.0, _fireball_cd - delta)
	_nova_cd = maxf(0.0, _nova_cd - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_arc_cd = maxf(0.0, _arc_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_attack_anim_t = maxf(0.0, _attack_anim_t - delta)
	_hit_pulse = maxf(0.0, _hit_pulse - delta)
	_level_glow = maxf(0.0, _level_glow - delta)

	_update_camera_fx(delta)

	if _level_glow > 0.0:
		visual.modulate = Color(1.35, 1.25, 0.8).lerp(Color.WHITE, 1.0 - _level_glow / 0.6)
	elif _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		visual.modulate = Color(1.5, 0.6, 0.6) if fmod(_flash_t * 12.0, 1.0) < 0.5 else Color.WHITE
	else:
		visual.modulate = Color.WHITE

	if _attack_anim_t > 0.0:
		var t := 1.0 - (_attack_anim_t / 0.16)
		weapon.rotation = lerpf(-1.15, 0.7, ease(t, 0.35))
		weapon.scale = Vector2.ONE * lerpf(1.15, 1.0, t)
		slash_fx.visible = t < 0.75
		slash_fx.modulate.a = 1.0 - t
		slash_fx.scale = Vector2.ONE * lerpf(0.85, 1.25, t)
	else:
		weapon.rotation = 0.0
		weapon.scale = Vector2.ONE
		slash_fx.visible = false

	var mouse := get_global_mouse_position()
	aim_pivot.look_at(mouse)
	var aim_x := mouse.x - global_position.x
	if absf(aim_x) > 2.0:
		_facing = 1.0 if aim_x >= 0.0 else -1.0
		sprite.flip_h = _facing < 0.0

	if _dash_timer > 0.0:
		_dash_timer -= delta
		var dash_t := clampf(_dash_timer / DASH_TIME, 0.0, 1.0)
		velocity = _dash_dir * dash_speed * (0.55 + 0.45 * dash_t)
		move_and_slide()
		_play_anim_if("dash")
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var in_water := _is_in_water()
	var max_speed := BASE_SPEED * move_speed_mult * (WATER_SPEED_MULT if in_water else 1.0)
	var accel := ACCEL * (WATER_ACCEL_MULT if in_water else 1.0)
	var fric := FRICTION * (0.7 if in_water else 1.0)

	if input_dir.length_squared() > 0.01:
		velocity = velocity.move_toward(input_dir.normalized() * max_speed, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, fric * delta)

	move_and_slide()

	_splash_cd = maxf(0.0, _splash_cd - delta)
	_update_movement_vfx(input_dir, in_water)

	if _attack_anim_t <= 0.0:
		if input_dir.length_squared() > 0.01 or velocity.length() > 20.0:
			_play_anim_if("walk")
			visual.position.y = sin(Time.get_ticks_msec() * 0.022) * 1.4
		else:
			_play_anim_if("idle")
			visual.position.y = move_toward(visual.position.y, 0.0, 20.0 * delta)

	if in_water and _level_glow <= 0.0 and _flash_t <= 0.0:
		sprite.modulate = Color(0.85, 0.95, 1.05)
	elif _flash_t <= 0.0 and _level_glow <= 0.0:
		sprite.modulate = Color.WHITE

	if Input.is_action_pressed("basic_attack") and _basic_cd <= 0.0:
		_fire_basic(mouse)
	if Input.is_action_just_pressed("fireball") and _fireball_cd <= 0.0:
		_fire_fireball(mouse)
	if Input.is_action_just_pressed("frost_nova") and _nova_cd <= 0.0:
		_cast_frost_nova()
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_start_dash(input_dir, mouse)
	if arc_unlocked and Input.is_action_just_pressed("lightning_arc") and _arc_cd <= 0.0:
		_cast_arc()


func _update_camera_fx(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 18.0)
		camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 12.0 * delta)
	camera.zoom = camera.zoom.lerp(_base_zoom, 8.0 * delta)


func add_camera_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _play_anim_if(name: String) -> void:
	if sprite.animation != name or not sprite.is_playing():
		sprite.play(name)


func _is_in_water() -> bool:
	if _coast_map and _coast_map.has_method("is_water_at"):
		return _coast_map.is_water_at(global_position)
	return false


func _update_movement_vfx(input_dir: Vector2, in_water: bool) -> void:
	var moving := input_dir.length_squared() > 0.01 or velocity.length() > 30.0
	if _foot_dust:
		_foot_dust.emitting = moving and not in_water
	if _water_wake:
		_water_wake.emitting = moving and in_water
	if in_water and not _was_in_water:
		if _coast_map and _coast_map.has_method("spawn_splash"):
			_coast_map.spawn_splash(global_position + Vector2(0, 8))
	if in_water and moving and _splash_cd <= 0.0:
		_splash_cd = 0.35
		if _coast_map and _coast_map.has_method("spawn_splash") and randf() < 0.45:
			_coast_map.spawn_splash(global_position + Vector2(randf_range(-4, 4), 6))
	_was_in_water = in_water


func _scaled_dmg(base: int) -> int:
	return maxi(1, int(round(float(base) * damage_mult)))


func _fire_basic(target: Vector2) -> void:
	_basic_cd = basic_cd
	_play_attack_anim(0.9)
	add_camera_shake(1.6)
	if has_node("/root/Sfx"):
		Sfx.play("slash", randf_range(0.95, 1.08), -2.0)
	attacked.emit("basic")
	if basic_attack_scene == null or projectiles_root == null:
		return
	var proj := basic_attack_scene.instantiate()
	projectiles_root.add_child(proj)
	var dir := (target - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	velocity += dir * 45.0
	if proj.has_method("launch"):
		proj.launch(muzzle.global_position, dir, _scaled_dmg(basic_dmg), self)


func _fire_fireball(target: Vector2) -> void:
	_fireball_cd = fireball_cd
	_play_attack_anim(1.1)
	add_camera_shake(2.4)
	camera.zoom = _base_zoom * 1.04
	if has_node("/root/Sfx"):
		Sfx.play("fireball", randf_range(0.92, 1.05), 0.0)
	attacked.emit("fireball")
	if fireball_scene == null or projectiles_root == null:
		return
	var dir := (target - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var count := fireball_count
	for i in count:
		var proj := fireball_scene.instantiate()
		projectiles_root.add_child(proj)
		var spread := 0.0
		if count > 1:
			spread = lerpf(-0.18, 0.18, float(i) / float(count - 1))
		var shot_dir := dir.rotated(spread)
		if proj.has_method("launch"):
			proj.launch(muzzle.global_position, shot_dir, _scaled_dmg(fireball_dmg), self, fireball_pierce)


func _cast_frost_nova() -> void:
	_nova_cd = nova_cd
	add_camera_shake(3.0)
	camera.zoom = _base_zoom * 1.06
	if has_node("/root/Sfx"):
		Sfx.play("nova", randf_range(0.95, 1.05), -1.0)
	attacked.emit("nova")
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2(1.22, 1.22), 0.07)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.14)
	if frost_nova_scene == null or projectiles_root == null:
		return
	var nova := frost_nova_scene.instantiate()
	projectiles_root.add_child(nova)
	if nova.has_method("activate"):
		nova.activate(global_position, _scaled_dmg(nova_dmg), self, nova_radius)


func _cast_arc() -> void:
	_arc_cd = arc_cd_max
	add_camera_shake(2.8)
	if has_node("/root/Sfx"):
		Sfx.play("nova", 1.25, -2.0)  # bright zap-ish reuse
	attacked.emit("arc")
	if projectiles_root == null:
		return
	var arc := Node2D.new()
	arc.set_script(LightningArcScript)
	projectiles_root.add_child(arc)
	if arc.has_method("activate"):
		arc.activate(global_position, _scaled_dmg(arc_dmg), arc_targets, 170.0)


func _start_dash(input_dir: Vector2, mouse: Vector2) -> void:
	_dash_cd = dash_cd
	_dash_timer = DASH_TIME
	_invuln = maxf(_invuln, DASH_TIME + 0.06)
	if input_dir.length_squared() > 0.01:
		_dash_dir = input_dir.normalized()
	else:
		_dash_dir = (mouse - global_position).normalized()
		if _dash_dir == Vector2.ZERO:
			_dash_dir = Vector2.RIGHT
	visual.modulate = Color(0.7, 0.9, 1.5)
	_flash_t = DASH_TIME
	add_camera_shake(1.2)
	if has_node("/root/Sfx"):
		Sfx.play("dash", randf_range(0.95, 1.1), -3.0)
	_play_anim_if("dash")
	if not _is_in_water():
		var vfx := get_tree().get_first_node_in_group("vfx_layer")
		if vfx:
			ParticleFactory.make_sand_dust(vfx, global_position)


func _play_attack_anim(punch: float = 1.0) -> void:
	_attack_anim_t = 0.16
	sprite.play("attack")
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2(1.0 + 0.12 * punch, 1.0 - 0.08 * punch), 0.04)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.09)


func take_hit(amount: int) -> void:
	if not _alive or _invuln > 0.0 or _dash_timer > 0.0:
		return
	_invuln = INVULN_TIME
	_flash_t = INVULN_TIME
	_hit_pulse = 0.12
	add_camera_shake(3.5)
	if has_node("/root/Sfx"):
		Sfx.play("hurt", randf_range(0.9, 1.05), 0.0)
	GameManager.apply_damage(amount)


func _on_player_died() -> void:
	_alive = false
	velocity = Vector2.ZERO
	visual.modulate = Color(0.4, 0.4, 0.45)
	sprite.pause()
	if has_node("/root/Sfx"):
		Sfx.play("death", 0.85, 2.0)
	died.emit()


func _on_leveled_up(level: int) -> void:
	if not _alive:
		return
	var reward: Dictionary = SkillProgression.apply(self, level)
	play_level_up_fx(level, reward)


func apply_skill_reward(reward: Dictionary) -> void:
	var id: String = str(reward.get("id", ""))
	if id != "" and unlocked_ids.has(id):
		return
	if id != "":
		unlocked_ids.append(id)
	match str(reward.get("type", "")):
		"stat":
			GameManager.increase_max_health(25, true)
		"fireball":
			fireball_dmg = int(round(float(fireball_dmg) * 1.35))
			fireball_pierce += 1
		"unlock_arc":
			arc_unlocked = true
		"mobility":
			move_speed_mult *= 1.10
			dash_cd = maxf(0.75, dash_cd * 0.78)
			dash_speed *= 1.08
		"nova":
			nova_dmg = int(round(float(nova_dmg) * 1.40))
			nova_radius *= 1.25
		"basic":
			basic_dmg = int(round(float(basic_dmg) * 1.25))
			basic_cd = maxf(0.14, basic_cd * 0.88)
		"power":
			damage_mult *= 1.10
			GameManager.increase_max_health(15, true)
		"ascend":
			damage_mult *= 1.08
			GameManager.increase_max_health(10, true)
			# Occasional extra fireball at high levels
			if fireball_count < 3 and randf() < 0.35:
				fireball_count += 1
		_:
			pass
	skill_unlocked.emit(reward)


func play_level_up_fx(level: int, reward: Dictionary = {}) -> void:
	if has_node("/root/Sfx"):
		Sfx.play("levelup", 1.0, 2.0)
	add_camera_shake(4.5)
	camera.zoom = _base_zoom * 1.12
	_level_glow = 0.6

	var glow_tw := create_tween()
	glow_tw.tween_property(visual, "modulate", Color(1.6, 1.45, 0.7), 0.12)
	glow_tw.tween_property(visual, "modulate", Color(1.25, 1.15, 0.85), 0.2)
	glow_tw.tween_property(visual, "modulate", Color.WHITE, 0.45)

	var sc_tw := create_tween()
	sc_tw.tween_property(visual, "scale", Vector2(1.35, 1.35), 0.1)
	sc_tw.tween_property(visual, "scale", Vector2(0.95, 0.95), 0.1)
	sc_tw.tween_property(visual, "scale", Vector2.ONE, 0.15)

	if light:
		var old_e := light.energy
		var old_c := light.color
		light.color = Color(1.0, 0.92, 0.55)
		var lt := create_tween()
		lt.tween_property(light, "energy", old_e + 1.4, 0.12)
		lt.tween_property(light, "energy", old_e, 0.55)
		lt.parallel().tween_property(light, "color", old_c, 0.55)

	var ring := Polygon2D.new()
	ring.z_index = 15
	ring.color = Color(1.0, 0.9, 0.4, 0.65)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 18.0)
	ring.polygon = pts
	add_child(ring)
	var rt := create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector2(5.5, 5.5), 0.45)
	rt.tween_property(ring, "modulate:a", 0.0, 0.45)
	rt.chain().tween_callback(ring.queue_free)

	var vfx := get_tree().get_first_node_in_group("vfx_layer")
	if vfx == null:
		vfx = get_parent()
	if vfx:
		ParticleFactory.make_level_up_burst(vfx, global_position)
		ParticleFactory.spawn_float_text(
			vfx, global_position + Vector2(0, -28), "LEVEL %d!" % level, Color(1.0, 0.92, 0.4)
		)
		if not reward.is_empty():
			ParticleFactory.spawn_float_text(
				vfx,
				global_position + Vector2(0, -48),
				str(reward.get("title", "Upgrade")),
				Color(0.75, 0.95, 1.0)
			)


func get_skill_cds() -> Dictionary:
	return {
		"basic": _basic_cd,
		"fireball": _fireball_cd,
		"nova": _nova_cd,
		"dash": _dash_cd,
		"arc": _arc_cd,
		"nova_max": nova_cd,
		"dash_max": dash_cd,
		"fireball_max": fireball_cd,
		"arc_max": arc_cd_max,
		"arc_unlocked": arc_unlocked,
	}


func get_unlock_summary() -> String:
	if unlocked_ids.is_empty():
		return "No upgrades yet — keep collecting XP"
	return "Upgrades: %d" % unlocked_ids.size()
