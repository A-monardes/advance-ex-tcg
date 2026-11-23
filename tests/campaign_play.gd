extends SceneTree
## Campaña nueva apretando teclas: título -> Campaign -> nombre -> mazo inicial -> el primer
## mapa. Después juega de verdad (IA contra IA) un duelo contra cada rival del mapa que esté
## disponible, abre los sobres y vuelve al mapa. Guarda capturas de cada pantalla nueva.
## Uso: godot --path . -s tests/campaign_play.gd [-- carpeta_capturas]
var out := ""
var scene: Node2D
var shots := {}

func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	_run.call_deferred()

func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)

func snap(name: String) -> void:
	if out == "" or shots.has(name):
		return
	shots[name] = true
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func busy() -> bool:
	return not (scene.anim.is_empty() and scene.deck_anim.is_empty() and scene.banner.is_empty() and scene.prize_anim.is_empty() \
			and scene.coin_anim.is_empty() and scene.ko_anim.is_empty() and scene.energy_anim.is_empty() \
			and scene.evo_anim.is_empty() and scene.trainer_anim.is_empty()) or not scene._trans.is_empty()

func _run() -> void:
	Engine.time_scale = 8.0 if out != "" else 20.0
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	var camp = scene.campaign
	camp.st.save_path = "user://campana_recorrido.json"
	camp.st.reset()
	await process_frame
	scene.anim_speed = 2
	scene.title_attract = false      # sin la pantalla de "PRESS START"
	scene.CAMPAIGN_ON = true      # la prueba entra a la campaña aunque esté oculta
	scene.title_row = 0
	await snap("01_titulo")
	key(KEY_Z)
	var ai := SimpleAI.new(9, 5)
	var duels := 0
	var wins := 0
	var frames := 0
	var pending: Array = []        # rivales del mapa a los que todavía hay que desafiar
	var started := false
	var counted: Game = null
	while frames < 60000:
		frames += 1
		await process_frame
		if not scene._trans.is_empty():
			continue
		match scene.mode:
			"campaign":
				match camp.screen:
					"intro":
						var it = camp.intro
						if it.waiting == "dialog":
							await snap("01b_birch_%d" % it.i)
							it.typed = 999.0
							key(KEY_Z)
					"name":
						await snap("02_nombre")
						for ch in "Agus":
							camp.name_buf += ch
						await snap("03_nombre_escrito")
						camp.name_cursor = Vector2i(7, camp.NAME_ROWS.size())
						key(KEY_Z)
					"new":
						await snap("04_mazo_inicial")
						key(KEY_RIGHT)
						key(KEY_Z)
					"packs":
						await snap("07_sobre")
						key(KEY_Z)
					"world":
						var w = camp.world
						if not started:
							started = true
							await snap("05_mapa")
							for n in w.npcs:
								var rid: String = n["def"].get("rival", "")
								if rid != "" and camp.st.rival_available(rid):
									pending.append(rid)
						if not w.dialog.is_empty():
							w.dialog["typed"] = 999.0
							key(KEY_Z)
							continue
						if not w.alert.is_empty() or not w.approach.is_empty():
							continue
						if pending.is_empty():
							break
						var rid: String = pending.pop_front()
						camp.start_world_duel(rid)
			"duel":
				var g: Game = scene.game
				if scene.intro != "" or g.phase == "over":
					if g.phase == "over" and g != counted:
						counted = g
						await snap("06_resultado")
						print("duelo terminado, ganador ", g.winner)
						if g.winner == scene.human:
							wins += 1
						duels += 1
					key(KEY_Z)
					continue
				if scene.setup_screen != "":
					key(KEY_X)                     # cierra la ventana del mulligan / de la mano
					continue
				if not scene.prize_anim.is_empty() and scene.prize_anim[0].get("choose", false) and scene.anim_cartas._prize_showing():
					scene.paneles._pick_prize(0)
					continue
				if busy():
					continue
				if g.turn_number >= 6 and g.phase == "main":
					await snap("06_duelo")
					g.concede(1 - scene.human)     # para no tardar: el rival se rinde al rato
					continue
				if g.actor() == scene.human:
					g.apply(ai.choose(g))
	print("CAMPAÑA duelos=%d ganados=%d vencidos=%s colección=%d mapa=%s frames=%d" % [duels, wins,
			camp.st.beaten, camp.st.total_cards(), camp.world.map_id, frames])
	print("FIN ", "ok" if started and camp.st.is_started() and camp.st.player_name == "Agus" and duels >= 1 else "FALLA")
	camp.st.reset()
	quit()
