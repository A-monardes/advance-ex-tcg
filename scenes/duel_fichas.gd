extends RefCounted
## Fichas de cartas (C): ficha completa, vista partida de los Activos, arte en grande y galería
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


# ===========================================================================
# Fichas de cartas (tecla C)
# ===========================================================================

func _info_for_cursor() -> Array:
	var me = d.game.players[d.human]
	if d.menu_items.is_empty() or d.menu_level == "root" and d.game.phase == "main":
		var lines: Array = []
		if me.active != null:
			lines.append({"section": "YOUR ACTIVE", "bg": d.C_MINE_BG})
			lines.append_array(_card_lines(me.active.top(), me.active))
		var opp = d.game.players[1 - d.human]
		if opp.active != null:
			lines.append({"section": "OPPONENT'S ACTIVE", "bg": d.C_OPP_BG})
			lines.append_array(_card_lines(opp.active.top(), opp.active))
		if d.game.stadium != "":
			lines.append({"section": "STADIUM", "bg": d.C_STADIUM_BG})
			lines.append_array(_card_lines(d.game.stadium, null))
		return lines
	var a: Dictionary = d.menu_items[d.cursor].get("action", {})
	if a.is_empty():      # opciones que no son jugadas (cara o cruz, confirmar fin de turno)
		return []
	if a.has("h") and a["t"] != "choose":
		var actor_p = d.game.players[d.game.actor()]
		return _card_lines(actor_p.hand[a["h"]], null)
	if a["t"] == "attack" or a["t"] == "power":
		return _card_lines(me.active.top() if a["t"] == "attack" else me.slot(a["s"]).top(), null)
	if a["t"] in ["retreat", "choose"] and a.has("b"):
		var p = d.game.players[d.game.actor()].bench[a["b"]]
		return _card_lines(p.top(), p)
	var opt: Dictionary = d.game.choice_options()[a["i"]] if a.has("i") else {}
	if opt.has("id") and opt["id"] != "":
		return _card_lines(opt["id"], null)
	return []


func _card_lines(id: String, p: PokemonInPlay) -> Array:
	var c = CardDB.get_card(id)
	# Cabecera (imagen + datos básicos), cuerpo (habilidades, ataques...) y pie (debilidad,
	# resistencia, retirada): _draw_info los dibuja en paneles separados.
	var lines: Array = [{"img": id, "head": true}]
	lines.append({"row": [["bold", c.get("name", "?")], ["dim", "  " + id]]})
	if CardDB.is_pokemon(id):
		lines.append(", ".join(c.get("subtypes", [])))
		var tr: Array = [["text", "HP %d  " % int(c.get("hp", 0))]]
		for t in c.get("types", []):
			tr.append(["icon", t])
			tr.append(["text", d.TYPE_ES.get(t, t) + " "])
		lines.append({"row": tr})
		var from = str(c.get("evolves_from", c.get("evolvesFrom", "")))
		if from != "":
			lines.append({"text": "From " + from, "color": d.C_DIM})
		lines.append({"body": true})
		if p != null:
			lines.append("Damage %d · Energy %d %s" % [p.damage, Energy.total(p), p.conditions_text()])
			lines.append(_attached_text(p))
		if CardDB.is_holon_energy(id):
			# Pokémon Holon's: también se juegan como Energía (texto del recuadro de la carta)
			lines.append({"gap": d.INFO_GAP})
			lines.append({"row": [["bold", "As Energy", d.C_ENERGY_RULE]]})
			lines.append_array(_para(CardDB.holon_energy_text(id), d.C_ENERGY_RULE))
		for ab in c.get("abilities", []):
			lines.append({"gap": d.INFO_GAP})
			var col: Color = d.C_POWER if ab["kind"] == "Poké-Power" else d.C_BODY
			lines.append({"row": [["bold", ab["kind"] + ": ", col], ["bold", ab["name"], col]]})
			lines.append_array(_para(str(ab["text"]), col))
		_attack_lines(lines, c)
		if CardDB.is_level_up(id):
			# Pokémon LV.X: la regla de la carta y, en juego, lo que conserva de su nivel anterior
			lines.append({"gap": d.INFO_GAP})
			lines.append_array(_para(str(c.get("text", "")), d.C_DIM))
			var prev = p.lower_level() if p != null else ""
			if prev != "":
				var pc: Dictionary = CardDB.get_card(prev)
				lines.append({"sub": "PREVIOUS LEVEL: " + CardDB.card_name(prev).to_upper()})
				for ab in pc.get("abilities", []):
					lines.append({"gap": d.INFO_GAP})
					var col2: Color = d.C_POWER if ab["kind"] == "Poké-Power" else d.C_BODY
					lines.append({"row": [["bold", ab["kind"] + ": ", col2], ["bold", ab["name"], col2]]})
					lines.append_array(_para(str(ab["text"]), col2))
				_attack_lines(lines, pc)
		# Herramienta y MT unidas, con su imagen y su texto
		if p != null:
			for extra in [[p.tool, "ATTACHED TOOL"], [p.tm, "ATTACHED TECHNICAL MACHINE"]]:
				if extra[0] != "":
					lines.append({"sub": extra[1]})
					var sub_lines: Array = _card_lines(extra[0], null)
					lines.append_array(sub_lines.filter(func(l): return not (l is Dictionary and (l.has("head") or l.has("body") or l.has("foot")))))
		lines.append({"foot": true})
		var wr: Array = [["text", "Weakness "]]
		for t in c.get("weaknesses", []):
			wr.append(["icon", t])
			if c.get("weakness_plus", {}).has(t):      # DP: +10/+20/+30 en vez de x2
				wr.append(["text", "+%d" % int(c["weakness_plus"][t])])
		if c.get("weaknesses", []).is_empty():
			wr.append(["text", "-"])
		wr.append(["text", "   Resistance "])
		for t in c.get("resistances", []):
			wr.append(["icon", t])
		if c.get("resistances", []).is_empty():
			wr.append(["text", "-"])
		wr.append(["text", "   Retreat "])
		for i in int(c.get("retreat", 0)):
			wr.append(["icon", "Colorless"])
		if int(c.get("retreat", 0)) == 0:
			wr.append(["text", "0"])
		lines.append({"row": wr})
	else:
		lines.append(", ".join(c.get("subtypes", [])) if not c.get("subtypes", []).is_empty() else str(c.get("supertype", "")))
		lines.append({"body": true})
		lines.append_array(_para(str(c.get("text", "")).replace("You can play only one Supporter card each turn. When you play this card, put it next to your Active Pokémon. When your turn ends, discard this card. ", "")))
		# MT y Estadios que dan un ataque (Rocket's Tricky Gym, Holon Lake...): el ataque con su costo
		_attack_lines(lines, c)
	return lines


