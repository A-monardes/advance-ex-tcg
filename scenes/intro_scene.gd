extends RefCounted
## Introducción de una partida nueva: el Profesor Birch, al estilo de Rubí y Zafiro.
## El guion está en data/intro.json (pasos: dice, birch, pokemon, pausa, nombre, mazo, fin).
## La campaña (scenes/campaign.gd) la abre en la pantalla "intro" y le pasa teclas y tiempo;
## para el nombre y el mazo usa sus propias pantallas y después vuelve acá (resume()).

const MiniBattle := preload("res://scenes/mini_battle.gd")
const TYPE_SPEED := 45.0          # letras por segundo, como en los diálogos del mapa
const FADE := 0.6
const BIRCH_PATH := "res://mundo/propios/intro/birch.png"   # tira de cuadros (tools/armar_birch.py)
const BIRCH_JSON := "res://mundo/propios/intro/birch.json"
const BALL_HOLD := 0.5            # Birch muestra la Poké Ball antes de abrirla
const OUT_FRAME := 0.06           # segundos por cuadro mientras sale el Pokémon
const BACK_FRAME := 0.025         # ...y mientras vuelve (al revés, más rápido)
const CARD_SCALE := 1.15
const CARD_FLIP := 0.45           # la carta aparece dada vuelta y gira hasta mostrar la cara

var d                             # la pantalla de duelo (ayudantes de dibujo)
var camp                          # la campaña
var steps: Array = []
var i := -1
var t := 0.0                      # tiempo total (para animaciones)
var step_t := 0.0                 # tiempo dentro del paso actual
var waiting := ""                 # "dialog", "pause", "external" o "" (listo para el siguiente)
var who := "Prof. Birch"
var pages: Array = []
var page := 0
var typed := 0.0
var birch_on := false
var birch_k := 0.0                # 0 = no está, 1 = está (para entrar y salir suave)
var mon := ""                     # el Pokémon que está afuera
var mon_t := -1.0                 # desde cuándo está afuera (o volviendo, si mon_back)
var mon_back := false
var fade_in := 0.0
var fade_out := -1.0
var _birch_tex: Texture2D
var _tried_birch := false
var _cell := Vector2(109, 85)     # tamaño de cada cuadro de la tira
var _feet := 84.0                 # fila de los pies dentro del cuadro
var _frames := 1
var card := ""                    # carta que Birch está mostrando ("" = ninguna)
var card_t := -9.0
var card_out := false             # la carta se está yendo
var b_anim := ""                  # "" (quieto), "sale" o "vuelve"
var b_t0 := 0.0


func _init(duel, campaign) -> void:
	d = duel
	camp = campaign


func start() -> void:
	var data: Dictionary = {}
	var txt := FileAccess.get_file_as_string("res://data/intro.json")
	var parsed = JSON.parse_string(txt)
	if parsed is Dictionary:
		data = parsed
	steps = data.get("pasos", [])
	i = -1
	t = 0.0
	waiting = ""
	who = "Prof. Birch"
	birch_on = false
	birch_k = 0.0
	mon = ""
	mon_t = -1.0
	fade_in = 0.0
	fade_out = -1.0
	_next()


## La campaña vuelve acá después de la pantalla de nombre o de mazo.
func resume() -> void:
	waiting = ""
	_next()


func _next() -> void:
	while true:
		i += 1
		step_t = 0.0
		if i >= steps.size():
			_finish()
			return
		var s: Dictionary = steps[i]
		if s.has("quien"):
			who = str(s["quien"])
		if s.has("birch"):
			birch_on = str(s["birch"]) == "entra"
			if birch_on:
				d.snd.play("move")
		if s.has("pokemon"):
			if str(s.get("accion", "sale")) == "sale":
				mon = str(s["pokemon"])
				mon_t = t
				mon_back = false
				b_anim = "sale"
				b_t0 = t
				d.snd.play("evolve")
			else:
				mon_back = true
				mon_t = t
				b_anim = "vuelve"
				b_t0 = t
				d.snd.play("back")
		if s.has("carta"):
			var cid := str(s["carta"])
			if cid != "":
				card = cid
				card_out = false
				d.snd.play("draw")
			else:
				card_out = true
				d.snd.play("back")
			card_t = t
		if s.has("dice"):
			pages = s["dice"].map(func(x): return camp.fmt(str(x)))
			page = 0
			typed = 0.0
			waiting = "dialog"
			return
		if s.has("pausa") or s.has("pokemon") or s.has("birch") or s.has("carta"):
			waiting = "pause"
			return
		if s.has("nombre"):
			waiting = "external"
			camp.open_name_from_intro()
			return
		if s.has("mazo"):
			waiting = "external"
			camp.open_starter_from_intro()
			return
		if s.has("fin"):
			_finish()
			return


