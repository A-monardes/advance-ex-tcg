extends RefCounted
## Pantalla de título, menú principal y armado del duelo libre
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


func _title_input(k: int, accept: bool) -> void:
	var n: int = d.deck_names().size()
	d.my_deck = clampi(d.my_deck, 0, n - 1)
	d.opp_deck = clampi(d.opp_deck, 0, n - 1)
	d.title_msg = ""
	if d.title_view == "options":
		# Opciones: Animación, Efectos, Música y Mesa (las mismas de la pausa)
		match k:
			KEY_UP, KEY_DOWN:
				d.opt_cursor = (d.opt_cursor + (1 if k == KEY_DOWN else 6)) % 7
				d.snd.play("move")
			KEY_LEFT, KEY_RIGHT:
				if d.opt_cursor < 5:
					d.paneles._pause_change(d.opt_cursor + 1, 1 if k == KEY_RIGHT else -1)
					d.snd.play("ok")
				elif d.opt_cursor == 5:
					_toggle_border()
			KEY_X, KEY_ESCAPE, KEY_BACKSPACE:
				d.title_view = ""
				d.snd.play("back")
		if accept:
			if d.opt_cursor == 6:         # Card art: bajar el arte de todas las cartas
				d.arte.download_all()
			elif d.opt_cursor == 5:
				_toggle_border()
				return
			else:
				d.paneles._pause_change(d.opt_cursor + 1, 1)
			d.snd.play("ok")
		return
	if d.title_view == "duel":
		_duel_setup_input(k, accept, n)
		return
	if d.title_view == "online":
		return       # la maneja online.input (necesita el evento entero para escribir)
	match k:
		KEY_UP:
			d.title_row = (d.title_row + d.TITLE_ROWS - 1) % d.TITLE_ROWS
			d.snd.play("move")
		KEY_DOWN:
			d.title_row = (d.title_row + 1) % d.TITLE_ROWS
			d.snd.play("move")
	if not accept:
		return
	match d.title_row:
		0:
			if not d.CAMPAIGN_ON:
				d.snd.play("error")
				return
			d.snd.play("ok")
			d._go(func():
				d.mode = "campaign"
				d.campaign.open())
		1:
			d.snd.play("ok")
			d.title_view = "options"
			d.opt_cursor = 0
		2:
			d.snd.play("ok")
			d._go(func():
				d.mode = "editor"
				d.editor.open())
		3:
			d.snd.play("ok")
			d.title_view = "duel"
			d.free_cell = 5                   # el cursor arranca en "Start duel!"
			d.free_popup = ""
		4:
			d.snd.play("ok")
			d.title_view = "online"
			d.online.open()


## Armado del duelo libre: una grilla de casillas (mazo propio, rival, dificultad, formato,
## tipo de batalla y empezar). Z abre la ventana de cada una; X cierra la ventana o vuelve.
##   casillas: 0 tu mazo · 1 rival · 2 dificultad · 3 formato · 4 batalla · 5 empezar
const FREE_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const FD_LIST_ROWS := 6     # renglones de la lista de mazos (abajo va la descripción entera)

func _duel_setup_input(k: int, accept: bool, n: int) -> void:
	if d.free_popup != "":
		_free_popup_input(k, accept, n)
		return
	if k in FREE_KEYS:
		var to: int = d.FREE_MOVES[d.free_cell][FREE_KEYS.find(k)]
		if to != d.free_cell:
			d.free_cell = to
			d.snd.play("move")
		return
	if k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE]:
		d.title_view = ""
		d.snd.play("back")
		return
	if not accept:
		return
	match d.free_cell:
		0, 1:
			d.free_popup = "deck_me" if d.free_cell == 0 else "deck_opp"
			d.popup_cursor = d.my_deck if d.free_cell == 0 else d.opp_deck
			d.popup_scroll = clampi(d.popup_cursor - FD_LIST_ROWS / 2, 0, maxi(0, n - FD_LIST_ROWS))
			d.snd.play("ok")
		2:
			d.free_popup = "diff"
			d.popup_cursor = d.ai_level - 1
			d.snd.play("ok")
		3:
			d.snd.play("ok")
			d.fmt_menu.open("duel")
		4:
			d.free_popup = "battle"
			d.popup_cursor = 1 if d.doubles_mode else 0
			d.snd.play("ok")
		5:
			_free_start()


func _free_popup_input(k: int, accept: bool, n: int) -> void:
	if k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE]:
		d.free_popup = ""
		d.snd.play("back")
		return
	match d.free_popup:
		"deck_me", "deck_opp":
			if k == KEY_UP or k == KEY_DOWN:
				d.popup_cursor = (d.popup_cursor + (1 if k == KEY_DOWN else -1) + n) % n
				d.popup_scroll = clampi(d.popup_scroll, d.popup_cursor - FD_LIST_ROWS + 1, d.popup_cursor)
				d.snd.play("move")
			if accept:
				if d.free_popup == "deck_me":
					d.my_deck = d.popup_cursor
				else:
					d.opp_deck = d.popup_cursor
				d.free_popup = ""
				d.snd.play("ok")
		"diff":
			if k == KEY_UP or k == KEY_DOWN:
				d.popup_cursor = (d.popup_cursor + (1 if k == KEY_DOWN else -1) + 5) % 5
				d.snd.play("move")
			if accept:
				d.ai_level = d.popup_cursor + 1
				d._save_settings()
				d.free_popup = ""
				d.snd.play("ok")
		"battle":
			if k == KEY_LEFT or k == KEY_RIGHT:
				d.popup_cursor = 1 - d.popup_cursor
				d.snd.play("move")
			if accept:
				d.doubles_mode = d.popup_cursor == 1
				d.free_popup = ""
				d.snd.play("ok")


