extends RefCounted
## Pantallas de la campaña. Las dibuja y les pasa las teclas la pantalla de duelo (duel.gd),
## que tiene los ayudantes de texto, marcos e imágenes. El estado está en
## engine/campaign_state.gd y los datos (rivales, mazos iniciales) en data/campana.json.
##
## Pantallas:
##   "intro"   la presentación del Profesor Birch (scenes/intro_scene.gd, guion en data/intro.json)
##   "name"    elegir tu nombre de entrenador (campaña nueva)
##   "new"     elegir el mazo inicial
##   "world"   el mapa caminable (scenes/overworld.gd, mapas en data/mapas/)
##   "packs"   abrir los sobres ganados o comprados
##   "shop"    la tienda de cartas (scenes/card_shop.gd)

const CampaignState := preload("res://engine/campaign_state.gd")
const OverworldScript := preload("res://scenes/overworld.gd")
const ShopScript := preload("res://scenes/card_shop.gd")
const IntroScript := preload("res://scenes/intro_scene.gd")
const SET_NAMES := {"ex1": "Ruby & Sapphire", "ex2": "Sandstorm", "ex3": "Dragon",
		"ex4": "Team Magma vs Team Aqua", "ex5": "Hidden Legends"}
const RARITY_ES := {"Common": "Common", "Uncommon": "Uncommon", "Rare": "Rare", "Rare Holo": "Rare Holo",
		"Rare Holo EX": "Rare Holo ex", "Rare Secret": "Secret Rare"}
const REVEAL_TIME := 0.22      # segundos por carta al abrir un sobre
const PACK_ANIM := 1.6         # segundos de la animación del sobre abriéndose
const PACK_COLORS := {"ex1": Color("#c83838"), "ex2": Color("#c89838"), "ex3": Color("#3878c8"),
		"ex4": Color("#7848a8"), "ex5": Color("#507868")}
const NAME_MAX := 10
const NAME_ROWS := ["ABCDEFGHIJ", "KLMNOPQRST", "UVWXYZ.-!?", "abcdefghij", "klmnopqrst", "uvwxyz '&,"]

var d                          # la pantalla de duelo
var st: CampaignState
var screen := "name"
var cursor := 0
var rival_id := ""
var reward := {}
var packs: Array = []          # cartas de cada sobre ganado
var pack_i := 0
var reveal := 0.0
var pack_new := {}             # cartas que no tenías antes de abrir el sobre
var pack_t := 9.0              # tiempo de la animación del sobre (>= PACK_ANIM: ya abierto)
var pack_cursor := 0           # carta marcada del sobre abierto (con todas a la vista)
var _pack_art := {}            # imágenes de los sobres (mundo/propios/sobre_<set>[_grande].png)
var world                      # mapa caminable (scenes/overworld.gd)
var shop                       # tienda de cartas (scenes/card_shop.gd)
var after_packs := "world"     # adónde se vuelve después de abrir los sobres
var name_buf := ""
var name_cursor := Vector2i.ZERO
var intro                      # presentación del Profesor Birch (scenes/intro_scene.gd)
var from_intro := false        # la pantalla de nombre o de mazo la abrió la presentación


func _init(duel) -> void:
	d = duel
	st = CampaignState.new()
	world = OverworldScript.new(duel, self)
	shop = ShopScript.new(duel, self)
	intro = IntroScript.new(duel, self)


## Desde el título: si hay partida guardada, seguís donde estabas; si no, nombre y mazo.
func open() -> void:
	cursor = 0
	if st.load_save():
		_enter_place(st.start_place())
	else:
		name_buf = ""
		name_cursor = Vector2i.ZERO
		from_intro = true
		screen = "intro"
		intro.start()


## La presentación pide el nombre o el mazo: se usan las pantallas de siempre.
func open_name_from_intro() -> void:
	name_cursor = Vector2i.ZERO
	screen = "name"


