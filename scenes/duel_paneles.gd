extends RefCounted
## Paneles del duelo: cuadro de texto y menús, registro, mano, recorrer la mesa, Premios, pausa y resultados
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


func _draw_textbox() -> void:
	var box = Rect2(Vector2(0, d.BOX_Y), Vector2(d.W, d.H - d.BOX_Y))
	var x := 9.0
	var y = d.BOX_Y + 4.0
	var tw = box.size.x - 18
	# Menú principal de tu turno: "¿Qué hará...?" y las opciones en dos columnas
	if d.game.phase == "main" and d.game.actor() == d.human and d.menu_level == "root" and not d.menu_items.is_empty() \
			and d.prize_view.is_empty() and d.trainer_anim.is_empty() and d.power_anim.is_empty() and d.anim.is_empty() and not d.anim_cartas._deck_showing() and not d.board_view \
			and not d.anim_cartas._prize_showing() and d.energy_anim.is_empty() and d.evo_anim.is_empty() and d.coin_anim.is_empty() \
			and d.ko_anim.is_empty() and d.check_anim.is_empty() and d.move_anim.is_empty():
		_draw_command_menu()
		return
	d._frame(box)
	if d.game.phase == "over" and not d.anim_cartas._prize_showing():
		var msg = "YOU WON!" if d.game.winner == d.human else ("Draw" if d.game.winner == 2 else "You lost...")
		d._text(Vector2(x, y), msg, d.C_TEXT)
		d._text_scroll(Vector2(x, y + d.LINE), d.game.win_reason, d.C_TEXT, tw, "over")
		d._text(Vector2(x, y + d.LINE * 2), "Z: back to title", d.C_DIM)
		return
	if d.board_view:
		d.fichas._draw_board_details(box, x, y)
		return
	if not d.prize_view.is_empty():
		_draw_prize_view_text(x, y)
		return
	if not d.coin_anim.is_empty() and str(d.coin_anim.get("label", "")) != "":
		d._text_scroll(Vector2(x, y), d.coin_anim["label"], d.C_TEXT, tw, "coinlbl")
		return
	if not d.power_anim.is_empty():
		var whose = "Your" if d.power_anim["p"] == d.human else "The opponent's"
		d._text_scroll(Vector2(x, y), "%s %s uses %s!" % [whose, d.power_anim["mon"], d.power_anim["name"]], d.C_TEXT, tw, "power")
		d._text(Vector2(x, y + d.LINE), "Attack" if d.power_anim.get("tag", "") == "ATTACK" else "Poké-Power", d.C_DIM)
		return
	if not d.trainer_anim.is_empty():
		var who = "You play" if d.trainer_anim["p"] == d.human else "The opponent plays"
		d._text_scroll(Vector2(x, y), "%s %s." % [who, CardDB.card_name(d.trainer_anim["id"])], d.C_TEXT, tw, "trainer")
		d._text(Vector2(x, y + d.LINE), _card_kind(d.trainer_anim["id"]), d.C_DIM)
		return
	if d.anim_cartas._deck_showing():
		d.anim_cartas._draw_deck_text(x, y, tw)
		return
	if not d.bench_fx.is_empty() and d.anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty():
		# Daño a la Banca: a quién y cuánto
		var parts: Array = []
		for e in d.bench_fx:
			parts.append("%s%s -%d" % ["" if e["p"] == d.human else "Foe ", e["mon"].display_name(), int(e["dmg"])])
		d._text_scroll(Vector2(x, y), "Damage to the Bench!", d.C_TEXT, tw, "bfx")
		d._text_scroll(Vector2(x, y + d.LINE), ", ".join(parts), d.C_DIM, tw, "bfx2")
		return
	if not d.check_anim.is_empty() and d.anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty():
		var ck: Dictionary = d.check_anim[0]
		if ck["kind"] == "stadium":
			var why := {"Desert Ruins": "The desert sands wear down Pokémon-ex with 100 HP or more!",
					"Cursed Stone": "The Cursed Stone hurts Pokémon with Poké-Powers!",
					"Team Magma Hideout": "Team Magma Hideout hurts the Basic Pokémon just played!"}
			var hurt: Array = []
			for e in ck["hits"]:
				hurt.append("%s%s -%d" % ["" if e["p"] == d.human else "Foe ", e["mon"].display_name(), int(e["dmg"])])
			d._text_scroll(Vector2(x, y), "%s: %s" % [ck["src"], why.get(ck["src"], "the Stadium does damage!")], d.C_TEXT, tw, "chk")
			d._text_scroll(Vector2(x, y + d.LINE), ", ".join(hurt), d.C_DIM, tw, "chk2")
			return
		var whose = "" if ck["p"] == d.human else "Foe "
		d._text_scroll(Vector2(x, y), "%s%s is hurt by %s!" % [whose, ck["mon"].display_name(), "poison" if ck["kind"] == "poison" else "its burn"], d.C_TEXT, tw, "chk")
		d._text(Vector2(x, y + d.LINE), "%d damage (%s)" % [ck["dmg"], "Poisoned" if ck["kind"] == "poison" else "Burned"], d.C_DIM)
		return
	if not d.ko_anim.is_empty() and d.anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty():
		d._text_scroll(Vector2(x, y), "%s was" % d.ko_anim[0]["name"], d.C_TEXT, tw, "ko")
		d._text(Vector2(x, y + d.LINE), "Knocked Out!", d.C_TEXT)
		return
	if d.anim_cartas._prize_showing() and d.prize_anim[0].get("choose", false):
		var pc: Dictionary = d.prize_anim[0]
		var head = "Choose one of your Prize cards" + (" (%d/%d)" % [pc["n"], pc["of"]] if pc["of"] > 1 else "") + "."
		d._text(Vector2(x, y), head, d.C_TEXT)
		var pile = _prize_pile(pc["p"])
		var ci = clampi(d.prize_cursor, 0, pile.size() - 1)
		if pile.is_empty() or not pile.any(func(q): return q[1]):
			d._text(Vector2(x, y + d.LINE), "They're face down: it could be any of them.", d.C_DIM)
		elif pile[ci][1]:
			d._text(Vector2(x, y + d.LINE), "Face up: " + CardDB.card_name(pile[ci][0]), d.C_TEXT)
		else:
			d._text(Vector2(x, y + d.LINE), "Face down: it could be any of the hidden ones.", d.C_DIM)
		d._text(Vector2(x, y + d.LINE * 2), "◀▶▲▼ move · Z take", d.C_DIM)
		return
	if d.anim_cartas._prize_showing():
		var pz: Dictionary = d.prize_anim[0]
		var mine: bool = pz["p"] == d.human
		var head = "You took a Prize card!" if mine else "The opponent took a Prize card."
		if pz["of"] > 1:
			head += " (%d/%d)" % [pz["n"], pz["of"]]
		d._text_fit(Vector2(x, y), head, d.C_TEXT, tw)
		if mine and pz["t"] > 0.35:
			d._text_scroll(Vector2(x, y + d.LINE), CardDB.card_name(pz["id"]) + " goes to your hand.", d.C_TEXT, tw, "prize")
		var left: int = pz["left"]
		var rest = ("%d left." if mine else "%d left.") % left if left > 0 else ("No Prize cards left!" if mine else "No Prize cards left!")
		d._text(Vector2(x, y + d.LINE * 2), rest, d.C_DIM)
		return
	if not d.move_anim.is_empty() and d.anim.is_empty() and d.ko_anim.is_empty() and d.check_anim.is_empty() and d.coin_anim.is_empty() \
			and d.trainer_anim.is_empty() and d.evo_anim.is_empty():
		var lines: Array = d.move_anim[0]["text"]
		for i in lines.size():
			d._text_scroll(Vector2(x, y + d.LINE * i), lines[i], d.C_TEXT, tw, "mv%d" % i)
		return
	if not d.energy_anim.is_empty() and d.anim.is_empty():
		var ea: Dictionary = d.energy_anim[0]
		d._text_scroll(Vector2(x, y), "%s was attached to" % CardDB.card_name(ea["id"]), d.C_TEXT, tw, "en0")
		d._text_scroll(Vector2(x, y + d.LINE), "%s!" % ea["mon"].display_name(), d.C_TEXT, tw, "en1")
		if ea.get("src", "") == "discard":
			d._text(Vector2(x, y + d.LINE * 2), "(from the discard pile)", d.C_DIM)
		return
	if not d.evo_anim.is_empty():
		var e: Dictionary = d.evo_anim["list"][d.evo_anim["i"]]
		d._text_scroll(Vector2(x, y), "%s is evolving!" % e["from"], d.C_TEXT, tw, "evo0")
		if d.evo_anim["t"] >= d.EVO_FLASH:
			d._text_scroll(Vector2(x, y + d.LINE), "It evolved into %s!" % e["to"], d.C_TEXT, tw, "evo1")
		return
	if not d.anim.is_empty():
		d._text_scroll(Vector2(x, y), d.anim["label"], d.C_TEXT, tw, "atk")
		if d.anim["applied"] and d.anim["dmg"] > 0:
			d._text(Vector2(x, y + d.LINE), "%d damage!" % d.anim["dmg"], d.C_TEXT)
		return
	if (d.game.actor() != d.human and d.intro != "call") or d.menu_items.is_empty():
		var n = d.game.log_lines.size()
		var start = maxi(0, n - d.VISIBLE_LINES)
		for i in range(start, n):
			d._text_fit(Vector2(x, y + (i - start) * d.LINE), d.game.log_lines[i].strip_edges(), d.C_TEXT, tw - 10)
		if d.game.actor() != d.human and d.game.phase != "over":
			var bob := 1.0 if int(Clock.ms() / 300.0) % 2 == 0 else 0.0
			d._text(Vector2(box.end.x - 15, box.end.y - 15 + bob), "▼", Color("#e03828"))
		return
	_draw_list_menu()


