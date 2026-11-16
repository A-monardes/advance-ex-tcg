extends SceneTree
## Cuadros del brillo holo para armar un GIF.
var out := "/home/claude/shots/holo"
func _initialize() -> void:
	Engine.max_fps = 30
	_run.call_deferred()
func _run() -> void:
	var scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	scene._start_duel()
	scene.intro = ""
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	var guard := 0
	while g.phase != "main" and guard < 200:
		guard += 1
		g.apply(ai.choose(g))
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []; scene.energy_anim = []
	scene.turn_seen = 999
	scene.deck_seen = g.deck_log.size()
	scene.prize_seen = g.prize_log.size()
	scene.coins_seen = g.coin_log.size()
	scene.evo_seen = g.evo_log.size() if "evo_log" in g else scene.evo_seen
	scene.vs_seen = {"x": 1}
	var me: PlayerState = g.players[scene.human]
	var opp: PlayerState = g.players[1 - scene.human]
	me.active = PokemonInPlay.new("ex1-3")        # Blaziken (holo)
	opp.active = PokemonInPlay.new("ex2-96")      # Gardevoir ex (holo ex)
	me.bench = [PokemonInPlay.new("ex1-7"), PokemonInPlay.new("ex1-11")]
	g.current = 1 - scene.human
	scene.ai_timer = 9999.0
	scene._rebuild_menu()
	for i in 110:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("f%03d.png" % i))
	quit()
