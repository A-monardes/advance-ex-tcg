extends RefCounted
## Animaciones de los Pokémon: evolución, barra de vida, Fuera de Combate, brillo de los ex, espera, cartel de turno y daño a la Banca
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


# ===========================================================================
# Animación de evolución
# ===========================================================================
# El Pokémon parpadea en blanco cada vez más rápido, con rayos de luz girando;
# un destello final y chispas. Después de cada acción se miran las evoluciones
# nuevas en game.evolve_log (cartas en mano, Rare Candy, Poké-Powers, etc.).

func _check_evolutions() -> void:
	if d.game.evolve_log.size() <= d.evo_seen:
		return
	var list = d.game.evolve_log.slice(d.evo_seen)
	d.evo_seen = d.game.evolve_log.size()
	if d.animations_on:
		d.evo_anim = {"list": list, "i": 0, "t": 0.0}


func _update_evo(delta: float) -> void:
	d.evo_anim["t"] += delta / d.EVO_TIME
	if d.evo_anim["t"] >= 1.0:
		d.evo_anim["t"] = 0.0
		d.evo_anim["i"] += 1
		if d.evo_anim["i"] >= d.evo_anim["list"].size():
			d.evo_anim = {}
			if d.anim.is_empty():
				d.ai_timer = d.AI_DELAY
				d._rebuild_menu()


## Rectángulo en pantalla de un Pokémon en juego (Activo: su carta grande; Banca: la cartita).
func _slot_rect(player: int, slot: int) -> Rect2:
	if d._dbl() and PlayerState.is_active_slot(slot):
		return d.mesa._dbl_card_rect(player, 1 if slot == PlayerState.ACTIVE2 else 0)
	if slot == -1:
		return d._card_rect(player)
	return d._bench_rect(player, slot)


func _draw_evo() -> void:
	if d.evo_anim.is_empty():
		return
	var e: Dictionary = d.evo_anim["list"][d.evo_anim["i"]]
	var pl: PlayerState = d.game.players[e["p"]]
	var mon: PokemonInPlay = e["mon"]
	var s := pl.slot_of(mon)
	if s == -2 or (s == -1 and pl.active != mon):
		return
	var t: float = d.evo_anim["t"]
	var r = _slot_rect(e["p"], s)
	if s == -1:
		r = d._art_rect(e["p"])
	var c = r.get_center()
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.25 * sin(minf(t, 1.0) * PI)))
	if t < d.EVO_FLASH:
		var k = t / d.EVO_FLASH
		# Parpadeo cada vez más rápido entre la forma anterior y una silueta blanca
		var box = _slot_rect(e["p"], s)
		if sin(k * k * 70.0) > 0.0:
			d.draw_rect(r.grow(1), Color(1, 1, 1, 0.95))
			if s != -1:
				d.draw_rect(box, Color(1, 1, 1, 0.95))
		# Rayos de luz girando
		for i in 8:
			var ang = TAU * i / 8.0 + k * 4.0
			var len = 10.0 + k * 22.0
			d.draw_line(c + Vector2(cos(ang), sin(ang)) * 6.0, c + Vector2(cos(ang), sin(ang)) * len, Color(1, 1, 0.8, 0.4 + 0.6 * k), 1.0)
	else:
		var k = (t - d.EVO_FLASH) / (1.0 - d.EVO_FLASH)
		# Destello y anillo que se expande
		if k < 0.25:
			d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(1, 1, 1, 0.7 * (1.0 - k / 0.25)))
		d.draw_arc(c, 6.0 + k * 30.0, 0, TAU, 24, Color(1, 1, 0.8, 1.0 - k), 2.0)
		# Chispas
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(e["to"])
		for i in 10:
			var ang := rng.randf() * TAU
			var p = c + Vector2(cos(ang), sin(ang)) * (8.0 + k * rng.randf_range(10, 24))
			d.anim_ataques._draw_burst(p, 2.5 * (1.0 - k) + 0.5, Color("#fff4a0"), 4)
# ===========================================================================
# Barra de vida animada
# ===========================================================================

func _shown_hp(m: PokemonInPlay) -> float:
	return d.hp_shown.get(m, float(clampi(m.hp_left(), 0, m.max_hp())))


## La ficha tiembla un momento cuando empiezan a bajar los PS (como en las batallas de GBA).
const HP_SHAKE_TIME := 0.3
var hp_drop_t := {}           # Pokémon -> cuándo empezaron a bajar sus PS (segundos)

