extends SceneTree
## Capturas de: bajar a la Banca, retirarse y pasar al puesto Activo.
var out := "/home/claude/shots/mov"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String) -> void:
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func freeze_at(t: float) -> void:
	scene.move_anim[0]["t"] = t
	scene.move_anim[0]["dur"] = 1.0e9
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
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
	scene.vs_seen = {"x": 1}
	var me: PlayerState = g.players[scene.human]
	g.current = scene.human
	# Asegurar un Básico en la mano
	var basic := "ex1-73"
	me.hand.append(basic)
	me.bench = me.bench.slice(0, 1)
	scene._rebuild_menu()
	var acts := g.legal_actions()
	var bench_act = null
	for a in acts:
		if a["t"] == "bench" and me.hand[a["h"]] == basic:
			bench_act = a
	print("bench ", bench_act)
	scene._do(bench_act)
	print("moves ", scene.move_anim.size())
	for i in 3:
		freeze_at([0.3, 0.6, 0.9][i])
		await shot("01_banca_%d" % i)
	scene.move_anim = []
	# Retirada: sin costo para simplificar
	me.active.energy.clear()
	for e in 4:
		me.active.energy.append("ex1-108" if CardDB.get_card("ex1-108").size() > 0 else me.active.energy[0])
	me.retreated = false
	acts = g.legal_actions()
	var ret = null
	for a in acts:
		if a["t"] == "retreat":
			ret = a
	print("retreat ", ret)
	if ret != null:
		scene._do(ret)
		while g.phase == "choice" and g.actor() == scene.human:
			var ch := g.legal_actions()
			scene._do(ch[0])
		print("moves ", scene.move_anim.size(), " ", scene.move_anim.map(func(b): return b["text"]))
		scene.energy_anim = []
		for i in 3:
			freeze_at([0.3, 0.5, 0.75][i])
			await shot("02_retirada_%d" % i)
		scene.move_anim = []
	# Pasar al puesto Activo después de un KO
	var before: Dictionary = scene._snapshot()
	me.discard.append_array(me.active.cards)
	me.active = me.bench.pop_front()
	scene.anim_ataques._check_moves(before)
	print("promo ", scene.move_anim.map(func(b): return b["text"]))
	for i in 2:
		freeze_at([0.4, 0.7][i])
		await shot("03_activo_%d" % i)
	print("listo")
	quit()
