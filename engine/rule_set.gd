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

## Temporadas de la era ADV, cada una con los sets legales y las reglas de ese año.
## "sets" en el orden en que salieron; los que todavía no están en el juego se marcan
## como "en construcción" en el título.
const SEASONS := [
	{"id": "2003-04", "name": "2003-04 · Expedition to Hidden Legends",
		"sets": ["ecard1", "ecard2", "ecard3", "ex1", "ex2", "ex3", "ex4", "ex5", "np"],
		"first_player_supporter": true, "coin_winner_chooses": false},
	{"id": "2004-05", "name": "2004-05 · Ruby & Sapphire to Emerald",
		"sets": ["ex1", "ex2", "ex3", "ex4", "ex5", "ex6", "ex7", "ex8", "ex9", "np"],
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
func is_legal(id: String) -> bool:
	return legal_sets.is_empty() or id.split("-")[0] in legal_sets


## Las mismas reglas, en batalla doble.
static func make_doubles(base: RuleSet) -> RuleSet:
	base.doubles = true
	base.bench_size = 4
	base.name += " · Double Battle"
	return base
