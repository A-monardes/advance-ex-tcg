
extends RefCounted
## Editor de mazos. Lo dibuja y le pasa las teclas la pantalla de duelo (duel.gd),
## que tiene los ayudantes de texto e imágenes.
##
## Pantallas:
##   "list"   tus mazos + crear uno vacío + copiar uno existente
##   "edit"   pestañas Mazo / Pokémon / Entrenadores / Energías; ←→ quita/agrega copias
##   "rename" escribir el nombre del mazo con el teclado

const TABS := ["Deck", "Pokémon", "Trainers", "Energy"]
const ROWS := 9             # filas visibles en las listas
const LIST_Y := 32
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
var editing_preset := false # editando un mazo de los rivales de la campaña (se guarda en data/decks.json)
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
	_tab_memo_key = []
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
	_tab_memo_key = []
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
	# Los mazos de los rivales de la campaña, solo corriendo el juego desde Godot (se guardan en
	# data/decks.json; en la web ese archivo no se puede cambiar)
	if Decks.presets_editable():
		for n in Decks.campaign_names():
			rows.append({"kind": "preset", "name": n})
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


## El catálogo tiene más de 2000 cartas: el orden, la lista de cada pestaña y la validación
## del mazo se calculan una vez y se guardan (antes se rehacían en cada cuadro).
static var _sort_keys := {}
var _tab_memo_key := []
var _tab_memo: Array = []
var _deck_memo := {}       # hash del mazo -> {"errs": [...], "formats": "..."}


func _deck_info(deck: Array) -> Dictionary:
	var h := deck.hash()
	if not _deck_memo.has(h):
		if _deck_memo.size() > 64:
			_deck_memo.clear()
		var errs := Game.validate_deck(deck)
		_deck_memo[h] = {"errs": errs, "formats": legal_formats(deck) if errs.is_empty() else ""}
	return _deck_memo[h]


func _sort_key(id: String) -> String:
	if _sort_keys.has(id):
		return _sort_keys[id]
	var k := _make_sort_key(id)
	_sort_keys[id] = k
	return k


func _make_sort_key(id: String) -> String:
	var cat := 0 if CardDB.is_pokemon(id) else (2 if CardDB.is_energy(id) else 1)
	var parts := id.split("-")
	return "%d|%02d|%04d" % [cat, _set_rank(parts[0]), int(parts[1]) if parts.size() > 1 else 0]


## Orden de los sets: como salieron (ex1, ex2... ex16, POP, Black Star) y los e-card al
## final. (Antes se ordenaba como texto y "ex10" quedaba antes que "ex2".)
static var _set_order: Array = []

static func set_list() -> Array:
	if _set_order.is_empty():
		var ecard: Array = []
		for id in CardDB.all_ids():
			var st := CardDB.set_of(id)
			if st.begins_with("ecard"):
				if not ecard.has(st):
					ecard.append(st)
			elif not _set_order.has(st):
				_set_order.append(st)
		_set_order.append_array(ecard)
	return _set_order


static func _set_rank(st: String) -> int:
	var i := set_list().find(st)
	return i if i >= 0 else 99


func _tab_cards() -> Array:
	var key := [tab, search, _pool.size(), camp != null, counts.hash() if tab == 0 else 0, str(filters[tab]).hash(), family]
	if key == _tab_memo_key:
		return _tab_memo
	_tab_memo = _tab_cards_build()
	_tab_memo_key = key
	return _tab_memo


func _tab_cards_build() -> Array:
	var ids: Array = []
	if tab == 1 and not family.is_empty():
		return _family_cards()
	match tab:
		0:
			ids = counts.keys().filter(func(id): return counts[id] > 0)
		1:
			ids = _pool.filter(func(id): return CardDB.is_pokemon(id))
		2:
			ids = _pool.filter(func(id): return CardDB.is_trainer(id))
		3:
			ids = _pool.filter(func(id): return CardDB.is_energy(id))
			if "Holon's" in filters[3].get("ekind", []):
				ids += _pool.filter(func(id): return CardDB.is_holon_energy(id))
	if search != "":
		ids = ids.filter(func(id): return _matches(id, search))
	if tab > 0:
		var f: Dictionary = filters[tab]
		ids = ids.filter(func(id): return _passes(id, f))
		return _sort_by(ids, f.get("sort", 0))
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
	var n := CardDB.deck_name(CardDB.card_name(id))   # Charmander y Charmander δ (y Empoleon LV.X) cuentan juntos
	var t := 0
	for k in counts:
		if CardDB.deck_name(CardDB.card_name(k)) == n:
			t += counts[k]
	return t


func _add(id: String) -> void:
	msg = ""
	if _total() >= 60:
		msg = "The deck already has 60 cards."
		return
	if not CardDB.is_basic_energy(id) and _copies_by_name(id) >= 4:
		msg = "No more than 4 copies of %s." % CardDB.deck_name(CardDB.card_name(id))
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
	if editing_preset:
		if not Decks.save_preset(deck_name, _entries()):
			msg = "Could not save the campaign deck."
		return
	Decks.save_user(deck_name, _entries())


