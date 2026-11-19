extends SceneTree
## Juega partidas IA contra IA a través de la pantalla de duelo, avanzando el tiempo a mano,
## para comprobar que ninguna animación (monedas, ataques, Energías, Premios, robos) se trabe.
## Uso: godot --headless --script res://tests/ui_smoke.gd
func _initialize(): _run.call_deferred()
func _run():
	var scene: Node2D = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	var ai := SimpleAI.new(5)
	for game_i in 4:
		scene.animations_on = game_i < 3        # la última, sin animaciones
		var picks := 0
		scene.my_deck = game_i; scene.opp_deck = (game_i + 1) % 4
		scene._start_duel()
		scene.set_process(false)
		var steps := 0
		var draws := 0
		var shuffles := 0
		while scene.game.phase != "over" and steps < 100000:
			if not scene.deck_anim.is_empty():
				if scene.deck_anim[0]["t"] == 0.0:
					if scene.deck_anim[0]["k"] == "draw": draws += 1
					else: shuffles += 1
			if scene.intro == "call":
				scene._opening_call(steps % 2 == 0)     # cara o cruz
			if not scene.prize_anim.is_empty() and scene.prize_anim[0].get("choose", false) and scene._prize_showing():
				scene._pick_prize(steps % 4)
				picks += 1
			if scene.setup_screen == "mull":
				scene.setup_screen = ""            # como apretar X en la pantalla del mulligan
			scene._process(0.05)
			steps += 1
			var g: Game = scene.game
			if g.phase != "over" and g.actor() == scene.human and scene.coin_anim.is_empty() and scene.evo_anim.is_empty() \
					and scene.anim.is_empty() and scene.energy_anim.is_empty() and scene.prize_anim.is_empty() and scene.deck_anim.is_empty() \
					and scene.trainer_anim.is_empty() and scene.ko_anim.is_empty() and scene.banner.is_empty():
				scene._do(ai.choose(g))
		print("fin: ", scene.game.phase, " premios elegidos ", picks, " pasos ", steps, " turno ", scene.game.turn_number, " robos ", draws, " barajadas ", shuffles, " ", scene.game.win_reason)
	quit()