## Menú principal estilo GBA: a la izquierda la pregunta, a la derecha las opciones en dos columnas.
func _draw_command_menu() -> void:
	var left = Rect2(0, d.BOX_Y, 112, d.H - d.BOX_Y)
	var right = Rect2(110, d.BOX_Y, d.W - 110, d.H - d.BOX_Y)
	d._frame(left)
	d._frame(right)
	var y = d.BOX_Y + 4.0
	var act = d.game.players[d.human].active
	d._text(Vector2(9, y), "What will", d.C_TEXT)
	d._text_scroll(Vector2(9, y + d.LINE), (act.display_name() if act != null else "") + " do?", d.C_TEXT, 94, "cmd_name")
	d._text(Vector2(9, y + d.LINE * 2), "B table · M hand", d.C_DIM)
	var n = d.menu_items.size()
	var rows = ceili(n / 2.0)
	var lh = d.LINE if rows <= 3 else 10
	for i in n:
		var ox = 124 + (i % 2) * 58
		var oy = y + (i / 2) * lh
		d._stripe(Rect2(ox - 9, oy - 1, 57, lh), (i / 2 + i % 2))
		var label: String = d.menu_items[i]["label"]
		if label == "End turn":
			label = "End turn"
		d._text(Vector2(ox, oy), label, d.C_TEXT)
		if i == d.cursor:
			d._text(Vector2(ox - 8, oy), "▶", d.C_TEXT)


## Listas (ataques, cartas, elecciones): opciones a la izquierda y detalles a la derecha.
func _draw_list_menu() -> void:
	var img_id := _menu_card_id()
	var split := 136 if img_id != "" else 150
	var left = Rect2(0, d.BOX_Y, split + 2, d.H - d.BOX_Y)
	var right = Rect2(split, d.BOX_Y, d.W - split, d.H - d.BOX_Y)
	d._frame(left)
	d._frame(right)
	var y = d.BOX_Y + 4.0
	for i in range(d.scroll, mini(d.scroll + d.MENU_LINES, d.menu_items.size())):
		var ly = y + (i - d.scroll) * d.LINE
		d._stripe(Rect2(4, ly - 1, left.size.x - 8, d.LINE), i)
		if i == d.cursor:
			d._text(Vector2(8, ly), "▶", d.C_TEXT)
			d._text_scroll(Vector2(17, ly), d.menu_items[i]["label"], d.C_TEXT, left.size.x - 32, "menu")
		else:
			d._text_fit(Vector2(17, ly), d.menu_items[i]["label"], d.C_TEXT, left.size.x - 32)
	if d.scroll > 0:
		d._text(Vector2(left.end.x - 11, y - 2), "▲", d.C_DIM)
	if d.scroll + d.MENU_LINES < d.menu_items.size():
		d._text(Vector2(left.end.x - 11, y + d.LINE * 2 + 2), "▼", d.C_DIM)
	# Detalle de la opción elegida
	var rx = right.position.x + 8
	var rw = right.size.x - 14
	var title := _menu_title()
	var act: Dictionary = d.menu_items[d.cursor].get("action", {}) if d.cursor < d.menu_items.size() else {}
	if act.get("t", "") == "attack" and d.game.current_player().active != null:
		var box := [[]]
		d.game.with_ctx(act.get("ctx", null), func(): box[0] = d.game.current_player().active.attacks())
		var atks: Array = box[0]
		if act["a"] < atks.size():
			var atk: Dictionary = atks[act["a"]]
			d._text_scroll(Vector2(rx, y), title, d.C_DIM, rw, "mtitle")
			var cx = rx
			for t in atk.get("cost", []):
				d.imagenes._draw_energy_icon(Vector2(cx + 4.5, y + d.LINE + 5), 9, t)
				cx += 10
			if atk.get("cost", []).is_empty():
				d._text(Vector2(rx, y + d.LINE), "No cost", d.C_TEXT)
			var dmg: String = atk.get("damage_text", "")
			d._text(Vector2(rx, y + d.LINE * 2), "Damage", d.C_TEXT)
			d._text(Vector2(rx + d._text_w("Damage") + 4, y + d.LINE * 2), dmg if dmg != "" else "—", Color("#c03028"))
			return
	if img_id != "":
		# Imagen a la derecha (40x40, como en la ficha) y, al lado, la pregunta o el tipo de carta
		d.imagenes._draw_card_image(Rect2(right.end.x - 4 - d.MENU_IMG, d.BOX_Y + 4, d.MENU_IMG, d.MENU_IMG), img_id)
		var tw = right.size.x - 14 - d.MENU_IMG - 2
		var info = title if d.game.phase != "main" else _card_kind(img_id)
		var lines = d._wrap(info, tw)
		for i in mini(3, lines.size()):
			if i == 2 and lines.size() > 3:
				d._text_scroll(Vector2(rx, y + i * d.LINE), " ".join(lines.slice(2)), d.C_TEXT, tw, "mtitle")
			else:
				d._text_fit(Vector2(rx, y + i * d.LINE), lines[i], d.C_TEXT, tw)
		return
	# Solo la pregunta (elecciones): en varios renglones
	var lines = d._wrap(title, rw)
	for i in mini(3, lines.size()):
		d._text(Vector2(rx, y + i * d.LINE), lines[i], d.C_TEXT if i < 2 or lines.size() <= 3 else d.C_DIM)


func _menu_card_id() -> String:
	if d.menu_items.is_empty() or d.cursor >= d.menu_items.size():
		return ""
	var a: Dictionary = d.menu_items[d.cursor].get("action", {})
	if a.get("t", "") in ["trainer", "energy", "bench", "evolve"]:
		var hand = d.game.players[d.game.actor()].hand
		if a["h"] < hand.size():
			return hand[a["h"]]
	if a.get("t", "") == "choose" and a.has("i"):
		var opts = d.game.choice_options()
		if a["i"] < opts.size() and str(opts[a["i"]].get("id", "")) != "" and not CardDB.get_card(opts[a["i"]]["id"]).is_empty():
			return opts[a["i"]]["id"]
	return ""
# ===========================================================================
# Registro con turnos en franjas de colores
# ===========================================================================