func _hp_shake(m: PokemonInPlay) -> Vector2:
	if not hp_drop_t.has(m) or not d.animations_on:
		return Vector2.ZERO
	var k: float = (Clock.ms() / 1000.0 - float(hp_drop_t[m])) / HP_SHAKE_TIME
	if k >= 1.0:
		return Vector2.ZERO
	var amp = roundf(2.0 * (1.0 - k))
	return Vector2(amp if int(k * 12.0) % 2 == 0 else -amp, 0)


func _update_hp(delta: float) -> void:
	_collect_checkup()
	var alive := {}
	for pl in d.game.players:
		for m in pl.all_in_play():
			alive[m] = true
			var target := float(clampi(m.hp_left(), 0, m.max_hp()))
			if d.hp_hold.has(m):
				target = maxf(target, minf(float(d.hp_hold[m]), float(m.max_hp())))
			var cur: float = d.hp_shown.get(m, target)
			if cur > target and not hp_drop_t.has(m):
				hp_drop_t[m] = Clock.ms() / 1000.0
			elif cur <= target:
				hp_drop_t.erase(m)
			if cur != target:
				var step := maxf(45.0, absf(target - cur) * 2.5) * delta   # rápido al principio, frena al final
				cur = target if absf(target - cur) <= step else cur + signf(target - cur) * step
			d.hp_shown[m] = cur
	if d.hp_shown.size() > alive.size():
		for m in d.hp_shown.keys():
			if not alive.has(m):
				d.hp_shown.erase(m)
	for m in d.hp_hold.keys():
		if not alive.has(m):
			d.hp_hold.erase(m)


## Daño de veneno y quemadura del chequeo entre turnos: se ve aparte, después del ataque
## (la barra de PS se queda donde la dejó el golpe hasta que le toca).
func _collect_checkup() -> void:
	if d.game.checkup_log.size() <= d.checkup_seen:
		return
	var batch: Array = d.game.checkup_log.slice(d.checkup_seen)
	d.checkup_seen = d.game.checkup_log.size()
	if not d.animations_on:
		return
	for e in batch:
		var m: PokemonInPlay = e["mon"]
		if not d.hp_hold.has(m):
			var total := 0
			for e2 in batch:
				if e2["mon"] == m:
					total += int(e2["dmg"])
			d.hp_hold[m] = clampi(m.hp_left(), 0, m.max_hp()) + total
		var dd_: Dictionary = e.duplicate()
		dd_["t"] = 0.0
		d.check_anim.append(dd_)


const CHECK_TIME := 1.1


func _update_check(delta: float) -> void:
	var c: Dictionary = d.check_anim[0]
	if float(c["t"]) == 0.0:
		var m: PokemonInPlay = c["mon"]
		if d.hp_hold.has(m):
			d.hp_hold[m] = int(d.hp_hold[m]) - int(c["dmg"])
			if int(d.hp_hold[m]) <= m.hp_left():
				d.hp_hold.erase(m)
		d.snd.play("hit_Psychic" if c["kind"] == "poison" else "hit_Fire")
	c["t"] = float(c["t"]) + delta / CHECK_TIME
	if float(c["t"]) >= 1.0:
		d.check_anim.pop_front()
		if d.check_anim.is_empty():
			d.ai_timer = d.AI_DELAY
			d._rebuild_menu()


## El Activo titila del color del estado y sube el número ("-10" violeta o naranja).
func _draw_check() -> void:
	if d.check_anim.is_empty() or not d.anim.is_empty() or not d.coin_anim.is_empty() or not d.evo_anim.is_empty():
		return
	var c: Dictionary = d.check_anim[0]
	var m: PokemonInPlay = c["mon"]
	var pl: PlayerState = d.game.players[c["p"]]
	var r := Rect2()
	if d._dbl():
		r = d.mesa._dbl_card_rect(pl.index, 1 if pl.active2 == m else 0)
	else:
		r = d._card_rect(pl.index)
	var t: float = c["t"]
	var col := Color("#b058e0") if c["kind"] == "poison" else Color("#f87830")
	if t < 0.45 and int(t * 18.0) % 2 == 0:
		d.draw_rect(r, Color(col, 0.45))
	var txt = "-%d" % int(c["dmg"])
	var sc := 1.5 + (sin(clampf(t * 5.0, 0.0, 1.0) * PI) * 0.5 if t < 0.2 else 0.0)
	var w: float = d._text_w(txt) * sc
	var p = r.get_center() + Vector2(-w / 2.0, -4.0 - minf(t, 0.6) * 14.0)
	var tc := Color("#fcd0ff") if c["kind"] == "poison" else Color("#ffe8a8")
	tc.a = clampf((1.0 - t) * 4.0, 0.0, 1.0)
	d.draw_rect(Rect2(p.round() + Vector2(-3, 0), Vector2(w + 6, 12.0 * sc)), Color(col.darkened(0.6), 0.8 * tc.a))
	d.draw_set_transform(d._base_off + p.round(), 0, Vector2(sc, sc))
	d._text(Vector2.ZERO, txt, tc)
	d.draw_set_transform(d._base_off)
