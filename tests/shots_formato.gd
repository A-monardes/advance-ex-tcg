extends SceneTree
## Captura: el duelo libre rechaza un mazo que no es del formato elegido.
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	for i in 5: await process_frame
	scene.title_view = "duel"
	scene.season_idx = 1
	scene.my_deck = Decks.names().find("Magma Spirit (Worlds 2004)")
	scene.duel_row = scene.DUEL_ROWS - 1
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_Z
	scene._duel_setup_input(KEY_Z, true, Decks.names().size())
	print("msg: ", scene.title_msg, " | mode: ", scene.mode)
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/home/claude/shots/frlg/03_formato.png")
	quit()