func open_starter_from_intro() -> void:
	cursor = 0
	screen = "new"


## Terminó la presentación: empieza la campaña.
func intro_done() -> void:
	from_intro = false
	if st.player_name == "":            # por si el guion no pidió mazo
		st.start(0, name_buf if name_buf != "" else "Trainer")
	_enter_place(st.data.get("inicio", {"mapa": "escuela"}))


## Reemplaza {nombre} por tu nombre de entrenador y {inicial} por el tipo de tu mazo
## inicial ("Fire", "Water" o "Grass").
func fmt(text: String) -> String:
	return text.replace("{nombre}", st.player_name if st.player_name != "" else name_buf) \
		.replace("{inicial}", st.starter_title())


func _enter_start() -> void:
	d._go(func(): _enter_place(st.data.get("inicio", {"mapa": "escuela"})))


func _enter_place(pl: Dictionary) -> void:
	world.enter(str(pl.get("mapa", "escuela")))
	if pl.has("x") and pl.has("y"):
		world.pos = Vector2i(int(pl["x"]), int(pl["y"]))
	if pl.has("dir"):
		world.dir = str(pl["dir"])
	screen = "world"


## Guarda dónde estás (al salir al título o antes de un duelo).
func save_place() -> void:
	st.place = {"mapa": world.map_id, "x": world.pos.x, "y": world.pos.y, "dir": world.dir}
	st.save()


## Borra la partida y vuelve a empezar (nombre y mazo).
func restart() -> void:
	st.reset()
	open()


# ===========================================================================
# Teclas
# ===========================================================================

func input(event: InputEventKey) -> void:
	var k := event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo
	var back := k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE] and not event.echo
	match screen:
		"intro": intro.input(event)
		"name": _name_input(k, accept, back)
		"world": world.input(event)
		"new": _new_input(k, accept)
		"packs": _packs_input(k, accept, event.echo)
		"shop": shop.input(event)


func _new_input(k: int, accept: bool) -> void:
	var n: int = st.data["starters"].size()
	if k in [KEY_LEFT, KEY_RIGHT]:
		cursor = (cursor + (1 if k == KEY_RIGHT else n - 1)) % n
		d.snd.play("move")
	if accept:
		d.snd.play("ok")
		st.start(cursor, name_buf if name_buf != "" else "Trainer")
		cursor = 0
		if from_intro:
			screen = "intro"
			intro.resume()
		else:
			_enter_start()


func _name_input(k: int, accept: bool, back: bool) -> void:
	var rows := NAME_ROWS.size() + 1      # la última fila: Borrar / Listo
	match k:
		KEY_UP: name_cursor.y = (name_cursor.y + rows - 1) % rows
		KEY_DOWN: name_cursor.y = (name_cursor.y + 1) % rows
		KEY_LEFT: name_cursor.x = (name_cursor.x + 9) % 10
		KEY_RIGHT: name_cursor.x = (name_cursor.x + 1) % 10
	if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		d.snd.play("move")
	if back:
		if name_buf.length() > 0:
			name_buf = name_buf.left(name_buf.length() - 1)
			d.snd.play("back")
		elif from_intro:                   # en la presentación el nombre es obligatorio
			d.snd.play("error")
		else:                              # sin nombre todavía: X vuelve al título
			d.snd.play("back")
			d._go(func(): d.mode = "title")
		return
	if not accept:
		return
	if name_cursor.y == NAME_ROWS.size():
		if name_cursor.x < 5:              # Borrar
			if name_buf.length() > 0:
				name_buf = name_buf.left(name_buf.length() - 1)
				d.snd.play("back")
		elif name_buf.strip_edges() == "":   # Listo, pero sin nombre
			d.snd.play("error")
		else:
			name_buf = name_buf.strip_edges()
			d.snd.play("ok")
			cursor = 0
			if from_intro:
				screen = "intro"
				intro.resume()
			else:
				screen = "new"
		return
	if name_buf.length() >= NAME_MAX:
		d.snd.play("error")
		return
	name_buf += NAME_ROWS[name_cursor.y][name_cursor.x]
	d.snd.play("ok")
	if name_buf.length() >= NAME_MAX:
		name_cursor = Vector2i(7, NAME_ROWS.size())    # salta a "Done"


