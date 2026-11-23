extends RefCounted
## Animaciones de cartas: unir Energía, tomar Premios, barajar y robar, Entrenadores y Poké-Powers
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


# ===========================================================================
# Animación al unir una Energía
# ===========================================================================
# Se compara qué Energías tenía cada Pokémon antes y después de cada acción, así
# funciona igual con la Energía de la mano, Poké-Powers, Entrenadores o ataques.
# La Energía vuela desde la mano (o desde el Pokémon que la cedió) y al llegar
# hace un destello del color de su tipo.

func _energy_snapshot() -> Dictionary:
	var snap := {}
	for pl in d.game.players:
		for m in pl.all_in_play():
			snap[m] = m.energy.duplicate()
	# Descartes (para saber si una Energía sale de la pila de descarte)
	snap["_discard"] = [d.game.players[0].discard.duplicate(), d.game.players[1].discard.duplicate()]
	return snap


func _discard_spot(player: int) -> Vector2:
	return d._counters_pos(player) + Vector2(31, 17)


func _check_energy(before: Dictionary) -> void:
	if not d.animations_on:
		return
	var discards: Array = before.get("_discard", [[], []])
	# Energías que dejó cada Pokémon (para saber de dónde salen las que se mueven)
	var lost: Array = []
	for m in before:
		if not (m is PokemonInPlay):
			continue
		var now: Array = m.energy.duplicate()
		for e in before[m]:
			if e in now:
				now.erase(e)
			else:
				lost.append([m, e])
	# Cuántas de cada Energía salieron del descarte de cada jugador
	var from_discard := [{}, {}]
	for qi in 2:
		var cur: Array = d.game.players[qi].discard.duplicate()
		for e in discards[qi]:
			if e in cur:
				cur.erase(e)
			elif CardDB.is_energy(e):
				from_discard[qi][e] = from_discard[qi].get(e, 0) + 1
	for pi in d.game.players.size():
		var pl: PlayerState = d.game.players[pi]
		for m in pl.all_in_play():
			var old: Array = before.get(m, []).duplicate()
			for e in m.energy:
				if e in old:
					old.erase(e)
					continue
				var from = Vector2(d.W / 2.0, d.H - 14) if pi == d.human else Vector2(d.W - 30, 4)
				var src_kind := "hand"
				var moved := false
				for l in lost:
					if l[1] == e:
						var src: PokemonInPlay = l[0]
						for qi in d.game.players.size():
							if src in d.game.players[qi].all_in_play():
								from = d.anim_pokemon._slot_rect(qi, d.game.players[qi].slot_of(src)).get_center()
						lost.erase(l)
						moved = true
						src_kind = "mon"
						break
				if not moved and from_discard[pi].get(e, 0) > 0:
					from_discard[pi][e] -= 1
					from = _discard_spot(pi)
					src_kind = "discard"
				d.energy_anim.append({"p": pi, "mon": m, "id": e, "from": from, "src": src_kind, "t": 0.0})


func _pending_units(m: PokemonInPlay) -> int:
	var n := 0
	for ea in d.energy_anim:
		if ea["mon"] == m:
			n += Energy.units_of_card(ea["id"], m).size()
	return n


func _update_energy(delta: float) -> void:
	var ea: Dictionary = d.energy_anim[0]
	ea["t"] += delta / d.ENERGY_TIME
	if ea["t"] >= 1.0:
		d.energy_anim.pop_front()
		if d.energy_anim.is_empty():
			d.ai_timer = d.AI_DELAY
			d._rebuild_menu()


func _energy_color(id: String, t: float) -> Color:
	var name := CardDB.card_name(id)
	if "Rainbow" in name or "Multi" in name:
		return Color.from_hsv(fmod(t * 2.0, 1.0), 0.7, 1.0)
	return d.paneles._card_chip_color(id)