# ===========================================================================
# Fuera de combate
# ===========================================================================
# El Pokémon parpadea en blanco, se hunde y se desvanece en polvo.

func _update_ko(delta: float) -> void:
	d.ko_anim[0]["t"] += delta / d.KO_TIME
	if d.ko_anim[0]["t"] >= 1.0:
		d.ko_anim.pop_front()
		if d.ko_anim.is_empty():
			d.ai_timer = d.AI_DELAY
			d._rebuild_menu()


func _draw_ko() -> void:
	if d.ko_anim.is_empty() or not d.check_anim.is_empty() or not d.anim.is_empty() or not d.coin_anim.is_empty() or not d.evo_anim.is_empty():
		return
	var k: Dictionary = d.ko_anim[0]
	var t: float = k["t"]
	var active: bool = PlayerState.is_active_slot(k["slot"])
	var mine: bool = k["p"] == d.human
	var panel: Rect2
	var portrait := Rect2()
	if active and d._dbl():
		var di = 1 if k["slot"] == PlayerState.ACTIVE2 else 0
		panel = d.mesa._dbl_info_rect(k["p"], di)
		portrait = d.mesa._dbl_card_rect(k["p"], di)
	elif active:
		panel = d._info_rect(k["p"])
		portrait = d._card_rect(k["p"])
	else:
		panel = d._bench_rect(k["p"], k["slot"])
	var tc: Color = d.TYPE_COLORS.get(CardDB.types(k["id"])[0] if not CardDB.types(k["id"]).is_empty() else "Colorless", d.C_PANEL_DARK)
	if t < 0.35:
		# Parpadeo
		var on := int(t * 20) % 2 == 0
		for r: Rect2 in [panel, portrait]:
			if r.size.x > 0:
				d.draw_rect(r, d.C_PANEL if not on else Color.WHITE)
				d.draw_rect(r, d.C_TEXT, false)
		if active:
			d._text_fit(panel.position + Vector2(7, 1), k["name"], d.C_TEXT, panel.size.x - 10)
		_draw_ko_title(t, CardDB.is_ex(k["id"]))
		return
	# Se hunde y se desvanece
	var u := (t - 0.35) / 0.65
	var a := 1.0 - u
	for r: Rect2 in [panel, portrait]:
		if r.size.x <= 0:
			continue
		var h: float = r.size.y * (1.0 - u)
		var rr = Rect2(r.position + Vector2(0, r.size.y - h), Vector2(r.size.x, h))
		d.draw_rect(rr, Color(d.C_PANEL if r == panel else tc.darkened(0.3), a))
		d.draw_rect(rr, Color(d.C_TEXT, a), false)
	# Polvo que sube
	for i in 10:
		var px := panel.position.x + fmod(i * 37.0, panel.size.x)
		var py := panel.end.y - u * (8.0 + (i % 4) * 5.0)
		d.draw_rect(Rect2(px, py, 1.5, 1.5), Color(1, 1, 1, a))
	if portrait.size.x > 0:
		for i in 6:
			var px := portrait.position.x + fmod(i * 11.0, portrait.size.x)
			d.draw_rect(Rect2(px, portrait.end.y - u * (10.0 + (i % 3) * 6.0), 1.5, 1.5), Color(1, 1, 1, a))
	if CardDB.is_ex(k["id"]):
		_draw_ex_ko_banner(u, panel.get_center() if portrait.size.x <= 0 else portrait.get_center())
	_draw_ko_title(t, CardDB.is_ex(k["id"]))