func _free_start() -> void:
	var names: Array = d.deck_names()
	var fmt_rules = d.format_rules()
	for pair in [[d.my_deck, "Your deck"], [d.opp_deck, "The opponent's deck"]]:
		var errs = Game.validate_deck(Decks.get_deck(names[pair[0]]), fmt_rules)
		if not errs.is_empty():
			d.title_msg = "%s is not valid: %s" % [pair[1], errs[0]]
			d.snd.play("error")
			return
	d.snd.play("ok")
	d.campaign_rival = ""
	d._go(d._start_duel)


## La carta que representa al mazo: su Pokémon más fuerte (ex y Fase 2 primero).
func _deck_cover(deck_name: String) -> String:
	var best := ""
	var best_v := -1.0
	for id in Decks.get_deck(deck_name):
		if not CardDB.is_pokemon(id):
			continue
		var v := (10.0 if CardDB.is_ex(id) else 0.0) + CardDB.stage(id) * 3.0 + CardDB.hp(id) / 100.0
		if v > best_v:
			best_v = v
			best = id
	return best


const C_FD_SEL := Color("#c03028")
const C_FD_ME := Color("#d0dcf4")       # tu mazo / dobles
const C_FD_OPP := Color("#f4d4cc")      # el rival / simples
const C_FD_LINE := Color("#b8c0d0")


func _draw_duel_setup() -> void:
	var names: Array = d.deck_names()
	var r = d.format_rules()
	d.my_deck = clampi(d.my_deck, 0, names.size() - 1)
	d.opp_deck = clampi(d.opp_deck, 0, names.size() - 1)
	# Estilo de la elección de mesa de Pokémon Pinball: rayas verdes, barra de título y cajas
	_pb_bg(PB_GREEN)
	_pb_title(8, "FREE DUEL")
	var x1 := 108.0         # fin de la columna de los mazos
	var x2 := 172.0         # fin de la columna del formato
	var top := 20.0
	var bot := 142.0
	# Izquierda: los dos mazos (nombre, si es legal en el formato y su carta) y la dificultad
	for i in 2:
		var box := Rect2(4, top + i * 44, x1 - 4, 42)
		var inn := _fd_box(box, "YOUR DECK" if i == 0 else "OPPONENT", i)
		d.draw_rect(inn, Color(C_FD_ME if i == 0 else C_FD_OPP, 0.55))     # tu mazo en azul, el rival en rojo
		var nm: String = names[d.my_deck if i == 0 else d.opp_deck]
		d._text_fit(Vector2(inn.position.x + 2, inn.position.y + 1), ("★ " if Decks.is_user(nm) else "") + nm, d.C_TEXT, 62)
		var legal = d._deck_legal(nm, r)
		d.imagenes._draw_tiny(Vector2(inn.position.x + 2, inn.end.y - 7), "LEGAL TO USE" if legal else "NOT LEGAL HERE",
				Color("#388850") if legal else d.C_HP_LOW)
		var cover := _deck_cover(nm)
		var ir := Rect2(inn.end.x - 27, inn.position.y + 1, 26, 26)
		d.draw_rect(ir.grow(1), d.C_INK)
		if cover != "":
			d.imagenes._draw_card_image(ir, cover)
	var dbox := Rect2(4, top + 88, x1 - 4, bot - top - 88)
	var din := _fd_box(dbox, "DIFFICULTY", 2)
	var lv = "%d · %s" % [d.ai_level, SimpleAI.LEVEL_NAMES[d.ai_level - 1]]
	d._text(Vector2(din.get_center().x - d._text_w(lv) / 2.0, din.position.y + 3), lv, d.C_TEXT)
	# Centro: el formato (con el logo del Mundial)
	var fin := _fd_box(Rect2(x1 + 4, top, x2 - x1 - 4, bot - top), "FORMAT", 3)
	var fcx := fin.get_center().x
	var fname: String = str(RuleSet.SEASONS[d.season_idx]["worlds"]).to_upper() if d.format_upto < 0 \
			else "CUSTOM " + str(RuleSet.SEASONS[d.season_idx]["id"])
	d.imagenes._draw_tiny(Vector2(roundf(fcx - fname.length() * 2.0), fin.position.y + 2), fname, d.C_TEXT)
	var year = str(RuleSet.SEASONS[d.season_idx]["worlds"]).right(4)
	var logo: Texture2D = d.fmt_menu._logo(year)
	var lb = Rect2(fin.position.x + 1, fin.position.y + 10, fin.size.x - 2, fin.size.y - 22)
	# Abajo, chiquito: con cuántos sets se juega (los POP aparte; las promos no cuentan)
	var ls: Array = r.legal_sets.filter(func(c): return not str(c).begins_with("np"))
	var n_pop := ls.filter(func(c): return str(c).begins_with("pop")).size()
	var cnt = "%d SETS" % (ls.size() - n_pop) + (" + %d POP" % n_pop if n_pop > 0 else "")
	d.imagenes._draw_tiny(Vector2(roundf(fcx - cnt.length() * 2.0), fin.end.y - 8), cnt, d.C_DIM)
	if d.format_upto >= 0:
		# Custom: del set más viejo (arriba) al último que entra (abajo), con una flecha
		var rng := _fd_set_range()
		var hb = (lb.size.y - 10) / 2.0
		_fd_set_logo(Rect2(lb.position, Vector2(lb.size.x, hb)), rng[0])
		var ay = lb.position.y + hb + 1
		var ax = lb.get_center().x
		d.draw_colored_polygon(PackedVector2Array([Vector2(ax - 4, ay + 1), Vector2(ax + 4, ay + 1), Vector2(ax, ay + 7)]), C_FD_SEL)
		_fd_set_logo(Rect2(lb.position + Vector2(0, hb + 10), Vector2(lb.size.x, hb)), rng[1])
	elif logo != null:
		var sc = minf(lb.size.x / logo.get_width(), lb.size.y / logo.get_height())
		var sz = Vector2(logo.get_width(), logo.get_height()) * sc
		d.draw_texture_rect(logo, Rect2(lb.position + (lb.size - sz) / 2.0, sz), false)
	else:
		d._text(Vector2(fcx - d._text_w(year) / 2.0, lb.get_center().y - 5), year, d.C_TEXT)
	# Derecha: tipo de batalla (con su dibujo) y el botón de empezar (un recuadro naranja)
	var bin := _fd_box(Rect2(x2 + 4, top, d.W - x2 - 8, 72), "BATTLE", 4)
	d.draw_rect(bin, Color(C_FD_ME if d.doubles_mode else C_FD_OPP, 0.55))     # simples rojo, dobles azul
	var bt = "Doubles" if d.doubles_mode else "Singles"
	d._text(Vector2(bin.get_center().x - d._text_w(bt) / 2.0, bin.position.y + 1), bt, d.C_TEXT)
	_fd_battle_icon(Vector2(bin.get_center().x, bin.position.y + 34), 14.0, d.doubles_mode)
	var sel_start: bool = d.free_cell == 5 and d.free_popup == ""
	_fd_start_button(Rect2(x2 + 4, top + 78, d.W - x2 - 8, bot - top - 78), sel_start)
	match d.free_popup:
		"deck_me", "deck_opp":
			_fd_deck_window(names, r)
		"diff":
			_fd_diff_window()
		"battle":
			_fd_battle_window()


