extends SceneTree
## Recorre la Escuela de Entrenadores: la puerta a la tienda de cartas (compra un sobre), el maestro, un alumno
## que te desafía (duelo ganado a la fuerza), sobres, vuelta al mapa, menú y guardado.
## Saca capturas en /home/claude/shots/mundo.
var out := "/home/claude/shots/mundo"
var scene: Node2D
var n_shot := 0
func _initialize() -> void:
	Engine.max_fps = 60          # las esperas de la prueba cuentan cuadros
	_run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	n_shot += 1
	root.get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [n_shot, name]))
func press(code: int, pressed: bool = true) -> void:
	var ev := InputEventKey.new()
	ev.pressed = pressed
	ev.keycode = code
	var dirs := {KEY_UP: "up", KEY_DOWN: "down", KEY_LEFT: "left", KEY_RIGHT: "right"}
	if dirs.has(code) and scene.campaign.world != null:
		scene.campaign.world.forced_dir = dirs[code] if pressed else ""
	if pressed:
		scene._unhandled_input(ev)
func tap(code: int, wait: int = 2) -> void:
	press(code)
	for i in wait:
		await process_frame
	press(code, false)
	for i in 2:
		await process_frame
func frames(n: int) -> void:
	for i in n:
		await process_frame
func wait_trans() -> void:
	for i in 200:
		if scene._trans.is_empty():
			return
		await process_frame
func walk(code: int, steps: int) -> void:
	var w = scene.campaign.world
	press(code)
	var started := 0
	var last_to := Vector2i(-99, -99)
	for i in 600:
		await process_frame
		if not w.move.is_empty() and w.move["to"] != last_to:
			last_to = w.move["to"]
			started += 1
		if started >= steps or not w.dialog.is_empty() or not w.alert.is_empty() or scene.campaign.screen != "world":
			break
		if steps == 0 and i > 6:
			break
	press(code, false)
	for i in 30:
		if w.move.is_empty():
			break
		await process_frame
	await frames(2)
func talk_through(max_taps: int = 40) -> void:
	var w = scene.campaign.world
	for i in max_taps:
		if w.dialog.is_empty():
			return
		await frames(3)
		await tap(KEY_Z)