func _start_edit(name: String, preset := false) -> void:
	editing_preset = preset
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
			"preset":
				_start_edit(row["name"], true)
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
	if fpanel:
		_filter_input(k, event.echo)
		return
	if not family.is_empty() and k in [KEY_X, KEY_ESCAPE] and not event.echo:
		family = []              # X sale de la familia y vuelve a la lista entera
		cursor = 0
		scroll = 0
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
			family = []
		KEY_C:
			if id != "" and not event.echo:
				var tab_list := _tab_cards()
				var entries: Array = []
				for cid in tab_list:
					var c2: String = cid
					entries.append(func(): return d.fichas._card_lines(c2, null))
				d.fichas._open_info(entries, cursor, func(j: int):
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
		KEY_V:
			if not event.echo and tab > 0:
				fpanel = true
				frow = 0
				fcol = 0
				family = []
				d.snd.play("ok")
			elif not event.echo:
				msg = "Filters work in the Pokémon, Trainers and Energy tabs."
		KEY_G:
			if not event.echo:
				if not family.is_empty():
					family = []
					cursor = 0
					scroll = 0
				elif id != "" and CardDB.is_pokemon(id):
					_open_family(id)
				else:
					msg = "G shows the evolution family of a Pokémon."
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

const PB_PURPLE := [Color("#a070d8"), Color("#8858c0")]


## Encabezado: franja amarilla a rayas con una línea negra abajo (estilo Pinball).
func _head(r: Rect2) -> void:
	for y in int(r.size.y):
		d.draw_rect(Rect2(r.position.x, r.position.y + y, r.size.x, 1), d.titulo.PB_YELLOW[(y / 2) % 2])
	d.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), d.titulo.PB_INK)


## Caja blanca a rayitas de Pinball (un píxel más adentro, para que se vean las rayas del fondo).
func _box(r: Rect2) -> void:
	d.titulo._pb_box(r.grow(-1))


## Ventanita encima de lo demás: la misma caja con borde negro.
func _popup(r: Rect2) -> void:
	d.draw_rect(r, d.titulo.PB_INK)
	d.titulo._pb_box(r.grow(-1))

func draw() -> void:
	# Fondo a rayas violetas, al estilo de los menús de Pokémon Pinball (ver duel_titulo.gd)
	d.titulo._pb_bg(PB_PURPLE)
	d.draw_rect(Rect2(0, 147, d.W, 13), d.titulo.PB_INK)     # la ayuda de abajo va sobre negro
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
	_head(Rect2(0, 0, d.W, 22))
	d._text(Vector2(9, 5), "YOUR DECKS", d.C_TEXT)
	var cash := "₽%d" % camp.money
	d._text(Vector2(d.W - 9 - d._text_w(cash), 5), cash, d.C_DIM)
	_box(Rect2(0, 20, d.W, 100))
	for i: int in camp.DECK_SLOTS:
		var y: int = 25 + i * 23
		var sel: bool = i == cursor
		var size: int = camp.deck_size(i)
		var empty: bool = size == 0 and str(camp.decks[i]["nombre"]) == ""
		d._stripe(Rect2(5, y - 2, d.W - 10, 22), i)
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
		_popup(r)
		for j in CAMP_OPTIONS.size():
			var oy := r.position.y + 5 + j * 12
			d._stripe(Rect2(r.position.x + 3, oy - 1, r.size.x - 6, 12), j)
			if j == camp_menu:
				d._text(Vector2(r.position.x + 6, oy), "▶", d.C_TEXT)
			var col: Color = d.C_TEXT
			if CAMP_OPTIONS[j] == "Clear" and confirm_delete:
				col = d.C_HP_LOW
			d._text(Vector2(r.position.x + 15, oy), CAMP_OPTIONS[j], col)
	# Cuadro de abajo
	_box(Rect2(0, 118, d.W, 42))
	if screen == "rename":
		d._text(Vector2(9, 122), "Deck name (Enter saves · Esc cancels):", d.C_TEXT)
		var blink := "_" if int(Clock.ms() / 400) % 2 == 0 else " "
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


## Colores de la barra de composición del mazo: Pokémon, Entrenadores y Energías.
const C_BAR := [Color("#58b048"), Color("#e8b030"), Color("#5080d8")]
const C_OK := Color("#388850")
const C_CAMP := Color("#7048a8")      # mazos de los rivales de la campaña


## [Pokémon, Entrenadores, Energías] de una lista de cartas.
static func composition(deck: Array) -> Array:
	var out := [0, 0, 0]
	for id in deck:
		if CardDB.is_pokemon(id):
			out[0] += 1
		elif CardDB.is_energy(id):
			out[2] += 1
		else:
			out[1] += 1
	return out


## Los Mundiales en que se puede jugar el mazo: ["2004", "2005"...] (solo las cartas legales).
static func legal_worlds(deck: Array) -> Array:
	var out: Array = []
	for i in RuleSet.SEASONS.size():
		if RuleSet.from_season(i).illegal_cards(deck).is_empty():
			out.append(str(RuleSet.SEASONS[i]["worlds"]).right(4))
	return out


