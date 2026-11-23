extends SceneTree
## Revisa el orden de las animaciones jugando partidas por la pantalla (IA contra IA):
##  - mientras se ve una moneda "adelantada", la jugada todavía no se aplicó;
##  - el Premio no se muestra mientras se ve un KO;
##  - recuperar cartas del descarte tiene su animación.
## Uso: godot --path . -s tests/anim_order.gd [-- carpeta_para_capturas]
var out := ""
func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	_run.call_deferred()
func _run() -> void:
	var stats := {"previas": 0, "aplicadas_antes": 0, "premio_con_ko": 0, "recuperar": 0, "partidas": 0}
	var shots := {}
	Engine.time_scale = 10.0 if out == "" else 3.0
	Engine.max_fps = 0
	for game_i in (6 if out == "" else 2):
		var scene: Node2D = load("res://scenes/duel.tscn").instantiate()
		root.add_child(scene)
		scene.my_deck = game_i % 10
		scene.opp_deck = (game_i * 3 + 1) % 10
		scene.anim_speed = 2
		scene._start_duel()
		var ai := SimpleAI.new(game_i + 1, 3)
		var seen_then := false
		for f in 30000:
			var g: Game = scene.game
			if g.phase == "over":
				break
			scene.anim_speed = 2
			var idle: bool = scene.anim.is_empty() and scene.deck_anim.is_empty() and scene.banner.is_empty() and scene.prize_anim.is_empty() \
					and scene.coin_anim.is_empty() and scene.ko_anim.is_empty() and scene.energy_anim.is_empty() \
					and scene.evo_anim.is_empty() and scene.trainer_anim.is_empty()
			if scene.intro == "call":
				scene._opening_call(true)
			if scene.anim_cartas._prize_showing() and scene.prize_anim[0].get("choose", false):
				scene.paneles._pick_prize(0)
			if idle and g.actor() == scene.human and scene.menu_items.size() > 0:
				scene._do(ai.choose(g))
			if not scene.coin_anim.is_empty() and scene.coin_anim.has("then"):
				if not seen_then:
					stats["previas"] += 1
				seen_then = true
				if g.coin_log.size() > scene.coins_seen:
					stats["aplicadas_antes"] += 1
				if out != "" and not shots.has("moneda") and scene.coin_anim["t"] > 0.7:
					shots["moneda"] = true
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(out.path_join("moneda.png"))
			else:
				seen_then = false
			if not scene.ko_anim.is_empty() and scene.anim_cartas._prize_showing():
				stats["premio_con_ko"] += 1
			if not scene.deck_anim.is_empty() and scene.deck_anim[0]["k"] == "recover":
				if scene.deck_anim[0]["t"] == 0.0:
					stats["recuperar"] += 1
				if out != "" and not shots.has("recuperar") and scene.anim_cartas._deck_showing() and scene.deck_anim[0]["t"] > 0.35:
					shots["recuperar"] = true
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(out.path_join("recuperar.png"))
			await process_frame
		stats["partidas"] += 1
		scene.queue_free()
		await process_frame
	print("ORDEN ", stats)
	quit()
