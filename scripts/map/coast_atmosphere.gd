extends Node2D
## Coastal depth: sky, distant sea, clouds. Exposes sky polygons for day/night cycle.


@export var map_size: Vector2 = Vector2(1536, 1024)

var sky_nodes: Array[Polygon2D] = []
var _cloud_sprites: Array[Sprite2D] = []
var _sea_nodes: Array[Polygon2D] = []
var _t: float = 0.0


func _ready() -> void:
	_build_sky_band()
	_build_distant_sea()
	_build_clouds()


func get_sky_nodes() -> Array:
	return sky_nodes


func _process(delta: float) -> void:
	_t += delta
	for i in _cloud_sprites.size():
		var s := _cloud_sprites[i]
		s.position.x += (6.0 + i * 2.5) * delta
		if s.position.x > map_size.x + 100.0:
			s.position.x = -100.0
			s.position.y = 16.0 + float((i * 23) % 100)
	# Gentle sea shimmer
	for i in _sea_nodes.size():
		var sea := _sea_nodes[i]
		var pulse := 0.04 * sin(_t * 1.2 + float(i))
		sea.modulate = Color(1, 1, 1, 0.9 + pulse)


func _build_sky_band() -> void:
	var sky := Polygon2D.new()
	sky.z_index = -50
	sky.color = Color("c98a5a")
	sky.polygon = PackedVector2Array([
		Vector2(-200, -180), Vector2(map_size.x + 200, -180),
		Vector2(map_size.x + 200, 40), Vector2(-200, 80),
	])
	add_child(sky)
	sky_nodes.append(sky)

	var sky2 := Polygon2D.new()
	sky2.z_index = -49
	sky2.color = Color("e0a878")
	sky2.polygon = PackedVector2Array([
		Vector2(-200, -100), Vector2(map_size.x + 200, -120),
		Vector2(map_size.x + 200, 20), Vector2(-200, 50),
	])
	add_child(sky2)
	sky_nodes.append(sky2)

	# Soft sun glow disc (decorative)
	var sun := Polygon2D.new()
	sun.z_index = -48
	sun.color = Color(1.0, 0.85, 0.45, 0.35)
	var pts := PackedVector2Array()
	var sc := Vector2(map_size.x * 0.72, -40)
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(sc + Vector2(cos(a), sin(a)) * 36.0)
	sun.polygon = pts
	add_child(sun)
	sky_nodes.append(sun)


func _build_distant_sea() -> void:
	var sea := Polygon2D.new()
	sea.z_index = -40
	sea.color = Color("1a5a6a")
	sea.polygon = PackedVector2Array([
		Vector2(-100, map_size.y - 40),
		Vector2(map_size.x + 100, map_size.y - 40),
		Vector2(map_size.x + 100, map_size.y + 220),
		Vector2(-100, map_size.y + 220),
	])
	add_child(sea)
	_sea_nodes.append(sea)

	var sea_hi := Polygon2D.new()
	sea_hi.z_index = -39
	sea_hi.color = Color(0.25, 0.55, 0.62, 0.55)
	sea_hi.polygon = PackedVector2Array([
		Vector2(-100, map_size.y - 30),
		Vector2(map_size.x + 100, map_size.y - 50),
		Vector2(map_size.x + 100, map_size.y + 40),
		Vector2(-100, map_size.y + 60),
	])
	add_child(sea_hi)
	_sea_nodes.append(sea_hi)

	# Horizon glitter line
	var glitter := Polygon2D.new()
	glitter.z_index = -38
	glitter.color = Color(0.7, 0.9, 0.95, 0.25)
	glitter.polygon = PackedVector2Array([
		Vector2(0, map_size.y - 36),
		Vector2(map_size.x, map_size.y - 48),
		Vector2(map_size.x, map_size.y - 42),
		Vector2(0, map_size.y - 30),
	])
	add_child(glitter)
	_sea_nodes.append(glitter)


func _build_clouds() -> void:
	for i in 6:
		var tex := _make_cloud_texture(70 + i * 12, 20 + i * 2)
		var s := Sprite2D.new()
		s.texture = tex
		s.z_index = -45
		s.modulate = Color(1, 0.93, 0.88, 0.32)
		s.position = Vector2(fmod(float(i) * 260.0, map_size.x), 24.0 + i * 12.0)
		s.scale = Vector2(1.15 + i * 0.08, 1.0)
		add_child(s)
		_cloud_sprites.append(s)


func _make_cloud_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var dx := (x / float(w) - 0.5) * 2.0
			var dy := (y / float(h) - 0.5) * 2.0
			var d := dx * dx + dy * dy * 1.9
			# two blobs
			var d2 := ((x / float(w) - 0.35) * 2.2)
			d2 = d2 * d2 + dy * dy * 2.2
			var dens := maxf(1.0 - d, 0.0) + maxf(1.0 - d2, 0.0) * 0.7
			if dens > 0.05:
				var a := clampf(dens * 0.55, 0.0, 0.75)
				img.set_pixel(x, y, Color(1, 0.96, 0.92, a))
	return ImageTexture.create_from_image(img)
