extends StaticBody2D
## Palm with soft multi-layer shadows, segmented trunk, and gentle wind animation.


var _phase: float = 0.0
var _wind: float = 1.0
var _fronds: Array[Node2D] = []
var _canopy: Node2D
var _shadow_main: Polygon2D
var _shadow_canopy: Polygon2D
var _trunk: Node2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_phase = randf() * TAU
	_wind = randf_range(0.8, 1.3)
	_build()


func _build() -> void:
	# Soft multi-pass ground shadow
	_shadow_main = Polygon2D.new()
	_shadow_main.z_index = 0
	_shadow_main.color = Color(0.1, 0.06, 0.03, 0.38)
	_shadow_main.polygon = _ellipse(Vector2(3, 13), 17, 6, 16)
	add_child(_shadow_main)

	var shadow_soft := Polygon2D.new()
	shadow_soft.z_index = 0
	shadow_soft.color = Color(0.08, 0.05, 0.02, 0.16)
	shadow_soft.polygon = _ellipse(Vector2(1, 12), 20, 7.5, 16)
	add_child(shadow_soft)

	_shadow_canopy = Polygon2D.new()
	_shadow_canopy.z_index = 1
	_shadow_canopy.color = Color(0.06, 0.1, 0.04, 0.2)
	_shadow_canopy.polygon = _ellipse(Vector2(1, 7), 13, 4.5, 14)
	add_child(_shadow_canopy)

	# Trunk
	_trunk = Node2D.new()
	_trunk.z_index = 2
	add_child(_trunk)
	var browns: Array[Color] = [
		Color("4e3418"), Color("6b4a28"), Color("7d5630"), Color("8f663c"), Color("a07848"),
	]
	for i in 6:
		var seg := Polygon2D.new()
		var t := float(i) / 5.0
		var y0 := 13.0 - t * 24.0
		var w := lerpf(4.4, 2.2, t)
		# Slight lean for natural trunk
		var lean := sin(t * PI) * 0.8
		seg.color = browns[i % browns.size()]
		seg.polygon = PackedVector2Array([
			Vector2(-w + lean, y0), Vector2(w + lean, y0),
			Vector2(w * 0.82 + lean, y0 - 4.5), Vector2(-w * 0.82 + lean, y0 - 4.5),
		])
		_trunk.add_child(seg)
		if i > 0 and i < 5:
			var ring := Polygon2D.new()
			ring.color = Color("3a2810")
			ring.polygon = PackedVector2Array([
				Vector2(-w * 0.92 + lean, y0 - 0.4),
				Vector2(w * 0.92 + lean, y0 - 0.4),
				Vector2(w * 0.88 + lean, y0 + 0.5),
				Vector2(-w * 0.88 + lean, y0 + 0.5),
			])
			_trunk.add_child(ring)
		# Highlight strip
		var hi := Polygon2D.new()
		hi.color = browns[mini(i + 1, browns.size() - 1)].lightened(0.12)
		hi.polygon = PackedVector2Array([
			Vector2(-w * 0.55 + lean, y0 - 0.5),
			Vector2(-w * 0.25 + lean, y0 - 0.5),
			Vector2(-w * 0.3 + lean, y0 - 4.0),
			Vector2(-w * 0.5 + lean, y0 - 4.0),
		])
		_trunk.add_child(hi)

	# Canopy
	_canopy = Node2D.new()
	_canopy.position = Vector2(0, -11)
	_canopy.z_index = 4
	add_child(_canopy)

	var greens: Array[Color] = [
		Color("0e3a1c"), Color("145528"), Color("1f6b32"), Color("2a7f3c"),
		Color("258038"), Color("3a9a4e"), Color("186028"), Color("4aab55"),
	]
	for i in 9:
		var holder := Node2D.new()
		_canopy.add_child(holder)
		var leaf := Polygon2D.new()
		leaf.color = greens[i % greens.size()]
		var ang := -PI * 0.5 + (i - 4.0) * 0.36
		var len := 17.0 + float(i % 4) * 2.2
		var tip := Vector2(cos(ang), sin(ang)) * len
		var side := Vector2(-sin(ang), cos(ang)) * (4.2 + float(i % 3) * 0.6)
		leaf.polygon = PackedVector2Array([
			Vector2.ZERO,
			tip * 0.3 + side * 0.4,
			tip * 0.65 + side * 0.22,
			tip * 1.05,
			tip * 0.65 - side * 0.22,
			tip * 0.3 - side * 0.4,
		])
		holder.add_child(leaf)
		# Secondary leaflet for depth
		var leaf2 := Polygon2D.new()
		leaf2.color = leaf.color.darkened(0.08)
		leaf2.polygon = PackedVector2Array([
			Vector2.ZERO,
			tip * 0.5 + side * 0.15,
			tip * 0.9 + side * 0.05,
			tip * 0.5 - side * 0.05,
		])
		holder.add_child(leaf2)
		var rib := Polygon2D.new()
		rib.color = leaf.color.lightened(0.18)
		rib.polygon = PackedVector2Array([
			Vector2.ZERO, tip * 0.12 + side * 0.04, tip * 0.92, tip * 0.12 - side * 0.04,
		])
		holder.add_child(rib)
		_fronds.append(holder)

	var crown := Polygon2D.new()
	crown.color = Color("0c3518")
	crown.polygon = _ellipse(Vector2.ZERO, 6.5, 5.2, 12)
	_canopy.add_child(crown)
	var crown_hi := Polygon2D.new()
	crown_hi.color = Color("1f7034")
	crown_hi.polygon = _ellipse(Vector2(-1.2, -1.2), 3.8, 3.0, 10)
	_canopy.add_child(crown_hi)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	col.shape = shape
	col.position = Vector2(0, 6)
	add_child(col)


func _process(delta: float) -> void:
	_phase += delta * 1.2 * _wind
	var sway := sin(_phase) * 0.08
	var sway2 := cos(_phase * 0.65) * 0.04
	if _canopy:
		_canopy.rotation = sway * 0.65 + sway2
		_canopy.position = Vector2(sin(_phase * 0.7) * 1.4, -11.0 + cos(_phase * 0.9) * 0.4)
	if _trunk:
		_trunk.rotation = sway * 0.08
	# Shadow breathes slightly with canopy
	if _shadow_canopy:
		_shadow_canopy.position.x = sin(_phase * 0.7) * 1.8
		_shadow_canopy.scale = Vector2(1.0 + sin(_phase) * 0.04, 1.0)
	if _shadow_main:
		_shadow_main.position.x = sin(_phase * 0.5) * 0.6
	for i in _fronds.size():
		_fronds[i].rotation = sway + sin(_phase * 1.35 + float(i) * 0.65) * 0.055
		_fronds[i].position.y = sin(_phase * 1.1 + float(i)) * 0.35


func _ellipse(center: Vector2, rx: float, ry: float, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segs:
		var a := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
