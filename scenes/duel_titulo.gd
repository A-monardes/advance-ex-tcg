extends RefCounted
## Pantalla de título, menú principal y armado del duelo libre
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


func _title_input(k: int, accept: bool) -> void:
	var n := Decks.names().size()
	d.my_deck = clampi(d.my_deck, 0, n - 1)
	d.opp_deck = clampi(d.opp_deck, 0, n - 1)
	d.title_msg = ""
	if d.title_view == "options":
		# Opciones: Animación, Efectos, Música y Mesa (las mismas de la pausa)
		match k:
			KEY_UP, KEY_DOWN:
				d.opt_cursor = (d.opt_cursor + (1 if k == KEY_DOWN else 5)) % 6
				d.snd.play("move")
			KEY_LEFT, KEY_RIGHT:
				if d.opt_cursor < 5:
					d.paneles._pause_change(d.opt_cursor + 1, 1 if k == KEY_RIGHT else -1)
					d.snd.play("ok")
			KEY_X, KEY_ESCAPE, KEY_BACKSPACE:
				d.title_view = ""
				d.snd.play("back")
		if accept:
			if d.opt_cursor == 5:         # Card art: bajar el arte de todas las cartas
				d.arte.download_all()
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
	var names := Decks.names()
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
	var names := Decks.names()
	var r = d.format_rules()
	d.my_deck = clampi(d.my_deck, 0, names.size() - 1)
	d.opp_deck = clampi(d.opp_deck, 0, names.size() - 1)
	var panel = Rect2(2, 40, d.W - 4, 107)
	d._frame(panel)
	d._text_center(42, "FREE DUEL", d.C_DIM)
	var x1 := 110.0
	var x2 := 174.0
	var top := 53.0
	d.draw_rect(Rect2(6, top - 1, d.W - 12, 1), C_FD_LINE)
	d.draw_rect(Rect2(x1, top, 1, panel.end.y - top - 4), C_FD_LINE)
	d.draw_rect(Rect2(x2, top, 1, panel.end.y - top - 4), C_FD_LINE)
	# Izquierda: los dos mazos (nombre, si es legal en el formato y su carta) y la dificultad
	for i in 2:
		var ry := top + 1 + i * 38
		var cell := Rect2(5, ry, x1 - 7, 37)
		if i == 1:
			d.draw_rect(Rect2(6, ry - 1, x1 - 8, 1), C_FD_LINE)
		var nm: String = names[d.my_deck if i == 0 else d.opp_deck]
		d.draw_rect(cell, C_FD_ME if i == 0 else C_FD_OPP)       # tu mazo en azul, el del rival en rojo
		_fd_cell_bg(cell, i)
		d._text(Vector2(8, ry + 1), "Your deck" if i == 0 else "Opponent", d.C_DIM)
		d._text_fit(Vector2(8, ry + 12), ("★ " if Decks.is_user(nm) else "") + nm, d.C_TEXT, 54)
		var legal = d._deck_legal(nm, r)
		d.imagenes._draw_tiny(Vector2(8, ry + 30), "LEGAL TO USE" if legal else "NOT LEGAL IN THIS FORMAT",
				Color("#388850") if legal else d.C_HP_LOW)
		var cover := _deck_cover(nm)
		var ir := Rect2(x1 - 34, ry + 2, 27, 26)
		d.draw_rect(ir.grow(1), d.C_INK)
		if cover != "":
			d.imagenes._draw_card_image(Rect2(x1 - 33, ry + 2, 26, 26), cover)
	var dy := top + 77
	d.draw_rect(Rect2(6, dy - 1, x1 - 8, 1), C_FD_LINE)
	_fd_cell_bg(Rect2(5, dy, x1 - 7, panel.end.y - dy - 4), 2)
	d._text(Vector2(8, dy + 1), "Difficulty", d.C_DIM)
	var lv = "%d · %s" % [d.ai_level, SimpleAI.LEVEL_NAMES[d.ai_level - 1]]
	d._text(Vector2(x1 - 4 - d._text_w(lv), dy + 1), lv, d.C_TEXT)
	# Centro: el formato (con el logo del Mundial)
	_fd_cell_bg(Rect2(x1 + 2, top, x2 - x1 - 3, panel.end.y - top - 4), 3)
	d._text(Vector2((x1 + x2) / 2.0 - d._text_w("Format") / 2.0, top + 2), "Format", d.C_DIM)
	var fname: String = str(RuleSet.SEASONS[d.season_idx]["worlds"]).to_upper() if d.format_upto < 0 \
			else "CUSTOM " + str(RuleSet.SEASONS[d.season_idx]["id"])
	d.imagenes._draw_tiny(Vector2((x1 + x2) / 2.0 - fname.length() * 2.0, top + 14), fname, d.C_TEXT)
	var year = str(RuleSet.SEASONS[d.season_idx]["worlds"]).right(4)
	var logo: Texture2D = d.fmt_menu._logo(year)
	var lb = Rect2(x1 + 4, top + 22, x2 - x1 - 8, panel.end.y - top - 36)
	# Abajo, chiquito: con cuántos sets se juega (los POP aparte; las promos no cuentan)
	var ls: Array = r.legal_sets.filter(func(c): return not str(c).begins_with("np"))
	var n_pop := ls.filter(func(c): return str(c).begins_with("pop")).size()
	var cnt = "%d SETS" % (ls.size() - n_pop) + (" + %d POP" % n_pop if n_pop > 0 else "")
	d.imagenes._draw_tiny(Vector2(roundf((x1 + x2) / 2.0 - cnt.length() * 2.0), panel.end.y - 11), cnt, d.C_DIM)
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
		d._text(Vector2((x1 + x2) / 2.0 - d._text_w(year) / 2.0, lb.get_center().y - 5), year, d.C_TEXT)
	# Derecha: tipo de batalla (con su dibujo) y empezar
	var by := top + 58
	var bcell = Rect2(x2 + 2, top, panel.end.x - x2 - 6, by - top - 1)
	d.draw_rect(bcell, C_FD_ME if d.doubles_mode else C_FD_OPP)     # simples rojo, dobles azul
	_fd_cell_bg(bcell, 4)
	var cx = (x2 + panel.end.x - 3) / 2.0
	d._text(Vector2(cx - d._text_w("Battle") / 2.0, top + 2), "Battle", d.C_DIM)
	var bt = "Doubles" if d.doubles_mode else "Singles"
	d._text(Vector2(cx - d._text_w(bt) / 2.0, top + 12), bt, d.C_TEXT)
	_fd_battle_icon(Vector2(cx, top + 40), 14.0, d.doubles_mode)
	d.draw_rect(Rect2(x2 + 2, by, panel.end.x - x2 - 6, 1), C_FD_LINE)
	var sb = Rect2(x2 + 3, by + 10, panel.end.x - x2 - 8, 20)
	_fd_cell_bg(Rect2(x2 + 2, by + 1, panel.end.x - x2 - 6, panel.end.y - by - 5), 5)
	d._frame(sb)
	d._text(Vector2(sb.get_center().x - d._text_w("Start duel!") / 2.0, sb.position.y + 5), "Start duel!",
			C_FD_SEL if d.free_cell == 5 else d.C_TEXT)
	match d.free_popup:
		"deck_me", "deck_opp":
			_fd_deck_window(names, r)
		"diff":
			_fd_diff_window()
		"battle":
			_fd_battle_window()


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


