extends RefCounted
## Mapas caminables de la campaña (estilo GBC/GBA): te movés de a casilla, les hablás a
## los personajes y los rivales te desafían a duelo. La dibuja la pantalla de duelo
## (duel.gd) a través de la campaña (campaign.gd), igual que las demás pantallas.
##
## Mapas:      data/mapas/<id>.json  (baldosas como letras, personajes, objetos)
## Arte:       mundo/baldosas.png y mundo/personajes/<id>.png (tools/make_world.py);
##             tus propios PNG van en mundo/propios/ (personajes y fondos de mapas enteros:
##             con "fondo" en el mapa, se dibuja esa imagen en lugar de las baldosas)
##
## Teclas: flechas = caminar (un toque solo gira) · Z = hablar / mirar · X = menú

const TILE := 16
const STEP_TIME := 16.0 / 60.0   # segundos por casilla: 1 píxel por cuadro, como en la GBA
const TURN_GRACE := 0.09      # un toque corto solo gira
const RUN_FACTOR := 0.5       # corriendo, cada casilla tarda la mitad (2 píxeles por cuadro)
const TYPE_SPEED := 45.0
const ALERT_TIME := 0.7       # el "!" sobre el rival que te vio
const DIRS := {"down": Vector2i(0, 1), "up": Vector2i(0, -1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}
const DIR_ROW := {"down": 0, "up": 1, "left": 2, "right": 3}
const KEY_DIR := {KEY_DOWN: "down", KEY_UP: "up", KEY_LEFT: "left", KEY_RIGHT: "right"}

## Letra del mapa -> [baldosa en baldosas.png, ¿se puede pisar?]
## "#" elige sola entre pared de frente o techo según lo que tenga abajo.
const LEGEND := {
	".": [0, true], ",": [1, true], "=": [2, true], "#": [4, false], "E": [5, false],
	"L": [6, false], "B": [8, false], "r": [10, false], "T": [11, false], "b": [12, false],
	"P": [13, false], "C": [14, false], "D": [15, true], "M": [11, false],
	"_": [0, true], "f": [1, true],     # arena de las canchas y flores (patio): se pisan
}
const T_WALL_TOP := 3
const FLOOR_VARIANTS := [16, 17]     # piedras gastadas que se mezclan con el piso
const SPRITE_H := 32                 # personajes de 16x32 (como en Ruby/Sapphire)
const FEET := 29                     # fila de los pies dentro del cuadro
const ANIMATED := {6: 2, 8: 2}       # baldosa -> cuadros (lava, braseros)
const SpecialFX := preload("res://scenes/special_fx.gd")
const SIT_DROP := -3                 # personajes sentados: cuánto suben para quedar sobre la silla

var d                       # pantalla de duelo (dibujo, texto, sonido)
var camp                    # campaña
var map_id := ""
var data := {}
var rows: Array = []
var mw := 0
var mh := 0
var npcs: Array = []        # {"id", "pos": Vector2i, "dir", "sprite", "def", "move": {...}, "wait"}
var pos := Vector2i.ZERO    # jugador
var dir := "up"
var move := {}              # paso en curso: {"from": Vector2i, "to": Vector2i, "t"}
var hold := {}              # dirección apretada: {"dir", "t"}
var walk_frame := 0
var dialog := {}            # {"name", "pages", "page", "typed", "then": Callable, "ask": bool, "yes"}
var menu_open := false
var menu_cursor := 0
var spotted := {}           # rivales que ya te desafiaron en esta visita
var alert := {}             # {"npc", "t"}: el rival te vio
var approach := {}          # {"npc"}: el rival camina hacia vos
var banner_t := 0.0         # cartel con el nombre del lugar
var clock := 0.0
var _tiles: Texture2D
var _bg: Texture2D = null    # imagen del mapa entero ("fondo"), si está
var _front := {}            # fila -> textura con los muebles de esa fila que tapan a quien pasa por detrás
var _sprites := {}
var _rng := RandomNumberGenerator.new()
var wind := {}              # ráfaga de viento en curso: {"t", "leaves": [...]}
var next_wind := 0.0        # cuándo sopla la próxima (clock)
var _flowers: Array = []    # flores del mapa ('f'): [[casilla, casilla de pasto de donde copiar el fondo]]
var _flower_tex: Texture2D = null
const WIND_TIME := 2.8
const WIND_EVERY := [14.0, 20.0]
var field_fx: Array = []    # pasto al pisar: {"kind", "at": Vector2 (píxel del mapa), "t", "flip"}
const GRASS_TIME := 0.4


func _init(duel, campaign) -> void:
	d = duel
	camp = campaign
	_rng.randomize()


# ===========================================================================
# Cargar un mapa
# ===========================================================================

func enter(id: String) -> void:
	map_id = id
	field_fx = []
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mapas/%s.json" % id))
	rows = data["baldosas"]
	mh = rows.size()
	mw = 0
	for r in rows:
		mw = maxi(mw, str(r).length())
	var st: Array = data["inicio"]
	pos = Vector2i(int(st[0]), int(st[1]))
	dir = str(st[2])
	npcs = []
	for p in data.get("personajes", []):
		if p.has("solo_si") and not camp.st.cond_met(p["solo_si"], str(p.get("rival", ""))):
			continue        # todavía no aparece (o ya no está): se revisa al entrar al mapa
		var spr := _pick_sprite(p.get("sprite", p["id"]))
		if p.get("pokemon", false) and not _has_sprite(spr):
			continue        # Pokémon sueltos ("pokemon": true): solo si tenés su sprite (tools/armar_pokemon_mundo.py)
		npcs.append({"id": p["id"], "pos": Vector2i(int(p["x"]), int(p["y"])), "dir": p.get("dir", "down"),
				"home": Vector2i(int(p["x"]), int(p["y"])), "sprite": spr, "def": p,
				"move": {}, "wait": _rng.randf_range(1.0, 3.0)})
	move = {}
	hold = {}
	dialog = {}
	menu_open = false
	spotted = {}
	alert = {}
	approach = {}
	banner_t = 0.0
	if _tiles == null:
		_tiles = _load_tex("res://mundo/baldosas.png")
	_bg = null
	var bg_name := str(data.get("fondo", ""))
	if bg_name != "":
		for dir_path in ["res://mundo/propios", "user://mundo/propios", "res://mundo/fondos", "user://mundo/fondos"]:
			var p := "%s/%s.png" % [dir_path, bg_name]
			if _bg == null and ImgLoad.exists(p):
				_bg = _load_tex(p)
	_build_front()
	_setup_wind()


## Con un "fondo" de mapa entero, los muebles (pupitres, macetas, mesas...) están pintados
## en la imagen y sobresalen hacia la casilla de atrás. Para que tapen al que pasa por detrás,
## se arma por cada fila una capa con esos píxeles: la casilla del mueble entera y, en la
## casilla de arriba (si se puede pisar), lo que no es piso. Lo que es piso se reconoce
## comparando con la baldosa más común de esa misma letra.
func _build_front() -> void:
	_front = {}
	if _bg == null:
		return
	var img := _bg.get_image()
	img.convert(Image.FORMAT_RGBA8)
	# La baldosa más común de cada letra que se pisa (el piso "limpio")
	var counts := {}
	var plain := {}
	var tiles_of := {}          # cuántas casillas hay de cada letra de suelo
	for ty in mh:
		for tx in mw:
			var ch := _char_at(Vector2i(tx, ty))
			if not _is_ground(ch) or (tx + 1) * TILE > img.get_width() or (ty + 1) * TILE > img.get_height():
				continue
			var reg := img.get_region(Rect2i(tx * TILE, ty * TILE, TILE, TILE))
			tiles_of[ch] = int(tiles_of.get(ch, 0)) + 1
			var key := Marshalls.raw_to_base64(reg.get_data())
			if not counts.has(ch):
				counts[ch] = {}
			counts[ch][key] = int(counts[ch].get(key, 0)) + 1
			if int(counts[ch][key]) > int(plain.get(ch, [0, null])[0]):
				plain[ch] = [counts[ch][key], reg]
	# El piso más común de todo el mapa: lo que no se le parece en una casilla de mueble es
	# el mueble (así la silla tapa al que está sentado, pero no el piso de alrededor)
	var base_floor: Image = null
	var most := 0
	for ch in tiles_of:
		if int(tiles_of[ch]) > most and plain.has(ch):
			most = int(tiles_of[ch])
			base_floor = plain[ch][1]
	for ty in mh:
		var layer: Image = null
		for tx in mw:
			var ch := _char_at(Vector2i(tx, ty))
			if _is_ground(ch) or ch in ["#", "E"] or (tx + 1) * TILE > img.get_width():
				continue
			if layer == null:
				layer = Image.create(mw * TILE, TILE * 2, false, Image.FORMAT_RGBA8)
			var own_ref: Image = _ref_tile(img, tx, ty, false)
			if own_ref == null:
				own_ref = base_floor
			for y in TILE:
				for x in TILE:
					var c := img.get_pixel(tx * TILE + x, ty * TILE + y)
					if own_ref == null or _differs(c, own_ref.get_pixel(x, y)):
						layer.set_pixel(tx * TILE + x, TILE + y, c)
			var up := _char_at(Vector2i(tx, ty - 1))
			if ty == 0 or not _is_ground(up) or not plain.has(up):
				continue
			# Lo que sobresale hacia la casilla de atrás: por columna, desde abajo, mientras siga
			# siendo mueble. Se compara con una casilla de piso vecina de esa misma fila (mismo
			# color y misma sombra), así no se copia piso de más
			var floor_img: Image = _ref_tile(img, tx, ty - 1, true, up)
			if floor_img == null:
				floor_img = plain[up][1]
			for x in TILE:
				var misses := 0
				for y in range(TILE - 1, -1, -1):
					var c := img.get_pixel(tx * TILE + x, (ty - 1) * TILE + y)
					if _differs(c, floor_img.get_pixel(x, y)):
						misses = 0
						layer.set_pixel(tx * TILE + x, y, c)
					else:
						misses += 1
						if misses >= 2:
							break
		if layer != null:
			_front[ty] = ImageTexture.create_from_image(layer)


## Una casilla de piso cerca de (tx, ty) en la misma fila, para comparar: la más cercana que
## sea suelo (y, con above = true, que no tenga un mueble justo abajo). Con letter, solo
## casillas de esa misma letra.
func _ref_tile(img: Image, tx: int, ty: int, above: bool, letter := "") -> Image:
	for dist in range(1, 6):
		for sx in [-1, 1]:
			var x: int = tx + sx * dist
			if x < 0 or x >= mw or (x + 1) * TILE > img.get_width() or (ty + 1) * TILE > img.get_height():
				continue
			if not _is_ground(_char_at(Vector2i(x, ty))):
				continue
			if letter != "" and _char_at(Vector2i(x, ty)) != letter:
				continue          # el mismo piso (arena con arena), no el pasto de al lado
			if above and not _is_ground(_char_at(Vector2i(x, ty + 1))):
				continue
			return img.get_region(Rect2i(x * TILE, ty * TILE, TILE, TILE))
	return null


func _differs(c: Color, f: Color) -> bool:
	return absf(c.r - f.r) + absf(c.g - f.g) + absf(c.b - f.b) > 0.12


## Suelo (no es un mueble): lo que se pisa y las letras propias del dibujo de cada mapa que no
## están en LEGEND, como la arena de las canchas o las flores del patio.
func _is_ground(ch: String) -> bool:
	return LEGEND.get(ch, [0, true])[1]


func _load_tex(path: String) -> Texture2D:
	if not ImgLoad.exists(path):
		return null
	var img := ImgLoad.load(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


## Carga una hoja de personaje y apoya los pies de cada cuadro en la misma fila (FEET).
## Las hojas recortadas a mano suelen traer cuadros corridos un píxel o dos: sin esto el
## personaje flota sobre la sombra y sube y baja al caminar.
func _load_sprite(path: String) -> Texture2D:
	var img := ImgLoad.load(path)
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGBA8)
	if img.get_height() >= SPRITE_H * 4 and img.get_width() >= TILE:
		var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		for cy in img.get_height() / SPRITE_H:
			for cx in img.get_width() / TILE:
				var cell := Rect2i(cx * TILE, cy * SPRITE_H, TILE, SPRITE_H)
				var bottom := -1
				for y in range(SPRITE_H - 1, -1, -1):
					for x in TILE:
						if img.get_pixel(cell.position.x + x, cell.position.y + y).a > 0.1:
							bottom = y
							break
					if bottom >= 0:
						break
				var shift := 0 if bottom < 0 else FEET - bottom
				var src := Rect2i(cell.position + Vector2i(0, maxi(0, -shift)), Vector2i(TILE, SPRITE_H - absi(shift)))
				out.blit_rect(img, src, cell.position + Vector2i(0, maxi(0, shift)))     # sin pisar el cuadro vecino
		img = out
	return ImageTexture.create_from_image(img)


## Si hay un PNG para ese personaje (sin el genérico de reemplazo). Así "jugador_corre" se usa
## solo si lo agregaste: la hoja de correr, con el mismo formato que jugador.png.
func _has_sprite(id: String) -> bool:
	if not _sprites.has("?" + id):
		var ok := false
		for dir_path in ["res://mundo/propios", "user://mundo/propios", "res://mundo/personajes", "user://mundo/personajes"]:
			ok = ok or ImgLoad.exists("%s/%s.png" % [dir_path, id])
		_sprites["?" + id] = ok
	return _sprites["?" + id]


## "sprite" puede ser una lista: se usa el primero que exista. Así un personaje nuevo puede
## pedir su propio PNG ("espectador_1") y mientras tanto usar uno que ya está ("nino_castano").
func _pick_sprite(v) -> String:
	if v is Array:
		for id in v:
			if _has_sprite(str(id)):
				return str(id)
		return str(v[-1]) if not v.is_empty() else ""
	return str(v)


## mundo/propios/ tiene prioridad: tus propios sprites, que los scripts de tools/ no pisan.
func _sprite(id: String) -> Texture2D:
	if not _sprites.has(id):
		var tex: Texture2D = null
		for dir_path in ["res://mundo/propios", "user://mundo/propios", "res://mundo/personajes", "user://mundo/personajes"]:
			var p := "%s/%s.png" % [dir_path, id]
			if tex == null and ImgLoad.exists(p):
				tex = _load_sprite(p)
		if tex == null and id != "ayudante":
			tex = _sprite("ayudante")      # si falta, un personaje genérico
		_sprites[id] = tex
	return _sprites[id]


func _char_at(c: Vector2i) -> String:
	if c.y < 0 or c.y >= mh or c.x < 0 or c.x >= str(rows[c.y]).length():
		return "#"
	return str(rows[c.y])[c.x]


func _walkable(c: Vector2i) -> bool:
	var ch := _char_at(c)
	if not LEGEND.get(ch, [0, false])[1]:
		return false
	if ch == "D" and _exit_at(c).is_empty():
		return false               # puerta que todavía no lleva a ningún lado
	for n in npcs:
		if n["pos"] == c or (not n["move"].is_empty() and n["move"]["to"] == c):
			return false
	return true


## Salida en esa casilla: {"x", "y", "mapa", "a": [x, y, dir]} de "salidas", o {}.
func _exit_at(c: Vector2i) -> Dictionary:
	for e in data.get("salidas", []):
		if int(e.get("x", -1)) == c.x and int(e.get("y", -1)) == c.y:
			return e
	return {}


func _npc_at(c: Vector2i) -> Variant:
	for n in npcs:
		if n["pos"] == c:
			return n
	return null


# ===========================================================================
# Teclas
# ===========================================================================

func input(event: InputEventKey) -> void:
	var k := event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo
	var back := k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE] and not event.echo
	if not dialog.is_empty():
		_dialog_input(k, accept, back)
		return
	if menu_open:
		_menu_input(k, accept, back)
		return
	if not alert.is_empty() or not approach.is_empty():
		return
	if accept and move.is_empty():
		_interact()
	elif back and k == KEY_X:
		x_pending = true            # se decide al soltarla: menú, o correr si caminaste con ella
	elif back and move.is_empty():
		_open_menu()


