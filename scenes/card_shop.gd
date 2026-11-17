extends RefCounted
## La tienda de cartas: una pantalla aparte, como las tiendas clásicas de los juegos (la
## vendedora atrás del mostrador, el cuadro de texto abajo y las opciones al costado).
## Se entra desde una puerta del mapa ("puerta_tienda" en data/mapas/<mapa>.json) o
## hablándole a un personaje con "tienda". Lo que vende y lo que dice la vendedora está en
## data/campana.json -> "tiendas" (ver data/LEEME_CAMPANA.txt, punto 5).
##
## Imágenes (opcionales, en mundo/propios/ o mundo/fondos/; las arma tools/armar_tienda.py):
##   "fondo"    la pantalla entera de la tienda (240x160 ideal; otro tamaño se escala hasta
##              cubrirla). Si no está, se dibuja un local genérico.
##   "retrato"  la vendedora, encima del fondo. Con <retrato>.json al lado es una tira de
##              caras: {"celda": [w, h], "x", "y", "normal": 0, "parpadeo": [1, 2, 1],
##              "feliz": 3, "hablar": [4, 5, 6]}. Parpadea cada tantos segundos, mueve la
##              boca mientras escribe ("hablar": la versión con boca abierta de los cuadros
##              0, 1, 2...) y pone la cara "feliz" cuando comprás un sobre y cuando te
##              despedís. Sin retrato, una silueta.

const TYPE_SPEED := 45.0
const COUNTER_Y := 86.0           # borde de arriba del mostrador
const C_NAME := Color("#c03028")
const BLINK_STEP := 0.06          # segundos de cada cuadro del parpadeo
const HAPPY_AFTER := 0.9          # la sonrisa dura un poco más que el mensaje
const MOUTH_CHARS := 5            # letras que dura la boca abierta (o cerrada) al hablar

var d                             # pantalla de duelo (dibujo, texto, sonido)
var camp                          # campaña
var id := ""
var info := {}                    # data/campana.json -> "tiendas" -> id
var state := "talk"               # "talk" (texto), "menu", "buy"
var cursor := 0
var buy_cursor := 0
var msg := {}                     # {"pages", "page", "typed", "then", "ask", "yes"}
var prompt := ""                  # texto fijo del cuadro mientras se elige
var clock := 0.0
var _bg: Texture2D = null         # la imagen de la tienda (toda la pantalla)
var _clerk: Texture2D = null      # la vendedora (tira de caras)
var _clerk_info := {}             # <retrato>.json: celda, posición y qué cuadro es cada cara
var next_blink := 3.0             # cuándo parpadea (clock)
var blink_t := -1.0               # >= 0 mientras parpadea
var happy_until := 0.0            # hasta cuándo sonríe (clock)
var _rng := RandomNumberGenerator.new()
const WIN_TIME := 0.13            # lo que tarda una ventana en entrar
var win_t := 1.0                  # el menú o la lista entrando (0 -> 1)


func _init(duel, campaign) -> void:
	d = duel
	camp = campaign


## Abre la tienda (la campaña ya cambió a la pantalla "shop").
func open(shop_id: String) -> void:
	id = shop_id
	info = camp.st.data.get("tiendas", {}).get(shop_id, {})
	_bg = _find_tex(str(info.get("fondo", info.get("imagen", ""))))
	var rname := str(info.get("retrato", ""))
	_clerk = _find_tex(rname)
	_clerk_info = _find_json(rname)
	_rng.randomize()
	next_blink = clock + _rng.randf_range(2.0, 4.5)
	blink_t = -1.0
	happy_until = 0.0
	cursor = 0
	buy_cursor = 0
	var first: bool = camp.st.first_visit(shop_id)
	if first and info.has("primera_vez"):
		_say(_lines("primera_vez", []), _to_menu)     # la primera vez que entrás, otro saludo
	else:
		_say(_lines("hola", ["Welcome to the Card Shop!"]), _to_menu)


## Volviendo de abrir un sobre comprado.
func back_from_pack() -> void:
	_to_menu(true)


func _find_tex(name: String) -> Texture2D:
	if name == "":
		return null
	for dir_path in ["res://mundo/propios", "user://mundo/propios", "res://mundo/fondos", "user://mundo/fondos"]:
		var p := "%s/%s.png" % [dir_path, name]
		if ImgLoad.exists(p):
			var img := ImgLoad.load(p)
			if img != null and not img.is_empty():
				return ImageTexture.create_from_image(img)
	return null


