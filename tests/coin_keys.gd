extends SceneTree
## Simula al jugador apretando teclas al empezar un duelo, con los dos resultados de la
## moneda inicial y las dos reglas, hasta llegar a elegir el Pokémon Activo.
func _initialize() -> void:
	_run.call_deferred()
func key(scene, code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)
func _run() -> void:
	var ok := 0
	var total := 0
	for rules_2003 in [false, true]:
		for human_wins in [true, false]:
			total += 1
			var scene: Node2D = load("res://scenes/duel.tscn").instantiate()
			root.add_child(scene)
			scene.rules_2003 = rules_2003
			scene._start_duel()
			scene.game.coin_winner = scene.human if human_wins else 1 - scene.human
			var reached := false
			for f in 4000:
				var g: Game = scene.game
				# Como haría el jugador: Z cuando hay un menú suyo
				if scene.menu_items.size() > 0 and (g.actor() == scene.human or scene.intro == "call") and f % 5 == 0:
					key(scene, KEY_Z)
				scene._process(0.05)
				if g.phase == "setup" and g.actor() == scene.human and scene.deck_anim.is_empty() and scene.menu_items.size() > 0:
					reached = true
					break
			print("reglas 2003=%s, gana el jugador=%s -> %s (fase %s, intro '%s')" % [rules_2003, human_wins,
					"OK" if reached else "TRABADO", scene.game.phase, scene.intro])
			if reached:
				ok += 1
			scene.queue_free()
			await process_frame
	print("MONEDA_TECLAS %d/%d" % [ok, total])
	quit()