## Casilla del duelo libre: la elegida, con fondo y borde (los mazos ya tienen su color).
func _fd_cell_bg(r: Rect2, cell: int) -> void:
	if cell != d.free_cell or d.free_popup != "":
		return
	if cell in [2, 3, 5]:
		d.draw_rect(r, Color("#d8e4f8"))
	else:
		d.draw_rect(r, Color(1, 1, 1, 0.25))
	d._outline(r, C_FD_SEL)


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
	d._frame(r)
	d._text(Vector2(r.position.x + 8, r.position.y + 4), title, d.C_DIM)


func _fd_deck_window(names: Array, r: RuleSet) -> void:
	var win = Rect2(10, 14, d.W - 20, 128)
	_fd_window(win, "YOUR DECK" if d.free_popup == "deck_me" else "OPPONENT'S DECK")
	var lw := 150.0
	for i in range(d.popup_scroll, mini(d.popup_scroll + FD_LIST_ROWS, names.size())):
		var y = win.position.y + 17 + (i - d.popup_scroll) * 11
		var nm: String = names[i]
		d._stripe(Rect2(win.position.x + 4, y - 1, lw, 11), i)
		if i == d.popup_cursor:
			d.draw_rect(Rect2(win.position.x + 4, y - 1, lw, 11), Color("#d8e4f8"))
			d._text(Vector2(win.position.x + 6, y), "▶", d.C_TEXT)
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
	var px = win.position.x + lw + 10
	var cover = _deck_cover(sel)
	if cover != "":
		var ir = Rect2(px + 4, win.position.y + 18, 40, 40)
		d.draw_rect(ir.grow(1), d.C_INK)
		d.imagenes._draw_card_image(ir, cover)
	var legal_sel = d._deck_legal(sel, r)
	d.imagenes._draw_tiny(Vector2(px, win.position.y + 64), "LEGAL" if legal_sel else "NOT LEGAL", Color("#388850") if legal_sel else d.C_HP_LOW)
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
		d._stripe(Rect2(win.position.x + 4, y - 1, win.size.x - 8, 11), i)
		if i == d.popup_cursor:
			d.draw_rect(Rect2(win.position.x + 4, y - 1, win.size.x - 8, 11), Color("#d8e4f8"))
			d._text(Vector2(win.position.x + 7, y), "▶", d.C_TEXT)
		d._text(Vector2(win.position.x + 17, y), "%d · %s" % [i + 1, SimpleAI.LEVEL_NAMES[i]],
				C_FD_SEL if i == d.ai_level - 1 else d.C_TEXT)


