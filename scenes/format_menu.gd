extends RefCounted
## Pantalla para elegir el formato. La dibuja y le pasa las teclas la pantalla de duelo
## (duel.gd), que tiene los ayudantes de texto.
##
##   Official: el formato del Mundial de cada temporada (cerrado: el que va a servir para
##             un ladder en línea).
##   Custom:   un momento de la temporada: el principio (1 de septiembre) más los sets que
##             fueron saliendo durante el año, en el orden en que salieron.
##
## Lo elegido queda en d.season_idx y d.format_upto (-1 = Mundial).

var d                    # la pantalla de duelo (duel.gd)
var back_view := ""      # a qué pantalla del título vuelve ("duel" u "online")
var tab := 0             # 0 Official · 1 Custom
var row := 0             # Official: qué Mundial · Custom: 0 = temporada, 1.. = momentos
var c_season := 0        # temporada que se está mirando en Custom

const TABS := ["Official", "Custom"]
const C_WORLDS := Color("#b87810")
const C_ON := Color("#388850")
## Logos de los Mundiales (los pone el jugador): mundo/propios/mundiales/2004.png, 2005.png...
const LOGO_DIR := "res://mundo/propios/mundiales"
var _logos := {}


func _init(duel) -> void:
	d = duel


func open(from_view: String) -> void:
	back_view = from_view
	tab = 1 if d.format_upto >= 0 else 0
	c_season = d.season_idx
	row = d.season_idx if tab == 0 else d.format_upto + 1
	_list_t0 = Time.get_ticks_msec()
	d.title_view = "format"


func _steps(i: int) -> Array:
	return RuleSet.SEASONS[i].get("steps", [])


func input(k: int, accept: bool, back: bool) -> void:
	var n_seasons := RuleSet.SEASONS.size()
	if back:
		d.title_view = back_view
		d.snd.play("back")
		return
	if k == KEY_TAB:
		tab = 1 - tab
		row = d.season_idx if tab == 0 else 0
		d.snd.play("move")
		return
	if tab == 0:
		match k:
			KEY_UP, KEY_LEFT: row = (row + n_seasons - 1) % n_seasons
			KEY_DOWN, KEY_RIGHT: row = (row + 1) % n_seasons
		if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			d.snd.play("move")
			_list_t0 = Time.get_ticks_msec()
		if accept:
			_choose(row, -1)
		return
	var n_rows := _steps(c_season).size() + 2     # temporada, principio y cada set
	match k:
		KEY_UP: row = (row + n_rows - 1) % n_rows
		KEY_DOWN: row = (row + 1) % n_rows
		KEY_LEFT, KEY_RIGHT:
			# ◀▶ cambian la temporada desde cualquier renglón (de pestaña se cambia solo con Tab)
			c_season = (c_season + (1 if k == KEY_RIGHT else -1) + n_seasons) % n_seasons
			row = mini(row, _steps(c_season).size() + 1)
	if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		d.snd.play("move")
	if accept and row > 0:
		var n := row - 1
		_choose(c_season, -1 if n >= _steps(c_season).size() else n)


## Elige el formato y queda marcado; la pantalla sigue abierta (X vuelve).
func _choose(season: int, upto: int) -> void:
	d.season_idx = season
	d.format_upto = upto
	d._save_settings()
	d.snd.play("ok")


func draw() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), d.C_BG)
	# Encabezado
	d._frame(Rect2(0, 0, d.W, 22))
	d._text(Vector2(9, 5), "FORMAT", d.C_TEXT)
	var right := "Fixed · for ranked play" if tab == 0 else "Free · for fun"
	d._text(Vector2(d.W - 9 - d._text_w(right), 5), right, d.C_DIM)
	var x := 2.0
	for i in TABS.size():
		var w: float = d._text_w(TABS[i]) + 10
		var r := Rect2(x, 21, w, 13)
		d.draw_rect(r, d.C_FRAME_OUT)
		d.draw_rect(r.grow(-1), d.C_PANEL if i == tab else d.C_FRAME_MID)
		d._text(Vector2(x + 5, 22), TABS[i], d.C_TEXT if i == tab else d.C_LIGHT)
		x += w + 1
	if tab == 0:
		_draw_official()
	else:
		_draw_custom()