func _find_json(name: String) -> Dictionary:
	if name == "":
		return {}
	for dir_path in ["res://mundo/propios", "user://mundo/propios", "res://mundo/fondos", "user://mundo/fondos"]:
		var p := "%s/%s.json" % [dir_path, name]
		if ImgLoad.exists(p):
			var v = JSON.parse_string(FileAccess.get_file_as_string(p))
			if v is Dictionary:
				return v
	return {}


## Frases de la tienda: una lista, o un texto solo.
func _lines(key: String, def: Array) -> Array:
	var v = info.get(key, def)
	return v if v is Array else [str(v)]


func clerk() -> String:
	return str(info.get("vendedora", ""))


func _menu_items() -> Array:
	var items := ["BUY"]
	if info.has("charla"):
		items.append("TALK")
	items.append("EXIT")
	return items


func _items() -> Array:
	return camp.st.shop_items(id)


func _label(it: Dictionary) -> String:
	var set_id := str(it.get("sobre", ""))
	return str(it.get("nombre", camp.SET_NAMES.get(set_id, set_id) + " pack"))


# ===========================================================================
# Texto
# ===========================================================================

## happy = true: la vendedora sonríe mientras lo dice (y un poquito después).
func _say(pages: Array, then: Callable = Callable(), ask: bool = false, happy: bool = false) -> void:
	state = "talk"
	msg = {"pages": pages.map(func(x): return camp.fmt(str(x))), "page": 0, "typed": 0.0, "then": then,
			"ask": ask, "yes": true, "happy": happy}


func _to_menu(again: bool = false) -> void:
	if state != "menu":
		win_t = 0.0
	state = "menu"
	msg = {}
	var key := "otra_cosa" if again else "pregunta"
	prompt = camp.fmt(str(_lines(key, ["Is there anything else?"] if again else ["What would you like?"])[0]))


func _msg_input(k: int, accept: bool, back: bool) -> void:
	var full: String = msg["pages"][msg["page"]]
	var last: bool = msg["page"] == msg["pages"].size() - 1
	if msg["ask"] and last and msg["typed"] >= full.length():
		if k in [KEY_UP, KEY_DOWN]:
			msg["yes"] = not msg["yes"]
			d.snd.play("move")
		if back:
			msg["yes"] = false
		if accept or back:
			d.snd.play("ok" if msg["yes"] else "back")
			var then: Callable = msg["then"]
			var yes: bool = msg["yes"]
			msg = {}
			then.call(yes)
		return
	if not (accept or back):
		return
	if msg["typed"] < full.length():
		msg["typed"] = float(full.length())
		return
	if not last:
		msg["page"] += 1
		msg["typed"] = 0.0
		return
	var then: Callable = msg["then"]
	msg = {}
	if then.is_valid():
		then.call()


# ===========================================================================
# Teclas
# ===========================================================================

func input(event: InputEventKey) -> void:
	var k := event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo
	var back := k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE] and not event.echo
	if not msg.is_empty():
		_msg_input(k, accept, back)
		return
	match state:
		"menu": _menu_input(k, accept, back)
		"buy": _buy_input(k, accept, back)


func _menu_input(k: int, accept: bool, back: bool) -> void:
	var items := _menu_items()
	if k == KEY_UP or k == KEY_DOWN:
		cursor = (cursor + (1 if k == KEY_DOWN else items.size() - 1)) % items.size()
		d.snd.play("move")
	var pick: String = "EXIT" if back else (items[cursor] if accept else "")
	match pick:
		"BUY":
			d.snd.play("ok")
			state = "buy"
			win_t = 0.0
		"TALK":
			d.snd.play("ok")
			_say(_lines("charla", ["..."]), _to_menu.bind(true))
		"EXIT":
			d.snd.play("back" if back else "ok")
			_say(_lines("adios", ["Please come again!"]), camp.leave_shop, false, true)


