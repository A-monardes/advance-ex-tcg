extends SceneTree
## Capturas: el golpe del ataque y, aparte, después, el veneno; y el cartel de Rough Skin en la pelea.
var out := "/home/claude/shots/checkup"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("captura ", name, " anim=", scene.anim.get("dmg", "-"), " ko=", scene.anim.get("ko", false), " bodies=", scene.anim.get("bodies", []), " check=", scene.check_anim.size())
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
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
	me.active = PokemonInPlay.new("ex1-73")
	me.active.energy.append_array(["ex1-108", "ex1-108"])
	op.active = PokemonInPlay.new("ex1-22")
	op.active.poison = 1
	g.current = scene.human
	g.turn_number = maxi(g.turn_number, 3)
	scene.deck_anim = []
	scene.banner = {}
	scene.menu_level = "root"
	scene._rebuild_menu()
	await shot("00_mesa", 120)
	var acts := g.legal_actions().filter(func(a): return a["t"] == "attack" and a["a"] == 0)
	scene._do(acts[0])
	print("mini=", scene.anim.get("mini", false), " scene=", scene.anim.get("scene", false))
	for i in 12:
		await shot("%02d_pelea" % (i + 1), 10)
	for i in 26:
		await shot("%02d_despues" % (i + 13), 12)
	print("HP rival ", op.active.hp_left() if op.active else -1)
	quit()
