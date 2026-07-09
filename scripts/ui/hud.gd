extends CanvasLayer
## Run stats, XP bar, skill CDs, unlock feed, death overlay.

@onready var health_bar: ProgressBar = $Root/Margin/VBox/HealthRow/HealthBar
@onready var health_label: Label = $Root/Margin/VBox/HealthRow/HealthLabel
@onready var kills_label: Label = $Root/Margin/VBox/KillsLabel
@onready var score_label: Label = $Root/Margin/VBox/ScoreLabel
@onready var xp_bar: ProgressBar = $Root/Margin/VBox/XpRow/XpBar
@onready var xp_label: Label = $Root/Margin/VBox/XpRow/XpLabel
@onready var skills_label: Label = $Root/Margin/VBox/SkillsLabel
@onready var unlock_label: Label = $Root/Margin/VBox/UnlockLabel
@onready var death_panel: PanelContainer = $Root/DeathPanel
@onready var death_label: Label = $Root/DeathPanel/Margin/DeathLabel
@onready var help_label: Label = $Root/Help
@onready var title_label: Label = $Root/Margin/VBox/Title
@onready var level_flash: ColorRect = $Root/LevelFlash
@onready var level_banner: Label = $Root/LevelBanner

var _player: Node = null
var _phase_name: String = "day"
var _last_unlock_title: String = ""


func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.kills_changed.connect(_on_kills_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.leveled_up.connect(_on_leveled_up)
	GameManager.player_died.connect(_on_player_died)
	GameManager.healed.connect(_on_healed)
	death_panel.visible = false
	_on_health_changed(GameManager.player_health, GameManager.player_max_health)
	_on_kills_changed(GameManager.kills)
	_on_score_changed(GameManager.score)
	_on_xp_changed(GameManager.xp, GameManager.xp_to_next_level(), GameManager.level)
	help_label.text = "WASD | Mouse | LMB slash | RMB fireball | Q nova | Space dash\nE lightning (Lv4+)  |  Gold orbs = XP  |  Level up for skill unlocks"
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn == null:
		dn = get_node_or_null("/root/Main/DayNightCycle")
	if dn and dn.has_signal("phase_changed"):
		dn.phase_changed.connect(_on_phase_changed)
	_style_xp_bar()
	_update_next_unlock_hint(GameManager.level)


func _style_xp_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.06, 0.85)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.75, 0.2, 1)
	fill.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("background", bg)
	xp_bar.add_theme_stylebox_override("fill", fill)


func _on_phase_changed(phase_name: String, _blend: float) -> void:
	_phase_name = phase_name
	if title_label:
		title_label.text = "The Coast  ·  %s" % phase_name.capitalize()


func bind_player(player: Node) -> void:
	_player = player
	if _player and _player.has_signal("skill_unlocked"):
		if not _player.skill_unlocked.is_connected(_on_skill_unlocked):
			_player.skill_unlocked.connect(_on_skill_unlocked)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("get_skill_cds"):
		return
	var cds: Dictionary = _player.get_skill_cds()
	var parts: PackedStringArray = [
		"FB %s" % _cd_text(cds.get("fireball", 0.0), cds.get("fireball_max", 1.0)),
		"Nova %s" % _cd_text(cds.get("nova", 0.0), cds.get("nova_max", 1.0)),
		"Dash %s" % _cd_text(cds.get("dash", 0.0), cds.get("dash_max", 1.0)),
	]
	if bool(cds.get("arc_unlocked", false)):
		parts.append("Arc %s" % _cd_text(cds.get("arc", 0.0), cds.get("arc_max", 1.0)))
	skills_label.text = "Skills  " + "  |  ".join(parts)


func _cd_text(remaining: float, maximum: float) -> String:
	if remaining <= 0.0:
		return "READY"
	return "%.1fs" % remaining


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "Life  %d / %d" % [current, maximum]


func _on_healed(_amount: int) -> void:
	var tw := create_tween()
	tw.tween_property(health_bar, "modulate", Color(0.6, 1.2, 0.7), 0.08)
	tw.tween_property(health_bar, "modulate", Color.WHITE, 0.2)


