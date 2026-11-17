
extends RefCounted
## Editor de mazos. Lo dibuja y le pasa las teclas la pantalla de duelo (duel.gd),
## que tiene los ayudantes de texto e imágenes.
##
## Pantallas:
##   "list"   tus mazos + crear uno vacío + copiar uno existente
##   "edit"   pestañas Mazo / Pokémon / Entrenadores / Energías; ←→ quita/agrega copias
##   "rename" escribir el nombre del mazo con el teclado

const TABS := ["Deck", "Pokémon", "Trainers", "Energy"]
const ROWS := 8             # filas visibles en las listas
const LIST_Y := 37
const ROW_H := 10

var d                       # la pantalla de duelo (duel.gd)
var screen := "list"
var cursor := 0
var scroll := 0
var copy_from := 0          # mazo elegido en "Copiar mazo"
var confirm_delete := false
var deck_name := ""
var counts := {}            # id -> copias en el mazo que se está editando
var tab := 0
var search := ""
var searching := false      # F: escribiendo en el buscador (las letras no hacen sus acciones)
var typed := ""             # nombre mientras se escribe
var msg := ""               # aviso breve (p.ej. "máximo 4 copias")
var _pool: Array = []       # todas las cartas que se pueden usar
var _full_pool: Array = []
var camp = null             # en la campaña: el estado (solo tus cartas, guarda en la campaña)
var camp_slot := 0          # campaña: qué lugar de mazo se está editando
var camp_menu := -1         # campaña: opción marcada en el menú de un mazo (-1 = cerrado)
const CAMP_OPTIONS := ["Edit", "Use in duels", "Rename", "Copy to empty slot", "Clear"]


func _init(duel) -> void:
	d = duel
	for id in CardDB.all_ids():
		if CardDB.is_pokemon(id) or CardDB.is_energy(id) or (CardDB.is_trainer(id) and Trainers.is_implemented(id)):
			_pool.append(id)
	_full_pool = _pool.duplicate()


## Mazos de la campaña: primero la lista de tus lugares de mazo (CampaignState.DECK_SLOTS);
## se arman solo con las cartas de tu colección y se guardan en la campaña.
func open_collection(state) -> void:
	camp = state
	_pool = state.collection_ids()
	screen = "camp_list"
	cursor = state.active_deck
	camp_menu = -1
	confirm_delete = false
	search = ""
	searching = false
	msg = ""


func _start_camp_edit(slot: int) -> void:
	camp_slot = slot
	deck_name = camp.deck_name(slot)
	counts = {}
	for e in camp.decks[slot]["cartas"]:
		counts[str(e[0])] = counts.get(str(e[0]), 0) + int(e[1])
	screen = "edit"
	tab = 0 if not counts.is_empty() else 1
	cursor = 0
	scroll = 0
	search = ""
	searching = false
	msg = ""


func open() -> void:
	camp = null
	_pool = _full_pool.duplicate()
	screen = "list"
	cursor = 0
	scroll = 0
	confirm_delete = false
	msg = ""


# ===========================================================================
# Datos
# ===========================================================================

func _list_rows() -> Array:
	var rows: Array = []
	for n in Decks.user_names():
		rows.append({"kind": "deck", "name": n})
	rows.append({"kind": "new"})
	rows.append({"kind": "copy"})
	return rows


func _total() -> int:
	var t := 0
	for id in counts:
		t += counts[id]
	return t


func _deck_array() -> Array[String]:
	var out: Array[String] = []
	for id in counts:
		for i in counts[id]:
			out.append(id)
	return out


func _entries() -> Array:
	var out: Array = []
	for id in _sorted(counts.keys()):
		if counts[id] > 0:
			out.append([id, counts[id]])
	return out


## Orden: Pokémon (por set y número), Entrenadores, Energías.
func _sorted(ids: Array) -> Array:
	var arr := ids.duplicate()
	arr.sort_custom(func(a, b): return _sort_key(a) < _sort_key(b))
	return arr


func _sort_key(id: String) -> String:
	var cat := 0 if CardDB.is_pokemon(id) else (2 if CardDB.is_energy(id) else 1)
	var parts := id.split("-")
	var set_rank := "z" + parts[0] if parts[0].begins_with("ecard") else parts[0]   # los ecard al final
	return "%d|%s|%04d" % [cat, set_rank, int(parts[1]) if parts.size() > 1 else 0]


