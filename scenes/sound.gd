extends Node
## Sonido estilo 8 bits, generado por código al empezar (no usa archivos de audio).
##   play("move")          efecto corto
##   music("title")        música en bucle ("title", "battle", "win", "lose" o "" para parar)
##   set_levels(sfx, mus)  0 apagado · 1 bajo · 2 medio · 3 alto
##
## TUS PROPIOS ARCHIVOS (reemplazan a los generados):
##   música:  musica/titulo.ogg   (pantalla de título y editor)
##            musica/duelo.ogg    (durante la partida)
##            musica/victoria.ogg / musica/derrota.ogg   (al terminar, opcionales)
##   efectos: sonidos/<nombre>.ogg  con los nombres de la lista SFX_NAMES de abajo
##   golpes de la mini pelea: sonidos/golpes/<familia>_<fisico|distancia>_<debil|fuerte>.ogg
##            (familia = tipo del Pokémon en los juegos: tierra, volador, siniestro...; ver hit())
##            y sonidos/golpes/super_efectivo.ogg (golpe a la Debilidad; reemplaza a "weak")
## Sirven .ogg, .mp3 o .wav. Se buscan en la carpeta del proyecto (res://) y en la
## carpeta de datos del usuario (user://), igual que los sprites. La música vuelve a
## empezar sola cuando termina.

const RATE := 22050          # efectos
const MUSIC_RATE := 16000    # música generada (alcanza para chiptune y se arma más rápido)
const LEVEL_DB := [-80.0, -18.0, -11.0, -6.0]
const LEVEL_NAMES := ["Off", "Low", "Medium", "High"]
const DIRS := ["res://", "user://"]
const EXTS := ["ogg", "mp3", "wav"]
const MUSIC_FILES := {"title": "titulo", "decks": "mazos", "battle": "duelo", "win": "victoria", "lose": "derrota"}
## Pistas que se repiten. "battle" elige al azar entre duelo, duelo2, duelo3... en cada duelo.
## musica/<pista>.json (tools/armar_musica.py) dice desde dónde se repite: {"loop_offset": segundos}.
const LOOPING := ["title", "decks", "battle"]
const SFX_NAMES := ["move", "ok", "back", "error", "coin", "heads", "tails", "draw", "shuffle", "trainer",
		"energy", "evolve", "evolved", "ko", "prize", "turn", "win", "lose",
		"hit_Fire", "hit_Water", "hit_Grass", "hit_Lightning", "hit_Psychic", "hit_Fighting",
		"hit_Darkness", "hit_Metal", "hit_Colorless", "special", "vs", "encounter", "door", "blip", "weak", "shine", "viento"]
## Efectos que cambian un poquito de tono cada vez (para que no suenen siempre idénticos).
const VARY := {"blip": 0.04, "move": 0.03, "draw": 0.08, "coin": 0.05, "energy": 0.04, "shuffle": 0.05,
		"hit_Fire": 0.06, "hit_Water": 0.06, "hit_Grass": 0.06, "hit_Lightning": 0.06, "hit_Psychic": 0.06,
		"hit_Fighting": 0.06, "hit_Darkness": 0.06, "hit_Metal": 0.06, "hit_Colorless": 0.06}
## Volumen propio de cada efecto (dB): los de menú van más bajos porque suenan todo el tiempo.
const GAIN := {"move": -7.0, "ok": -10.0, "back": -6.0, "draw": -3.0, "shuffle": -3.0, "turn": -2.0, "blip": -12.0}
## Nombres en castellano que también sirven para los efectos de siempre (sonidos/atras.ogg = "back"...).
const FILE_NAMES := {"back": "atras", "ok": "confirmar", "energy": "unir_energia", "turn": "cambio_turno",
		"ko": "faint", "shuffle": "mezclar", "coin": "coin-flip", "heads": "coin-land", "tails": "coin-land",
		"move": "cursor", "prize": "premio", "evolve": "evolucion"}