## "KNOCKED OUT!" con las letras del título: entra de golpe (grande y se achica) en el
## medio de la mesa; si era un ex, abajo aparece "2 PRIZES!".
func _draw_ko_title(t: float, ex: bool) -> void:
	var t0 := 0.2
	if t < t0:
		return
	var k := (t - t0) / (1.0 - t0)
	var fade = clampf((1.0 - k) / 0.12, 0.0, 1.0)
	var cy = d.BOX_Y / 2.0 - (6.0 if ex else 0.0)
	var band_h := 44.0 if ex else 28.0
	d.draw_rect(Rect2(0, cy - 14, d.W, band_h), Color(0.08, 0.02, 0.02, 0.55 * fade))
	d.draw_rect(Rect2(0, cy - 14, d.W, 1), Color("#f85838", 0.9 * fade))
	d.draw_rect(Rect2(0, cy - 14 + band_h - 1, d.W, 1), Color("#f85838", 0.9 * fade))
	_draw_pop_art("ko", Vector2(d.W / 2.0, cy), k / 0.1, fade)
	if ex:
		_draw_pop_art("ko_premios", Vector2(d.W / 2.0, cy + 18), (k - 0.25) / 0.1, fade)


## Dibuja un cartel de ui/ centrado en c: con p de 0 a 1 entra de golpe (de grande a su
## tamaño); p < 0 todavía no se ve.
func _draw_pop_art(id: String, c: Vector2, p: float, alpha: float = 1.0) -> void:
	if p < 0.0:
		return
	var tex := _banner_art(id)
	if tex == null:
		return
	var q = clampf(p, 0.0, 1.0)
	var sc = 1.0 + 1.2 * (1.0 - q) * (1.0 - q)
	var sz := Vector2(tex.get_width(), tex.get_height())
	d.draw_set_transform(d._base_off + Vector2(roundf(c.x), roundf(c.y)), 0, Vector2(sc, sc))
	d.draw_texture(tex, (-sz / 2.0).round(), Color(1, 1, 1, alpha * clampf(q * 3.0, 0.0, 1.0)))
	d.draw_set_transform(d._base_off)


## Cae un Pokémon ex: tus destellos dorados salen del lugar y un cartel "2 PRIZES!" en el
## medio de la mesa (entra grande y se acomoda, como el de la debilidad).
func _draw_ex_ko_banner(u: float, from: Vector2) -> void:
	for i in 6:
		var ang := TAU * i / 6.0 + u * 1.5
		var sp = from + Vector2(cos(ang), sin(ang)) * (6.0 + u * 30.0)
		if d.SpecialFX.has_fx("estrellas"):
			d.SpecialFX.fx_draw(d, "estrellas", 1, sp, 0.45 + 0.2 * sin(u * PI), 1.0 - u, 0.0, false, Color("#f8d860"))
		else:
			d.anim_ataques._draw_burst(sp, 3.0, Color("#f8d860", 1.0 - u), 4)
	# El texto "2 PRIZES!" va en _draw_ko_title, con las letras del título
# ===========================================================================
# Pokémon ex: brillo al llegar a la mesa
# ===========================================================================
# Cuando un Pokémon ex aparece en la mesa (lo bajás, evoluciona a ex o sube a la Banca),
# una franja de luz cruza la carta, el borde destella en dorado y saltan tus destellos.

## Nada se está animando en la mesa (para el brillo de los ex y el balanceo del Activo).
func _board_idle() -> bool:
	return d.anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty() and d.ko_anim.is_empty() and d.check_anim.is_empty() \
			and d.move_anim.is_empty() and d.energy_anim.is_empty() and d.prize_anim.is_empty() and d.trainer_anim.is_empty() \
			and d.power_anim.is_empty() and d.banner.is_empty() and d.rival_intro.is_empty() and d.deck_anim.is_empty() and d.vs_anim.is_empty() and d.intro == ""


func _update_ex_shine(delta: float) -> void:
	if d.game.phase in ["setup", "first"]:
		return                      # en la preparación las cartas todavía están boca abajo
	var live := {}
	for pl: PlayerState in d.game.players:
		for m: PokemonInPlay in pl.all_in_play():
			live[m] = true
			var top := m.top()
			if CardDB.is_ex(top) and str(d.ex_seen.get(m, "")) != top:
				if d.animations_on and d.anim_ataques._is_moving(m):
					continue                # todavía está llegando: brilla cuando se acomode
				d.ex_seen[m] = top
				if d.animations_on:
					d.ex_shine[m] = {"t": 0.0, "snd": false}
	for m in d.ex_seen.keys():
		if not live.has(m):
			d.ex_seen.erase(m)
			d.ex_shine.erase(m)
	if d.ex_shine.is_empty() or not _board_idle():
		return
	var first = d.ex_shine.keys()[0]          # de a uno
	var e: Dictionary = d.ex_shine[first]
	if not e["snd"]:
		e["snd"] = true
		d.snd.play("shine")
	e["t"] += delta / d.EX_SHINE_TIME
	if e["t"] >= 1.0:
		d.ex_shine.erase(first)