func _packs_input(k: int, accept: bool, echo: bool) -> void:
	# Con todas las cartas a la vista: las flechas recorren el sobre y C muestra la ficha
	var cards: Array = packs[pack_i]["cards"] if pack_i < packs.size() else []
	var all_shown := pack_t >= PACK_ANIM and int(reveal) >= cards.size() and not cards.is_empty()
	if all_shown and k in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		var n := cards.size()
		match k:
			KEY_LEFT: pack_cursor = (pack_cursor - 1 + n) % n
			KEY_RIGHT: pack_cursor = (pack_cursor + 1) % n
			KEY_UP: pack_cursor = pack_cursor - 3 if pack_cursor >= 3 else pack_cursor
			KEY_DOWN: pack_cursor = pack_cursor + 3 if pack_cursor + 3 < n else pack_cursor
		d.snd.play("move")
		return
	if all_shown and k == KEY_C and not echo:
		var entries: Array = []
		for cid in cards:
			var c2: String = cid
			entries.append(func(): return d._card_lines(c2, null))
		d.snd.play("ok")
		d._open_info(entries, pack_cursor, func(j: int): pack_cursor = j)
		return
	if not accept:
		return
	if pack_t < PACK_ANIM:
		pack_t = PACK_ANIM             # Z saltea la animación
		return
	if reveal < 9.0:
		reveal = 9.0                   # Z muestra todas las cartas
		return
	d.snd.play("ok")
	pack_i += 1
	pack_cursor = 0
	if pack_i < packs.size():
		reveal = 0.0
		pack_t = 0.0
		return
	screen = after_packs
	after_packs = "world"
	if screen == "shop":
		shop.back_from_pack()


# ===========================================================================
# Flujo
# ===========================================================================

## Un rival del mapa te desafió: al duelo (al volver se sigue en after_duel).
func start_world_duel(rid: String) -> void:
	rival_id = rid
	save_place()
	var r: Dictionary = st.rival(rid)
	d._go(func(): d.start_campaign_duel(st.deck_cards(), Decks.get_deck(r["mazo"]), int(r.get("nivel", 1)), rid), "battle")


## Vuelve de un duelo: el rival dice su frase y, si ganaste, recibís los sobres.
func after_duel(won: bool) -> void:
	var r: Dictionary = st.rival(rival_id)
	screen = "world"
	var who: String = r.get("nombre", "")
	if not won:
		st.record_loss(rival_id)
		st.mark(r.get("marcar_al_perder", []))     # eventos: "te ganó tal rival"
		world.say(who, r.get("gane", ["..."]))
		return
	reward = st.record_win(rival_id)
	st.mark(r.get("marcar_al_ganar", []))          # eventos: "le ganaste a tal rival"
	var lines: Array = r.get("perdi", []).duplicate()
	var n: int = reward["packs"]
	var cards: Array = reward.get("cards", [])
	if int(reward.get("money", 0)) > 0:
		lines.append("You got ₽%d for winning!" % int(reward["money"]))
	var cards_at := lines.size()
	for id in cards:
		lines.append("You received %s!" % CardDB.card_name(id))
	if n > 0:
		lines.append("You receive %s of %s." % ["1 booster pack" if n == 1 else "%d booster packs" % n, SET_NAMES.get(reward["set"], reward["set"])])
	if lines.is_empty():
		return
	world.say(who, lines, _start_packs if n > 0 else Callable())
	if not cards.is_empty():
		world.dialog["cards"] = cards        # las cartas ganadas se ven arriba del cuadro de texto
		world.dialog["cards_at"] = cards_at


