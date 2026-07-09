extends Node2D
## Multi-layer coast: sand base, GPU-shaded water, rocks, palms, VFX, atmosphere.

const TilesetBuilder = preload("res://scripts/map/tileset_builder.gd")
const PalmPropScript = preload("res://scripts/map/palm_prop.gd")
const AtmosphereScript = preload("res://scripts/map/coast_atmosphere.gd")
const ParticleFactory = preload("res://scripts/vfx/particle_factory.gd")

enum Tile { SAND, WATER, ROCK, PALM }

const TILE_SIZE := 64  # Matches tileset_builder TILE (sharper beach)
# Slightly fewer cells so world size stays playable with 64px tiles
const MAP_W := 36
const MAP_H := 24

@onready var base_layer: TileMapLayer = $BaseLayer
@onready var water_layer: TileMapLayer = $WaterLayer
@onready var rock_layer: TileMapLayer = $RockLayer
@onready var props_layer: Node2D = $Props
@onready var entities: Node2D = $Entities
@onready var projectiles: Node2D = $Projectiles
@onready var loot_layer: Node2D = $Loot
@onready var vfx_layer: Node2D = $Vfx

var _tiles: Array = []
var player_spawn: Vector2 = Vector2.ZERO
var atmosphere: Node2D = null
var map_pixel_size: Vector2:
	get:
		return Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE)


func _ready() -> void:
	var tileset := TilesetBuilder.build()
	base_layer.tile_set = tileset
	water_layer.tile_set = tileset
	rock_layer.tile_set = tileset

	base_layer.collision_enabled = false
	water_layer.collision_enabled = false
	rock_layer.collision_enabled = true
	if tileset.get_physics_layers_count() > 0:
		tileset.set_physics_layer_collision_layer(0, 1)
		tileset.set_physics_layer_collision_mask(0, 0)

	_apply_water_shader()
	_generate_tiles()
	_paint_tilemaps()
	_spawn_palms()
	_add_map_bounds()
	_spawn_atmosphere()
	vfx_layer.add_to_group("vfx_layer")
	ParticleFactory.make_ambient_dust(vfx_layer, map_pixel_size)
	player_spawn = _world_pos(MAP_W / 2, MAP_H / 2 - 2)


func _apply_water_shader() -> void:
	var mat := ShaderMaterial.new()
	var shader := load("res://shaders/water_wave.gdshader") as Shader
	if shader:
		mat.shader = shader
		# Calm wave look — low frequency, soft foam (no psychedelic caustics)
		mat.set_shader_parameter("time_scale", 0.55)
		mat.set_shader_parameter("wave_strength", 0.007)
		mat.set_shader_parameter("foam_strength", 0.12)
		mat.set_shader_parameter("alpha_mul", 0.94)
		water_layer.material = mat


func get_entities_root() -> Node2D:
	return entities


func get_projectiles_root() -> Node2D:
	return projectiles


func get_loot_root() -> Node2D:
	return loot_layer


func get_vfx_root() -> Node2D:
	return vfx_layer


func get_camera_limits() -> Rect2:
	return Rect2(Vector2.ZERO, map_pixel_size)


func get_atmosphere() -> Node2D:
	return atmosphere


func is_water_at(world_pos: Vector2) -> bool:
	var local := base_layer.to_local(world_pos)
	var cell := base_layer.local_to_map(local)
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_W or cell.y >= MAP_H:
		return false
	return int(_tiles[cell.y][cell.x]) == Tile.WATER


func spawn_splash(world_pos: Vector2) -> void:
	ParticleFactory.make_water_splash(vfx_layer, world_pos)


func _world_pos(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE_SIZE + TILE_SIZE * 0.5, ty * TILE_SIZE + TILE_SIZE * 0.5)


func _generate_tiles() -> void:
	_tiles.clear()
	for y in MAP_H:
		var row: Array = []
		for x in MAP_W:
			var t := Tile.SAND
			var shore := MAP_H * 0.55 + sin(x * 0.35) * 2.0 + cos(x * 0.12) * 1.5
			if y > shore:
				t = Tile.WATER
			if x < 2 or x > MAP_W - 3:
				if y < MAP_H * 0.7 and (x + y) % 3 != 0:
					t = Tile.ROCK
			row.append(t)
		_tiles.append(row)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 28:
		var rx := rng.randi_range(4, MAP_W - 5)
		var ry := rng.randi_range(2, int(MAP_H * 0.5))
		if _tiles[ry][rx] == Tile.SAND:
			_tiles[ry][rx] = Tile.ROCK
			if rng.randf() < 0.5 and rx + 1 < MAP_W and _tiles[ry][rx + 1] == Tile.SAND:
				_tiles[ry][rx + 1] = Tile.ROCK

	for i in 22:
		var px := rng.randi_range(5, MAP_W - 6)
		var py := rng.randi_range(2, int(MAP_H * 0.48))
		if _tiles[py][px] == Tile.SAND:
			_tiles[py][px] = Tile.PALM

	var cx := MAP_W / 2
	var cy := MAP_H / 2 - 2
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var sx := cx + ox
			var sy := cy + oy
			if sx >= 0 and sy >= 0 and sx < MAP_W and sy < MAP_H:
				_tiles[sy][sx] = Tile.SAND