func _step_pause() -> float:
	var s: Dictionary = steps[i]
	if s.has("pausa"):
		return float(s["pausa"])
	if s.has("pokemon"):
		if _birch() != null and _frames > 2:
			if str(s.get("accion", "sale")) == "sale":
				return BALL_HOLD + (_frames - 2) * OUT_FRAME + 0.3
			return (_frames - 1) * BACK_FRAME + 0.2
		return 0.9 if str(s.get("accion", "sale")) == "sale" else 0.5
	if s.has("carta"):
		return CARD_FLIP + 0.15
	return 0.35                       # Birch entrando o saliendo


func _finish() -> void:
	if fade_out < 0.0:
		fade_out = 0.0
		waiting = "end"


func update(delta: float) -> void:
	t += delta
	step_t += delta
	fade_in = minf(1.0, fade_in + delta / FADE)
	birch_k = move_toward(birch_k, 1.0 if birch_on else 0.0, delta / 0.35)
	if card_out and card != "" and t - card_t > CARD_FLIP:
		card = ""
	if mon_back and mon != "" and t - mon_t > (_frames - 1) * BACK_FRAME + 0.05:
		mon = ""
	match waiting:
		"dialog":
			var txt: String = pages[page]
			if typed < txt.length():
				var before := int(typed)
				typed = minf(typed + delta * TYPE_SPEED, txt.length())
				var now := int(typed)
				if now != before and now % 2 == 0 and txt.substr(now - 1, 1) != " ":
					d.snd.play("blip")
		"pause":
			if step_t >= _step_pause():
				waiting = ""
				_next()
		"end":
			fade_out += delta
			if fade_out >= FADE:
				waiting = "done"
				camp.intro_done()


func input(event: InputEventKey) -> void:
	var k := event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_X] and not event.echo
	if not accept or waiting != "dialog":
		return
	var txt: String = pages[page]
	if typed < txt.length():
		typed = txt.length()              # Z completa la página
		return
	d.snd.play("ok")
	page += 1
	typed = 0.0
	if page >= pages.size():
		waiting = ""
		_next()


# ===========================================================================
# Dibujo
# ===========================================================================

func draw() -> void:
	var W: float = d.W
	var H: float = d.H
	# Fondo: degradé oscuro con una luz suave donde está Birch, como en Rubí y Zafiro
	for y in int(H):
		var k := float(y) / H
		d.draw_rect(Rect2(0, y, W, 1), Color(0.05 + 0.06 * k, 0.07 + 0.1 * k, 0.16 + 0.12 * k))
	var stage := Vector2(W / 2.0, 92)
	for r in [70, 52, 36]:
		d.draw_set_transform(d._base_off + stage, 0, Vector2(1.0, 0.28))
		d.draw_circle(Vector2.ZERO, r, Color(0.55, 0.75, 1.0, 0.06))
		d.draw_set_transform(d._base_off)
	d.draw_set_transform(d._base_off + stage, 0, Vector2(1.0, 0.25))
	d.draw_circle(Vector2.ZERO, 40, Color(0.75, 0.9, 1.0, 0.18))
	d.draw_set_transform(d._base_off)
	# Birch
	var tex := _birch()
	if tex != null and birch_k > 0.0:
		# la tira trae a Birch y al Pokémon juntos (Birch a la derecha, mirando a la izquierda)
		var fr := _birch_frame()
		var pos := Vector2(roundf(stage.x - _cell.x / 2.0), roundf(stage.y + 4 - _feet + (1.0 - birch_k) * 6.0))
		d.draw_texture_rect_region(tex, Rect2(pos, _cell), Rect2(fr * _cell.x, 0, _cell.x, _cell.y), Color(1, 1, 1, birch_k))
	elif mon != "":
		_draw_mon(Vector2(stage.x, stage.y + 2))      # sin la tira de Birch: el sprite de PMD
	# La carta que muestra Birch, donde estaba el Pokémon
	if card != "":
		_draw_card(Vector2(stage.x - 36, 56))
	# Cuadro de texto
	if waiting == "dialog":
		_draw_dialog()
	# Fundidos de entrada y salida
	var black := 1.0 - fade_in
	if fade_out >= 0.0:
		black = maxf(black, clampf(fade_out / FADE, 0.0, 1.0))
	if black > 0.0:
		d.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, black))