func _tab_cards() -> Array:
	var ids: Array = []
	match tab:
		0:
			ids = counts.keys().filter(func(id): return counts[id] > 0)
		1:
			ids = _pool.filter(func(id): return CardDB.is_pokemon(id))
		2:
			ids = _pool.filter(func(id): return CardDB.is_trainer(id))
		3:
			ids = _pool.filter(func(id): return CardDB.is_energy(id))
	if search != "":
		ids = ids.filter(func(id): return _matches(id, search))
	return _sorted(ids)


## El buscador encuentra por nombre, por código de carta o de set ("ex2", "ecard1-33", "np")
## y por nombre del set ("Sandstorm", "Aquapolis").
func _matches(id: String, query: String) -> bool:
	var q := query.strip_edges().to_lower()
	if q == "":
		return true
	if CardDB.card_name(id).to_lower().contains(q):
		return true
	# Código: tiene que traer un número, un guion o ser "np" (así "ex" sigue buscando los
	# Pokémon-ex por nombre). "ex1" es el set entero; "ex1-1" encuentra 1, 10, 11...
	var code_like := q == "np" or q.contains("-") or RegEx.create_from_string("\\d").search(q) != null
	if code_like:
		var lid := id.to_lower()
		var set_code := lid.split("-")[0]
		if q.contains("-") and set_code == q.split("-")[0] and lid.begins_with(q):
			return true
		if not q.contains("-") and set_code == q:
			return true
	return q.length() >= 4 and str(CardDB.get_card(id).get("set", "")).to_lower().contains(q)


func _copies_by_name(id: String) -> int:
	var n := CardDB.card_name(id)
	var t := 0
	for k in counts:
		if CardDB.card_name(k) == n:
			t += counts[k]
	return t


func _add(id: String) -> void:
	msg = ""
	if _total() >= 60:
		msg = "The deck already has 60 cards."
		return
	if not CardDB.is_basic_energy(id) and _copies_by_name(id) >= 4:
		msg = "No more than 4 copies of %s." % CardDB.card_name(id)
		return
	if camp != null and counts.get(id, 0) >= camp.owned(id):
		msg = "You have %d %s." % [camp.owned(id), CardDB.card_name(id)]
		return
	counts[id] = counts.get(id, 0) + 1
	_save()


func _remove(id: String) -> void:
	msg = ""
	if counts.get(id, 0) <= 0:
		return
	counts[id] -= 1
	if counts[id] == 0:
		counts.erase(id)
	_save()


func _save() -> void:
	if camp != null:
		camp.decks[camp_slot]["cartas"] = _entries()
		camp.save()
		return
	Decks.save_user(deck_name, _entries())


func _start_edit(name: String) -> void:
	deck_name = name
	counts = {}
	for e in Decks.entries(name):
		counts[str(e[0])] = counts.get(str(e[0]), 0) + int(e[1])
	screen = "edit"
	tab = 0 if not counts.is_empty() else 1
	cursor = 0
	scroll = 0
	search = ""
	searching = false
	msg = ""


# ===========================================================================
# Teclas
# ===========================================================================

func input(event: InputEventKey) -> void:
	var k := event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo
	var back := k in [KEY_X, KEY_ESCAPE] and not event.echo
	match screen:
		"list": _list_input(k, accept, back)
		"camp_list": _camp_list_input(k, accept, back)
		"edit": _edit_input(event, k, back)
		"rename": _rename_input(event, k)


func _camp_list_input(k: int, accept: bool, back: bool) -> void:
	var n: int = camp.DECK_SLOTS
	if camp_menu >= 0:
		match k:
			KEY_UP: camp_menu = (camp_menu - 1 + CAMP_OPTIONS.size()) % CAMP_OPTIONS.size()
			KEY_DOWN: camp_menu = (camp_menu + 1) % CAMP_OPTIONS.size()
		if k in [KEY_UP, KEY_DOWN]:
			confirm_delete = false
			d.snd.play("move")
		if back:
			camp_menu = -1
			confirm_delete = false
			d.snd.play("back")
		elif accept:
			_camp_option(CAMP_OPTIONS[camp_menu])
		return
	match k:
		KEY_UP:
			cursor = (cursor - 1 + n) % n
			msg = ""
			d.snd.play("move")
		KEY_DOWN:
			cursor = (cursor + 1) % n
			msg = ""
			d.snd.play("move")
	if accept:
		camp_menu = 0
		confirm_delete = false
		d.snd.play("ok")
	elif back:
		camp.save()
		d.snd.play("back")
		d._go(func(): d.mode = "campaign")     # vuelve al mapa


