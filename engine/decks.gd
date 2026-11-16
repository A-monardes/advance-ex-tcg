class_name Decks
extends RefCounted
## Mazos: los predefinidos (data/decks.json) y los que arma el jugador
## (user://mis_mazos.json). Formato: {"nombre": {"description": "...", "cards": [[id, copias], ...]}}

const PATH := "res://data/decks.json"
const USER_PATH := "user://mis_mazos.json"

static var _decks: Dictionary = {}
static var _user: Dictionary = {}
static var _user_loaded := false


static func _load() -> void:
	if _decks.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		_decks = JSON.parse_string(f.get_as_text())
	if not _user_loaded:
		_user_loaded = true
		if FileAccess.file_exists(USER_PATH):
			var uf := FileAccess.open(USER_PATH, FileAccess.READ)
			var parsed = JSON.parse_string(uf.get_as_text())
			if parsed is Dictionary:
				_user = parsed


## Todos los mazos: primero los predefinidos y después los tuyos.
static func names() -> Array:
	_load()
	return _decks.keys() + _user.keys()


static func preset_names() -> Array:
	_load()
	return _decks.keys()


static func user_names() -> Array:
	_load()
	return _user.keys()


static func is_user(deck_name: String) -> bool:
	_load()
	return _user.has(deck_name)


static func description(deck_name: String) -> String:
	_load()
	var d: Dictionary = _user.get(deck_name, _decks.get(deck_name, {}))
	return str(d.get("description", ""))


## [[id, copias], ...]
static func entries(deck_name: String) -> Array:
	_load()
	var d: Dictionary = _user.get(deck_name, _decks.get(deck_name, {}))
	return d.get("cards", []).duplicate(true)


static func get_deck(deck_name: String) -> Array[String]:
	var out: Array[String] = []
	for entry in entries(deck_name):
		for i in int(entry[1]):
			out.append(str(entry[0]))
	return out


# --- Mazos del jugador ----------------------------------------------------------

static func save_user(deck_name: String, cards: Array, desc: String = "Custom deck") -> void:
	_load()
	_user[deck_name] = {"description": desc, "cards": cards}
	_write_user()


static func delete_user(deck_name: String) -> void:
	_load()
	_user.erase(deck_name)
	_write_user()


static func rename_user(old_name: String, new_name: String) -> bool:
	_load()
	if new_name == "" or new_name == old_name or _user.has(new_name) or _decks.has(new_name):
		return false
	var keys := _user.keys()
	var rebuilt := {}
	for k in keys:        # conserva el orden
		rebuilt[new_name if k == old_name else k] = _user[k]
	_user = rebuilt
	_write_user()
	return true


## Un nombre que todavía no exista: "Mi mazo 1", "Mi mazo 2"...
static func free_name(base: String) -> String:
	_load()
	if not _user.has(base) and not _decks.has(base):
		return base
	var i := 2
	while _user.has("%s %d" % [base, i]) or _decks.has("%s %d" % [base, i]):
		i += 1
	return "%s %d" % [base, i]


static func _write_user() -> void:
	var f := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_user, "  "))
