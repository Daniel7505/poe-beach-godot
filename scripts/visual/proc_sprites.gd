extends RefCounted
## Procedural pixel-art sprite sheets for exile / crab / zombie (no external art).

const SIZE := 32


static func exile_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", [_draw_exile(0), _draw_exile(1)], 4.0, true)
	_add_anim(frames, "walk", [_draw_exile(2), _draw_exile(3), _draw_exile(2), _draw_exile(4)], 8.0, true)
	_add_anim(frames, "attack", [_draw_exile(5), _draw_exile(6)], 12.0, false)
	_add_anim(frames, "dash", [_draw_exile(7)], 1.0, true)
	return frames


static func crab_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", [_draw_crab(0), _draw_crab(1)], 3.0, true)
	_add_anim(frames, "walk", [_draw_crab(2), _draw_crab(3), _draw_crab(4), _draw_crab(3)], 10.0, true)
	_add_anim(frames, "attack", [_draw_crab(5), _draw_crab(6)], 10.0, false)
	return frames


static func zombie_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", [_draw_zombie(0), _draw_zombie(1)], 2.5, true)
	_add_anim(frames, "walk", [_draw_zombie(2), _draw_zombie(3), _draw_zombie(4), _draw_zombie(3)], 6.0, true)
	_add_anim(frames, "attack", [_draw_zombie(5), _draw_zombie(6)], 8.0, false)
	return frames


static func spitter_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", [_draw_spitter(0), _draw_spitter(1)], 3.5, true)
	_add_anim(frames, "walk", [_draw_spitter(2), _draw_spitter(3), _draw_spitter(4), _draw_spitter(3)], 9.0, true)
	_add_anim(frames, "attack", [_draw_spitter(5), _draw_spitter(6)], 10.0, false)
	return frames


static func charger_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", [_draw_charger(0), _draw_charger(1)], 2.8, true)
	_add_anim(frames, "walk", [_draw_charger(2), _draw_charger(3), _draw_charger(4), _draw_charger(3)], 7.0, true)
	_add_anim(frames, "attack", [_draw_charger(5), _draw_charger(6)], 9.0, false)
	return frames


static func _add_anim(sf: SpriteFrames, name: String, imgs: Array, speed: float, loop: bool) -> void:
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for img in imgs:
		var tex := ImageTexture.create_from_image(img)
		sf.add_frame(name, tex)


static func _img() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return
	# Alpha blend over existing
	var dst := img.get_pixel(x, y)
	if c.a >= 0.99 or dst.a < 0.01:
		img.set_pixel(x, y, c)
	else:
		var a := c.a + dst.a * (1.0 - c.a)
		var rgb := (c * c.a + dst * dst.a * (1.0 - c.a)) / maxf(a, 0.001)
		rgb.a = a
		img.set_pixel(x, y, rgb)


static func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, x, y, c)


static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			_p(img, x, y, c)


static func _draw_exile(frame: int) -> Image:
	var img := _img()
	var bob := 0
	var leg := 0
	var arm := 0
	match frame:
		1:
			bob = -1
		2:
			leg = -2
			arm = 1
		3:
			leg = 2
			arm = -1
		4:
			leg = -1
			arm = 1
		5:
			arm = 3
		6:
			arm = 6
		7:
			bob = -2
	# Soft contact shadow
	_fill_ellipse(img, 16, 28, 8, 2.8, Color(0.1, 0.05, 0.02, 0.38))
	# Legs
	var pant := Color("2a3344")
	_fill_rect(img, 12, 20 + bob, 3, 7 + leg, pant)
	_fill_rect(img, 17, 20 + bob, 3, 7 - leg, pant)
	_fill_rect(img, 12, 26 + bob + maxi(leg, 0), 3, 2, Color("1a1520"))
	_fill_rect(img, 17, 26 + bob + maxi(-leg, 0), 3, 2, Color("1a1520"))
	# Body (armor blue + red cloth — PoE exile vibe)
	_fill_rect(img, 11, 12 + bob, 10, 10, Color("3d5f8a"))
	_fill_rect(img, 12, 13 + bob, 8, 8, Color("4a72a0"))
	_fill_rect(img, 13, 14 + bob, 3, 3, Color("6a92c0"))  # chest highlight
	# Red sash / cape flap
	_fill_rect(img, 10, 14 + bob, 2, 9, Color("8b2a2a"))
	_fill_rect(img, 9, 16 + bob, 2, 6, Color("6e1f1f"))
	_fill_rect(img, 20, 15 + bob, 2, 6, Color("6e1f1f"))
	# Belt + buckle
	_fill_rect(img, 11, 20 + bob, 10, 2, Color("c4a35a"))
	_fill_rect(img, 15, 20 + bob, 2, 2, Color("e8d080"))
	# Head
	_fill_ellipse(img, 16, 9 + bob, 5, 5.5, Color("e0b892"))
	_fill_ellipse(img, 16, 8 + bob, 5, 3.5, Color("2c2430"))  # hair
	_fill_rect(img, 13, 6 + bob, 6, 2, Color("1a1520"))  # hair fringe
	# Eyes + brow
	_p(img, 14, 9 + bob, Color("1a1010"))
	_p(img, 18, 9 + bob, Color("1a1010"))
	_p(img, 14, 8 + bob, Color("3a2a20"))
	_p(img, 18, 8 + bob, Color("3a2a20"))
	# Arms
	var skin := Color("d4a882")
	_fill_rect(img, 8, 14 + bob, 3, 6, skin)
	_fill_rect(img, 21, 14 + bob - arm / 2, 3, 6 + absi(arm) / 2, skin)
	# Shoulder pads
	_fill_rect(img, 9, 12 + bob, 3, 3, Color("c0c6d0"))
	_fill_rect(img, 20, 12 + bob, 3, 3, Color("c0c6d0"))
	_p(img, 10, 12 + bob, Color("e8ecf2"))
	_p(img, 21, 12 + bob, Color("e8ecf2"))
	# Weapon glint on attack frames
	if frame >= 5:
		_fill_rect(img, 22 + arm, 12 + bob, 6, 2, Color("dfe6f0"))
		_fill_rect(img, 26 + arm, 11 + bob, 2, 4, Color("b0b8c4"))
		_p(img, 27 + arm, 11 + bob, Color("ffffff"))
	_outline(img, Color(0.08, 0.06, 0.1, 0.85))
	return img


