extends "res://scripts/projectiles/projectile.gd"
## Short-range melee slash with trail + fade arc.


func _ready() -> void:
	speed = 400.0
	lifetime = 0.16
	pierce = 2
	knockback = 130.0
	super._ready()
	ParticleFactory.make_slash_trail(self)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if has_node("Visual"):
		var v: Polygon2D = $Visual
		var t := clampf(_age / maxf(lifetime, 0.001), 0.0, 1.0)
		v.scale = Vector2.ONE * lerpf(0.75, 1.35, t)
		v.modulate.a = lerpf(1.0, 0.1, t)
		v.rotation = lerpf(-0.15, 0.35, t)
