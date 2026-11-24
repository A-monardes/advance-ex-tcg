extends RefCounted
## Animaciones de ataque y de Pokémon que cambian de lugar, íconos de estado de Mystery Dungeon
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


# ===========================================================================
# Animaciones de ataque (según el tipo del atacante)
# ===========================================================================
# Todo es procedural: formas simples dibujadas cuadro a cuadro.
# t va de 0 a 1. Antes de ANIM_IMPACT el ataque "viaja"; en el impacto se aplica
# la acción en el motor (baja la vida) y el defensor tiembla.

## Cómo se ve un ataque: "effect" (no hace daño: sale como un Poké-Power), "bench" (solo
## le pega a la Banca: el atacante se gira hacia ella) o "" (el golpe de siempre).
func _attack_style(action: Dictionary) -> String:
	if d.game.rules.doubles or action.has("ctx") or d.game.phase != "main":
		return ""
	var att = d.game.current_player()
	if att.active == null:
		return ""
	var atks = att.active.attacks()
	if int(action.get("a", 0)) >= atks.size():
		return ""
	var atk: Dictionary = atks[action["a"]]
	if str(atk.get("damage_text", "")) != "":
		return ""
	var txt := str(atk.get("text", ""))
	var low = txt.to_lower()
	# "Choose 1 of your opponent's Benched Pokémon. This attack does 10 damage to that Pokémon."
	if int(action.get("tg", -2)) >= 0 or (low.contains("of your opponent's benched pokémon") and low.contains("damage") \
			and not low.contains("defending pokémon")):
		return "bench"
	if MiniBattle.leaves_status(txt) or MiniBattle.heals_self(txt, CardDB.card_name(att.active.top())):
		return ""                  # estados y curarse: la mini pelea de siempre
	if low.contains("damage") or low.contains("knocked out") or low.contains("discard") and low.contains("defending"):
		return ""                  # le hace algo al rival: se ve el golpe
	return "effect"


func _start_effect_attack(action: Dictionary, coins: Array) -> bool:
	var pi = d.game.actor()
	var mon: PokemonInPlay = d.game.players[pi].active
	var sp := MiniBattle.folder(mon.top())
	if sp == "" or not MiniBattle.available(mon.top()):
		return false
	var atk: Dictionary = mon.attacks()[action["a"]]
	var n: int = 0 if coins.is_empty() else coins[0].size()
	var go := func():
		d.anim_cartas._set_power_anim(pi, mon, sp, d.anim_cartas.power_class(str(atk.get("text", ""))), str(atk.get("name", "")), d._card_rect(pi),
				false, func(): d._apply_now(action, n), "ATTACK", Color("#3868c8"))
	if not coins.is_empty():
		d._show_coins(coins, go, d._attack_label(action))
	else:
		go.call()
	return true


func _start_attack_anim(action: Dictionary, coins_shown: int = 0) -> void:
	if action.has("ctx"):
		# Dobles: el que ataca y el que defiende pasan a ser "el" Activo de cada uno mientras
		# se arma la animación (y la mesa los marca con dbl_focus)
		var c: Array = action["ctx"]
		d.dbl_focus = [1 if c[0] else 0, 1 if c[1] else 0]
		d.game.with_ctx(c, func(): _start_attack_anim_raw(action, coins_shown))
		return
	d.dbl_focus = [0, 0]
	_start_attack_anim_raw(action, coins_shown)


func _start_attack_anim_raw(action: Dictionary, coins_shown: int = 0) -> void:
	var att = d.game.current_player()
	var atk: Dictionary = att.active.attacks()[action["a"]]
	var def = d.game.other(att)
	# Objetivo real: el Activo rival, o el Pokémon de Banca elegido (p.ej. Crushing Wave).
	var target: PokemonInPlay = def.active
	var to: Vector2 = d._art_rect(def.index).get_center()
	var tg: int = action.get("tg", -2)
	var bench_only := false
	if tg >= 0 and tg < def.bench.size():
		target = def.bench[tg]
		to = d._bench_rect(def.index, tg).get_center()
	elif bench_only:
		# Todavía no se eligió a quién: apunta al medio de la Banca
		to = (d._bench_rect(def.index, 0).get_center() + d._bench_rect(def.index, def.bench.size() - 1).get_center()) / 2.0
	d.anim = {
		"t": 0.0, "action": action, "applied": false, "dmg": 0,
		"type": _attack_type(att.active, atk),
		"att_card": att.active.top(), "atk_name": str(atk.get("name", "")),
		"atk_text": str(atk.get("text", "")), "atk_dmg_text": str(atk.get("damage_text", "")),
		"att_mon_s": att.active, "att_dmg_s": att.active.damage,
		"from": d._art_rect(att.index).get_center(),
		"to": to, "att": att.index, "def": def.index,
		"hp_before": target.hp_left() if target != null else 0,
		"def_mon": target,
		"label": "%s used %s!" % [att.active.display_name(), atk["name"]],
		"coins_shown": coins_shown,
		"seed": randi(),
		"dur": d.ANIM_TIME, "impact": d.ANIM_IMPACT,
		"poison": str(atk.get("text", "")).contains("Poisoned"),
		"weak": target != null and target == def.active and not Abilities.ignores_weakness(d.game, target) \
				and att.active.types().any(func(ty): return ty in Abilities.weakness_types(d.game, target)),
	}
	# Algunos Pokémon tienen su propia animación (scenes/special_fx.gd), pero solo cuando le
	# pegan a su rival (Kyogre a Groudon, Zangoose a Seviper…) con un ataque que hace daño.
	var sig = d.SpecialFX.signature_against(CardDB.card_name(att.active.top()),
			CardDB.card_name(target.top()) if target != null else "")
	# Con la escena de batalla activada, el ataque al Activo se ve como en los juegos de GBA
	# (tiene prioridad sobre la animación especial de rivales).
	var hits_active: bool = d.mode == "duel" and target != null and target == def.active \
			and str(atk.get("damage_text", "")) != ""     # los ataques que son solo efectos, en la mesa
	# En la mini pelea también se ven los ataques que solo dejan un estado al Activo rival
	var status_only: bool = d.mode == "duel" and target != null and target == def.active \
			and str(atk.get("damage_text", "")) == "" and MiniBattle.leaves_status(str(atk.get("text", "")))
	# ...y los que solo curan al atacante (se ve el efecto de curación encima suyo)
	if not status_only and str(atk.get("damage_text", "")) == "" and def.active != null and not d.game.rules.doubles \
			and MiniBattle.heals_self(str(atk.get("text", "")), CardDB.card_name(att.active.top())):
		status_only = true
	if d.battle_mode == 1 and (hits_active or status_only) and MiniBattle.can_use(att.active.top(), def.active.top()):
		MiniBattle.setup(d.anim, att, def, atk, d.human)
	elif sig != "" and str(atk.get("damage_text", "")) != "":
		d.anim["sig"] = sig
		d.anim["power"] = d.SpecialFX.power(att.active.top())
		d.anim["dur"] = d.SpecialFX.SIG_TIME
		d.anim["impact"] = d.SpecialFX.SIG_IMPACT
		d.snd.play("special")