## Barra de tres colores con la composición (y los números al lado si `nums`).
func _comp_bar(p: Vector2, w: float, comp: Array, nums: bool) -> void:
	var tot: int = comp[0] + comp[1] + comp[2]
	d.draw_rect(Rect2(p - Vector2(1, 1), Vector2(w + 2, 6)), d.C_INK)
	d.draw_rect(Rect2(p, Vector2(w, 4)), d.C_FRAME_MID)
	if tot == 0:
		if nums:
			d.imagenes._draw_tiny(p + Vector2(w + 5, 0), "0 0 0", d.C_INK)
		return
	var x := p.x
	for k in 3:
		var ww := roundf(w * comp[k] / tot) if k < 2 else p.x + w - x
		if ww > 0:
			d.draw_rect(Rect2(x, p.y, ww, 4), C_BAR[k])
		x += ww
	if nums:
		d.imagenes._draw_tiny(p + Vector2(w + 5, 0), "%d %d %d" % comp, d.C_INK)


## El panel de la derecha de la lista de mazos: carta, cantidad, en qué Mundiales es legal,
## composición y descripción.
func _draw_deck_panel(r: Rect2, deck_name_shown: String, deck: Array, desc: String) -> void:
	var cover: String = d.titulo._deck_cover(deck_name_shown) if deck_name_shown != "" else ""
	var ir := Rect2(r.position.x + 6, r.position.y + 6, 40, 40)
	d.draw_rect(ir.grow(1), d.C_INK)
	if cover != "":
		d.imagenes._draw_card_image(ir, cover)
	var tx := ir.end.x + 5
	d._text_fit(Vector2(tx, r.position.y + 5), deck_name_shown, d.C_TEXT, r.end.x - tx - 4)
	var info := _deck_info(deck)
	var cnt := "%d/60" % deck.size()
	d._text(Vector2(tx, r.position.y + 16), cnt, C_OK if info["errs"].is_empty() else d.C_HP_LOW)
	var worlds := legal_worlds(deck)
	if info["errs"].is_empty() and not worlds.is_empty():
		# "LEGAL" y abajo los Mundiales donde se puede jugar, de a dos años por renglón
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 28), "LEGAL", C_OK)
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 35), "WORLDS", C_OK)
		for k in worlds.size():
			d.imagenes._draw_tiny(Vector2(tx + (k % 2) * 20, r.position.y + 42 + (k / 2) * 7), str(worlds[k]), C_OK)
	elif not info["errs"].is_empty():
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 28), "NOT LEGAL", d.C_HP_LOW)
	else:
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 28), "NOT LEGAL", d.C_HP_LOW)
		d.imagenes._draw_tiny(Vector2(tx, r.position.y + 35), "ANY WORLDS", d.C_HP_LOW)
	var comp := composition(deck)
	var by := r.position.y + 66
	_comp_bar(Vector2(r.position.x + 6, by), r.size.x - 12, comp, false)
	var labels := ["POKEMON %d" % comp[0], "TRAINER %d" % comp[1], "ENERGY %d" % comp[2]]
	for k in 3:
		d.imagenes._draw_tiny(Vector2(r.position.x + 6, by + 7 + k * 7), labels[k], C_BAR[k].darkened(0.2))
	var dl: Array = d._wrap(desc, r.size.x - 12)
	for k in mini(dl.size(), 3):
		d._text(Vector2(r.position.x + 6, by + 29 + k * 10), str(dl[k]), d.C_DIM)


