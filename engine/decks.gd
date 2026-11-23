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


## Mazos de la campaña (los primeros 46 mazos del juego): no salen en el duelo libre, los usan
## los rivales de la campaña. Se pueden editar desde el editor de mazos solo corriendo el
## juego desde Godot (ver save_preset).
static func is_campaign(deck_name: String) -> bool:
	_load()
	return bool(_decks.get(deck_name, {}).get("campaign", false))


static func campaign_names() -> Array:
	_load()
	return _decks.keys().filter(func(n): return bool(_decks[n].get("campaign", false)))


## ¿Se pueden guardar cambios en los mazos predefinidos? Solo corriendo el juego desde el
## editor de Godot (en la versión exportada o la web data/decks.json es de solo lectura).
static func presets_editable() -> bool:
	return OS.has_feature("editor")


## Guarda las cartas de un mazo predefinido en data/decks.json. Reescribe solo la lista
## "cards" de ese mazo y deja el resto del archivo como está.
static func save_preset(deck_name: String, cards: Array) -> bool:
	_load()
	if not presets_editable() or not _decks.has(deck_name):
		return false
	var txt := FileAccess.get_file_as_string(PATH)
	var i := txt.find("\n  %s: {" % JSON.stringify(deck_name))
	if i < 0:
		return false
	var c0 := txt.find("\"cards\": [", i)
	var c1 := txt.find("\n    ]", c0)
	if c0 < 0 or c1 < 0:
		return false
	var rows: Array = []
	var cur := ""
	for e in cards:
		var item := "[%s, %d]" % [JSON.stringify(str(e[0])), int(e[1])]
		var cand := item if cur == "" else cur + ", " + item
		if cur != "" and ("      " + cand + ",").length() > 80:
			rows.append(cur)
			cur = item
		else:
			cur = cand
	if cur != "":
		rows.append(cur)
	var body := ",\n".join(rows.map(func(r): return "      " + r))
	var new_txt := txt.substr(0, c0) + "\"cards\": [\n" + body + txt.substr(c1)
	var check = JSON.parse_string(new_txt)
	if not (check is Dictionary and check.has(deck_name)):
		return false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(new_txt)
	f.close()
	_decks[deck_name]["cards"] = cards.duplicate(true)
	return true


## Formato (temporada, "2003-04"...) de un mazo predefinido; "" si no tiene.
static func format_of(deck_name: String) -> String:
	_load()
	return str(_decks.get(deck_name, {}).get("format", ""))


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