## Los ataques de la carta en la ficha: costo con íconos, nombre, daño y texto.
func _attack_lines(lines: Array, c: Dictionary) -> void:
	for atk in c.get("attacks", []):
		lines.append({"gap": d.INFO_GAP})
		var row: Array = []
		for t in atk.get("cost", []):
			row.append(["icon", t])
		if atk.get("cost", []).is_empty():
			row.append(["text", "(no cost)"])
		row.append(["bold", "  " + atk["name"]])
		row.append(["text", "  " + atk.get("damage_text", "")])
		lines.append({"row": row})
		if str(atk.get("text", "")) != "":
			lines.append_array(_para(str(atk["text"]), d.C_TEXT))


## Un párrafo de la ficha partido en renglones del ancho del panel del medio, para que
## ▲▼ lo recorra de a un renglón aunque no entre entero.
func _para(text: String, col: Color = d.C_TEXT) -> Array:
	var out: Array = []
	for l in d._wrap(d._type_marks(text), d.W - 22.0):
		var plain := str(l)
		var i = plain.find(d.ICON_MARK)
		while i >= 0:                  # los íconos se vuelven a poner al dibujar
			plain = plain.substr(0, i) + plain.substr(i + 2)
			i = plain.find(d.ICON_MARK)
		out.append({"text": plain, "color": col})
	return out
func _draw_info() -> void:
	var r = Rect2(Vector2(0, 0), Vector2(d.W, d.H))
	d._page(r, Rect2(4, 3, d.W - 8, d.H - 19))
	d.info_more = false
	if not d.info_lines.is_empty() and d.info_lines[0] is Dictionary and d.info_lines[0].has("split"):
		_draw_split_info()
	elif _info_card_start() >= 0:
		_draw_info_card()
	else:
		_info_flow(d.info_lines.slice(d.info_offset), 6.0, d.H - 17.0, 10.0, d.W - 20.0, null)
	# Ayuda abajo: solo lo que se puede hacer, y flechitas si hay más texto
	var hint: Array = []
	if d.info_nav.size() > 1:
		hint.append("◀▶ %d/%d" % [d.info_nav_i + 1, d.info_nav.size()])
	if (d.info_more or d.info_offset > 0) and _info_card_start() <= 0:
		hint.append("▲▼ read")      # con rótulo abajo no entra: la flechita ▼/▲ ya lo indica
	if _info_img() != "":
		hint.append("C art")
	if not d.info_stack.is_empty():
		hint.append("Z back")
	elif not _info_attached().is_empty():
		hint.append("Z attached")
		hint.append("X close")
	else:
		hint.append("Z close")
	var ht := " · ".join(hint)
	d._page_hint(Vector2(d.W - 9 - d._text_w(ht), d.H - 14), ht)
	# De quién es la carta (TU ACTIVO, RIVAL · BANCA 2, ESTADIO...): abajo a la izquierda
	var ax := 10.0
	var hi := _info_card_start()
	if hi > 0:
		var section: Dictionary = d.info_lines[hi - 1]
		var st: String = section["section"]
		var sr = Rect2(8, d.H - 15, d._text_w(st) + 6, d.TEXT_H + 1)
		d.draw_rect(sr.grow(1), d.C_INK)
		d.draw_rect(sr, section.get("bg", d.C_MINE_BG))
		d._text(sr.position + Vector2(3, 0), st, d.C_TEXT)
		ax = sr.end.x + 4
	if d.info_more and int(Clock.ms() / 350.0) % 2 == 0:
		d._text(Vector2(ax, d.H - 14), "▼", Color("#e03828"))
	elif d.info_offset > 0:
		d._page_hint(Vector2(ax, d.H - 14), "▲")


## Si info_lines es la ficha de UNA carta (con o sin rótulo de sección delante), el índice de
## su cabecera; si no (texto suelto o varias cartas), -1.
func _info_card_start() -> int:
	var hi = _info_find("head")
	if hi < 0:
		return -1
	for i in hi:
		if not (d.info_lines[i] is Dictionary and d.info_lines[i].has("section")):
			return -1
	for i in range(hi + 1, d.info_lines.size()):
		if d.info_lines[i] is Dictionary and d.info_lines[i].has("head"):
			return -1
	return hi


## Índice del primer renglón marcado con key ("head", "body", "foot"), o -1.
func _info_find(key: String) -> int:
	for i in d.info_lines.size():
		if d.info_lines[i] is Dictionary and d.info_lines[i].has(key):
			return i
	return -1


