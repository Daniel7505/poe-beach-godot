extends RefCounted
## Shared GPU particle presets — sand dust, water splash, fireball ember (low count for perf).


static func soft_disk(size: int = 8, color: Color = Color.WHITE) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / r
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a * color.a))
	return ImageTexture.create_from_image(img)


static func make_sand_dust(parent: Node, world_pos: Vector2 = Vector2.ZERO) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.z_index = 3
	p.amount = 14
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.7
	p.randomness = 0.4
	p.local_coords = false
	p.texture = soft_disk(6, Color(0.86, 0.72, 0.48, 0.9))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 12.0
	mat.initial_velocity_max = 36.0
	mat.gravity = Vector3(0, 22, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.1
	mat.color = Color(0.9, 0.78, 0.55, 0.55)
	mat.angular_velocity_min = -40.0
	mat.angular_velocity_max = 40.0
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func make_heal_burst(parent: Node, world_pos: Vector2) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.z_index = 11
	p.amount = 16
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.85
	p.randomness = 0.35
	p.local_coords = false
	p.texture = soft_disk(6, Color(1.0, 0.35, 0.4, 1))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 100.0
	mat.initial_velocity_min = 25.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, -30, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.1
	mat.color = Color(1.0, 0.4, 0.45, 0.9)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1, 0.7, 0.75, 1),
		Color(1, 0.25, 0.3, 0.7),
		Color(0.6, 0.1, 0.15, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func spawn_float_text(parent: Node, world_pos: Vector2, text: String, color: Color = Color(0.4, 1.0, 0.5)) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 30
	label.modulate = color
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	label.global_position = world_pos + Vector2(-12, -18)
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "global_position:y", world_pos.y - 42.0, 0.55)
	tw.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tw.chain().tween_callback(label.queue_free)