func _draw_energy_anim() -> void:
	if d.energy_anim.is_empty() or not d.anim.is_empty():
		return
	var ea: Dictionary = d.energy_anim[0]
	var pl: PlayerState = d.game.players[ea["p"]]
	var mon: PokemonInPlay = ea["mon"]
	var slot := -1 if pl.active == mon else pl.slot_of(mon)
	if not pl.all_in_play().has(mon):
		return
	var r = d.anim_pokemon._slot_rect(ea["p"], slot)
	var to = r.get_center()
	var t: float = ea["t"]
	var c := _energy_color(ea["id"], t)
	var units := Energy.units_of_card(ea["id"])
	var etype: String = "*" if units.is_empty() or units[0].size() != 1 else str(units[0][0])
	const FLY := 0.55
	if ea.get("src", "") == "discard":
		# Pilita de descarte de donde sale la Energía
		var fa := clampf(1.0 - (t - FLY) / 0.3, 0.0, 1.0) if t > FLY else 1.0
		var o: Vector2 = ea["from"]
		for i in 3:
			var pr = Rect2(o - Vector2(6, 8) + Vector2(i, -i), Vector2(12, 16))
			d.draw_rect(pr, Color(d.C_PANEL_DARK.darkened(0.15 * (2 - i)), fa))
			d.draw_rect(pr, Color(d.C_TEXT, fa), false)
	if t < FLY:
		# Vuelo en arco con estela
		var k := t / FLY
		k = k * k * (3.0 - 2.0 * k)
		for j in range(5, -1, -1):
			var kk = maxf(0.0, k - j * 0.05)
			var p: Vector2 = ea["from"].lerp(to, kk) + Vector2(0, -sin(kk * PI) * 26.0)
			var rad := 5.0 - j * 0.7
			if j == 0:                 # el ícono del tipo (tus círculos de Energía)
				d.imagenes._draw_energy_icon(p.round(), 12, etype)
			else:
				d.draw_circle(p, rad, Color(c, 0.5 - j * 0.07))
	else:
		# Llegada: brillo en el Pokémon, anillo y chispas
		var k := (t - FLY) / (1.0 - FLY)
		var a = 1.0 - k
		d.draw_rect(r, Color(c, 0.6 * a))
		d.draw_rect(r.grow(1), Color(c.lightened(0.4), a), false, 2.0)
		d.draw_arc(to, 5.0 + k * 20.0, 0, TAU, 24, Color(d.C_TEXT, a), 3.0)
		d.draw_arc(to, 5.0 + k * 20.0, 0, TAU, 24, Color(c.lightened(0.3), a), 1.5)
		# Tus destellos salen del lugar donde entró la Energía
		for i in 6:
			var ang = TAU * i / 6.0 + 0.3
			var p = to + Vector2(cos(ang), sin(ang)) * (6.0 + k * 18.0)
			if d.SpecialFX.has_fx("estrellas"):
				d.SpecialFX.fx_draw(d, "estrellas", 1, p, 0.3 + 0.25 * sin(k * PI), a, k * 2.0, false, c.lightened(0.5))
			else:
				var sz = 2.5 if i % 2 == 0 else 1.5
				d.draw_line(p - Vector2(sz, 0), p + Vector2(sz, 0), Color(1, 1, 1, a), 1.0)
				d.draw_line(p - Vector2(0, sz), p + Vector2(0, sz), Color(1, 1, 1, a), 1.0)
		# El ícono queda un instante en el centro, crece y se apaga
		if k < 0.6:
			var ik = k / 0.6
			var tex = d.imagenes._energy_texture(etype, 16)
			var dd_ = 12.0 + ik * 6.0
			if tex != null:
				d.draw_texture_rect(tex, Rect2(to - Vector2(dd_, dd_) / 2.0, Vector2(dd_, dd_)), false, Color(1, 1, 1, 1.0 - ik))
			else:
				d.draw_circle(to, dd_ / 2.0, Color(c, 1.0 - ik))
# ===========================================================================
# Animación al tomar un Premio
# ===========================================================================
# Una estrella grande aparece girando en el centro, con rayos y chispas, y delante
# la carta del Premio se da vuelta. Los Premios del rival se ven boca abajo.

## Por las dudas: si el motor espera que elijas un Premio y no hay selector, se abre uno.
func _ensure_prize_picker() -> void:
	if d.mode != "duel" or d.game.pending_choice_kind() != "prize" or d.game.actor() != d.human:
		return
	if d.prize_anim.any(func(e): return e.get("choose", false)):
		return
	var li: int = d.game.pending_choice().get("log", -1)
	if li < 0 or li >= d.game.prize_log.size():
		return
	var dd_: Dictionary = d.game.prize_log[li].duplicate()
	dd_["t"] = 0.0
	dd_["log"] = li
	dd_["choose"] = true
	dd_["quick"] = true
	d.prize_anim.push_front(dd_)


func _prize_showing() -> bool:
	return not d.prize_anim.is_empty() and d.anim.is_empty() and d.energy_anim.is_empty() \
			and d.coin_anim.is_empty() and d.evo_anim.is_empty() and d.ko_anim.is_empty() and d.check_anim.is_empty() and d.move_anim.is_empty()


func _update_prize(delta: float) -> void:
	if d.prize_anim[0].get("choose", false):
		if d.paneles._prize_pile_size(d.prize_anim[0]["p"]) <= 1:
			d.paneles._pick_prize(0)        # queda uno solo: no hay nada que elegir
		return
	d.prize_anim[0]["t"] += delta / d.PRIZE_TIME
	if d.prize_anim[0]["t"] >= 1.0:
		d.prize_anim.pop_front()
		d.marquee_t0.erase("prize")
		if d.prize_anim.is_empty():
			d.ai_timer = d.AI_DELAY
			d._rebuild_menu()


func _draw_star(c: Vector2, r: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang = rot + TAU * i / 10.0 - PI / 2.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.45))
	d.draw_colored_polygon(pts, col)