func _start_packs() -> void:
	packs = []
	pack_new = {}
	for i in reward["packs"]:
		var before := {}
		for id in st.collection:
			before[id] = st.collection[id]
		var cards: Array = st.open_pack(reward["set"])
		var news := {}
		for id in cards:
			if before.get(id, 0) == 0:
				news[id] = true
		packs.append({"cards": cards, "new": news, "reverse": st.last_reverse})
	pack_i = 0
	reveal = 0.0
	pack_t = 0.0
	screen = "packs"


## Un sobre comprado en una tienda: se abre igual que los que se ganan y se vuelve a la tienda.
func open_bought_pack(set_id: String) -> void:
	reward = {"packs": 1, "set": set_id}
	_start_packs()
	after_packs = "shop"


## Entra a la tienda (data/campana.json -> "tiendas" -> shop_id).
func open_shop(shop_id: String) -> void:
	var go_in := func():
		screen = "shop"
		shop.open(shop_id)
	d._go(go_in, "door")


## Sale de la tienda y vuelve al mapa, de espaldas a la puerta.
func leave_shop() -> void:
	var go_out := func():
		screen = "world"
		world.dir = world._opposite(world.dir)
	d._go(go_out, "door")


func update(delta: float) -> void:
	if screen == "intro":
		intro.update(delta)
		return
	if screen == "world":
		world.update(delta)
		return
	if screen == "shop":
		shop.update(delta)
		return
	if screen == "packs" and pack_t < PACK_ANIM:
		var was := pack_t
		pack_t += delta
		if was < 0.8 and pack_t >= 0.8:
			d.snd.play("draw")             # se rompe el envoltorio
		return
	if screen == "packs" and reveal < 9.0:
		var before := int(reveal)
		reveal = minf(reveal + delta / REVEAL_TIME, 9.0)
		if int(reveal) != before:
			var pk: Dictionary = packs[pack_i]
			var id: String = pk["cards"][mini(int(reveal) - 1, pk["cards"].size() - 1)]
			d.snd.play("prize" if st.rarity.get(id, "").begins_with("Rare") else "draw")


# ===========================================================================
# Dibujo
# ===========================================================================

func draw() -> void:
	if screen == "intro":
		intro.draw()
		return
	if screen == "name":
		_draw_name()
		return
	if screen == "world":
		world.draw()
		return
	if screen == "shop":
		shop.draw()
		return
	d._menu_bg()
	match screen:
		"new": _draw_new()
		"packs": _draw_packs()


func _header(title: String, right: String = "") -> void:
	d._frame(Rect2(0, 0, d.W, 22))
	d._text(Vector2(9, 5), title, d.C_TEXT)
	if right != "":
		d._text(Vector2(d.W - 9 - d._text_w(right), 5), right, d.C_DIM)


func _draw_new() -> void:
	_header("CHOOSE YOUR STARTER DECK")
	var sts: Array = st.data["starters"]
	for i in sts.size():
		var s: Dictionary = sts[i]
		var r := Rect2(4 + i * 78, 26, 76, 88)
		var sel := i == cursor
		d._frame(r)
		if sel:
			d._outline(r.grow(-2), Color("#c03028"))
		d._draw_card_image(Rect2(r.position.x + 18, r.position.y + 8, d.MENU_IMG, d.MENU_IMG), s["carta"])
		var tw = d._text_w(s["titulo"])
		d._text(Vector2(r.position.x + (r.size.x - tw) / 2.0, r.position.y + 52), s["titulo"], Color("#c03028") if sel else d.C_TEXT)
		var dn: String = s["deck"]
		d._text_fit(Vector2(r.position.x + maxf(6, (r.size.x - d._text_w(dn)) / 2.0), r.position.y + 66), dn, d.C_DIM, r.size.x - 12)
	d._frame(Rect2(0, 118, d.W, 42))
	var cur: Dictionary = sts[cursor]
	d._text_scroll(Vector2(9, 122), cur["texto"], d.C_TEXT, 222, "camp_new")
	d._text(Vector2(9, 140), "◀▶ choose · Z start with this deck", d.C_DIM)


