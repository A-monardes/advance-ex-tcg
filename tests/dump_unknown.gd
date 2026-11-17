extends SceneTree
## Lista los ataques con texto sin programar (texto completo), para los sets dados.
## Uso: godot --headless -s res://tests/dump_unknown.gd -- ex6 ex7 ...
func _init() -> void:
	CardDB.load_db()
	var sets := OS.get_cmdline_user_args()
	for id in CardDB.all_ids():
		if not sets.is_empty() and CardDB.set_of(id) not in sets:
			continue
		var atks: Array = CardDB.get_card(id).get("attacks", [])
		for atk in atks:
			var p := AttackEffects.parse(id, atk)
			if p["unknown"] != "":
				print("%s %s | %s [%s] %s :: %s" % [id, CardDB.card_name(id), atk["name"], atk.get("damage_text", ""), str(atk.get("cost", [])), atk.get("text", "")])
	quit()
