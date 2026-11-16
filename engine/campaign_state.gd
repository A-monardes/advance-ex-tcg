extends RefCounted
## Estado de la campaña: mazo inicial, colección de cartas, el mazo que usás, rivales
## vencidos, dónde estás y sobres. Los datos fijos (rivales, diálogos, mazos iniciales)
## están en data/campana.json; el progreso se guarda en user://campana.json.
##
## Las Energías básicas no se coleccionan: siempre hay todas las que quieras.

const DATA_PATH := "res://data/campana.json"
const RARITY_PATH := "res://data/rarezas.json"
const MAX_COPIES := 4

var save_path := "user://campana.json"
var data := {}
var rarity := {}
var starter := ""            # mazo inicial elegido ("" = campaña sin empezar)
var player_name := ""        # tu nombre de entrenador
var collection := {}         # id -> copias (sin contar Energías básicas)
var reverse := {}            # id -> cuántas de esas copias son reverse holo (solo se ven distinto)
var last_reverse := -1       # en el último sobre abierto, qué carta salió reverse holo
var gifts := {}              # regalos ya recibidos: id del regalo -> true
## Tus mazos: DECK_SLOTS lugares, cada uno {"nombre", "cartas": [[id, copias], ...]}. Todos
## se arman con la misma colección (una carta puede estar en varios). "deck" es el que está
## en uso (el que llevás a los duelos).
const DECK_SLOTS := 4
var decks: Array = []
var active_deck := 0
var deck: Array:
	get:
		_ensure_decks()
		return decks[active_deck]["cartas"]
	set(v):
		_ensure_decks()
		decks[active_deck]["cartas"] = v
var beaten := {}             # id de rival -> veces que le ganaste
var lost := {}               # id de rival -> veces que te ganó
var place := {}              # dónde quedaste: {"mapa", "x", "y", "dir"} ({} = el inicio)
var money := 0               # dinero (₽): se gana en los duelos y se gasta en las tiendas
var visited := {}            # tiendas en las que ya entraste: id -> true
var marks := {}              # marcas de eventos ("marcar" en los datos): id -> true
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	rarity = JSON.parse_string(FileAccess.get_file_as_string(RARITY_PATH))


# ===========================================================================
# Guardado
# ===========================================================================

func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not (d is Dictionary):
		return false
	starter = str(d.get("starter", ""))
	# Partidas de antes de los mazos Blaze/Torrent/Overgrow: el inicial viejo cuenta como el nuevo
	starter = {"Ruby": "Blaze", "Sapphire": "Torrent", "Forest Guardian": "Overgrow"}.get(starter, starter)
	player_name = str(d.get("nombre", ""))
	collection = {}
	for k in d.get("collection", {}):
		collection[k] = int(d["collection"][k])
	decks = []
	var saved = d.get("mazos", null)
	if saved is Array and not saved.is_empty():
		for m in saved:
			if m is Dictionary:
				decks.append({"nombre": str(m.get("nombre", "")), "cartas": m.get("cartas", [])})
		active_deck = clampi(int(d.get("mazo_activo", 0)), 0, decks.size() - 1)
	else:
		# Partida de antes de los mazos múltiples: el mazo que tenías queda en el lugar 1
		decks = [{"nombre": _starter_deck_name(str(d.get("starter", ""))), "cartas": d.get("deck", [])}]
		active_deck = 0
	_ensure_decks()
	gifts = d.get("regalos", {})
	reverse = {}
	for k in d.get("reverse", {}):
		reverse[k] = int(d["reverse"][k])
	beaten = {}
	for k in d.get("beaten", {}):
		beaten[k] = int(d["beaten"][k])
	place = d.get("lugar", {})
	lost = {}
	for k in d.get("perdidos", {}):
		lost[k] = int(d["perdidos"][k])
	money = int(d.get("dinero", 0))
	visited = d.get("visitas", {})
	marks = d.get("marcas", {})
	return starter != ""


func save() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"starter": starter, "nombre": player_name, "collection": collection, "reverse": reverse, "regalos": gifts, "deck": deck,
				"mazos": decks, "mazo_activo": active_deck, "beaten": beaten, "lugar": place, "dinero": money, "perdidos": lost, "visitas": visited, "marcas": marks}, "  "))


func reset() -> void:
	starter = ""
	player_name = ""
	collection = {}
	reverse = {}
	gifts = {}
	decks = []
	active_deck = 0
	_ensure_decks()
	beaten = {}
	lost = {}
	place = {}
	money = 0
	visited = {}
	marks = {}
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func is_started() -> bool:
	return starter != ""