# ===========================================================================
# Sobres: imagen, envoltorio y la animación de abrirlos
# ===========================================================================

func pack_art(set_id: String, big: bool) -> Texture2D:
	var key := set_id + ("_grande" if big else "")
	if not _pack_art.has(key):
		var tex: Texture2D = null
		for dir_path in ["res://mundo/propios", "user://mundo/propios"]:
			var p := "%s/sobre_%s.png" % [dir_path, key]
			if tex == null and ImgLoad.exists(p):
				var img := ImgLoad.load(p)
				if img != null and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
		_pack_art[key] = tex
	return _pack_art[key]


## Alto de los bordes plateados (arriba y abajo) según el ancho del sobre.
func crimp_h(w: float) -> float:
	return roundf(w / 11.0)


## Un sobre cerrado: la imagen (o un color con el nombre si no hay imagen) entre dos bordes
## plateados. art = el rectángulo de la imagen; los bordes van por fuera.
## top = false: sin el borde de arriba (ya se rompió).
func draw_pack(art: Rect2, set_id: String, big: bool, top: bool = true) -> void:
	var c := crimp_h(art.size.x)
	var whole := Rect2(art.position - Vector2(0, c if top else 0), art.size + Vector2(0, c * (2 if top else 1)))
	d.draw_rect(whole.grow(1), d.C_INK)
	var tex := pack_art(set_id, big)
	if tex != null:
		d.draw_texture_rect(tex, art, false)
	else:
		var col: Color = PACK_COLORS.get(set_id, Color("#808890"))
		d.draw_rect(art, col)
		d.draw_rect(Rect2(art.position + Vector2(0, art.size.y * 0.35), Vector2(art.size.x, art.size.y * 0.3)), col.lightened(0.25))
		var name: String = SET_NAMES.get(set_id, set_id)
		var lines: Array = d._wrap(name, art.size.x - 6)
		for i in lines.size():
			var ln: String = lines[i]
			d._text(Vector2(art.position.x + (art.size.x - d._text_w(ln)) / 2.0, art.position.y + art.size.y * 0.36 + i * 11), ln, Color.WHITE)
	if top:
		_crimp(Rect2(art.position - Vector2(0, c), Vector2(art.size.x, c)))
	_crimp(Rect2(Vector2(art.position.x, art.end.y), Vector2(art.size.x, c)))


## Borde plateado con las rayitas del sellado.
func _crimp(r: Rect2) -> void:
	d.draw_rect(r, Color("#c8ccd8"))
	d.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("#f0f2f8"))
	d.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color("#8a90a0"))
	var x := r.position.x + 1
	while x < r.end.x - 1:
		d.draw_rect(Rect2(x, r.position.y + 1, 1, r.size.y - 2), Color("#a0a6b8"))
		x += 3