## Botón de empezar: rojo en degradé como el OK de la elección de Pokémon iniciales
## (ui/boton_ok.png), con "START" chiquito y "DUEL!" con las letras doradas del título
## (ui/boton_duelo.png, de tools/logo_juego.py). Apagado si no está elegido.
var _duel_btn: Texture2D


func _fd_start_button(r: Rect2, sel: bool) -> void:
	if _duel_btn == null:
		var img := ImgLoad.load("res://ui/boton_duelo.png")
		if img != null:
			_duel_btn = ImageTexture.create_from_image(img)
	var dim := 1.0 if sel or d.free_popup != "" else 0.78
	var dc := Color(dim, dim, dim)
	d.draw_rect(r.grow(1), PB_INK)
	var h := int(r.size.y)
	for y in h:
		var k := y / float(h - 1)
		d.draw_rect(Rect2(r.position.x, r.position.y + y, r.size.x, 1), Color8(int(240 - 90 * k), int(88 - 56 * k), int(64 - 32 * k)) * dc)
	d.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), Color8(255, 168, 136) * dc)
	d.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), Color8(96, 16, 24))
	var label := "START"
	var tx := roundf(r.get_center().x - (label.length() * 4 - 1) / 2.0)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 7) + o, label, Color8(96, 16, 24))
	d.imagenes._draw_tiny(Vector2(tx, r.position.y + 7), label, Color("#f8f8f8") * dc)
	if _duel_btn != null:
		var p := (r.get_center() - _duel_btn.get_size() / 2.0 + Vector2(0, 5)).round()
		d.draw_texture(_duel_btn, p, dc)
	else:
		d._text(Vector2(r.get_center().x - d._text_w("Start duel!") / 2.0, r.position.y + 20), "Start duel!", Color.WHITE)
	if sel:
		_pb_corners(r)


## Caja del duelo libre: la de Pinball, con las esquinas rojas si es la elegida.
func _fd_box(r: Rect2, header: String, cell: int) -> Rect2:
	var sel: bool = cell == d.free_cell and d.free_popup == ""
	var inner := _pb_box(r, header, sel)
	if sel:
		_pb_corners(r)
	return inner


## Formato Custom: [el set más viejo, el último que entra] (sin POP ni promos).
func _fd_set_range() -> Array:
	var dd_: Dictionary = RuleSet.SEASONS[d.season_idx]
	var steps: Array = dd_.get("steps", [])
	var st: Array = dd_["start"].filter(func(c): return not str(c).begins_with("pop") and not str(c).begins_with("np"))
	var n = d.format_upto if d.format_upto >= 0 and d.format_upto <= steps.size() else steps.size()
	var newest: String = str(st[-1])
	for j in n:          # el último set que entra (un POP solo si tiene su símbolo; las promos no)
		var c := str(steps[j][0])
		if c.begins_with("np") or (c.begins_with("pop") and _fd_set_symbol(c, 20) == null):
			continue
		newest = c
	return [str(st[0]), newest]


