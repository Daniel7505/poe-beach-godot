extends "res://scripts/enemies/enemy_base.gd"
## Scuttling beach crab — fast, flanks the player, low HP.

const ProcSprites = preload("res://scripts/visual/proc_sprites.gd")


func _ready() -> void:
	max_health = 20
	move_speed = 105.0
	contact_damage = 6
	score_value = 10
	aggro_range = 280.0
	leash_range = 400.0
	attack_range = 20.0
	attack_cooldown = 0.5
	attack_windup = 0.12
	prefer_flank = true
	death_tint = Color(0.95, 0.45, 0.25)
	super._ready()
	if sprite:
		sprite.sprite_frames = ProcSprites.crab_frames()
		sprite.play("idle")
