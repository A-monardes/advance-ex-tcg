extends SceneTree
## Compara imágenes holo antes y después del filtro (para revisar a ojo).
func _initialize() -> void:
	var scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	var ids := ["ex1-1", "ex1-3", "ex1-7", "ex1-11"]
	var sheet := Image.create(4 * 84, 2 * 84, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.15))
	var t0 := Time.get_ticks_msec()
	for i in ids.size():
		var raw: Image = scene._load_card_image_raw(ids[i])
		var a: Image = scene._gba_art(raw, 40, 40)
		var b: Image = scene._gba_art(scene._load_card_image(ids[i]), 40, 40)
		a.resize(80, 80, Image.INTERPOLATE_NEAREST)
		b.resize(80, 80, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(a, Rect2i(0, 0, 80, 80), Vector2i(i * 84 + 2, 2))
		sheet.blit_rect(b, Rect2i(0, 0, 80, 80), Vector2i(i * 84 + 2, 86))
	print("ms ", Time.get_ticks_msec() - t0)
	sheet.save_png(OS.get_cmdline_user_args()[0])
	quit()