## El símbolo de un set achicado a `size` de alto (null si no está).
var _set_syms := {}

func _fd_set_symbol(code: String, size: int) -> Texture2D:
	var key = "%s|%d" % [code, size]
	if not _set_syms.has(key):
		var tex: Texture2D = null
		var p := "res://mundo/propios/sets/simbolos/%s.png" % code
		if ImgLoad.exists(p):
			var img := ImgLoad.load(p)
			if img != null:
				img.convert(Image.FORMAT_RGBA8)
				var sc := float(size) / maxi(img.get_width(), img.get_height())
				img.resize(maxi(1, roundi(img.get_width() * sc)), maxi(1, roundi(img.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
				tex = ImageTexture.create_from_image(img)
		_set_syms[key] = tex
	return _set_syms[key]


## El logo de un set (mundo/propios/sets/<código>.png, propio del jugador) o su nombre.
var _set_logos := {}

func _fd_set_logo(r: Rect2, code: String) -> void:
	# Con el símbolo del set (mundo/propios/sets/simbolos/<código>.png): el ícono y el nombre al lado
	var sym = _fd_set_symbol(code, int(clampf(r.size.y - 8.0, 10.0, 20.0)))
	if sym != null:
		# El símbolo y, debajo, el nombre en letra chica
		var hh = sym.get_height() + 7
		var sp = Vector2(r.get_center().x - sym.get_width() / 2.0, r.get_center().y - hh / 2.0).round()
		d.draw_texture(sym, sp)
		var nm := RuleSet.set_title(code).replace("EX ", "").replace(" Base Set", "").to_upper()
		if nm.length() * 4 - 1 > r.size.x + 4:
			nm = nm.left(int((r.size.x + 5) / 4) - 1) + "."
		d.imagenes._draw_tiny(Vector2(r.get_center().x - nm.length() * 2.0, sp.y + sym.get_height() + 2), nm, d.C_TEXT)
		return
	if not _set_logos.has(code):
		var tex: Texture2D = null
		for ext in ["png", "webp", "jpg"]:
			var p := "res://mundo/propios/sets/%s.%s" % [code, ext]
			if tex == null and ImgLoad.exists(p):
				var img := ImgLoad.load(p)
				if img != null:
					var sc = minf(r.size.x / img.get_width(), r.size.y / img.get_height())
					if sc < 1.0:
						img.resize(maxi(1, roundi(img.get_width() * sc)), maxi(1, roundi(img.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
					tex = ImageTexture.create_from_image(img)
		_set_logos[code] = tex
	var t: Texture2D = _set_logos[code]
	if t != null:
		var sc2 = minf(1.0, minf(r.size.x / t.get_width(), r.size.y / t.get_height()))
		var sz = Vector2(t.get_width(), t.get_height()) * sc2
		d.draw_texture_rect(t, Rect2((r.position + (r.size - sz) / 2.0).round(), sz), false)
		return
	# Sin logo: el nombre del set, en uno o dos renglones
	var lines = d._wrap(RuleSet.set_title(code).replace("EX ", ""), r.size.x)
	var y0 = r.get_center().y - mini(lines.size(), 2) * 5.0
	for k in mini(lines.size(), 2):
		d._text(Vector2(r.get_center().x - d._text_w(str(lines[k])) / 2.0, y0 + k * 10), str(lines[k]), d.C_TEXT)


## Imagen de la batalla (mundo/propios/ui/batalla_singles.png o batalla_dobles.png, propias del
## jugador), recortada al centro y achicada al rectángulo pedido. null si no está.
var _fd_pics := {}

func _fd_pic(doubles: bool, w: int, h: int) -> Texture2D:
	var key = "%s|%dx%d" % [doubles, w, h]
	if not _fd_pics.has(key):
		var tex: Texture2D = null
		var p := "res://mundo/propios/ui/%s.png" % ("batalla_dobles" if doubles else "batalla_singles")
		if ImgLoad.exists(p):
			var img := ImgLoad.load(p)
			if img != null:
				img.convert(Image.FORMAT_RGBA8)
				var sc := maxf(float(w) / img.get_width(), float(h) / img.get_height())
				var cw = int(w / sc)
				var ch = int(h / sc)
				img = img.get_region(Rect2i((img.get_width() - cw) / 2, (img.get_height() - ch) / 2, cw, ch))
				img.resize(w, h, Image.INTERPOLATE_LANCZOS)
				tex = ImageTexture.create_from_image(img)
		_fd_pics[key] = tex
	return _fd_pics[key]


## El dibujito de la batalla: cartas propias abajo a la izquierda, las del rival arriba a la derecha.
func _fd_battle_icon(c: Vector2, rad: float, doubles: bool) -> void:
	# Con imagen propia: un rectángulo de 3:2 con borde y el fondo del color del tipo de batalla
	var pw := int(rad * 3.4)
	var ph := int(rad * 2.2)
	var img := _fd_pic(doubles, pw, ph)
	if img != null:
		var pr := Rect2((c - Vector2(pw, ph) / 2.0).round(), Vector2(pw, ph))
		d.draw_rect(pr.grow(2), Color("#5878c8") if doubles else Color("#c85848"))     # dobles azul, simples rojo
		d.draw_rect(pr.grow(1), d.C_INK)
		d.draw_texture(img, pr.position)
		return
	d.draw_circle(c, rad + 1, d.C_INK)
	d.draw_circle(c, rad, Color("#a8c0f0") if doubles else Color("#f0b0a0"))
	var cw := rad * 0.42
	var ch := rad * 0.56
	var n := 2 if doubles else 1
	for side in 2:
		var col := Color("#c85848") if side == 0 else Color("#4878c8")
		var base := c + (Vector2(rad * 0.35, -rad * 0.38) if side == 0 else Vector2(-rad * 0.35, rad * 0.38))
		for k in n:
			var off = (k - (n - 1) / 2.0) * (cw + 2.0)
			var r = Rect2(base + Vector2(off - cw / 2.0, -ch / 2.0), Vector2(cw, ch)).abs()
			d.draw_rect(r.grow(1), d.C_INK)
			d.draw_rect(r, col)


func _fd_window(r: Rect2, title: String) -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.35))
	d.draw_rect(r.grow(1), PB_INK)
	_pb_box(r, title, true)


func _fd_deck_window(names: Array, r: RuleSet) -> void:
	var win = Rect2(10, 14, d.W - 20, 128)
	_fd_window(win, "YOUR DECK" if d.free_popup == "deck_me" else "OPPONENT'S DECK")
	var lw := 150.0
	for i in range(d.popup_scroll, mini(d.popup_scroll + FD_LIST_ROWS, names.size())):
		var y = win.position.y + 17 + (i - d.popup_scroll) * 11
		var nm: String = names[i]
		if i == d.popup_cursor:
			d.draw_rect(Rect2(win.position.x + 4, y - 1, lw, 11), Color("#f8f0a0"))
			_pb_corners(Rect2(win.position.x + 4, y - 1, lw, 11))
		var legal = d._deck_legal(nm, r)
		d._text_fit(Vector2(win.position.x + 15, y), ("★ " if Decks.is_user(nm) else "") + nm,
				d.C_TEXT if legal else d.C_DIM, lw - 14)
	if names.size() > FD_LIST_ROWS:
		if d.popup_scroll > 0:
			d._text(Vector2(win.position.x + lw - 4, win.position.y + 16), "▲", d.C_DIM)
		if d.popup_scroll + FD_LIST_ROWS < names.size():
			d._text(Vector2(win.position.x + lw - 4, win.position.y + 16 + (FD_LIST_ROWS - 1) * 11), "▼", d.C_DIM)
	# A la derecha: la carta del mazo elegido y si se puede usar en el formato
	var sel: String = names[d.popup_cursor]
	# (la imagen ocupa todo el alto de la lista; abajo, si se puede usar en el formato)
	var side := Rect2(win.position.x + lw + 6, win.position.y + 15, win.end.x - 5 - (win.position.x + lw + 6), 0)
	var isz := 56.0
	var ir := Rect2(roundf(side.get_center().x - isz / 2.0), side.position.y, isz, isz)
	var cover = _deck_cover(sel)
	if cover != "":
		d.draw_rect(ir.grow(1), d.C_INK)
		d.imagenes._draw_card_image(ir, cover)
	var legal_sel = d._deck_legal(sel, r)
	var lt: String = "LEGAL" if legal_sel else "NOT LEGAL"
	d.imagenes._draw_tiny(Vector2(roundf(ir.get_center().x - (lt.length() * 4 - 1) / 2.0), ir.end.y + 4), lt,
			Color("#388850") if legal_sel else d.C_HP_LOW)
	# Abajo, a todo lo ancho: la descripción del mazo
	var dy = win.position.y + 17 + FD_LIST_ROWS * 11 + 3
	d.draw_rect(Rect2(win.position.x + 4, dy - 2, win.size.x - 8, 1), C_FD_LINE)
	var dl = d._wrap(Decks.description(sel), win.size.x - 16)
	for k in mini(dl.size(), int((win.end.y - dy - 4) / 10)):
		d._text(Vector2(win.position.x + 8, dy + k * 10), str(dl[k]), d.C_DIM)


func _fd_diff_window() -> void:
	var win := Rect2(60, 44, 120, 76)
	_fd_window(win, "DIFFICULTY")
	for i in 5:
		var y = win.position.y + 17 + i * 11
		if i == d.popup_cursor:
			d.draw_rect(Rect2(win.position.x + 4, y - 1, win.size.x - 8, 11), Color("#f8f0a0"))
			_pb_corners(Rect2(win.position.x + 4, y - 1, win.size.x - 8, 11))
		d._text(Vector2(win.position.x + 17, y), "%d · %s" % [i + 1, SimpleAI.LEVEL_NAMES[i]],
				C_FD_SEL if i == d.ai_level - 1 else d.C_TEXT)


## Opción "Border": el marco alrededor de la pantalla (ver scenes/marco_pantalla.gd).
func _toggle_border() -> void:
	d.border_on = not d.border_on
	d._apply_border()
	d._save_settings()
	d.snd.play("ok")


func _fd_battle_window() -> void:
	var win := Rect2(28, 20, 184, 112)
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.35))
	d.draw_rect(win.grow(1), PB_INK)
	_pb_box(win)            # caja a rayitas blancas, como la elección de mesa de Pokémon Pinball
	var half = win.size.x / 2.0
	for i in 2:
		var hx = win.position.x + i * half
		var sel = i == d.popup_cursor
		var card := Rect2(hx + 7, win.position.y + 8, half - 14, win.size.y - 16)
		var ri := _pinball_card(card, sel)
		d.draw_rect(ri, C_FD_ME if i == 1 else C_FD_OPP)
		_fd_battle_icon(Vector2(ri.get_center().x, ri.position.y + 42), 19.0, i == 1)
		var sub = "2 vs 2" if i == 1 else "1 vs 1"
		d._text(Vector2(ri.get_center().x - d._text_w(sub) / 2.0, ri.end.y - 15), sub, C_FD_SEL if sel else d.C_DIM)
		if not sel:
			d.draw_rect(ri, Color(1, 1, 1, 0.4))
		_pinball_tab(card, "DOUBLES" if i == 1 else "SINGLES", sel)
	d._text(Vector2(win.position.x - 9, win.get_center().y - 5), "◀", d.C_LIGHT)
	d._text(Vector2(win.end.x + 3, win.get_center().y - 5), "▶", d.C_LIGHT)


## Recuadro naranja con una pestaña arriba, como los de RUBY y SAPPHIRE de Pokémon Pinball.
## Devuelve el rectángulo de adentro (para el dibujo); la pestaña va después, con
## _pinball_tab. El que no está elegido va apagado.
const C_PB_L := Color("#f8c888")
const C_PB_M := Color("#d89030")
const C_PB_D := Color("#805010")


func _pinball_card(r: Rect2, sel: bool) -> Rect2:
	var l := C_PB_L if sel else C_PB_L.darkened(0.25)
	var m := C_PB_M if sel else C_PB_M.darkened(0.25)
	var dk := C_PB_D if sel else C_PB_D.darkened(0.15)
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	d.draw_rect(r, m)
	d.draw_rect(Rect2(x, y, w, 1), l)                  # luz arriba y a la izquierda
	d.draw_rect(Rect2(x, y, 1, h), l)
	d.draw_rect(Rect2(x + w - 1, y + 1, 1, h - 1), dk)  # sombra a la derecha y abajo
	d.draw_rect(Rect2(x + 1, y + h - 1, w - 1, 1), dk)
	var ri := Rect2(x + 3, y + 5, w - 6, h - 8)
	d.draw_rect(Rect2(ri.position.x - 1, ri.position.y - 1, ri.size.x + 1, 1), dk)   # hundido
	d.draw_rect(Rect2(ri.position.x - 1, ri.position.y - 1, 1, ri.size.y + 1), dk)
	d.draw_rect(Rect2(ri.end.x, ri.position.y - 1, 1, ri.size.y + 2), l)
	d.draw_rect(Rect2(ri.position.x - 1, ri.end.y, ri.size.x + 2, 1), l)
	d.draw_rect(ri, Color("#f8f8f8"))
	return ri


## La pestaña del recuadro (va después del dibujo de adentro, que queda tapado arriba).
func _pinball_tab(r: Rect2, label: String, sel: bool) -> void:
	var m := C_PB_M if sel else C_PB_M.darkened(0.25)
	var dk := C_PB_D if sel else C_PB_D.darkened(0.15)
	var x := r.position.x
	var w := r.size.x
	var ri := Rect2(x + 3, r.position.y + 5, w - 6, r.size.y - 8)
	# Pestaña: trapecio que baja desde el borde de arriba, con el nombre en blanco
	var tw := label.length() * 4 + 9
	var x0 := roundf(x + (w - tw) / 2.0) - 8
	var x1 := x0 + tw + 16
	for k in 8:
		var ty := ri.position.y - 1 + k
		d.draw_rect(Rect2(x0 + k, ty, x1 - x0 - 2 * k, 1), m)
		d.draw_rect(Rect2(x0 + k, ty, 1, 1), dk)
		d.draw_rect(Rect2(x1 - k - 1, ty, 1, 1), dk)
	d.draw_rect(Rect2(x0 + 8, ri.position.y + 7, x1 - x0 - 16, 1), dk)
	var tx := roundf(x + (w - (label.length() * 4 - 1)) / 2.0)
	var ty0 := ri.position.y
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		d.imagenes._draw_tiny(Vector2(tx, ty0) + o, label, dk)
	d.imagenes._draw_tiny(Vector2(tx, ty0), label, Color("#f8f8f8") if sel else Color("#e8e0d8"))


## Pantalla de título animada: la escena al azar de data/titulos.json, el logo y "PRESS START".
func _draw_attract() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), d.C_BG)
	d.title_scene.draw(d, d._attract_t)
	_draw_logo(4, d._attract_t)
	if int(d._attract_t * 2.0) % 2 == 0:
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)]:
			d._text(Vector2(floor((d.W - d._text_w("PRESS START")) / 2.0), 47) + o, "PRESS START", Color(0.08, 0.1, 0.18))
		d._text_center(47, "PRESS START", d.C_LIGHT)
	# Aviso de proyecto de fans (va siempre, también en la versión web)
	for i in DISCLAIMER.size():
		var line: String = DISCLAIMER[i]
		var y = d.H - 21 + i * 9
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			d._text(Vector2(floor((d.W - d._text_w(line)) / 2.0), y) + o, line, Color(0.08, 0.1, 0.18))
		d._text_center(y, line, Color(0.85, 0.87, 0.92))