func _open_menu() -> void:
	menu_open = true
	menu_cursor = 0
	menu_t = 0.0
	d.snd.play("ok")


func _dialog_input(k: int, accept: bool, back: bool) -> void:
	var full: String = dialog["pages"][dialog["page"]]
	var last: bool = dialog["page"] == dialog["pages"].size() - 1
	if dialog.get("ask", false) and last and dialog["typed"] >= full.length():
		if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			dialog["yes"] = not dialog["yes"]
			d.snd.play("move")
			return
		if back:
			dialog["yes"] = false
		if accept or back:
			var ok: bool = dialog["yes"]
			var then: Callable = dialog["then"]
			_close_dialog()
			d.snd.play("ok" if ok else "back")
			then.call(ok)
		return
	if not accept:
		return
	if dialog["typed"] < full.length():
		dialog["typed"] = float(full.length())
		return
	d.snd.play("move")
	if not last:
		dialog["page"] += 1
		dialog["typed"] = 0.0
		return
	var then: Callable = dialog.get("then", Callable())
	_close_dialog()
	if then.is_valid():
		then.call()


const MENU_ITEMS := ["Your decks", "Start over", "Back to title", "Close"]


func _menu_input(k: int, accept: bool, back: bool) -> void:
	if k == KEY_UP or k == KEY_DOWN:
		menu_cursor = (menu_cursor + (1 if k == KEY_DOWN else MENU_ITEMS.size() - 1)) % MENU_ITEMS.size()
		d.snd.play("move")
	if back:
		_close_menu()
		d.snd.play("back")
		return
	if not accept:
		return
	d.snd.play("ok")
	match menu_cursor:
		0:
			_close_menu()
			_open_deck()
		1:
			_close_menu()
			var then := func(ok: bool) -> void:
				if ok:
					d._go(func(): camp.restart())
			say("", ["This erases your saved game: collection, deck and progress.", "Start over from the beginning?"], then, true)
		2:
			_close_menu()
			_leave()
		3:
			_close_menu()