## Empieza la campaña con uno de los mazos iniciales: sus cartas pasan a tu colección.
func start(starter_index: int, name: String = "") -> void:
	reset()
	player_name = name
	money = int(data.get("dinero_inicial", 0))
	var st: Dictionary = data["starters"][starter_index]
	starter = st["deck"]
	decks[0]["nombre"] = _starter_deck_name(starter)
	deck = Decks.entries(starter)
	for e in deck:
		if not CardDB.is_basic_energy(e[0]):
			collection[e[0]] = collection.get(e[0], 0) + int(e[1])
	save()


# ===========================================================================
# Consultas
# ===========================================================================

## La ficha de un rival, ya con la "variante" que corresponda según cómo va la partida.
func rival(id: String) -> Dictionary:
	return resolve(data.get("rivales", {}).get(id, {}), id)


# ===========================================================================
# Condiciones y variantes (ver data/GUIA_PERSONAJES.txt)
# ===========================================================================

## ¿Se cumplen todas las condiciones de req? subject: el rival del que se habla (para
## "ganadas" y "perdidas" sin nombre).
##   vencer / no_vencer      a quién le ganaste (o todavía no): "id" o ["id", "id"]
##   vencidos                a cuántos rivales distintos les ganaste (como mínimo)
##   ganadas / perdidas      cuántas veces le ganaste / te ganó ESTE rival (como mínimo)
##   ganadas_a / perdidas_a  lo mismo con otros: {"roja": 2, "jefe": 1}
##   regalo / sin_regalo     regalos recibidos (o no): "id" o lista
##   marca / sin_marca       marcas de eventos puestas con "marcar" (o no): "id" o lista
##   dinero                  tener al menos esa plata
##   visitaste               haber entrado a esa tienda: "bridgette"
##   inicial                 empezaste con ese mazo: "Blaze" o "Fire" (o una lista: cualquiera)
func cond_met(req, subject: String = "") -> bool:
	if not (req is Dictionary):
		return true
	for rid in _list(req.get("vencer", [])):
		if beaten.get(rid, 0) == 0:
			return false
	for rid in _list(req.get("no_vencer", [])):
		if beaten.get(rid, 0) > 0:
			return false
	if req.has("vencidos") and beaten.size() < int(req["vencidos"]):
		return false
	if req.has("ganadas") and beaten.get(subject, 0) < int(req["ganadas"]):
		return false
	if req.has("perdidas") and lost.get(subject, 0) < int(req["perdidas"]):
		return false
	var ga = req.get("ganadas_a", {})
	if ga is Dictionary:
		for rid in ga:
			if beaten.get(str(rid), 0) < int(ga[rid]):
				return false
	var pa = req.get("perdidas_a", {})
	if pa is Dictionary:
		for rid in pa:
			if lost.get(str(rid), 0) < int(pa[rid]):
				return false
	for gid in _list(req.get("regalo", [])):
		if not gifts.has(gid):
			return false
	for gid in _list(req.get("sin_regalo", [])):
		if gifts.has(gid):
			return false
	for m in _list(req.get("marca", [])):
		if not marks.has(m):
			return false
	for m in _list(req.get("sin_marca", [])):
		if marks.has(m):
			return false
	if req.has("dinero") and money < int(req["dinero"]):
		return false
	for shop_id in _list(req.get("visitaste", [])):
		if not visited.has(shop_id):
			return false
	var ini := _list(req.get("inicial", []))
	if not ini.is_empty() and not ini.any(func(x): return _is_starter(x)):
		return false
	return true


## Tipo del mazo inicial ("Fire", "Water", "Grass"), o "" si no empezaste.
func starter_title() -> String:
	for st in data.get("starters", []):
		if str(st.get("deck", "")) == starter:
			return str(st.get("titulo", ""))
	return ""


## ¿Empezaste la campaña con ese mazo inicial? Vale el nombre del mazo ("Blaze") o su tipo
## como se ve al elegirlo ("Fire"), sin importar mayúsculas.
func _is_starter(name: String) -> bool:
	var n := name.strip_edges().to_lower()
	if n == starter.to_lower():
		return true
	for st in data.get("starters", []):
		if str(st.get("deck", "")) == starter and str(st.get("titulo", "")).to_lower() == n:
			return true
	return false


func _list(v) -> Array:
	if v is Array:
		return v.map(func(x): return str(x))
	if v == null or str(v) == "":
		return []
	return [str(v)]