static func _draw_crab(frame: int) -> Image:
	var img := _img()
	var claw := 0
	var leg := 0
	match frame:
		1:
			claw = 1
		2:
			leg = 1
		3:
			leg = -1
			claw = 1
		4:
			leg = 1
		5:
			claw = 3
		6:
			claw = 5
	_fill_ellipse(img, 16, 26, 8, 2.5, Color(0.1, 0.05, 0.02, 0.3))
	# Legs
	var leg_c := Color("c45a38")
	for i in 3:
		var ox := 8 + i * 3
		_fill_rect(img, ox, 20 + (leg if i % 2 == 0 else -leg), 2, 5, leg_c)
		_fill_rect(img, 22 - i * 3, 20 + (-leg if i % 2 == 0 else leg), 2, 5, leg_c)
	# Body shell
	_fill_ellipse(img, 16, 16, 10, 7, Color("d45a32"))
	_fill_ellipse(img, 16, 15, 8, 5, Color("e87040"))
	_fill_ellipse(img, 16, 14, 4, 2.5, Color("f0a070"))
	# Eyes on stalks
	_fill_rect(img, 12, 8, 2, 4, Color("c45a38"))
	_fill_rect(img, 18, 8, 2, 4, Color("c45a38"))
	_fill_ellipse(img, 13, 7, 2, 2, Color("1a1010"))
	_fill_ellipse(img, 19, 7, 2, 2, Color("1a1010"))
	_p(img, 13, 7, Color("f0e060"))
	_p(img, 19, 7, Color("f0e060"))
	# Claws
	var claw_c := Color("e87840")
	_fill_ellipse(img, 6 - claw, 14, 5, 3.5, claw_c)
	_fill_ellipse(img, 26 + claw, 14, 5, 3.5, claw_c)
	_fill_rect(img, 3 - claw, 12, 4, 2, Color("f0a070"))
	_fill_rect(img, 25 + claw, 12, 4, 2, Color("f0a070"))
	# Shell ridges
	_fill_rect(img, 12, 14, 8, 1, Color("c45030"))
	_fill_rect(img, 13, 17, 6, 1, Color("c45030"))
	_outline(img, Color(0.15, 0.05, 0.02, 0.8))
	return img


static func _draw_zombie(frame: int) -> Image:
	var img := _img()
	var bob := 0
	var arm := 0
	var lean := 0
	match frame:
		1:
			bob = 1
		2:
			lean = -1
			arm = 1
		3:
			lean = 1
		4:
			lean = -1
			arm = 2
		5:
			arm = 4
		6:
			arm = 7
	_fill_ellipse(img, 16, 28, 7, 2.5, Color(0.05, 0.08, 0.04, 0.35))
	# Legs (shamble)
	var rag := Color("3d4a38")
	_fill_rect(img, 12 + lean, 20 + bob, 3, 7, rag)
	_fill_rect(img, 17 - lean, 20 + bob, 3, 7, rag)
	_fill_rect(img, 12 + lean, 26 + bob, 3, 2, Color("2a2018"))
	_fill_rect(img, 17 - lean, 26 + bob, 3, 2, Color("2a2018"))
	# Torso
	_fill_rect(img, 11 + lean, 11 + bob, 10, 11, Color("5a6b4e"))
	_fill_rect(img, 12 + lean, 12 + bob, 8, 9, Color("6a7d5a"))
	# Torn cloth
	_fill_rect(img, 10 + lean, 18 + bob, 2, 5, Color("4a3a2a"))
	# Head
	_fill_ellipse(img, 16 + lean, 8 + bob, 5, 5.5, Color("8a9a72"))
	_fill_ellipse(img, 16 + lean, 7 + bob, 5, 2.5, Color("4a5540"))
	# Hollow eyes
	_fill_rect(img, 13 + lean, 8 + bob, 2, 2, Color("1a2010"))
	_fill_rect(img, 17 + lean, 8 + bob, 2, 2, Color("1a2010"))
	_p(img, 14 + lean, 8 + bob, Color("c0e060"))
	_p(img, 18 + lean, 8 + bob, Color("c0e060"))
	# Reaching arm
	_fill_rect(img, 21 + lean, 12 + bob, 3 + arm, 3, Color("7a8a62"))
	_fill_rect(img, 23 + lean + arm, 11 + bob, 3, 4, Color("8a9a72"))
	# Other arm hang
	_fill_rect(img, 8 + lean, 14 + bob, 3, 6, Color("7a8a62"))
	# Wound detail
	_p(img, 14 + lean, 15 + bob, Color("4a3028"))
	_p(img, 15 + lean, 16 + bob, Color("3a2018"))
	_outline(img, Color(0.05, 0.08, 0.04, 0.85))
	return img