## Si hay un duelo en curso, se gana a la fuerza; después pasa los diálogos y los sobres.
func win_duel() -> void:
	await wait_trans()
	if scene.mode == "duel":
		scene.rival_intro = {}        # la presentación del rival se saltea
		scene.intro = ""
		var g: Game = scene.game
		g.concede(1 - scene.human)
		scene.anim = {}; scene.ko_anim = []; scene.prize_anim = []; scene.coin_anim = {}; scene.deck_anim = []
		scene.banner = {}; scene.move_anim = []; scene.energy_anim = []; scene.trainer_anim = {}; scene.evo_anim = {}
		await frames(3)
		await tap(KEY_Z)
		await wait_trans()
		await frames(5)
	await talk_through()
	for i in 20:
		if scene.campaign.screen != "packs":
			break
		await tap(KEY_Z)
	await wait_trans()
	await frames(5)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	var camp = scene.campaign
	camp.st.save_path = "user://campana_mundo_prueba.json"
	camp.st.reset()
	camp.st.start(0, "Test")
	scene.mode = "campaign"
	camp.open()
	await wait_trans()
	await frames(5)
	var w = camp.world
	print("pantalla ", camp.screen, " mapa ", w.map_id, " pos ", w.pos, " fondo ", w._bg != null)
	await shot("entrada")
	await frames(150)          # que se vaya el cartel
	# La puerta de entrada lleva a la tienda de cartas (pantalla aparte)
	await walk(KEY_DOWN, 1)
	await frames(30)
	print("puerta: diálogo ", not w.dialog.is_empty(), " pos ", w.pos)
	await shot("puerta")
	var money0: int = camp.st.money
	await talk_through()            # la última página pregunta; Z = Sí
	await wait_trans()
	await frames(5)
	var sh = camp.shop
	print("tienda: pantalla ", camp.screen, " vendedora ", sh.clerk())
	await frames(80)
	await shot("tienda_hola")
	for i in 10:
		if sh.state == "menu":
			break
		await tap(KEY_Z)
		await frames(3)
	await shot("tienda_menu")
	await tap(KEY_Z)                # BUY
	await shot("tienda_lista")
	await tap(KEY_Z)                # el primer sobre
	await frames(60)
	await shot("tienda_confirmar")
	await tap(KEY_Z)                # Sí
	for i in 10:
		if sh.msg.is_empty():
			break
		await frames(40)
		await tap(KEY_Z)
	await wait_trans()
	await frames(5)
	print("compra: pantalla ", camp.screen, " dinero ", camp.st.money)
	for i in 20:
		if camp.screen != "packs":
			break
		await tap(KEY_Z)
	await frames(30)
	print("vuelta a la tienda: ", camp.screen, " ", sh.state, " '", sh.prompt, "'")
	await shot("tienda_otra_cosa")
	await tap(KEY_X)                # salir
	for i in 10:
		if camp.screen != "shop" or sh.msg.is_empty():
			break
		await frames(30)
		await tap(KEY_Z)
	await wait_trans()
	await frames(5)
	var bought_ok: bool = camp.st.money == money0 - 300
	print("fuera de la tienda: ", camp.screen, " pos ", w.pos, " dir ", w.dir)
	# Hasta el maestro (por la columna 10: en la 8 hay dos chicos charlando)
	await walk(KEY_UP, 1)
	await walk(KEY_RIGHT, 2)
	await walk(KEY_UP, 10)
	await tap(KEY_LEFT, 1)
	print("frente al maestro: pos ", w.pos, " dir ", w.dir)
	await tap(KEY_Z)
	await frames(60)
	await shot("maestro")
	await talk_through()
	# A la alumna que mira por la puerta del fondo
	await walk(KEY_RIGHT, 5)
	await tap(KEY_RIGHT, 1)
	print("frente a la alumna: pos ", w.pos, " dir ", w.dir)
	await tap(KEY_Z)
	await frames(60)
	await shot("desafio")
	await talk_through()
	await wait_trans()
	print("modo tras desafío: ", scene.mode, " rival ", scene.campaign_rival)
	if scene.mode == "duel":
		scene.rival_intro = {}        # la presentación del rival se saltea
		scene.intro = ""
		var g: Game = scene.game
		g.concede(1 - scene.human)
		scene.anim = {}; scene.ko_anim = []; scene.prize_anim = []; scene.coin_anim = {}; scene.deck_anim = []
		scene.banner = {}; scene.move_anim = []; scene.energy_anim = []; scene.trainer_anim = {}; scene.evo_anim = {}
		await frames(3)
		await tap(KEY_Z)
		await wait_trans()
		await frames(5)
	print("después del duelo: modo ", scene.mode, " pantalla ", camp.screen, " diálogo ", not w.dialog.is_empty(), " pos ", w.pos)
	await frames(60)
	await shot("despues")
	await talk_through()
	await frames(3)
	print("pantalla tras diálogo: ", camp.screen)
	await shot("sobre")
	for i in 20:
		if camp.screen != "packs":
			break
		await tap(KEY_Z)
	await frames(20)
	print("vuelta: pantalla ", camp.screen, " pos ", w.pos, " vencidos ", camp.st.beaten)
	await shot("de_vuelta")
	# Ya le ganaste: sin revancha hasta vencer al director (dice su texto de "vencido")
	await tap(KEY_RIGHT, 1)
	await tap(KEY_Z)
	await frames(30)
	var r_al: Dictionary = camp.st.rival("alumna")
	var t1: String = w.dialog.get("pages", [""])[0] if not w.dialog.is_empty() else ""
	var vencido_ok: bool = t1 == r_al["vencido"][0] and not w.dialog.get("ask", false)
	print("vencida, sin revancha: ", vencido_ok, " '", t1, "'")
	await talk_through()
	# Por la puerta del fondo al patio, y de vuelta
	await walk(KEY_UP, 1)
	await wait_trans()
	await frames(10)
	print("patio: mapa ", w.map_id, " pos ", w.pos)
	await frames(150)
	await shot("patio")
	# El jefe, arriba del todo entre las dos canchas
	await walk(KEY_LEFT, 4)
	await walk(KEY_UP, 8)
	print("frente al jefe: pos ", w.pos, " dir ", w.dir)
	await tap(KEY_Z)
	await frames(60)
	await shot("jefe")
	await talk_through()
	await win_duel()
	print("director vencido: ", camp.st.beaten.has("jefe"), " pos ", w.pos)
	await walk(KEY_DOWN, 8)
	await walk(KEY_RIGHT, 4)
	await walk(KEY_DOWN, 1)
	await wait_trans()
	await frames(10)
	print("de vuelta: mapa ", w.map_id, " pos ", w.pos, " dir ", w.dir)
	# Con el director vencido, la alumna pregunta por la revancha: "No"
	await tap(KEY_RIGHT, 1)
	await tap(KEY_Z)
	await frames(10)
	for i in 20:
		if w.dialog.is_empty() or (w.dialog.get("ask", false) and w.dialog["page"] == w.dialog["pages"].size() - 1):
			break
		await frames(3)
		await tap(KEY_Z)
	await frames(30)
	var asked: bool = w.dialog.get("ask", false)
	await tap(KEY_X)               # No
	await frames(30)
	var t2: String = w.dialog.get("pages", [""])[0] if not w.dialog.is_empty() else ""
	var no_ok: bool = asked and t2 == r_al["revancha_no"][0]
	print("revancha preguntada: ", asked, " respuesta no: '", t2, "'")
	await talk_through()
	await walk(KEY_LEFT, 6)
	await walk(KEY_DOWN, 4)
	await shot("aula")
	await tap(KEY_X)
	await shot("menu")
	# Volver al título (guarda el lugar) y seguir donde estabas
	w.menu_cursor = 2
	await tap(KEY_Z)
	await wait_trans()
	print("al título: modo ", scene.mode, " lugar ", camp.st.place)
	var saved: Vector2i = w.pos
	scene.mode = "campaign"
	camp.open()
	await wait_trans()
	print("FIN ", "ok" if camp.screen == "world" and w.pos == saved and camp.st.beaten.has("alumna") and bought_ok and vencido_ok and no_ok else "FALLA",
			" pantalla ", camp.screen, " pos ", w.pos)
	camp.st.reset()
	quit()
