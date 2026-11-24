extends RefCounted
## Pantalla "Online duel" del menú principal: elegir mazo, crear una partida (te da un
## código de 4 letras para pasarle al otro) o unirte con el código que te pasaron.
## La conexión es engine/net_link.gd; la partida la arranca duel.start_net_duel.

const PROTO := 3          # si cambia la forma de los mensajes, se sube y no se mezclan versiones
const CFG := "user://online.cfg"
const ROWS := ["Your deck", "Format", "Battle", "Server", "Create a game", "Join a game"]

var d                     # la escena del duelo (scenes/duel.gd)
var row := 4
var screen := "menu"      # menu · code (escribiendo el código) · server (escribiendo la dirección) · link
var typed := ""
var msg := ""
var server_url := NetLink.DEFAULT_URL
var link: NetLink = null
var _hello_sent := false
var _t := 0.0


func _init(duel) -> void:
	d = duel
	var cfg := ConfigFile.new()
	if cfg.load(CFG) == OK:
		server_url = str(cfg.get_value("online", "server", server_url))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("online", "server", server_url)
	cfg.save(CFG)


func open() -> void:
	screen = "menu"
	row = 4
	msg = ""
	_cancel()


func _cancel() -> void:
	if link != null:
		link.close()
	link = null
	_hello_sent = false


static func version() -> String:
	return "%d-%d" % [PROTO, CardDB.all_ids().size()]


func _my_deck() -> Array[String]:
	return Decks.get_deck(d.deck_names()[d.my_deck])


# ===========================================================================
# Teclas
# ===========================================================================

func input(event: InputEventKey) -> void:
	var k: int = event.keycode
	var accept: bool = k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo
	var back: bool = k in [KEY_X, KEY_ESCAPE] and not event.echo
	match screen:
		"code", "server":
			_typing(event, k)
			return
		"link":
			if back or (accept and link != null and link.status in ["error", "closed"]):
				_cancel()
				screen = "menu"
				d.snd.play("back")
			return
	var n: int = d.deck_names().size()
	match k:
		KEY_UP:
			row = (row + ROWS.size() - 1) % ROWS.size()
			d.snd.play("move")
		KEY_DOWN:
			row = (row + 1) % ROWS.size()
			d.snd.play("move")
		KEY_LEFT, KEY_RIGHT:
			var s := 1 if k == KEY_RIGHT else -1
			match row:
				0: d.my_deck = (d.my_deck + s + n) % n
				1:
					d.season_idx = (d.season_idx + s + RuleSet.SEASONS.size()) % RuleSet.SEASONS.size()
					d.format_upto = -1
				2: d.doubles_mode = not d.doubles_mode
			if row <= 2:
				d.snd.play("move")
				d._save_settings()
	if back or k == KEY_BACKSPACE:
		_cancel()
		d.title_view = ""
		d.snd.play("back")
		return
	if not accept:
		return
	msg = ""
	match row:
		1:
			d.snd.play("ok")
			d.fmt_menu.open("online")      # todos los formatos: Mundiales y Custom
		3:
			screen = "server"
			typed = server_url
			d.snd.play("ok")
		4:
			var errs := Game.validate_deck(_my_deck(), d.format_rules())
			if not errs.is_empty():
				msg = "Your deck can't be used in this format: " + errs[0]
				d.snd.play("error")
				return
			link = NetLink.new()
			link.host(server_url)
			screen = "link"
			_hello_sent = false
			d.snd.play("ok")
		5:
			screen = "code"
			typed = ""
			d.snd.play("ok")


func _typing(event: InputEventKey, k: int) -> void:
	var max_len := 4 if screen == "code" else 120
	if k == KEY_ESCAPE:
		screen = "menu"
		d.snd.play("back")
		return
	if k in [KEY_ENTER, KEY_KP_ENTER]:
		if screen == "server":
			server_url = typed.strip_edges()
			_save()
			screen = "menu"
			d.snd.play("ok")
		elif typed.length() == 4:
			link = NetLink.new()
			link.join(server_url, typed)
			screen = "link"
			_hello_sent = false
			d.snd.play("ok")
		else:
			d.snd.play("error")
		return
	if k == KEY_BACKSPACE:
		typed = typed.left(maxi(0, typed.length() - 1))
		return
	if k == KEY_V and event.ctrl_pressed:
		typed = (typed + DisplayServer.clipboard_get().strip_edges()).left(max_len)
		if screen == "code":
			typed = typed.to_upper()
		return
	var ch := char(event.unicode) if event.unicode > 31 else ""
	if ch == "" or typed.length() >= max_len:
		return
	if screen == "code":
		ch = ch.to_upper()
		if not ch in "ABCDEFGHJKLMNPQRSTUVWXYZ":
			return
	typed += ch


# ===========================================================================
# Conexión y apretón de manos
# ===========================================================================

