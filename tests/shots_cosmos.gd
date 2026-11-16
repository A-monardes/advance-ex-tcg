extends SceneTree
## Cuadros del holo "cosmos" para armar un GIF (ficha de carta + mesa).
var out := "/home/claude/shots/cosmos"
func _initialize() -> void:
	Engine.max_fps = 15
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
	while g.phase != "main" and guard < 300:
		guard += 1
		g.apply(ai.choose(g))
	scene.deck_seen = g.deck_log.size(); scene.prize_seen = g.prize_log.size(); scene.coins_seen = g.coin_log.size()
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []; scene.energy_anim = []
	scene.turn_seen = 999; scene.vs_seen = {"x": 1}
	var me: PlayerState = g.players[scene.human]
	var opp: PlayerState = g.players[1 - scene.human]
	me.active = PokemonInPlay.new(OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "ex1-3")
	opp.active = PokemonInPlay.new("ex2-96")
	g.current = 1 - scene.human
	scene.ai_timer = 9999.0
	scene._rebuild_menu()
	await process_frame
	var n := 140
	for i in n:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("f%03d.png" % i))
	quit()