## Dibuja renglones de la ficha de arriba hacia abajo desde y, hasta bottom, en la columna
## que empieza en x0 y mide width. Si no entran todos, deja info_more en true.
func _info_flow(lines: Array, y: float, bottom: float, x0: float, width: float, bg: Variant) -> void:
	var styled = d._ui_tex("fondo") != null
	var images: Array = []        # [Rect2, id o textura] para dibujar al final
	var narrow_until := -1.0      # el texto deja lugar a la imagen hasta esta altura
	var side_w = d.INFO_IMG        # ancho de esa imagen
	if styled:
		bg = null                 # sobre la caja crema, las secciones se marcan con pestañas
	var drawn := 0
	for line in lines:
		if y > bottom - 9:
			d.info_more = true
			break
		drawn += 1
		if line is Dictionary:
			if line.has("section"):
				bg = line["bg"]
				y += 2
				if styled:            # pestaña verde, y el texto de la sección sobre la caja crema
					bg = null
					d._tab(Vector2(6, y), minf(d.W - 12, d._text_w(line["section"]) + 30), line["section"], d.TEXT_H + 2)
				else:
					d.draw_rect(Rect2(5, y, d.W - 10, d.TEXT_H + 3), Color(bg).darkened(0.12))
					d._text(Vector2(x0, y + 1), line["section"], d.C_TEXT)
				y += d.TEXT_H + 3
			if line.has("gap"):      # espacio entre ataques, para que se lean mejor
				if bg != null:
					d.draw_rect(Rect2(5, y, d.W - 10, line["gap"]), bg)
				y += line["gap"]
				continue
			if line.get("img", "") != "":
				var bt = _art_banner(line["img"])
				if bt != null:            # el arte completo, apaisado, arriba a la derecha
					images.append([Rect2(d.W - 10 - d.BANNER_W, y + 2, d.BANNER_W, d.BANNER_H), bt])
					side_w = d.BANNER_W
					narrow_until = y + d.BANNER_H + 4
				else:
					images.append([Rect2(d.W - 52, y + 2, d.INFO_IMG, d.INFO_IMG), line["img"]])
					side_w = d.INFO_IMG
					narrow_until = y + d.INFO_IMG + 4
			if line.has("sub"):
				if y + d.TEXT_H + 6 > bottom:
					d.info_more = true
					break
				y += 3
				if bg != null:
					d.draw_rect(Rect2(5, y - 3, d.W - 10, d.TEXT_H + 6), bg)
				d.draw_line(Vector2(x0, y + 4), Vector2(d.W - 12, y + 4), d.C_PANEL_DARK)
				var lw = d._text_w(line["sub"]) + 6
				d.draw_rect(Rect2(14, y - 1, lw, d.TEXT_H + 1), bg if bg != null else d.C_PANEL)
				d._text(Vector2(17, y - 1), line["sub"], d.C_DIM)
				y += d.TEXT_H + 3
				narrow_until = -1.0
				continue
			if line.has("text"):
				var tw = width - (side_w + 8 if y < narrow_until else 0)
				if y < narrow_until and d._wrap(d._type_marks(line["text"]), tw).size() > 2:
					y = narrow_until      # un párrafo largo empieza debajo de la imagen, a lo ancho
					tw = width
				var th = d._wrap(d._type_marks(line["text"]), tw).size() * d.LINE_S + 1
				if y + th > bottom:
					d.info_more = true
					break
				if bg != null:
					d.draw_rect(Rect2(5, y, d.W - 10, th), bg)
				d._text_wrap(Vector2(x0, y), d._type_marks(line["text"]), tw, line.get("color", d.C_TEXT))
				y += th
				continue
			if line.has("row"):
				var rh = d.TEXT_H + 3
				if y + rh > bottom:
					d.info_more = true
					break
				if bg != null:
					d.draw_rect(Rect2(5, y, d.W - 10, rh), bg)
				d.imagenes._draw_icon_row(Vector2(x0, y), line["row"])
				y += rh
			continue
		var s: String = d._type_marks(line)
		var lw = width - (side_w + 8 if y < narrow_until else 0)
		if y < narrow_until and d._wrap(s, lw).size() > 2:
			y = narrow_until
			lw = width
		var h = d._wrap(s, lw).size() * d.LINE_S + 1
		if y + h > bottom:
			d.info_more = true
			break
		if bg != null:
			d.draw_rect(Rect2(5, y, d.W - 10, h), bg)
		d._text_wrap(Vector2(x0, y), s, lw, d.C_TEXT)
		y += h
	for im in images:
		var rect: Rect2 = im[0]
		if rect.end.y < bottom:
			if im[1] is Texture2D:
				d.draw_texture(im[1], rect.position)
			else:
				d.imagenes._draw_card_image(rect, im[1])


