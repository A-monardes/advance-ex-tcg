extends SceneTree
## Capturas de la pantalla "Online duel": el menú y la sala creada con su código (relay local).
var out := "/home/claude/shots/online"
var scene: Node2D
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String, frames: int = 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.title_attract = false
	await shot("0_titulo", 30)
	scene.title_view = "online"
	scene.online.open()
	scene.online.server_url = "ws://127.0.0.1:8080"
	await shot("1_menu", 10)
	scene.online.link = NetLink.new()
	scene.online.link.host("ws://127.0.0.1:8080")
	scene.online.screen = "link"
	await shot("2_sala", 60)
	quit()