## Dónde está dibujado un Pokémon en la mesa (la carta grande del Activo o la de la Banca).
func _mon_rect(m: PokemonInPlay) -> Rect2:
	for pl: PlayerState in d.game.players:
		if d._dbl() and pl.is_active(m):
			return d.mesa._dbl_card_rect(pl.index, 0 if pl.active == m else 1)
		if pl.active == m:
			return d.mesa._portrait_rect(d._card_rect(pl.index).position + _idle_bob(pl))
		var i := pl.bench.find(m)
		if i >= 0:
			return d._bench_rect(pl.index, i)
	return Rect2()


func _draw_ex_shine() -> void:
	if d.ex_shine.is_empty() or not _board_idle():
		return
	var m = d.ex_shine.keys()[0]
	var r := _mon_rect(m)
	if r.size.x <= 0:
		return
	var t: float = d.ex_shine[m]["t"]
	var gold := Color("#f8d030")
	# El borde destella en dorado
	var ga := sin(clampf(t / 0.5, 0.0, 1.0) * PI)
	d.draw_rect(r.grow(1), Color(gold, ga), false, 1.0)
	d.draw_rect(r.grow(2), Color(gold, ga * 0.4), false, 1.0)
	# La franja de luz cruza en diagonal (recortada a la carta)
	if t < 0.6:
		var k := t / 0.6
		var slant = r.size.y * 0.45
		var x = r.position.x - 8.0 + (r.size.x + slant + 16.0) * k
		var card = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		for band: Array in [[0.0, 6.0, 0.7], [-9.0, 2.0, 0.45]]:
			var bx: float = x + float(band[0])
			var bw: float = band[1]
			var poly = PackedVector2Array([Vector2(bx - slant, r.end.y), Vector2(bx - slant + bw, r.end.y),
					Vector2(bx + bw, r.position.y), Vector2(bx, r.position.y)])
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly, card):
				d.draw_colored_polygon(piece, Color(1, 1, 1, float(band[2])))
	# Destellos en las esquinas, uno detrás del otro
	var corners = [r.position + Vector2(r.size.x - 2, 3), r.position + Vector2(3, r.size.y * 0.55), r.end - Vector2(4, 3)]
	for i in corners.size():
		var st := 0.3 + i * 0.15
		if t < st or t > st + 0.45:
			continue
		var q := (t - st) / 0.45
		var sc = sin(q * PI)
		if d.SpecialFX.has_fx("estrellas"):
			d.SpecialFX.fx_draw(d, "estrellas", 1, corners[i], 0.35 + 0.4 * sc, sc, q * 1.2)
		else:
			d.anim_ataques._draw_burst(corners[i], 1.5 + 3.0 * sc, Color(1, 1, 1, sc), 4)
# ===========================================================================
# El Activo espera
# ===========================================================================
# Si es tu turno y tardás en jugar (IDLE_AFTER segundos sin tocar nada, con la mesa
# quieta), tu Activo empieza a subir y bajar un píxel, como los Pokémon de las batallas de
# GBA mientras esperan una orden. Apenas tocás una tecla, se queda quieto. Dormido o
# Paralizado no se mueve.

const BOB_PERIOD := 1.0
const IDLE_AFTER := 4.0


## Es tu turno y el juego está esperando que elijas algo.
func _waiting_human() -> bool:
	return d.game != null and d.game.phase in ["main", "choice"] and d.game.actor() == d.human and _board_idle() \
			and not d.paused and d.rival_intro.is_empty()


func _idle_bob(pl: PlayerState) -> Vector2:
	if d.game == null or pl.index != d.human or pl.active == null or not d.animations_on or not _waiting_human():
		return Vector2.ZERO
	var now := Clock.ms() / 1000.0
	var waited = now - d.idle_since - IDLE_AFTER
	if waited < 0.0:
		return Vector2.ZERO
	var conds = d.mesa._condition_list(pl.active)
	if conds.has("asleep") or conds.has("paralyzed"):
		return Vector2.ZERO
	return Vector2(0, -1) if fmod(waited, BOB_PERIOD) < BOB_PERIOD * 0.5 else Vector2.ZERO
# ===========================================================================
# Cartel de cambio de turno
# ===========================================================================

func _banner_showing() -> bool:
	return not d.banner.is_empty() and d.anim.is_empty() and d.coin_anim.is_empty() and d.evo_anim.is_empty() \
			and d.ko_anim.is_empty() and d.check_anim.is_empty() and d.energy_anim.is_empty() and d.prize_anim.is_empty() and d.move_anim.is_empty()


