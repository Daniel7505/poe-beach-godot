extends "res://scripts/projectiles/projectile.gd"
## Right-click fireball with ember trail + point light.


func _ready() -> void:
	speed = 300.0
	lifetime = 1.4
	pierce = 3
	knockback = 160.0
	super._ready()
	ParticleFactory.make_fireball_embers(self)
	var light := PointLight2D.new()
	light.name = "FireLight"
	light.color = Color(1.0, 0.55, 0.2)
	light.energy = 1.1
	light.texture_scale = 1.6
	light.texture = ParticleFactory.soft_disk(48, Color.WHITE)
	add_child(light)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if has_node("Visual"):
		var v: Polygon2D = $Visual
		var pulse := 1.0 + 0.12 * sin(_age * 18.0)
		v.scale = Vector2.ONE * pulse
	if has_node("FireLight"):
		var fl: PointLight2D = $FireLight
		fl.energy = 0.9 + 0.35 * sin(_age * 22.0)