## La ficha de una carta en tres paneles: arriba la imagen con los datos básicos, en el medio
## lo que hace (habilidades, ataques: es lo único que se desplaza con ▲▼) y abajo debilidad,
## resistencia y retirada.
func _draw_info_card() -> void:
	var hi := _info_card_start()
	var bi = _info_find("body")
	var fi = _info_find("foot")
	if bi < 0:
		bi = d.info_lines.size()
	var id: String = d.info_lines[hi]["img"]
	# --- Cabecera
	var head = Rect2(6, 4, d.W - 12, d.BANNER_H + 6)
	d._cream_box(head)
	var art = _art_banner(id)
	var aw = d.BANNER_W if art != null else d.INFO_IMG
	var ah = d.BANNER_H if art != null else d.INFO_IMG
	var ar = Rect2(head.end.x - 3 - aw, head.position.y + 3, aw, ah)
	if art != null:
		d.draw_texture(art, ar.position)
	else:
		d.imagenes._draw_card_image(ar, id)
	var y = head.position.y + 2.0
	var tw = ar.position.x - head.position.x - 10.0
	for line in d.info_lines.slice(hi + 1, bi):
		if line is Dictionary and line.has("row"):
			d.imagenes._draw_icon_row(Vector2(head.position.x + 5, y), line["row"])
			y += d.TEXT_H + 2
		elif line is Dictionary and line.has("text"):
			d._text_fit(Vector2(head.position.x + 5, y), str(line["text"]), line.get("color", d.C_TEXT), tw)
			y += d.LINE_S + 1
		elif line is String:
			d._text_fit(Vector2(head.position.x + 5, y), line, d.C_TEXT, tw)
			y += d.LINE_S + 1
	# --- Pie
	var foot_h := 0.0
	if fi >= 0:
		foot_h = d.TEXT_H + 7
		var foot = Rect2(6, d.H - 17 - foot_h - 1, d.W - 12, foot_h)
		d._tab(foot.position, foot.size.x, "", foot_h)
		for line in d.info_lines.slice(fi + 1):
			if line is Dictionary and line.has("row"):
				d.imagenes._draw_icon_row(foot.position + Vector2(8, 3), _light_row(line["row"]))
	# --- Cuerpo (se desplaza)
	var body_top = head.end.y + 2
	var body_bottom = d.H - 17 - foot_h - 2
	var body = Rect2(6, body_top, d.W - 12, body_bottom - body_top)
	d.draw_rect(body, Color("#fbf8ec"))
	d.draw_rect(Rect2(body.position.x, body.position.y, body.size.x, 1), d.C_PAGE_LINE)
	d.draw_rect(Rect2(body.position.x, body.end.y - 1, body.size.x, 1), d.C_PAGE_LINE)
	var lines = d.info_lines.slice(bi + 1, fi if fi >= 0 else d.info_lines.size())
	_info_flow(lines.slice(d.info_offset), body_top + 3, body_bottom, 11.0, d.W - 22.0, null)


# ---------------------------------------------------------------------------
# Vista partida (C en la mesa): tus Activos a la izquierda, los del rival a la derecha
# y el Estadio abajo. En dobles, los dos Activos de cada lado, resumidos.
# ---------------------------------------------------------------------------
const SPLIT_W := 113.0

func _draw_split_info() -> void:
	var stadium_h = d.TEXT_H + 3.0 if d.game.stadium != "" else 0.0
	var bottom = d.H - 18.0 - (stadium_h + 2.0 if stadium_h > 0 else 0.0)
	for side in 2:
		var pl: int = d.human if side == 0 else 1 - d.human
		var x := 6.0 + side * (SPLIT_W + 2.0)
		var mons: Array = d.game.players[pl].actives()
		var label := ("YOUR " if side == 0 else "FOE ") + ("ACTIVES" if mons.size() > 1 else "ACTIVE")
		var lr = Rect2(x, 4, SPLIT_W, d.TEXT_H + 1)
		d.draw_rect(lr, d.C_MINE_BG if side == 0 else d.C_OPP_BG)
		d.draw_rect(Rect2(lr.position.x, lr.end.y, lr.size.x, 1), d.C_PAGE_LINE)
		d._text(Vector2(x + 4, 4), label, d.C_TEXT)
		if mons.is_empty():
			d._text(Vector2(x + 4, 20), "(no Active Pokémon)", d.C_DIM)
		elif mons.size() == 1:
			_split_full(d.game.players[pl], mons[0], x, 17.0, bottom)
		else:
			var hh = (bottom - 17.0 - 2.0) / 2.0
			for k in 2:
				_split_head(d.game.players[pl], mons[k], Rect2(x, 17.0 + k * (hh + 2.0), SPLIT_W, hh), true)
	if stadium_h > 0:
		var sr = Rect2(6, d.H - 18.0 - stadium_h, d.W - 12, stadium_h)
		d.draw_rect(sr, d.C_STADIUM_BG)
		d.draw_rect(Rect2(sr.position.x, sr.position.y, sr.size.x, 1), d.C_PAGE_LINE)
		d._text_fit(Vector2(sr.position.x + 4, sr.position.y + 1), "STADIUM · " + CardDB.card_name(d.game.stadium), d.C_TEXT, sr.size.x - 8)