## Si los datos tienen "variantes", la primera cuya "si" se cumpla reemplaza las claves que
## trae (frases, mazo, nivel, premios...). Lo que no trae queda como en la ficha base.
func resolve(base: Dictionary, subject: String = "") -> Dictionary:
	var vars = base.get("variantes", [])
	if not (vars is Array) or vars.is_empty():
		return base
	for v in vars:
		if v is Dictionary and cond_met(v.get("si", {}), subject):
			var out := base.duplicate()
			out.erase("variantes")
			for k in v:
				if k == "si":
					continue
				# Un "regalo" sin "id" en la variante es el mismo regalo de base con algo
				# cambiado (por ejemplo solo las cartas): se combina con el de base.
				if k == "regalo" and v[k] is Dictionary and not v[k].has("id") and out.get("regalo") is Dictionary:
					var g: Dictionary = out["regalo"].duplicate()
					g.merge(v[k], true)
					out[k] = g
				else:
					out[k] = v[k]
			return out
	var plain := base.duplicate()
	plain.erase("variantes")
	return plain


## Pone una marca de evento (o varias): "marcar": "id" o ["id", "id"].
func mark(v) -> void:
	var changed := false
	for m in _list(v):
		if not marks.has(m):
			marks[m] = true
			changed = true
	if changed:
		save()


## Dónde empieza (o sigue) la campaña: {"mapa", "x", "y", "dir"}.
func start_place() -> Dictionary:
	if not place.is_empty():
		return place
	return data.get("inicio", {"mapa": "escuela"})


## ¿Se le puede pedir la revancha a un rival que ya venciste? Lo dice su "revancha_requiere"
## o, si no tiene, el "revanchas_requieren" general de data/campana.json (sin nada: siempre).
func rematch_available(rival_id: String) -> bool:
	var req = rival(rival_id).get("revancha_requiere", data.get("revanchas_requieren", {}))
	return gift_ready(req if req is Dictionary else {}, rival_id)


## Anota que un rival te ganó.
func record_loss(rival_id: String) -> void:
	lost[rival_id] = lost.get(rival_id, 0) + 1
	save()


## Un rival está disponible si se cumple su "requiere" (si no tiene, siempre).
func rival_available(rival_id: String) -> bool:
	return gift_ready(rival(rival_id).get("requiere", {}), rival_id)


func owned(id: String) -> int:
	if CardDB.is_basic_energy(id):
		return 99
	return int(collection.get(id, 0))


## Siempre DECK_SLOTS lugares (los que faltan, vacíos).
func _ensure_decks() -> void:
	while decks.size() < DECK_SLOTS:
		decks.append({"nombre": "", "cartas": []})


func _starter_deck_name(st: String) -> String:
	return (st.replace(" (Worlds 2004)", "") + " deck") if st != "" else "My deck"


## Nombre que se muestra de un lugar ("Deck 2" si no tiene nombre).
func deck_name(i: int) -> String:
	_ensure_decks()
	var n := str(decks[i]["nombre"]).strip_edges()
	return n if n != "" else "Deck %d" % (i + 1)


func deck_size(i: int) -> int:
	_ensure_decks()
	var n := 0
	for e in decks[i]["cartas"]:
		n += int(e[1])
	return n


func deck_cards(i: int = -1) -> Array[String]:
	_ensure_decks()
	var out: Array[String] = []
	for e in decks[active_deck if i < 0 else i]["cartas"]:
		for k in int(e[1]):
			out.append(str(e[0]))
	return out


func deck_errors(i: int = -1) -> Array[String]:
	_ensure_decks()
	var slot := active_deck if i < 0 else i
	var errs := Game.validate_deck(deck_cards(slot))
	var counts := {}
	for e in decks[slot]["cartas"]:
		counts[e[0]] = counts.get(e[0], 0) + int(e[1])
	for id in counts:
		if counts[id] > owned(id):
			errs.append("You have %d %s and the deck uses %d." % [owned(id), CardDB.card_name(id), counts[id]])
	return errs


## Cartas distintas de la colección (para el editor), más las Energías básicas.
func collection_ids() -> Array:
	var out: Array = []
	for id in collection:
		if collection[id] > 0:
			out.append(id)
	for id in CardDB.all_ids():
		if CardDB.is_basic_energy(id) and id.begins_with("ex1-"):
			out.append(id)
	return out


func total_cards() -> int:
	var n := 0
	for id in collection:
		n += int(collection[id])
	return n


# ===========================================================================
# Recompensas y sobres
# ===========================================================================

