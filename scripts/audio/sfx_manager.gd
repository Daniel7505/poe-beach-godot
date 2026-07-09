extends Node
## Lightweight procedural SFX pool — no external audio files required.
## Autoloaded as Sfx.

const POOL_SIZE := 10
const SAMPLE_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # name -> AudioStreamWAV
var _bus_ready: bool = false


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)
	_build_library()


func _build_library() -> void:
	_cache["slash"] = _synth_noise_hit(0.07, 1800.0, 0.55)
	_cache["hit"] = _synth_thump(0.08, 140.0, 0.7)
	_cache["fireball"] = _synth_whoosh(0.22, 0.75)
	_cache["nova"] = _synth_chime(0.18, 520.0, 0.55)
	_cache["dash"] = _synth_whoosh(0.12, 0.5)
	_cache["pickup"] = _synth_chime(0.12, 880.0, 0.6)
	_cache["heal"] = _synth_chime(0.16, 660.0, 0.5)
	_cache["death"] = _synth_noise_hit(0.16, 220.0, 0.85)
	_cache["xp"] = _synth_chime(0.1, 1200.0, 0.45)
	_cache["hurt"] = _synth_thump(0.1, 90.0, 0.65)
	_cache["levelup"] = _synth_level_up()  # Longer fanfare for the celebration


func play(name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not _cache.has(name):
		return
	var player := _next_player()
	if player == null:
		return
	player.stream = _cache[name]
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.volume_db = -4.0 + volume_db
	player.play()


func _next_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	# Steal first if all busy
	return _players[0] if _players.size() > 0 else null


func _synth_noise_hit(duration: float, filter_hz: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * (8.0 + filter_hz * 0.004))
		# Band-limited-ish noise + short tone
		var noise := (randf() * 2.0 - 1.0)
		phase += TAU * filter_hz / float(SAMPLE_RATE)
		var tone := sin(phase) * 0.35
		var s := (noise * 0.65 + tone) * env * volume
		_write_sample(data, i, s)
	return _make_stream(data)


func _synth_thump(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 18.0)
		var f := freq * (1.0 - t * 3.0)
		phase += TAU * maxf(f, 40.0) / float(SAMPLE_RATE)
		var s := sin(phase) * env * volume
		# Click transient
		if i < 40:
			s += (randf() * 2.0 - 1.0) * (1.0 - float(i) / 40.0) * 0.3 * volume
		_write_sample(data, i, s)
	return _make_stream(data)


func _synth_whoosh(duration: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var u := t / duration
		var env := sin(u * PI)  # fade in/out
		var f := lerpf(200.0, 900.0, u)
		phase += TAU * f / float(SAMPLE_RATE)
		var noise := (randf() * 2.0 - 1.0) * 0.55
		var s := (sin(phase) * 0.35 + noise) * env * volume
		_write_sample(data, i, s)
	return _make_stream(data)


func _synth_chime(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var p1 := 0.0
	var p2 := 0.0
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 10.0)
		p1 += TAU * freq / float(SAMPLE_RATE)
		p2 += TAU * freq * 2.01 / float(SAMPLE_RATE)
		var s := (sin(p1) * 0.7 + sin(p2) * 0.3) * env * volume
		_write_sample(data, i, s)
	return _make_stream(data)


func _synth_level_up() -> AudioStreamWAV:
	## Brighter multi-note fanfare for the level-up celebration.
	var duration := 0.55
	var n := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	var step := 0.09
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var note_i := mini(int(t / step), notes.size() - 1)
		var f: float = notes[note_i]
		var local_t := t - float(note_i) * step
		var env := exp(-local_t * 7.0)
		# Layer octave for richness
		var s := (sin(TAU * f * t) * 0.65 + sin(TAU * f * 2.0 * t) * 0.25) * env * 0.6
		# Soft sparkle noise at note starts
		if local_t < 0.012:
			s += (randf() * 2.0 - 1.0) * 0.12 * (1.0 - local_t / 0.012)
		_write_sample(data, i, s)
	return _make_stream(data)


func _write_sample(data: PackedByteArray, i: int, sample: float) -> void:
	var s := int(clampf(sample, -1.0, 1.0) * 32767.0)
	var idx := i * 2
	data[idx] = s & 0xFF
	data[idx + 1] = (s >> 8) & 0xFF


func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