func _birch() -> Texture2D:
	if not _tried_birch:
		_tried_birch = true
		var img: Image = ImgLoad.load(BIRCH_PATH) if ImgLoad.exists(BIRCH_PATH) else null
		if img != null:
			_birch_tex = ImageTexture.create_from_image(img)
			_cell = Vector2(img.get_width(), img.get_height())
			_feet = _cell.y - 1
			var info = JSON.parse_string(FileAccess.get_file_as_string(BIRCH_JSON)) if ImgLoad.exists(BIRCH_JSON) else null
			if info is Dictionary and info.has("celda"):
				_cell = Vector2(info["celda"][0], info["celda"][1])
				_feet = float(info.get("pies", _cell.y - 1))
			_frames = maxi(1, int(img.get_width() / _cell.x))
	return _birch_tex


## Qué cuadro de la tira va: 0 parado, 1 con la Poké Ball, 2.. sale el Pokémon (el último: ya afuera).
func _birch_frame() -> int:
	if _frames <= 2:
		return 0
	var age := t - b_t0
	match b_anim:
		"sale":
			if age < BALL_HOLD:
				return 1
			return mini(_frames - 1, 2 + int((age - BALL_HOLD) / OUT_FRAME))
		"vuelve":
			return maxi(0, _frames - 1 - int(age / BACK_FRAME))
	return 0


## La carta aparece de dorso desde abajo, gira y muestra la cara; al irse hace lo mismo al revés.
func _draw_card(center: Vector2) -> void:
	var k := clampf((t - card_t) / CARD_FLIP, 0.0, 1.0)
	if card_out:
		k = 1.0 - k
	var e := k * k * (3.0 - 2.0 * k)
	var pos := center + Vector2(0, (1.0 - e) * 30.0 + sin(t * 2.2) * 1.0 * e)
	var a := clampf(k * 2.5, 0.0, 1.0)
	var flip := cos(e * PI)                      # 1 dorso de frente, 0 de canto, -1 cara de frente
	var face := flip < 0.0
	var sx := maxf(absf(flip), 0.04)
	# brillo detrás cuando ya muestra la cara
	if face:
		d._draw_burst(pos, 30.0 + sin(t * 3.0) * 2.0, Color(1, 1, 0.8, 0.18 * -flip), 12)
	d.draw_set_transform(d._base_off + pos, 0, Vector2(sx, 1.0))
	if face:
		d._draw_trainer_card(Vector2.ZERO, CARD_SCALE, card, a)
	else:
		d._draw_card_back(Rect2(Vector2(-24, -32) * CARD_SCALE, Vector2(48, 64) * CARD_SCALE), a)
	d.draw_set_transform(d._base_off)


func _draw_mon(ground: Vector2) -> void:
	var sp := mon
	if not MiniBattle.has_anim(sp, "Idle"):
		return
	var age := t - mon_t
	var k := clampf(age / 0.35, 0.0, 1.0)
	if mon_back:
		k = 1.0 - clampf(age / 0.4, 0.0, 1.0)
	if k <= 0.0:
		return
	# Sale con un destello blanco que se abre (o se cierra al volver)
	if (not mon_back and age < 0.45) or mon_back:
		var fl := 1.0 - k if not mon_back else k
		d._draw_burst(ground + Vector2(0, -12), 6.0 + 22.0 * (1.0 - fl), Color(1, 1, 1, 0.8 * fl), 10)
	var an := MiniBattle._anim(sp, "Idle")
	var fr := MiniBattle._frame_at(an, t / MiniBattle.TICK, true) if not an.is_empty() else 0
	var sc := 2.0 * k
	d.draw_set_transform(d._base_off + ground.round(), 0, Vector2(sc, sc))
	MiniBattle._put(d, sp, "Idle", 0, fr, Vector2.ZERO, k)
	d.draw_set_transform(d._base_off)


func _draw_dialog() -> void:
	var box := Rect2(0, 112, d.W, 48)
	d._frame(box)
	if who != "":
		var tag := Rect2(4, 94, d._text_w(who) + 16, 21)
		d._frame(tag)
		d._text(tag.position + Vector2(8, 5), who, Color("#c03028"))
	var txt: String = pages[page]
	var shown := txt.substr(0, int(typed))
	var lines: Array = d._wrap(txt, box.size.x - 20)
	var used := 0
	for li in mini(3, lines.size()):
		var ln: String = lines[li]
		d._text(Vector2(9, box.position.y + 5 + li * 13), shown.substr(used, ln.length()), d.C_TEXT)
		used += ln.length() + 1
	if typed >= txt.length():
		var bob := 1.0 if int(t * 3.3) % 2 == 0 else 0.0
		d._text(Vector2(box.end.x - 15, box.end.y - 15 + bob), "▼", Color("#e03828"))