func _open_deck() -> void:
	d._go(func():
		d.mode = "editor"
		d.editor.open_collection(camp.st))


## Guarda dónde estás y vuelve al título.
func _leave() -> void:
	camp.save_place()
	d._go(func(): d.mode = "title")


## Diálogo con un personaje (o un cartel si name = ""). then se llama al terminar;
## con ask = true, la última frase es una pregunta y then recibe true/false.
func say(name: String, pages: Array, then: Callable = Callable(), ask: bool = false) -> void:
	var chained := clock - _dlg_closed_at < 0.2      # sigue a otro diálogo: no vuelve a entrar
	dialog = {"name": name, "pages": pages.map(func(x): return camp.fmt(str(x))), "page": 0, "typed": 0.0, "then": then,
			"ask": ask, "yes": true, "open": 1.0 if chained else 0.0}
	_dlg_ghost_t = -1.0
	_dlg_ghost = {}


func _interact() -> void:
	var front: Vector2i = pos + DIRS[dir]
	var n = _npc_at(front)
	if n != null:
		if not n["def"].get("sentado", false):     # los que están sentados no se dan vuelta
			n["dir"] = _opposite(dir)
		n["move"] = {}
		n["volver"] = 0.35        # al terminar la charla vuelve a su lugar y a mirar como antes
		_talk_to(n)
		return
	_look_at(front)


## Mirar algo del mapa con Z (ver data/GUIA_PERSONAJES.txt, punto 17):
##   "objetos_casilla": {"x,y": {...}}  una casilla puntual (tiene prioridad)
##   "objetos": {"letra": {...}}         todas las casillas de esa letra de "baldosas"
## Cada objeto tiene "frases" y opcionalmente "al_azar" (una de varias versiones cada vez),
## "variantes", "marcar", "regalo" (cartas escondidas, una sola vez) y "accion": "mazo".
func _look_at(c: Vector2i) -> void:
	var key := "%d,%d" % [c.x, c.y]
	var raw: Dictionary = data.get("objetos_casilla", {}).get(key, {})
	if raw.is_empty():
		raw = data.get("objetos", {}).get(_char_at(c), {})
	if raw.is_empty():
		return
	var obj: Dictionary = camp.st.resolve(raw)
	d.snd.play("ok")
	if obj.has("marcar"):
		camp.st.mark(obj["marcar"])
	if obj.has("regalo"):
		var gdef := obj.duplicate()
		gdef["nombre"] = ""
		if not gdef["regalo"].has("id"):
			gdef["id"] = "%s_%s" % [map_id, key]      # sin "id": uno propio por casilla
		_gift_talk(gdef)
		return
	var pages: Array = obj.get("frases", ["..."])
	var pool = obj.get("al_azar", [])
	if pool is Array and not pool.is_empty():
		var pick = pool[_rng.randi() % pool.size()]
		pages = pick if pick is Array else [str(pick)]
	if obj.get("accion", "") == "mazo":
		var then := func(ok: bool) -> void:
			if ok:
				_open_deck()
		say("", pages + ["Do you want to edit your deck?"], then, true)
	else:
		say("", pages)