func _draw_list() -> void:
	var r: RuleSet = d.format_rules()
	_head(Rect2(0, 0, d.W, 18))
	d._text(Vector2(8, 4), "DECK EDITOR", d.C_TEXT)
	var fmt := "Format: " + (str(RuleSet.SEASONS[d.season_idx]["worlds"]) if d.format_upto < 0 else "Custom " + str(RuleSet.SEASONS[d.season_idx]["id"]))
	d._text(Vector2(d.W - 8 - d._text_w(fmt), 4), fmt, d.C_DIM)
	var left := Rect2(0, 16, 132, 132)
	_box(left)
	var rows := _list_rows()
	var presets := Decks.names()
	var vis := 10
	var top := clampi(cursor - vis + 1, 0, maxi(0, rows.size() - vis))
	for i in range(top, mini(top + vis, rows.size())):
		var y := 21 + (i - top) * 12
		var row: Dictionary = rows[i]
		var sel := i == cursor
		var rr := Rect2(4, y - 1, left.size.x - 8, 12)
		d._stripe(rr, i)
		if sel:
			d.draw_rect(rr, Color("#d8e4f8"))
			d._text(Vector2(6, y), "▶", d.C_TEXT)
		match row["kind"]:
			"deck":
				var n: String = row["name"]
				var deck := Decks.get_deck(n)
				var ok: bool = _deck_info(deck)["errs"].is_empty() and r.illegal_cards(deck).is_empty()
				if sel:
					d._text_scroll(Vector2(15, y), "★ " + n, d.C_TEXT, left.size.x - 32, "edl")
				else:
					d._text_fit(Vector2(15, y), "★ " + n, d.C_TEXT, left.size.x - 32)
				# Puntito: verde si se puede jugar en el formato actual, rojo si no
				d.draw_circle(Vector2(left.end.x - 11, y + 5), 3.0, d.C_INK)
				d.draw_circle(Vector2(left.end.x - 11, y + 5), 2.0, C_OK if ok else d.C_HP_LOW)
			"preset":
				var pn: String = row["name"]
				if sel:
					d._text_scroll(Vector2(15, y), "⚑ " + pn, C_CAMP, left.size.x - 32, "edl")
				else:
					d._text_fit(Vector2(15, y), "⚑ " + pn, C_CAMP, left.size.x - 32)
			"new":
				d._text(Vector2(15, y), "+ New deck", Color("#c03028") if sel else d.C_TEXT)
			"copy":
				var src: String = presets[copy_from] if not presets.is_empty() else ""
				d._text(Vector2(15, y), "+ Copy", Color("#c03028") if sel else d.C_TEXT)
				d._text_fit(Vector2(52, y), ("◀ " + src + " ▶") if sel else src, d.C_TEXT, left.size.x - 58)
	if top > 0:
		d._text(Vector2(left.end.x - 13, 18), "▲", d.C_DIM)
	if top + vis < rows.size():
		d._text(Vector2(left.end.x - 13, 21 + (vis - 1) * 12), "▼", d.C_DIM)
	# Derecha: el mazo elegido
	var right := Rect2(130, 16, d.W - 130, 132)
	_box(right)
	var row: Dictionary = rows[cursor] if cursor < rows.size() else {}
	match row.get("kind", ""):
		"deck", "preset":
			_draw_deck_panel(right, row["name"], Decks.get_deck(row["name"]), Decks.description(row["name"]))
		"copy":
			if not presets.is_empty():
				var pn: String = presets[copy_from]
				_draw_deck_panel(right, pn, Decks.get_deck(pn), Decks.description(pn))
		"new":
			d._text_wrap(Vector2(right.position.x + 6, right.position.y + 6), "Starts a deck from scratch.", right.size.x - 12, d.C_DIM)
	if screen == "rename":
		# Ventana para escribir el nombre
		var w := Rect2(20, 58, d.W - 40, 40)
		d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.35))
		_popup(w)
		d._text(Vector2(w.position.x + 8, w.position.y + 5), "Deck name (Enter saves · Esc cancels):", d.C_DIM)
		var blink := "_" if int(Clock.ms() / 400) % 2 == 0 else " "
		d._text(Vector2(w.position.x + 8, w.position.y + 18), typed + blink, Color("#c03028"))
		if msg != "":
			d._text_fit(Vector2(w.position.x + 8, w.position.y + 28), msg, d.C_HP_LOW, w.size.x - 16)
		return
	var keys := "▲▼ choose · Z edit · R rename · D delete · X back"
	if row.get("kind", "") == "copy":
		keys = "◀▶ choose deck · Z copy · X back"
	elif row.get("kind", "") == "new":
		keys = "Z create · X back"
	elif row.get("kind", "") == "preset":
		keys = "Z edit this campaign rival's deck · X back"
	if confirm_delete:
		keys = "Delete this deck? Press D again to confirm"
	d._text_scroll(Vector2(6, 150), keys, d.C_HP_LOW if confirm_delete else d.C_LIGHT, 228, "edkeys")