func _draw_prize() -> void:
	if not _prize_showing():
		return
	var pz: Dictionary = d.prize_anim[0]
	if pz.get("choose", false):
		d.paneles._draw_prize_choice(pz)
		return
	var t: float = pz["t"]
	var mine: bool = pz["p"] == d.human
	var fade_in := clampf(t / 0.12, 0.0, 1.0)
	var fade_out := clampf((1.0 - t) / 0.12, 0.0, 1.0)
	var a := minf(fade_in, fade_out)
	var center = Vector2(d.W / 2.0, 56)
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.45 * a))
	# Estrella: aparece con rebote y gira despacio
	var k := clampf(t / 0.22, 0.0, 1.0)
	var pop = 1.0 + 2.7 * pow(k - 1.0, 3) + 1.7 * pow(k - 1.0, 2)   # ease-out-back
	var rot := t * 1.6
	var sr = 48.0 * pop * fade_out
	# Rayos detrás
	for i in 12:
		var ang = rot * 0.5 + TAU * i / 12.0
		var len = sr * (1.15 + 0.15 * sin(t * 30.0 + i))
		d.draw_line(center + Vector2(cos(ang), sin(ang)) * sr * 0.5, center + Vector2(cos(ang), sin(ang)) * len,
				Color(1, 0.95, 0.6, 0.55 * a), 2.0)
	_draw_star(center + Vector2(1, 2), sr, rot, Color(0, 0, 0, 0.35 * a))
	_draw_star(center, sr, rot, Color(d.C_TEXT, a))
	_draw_star(center, sr - 3, rot, Color(d.C_ACCENT, a))
	_draw_star(center + Vector2(-2, -3), (sr - 3) * 0.55, rot, Color(1, 0.97, 0.7, a))
	# Chispas que giran alrededor
	for i in 6:
		var ang = -rot * 1.3 + TAU * i / 6.0
		var p = center + Vector2(cos(ang), sin(ang)) * (sr + 8.0)
		var s = 2.0 + sin(t * 25.0 + i * 2.0)
		d.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 1, a))
		d.draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 1, a))
	# Carta delante: entra desde abajo y se da vuelta
	var ck := clampf((t - 0.08) / 0.2, 0.0, 1.0)
	ck = ck * ck * (3.0 - 2.0 * ck)
	var bob := sin(t * 9.0) * 1.5
	var cc = center + Vector2(0, (1.0 - ck) * 70.0 + bob)
	if pz.has("from"):
		cc = (pz["from"] as Vector2).lerp(center, ck) + Vector2(0, bob)
	var flip := clampf((t - 0.22) / 0.16, 0.0, 1.0) if mine else 0.0
	var sx := absf(cos(flip * PI))
	var face := mine and flip >= 0.5
	var cw = 40.0 * sx
	var card = Rect2(cc - Vector2(cw / 2.0, 27), Vector2(cw, 54))
	if cw < 1.0:
		return
	d.draw_rect(Rect2(card.position + Vector2(2, 2), card.size), Color(0, 0, 0, 0.4 * a))
	if face:
		d.draw_rect(card, Color(d.C_PANEL, a))
		d.draw_rect(card, Color(d.C_TEXT, a), false)
		var img = Rect2(card.position + Vector2(2 * sx, 3), Vector2(36 * sx, 36))
		d.imagenes._draw_card_image(img, pz["id"])
		d.draw_rect(Rect2(card.position + Vector2(3 * sx, 42), Vector2(34 * sx, 2)), Color(d.paneles._card_chip_color(pz["id"]), a))
	else:
		_draw_card_back(card, a)


## Punto del borde de r en dirección a "toward" (para que las flechas no tapen las cartas).
func _edge_point(r: Rect2, toward: Vector2) -> Vector2:
	var c = r.get_center()
	var p = c
	for i in 40:
		var q = c.lerp(toward, i / 40.0)
		if not r.grow(1).has_point(q):
			return q
		p = q
	return p




## Avanza la animación de una ventana; devuelve cuánto le falta entrar (0 = del todo adentro).
func _slide_step(key: String, open: bool, delta: float) -> void:
	var sl: Dictionary = d._slides.get(key, {"t": 1.0, "open": false})
	if open and not sl["open"]:
		sl = {"t": 0.0, "open": true}
	elif not open:
		sl = {"t": 1.0, "open": false}
	else:
		sl["t"] = minf(1.0, sl["t"] + minf(delta, 1.0 / 30.0) / d.SLIDE_TIME)    # un cuadro lento no la saltea
	d._slides[key] = sl


func _slide_off(key: String) -> float:
	var sl: Dictionary = d._slides.get(key, {"t": 1.0})
	var k: float = sl["t"]
	return 1.0 - (1.0 - pow(1.0 - k, 3))     # 1 -> 0, frenando al final


## Dibuja una ventana corrida hacia abajo (dy píxeles).
func _draw_slid(dy: float, f: Callable) -> void:
	if dy <= 0.5:
		f.call()
		return
	d._base_off = Vector2(0, roundf(dy))
	d.draw_set_transform(d._base_off)
	f.call()
	d._base_off = Vector2.ZERO
	d.draw_set_transform(Vector2.ZERO)
var _back_levels: Array = []        # el dorso de mundo/propios/dorso_carta.png, en varios tamaños
var _back_loaded := false


## Carga el dorso (si está) y prepara copias cada vez más chicas, achicadas con buena
## calidad, para dibujarlo chiquito sin que se vea pixelado.
func _load_back() -> void:
	_back_loaded = true
	for dir_path in ["res://mundo/propios", "user://mundo/propios"]:
		var p = "%s/dorso_carta.png" % dir_path
		if not ImgLoad.exists(p):
			continue
		var img = ImgLoad.load(p)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGBA8)
		while true:
			_back_levels.append(ImageTexture.create_from_image(img))
			if img.get_width() <= 8:
				break
			img = img.duplicate()
			img.resize(maxi(1, img.get_width() / 2), maxi(1, img.get_height() / 2), Image.INTERPOLATE_LANCZOS)
		return