const DISCLAIMER := ["Free fan game. Not affiliated with Nintendo,", "Game Freak, Creatures or The Pokémon Company."]


## El logo del juego (ui/logo.png, hecho con tools/logo_juego.py). t >= 0: cada tanto lo
## cruza un brillo (ui/logo_brillo.png, una tira de cuadros del mismo tamaño).
var _logo_tex: Texture2D
var _logo_shine: Texture2D

func _draw_logo(y: float, t: float = -1.0) -> void:
	if _logo_tex == null:
		var img := ImgLoad.load("res://ui/logo.png")
		var sh := ImgLoad.load("res://ui/logo_brillo.png")
		_logo_tex = ImageTexture.create_from_image(img) if img != null else null
		_logo_shine = ImageTexture.create_from_image(sh) if sh != null else null
	if _logo_tex == null:
		d._text_center(y + 8, "ADVANCE", d.C_LIGHT, true)
		return
	var w := _logo_tex.get_width()
	var h := _logo_tex.get_height()
	var pos = Vector2(floor((d.W - w) / 2.0), y)
	d.draw_texture(_logo_tex, pos)
	if t >= 0.0 and _logo_shine != null:
		var n := _logo_shine.get_width() / w
		var f := int(fmod(t, 4.0) / 0.035)     # pasa en ~0.7 s, cada 4 s
		if f < n:
			d.draw_texture_rect_region(_logo_shine, Rect2(pos, Vector2(w, h)), Rect2(f * w, 0, w, h))