func _draw_edit() -> void:
	var total := _total()
	var deck := _deck_array()
	var errs: Array = _deck_info(deck)["errs"]
	# Arriba: nombre, cantidad y la composición siempre a la vista
	_head(Rect2(0, 0, d.W, 18))
	d._text_fit(Vector2(8, 4), ("⚑ " if editing_preset else "★ ") + deck_name, C_CAMP if editing_preset else d.C_TEXT, 84)
	var cnt := "%d/60" % total
	d._text(Vector2(94, 4), cnt, C_OK if errs.is_empty() else (d.C_TEXT if total < 60 else d.C_HP_LOW))
	_comp_bar(Vector2(126, 7), 58, composition(deck), true)
	# Pestañas y el buscador (F)
	var x := 2.0
	for i in TABS.size():
		var label: String = TABS[i] if i != 2 else "Trainer"
		var w: float = d._text_w(label) + 8
		var r := Rect2(x, 16, w, 13)
		d.draw_rect(r, d.titulo.PB_INK)
		d.draw_rect(r.grow(-1), d.titulo.PB_YELLOW[0] if i == tab else Color("#e0e0e0"))
		d._text(Vector2(x + 4, 17), label, d.titulo.PB_INK if i == tab else d.C_DIM)
		x += w + 1
	var sbox := Rect2(x + 2, 17, d.W - x - 4, 11)
	d.draw_rect(sbox, d.C_INK)
	d.draw_rect(sbox.grow(-1), d.C_PANEL)
	if searching or search != "":
		d._text_fit(Vector2(sbox.position.x + 3, 18), search + ("_" if searching else ""), Color("#c03028") if searching else d.C_TEXT, sbox.size.x - 6)
	else:
		d._text(Vector2(sbox.position.x + 3, 18), "F: search", d.C_DIM)
	# Lista de cartas
	var cards := _tab_cards()
	var list := Rect2(0, 28, 152, 98)
	_box(list)
	var list_w := list.size.x
	for i in range(scroll, mini(scroll + ROWS, cards.size())):
		var id: String = cards[i]
		var y := LIST_Y + (i - scroll) * ROW_H
		var sel := i == cursor
		d._stripe(Rect2(4, y - 1, list_w - 8, ROW_H), i)
		if sel:
			d.draw_rect(Rect2(4, y - 1, list_w - 8, ROW_H), Color("#d8e4f8"))
		d.draw_rect(Rect2(7, y + 2, 7, 7), d.C_INK)
		d.draw_rect(Rect2(8, y + 3, 5, 5), d.paneles._card_chip_color(id))
		var n: int = counts.get(id, 0)
		var name_w := list_w - 17 - 58
		if sel:
			d._text_scroll(Vector2(17, y), CardDB.card_name(id), d.C_TEXT, name_w, "ed_card")
		else:
			d._text_fit(Vector2(17, y), CardDB.card_name(id), d.C_TEXT, name_w)
		d.imagenes._draw_tiny(Vector2(list_w - 56, y + 2), id.to_upper(), d.C_DIM)
		if camp != null and not CardDB.is_basic_energy(id):
			# En la campaña: en el mazo / las que tenés
			var own := "%d/%d" % [n, camp.owned(id)]
			d._text(Vector2(list_w - 7 - d._text_w(own), y), own, Color("#c03028") if n > 0 else d.C_DIM)
			if camp.reverse.get(id, 0) > 0:      # tenés alguna reverse holo
				var hue := fmod(Clock.ms() / 1500.0 + i * 0.1, 1.0)
				d._text(Vector2(list_w - 64, y), "R", Color.from_hsv(hue, 0.75, 0.85))
		elif n > 0:
			d._text(Vector2(list_w - 20, y), "×%d" % n, Color("#c03028"))
	if cards.is_empty():
		d._text_fit(Vector2(9, LIST_Y), "The deck is empty: Tab switches tabs." if tab == 0 else "Nothing matches the search or filter.", d.C_DIM, list_w - 18)
	if scroll > 0:
		d._text(Vector2(list_w - 12, LIST_Y - 3), "▲", d.C_DIM)
	if scroll + ROWS < cards.size():
		d._text(Vector2(list_w - 12, LIST_Y + (ROWS - 1) * ROW_H + 2), "▼", d.C_DIM)
	# Derecha: la carta grande y sus datos en renglones cortos
	var side := Rect2(150, 28, d.W - 150, 98)
	_box(side)
	var id_sel: String = cards[cursor] if cursor < cards.size() else ""
	if id_sel != "":
		var isz := 56.0
		var ir := Rect2(side.position.x + (side.size.x - isz) / 2.0, side.position.y + 5, isz, isz)
		d.draw_rect(ir.grow(1), d.C_INK)
		d.imagenes._draw_card_image(ir, id_sel)     # sin reverse holo: el brillo queda para los duelos
		var ty := ir.end.y + 4
		d._text_fit(Vector2(side.position.x + 6, ty), d.paneles._card_kind(id_sel), d.C_TEXT, side.size.x - 10)
		if CardDB.is_pokemon(id_sel):
			var hp := "HP %d · %s" % [CardDB.hp(id_sel), "/".join(CardDB.types(id_sel).map(func(t): return d.TYPE_ES.get(t, t)))]
			d._text_fit(Vector2(side.position.x + 6, ty + 10), hp, d.C_DIM, side.size.x - 10)
			if CardDB.evolves_from(id_sel) != "":
				var ef := "FROM " + CardDB.evolves_from(id_sel).to_upper()
				if ef.length() * 4 > side.size.x - 10:
					ef = ef.left(int((side.size.x - 10) / 4) - 1) + "."
				d.imagenes._draw_tiny(Vector2(side.position.x + 6, ty + 22), ef, d.C_DIM)
	# Abajo: la carta (nombre · código · set) y si el mazo es válido
	_box(Rect2(0, 124, d.W, 24))
	if id_sel != "":
		var line := "%s · %s · %s" % [CardDB.card_name(id_sel), id_sel, CardDB.get_card(id_sel).get("set", "")]
		d._text_scroll(Vector2(6, 127), line, d.C_TEXT, 228, "ed_info")
	var status := msg
	if status == "":
		status = "Valid deck: ready to use." if errs.is_empty() else errs[0]
	d._text_fit(Vector2(6, 136), status, d.C_HP_LOW if msg != "" or not errs.is_empty() else C_OK, 228)
	var summary := _filter_summary()
	if searching:
		d._text_scroll(Vector2(6, 150), "Name, code (ex2, ecard1-33) or set · Enter done · Esc clear", d.C_LIGHT, 228, "ed_keys")
	elif summary != "":
		d._text_scroll(Vector2(6, 150), "%s  (%d)" % [summary, cards.size()], Color("#a8c8ff"), 228, "ed_filt")
	else:
		d._text_scroll(Vector2(6, 150), "◀▶ -/+ · Tab · F find · V filter · G family · C card · X done", d.C_LIGHT, 228, "ed_keys")
	if fpanel:
		_draw_filter_panel()


## En qué temporadas se puede jugar el mazo ("2003-04 · 2004-05", o "none").
static func legal_formats(deck: Array) -> String:
	var out: Array = []
	for i in RuleSet.SEASONS.size():
		if RuleSet.from_season(i).illegal_cards(deck).is_empty():
			out.append(RuleSet.SEASONS[i]["id"])
	return " · ".join(out) if not out.is_empty() else "none"


# ===========================================================================
# Filtros (V) y familia evolutiva (G)
# ===========================================================================
# Cada pestaña (Pokémon, Entrenadores, Energías) tiene su propio filtro. El panel se abre
# con V: filas de opciones que se prenden con Z (varias a la vez valen "cualquiera de"),
# filas que se giran con ◀▶ (temporada y expansión) y el orden de la lista.
# G sobre un Pokémon muestra toda su línea evolutiva, con todas sus versiones.

