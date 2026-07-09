extends "res://scripts/enemies/enemy_base.gd"
## Shambling drowned zombie — tanky, direct chase, hard-hitting lunge.

const ProcSprites = preload("res://scripts/visual/proc_sprites.gd")


func _ready() -> void:
	max_health = 50
	move_speed = 54.0
	contact_damage = 13
	score_value = 25
	aggro_range = 360.0
	leash_range = 480.0
	attack_range = 24.0
	attack_cooldown = 0.9
	attack_windup = 0.3
	prefer_flank = false
	death_tint = Color(0.55, 0.7, 0.4)
	super._ready()
	if sprite:
		sprite.sprite_frames = ProcSprites.zombie_frames()
		sprite.play("idle")
