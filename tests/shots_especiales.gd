extends SceneTree
## Capturas de las animaciones especiales y de los cara a cara.
var out := OS.get_environment("FX_OUT") if OS.get_environment("FX_OUT") != "" else "/home/claude/shots/especiales"
var steps: Array = [0.4, 0.7, 0.88]
var scene: Node2D
const SpecialFX := preload("res://scenes/special_fx.gd")
const SIGS := [["kyogre", "ex5-94"], ["groudon", "ex5-93"], ["rayquaza", "ex3-97"], ["mewtwo", "ex1-101"],
		["mew", "ex1-101"], ["zangoose", "ex2-14"], ["seviper", "ex2-11"], ["fuego1", "ex3-100"],
		["planta1", "ex4-39"], ["agua1", "ex4-46"], ["fuego2", "ex2-99"], ["planta2", "ex5-55"],
		["agua2", "ex5-79"], ["fuego3", "ex4-89"], ["planta3", "ex4-93"], ["agua3", "ex4-95"], ["heracross", "ex5-7"], ["pinsir", "ex5-13"],
		["", "ex1-73"], ["", "ex2-58"]]    # sin animación propia: fuego (Torchic) y veneno (Cacnea)
const VS := [["ex5-94", "ex5-93"], ["ex3-97", "ex4-9"], ["ex2-14", "ex2-11"], ["ex1-73", "ex1-75"], ["ex3-100", "ex4-46"], ["ex5-7", "ex5-13"]]
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String) -> void:
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._trans = {}
	scene._start_duel()
	scene.intro = ""
	var g: Game = scene.game
	g.coin_winner = scene.human
	g.apply({"t": "first", "me": true}) if g.phase == "first" else null
	var ai := SimpleAI.new(2, 3)
	var guard := 0
	while g.phase != "main" and guard < 200:
		guard += 1
		var acts := g.legal_actions()
		if acts.is_empty(): break
		g.apply(ai.choose(g))
	scene.deck_anim = []; scene.banner = {}; scene.coin_anim = {}; scene.prize_anim = []
	scene.turn_seen = 999
	var me: PlayerState = g.players[scene.human]
	var opp: PlayerState = g.players[1 - scene.human]
	# Cara a cara
	for i in VS.size():
		me.active = PokemonInPlay.new(VS[i][0])
		opp.active = PokemonInPlay.new(VS[i][1])
		scene.vs_anim = {}
		scene.vs_seen = {}
		scene.anim = {}
		scene._check_vs()
		print("vs ", VS[i], " -> ", scene.vs_anim.get("title", "NADA"))
		for tt in [0.5]:
			scene.vs_anim["t"] = tt
			scene.paused = false
			await shot("vs_%d" % i)
	scene.vs_anim = {}
	scene.vs_seen = {"x": true}
	# Ataques especiales: la mitad ataca el humano, la otra mitad el rival
	opp.active = PokemonInPlay.new("ex1-1")
	for i in SIGS.size():
		var attacker_human: bool = i % 2 == 0
		var a: PlayerState = me if attacker_human else opp
		var d: PlayerState = opp if attacker_human else me
		a.active = PokemonInPlay.new(SIGS[i][1])
		d.active = PokemonInPlay.new("ex1-1" if attacker_human else "ex1-59")
		g.current = a.index
		scene._start_attack_anim({"t": "attack", "a": 0}, 0)
		scene.anim["power"] = SpecialFX.power(SIGS[i][1])
		if SIGS[i][0] != "":
			scene.anim["sig"] = SIGS[i][0]
		else:
			scene.anim.erase("sig")
			scene.anim["dur"] = 1.0e9
		scene.anim["applied"] = true
		scene.anim["dur"] = 1.0e9
		scene.anim["dmg"] = 60
		scene.vs_seen = {}
		if OS.get_environment("FX_STEPS") != "":
			steps = []
			var n := int(OS.get_environment("FX_STEPS"))
			for q in n:
				steps.append(float(q) / n)
		for k in steps.size():
			scene.anim["t"] = steps[k]
			scene.vs_anim = {}
			scene.vs_seen = {"a": 1}
			await shot("sig_%02d_%s_%02d" % [i, SIGS[i][0], k])
	print("listo")
	quit()
