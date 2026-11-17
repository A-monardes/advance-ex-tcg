extends SceneTree
## Capturas: primer plano de la carta robada antes de ir a la mano.
var out := "/home/claude/shots/robo"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("captura ", name, " deck=", scene.deck_anim.size(), " closeup=", scene.deck_anim[0].get("closeup", false) if not scene.deck_anim.is_empty() else "-")
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
	await shot("00_mesa", 150)
	scene.deck_anim = []
	scene.banner = {}
	var me: PlayerState = g.players[scene.human]
	me.draw(1)
	for i in 14:
		await shot("%02d_robo" % (i + 1), 5)
	quit()
