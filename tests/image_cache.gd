extends SceneTree
## La imagen guardada de cada carta no se achica al usarla en otros tamaños.
func _initialize() -> void:
	var scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	var ids := []
	for f in DirAccess.get_files_at("res://sprites"):
		if f.ends_with(".png") and f.begins_with("ex"):
			ids.append(f.get_basename())
		if ids.size() >= 5:
			break
	var ok := true
	for id in ids:
		var a: Image = scene.imagenes._load_card_image(id)
		var w0 := a.get_width()
		scene.imagenes._card_texture(id, 16)
		scene.imagenes._card_texture(id, 40)
		var b: Image = scene.imagenes._load_card_image(id)
		if b.get_width() != w0:
			ok = false
			print("FALLA ", id, " ", w0, " -> ", b.get_width())
	print("IMAGENES ", "ok" if ok else "FALLA", " ", ids)
	quit()