## Presentación del rival: franja roja con su nombre desde la derecha, azul con el tuyo desde
## la izquierda y un VS en el medio; al final se van para los costados.
func _draw_rival_intro() -> void:
	if d.rival_intro.is_empty():
		return
	var t: float = d.rival_intro["t"]
	var into := clampf(t / 0.35, 0.0, 1.0)
	var out = clampf((t - (d.RIVAL_INTRO_TIME - 0.3)) / 0.3, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - into, 3)
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0, 0, 0, 0.55 * (1.0 - out)))
	var bh := 30.0
	var shift = (1.0 - ease_in) * d.W + out * d.W
	# Rival (arriba, desde la derecha)
	var top = Rect2(shift, 30, d.W, bh)
	d.draw_rect(top, Color("#b83828"))
	d.draw_rect(Rect2(top.position, Vector2(d.W, 2)), Color("#f08070"))
	d.draw_rect(Rect2(top.position + Vector2(0, bh - 2), Vector2(d.W, 2)), Color("#701810"))
	d._text_big(Vector2(top.position.x + d.W - 16 - d._text_w(d.rival_intro["rival"]) * 2, top.position.y + 3), d.rival_intro["rival"], Color.WHITE)
	if d.rival_intro["deck"] != "":
		var dk: String = d.rival_intro["deck"]
		d._text(Vector2(top.position.x + 46, top.position.y + 10), dk, Color("#f8d0c8"))
	_draw_trainer_sprite(str(d.rival_intro.get("sprite", "")), Vector2(top.position.x + 10, top.end.y - 2))
	# Vos (abajo, desde la izquierda)
	var bot = Rect2(-shift, 82, d.W, bh)
	d.draw_rect(bot, Color("#2858b0"))
	d.draw_rect(Rect2(bot.position, Vector2(d.W, 2)), Color("#80a8f0"))
	d.draw_rect(Rect2(bot.position + Vector2(0, bh - 2), Vector2(d.W, 2)), Color("#102860"))
	d._text_big(Vector2(bot.position.x + 16, bot.position.y + 3), d.rival_intro["me"], Color.WHITE)
	_draw_trainer_sprite("jugador", Vector2(bot.end.x - 42, bot.end.y - 2))
	# VS en el medio, con un golpecito de escala al aparecer
	if t > 0.3 and out < 1.0:
		var k := clampf((t - 0.3) / 0.15, 0.0, 1.0)
		var sc = 3.0 + (1.0 - k) * 2.0
		var vs_w = d._text_w("VS") * sc
		d.draw_set_transform(d._base_off + Vector2(d.W / 2.0 - vs_w / 2.0, 66 - 5 * sc), 0, Vector2(sc, sc))
		d._text(Vector2.ZERO, "VS", Color("#f8d030", 1.0 - out))
		d.draw_set_transform(d._base_off)


## El personaje del mapa (mundo/propios), al doble, mirando de frente; pies en `feet`.
func _draw_trainer_sprite(id: String, feet: Vector2) -> void:
	if id == "" or d.campaign == null:
		return
	var tex: Texture2D = d.campaign.world._sprite(id)
	if tex == null or tex.get_height() < 128:
		return
	var region := Rect2(0, 0, 16, 32)
	d.draw_texture_rect_region(tex, Rect2(feet + Vector2(0, -60), Vector2(32, 64)), region)


func _draw_banner() -> void:
	if not _banner_showing():
		return
	var t: float = d.banner["t"]
	var mine: bool = d.banner["p"] == d.human
	# Entra desde la izquierda, se queda y sale por la derecha
	var x := 0.0
	if t < 0.18:
		var k := t / 0.18
		x = -d.W * (1.0 - k * k * (3.0 - 2.0 * k))
	elif t > 0.82:
		var k := (t - 0.82) / 0.18
		x = d.W * k * k
	var band = Rect2(x, 39, d.W, 34)
	var col := Color("#3868c8") if mine else Color("#c04838")     # tu lado azul, el rival rojo
	var sudden: bool = d.banner.get("sudden", false)
	if sudden:
		col = Color("#6a3c9c")
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.25 * (1.0 - absf(x) / d.W)))
	d.draw_rect(band, col)
	d.draw_rect(Rect2(band.position + Vector2(0, 2), Vector2(d.W, 1)), Color(1, 1, 1, 0.5))
	d.draw_rect(Rect2(band.position + Vector2(0, band.size.y - 3), Vector2(d.W, 1)), Color(0, 0, 0, 0.3))
	var txt := "YOUR TURN!" if mine else "OPPONENT'S TURN"
	var art := "turno_tuyo" if mine else "turno_rival"
	if sudden:
		txt = "SUDDEN DEATH!"
		art = "muerte_subita"
		mine = false
	# El texto grande con las letras del título (ui/turno_*.png, de tools/logo_juego.py)
	var tex := _banner_art(art)
	if tex != null:
		d.draw_texture(tex, Vector2(round(x + (d.W - tex.get_width()) / 2.0), 42))
	else:
		var tw = d._text_w(txt) * 2
		d._text_big(Vector2(x + (d.W - tw) / 2.0, 41), txt, d.C_TEXT if mine else d.C_LIGHT)
	var sub = "Turn %d" % d.banner["turn"] if not sudden else "It's a tie: a new game with 1 Prize card each"
	var sp = Vector2(x + (d.W - d._text_w(sub)) / 2.0, 61)
	d._text(sp + Vector2(1, 1), sub, Color(0, 0, 0, 0.35))
	d._text(sp, sub, d.C_LIGHT)


