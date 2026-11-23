extends SceneTree
## Ficha de carta: el desplazamiento para al final del texto y ◀▶ pasa a la carta vecina
## (mano, mesa, menú principal y editor).
var out := "/home/claude/shots/ficha"
var scene
var fails := 0
func _initialize() -> void:
	Engine.max_fps = 30
	_run.call_deferred()
func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)
func frames(n: int) -> void:
	for i in n:
		await process_frame
func check(c: bool, what: String) -> void:
	print(("ok   " if c else "FALLA ") + what)
	if not c: fails += 1
func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	scene._start_duel()
	scene.intro = ""
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	var guard := 0
	while g.phase != "main" and guard < 300:
		guard += 1
		g.apply(ai.choose(g))
	print("fase ", g.phase)
	scene.deck_seen = g.deck_log.size(); scene.prize_seen = g.prize_log.size(); scene.coins_seen = g.coin_log.size()
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []; scene.energy_anim = []
	scene.turn_seen = 999; scene.vs_seen = {"x": 1}
	# Si los Activos son rivales de leyenda, el "VS" se tragaría las teclas: lo damos por visto
	var mine = g.players[scene.human].active
	var theirs = g.players[1 - scene.human].active
	if mine != null and theirs != null:
		var rv: Dictionary = preload("res://scenes/special_fx.gd").rivalry(CardDB.card_name(mine.top()), CardDB.card_name(theirs.top()))
		if not rv.is_empty():
			scene.vs_seen[rv["key"]] = true
	g.current = scene.human
	scene.ai_timer = 9999.0
	scene._rebuild_menu()
	await frames(3)
	# Mano
	key(KEY_M)
	await frames(2)
	key(KEY_C)
	await frames(3)
	check(not scene.info_lines.is_empty(), "C en la mano abre la ficha")
	for i in 40:
		key(KEY_DOWN)
		await frames(1)
	var off: int = scene.info_offset
	await shot("01_fin_del_texto")
	check(not scene.info_more, "después de bajar mucho ya no queda nada por leer")
	key(KEY_DOWN)
	await frames(2)
	check(scene.info_offset == off, "no baja más allá del final (offset %d)" % off)
	var hand: Array = g.players[scene.human].hand
	key(KEY_RIGHT)
	await frames(2)
	check(scene.hand_cursor == 1 and scene.info_offset == 0, "→ pasa a la segunda carta de la mano")
	await shot("02_siguiente")
	key(KEY_LEFT); key(KEY_LEFT)
	await frames(2)
	check(scene.hand_cursor == hand.size() - 1, "← desde la primera vuelve a la última")
	key(KEY_Z)
	key(KEY_X)
	await frames(2)
	# Menú principal: Activos y después cada Pokémon en juego
	key(KEY_C)
	await frames(2)
	var n: int = scene.info_nav.size()
	check(n == 1 + scene.paneles._board_slots().size() + (1 if g.stadium != "" else 0), "C en el menú principal: la vista partida y una página por Pokémon en juego (y el Estadio) (%d)" % n)
	key(KEY_RIGHT)
	await frames(2)
	await shot("03_mesa")
	key(KEY_Z)
	# Mesa (B)
	key(KEY_B)
	key(KEY_C)
	await frames(2)
	key(KEY_RIGHT)
	await frames(2)
	var all: Array = scene.paneles._board_slots()
	check(scene.board_sel == all[1 % all.size()], "en la mesa, → mueve también la selección")
	key(KEY_Z)
	key(KEY_X)
	# Editor
	scene.mode = "editor"
	scene.editor.open()
	scene.editor._start_edit("Ruby")
	await frames(2)
	scene.editor.tab = 1
	scene.editor.cursor = 0
	key(KEY_C)
	await frames(2)
	key(KEY_RIGHT); key(KEY_RIGHT)
	await frames(2)
	check(scene.editor.cursor == 2, "en el editor, → pasa a la carta de abajo de la lista")
	# Una carta con mucho texto: baja hasta el final y para ahí
	for i in 60:
		key(KEY_RIGHT)
		await frames(1)
		if scene.info_more:
			break
	var steps := 0
	while scene.info_more and steps < 40:
		key(KEY_DOWN)
		await frames(1)
		steps += 1
	var off2: int = scene.info_offset
	key(KEY_DOWN); key(KEY_DOWN)
	await frames(2)
	check(off2 > 0 and scene.info_offset == off2, "carta larga: baja %d y ahí se frena" % off2)
	await shot("04_editor_final")
	print("listo, fallas: ", fails)
	quit()