func _buy_input(k: int, accept: bool, back: bool) -> void:
	var n := _items().size() + 1          # + "CANCEL"
	if k == KEY_UP or k == KEY_DOWN:
		buy_cursor = (buy_cursor + (1 if k == KEY_DOWN else n - 1)) % n
		d.snd.play("move")
	if back or (accept and buy_cursor == n - 1):
		d.snd.play("back")
		_to_menu(true)
		return
	if not accept:
		return
	d.snd.play("ok")
	var it: Dictionary = _items()[buy_cursor]
	var price := int(it.get("precio", 0))
	var ask := str(_lines("confirmar", ["{sobre}? That will be ₽{precio}. OK?"])[0])
	ask = ask.replace("{sobre}", _label(it)).replace("{precio}", str(price))
	_say([ask], func(yes: bool) -> void:
		if not yes:
			_to_menu(true)
		elif not camp.st.buy(price):
			d.snd.play("error")
			_say(_lines("sin_dinero", ["Sorry, you don't have enough money."]), _to_menu.bind(true))
		else:
			if not d.snd.fx(["comprar"]):
				d.snd.play("prize")
			var set_id := str(it.get("sobre", "ex1"))
			_say(_lines("gracias", ["Here you go! Thank you!"]), func(): d._go(func(): camp.open_bought_pack(set_id)), false, true)
	, true)


func update(delta: float) -> void:
	clock += delta
	if msg.get("happy", false):
		happy_until = clock + HAPPY_AFTER
	if blink_t >= 0.0:
		blink_t += delta
		if blink_t >= BLINK_STEP * _blink_frames().size():
			blink_t = -1.0
			next_blink = clock + _rng.randf_range(2.0, 5.0)
	elif clock >= next_blink:
		blink_t = 0.0
	win_t = minf(1.0, win_t + minf(delta, 1.0 / 30.0) / WIN_TIME)
	if not msg.is_empty():
		var full: String = msg["pages"][msg["page"]]
		var before := int(msg["typed"])
		msg["typed"] = minf(msg["typed"] + delta * TYPE_SPEED, full.length())
		var now := int(msg["typed"])
		if now != before and now % 2 == 0 and full.substr(now - 1, 1) != " ":
			d.snd.play("blip")


# ===========================================================================
# Dibujo
# ===========================================================================

func draw() -> void:
	if _bg != null:
		_draw_image()
	else:
		_draw_room()
	if _clerk != null:
		_draw_portrait()
	elif _bg == null:
		_draw_clerk()
	if _bg == null:
		_draw_counter()
	_draw_money()
	var slide := -(1.0 - (1.0 - pow(1.0 - win_t, 3))) * 160.0     # entran desde la izquierda
	match state:
		"menu": _draw_off(Vector2(slide, 0), _draw_menu)
		"buy": _draw_off(Vector2(slide, 0), _draw_buy)
	_draw_box()


func _draw_off(off: Vector2, f: Callable) -> void:
	if absf(off.x) < 0.5:
		f.call()
		return
	d._base_off = off.round()
	d.draw_set_transform(d._base_off)
	f.call()
	d._base_off = Vector2.ZERO
	d.draw_set_transform(Vector2.ZERO)


## La imagen tapa toda la pantalla: escalada hasta cubrirla (sin deformar) y centrada.
## Si es de 240x160 (o 480x320, etc.) entra justa, sin recortar nada.
func _draw_image() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color.BLACK)
	var sz := _bg.get_size()
	var k: float = maxf(d.W / sz.x, d.H / sz.y)
	var w := sz.x * k
	var h := sz.y * k
	d.draw_texture_rect(_bg, Rect2((d.W - w) / 2.0, (d.H - h) / 2.0, w, h), false)


func _draw_room() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color("#e8d8b0"))
	for x in range(0, d.W, 16):                    # empapelado a rayas
		d.draw_rect(Rect2(x, 0, 8, COUNTER_Y), Color("#e0cfa4"))
	d.draw_rect(Rect2(0, 0, d.W, 6), Color("#a87850"))
	for shelf in 2:
		var y := 22.0 + shelf * 26
		for side in 2:
			var x0 := 6.0 if side == 0 else 160.0
			d.draw_rect(Rect2(x0, y + 18, 74, 4), Color("#8a5a34"))
			d.draw_rect(Rect2(x0, y + 22, 74, 1), Color("#5a3818"))
			var cols := [Color("#d84838"), Color("#3878d0"), Color("#48a048"), Color("#e8b030"), Color("#8858c0")]
			for i in 7:
				var c: Color = cols[(i + shelf * 2 + side) % cols.size()]
				var h := 14.0 - (i % 2) * 2
				var bx := x0 + 3 + i * 10
				d.draw_rect(Rect2(bx, y + 18 - h, 9, h), C_INK_SOFT)
				d.draw_rect(Rect2(bx + 1, y + 19 - h, 7, h - 1), c)
				d.draw_rect(Rect2(bx + 2, y + 21 - h, 5, 3), c.lightened(0.45))
	# Cartel arriba, en el medio
	var sign_r := Rect2(86, 10, 68, 14)
	d.draw_rect(sign_r.grow(1), C_INK_SOFT)
	d.draw_rect(sign_r, Color("#f8f0d8"))
	var title := str(info.get("nombre", "CARD SHOP")).to_upper()
	d._text(Vector2(sign_r.position.x + (sign_r.size.x - d._text_w(title)) / 2.0, sign_r.position.y + 1), title, C_NAME)


