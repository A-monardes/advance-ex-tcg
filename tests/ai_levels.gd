extends SceneTree
## Mide la fuerza de cada nivel de IA contra el nivel Normal (3): partidas con mazos al
## azar, alternando quién juega cada mazo.
## Uso: godot --headless --script res://tests/ai_levels.gd -- [cruces] [niveles, p.ej. 1,2,4,5] [nivel base] [JSON de ajustes]
func _initialize(): _run.call_deferred()

func play(da: String, db: String, la: int, lb: int, sd: int) -> int:
	var g := Game.new(Decks.get_deck(da), Decks.get_deck(db), sd)
	var ais := [_mk(sd, la), _mk(sd + 7, lb)]
	g.start()
	var steps := 0
	var lt := 0
	var stt := 0
	while g.phase != "over" and steps < 4000 and g.turn_number < 150:
		if g.turn_number != lt:
			lt = g.turn_number
			stt = 0
		stt += 1
		var a: Dictionary = ais[g.actor()].choose(g)
		if stt > 80 and g.phase == "main":
			a = {"t": "end"}
		g.apply(a)
		steps += 1
	return g.winner if g.phase == "over" else 2

var cfg := {}

func _mk(sd: int, lvl: int):
	var ai := SimpleAI.new(sd, lvl)
	# Ajustes de prueba: 4 parámetro = JSON {"4": {"sim_margin": 0}, ...}
	for k in cfg.get(str(lvl), {}):
		ai.set(k, cfg[str(lvl)][k])
	return ai


func _run():
	CardDB.load_db()
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var decks: Array = Decks.preset_names().filter(func(x): return not x.contains("Worlds"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var levels := [1, 2, 4, 5]
	if args.size() > 1:
		levels = Array(args[1].split(",")).map(func(x): return int(x))
	var base_lvl := int(args[2]) if args.size() > 2 else 3
	if args.size() > 3:
		cfg = JSON.parse_string(args[3])
		var AIEval := preload("res://engine/ai_eval.gd")
		for k in cfg.get("eval", {}):
			AIEval.W[k] = float(cfg["eval"][k])
	for lvl in levels:
		var w := 0
		var l := 0
		var d := 0
		var t0 := Time.get_ticks_msec()
		for k in n:
			var da: String = decks[rng.randi() % decks.size()]
			var db: String = decks[rng.randi() % decks.size()]
			# mismo cruce dos veces, cambiando quién juega cada mazo
			for swap in 2:
				var r: int
				if swap == 0:
					r = play(da, db, lvl, base_lvl, 1000 + k * 13)
					if r == 0: w += 1
					elif r == 1: l += 1
					else: d += 1
				else:
					r = play(db, da, base_lvl, lvl, 2000 + k * 13)
					if r == 1: w += 1
					elif r == 0: l += 1
					else: d += 1
		var nm: String = SimpleAI.LEVEL_NAMES[lvl - 1]
		print("%-12s vs %s: %3d ganadas, %3d perdidas, %d empates/sin terminar  (%.0f%%)  %.1fs" % [nm, SimpleAI.LEVEL_NAMES[base_lvl - 1], w, l, d, 100.0 * w / maxf(1, w + l), (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
