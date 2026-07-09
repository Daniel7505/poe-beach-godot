extends Node
## Gentle day ↔ golden-hour hint. Readable combat first; not a full night sim.

signal phase_changed(phase_name: String, blend: float)

@export var cycle_seconds: float = 360.0  # slow, subtle
@export var start_phase: float = 0.08
@export var intensity: float = 0.55  # 0 = static warm day, 1 = full keyframe range

var _t: float = 0.0
var _canvas: CanvasModulate
var _hero_light: PointLight2D
var _sky_nodes: Array[Polygon2D] = []
var _last_phase: String = ""
var _base_modulate := Color(1.06, 0.95, 0.84)
var _base_hero_energy := 0.55
var _base_hero_color := Color(1.0, 0.9, 0.75)


func _ready() -> void:
	add_to_group("day_night")


func setup(canvas: CanvasModulate, hero_light: PointLight2D = null, sky_nodes: Array = []) -> void:
	_canvas = canvas
	_hero_light = hero_light
	_sky_nodes.clear()
	for n in sky_nodes:
		if n is Polygon2D:
			_sky_nodes.append(n)
	_t = start_phase * cycle_seconds
	if _canvas:
		_base_modulate = _canvas.color
	_apply(0.0)


func bind_hero_light(light: PointLight2D) -> void:
	_hero_light = light
	if _hero_light:
		_base_hero_energy = _hero_light.energy
		_base_hero_color = _hero_light.color


func _process(delta: float) -> void:
	_t += delta
	_apply(delta)


func _apply(_delta: float) -> void:
	if _canvas == null:
		return
	var u := fposmod(_t / cycle_seconds, 1.0)
	var sample := _sample(u)
	# Mix toward base so the shift stays a hint
	var k := intensity
	_canvas.color = _base_modulate.lerp(sample["modulate"] as Color, k)
	if _hero_light:
		_hero_light.energy = lerpf(_base_hero_energy, float(sample["hero_energy"]), k * 0.7)
		_hero_light.color = _base_hero_color.lerp(sample["hero_color"] as Color, k * 0.6)
	for sky in _sky_nodes:
		if is_instance_valid(sky):
			var target: Color = sample["sky"]
			sky.color = sky.color.lerp(target, 0.02 * k)
	var pname: String = sample["name"]
	if pname != _last_phase:
		_last_phase = pname
		phase_changed.emit(pname, u)


func _sample(u: float) -> Dictionary:
	# Soft golden-hour sway — never drops into full blue night
	var keys := [
		{"u": 0.00, "name": "day", "mod": Color(1.05, 0.96, 0.88), "sky": Color("e8b888"), "he": 0.5, "hc": Color(1.0, 0.92, 0.78)},
		{"u": 0.30, "name": "afternoon", "mod": Color(1.08, 0.94, 0.82), "sky": Color("e0a070"), "he": 0.55, "hc": Color(1.0, 0.88, 0.72)},
		{"u": 0.48, "name": "dusk", "mod": Color(1.1, 0.88, 0.78), "sky": Color("d08060"), "he": 0.65, "hc": Color(1.0, 0.82, 0.65)},
		{"u": 0.62, "name": "evening", "mod": Color(0.98, 0.9, 0.92), "sky": Color("a87888"), "he": 0.72, "hc": Color(0.95, 0.85, 0.9)},
		{"u": 0.78, "name": "cool", "mod": Color(0.96, 0.94, 1.02), "sky": Color("8890b0"), "he": 0.68, "hc": Color(0.9, 0.9, 1.0)},
		{"u": 0.92, "name": "dawn", "mod": Color(1.06, 0.92, 0.88), "sky": Color("e89880"), "he": 0.58, "hc": Color(1.0, 0.88, 0.78)},
		{"u": 1.00, "name": "day", "mod": Color(1.05, 0.96, 0.88), "sky": Color("e8b888"), "he": 0.5, "hc": Color(1.0, 0.92, 0.78)},
	]
	var a: Dictionary = keys[0]
	var b: Dictionary = keys[1]
	for i in range(keys.size() - 1):
		if u >= keys[i]["u"] and u <= keys[i + 1]["u"]:
			a = keys[i]
			b = keys[i + 1]
			break
	var span: float = maxf(float(b["u"]) - float(a["u"]), 0.0001)
	var t: float = clampf((u - float(a["u"])) / span, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return {
		"name": b["name"] if t > 0.5 else a["name"],
		"modulate": (a["mod"] as Color).lerp(b["mod"] as Color, t),
		"sky": (a["sky"] as Color).lerp(b["sky"] as Color, t),
		"hero_energy": lerpf(float(a["he"]), float(b["he"]), t),
		"hero_color": (a["hc"] as Color).lerp(b["hc"] as Color, t),
	}