const C_INK_SOFT := Color("#503828")


func _draw_counter() -> void:
	d.draw_rect(Rect2(0, COUNTER_Y, d.W, 4), Color("#c89058"))
	d.draw_rect(Rect2(0, COUNTER_Y + 4, d.W, d.H - COUNTER_Y - 4), Color("#9a6438"))
	d.draw_rect(Rect2(0, COUNTER_Y + 4, d.W, 1), Color("#5a3818"))
	for x in range(10, d.W, 40):
		d.draw_rect(Rect2(x, COUNTER_Y + 8, 1, d.H - COUNTER_Y), Color("#7a4c28"))
	# Una vitrina con sobres sobre el mostrador
	for i in 3:
		var bx := 20.0 + i * 12
		d.draw_rect(Rect2(bx, COUNTER_Y - 12, 10, 13), C_INK_SOFT)
		d.draw_rect(Rect2(bx + 1, COUNTER_Y - 11, 8, 11), [Color("#d84838"), Color("#3878d0"), Color("#e8b030")][i])


func _blink_frames() -> Array:
	var f = _clerk_info.get("parpadeo", [])
	return f if f is Array and not f.is_empty() else [0]


## Qué cara pone ahora: contenta, parpadeando o normal.
func face() -> int:
	if clock < happy_until or msg.get("happy", false):
		return int(_clerk_info.get("feliz", _clerk_info.get("normal", 0)))
	if blink_t >= 0.0:
		var f := _blink_frames()
		return _talk_face(int(f[mini(int(blink_t / BLINK_STEP), f.size() - 1)]))
	return _talk_face(int(_clerk_info.get("normal", 0)))


## Mientras escribe, abre y cierra la boca (se cierra en los espacios y en la puntuación).
func _talk_face(base: int) -> int:
	var open = _clerk_info.get("hablar", [])
	if not (open is Array) or base < 0 or base >= open.size() or msg.is_empty():
		return base
	var full: String = msg["pages"][msg["page"]]
	var n := int(msg["typed"])
	if n >= full.length():
		return base
	var ch := full.substr(n, 1)
	if ch in [" ", ".", ",", "!", "?", "\n"] or int(n / float(MOUTH_CHARS)) % 2 == 1:
		return base
	var cell = _clerk_info.get("celda", [1, 1])
	if _clerk == null or int(open[base]) >= int(_clerk.get_size().x / float(cell[0])):
		return base     # una tira vieja sin las caras con boca abierta
	return int(open[base])


## La vendedora: un cuadro de la tira (o la imagen entera si no hay .json).
func _draw_portrait() -> void:
	var sz := _clerk.get_size()
	var cell = _clerk_info.get("celda", null)
	if not (cell is Array) or cell.size() < 2:
		var x0: float = (d.W - sz.x) / 2.0
		d.draw_texture(_clerk, Vector2(x0, maxf(0.0, 112.0 - sz.y)))
		return
	var cw := float(cell[0])
	var ch := float(cell[1])
	var n := maxi(1, int(sz.x / cw))
	var i := clampi(face(), 0, n - 1)
	var at: Vector2 = Vector2(float(_clerk_info.get("x", (d.W - cw) / 2.0)), float(_clerk_info.get("y", 0)))
	d.draw_texture_rect_region(_clerk, Rect2(at, Vector2(cw, ch)), Rect2(i * cw, 0, cw, ch))


## Sin imagen: una silueta donde va la vendedora.
func _draw_clerk() -> void:
	var cx: float = d.W / 2.0
	var bottom := COUNTER_Y + 10.0
	var sil := Color("#6a6070")
	d.draw_circle(Vector2(cx, bottom - 58), 13.0, sil)
	d.draw_colored_polygon(PackedVector2Array([Vector2(cx - 12, bottom - 44), Vector2(cx + 12, bottom - 44),
			Vector2(cx + 26, bottom), Vector2(cx - 26, bottom)]), sil)
	d._text(Vector2(cx - d._text_w("?") / 2.0, bottom - 64), "?", Color("#e8d8b0"))


