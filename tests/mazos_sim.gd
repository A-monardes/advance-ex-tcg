extends SceneTree
## Simula mazos con la IA (nivel Normal en los dos lados) para medir si son viables.
## Uso: godot --headless --script res://tests/mazos_sim.gd -- <mazos.json> <temporada 0-3> <partidas por cruce> <salida.json> [solo=nombre1,nombre2]
## mazos.json: {"nombre": {"cards": [[id, copias], ...]}}. Cada mazo juega contra todos los
## demás del archivo, la mitad de las partidas empezando de cada lado.
func _initialize(): _run.call_deferred()


func play(a: Array, b: Array, sd: int, r: RuleSet) -> int:
	var g := Game.new(a, b, sd)
	g.rules = r
	var ais := [SimpleAI.new(sd, 3), SimpleAI.new(sd + 7, 3)]
	g.start()
	var steps := 0
	var lt := 0
	var stt := 0
	while g.phase != "over" and steps < 4000 and g.turn_number < 120:
		if g.turn_number != lt:
			lt = g.turn_number
			stt = 0
		stt += 1
		var act: Dictionary = ais[g.actor()].choose(g)
		if stt > 80 and g.phase == "main":
			act = {"t": "end"}
		g.apply(act)
		steps += 1
	return g.winner if g.phase == "over" else 2


func expand(e: Array) -> Array[String]:
	var out: Array[String] = []
	for x in e:
		for i in int(x[1]):
			out.append(str(x[0]))
	return out


func _run():
	CardDB.load_db()
	var args := OS.get_cmdline_user_args()
	var decks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var r := RuleSet.from_season(int(args[1]))
	var n := int(args[2])
	var only: Array = []
	if args.size() > 4 and args[4].begins_with("solo="):
		only = Array(args[4].substr(5).split(","))
	var names: Array = decks.keys()
	var res := {}
	for nm in names:
		var errs := Game.validate_deck(expand(decks[nm]["cards"]), r)
		res[nm] = {"w": 0, "l": 0, "d": 0, "errs": errs, "vs": {}}
	var t0 := Time.get_ticks_msec()
	var games := 0
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: String = names[i]
			var b: String = names[j]
			if not only.is_empty() and not (a in only or b in only):
				continue
			if not res[a]["errs"].is_empty() or not res[b]["errs"].is_empty():
				continue
			for k in n:
				var sd := 1000 + i * 7919 + j * 104729 + k * 13
				var first_a := k % 2 == 0
				var w := play(expand(decks[a]["cards"]) if first_a else expand(decks[b]["cards"]),
						expand(decks[b]["cards"]) if first_a else expand(decks[a]["cards"]), sd, r)
				games += 1
				var wa := -1
				if w == 2:
					res[a]["d"] += 1
					res[b]["d"] += 1
				else:
					wa = 1 if (w == 0) == first_a else 0
					res[a]["w" if wa == 1 else "l"] += 1
					res[b]["l" if wa == 1 else "w"] += 1
				res[a]["vs"][b] = res[a]["vs"].get(b, 0) + (1 if wa == 1 else 0)
				res[b]["vs"][a] = res[b]["vs"].get(a, 0) + (1 if wa == 0 else 0)
	var f := FileAccess.open(args[3], FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	print("%d partidas en %.1fs" % [games, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