static func _draw_spitter(frame: int) -> Image:
	var img := _img()
	var bob := 0
	var stretch := 0
	match frame:
		1:
			bob = -1
		2, 4:
			stretch = 1
		3:
			stretch = -1
		5:
			stretch = 2
		6:
			stretch = 4
	_fill_ellipse(img, 16, 26, 7, 2.2, Color(0.05, 0.08, 0.03, 0.32))
	# Segmented body
	_fill_ellipse(img, 16, 17 + bob, 8, 6, Color("4a7a30"))
	_fill_ellipse(img, 16, 15 + bob, 6, 4, Color("5a9a3a"))
	_fill_ellipse(img, 10 - stretch, 16 + bob, 4, 3, Color("3a6a28"))
	_fill_ellipse(img, 22 + stretch, 16 + bob, 4, 3, Color("3a6a28"))
	# Legs
	for i in 3:
		_fill_rect(img, 8 + i * 2, 20 + bob + (stretch if i % 2 == 0 else -stretch), 2, 4, Color("3a5520"))
		_fill_rect(img, 20 - i * 2, 20 + bob + (-stretch if i % 2 == 0 else stretch), 2, 4, Color("3a5520"))
	# Head / spit sac
	_fill_ellipse(img, 16, 10 + bob, 5, 4, Color("6ab040"))
	_p(img, 14, 9 + bob, Color("1a2010"))
	_p(img, 18, 9 + bob, Color("1a2010"))
	_p(img, 14, 9 + bob, Color("c0f060"))
	_p(img, 18, 9 + bob, Color("c0f060"))
	if frame >= 5:
		_fill_ellipse(img, 16 + stretch, 6 + bob, 3, 2, Color("a0e040"))
	_outline(img, Color(0.08, 0.12, 0.04, 0.85))
	return img


static func _draw_charger(frame: int) -> Image:
	var img := _img()
	var bob := 0
	var lean := 0
	match frame:
		1:
			bob = 1
		2:
			lean = -1
		3:
			lean = 1
		4:
			lean = -1
		5:
			lean = 2
			bob = 1
		6:
			lean = 4
	_fill_ellipse(img, 16, 28, 9, 2.6, Color(0.1, 0.07, 0.03, 0.36))
	# Thick legs
	_fill_rect(img, 11 + lean, 20 + bob, 4, 7, Color("6a5438"))
	_fill_rect(img, 17 + lean, 20 + bob, 4, 7, Color("6a5438"))
	_fill_rect(img, 11 + lean, 26 + bob, 4, 2, Color("3a2a18"))
	_fill_rect(img, 17 + lean, 26 + bob, 4, 2, Color("3a2a18"))
	# Stocky body
	_fill_ellipse(img, 16 + lean, 15 + bob, 10, 8, Color("b89050"))
	_fill_ellipse(img, 16 + lean, 14 + bob, 7, 5, Color("d0a860"))
	# Head / beak
	_fill_ellipse(img, 16 + lean * 2, 8 + bob, 5, 4, Color("c8a060"))
	_fill_rect(img, 20 + lean * 2, 8 + bob, 5, 2, Color("e8c878"))
	_p(img, 14 + lean, 8 + bob, Color("1a1010"))
	_p(img, 15 + lean, 8 + bob, Color("f0e080"))
	# Shoulder crest
	_fill_rect(img, 10 + lean, 11 + bob, 3, 4, Color("8a6840"))
	if frame >= 5:
		# Dust streaks while charging
		_fill_rect(img, 4, 22, 3, 1, Color(0.85, 0.75, 0.5, 0.5))
		_fill_rect(img, 2, 24, 4, 1, Color(0.8, 0.7, 0.45, 0.35))
	_outline(img, Color(0.12, 0.08, 0.04, 0.85))
	return img


static func _outline(img: Image, color: Color) -> void:
	## Dark silhouette edge for readable pixel characters on sand.
	var copy := img.duplicate()
	for y in SIZE:
		for x in SIZE:
			if copy.get_pixel(x, y).a < 0.2:
				continue
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					var nx := x + ox
					var ny := y + oy
					if nx < 0 or ny < 0 or nx >= SIZE or ny >= SIZE:
						continue
					if copy.get_pixel(nx, ny).a < 0.15:
						_p(img, nx, ny, color)