## Franja (0 o 1) de cada línea del registro, según el número de turno.
func _log_bands() -> Array:
	var bands: Array = []
	bands.resize(d.game.log_lines.size())
	var current := -1
	var rx := RegEx.new()
	rx.compile("^— Turn (\\d+)")
	for i in d.game.log_lines.size():
		var m = rx.search(d.game.log_lines[i])
		if m != null:
			current = int(m.get_string(1)) % 2
		bands[i] = current
	# Líneas antes del primer "Turno" del registro (preparación): la franja opuesta.
	var first := -1
	for b in bands:
		if b != -1:
			first = b
			break
	for i in bands.size():
		if bands[i] == -1:
			bands[i] = 1 - first if first != -1 else 0
		else:
			break
	return bands


func _draw_log_lines(x: float, y: float, width: float, start: int, end: int, line_h: float) -> void:
	var bands := _log_bands()
	for i in range(start, end):
		var ly = y + (i - start) * line_h
		var bc: Color = d.C_BAND[bands[i]]
		if d.show_log and d._ui_tex("fondo") != null and line_h == d.LINE_S:    # sobre la caja crema
			bc = d.C_PAGE_BOX if bands[i] == 0 else Color("#f0e0b0")
		d.draw_rect(Rect2(x - 3, ly - 1, width + 6, line_h), bc)
		d._text_fit(Vector2(x, ly), d.game.log_lines[i].strip_edges(), d.C_TEXT, width)



func _draw_full_log() -> void:
	var styled = d._ui_tex("fondo") != null
	d._page(Rect2(Vector2.ZERO, Vector2(d.W, d.H)), Rect2(4, 14, d.W - 8, d.H - 30))
	var n = d.game.log_lines.size()
	var end = n - d.log_scroll
	var start = maxi(0, end - d.LOG_LINES_FULL)
	if styled:
		d._tab(Vector2(6, 3), 70, "LOG")
	else:
		d._text(Vector2(10, 5), "LOG", d.C_DIM)
	_draw_log_lines(10, 17, d.W - 20, start, end, d.LINE_S)
	d._page_hint(Vector2(d.W - 122, d.H - 14), "▲▼ scroll · Tab close")
# ===========================================================================
# Visor de la mano (tecla M)
# ===========================================================================

const HAND_ROWS := 10

## Filas del visor: [id, cantidad]. La mano va carta por carta; el descarte se agrupa
## (Fire Energy ×3) y muestra primero lo último que se descartó.
func _pile_rows() -> Array:
	var rows: Array = []
	if d.pile_view == "hand":
		for id in d.game.players[d.human].hand:
			rows.append([id, 1])
		return rows
	var pile: Array[String] = d.game.players[d.human if d.pile_side == 0 else 1 - d.human].discard
	var index := {}
	for i in range(pile.size() - 1, -1, -1):
		var id: String = pile[i]
		if index.has(id):
			rows[index[id]][1] += 1
		else:
			index[id] = rows.size()
			rows.append([id, 1])
	return rows


func _hand_input(k: int, accept: bool, back: bool) -> void:
	var rows := _pile_rows()
	if k == KEY_UP:
		d.hand_cursor = maxi(0, d.hand_cursor - 1)
	elif k == KEY_DOWN:
		d.hand_cursor = mini(rows.size() - 1, d.hand_cursor + 1)
	elif k in [KEY_LEFT, KEY_RIGHT] and d.pile_view == "discard":
		d.pile_side = 1 - d.pile_side
		d.hand_cursor = 0
	elif k == KEY_M and d.pile_view != "hand":
		d.pile_view = "hand"
		d.hand_cursor = 0
	elif k == KEY_D and d.pile_view != "discard":
		d.pile_view = "discard"
		d.pile_side = 0
		d.hand_cursor = 0
	elif (accept or k == KEY_C) and not rows.is_empty():
		var entries: Array = []
		for r in rows:
			var rid: String = r[0]
			entries.append(func(): return d.fichas._card_lines(rid, null))
		d.fichas._open_info(entries, d.hand_cursor, func(j: int): d.hand_cursor = j)
	elif back or k == KEY_M or k == KEY_D:
		d.pile_view = ""


func _draw_hand() -> void:
	var rows := _pile_rows()
	var styled = d._ui_tex("fondo") != null
	var mine = d.pile_view == "hand" or d.pile_side == 0
	var bg = d.C_MINE_BG if mine else d.C_OPP_BG
	var total := 0
	for row in rows:
		total += row[1]
	var head = "YOUR HAND (%d)" % total if d.pile_view == "hand" \
			else (("YOUR DISCARD (%d)" if mine else "OPPONENT'S DISCARD (%d)") % total)
	var right = "Opponent: %d cards" % d.game.players[1 - d.human].hand.size() if d.pile_view == "hand" else "◀▶ switch"
	if styled:
		d._page(Rect2(Vector2.ZERO, Vector2(d.W, d.H)), Rect2(4, 15, d.W - 8, d.H - 19))
		d._tab(Vector2(6, 3), d._text_w(head) + 26, head)
		d._text(Vector2(d.W - 8 - d._text_w(right), 3), right, Color.WHITE)
		bg = Color("#f8d8a8") if mine else Color("#f8c8c0")     # fila elegida, sobre la caja crema
	else:
		d._frame(Rect2(Vector2.ZERO, Vector2(d.W, d.H)))
		d.draw_rect(Rect2(5, 5, d.W - 10, d.TEXT_H + 3), bg.darkened(0.12))
		d._text(Vector2(10, 6), head, d.C_TEXT)
		d._text(Vector2(d.W - 8 - d._text_w(right) - 2, 6), right, d.C_TEXT)
	if rows.is_empty():
		d._text(Vector2(14, 26), "No cards." if d.pile_view == "discard" else "You have no cards in your hand.", d.C_TEXT)
	d.hand_cursor = clampi(d.hand_cursor, 0, maxi(0, rows.size() - 1))
	var top = clampi(d.hand_cursor - HAND_ROWS + 1, 0, maxi(0, rows.size() - HAND_ROWS))
	for i in range(top, mini(top + HAND_ROWS, rows.size())):
		var id: String = rows[i][0]
		var y = 22 + (i - top) * d.LINE_S
		d._stripe(Rect2(6, y - 1, 154, d.LINE_S), i)
		if i == d.hand_cursor:
			d.draw_rect(Rect2(6, y - 1, 154, d.LINE_S), bg)
			d._text(Vector2(10, y), "▶", d.C_TEXT)
		var chip = _card_chip_color(id)
		d.draw_rect(Rect2(19, y + 1, 7, 7), d.C_INK)
		d.draw_rect(Rect2(20, y + 2, 5, 5), chip)
		var label = CardDB.card_name(id) + (" ×%d" % rows[i][1] if rows[i][1] > 1 else "")
		if i == d.hand_cursor:
			d._text_scroll(Vector2(30, y), label, d.C_TEXT, 126, "hand_sel")
		else:
			d._text_fit(Vector2(30, y), label, d.C_TEXT, 126)
	# Imagen de la carta seleccionada, a la derecha
	if not rows.is_empty():
		var sel: String = rows[d.hand_cursor][0]
		var ir = Rect2(180, 22, d.INFO_IMG, d.INFO_IMG)
		d.draw_rect(Rect2(ir.position + Vector2(2, 2), ir.size), Color(0, 0, 0, 0.25))
		d.imagenes._draw_card_image(ir, sel)
		d._text_fit(Vector2(164, 66), _card_kind(sel), d.C_TEXT, 70)
		var sub := ""
		if CardDB.is_pokemon(sel):
			sub = "HP %d · %s" % [CardDB.hp(sel), "/".join(CardDB.types(sel).map(func(t): return d.TYPE_ES.get(t, t)))]
		elif CardDB.is_basic_energy(sel):
			sub = CardDB.basic_energy_type(sel)
		d._text_fit(Vector2(164, 77), sub, d.C_TEXT, 70)
		d._text_fit(Vector2(164, 88), sel, d.C_DIM, 70)
		# En tu turno: por qué esta carta no se puede jugar ahora (LV.X en la Banca, Partidario repetido...)
		if d.pile_view == "hand" and d.mode == "duel" and d.game.actor() == d.human:
			var why = d.game.why_unplayable(d.game.players[d.human], sel)
			if why != "":
				var wl = d._wrap(why, 72)
				for k in mini(wl.size(), 4):
					d._text(Vector2(164, 100 + k * 10), str(wl[k]), Color("#c03028"))
	if rows.size() > HAND_ROWS:
		d._text(Vector2(152, 22), "▲" if top > 0 else "", d.C_DIM)
		d._text(Vector2(152, 22 + (HAND_ROWS - 1) * d.LINE_S), "▼" if top + HAND_ROWS < rows.size() else "", d.C_DIM)
	var keys = "Z/C view card · M hand · D discard · X close"
	d._text_fit(Vector2(10, d.H - 15), keys, d.C_DIM, d.W - 20)