## Dorso de carta: la imagen de mundo/propios/dorso_carta.png (tools/armar_dorso.py) o, si no
## está, uno genérico azul con borde claro y una estrellita.
func _draw_card_back(card: Rect2, a: float = 1.0) -> void:
	if not _back_loaded:
		_load_back()
	if not _back_levels.is_empty():
		var tex: Texture2D = _back_levels[0]
		for lv in _back_levels:          # la copia más chica que no quede menor que la carta
			if (lv as Texture2D).get_width() >= absf(card.size.x):
				tex = lv
		d.draw_texture_rect(tex, card, false, Color(1, 1, 1, a))
		return
	d.draw_rect(card, Color("#2850a0", a))
	if card.size.x > 6:
		d.draw_rect(card.grow(-2), Color("#4070c8", a), false)
	d.draw_rect(card, Color(d.C_TEXT, a), false)
	var r = minf(card.size.x, card.size.y) * 0.3
	if r >= 2.0:
		_draw_star(card.get_center(), r, 0.0, Color(d.C_ACCENT, a))
# ===========================================================================
# Barajar y robar
# ===========================================================================
# El motor anota en game.deck_log cada barajada y cada robo. Se muestra un mazo
# chiquito al costado del Activo: al barajar, las dos mitades se separan y se
# intercalan; al robar, las cartas vuelan del mazo a la mano (las tuyas se dan
# vuelta en el camino; las del rival llegan boca abajo).

const DECK_CARD := Vector2(14, 19)


func _deck_spot(player: int) -> Vector2:
	return d._counters_pos(player) + Vector2(31, 3)


func _hand_spot(player: int) -> Vector2:
	return Vector2(96, 116) if player == d.human else Vector2(150, -8)


func _draw_duration(n: int) -> float:
	return (n - 1) * _draw_stagger(n) + d.DRAW_FLY + 0.15


func _draw_stagger(n: int) -> float:
	return minf(0.14, 0.7 / maxf(1.0, n))


func _deck_showing() -> bool:
	return not d.deck_anim.is_empty() and d.anim.is_empty() and d.bench_fx.is_empty() and d.check_anim.is_empty() and d.energy_anim.is_empty() \
			and d.coin_anim.is_empty() and d.evo_anim.is_empty() and d.prize_anim.is_empty() and d.move_anim.is_empty()


func _update_deck(delta: float) -> void:
	d.deck_anim[0]["t"] += delta
	if d.deck_anim[0]["t"] >= d.deck_anim[0]["dur"]:
		d.deck_anim.pop_front()
		d.marquee_t0.erase("deck")
		if d.deck_anim.is_empty():
			d.ai_timer = d.AI_DELAY
			d._rebuild_menu()


func _draw_deck_text(x: float, y: float, w: float) -> void:
	var dd_: Dictionary = d.deck_anim[0]
	var mine: bool = dd_["p"] == d.human
	if dd_["k"] == "shuffle":
		d._text(Vector2(x, y), "Shuffling your deck..." if mine else "The opponent shuffles their deck...", d.C_TEXT)
		return
	var n: int = dd_["ids"].size()
	var what = "1 card" if n == 1 else "%d cards" % n
	var names: Array = []
	for id in dd_["ids"]:
		names.append(CardDB.card_name(id))
	if dd_["k"] == "recover":
		d._text(Vector2(x, y), ("You get back " if mine else "The opponent gets back ") + what, d.C_TEXT)
		d._text(Vector2(x, y + d.LINE), "from the discard pile:", d.C_TEXT)
		d._text_scroll(Vector2(x, y + d.LINE * 2), ", ".join(names), d.C_DIM, w, "deck")
		return
	d._text(Vector2(x, y), ("You draw " if mine else "The opponent draws ") + what + ".", d.C_TEXT)
	if mine:
		d._text_scroll(Vector2(x, y + d.LINE), ", ".join(names), d.C_DIM, w, "deck")


func _draw_deck_anim() -> void:
	if not _deck_showing():
		return
	var dd_: Dictionary = d.deck_anim[0]
	var t: float = dd_["t"]
	var dur: float = dd_["dur"]
	var recover: bool = dd_["k"] == "recover"
	var spot = _discard_spot(dd_["p"]) if recover else _deck_spot(dd_["p"])
	var fade := clampf(minf(t, dur - t) / 0.1, 0.0, 1.0)
	if dd_["k"] == "shuffle":
		_draw_shuffle(spot, t / dur, fade)
		return
	if recover:
		# Pila de descarte (boca arriba) de donde salen las cartas
		for i in 3:
			var pr = Rect2(spot - DECK_CARD / 2 + Vector2(i, -i), DECK_CARD)
			d.draw_rect(pr, Color(d.C_INK, fade))
			d.draw_rect(pr.grow(-1), Color(Color("#a8a8b0").darkened(0.12 * (2 - i)), fade))
	else:
		# Mazo de donde salen las cartas
		for i in 3:
			_draw_card_back(Rect2(spot - DECK_CARD / 2 + Vector2(i, -i), DECK_CARD), fade)
	var ids: Array = dd_["ids"]
	if dd_.get("closeup", false):
		_draw_closeup(dd_, spot)
		return
	var stagger := _draw_stagger(ids.size())
	var to = _hand_spot(dd_["p"])
	for i in ids.size():
		var k = (t - i * stagger) / d.DRAW_FLY
		if k <= 0.0 or k >= 1.0:
			continue
		var e = k * k * (3.0 - 2.0 * k)
		var from = spot + Vector2(2, -2)
		var p = from.lerp(to + Vector2((i - ids.size() / 2.0) * 6.0, 0), e) + Vector2(0, -sin(e * PI) * 14.0)
		# Se da vuelta a mitad de camino (solo las tuyas)
		var sx = absf(cos(e * PI)) if dd_["p"] == d.human and not recover else 1.0
		var face: bool = recover or (dd_["p"] == d.human and e > 0.5)
		var size = DECK_CARD * (1.0 + 0.4 * sin(e * PI))
		var r = Rect2(p - Vector2(size.x * sx, size.y) / 2, Vector2(size.x * sx, size.y))
		if r.size.x < 1.0:
			continue
		d.draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.35))
		if face:
			d.draw_rect(r, d.C_PANEL)
			d.imagenes._draw_card_image(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, r.size.x - 2)), ids[i])
			d.draw_rect(Rect2(r.position + Vector2(1, r.size.y - 4), Vector2(r.size.x - 2, 2)), d.paneles._card_chip_color(ids[i]))
			d.draw_rect(r, d.C_TEXT, false)
		else:
			_draw_card_back(r)


