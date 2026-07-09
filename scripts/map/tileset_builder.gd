extends RefCounted
## Rich coastal TileSet — paints a hand-painted-style atlas, saves PNG, builds TileSet.
## Water frames feed a separate WaterLayer (GPU shader); rocks keep physics.

const TILE := 64  # Higher-res beach tiles (was 32)
const SOURCE_ID := 0
const ATLAS_W := 10
const ATLAS_H := 3
const ATLAS_PATH := "res://assets/tiles/coast_atlas.png"


## Scale design values authored at 32px into current TILE size.
static func _s(v: float) -> float:
	return v * float(TILE) / 32.0


static func _si(v: int) -> int:
	return int(round(float(v) * float(TILE) / 32.0))

# Row 0 — sand family
const SAND_0 := Vector2i(0, 0)
const SAND_1 := Vector2i(1, 0)
const SAND_2 := Vector2i(2, 0)
const SAND_3 := Vector2i(3, 0)
const SAND_4 := Vector2i(4, 0)
const WET_SAND := Vector2i(5, 0)
const WET_SAND_2 := Vector2i(6, 0)
const SAND_DUNE := Vector2i(7, 0)
const SAND_PEBBLE := Vector2i(8, 0)

# Row 1 — water frames (animation bases WATER_0 / DEEP_0 only as tiles)
const WATER_0 := Vector2i(0, 1)
const WATER_1 := Vector2i(1, 1)
const WATER_2 := Vector2i(2, 1)
const WATER_3 := Vector2i(3, 1)
const DEEP_0 := Vector2i(4, 1)
const DEEP_1 := Vector2i(5, 1)
const DEEP_2 := Vector2i(6, 1)
const DEEP_3 := Vector2i(7, 1)
const FOAM := Vector2i(8, 1)

# Row 2 — rocks
const ROCK_0 := Vector2i(0, 2)
const ROCK_1 := Vector2i(1, 2)
const ROCK_2 := Vector2i(2, 2)
const ROCK_3 := Vector2i(3, 2)
const ROCK_MOSS := Vector2i(4, 2)


static func build() -> TileSet:
	var img := _paint_or_load_atlas()
	var tex := ImageTexture.create_from_image(img)

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE, TILE)

	for c in _base_tile_coords():
		source.create_tile(c)

	tileset.add_source(source, SOURCE_ID)

	# Slower water frames — pairs with calm GPU swell (avoids busy/psychedelic look)
	_setup_anim(source, WATER_0, 4, 0.55)
	_setup_anim(source, DEEP_0, 4, 0.65)

	for r in [ROCK_0, ROCK_1, ROCK_2, ROCK_3, ROCK_MOSS]:
		_add_full_tile_collision(source, r)

	return tileset


static func sand_atlas(x: int, y: int) -> Vector2i:
	var v: Array[Vector2i] = [SAND_0, SAND_1, SAND_2, SAND_3, SAND_4, SAND_DUNE, SAND_PEBBLE]
	return v[absi(x * 5 + y * 11) % v.size()]


static func rock_atlas(x: int, y: int) -> Vector2i:
	var v: Array[Vector2i] = [ROCK_0, ROCK_1, ROCK_2, ROCK_3, ROCK_MOSS]
	return v[absi(x * 2 + y * 5) % v.size()]


static func _base_tile_coords() -> Array[Vector2i]:
	return [
		SAND_0, SAND_1, SAND_2, SAND_3, SAND_4, WET_SAND, WET_SAND_2, SAND_DUNE, SAND_PEBBLE,
		WATER_0, DEEP_0, FOAM,
		ROCK_0, ROCK_1, ROCK_2, ROCK_3, ROCK_MOSS,
	]


static func _paint_or_load_atlas() -> Image:
	var img := _paint_atlas()
	# Persist hand-paintable PNG for art pipeline / inspection
	_save_atlas_png(img)
	return img


static func _save_atlas_png(img: Image) -> void:
	var abs_dir := ProjectSettings.globalize_path("res://assets/tiles")
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var abs_path := ProjectSettings.globalize_path(ATLAS_PATH)
	img.save_png(abs_path)


static func _setup_anim(source: TileSetAtlasSource, base: Vector2i, frames: int, duration: float) -> void:
	source.set_tile_animation_columns(base, frames)
	source.set_tile_animation_separation(base, Vector2i(0, 0))
	source.set_tile_animation_speed(base, 1.0)
	source.set_tile_animation_frames_count(base, frames)
	for i in frames:
		source.set_tile_animation_frame_duration(base, i, duration)