func _draw_money() -> void:
	var cash := "₽%d" % camp.st.money
	var r := Rect2(4, 4, maxf(64.0, d._text_w(cash) + 32), 18)
	d._frame(r)
	d._text(Vector2(r.position.x + 7, r.position.y + 2), "₽", d.C_TEXT)
	d._text(Vector2(r.end.x - 8 - d._text_w(cash.substr(1)), r.position.y + 2), cash.substr(1), d.C_TEXT)


func _draw_menu() -> void:
	var items := _menu_items()
	var r := Rect2(4, 98 - items.size() * 14 - 8, 58, items.size() * 14 + 8)
	d._frame(r)
	for i in items.size():
		var y := r.position.y + 4 + i * 14
		if i == cursor:
			d._text(Vector2(r.position.x + 6, y), "▶", d.C_TEXT)
		d._text(Vector2(r.position.x + 16, y), items[i], d.C_TEXT)


func _draw_buy() -> void:
	var items := _items()
	var r := Rect2(4, 24, 150, 10 + (items.size() + 1) * 13)
	d._frame(r)
	for i in items.size() + 1:
		var y := r.position.y + 4 + i * 13
		if i == buy_cursor:
			d._text(Vector2(r.position.x + 5, y), "▶", d.C_TEXT)
		if i == items.size():
			d._text(Vector2(r.position.x + 15, y), "CANCEL", d.C_TEXT)
			continue
		var it: Dictionary = items[i]
		var price := "₽%d" % int(it.get("precio", 0))
		var can: bool = camp.st.money >= int(it.get("precio", 0))
		var col: Color = d.C_TEXT if can else d.C_DIM
		var pw: float = d._text_w(price)
		d._text_fit(Vector2(r.position.x + 15, y), _label(it), col, r.size.x - 28 - pw)
		d._text(Vector2(r.end.x - 7 - pw, y), price, col)
	# El sobre marcado, a la derecha de la lista
	if buy_cursor < items.size():
		var set_id := str(items[buy_cursor].get("sobre", ""))
		var art := Rect2(r.end.x + 14 + (d.W - r.end.x - 14 - 60) / 2.0 - 4, 14, 60, 84)
		var bob := sin(clock * 3.0) * 1.5
		camp.draw_pack(Rect2(art.position + Vector2(0, bob), art.size), set_id, false)


func _draw_box() -> void:
	var box := Rect2(0, 112, d.W, 48)
	var txt := prompt
	var typed := 99999.0
	if not msg.is_empty():
		txt = msg["pages"][msg["page"]]
		typed = msg["typed"]
	elif state == "buy":
		var items := _items()
		if buy_cursor < items.size():
			var it: Dictionary = items[buy_cursor]
			var set_id := str(it.get("sobre", ""))
			txt = str(it.get("texto", "A booster pack of %s. 9 cards, at least one rare!" % camp.SET_NAMES.get(set_id, set_id)))
		else:
			txt = "Go back."
	d._frame(box)
	var who := clerk()
	if who != "" and (not msg.is_empty() or state == "menu"):
		var tag := Rect2(4, 94, d._text_w(who) + 16, 21)     # el marco tiene 4 px de cada lado
		d._frame(tag)
		d._text(tag.position + Vector2(8, 5), who, C_NAME)
	var shown := txt.substr(0, int(typed))
	var lines: Array = d._wrap(txt, box.size.x - 20)
	var used := 0
	for i in mini(3, lines.size()):
		var ln: String = lines[i]
		d._text(Vector2(9, box.position.y + 5 + i * 13), shown.substr(used, ln.length()), d.C_TEXT)
		used += ln.length() + 1
	if msg.is_empty() or typed < txt.length():
		return
	var last: bool = msg["page"] == msg["pages"].size() - 1
	if msg["ask"] and last:
		var q := Rect2(4, 56, 48, 38)
		d._frame(q)
		for i in 2:
			var y := q.position.y + 6 + i * 13
			if (i == 0) == msg["yes"]:
				d._text(Vector2(q.position.x + 6, y), "▶", d.C_TEXT)
			d._text(Vector2(q.position.x + 16, y), "YES" if i == 0 else "NO", d.C_TEXT)
	else:
		var bob := 1.0 if int(clock * 3.3) % 2 == 0 else 0.0
		d._text(Vector2(box.end.x - 15, box.end.y - 15 + bob), "▼", Color("#e03828"))