## Efectos con varias versiones: cada vez suena una al azar (sonidos/cardDraw.ogg, cardDraw02.ogg...).
const VARIANTS := {"draw": ["cardDraw", "cardDraw02", "cardDraw03", "cardDraw04", "cardDraw05"]}
const COOLDOWN := 0.07       # el mismo efecto no se repite antes de este tiempo (s)
const COOLDOWNS := {"blip": 0.045}

var sfx_level := 2
var music_level := 2
var _sfx := {}               # nombre -> AudioStream
var _music := {}             # nombre -> AudioStream
var _custom_music := {}      # nombre -> true si vino de un archivo tuyo
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music := ""
var _music_loops := true
var _next := 0
var _last_played := {}       # nombre -> tiempo (s)
var _rng := RandomNumberGenerator.new()
var _hit_files := {}         # golpes de sonidos/golpes/: nombre -> AudioStream (o null si no está)
var custom_weak := false     # hay sonidos/golpes/super_efectivo
var _variants := {}          # nombre -> [AudioStream] (VARIANTS)


func _ready() -> void:
	_rng.randomize()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)
	_build_sfx()
	for n in SFX_NAMES:
		var custom := _load_file("sonidos/" + n)
		if custom == null and FILE_NAMES.has(n):
			custom = _load_file("sonidos/" + str(FILE_NAMES[n]))
		if custom != null:
			_sfx[n] = custom
	for n in VARIANTS:
		var list: Array = []
		for base in VARIANTS[n]:
			var v := _load_file("sonidos/" + str(base))
			if v != null:
				list.append(v)
		if not list.is_empty():
			_variants[n] = list
	# La evolución propia ya trae su final: no se suma el "evolved" generado encima.
	if _load_file("sonidos/evolucion") != null and _load_file("sonidos/evolved") == null:
		_sfx.erase("evolved")
	var sup := _load_file("sonidos/golpes/super_efectivo")
	if sup != null:
		_sfx["weak"] = sup
		custom_weak = true
	set_levels(sfx_level, music_level)


func set_levels(sfx: int, mus: int) -> void:
	sfx_level = clampi(sfx, 0, 3)
	music_level = clampi(mus, 0, 3)
	if _music_player == null:
		return
	_music_player.volume_db = LEVEL_DB[music_level] - (0.0 if _custom_music.get(_current_music, false) else 5.0)
	if music_level == 0:
		_music_player.stop()
	elif _current_music != "" and not _music_player.playing and _music_player.stream != null and _music_loops \
			and _music_held() <= 0.0:
		_music_player.play()


func play(name: String, pitch: float = 1.0) -> void:
	if sfx_level == 0 or not (_sfx.has(name) or _variants.has(name)):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(name, -10.0)) < float(COOLDOWNS.get(name, COOLDOWN)):
		return
	_last_played[name] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	if _variants.has(name):
		var list: Array = _variants[name]
		p.stream = list[_rng.randi() % list.size()]
	else:
		p.stream = _sfx[name]
	var v: float = VARY.get(name, 0.0)
	p.pitch_scale = pitch * (1.0 + _rng.randf_range(-v, v))
	p.volume_db = LEVEL_DB[sfx_level] + float(GAIN.get(name, 0.0))
	p.play()


## Golpe de la mini pelea con un archivo propio: prueba los nombres en orden
## (<familia>_<fisico|distancia>_<debil|fuerte> y parecidos) y toca el primero que exista.
## Devuelve false si no hay ninguno (entonces suena el golpe generado del tipo de la carta).
func hit(names: Array) -> bool:
	return fx(names)


## Efecto con archivo propio, sin uno generado de reemplazo (usar_soporte, envenenar,
## power_curar...): busca en sonidos/golpes/ y en sonidos/, y toca el primero que exista.
func fx(names: Array) -> bool:
	for n in names:
		if not _hit_files.has(n):
			var st := _load_file("sonidos/golpes/" + str(n))
			if st == null:
				st = _load_file("sonidos/" + str(n))
			_hit_files[n] = st
		var st: AudioStream = _hit_files[n]
		if st == null:
			continue
		if sfx_level == 0:
			return true
		var p := _players[_next]
		_next = (_next + 1) % _players.size()
		p.stream = st
		p.pitch_scale = 1.0
		p.volume_db = LEVEL_DB[sfx_level]
		p.play()
		_last_fx_len = st.get_length()
		return true
	return false


