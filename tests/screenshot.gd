extends SceneTree
## Saca capturas de la pantalla de duelo (necesita un display; en Linux: xvfb-run).
## Uso: godot --script res://tests/screenshot.gd -- carpeta_de_salida

var out_dir := "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("captura: ", name)


func _key(scene: Node, code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)


func _run() -> void:
	var scene: Node2D = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	scene.my_deck = 0
	scene.opp_deck = 1
	await _shot("1_titulo")
	var ai := SimpleAI.new(11)
	# La IA juega por los dos hasta que el humano tenga un Poké-Power disponible.
	var found := false
	for attempt in 40:
		scene._start_duel()
		while scene.game.phase != "over":
			var g: Game = scene.game
			if g.actor() == 0 and g.phase == "main" and g.turn_number >= 5 \
					and g.legal_actions().any(func(a): return a["t"] == "power" or a["t"] == "attack"):
				found = g.legal_actions().any(func(a): return a["t"] == "power") or attempt > 30
				break
			g.apply(ai.choose(g))
		if found:
			break
	scene.menu_level = "root"
	scene._rebuild_menu()
	await _shot("2_menu")
	_key(scene, KEY_Z)
	await _shot("3_submenu")
	_key(scene, KEY_X)
	_key(scene, KEY_C)
	await _shot("4_ficha")
	_key(scene, KEY_C)
	scene.show_log = true
	await _shot("5_registro")
	scene.show_log = false
	_key(scene, KEY_M)
	_key(scene, KEY_DOWN)
	await _shot("6_mano")
	_key(scene, KEY_Z)
	await _shot("7_carta_de_la_mano")
	_key(scene, KEY_X)
	_key(scene, KEY_X)
	# Menú Entrenador (si hay alguno jugable)
	scene.menu_level = "root"
	scene._rebuild_menu()
	for i in scene.menu_items.size():
		if scene.menu_items[i].get("category", "") in ["Entrenador", "Energía"]:
			scene.cursor = i
			break
	_key(scene, KEY_Z)
	await _shot("8_menu_entrenador")
	_key(scene, KEY_X)
	scene.menu_level = "root"
	scene._rebuild_menu()
	_key(scene, KEY_D)
	await _shot("9_descarte")
	_key(scene, KEY_X)
	await _shot("10_tablero")
	quit()
