extends SceneTree
## Muestra cómo se tradujo cada ataque (para revisar a mano). Uso: -- ex6 ex7 ...
func _init() -> void:
	CardDB.load_db()
	var sets := OS.get_cmdline_user_args()
	for id in CardDB.all_ids():
		if not sets.is_empty() and CardDB.set_of(id) not in sets:
			continue
		for atk in CardDB.get_card(id).get("attacks", []):
			if str(atk.get("text", "")) == "":
				continue
			var p := AttackEffects.parse(id, atk)
			var ops: Array = []
			for op in p["ops"]:
				var d: Dictionary = op.duplicate()
				ops.append(JSON.stringify(d))
			print("%s|%s|%s => %s" % [id, atk["name"], atk.get("text", ""), " ; ".join(ops)])
	quit()