## Un efecto que va antes de la música (comenzar_partida): corta la que está sonando y la
## siguiente pista recién empieza cuando el efecto termina.
var _last_fx_len := 0.0
var _hold_until := 0.0

func jingle(names: Array) -> bool:
	if not fx(names):
		return false
	if sfx_level > 0:
		_hold_until = Time.get_ticks_msec() / 1000.0 + _last_fx_len
		_music_player.stop()
	return true


func _music_held() -> float:
	return maxf(0.0, _hold_until - Time.get_ticks_msec() / 1000.0)


func _resume_music() -> void:
	var left := _music_held()
	if left > 0.0:
		get_tree().create_timer(left + 0.02).timeout.connect(_resume_music)
		return
	if music_level > 0 and _music_player.stream != null and not _music_player.playing and _current_music != "":
		_music_player.play()


## "title", "battle", "win", "lose" o "" (silencio). "win"/"lose" no se repiten.
func music(name: String) -> void:
	if name == _current_music:
		return
	_current_music = name
	_music_player.stop()
	if name == "":
		return
	if name == "battle":
		_pick_battle_track()
	if not _music.has(name):
		var custom := _load_track(str(MUSIC_FILES.get(name, name)), name in LOOPING)
		_custom_music[name] = custom != null
		if custom != null:
			_music[name] = custom
		elif name in ["title", "battle"]:
			_music[name] = _build_music(name)
		elif name == "decks":           # sin música propia del editor: la del título
			var t := _load_track("titulo", true)
			_custom_music[name] = t != null
			_music[name] = t if t != null else _build_music("title")
		else:
			_music[name] = null          # victoria/derrota: sin archivo, alcanza con el efecto
	_music_loops = name in LOOPING
	_music_player.stream = _music[name]
	set_levels(sfx_level, music_level)    # el volumen depende de si es tuya o generada
	var wait := _music_held()
	if wait > 0.0:
		get_tree().create_timer(wait).timeout.connect(_resume_music)    # después del efecto
	elif music_level > 0 and _music[name] != null and not _music_player.playing:
		_music_player.play()


## Cada duelo suena una de las pistas de duelo que haya (duelo, duelo2, duelo3...), al azar.
var _battle_tracks := []         # [[nombre de archivo, AudioStream]]

func _pick_battle_track() -> void:
	if _battle_tracks.is_empty():
		for i in range(1, 10):
			var base := "duelo" if i == 1 else "duelo%d" % i
			var st := _load_track(base, true)
			if st != null:
				_battle_tracks.append([base, st])
		if _battle_tracks.is_empty():
			_battle_tracks.append(["", null])
	var pick: Array = _battle_tracks[_rng.randi() % _battle_tracks.size()]
	if pick[1] != null:
		_music["battle"] = pick[1]
		_custom_music["battle"] = true


## Carga una pista y, si se repite, le pone el loop (desde loop_offset de su .json).
func _load_track(base: String, looping: bool) -> AudioStream:
	var st := _load_file("musica/" + base)
	if st == null or not looping:
		return st
	var offset := 0.0
	for d in DIRS:
		var jp: String = d + "musica/" + base + ".json"
		if FileAccess.file_exists(jp):
			var info = JSON.parse_string(FileAccess.get_file_as_string(jp))
			if info is Dictionary:
				offset = float(info.get("loop_offset", 0.0))
			break
	if st is AudioStreamOggVorbis or st is AudioStreamMP3:
		st.loop = true
		st.loop_offset = offset
	elif st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = int(offset * st.mix_rate)
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st


func has_custom_music(name: String) -> bool:
	return _custom_music.get(name, false)


func _on_music_finished() -> void:
	if _music_loops and _current_music != "" and music_level > 0:
		_music_player.play()