func _is_near_water(x: int, y: int) -> bool:
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var nx := x + ox
			var ny := y + oy
			if nx < 0 or ny < 0 or nx >= MAP_W or ny >= MAP_H:
				continue
			if int(_tiles[ny][nx]) == Tile.WATER:
				return true
	return false


func _is_shore_foam(x: int, y: int) -> bool:
	# Sand cell adjacent to water on south-ish side
	if int(_tiles[y][x]) != Tile.SAND and int(_tiles[y][x]) != Tile.PALM:
		return false
	if y + 1 < MAP_H and int(_tiles[y + 1][x]) == Tile.WATER:
		return true
	if y + 1 < MAP_H and x > 0 and int(_tiles[y + 1][x - 1]) == Tile.WATER:
		return true
	if y + 1 < MAP_H and x + 1 < MAP_W and int(_tiles[y + 1][x + 1]) == Tile.WATER:
		return true
	return false


func _paint_tilemaps() -> void:
	base_layer.clear()
	water_layer.clear()
	rock_layer.clear()
	for y in MAP_H:
		for x in MAP_W:
			var cell := Vector2i(x, y)
			var t: int = _tiles[y][x]
			var sand_atlas := TilesetBuilder.sand_atlas(x, y)
			if t == Tile.SAND or t == Tile.PALM or t == Tile.ROCK:
				if _is_near_water(x, y) and t != Tile.ROCK:
					sand_atlas = TilesetBuilder.WET_SAND if (x + y) % 2 == 0 else TilesetBuilder.WET_SAND_2
			# Always paint base sand (under water for translucency)
			if t == Tile.WATER:
				base_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, TilesetBuilder.sand_atlas(x, y + 3))
			else:
				base_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, sand_atlas)

			match t:
				Tile.WATER:
					var shore := MAP_H * 0.55 + sin(x * 0.35) * 2.0
					if y > shore + 3.0:
						water_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, TilesetBuilder.DEEP_0)
					else:
						water_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, TilesetBuilder.WATER_0)
				Tile.ROCK:
					rock_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, TilesetBuilder.rock_atlas(x, y))
				_:
					pass

			# Shore foam accents on wet sand edge
			if _is_shore_foam(x, y) and (x * 3 + y) % 4 != 0:
				water_layer.set_cell(cell, TilesetBuilder.SOURCE_ID, TilesetBuilder.FOAM)


func _spawn_palms() -> void:
	for y in MAP_H:
		for x in MAP_W:
			if int(_tiles[y][x]) != Tile.PALM:
				continue
			var palm := StaticBody2D.new()
			palm.set_script(PalmPropScript)
			props_layer.add_child(palm)
			palm.position = _world_pos(x, y)
			var flip := 1.0 if randf() > 0.5 else -1.0
			# Scale palms up for 64px world so they still read as full trees
			var s := randf_range(1.55, 1.95)
			palm.scale = Vector2(s * flip, s * randf_range(0.95, 1.08))


func _spawn_atmosphere() -> void:
	atmosphere = Node2D.new()
	atmosphere.set_script(AtmosphereScript)
	atmosphere.set("map_size", map_pixel_size)
	add_child(atmosphere)
	move_child(atmosphere, 0)


func _add_map_bounds() -> void:
	var thickness := 24.0
	var size := map_pixel_size
	var rects := [
		Rect2(Vector2(-thickness, -thickness), Vector2(size.x + thickness * 2.0, thickness)),
		Rect2(Vector2(-thickness, size.y), Vector2(size.x + thickness * 2.0, thickness)),
		Rect2(Vector2(-thickness, 0.0), Vector2(thickness, size.y)),
		Rect2(Vector2(size.x, 0.0), Vector2(thickness, size.y)),
	]
	for r in rects:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.position + r.size * 0.5
		body.add_child(col)
		add_child(body)


func find_sand_positions(count: int, min_dist_from: Vector2 = Vector2.ZERO, min_dist: float = 80.0) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for y in MAP_H:
		for x in MAP_W:
			if _tiles[y][x] != Tile.SAND:
				continue
			var p := _world_pos(x, y)
			if min_dist_from != Vector2.ZERO and p.distance_to(min_dist_from) < min_dist:
				continue
			candidates.append(p)
	candidates.shuffle()
	var result: Array[Vector2] = []
	for i in mini(count, candidates.size()):
		result.append(candidates[i])
	return result
