## Arte de las cartas en alta resolución, para la ficha y la vista de galería.
##
## Busca, en este orden:
##   1. res://mundo/propios/arte/<id>.png|.jpg|.webp    imagen propia, solo el arte (ya recortada)
##   2. res://mundo/propios/cartas/<id>.png|.jpg|.webp  la carta entera propia (se recorta sola)
##   3. user://arte/<id>.png                            lo que ya se bajó antes
## Si no está, la baja una sola vez: primero de la base de cartas oficial (pokemon.com, que
## muestra el arte sin el brillo holográfico) y, si ahí no está, de images.pokemontcg.io.
## Recorta el recuadro del arte y lo guarda. Jugando desde el editor de Godot lo guarda en
## el proyecto (mundo/propios/arte/), así viaja dentro de cada exportación; en el juego
## exportado, en user://arte/. Sin conexión, sigue el recorte cuadrado de siempre.
## download_all() baja el de todas las cartas (Options > Card art).
class_name ArteHD
extends Node

signal listo(id: String)

const DIR := "user://arte"
const OWN_DIR := "res://mundo/propios/arte"
const OWN_CARDS := "res://mundo/propios/cartas"
const SOURCES := [
	"https://assets.pokemon.com/assets/cms2/img/cards/web/{SET}/{SET}_EN_{N}.png",
	"https://images.pokemontcg.io/{set}/{N}_hires.png",
]

var _http: HTTPRequest
var _queue: Array[String] = []
var _busy := ""
var _try := 0              # qué fuente de SOURCES se está probando
var batch_total := 0       # "bajar todo": cuántas había que bajar
var batch_done := 0        # y cuántas ya se intentaron
var batch_failed := 0
var _failed := {}          # id -> true si no se pudo bajar en esta sesión
var _cache := {}           # id -> Image
var _crop := {}            # supertipo -> [x0, y0, x1, y1] en proporciones de la carta


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_done)
	var raw := FileAccess.get_file_as_string("res://data/arte_recorte.json")
	var d: Variant = JSON.parse_string(raw) if raw != "" else null
	if d is Dictionary:
		_crop = d


## La imagen del arte si ya está a mano (propia o bajada); si no, null.
func image(id: String) -> Image:
	if _cache.has(id):
		return _cache[id]
	var img: Image = null
	for ext in ["png", "jpg", "webp"]:
		var own := "%s/%s.%s" % [OWN_DIR, id, ext]
		if FileAccess.file_exists(own):
			img = ImgLoad.load(own)
			break
	if img == null:
		for ext in ["png", "jpg", "webp"]:
			var whole := "%s/%s.%s" % [OWN_CARDS, id, ext]
			if FileAccess.file_exists(whole):
				var card := ImgLoad.load(whole)
				if card != null:
					img = crop(card, id)
				break
	if img == null and FileAccess.file_exists(_path(id)):
		img = Image.load_from_file(_path(id))
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
		_cache[id] = img
	return img


## Pide el arte: si no está, lo pone en la cola de descarga (una vez por sesión).
func want(id: String) -> void:
	if id == "" or image(id) != null or _failed.has(id) or id == _busy or id in _queue:
		return
	_queue.append(id)
	_next()


## "loading", "failed" o "" (listo o nunca pedido).
func state(id: String) -> String:
	if id == _busy or id in _queue:
		return "loading"
	if _failed.has(id):
		return "failed"
	return ""


func _path(id: String) -> String:
	if OS.has_feature("editor"):
		return "%s/%s.png" % [OWN_DIR, id]
	return "%s/%s.png" % [DIR, id]


## ¿Ya está el arte de esta carta (propio o bajado)? Sin cargar la imagen.
func has_art(id: String) -> bool:
	if _cache.has(id):
		return true
	for base in [OWN_DIR, OWN_CARDS]:
		for ext in ["png", "jpg", "webp"]:
			if FileAccess.file_exists("%s/%s.%s" % [base, id, ext]):
				return true
	return FileAccess.file_exists("%s/%s.png" % [DIR, id])


## Pone en cola el arte de todas las cartas que todavía no lo tienen.
func download_all() -> void:
	if batch_total > 0 and batch_done < batch_total:
		return
	batch_total = 0
	batch_done = 0
	batch_failed = 0
	for id in CardDB.all_ids():
		if not has_art(id) and not id in _queue and id != _busy:
			_failed.erase(id)
			_queue.append(id)
			batch_total += 1
	_next()


## "" si no se pidió bajar todo; si no, el progreso para mostrar en Options.
func batch_text() -> String:
	if batch_total == 0:
		return ""
	if batch_done < batch_total:
		return "%d/%d" % [batch_done, batch_total]
	return "Done" if batch_failed == 0 else "%d missing" % batch_failed


func _next() -> void:
	if _busy != "" or _queue.is_empty():
		return
	_busy = _queue.pop_front()
	_try = 0
	_request()


## Holo → su gemela sin holo (mismo set, nombre, PS y ataques): en Expedition las holo
## son 1-32 y las normales 33-64; en Aquapolis y Skyridge las holo son las "H". Así el
## arte se baja sin el brillo que tapa el fondo.
var _twins = null