## Busca base.ogg / .mp3 / .wav en res:// y user://. Devuelve null si no hay.
func _load_file(base: String) -> AudioStream:
	for d in DIRS:
		for e in EXTS:
			var path: String = d + base + "." + e
			if d == "res://" and ResourceLoader.exists(path):
				var res = load(path)       # importado por el editor de Godot
				if res is AudioStream:
					return res
			if FileAccess.file_exists(path):
				var s := _load_raw(path, e)
				if s != null:
					return s
	return null


## Carga un archivo sin pasar por el importador (por ejemplo, si lo copiaste con el
## juego cerrado o está en user://).
func _load_raw(path: String, ext: String) -> AudioStream:
	match ext:
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			return mp3 if not mp3.data.is_empty() else null
		"wav":
			return _load_wav(path)
	return null


## WAV PCM de 8 o 16 bits (lo que exporta cualquier editor de audio).
func _load_wav(path: String) -> AudioStreamWAV:
	var b := FileAccess.get_file_as_bytes(path)
	if b.size() < 44 or b.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var pos := 12
	var channels := 1
	var rate := 22050
	var bits := 16
	while pos + 8 <= b.size():
		var id := b.slice(pos, pos + 4).get_string_from_ascii()
		var size := b.decode_u32(pos + 4)
		if id == "fmt ":
			channels = b.decode_u16(pos + 10)
			rate = b.decode_u32(pos + 12)
			bits = b.decode_u16(pos + 22)
		elif id == "data":
			var w := AudioStreamWAV.new()
			w.format = AudioStreamWAV.FORMAT_16_BITS if bits == 16 else AudioStreamWAV.FORMAT_8_BITS
			w.stereo = channels == 2
			w.mix_rate = rate
			var data := b.slice(pos + 8, pos + 8 + size)
			if bits == 8:      # WAV guarda 8 bits sin signo; Godot los quiere con signo
				for i in data.size():
					data[i] = (data[i] + 128) & 0xFF
			w.data = data
			return w
		pos += 8 + size + (size & 1)
	return null


# ===========================================================================
# Síntesis
# ===========================================================================

var _noise_state := 0x7ACE


## Un tono con barrido de frecuencia y envolvente. wave: "sq" (cuadrada), "tri", "noise".
## La caída es exponencial (como en las consolas): suena más natural que una recta.
func _tone(f0: float, f1: float, dur: float, wave: String = "sq", vol: float = 0.5,
		duty: float = 0.5, attack: float = 0.004, rate: int = RATE) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var noise_v := 0.0
	var noise_count := 0.0
	for i in n:
		var k := float(i) / maxf(1.0, n - 1)
		var f := lerpf(f0, f1, k)
		phase = fmod(phase + f / rate, 1.0)
		var s := 0.0
		match wave:
			"sq":
				s = 1.0 if phase < duty else -1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				noise_count += f / rate
				if noise_count >= 1.0:
					noise_count -= 1.0
					var bit := (_noise_state ^ (_noise_state >> 1)) & 1
					_noise_state = (_noise_state >> 1) | (bit << 14)
					noise_v = 1.0 if _noise_state & 1 else -1.0
				s = noise_v
		var env := minf(1.0, float(i) / maxf(1.0, attack * rate)) * pow(1.0 - k, 1.6)
		out[i] = s * vol * env
	return out


func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


func _silence(dur: float, rate: int = RATE) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * rate))
	return out


## Filtro pasa-bajos suave: le saca lo "chillón" a las ondas cuadradas.
func _soften(s: PackedFloat32Array, alpha: float) -> PackedFloat32Array:
	var y := 0.0
	for i in s.size():
		y += alpha * (s[i] - y)
		s[i] = y
	return s