## La animación: el sobre cae, tiembla, se rompe el borde de arriba, asoman las cartas y
## un destello da paso a las cartas.
func _draw_pack_opening(set_id: String) -> void:
	var t := pack_t
	var size := Vector2(80, 112)
	var center := Vector2(d.W / 2.0, 92)
	var c := crimp_h(size.x)
	# Cae desde arriba con un rebotecito
	var drop := clampf(t / 0.35, 0.0, 1.0)
	var y_off := -140.0 * pow(1.0 - drop, 3)
	if t > 0.35 and t < 0.5:
		y_off += sin((t - 0.35) / 0.15 * PI) * -4.0
	# Tiembla antes de abrirse
	var x_off := 0.0
	if t > 0.5 and t < 0.8:
		x_off = sin(t * 70.0) * 2.0
	var art := Rect2(center - size / 2.0 + Vector2(x_off, y_off), size)
	# Brillo detrás
	if t > 0.45:
		var glow := clampf((t - 0.45) / 0.4, 0.0, 1.0)
		d._draw_burst(art.get_center(), 60.0 + glow * 10.0, Color(1, 0.95, 0.6, 0.25 * glow), 12)
	var torn := t >= 0.8
	# Cartas que asoman por arriba (detrás del sobre)
	if t > 0.95:
		var up := clampf((t - 0.95) / 0.35, 0.0, 1.0)
		for i in 3:
			var cw := 44.0
			var ch := 60.0
			var cx := art.get_center().x - cw / 2.0 + (i - 1) * 8.0
			var cy := art.position.y + 6 - up * (32.0 + i * 7.0)
			d._draw_card_back(Rect2(cx, cy, cw, ch))
	draw_pack(art, set_id, true, not torn)
	# El borde de arriba sale volando
	if torn and t < 1.4:
		var k := (t - 0.8) / 0.6
		var strip := Rect2(Vector2.ZERO, Vector2(size.x, c))
		var pos := art.position + Vector2(size.x / 2.0 + k * 60.0, -c / 2.0 - k * 50.0 + k * k * 30.0)
		d.draw_set_transform(d._base_off + pos, k * 1.4, Vector2.ONE)
		var a := 1.0 - k
		d.draw_rect(Rect2(-strip.size / 2.0, strip.size).grow(1), Color(d.C_INK, a))
		d.draw_rect(Rect2(-strip.size / 2.0, strip.size), Color("#c8ccd8", a))
		d.draw_set_transform(d._base_off, 0.0, Vector2.ONE)
	# Destello al final
	if t > 1.3:
		var f := 1.0 - absf((t - 1.45) / 0.15)
		d.draw_rect(Rect2(0, 0, d.W, d.H), Color(1, 1, 1, clampf(f, 0.0, 1.0) * 0.9))


func _draw_packs() -> void:
	var pk: Dictionary = packs[pack_i]
	var cards: Array = pk["cards"]
	_header("PACK %d/%d" % [pack_i + 1, packs.size()], SET_NAMES.get(reward.get("set", ""), ""))
	if pack_t < PACK_ANIM:
		_draw_pack_opening(str(reward.get("set", "ex1")))
		return
	d._frame(Rect2(0, 20, 128, 140))
	var shown := int(reveal)
	var last := ""
	var last_rev := false
	var browsing := shown >= cards.size()
	for i in cards.size():
		var cell := Rect2(9 + (i % 3) * 37, 26 + (i / 3) * 42, 34, 38)
		if i < shown:
			var id: String = cards[i]
			last = id
			var rev: bool = i == pk.get("reverse", -1)
			last_rev = rev
			var rare: bool = st.rarity.get(id, "").begins_with("Rare")
			d.draw_rect(cell, Color("#f8d030") if rare else d.C_INK)
			d.draw_rect(cell.grow(-1), Color("#f8f8e8"))
			if rev:
				d._draw_reverse(cell.grow(-1), Rect2(cell.position + Vector2(2, 2), Vector2(30, 30)), id)
			d._draw_card_image(Rect2(cell.position + Vector2(2, 2), Vector2(30, 30)), id, rev)
			if pk["new"].has(id):
				d.draw_rect(Rect2(cell.position.x + 1, cell.end.y - 5, cell.size.x - 2, 4), Color("#c03028"))
		else:
			d._draw_card_back(cell)
	# Con todas a la vista, la marcada (la que se ve a la derecha) titila
	if browsing:
		var pc := clampi(pack_cursor, 0, cards.size() - 1)
		last = cards[pc]
		last_rev = pc == pk.get("reverse", -1)
		var cell := Rect2(9 + (pc % 3) * 37, 26 + (pc / 3) * 42, 34, 38)
		var on := int(Time.get_ticks_msec() / 300.0) % 2 == 0
		d._outline(cell.grow(1), Color("#f85838") if on else Color("#f8d030"))
		d._outline(cell.grow(2), Color(0, 0, 0, 0.4))
	# A la derecha, la última carta que salió
	var side = Rect2(126, 20, d.W - 126, 140)
	d._frame(side)
	if last != "":
		d._draw_card_image(Rect2(side.position.x + (side.size.x - d.MENU_IMG) / 2.0, 28, d.MENU_IMG, d.MENU_IMG), last, last_rev)
		d._text_scroll(Vector2(side.position.x + 9, 74), CardDB.card_name(last), d.C_TEXT, side.size.x - 18, "pack_name")
		var rr: String = RARITY_ES.get(st.rarity.get(last, ""), "")
		if last_rev:
			rr = "Reverse holo"
		var rc: Color = Color.from_hsv(fmod(Time.get_ticks_msec() / 1500.0, 1.0), 0.7, 0.85) if last_rev \
				else (Color("#b08800") if (rr.begins_with("Rare") or rr == "Secret Rare") else d.C_DIM)
		d._text(Vector2(side.position.x + 9, 86), rr, rc)
		if pk["new"].has(last):
			d._text(Vector2(side.position.x + 9, 98), "NEW!", Color("#c03028"))
		d._text(Vector2(side.position.x + 9, 110), "You have %d" % st.owned(last), d.C_DIM)
	var hint := "Z: show all" if shown < cards.size() else ("Z: next pack" if pack_i + 1 < packs.size() else "Z: done")
	if browsing:
		d._text(Vector2(side.position.x + 9, 122), "◀▶ browse", d.C_DIM)
		d._text(Vector2(side.position.x + 9, 133), "C: details", d.C_DIM)
	d._text(Vector2(side.position.x + 9, 144), hint, d.C_DIM)


