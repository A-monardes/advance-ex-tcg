extends SceneTree
## Captura cuadros de las animaciones de ataque de cada tipo (necesita display).
## Uso: godot --script res://tests/anim_frames.gd -- carpeta_de_salida

const ATTACKERS := {"Fire": "ex1-28", "Water": "ex1-40", "Grass": "ex2-22", "Lightning": "ex2-72",
		"Psychic": "ex1-7", "Fighting": "ex1-8", "Darkness": "ex1-10", "Metal": "ex1-36"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var scene: Node2D = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)   # avanzamos la animación a mano
	for type in ATTACKERS:
		scene._start_duel()
		var g: Game = scene.game
		var ai := SimpleAI.new(3)
		while g.phase == "setup":
			g.apply(ai.choose(g))
		g.current = 0
		g.phase = "main"
		g.players[0].active = PokemonInPlay.new(ATTACKERS[type], 0)
		g.players[1].active = PokemonInPlay.new("ex2-83", 0)    # Wailmer
		scene._rebuild_menu()
		scene.anim_ataques._start_attack_anim({"t": "attack", "a": 0, "tg": -2, "opt": false})
		var n := 0
		while not scene.anim.is_empty():
			scene.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("%s_%02d.png" % [type, n]))
			n += 1
			if not scene.coin_anim.is_empty():
				scene.monedas._update_coins(0.05)
			else:
				scene.anim_ataques._update_anim(0.05)
	# Demostración de monedas: normal, quemadura y sueño
	scene._start_duel()
	# Resultados fijos para ver todas las caras: normal, quemadura con cruz, dormido con cruz y con cara.
	for e in [[true, ""], [false, "burn"], [false, "sleep"], [true, "sleep"]]:
		scene.game.coin_log.append(e[0])
		scene.game.coin_reasons.append(e[1])
	scene.monedas._check_coins()
	var m := 0
	while not scene.coin_anim.is_empty():
		scene.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("Coins_%03d.png" % m))
		m += 1
		scene.monedas._update_coins(0.04)
	print("ok")
	quit()