func _on_kills_changed(kills: int) -> void:
	kills_label.text = "Kills  %d" % kills


func _on_score_changed(score: int) -> void:
	score_label.text = "Score  %d" % score


func _on_xp_changed(xp: int, xp_to_next: int, level: int) -> void:
	xp_bar.max_value = xp_to_next
	xp_bar.value = xp
	xp_label.text = "Lv %d  %d/%d" % [level, xp, xp_to_next]


func _on_leveled_up(level: int) -> void:
	var tw := create_tween()
	tw.tween_property(xp_bar, "modulate", Color(1.5, 1.35, 0.55), 0.1)
	tw.tween_property(xp_bar, "modulate", Color.WHITE, 0.4)
	_play_level_flash(level)
	_update_next_unlock_hint(level)


func _on_skill_unlocked(reward: Dictionary) -> void:
	_last_unlock_title = str(reward.get("title", "Upgrade"))
	var desc := str(reward.get("desc", ""))
	if unlock_label:
		unlock_label.text = "Unlocked: %s — %s" % [_last_unlock_title, desc]
		unlock_label.modulate = Color(1.2, 1.15, 0.7)
		var tw := create_tween()
		tw.tween_property(unlock_label, "modulate", Color(0.85, 0.95, 0.75, 1), 0.8)
	if level_banner:
		# Show skill name under level banner briefly
		pass


func _update_next_unlock_hint(level: int) -> void:
	const SkillProgression = preload("res://scripts/player/skill_progression.gd")
	var next := SkillProgression.reward_for_level(level + 1)
	if unlock_label == null:
		return
	if next.is_empty():
		unlock_label.text = "Max scripted unlocks — keep ascending!"
	elif _last_unlock_title == "":
		unlock_label.text = "Next @ Lv%d: %s" % [level + 1, str(next.get("title", "?"))]
	else:
		unlock_label.text = "Last: %s  |  Next @ Lv%d: %s" % [
			_last_unlock_title, level + 1, str(next.get("title", "?"))
		]


func _play_level_flash(level: int) -> void:
	if level_flash:
		level_flash.visible = true
		level_flash.color = Color(1.0, 0.92, 0.55, 0.0)
		var ft := create_tween()
		ft.tween_property(level_flash, "color:a", 0.55, 0.08)
		ft.tween_property(level_flash, "color:a", 0.0, 0.45)
		ft.tween_callback(func():
			if is_instance_valid(level_flash):
				level_flash.visible = false
		)
	if level_banner:
		level_banner.visible = true
		level_banner.text = "LEVEL %d!" % level
		level_banner.modulate = Color(1, 1, 1, 0)
		level_banner.scale = Vector2(0.6, 0.6)
		level_banner.pivot_offset = level_banner.size * 0.5
		var bt := create_tween()
		bt.set_parallel(true)
		bt.tween_property(level_banner, "modulate:a", 1.0, 0.12)
		bt.tween_property(level_banner, "scale", Vector2(1.15, 1.15), 0.15)
		bt.chain().tween_property(level_banner, "scale", Vector2.ONE, 0.12)
		bt.tween_property(level_banner, "modulate:a", 0.0, 0.35).set_delay(0.55)
		bt.chain().tween_callback(func():
			if is_instance_valid(level_banner):
				level_banner.visible = false
		)
	if title_label:
		var old := title_label.text
		title_label.text = "Level %d!" % level
		get_tree().create_timer(1.4).timeout.connect(func():
			if is_instance_valid(title_label):
				title_label.text = old
		)


func _on_player_died() -> void:
	death_panel.visible = true
	death_label.text = "You have been slain\nScore: %d  |  Kills: %d  |  Level: %d\n\nPress R to restart" % [
		GameManager.score, GameManager.kills, GameManager.level
	]


func _unhandled_input(event: InputEvent) -> void:
	if death_panel.visible and event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_R:
			GameManager.reset_run()
			get_tree().reload_current_scene()