func _wav(samples: PackedFloat32Array, rate: int = RATE, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


# ===========================================================================
# Efectos
# ===========================================================================

func _build_sfx() -> void:
	var s := {}
	# Menú: cortitos y suaves (triangular), porque se oyen a cada rato.
	s["move"] = _tone(1050, 1050, 0.03, "tri", 0.5)
	s["ok"] = _cat([_tone(880, 880, 0.035, "sq", 0.22, 0.25), _tone(1320, 1320, 0.06, "sq", 0.22, 0.25)])
	s["back"] = _cat([_tone(784, 784, 0.035, "tri", 0.45), _tone(523, 523, 0.06, "tri", 0.45)])
	s["error"] = _tone(180, 150, 0.14, "sq", 0.22, 0.5)
	s["coin"] = _cat([_tone(1568, 1568, 0.025, "sq", 0.2, 0.125), _tone(2093, 2093, 0.05, "sq", 0.2, 0.125)])
	s["heads"] = _cat([_tone(1319, 1319, 0.05, "sq", 0.25, 0.25), _tone(1976, 1976, 0.14, "sq", 0.25, 0.25)])
	s["tails"] = _cat([_tone(659, 659, 0.05, "tri", 0.5), _tone(494, 494, 0.14, "tri", 0.5)])
	s["draw"] = _tone(2500, 5000, 0.07, "noise", 0.16)
	s["shuffle"] = _cat([_tone(4000, 4000, 0.035, "noise", 0.14), _silence(0.035), _tone(4500, 4500, 0.035, "noise", 0.12),
			_silence(0.035), _tone(4000, 4000, 0.035, "noise", 0.14), _silence(0.035), _tone(3500, 3500, 0.06, "noise", 0.15)])
	s["trainer"] = _mix(_tone(1500, 6000, 0.16, "noise", 0.09), _tone(523, 1047, 0.16, "tri", 0.3))
	s["energy"] = _cat([_tone(1047, 1047, 0.035, "sq", 0.18, 0.125), _tone(1319, 1319, 0.035, "sq", 0.18, 0.125),
			_tone(1568, 1568, 0.035, "sq", 0.18, 0.125), _tone(2093, 2093, 0.09, "sq", 0.18, 0.125)])
	s["evolve"] = _mix(_tone(220, 1400, 0.9, "sq", 0.12, 0.25, 0.25), _tone(330, 2100, 0.9, "tri", 0.3, 0.5, 0.25))
	s["evolved"] = _cat([_tone(1047, 1047, 0.07, "sq", 0.22, 0.25), _tone(1319, 1319, 0.07, "sq", 0.22, 0.25),
			_tone(1568, 1568, 0.07, "sq", 0.22, 0.25), _tone(2093, 2093, 0.28, "sq", 0.22, 0.25)])
	s["ko"] = _cat([_tone(784, 784, 0.07, "sq", 0.24, 0.5), _tone(587, 587, 0.07, "sq", 0.24, 0.5),
			_tone(440, 440, 0.07, "sq", 0.24, 0.5), _tone(294, 150, 0.32, "sq", 0.24, 0.5)])
	s["prize"] = _cat([_tone(1047, 1047, 0.06, "sq", 0.22, 0.25), _tone(1319, 1319, 0.06, "sq", 0.22, 0.25),
			_tone(1568, 1568, 0.06, "sq", 0.22, 0.25), _tone(2093, 2093, 0.06, "sq", 0.22, 0.25),
			_tone(1568, 1568, 0.06, "sq", 0.22, 0.25), _tone(2093, 2093, 0.28, "sq", 0.22, 0.25)])
	s["turn"] = _cat([_tone(784, 784, 0.07, "tri", 0.45), _tone(1175, 1175, 0.14, "tri", 0.45)])
	# Golpes según el tipo de Energía del ataque
	s["hit_Fire"] = _mix(_tone(600, 2500, 0.32, "noise", 0.24, 0.5, 0.02), _tone(300, 80, 0.32, "sq", 0.12, 0.5))
	s["hit_Water"] = _cat([_tone(1200, 400, 0.07, "tri", 0.45), _tone(1400, 500, 0.07, "tri", 0.45), _tone(1000, 300, 0.11, "tri", 0.45)])
	s["hit_Grass"] = _mix(_tone(5000, 1800, 0.22, "noise", 0.15, 0.5, 0.04), _tone(880, 1320, 0.18, "tri", 0.3))
	s["hit_Lightning"] = _cat([_tone(1800, 200, 0.045, "sq", 0.22, 0.5), _tone(1600, 200, 0.045, "sq", 0.22, 0.5),
			_mix(_tone(2000, 100, 0.18, "sq", 0.18, 0.25), _tone(7000, 7000, 0.18, "noise", 0.15))])
	s["hit_Psychic"] = _cat([_tone(600, 900, 0.09, "tri", 0.45), _tone(900, 500, 0.09, "tri", 0.45), _tone(500, 1000, 0.13, "tri", 0.45)])
	s["hit_Fighting"] = _mix(_tone(160, 50, 0.16, "sq", 0.35, 0.5), _tone(1200, 1200, 0.09, "noise", 0.28))
	s["hit_Darkness"] = _mix(_tone(300, 60, 0.28, "sq", 0.22, 0.125), _tone(800, 300, 0.28, "noise", 0.12))
	s["hit_Metal"] = _cat([_tone(2637, 2637, 0.05, "sq", 0.18, 0.125), _tone(3136, 3136, 0.18, "sq", 0.16, 0.125)])
	s["hit_Colorless"] = _mix(_tone(220, 70, 0.15, "sq", 0.32, 0.5), _tone(2000, 2000, 0.07, "noise", 0.2))
	# Ataque especial: un barrido que sube; cara a cara: dos golpes y un acorde
	s["special"] = _mix(_tone(200, 1600, 0.5, "sq", 0.12, 0.25, 0.05), _tone(300, 2400, 0.5, "noise", 0.08))
	s["vs"] = _cat([_mix(_tone(140, 60, 0.12, "sq", 0.3, 0.5), _tone(3000, 3000, 0.08, "noise", 0.2)), _silence(0.06),
			_mix(_tone(140, 60, 0.12, "sq", 0.3, 0.5), _tone(3000, 3000, 0.08, "noise", 0.2)),
			_mix(_tone(523, 523, 0.4, "sq", 0.16, 0.25, 0.2), _tone(784, 784, 0.4, "sq", 0.12, 0.25, 0.2))])
	# Mapa: desafío de un rival (subida rápida y destello), puerta, y el "blip" del texto
	s["encounter"] = _cat([_tone(392, 1568, 0.18, "sq", 0.2, 0.25), _tone(1568, 1568, 0.05, "sq", 0.18, 0.125),
			_tone(1319, 1319, 0.05, "sq", 0.18, 0.125), _tone(1568, 1568, 0.05, "sq", 0.18, 0.125),
			_mix(_tone(2093, 2093, 0.3, "sq", 0.16, 0.25, 0.01), _tone(6000, 2000, 0.3, "noise", 0.08))])
	s["door"] = _cat([_tone(1800, 600, 0.09, "noise", 0.16), _tone(240, 160, 0.12, "sq", 0.16, 0.5)])
	s["blip"] = _tone(1400, 1400, 0.018, "sq", 0.14, 0.5)
	# Golpe a la debilidad: un estallido grave con crujido
	s["weak"] = _mix(_tone(120, 40, 0.42, "sq", 0.36, 0.5), _tone(5000, 600, 0.42, "noise", 0.3, 0.5, 0.002))
	# Un Pokémon ex llega a la mesa: un brillo que sube tintineando
	s["shine"] = _mix(_cat([_tone(1568, 1568, 0.04, "tri", 0.3), _tone(2093, 2093, 0.04, "tri", 0.3),
			_tone(2637, 2637, 0.04, "tri", 0.3), _tone(3136, 3136, 0.04, "tri", 0.28), _tone(4186, 4186, 0.22, "tri", 0.24, 0.5, 0.002)]),
			_cat([_silence(0.1), _tone(9000, 6000, 0.25, "noise", 0.05, 0.5, 0.05)]))
	# Ráfaga de viento en el patio: un soplido suave que crece y se va
	s["viento"] = _mix(_tone(900, 400, 1.8, "noise", 0.05, 0.5, 0.7), _tone(1800, 700, 1.6, "noise", 0.025, 0.5, 0.9))
	s["win"] = _cat([_tone(784, 784, 0.11, "sq", 0.24, 0.25), _tone(784, 784, 0.11, "sq", 0.24, 0.25),
			_tone(784, 784, 0.11, "sq", 0.24, 0.25), _tone(1047, 1047, 0.45, "sq", 0.24, 0.25),
			_tone(932, 932, 0.22, "sq", 0.24, 0.25), _tone(1047, 1047, 0.6, "sq", 0.24, 0.25)])
	s["lose"] = _cat([_tone(523, 523, 0.2, "tri", 0.45), _tone(494, 494, 0.2, "tri", 0.45),
			_tone(466, 466, 0.2, "tri", 0.45), _tone(440, 300, 0.7, "tri", 0.45)])
	for k in s:
		_sfx[k] = _wav(_soften(s[k], 0.45))


# ===========================================================================
# Música de relleno (melodías originales y simples; reemplazala con musica/*.ogg)
# ===========================================================================

func _chord(root: int, minor: bool) -> Array:
	return [root, root + (3 if minor else 4), root + 7]


func _build_music(name: String) -> AudioStreamWAV:
	var bpm := 112.0 if name == "title" else 140.0
	var step := 60.0 / bpm / 2.0            # corcheas
	var prog: Array
	if name == "title":
		prog = [[60, false], [57, true], [53, false], [55, false], [60, false], [57, true], [62, true], [55, false]]
	else:
		prog = [[57, true], [53, false], [55, false], [52, false], [57, true], [53, false], [50, true], [52, false]]
	var steps_per_chord := 8
	var total := prog.size() * steps_per_chord
	var step_len := int(step * MUSIC_RATE)
	var out := PackedFloat32Array()
	out.resize(total * step_len)
	# Patrones de melodía: índices sobre las notas del acorde (-1 = silencio).
	var pats := {
		"title": [[2, -1, 1, 0, 1, -1, 2, 4], [3, -1, 2, -1, 1, 2, 0, -1]],
		"battle": [[0, -1, 2, 0, 4, 2, 3, 2], [5, 4, 2, -1, 2, 4, 5, -1]],
	}
	for c in prog.size():
		var notes := _chord(prog[c][0], prog[c][1])
		var scale := [notes[0], notes[1], notes[2], notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[0] + 24]
		var pat: Array = pats[name][c % 2]
		for st in steps_per_chord:
			var base := (c * steps_per_chord + st) * step_len
			var idx: int = pat[st]
			if idx >= 0:
				var midi: int = scale[mini(idx, scale.size() - 1)] + 12
				_add(out, base, _tone(_hz(midi), _hz(midi), step * (1.7 if name == "title" else 0.95),
						"sq", 0.13, 0.25, 0.006, MUSIC_RATE))
			if name == "title":
				if st % 2 == 0:
					var bm: int = notes[0] - 12 if st % 4 == 0 else notes[2] - 12
					_add(out, base, _tone(_hz(bm), _hz(bm), step * 1.9, "tri", 0.3, 0.5, 0.006, MUSIC_RATE))
			else:
				var bm2: int = notes[0] - 12 if st % 2 == 0 else notes[0]
				_add(out, base, _tone(_hz(bm2), _hz(bm2), step * 0.9, "tri", 0.3, 0.5, 0.006, MUSIC_RATE))
				if st % 4 == 0:
					_add(out, base, _tone(180, 55, 0.08, "tri", 0.4, 0.5, 0.001, MUSIC_RATE))          # bombo
				elif st % 4 == 2:
					_add(out, base, _tone(2500, 2500, 0.06, "noise", 0.09, 0.5, 0.001, MUSIC_RATE))     # caja
				_add(out, base, _tone(8000, 8000, 0.015, "noise", 0.03, 0.5, 0.001, MUSIC_RATE))        # platillo
	return _wav(_soften(out, 0.5), MUSIC_RATE, true)


func _add(out: PackedFloat32Array, at: int, s: PackedFloat32Array) -> void:
	var n := out.size()
	for i in s.size():
		var j := (at + i) % n            # lo que se pasa del final vuelve al principio (bucle sin cortes)
		out[j] += s[i]