# ===========================================================================
# Pokémon que cambian de lugar
# ===========================================================================
# Bajar un Básico a la Banca, retirarse, pasar al puesto Activo después de un KO o
# por un Switch: la carta viaja de un lugar al otro en vez de aparecer de golpe.
# Se detecta comparando dónde estaba cada Pokémon antes y después de la jugada.

func _places() -> Array:
	var out := []
	for pl in d.game.players:
		var dd_ := {}
		for m in pl.all_in_play():
			dd_[m] = -1 if m == pl.active else pl.slot_of(m)
		out.append(dd_)
	return out


func _is_moving(m: PokemonInPlay) -> bool:
	for b in d.move_anim:
		for it in b["items"]:
			if it["mon"] == m:
				return true
	return false


func _check_moves(before: Dictionary) -> void:
	if not d.animations_on or not before.has("places"):
		return
	if before["phase"] in ["setup", "first"] or d.game.phase in ["setup", "first"]:
		return      # la preparación se revela con su propia animación
	var items := []
	var texts := []
	for pi in d.game.players.size():
		var pl: PlayerState = d.game.players[pi]
		var old: Dictionary = before["places"][pi]
		var hand_before: Array = before["piles"][pi][1]
		var mine = pi == d.human
		for m in pl.all_in_play():
			var now: int = -1 if m == pl.active else pl.slot_of(m)
			if old.has(m):
				if old[m] == now:
					continue
				items.append({"mon": m, "p": pi, "from": d.anim_pokemon._slot_rect(pi, old[m]), "kind": "swap" if now == -1 or old[m] == -1 else "shift"})
				if now == -1:
					var out_mon = null
					for o in old:
						if old[o] == -1 and o != m and pl.all_in_play().has(o):
							out_mon = o
					if out_mon != null:
						texts = ["%s returns to the Bench" % out_mon.display_name(), "and %s comes out." % m.display_name()]
					else:
						texts = ["%s moves to the Active Spot!" % m.display_name()]
			else:
				# Nuevo en juego: desde la mano (o desde el mazo, si no estaba en la mano)
				var bench_r = d.anim_pokemon._slot_rect(pi, now)
				var from_hand := m.cards[0] in hand_before
				var start: Rect2
				if from_hand:
					start = Rect2(Vector2(bench_r.position.x, d.H + 4 if mine else -30), d.MINI_SIZE)
				else:
					start = Rect2(d._counters_pos(pi) + Vector2(28, -6), d.MINI_SIZE)
				items.append({"mon": m, "p": pi, "from": start, "kind": "hand" if from_hand else "deck"})
				var who = "You put" if mine else "The opponent puts"
				var where := "on the Bench" if now >= 0 else "in the Active Spot"
				var shown = "Pokémon face down" if d.mesa._face_down(m) else m.display_name()
				if texts.is_empty() or texts[0].begins_with(who):
					texts = ["%s a %s %s." % [who, shown, where]] if texts.is_empty() \
							else [texts[0].trim_suffix(".") + " and %s." % shown]
	if items.is_empty():
		return
	var swap := items.any(func(it): return it["kind"] == "swap")
	d.move_anim.append({"items": items, "t": 0.0, "dur": d.SWAP_TIME if swap else d.MOVE_TIME, "text": texts})
	d.snd.play("draw", 0.8 if swap else 1.0)


func _draw_moves() -> void:
	for bi in d.move_anim.size():
		var b: Dictionary = d.move_anim[bi]
		var t: float = b["t"] if bi == 0 else 0.0
		var k = t * t * (3.0 - 2.0 * t)
		for it in b["items"]:
			var m: PokemonInPlay = it["mon"]
			var pl: PlayerState = d.game.players[it["p"]]
			var slot := -1 if m == pl.active else pl.slot_of(m)
			if slot == -2:
				continue
			var to = d.anim_pokemon._slot_rect(it["p"], slot)
			var from: Rect2 = it["from"]
			var size: Vector2 = from.size.lerp(to.size, k)
			var c: Vector2 = from.get_center().lerp(to.get_center(), k)
			if it["kind"] == "swap":
				# Los dos se cruzan en arcos opuestos: como van en sentidos contrarios, la
				# perpendicular de cada uno ya apunta hacia lados distintos.
				var dirv = (to.get_center() - from.get_center()).normalized()
				c += Vector2(-dirv.y, dirv.x) * sin(k * PI) * 20.0
			elif it["kind"] == "hand":
				c.y += -sin(k * PI) * 8.0 * (1.0 if it["p"] == d.human else -1.0)
			_draw_moving_card(Rect2(c - size / 2.0, size).abs(), m, bi == 0 and t > 0.0)
			if bi == 0 and t > 0.85:      # polvito al aterrizar
				var a = (1.0 - t) / 0.15
				for j in 4:
					var px = to.position.x + (to.size.x if j % 2 else 0.0) + (-3.0 if j % 2 == 0 else 3.0) * (1.0 - a)
					d.draw_rect(Rect2(Vector2(px, to.end.y - 2 - j / 2 * 3), Vector2(2, 2)), Color(1, 1, 1, a * 0.8))


