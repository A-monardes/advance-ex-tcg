extends SceneTree
## Capturas con cartas de FireRed–Emerald en la mesa (nombres con ★, ♀, Rocket's, Dark...).
var out := "/home/claude/shots/frlg"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("captura ", name)
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._start_duel()
	var g: Game = scene.game
	scene.game.coin_winner = 1 - scene.human
	var ai := SimpleAI.new(2, 3)
	while g.phase != "main":
		g.apply(ai.choose(g))
	var me: PlayerState = g.players[scene.human]
	var op: PlayerState = g.players[1 - scene.human]
	me.active = PokemonInPlay.new("ex7-101")
	me.active.energy.append_array(["ex9-88", "ex7-94"])
	me.bench.clear()
	for id in ["ex7-108", "ex6-70", "ex8-16", "ex7-2"]:
		me.bench.append(PokemonInPlay.new(id))
	op.active = PokemonInPlay.new("ex6-110")
	op.bench.clear()
	for id in ["ex8-107", "ex6-71", "ex9-95"]:
		op.bench.append(PokemonInPlay.new(id))
	g.set_stadium(me, "ex7-87")
	g.current = scene.human
	Abilities.refresh(g)
	scene.deck_anim = []
	scene.banner = {}
	scene.menu_level = "root"
	scene._rebuild_menu()
	await shot("01_mesa", 200)
	me.active = PokemonInPlay.new("ex7-108")
	op.active = PokemonInPlay.new("ex6-70")
	await shot("02_estrella", 30)
	quit()