func _camp_option(opt: String) -> void:
	var slot := cursor
	match opt:
		"Edit":
			camp_menu = -1
			d.snd.play("ok")
			_start_camp_edit(slot)
		"Use in duels":
			camp.active_deck = slot
			camp.save()
			camp_menu = -1
			var errs: Array = camp.deck_errors(slot)
			msg = "You'll duel with %s." % camp.deck_name(slot) if errs.is_empty() \
					else "In use, but it isn't ready: " + str(errs[0])
			d.snd.play("ok")
		"Rename":
			camp_slot = slot
			deck_name = camp.deck_name(slot)
			typed = str(camp.decks[slot]["nombre"])
			camp_menu = -1
			screen = "rename"
			d.snd.play("ok")
		"Copy to empty slot":
			var dest := -1
			for i in camp.DECK_SLOTS:
				if i != slot and camp.deck_size(i) == 0:
					dest = i
					break
			camp_menu = -1
			if camp.deck_size(slot) == 0:
				msg = "This deck is empty."
				d.snd.play("error")
			elif dest < 0:
				msg = "There's no empty slot. Clear one first."
				d.snd.play("error")
			else:
				camp.decks[dest] = {"nombre": "Copy of " + camp.deck_name(slot), "cartas": camp.decks[slot]["cartas"].duplicate(true)}
				camp.save()
				msg = "Copied to slot %d." % (dest + 1)
				d.snd.play("ok")
		"Clear":
			if not confirm_delete:
				confirm_delete = true          # la segunda vez, se vacía
				d.snd.play("move")
				return
			camp.decks[slot] = {"nombre": "", "cartas": []}
			camp.save()
			confirm_delete = false
			camp_menu = -1
			msg = "Slot %d is empty now." % (slot + 1)
			d.snd.play("ok")


func _list_input(k: int, accept: bool, back: bool) -> void:
	var rows := _list_rows()
	var presets := Decks.names()
	if k != KEY_DELETE and k != KEY_D:
		confirm_delete = false
	match k:
		KEY_UP: cursor = (cursor - 1 + rows.size()) % rows.size()
		KEY_DOWN: cursor = (cursor + 1) % rows.size()
		KEY_LEFT, KEY_RIGHT:
			if rows[cursor]["kind"] == "copy":
				copy_from = (copy_from + (1 if k == KEY_RIGHT else -1) + presets.size()) % presets.size()
		KEY_R:
			if rows[cursor]["kind"] == "deck":
				deck_name = rows[cursor]["name"]
				typed = deck_name
				screen = "rename"
		KEY_DELETE, KEY_D:
			if rows[cursor]["kind"] == "deck":
				if confirm_delete:
					Decks.delete_user(rows[cursor]["name"])
					confirm_delete = false
					cursor = mini(cursor, _list_rows().size() - 1)
				else:
					confirm_delete = true
	if accept:
		var row: Dictionary = rows[cursor]
		match row["kind"]:
			"deck":
				_start_edit(row["name"])
			"new":
				var n := Decks.free_name("My deck")
				Decks.save_user(n, [])
				_start_edit(n)
			"copy":
				var src: String = presets[copy_from]
				var n := Decks.free_name("Copy of " + src.replace(" (Worlds 2004)", ""))
				Decks.save_user(n, Decks.entries(src))
				_start_edit(n)
	elif back:
		d._go(func(): d.mode = "title")