## Carta en viaje: marco amarillo, color del tipo y la ilustración escalada.
func _draw_moving_card(r: Rect2, m: PokemonInPlay, shadow: bool) -> void:
	r.position = r.position.floor()
	r.size = r.size.round()
	if d.mesa._face_down(m):
		d.anim_cartas._draw_card_back(r)
		return
	var t = d._main_type(m.top())
	if shadow:
		d.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), d.C_YELLOW)
	d._fill_types(r.grow(-2), m)
	var side = floorf(minf(r.size.x - 6, r.size.y - 10))
	if side < 4:
		return
	var ar = Rect2(r.position + Vector2(floorf((r.size.x - side) / 2.0), 4), Vector2(side, side))
	var tex = d.mesa._art_texture(m.top(), 36, 36)
	if tex != null:
		d.draw_texture_rect(tex, ar, false)
	else:
		d.draw_rect(ar, d.TYPE_DARK[t])


## Cara a cara: si los dos Activos son rivales clásicos (ver scenes/special_fx.gd) y
## todavía no se mostró en esta partida, empieza la escena. Devuelve true si empezó.
func _check_vs() -> bool:
	if not d.animations_on or d.intro != "" or d.game.phase not in ["main", "choice"] or d.game.rules.doubles:
		return false        # en las batallas dobles no hay cara a cara
	if d.anim_speed != 0:
		return false        # solo con la velocidad Normal (en las rápidas queda el marco de la pantalla)
	var mine: PokemonInPlay = d.game.players[d.human].active
	var theirs: PokemonInPlay = d.game.players[1 - d.human].active
	if mine == null or theirs == null:
		return false
	var r = d.SpecialFX.rivalry(CardDB.card_name(mine.top()), CardDB.card_name(theirs.top()))
	if r.is_empty() or d.vs_seen.has(r["key"]):
		return false
	d.vs_seen[r["key"]] = true
	d.vs_anim = r
	d.vs_anim["t"] = 0.0
	d.vs_anim["a"] = mine.top()
	d.vs_anim["b"] = theirs.top()
	d.snd.play("vs")
	return true


## Tipo de la animación: la primera Energía de color del costo del ataque
## (Crushing Wave cuesta Agua, aunque Swampert ex sea Lucha). Si el ataque solo
## pide Incolora, se usa el tipo del Pokémon.
func _attack_type(p: PokemonInPlay, atk: Dictionary) -> String:
	for c in atk.get("cost", []):
		if c != "Colorless" and d.TYPE_COLORS.has(c):
			return c
	var types = p.types()
	return types[0] if not types.is_empty() else "Colorless"


func _update_anim(delta: float) -> void:
	# Disparo a la Banca: cuando llega, arrancan los estallidos de las cartas
	if d.anim.get("m_bench", false) and float(d.anim["t"]) * float(d.anim["dur"]) >= float(d.anim["m_impact"]):
		for e in d.bench_fx:
			e["wait_shot"] = false
		d.anim_pokemon._update_bench_fx(delta)
	if d.anim.get("waiting", false):
		d.anim["waiting"] = false
		if d.anim.get("hit_pending", false):
			d.anim["hit_pending"] = false
			d._hit_sound()
	if float(d.anim.get("stop", 0.0)) > 0.0:
		d.anim["stop"] = float(d.anim["stop"]) - delta     # golpe a la debilidad: el instante se congela
		return
	var t_before: float = d.anim["t"]
	d.anim["t"] += delta / float(d.anim.get("dur", d.ANIM_TIME))
	var imp_t = float(d.anim.get("impact", d.ANIM_IMPACT))
	if d.anim.get("weak", false) and t_before < imp_t and d.anim["t"] >= imp_t:
		d.anim["t"] = imp_t + 0.001
		d.anim["stop"] = WEAK_STOP
		d.snd.play("weak")
	if not d.anim["applied"] and d.anim["t"] >= float(d.anim.get("impact", d.ANIM_IMPACT)):
		d.anim["applied"] = true
		var mon: PokemonInPlay = d.anim["def_mon"]
		d.anim["cond_before"] = d.mesa._condition_list(mon) if mon != null else []
		var before = d._snapshot()
		var start = d.game.coin_log.size()
		d.game.body_events.clear()
		d.game.checkup_mark = -1
		var turn0 = d.game.turn_number
		d.game.apply(d.anim["action"])
		d.mesa._collect_body_events(true)
		if d.anim.get("coins_shown", 0) > 0:
			d.coins_seen = start + int(d.anim["coins_shown"])     # ya se vieron antes del ataque
		d.anim_cartas._check_energy(before["energy"])
		d.anim_pokemon._check_evolutions()
		d._check_recovered(before["piles"])
		_check_moves(before)
		d.anim_pokemon._check_bench_hits(before)
		# Monedas del ataque que no se adelantaron (sin animaciones previas): antes del golpe.
		# Las del cambio de turno (Dormido, Quemado) se ven después del ataque.
		var own := false
		for i in range(d.coins_seen, d.game.coin_log.size()):
			if d.game.coin_reasons[i] == "":
				own = true
		if own and d.monedas._check_coins():
			d.anim["waiting"] = true     # primero se ven las monedas, después el golpe
		if mon != null:
			# Si después del ataque hubo chequeo entre turnos, el golpe es lo que había justo
			# antes (el veneno y la quemadura se ven aparte, después)
			var hp_after := mon.hp_left()
			var ck = mon.flags.get("pre_checkup", [])
			var checked: bool = ck is Array and ck.size() == 3 and int(ck[0]) == turn0
			if checked:
				hp_after = mon.max_hp() - int(ck[1])
			d.anim["dmg"] = maxi(0, d.anim["hp_before"] - maxi(0, hp_after))
			if not d.game.players[d.anim["def"]].all_in_play().has(mon) and (not checked or hp_after <= 0):     # quedó KO con el golpe
				d.anim["dmg"] = d.anim["hp_before"]
				d.anim["ko"] = true
		if d.anim.get("mini", false):
			MiniBattle.on_applied(d.anim)
		if d.anim.get("waiting", false):
			d.anim["hit_pending"] = true     # suena cuando se ve el golpe, después de las monedas
		else:
			d._hit_sound()
	if d.anim["t"] >= 1.0:
		d.anim = {}
		d.ai_timer = d.AI_DELAY
		d.monedas._check_coins()      # las monedas del cambio de turno, si las hubo
		d._rebuild_menu()