## Cabecera de un lado: retrato, nombre, PS (barra y número), energías y estado.
## compact: para dobles (sin ataques); el recuadro es todo el espacio de ese Pokémon.
func _split_head(pl: PlayerState, m: PokemonInPlay, r: Rect2, compact: bool) -> void:
	d._cream_box(r)
	var id := m.top()
	var side := 30 if compact else 34
	var ar = Rect2(r.position + Vector2(3, 3), Vector2(side, side))
	d.draw_rect(ar.grow(1), d.C_INK)
	var tex = d.mesa._art_texture(id, side, side)
	if tex != null:
		d.draw_texture(tex, ar.position)
	else:
		d.imagenes._draw_card_image(ar, id)
	var tx = ar.end.x + 4
	var tw = r.end.x - tx - 3
	d._text_fit(Vector2(tx, r.position.y + 1), CardDB.card_name(id), d.C_TEXT, tw)
	d.mesa._draw_hp_bar(Vector2(tx, r.position.y + 13), int(tw), m)
	var hp = "%d/%d" % [m.hp_left(), m.max_hp()]
	d.imagenes._draw_tiny(Vector2(r.end.x - 4 - hp.length() * 4, r.position.y + 22), hp, d.C_TEXT)
	# Energías unidas (íconos chicos) y estado
	var ex = tx
	var ey = r.position.y + 22
	for e in m.energy:
		var u: Array = Energy.units_of_card(e, m)
		var t: String = u[0][0] if not u.is_empty() else "Colorless"
		if not t in d.TYPE_COLORS:
			t = "Colorless"
		if ex + 7 > r.end.x - 4 - hp.length() * 4 - 2:
			break
		d.imagenes._draw_energy_icon(Vector2(ex + 3, ey + 3), 7, t)
		ex += 7
	var cond := m.conditions_text()
	if cond != "":
		var cy = ar.end.y - d.TEXT_H + 1 if not compact else ey + 7
		d._text_fit(Vector2(tx, maxf(cy, ey + 6)), cond, Color("#c03030"), tw)
	if compact:
		# En dobles, debajo del retrato: herramienta/MT si hay
		var extra: Array = []
		if m.tool != "":
			extra.append(CardDB.card_name(m.tool))
		if m.tm != "":
			extra.append(CardDB.card_name(m.tm))
		var ty = maxf(ar.end.y + 2, r.position.y + 22 + 7 + (d.TEXT_H if cond != "" else 0))
		if not extra.is_empty() and ty + d.TEXT_H <= r.end.y:
			d._text_fit(Vector2(r.position.x + 4, ty), " · ".join(extra), d.C_DIM, r.size.x - 8)
			ty += d.TEXT_H
		# Efectos (con su ícono y qué hacen), los que entren
		for rs in d.anim_ataques._effect_reasons(pl, m, -1):
			if ty + d.TEXT_H > r.end.y:
				break
			var no_icon := str(rs[0]).begins_with("est_poder")
			if not no_icon:
				d.anim_ataques._reason_icon(rs[0], Vector2(r.position.x + 9, ty + 4.5))
			var tx0 = r.position.x + (4 if no_icon else 16)
			d._text_fit(Vector2(tx0, ty), d.anim_ataques._short_reason(rs[1], r.end.x - 4 - tx0), d.REASON_COL.get(rs[0], d.C_TEXT), r.end.x - 4 - tx0)
			ty += d.TEXT_H
	# El ícono animado sobre el retrato, como en la mesa
	d.anim_ataques._draw_status_fx(pl, m, ar)


## Un lado con un solo Activo: cabecera, ataques y Poké-Powers/Bodies (sin el texto largo)
## y el pie con debilidad, resistencia y retirada.
func _split_full(pl: PlayerState, m: PokemonInPlay, x: float, top: float, bottom: float) -> void:
	var c := CardDB.get_card(m.top())
	var head := Rect2(x, top, SPLIT_W, 40)
	_split_head(pl, m, head, false)
	var foot_h = d.TEXT_H + 4.0
	var foot = Rect2(x, bottom - foot_h, SPLIT_W, foot_h)
	var body = Rect2(x, head.end.y + 1, SPLIT_W, foot.position.y - head.end.y - 2)
	d.draw_rect(body, Color("#fbf8ec"))
	var y = body.position.y + 2
	var rows: Array = []
	# Primero los efectos que tiene encima (ícono + qué le pasa), después habilidades y ataques
	for rs in d.anim_ataques._effect_reasons(pl, m, -1):
		if rs[0] == "est_poder":          # "se puede usar" ya se ve en la pestaña y en la lista
			continue
		if str(rs[0]).begins_with("est_poder"):
			rows.append([[], rs[1], "", d.REASON_COL.get(rs[0], d.C_TEXT)])      # sin ícono
		else:
			rows.append([["fx", rs[0]], rs[1], "", d.REASON_COL.get(rs[0], d.C_TEXT)])
	for ab in c.get("abilities", []):
		var col: Color = d.C_POWER if ab["kind"] == "Poké-Power" else d.C_BODY
		rows.append([[], ab["name"], "", col])
	for atk in c.get("attacks", []):
		rows.append([atk.get("cost", []), atk["name"], str(atk.get("damage_text", "")), d.C_TEXT])
	if m.tool != "" or m.tm != "":
		var ex: Array = []
		if m.tool != "":
			ex.append(CardDB.card_name(m.tool))
		if m.tm != "":
			ex.append(CardDB.card_name(m.tm))
		rows.append([[], " · ".join(ex), "", d.C_DIM])
	for row in rows:
		if y + d.TEXT_H > body.end.y:
			break
		var rx = body.position.x + 3
		var cost: Array = row[0]
		if not cost.is_empty() and str(cost[0]) == "fx":
			d.anim_ataques._reason_icon(cost[1], Vector2(rx + 5, y + 4.5))
			d._text_fit(Vector2(rx + 12, y), d.anim_ataques._short_reason(row[1], body.end.x - rx - 15), row[3], body.end.x - rx - 15)
			y += d.LINE_S
			continue
		for t in cost:
			d.imagenes._draw_energy_icon(Vector2(rx + 3, y + 4.5), 7, t)
			rx += 7
		if not cost.is_empty():
			rx += 2
		var dmg: String = row[2]
		var dw = d._text_w(dmg) if dmg != "" else 0.0
		if row[3] == d.C_POWER or row[3] == d.C_BODY:
			d._text_bold(Vector2(rx, y), row[1], row[3])
		else:
			d._text_fit(Vector2(rx, y), row[1], row[3], body.end.x - rx - dw - 6)
		if dmg != "":
			d._text(Vector2(body.end.x - 3 - dw, y), dmg, d.C_TEXT)
		y += d.LINE_S
	d._tab(foot.position, foot.size.x, "", foot_h)
	var wr: Array = []
	for t in c.get("weaknesses", []):
		wr.append(["icon", t])
	var fx = foot.position.x + 7
	var fy = foot.position.y + 2
	d._text_bold(Vector2(fx, fy), "W", Color.WHITE)
	fx += 8
	for t in c.get("weaknesses", []):
		d.imagenes._draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, t)
		fx += 9
		if c.get("weakness_plus", {}).has(t):
			var wtxt = "+%d" % int(c["weakness_plus"][t])
			d._text_bold(Vector2(fx, fy), wtxt, Color.WHITE)
			fx += 5 * wtxt.length() + 1
	if c.get("weaknesses", []).is_empty():
		d._text_bold(Vector2(fx, fy), "-", Color.WHITE); fx += 6
	fx += 5
	d._text_bold(Vector2(fx, fy), "R", Color.WHITE)
	fx += 8
	for t in c.get("resistances", []):
		d.imagenes._draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, t)
		fx += 9
	if c.get("resistances", []).is_empty():
		d._text_bold(Vector2(fx, fy), "-", Color.WHITE); fx += 6
	fx += 5
	d._text_bold(Vector2(fx, fy), "Ret", Color.WHITE)
	fx += 18
	var rc = int(c.get("retreat", 0))
	for i in rc:
		d.imagenes._draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, "Colorless")
		fx += 9
	if rc == 0:
		d._text_bold(Vector2(fx, fy), "0", Color.WHITE)


