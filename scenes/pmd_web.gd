class_name PmdWeb
extends Node
## Versión web: los sprites de PMD no van dentro del paquete del juego (pesan demasiado),
## quedan como archivos sueltos en la página (carpeta pmd/). Al empezar un duelo se bajan
## los de los Pokémon de los dos mazos y se guardan en user://pmd (el navegador los
## recuerda para la próxima). data/pmd_web.json lista qué archivos tiene cada especie.

signal listo(sp: String)

const MANIFEST := "res://data/pmd_web.json"

var _files := {}           # especie -> [archivos]
var _queue: Array = []     # [especie, archivo]
var _busy := {}            # HTTPRequest -> [especie, archivo]
var _pool: Array[HTTPRequest] = []
var _base := ""
const PARALLEL := 6


func _ready() -> void:
	var j = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) if ImgLoad.exists(MANIFEST) else null
	if j is Dictionary:
		_files = j
	if OS.has_feature("web"):
		_base = str(JavaScriptBridge.eval("new URL('pmd/', window.location.href).href"))
	for i in PARALLEL:
		var h := HTTPRequest.new()
		h.timeout = 30.0
		add_child(h)
		h.request_completed.connect(_done.bind(h))
		_pool.append(h)


func enabled() -> bool:
	return _base != "" and not _files.is_empty()


## Pide las especies de estas cartas (las que todavía no están bajadas).
func want_cards(ids: Array) -> void:
	if not enabled():
		return
	var seen := {}
	for id in ids:
		if not CardDB.is_pokemon(id):
			continue
		for sp in BattleScene.species(CardDB.card_name(id)):
			var n: String = sp.trim_suffix("#shiny") + ("_shiny" if sp.ends_with("#shiny") else "")
			if _files.has(n):
				if not seen.has(n):
					seen[n] = true
					want(n)
				break


func want(sp: String) -> void:
	for f in _files.get(sp, []):
		var item := [sp, str(f)]
		if not ImgLoad.exists("%s/%s/%s" % [MiniBattle.USER_DIR, sp, f]) and not item in _queue \
				and not item in _busy.values():
			_queue.append(item)
	_next()


func _next() -> void:
	for h in _pool:
		if _queue.is_empty():
			return
		if _busy.has(h):
			continue
		var item: Array = _queue.pop_front()
		_busy[h] = item
		if h.request(_base + "%s/%s" % [item[0], item[1]]) != OK:
			_busy.erase(h)


func _done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray, h: HTTPRequest) -> void:
	var item: Array = _busy.get(h, [])
	_busy.erase(h)
	if item.is_empty():
		return
	var sp: String = item[0]
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		DirAccess.make_dir_recursive_absolute("%s/%s" % [MiniBattle.USER_DIR, sp])
		var f := FileAccess.open("%s/%s/%s" % [MiniBattle.USER_DIR, sp, item[1]], FileAccess.WRITE)
		if f != null:
			f.store_buffer(body)
			f.close()
	if not _queue.any(func(it): return it[0] == sp) and not _busy.values().any(func(it): return it[0] == sp):
		MiniBattle.forget(sp)
		listo.emit(sp)
	_next()