const HIT_SHAKE := 0.34      # lo que tiembla el defensor después del golpe (fracción del ataque)
const BIG_HIT := 60          # desde este daño tiembla toda la mesa
const WEAK_STOP := 0.14      # golpe a la debilidad: segundos que se congela el impacto


## Temblor de toda la mesa en los golpes fuertes.
func _table_shake() -> Vector2:
	if d.anim.get("scene", false):
		return MiniBattle.quake(d.anim) if d.anim.get("mini", false) else Vector2.ZERO
	var weak: bool = not d.anim.is_empty() and d.anim.get("weak", false) and int(d.anim.get("dmg", 0)) > 0
	if d.anim.is_empty() or d.anim.get("waiting", false) or (int(d.anim.get("dmg", 0)) < BIG_HIT and not weak):
		return Vector2.ZERO
	var t: float = d.anim["t"]
	var imp: float = d.anim.get("impact", d.ANIM_IMPACT)
	var dur := 0.3 if weak else 0.18
	if t < imp or t > imp + dur:
		return Vector2.ZERO
	var k = 1.0 - (t - imp) / dur
	var amp := 3.5 if weak else 2.0
	if float(d.anim.get("stop", 0.0)) > 0.0:
		k = 1.0                         # mientras se congela, la mesa sigue sacudida
		t += Clock.ms() / 1000.0
	return Vector2(round(sin(t * 110.0) * amp * k), round(cos(t * 95.0) * amp * 0.75 * k))


# Íconos de estado de Mystery Dungeon (efectos/propios/est_*.png, tools/armar_estados.py),
# animados arriba de la imagen del Pokémon. Si tiene varios, se turnan.
#   est_poder         tiene un Poké-Power que puede usar ahora
#   est_poder_negado  su Poké-Power está negado (Condición Especial, Toxic Gas, Lazy...)
#   est_aviso         el rival le puso un efecto (no puede atacar, ni retirarse, ataque bloqueado...)
#   est_escudo        recibe menos daño          est_mas / est_menos  hace más / menos daño
#   est_quemado, est_confuso, est_dormido, est_veneno; Paralizado = rayo.png
const PMD_SHOW := 1.1         # segundos que se ve cada ícono (su animación)
const PMD_GAP := 0.9          # después desaparece un momento y aparece el siguiente (o el mismo de nuevo)
var _power_cache := {}         # jugador -> slots con un Poké-Power usable (se recalcula si cambia la partida)
var _power_cache_key := []


func _power_slots(pl: PlayerState) -> Dictionary:
	var key = [d.game.turn_number, d.game.log_lines.size(), d.game.current, d.game.phase]
	if key != _power_cache_key:
		_power_cache_key = key
		_power_cache = {}
	if not _power_cache.has(pl.index):
		var slots := {}
		if d.game.current == pl.index and d.game.phase == "main":
			for a in Abilities.power_actions(d.game, pl):
				slots[int(a["s"])] = true
		_power_cache[pl.index] = slots
	return _power_cache[pl.index]


func _pmd_icons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	var out: Array = []
	for r in _pmd_reasons(pl, p, slot):
		if not r[0] in out:
			out.append(r[0])
	return out


const CONDITION_ICONS := ["est_quemado", "est_veneno", "est_dormido", "est_confuso", "rayo"]


## Los motivos sin las Condiciones Especiales (esas ya se ven en rojo al lado de la vida).
func _effect_reasons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	return _pmd_reasons(pl, p, slot).filter(func(r): return not r[0] in CONDITION_ICONS)


## Versión corta de un motivo para la vista partida (la ficha completa tiene el texto entero).
func _short_reason(t: String, width: float) -> String:
	if d._text_w(t) <= width:
		return t
	for cut in [" next turn", " from attacks", " at end of next turn", ": takes less damage", " damage"]:
		if t.contains(cut) and d._text_w(t.replace(cut, "")) <= width:
			return t.replace(cut, "")
	return t.replace(" next turn", "")


## Ícono de estado chiquito (unos 10 px), animado, para los renglones de explicación.
func _reason_icon(name: String, center: Vector2) -> void:
	var cell = d.SpecialFX.fx_cell(name)
	if cell.x <= 0:
		return
	_draw_pmd_icon(name, center, 10.0 / maxf(cell.x, cell.y))