func _draw_title() -> void:
	if d.title_attract:
		_draw_attract()
		return
	if d._table_tex == null:
		d._table_tex = ImageTexture.create_from_image(d.mesa._table_image())
	d.draw_rect(Rect2(0, 0, d.W, d.H), d.C_BG)
	d.draw_texture_rect(d._table_tex, Rect2(0, 0, d.W, d.H), false, Color(1, 1, 1, 0.35))
	_draw_logo(1)
	if d.title_view == "format":
		d.fmt_menu.draw()
		return
	if d.title_view == "duel":
		_draw_duel_setup()
	elif d.title_view == "online":
		d.online.draw()
	else:
		# Menú principal: caja de Pinball con su pestaña y la flechita amarilla
		var panel := Rect2(62, 52, 116, 78)
		d.draw_rect(panel.grow(2), Color(0, 0, 0, 0.25))
		var inner := _pb_box(panel, "MENU", true)
		for i in d.TITLE_ROWS:
			var y = inner.position.y + 2 + i * 12
			var sel = i == d.title_row and d.title_view == ""
			var label: String = d.TITLE_ITEMS[i]
			var col: Color = Color("#c03028") if sel else d.C_TEXT
			if i == 0 and not d.CAMPAIGN_ON:
				label = "Campaign (soon)"
				col = d.C_DIM
			if sel:
				_pb_corners(Rect2(inner.position.x + 2, y - 1, inner.size.x - 4, 11))
			d._text(Vector2(inner.position.x + 8, y), label, col)
	if d.title_view == "options":
		# Pantalla de opciones de Pinball: rayas naranjas, barra de título y una caja
		_pb_bg(PB_ORANGE)
		_pb_title(12, "OPTIONS")
		var o := Rect2(14, 28, d.W - 28, 108)
		var oi := _pb_box(o, "SETTINGS", true)
		for i in 7:
			var y := oi.position.y + 3 + i * 12
			var sel = i == d.opt_cursor
			if sel:
				_pb_corners(Rect2(o.position.x + 5, y - 1, o.size.x - 10, 11))
			var label: String = d.PAUSE_ITEMS[i + 1] if i < 5 else ("Border" if i == 5 else "Card art")
			d._text(Vector2(o.position.x + 10, y), label, d.C_TEXT)
			var v = d.paneles._pause_value(i + 1) if i < 5 else (("On" if d.border_on else "Off") if i == 5 \
					else (d.arte.batch_text() if d.arte.batch_text() != "" else "Get all"))
			var vs = ("◀ " + v + " ▶") if sel and i < 6 else (("Z " + v) if sel else v)
			d._text(Vector2(o.end.x - 8 - d._text_w(vs), y), vs, d.C_TEXT if sel else d.C_DIM)
	if d.title_view in ["options", "duel", "online", "format"]:
		d.draw_rect(Rect2(0, 146, d.W, 14), PB_INK)          # la ayuda va sobre una franja negra
	if d.title_msg != "":
		d._text_scroll(Vector2(6, 149), d.title_msg, Color("#f8a090"), 228, "title_msg")
	elif d.title_view == "duel":
		var hint := "▲▼◀▶ move · Z open · X back"
		if d.free_popup != "":
			hint = "◀▶ choose · Z select · X back" if d.free_popup == "battle" else "▲▼ choose · Z select · X back"
		elif d.free_cell == 3:
			hint = "Z: all formats (Official / Custom)"
		elif d.free_cell == 5:
			hint = "▲▼◀▶ move · Z start duel · X back"
		d._text(Vector2(6, 149), hint, d.C_LIGHT)
	elif d.title_view == "online":
		d._text_scroll(Vector2(6, 149), d.online.keys_text(), d.C_LIGHT, 228, "online_keys")
	else:
		d._text(Vector2(6, 149), "▲▼ select · Z accept", d.C_LIGHT)


