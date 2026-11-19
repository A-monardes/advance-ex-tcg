extends SceneTree
## Prueba de la partida en línea: dos juegos (dos procesos) contra un relay local
## (node server/relay.js). Cada uno juega solo con la IA en su lado, pero pasando por la red,
## y al final imprimen el ganador y la huella del estado: tienen que dar igual.
## Uso: godot -s tests/net_duel.gd -- host|guest [animaciones 0|1] [mazo temporada]
var scene: Node2D
var ai: SimpleAI
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var role: String = args[0] if args.size() > 0 else "host"
	var anims: bool = args.size() > 1 and args[1] == "1"
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.title_attract = false
	scene.animations_on = anims
	scene.anim_speed = 2
	scene.mode = "title"
	scene.title_view = "online"
	scene.online.open()
	scene.online.server_url = "ws://127.0.0.1:8080"
	scene.my_deck = 0 if role == "host" else 1
	if args.size() > 3:      # mazos por nombre y temporada (la del host): -- host 0 "Power Wave" 6
		scene.my_deck = Decks.names().find(args[2])
		scene.season_idx = int(args[3])
	if role == "host":
		scene.online.link = NetLink.new()
		scene.online.link.host("ws://127.0.0.1:8080")
		scene.online.screen = "link"
		while scene.online.link == null or scene.online.link.room == "":
			await process_frame
			if scene.online.link == null:
				break
		FileAccess.open("/tmp/net_room.txt", FileAccess.WRITE).store_string(scene.online.link.room)
		print("host: room ", scene.online.link.room)
	else:
		while not FileAccess.file_exists("/tmp/net_room.txt"):
			await create_timer(0.2).timeout
		var code := FileAccess.get_file_as_string("/tmp/net_room.txt")
		scene.online.link = NetLink.new()
		scene.online.link.join("ws://127.0.0.1:8080", code)
		scene.online.screen = "link"
	var t0 := Time.get_ticks_msec()
	while scene.mode != "duel" and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	if scene.mode != "duel":
		print(role, ": no arrancó la partida: ", scene.online.msg, " ", scene.online.link.error if scene.online.link else "")
		quit()
		return
	print(role, ": partida arrancada, soy el jugador ", scene.human, " seed ", scene.game.rng.seed)
	ai = SimpleAI.new(77 if role == "host" else 99, 3)
	var g: Game = scene.game
	var steps := 0
	t0 = Time.get_ticks_msec()
	while g.phase != "over" and scene.net_lost == "" and Time.get_ticks_msec() - t0 < 240000:
		scene._mull_shown = true
		scene._setup_closed = true
		scene.setup_screen = ""
		scene.intro = ""
		scene.rival_intro = {}
		if g.actor() == scene.human and scene.anim.is_empty() and scene.coin_anim.is_empty() and scene.trainer_anim.is_empty() \
				and scene.power_anim.is_empty() and scene.banner.is_empty() and scene.evo_anim.is_empty() and scene.prize_anim.is_empty() \
				and scene.deck_anim.is_empty() and scene.check_anim.is_empty() and scene.ko_anim.is_empty() and scene.vs_anim.is_empty() \
				and scene.move_anim.is_empty() and scene.energy_anim.is_empty():
			scene._do(ai.choose(g))
			steps += 1
		await process_frame
	await create_timer(1.0).timeout
	print(role, ": fin fase=", g.phase, " ganador=", g.winner, " turno=", g.turn_number, " pasos=", steps,
			" huella=", scene._net_hash(), " perdido='", scene.net_lost, "'")
	quit()