## Lo mismo que _pmd_icons, pero con el motivo: [[ícono, "explicación"], ...] (un ícono puede
## aparecer varias veces si tiene varios motivos). Se muestra en la vista partida (C en la mesa).
func _pmd_reasons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	var out: Array = []
	var t = d.game.turn_number
	if slot == -1:
		if p.burned:
			out.append(["est_quemado", "Burned: flip at checkup, tails = 2 damage counters"])
		if p.poison > 0:
			out.append(["est_veneno", "Poisoned: %d damage counter%s at checkup" % [p.poison, "" if p.poison == 1 else "s"]])
		match p.rotation:
			"asleep": out.append(["est_dormido", "Asleep: can't attack or retreat"])
			"confused": out.append(["est_confuso", "Confused: flip to attack"])
			"paralyzed": out.append(["rayo", "Paralyzed: can't attack or retreat"])
	for ab in p.abilities():
		if ab["kind"] != "Poké-Power":
			continue
		if Abilities.power_blocked(d.game, pl, p):
			out.append(["est_poder_negado", "Can't use Poké-Power: %s" % ab["name"]])
		elif _power_slots(pl).has(slot):
			out.append(["est_poder", "Can use Poké-Power: %s" % ab["name"]])
	if slot != -1:
		return out
	var f = p.flags
	if int(f.get("cant_attack", -1)) >= t:
		out.append(["est_aviso", "Can't attack next turn"])
	if int(f.get("cant_retreat", -1)) >= t:
		out.append(["est_aviso", "Can't retreat next turn"])
	if int(f.get("no_attach", -1)) >= t:
		out.append(["est_aviso", "Can't get Energy next turn"])
	if int(f.get("smokescreen", -1)) >= t:
		out.append(["est_aviso", "Must flip to attack (tails: no attack)"])
	if f.get("disabled_attack", null) is Array and int(f["disabled_attack"][1]) >= t:
		out.append(["est_aviso", "Can't use %s next turn" % str(f["disabled_attack"][0])])
	if f.has("delayed_status"):
		var ds = f["delayed_status"]
		var cond: String = str(ds[0]) if ds is Array else str(ds)
		out.append(["est_aviso", "Will be %s at end of next turn" % cond.capitalize()])
	if f.get("silver_wind", null) is Array and int(f["silver_wind"][0]) >= t:
		out.append(["est_aviso", "Takes %d more damage next turn" % int(f["silver_wind"][2])])
	if Abilities.attack_blocked(d.game, p):
		out.append(["est_aviso", "Can't attack (a Poké-Body blocks it)"])
	var opp = d.game.other(pl)
	if int(f.get("prevent_all", -1)) >= t:
		out.append(["est_escudo", "No damage or effects from attacks"])
	elif int(f.get("prevent_damage", -1)) >= t:
		out.append(["est_escudo", "No damage from attacks"])
	if int(f.get("reduce_until", -1)) >= t:
		out.append(["est_escudo", "Takes less damage next turn"])
	if CardDB.card_name(p.tool) == "Buffer Piece":
		out.append(["est_escudo", "Buffer Piece: takes 20 less damage"])
	if p.is_type("Metal") and Energy.count_named(p, "Metal Energy") > 0:
		out.append(["est_escudo", "Metal Energy: takes 10 less damage"])
	for body in ["Exoskeleton", "Hard Cocoon", "Sand Guard", "Crust", "Ice Wall", "Glowing Screen"]:
		if Abilities.body(d.game, p, body):
			out.append(["est_escudo", "%s: takes less damage" % body])
	if Abilities.body(d.game, p, "Energy Guard") and p.basic_energy_count() > 0:
		out.append(["est_escudo", "Energy Guard: takes less damage"])
	if Abilities.body(d.game, p, "Shell Retreat") and not p.energy.is_empty():
		out.append(["est_escudo", "Shell Retreat: takes less damage"])
	if Abilities.body(d.game, p, "Core Guard") and Energy.count_type(p, "Psychic") > 0:
		out.append(["est_escudo", "Core Guard: takes less damage"])
	if int(f.get("next_until", -1)) >= t:
		out.append(["est_mas", "Next attack does more damage"])
	if CardDB.card_name(p.tool) == "Strength Charm":
		out.append(["est_mas", "Strength Charm: +10 damage"])
	if (p.is_type("Darkness") or p.name_has("Dark")) and Energy.count_named(p, "Darkness Energy") > 0:
		out.append(["est_mas", "Darkness Energy: +10 damage"])
	if Abilities.active_body(d.game, pl, "Power Pinchers"):
		out.append(["est_mas", "Power Pinchers: does more damage"])
	if Abilities.body(d.game, p, "Overzealous"):
		out.append(["est_mas", "Overzealous: does more damage"])
	if Energy.count_named(p, "Double Rainbow Energy") > 0:
		out.append(["est_menos", "Double Rainbow Energy: -10 damage"])
	if Abilities.active_body(d.game, opp, "Intimidating Fang"):
		out.append(["est_menos", "Intimidating Fang: -10 damage"])
	return out


## Pastilla de estado de Rubí/Zafiro (mundo/propios/ui/estado_*.png) en la ficha. Si
## tiene varios estados, se turnan cada STATUS_PILL_TIME segundos. false = no hay imágenes.
const PILL_FOR := {"poisoned": "estado_psn", "paralyzed": "estado_par", "asleep": "estado_slp",
		"burned": "estado_brn", "confused": "estado_cnf"}
const STATUS_PILL_TIME := 1.5

func _draw_status_pill(pos: Vector2, conds: Array) -> bool:
	var texs: Array = []
	for c in conds:
		var tex = d._ui_tex(str(PILL_FOR.get(c, "")))
		if tex == null:
			return false
		texs.append(tex)
	var i := int(Clock.ms() / 1000.0 / STATUS_PILL_TIME) % texs.size()
	d.draw_texture(texs[i], pos)
	if texs.size() > 1:            # puntitos debajo: cuántos tiene y cuál se ve
		for j in texs.size():
			d.draw_rect(Rect2(pos.x + 22, pos.y + 1 + j * 2, 1, 1), d.C_TEXT if j == i else d.C_PANEL_DARK)
	return true


## Se ven los íconos animados de estado (están las tiras y las animaciones prendidas).
func _pmd_shown() -> bool:
	return d.animations_on and d.SpecialFX.has_fx("est_quemado") and d.SpecialFX.has_fx("est_veneno") \
			and d.SpecialFX.has_fx("est_dormido") and d.SpecialFX.has_fx("est_confuso") and d.SpecialFX.has_fx("rayo")