func _talk_to(n: Dictionary) -> void:
	# Lo que dice según cómo va la partida: la primera "variante" que se cumpla (ver
	# data/GUIA_PERSONAJES.txt). "marcar" anota un evento al hablarle.
	var def: Dictionary = camp.st.resolve(n["def"], str(n["def"].get("rival", "")))
	var rid: String = def.get("rival", "")
	if def.has("marcar"):
		camp.st.mark(def["marcar"])
	if rid == "":
		d.snd.play("ok")
		if def.has("tienda"):
			var shop_id: String = str(def["tienda"])
			if def.has("frases"):
				say(def.get("nombre", ""), def["frases"], func(): camp.open_shop(shop_id))
			else:
				camp.open_shop(shop_id)
			return
		if def.has("regalo"):
			_gift_talk(def)
			return
		say(def.get("nombre", ""), def.get("frases", ["..."]))
		return
	var r: Dictionary = camp.st.rival(rid)
	if r.has("marcar") and camp.st.rival_available(rid):
		camp.st.mark(r["marcar"])
	if not camp.st.rival_available(rid):
		d.snd.play("ok")
		say(r["nombre"], def.get("bloqueado", ["Not yet."]))
		return
	if camp.st.beaten.get(rid, 0) > 0:
		d.snd.play("ok")
		var who: String = r["nombre"]
		if not camp.st.rematch_available(rid):
			# Ya le ganaste y las revanchas todavía no se abrieron (por ejemplo, hasta vencer al director)
			say(who, r.get("vencido", [r.get("perdi", ["..."])[0]]))
			return
		var then := func(ok: bool) -> void:
			if ok:
				_challenge(rid, r.get("revancha_si", ["Let's go again!"]))
			else:
				say(who, r.get("revancha_no", ["Maybe next time."]))
		say(who, r.get("revancha_pregunta", ["Want a rematch?"]), then, true)
		return
	if camp.st.lost.get(rid, 0) > 0 and r.has("otra_vez"):
		_challenge(rid, r["otra_vez"])       # le perdiste antes: lo que dice al volver a jugar
		return
	_challenge(rid, r.get("hola", ["..."]))


## Personaje con un regalo (data/mapas/*.json, "regalo"):
##   "regalo": {"id": "charmander_secreto", "cartas": ["ex3-98"], "requiere": {"medalla": "brasa"},
##              "dar": ["frases al darlo"], "despues": ["frases cuando ya te lo dio"]}
## Mientras no se cumple "requiere", dice sus "frases" de siempre.
func _gift_talk(def: Dictionary) -> void:
	var g: Dictionary = def["regalo"]
	var name: String = def.get("nombre", "")
	var gid: String = g.get("id", def.get("id", "regalo"))
	if camp.st.gifts.has(gid):
		say(name, g.get("despues", def.get("frases", ["..."])))
		return
	if not camp.st.gift_ready(g.get("requiere", {})):
		say(name, def.get("frases", ["..."]))
		return
	var cards: Array = g.get("cartas", [])
	var then := func() -> void:
		if camp.st.give_gift(gid, cards):
			d.snd.play("prize")
			var lines: Array = []
			for id in cards:
				lines.append("You received %s!" % CardDB.card_name(id))
			say("", lines)
			dialog["cards"] = cards
	say(name, g.get("dar", ["Here, this is for you!"]), then)


## Diálogo de desafío (lines) y, al terminar, el duelo.
func _challenge(rid: String, lines: Array) -> void:
	var r: Dictionary = camp.st.rival(rid)
	var errs: Array = camp.st.deck_errors()
	if not errs.is_empty():
		d.snd.play("error")
		say(r["nombre"], ["Your deck isn't ready: " + str(errs[0]), "Fix it, or pick another one, from the menu (X > Your decks)."])
		return
	say(r["nombre"], lines, func(): camp.start_world_duel(rid))


func _opposite(dd: String) -> String:
	return {"down": "up", "up": "down", "left": "right", "right": "left"}[dd]


# ===========================================================================
# Movimiento
# ===========================================================================

func update(delta: float) -> void:
	clock += delta
	banner_t += delta
	_update_wind(delta)
	for f in field_fx:
		f["t"] += delta
	field_fx = field_fx.filter(func(f): return f["t"] < GRASS_TIME)
	var wd := minf(delta, 1.0 / 30.0)       # un cuadro lento no saltea las animaciones de ventanas
	if menu_open:
		menu_t = minf(1.0, menu_t + wd / WIN_TIME)
	if menu_close_t >= 0.0:
		menu_close_t += wd / WIN_TIME
		if menu_close_t >= 1.0 or menu_open:
			menu_close_t = -1.0
	if _dlg_ghost_t >= 0.0:
		_dlg_ghost_t += wd / WIN_TIME
		if _dlg_ghost_t >= 1.0:
			_dlg_ghost_t = -1.0
			_dlg_ghost = {}
	if not dialog.is_empty():
		dialog["open"] = minf(1.0, float(dialog.get("open", 1.0)) + wd / WIN_TIME)
		var full: String = dialog["pages"][dialog["page"]]
		var before := int(dialog["typed"])
		if dialog["open"] >= 1.0:          # empieza a escribir cuando el cuadro terminó de entrar
			dialog["typed"] = minf(dialog["typed"] + delta * TYPE_SPEED, full.length())
		var now := int(dialog["typed"])
		if now != before and now % 2 == 0 and now <= full.length() and full.substr(now - 1, 1) != " ":
			d.snd.play("blip")            # el "blip" de las letras
	_update_npcs(delta)
	if not alert.is_empty():
		alert["t"] += delta
		if alert["t"] >= ALERT_TIME:
			approach = {"npc": alert["npc"]}
			alert = {}
		return
	if not approach.is_empty():
		_update_approach()
		return
	if x_pending and not (Input.is_key_pressed(KEY_X) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)):
		x_pending = false           # se soltó X sin caminar: el menú
		if move.is_empty() and dialog.is_empty() and not menu_open and d._trans.is_empty():
			_open_menu()
	if not dialog.is_empty() or menu_open or d._trans.size() > 0:
		hold = {}
		return
	var carry := 0.0        # tiempo que sobró del paso anterior (para que el siguiente no arranque en 0)
	if not move.is_empty():
		var dur := STEP_TIME * (RUN_FACTOR if move.get("run", false) else 1.0)
		move["t"] += delta / dur
		if move["t"] >= 1.0:
			var ran: bool = move.get("run", false)
			carry = (move["t"] - 1.0) * dur
			pos = move["to"]
			move = {}
			walk_frame = (walk_frame + 1) % 2
			if ran and _char_at(pos) in [",", "f"]:
				_spawn_fx("pasto", pos, dir)      # el pasto se levanta solo si pasás corriendo
			if _after_step():
				hold = {}
				return
		else:
			return
	var want := _held_dir()
	if want == "":
		hold = {}
		return
	if hold.get("dir", "") != want:
		var was_moving: bool = hold.get("moving", false)
		hold = {"dir": want, "t": 0.0, "moving": was_moving}
		if dir != want and not was_moving:
			dir = want             # un toque solo gira
			return
	hold["t"] += delta
	dir = want
	if hold["t"] < TURN_GRACE and not hold.get("moving", false):
		return
	var to: Vector2i = pos + DIRS[dir]
	if _walkable(to):
		move = {"from": pos, "to": to, "t": 0.0, "run": _running()}
		# Sigue de largo: arranca con lo que sobró del paso anterior, sin quedarse un cuadro quieto
		move["t"] = minf(carry / (STEP_TIME * (RUN_FACTOR if move["run"] else 1.0)), 0.5)
		if move["run"]:
			x_pending = false       # X se usó para correr, no abre el menú
		hold["moving"] = true
	elif _char_at(to) == "D" and data.has("puerta_tienda"):
		hold = {}
		var shop_id := str(data["puerta_tienda"])     # la puerta lleva a la tienda de cartas
		say("", data.get("puerta", ["Go to the Card Shop?"]), func(yes: bool) -> void:
			if yes:
				camp.open_shop(shop_id), true)
	elif _char_at(to) == "D" and data.has("puerta"):
		hold = {}
		say("", data["puerta"])      # la puerta no lleva a ningún lado todavía
	elif hold.get("bump", -1.0) < clock - 0.35:
		hold["bump"] = clock
		d.snd.play("error", 0.7)


