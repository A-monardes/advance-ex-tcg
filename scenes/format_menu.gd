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


func _init(duel) -> void:
	d = duel


func open(from_view: String) -> void:
	back_view = from_view
	tab = 1 if d.format_upto >= 0 else 0
	c_season = d.season_idx
	row = d.season_idx if tab == 0 else d.format_upto + 1
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
			KEY_UP: row = (row + n_seasons - 1) % n_seasons
			KEY_DOWN: row = (row + 1) % n_seasons
			KEY_LEFT, KEY_RIGHT:
				tab = 1
				row = 0
				c_season = d.season_idx
		if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			d.snd.play("move")
		if accept:
			_choose(row, -1)
		return
	var n_rows := _steps(c_season).size() + 2     # temporada, principio y cada set
	match k:
		KEY_UP: row = (row + n_rows - 1) % n_rows
		KEY_DOWN: row = (row + 1) % n_rows
		KEY_LEFT, KEY_RIGHT:
			if row == 0:
				c_season = (c_season + (1 if k == KEY_RIGHT else -1) + n_seasons) % n_seasons
			else:
				tab = 0
				row = d.season_idx
	if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		d.snd.play("move")
	if accept and row > 0:
		var n := row - 1
		_choose(c_season, -1 if n >= _steps(c_season).size() else n)


## Elige el formato y vuelve.
func _choose(season: int, upto: int) -> void:
	d.season_idx = season
	d.format_upto = upto
	d._save_settings()
	d.snd.play("ok")
	d.title_view = back_view


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


func _draw_official() -> void:
	d._frame(Rect2(0, 33, 120, 86))
	d._frame(Rect2(118, 33, d.W - 118, 86))
	for i in RuleSet.SEASONS.size():
		var s: Dictionary = RuleSet.SEASONS[i]
		var y := 38 + i * 12
		if i == row:
			d.draw_rect(Rect2(4, y - 1, 112, 11), Color("#d8e4f8"))
			d._text(Vector2(6, y), "▶", d.C_TEXT)
		d._text(Vector2(15, y), str(s["worlds"]), C_WORLDS)
		if i == d.season_idx and d.format_upto < 0:
			d._text(Vector2(104, y), "✓", C_ON)
	var s: Dictionary = RuleSet.SEASONS[row]
	var sets: Array = s["sets"].filter(func(c): return not str(c).begins_with("pop") and c != "np")
	var pops: int = s["sets"].filter(func(c): return str(c).begins_with("pop")).size()
	d._text(Vector2(123, 37), "%d sets + %s promos" % [sets.size(), ("%d POP +" % pops) if pops > 0 else ""], d.C_DIM)
	for j in mini(6, sets.size()):
		d._text_fit(Vector2(125, 48 + j * 9), RuleSet.set_title(sets[j]).replace("EX ", ""), d.C_TEXT, d.W - 132)
	if sets.size() > 6:
		d._text(Vector2(125, 48 + 6 * 9), "+%d more" % (sets.size() - 6), d.C_DIM)
	d._frame(Rect2(0, 117, d.W, 43))
	d._text_fit(Vector2(9, 121), "%s · %s" % [s["worlds"], s["where"]], d.C_TEXT, 222)
	d._text_fit(Vector2(9, 132), "Season %s: %s." % [s["id"], str(s["name"]).split(" · ")[1]], d.C_DIM, 222)
	d._text_fit(Vector2(9, 143), "▲▼ choose · Z use · Tab custom · X back", d.C_DIM, 222)


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
	d._text_fit(Vector2(9, 143), "▲▼ move · ◀▶ season · Z up to here · X back", d.C_DIM, 222)