func _card_chip_color(id: String) -> Color:
	if CardDB.is_pokemon(id):
		var t = CardDB.types(id)
		return d.TYPE_COLORS.get(t[0] if not t.is_empty() else "Colorless", d.C_LIGHT)
	if CardDB.is_basic_energy(id):
		return d.TYPE_COLORS.get(CardDB.basic_energy_type(id), d.C_LIGHT)
	if CardDB.is_energy(id):
		return d.TYPE_COLORS["*"]
	return d.C_PANEL_DARK


func _card_kind(id: String) -> String:
	if CardDB.is_pokemon(id):
		var st: String = ["Basic", "Stage 1", "Stage 2"][CardDB.stage(id)]
		return st + (" ex" if CardDB.is_ex(id) else "")
	if CardDB.is_energy(id):
		return ("" if CardDB.is_basic_energy(id) else "Special ") + "Energy"
	if CardDB.is_supporter(id):
		return "Supporter"
	if CardDB.is_stadium(id):
		return "Stadium"
	if CardDB.is_pokemon_tool(id):
		return "Pokémon Tool"
	if CardDB.is_tm(id):
		return "TM"
	if CardDB.is_fossil(id):
		return "Fossil"
	return "Item"


func _menu_title() -> String:
	if d.intro == "call":
		return "Opening coin flip: heads or tails?"
	match d.game.phase:
		"first":
			return "You won the coin flip! Who goes first?"
		"setup":
			return "Choose your Active Pokémon" if d.game.players[d.human].active == null else "Setup"
		"choice":
			return d.game.pending_prompt()
	return d.category if d.menu_level == "list" else "Turn %d" % d.game.turn_number


# ===========================================================================
# Marca sobre el Pokémon al que apunta la opción del menú
# ===========================================================================
# Así, si hay dos Pokémon con el mismo nombre (Activo y Banca), se ve a cuál
# va la Energía, la evolución, la Poción, etc.

## Pokémon afectados por la opción seleccionada del menú: [[jugador, casilla, rol], ...]
## rol "target" = el que recibe el efecto; "source" = de dónde sale (Energía que se mueve,
## Pokémon que se retira). Así se puede dibujar una flecha de uno a otro.
func _menu_targets() -> Array:
	if d.game == null or d.game.actor() != d.human or d.menu_items.is_empty() or d.cursor >= d.menu_items.size():
		return []
	var a: Dictionary = d.menu_items[d.cursor].get("action", {})
	if a.is_empty():
		return []
	var me = d.game.actor()
	var opp = 1 - me
	# Dobles: con "ctx", "el" Activo de cada uno es el segundo
	var c = a.get("ctx", [false, false])
	var my_act = PlayerState.ACTIVE2 if c[me] else -1
	var op_act = PlayerState.ACTIVE2 if c[opp] else -1
	match a["t"]:
		"energy", "evolve":
			return [[me, a["tg"], "target"]]
		"send_out":
			return [[me, a["b"], "source"], [me, PlayerState.ACTIVE2, "target"]]
		"retreat":
			return [[me, my_act, "source"], [me, a["b"], "target"]]
		"choose":
			if a.has("b"):
				return [[me, a["b"], "target"]]
			var opts = d.game.choice_options()
			if a["i"] >= opts.size():
				return []
			var opt: Dictionary = opts[a["i"]]
			var side: int = opp if opt.get("opp", false) else me
			if opt.has("retreat_to"):
				return [[me, -1, "source"], [me, opt["retreat_to"], "target"]]
			if opt.has("s"):
				return [[side, opt["s"], "target"]]
			if opt.has("b"):
				return [[side, opt["b"], "target"]]
		"attack":
			var out: Array = [[me, my_act, "source"]]
			var tg: int = a["tg"]
			if tg == -2 or tg == -1:
				tg = op_act
			elif tg == PlayerState.ACTIVE2 and c[opp]:
				tg = -1                    # "el otro Activo" visto desde el contexto
			out.append([opp, tg, "target"])
			return out
		"trainer", "power":
			var p: Dictionary = a["p"]
			var power: bool = a["t"] == "power"
			var name = CardDB.card_name(d.game.players[me].hand[a["h"]]) if not power else str(a["n"])
			var from_slot: bool = p.has("from") and typeof(p["from"]) == TYPE_INT
			if from_slot and p.has("to"):
				return [[me, p["from"], "source"], [me, p["to"], "target"]]
			if from_slot:
				# Call for Power: hacia el que usa el poder; Metal Juncture: hacia el Activo
				return [[me, p["from"], "source"], [me, a["s"] if name == "Call for Power" else -1, "target"]]
			# Poderes que apuntan al rival; el resto (p. ej. Delta Transport) a lo propio.
			var vs_opp: bool = name == "Energy Removal 2" or (power and name in d.OPP_POWERS)
			if p.has("tg"):
				return [[opp if vs_opp else me, p["tg"], "target"]]
			if p.has("mb"):
				return [[me, p["mb"], "target"]]
			if p.has("b"):
				if power:
					return [[opp if vs_opp else me, p["b"], "target"]]          # Dragon Wind
				return [[me, -1, "source"], [me, p["b"], "target"]]   # Switch
			if power:
				return [[me, a["s"], "target"]]
	return []


func _draw_target_highlight() -> void:
	if not d.anim.is_empty() or not d.evo_anim.is_empty() or not d.coin_anim.is_empty() or not d.energy_anim.is_empty() \
			or not d.move_anim.is_empty():
		return
	var list: Array = [[d.board_sel[0], d.board_sel[1], "target"]] if d.board_view else _menu_targets()
	var valid: Array = []
	for tg in list:
		if d.game.players[tg[0]].slot(tg[1]) != null:
			valid.append(tg)
	if valid.is_empty():
		return
	var now := Clock.ms() / 1000.0
	var pulse := 0.5 + 0.5 * sin(now * 7.0)
	var src_rect := Rect2()
	var dst_rect := Rect2()
	for tg in valid:
		var r = d.anim_pokemon._slot_rect(tg[0], tg[1])
		var c: Color = d.C_ACCENT if tg[2] == "target" else d.C_SOURCE
		if tg[2] == "target":
			dst_rect = r
		else:
			src_rect = r
		# Brillo: relleno que late y halo de varias capas
		d.draw_rect(r, Color(c, 0.2 + 0.3 * pulse))
		for g in 3:
			d.draw_rect(r.grow(1 + g), Color(c, (0.9 - g * 0.3) * (0.6 + 0.4 * pulse)), false, 1.0)
		d.draw_rect(r.grow(1), Color(1, 1, 1, 0.5 * pulse), false, 1.0)
		if tg[2] == "target" and valid.size() == 1:
			# Flechita encima (o debajo, para la Banca de arriba)
			var top = r.position.y > 20
			var x = r.get_center().x
			var bounce := 1.5 * sin(now * 7.0)
			var y = (r.position.y - 3 - bounce) if top else (r.end.y + 3 + bounce)
			var dd_ = -1.0 if top else 1.0
			var tri = PackedVector2Array([Vector2(x - 4, y + dd_ * 5), Vector2(x + 4, y + dd_ * 5), Vector2(x, y)])
			d.draw_colored_polygon(tri, d.C_ACCENT)
			d.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), d.C_TEXT, 1.0)
	# Flecha animada de origen a destino
	if src_rect.size != Vector2.ZERO and dst_rect.size != Vector2.ZERO:
		# Del centro del origen al borde del destino (así no tapa el nombre)
		var a := src_rect.get_center()
		var b = d.anim_cartas._edge_point(dst_rect, a) + (a - dst_rect.get_center()).normalized()
		var dist = a.distance_to(b)
		if dist > 4.0:
			var dir = (b - a) / dist
			var bulge = Vector2(dir.y, -dir.x) * minf(14.0, dist * 0.3)
			var pts := PackedVector2Array()
			for i in 17:
				var k = i / 16.0
				pts.append(a.lerp(b, k) + bulge * sin(k * PI))
			d.draw_polyline(pts, Color(d.C_TEXT, 0.7), 3.0)
			d.draw_polyline(pts, Color(1, 1, 1, 0.9), 1.0)
			# Puntos que viajan por la curva
			for j in 3:
				var k = fmod(now * 0.9 + j / 3.0, 1.0)
				var p = a.lerp(b, k) + bulge * sin(k * PI)
				d.draw_circle(p, 1.5, d.C_SOURCE.lerp(d.C_ACCENT, k))
			var end := pts[15]
			var tip := pts[16]
			var tdir = (tip - end).normalized()
			var n = Vector2(-tdir.y, tdir.x)
			var head = PackedVector2Array([tip, tip - tdir * 5 + n * 3.0, tip - tdir * 5 - n * 3.0])
			d.draw_colored_polygon(head, d.C_ACCENT)
			d.draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), d.C_TEXT, 1.0)