## Anota la victoria y devuelve la recompensa: {"packs", "set", "cards", "first"}.
## La primera vez da los "sobres" del rival (de la expansión "sobre") y sus "cartas" (ids
## de cartas que pasan directo a tu colección); las revanchas dan "revancha" sobres (del
## rival o, si no tiene, el de data/campana.json -> recompensas).
func record_win(rival_id: String) -> Dictionary:
	var first: bool = beaten.get(rival_id, 0) == 0
	var r := rival(rival_id)            # con la variante de ANTES de esta victoria
	beaten[rival_id] = beaten.get(rival_id, 0) + 1
	var rematch := int(r.get("revancha", data.get("recompensas", {}).get("revancha", 1)))
	var cards: Array = []
	if first:
		for id in r.get("cartas", []):
			if not CardDB.get_card(str(id)).is_empty():
				cards.append(str(id))
				collection[str(id)] = collection.get(str(id), 0) + 1
	var cash := int(r.get("dinero", 0)) if first else int(r.get("dinero_revancha", 0))
	money += cash
	var out := {"packs": int(r.get("sobres", 1)) if first else rematch, "set": str(r.get("sobre", "ex1")),
			"cards": cards, "first": first, "money": cash}
	save()
	return out


## Abre un sobre de la expansión, como los de la época: 4 comunes, 3 infrecuentes, una carta
## reverse holo (de cualquier rareza menos ex y secretas; casi siempre común o infrecuente) y
## 1 rara (a veces holo o ex). Las secret rare no salen en sobres: son regalos. Las cartas se suman a la colección; last_reverse dice cuál
## salió reverse holo.
func open_pack(set_id: String) -> Array[String]:
	var by := {}
	for id in rarity:
		if not id.begins_with(set_id + "-") or CardDB.get_card(id).is_empty() or CardDB.is_basic_energy(id):
			continue
		var r: String = rarity[id]
		if not by.has(r):
			by[r] = []
		by[r].append(id)
	var out: Array[String] = []
	for i in 4:
		out.append(_pick(by, ["Common"]))
	for i in 3:
		out.append(_pick(by, ["Uncommon", "Common"]))
	var rv := rng.randf()
	var rev_kind := ["Common"] if rv < 0.6 else (["Uncommon", "Common"] if rv < 0.9 else ["Rare", "Rare Holo", "Uncommon"])
	out.append(_pick(by, rev_kind))
	var rev_id: String = out[out.size() - 1]
	var rev_at := out.slice(0, out.size() - 1).filter(func(x): return x != "").size()   # su lugar sin huecos
	var roll := rng.randf()
	var rare_kind := ["Rare", "Rare Holo"]
	if roll >= 0.62:
		rare_kind = ["Rare Holo", "Rare"]
	if roll >= 0.92:
		rare_kind = ["Rare Holo EX", "Rare Holo"]
	# Las secret rare no salen en los sobres: son regalos de personajes (ver give_gift).
	out.append(_pick(by, rare_kind))
	out = out.filter(func(x): return x != "")
	last_reverse = rev_at if rev_id != "" else -1
	if last_reverse >= 0:
		reverse[rev_id] = reverse.get(rev_id, 0) + 1
	for id in out:
		collection[id] = collection.get(id, 0) + 1
	save()
	return out


func _pick(by: Dictionary, kinds: Array) -> String:
	for k in kinds:
		var pool: Array = by.get(k, [])
		if not pool.is_empty():
			return pool[rng.randi() % pool.size()]
	return ""


# ===========================================================================
# Tiendas
# ===========================================================================

## Lo que vende una tienda (data/campana.json -> "tiendas" -> id): [{"sobre", "precio"}, ...].
func shop_items(shop_id: String) -> Array:
	return data.get("tiendas", {}).get(shop_id, {}).get("sobres", [])


## ¿Es la primera vez que entrás a esta tienda? La anota como visitada (y guarda).
func first_visit(shop_id: String) -> bool:
	if visited.has(shop_id):
		return false
	visited[shop_id] = true
	save()
	return true


## Compra un sobre: descuenta el precio si alcanza. Devuelve false si no alcanza.
## (El sobre se abre aparte, con open_pack.)
func buy(price: int) -> bool:
	if price < 0 or money < price:
		return false
	money -= price
	save()
	return true


# ===========================================================================
# Regalos (por ejemplo, las secret rare)
# ===========================================================================

## ¿Se cumple lo que se pide? {"vencer": "alumno"} o {"vencer": ["alumno", "alumna"]}
## (rivales a los que hay que haberles ganado), {"vencidos": 3} (cuántos rivales distintos);
## sin nada, siempre.
func gift_ready(req: Dictionary, subject: String = "") -> bool:
	return cond_met(req, subject)


## Da las cartas del regalo una sola vez. Devuelve false si ya lo habías recibido.
func give_gift(gift_id: String, cards: Array) -> bool:
	if gifts.has(gift_id):
		return false
	gifts[gift_id] = true
	for id in cards:
		collection[id] = collection.get(id, 0) + 1
	save()
	return true
