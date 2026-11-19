class_name CardDB
extends RefCounted
## Base de datos de cartas (solo lectura). Se carga una vez desde data/cards_adv.json.

const DEFAULT_PATH := "res://data/cards_adv.json"

## Nombre japonés de cada set de la era ADV.
const SET_NAMES_JP := {
	"ex1": "ADV Expansion Pack", "ex2": "Miracle of the Desert", "ex3": "Rulers of the Heavens",
	"ex4": "Magma VS Aqua", "ex5": "Undone Seal",
}

static var _cards: Dictionary = {}


static func load_db(path: String = DEFAULT_PATH) -> void:
	if not _cards.is_empty():
		return
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "Could not open " + path)
	var arr: Array = JSON.parse_string(f.get_as_text())
	for c in arr:
		_cards[c["id"]] = c


static func count() -> int:
	return _cards.size()


static func all_ids() -> Array:
	return _cards.keys()


static func get_card(id: String) -> Dictionary:
	return _cards.get(id, {})


static func card_name(id: String) -> String:
	return get_card(id).get("name", "?")


static func subtypes(id: String) -> Array:
	return get_card(id).get("subtypes", [])


static func is_pokemon(id: String) -> bool:
	return get_card(id).get("supertype", "") == "Pokémon"


static func is_trainer(id: String) -> bool:
	return get_card(id).get("supertype", "") == "Trainer"


static func is_energy(id: String) -> bool:
	return get_card(id).get("supertype", "") == "Energy"


static func is_basic_energy(id: String) -> bool:
	return is_energy(id) and "Basic" in subtypes(id)


static func is_basic_pokemon(id: String) -> bool:
	return is_pokemon(id) and "Basic" in subtypes(id)


## Fósiles: Entrenadores que se juegan como Pokémon Básicos.
static func is_fossil(id: String) -> bool:
	return is_trainer(id) and get_card(id).has("hp")


## Lo que se puede bajar a la Banca desde la mano.
static func is_playable_basic(id: String) -> bool:
	return is_basic_pokemon(id) or is_fossil(id)


static func is_evolution(id: String) -> bool:
	return is_pokemon(id) and ("Stage 1" in subtypes(id) or "Stage 2" in subtypes(id))


static func is_supporter(id: String) -> bool:
	return is_trainer(id) and "Supporter" in subtypes(id)


static func is_stadium(id: String) -> bool:
	return is_trainer(id) and "Stadium" in subtypes(id)


static func is_pokemon_tool(id: String) -> bool:
	return is_trainer(id) and "Pokémon Tool" in subtypes(id)


static func is_tm(id: String) -> bool:
	return is_trainer(id) and "Technical Machine" in subtypes(id)


static func is_ex(id: String) -> bool:
	return "ex" in subtypes(id)


## Pokémon δ (Delta Species): "que tiene δ en su carta".
## Holon Veil (Ampharos δ) hace que las cartas de Pokémon de su dueño cuenten como δ
## (lo actualiza Abilities.refresh).
static var veil_delta := {}


static func is_delta(id: String) -> bool:
	return card_name(id).contains("δ") or veil_delta.has(id)


## Pokémon Holon's que se pueden unir como Energía desde la mano.
static func is_holon_energy(id: String) -> bool:
	return is_pokemon(id) and card_name(id).begins_with("Holon's ")


static func is_star(id: String) -> bool:
	return "Star" in subtypes(id)


## "Pokémon con dueño": Team Aqua's, Team Magma's, Rocket's...
static func has_owner(id: String) -> bool:
	return card_name(id).contains("'s ")


static func stage(id: String) -> int:
	var s := subtypes(id)
	if "Stage 2" in s:
		return 2
	if "Stage 1" in s:
		return 1
	return 0


static func evolves_from(id: String) -> String:
	return get_card(id).get("evolves_from", "")


## Nombre de archivo para una carta: Windows no admite "?" (Unown ? es ex10-question).
static func file_id(id: String) -> String:
	return id.replace("?", "question")


## La δ no forma parte del nombre para evolucionar: Charmeleon δ va sobre cualquier
## Charmander (con δ o sin), y Fearow sobre Spearow δ.
static func evo_name(n: String) -> String:
	return n.replace(" δ", "").replace("δ", "").strip_edges()


## ¿La carta evo evoluciona de un Pokémon que se llama base_name?
static func evolves_onto(evo: String, base_name: String) -> bool:
	var f := evolves_from(evo)
	return f != "" and evo_name(f) == evo_name(base_name)


static func types(id: String) -> Array:
	return get_card(id).get("types", [])


static func hp(id: String) -> int:
	return int(get_card(id).get("hp", 0))


## Tipo que da una Energía básica: "Fire Energy" -> "Fire"
static func basic_energy_type(id: String) -> String:
	return card_name(id).replace(" Energy", "")


## Busca el id de una carta por nombre (primera coincidencia, opcionalmente en un set).
static func find(card_name_: String, set_prefix: String = "") -> String:
	for id in _cards:
		if _cards[id]["name"] == card_name_ and (set_prefix == "" or id.begins_with(set_prefix + "-")):
			return id
	return ""


static func set_of(id: String) -> String:
	return id.split("-")[0]