func _logo(year: String) -> Texture2D:
	if not _logos.has(year):
		var tex: Texture2D = null
		for ext in ["png", "webp", "jpg"]:
			var p := "%s/%s.%s" % [LOGO_DIR, year, ext]
			if ImgLoad.exists(p):
				# Se achica una vez, con buen filtro, al tamaño en que se dibuja
				var img := ImgLoad.load(p)
				var sc := minf(108.0 / img.get_width(), 64.0 / img.get_height())
				if sc < 1.0:
					img.resize(maxi(1, roundi(img.get_width() * sc)), maxi(1, roundi(img.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
				tex = ImageTexture.create_from_image(img)
				break
		_logos[year] = tex
	return _logos[year]


var _list_t0 := 0


func _draw_official() -> void:
	var left := Rect2(0, 33, 120, 86)
	d._frame(left)
	d._frame(Rect2(118, 33, d.W - 118, 86))
	var s: Dictionary = RuleSet.SEASONS[row]
	# Arriba: ◀ Worlds 2005 ▶ (con ✓ si es el elegido)
	d.draw_rect(Rect2(4, 37, 112, 12), Color("#d8e4f8"))
	d._text(Vector2(6, 38), "◀", d.C_TEXT)
	d._text(Vector2(108, 38), "▶", d.C_TEXT)
	var title := str(s["worlds"])
	d._text(Vector2(60 - d._text_w(title) / 2.0, 38), title, C_WORLDS)
	if row == d.season_idx and d.format_upto < 0:
		_check(Vector2(95, 39))
	# El logo de ese Mundial (si el jugador lo puso); si no, el lugar
	var year := str(title).right(4)
	var logo := _logo(year)
	var box := Rect2(6, 51, 108, 64)
	if logo != null:
		var sc := minf(box.size.x / logo.get_width(), box.size.y / logo.get_height())
		var sz := Vector2(logo.get_width(), logo.get_height()) * sc
		d.draw_texture_rect(logo, Rect2(box.position + (box.size - sz) / 2.0, sz), false)
	else:
		var where := str(s["where"]).split(" · ")
		d._text(Vector2(60 - d._text_w(where[0]) / 2.0, 70), where[0], d.C_DIM)
		d._text(Vector2(60 - d._text_w(where[1]) / 2.0, 82), where[1], d.C_DIM)
	# Derecha: todos los sets (y los POP); si no entran, la lista sube sola y vuelve
	var sets: Array = s["sets"].filter(func(c): return c != "np")
	var n_sets: int = sets.filter(func(c): return not str(c).begins_with("pop")).size()
	var pops: int = sets.size() - n_sets
	d._text(Vector2(123, 37), ("%d sets + %d POP + promos" % [n_sets, pops]) if pops > 0 else "%d sets + promos" % n_sets, d.C_DIM)
	var vis := 7
	var extra := maxi(0, sets.size() - vis)
	var off := 0
	if extra > 0:
		# quieto 2 s arriba, baja un renglón cada 0.7 s, quieto 2 s abajo, y vuelve
		var t := (Time.get_ticks_msec() - _list_t0) / 1000.0
		var cycle := 4.0 + extra * 0.7 * 2.0
		var u := fmod(t, cycle)
		if u < 2.0:
			off = 0
		elif u < 2.0 + extra * 0.7:
			off = int((u - 2.0) / 0.7) + 1
		elif u < 4.0 + extra * 0.7:
			off = extra
		else:
			off = extra - int((u - 4.0 - extra * 0.7) / 0.7) - 1
		off = clampi(off, 0, extra)
	for j in mini(vis, sets.size()):
		var c: String = sets[j + off]
		var nm := RuleSet.set_title(c).replace("EX ", "")
		d._text_fit(Vector2(125, 47 + j * 9), nm, d.C_DIM if c.begins_with("pop") else d.C_TEXT, d.W - (142 if extra > 0 else 132))
	if extra > 0:
		if off > 0:
			d._text(Vector2(d.W - 14, 45), "▲", d.C_DIM)
		if off < extra:
			d._text(Vector2(d.W - 14, 103), "▼", d.C_DIM)
	d._frame(Rect2(0, 117, d.W, 43))
	d._text_fit(Vector2(9, 121), "%s · %s" % [s["worlds"], s["where"]], d.C_TEXT, 222)
	d._text_fit(Vector2(9, 132), "Season %s: %s." % [s["id"], str(s["name"]).split(" · ")[1]], d.C_DIM, 222)
	d._text_fit(Vector2(9, 143), "◀▶ choose · Z select · Tab custom · X back", d.C_DIM, 222)


## Tilde de "elegido" dibujada (la fuente no tiene ✓).
func _check(p: Vector2) -> void:
	for o in [Vector2(0, 1), Vector2(1, 0)]:
		d.draw_line(p + Vector2(1, 4) + o, p + Vector2(3, 6) + o, d.C_FRAME_OUT, 2.0)
		d.draw_line(p + Vector2(3, 6) + o, p + Vector2(8, 1) + o, d.C_FRAME_OUT, 2.0)
	d.draw_line(p + Vector2(1, 4), p + Vector2(3, 6), C_ON, 2.0)
	d.draw_line(p + Vector2(3, 6), p + Vector2(8, 1), C_ON, 2.0)


func _draw_custom() -> void:
	d._frame(Rect2(0, 33, d.W, 86))
	var s: Dictionary = RuleSet.SEASONS[c_season]
	var steps := _steps(c_season)
	var mine: bool = c_season == d.season_idx       # la temporada del formato elegido
	var chosen: int = (d.format_upto if d.format_upto >= 0 else steps.size()) if mine else -1
	var y := 38.0
	if row == 0:
		d.draw_rect(Rect2(4, y - 1, d.W - 8, 11), Color("#d8e4f8"))
	d._text(Vector2(9, y), "Season", d.C_TEXT)
	d._text(Vector2(62, y), "◀ %s ▶" % s["id"], Color("#3868c8"))
	# Línea de tiempo: principio de temporada y un renglón por set que salió en el año
	var y0 := 50.0
	var lh := 10.0 if steps.size() >= 4 else 11.0
	d.draw_rect(Rect2(13, y0 + 5, 1, lh * steps.size()), d.C_DIM)
	for j in steps.size() + 1:
		var yy := y0 + j * lh
		var on := chosen >= j
		d._stripe(Rect2(4, yy - 1, d.W - 8, lh), j + 1)
		if row == j + 1:
			d.draw_rect(Rect2(4, yy - 1, d.W - 8, lh), Color("#d8e4f8"))
		d.draw_rect(Rect2(11, yy + 2, 5, 5), C_ON if on else d.C_DIM)
		if not on:
			d.draw_rect(Rect2(12, yy + 3, 3, 3), d.C_PANEL)
		var label := ""
		var when := ""
		if j == 0:
			var st: Array = s["start"].filter(func(c): return not str(c).begins_with("pop") and c != "np")
			label = "Start: %s ... %s" % [RuleSet.set_title(st[0]).replace("EX ", ""), RuleSet.set_title(st[-1]).replace("EX ", "")]
			when = "Sep %s" % str(s["id"]).left(4)
		else:
			label = "+ " + RuleSet.set_title(steps[j - 1][0]).replace("EX ", "")
			when = steps[j - 1][1]
		d._text_fit(Vector2(20, yy), label, d.C_TEXT if on else d.C_DIM, d.W - 80)
		d._text(Vector2(d.W - 9 - d._text_w(when), yy), when, d.C_DIM)
	var yw := y0 + (steps.size() + 1) * lh + 1
	d._text(Vector2(20, yw), "= %s card pool" % s["worlds"], C_WORLDS)
	d._frame(Rect2(0, 117, d.W, 43))
	var r := RuleSet.from_point(c_season, maxi(0, row - 1) if row > 0 else (chosen if chosen >= 0 else 0))
	var top := r.name if not (row > 0 and row - 1 >= steps.size()) else "%s (same cards)" % s["worlds"]
	d._text_fit(Vector2(9, 121), top, d.C_TEXT, 222)
	d._text_fit(Vector2(9, 132), "Sets join in the order they came out.", d.C_DIM, 222)
	d._text_fit(Vector2(9, 143), "▲▼◀▶ move · Z select · Tab official · X back", d.C_DIM, 222)