var forced_dir := ""        # para las pruebas automáticas: dirección "apretada"
var forced_run := false     # para las pruebas automáticas: correr
var x_pending := false      # se tocó X: abre el menú al soltarla, salvo que se haya usado para correr
const WIN_TIME := 0.13      # lo que tarda una ventana en entrar o salir
var menu_t := 1.0           # el menú entrando (0 -> 1)
var menu_close_t := -1.0    # el menú saliendo (0 -> 1; -1 = nada)
var _dlg_ghost := {}        # el diálogo que se acaba de cerrar (sale hacia abajo)
var _dlg_ghost_t := -1.0
var _dlg_closed_at := -9.0


func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3)


## Dibuja algo corrido (ventanas que entran o salen).
func _draw_off(off: Vector2, f: Callable) -> void:
	if off.length() < 0.5:
		f.call()
		return
	d._base_off = off.round()
	d.draw_set_transform(d._base_off)
	f.call()
	d._base_off = Vector2.ZERO
	d.draw_set_transform(Vector2.ZERO)


func _close_dialog() -> void:
	var g := dialog.duplicate()
	g["typed"] = 99999.0
	_dlg_ghost = g
	_dlg_ghost_t = 0.0
	_dlg_closed_at = clock
	dialog = {}


func _close_menu() -> void:
	menu_open = false
	menu_close_t = 0.0


## Correr: Shift, o X (B en el joystick) mantenida mientras caminás.
func _running() -> bool:
	return forced_run or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_X) \
			or Input.is_joy_button_pressed(0, JOY_BUTTON_B)


func _held_dir() -> String:
	if forced_dir != "":
		return forced_dir
	for key in KEY_DIR:
		if Input.is_key_pressed(key):
			return KEY_DIR[key]
	var pads := {JOY_BUTTON_DPAD_DOWN: "down", JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_LEFT: "left",
			JOY_BUTTON_DPAD_RIGHT: "right"}
	for b in pads:
		if Input.is_joy_button_pressed(0, b):
			return pads[b]
	var ax := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ay := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if maxf(absf(ax), absf(ay)) > 0.5:
		if absf(ax) > absf(ay):
			return "right" if ax > 0 else "left"
		return "down" if ay > 0 else "up"
	return ""


## Al llegar a una casilla: salida o un rival que te ve. Devuelve true si pasó algo.
func _after_step() -> bool:
	var ex := _exit_at(pos)
	if not ex.is_empty() and ImgLoad.exists("res://data/mapas/%s.json" % str(ex.get("mapa", ""))):
		var to: Array = ex.get("a", [])
		var go := func():
			enter(str(ex["mapa"]))
			if to.size() >= 2:
				pos = Vector2i(int(to[0]), int(to[1]))
			if to.size() >= 3:
				dir = str(to[2])
		d._go(go, "door")
		return true
	for n in npcs:
		var def: Dictionary = n["def"]
		var rid: String = def.get("rival", "")
		var sight := int(def.get("vista", 0))
		if rid == "" or sight <= 0 or spotted.has(rid) or camp.st.beaten.get(rid, 0) > 0:
			continue
		if not camp.st.rival_available(rid):
			continue
		if _sees(n, sight):
			spotted[rid] = true
			n["move"] = {}
			alert = {"npc": n, "t": 0.0}
			d.snd.play("vs")
			return true
	return false


func _sees(n: Dictionary, sight: int) -> bool:
	var step: Vector2i = DIRS[n["dir"]]
	var c: Vector2i = n["pos"]
	for i in sight:
		c += step
		if c == pos:
			return true
		if not LEGEND.get(_char_at(c), [0, false])[1] or _npc_at(c) != null:
			return false
	return false


## El rival que te vio camina hasta quedar al lado tuyo y te habla.
func _update_approach() -> void:
	var n: Dictionary = approach["npc"]
	if not n["move"].is_empty():
		return
	var diff: Vector2i = pos - n["pos"]
	if absi(diff.x) + absi(diff.y) <= 1:
		dir = _opposite(n["dir"])
		approach = {}
		n["volver"] = 0.5
		_talk_to(n)
		return
	var to: Vector2i = n["pos"] + DIRS[n["dir"]]
	if to == pos or not LEGEND.get(_char_at(to), [0, false])[1]:
		dir = _opposite(n["dir"])
		approach = {}
		n["volver"] = 0.5
		_talk_to(n)
		return
	n["move"] = {"from": n["pos"], "to": to, "t": 0.0}


func _update_npcs(delta: float) -> void:
	for n in npcs:
		if not n["move"].is_empty():
			n["move"]["t"] += delta / STEP_TIME
			if n["move"]["t"] >= 1.0:
				n["pos"] = n["move"]["to"]
				n["move"] = {}
			continue
		if not dialog.is_empty() or not approach.is_empty() or not alert.is_empty():
			continue
		if n.has("volver"):
			_walk_home(n, delta)
			continue
		if not n["def"].get("pasea", false):
			_look_around(n, delta)
			continue
		n["wait"] -= delta
		if n["wait"] > 0.0:
			continue
		var mon: bool = n["def"].get("pokemon", false)      # los Pokémon son más inquietos y van más lejos
		n["wait"] = _rng.randf_range(0.5, 1.6) if mon else _rng.randf_range(1.2, 3.0)
		var dd: String = DIRS.keys()[_rng.randi() % 4]
		n["dir"] = dd
		var to: Vector2i = n["pos"] + DIRS[dd]
		var home: Vector2i = n["home"]
		if absi(to.x - home.x) + absi(to.y - home.y) <= (3 if mon else 2) and _walkable(to) and to != pos \
				and (move.is_empty() or move["to"] != to):
			n["move"] = {"from": n["pos"], "to": to, "t": 0.0}


