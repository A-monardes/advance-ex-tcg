extends SceneTree
## Capturas de las reverse holo: sobre, editor y duelo.
var out := "/home/claude/shots/reverse"
var scene
func _initialize() -> void:
	Engine.max_fps = 30
	_run.call_deferred()
func shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	var camp = scene.campaign
	camp.st.save_path = "user://campana_reverse_prueba.json"
	camp.st.reset()
	camp.st.start(0, "Agus")
	# Sobres: abrir varios y mirar dónde salió la reverse
	var revs := {}
	for i in 200:
		var cards: Array = camp.st.open_pack("ex1")
		var r: int = camp.st.last_reverse
		if r >= 0:
			var k: String = camp.st.rarity.get(cards[r], "")
			revs[k] = revs.get(k, 0) + 1
	print("reverse por rareza en 200 sobres: ", revs)
	scene.mode = "campaign"
	camp.reward = {"packs": 1, "set": "ex5"}
	camp._start_packs()
	camp.reveal = 9.0
	await shot("01_sobre")
	camp.reveal = float(camp.packs[0]["reverse"] + 1)
	await shot("02_sobre_reverse")
	# Editor de colección
	scene.mode = "editor"
	scene.editor.open_collection(camp.st)
	await shot("03_editor")
	# Duelo de campaña con reverse en el Activo y la Banca
	camp.st.reverse["ex1-73"] = 1        # Torchic de R&S
	camp.st.reverse["ex5-68"] = 1        # carta de Hidden Legends
	camp.st.reverse["ex1-74"] = 1
	scene.start_campaign_duel(camp.st.deck_cards(), Decks.get_deck("Sapphire"), 1, "tomas")
	scene.intro = ""
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	var guard := 0
	while g.phase != "main" and guard < 200:
		guard += 1
		g.apply(ai.choose(g))
	scene.deck_seen = g.deck_log.size(); scene.prize_seen = g.prize_log.size(); scene.coins_seen = g.coin_log.size()
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []; scene.energy_anim = []
	scene.turn_seen = 999
	scene.vs_seen = {"x": 1}
	var me: PlayerState = g.players[scene.human]
	me.active = PokemonInPlay.new("ex5-68")
	me.bench = [PokemonInPlay.new("ex1-73"), PokemonInPlay.new("ex1-74")]
	g.current = 1 - scene.human
	scene.ai_timer = 9999.0
	scene._rebuild_menu()
	await shot("04_duelo")
	for i in 20:
		await process_frame
	await shot("05_duelo_b")
	camp.st.reset()
	quit()