static func _add_full_tile_collision(source: TileSetAtlasSource, coords: Vector2i) -> void:
	var td: TileData = source.get_tile_data(coords, 0)
	var half := TILE * 0.5
	var inset := _s(2.0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half + inset, -half + inset),
		Vector2(half - inset, -half + inset),
		Vector2(half - inset, half - inset),
		Vector2(-half + inset, half - inset),
	]))


static func _ox(c: Vector2i) -> int:
	return c.x * TILE


static func _oy(c: Vector2i) -> int:
	return c.y * TILE


static func _px(img: Image, c: Vector2i, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= TILE or y >= TILE:
		return
	img.set_pixel(_ox(c) + x, _oy(c) + y, color)


static func _hash(x: int, y: int, s: int = 0) -> int:
	return ((x * 374761393 + y * 668265263 + s * 1274126177) * 1103515245) & 0x7fffffff


static func _fbm(x: float, y: float, seed: int) -> float:
	# Cheap value-noise blend for painted feel
	var n := 0.0
	var amp := 0.5
	var fx := x
	var fy := y
	for o in 3:
		var ix := int(floor(fx))
		var iy := int(floor(fy))
		var fxx := fx - float(ix)
		var fyy := fy - float(iy)
		fxx = fxx * fxx * (3.0 - 2.0 * fxx)
		fyy = fyy * fyy * (3.0 - 2.0 * fyy)
		var h00 := float(_hash(ix, iy, seed + o) % 1000) / 1000.0
		var h10 := float(_hash(ix + 1, iy, seed + o) % 1000) / 1000.0
		var h01 := float(_hash(ix, iy + 1, seed + o) % 1000) / 1000.0
		var h11 := float(_hash(ix + 1, iy + 1, seed + o) % 1000) / 1000.0
		var hx0 := lerpf(h00, h10, fxx)
		var hx1 := lerpf(h01, h11, fxx)
		n += lerpf(hx0, hx1, fyy) * amp
		amp *= 0.5
		fx *= 2.1
		fy *= 2.1
	return n


static func _paint_atlas() -> Image:
	var img := Image.create(TILE * ATLAS_W, TILE * ATLAS_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_paint_sand(img, SAND_0, 0)
	_paint_sand(img, SAND_1, 1)
	_paint_sand(img, SAND_2, 2)
	_paint_sand(img, SAND_3, 3)
	_paint_sand(img, SAND_4, 4)
	_paint_wet_sand(img, WET_SAND, 0)
	_paint_wet_sand(img, WET_SAND_2, 1)
	_paint_dune(img, SAND_DUNE)
	_paint_pebble_sand(img, SAND_PEBBLE)

	for i in 4:
		_paint_water(img, Vector2i(i, 1), false, i)
		_paint_water(img, Vector2i(4 + i, 1), true, i)
	_paint_foam(img, FOAM)

	_paint_rock(img, ROCK_0, 0, false)
	_paint_rock(img, ROCK_1, 1, false)
	_paint_rock(img, ROCK_2, 2, false)
	_paint_rock(img, ROCK_3, 3, false)
	_paint_rock(img, ROCK_MOSS, 4, true)
	return img


static func _paint_sand(img: Image, coords: Vector2i, variant: int) -> void:
	## Hand-painted warm beach at 64px: wash + brush + fine grit.
	var washes: Array[Color] = [
		Color("e2c08a"), Color("d4a96a"), Color("c99655"), Color("ebcf9a"), Color("c48a4a"),
	]
	var base: Color = washes[variant % washes.size()]
	var shadow := base.darkened(0.18).lerp(Color("8a5a32"), 0.2)
	var highlight := base.lightened(0.16).lerp(Color("f5e6c0"), 0.25)
	var mid := (TILE - 1) * 0.5
	var half := TILE * 0.5
	# Finer noise scale so 64px tiles keep crisp detail
	var freq := 32.0 / float(TILE)
	for y in TILE:
		for x in TILE:
			var n := _fbm(float(x) * 0.14 * freq + variant * 0.7, float(y) * 0.14 * freq, variant)
			var n2 := _fbm(float(x) * 0.38 * freq, float(y) * 0.36 * freq, 20 + variant)
			var brush := _fbm(float(x) * 0.55 * freq + variant, float(y) * 0.2 * freq, 40 + variant)
			var c := base.lerp(shadow, clampf((n2 - 0.45) * 0.9, 0.0, 0.45))
			c = c.lerp(highlight, clampf((n - 0.55) * 0.8, 0.0, 0.4))
			var stroke := sin((float(x) + float(y) * 0.6 + variant * 4.0) * 0.28 + brush * 2.0)
			c = c.lightened(stroke * 0.04)
			if _hash(x, y, variant) % 10 == 0:
				c = c.lightened(0.09)
			if _hash(x, y, variant + 3) % 14 == 0:
				c = c.darkened(0.1)
			if _hash(x, y, 50 + variant) % 40 == 0:
				c = Color("f2e4c8")
			if _hash(x, y, 70 + variant) % 60 == 0:
				c = Color("c07048")
			if _hash(x, y, 90 + variant) % 80 == 0:
				c = Color("d8b898")
			var vx := absf(float(x) - mid) / half
			var vy := absf(float(y) - mid) / half
			var vig := maxf(vx, vy)
			if vig > 0.8:
				c = c.darkened((vig - 0.8) * 0.4)
			_px(img, coords, x, y, c)


static func _paint_wet_sand(img: Image, coords: Vector2i, variant: int) -> void:
	var dry := Color("d0a86c")
	var wet := Color("6e5e42")
	var wet2 := Color("4a5a52")
	var gloss := Color("e0d4b0")
	for y in TILE:
		for x in TILE:
			var n := _fbm(x * 0.18, y * 0.18, 90 + variant)
			var shore := float(y) / float(TILE) + n * 0.18
			var c := dry.lerp(wet, clampf(0.35 + shore * 0.5, 0.0, 0.92))
			c = c.lerp(wet2, clampf(shore - 0.55, 0.0, 0.35))
			# Specular wet patches
			if n > 0.6:
				c = c.lerp(gloss, 0.28 + (n - 0.6) * 0.4)
			# Tide ripple lines
			var ripple := sin(float(x) * 0.7 + float(variant) + n * 3.0) + float(y) * 0.35
			if int(ripple * 2.0) % 4 == 0 and shore > 0.35:
				c = c.lerp(Color("3a4840"), 0.12)
			# Tiny bubbles
			if _hash(x, y, variant) % 40 == 0 and shore > 0.4:
				c = c.lerp(Color(0.9, 0.95, 0.95), 0.35)
			_px(img, coords, x, y, c)


static func _paint_dune(img: Image, coords: Vector2i) -> void:
	_paint_sand(img, coords, 2)
	var ridge_w := _s(7.0)
	for y in TILE:
		for x in TILE:
			var ridge_y := _s(15.0) + sin(x * 0.21) * _s(4.5) + cos(x * 0.08) * _s(1.5)
			var ridge := absf(float(y) - ridge_y)
			if ridge < ridge_w:
				var p := img.get_pixel(_ox(coords) + x, _oy(coords) + y)
				var k := 1.0 - ridge / ridge_w
				k *= k
				if float(y) < ridge_y:
					p = p.lightened(0.14 * k)
					p = p.lerp(Color("f0d8a8"), 0.12 * k)
				else:
					p = p.darkened(0.14 * k)
					p = p.lerp(Color("8a6038"), 0.1 * k)
				_px(img, coords, x, y, p)


static func _paint_pebble_sand(img: Image, coords: Vector2i) -> void:
	_paint_sand(img, coords, 1)
	for i in 14:
		var px := _si(5) + (i * _si(10) + _hash(i, 2, 3) % _si(8)) % (TILE - _si(8))
		var py := _si(7) + (i * _si(8) + _hash(i, 5, 1) % _si(10)) % (TILE - _si(10))
		var pr := _si(1) + i % 3
		var col := Color("8c7a64") if i % 2 == 0 else Color("6a6258")
		if i % 3 == 0:
			col = Color("a09078")
		for oy in range(-pr - 1, pr + 2):
			for ox in range(-pr - 1, pr + 2):
				var d2 := ox * ox + oy * oy
				if d2 <= pr * pr:
					var c := col.lightened(0.06 * float(-oy))
					if d2 >= pr * pr - 1:
						c = c.darkened(0.12)
					_px(img, coords, px + ox, py + oy, c)


static func _paint_water(img: Image, coords: Vector2i, deep: bool, frame: int) -> void:
	## Clear turquoise shallows / richer deep teal, soft foam crests.
	var base := Color(0.18, 0.58, 0.62, 0.62) if not deep else Color(0.08, 0.34, 0.48, 0.80)
	var light := Color(0.48, 0.82, 0.80, 0.45)
	var foam := Color(0.94, 0.98, 1.0, 0.82)
	var phase := float(frame) * 1.4
	for y in TILE:
		for x in TILE:
			var wx := float(x) + phase * 2.8
			var wy := float(y) - phase * 1.3
			var wave := sin(wx * 0.4 + wy * 0.24) * 0.5 + 0.5
			var wave2 := cos(wx * 0.18 - wy * 0.36 + phase) * 0.5 + 0.5
			var n := _fbm(wx * 0.12, wy * 0.12, frame + (12 if deep else 0))
			var c := base.lerp(light, wave * 0.45 + n * 0.18)
			# Warm sand show-through in shallows
			if not deep:
				c = c.lerp(Color(0.75, 0.62, 0.4, c.a), 0.12 * (1.0 - wave))
			c.a = clampf(base.a + wave2 * 0.12 + n * 0.05, 0.35, 0.92)
			if wave > 0.7 and int(wy + wave * 5.0 + phase) % 5 == 0:
				c = c.lerp(foam, 0.55)
			if (_hash(x + frame * 2, y, 3) % 24) == 0:
				c = c.lerp(Color(1, 1, 1, 0.6), 0.4)
			_px(img, coords, x, y, c)


static func _paint_foam(img: Image, coords: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(img, coords, x, y, Color(0, 0, 0, 0))
	var band_w := _s(6.0)
	for y in TILE:
		for x in TILE:
			var band := absf(float(y) - _s(15.0) - sin(x * 0.28) * _s(3.5) - cos(x * 0.1) * _s(1.2))
			if band < band_w:
				var a := pow(1.0 - band / band_w, 1.4) * 0.8
				if _hash(x, y, 1) % 5 == 0:
					a *= 0.4
				var c := Color(0.95, 0.98, 1.0, a)
				if _hash(x, y, 2) % 7 == 0:
					c.a *= 0.25
				_px(img, coords, x, y, c)


static func _paint_rock(img: Image, coords: Vector2i, variant: int, mossy: bool) -> void:
	for y in TILE:
		for x in TILE:
			_px(img, coords, x, y, Color(0, 0, 0, 0))

	# Soft painted contact shadow
	for y in range(_si(16), _si(31)):
		for x in range(_si(2), _si(30)):
			var dx := (x - _s(16.0)) / _s(12.5)
			var dy := (y - _s(24.5)) / _s(6.0)
			var dd := dx * dx + dy * dy
			if dd < 1.0:
				var a := (1.0 - dd) * 0.42
				_px(img, coords, x, y, Color(0.14, 0.09, 0.05, a))

	var body := Color("5c564c")
	var midc := Color("7a7062")
	var hi := Color("a89e8c")
	var moss := Color("4a6a3c")
	var cx := _s(15.5) + (variant % 3 - 1) * _s(1.8)
	var cy := _s(13.2) + (variant % 2) * _s(0.9)
	var rx := _s(11.2) + variant * _s(0.35)
	var ry := _s(9.4) + (variant % 3) * _s(0.55)
	var freq := 32.0 / float(TILE)
	for y in TILE:
		for x in TILE:
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			var d := dx * dx + dy * dy
			var n := _fbm(x * 0.22 * freq, y * 0.22 * freq, 30 + variant) * 0.18
			if d + n < 1.0:
				var c := body
				if d < 0.28:
					c = midc
				if dy < -0.22 and d < 0.55:
					c = hi
				if dy > 0.28:
					c = body.darkened(0.2)
				var facet := _fbm(x * 0.5 * freq, y * 0.5 * freq, 55 + variant)
				if facet > 0.62:
					c = c.darkened(0.1)
				elif facet < 0.35:
					c = c.lightened(0.06)
				if mossy and _fbm(x * 0.28 * freq, y * 0.28 * freq, 99) > 0.55 and d < 0.78:
					c = c.lerp(moss, 0.55 + n)
				if d > 0.72 and dy < 0.0:
					c = c.lightened(0.1)
				if d > 0.8:
					c = c.lerp(Color("8a7060"), 0.15)
				_px(img, coords, x, y, c)