const C_FILTER := Color("#3868c8")
const POKE_TYPES := ["Grass", "Fire", "Water", "Lightning", "Psychic", "Fighting", "Darkness", "Metal", "Colorless"]
const STAGES := ["Basic", "Stage 1", "Stage 2", "ex", "LV.X", "δ", "★"]
const T_KINDS := ["Supporter", "Item", "Stadium", "Tool", "TM"]
const E_KINDS := ["Basic", "Special", "Holon's"]
## Qué hace un Entrenador, deducido de su texto (en minúsculas).
const DOES_RX := {
	"Draw": "\\bdraw",
	"Search": "search your (deck|discard)",
	"Energy": "energy card.*(from your discard|from your hand|to your hand|attach)|attach.*energy|move .*energy",
	"Switch": "switch",
	"Heal": "remove .*damage counter|heal",
	"Disrupt": "your opponent (shuffles|discards|reveals|can't)|opponent's hand|discard .*energy .*(defending|your opponent)|your opponent's .*(energy|prize|deck)",
}

var filters := [{}, {}, {}, {}]
var fpanel := false
var frow := 0
var fcol := 0
var family: Array = []           # nombres de la línea evolutiva que se está mirando (G)
var _rules_cache := {}
var _does_cache := {}
var _rx_cache := {}


## Filas del panel de la pestaña: key (dónde se guarda), label, opts, mode (multi / one / spin).
func _filter_rows(t: int) -> Array:
	var season := {"key": "season", "label": "Season", "mode": "spin"}
	var set_row := {"key": "set", "label": "Set", "mode": "spin"}
	match t:
		1:
			return [{"key": "type", "label": "Type", "opts": POKE_TYPES, "mode": "multi", "icons": true},
				{"key": "stage", "label": "Stage", "opts": STAGES.slice(0, 3), "mode": "multi"},
				{"key": "stage", "label": "", "opts": STAGES.slice(3), "mode": "multi"},
				season, set_row,
				{"key": "sort", "label": "Sort", "opts": ["Set", "Name", "HP", "Type"], "mode": "one"}]
		2:
			return [{"key": "kind", "label": "Kind", "opts": T_KINDS, "mode": "multi"},
				{"key": "does", "label": "Does", "opts": ["Draw", "Search", "Energy"], "mode": "multi"},
				{"key": "does", "label": "", "opts": ["Switch", "Heal", "Disrupt"], "mode": "multi"},
				season, set_row,
				{"key": "sort", "label": "Sort", "opts": ["Set", "Name", "Kind"], "mode": "one"}]
		3:
			return [{"key": "ekind", "label": "Kind", "opts": E_KINDS, "mode": "multi", "labels": ["Basic", "Special", "Holon's Pokémon"]},
				{"key": "gives", "label": "Gives", "opts": POKE_TYPES + ["Any"], "mode": "multi", "icons": true},
				season, set_row,
				{"key": "sort", "label": "Sort", "opts": ["Set", "Name", "Type"], "mode": "one"}]
	return []


func _spin_label(key: String, v: int) -> String:
	if v < 0:
		return "All"
	if key == "season":
		return str(RuleSet.SEASONS[v]["id"])
	var st: String = set_list()[v]
	for id in CardDB.all_ids():
		if CardDB.set_of(id) == st:
			return str(CardDB.get_card(id).get("set", st))
	return st


func _spin_count(key: String) -> int:
	return RuleSet.SEASONS.size() if key == "season" else set_list().size()


func _filter_input(k: int, echo: bool) -> void:
	var rows := _filter_rows(tab)
	var f: Dictionary = filters[tab]
	var row: Dictionary = rows[frow]
	var n: int = row.get("opts", []).size()
	var changed := false
	match k:
		KEY_UP:
			frow = (frow - 1 + rows.size()) % rows.size()
		KEY_DOWN:
			frow = (frow + 1) % rows.size()
		KEY_LEFT, KEY_RIGHT:
			var dir := -1 if k == KEY_LEFT else 1
			if row["mode"] == "spin":
				var cnt := _spin_count(row["key"])
				f[row["key"]] = (int(f.get(row["key"], -1)) + 1 + dir + cnt + 1) % (cnt + 1) - 1
				changed = true
			else:
				fcol = (fcol + dir + n) % n
		KEY_Z, KEY_ENTER, KEY_SPACE:
			if echo:
				return
			if row["mode"] == "multi":
				var arr: Array = f.get(row["key"], []).duplicate()
				var o: String = row["opts"][fcol]
				if arr.has(o):
					arr.erase(o)
				else:
					arr.append(o)
				f[row["key"]] = arr
				changed = true
			elif row["mode"] == "one":
				f["sort"] = fcol
				changed = true
		KEY_Y:
			if not echo:
				filters[tab] = {}
				changed = true
				d.snd.play("back")
		KEY_V, KEY_X, KEY_ESCAPE:
			if not echo:
				fpanel = false
				d.snd.play("back")
			return
	if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		d.snd.play("move")
	elif changed and k != KEY_Y:
		d.snd.play("ok")
	rows = _filter_rows(tab)
	fcol = clampi(fcol, 0, maxi(0, rows[frow].get("opts", []).size() - 1))
	if changed:
		cursor = 0
		scroll = 0