## Después de hablar (o de venir a desafiarte), el personaje vuelve caminando a su casilla
## y mira otra vez hacia donde miraba. Los que pasean solo retoman su paseo.
func _walk_home(n: Dictionary, delta: float) -> void:
	n["volver"] = float(n["volver"]) - delta
	if float(n["volver"]) > 0.0:
		return
	var def: Dictionary = n["def"]
	var home: Vector2i = n["home"]
	if def.get("pasea", false) or def.get("sentado", false) or n["pos"] == home:
		if not def.get("pasea", false):
			n["dir"] = str(def.get("dir", "down"))
		n.erase("volver")
		n["wait"] = _rng.randf_range(1.5, 3.0)
		return
	var diff: Vector2i = home - n["pos"]
	var tries: Array = []
	var dx := "right" if diff.x > 0 else "left"
	var dy := "down" if diff.y > 0 else "up"
	if absi(diff.y) >= absi(diff.x):
		tries = [dy, dx] if diff.x != 0 else [dy]
	else:
		tries = [dx, dy] if diff.y != 0 else [dx]
	for dd in tries:
		var to: Vector2i = n["pos"] + DIRS[dd]
		if _walkable(to) and to != pos and (move.is_empty() or move["to"] != to):
			n["dir"] = dd
			n["move"] = {"from": n["pos"], "to": to, "t": 0.0}
			return
	n["volver"] = 0.3          # algo lo tapa (por ejemplo, vos): prueba de nuevo en un rato


## Los que están quietos miran para los costados de vez en cuando (y vuelven a mirar
## hacia donde miraban). No lo hacen los sentados, los que tienen "quieto": true ni los
## rivales que te ven pasar ("vista"), para no cambiarles hacia dónde vigilan.
func _look_around(n: Dictionary, delta: float) -> void:
	var def: Dictionary = n["def"]
	if def.get("sentado", false) or def.get("quieto", false) or int(def.get("vista", 0)) > 0:
		return
	n["wait"] -= delta
	if n["wait"] > 0.0:
		return
	var home_dir: String = def.get("dir", "down")
	if n["dir"] != home_dir:
		n["dir"] = home_dir
		n["wait"] = _rng.randf_range(2.5, 5.5)
	else:
		var opts: Array = DIRS.keys().filter(func(x): return x != home_dir and x != _opposite(home_dir))
		n["dir"] = opts[_rng.randi() % opts.size()]
		n["wait"] = _rng.randf_range(0.8, 1.8)


# ===========================================================================
# Dibujo
# ===========================================================================

func _player_px() -> Vector2:
	if move.is_empty():
		return Vector2(pos) * TILE
	# Redondeado al píxel, igual que la cámara: así no tiembla contra el fondo
	return ((Vector2(move["from"]).lerp(Vector2(move["to"]), move["t"])) * TILE).round()


## "ajuste": [x, y] en el mapa corre el dibujo de un personaje unos píxeles (por ejemplo,
## para pegarlo a una mesa) sin cambiar la casilla que ocupa. Solo mientras está quieto en
## su lugar de siempre.
func _nudge(n: Dictionary) -> Vector2:
	var a = n["def"].get("ajuste", null)
	if not (a is Array) or a.size() < 2 or not n["move"].is_empty() or n["pos"] != n["home"]:
		return Vector2.ZERO
	return Vector2(float(a[0]), float(a[1]))


func _npc_px(n: Dictionary) -> Vector2:
	if n["move"].is_empty():
		return Vector2(n["pos"]) * TILE
	return (Vector2(n["move"]["from"]).lerp(Vector2(n["move"]["to"]), n["move"]["t"]) * TILE).round()


func draw() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color("#181018"))
	# Cámara centrada en el jugador, sin salirse del mapa
	var center := _player_px() + Vector2(TILE / 2.0, TILE / 2.0)
	var cam := (center - Vector2(d.W, d.H) / 2.0).round()
	cam.x = clampf(cam.x, 0.0, maxf(0.0, mw * TILE - d.W)) if mw * TILE > d.W else -(d.W - mw * TILE) / 2.0
	cam.y = clampf(cam.y, 0.0, maxf(0.0, mh * TILE - d.H)) if mh * TILE > d.H else -(d.H - mh * TILE) / 2.0
	cam = cam.round()
	if _bg != null:
		d.draw_texture(_bg, -cam)
	else:
		var x0 := int(floor(cam.x / TILE))
		var y0 := int(floor(cam.y / TILE))
		for ty in range(y0, y0 + d.H / TILE + 2):
			for tx in range(x0, x0 + d.W / TILE + 2):
				if ty < 0 or ty >= mh or tx < 0 or tx >= mw:
					continue
				_draw_tile(Vector2i(tx, ty), Vector2(tx * TILE, ty * TILE) - cam)
	# Personajes, de atrás hacia adelante
	var actors: Array = []
	for n in npcs:
		actors.append({"y": _npc_px(n).y, "px": _npc_px(n) + _nudge(n), "sprite": n["sprite"], "dir": n["dir"],
				"moving": not n["move"].is_empty(), "t": n["move"].get("t", 0.0),
				"frame": (n["pos"].x + n["pos"].y) % 2, "sit": n["def"].get("sentado", false) and n["move"].is_empty()})
	var run_now: bool = not move.is_empty() and move.get("run", false) and _has_sprite("jugador_corre")
	actors.append({"y": _player_px().y, "px": _player_px(), "sprite": "jugador_corre" if run_now else "jugador", "dir": dir,
			"moving": not move.is_empty(), "t": move.get("t", 0.0), "frame": walk_frame})
	for ty in _front:              # los muebles, entre los de atrás y los de adelante
		actors.append({"y": ty * TILE - 0.5, "front": ty})
	actors.sort_custom(func(a, b): return a["y"] < b["y"])
	_draw_flowers(cam)
	for a in actors:
		if a.has("front"):
			d.draw_texture(_front[a["front"]], Vector2(0, (a["front"] - 1) * TILE) - cam)
		else:
			_draw_actor(a, cam)
	_draw_field_fx(cam)
	_draw_wind_leaves()
	if not alert.is_empty():
		var p: Vector2 = _npc_px(alert["npc"]) - cam + Vector2(4, -30)
		var bob := -minf(alert["t"] * 30.0, 3.0)
		d.draw_rect(Rect2(p + Vector2(0, bob), Vector2(9, 12)), d.C_INK)
		d.draw_rect(Rect2(p + Vector2(1, 1 + bob), Vector2(7, 10)), Color.WHITE)
		d.draw_rect(Rect2(p + Vector2(4, 2 + bob), Vector2(2, 5)), Color("#e03828"))
		d.draw_rect(Rect2(p + Vector2(4, 8 + bob), Vector2(2, 2)), Color("#e03828"))
	_draw_banner()
	var mw := _menu_width() + 8.0
	if menu_open:
		_draw_off(Vector2((1.0 - _ease_out(menu_t)) * mw, 0), _draw_menu)
	elif menu_close_t >= 0.0:
		_draw_off(Vector2(pow(menu_close_t, 2) * mw, 0), _draw_menu)
	if not dialog.is_empty():
		_draw_off(Vector2(0, (1.0 - _ease_out(dialog.get("open", 1.0))) * 64.0), _draw_dialog)
	elif _dlg_ghost_t >= 0.0:
		dialog = _dlg_ghost
		_draw_off(Vector2(0, pow(_dlg_ghost_t, 2) * 64.0), _draw_dialog)
		dialog = {}