var _banner_tex := {}

func _banner_art(id: String) -> Texture2D:
	if not _banner_tex.has(id):
		var img := ImgLoad.load("res://ui/%s.png" % id)
		_banner_tex[id] = ImageTexture.create_from_image(img) if img != null else null
	return _banner_tex[id]
# ===========================================================================
# Daño a la Banca
# ===========================================================================
# Cuando un ataque (o un Poder) le hace daño a Pokémon de la Banca, después del golpe al
# Activo cada carta dañada recibe un estallido (piedras si el ataque es de tipo Lucha),
# sale el "-10" y le bajan los PS. No se repite el ataque: solo se ve el daño.

const BENCH_FX_TIME := 0.85


func _bench_shot_info(action: Dictionary) -> Dictionary:
	var att = d.game.current_player()
	var atk: Dictionary = att.active.attacks()[action["a"]]
	return {"att": att.index, "atk": atk, "type": d.anim_ataques._attack_type(att.active, atk),
			"label": "%s used %s!" % [att.active.display_name(), atk["name"]]}


## El disparo a la Banca (mini pelea): el atacante se gira hacia la carta y le dispara; el
## estallido y el "-10" de cada carta salen cuando llega el disparo.
func _start_bench_shot(slot: int) -> void:
	var att: PlayerState = d.game.players[int(d._bench_shot["att"])]
	var def = d.game.other(att)
	if att.active == null or def.active == null or not MiniBattle.can_use(att.active.top(), def.active.top()):
		return
	var atk: Dictionary = d._bench_shot["atk"]
	var to = d._bench_rect(def.index, slot).get_center()
	d.anim = {"t": 0.0, "action": {}, "applied": true, "dmg": 0, "type": d._bench_shot["type"],
		"att_card": att.active.top(), "atk_name": str(atk.get("name", "")), "atk_text": str(atk.get("text", "")),
		"atk_dmg_text": "", "att_mon_s": att.active, "att_dmg_s": att.active.damage,
		"from": d._art_rect(att.index).get_center(), "to": to, "att": att.index, "def": def.index,
		"hp_before": 0, "def_mon": def.active, "label": d._bench_shot["label"], "coins_shown": 0, "seed": randi(),
		"dur": d.ANIM_TIME, "impact": d.ANIM_IMPACT, "poison": false, "weak": false}
	MiniBattle.setup(d.anim, att, def, atk, d.human)
	MiniBattle.setup_bench(d.anim, att.index == d.human, to)
	for e in d.bench_fx:
		e["wait_shot"] = true          # esperan a que llegue el disparo
const BENCH_FX_STAGGER := 0.12


## Daño de cada Pokémon de Banca (de los dos jugadores), para ver qué cambió.
func _bench_damage() -> Array:
	var out := []
	for pl in d.game.players:
		var dd_ := {}
		for m in pl.bench:
			dd_[m] = m.damage
		out.append(dd_)
	return out