## Primer plano de la carta robada: sale del mazo dándose vuelta, se agranda en el centro
## (la mesa se oscurece un poco), se queda un momento y baja achicándose hasta la mano.
func _draw_closeup(dd_: Dictionary, spot: Vector2) -> void:
	var per = d.CU_IN + d.CU_HOLD + d.CU_OUT
	var t: float = dd_["t"]
	var i = mini(int(t / per), dd_["ids"].size() - 1)
	var u = t - i * per
	var id: String = dd_["ids"][i]
	var center = Vector2(d.W / 2.0, d.BOX_Y / 2.0 + 2.0)
	var big := 1.45
	var pos = center
	var sc := big
	var sx := 1.0
	var dim := 1.0
	if u < d.CU_IN:
		var e = u / d.CU_IN
		e = e * e * (3.0 - 2.0 * e)
		pos = spot.lerp(center, e) + Vector2(0, -sin(e * PI) * 10.0)
		sc = lerpf(0.3, big, e)
		sx = absf(cos(e * PI))            # se da vuelta en el camino
		dim = e
	elif u > d.CU_IN + d.CU_HOLD:
		var e = clampf((u - d.CU_IN - d.CU_HOLD) / d.CU_OUT, 0.0, 1.0)
		e = e * e
		pos = center.lerp(_hand_spot(d.human), e)
		sc = lerpf(big, 0.3, e)
		dim = 1.0 - e
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.35 * dim))
	var size = Vector2(48, 64) * sc
	var r = Rect2(pos - Vector2(size.x * sx, size.y) / 2.0, Vector2(size.x * sx, size.y))
	if r.size.x < 1.0:
		return
	var face = u >= d.CU_IN * 0.5
	if not face:
		_draw_card_back(r)
		return
	d.draw_rect(Rect2(r.position + Vector2(2, 3) * sc, r.size), Color(0, 0, 0, 0.35))
	d.imagenes._round_box(r, d.C_PANEL, d.C_TEXT)
	if sx < 0.95:
		return
	d.imagenes._draw_card_image(Rect2(r.position + Vector2(3, 3) * sc, Vector2(42, 42) * sc), id)
	d.draw_rect(Rect2(r.position.x + 3 * sc, r.position.y + 47 * sc, 42 * sc, 2), d.paneles._card_chip_color(id))
	if sc > 0.8:
		d._text_fit(Vector2(r.position.x + 3 * sc, r.position.y + 50 * sc), CardDB.card_name(id), d.C_TEXT, 42 * sc)
	# Brillo que cruza la carta cuando llega
	var g = (u - d.CU_IN) / 0.3
	if g > 0.0 and g < 1.0:
		var gx = r.position.x + r.size.x * g
		d.draw_rect(Rect2(gx - 3, r.position.y + 2, 4, r.size.y - 4), Color(1, 1, 1, 0.35 * (1.0 - g)))


## Barajada estilo riffle: dos mitades que se abren y se intercalan, dos veces.
func _draw_shuffle(spot: Vector2, u: float, fade: float) -> void:
	const N := 6
	var cycle = fmod(u * 2.0, 1.0) if u < 0.999 else 0.999
	var done = u >= 0.92
	for i in N:
		var left = i % 2 == 0
		var pos = spot
		if not done:
			if cycle < 0.35:
				# Se abren las dos mitades
				var k = cycle / 0.35
				pos += Vector2((-13.0 if left else 13.0) * k, -3.0 * sin(k * PI))
			else:
				# Las cartas caen alternadas hacia el centro
				var order = float(N - 1 - i) / N
				var k = clampf((cycle - 0.35) / 0.65 * 1.6 - order * 0.6, 0.0, 1.0)
				pos += Vector2((-13.0 if left else 13.0) * (1.0 - k), -4.0 * sin(k * PI))
		pos += Vector2(0, -i * 0.8)
		var tilt = 0.0 if done else (0.25 if left else -0.25) * sin(clampf(cycle / 0.35, 0.0, 1.0) * PI * 0.5) * (1.0 if cycle < 0.6 else 0.0)
		d.draw_set_transform(d._base_off + pos, tilt)
		_draw_card_back(Rect2(-DECK_CARD / 2, DECK_CARD), fade)
		d.draw_set_transform(d._base_off)
	if done:
		# Golpecito final: chispas
		var k = (u - 0.92) / 0.08
		for j in 4:
			var ang := TAU * j / 4.0 + 0.78
			var p = spot + Vector2(cos(ang), sin(ang)) * (12.0 + k * 6.0)
			d.draw_line(p - Vector2(2, 0), p + Vector2(2, 0), Color(1, 1, 1, 1.0 - k))
			d.draw_line(p - Vector2(0, 2), p + Vector2(0, 2), Color(1, 1, 1, 1.0 - k))
