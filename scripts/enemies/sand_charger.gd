extends "res://scripts/enemies/enemy_base.gd"
## Stocky sand charger — telegraphs, then rushes in a straight line.

const ProcSprites = preload("res://scripts/visual/proc_sprites.gd")


func _ready() -> void:
	max_health = 40
	move_speed = 62.0
	contact_damage = 16
	score_value = 22
	aggro_range = 300.0
	leash_range = 440.0
	attack_range = 110.0  # starts charge from farther out
	attack_cooldown = 1.4
	attack_windup = 0.4
	charge_attack = true
	charge_speed = 260.0
	prefer_flank = false
	death_tint = Color(0.75, 0.6, 0.35)
	super._ready()
	if sprite:
		sprite.sprite_frames = ProcSprites.charger_frames()
		sprite.play("idle")