func update(delta: float) -> void:
	_t += delta
	if link == null or screen != "link":
		return
	link.poll()
	if link.status != "ready":
		return
	if link.you == 1 and not _hello_sent:
		link.send({"k": "hello", "deck": _my_deck(), "ver": version()})
		_hello_sent = true
	for j in link.inbox.size():
		var m: Dictionary = link.inbox[j]
		match str(m.get("k", "")):
			"hello":
				if link.you == 0:
					link.inbox.remove_at(j)
					_host_answer(m)
					return
			"go":
				if link.you == 1:
					link.inbox.remove_at(j)
					if str(m.get("ver", "")) != version():
						msg = "The other player has a different version of the game."
						link.status = "error"
						link.error = msg
						return
					var l := link
					link = null
					d._go(func(): d.start_net_duel(l, m["decks"], int(m["seed"]), int(m["season"]), bool(m["doubles"]), int(m.get("upto", -1))))
					return
			"bad":
				link.inbox.remove_at(j)
				link.status = "error"
				link.error = str(m.get("why", "The other player refused the game."))
				return


## Quien creó la sala recibe el mazo del otro, lo revisa y arranca (manda la semilla).
func _host_answer(m: Dictionary) -> void:
	var rules: RuleSet = d.format_rules()
	var theirs: Array[String] = []
	theirs.assign(m.get("deck", []))
	var why := ""
	if str(m.get("ver", "")) != version():
		why = "The two players have different versions of the game."
	else:
		var errs := Game.validate_deck(theirs, rules)
		if not errs.is_empty():
			why = "The guest's deck can't be used in %s: %s" % [rules.name, errs[0]]
	if why != "":
		link.send({"k": "bad", "why": why})
		link.status = "error"
		link.error = why
		return
	var seed_value := randi() % 2000000000 + 1
	var decks := [_my_deck(), theirs]
	link.send({"k": "go", "decks": decks, "seed": seed_value, "season": d.season_idx, "upto": d.format_upto, "doubles": d.doubles_mode, "ver": version()})
	var l := link
	link = null
	d._go(func(): d.start_net_duel(l, decks, seed_value, d.season_idx, d.doubles_mode, d.format_upto))


# ===========================================================================
# Dibujo
# ===========================================================================

func keys_text() -> String:
	match screen:
		"code": return "Type the 4-letter code · Enter join · Ctrl+V paste · Esc back"
		"server": return "Type the server address · Enter save · Ctrl+V paste · Esc back"
		"link": return "X cancel"
	return "▲▼ select · ◀▶ change · Z accept · X back"


func draw() -> void:
	# Estilo Pokémon Pinball (ver duel_titulo.gd): rayas azules, barra de título y una caja
	var t = d.titulo
	t._pb_bg(t.PB_BLUE)
	t._pb_title(8, "ONLINE DUEL")
	var panel := Rect2(6, 22, d.W - 12, 120)
	t._pb_box(panel, "LINK" if screen == "link" else "GAME", true)
	if screen == "link":
		_draw_link(panel)
		return
	var names: Array = d.deck_names()
	var r: RuleSet = d.format_rules()
	var vals := [names[d.my_deck], r.name, "Doubles (2 vs 2)" if d.doubles_mode else "Singles", server_url, "", ""]
	for i in ROWS.size():
		var y := 37 + i * 12 + (4 if i >= 4 else 0)
		var sel: bool = i == row and screen == "menu"
		if sel:
			t._pb_corners(Rect2(11, y - 1, d.W - 22, 11))
		if i < 4:
			d._text(Vector2(15, y), ROWS[i], d.C_DIM)
			var v: String = vals[i]
			if screen == "server" and i == 3:
				v = typed + ("_" if int(_t * 2.5) % 2 == 0 else " ")
				d._text_fit(Vector2(72, y), v, Color("#c03028"), 158)
			elif sel and i <= 2:
				d._text_scroll(Vector2(72, y), "◀ " + v + " ▶", d.C_TEXT, 158, "onl%d" % i)
			else:
				d._text_fit(Vector2(72, y), v, d.C_TEXT, 158)
		else:
			var label: String = ROWS[i]
			if i == 5 and screen == "code":
				label = "Code: " + typed + ("_" if int(_t * 2.5) % 2 == 0 else " ")
			d._text(Vector2(15, y), label, Color("#c03028") if sel or (i == 5 and screen == "code") else d.C_TEXT)
	if msg != "":
		d._text_scroll(Vector2(12, 128), msg, d.C_HP_LOW, 216, "onlmsg")
	elif row == 1:
		d._text_fit(Vector2(12, 128), "The game uses the format of the player who creates it.", d.C_DIM, 222)


func _draw_link(panel: Rect2) -> void:
	var lines: Array = []
	var big := ""
	match link.status if link != null else "error":
		"connecting":
			lines = ["Connecting to the server" + ".".repeat(1 + int(_t * 2.5) % 3)]
		"waiting":
			lines = ["Game created! Give this code to the other player:", "", "", "Waiting for them to join" + ".".repeat(1 + int(_t * 2.5) % 3)]
			big = link.room
		"ready":
			lines = ["Connected (room %s). Starting" % link.room + ".".repeat(1 + int(_t * 2.5) % 3)]
		_:
			lines = [link.error if link != null and link.error != "" else "Something went wrong.", "", "Z / X: back"]
	for i in lines.size():
		d._text_fit(Vector2(12, 38 + i * 12), lines[i], d.C_TEXT, 216)
	if big != "":
		var w: float = d._text_w(big) * 2
		d._text_big(Vector2((d.W - w) / 2.0, 50), big, Color("#c03028"))