# ===========================================================================
# Recorrer la mesa (tecla B): ver en detalle cualquier Pokémon en juego
# ===========================================================================
# ←/→ se mueve entre el Activo y la Banca; ↑/↓ cambia entre tu lado y el del rival.
# Abajo se ve un resumen; Z o C abre la ficha completa. Mientras está abierto, el rival espera.

func _board_input(k: int, accept: bool, back: bool, echo: bool) -> void:
	var player: int = d.board_sel[0]
	var slots: Array = d.game.players[player].slots()
	var i = slots.find(d.board_sel[1])
	match k:
		KEY_LEFT, KEY_RIGHT:
			# Recorrido continuo: tus Pokémon y después los del rival (y vuelta).
			var all: Array = []
			for pl in [d.human, 1 - d.human]:
				for sl in d.game.players[pl].slots():
					all.append([pl, sl])
			if not all.is_empty():
				var cur := 0
				for j in all.size():
					if all[j][0] == player and all[j][1] == d.board_sel[1]:
						cur = j
				d.board_sel = all[(cur + (1 if k == KEY_RIGHT else -1) + all.size()) % all.size()]
		KEY_UP, KEY_DOWN:
			var other: int = 1 - d.human if k == KEY_UP else d.human
			var os: Array = d.game.players[other].slots()
			if not os.is_empty():
				var want: int = d.board_sel[1]
				d.board_sel = [other, want if want in os else os[os.size() - 1]]
	if accept or (k == KEY_C and not echo):
		var all := _board_slots()
		var cur := 0
		for j in all.size():
			if all[j][0] == d.board_sel[0] and all[j][1] == d.board_sel[1]:
				cur = j
		if not all.is_empty():
			var entries: Array = []
			for sl in all:
				var pl: int = sl[0]
				var slot: int = sl[1]
				entries.append(func(): return _board_info(pl, slot))
			d.fichas._open_info(entries, cur, func(j: int): d.board_sel = all[j])
	elif back or (k == KEY_B and not echo):
		d.board_view = false


## Todos los lugares con Pokémon: los tuyos y después los del rival (el orden de ◀▶).
func _board_slots() -> Array:
	var all: Array = []
	for pl in [d.human, 1 - d.human]:
		for sl in d.game.players[pl].slots():
			all.append([pl, sl])
	return all


func _stadium_info() -> Array:
	if d.game.stadium == "":
		return ["(There's no Stadium in play anymore.)"]
	var lines: Array = [{"section": "STADIUM", "bg": d.C_STADIUM_BG}]
	lines.append_array(d.fichas._card_lines(d.game.stadium, null))
	return lines


func _board_info(pl: int, slot: int) -> Array:
	var mon: PokemonInPlay = d.game.players[pl].slot(slot)
	if mon == null:
		return ["(There's no Pokémon here anymore.)"]
	var mine: bool = pl == d.human
	d.info_attach = [pl, slot]
	var lines: Array = [{"section": ("YOUR " if mine else "FOE ") + d.fichas._place_name(slot).to_upper(),
			"bg": d.C_MINE_BG if mine else d.C_OPP_BG}]
	var card = d.fichas._card_lines(mon.top(), mon)
	var bi := -1
	for i in card.size():
		if card[i] is Dictionary and card[i].has("body"):
			bi = i
			break
	if bi >= 0:
		var extra: Array = []
		for r in d.anim_ataques._effect_reasons(d.game.players[pl], mon, slot):
			if str(r[0]).begins_with("est_poder"):     # el Poké-Power va sin ícono, solo el texto
				extra.append({"row": [["text", r[1], d.REASON_COL.get(r[0], d.C_TEXT)]]})
			else:
				extra.append({"row": [["fx", r[0]], ["text", r[1], d.REASON_COL.get(r[0], d.C_TEXT)]]})
		for j in extra.size():
			card.insert(bi + 3 + j, extra[j])     # después de "Damage · Energy" y las energías
	lines.append_array(card)
	return lines
# ===========================================================================
# Elegir el Premio
# ===========================================================================
# Como en el juego real, los Premios están boca abajo y vos elegís cuál tomar.
# El motor ya apartó una carta al hacer el KO; si elegís otra posición, se
# intercambian (la que estaba en esa posición va a tu mano y la otra vuelve a los
# Premios), así que te llevás exactamente la carta del lugar que elegiste.

const PRIZE_CARD := Vector2(20, 27)


## Cartas boca abajo entre las que se elige: los Premios que quedan más los que se
## están tomando ahora y todavía no se eligieron.
func _prize_pile_size(player: int) -> int:
	var n: int = d.game.players[player].prizes.size()
	for e in d.prize_anim:
		if e["p"] == player and e.get("choose", false):
			n += 1
	return n


func _prize_slot_pos(i: int) -> Vector2:
	var center = Vector2(d.W / 2.0, 56)
	var col = i % 2
	var row = i / 2
	return center + Vector2((col - 0.5) * 26.0, (row - 1) * 31.0)


func _pick_prize(k: int) -> void:
	var pz: Dictionary = d.prize_anim[0]
	var pl: PlayerState = d.game.players[pz["p"]]
	# La elección la hace el motor (así también viaja en el duelo en línea)
	if k > pl.prizes.size() and pz.has("log"):
		# Elegiste otra de las que ya se apartaron (ambas están en tu mano): solo cambia
		# cuál se muestra primero
		var pend = d.prize_anim.filter(func(e): return e["p"] == pz["p"] and e.get("choose", false) and e.has("log"))
		var j = k - pl.prizes.size()
		if j < pend.size():
			var a1: Dictionary = d.game.prize_log[pz["log"]]
			var a2: Dictionary = d.game.prize_log[pend[j]["log"]]
			for key in ["id", "up"]:
				var tmp = a1.get(key)
				a1[key] = a2.get(key)
				a2[key] = tmp
	if d.game.pending_choice_kind() == "prize" and d.game.actor() == pz["p"]:
		d._do({"t": "choose", "k": mini(k, pl.prizes.size())})
		if pz.has("log"):
			pz["id"] = d.game.prize_log[pz["log"]]["id"]
	if pz.get("quick", false):
		d.prize_anim.pop_front()
		d.prize_cursor = 0
		d._rebuild_menu()
		return
	pz["from"] = _prize_slot_pos(k)
	pz["choose"] = false
	pz["t"] = 0.08
	d.prize_cursor = 0