func _fd_battle_window() -> void:
	var win := Rect2(28, 20, 184, 112)
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.35))
	d._frame(win)
	var half = win.size.x / 2.0
	d.draw_rect(Rect2(win.position.x + half, win.position.y + 5, 1, win.size.y - 10), C_FD_LINE)
	for i in 2:
		var hx = win.position.x + i * half
		var sel = i == d.popup_cursor
		var cell = Rect2(hx + 4, win.position.y + 4, half - 8, win.size.y - 8)
		d.draw_rect(cell, C_FD_ME if i == 1 else C_FD_OPP)
		if sel:
			d._outline(cell, C_FD_SEL)
		else:
			d.draw_rect(cell, Color(1, 1, 1, 0.35))
		var lbl := "DOUBLES" if i == 1 else "SINGLES"
		d._text(Vector2(hx + half / 2.0 - d._text_w(lbl) / 2.0, win.position.y + 9), lbl, C_FD_SEL if sel else d.C_TEXT)
		_fd_battle_icon(Vector2(hx + half / 2.0, win.position.y + 54), 24.0, i == 1)
		var sub = "2 vs 2" if i == 1 else "1 vs 1"
		d._text(Vector2(hx + half / 2.0 - d._text_w(sub) / 2.0, win.position.y + 90), sub, d.C_DIM)
	d._text(Vector2(win.position.x - 9, win.get_center().y - 5), "◀", d.C_LIGHT)
	d._text(Vector2(win.end.x + 3, win.get_center().y - 5), "▶", d.C_LIGHT)
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
		# Menú principal: cuatro opciones
		var panel := Rect2(64, 56, 112, 70)
		d._frame(panel)
		for i in d.TITLE_ROWS:
			var y = panel.position.y + 6 + i * 12
			var sel = i == d.title_row and d.title_view == ""
			var label: String = d.TITLE_ITEMS[i]
			var col: Color = Color("#c03028") if sel else d.C_TEXT
			d._stripe(Rect2(panel.position.x + 4, y - 1, panel.size.x - 8, 12), i)
			if i == 0 and not d.CAMPAIGN_ON:
				label = "Campaign (soon)"
				col = d.C_DIM
			if sel:
				d._text(Vector2(panel.position.x + 8, y), "▶", d.C_TEXT)
			d._text(Vector2(panel.position.x + 18, y), label, col)
	if d.title_view == "options":
		var o := Rect2(40, 40, 160, 84)
		d._frame(o)
		d._text(Vector2(o.position.x + 9, o.position.y + 4), "OPTIONS", d.C_DIM)
		for i in 6:
			var y := o.position.y + 16 + i * 11
			var sel = i == d.opt_cursor
			d._stripe(Rect2(o.position.x + 4, y - 1, o.size.x - 8, 11), i)
			if sel:
				d._text(Vector2(o.position.x + 8, y), "▶", d.C_TEXT)
			var label: String = d.PAUSE_ITEMS[i + 1] if i < 5 else "Card art"
			d._text(Vector2(o.position.x + 17, y), label, d.C_TEXT)
			var v = d.paneles._pause_value(i + 1) if i < 5 else (d.arte.batch_text() if d.arte.batch_text() != "" else "Get all")
			var vs = ("◀ " + v + " ▶") if sel and i < 5 else (("Z " + v) if sel else v)
			d._text(Vector2(o.end.x - 8 - d._text_w(vs), y), vs, d.C_TEXT if sel else d.C_DIM)
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