## Clase de Entrenador para el filtro.
func _t_kind(id: String) -> String:
	if CardDB.is_supporter(id):
		return "Supporter"
	if CardDB.is_stadium(id):
		return "Stadium"
	if CardDB.is_pokemon_tool(id):
		return "Tool"
	if CardDB.is_tm(id) or "Machine" in str(CardDB.get_card(id).get("subtypes", [])):
		return "TM"
	return "Item"


func _does(id: String) -> Array:
	if _does_cache.has(id):
		return _does_cache[id]
	var txt := str(CardDB.get_card(id).get("text", "")).to_lower()
	var out: Array = []
	for tag in DOES_RX:
		if not _rx_cache.has(tag):
			_rx_cache[tag] = RegEx.create_from_string(DOES_RX[tag])
		if _rx_cache[tag].search(txt) != null:
			out.append(tag)
	_does_cache[id] = out
	return out


## Tipos de Energía que da una carta de Energía (o un Pokémon Holon's unido como Energía).
func _gives(id: String) -> Array:
	var out: Array = []
	for u in Energy.units_of_card(id):
		for t in u:
			var name: String = "Any" if t == Energy.ANY else t
			if not out.has(name):
				out.append(name)
	return out


func _stage_tags(id: String) -> Array:
	var out: Array = [["Basic", "Stage 1", "Stage 2"][CardDB.stage(id)]]
	if CardDB.is_ex(id):
		out.append("ex")
	if CardDB.is_level_up(id):
		out.append("LV.X")
	if CardDB.is_delta(id):
		out.append("δ")
	if "★" in CardDB.card_name(id):
		out.append("★")
	return out


func _season_rules(i: int) -> RuleSet:
	if not _rules_cache.has(i):
		_rules_cache[i] = RuleSet.from_season(i)
	return _rules_cache[i]


func _any_in(a: Array, b: Array) -> bool:
	for x in a:
		if b.has(x):
			return true
	return false


func _passes(id: String, f: Dictionary) -> bool:
	if f.is_empty():
		return true
	var se := int(f.get("season", -1))
	if se >= 0 and not _season_rules(se).is_legal(id):
		return false
	var st := int(f.get("set", -1))
	if st >= 0 and CardDB.set_of(id) != set_list()[st]:
		return false
	match tab:
		1:
			if not f.get("type", []).is_empty() and not _any_in(CardDB.types(id), f["type"]):
				return false
			if not f.get("stage", []).is_empty() and not _any_in(_stage_tags(id), f["stage"]):
				return false
		2:
			if not f.get("kind", []).is_empty() and not f["kind"].has(_t_kind(id)):
				return false
			if not f.get("does", []).is_empty() and not _any_in(_does(id), f["does"]):
				return false
		3:
			var ek: Array = f.get("ekind", [])
			if not ek.is_empty():
				var kind := "Holon's" if CardDB.is_holon_energy(id) else ("Basic" if CardDB.is_basic_energy(id) else "Special")
				if not ek.has(kind):
					return false
			# Una Energía de cualquier tipo (Rainbow, Holon's Castform...) también da el tipo pedido
			var gv := _gives(id)
			if not f.get("gives", []).is_empty() and not _any_in(gv, f["gives"]) and not (gv.has("Any") and not f["gives"].is_empty()):
				return false
	return true


func _sort_by(ids: Array, mode: int) -> Array:
	var labels: Array = _filter_rows(tab).back().get("opts", ["Set"])
	var how: String = labels[mode] if mode < labels.size() else "Set"
	var arr := _sorted(ids)            # base: por set (desempata siempre igual)
	var pos := {}
	for i in arr.size():
		pos[arr[i]] = i
	match how:
		"Name":
			arr.sort_custom(func(a, b): return [CardDB.card_name(a), pos[a]] < [CardDB.card_name(b), pos[b]])
		"HP":
			arr.sort_custom(func(a, b): return [-CardDB.hp(a), pos[a]] < [-CardDB.hp(b), pos[b]])
		"Type":
			arr.sort_custom(func(a, b): return [_type_rank(a), pos[a]] < [_type_rank(b), pos[b]])
		"Kind":
			arr.sort_custom(func(a, b): return [T_KINDS.find(_t_kind(a)), pos[a]] < [T_KINDS.find(_t_kind(b)), pos[b]])
	return arr


func _type_rank(id: String) -> int:
	var t: Array = CardDB.types(id) if CardDB.is_pokemon(id) and not (tab == 3) else _gives(id)
	if t.is_empty():
		return 99
	var i := POKE_TYPES.find(t[0])
	return i if i >= 0 else 98


## Texto del filtro activo para el renglón de abajo ("" si no hay).
func _filter_summary() -> String:
	if tab == 1 and not family.is_empty():
		return "Family: " + " > ".join(family)
	if tab == 0:
		return ""
	var f: Dictionary = filters[tab]
	var parts: Array = []
	for key in ["type", "stage", "kind", "does", "ekind", "gives"]:
		var arr: Array = f.get(key, [])
		if not arr.is_empty():
			parts.append(", ".join(arr))
	for key in ["season", "set"]:
		if int(f.get(key, -1)) >= 0:
			parts.append(_spin_label(key, int(f[key])))
	if int(f.get("sort", 0)) > 0:
		parts.append("by " + str(_filter_rows(tab).back()["opts"][int(f["sort"])]).to_lower())
	return ("Filter: " + " · ".join(parts)) if not parts.is_empty() else ""