## Las cartas entre las que se elige, en orden de casilla: [id, boca_arriba].
## Primero los Premios que quedan y después las que el motor ya apartó y faltan elegir.
func _prize_pile(player: int) -> Array:
	var pl: PlayerState = d.game.players[player]
	var all_up: bool = pl.flags.get("prizes_face_up", false)
	var faceup: Array = pl.flags.get("faceup_prizes", [])
	var out: Array = []
	for id in pl.prizes:
		out.append([id, all_up or faceup.has(id)])
	for e in d.prize_anim:
		if e["p"] == player and e.get("choose", false):
			var cur: Dictionary = d.game.prize_log[e["log"]] if e.has("log") else e
			out.append([cur["id"], all_up or cur.get("up", false)])
	return out


func _draw_prize_choice(pz: Dictionary) -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.5))
	var n = _prize_pile_size(pz["p"])
	var pile = _prize_pile(pz["p"])
	d.prize_cursor = clampi(d.prize_cursor, 0, n - 1)
	var now := Clock.ms() / 1000.0
	var downs := 0
	for i in n:
		var c = _prize_slot_pos(i)
		var sel = i == d.prize_cursor
		var lift = -3.0 - sin(now * 6.0) if sel else 0.0
		var r = Rect2(c - PRIZE_CARD / 2 + Vector2(0, lift), PRIZE_CARD)
		d.draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.4))
		if i < pile.size() and pile[i][1]:
			d.imagenes._draw_card_image(r, pile[i][0])      # boca arriba: se ve qué es
		else:
			d.anim_cartas._draw_card_back(r)
			downs += 1
		if sel:
			d.draw_rect(r.grow(1), d.C_ACCENT, false, 2.0)
			var tip = Vector2(r.position.x - 3, r.get_center().y)
			d.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, -4), tip + Vector2(-5, 4)]), d.C_ACCENT)
	d._text(Vector2(d.W / 2.0 + 34, 12), "PRIZES", d.C_LIGHT)
	d._text(Vector2(d.W / 2.0 + 34, 23), "%d face down" % downs, d.C_LIGHT)
	if downs < n:
		d._text(Vector2(d.W / 2.0 + 34, 34), "%d face up" % (n - downs), d.C_LIGHT)
# ===========================================================================
# Menú de pausa
# ===========================================================================

func _open_pause() -> void:
	d.paused = true
	d.pause_cursor = 0
	d.pause_view = ""
	d.snd.play("ok")


func _pause_value(i: int) -> String:
	match i:
		1: return d.ANIM_SPEED_NAMES[d.anim_speed]
		2: return d.BATTLE_MODES[d.battle_mode]
		3: return d.SoundScript.LEVEL_NAMES[d.sfx_level]
		4: return d.SoundScript.LEVEL_NAMES[d.music_level]
		5: return d.table_styles[d.table_style][0]
	return ""


func _pause_change(i: int, dd_: int) -> void:
	match i:
		1: d.anim_speed = (d.anim_speed + dd_ + d.ANIM_SPEEDS.size()) % d.ANIM_SPEEDS.size()
		2: d.battle_mode = (d.battle_mode + dd_ + d.BATTLE_MODES.size()) % d.BATTLE_MODES.size()
		3, 4:
			if i == 3:
				d.sfx_level = (d.sfx_level + dd_ + 4) % 4
			else:
				d.music_level = (d.music_level + dd_ + 4) % 4
			d.snd.set_levels(d.sfx_level, d.music_level)
		5:
			d.table_style = (d.table_style + dd_ + d.table_styles.size()) % d.table_styles.size()
			d._table_tex = null
		_:
			return
	d._save_settings()


func _pause_input(k: int, accept: bool, back: bool) -> void:
	if d.pause_view == "controls":
		if accept or back or k == KEY_P:
			d.pause_view = ""
			d.snd.play("back")
		return
	if d.pause_view == "quit":
		if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			d.quit_yes = not d.quit_yes
			d.snd.play("move")
		elif accept:
			if d.quit_yes:
				d.paused = false
				if d.net != null:
					d.net.send({"k": "concede"})
				d.game.concede(d.human)
				d.snd.play("back")
			else:
				d.pause_view = ""
				d.snd.play("back")
		elif back:
			d.pause_view = ""
			d.snd.play("back")
		return
	match k:
		KEY_UP:
			d.pause_cursor = (d.pause_cursor - 1 + d.PAUSE_ITEMS.size()) % d.PAUSE_ITEMS.size()
			d.snd.play("move")
		KEY_DOWN:
			d.pause_cursor = (d.pause_cursor + 1) % d.PAUSE_ITEMS.size()
			d.snd.play("move")
		KEY_LEFT, KEY_RIGHT:
			_pause_change(d.pause_cursor, 1 if k == KEY_RIGHT else -1)
			d.snd.play("move")
	if accept:
		match d.pause_cursor:
			0:
				d.paused = false
				d.snd.play("back")
			6:
				d.pause_view = "controls"
				d.snd.play("ok")
			7:
				d.pause_view = "quit"
				d.quit_yes = false
				d.snd.play("ok")
			_:
				_pause_change(d.pause_cursor, 1)
				d.snd.play("ok")
	elif back or k == KEY_P:
		d.paused = false
		d.snd.play("back")


const CONTROLS := [
	["Z", "A", "Accept"], ["X", "B", "Back"], ["Arrows", "D-Pad", "Move"],
	["P", "Start", "Pause"], ["C", "X", "View card"], ["B", "Y", "View table"],
	["M", "L", "Your hand"], ["D", "R", "Discard piles"], ["Tab", "Select", "Log"],
]


func _draw_pause() -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.5))
	if d.pause_view == "controls":
		d._page(Rect2(0, 0, d.W, d.H), Rect2(4, 3, d.W - 8, d.H - 19))
		d._text(Vector2(10, 5), "CONTROLS", d.C_DIM)
		d._text(Vector2(100, 5), "Keyboard", d.C_DIM)
		d._text(Vector2(165, 5), "Control", d.C_DIM)
		for i in CONTROLS.size():
			var y = 18 + i * 12
			var row: Array = CONTROLS[i]
			d._text(Vector2(10, y), row[2], d.C_TEXT)
			d._text(Vector2(100, y), row[0], Color("#c03028"))
			d._text(Vector2(165, y), row[1], d.C_FRAME_MID.darkened(0.3))
		d._page_hint(Vector2(10, d.H - 14), "X in the menu also pauses")
		d._page_hint(Vector2(d.W - 10 - d._text_w("Z: back"), d.H - 14), "Z: back")
		return
	var r := Rect2(44, 14, 152, 111)
	d._frame(r)
	d._text_center(r.position.y + 4, "PAUSE", d.C_TEXT)
	for i in d.PAUSE_ITEMS.size():
		var y = r.position.y + 16 + i * 11
		var sel = i == d.pause_cursor
		d._stripe(Rect2(r.position.x + 4, y - 1, r.size.x - 8, 11), i)
		if sel:
			d._text(Vector2(r.position.x + 8, y), "▶", d.C_TEXT)
		d._text(Vector2(r.position.x + 17, y), d.PAUSE_ITEMS[i], Color("#c03028") if i == 7 else d.C_TEXT)
		var v = _pause_value(i)
		if v != "":
			var vs = ("◀ " + v + " ▶") if sel else v
			d._text(Vector2(r.end.x - 8 - d._text_w(vs), y), vs, d.C_TEXT if sel else d.C_DIM)
	if d.pause_view == "quit":
		var q := Rect2(30, 122, 180, 36)
		d._frame(q)
		d._text(Vector2(q.position.x + 9, q.position.y + 4), "Concede? You lose this game.", d.C_TEXT)
		d._text(Vector2(q.position.x + 30, q.position.y + 17), "No", d.C_TEXT)
		d._text(Vector2(q.position.x + 100, q.position.y + 17), "Yes", d.C_TEXT)
		d._text(Vector2(q.position.x + (92 if d.quit_yes else 22), q.position.y + 17), "▶", d.C_TEXT)