# ===========================================================================
# Entrenadores en la mesa
# ===========================================================================
# Al jugar un Entrenador, la carta sale de la mano, se agranda en el centro de la mesa
# y después va a su lugar: al descarte, al Pokémon (Herramientas y MT) o al lugar del
# Estadio. Los Supporters quedan chiquitos junto al Activo hasta que termina el turno.

# ===========================================================================
# Poké-Power: el Pokémon sale de su carta con su sprite de Mystery Dungeon, mira a la
# pantalla y hace algo según el Poder (salta, carga energía, dispara...).
# ===========================================================================

const POWER_TIME := 1.5          # la versión completa
const POWER_SHORT := 0.75        # el mismo Poder otra vez en el turno
const POWER_IN := 0.28           # lo que tarda en salir de la carta (y en volver)

## Qué hace el Poder, por su texto: energía, curación, daño, búsqueda u otro.
static func power_class(text: String) -> String:
	var t := text.to_lower()
	if t.contains("energy") and (t.contains("attach") or t.contains("move")):
		return "energy"
	if t.contains("remove") and t.contains("damage counter") or t.contains("heal"):
		return "heal"
	if (t.contains("put") or t.contains("place")) and t.contains("damage counter") or t.contains(" damage to"):
		return "damage"
	if t.contains("draw") or t.contains("search") or t.contains("look at"):
		return "search"
	return "other"


const POWER_ANIMS := {"energy": "Charge", "heal": "Charge", "damage": "Shoot", "search": "Hop", "other": "Hop"}

## Arranca la animación; devuelve false si no hay sprite para ese Pokémon (se aplica directo).
func _start_power_anim(action: Dictionary, then: Callable) -> bool:
	if action.get("n", "") == Abilities.DISCARD_FOSSIL:
		return false
	var pi = d.game.actor()
	var mon: PokemonInPlay = null
	var slot: int = action["s"]
	var ctx = action.get("ctx", null)
	if ctx != null and slot == -1 and d.game.players[pi].active2 != null and ctx[pi]:
		slot = PlayerState.ACTIVE2
	mon = d.game.players[pi].slot(slot)
	if mon == null:
		return false
	var id := mon.top()
	var sp := MiniBattle.folder(id)
	if sp == "" or not MiniBattle.available(id):
		return false
	var text := ""
	for ab in CardDB.get_card(id).get("abilities", []):
		if ab.get("name", "") == action["n"]:
			text = ab.get("text", "")
	var cls := power_class(text)
	var key = "%d|%d|%s" % [pi, d.game.turn_number, action["n"]]
	var short: bool = d._last_power.get("key", "") == key
	d._last_power = {"key": key}
	var src: Rect2
	if slot == -1:
		src = d.mesa._dbl_card_rect(pi, 0) if d._dbl() else d._card_rect(pi)
	elif slot == PlayerState.ACTIVE2:
		src = d.mesa._dbl_card_rect(pi, 1)
	else:
		src = d._bench_rect(pi, slot)
	_set_power_anim(pi, mon, sp, cls, action["n"], src, short, then)
	return true


## Arma la animación de "sale de la carta y da dos saltos" (Poké-Powers y ataques que no
## hacen daño). tag: el cartel de abajo ("POKé-POWER" rojo o "ATTACK" azul).
func _set_power_anim(pi: int, mon: PokemonInPlay, sp: String, cls: String, name: String, src: Rect2,
		short: bool, then: Callable, tag: String = "POKé-POWER", tag_col: Color = Color("#d83828")) -> void:
	var id := mon.top()
	var an := "Hop" if MiniBattle.has_anim(sp, "Hop") else "Idle"
	var dur := POWER_SHORT if short else POWER_TIME
	var types := CardDB.types(id)
	d.power_anim = {"p": pi, "id": id, "sp": sp, "anim": an, "cls": cls, "name": name, "mon": mon.display_name(),
			"src": src, "t": 0.0, "dur": dur, "short": short, "then": then, "tag": tag, "tagcol": tag_col,
			"col": d.TYPE_COLORS.get(types[0] if not types.is_empty() else "Colorless", Color.WHITE)}


func _update_power(delta: float) -> void:
	d.power_anim["t"] += delta
	if d.power_anim["t"] >= d.power_anim["dur"]:
		var then = d.power_anim.get("then")
		d.power_anim = {}
		if then is Callable:
			then.call()