func _edit_input(event: InputEventKey, k: int, back: bool) -> void:
	if searching:
		_search_input(event, k)
		return
	var cards := _tab_cards()
	var id: String = cards[cursor] if cursor < cards.size() else ""
	match k:
		KEY_UP: cursor = maxi(0, cursor - 1)
		KEY_DOWN: cursor = mini(maxi(0, cards.size() - 1), cursor + 1)
		KEY_PAGEUP: cursor = maxi(0, cursor - ROWS)
		KEY_PAGEDOWN: cursor = mini(maxi(0, cards.size() - 1), cursor + ROWS)
		KEY_RIGHT, KEY_Z, KEY_ENTER:
			if id != "":
				_add(id)
		KEY_LEFT:
			if id != "":
				_remove(id)
				if tab == 0:
					cursor = mini(cursor, maxi(0, _tab_cards().size() - 1))
		KEY_TAB:
			tab = (tab + (-1 if event.shift_pressed else 1) + TABS.size()) % TABS.size()
			cursor = 0
			scroll = 0
		KEY_C:
			if id != "" and not event.echo:
				var tab_list := _tab_cards()
				var entries: Array = []
				for cid in tab_list:
					var c2: String = cid
					entries.append(func(): return d._card_lines(c2, null))
				d._open_info(entries, cursor, func(j: int):
					cursor = j
					if cursor < scroll:
						scroll = cursor
					elif cursor >= scroll + ROWS:
						scroll = cursor - ROWS + 1)
		KEY_BACKSPACE:
			if search != "":
				search = search.left(-1)
				cursor = 0
				scroll = 0
		KEY_ESCAPE, KEY_X:
			if search != "" and k == KEY_ESCAPE:
				search = ""
			elif not event.echo:
				_save()
				if camp != null:
					screen = "camp_list"               # vuelve a la lista de tus mazos
					cursor = camp_slot
					msg = ""
				else:
					open()
			return
		KEY_F, KEY_SLASH:
			if not event.echo:
				searching = true            # F abre el buscador; Enter lo cierra y deja el filtro
	if cursor < scroll:
		scroll = cursor
	if cursor >= scroll + ROWS:
		scroll = cursor - ROWS + 1


## Escribiendo en el buscador: todas las letras van al texto. Enter (o las flechas) dejan
## de escribir y el filtro queda; Escape lo borra.
func _search_input(event: InputEventKey, k: int) -> void:
	match k:
		KEY_ENTER, KEY_KP_ENTER:
			searching = false
		KEY_ESCAPE:
			searching = false
			search = ""
		KEY_UP, KEY_DOWN, KEY_TAB:
			searching = false
			_edit_input(event, k, false)
			return
		KEY_BACKSPACE:
			search = search.left(-1)
		_:
			var ch := char(event.unicode) if event.unicode >= 32 else ""
			if ch == "" or search.length() >= 20:
				return
			search += ch
	cursor = 0
	scroll = 0


func _rename_input(event: InputEventKey, k: int) -> void:
	if camp != null:          # campaña: el nombre del lugar de mazo (puede repetirse)
		match k:
			KEY_ENTER, KEY_KP_ENTER:
				camp.decks[camp_slot]["nombre"] = typed.strip_edges()
				camp.save()
				screen = "camp_list"
				msg = ""
			KEY_ESCAPE:
				screen = "camp_list"
				msg = ""
			KEY_BACKSPACE:
				typed = typed.left(-1)
			_:
				if event.unicode >= 32 and typed.length() < 24:
					typed += char(event.unicode)
		return
	match k:
		KEY_ENTER, KEY_KP_ENTER:
			var n := typed.strip_edges()
			if n == deck_name or Decks.rename_user(deck_name, n):
				screen = "list"
				msg = ""
			else:
				msg = "That name already exists or is empty."
		KEY_ESCAPE:
			screen = "list"
			msg = ""
		KEY_BACKSPACE:
			typed = typed.left(-1)
		_:
			if event.unicode >= 32 and typed.length() < 28:
				typed += char(event.unicode)


# ===========================================================================
# Dibujo
# ===========================================================================

func draw() -> void:
	# Fondo: el diseño de mesa elegido, apagado, como en el título
	d._menu_bg()
	match screen:
		"camp_list": _draw_camp_list()
		"list", "rename":
			if camp != null:
				_draw_camp_list()
			else:
				_draw_list()
		"edit": _draw_edit()