## local: segundos desde que apareció (la animación arranca del primer cuadro); -1 = reloj.
func _draw_pmd_icon(name: String, pos: Vector2, scale: float, local: float = -1.0, alpha: float = 1.0) -> void:
	var n = d.SpecialFX.fx_count(name)
	if n == 0:
		return
	var t := local if local >= 0.0 else Clock.ms() / 1000.0
	var fr = int(t / 0.09) % n
	d.SpecialFX.fx_draw(d, name, fr, pos, scale, alpha)


## El ícono de estado del Activo, arriba de su imagen, con un rebotecito.
func _draw_status_fx(pl: PlayerState, mon: PokemonInPlay = null, art_r: Rect2 = Rect2()) -> void:
	var m: PokemonInPlay = mon if mon != null else pl.active
	if m == null or not d.animations_on:
		return
	# (el Poké-Power ya se ve en la pestaña del Activo: acá no va el ícono de las esferas)
	var icons = _pmd_icons(pl, m, -1).filter(func(n): return not n.begins_with("est_poder"))
	if icons.is_empty():
		return
	# Intermitente: se ve un rato (con su animación desde el principio), desaparece un
	# momento y vuelve (el mismo, o el siguiente si tiene varios estados)
	var now := Clock.ms() / 1000.0
	var cycle := PMD_SHOW + PMD_GAP
	var idx = int(now / cycle) % icons.size()
	var local := fmod(now, cycle)
	if local >= PMD_SHOW:
		return
	var name: String = icons[idx]
	var art = Rect2(d._art_rect(pl.index).position + _anim_offset(pl.index), d._art_rect(pl.index).size)
	if art_r.size.x > 0:
		art = art_r
	var bob := roundf(sin(local * 4.0) * 1.5)
	var sc := 1.0
	if name == "rayo":
		sc = 0.6
	elif name.begins_with("est_poder"):
		sc = 2.0                         # los ojos son chiquitos (8x8)
	var pop := clampf(local / 0.08, 0.0, 1.0)            # aparece con un saltito de escala
	var fade := clampf((PMD_SHOW - local) / 0.12, 0.0, 1.0)  # y se apaga suave
	_draw_pmd_icon(name, Vector2(art.end.x - 8, art.position.y + 8 + bob), sc * (0.6 + 0.4 * pop), local, fade)
	if icons.size() > 1:                 # puntitos: cuántos estados tiene y cuál se ve
		for i in icons.size():
			var c = Color.WHITE if i == idx else Color(1, 1, 1, 0.4)
			d.draw_rect(Rect2(art.position.x + 2 + i * 4, art.end.y - 3, 2, 2), c)


## En la Banca: si tiene un Poké-Power que se puede usar ahora, el borde late en rojo (el
## mismo rojo de la pestaña de Poké-Power del Activo).
func _draw_bench_status(pl: PlayerState, i: int, r: Rect2) -> void:
	if not _power_slots(pl).has(i):
		return
	var a = 0.85 + 0.15 * sin(Clock.ms() / 1000.0 * 5.0) if d.animations_on else 1.0
	var glow = 0.35 + 0.65 * (0.5 + 0.5 * sin(Clock.ms() / 1000.0 * 5.0)) if d.animations_on else 1.0
	d._outline(r.grow(1), Color(d.TAB_COLORS["power"][0], a))
	d._outline(r.grow(2), Color(d.TAB_COLORS["power"][0], a))
	d._outline(r.grow(3), Color(d.TAB_COLORS["power"][1], glow))


## Destello blanco sobre la carta que recibe el golpe.
func _draw_hit_flash(pl: PlayerState) -> void:
	if d.anim.is_empty() or d.anim.get("waiting", false) or d.anim.get("scene", false) or int(d.anim.get("dmg", 0)) <= 0:
		return
	if pl.index != d.anim["def"] or not pl.is_active(d.anim["def_mon"]):
		return
	var t: float = d.anim["t"]
	var imp: float = d.anim.get("impact", d.ANIM_IMPACT)
	var weak: bool = d.anim.get("weak", false)
	var dur := 0.2 if weak else 0.09
	if t < imp or t > imp + dur:
		return
	var a = 1.0 - (t - imp) / dur
	var r = d.mesa._portrait_rect(d._card_rect(pl.index).position + _anim_offset(pl.index))
	if weak and float(d.anim.get("stop", 0.0)) <= 0.0:
		d.draw_rect(r, Color(1, 0.2, 0.15, 0.6 * a))      # debilidad: después del blanco, rojo
		d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(1, 1, 1, 0.25 * a))
	else:
		d.draw_rect(r, Color(1, 1, 1, 0.8 if weak else 0.75 * a))


## Desplazamiento del Activo de un jugador: el atacante embiste, el defensor tiembla.
func _anim_offset(player: int) -> Vector2:
	if d.anim.is_empty() or d.anim.get("waiting", false) or d.anim.get("scene", false):
		return Vector2.ZERO
	var t: float = d.anim["t"]
	var imp: float = d.anim.get("impact", d.ANIM_IMPACT)
	var sig: String = d.anim.get("sig", "")
	if player == d.anim["att"] and t < imp:
		var dir: Vector2 = (d.anim["to"] - d.anim["from"]).normalized()
		var k = sin(t / imp * PI) * (6.0 if d.anim["type"] in ["Fighting", "Colorless", "Metal"] or sig in ["zangoose", "heracross"] else 3.0)
		return dir * k
	if player == d.anim["def"] and t >= imp and t < imp + HIT_SHAKE and d.anim["dmg"] > 0 \
			and d.game.players[d.anim["def"]].is_active(d.anim["def_mon"]):
		# Cuanto más daño, más fuerte tiembla (y los especiales, lo suyo)
		var amp: float = d.SpecialFX.shake(sig) if sig != "" else clampf(2.0 + d.anim["dmg"] / 15.0, 3.0, 7.0)
		if d.anim.get("weak", false):
			amp = maxf(amp, 9.0)
		var k = pow(1.0 - (t - imp) / HIT_SHAKE, 1.5) * amp
		return Vector2(round(sin(t * 90.0) * k), round(cos(t * 70.0) * k * 0.35))
	return Vector2.ZERO


