extends SceneTree
## Capturas: la δ detrás de los PS de los Pokémon δ en la mesa (Kingdra δ contra Latias δ).
var out := "/home/claude/shots/delta_mesa"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._start_duel()
	var g: Game = scene.game
	var ai := SimpleAI.new(2, 3)
	while g.phase != "main":
		g.apply(ai.choose(g))
	g.players[scene.human].active = PokemonInPlay.new("ex13-10")
	g.players[1 - scene.human].active = PokemonInPlay.new("ex13-21")
	await shot("x", 150)
	for i in 6:
		await shot("final_%d" % i, 15)
	quit()