func source_id(id: String) -> String:
	if _twins == null:
		_twins = {}
		var groups := {}
		for c in CardDB.all_ids():
			var d: Dictionary = CardDB.get_card(c)
			if d.get("supertype", "") != "Pokémon" or not str(c).begins_with("ecard"):
				continue
			var key := "%s|%s|%s|%s" % [d["set"], d["name"], d.get("hp", ""), str(d.get("attacks", []).map(func(a): return a["name"]))]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(c)
		for ids in groups.values():
			if ids.size() < 2:
				continue
			var plain: String = ""
			for c in ids:
				var num: String = str(c).split("-")[1]
				if not num.is_valid_int():
					continue
				if plain == "" or int(num) > int(plain.split("-")[1]):
					plain = c
			if plain != "":
				for c in ids:
					if c != plain:
						_twins[c] = plain
	return _twins.get(id, id)


func _request() -> void:
	var parts := source_id(_busy).split("-")
	if OS.has_feature("web") and _try == 0:
		_try = 1             # en el navegador, la página oficial no deja leer sus imágenes (CORS)
	while _try < SOURCES.size():
		if parts.size() >= 2:
			var url: String = SOURCES[_try].replace("{SET}", parts[0].to_upper()).replace("{set}", parts[0]).replace("{N}", parts[1])
			var err := _http.request(url)
			if err == OK:
				return
			print("arte: no se pudo pedir %s (error %d)" % [url, err])
		_try += 1
	_failed[_busy] = true
	_busy = ""
	if batch_total > 0:
		batch_done += 1
		batch_failed += 1
	_next()


func _done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var id := _busy
	var card := Image.new()
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and card.load_png_from_buffer(body) == OK:
		var art := crop(card, id)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_path(id).get_base_dir()))
		art.save_png(ProjectSettings.globalize_path(_path(id)))
		_cache[id] = art
		_busy = ""
		if batch_total > 0:
			batch_done += 1
		listo.emit(id)
		_next()
		return
	print("arte: %s falló (resultado %d, código %d)" % [id, result, code])
	_try += 1                # no estaba en esa fuente: probar la siguiente
	_request()


## Recorta el recuadro del arte de la carta escaneada entera. Las cartas de cada expansión
## están escaneadas a tamaños distintos (400x550, 600x835, 734x1024) y con bordes un poco
## distintos, así que se busca el marco plateado del arte cerca de donde debería estar
## (data/arte_recorte.json); el borde que no se encuentre usa esa medida.
func crop(card: Image, id: String) -> Image:
	card.convert(Image.FORMAT_RGBA8)
	var kind := "Energy"
	if CardDB.is_pokemon(id):
		kind = "Pokémon"
	elif CardDB.get_card(id).get("supertype", "") == "Trainer":
		kind = "Trainer"
	var ecard := id.begins_with("ecard") and kind != "Energy"
	var r: Array = _crop.get(("ecard " + kind) if ecard else kind, _crop.get(kind, [0.0, 0.0, 1.0, 1.0]))
	var w := card.get_width()
	var h := card.get_height()
	var g := [float(r[0]) * w, float(r[1]) * h, float(r[2]) * w, float(r[3]) * h]
	var rect := Rect2i(int(g[0]), int(g[1]), int(g[2] - g[0]), int(g[3] - g[1]))
	if kind != "Energy" and not ecard:       # e-card: sin marco plateado, va la medida tal cual
		rect = _detect(card, g)
	return card.get_region(rect)


const FRAME := 0.85        # fracción de píxeles plateados para considerar que una fila es el marco


func _silver(img: Image, x: int, y: int) -> bool:
	var c := img.get_pixel(x, y)
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	return mx > 0.647 and mx - mn < 0.157


func _row_frac(img: Image, y: int, x0: int, x1: int) -> float:
	var n := 0
	var t := 0
	for x in range(x0, x1, 2):
		t += 1
		if _silver(img, x, y):
			n += 1
	return float(n) / maxi(1, t)


func _col_frac(img: Image, x: int, y0: int, y1: int) -> float:
	var n := 0
	var t := 0
	for y in range(y0, y1, 2):
		t += 1
		if _silver(img, x, y):
			n += 1
	return float(n) / maxi(1, t)


## g: el recuadro esperado [izq, arriba, der, abajo] en píxeles de esta imagen.
func _detect(img: Image, g: Array) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var xa := int(g[0] + w * 0.05)
	var xb := int(g[2] - w * 0.05)
	var rowf := func(y: int) -> bool: return _row_frac(img, y, xa, xb) >= FRAME
	var top := _edge(rowf, g[1], h, 1)
	var bottom := _edge(rowf, g[3], h, -1)
	var ya := int(top + (bottom - top) * 0.1)
	var yb := int(bottom - (bottom - top) * 0.1)
	var colf := func(x: int) -> bool: return _col_frac(img, x, ya, yb) >= FRAME
	var left := _edge(colf, g[0], w, 1)
	var right := _edge(colf, g[2], w, -1)
	var inset := maxi(1, w / 200)     # un poquito adentro, para que no asome el marco
	return Rect2i(left + inset, top + inset, right - left - inset * 2, bottom - top - inset * 2)


## Busca la línea de marco más cercana a donde se espera el borde (hasta 3% de la carta) y
## la sigue hacia adentro hasta que empieza el arte. inward: +1 si el arte está hacia
## números más grandes (borde de arriba o izquierdo), -1 si no. Sin marco: lo esperado.
func _edge(is_frame: Callable, expected: float, size: int, inward: int) -> int:
	var reach := int(size * 0.03)
	var e := int(expected)
	for dist in reach + 1:
		for p in [e - dist, e + dist]:
			if p < 0 or p >= size or not is_frame.call(p):
				continue
			var q: int = p
			while q + inward >= 0 and q + inward < size and is_frame.call(q + inward):
				q += inward
			return q + inward
	return e
