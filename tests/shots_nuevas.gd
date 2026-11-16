extends SceneTree
## Capturas de: moneda inicial, pausa, controles, rendirse, resultados, editor y transición.
var out := "/home/claude/shots/nuevas"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 3) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	# Transición a mitad de camino
	scene._go(func(): pass)
	for i in 8:
		await process_frame
		if scene._trans.is_empty() or scene._trans["t"] > 0.3:
			break
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("00_transicion.png"))
	print("transicion t=", scene._trans.get("t", -1))
	scene._trans = {}
	scene._start_duel()
	scene.game.coin_winner = 1 - scene.human
	scene._rebuild_menu()
	await shot("01_cara_o_cruz")
	# Forzar que gane el humano para ver la elección
	scene.game.coin_winner = scene.human
	key(KEY_Z)
	scene.coin_anim["t"] = 0.75
	scene.coin_anim["per"] = 999.0
	await shot("02_moneda")
	scene.coin_anim["per"] = 0.01
	for i in 10: await process_frame
	await shot("03_quien_empieza")
	key(KEY_Z)
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	while g.phase == "setup":
		g.apply(ai.choose(g))
	scene.deck_anim = []
	scene.banner = {}
	g.current = scene.human
	scene.menu_level = "root"
	scene._rebuild_menu()
	key(KEY_P)
	await shot("04_pausa")
	key(KEY_DOWN); key(KEY_DOWN); key(KEY_DOWN); key(KEY_DOWN); key(KEY_DOWN)
	key(KEY_Z)
	await shot("05_controles")
	key(KEY_Z)
	key(KEY_DOWN)
	key(KEY_Z)
	await shot("06_rendirse")
	key(KEY_X)
	key(KEY_P)
	# Resultados: jugar con la IA un rato y terminar
	for step in 300:
		if g.phase == "over": break
		g.apply(ai.choose(g))
	if g.phase != "over":
		g.concede(1 - scene.human)
	scene.ko_seen = g.ko_log.size(); scene.prize_seen = g.prize_log.size(); scene.coins_seen = g.coin_log.size()
	scene.evo_seen = g.evolve_log.size(); scene.deck_seen = g.deck_log.size()
	scene.anim = {}; scene.ko_anim = []; scene.prize_anim = []; scene.coin_anim = {}; scene.energy_anim = []; scene.evo_anim = {}; scene.trainer_anim = {}
	await shot("07_resultados", 6)
	# Editor
	scene.mode = "editor"
	scene.editor.open()
	await shot("08_editor_lista")
	key(KEY_DOWN)
	key(KEY_Z)
	await shot("09_editor_mazo")
	key(KEY_TAB)
	key(KEY_DOWN); key(KEY_DOWN)
	await shot("10_editor_pokemon")
	Decks.delete_user(scene.editor.deck_name)     # no dejar el mazo de prueba guardado
	quit()