func _draw_tile(c: Vector2i, at: Vector2) -> void:
	var ch := _char_at(c)
	var idx: int = LEGEND.get(ch, [0, true])[0]
	if ch == "#":
		var below := _char_at(c + Vector2i(0, 1))
		idx = T_WALL_TOP if below in ["#", "E"] or c.y == mh - 1 else 4
	if ANIMATED.has(idx):
		idx += int(clock * 2.5 + c.x) % ANIMATED[idx]
	if ch == ".":
		var hsh := (c.x * 73 + c.y * 151 + c.x * c.y * 7) % 11
		if hsh < FLOOR_VARIANTS.size():
			idx = FLOOR_VARIANTS[hsh]
	if _tiles == null:
		d.draw_rect(Rect2(at, Vector2(TILE, TILE)), Color("#e8c8a0") if LEGEND.get(ch, [0, true])[1] else Color("#503028"))
		return
	if idx * TILE >= _tiles.get_width():
		idx = LEGEND.get(ch, [0, true])[0]
	d.draw_texture_rect_region(_tiles, Rect2(at, Vector2(TILE, TILE)), Rect2(idx * TILE, 0, TILE, TILE))
	# Sombra que proyectan las paredes y los muebles sobre el piso de abajo
	if LEGEND.get(ch, [0, false])[1]:
		var above := _char_at(c + Vector2i(0, -1))
		if not LEGEND.get(above, [0, false])[1]:
			var deep: bool = above in ["#", "E", "b"]
			d.draw_rect(Rect2(at, Vector2(TILE, 3 if deep else 2)), Color(0.2, 0.05, 0.05, 0.22 if deep else 0.14))
			if deep:
				d.draw_rect(Rect2(at + Vector2(0, 3), Vector2(TILE, 1)), Color(0.2, 0.05, 0.05, 0.1))


## Personaje de 16x32: los pies van sobre su casilla y la cabeza tapa la de atrás.
## (Si el PNG es de 16x16, como los primeros, se dibuja igual.)
func _draw_actor(a: Dictionary, cam: Vector2) -> void:
	var tile_at: Vector2 = (a["px"] - cam).round()
	var tex := _sprite(a["sprite"])
	var fh := SPRITE_H if tex != null and tex.get_height() >= SPRITE_H * 4 else TILE
	var feet := FEET if fh == SPRITE_H else 15
	var at := tile_at + Vector2(0, 13 - feet)      # pies 2 píxeles arriba del borde de la casilla
	if a.get("sit", false) and tex != null and fh == SPRITE_H:
		# Sentado en una silla: como en Rubí/Zafiro, el sprite entero encima de la silla
		# (sin sombra y un poco más arriba, para que quede sobre el asiento)
		d.draw_texture_rect_region(tex, Rect2(at + Vector2(0, SIT_DROP), Vector2(TILE, fh)),
				Rect2(0, DIR_ROW[a["dir"]] * fh, TILE, fh))
		return
	# Sombra ovalada bajo los pies
	var sh := tile_at + Vector2(0, 12)
	d.draw_rect(Rect2(sh + Vector2(4, 0), Vector2(8, 3)), Color(0.15, 0.05, 0.05, 0.28))
	d.draw_rect(Rect2(sh + Vector2(3, 1), Vector2(10, 1)), Color(0.15, 0.05, 0.05, 0.28))
	var col := 0
	if a["moving"]:
		col = (1 + a["frame"]) if a["t"] < 0.5 else 0
	if tex == null:
		d.draw_rect(Rect2(tile_at + Vector2(3, -12), Vector2(10, 24)), Color("#c03028"))
		return
	d.draw_texture_rect_region(tex, Rect2(at, Vector2(TILE, fh)), Rect2(col * TILE, DIR_ROW[a["dir"]] * fh, TILE, fh))


# ---------------------------------------------------------------------------
# Viento (mapas con "viento": true, como el patio)
# ---------------------------------------------------------------------------
# Cada 14 a 20 segundos pasa una ráfaga: hojitas (efectos/propios/hoja.png) que cruzan la
# pantalla girando, un soplido suave, y las flores se mecen (mundo/propios/ui/flor.png,
# 3 cuadros; la arma tools/armar_ui.py). Con esa tira, las flores del mapa ('f') se dibujan
# siempre con ella (quietas en el primer cuadro); sin la tira quedan las del fondo.

func _setup_wind() -> void:
	wind = {}
	next_wind = clock + _rng.randf_range(5.0, 9.0)
	_flowers = []
	if _flower_tex == null:
		for dir_path in ["res://mundo/propios/ui", "user://mundo/propios/ui"]:
			var p := "%s/flor.png" % dir_path
			if _flower_tex == null and ImgLoad.exists(p):
				_flower_tex = _load_tex(p)
	for y in mh:
		for x in mw:
			if _char_at(Vector2i(x, y)) != "f":
				continue
			var src := Vector2i(-1, -1)      # la casilla de pasto más cercana en la misma fila
			for dx in range(1, mw):
				for c: Vector2i in [Vector2i(x - dx, y), Vector2i(x + dx, y)]:
					if src.x < 0 and c.x >= 0 and c.x < mw and _char_at(c) == ",":
						src = c
				if src.x >= 0:
					break
			_flowers.append([Vector2i(x, y), src])


func _update_wind(delta: float) -> void:
	if not data.get("viento", false):
		return
	if wind.is_empty():
		if clock >= next_wind and dialog.is_empty() and not menu_open:
			var leaves: Array = []
			for i in 9:
				leaves.append({"y": _rng.randf_range(10.0, d.H - 30.0), "delay": _rng.randf_range(0.0, 1.0),
						"speed": _rng.randf_range(0.85, 1.2), "wob": _rng.randf_range(3.0, 8.0),
						"ph": _rng.randf_range(0.0, TAU), "fr": _rng.randi() % 5, "sc": _rng.randf_range(0.7, 1.0)})
			wind = {"t": 0.0, "leaves": leaves}
			d.snd.play("viento")
		return
	wind["t"] += delta
	if wind["t"] >= WIND_TIME:
		wind = {}
		next_wind = clock + _rng.randf_range(WIND_EVERY[0], WIND_EVERY[1])


## Cuánto sopla en la columna de píxeles x de la pantalla (0..1): el frente de la ráfaga
## avanza de izquierda a derecha.
func _wind_at(screen_x: float) -> float:
	if wind.is_empty():
		return 0.0
	var front: float = (wind["t"] / WIND_TIME) * (d.W + 120.0) - 40.0
	var k := clampf((front - screen_x) / 80.0, 0.0, 1.0)      # ya pasó el frente por acá
	var fade := clampf((WIND_TIME - wind["t"]) / 0.8, 0.0, 1.0)
	return k * fade


func _draw_flowers(cam: Vector2) -> void:
	if _flower_tex == null or _flowers.is_empty():
		return
	var n := maxi(1, int(_flower_tex.get_width() / 16))
	for fl in _flowers:
		var c: Vector2i = fl[0]
		var src: Vector2i = fl[1]
		var at := Vector2(c) * TILE - cam
		if at.x < -TILE or at.x > d.W or at.y < -TILE or at.y > d.H:
			continue
		if _bg != null and src.x >= 0:          # tapar las flores pintadas en el fondo
			d.draw_texture_rect_region(_bg, Rect2(at, Vector2(TILE, TILE)), Rect2(Vector2(src) * TILE, Vector2(TILE, TILE)))
		var fr := 0
		var w := _wind_at(at.x + TILE / 2.0)
		if w > 0.05:                             # se mece: 0 1 2 1 ...
			var seq := [0, 1, 2, 1]
			fr = seq[int(clock * (6.0 + 6.0 * w) + c.x * 0.7) % seq.size()] % n
		d.draw_texture_rect_region(_flower_tex, Rect2(at, Vector2(TILE, TILE)), Rect2(fr * 16, 0, 16, 16))