func _check_bench_hits(before: Dictionary) -> void:
	if not d.animations_on or not before.has("bench") or d.mode != "duel":
		d._bench_shot = {}
		return
	var typ := "Colorless"
	if not d.anim.is_empty():
		typ = str(d.anim.get("type", "Colorless"))
	elif not d._bench_shot.is_empty():
		typ = str(d._bench_shot["type"])
	var n = d.bench_fx.size()
	var first_hit := -1
	for pi in d.game.players.size():
		var old: Dictionary = before["bench"][pi]
		for m in d.game.players[pi].bench:
			if not old.has(m) or m.damage <= int(old[m]):
				continue
			var dmg: int = m.damage - int(old[m])
			d.hp_hold[m] = clampi(m.max_hp() - int(old[m]), 0, m.max_hp())     # los PS bajan con el estallido
			d.bench_fx.append({"p": pi, "mon": m, "dmg": dmg, "t": -BENCH_FX_STAGGER * n / BENCH_FX_TIME,
					"col": d.TYPE_COLORS.get(typ, Color.WHITE), "rock": typ == "Fighting", "hit": false, "snd": "hit_" + typ})
			n += 1
			if first_hit < 0 and not d._bench_shot.is_empty() and pi != int(d._bench_shot["att"]):
				first_hit = d.game.players[pi].bench.find(m)
	# Ataque que solo le pegó a la Banca: ahora sí, el disparo hacia la carta
	if not d._bench_shot.is_empty() and d.game.pending_choice_kind() == "":
		if first_hit >= 0:
			_start_bench_shot(first_hit)
		d._bench_shot = {}


func _update_bench_fx(delta: float) -> void:
	for e in d.bench_fx:
		if e.get("wait_shot", false):
			continue
		e["t"] = float(e["t"]) + delta / BENCH_FX_TIME
		if not e["hit"] and float(e["t"]) >= 0.12:
			e["hit"] = true
			d.hp_hold.erase(e["mon"])
			d.snd.play(e["snd"])
	d.bench_fx = d.bench_fx.filter(func(e): return float(e["t"]) < 1.0 and d.game.players[e["p"]].bench.has(e["mon"]))
	for m in d.hp_hold.keys():
		if not d.bench_fx.any(func(e): return e["mon"] == m) and not d.check_anim.any(func(e): return e["mon"] == m) \
				and d.game.players.any(func(pl): return pl.bench.has(m)):
			d.hp_hold.erase(m)
	if d.bench_fx.is_empty():
		d.ai_timer = d.AI_DELAY
		d._rebuild_menu()


func _draw_bench_fx() -> void:
	if d.bench_fx.is_empty() or (not d.anim.is_empty() and not d.anim.get("m_bench", false)):
		return
	for e in d.bench_fx:
		var t: float = e["t"]
		if t < 0.0 or e.get("wait_shot", false):
			continue
		var pl: PlayerState = d.game.players[e["p"]]
		var i := pl.bench.find(e["mon"])
		if i < 0:
			continue
		var r = d._bench_rect(e["p"], i)
		var c = r.get_center()
		var col: Color = e["col"]
		# La carta titila con el golpe
		if t > 0.12 and t < 0.4 and int(t * 30.0) % 2 == 0:
			d.draw_rect(r, Color(1, 1, 1, 0.55))
		if e["rock"]:
			# Piedras que caen y se parten
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(e["mon"]) & 0xffff
			for k in 6:
				var dx := rng.randf_range(-8.0, 8.0)
				var fall := clampf(t / 0.12, 0.0, 1.0)
				var after := maxf(0.0, t - 0.12)
				var p = c + Vector2(dx + dx * after * 2.0, -20.0 + 20.0 * fall + after * after * 60.0 - (8.0 * after if k % 2 == 0 else 0.0))
				var a := clampf(1.0 - after * 2.2, 0.0, 1.0)
				var sz := 4.0 - minf(2.0, after * 6.0)
				d.draw_rect(Rect2(p.round() - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), Color("#383028", a))
				d.draw_rect(Rect2(p.round() - Vector2(sz, sz) / 2.0 + Vector2(1, 1), Vector2(sz - 2, sz - 2)), Color("#a09080", a))
		if t > 0.1 and t < 0.45:
			var k2 := (t - 0.1) / 0.35
			d.anim_ataques._draw_burst(c, 5.0 + k2 * 10.0, Color(col.lightened(0.45), 1.0 - k2), 8)
		# "-10" que sube
		if t > 0.12:
			var txt = "-%d" % int(e["dmg"])
			var u := t - 0.12
			var w = d._text_w(txt)
			var p2 = Vector2(c.x - w / 2.0, r.position.y - 2.0 - minf(u, 0.4) * 14.0)
			if e["p"] != d.human:
				p2.y = r.end.y - 6.0 - minf(u, 0.4) * 10.0
			var al := clampf((1.0 - t) * 4.0, 0.0, 1.0)
			d.draw_rect(Rect2(p2.round() + Vector2(-2, 1), Vector2(w + 4, 10)), Color(0.35, 0.05, 0.05, 0.75 * al))
			d._text(p2.round(), txt, Color(1.0, 0.9, 0.85, al))
