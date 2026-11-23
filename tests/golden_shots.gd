extends SceneTree
## Capturas fijas de las pantallas principales, para comparar antes y después de reordenar el
## código (tools/comparar_capturas.py). Misma semilla = misma partida.
## Uso: xvfb-run -a godot --path . --rendering-driver opengl3 -s tests/golden_shots.gd -- carpeta

var out_dir := "/tmp/golden"
var scene: Node2D


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)


## Partida fija hasta un turno tuyo con jugadas (sin animaciones pendientes).
func _duel(doubles: bool, turn_min: int) -> void:
	seed(777)
	scene.doubles_mode = doubles
	scene.net = null
	scene.human = 0
	scene.campaign_rival = ""
	scene.reverse_ids = {}
	scene._begin_duel(Decks.get_deck("Blaze"), Decks.get_deck("Torrent"), 3, "Golden", 31)
	var ai := SimpleAI.new(99, 3)
	var g: Game = scene.game
	var guard := 0
	while g.phase != "over" and guard < 3000:
		if g.actor() == 0 and g.phase == "main" and g.turn_number >= turn_min:
			break
		g.apply(ai.choose(g))
		guard += 1
	print("partida fija: turno %d, fase %s" % [g.turn_number, g.phase])
	_quiet()


func _quiet() -> void:
	scene.coin_anim = {}
	scene.coins_seen = scene.game.coin_log.size()
	for k in ["anim", "energy_anim", "prize_anim", "deck_anim", "trainer_anim", "ko_anim", "evo_anim", "banner", "vs_anim"]:
		var v = scene.get(k)
		if v is Array:
			v.clear()
		elif v is Dictionary:
			v.clear()
	scene.intro = ""
	scene.setup_screen = ""
	scene.info_lines = []
	scene.info_stack.clear()
	scene.pile_view = ""
	scene.show_log = false
	scene._slides.clear()
	scene._info_ghost = []
	scene.menu_level = "root"
	scene._rebuild_menu()


func _run() -> void:
	Clock.frozen = 123456
	Engine.time_scale = 0.0
	seed(1)
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	for i in 5:
		await process_frame
	scene.animations_on = false
	scene.title_attract = false
	await _shot("01_titulo")
	scene.title_view = "duel"
	await _shot("02_duelo_libre")
	scene.free_popup = "deck_me"
	await _shot("03_popup_mazo")
	scene.free_popup = "diff"
	await _shot("04_popup_dificultad")
	scene.free_popup = ""
	scene.title_view = "options"
	await _shot("05_opciones")
	scene.title_view = "online"
	await _shot("06_online")
	scene.title_view = ""
	scene.mode = "editor"
	scene.editor.open()
	await _shot("07_editor_lista")
	scene.editor._start_edit(Decks.names()[0])
	await _shot("08_editor_mazo")
	scene.editor.tab = 1
	scene.editor.cursor = 3
	await _shot("09_editor_pokemon")
	# Resultados: una partida jugada hasta el final
	_duel(false, 999)
	await _shot("22_resultados")
	# Duelo
	_duel(false, 3)
	await _shot("10_mesa")
	_key(KEY_Z)
	await _shot("11_submenu")
	_key(KEY_X)
	_key(KEY_C)
	await _shot("12_ficha")
	_key(KEY_C)
	scene.show_log = true
	await _shot("13_registro")
	scene.show_log = false
	_key(KEY_M)
	await _shot("14_mano")
	_key(KEY_Z)
	await _shot("15_carta_mano")
	_key(KEY_X)
	_key(KEY_X)
	_key(KEY_D)
	await _shot("16_descarte")
	_key(KEY_X)
	_key(KEY_B)
	await _shot("17_recorrer_mesa")
	_key(KEY_X)
	_quiet()
	scene.paused = true
	await _shot("20_pausa")
	scene.pause_view = "controls"
	await _shot("21_controles")
	scene.pause_view = ""
	scene.paused = false
	# Dobles
	_duel(true, 3)
	await _shot("18_mesa_dobles")
	_key(KEY_Z)
	await _shot("19_dobles_submenu")
	quit()