## El renglón de debilidad/resistencia/retirada en letra clara, para el pie verde.
func _light_row(row: Array) -> Array:
	var out: Array = []
	for part in row:
		if part[0] == "text":
			out.append(["bold", part[1], Color.WHITE])
		else:
			out.append(part)
	return out
# ===========================================================================
# Ficha de carta: desplazarse hasta el final del texto y ◀▶ para las vecinas
# ===========================================================================

## Abre la ficha. entries: una Callable por carta vecina (devuelve sus líneas); i: la actual;
## sync: qué hacer al pasar a otra (mover el cursor de la mano, la mesa o el editor).
func _open_info(entries: Array, i: int, sync: Callable = Callable()) -> void:
	d.info_nav = entries
	d.info_nav_i = clampi(i, 0, maxi(0, entries.size() - 1))
	d.info_nav_sync = sync
	d.info_attach = []
	d.info_lines = entries[d.info_nav_i].call() if not entries.is_empty() else []
	d.info_offset = 0
	d.info_more = false


## C en la pantalla principal: la ficha de lo que marca el cursor. En el menú principal,
## los dos Activos (y el Estadio), y con ◀▶ cada Pokémon en juego.
func _open_cursor_info() -> void:
	if d.menu_items.is_empty() or d.menu_level == "root" and d.game.phase == "main":
		# Una página por carta, todas con el mismo formato que en el editor de mazos:
		# tu Activo, el del rival, el Estadio y después las Bancas
		var entries: Array = [func(): return [{"split": true}]]    # primero, los dos lados a la vez
		var firsts: Array = []
		for pl in [d.human, 1 - d.human]:
			if d.game.players[pl].active != null:
				firsts.append([pl, -1])
				var p0: int = pl
				entries.append(func(): return d.paneles._board_info(p0, -1))
		if d.game.stadium != "":
			entries.append(func(): return d.paneles._stadium_info())
		for sl in d.paneles._board_slots():
			if not sl in firsts:
				var pl2: int = sl[0]
				var slot: int = sl[1]
				entries.append(func(): return d.paneles._board_info(pl2, slot))
		_open_info(entries, 0)
		return
	# En una lista (mano, ataques, elegir): las vecinas son las otras opciones de la lista
	var entries: Array = []
	var saved = d.cursor
	var start := 0
	for j in d.menu_items.size():
		d.cursor = j
		if _info_for_cursor().is_empty():
			continue
		if j == saved:
			start = entries.size()
		var jj = j
		entries.append(func():
			var keep = d.cursor
			d.cursor = jj
			var lines := _info_for_cursor()
			d.cursor = keep
			return lines)
	d.cursor = saved
	if entries.is_empty():
		d.info_lines = []
		return
	var idx_map: Array = []
	for j in d.menu_items.size():
		d.cursor = j
		if not _info_for_cursor().is_empty():
			idx_map.append(j)
	d.cursor = saved
	_open_info(entries, start, func(n: int): d.cursor = idx_map[n])


func _info_input(k: int) -> void:
	match k:
		KEY_DOWN:
			if d.info_more:
				# En la ficha de una carta solo se desplaza el panel del medio
				# (en la vista con varias cartas, como los dos Activos y el Estadio, baja hasta el final)
				var card := _info_card_start() >= 0
				var base = _info_find("body") + 1 if card else 0
				var fi = _info_find("foot") if card else -1
				var last = (fi if fi >= 0 else d.info_lines.size()) - base - 1
				d.info_offset = mini(d.info_offset + 1, maxi(0, last))
				while d.info_offset < last and _is_gap(d.info_lines[base + d.info_offset]):
					d.info_offset += 1     # los espacios entre ataques no cuentan como renglón
				d.snd.play("move")
		KEY_UP:
			if d.info_offset > 0:
				var base = _info_find("body") + 1 if _info_card_start() >= 0 else 0
				d.info_offset -= 1
				while d.info_offset > 0 and _is_gap(d.info_lines[base + d.info_offset]):
					d.info_offset -= 1
				d.snd.play("move")
		KEY_LEFT, KEY_RIGHT:
			if d.info_nav.size() > 1:
				d.info_nav_i = (d.info_nav_i + (1 if k == KEY_RIGHT else -1) + d.info_nav.size()) % d.info_nav.size()
				d.info_attach = []
				d.info_lines = d.info_nav[d.info_nav_i].call()
				d.info_offset = 0
				d.info_more = false
				if d.info_nav_sync.is_valid():
					d.info_nav_sync.call(d.info_nav_i)
				d.snd.play("move")