# ===========================================================================
# Pantalla de resultados
# ===========================================================================

func _results_showing() -> bool:
	return d.mode == "duel" and d.game != null and d.game.phase == "over" and d.anim.is_empty() and d.ko_anim.is_empty() and d.check_anim.is_empty() \
			and d.prize_anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty() and d.energy_anim.is_empty() \
			and d.trainer_anim.is_empty() and d.move_anim.is_empty() and d.power_anim.is_empty()


func _draw_results() -> void:
	d._page(Rect2(0, 0, d.W, d.H), Rect2(3, 3, d.W - 6, d.H - 6))
	var won = d.game.winner == d.human
	var title = "YOU WON!" if won else ("DRAW" if d.game.winner == 2 else "YOU LOST")
	if won:
		_draw_confetti()
	var art = "ganaste" if won else ("empate" if d.game.winner == 2 else "perdiste")
	if d.anim_pokemon._banner_art(art) != null:
		# Cae desde arriba con un rebote; si ganaste, además late de a ratos
		var drop = clampf(d.results_t / 0.45, 0.0, 1.0)
		var bounce = absf(sin(drop * PI * 1.5)) * (1.0 - drop) * 14.0
		var y = 14.0 - (1.0 - drop) * 30.0 - bounce
		var beat := 1.0
		if won and d.results_t > 0.6:
			var ph = fmod(d.results_t - 0.6, 1.4)
			beat = 1.0 + 0.12 * maxf(0.0, sin(ph / 0.25 * PI)) if ph < 0.25 else 1.0
		var tex = d.anim_pokemon._banner_art(art)
		var sz = Vector2(tex.get_width(), tex.get_height())
		d.draw_set_transform(d._base_off + Vector2(d.W / 2.0, roundf(y)), 0, Vector2(beat, beat))
		d.draw_texture(tex, (-sz / 2.0).round())
		d.draw_set_transform(d._base_off)
	else:
		d._text_center(5, title, Color("#c03028") if won else d.C_FRAME_MID.darkened(0.3), true)
	var reason = d.game.win_reason
	if d._text_w(reason) > d.W - 16:
		d._text_scroll(Vector2(8, 27), reason, d.C_DIM, d.W - 16, "res_reason")
	else:
		d._text_center(27, reason, d.C_DIM)
	for side in 2:
		var pl = d.human if side == 0 else 1 - d.human
		var x := 6 + side * 116
		var bg = d.C_MINE_BG if side == 0 else d.C_OPP_BG
		d.draw_rect(Rect2(x, 40, 112, 12), bg.darkened(0.1))
		d._text(Vector2(x + 4, 41), "YOU" if side == 0 else "OPPONENT", d.C_TEXT)
		# El Pokémon que más daño hizo
		var mvp = d.game.mvp(pl)
		var img = Rect2(x + 2, 56, d.MENU_IMG, d.MENU_IMG)
		if mvp.is_empty():
			d.anim_cartas._draw_card_back(img)
			d._text(Vector2(x + 46, 60), "No damage", d.C_DIM)
		else:
			d.imagenes._draw_card_image(img, mvp["id"])
			d._text(Vector2(x + 46, 55), "Top damage:", d.C_DIM)
			d._text_scroll(Vector2(x + 46, 66), CardDB.card_name(mvp["id"]), d.C_TEXT, 64, "mvp%d" % side)
			d._text(Vector2(x + 46, 77), "%d damage" % mvp["dmg"], Color("#c03028"))
		var prizes = d.game.prize_log.filter(func(e): return e["p"] == pl).size()
		var rows = [["Prizes", prizes], ["KO", d.game.stats[pl]["kos"]], ["Total damage", d.game.stats[pl]["dmg"]]]
		for j in rows.size():
			var y = 100 + j * 12
			d._text(Vector2(x + 4, y), rows[j][0], d.C_TEXT)
			var v = str(rows[j][1])
			d._text(Vector2(x + 108 - d._text_w(v), y), v, d.C_TEXT)
	_draw_result_trainers(won)
	d._text(Vector2(8, 145), "Turns: %d" % d.game.turn_number, d.C_DIM)
	var cont = "Z: continue" if d.campaign_rival != "" else "Z: back to title"
	d._text(Vector2(d.W - 8 - d._text_w(cont), 145), cont, d.C_TEXT)


## Confeti que cae detrás de todo cuando ganás.
func _draw_confetti() -> void:
	var cols := [Color("#f85838"), Color("#f8d030"), Color("#58a8f8"), Color("#68d058"), Color("#f878c8"), Color.WHITE]
	for i in 72:
		var spd = 22.0 + float(i % 5) * 7.0
		var y = fmod(d.results_t * spd + float(i * 37 % 170), d.H + 12.0) - 8.0
		var x = fmod(float(i * 53) + sin(d.results_t * 2.2 + i) * 6.0, d.W)
		var flip = int(d.results_t * 6.0 + i) % 2 == 0      # gira: a veces se ve de canto
		var sz = Vector2(3, 2) if flip else Vector2(2, 3)
		d.draw_rect(Rect2(Vector2(roundf(x), roundf(y)), sz), cols[i % cols.size()])


## Vos y el rival a los costados del título (los personajes del mapa): el que ganó salta
## de alegría; el que perdió se queda con la cabeza gacha, más oscuro y con una gotita.
## En un empate los dos se quedan quietos.
func _draw_result_trainers(won: bool) -> void:
	if d.campaign == null:
		return
	var draw_game = d.game.winner == 2
	for side in 2:
		var id = "jugador" if side == 0 else d.rival_sprite
		if id == "":
			continue
		var tex: Texture2D = d.campaign.world._sprite(id)
		if tex == null or tex.get_height() < 128:
			continue
		var winner = not draw_game and (won == (side == 0))
		var feet = Vector2(10 if side == 0 else d.W - 26, 37)
		var col := 0
		var tint := Color.WHITE
		if winner:
			# Saltitos: sube y baja (parábola) con una pausa entre salto y salto
			var ph = fmod(d.results_t, 0.7)
			if ph < 0.4:
				var k = ph / 0.4
				feet.y -= roundf(4.0 * k * (1.0 - k) * 4.0)
				col = 1 + int(d.results_t / 0.7) % 2      # piernas abiertas en el aire
		elif not draw_game:
			tint = Color(0.62, 0.62, 0.78)
			feet.y += 1
		d.draw_rect(Rect2(feet.x + 4, 37, 8, 2), Color(0, 0, 0, 0.25))     # sombra
		var dst = Rect2(feet + Vector2(0, -29), Vector2(16, 32))
		if not winner and not draw_game:
			# Cabeza gacha: la mitad de arriba se dibuja un píxel más abajo (encima del cuerpo)
			d.draw_texture_rect_region(tex, Rect2(dst.position + Vector2(0, 14), Vector2(16, 18)), Rect2(0, 14, 16, 18), tint)
			d.draw_texture_rect_region(tex, Rect2(dst.position + Vector2(0, 2), Vector2(16, 14)), Rect2(0, 0, 16, 14), tint)
			# Gotita de sudor
			var dp = dst.position + Vector2(13 if side == 0 else 1, 9 + fmod(d.results_t * 3.0, 3.0))
			d.draw_rect(Rect2(dp, Vector2(2, 3)), Color("#88c8f8"))
			d.draw_rect(Rect2(dp + Vector2(0.5, -1), Vector2(1, 1)), Color("#88c8f8"))
		else:
			d.draw_texture_rect_region(tex, dst, Rect2(col * 16, 0, 16, 32), tint)
# ===========================================================================
# Panel de Premios boca arriba (tecla R)
# ===========================================================================
# Cuando un efecto deja Premios boca arriba (Island Hermit, Here Comes Team Rocket!...),
# aparece una "R" junto a los Premios y con R se deslizan dos paneles: a la izquierda los
# Premios que le quedan al rival y a la derecha los tuyos. Los boca abajo se ven de dorso.