func _draw_wind_leaves() -> void:
	if wind.is_empty():
		return
	var t: float = wind["t"]
	for lf in wind["leaves"]:
		var u: float = (t - float(lf["delay"])) / (1.7 / float(lf["speed"]))
		if u < 0.0 or u > 1.0:
			continue
		var x: float = -12.0 + (d.W + 24.0) * u
		var y: float = float(lf["y"]) + sin(u * TAU * 1.5 + float(lf["ph"])) * float(lf["wob"]) + u * 10.0
		var p := Vector2(x, y).round()
		if SpecialFX.has_fx("hoja"):
			var fr := (int(t * 12.0) + int(lf["fr"])) % SpecialFX.fx_count("hoja")
			SpecialFX.fx_draw(d, "hoja", fr, p, float(lf["sc"]), 1.0, 0.0, int(lf["fr"]) % 2 == 0)
		else:
			d.draw_rect(Rect2(p, Vector2(3, 2)), Color("#78c050"))


# ---------------------------------------------------------------------------
# Pasto
# ---------------------------------------------------------------------------
# Al pisar pasto o flores saltan unas hojitas (efectos/propios/hoja.png) y se mueven unas
# briznas. Sin esa tira, se dibujan a mano.

func _spawn_fx(kind: String, c: Vector2i, _facing: String) -> void:
	var at := Vector2(c) * TILE + Vector2(TILE / 2.0, 12)
	field_fx.append({"kind": kind, "at": at, "t": 0.0, "flip": _rng.randi() % 2 == 0})


func _draw_field_fx(cam: Vector2) -> void:
	for f in field_fx:
		var p: Vector2 = (f["at"] - cam).round()
		var k: float = f["t"] / GRASS_TIME
		# Briznas que se doblan y vuelven
		var bend := sin(k * PI) * 2.5
		var gc := Color("#58a048")
		for i in 4:
			var bx := p.x - 6 + i * 4
			var h := 3.0 + (i % 2) * 2.0
			d.draw_line(Vector2(bx, p.y + 2), Vector2(bx + bend * (1 if i < 2 else -1), p.y + 2 - h), Color(gc, 1.0 - k * 0.6), 1.0)
		# Hojitas que saltan para los costados
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			var q := p + Vector2(side * (3.0 + k * 6.0), -4.0 - sin(k * PI) * 7.0)
			if SpecialFX.has_fx("hoja"):
				SpecialFX.fx_draw(d, "hoja", int(k * 8.0 + i * 2) % SpecialFX.fx_count("hoja"), q, 0.5, 1.0 - k, 0.0, side < 0)
			else:
				d.draw_rect(Rect2(q, Vector2(2, 1)), Color("#78c050", 1.0 - k))


## Cartel con el nombre del lugar al entrar (como en los juegos de GBA).
func _draw_banner() -> void:
	if banner_t > 2.2:
		return
	var k := 1.0
	if banner_t < 0.25:
		k = banner_t / 0.25
	elif banner_t > 1.9:
		k = 1.0 - (banner_t - 1.9) / 0.3
	var name: String = data.get("nombre", "")
	var w: float = d._text_w(name) + 20
	var r := Rect2(4, -24 + 28 * k, w, 20)
	d._frame(r)
	d._text(r.position + Vector2(10, 4), name, d.C_TEXT)


func _menu_width() -> float:
	var mw := 0.0
	for it in MENU_ITEMS:
		mw = maxf(mw, d._text_w(it))
	var w := mw + 26.0          # el ancho se ajusta al texto más largo
	return maxf(w, d._text_w("₽%d" % camp.st.money) + 26.0)


func _draw_menu() -> void:
	var w := _menu_width()
	var cash: String = "₽%d" % camp.st.money
	var r := Rect2(d.W - w - 4, 4, w, 12 + (MENU_ITEMS.size() + 1) * 13)
	d._frame(r)
	d._text(Vector2(r.position.x + 16, r.position.y + 6 + MENU_ITEMS.size() * 13), cash, d.C_DIM)    # tu dinero
	for i in MENU_ITEMS.size():
		var y := r.position.y + 6 + i * 13
		d._stripe(Rect2(r.position.x + 3, y - 2, r.size.x - 6, 13), i)
		if i == menu_cursor:
			d._text(Vector2(r.position.x + 6, y), "▶", d.C_TEXT)
		d._text(Vector2(r.position.x + 16, y), MENU_ITEMS[i], d.C_TEXT)


func _draw_dialog() -> void:
	var box := Rect2(0, 112, d.W, 48)
	var cards: Array = dialog.get("cards", [])
	var first := int(dialog.get("cards_at", 0))     # página del "You received ..." de la primera carta
	if not cards.is_empty() and dialog["page"] >= first:
		# La carta que recibiste, grande y con brillo, arriba del cuadro de texto
		var id: String = cards[mini(dialog["page"] - first, cards.size() - 1)]
		var pr := Rect2((d.W - 56) / 2.0, 40, 56, 56)
		var glow := 0.5 + 0.5 * sin(clock * 4.0)
		d.anim_ataques._draw_burst(pr.get_center(), 40.0 + glow * 4.0, Color(1, 0.95, 0.6, 0.35), 12)
		d._frame(pr.grow(4))
		d.imagenes._draw_card_image(pr, id)
	d._frame(box)
	var name: String = dialog["name"]
	if name != "":
		var tag := Rect2(4, 94, d._text_w(name) + 16, 21)     # el marco tiene 4 px de cada lado
		d._frame(tag)
		d._text(tag.position + Vector2(8, 5), name, Color("#c03028"))
	var txt: String = dialog["pages"][dialog["page"]]
	var shown := txt.substr(0, int(dialog["typed"]))
	var lines: Array = d._wrap(txt, box.size.x - 20)
	var used := 0
	for i in mini(3, lines.size()):
		var ln: String = lines[i]
		d._text(Vector2(9, box.position.y + 5 + i * 13), shown.substr(used, ln.length()), d.C_TEXT)
		used += ln.length() + 1
	var done: bool = dialog["typed"] >= txt.length()
	var last: bool = dialog["page"] == dialog["pages"].size() - 1
	if done and dialog.get("ask", false) and last:
		var q := Rect2(d.W - 52, 70, 48, 38)
		d._frame(q)
		for i in 2:
			var y := q.position.y + 6 + i * 13
			if (i == 0) == dialog["yes"]:
				d._text(Vector2(q.position.x + 6, y), "▶", d.C_TEXT)
			d._text(Vector2(q.position.x + 16, y), "Yes" if i == 0 else "No", d.C_TEXT)
	elif done:
		var bob := 1.0 if int(clock * 3.3) % 2 == 0 else 0.0
		d._text(Vector2(box.end.x - 15, box.end.y - 15 + bob), "▼", Color("#e03828"))