## Tus mazos de la campaña: un renglón doble por lugar (nombre y si está listo), el que está
## en uso marcado, y el menú de opciones al lado del elegido.
func _draw_camp_list() -> void:
	d._frame(Rect2(0, 0, d.W, 22))
	d._text(Vector2(9, 5), "YOUR DECKS", d.C_TEXT)
	var cash := "₽%d" % camp.money
	d._text(Vector2(d.W - 9 - d._text_w(cash), 5), cash, d.C_DIM)
	d._frame(Rect2(0, 20, d.W, 100))
	for i: int in camp.DECK_SLOTS:
		var y: int = 25 + i * 23
		var sel: bool = i == cursor
		var size: int = camp.deck_size(i)
		var empty: bool = size == 0 and str(camp.decks[i]["nombre"]) == ""
		if sel:
			d.draw_rect(Rect2(5, y - 2, d.W - 10, 22), Color("#f8e8c0") if d._ui_tex("fondo") != null else Color("#e8f0f8"))
			d._text(Vector2(8, y), "▶", d.C_TEXT)
		var title := "%d. %s" % [i + 1, "— empty —" if empty else camp.deck_name(i)]
		if i == camp.active_deck:
			title = "★ " + title            # el que está en uso
		d._text_fit(Vector2(17, y), title, d.C_DIM if empty else d.C_TEXT, 170)
		if not empty:
			var errs: Array = camp.deck_errors(i)
			var cnt := "%d/60" % size
			d._text(Vector2(d.W - 9 - d._text_w(cnt), y), cnt, d.C_HP_OK.darkened(0.35) if errs.is_empty() else d.C_HP_LOW)
			d._text_fit(Vector2(17, y + 10), "Ready to play." if errs.is_empty() else str(errs[0]), d.C_DIM, d.W - 30)
	# Menú de opciones del mazo elegido
	if camp_menu >= 0 and screen == "camp_list":
		var w := 0.0
		for o in CAMP_OPTIONS:
			w = maxf(w, d._text_w(o))
		var r := Rect2(d.W - w - 34, 24, w + 30, 10 + CAMP_OPTIONS.size() * 12)
		d._frame(r)
		for j in CAMP_OPTIONS.size():
			var oy := r.position.y + 5 + j * 12
			if j == camp_menu:
				d._text(Vector2(r.position.x + 6, oy), "▶", d.C_TEXT)
			var col: Color = d.C_TEXT
			if CAMP_OPTIONS[j] == "Clear" and confirm_delete:
				col = d.C_HP_LOW
			d._text(Vector2(r.position.x + 15, oy), CAMP_OPTIONS[j], col)
	# Cuadro de abajo
	d._frame(Rect2(0, 118, d.W, 42))
	if screen == "rename":
		d._text(Vector2(9, 122), "Deck name (Enter saves · Esc cancels):", d.C_TEXT)
		var blink := "_" if int(Time.get_ticks_msec() / 400) % 2 == 0 else " "
		d._text(Vector2(9, 135), typed + blink, Color("#c03028"))
		return
	var info := msg
	if info == "":
		info = "The deck marked ★ is the one you take to duels. All decks share your collection."
	if confirm_delete:
		info = "Clear this deck? Choose Clear again to confirm."
	d._text_scroll(Vector2(9, 122), info, d.C_HP_LOW if confirm_delete else d.C_TEXT, 222, "campdk%d" % cursor)
	var keys := "▲▼ choose · Z options · X back to the map" if camp_menu < 0 else "▲▼ choose · Z accept · X close"
	d._text_scroll(Vector2(9, 140), keys, d.C_DIM, 222, "campdkk")