# ===========================================================================
# Estilo Pokémon Pinball (menús principales)
# ===========================================================================
# Fondo a rayas de color (naranja en Options, verde en el duelo libre), barra de título negra
# con una línea amarilla, cajas blancas a rayitas con la esquina redondeada y una pestaña
# amarilla arriba a la izquierda, y de cursor cuatro esquinas rojas que se abren y se cierran.

const PB_ORANGE := [Color("#f8a000"), Color("#f87000")]
const PB_GREEN := [Color("#58d068"), Color("#38b048")]
const PB_BLUE := [Color("#5890f0"), Color("#3870d8")]
const PB_RED := [Color("#f06858"), Color("#d84838")]
const PB_YELLOW := [Color("#f8e800"), Color("#f8d000")]
const PB_INK := Color("#202020")


func _pb_bg(cols: Array, r: Rect2 = Rect2()) -> void:
	if r.size == Vector2.ZERO:
		r = Rect2(0, 0, d.W, d.H)
	for y in int(r.size.y):
		d.draw_rect(Rect2(r.position.x, r.position.y + y, r.size.x, 1), cols[(y / 2) % 2])


## Barra negra de lado a lado con una línea amarilla y el título en el medio.
func _pb_title(y: float, title: String) -> void:
	d.draw_rect(Rect2(0, y, d.W, 5), PB_INK)
	d.draw_rect(Rect2(0, y + 2, d.W, 1), PB_YELLOW[0])
	var w: float = d._text_w(title)
	var bx := Rect2(floorf((d.W - w) / 2.0) - 6, y - 4, w + 12, 13)
	d.draw_rect(bx, PB_INK)
	d.draw_rect(bx.grow(-1), Color("#f8f8f8"))
	d.draw_rect(bx.grow(-2), PB_INK)
	d._text(Vector2(bx.position.x + 6, y - 3), title, Color("#f8f8f8"))


