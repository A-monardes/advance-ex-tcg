extends SceneTree
## Mide cuánto tarda cada cuadro del editor de mazos con el catálogo entero (pestaña Pokémon).
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.mode = "editor"
	scene.editor.open()
	scene.editor._start_edit(Decks.names()[0]) if scene.editor.has_method("_start_edit") else null
	scene.editor.tab = 1
	for i in 30:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var n := 120
	for i in n:
		scene.editor.cursor = (i * 7) % 400
		scene.editor.scroll = maxi(0, scene.editor.cursor - 3)
		scene.queue_redraw()
		await process_frame
	print("editor: %.2f ms por cuadro" % ((Time.get_ticks_usec() - t0) / 1000.0 / n))
	var t1 := Time.get_ticks_usec()
	for i in 50:
		scene.editor._tab_cards()
	print("_tab_cards: %.3f ms" % ((Time.get_ticks_usec() - t1) / 1000.0 / 50))
	quit()
