extends SceneTree
## Capturas de pantallas del duelo con textos: ficha de carta, menú principal, lista de
## ataques, registro y mano. Uso: godot -s tests/shots_ingles.gd (con pantalla o xvfb).
var out := "/home/claude/shots/ingles"
var scene: Node2D

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	scene._start_duel()
	scene.intro = ""
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	g.coin_winner = scene.human
	if g.phase == "first":
		g.apply({"t": "first", "me": true})
	print("fase ", g.phase)
	var guard := 0
	while g.phase != "main" and guard < 200:
		guard += 1
		var acts := g.legal_actions()
		if acts.is_empty(): break
		g.apply(ai.choose(g))
	g.current = scene.human
	print("fase2 ", g.phase, " cur ", g.current, " guard ", guard)
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []
	scene.move_anim = []; scene.trainer_anim = {}; scene.energy_anim = []; scene.evo_anim = {}
	scene.turn_seen = 999
	var me: PlayerState = g.players[scene.human]
	me.active = PokemonInPlay.new("ex4-89")
	scene.menu_level = "list"     # como si se hubiera quedado en un submenú del turno anterior
	scene.category = "Attack"
	scene.menu_turn = -1
	scene._rebuild_menu()
	print("menu tras turno nuevo: ", scene.menu_level, " ", scene.menu_items.map(func(x): return x["label"]))
	await shot("01_menu")
	scene.info_lines = scene._card_lines("ex4-89", me.active)
	scene.info_offset = 0
	await shot("02_ficha")
	scene.info_lines = scene._card_lines("ex5-94", null)
	await shot("03_ficha_kyogre")
	scene.info_lines = []
	scene.show_log = true
	await shot("04_registro")
	scene.show_log = false
	scene.pile_view = "hand"
	await shot("05_mano")
	scene.pile_view = ""
	scene.paused = true
	scene.anim_speed = 2
	await shot("06_pausa")
	scene.paused = false
	scene.menu_level = "confirm_end"
	scene._rebuild_menu()
	await shot("07_confirmar")
	print("listo")
	quit()
