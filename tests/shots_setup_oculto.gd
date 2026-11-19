extends SceneTree
## Capturas: en la preparación los Pokémon que pone el rival se ven boca abajo.
var out := "/home/claude/shots/setup"
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
	# Que el rival prepare primero y vos todavía no
	if g.phase == "first":
		g.apply({"t": "first", "me": g.coin_winner != scene.human})
	scene.human = 1 - g.actor()       # vos preparás segundo: el rival ya puso los suyos
	while g.phase == "setup" and g.actor() != scene.human:
		g.apply(ai.choose(g))
	if g.phase == "setup" and g.actor() == scene.human and g.legal_actions().any(func(a): return a["t"] == "setup_active"):
		pass
	scene.deck_anim = []
	scene.banner = {}
	scene.setup_screen = ""
	scene._setup_closed = true
	scene._mull_shown = true
	print("fase ", g.phase, " rival activo ", g.players[1 - scene.human].active.display_name() if g.players[1 - scene.human].active else "-",
			" banca ", g.players[1 - scene.human].bench.size())
	await shot("1_preparacion", 60)
	quit()