func _draw_anim() -> void:
	if d.anim.is_empty() or d.anim.get("waiting", false) or d.anim.get("scene", false):
		return
	_draw_anim_fx()


## El efecto del ataque según el tipo (lo usa también la escena de batalla, con otras
## posiciones de atacante y defensor).
func _draw_anim_fx() -> void:
	var t: float = d.anim["t"]
	var from: Vector2 = d.anim["from"]
	var to: Vector2 = d.anim["to"]
	var c: Color = d.TYPE_COLORS.get(d.anim["type"], d.C_LIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = d.anim["seed"]
	var imp: float = d.anim.get("impact", d.ANIM_IMPACT)
	var travel = clampf(t / imp, 0.0, 1.0)     # 0..1 hasta el impacto
	var after = clampf((t - imp) / (1.0 - imp), 0.0, 1.0)   # 0..1 después
	var hit = t >= imp
	var kind: String = d.anim["type"]
	if d.anim.has("sig"):
		d.SpecialFX.draw_attack(d, d.anim, d.BOX_Y)
		kind = "special"
	elif d.anim.get("poison", false) and hit:
		# Ataques que envenenan: la nube de veneno de los sprites (si están), sobre el rival
		d.SpecialFX.poison_cloud(d, to, after / 0.95, 0.85)
	match kind:
		"special":
			pass
		"Fire":
			if d.SpecialFX.has_fx("ascuas") or d.SpecialFX.has_fx("fuego_golpe"):
				# Con los sprites de efectos: tres ascuas que vuelan y un golpe de fuego
				for i in 3:
					var k = clampf(travel * 1.3 - i * 0.15, 0.0, 1.0)
					if k > 0.0 and k < 1.0:
						var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 10)
						if d.SpecialFX.has_fx("ascuas"):
							d.SpecialFX.fx_draw(d, "ascuas", 5 + (int(t * 24.0) + i * 2) % 6, p, 0.9 - i * 0.12)
						else:
							d.draw_circle(p, 4.0 - i, c)
				if hit:
					if not d.SpecialFX.fire_hit(d, to, after / 0.9, 0.8):
						for i in 10:
							var ang := rng.randf() * TAU
							var p = to + Vector2(cos(ang), sin(ang)) * after * rng.randf_range(8, 18)
							d.draw_circle(p, (1.0 - after) * 3.0 + 0.5, c if i % 2 == 0 else Color("#ffd040"))
			else:
				# Tres bolas de fuego en fila y una explosión de llamas.
				for i in 3:
					var k = clampf(travel * 1.3 - i * 0.15, 0.0, 1.0)
					if k > 0.0 and k < 1.0:
						var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 10)
						d.draw_circle(p, 4.0 - i, c)
						d.draw_circle(p, 2.0 - i * 0.5, Color("#ffe060"))
				if hit:
					for i in 10:
						var ang := rng.randf() * TAU
						var r = after * rng.randf_range(8, 18)
						var p = to + Vector2(cos(ang), sin(ang)) * r + Vector2(0, -after * 6)
						d.draw_circle(p, (1.0 - after) * 3.0 + 0.5, c if i % 2 == 0 else Color("#ffd040"))
		"Water":
			# Chorro de gotas en arco y salpicadura.
			for i in 6:
				var k = clampf(travel * 1.4 - i * 0.07, 0.0, 1.0)
				if k > 0.0 and k < 1.0:
					var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 18)
					d.draw_circle(p, 2.5, c)
					d.draw_circle(p + Vector2(-0.8, -0.8), 1.0, d.C_LIGHT)
			if hit:
				for i in 8:
					var ang := -PI * rng.randf()
					var v := Vector2(cos(ang), sin(ang)) * rng.randf_range(10, 20)
					var p = to + v * after + Vector2(0, 20 * after * after)
					d.draw_circle(p, 2.0 * (1.0 - after) + 0.5, c)
		"Grass":
			# Hojas girando.
			for i in 5:
				var k = clampf(travel * 1.3 - i * 0.08, 0.0, 1.0)
				var p = from.lerp(to, k) + Vector2(0, sin(k * PI * 2.0 + i) * 6)
				if hit:
					var ang0 := rng.randf() * TAU
					p = to + Vector2(cos(ang0), sin(ang0)) * after * 16
				_draw_leaf(p, t * 20.0 + i, c)
		"Lightning":
			# Rayo que cae del cielo y destello de pantalla.
			if t > d.ANIM_IMPACT * 0.6:
				var pts = PackedVector2Array([Vector2(to.x + 4, 0)])
				var y := 0.0
				while y < to.y:
					y += rng.randf_range(5, 9)
					pts.append(Vector2(to.x + rng.randf_range(-6, 6), minf(y, to.y)))
				if after < 0.6 and int(t * 30) % 2 == 0:
					d.draw_polyline(pts, Color("#fff8a0"), 2.0)
					d.draw_polyline(pts, c, 1.0)
			if hit and after < 0.25:
				d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(1, 1, 0.8, 0.5 * (1.0 - after / 0.25)))
		"Psychic":
			# Ondas que salen del atacante y anillos sobre el defensor.
			for i in 3:
				var k = fmod(travel + i * 0.33, 1.0)
				if not hit:
					d.draw_arc(from.lerp(to, k), 4.0 + k * 6.0, 0, TAU, 16, c, 1.0)
			if hit:
				for i in 3:
					var r = (after * 1.5 - i * 0.2) * 22.0
					if r > 0.0:
						d.draw_arc(to, r, 0, TAU, 24, Color(c, 1.0 - after), 1.0)
		"Fighting":
			# Embestida (ver _anim_offset) y estrella de impacto.
			if hit and after < 0.6:
				_draw_burst(to, 6.0 + after * 14.0, d.C_LIGHT, 8)
				_draw_burst(to, 3.0 + after * 8.0, c, 8)
		"Darkness":
			# Pantalla que se oscurece y dos tajos en X.
			d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.35 * sin(t * PI)))
			if hit:
				var k = minf(after * 3.0, 1.0)
				var a = Color(0.85, 0.75, 1.0, 1.0 - after)
				d.draw_line(to + Vector2(-12, -12), to + Vector2(-12, -12).lerp(Vector2(12, 12), k), a, 2.0)
				d.draw_line(to + Vector2(12, -12), to + Vector2(12, -12).lerp(Vector2(-12, 12), k), a, 2.0)
		"Metal":
			# Esquirlas metálicas y chispas.
			for i in 4:
				var k = clampf(travel * 1.3 - i * 0.1, 0.0, 1.0)
				if k > 0.0 and k < 1.0:
					var p = from.lerp(to, k) + Vector2(0, (i - 1.5) * 4)
					var dd_ = (to - from).normalized() * 4
					d.draw_line(p - dd_, p + dd_, d.C_LIGHT, 2.0)
			if hit:
				for i in 8:
					var ang := rng.randf() * TAU
					var p = to + Vector2(cos(ang), sin(ang)) * after * rng.randf_range(10, 20)
					d.draw_rect(Rect2(p, Vector2(2, 2)), Color("#fff0a0") if i % 2 else c)
		_:
			if hit and after < 0.6:
				if d.SpecialFX.has_fx("estrellas"):      # tus estrellas de golpe
					d.SpecialFX.fx_draw(d, "estrellas", d.SpecialFX.fx_frame("estrellas", after / 0.6), to, 1.0, 1.0 - after)
				else:
					_draw_burst(to, 5.0 + after * 12.0, d.C_LIGHT, 5)
	# Golpe a la debilidad: tu explosión grande y estrellas que salen volando
	if hit and d.anim.get("weak", false) and d.anim["dmg"] > 0:
		var ke = clampf(after * 2.2, 0.0, 1.0)
		if ke < 1.0:
			if d.SpecialFX.has_fx("explosion"):
				d.SpecialFX.fx_draw(d, "explosion", d.SpecialFX.fx_frame("explosion", ke), to, 2.2, 1.0 - ke * 0.5)
			else:
				_draw_burst(to, 10.0 + ke * 24.0, Color("#fff0a0"), 8)
			for i in 6:
				var ang := TAU * i / 6.0 + 0.4
				var sp = to + Vector2(cos(ang), sin(ang)) * (8.0 + ke * 34.0)
				if d.SpecialFX.has_fx("estrellas"):
					d.SpecialFX.fx_draw(d, "estrellas", (i + int(ke * 8)) % 5, sp, 0.6, 1.0 - ke)
				else:
					d.anim_cartas._draw_star(sp, 3.0, ke * 3.0, Color(d.C_ACCENT, 1.0 - ke))
	# Número de daño flotando sobre el defensor (en la escena de batalla lo dicen la barra y
	# el mensaje, como en los juegos).
	if hit and d.anim["dmg"] > 0 and not d.anim.get("scene", false):
		# El número salta grande, rebota y sube flotando
		var txt = "-%d" % d.anim["dmg"]
		var weak: bool = d.anim.get("weak", false)
		var pop = clampf(after * 7.0, 0.0, 1.0)
		var base_sc := 3.0 if weak else 2.0
		var sc: float = base_sc + sin(pop * PI) * (1.4 if weak else 0.8) if pop < 1.0 else base_sc
		var w = d._text_w(txt) * sc
		var p = to + Vector2(-w / 2.0, -26 - after * 8)
		if p.y < 4:                        # objetivo arriba de todo: el número va abajo
			p = to + Vector2(-w / 2.0, 6 + after * 5)
		p.x = clampf(p.x, 2.0, d.W - 2.0 - w)  # que no se salga por los costados (mesa doble)
		var col: Color = Color("#f85838") if d.anim["dmg"] >= BIG_HIT or weak else d.C_LIGHT
		col.a = clampf((1.0 - after) * 3.0, 0.0, 1.0)
		d.draw_set_transform(d._base_off + p.round(), 0, Vector2(sc, sc))
		d._text(Vector2.ZERO, txt, col)
		d.draw_set_transform(d._base_off)
		if weak:                           # el cartel de la debilidad: grande, en el medio de la mesa
			var lbl := "WEAKNESS!"
			var lk = clampf(after * 5.0, 0.0, 1.0)
			var lsc = 2.0 + (1.0 - lk) * 1.5
			var lw = d._text_w(lbl) * lsc
			var lc := Color("#f8d030") if int(Clock.ms() / 90.0) % 2 == 0 else Color.WHITE
			lc.a = col.a
			d.draw_rect(Rect2(0, d.BOX_Y / 2.0 - 13, d.W, 22), Color(0.1, 0.05, 0.05, 0.55 * col.a))
			d.draw_set_transform(d._base_off + Vector2(roundf(d.W / 2.0 - lw / 2.0), roundf(d.BOX_Y / 2.0 - 5.0 * lsc)), 0, Vector2(lsc, lsc))
			d._text(Vector2.ZERO, lbl, lc)
			d.draw_set_transform(d._base_off)


func _draw_leaf(p: Vector2, ang: float, c: Color) -> void:
	var a := Vector2(cos(ang), sin(ang)) * 4.0
	var b = Vector2(-a.y, a.x) * 0.4
	d.draw_colored_polygon(PackedVector2Array([p - a, p + b, p + a, p - b]), c)


func _draw_burst(center: Vector2, radius: float, c: Color, points: int) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var ang := TAU * i / (points * 2.0) - PI / 2.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	d.draw_colored_polygon(pts, c)