func _draw_name() -> void:
	if d._ui_tex("fondo") == null:
		d.draw_rect(Rect2(0, 0, d.W, d.H), Color("#c8d8f0"))
	else:
		d._menu_bg()
	_header("WHAT'S YOUR NAME?")
	# Nombre con casilleros
	var nb := Rect2(40, 24, 160, 22)
	d._frame(nb)
	for i in NAME_MAX:
		var x := nb.position.x + 10 + i * 14
		var ch := name_buf.substr(i, 1) if i < name_buf.length() else ""
		if ch != "":
			d._text(Vector2(x + 1, nb.position.y + 4), ch, d.C_TEXT)
		var cur := i == name_buf.length() and int(Time.get_ticks_msec() / 400.0) % 2 == 0
		d.draw_rect(Rect2(x, nb.position.y + 16, 10, 1), Color("#c03028") if cur else d.C_DIM)
	# Teclado
	var kb := Rect2(4, 50, d.W - 8, 92)
	d._frame(kb)
	for ry in NAME_ROWS.size():
		var row: String = NAME_ROWS[ry]
		for rx in row.length():
			var p := Vector2(14 + rx * 22, kb.position.y + 4 + ry * 11 + (3 if ry >= 3 else 0))
			var sel := name_cursor == Vector2i(rx, ry)
			if sel:
				d.draw_rect(Rect2(p - Vector2(4, 0), Vector2(16, 11)), Color("#f8d8a0"))
			var ch := row.substr(rx, 1)
			d._text(p, "␣" if ch == " " else ch, Color("#c03028") if sel else d.C_TEXT)
	var by := kb.position.y + 4 + NAME_ROWS.size() * 11 + 6
	for i in 2:
		var lbl := "Delete" if i == 0 else "Done"
		var x := 30.0 + i * 110
		var sel := name_cursor.y == NAME_ROWS.size() and (name_cursor.x < 5) == (i == 0)
		if sel:
			d._text(Vector2(x - 10, by), "▶", d.C_TEXT)
		d._text(Vector2(x, by), lbl, Color("#c03028") if sel else d.C_TEXT)
	d._page_hint(Vector2(9, 146), "Z type · X delete · Done when finished")
