extends SceneTree
## Partidas al azar con mazos armados con cartas e-card, para encontrar errores en los efectos nuevos.
## Uso: godot --headless --path . -s tests/ecard_fuzz.gd [partidas]

func _init() -> void:
	CardDB.load_db()
	var n := 30
	if OS.get_cmdline_user_args().size() > 0:
		n = int(OS.get_cmdline_user_args()[0])
	var rng := RandomNumberGenerator.new()
	var pool: Array = []
	var trainers: Array = []
	for id in CardDB.all_ids():
		if not str(id).begins_with("ecard"):
			continue
		if CardDB.is_pokemon(id):
			pool.append(id)
		elif CardDB.is_trainer(id) and Trainers.is_implemented(id):
			trainers.append(id)
	var with_powers: Array = pool.filter(func(c): return not CardDB.get_card(c).get("abilities", []).is_empty())
	var energies := ["ex1-104", "ex1-105", "ex1-106", "ex1-107", "ex1-108", "ex1-109", "ex1-93", "ex1-94"]
	var errors := 0
	var used := {}
	var power_names: Array = []
	for c in with_powers:
		for ab in CardDB.get_card(c)["abilities"]:
			if ab["name"] not in power_names:
				power_names.append(ab["name"])
	for gi in n:
		rng.seed = gi
		var decks: Array = []
		for k in 2:
			var d: Array[String] = []
			# Líneas evolutivas completas de Pokémon con poderes (para que se usen de verdad)
			for li in 4:
				var top: String = with_powers[rng.randi() % with_powers.size()]
				var line: Array = [top]
				var cur := top
				while CardDB.evolves_from(cur) != "":
					var prev := _find_in(pool, CardDB.evolves_from(cur))
					if prev == "":
						break
					line.push_front(prev)
					cur = prev
				for c in line:
					for k2 in 2:
						d.append(c)
			# Básicos y sus evoluciones
			while d.size() < 30:
				var c: String = pool[rng.randi() % pool.size()]
				d.append(c)
			for i in 10:
				if not trainers.is_empty():
					d.append(trainers[rng.randi() % trainers.size()])
			while d.size() < 60:
				d.append(energies[rng.randi() % 6])
			decks.append(d)
		var g := Game.new(decks[0], decks[1], gi)
		var pick := RandomNumberGenerator.new()
		pick.seed = gi
		g.start()
		var steps := 0
		while g.phase != "over" and steps < 3000 and g.turn_number < 120:
			var acts := g.legal_actions()
			if acts.is_empty():
				print("SIN ACCIONES partida ", gi, " fase ", g.phase)
				errors += 1
				break
			var a: Dictionary = acts[pick.randi() % acts.size()]
			if steps % 30 == 29 and g.phase == "main":
				a = {"t": "end"}
			g.apply(a)
			steps += 1
		for line in g.log_lines:
			var ln := str(line)
			for nm in power_names:
				if ln.contains(" uses " + nm + ".") or ln.contains(nm + ":"):
					used[nm] = int(used.get(nm, 0)) + 1
	print("fuzz e-card: %d partidas, %d problemas" % [n, errors])
	var never: Array = power_names.filter(func(x): return not used.has(x))
	print("poderes usados: %d / %d. Nunca: %s" % [used.size(), power_names.size(), ", ".join(never)])
	quit()


func _find_in(pool: Array, card_name: String) -> String:
	for c in pool:
		if CardDB.card_name(c) == card_name:
			return c
	return ""