func _draw_power_anim() -> void:
	if d.power_anim.is_empty():
		return
	var t: float = d.power_anim["t"]
	var dur: float = d.power_anim["dur"]
	var t_in = POWER_IN * (0.6 if d.power_anim["short"] else 1.0)
	var kin = clampf(t / t_in, 0.0, 1.0)
	var kout = clampf((t - (dur - t_in)) / t_in, 0.0, 1.0)
	var env = minf(kin, 1.0 - kout)          # 0 → 1 → 0
	var col: Color = d.power_anim["col"]
	var sp: String = d.power_anim["sp"]
	# La mesa se oscurece y detrás aparece un círculo de luz del color del tipo
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.42 * env))
	var stage = Vector2(d.W / 2.0, d.BOX_Y - 24.0)        # donde pisa el Pokémon
	var glow_c = stage + Vector2(0, -26)
	for i in 4:
		var r = (16.0 + i * 9.0 + sin(t * 6.0 + i) * 2.0) * env
		d.draw_circle(glow_c, r, Color(col, 0.16 * env))
	d.draw_circle(glow_c, 13.0 * env, Color(col.lightened(0.5), 0.22 * env))
	# Sale de la carta: sube en arco, se agranda; al final vuelve igual
	var src_g: Vector2 = d.power_anim["src"].get_center() + Vector2(0, 8)
	var k = kin if kout <= 0.0 else 1.0 - kout
	var e = 1.0 - (1.0 - k) * (1.0 - k)
	var g = src_g.lerp(stage, e) + Vector2(0, -sin(e * PI) * 22.0)
	var sc = 1.0 + e
	# Qué anima: mientras sale y vuelve, Idle; en el medio, la acción del Poder
	var act_t = t - t_in
	var name = "Idle" if kin < 1.0 or kout > 0.0 else str(d.power_anim["anim"])
	if name == "Hop":
		var hop := MiniBattle._anim(sp, "Hop")
		if not hop.is_empty() and act_t / MiniBattle.TICK >= float(hop["total"]) * 2.0:
			name = "Idle"                  # después de los dos saltos, quieto
	var an = MiniBattle._anim(sp, name)
	var loop = name != "Shoot"
	var frame := 0
	if not an.is_empty():
		frame = MiniBattle._frame_at(an, maxf(0.0, act_t if name != "Idle" else t) / MiniBattle.TICK, loop)
		if name == "Shoot" and frame >= int(an["n"]) - 1:
			name = "Idle"
			an = MiniBattle._anim(sp, "Idle")
			frame = MiniBattle._frame_at(an, act_t / MiniBattle.TICK, true) if not an.is_empty() else 0
	d.draw_set_transform(d._base_off + g.round(), 0, Vector2(sc, sc))
	var pts = MiniBattle._put(d, sp, name, 0, frame, Vector2.ZERO, clampf(env * 3.0, 0.0, 1.0))
	d.draw_set_transform(d._base_off)
	var center: Vector2 = g + pts["c"] * sc
	# Efectos de la acción
	if kin >= 1.0 and kout <= 0.0:
		_draw_power_fx(d.power_anim["cls"], act_t, center, col)
	# Cartel abajo de la mesa: "POKé-POWER" en rojo y al lado el nombre del Poder
	var la = clampf(env * 2.5, 0.0, 1.0)
	var tag: String = d.power_anim.get("tag", "POKé-POWER")
	var nm: String = d.power_anim["name"]
	var tw = d._text_w(tag) + 10
	var nw = d._text_w(nm) + 14
	var rise := (1.0 - clampf(t / 0.2, 0.0, 1.0)) * 14.0
	var x0 = roundf((d.W - tw - nw) / 2.0)
	var y0 = d.BOX_Y - 13.0 + rise
	d.draw_rect(Rect2(x0 - 1, y0 - 1, tw + nw + 2, 13), Color(d.C_INK, la))
	d.draw_rect(Rect2(x0, y0, tw, 11), Color(d.power_anim.get("tagcol", Color("#d83828")), la))
	d._text(Vector2(x0 + 5, y0 + 1), tag, Color(1, 1, 1, la))
	d.draw_rect(Rect2(x0 + tw, y0, nw, 11), Color(0.1, 0.1, 0.16, 0.9 * la))
	d._text(Vector2(x0 + tw + 7, y0 + 1), nm, Color("#f8e070", la))


