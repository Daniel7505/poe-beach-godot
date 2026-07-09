extends "res://scripts/enemies/enemy_base.gd"
## Venom spit crawler — kites at mid-range and lobs toxic spit.

const ProcSprites = preload("res://scripts/visual/proc_sprites.gd")
const SpitScene = preload("res://scenes/projectiles/enemy_spit.tscn")


func _ready() -> void:
	max_health = 28
	move_speed = 78.0
	contact_damage = 5
	score_value = 18
	aggro_range = 340.0
	leash_range = 460.0
	attack_range = 170.0
	attack_cooldown = 1.15
	attack_windup = 0.28
	prefer_kite = true
	kite_distance = 145.0
	prefer_flank = false
	death_tint = Color(0.55, 0.85, 0.3)
	super._ready()
	if sprite:
		sprite.sprite_frames = ProcSprites.spitter_frames()
		sprite.play("idle")


func _on_melee_connect(player: Node, to_player: Vector2, dist: float) -> void:
	# Prefer spit; only nip if player walks into face
	if player and is_instance_valid(player) and dist < 28.0:
		if player.has_method("take_hit"):
			player.take_hit(contact_damage)
	_fire_spit(player)


func _fire_spit(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var root := get_tree().get_first_node_in_group("vfx_layer")
	# Prefer projectiles layer under coast map
	var map := get_parent()
	if map and map.get_parent() and map.get_parent().has_method("get_projectiles_root"):
		root = map.get_parent().get_projectiles_root()
	elif map and map.name == "Entities" and map.get_parent() and map.get_parent().has_node("Projectiles"):
		root = map.get_parent().get_node("Projectiles")
	if root == null:
		root = get_parent()
	var spit := SpitScene.instantiate()
	root.add_child(spit)
	var dir: Vector2 = (player.global_position - global_position).normalized()
	# Lead slightly toward player velocity if available
	if player is CharacterBody2D:
		var cb := player as CharacterBody2D
		dir = (player.global_position + cb.velocity * 0.12 - global_position).normalized()
	if spit.has_method("launch"):
		spit.launch(global_position + dir * 12.0, dir, 9)