func _draw_list() -> void:
	d._frame(Rect2(0, 0, d.W, 22))
	d._text(Vector2(9, 5), "DECK EDITOR", d.C_TEXT)
	d._text(Vector2(d.W - 9 - d._text_w("Saved automatically"), 5), "Saved automatically", d.C_DIM)
	d._frame(Rect2(0, 20, d.W, 100))
	var rows := _list_rows()
	var presets := Decks.names()
	var top := clampi(cursor - 7, 0, maxi(0, rows.size() - 8))
	for i in range(top, mini(top + 8, rows.size())):
		var y := 25 + (i - top) * 11
		var row: Dictionary = rows[i]
		var sel := i == cursor
		if sel:
			d._text(Vector2(8, y), "▶", d.C_TEXT)
		match row["kind"]:
			"deck":
				var n: String = row["name"]
				var deck := Decks.get_deck(n)
				var ok := Game.validate_deck(deck).is_empty()
				if sel:
					d._text_scroll(Vector2(17, y), "★ " + n, d.C_TEXT, 170, "edl")
				else:
					d._text_fit(Vector2(17, y), "★ " + n, d.C_TEXT, 170)
				var cnt := "%d/60" % deck.size()
				d._text(Vector2(d.W - 9 - d._text_w(cnt), y), cnt, d.C_HP_OK.darkened(0.35) if ok else d.C_HP_LOW)
			"new":
				d._text(Vector2(17, y), "+ New deck (empty)", Color("#c03028") if sel else d.C_TEXT)
			"copy":
				var src: String = presets[copy_from] if not presets.is_empty() else ""
				d._text(Vector2(17, y), "+ Copy:", Color("#c03028") if sel else d.C_TEXT)
				d._text_fit(Vector2(66, y), ("◀ " if sel else "") + src + (" ▶" if sel else ""), d.C_TEXT, 166)
	# Cuadro de abajo
	d._frame(Rect2(0, 118, d.W, 42))
	var x := 9.0
	if screen == "rename":
		d._text(Vector2(x, 122), "Deck name (Enter saves · Esc cancels):", d.C_TEXT)
		var blink := "_" if int(Time.get_ticks_msec() / 400) % 2 == 0 else " "
		d._text(Vector2(x, 135), typed + blink, Color("#c03028"))
		if msg != "":
			d._text_fit(Vector2(120, 135), msg, d.C_HP_LOW, 112)
		return
	var row: Dictionary = rows[cursor] if cursor < rows.size() else {}
	var info := ""
	match row.get("kind", ""):
		"deck":
			var errs := Game.validate_deck(Decks.get_deck(row["name"]))
			info = ("Ready to play. Formats: " + legal_formats(Decks.get_deck(row["name"]))) if errs.is_empty() else errs[0]
		"new":
			info = "Starts a deck from scratch."
		"copy":
			info = Decks.description(presets[copy_from]) if not presets.is_empty() else ""
	d._text_scroll(Vector2(x, 122), info, d.C_TEXT, 222, "edlist%d" % cursor)
	var keys := "Z edit · R rename · D delete · X back"
	if row.get("kind", "") == "copy":
		keys = "◀▶ choose deck · Z copy · X back"
	elif row.get("kind", "") == "new":
		keys = "Z create · X back"
	if confirm_delete:
		keys = "Delete this deck? Press D again to confirm"
	d._text_scroll(Vector2(x, 140), keys, d.C_HP_LOW if confirm_delete else d.C_DIM, 222, "edkeys")