# --- Familia evolutiva ------------------------------------------------------

## Nombre "de especie" para unir versiones: sin δ y sin " ex" (Blaziken ex es de la familia de Blaziken).
static func _fam_name(n: String) -> String:
	return CardDB.deck_name(n).trim_suffix(" ex")


func _open_family(id: String) -> void:
	var parent := {}       # especie -> de qué evoluciona
	var children := {}     # especie -> [especies que evolucionan de ella]
	for c in _pool:
		if not CardDB.is_pokemon(c):
			continue
		var me := _fam_name(CardDB.card_name(c))
		var from := _fam_name(CardDB.evolves_from(c))
		if from == "" or from == me:
			continue
		if not parent.has(me):
			parent[me] = from
		if not children.has(from):
			children[from] = []
		if not children[from].has(me):
			children[from].append(me)
	var root := _fam_name(CardDB.card_name(id))
	for i in 5:
		if parent.has(root) and _pool.any(func(c): return CardDB.is_pokemon(c) and _fam_name(CardDB.card_name(c)) == parent[root]):
			root = parent[root]
	var names: Array = [root]
	var i := 0
	while i < names.size():
		for ch in children.get(names[i], []):
			if not names.has(ch):
				names.append(ch)
		i += 1
	family = names
	tab = 1
	var cards := _family_cards()
	cursor = maxi(0, cards.find(id))
	scroll = maxi(0, cursor - ROWS / 2)
	d.snd.play("ok")


func _family_cards() -> Array:
	var ids := _pool.filter(func(c): return CardDB.is_pokemon(c) and family.has(_fam_name(CardDB.card_name(c))))
	var arr := _sorted(ids)
	var pos := {}
	for i in arr.size():
		pos[arr[i]] = i
	arr.sort_custom(func(a, b): return [CardDB.stage(a), family.find(_fam_name(CardDB.card_name(a))), pos[a]] < [CardDB.stage(b), family.find(_fam_name(CardDB.card_name(b))), pos[b]])
	return arr


# --- Panel ------------------------------------------------------------------

func _draw_filter_panel() -> void:
	var r := Rect2(4, 22, d.W - 8, 134)
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.35))
	d.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), d.C_INK)
	d.draw_rect(r, Color("#f8f8e8"))
	d._outline(r, Color("#484850"))
	d.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 12)), C_FILTER)
	d._text(Vector2(r.position.x + 5, r.position.y + 1), "FILTER  (%s)" % TABS[tab], d.C_LIGHT)
	var rows := _filter_rows(tab)
	var f: Dictionary = filters[tab]
	var blink := int(Clock.ms() / 250) % 4 != 0
	var row_h := 16.0 if rows.size() <= 5 else 15.0
	for ri in rows.size():
		var row: Dictionary = rows[ri]
		var y := r.position.y + 18 + ri * row_h
		d._text(Vector2(r.position.x + 5, y + 1), row["label"], d.C_DIM)
		var x := r.position.x + 40
		var here := ri == frow
		match row["mode"]:
			"spin":
				var v := int(f.get(row["key"], -1))
				var lbl := "◀ %s ▶" % _spin_label(row["key"], v)
				var w: float = d._text_w(lbl) + 8
				var cr := Rect2(x, y - 1, w, 13)
				d.draw_rect(cr, C_FILTER if v >= 0 else Color("#e8e8e0"))
				d._outline(cr, Color("#484850"))
				d._text(Vector2(x + 4, y + 1), lbl, d.C_LIGHT if v >= 0 else d.C_TEXT)
				if here and blink:
					d._outline(cr.grow(2), d.C_ACCENT)
			_:
				var opts: Array = row["opts"]
				for oi in opts.size():
					var o: String = opts[oi]
					var on: bool = (f.get(row["key"], []).has(o)) if row["mode"] == "multi" else int(f.get("sort", 0)) == oi
					var cr: Rect2
					if row.get("icons", false):
						var c := Vector2(x + 7, y + 5)
						cr = Rect2(c - Vector2(9, 9), Vector2(18, 18))
						if on:
							d.draw_arc(c, 8.0, 0, TAU, 24, C_FILTER, 2.0)
						d.imagenes._draw_energy_icon(c, 12, Energy.ANY if o == "Any" else o)
						x += 18
					else:
						var lbl: String = row.get("labels", opts)[oi]
						var w: float = d._text_w(lbl) + 7
						cr = Rect2(x, y - 1, w, 13)
						d.draw_rect(cr, C_FILTER if on else Color("#e8e8e0"))
						d._outline(cr, Color("#484850"))
						d._text(Vector2(x + 3, y + 1), lbl, d.C_LIGHT if on else d.C_TEXT)
						x += w + 4
					if here and oi == fcol and blink:
						d._outline(cr.grow(2), d.C_ACCENT)
	d._text_fit(Vector2(r.position.x + 5, r.end.y - 13), "Z on/off · ◀▶ change · Y clear all · V done", d.C_DIM, r.size.x - 10)