## Caja blanca a rayitas con las esquinas redondeadas; con `header`, una pestaña amarilla
## arriba a la izquierda (con el texto). Devuelve dónde empieza el contenido.
func _pb_box(r: Rect2, header: String = "", sel: bool = false) -> Rect2:
	var x := r.position.x
	var w := r.size.x
	for y in int(r.size.y):
		var cut := 0
		if y == 0 or y == int(r.size.y) - 1:
			cut = 2
		elif y == 1 or y == int(r.size.y) - 2:
			cut = 1
		d.draw_rect(Rect2(x + cut, r.position.y + y, w - 2 * cut, 1), Color("#f8f8f8") if y % 2 == 0 else Color("#e0e0e0"))
	var top := r.position.y
	if header != "":
		var hw: float = d._text_w(header) + 14
		for y in 10:
			var cut := 2 if y == 0 else (1 if y == 1 else 0)
			var slant := maxi(0, y - 1)       # la punta de la derecha baja en diagonal
			d.draw_rect(Rect2(x + cut, top + y, hw + 9 - slant - cut, 1), PB_YELLOW[(y / 2) % 2])
		d._text(Vector2(x + 5, top), header, PB_INK if sel else Color("#806000"))
		top += 11
	return Rect2(x + 3, top + 1, w - 6, r.end.y - top - 3)


## Cursor de selección: cuatro esquinas rojas en L con borde blanco que se abren y se cierran
## (tres cuadros: 0, 1 y 2 píxeles hacia afuera, y vuelta).
const PB_CORNER := Color("#ff2129")


func _pb_corners(r: Rect2) -> void:
	var step: int = [0, 1, 2, 1][int(Clock.ms() / 160) % 4]
	var a := r.grow(1 + step)
	var arm := clampf(roundf(minf(a.size.x, a.size.y) / 2.6), 3.0, 7.0)     # en renglones chicos, más cortas
	for cx in 2:
		for cy in 2:
			var x: float = a.position.x if cx == 0 else a.end.x - arm
			var y: float = a.position.y if cy == 0 else a.end.y - arm
			var vx: float = a.position.x if cx == 0 else a.end.x - 2     # brazo vertical
			var hy: float = a.position.y if cy == 0 else a.end.y - 2     # brazo horizontal
			d.draw_rect(Rect2(x - 1, hy - 1, arm + 2, 4), Color.WHITE)
			d.draw_rect(Rect2(vx - 1, y - 1, 4, arm + 2), Color.WHITE)
			d.draw_rect(Rect2(x, hy, arm, 2), PB_CORNER)
			d.draw_rect(Rect2(vx, y, 2, arm), PB_CORNER)