const PV_W := 70.0
const PV_H := 107.0
const PV_SLOT := Vector2(27, 26)


func _prize_is_up(pl: PlayerState, id: String) -> bool:
	return pl.flags.get("prizes_face_up", false) or pl.flags.get("faceup_prizes", []).has(id)


func _player_has_up_prizes(pl: PlayerState) -> bool:
	return pl.prizes.any(func(id): return _prize_is_up(pl, id))


func _prizes_revealed() -> bool:
	return d.mode == "duel" and d.game != null and d.game.phase != "over" \
			and d.game.players.any(func(pl): return _player_has_up_prizes(pl))


func _open_prize_view() -> void:
	d.snd.play("ok")
	# El cursor arranca en tu primer Premio boca arriba (o en el del rival)
	var start := [2, 0]
	for side in [1, 0]:
		var pl: PlayerState = d.game.players[d.human if side == 1 else 1 - d.human]
		for i in pl.prizes.size():
			if _prize_is_up(pl, pl.prizes[i]):
				start = [side * 2 + i % 2, i / 2]
				break
		if start != [2, 0] or side == 0:
			break
	d.prize_view = {"open": true, "t": 0.0, "col": start[0], "row": start[1]}
	d.show_log = false


## Jugador y número de Premio que marca el cursor.
func _prize_view_sel() -> Array:
	var side: int = int(d.prize_view["col"]) / 2
	var pl: PlayerState = d.game.players[d.human if side == 1 else 1 - d.human]
	return [pl, int(d.prize_view["row"]) * 2 + int(d.prize_view["col"]) % 2]


func _prize_view_input(k: int, accept: bool, close: bool) -> void:
	if close:
		d.snd.play("back")
		d.prize_view["open"] = false
		return
	if k in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		d.snd.play("move")
	match k:
		KEY_LEFT: d.prize_view["col"] = maxi(0, d.prize_view["col"] - 1)
		KEY_RIGHT: d.prize_view["col"] = mini(3, d.prize_view["col"] + 1)
		KEY_UP: d.prize_view["row"] = maxi(0, d.prize_view["row"] - 1)
		KEY_DOWN: d.prize_view["row"] = mini(2, d.prize_view["row"] + 1)
	if accept:
		var sel := _prize_view_sel()
		var pl: PlayerState = sel[0]
		var i: int = sel[1]
		if i < pl.prizes.size() and _prize_is_up(pl, pl.prizes[i]):
			d.snd.play("ok")
			var id: String = pl.prizes[i]
			d.fichas._open_info([func(): return d.fichas._card_lines(id, null)], 0)


## La "R" junto a los Premios de quien tenga alguno boca arriba (titila).
func _draw_prize_hint() -> void:
	if not _prizes_revealed() or not d.prize_view.is_empty() or d.mode != "duel":
		return
	if int(Clock.ms() / 400) % 3 == 2:
		return
	for pl in d.game.players:
		if not _player_has_up_prizes(pl):
			continue
		var o = d._counters_pos(pl.index)
		var at = Vector2(o.x + 47, o.y + 2) if o.x < d.W / 2.0 else Vector2(o.x - 10, o.y + 4)
		var r = Rect2(at, Vector2(9, 9))
		d.draw_rect(r, Color("#483810"))
		d.draw_rect(r.grow(-1), d.C_ACCENT)
		_draw_tiny_letter_r(at + Vector2(3, 2))


func _draw_tiny_letter_r(p: Vector2) -> void:
	var g := ["110", "101", "110", "101", "101"]
	for row in 5:
		for col in 3:
			if g[row][col] == "1":
				d.draw_rect(Rect2(p.x + col, p.y + row, 1, 1), Color("#483810"))


func _draw_prize_view() -> void:
	if d.prize_view.is_empty():
		return
	var t: float = d.prize_view["t"]
	var e = 1.0 - pow(1.0 - t, 3.0)
	var slide = (PV_W + 5.0) * e
	var blink := int(Clock.ms() / 220) % 2 == 0
	for side in 2:
		var pl: PlayerState = d.game.players[d.human if side == 1 else 1 - d.human]
		var x0 = (-PV_W - 3.0 + slide) if side == 0 else (d.W + 3.0 - slide)
		var box = Rect2(x0, 2, PV_W, PV_H)
		d.draw_rect(Rect2(box.position + Vector2(2, 2), box.size), d.C_INK)
		d.draw_rect(box, Color("#f8f8e8"))
		d._outline(box, Color("#484850"))
		var head := Color("#d84840") if side == 0 else Color("#3868c8")
		d.draw_rect(Rect2(box.position + Vector2(1, 1), Vector2(PV_W - 2, 11)), head)
		var title := "RIVAL" if side == 0 else "YOU"
		d._text(Vector2(x0 + (PV_W - d._text_w(title)) / 2.0, 2), title, d.C_LIGHT)
		var ups = pl.prizes.filter(func(id): return _prize_is_up(pl, id)).size()
		var sub = "%d left · %d up" % [pl.prizes.size(), ups]
		d._text(Vector2(x0 + (PV_W - d._text_w(sub)) / 2.0, 13), sub, d.C_TEXT)
		for i in 6:
			var r = Rect2(x0 + 7 + (i % 2) * (PV_SLOT.x + 2), 26 + (i / 2) * (PV_SLOT.y + 2), PV_SLOT.x, PV_SLOT.y)
			if i < pl.prizes.size():
				if _prize_is_up(pl, pl.prizes[i]):
					d.imagenes._draw_card_image(r, pl.prizes[i])
				else:
					d.anim_cartas._draw_card_back(r)
			else:
				# Ya tomado: hueco punteado
				for dd_ in range(0, int(r.size.x), 3):
					d.draw_rect(Rect2(r.position.x + dd_, r.position.y, 1, 1), d.C_DIM)
					d.draw_rect(Rect2(r.position.x + dd_, r.end.y - 1, 1, 1), d.C_DIM)
				for dd_ in range(0, int(r.size.y), 3):
					d.draw_rect(Rect2(r.position.x, r.position.y + dd_, 1, 1), d.C_DIM)
					d.draw_rect(Rect2(r.end.x - 1, r.position.y + dd_, 1, 1), d.C_DIM)
			var sel: bool = d.prize_view["open"] and int(d.prize_view["col"]) / 2 == side \
					and int(d.prize_view["row"]) * 2 + int(d.prize_view["col"]) % 2 == i
			if sel and blink:
				d._outline(r.grow(2), d.C_ACCENT)
				d._outline(r.grow(1), d.C_LIGHT)


func _draw_prize_view_text(x: float, y: float) -> void:
	var sel := _prize_view_sel()
	var pl: PlayerState = sel[0]
	var i: int = sel[1]
	var who = "Your" if pl.index == d.human else "Rival's"
	d._text(Vector2(x, y), "%s Prize %d:" % [who, i + 1], d.C_TEXT)
	if i >= pl.prizes.size():
		d._text(Vector2(x, y + d.LINE), "Already taken.", d.C_DIM)
		d._text(Vector2(x, y + d.LINE * 2), "R/X: close", d.C_DIM)
	elif _prize_is_up(pl, pl.prizes[i]):
		var id: String = pl.prizes[i]
		var line = CardDB.card_name(id)
		if CardDB.is_pokemon(id):
			var c = CardDB.get_card(id)
			var st: Array = c.get("subtypes", [])
			line += "  " + ("Stage 2" if "Stage 2" in st else "Stage 1" if "Stage 1" in st else "Basic") + "  HP " + str(c.get("hp", ""))
		d._text(Vector2(x, y + d.LINE), line, d.C_TEXT)
		d._text(Vector2(x, y + d.LINE * 2), "Z: card info   R/X: close", d.C_DIM)
	else:
		d._text(Vector2(x, y + d.LINE), "Face down.", d.C_DIM)
		d._text(Vector2(x, y + d.LINE * 2), "R/X: close", d.C_DIM)