## Teclas con la ficha de una carta abierta (y la galería encima, si está).
func _info_keys(k: int, accept: bool, back: bool, echo: bool) -> void:
	if d.gallery_id != "":
		if d.sq_edit and d.imagenes._sq_edit_keys(k, accept, back):
			return
		if k == KEY_S and not echo and OS.has_feature("editor"):
			d.sq_edit = true
			d.snd.play("ok")
			return
		if (accept or back or k == KEY_C) and not echo:
			_close_gallery()
			d.snd.play("back")
		return
	if k == KEY_C and not echo and _info_img() != "":
		_open_gallery(_info_img())
		d.snd.play("ok")
		return
	# Z en un Pokémon en juego: sus cartas unidas (Energías, Herramienta, MT)
	if accept and not echo and d.info_stack.is_empty() and not _info_attached().is_empty():
		_open_attached()
		d.snd.play("ok")
		return
	if (accept or back) and not echo and not d.info_stack.is_empty():
		var prev: Dictionary = d.info_stack.pop_back()     # vuelve a la ficha del Pokémon
		_open_info(prev["nav"], prev["i"], prev["sync"])
		d.info_offset = prev["offset"]
		d.snd.play("back")
		return
	if (accept or back or k == KEY_C) and not echo:
		d.info_lines = []
		d.info_stack.clear()
		d.snd.play("back")
	else:
		_info_input(k)


## Las cartas unidas al Pokémon de la ficha (cada una una vez, con cuántas hay).
func _info_attached() -> Array:
	if d.info_attach.is_empty() or d.game == null:
		return []
	var mon: PokemonInPlay = d.game.players[d.info_attach[0]].slot(d.info_attach[1])
	if mon == null:
		return []
	var out: Array = []          # [id, cantidad]
	for id in mon.energy + ([mon.tool] if mon.tool != "" else []) + ([mon.tm] if mon.tm != "" else []):
		var found := false
		for o in out:
			if o[0] == id:
				o[1] += 1
				found = true
		if not found:
			out.append([id, 1])
	return out


func _open_attached() -> void:
	var mon: PokemonInPlay = d.game.players[d.info_attach[0]].slot(d.info_attach[1])
	var mine: bool = d.info_attach[0] == d.human
	var cards := _info_attached()
	d.info_stack.append({"nav": d.info_nav, "i": d.info_nav_i, "sync": d.info_nav_sync, "offset": d.info_offset})
	var entries: Array = []
	for c in cards:
		var cid: String = c[0]
		var n: int = c[1]
		var head = "ON %s" % mon.display_name().to_upper() + (" · ×%d" % n if n > 1 else "")
		entries.append(func():
			var lines: Array = [{"section": head, "bg": d.C_MINE_BG if mine else d.C_OPP_BG}]
			lines.append_array(_card_lines(cid, null))
			return lines)
	_open_info(entries, 0)
# ===========================================================================
# Arte completo: banner en la ficha y vista de galería
# ===========================================================================

## El arte entero de la carta, apaisado y con colores de GBA, para arriba de la ficha.
## null si todavía no está (lo pide para la próxima) o si es una Energía.
func _art_banner(id: String) -> Texture2D:
	if CardDB.get_card(id).get("supertype", "") == "Energy":
		return null
	var key = id + "|banner"
	if d._hd_tex.has(key):
		return d._hd_tex[key]
	var src = d.arte.image(id)
	if src == null:
		d.arte.want(id)
		return null
	var img = _cover(src, d.BANNER_W, d.BANNER_H)
	for y in d.BANNER_H:
		for x in d.BANNER_W:
			var c = img.get_pixel(x, y)
			var v = Color.from_hsv(c.h, minf(1.0, c.s * 1.25), minf(1.0, c.v * 1.08))
			img.set_pixel(x, y, Color(v.r, v.g, v.b, 1.0))
	d.mesa._reduce_palette(img, 32)
	# marco fino oscuro, como las ventanas de imagen de la mesa
	for x in d.BANNER_W:
		img.set_pixel(x, 0, Color("#384050"))
		img.set_pixel(x, d.BANNER_H - 1, Color("#384050"))
	for y in d.BANNER_H:
		img.set_pixel(0, y, Color("#384050"))
		img.set_pixel(d.BANNER_W - 1, y, Color("#384050"))
	var tex = ImageTexture.create_from_image(img)
	d._hd_tex[key] = tex
	return tex


## La imagen recortada al centro para cubrir w x h sin deformar.
func _cover(src: Image, w: int, h: int) -> Image:
	var img = src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var sc = maxf(float(w) / img.get_width(), float(h) / img.get_height())
	var cw = mini(img.get_width(), int(ceil(w / sc)))
	var ch = mini(img.get_height(), int(ceil(h / sc)))
	img = img.get_region(Rect2i((img.get_width() - cw) / 2, (img.get_height() - ch) / 2, cw, ch))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return img


## La galería: el arte grande, en píxeles de GBA como el resto del juego.
func _open_gallery(id: String) -> void:
	d.gallery_id = id
	d.arte.want(id)


func _close_gallery() -> void:
	d.gallery_id = ""
	d.sq_edit = false


## Cuántos píxeles de pantalla mide cada píxel del juego (escala entera).
func _screen_scale() -> int:
	var ws = d.get_window().size
	var cs = d.get_window().content_scale_size      # 240x160, o 320x224 con el marco
	if cs.x <= 0 or cs.y <= 0:
		cs = Vector2i(d.W, d.H)
	return maxi(1, int(minf(ws.x / float(cs.x), ws.y / float(cs.y))))


