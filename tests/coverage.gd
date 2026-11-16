extends SceneTree
## Informe de cobertura: cuántos ataques y Entrenadores de la era EX entiende el motor.
## Uso: godot --headless --script res://tests/coverage.gd [prefijo_de_set]

func _init() -> void:
	CardDB.load_db()
	var only := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		only = args[0]
	var attacks := 0
	var ok_attacks := 0
	var cards := 0
	var ok_cards := 0
	var trainers := 0
	var ok_trainers := 0
	var missing := {}
	var abilities := 0
	var ok_abilities := 0
	var missing_ab := {}
	for id in CardDB.all_ids():
		if only != "" and not id.begins_with(only + "-"):
			continue
		if CardDB.is_pokemon(id):
			cards += 1
			var all_ok := true
			for ab in CardDB.get_card(id).get("abilities", []):
				abilities += 1
				if Abilities.is_implemented(ab["name"]):
					ok_abilities += 1
				else:
					all_ok = false
					missing_ab[ab["name"]] = true
			for atk in CardDB.get_card(id).get("attacks", []):
				attacks += 1
				var u: String = AttackEffects.parse(id, atk)["unknown"]
				if u == "":
					ok_attacks += 1
				else:
					all_ok = false
					missing[u] = missing.get(u, 0) + 1
			if all_ok:
				ok_cards += 1
		elif CardDB.is_trainer(id):
			trainers += 1
			if Trainers.is_implemented(id):
				ok_trainers += 1
	print("Cartas en la base: %d" % CardDB.count())
	print("Ataques entendidos:   %d / %d (%.0f%%)" % [ok_attacks, attacks, 100.0 * ok_attacks / max(1, attacks)])
	print("Poké-Powers/Bodies:   %d / %d" % [ok_abilities, abilities])
	print("Pokémon 100%% listos:  %d / %d" % [ok_cards, cards])
	print("Entrenadores:         %d / %d" % [ok_trainers, trainers])
	var keys := missing.keys()
	keys.sort_custom(func(a, b): return missing[a] > missing[b])
	if not missing_ab.is_empty():
		print("Habilidades sin programar: ", ", ".join(missing_ab.keys()))
	var missing_tr := {}
	for id in CardDB.all_ids():
		if CardDB.is_trainer(id) and not Trainers.is_implemented(id):
			missing_tr[CardDB.card_name(id)] = true
	if not missing_tr.is_empty():
		print("Entrenadores sin programar: ", ", ".join(missing_tr.keys()))
	print("\nTextos sin programar más comunes:")
	for k in keys.slice(0, 200):
		print("  %3d  %s" % [missing[k], k.substr(0, 110)])
	quit()