func _draw_edit() -> void:
	var total := _total()
	var deck := _deck_array()
	var errs := Game.validate_deck(deck)
	# Encabezado: nombre, búsqueda y cantidad
	d._frame(Rect2(0, 0, d.W, 22))
	d._text_fit(Vector2(9, 5), "★ " + deck_name, d.C_TEXT, 110 if (search != "" or searching) else 180)
	if search != "" or searching:
		d._text_fit(Vector2(122, 5), "Search: " + search + ("_" if searching else ""), Color("#c03028") if searching else d.C_DIM, 74)
	var cnt := "%d/60" % total
	d._text(Vector2(d.W - 9 - d._text_w(cnt), 5), cnt,
			d.C_HP_OK.darkened(0.35) if errs.is_empty() else (d.C_TEXT if total < 60 else d.C_HP_LOW))
	# Pestañas (como carpetas)
	var x := 2.0
	for i in TABS.size():
		var label: String = TABS[i]
		if i == 0:
			label += " (%d)" % total
		var w: float = d._text_w(label) + 10
		var r := Rect2(x, 21, w, 13)
		d.draw_rect(r, d.C_FRAME_OUT)
		d.draw_rect(r.grow(-1), d.C_PANEL if i == tab else d.C_FRAME_MID)
		d._text(Vector2(x + 5, 22), label, d.C_TEXT if i == tab else d.C_LIGHT)
		x += w + 1
	# Lista de cartas
	var cards := _tab_cards()
	var list := Rect2(0, 33, 172, 86)
	d._frame(list)
	var list_w := list.size.x
	for i in range(scroll, mini(scroll + ROWS, cards.size())):
		var id: String = cards[i]
		var y := LIST_Y + (i - scroll) * ROW_H
		var sel := i == cursor
		if sel:
			d.draw_rect(Rect2(4, y - 1, list_w - 8, ROW_H), Color("#d8e4f8"))
		d.draw_rect(Rect2(7, y + 2, 7, 7), d.C_INK)
		d.draw_rect(Rect2(8, y + 3, 5, 5), d._card_chip_color(id))
		var n: int = counts.get(id, 0)
		var name_w := list_w - 17 - 74
		if sel:
			d._text_scroll(Vector2(17, y), CardDB.card_name(id), d.C_TEXT, name_w, "ed_card")
		else:
			d._text_fit(Vector2(17, y), CardDB.card_name(id), d.C_TEXT, name_w)
		d._text(Vector2(list_w - 62, y), id, d.C_DIM)
		if camp != null and not CardDB.is_basic_energy(id):
			# En la campaña: en el mazo / las que tenés
			var own := "%d/%d" % [n, camp.owned(id)]
			d._text(Vector2(list_w - 8 - d._text_w(own), y), own, Color("#c03028") if n > 0 else d.C_DIM)
			if camp.reverse.get(id, 0) > 0:      # tenés alguna reverse holo
				var hue := fmod(Time.get_ticks_msec() / 1500.0 + i * 0.1, 1.0)
				d._text(Vector2(list_w - 70, y), "R", Color.from_hsv(hue, 0.75, 0.85))
		elif n > 0:
			d._text(Vector2(list_w - 21, y), "×%d" % n, Color("#c03028"))
	if cards.is_empty():
		d._text_fit(Vector2(9, LIST_Y), "The deck is empty: Tab switches tabs." if tab == 0 else "Nothing matches the search.", d.C_DIM, list_w - 18)
	if scroll > 0:
		d._text(Vector2(list_w - 12, LIST_Y - 3), "▲", d.C_DIM)
	if scroll + ROWS < cards.size():
		d._text(Vector2(list_w - 12, LIST_Y + (ROWS - 1) * ROW_H + 2), "▼", d.C_DIM)
	# Imagen de la carta y resumen del mazo
	var side := Rect2(170, 33, d.W - 170, 86)
	d._frame(side)
	var id_sel: String = cards[cursor] if cursor < cards.size() else ""
	if id_sel != "":
		d._draw_card_image(Rect2(side.position.x + (side.size.x - d.MENU_IMG) / 2.0, 38, d.MENU_IMG, d.MENU_IMG), id_sel,
				camp != null and camp.reverse.get(id_sel, 0) > 0)
	var np := 0
	var nt := 0
	var ne := 0
	for id in counts:
		if CardDB.is_pokemon(id):
			np += counts[id]
		elif CardDB.is_energy(id):
			ne += counts[id]
		else:
			nt += counts[id]
	var rows := [["Pokém.", np], ["Trainer", nt], ["Energy", ne]]
	for j in 3:
		var yy := 81 + j * 11
		d._text(Vector2(side.position.x + 7, yy), rows[j][0], d.C_DIM)
		var v := str(rows[j][1])
		d._text(Vector2(side.end.x - 7 - d._text_w(v), yy), v, d.C_TEXT)
	# Cuadro de abajo
	d._frame(Rect2(0, 117, d.W, 43))
	if id_sel != "":
		var line: String = d._card_kind(id_sel)
		if CardDB.is_pokemon(id_sel):
			line += " · HP %d · %s" % [CardDB.hp(id_sel), "/".join(CardDB.types(id_sel).map(func(t): return d.TYPE_ES.get(t, t)))]
			if CardDB.evolves_from(id_sel) != "":
				line += " · evolves from " + CardDB.evolves_from(id_sel)
		line += " · " + CardDB.get_card(id_sel).get("set", "")
		d._text_scroll(Vector2(9, 121), line, d.C_TEXT, 222, "ed_info")
	var status := msg
	if status == "":
		status = "Valid deck: ready to use." if errs.is_empty() else errs[0]
	d._text_fit(Vector2(9, 132), status, d.C_HP_LOW if msg != "" or not errs.is_empty() else d.C_HP_OK.darkened(0.35), 222)
	d._text_scroll(Vector2(9, 143), ("Name, code (ex2, ecard1-33) or set · Enter done · Esc clear" if searching else "◀▶ remove/add · Tab tab · F search · C card · X done"), d.C_DIM, 222, "ed_keys")


## En qué temporadas se puede jugar el mazo ("2003-04 · 2004-05", o "none").
static func legal_formats(deck: Array) -> String:
	var out: Array = []
	for i in RuleSet.SEASONS.size():
		if RuleSet.from_season(i).illegal_cards(deck).is_empty():
			out.append(RuleSet.SEASONS[i]["id"])
	return " · ".join(out) if not out.is_empty() else "none"