static func make_foot_dust(parent: Node) -> GPUParticles2D:
	## Attached to player — emit while walking on sand.
	var p := GPUParticles2D.new()
	p.name = "FootDust"
	p.z_index = 2
	p.position = Vector2(0, 10)
	p.amount = 22
	p.lifetime = 0.55
	p.explosiveness = 0.0
	p.randomness = 0.55
	p.local_coords = false
	p.emitting = false
	p.amount_ratio = 1.0
	p.texture = soft_disk(6, Color(0.9, 0.78, 0.52, 0.9))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -0.35, 0)
	mat.spread = 85.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 28.0
	mat.gravity = Vector3(0, 30, 0)
	mat.scale_min = 0.45
	mat.scale_max = 1.15
	mat.color = Color(0.88, 0.74, 0.5, 0.62)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(0.95, 0.85, 0.6, 0.7),
		Color(0.8, 0.65, 0.4, 0.35),
		Color(0.55, 0.45, 0.3, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	mat.color_ramp = rt
	p.process_material = mat
	parent.add_child(p)
	return p


static func make_water_splash(parent: Node, world_pos: Vector2) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.z_index = 6
	p.amount = 16
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.85
	p.randomness = 0.35
	p.local_coords = false
	p.texture = soft_disk(6, Color(0.75, 0.92, 0.98, 0.95))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 80.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, 140, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.2
	mat.color = Color(0.7, 0.9, 0.95, 0.75)
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func make_water_wake(parent: Node) -> GPUParticles2D:
	## Soft trail while wading.
	var p := GPUParticles2D.new()
	p.name = "WaterWake"
	p.z_index = 2
	p.position = Vector2(0, 8)
	p.amount = 10
	p.lifetime = 0.5
	p.randomness = 0.4
	p.local_coords = false
	p.emitting = false
	p.texture = soft_disk(5, Color(0.8, 0.95, 1.0, 0.7))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 14.0
	mat.gravity = Vector3(0, 5, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.3
	mat.color = Color(0.65, 0.88, 0.95, 0.4)
	p.process_material = mat
	parent.add_child(p)
	return p


static func make_fireball_embers(parent: Node) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.name = "Embers"
	p.z_index = 7
	p.amount = 28
	p.lifetime = 0.4
	p.randomness = 0.55
	p.local_coords = false
	p.emitting = true
	p.texture = soft_disk(7, Color(1.0, 0.7, 0.2, 1.0))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 42.0
	mat.initial_velocity_min = 25.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, -25, 0)
	mat.scale_min = 0.35
	mat.scale_max = 1.25
	mat.color = Color(1.0, 0.55, 0.15, 0.9)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 0.98, 0.65, 1.0),
		Color(1.0, 0.45, 0.08, 0.85),
		Color(0.25, 0.05, 0.0, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	p.process_material = mat
	parent.add_child(p)
	# Soft smoke behind embers
	var smoke := GPUParticles2D.new()
	smoke.name = "Smoke"
	smoke.z_index = 6
	smoke.amount = 12
	smoke.lifetime = 0.55
	smoke.randomness = 0.4
	smoke.local_coords = false
	smoke.emitting = true
	smoke.texture = soft_disk(8, Color(0.35, 0.25, 0.2, 0.5))
	var sm := ParticleProcessMaterial.new()
	sm.direction = Vector3(-1, 0, 0)
	sm.spread = 30.0
	sm.initial_velocity_min = 10.0
	sm.initial_velocity_max = 28.0
	sm.gravity = Vector3(0, -8, 0)
	sm.scale_min = 0.7
	sm.scale_max = 1.6
	sm.color = Color(0.3, 0.22, 0.18, 0.4)
	var sr := Gradient.new()
	sr.colors = PackedColorArray([
		Color(0.45, 0.35, 0.28, 0.35),
		Color(0.2, 0.15, 0.12, 0.0),
	])
	sr.offsets = PackedFloat32Array([0.0, 1.0])
	var srt := GradientTexture1D.new()
	srt.gradient = sr
	sm.color_ramp = srt
	smoke.process_material = sm
	parent.add_child(smoke)
	return p


static func make_death_burst(parent: Node, world_pos: Vector2, tint: Color = Color(0.9, 0.35, 0.25)) -> GPUParticles2D:
	## Dual-layer death explosion (core + sparks).
	var p := GPUParticles2D.new()
	p.z_index = 9
	p.amount = 22
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.95
	p.randomness = 0.45
	p.local_coords = false
	p.texture = soft_disk(8, Color(1, 1, 1, 1))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 45.0
	mat.initial_velocity_max = 130.0
	mat.gravity = Vector3(0, 140, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.6
	mat.color = Color(tint.r, tint.g, tint.b, 0.95)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1.0, 1.0, 0.9, 1.0),
		Color(tint.r, tint.g, tint.b, 0.85),
		Color(tint.r * 0.4, tint.g * 0.35, tint.b * 0.3, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	# Outer dust ring
	var dust := GPUParticles2D.new()
	dust.z_index = 8
	dust.amount = 12
	dust.lifetime = 0.4
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.local_coords = false
	dust.texture = soft_disk(6, Color(0.85, 0.7, 0.45, 0.8))
	var dm := ParticleProcessMaterial.new()
	dm.direction = Vector3(0, -0.2, 0)
	dm.spread = 180.0
	dm.initial_velocity_min = 30.0
	dm.initial_velocity_max = 70.0
	dm.gravity = Vector3(0, 60, 0)
	dm.scale_min = 0.6
	dm.scale_max = 1.4
	dm.color = Color(0.75, 0.6, 0.4, 0.55)
	dust.process_material = dm
	parent.add_child(dust)
	dust.global_position = world_pos
	dust.emitting = true
	dust.finished.connect(dust.queue_free)
	return p


static func make_level_up_burst(parent: Node, world_pos: Vector2) -> void:
	## Celebratory gold ring + rising sparks around the player.
	var ring := GPUParticles2D.new()
	ring.z_index = 12
	ring.amount = 36
	ring.lifetime = 0.7
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.randomness = 0.25
	ring.local_coords = false
	ring.texture = soft_disk(8, Color(1, 0.92, 0.45, 1))
	var rm := ParticleProcessMaterial.new()
	rm.direction = Vector3(0, -1, 0)
	rm.spread = 180.0
	rm.initial_velocity_min = 90.0
	rm.initial_velocity_max = 170.0
	rm.gravity = Vector3(0, 40, 0)
	rm.scale_min = 0.55
	rm.scale_max = 1.5
	rm.color = Color(1.0, 0.9, 0.4, 1.0)
	var rr := Gradient.new()
	rr.colors = PackedColorArray([
		Color(1, 1, 0.85, 1),
		Color(1, 0.85, 0.3, 0.85),
		Color(1, 0.6, 0.1, 0.0),
	])
	rr.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	var rrt := GradientTexture1D.new()
	rrt.gradient = rr
	rm.color_ramp = rrt
	ring.process_material = rm
	parent.add_child(ring)
	ring.global_position = world_pos
	ring.emitting = true
	ring.finished.connect(ring.queue_free)

	var rise := GPUParticles2D.new()
	rise.z_index = 12
	rise.amount = 24
	rise.lifetime = 0.9
	rise.one_shot = true
	rise.explosiveness = 0.35
	rise.randomness = 0.5
	rise.local_coords = false
	rise.texture = soft_disk(6, Color(1, 0.95, 0.7, 1))
	var um := ParticleProcessMaterial.new()
	um.direction = Vector3(0, -1, 0)
	um.spread = 50.0
	um.initial_velocity_min = 40.0
	um.initial_velocity_max = 110.0
	um.gravity = Vector3(0, -30, 0)
	um.scale_min = 0.4
	um.scale_max = 1.1
	um.color = Color(1.0, 0.95, 0.6, 0.9)
	rise.process_material = um
	parent.add_child(rise)
	rise.global_position = world_pos
	rise.emitting = true
	rise.finished.connect(rise.queue_free)


static func make_xp_burst(parent: Node, world_pos: Vector2) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.z_index = 11
	p.amount = 10
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 0.9
	p.local_coords = false
	p.texture = soft_disk(5, Color(1, 0.92, 0.4, 1))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 55.0
	mat.gravity = Vector3(0, -40, 0)
	mat.scale_min = 0.35
	mat.scale_max = 0.9
	mat.color = Color(1.0, 0.9, 0.4, 0.9)
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func make_hit_sparks(parent: Node, world_pos: Vector2, dir: Vector2 = Vector2.RIGHT) -> GPUParticles2D:
	## Quick attack impact sparkles.
	var p := GPUParticles2D.new()
	p.z_index = 10
	p.amount = 10
	p.lifetime = 0.28
	p.one_shot = true
	p.explosiveness = 1.0
	p.randomness = 0.35
	p.local_coords = false
	p.texture = soft_disk(5, Color(1, 0.95, 0.7, 1))
	var mat := ParticleProcessMaterial.new()
	var d := dir.normalized() if dir.length_squared() > 0.01 else Vector2.RIGHT
	mat.direction = Vector3(d.x, d.y, 0)
	mat.spread = 55.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 110.0
	mat.gravity = Vector3(0, 80, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.9
	mat.color = Color(1.0, 0.92, 0.55, 0.95)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([
		Color(1, 1, 0.9, 1),
		Color(1, 0.7, 0.3, 0.7),
		Color(0.5, 0.2, 0.05, 0.0),
	])
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex
	p.process_material = mat
	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func make_slash_trail(parent: Node) -> GPUParticles2D:
	## Soft trail on melee slash projectile.
	var p := GPUParticles2D.new()
	p.name = "SlashTrail"
	p.z_index = 7
	p.amount = 8
	p.lifetime = 0.2
	p.randomness = 0.3
	p.local_coords = false
	p.emitting = true
	p.texture = soft_disk(5, Color(0.9, 0.95, 1.0, 0.9))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 20.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.0
	mat.color = Color(0.85, 0.92, 1.0, 0.55)
	p.process_material = mat
	parent.add_child(p)
	return p


static func make_ambient_dust(parent: Node, map_size: Vector2) -> GPUParticles2D:
	## Map-wide sparse sand motes (very cheap).
	var p := GPUParticles2D.new()
	p.name = "AmbientDust"
	p.z_index = 4
	p.position = map_size * 0.5
	p.amount = 40
	p.lifetime = 6.0
	p.preprocess = 3.0
	p.randomness = 0.8
	p.local_coords = true
	p.visibility_rect = Rect2(-map_size * 0.55, map_size * 1.1)
	p.texture = soft_disk(4, Color(0.95, 0.85, 0.65, 0.7))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(map_size.x * 0.5, map_size.y * 0.5, 0)
	mat.direction = Vector3(0.4, -0.1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 14.0
	mat.gravity = Vector3(2, 1, 0)
	mat.scale_min = 0.25
	mat.scale_max = 0.7
	mat.color = Color(0.9, 0.78, 0.55, 0.22)
	p.process_material = mat
	p.emitting = true
	parent.add_child(p)
	return p