## Lo que pasa alrededor del Pokémon mientras usa el Poder.
func _draw_power_fx(cls: String, t: float, c: Vector2, col: Color) -> void:
	match cls:
		"energy":
			# Chispas del color del tipo que suben en espiral
			for i in 10:
				var ph = fmod(t * 1.4 + i * 0.1, 1.0)
				var ang = TAU * i / 10.0 + t * 3.0
				var p = c + Vector2(cos(ang) * (22.0 - ph * 10.0), 18.0 - ph * 46.0)
				d.draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(col.lightened(0.4), 1.0 - ph))
		"heal":
			# Crucecitas verdes que suben
			for i in 7:
				var ph = fmod(t * 1.1 + i * 0.143, 1.0)
				var p = c + Vector2(-20 + i * 7, 14.0 - ph * 40.0)
				var a = 1.0 - ph
				d.draw_rect(Rect2(p.round() + Vector2(-1, -3), Vector2(3, 7)), Color("#58d868", a))
				d.draw_rect(Rect2(p.round() + Vector2(-3, -1), Vector2(7, 3)), Color("#58d868", a))
		"damage":
			# Un destello que sale hacia el rival
			var k := clampf((t - 0.25) / 0.35, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				d.anim_ataques._draw_burst(c + Vector2(0, -6), 6.0 + k * 14.0, Color(col.lightened(0.3), 1.0 - k), 8)
		_:
			# Estrellitas alrededor
			for i in 6:
				var ang = TAU * i / 6.0 + t * 2.0
				var p = c + Vector2(cos(ang), sin(ang) * 0.6) * (26.0 + sin(t * 8.0 + i) * 3.0)
				var on = int(t * 10.0 + i) % 3 != 0
				if on:
					d.draw_rect(Rect2(p.round() + Vector2(-1, 0), Vector2(3, 1)), Color(1, 1, 0.8))
					d.draw_rect(Rect2(p.round() + Vector2(0, -1), Vector2(1, 3)), Color(1, 1, 0.8))


func _start_trainer_anim(action: Dictionary) -> void:
	var p = d.game.actor()
	var pl: PlayerState = d.game.players[p]
	var id: String = pl.hand[action["h"]]
	var dest = _discard_spot(p)
	var prm: Dictionary = action.get("p", {})
	if CardDB.is_pokemon_tool(id) or CardDB.is_tm(id):
		if prm.has("tg"):
			dest = d.anim_pokemon._slot_rect(p, prm["tg"]).get_center()
	elif CardDB.is_stadium(id):
		dest = Vector2(96, 43)
	d.trainer_anim = {"id": id, "p": p, "dest": dest, "t": 0.0}


func _update_trainer(delta: float) -> void:
	d.trainer_anim["t"] += delta / d.TRAINER_TIME
	if d.trainer_anim["t"] >= 1.0:
		if CardDB.is_supporter(d.trainer_anim["id"]):
			d.supporter_table[d.trainer_anim["p"]] = {"id": d.trainer_anim["id"], "turn": d.game.turn_number}
		var then = d.trainer_anim.get("then")
		d.trainer_anim = {}
		d.ai_timer = d.AI_DELAY
		if then is Callable:
			then.call()
		d._rebuild_menu()


func _draw_trainer_card(center: Vector2, sc: float, id: String, a: float) -> void:
	var size = Vector2(48, 64) * sc
	var r = Rect2(center - size / 2.0, size)
	if size.x < 3:
		return
	d.draw_rect(Rect2(r.position + Vector2(2, 3) * sc, r.size), Color(0, 0, 0, 0.35 * a))
	d.imagenes._round_box(r, Color(d.C_PANEL, a), Color(d.C_TEXT, a))
	var img = Rect2(r.position + Vector2(3, 3) * sc, Vector2(42, 42) * sc)
	d.imagenes._draw_card_image(img, id)
	if sc > 0.8:
		var kind_col = d.C_POWER if CardDB.is_supporter(id) else (d.C_BODY if CardDB.is_stadium(id) else d.C_KEYS)
		d.draw_rect(Rect2(r.position.x + 3 * sc, r.position.y + 47 * sc, 42 * sc, 2), Color(kind_col, a))
		d._text_fit(Vector2(r.position.x + 3 * sc, r.position.y + 50 * sc), CardDB.card_name(id), Color(d.C_TEXT, a), 42 * sc)


func _draw_trainer_anim() -> void:
	if d.trainer_anim.is_empty():
		return
	var t: float = d.trainer_anim["t"]
	var mine: bool = d.trainer_anim["p"] == d.human
	var center = Vector2(d.W / 2.0, 54)
	var start = Vector2(d.W / 2.0, d.H + 20) if mine else Vector2(d.W / 2.0, -30)
	var pos = center
	var sc := 1.0
	if t < 0.2:
		var k := t / 0.2
		k = k * k * (3.0 - 2.0 * k)
		pos = start.lerp(center, k)
		sc = lerpf(0.4, 1.0, k)
	elif t > 0.72:
		var k := (t - 0.72) / 0.28
		k = k * k
		pos = center.lerp(d.trainer_anim["dest"], k)
		sc = lerpf(1.0, 0.2, k)
	else:
		pos = center + Vector2(0, sin((t - 0.2) * 12.0) * 1.0)
		# Brillo detrás de la carta
		var glow := 1.0 - absf((t - 0.46) / 0.26)
		d.draw_circle(center, 44.0, Color(1, 1, 0.8, 0.10 + 0.10 * glow))
		d.draw_circle(center, 36.0, Color(1, 1, 0.8, 0.10 + 0.10 * glow))
	if t < 0.72:
		d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.3 * minf(1.0, t / 0.2)))
	_draw_trainer_card(pos, sc, d.trainer_anim["id"], 1.0)


func _draw_supporters_on_table() -> void:
	for p in 2:
		var st: Dictionary = d.supporter_table[p]
		if st.is_empty() or st["turn"] != d.game.turn_number:
			continue
		var pos = Vector2(132, 58) if p == d.human else Vector2(64, 33)
		var r = Rect2(pos, Vector2(16, 20))
		d.draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
		d.draw_rect(r, d.C_INK)
		d.draw_rect(r.grow(-1), Color("#f8f8e8"))
		d.imagenes._draw_card_image(Rect2(pos + Vector2(2, 2), Vector2(12, 12)), st["id"])
		d.draw_rect(Rect2(pos.x + 2, pos.y + 15, 12, 2), d.C_POWER)