## Dónde va el arte en la galería y a qué tamaño (en píxeles del juego). Se agranda en
## múltiplos enteros de píxeles de pantalla, para que se vea nítido y nunca borroso.
func _gallery_rect(img: Image) -> Rect2:
	# Estilo GBA: el arte se reduce a píxeles de la pantalla del juego (240x160), que
	# después se agrandan como todo lo demás. Una imagen chica no se estira de más.
	var f = minf(1.0, minf(224.0 / img.get_width(), 126.0 / img.get_height()))
	var sz = (Vector2(img.get_width(), img.get_height()) * f).floor()
	return Rect2(Vector2(round((d.W - sz.x) / 2.0), round(4 + (126.0 - sz.y) / 2.0)), sz)


## El arte a la resolución de la pantalla (cada píxel de la imagen, un cuadrado entero de
## píxeles reales).
func _gallery_tex(id: String, img: Image, r: Rect2) -> Texture2D:
	var key = "%s|gal" % id
	if not d._hd_tex.has(key):
		var small = img.duplicate() as Image
		small.resize(int(r.size.x), int(r.size.y), Image.INTERPOLATE_LANCZOS)
		d._hd_tex[key] = ImageTexture.create_from_image(small)
	return d._hd_tex[key]


## "EX Ruby & Sapphire · 3/109"
func _set_line(id: String) -> String:
	var c = CardDB.get_card(id)
	var set_id = id.split("-")[0]
	var s: String = ("EX " if set_id.begins_with("ex") else "") + str(c.get("set", ""))
	var n = str(c.get("number", ""))
	if d.SET_TOTAL.has(set_id):
		n += "/%d" % d.SET_TOTAL[set_id]
	return s + " · " + n


func _draw_gallery() -> void:
	var id = d.gallery_id
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color("#101018"))
	var img = d.arte.image(id)
	if img != null:
		var r = _gallery_rect(img)
		d.draw_rect(r.grow(1), Color("#d8d8e0"), false, 1.0)
		d.draw_texture(_gallery_tex(id, img, r), r.position)
		if d.sq_edit:
			d.imagenes._draw_sq_edit(id, img, r)
			return
	else:
		var box = Rect2(d.W / 2.0 - 32, 30, 64, 64)
		d.imagenes._draw_card_image(box, id)
		var msg = "Loading art..." if d.arte.state(id) == "loading" else "Couldn't download the art."
		d._text(Vector2(round((d.W - d._text_w(msg)) / 2.0), 100), msg, Color("#a0a8b8"))
	var c = CardDB.get_card(id)
	var y := 134.0
	d._text_fit(Vector2(8, y), _set_line(id), Color("#a0a8b8"), d.W - 16)
	var artist = str(c.get("artist", ""))
	if artist != "":
		d._text(Vector2(8, y + 12), "Illus. " + artist, Color("#e8c060"))
	var hint := "X back"
	d._text(Vector2(d.W - 8 - d._text_w(hint), y + 12), hint, Color("#687080"))


## La carta cuya imagen muestra la ficha abierta ("" si no tiene).
func _info_img() -> String:
	for line in d.info_lines:
		if line is Dictionary and line.get("img", "") != "":
			return line["img"]
	return ""


func _is_gap(line: Variant) -> bool:
	return line is Dictionary and line.has("gap")


func _place_name(slot: int) -> String:
	return "Active" if slot == -1 else "Bench %d" % (slot + 1)


## "Energías: Fire ×2, Rainbow · Herramienta: ... · MT: ..."
func _attached_text(p: PokemonInPlay) -> String:
	var counts := {}
	var order: Array = []
	for e in p.energy:
		var n := CardDB.card_name(e).replace(" Energy", "")
		if not counts.has(n):
			order.append(n)
		counts[n] = counts.get(n, 0) + 1
	var parts: Array = []
	for n in order:
		parts.append(n + (" ×%d" % counts[n] if counts[n] > 1 else ""))
	var s := "Energy: " + (", ".join(parts) if not parts.is_empty() else "none")
	if p.tool != "":
		s += " · Tool: " + CardDB.card_name(p.tool)
	if p.tm != "":
		s += " · TM: " + CardDB.card_name(p.tm)
	return s


func _draw_board_details(box: Rect2, x: float, y: float) -> void:
	var mine: bool = d.board_sel[0] == d.human
	var mon: PokemonInPlay = d.game.players[d.board_sel[0]].slot(d.board_sel[1])
	var w = box.size.x - 18 - d.MENU_IMG - 6
	if mon == null:
		d._text(Vector2(x, y), "There's no Pokémon here.", d.C_TEXT)
	else:
		d.imagenes._draw_card_image(Rect2(box.end.x - 4 - d.MENU_IMG, box.position.y + 4, d.MENU_IMG, d.MENU_IMG), mon.top())
		d._text_scroll(Vector2(x, y), "%s  %d/%d HP" % [mon.display_name(), maxi(0, mon.hp_left()), mon.max_hp()], d.C_TEXT, w, "b0" + str(d.board_sel))
		var where = ("Yours · " if mine else "Opponent's · ") + _place_name(d.board_sel[1])
		var st := mon.conditions_text()
		d._text_scroll(Vector2(x, y + d.LINE), where + ("  " + st if st != "" else ""), d.C_TEXT, w, "b1" + str(d.board_sel))
	d._text_scroll(Vector2(x, y + d.LINE * 2), "◀▶ browse · ▲ opponent ▼ yours · Z card · X close", d.C_DIM, w, "bkeys")
