extends SceneTree
## Capturas de las pantallas con el estilo GBA (necesita display: xvfb-run).
## Uso: godot --path . -s tests/shots_gba.gd -- carpeta
var out := "/home/claude/shots/gba"
var scene: Node2D

func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	_run.call_deferred()

func shot(name: String, frames: int = 3) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	scene._unhandled_input(ev)

func idle() -> void:
	# deja terminar las animaciones
	for i in 600:
		if scene.anim.is_empty() and scene.deck_anim.is_empty() and scene.banner.is_empty() and scene.prize_anim.is_empty() \
				and scene.coin_anim.is_empty() and scene.ko_anim.is_empty() and scene.energy_anim.is_empty() \
				and scene.evo_anim.is_empty() and scene.trainer_anim.is_empty():
			return
		scene.anim_speed = 2
		await process_frame

func id(n: String) -> String:
	return CardDB.find(n)

func _run() -> void:
	scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	await shot("01_titulo")
	scene._start_duel()
	var g: Game = scene.game
	var ai := SimpleAI.new(3, 3)
	while g.phase == "setup":
		g.apply(ai.choose(g))
	await idle()
	# Mesa armada a mano (como la maqueta)
	var me := g.players[scene.human]
	var opp := g.players[1 - scene.human]
	g.current = scene.human
	g.phase = "main"
	me.active = PokemonInPlay.new("ex4-89", 0)
	me.active.damage = 40
	for e in ["Fire Energy", "Fire Energy", "Fire Energy"]: me.active.energy.append(id(e))
	me.active.tool = id("Lum Berry")
	me.bench.clear()
	for c in ["ex1-73", "ex1-27", "ex1-61"]: me.bench.append(PokemonInPlay.new(c, 0))
	me.bench[1].damage = 20
	me.bench[1].energy.append(id("Fire Energy"))
	opp.active = PokemonInPlay.new("ex1-13", 0)
	opp.active.damage = 50
	opp.active.poison = 1
	for e in ["Water Energy", "Water Energy", "Water Energy"]: opp.active.energy.append(id(e))
	opp.bench.clear()
	for c in ["ex1-59", "ex1-40", "ex1-48", "ex1-99"]: opp.bench.append(PokemonInPlay.new(c, 0))
	opp.bench[1].damage = 30
	g.stadium = id("Team Aqua Hideout") if id("Team Aqua Hideout") != "" else ""
	g.stadium_owner = 1 - scene.human
	while opp.prizes.size() > 3: opp.deck.append(opp.prizes.pop_back())
	while me.prizes.size() > 4: me.deck.append(me.prizes.pop_back())
	if OS.get_cmdline_user_args().size() > 1:
		scene.menu_level = "root"
		scene._rebuild_menu()
		g.stadium = ""
		for i in scene.table_styles.size():
			scene.table_style = i
			scene._table_tex = null
			await shot("mesa_%02d" % i)
		quit()
		return
	scene.menu_level = "root"
	scene._rebuild_menu()
	await shot("02_menu")
	# Atacar
	var cats: Array = scene.menu_items.map(func(x): return x["label"])
	scene.cursor = cats.find("Atacar")
	key(KEY_Z)
	await shot("03_ataques")
	key(KEY_X)
	scene.cursor = cats.find("Trainer") if "Entrenador" in cats else 0
	me.hand.append(id("Potion"))
	scene._rebuild_menu()
	scene.cursor = scene.menu_items.map(func(x): return x["label"]).find("Trainer")
	if scene.cursor >= 0:
		key(KEY_Z)
		await shot("04_entrenador")
		key(KEY_X)
	# Ficha (C)
	key(KEY_C)
	await shot("05_ficha")
	key(KEY_X)
	# Mano
	key(KEY_M)
	await shot("06_mano")
	key(KEY_X)
	# Registro
	key(KEY_TAB)
	await shot("07_registro")
	key(KEY_TAB)
	# Mesa (B)
	key(KEY_B)
	key(KEY_RIGHT)
	await shot("08_mesa_b")
	key(KEY_X)
	# Mensaje durante el turno del rival
	g.current = 1 - scene.human
	scene.ai_timer = 999
	await shot("09_mensaje")
	# Cartel
	scene.banner = {"p": scene.human, "turn": 7, "t": 0.5}
	await shot("10_cartel")
	scene.banner = {}
	# Moneda
	scene.coin_anim = {"results": [true], "reasons": [""], "i": 0, "t": 0.8, "per": 999.0}
	await shot("11_moneda")
	scene.coin_anim = {}
	# Elegir Premio
	scene.prize_anim = [{"p": scene.human, "id": me.prizes[0], "n": 1, "of": 1, "left": 3, "t": 0.0, "choose": true}]
	await shot("12_premio")
	scene.prize_anim = []
	quit()
