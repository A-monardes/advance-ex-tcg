class_name RuleSet
extends RefCounted
## Reglas configurables por época. La idea del "viaje en el tiempo":
## cada preset reproduce cómo se jugaba en un momento concreto.

var name := ""
var prizes := 6
var bench_size := 5
var hand_size := 7
var deck_size := 60
var max_copies := 4
## Desde EX Ruby & Sapphire (2003) el primer jugador no roba en su primer turno.
var first_player_draws := false
## Tras el Mundial 2004 el primer jugador tampoco puede jugar Supporters en su primer turno.
var first_player_supporter := false
## Moneda inicial: true = el que la gana elige si empieza (2004-2005); false = empieza él.
var coin_winner_chooses := false
var confusion_self_damage := 30
var burn_damage := 20
var weakness_multiplier := 2
var resistance_value := 30
## Batalla doble (2 contra 2, variante "2-on-2" de la era EX): hasta 2 Activos por jugador y
## 4 en la Banca; un solo ataque por turno y una sola retirada.
var doubles := false
## Temporada (formato de torneo de ese año) y los sets que eran legales.
var season := ""
var legal_sets: Array = []
## Última Black Star Promo legal en la temporada (0 = todas).
var np_max := 0
## O la lista exacta de promos legales (2005-06: 027-033 y 035-036).
var np_ok: Array = []

## Temporadas de la era ADV, cada una con los sets legales y las reglas de ese año.
## "sets" en el orden en que salieron; los que todavía no están en el juego se marcan
## como "en construcción" en el título.
const SEASONS := [
	{"id": "2003-04", "name": "2003-04 · Expedition to Hidden Legends",
		"sets": ["ecard1", "ecard2", "ecard3", "ex1", "ex2", "ex3", "ex4", "ex5", "np"], "np_max": 26,
		"first_player_supporter": true, "coin_winner_chooses": false},
	{"id": "2004-05", "name": "2004-05 · Ruby & Sapphire to Emerald",
		"sets": ["ex1", "ex2", "ex3", "ex4", "ex5", "ex6", "ex7", "ex8", "ex9", "pop1", "np"], "np_max": 27,
		"first_player_supporter": false, "coin_winner_chooses": true},
	{"id": "2005-06", "name": "2005-06 · Hidden Legends to Holon Phantoms",
		"sets": ["ex5", "ex6", "ex7", "ex8", "ex9", "ex10", "ex11", "ex12", "ex13", "pop1", "pop2", "pop3", "np"],
		"np_ok": [27, 28, 29, 30, 31, 32, 33, 35, 36],
		"first_player_supporter": false, "coin_winner_chooses": true},
	# Mundial 2007 (DX-on): de EX Deoxys en adelante. Diamond & Pearl también era legal, pero
	# todavía no está en el juego.
	{"id": "2006-07", "name": "2006-07 · Deoxys to Power Keepers",
		"sets": ["ex8", "ex9", "ex10", "ex11", "ex12", "ex13", "ex14", "ex15", "ex16", "pop2", "pop3", "pop4", "pop5", "np"],
		"np_ok": [27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
		"first_player_supporter": false, "coin_winner_chooses": true},
]


static func ex_2003() -> RuleSet:
	var r := RuleSet.new()
	r.name = "EX 2003 (Ruby & Sapphire launch)"
	r.first_player_supporter = true
	return r


static func ex_2005() -> RuleSet:
	var r := RuleSet.new()
	r.name = "EX 2004-2007 (after Worlds 2004)"
	r.first_player_supporter = false
	r.coin_winner_chooses = true
	return r


static func from_season(i: int) -> RuleSet:
	var d: Dictionary = SEASONS[clampi(i, 0, SEASONS.size() - 1)]
	var r := RuleSet.new()
	r.season = d["id"]
	r.name = d["name"]
	r.legal_sets = d["sets"]
	r.np_max = int(d.get("np_max", 0))
	r.np_ok = d.get("np_ok", [])
	r.first_player_supporter = d["first_player_supporter"]
	r.coin_winner_chooses = d["coin_winner_chooses"]
	return r


## Sets de la temporada que todavía no están en el juego.
func missing_sets() -> Array:
	var have := {}
	for id in CardDB.all_ids():
		have[str(id).split("-")[0]] = true
	return legal_sets.filter(func(s): return not have.has(s))


## ¿La carta es legal en esta temporada? (sin temporada, todas)
## Las Energías básicas siempre lo son. Un Entrenador o Energía especial de un set viejo vale
## si tiene una reimpresión con el mismo nombre en un set legal (Potion, Switch...).
func is_legal(id: String) -> bool:
	if legal_sets.is_empty() or CardDB.is_basic_energy(id):
		return true
	if _printed_legal(id):
		return true
	if CardDB.is_pokemon(id):
		return false
	if _reprints.has(id):
		return _reprints[id]
	var ok := false
	var me := CardDB.get_card(id)
	for other in CardDB.all_ids():
		var c := CardDB.get_card(other)
		if c.get("name") == me.get("name") and _printed_legal(str(other)):
			ok = true
			break
	_reprints[id] = ok
	return ok


var _reprints := {}


func _printed_legal(id: String) -> bool:
	var p := id.split("-")
	if not p[0] in legal_sets:
		return false
	if p[0] != "np":
		return true
	if not np_ok.is_empty():
		return int(p[1]) in np_ok
	return np_max == 0 or int(p[1]) <= np_max


## Las cartas del mazo que no son legales en la temporada (sin repetir).
func illegal_cards(deck: Array) -> Array:
	var out: Array = []
	for id in deck:
		if not is_legal(str(id)) and not out.has(id):
			out.append(id)
	return out


## Copia independiente (la IA simula en copias de la partida; Giant Stump cambia el tamaño de la Banca).
func copy() -> RuleSet:
	var r := RuleSet.new()
	for prop in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not str(prop["name"]).begins_with("_"):
			var v = get(prop["name"])
			r.set(prop["name"], v.duplicate() if v is Array or v is Dictionary else v)
	return r


## Las mismas reglas, en batalla doble.
static func make_doubles(base: RuleSet) -> RuleSet:
	base.doubles = true
	base.bench_size = 4
	base.name += " · Double Battle"
	return base
