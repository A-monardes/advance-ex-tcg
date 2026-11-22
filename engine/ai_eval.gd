extends RefCounted
## Evaluación de una posición desde el punto de vista de un jugador (para la IA).
## Número más alto = mejor para `me`. No mira cartas ocultas: solo la mesa, los
## Premios y cuántas cartas hay en mano y mazo.

const WIN := 100000.0

## Pesos de la evaluación (se pueden ajustar desde tests/ai_levels.gd para probar).
static var W := {"prize": 120.0, "ko": 55.0, "dmg": 25.0, "hand_me": 3.0, "hand_opp": 1.0,
		"mon": 12.0, "stage": 10.0, "hp": 0.15, "energy": 12.0, "ready": 20.0, "bench": 4.0,
		"ready_active": 25.0, "stall": 30.0}
## Evaluación nueva (auditoría de la IA): el Activo listo para atacar también cuenta, y un
## Activo que ni con 1 Energía más puede atacar es un turno perdido. Se puede apagar para comparar.
static var v2 := true


static func evaluate(g: Game, me_index: int) -> float:
	var me: PlayerState = g.players[me_index]
	var opp: PlayerState = g.players[1 - me_index]
	if g.phase == "over":
		if g.winner == me_index:
			return WIN
		if g.winner == 1 - me_index:
			return -WIN
		return 0.0
	var v := 0.0
	# Premios: lo más importante
	v += (opp.prizes.size() - me.prizes.size()) * W["prize"]
	# Sin Pokémon en juego = derrota cercana
	if me.all_in_play().is_empty():
		return -WIN * 0.5
	if opp.all_in_play().is_empty():
		return WIN * 0.5
	v += _side_value(g, me) - _side_value(g, opp)
	# Amenazas sobre los Activos (en dobles, el mejor par atacante/defensor de cada lado)
	if not me.actives().is_empty() and not opp.actives().is_empty():
		# Se evalúa al terminar mi turno: el rival ataca primero (con 1 Energía más) y después yo.
		var to_move: int = g.current
		var my_w := 1.0 if to_move == me_index else 0.6       # si le toca al rival, mi amenaza vale menos
		var their_w := 1.0 if to_move != me_index else 0.6
		v += _threat(g, me.actives(), opp.actives()) * my_w
		v -= _threat(g, opp.actives(), me.actives()) * their_w
		for d in opp.actives():
			v += _status_value(d)
		for d in me.actives():
			v -= _status_value(d)
		if v2:
			# Activo trabado: ni con la Energía del turno que viene puede pegar
			for pair in [[me, opp, -1.0], [opp, me, 1.0]]:
				var a: PokemonInPlay = pair[0].active
				var d: PokemonInPlay = pair[1].active
				if a != null and d != null and best_damage(g, a, d, 1) == 0:
					v += W["stall"] * pair[2]
	# Recursos
	v += mini(me.hand.size(), 10) * W["hand_me"] - mini(opp.hand.size(), 10) * W["hand_opp"]
	if me.deck.size() < 6:
		v -= (6 - me.deck.size()) * 15.0
	return v


## Lo mejor que pueden hacer los atacantes contra los defensores el turno que viene: un KO
## (vale por los Premios que da) o, si no llega, la parte de los PS que le saca.
static func _threat(g: Game, atts: Array, defs: Array) -> float:
	var best := 0.0
	for a in atts:
		for d in defs:
			var dmg := best_damage(g, a, d, 1)
			var val: float
			if dmg >= d.hp_left():
				val = W["ko"] * (2.0 if d.is_ex() else 1.0)
			else:
				val = W["dmg"] * float(dmg) / maxf(1.0, d.hp_left())
			best = maxf(best, val)
	return best


static func _side_value(g: Game, p: PlayerState) -> float:
	var v := 0.0
	for m in p.all_in_play():
		var stage := CardDB.stage(m.top())
		v += W["mon"] + stage * W["stage"]
		v += m.hp_left() * W["hp"]
		var useful := mini(Energy.total(m), _max_cost(m) + 1)
		v += useful * W["energy"]
		if m.tool != "":
			v += 4.0
		# Pokémon listo para atacar (sirve de reemplazo si cae el Activo; el Activo, para pegar ya)
		var ready := m.attacks().any(func(atk): return int(atk.get("damage", 0)) > 0 and Energy.can_pay(m, atk.get("cost", [])))
		if ready and not p.is_active(m):
			v += W["ready"]
		elif ready and v2:
			v += W["ready_active"]
	v += mini(p.bench.size(), 4) * W["bench"]
	return v


static func _max_cost(m: PokemonInPlay) -> int:
	var c := 0
	for atk in m.attacks():
		c = maxi(c, atk.get("cost", []).size())
	return c


static func _status_value(m: PokemonInPlay) -> float:
	var v := 0.0
	if m.rotation in ["asleep", "paralyzed"]:
		v += 10.0
	elif m.rotation == "confused":
		v += 6.0
	if m.poison > 0:
		v += 6.0
	if m.burned:
		v += 6.0
	return v


## Daño aproximado del mejor ataque de `att` contra `def` (Debilidad y Resistencia
## incluidas). extra_energy: Energías que podría unir antes de atacar (1 = el turno que viene).
static func best_damage(g: Game, att: PokemonInPlay, def: PokemonInPlay, extra_energy: int) -> int:
	var best := 0
	var have := Energy.total(att) + extra_energy
	for atk in att.attacks():
		var cost: Array = atk.get("cost", [])
		var ok := Energy.can_pay(att, cost) if extra_energy == 0 else cost.size() <= have
		if not ok:
			continue
		var dmg: int
		if v2:
			dmg = int(attack_estimate(g, att, atk, def))
		else:
			dmg = int(atk.get("damage", 0))
			if dmg <= 0:
				continue
			if att.types().any(func(t): return t in def.data().get("weaknesses", [])):
				dmg *= 2
			if att.types().any(func(t): return t in def.data().get("resistances", [])):
				dmg -= 30
		best = maxi(best, dmg)
	return best


## Fórmulas que miran la mano del rival: la IA no las puede saber (y algunas escriben en el registro).
const HIDDEN_FORMULAS := ["opp_hand_energy", "opp_hand_trainers"]


## Daño esperado de un ataque contra `def`, leyendo sus efectos: las condiciones que no
## dependen de monedas se miran de verdad (¿es ex?, ¿está dormido?...), las monedas cuentan
## la mitad y las fórmulas se calculan con la mesa. Debilidad y Resistencia incluidas.
static func attack_estimate(g: Game, att: PokemonInPlay, atk: Dictionary, def: PokemonInPlay) -> float:
	var dmg := float(atk.get("damage", 0))
	var parsed: Dictionary = AttackEffects.parse(att.top(), atk)
	var me := g.owner_of(att)
	var opp := g.owner_of(def)
	if me == null or opp == null:
		return dmg
	var ctx := {"coins": [], "heads": 0, "flips": 0, "did": true, "opt": true, "dmg": dmg, "base": dmg,
			"ignore": {}, "target": -2, "dealt": 0, "attack": atk}
	var ign_w := false
	var ign_r := false
	for op in parsed["ops"]:
		var c: String = op.get("c", "")
		var w := 1.0
		if c in ["heads", "tails", "any_heads", "any_tails", "all_heads", "all_tails", "heads_at_least"]:
			w = 0.5
		elif c not in ["", "did"] and not AttackEffects._cond_ok(g, op, ctx, me, opp, att, def):
			continue
		match op["k"]:
			"bonus": dmg += op["n"] * w
			"set_base": dmg = op["n"] * w + dmg * (1.0 - w)
			"nothing":
				if w >= 1.0:
					return 0.0
				dmg *= 1.0 - w
			"flips":
				var n_coins := float(op["count"]) if op["count"] is int else 2.0
				match op["mode"]:
					"times", "times_tails": dmg = op["n"] * n_coins * 0.5
					"plus", "all_or_each": dmg += op["n"] * n_coins * 0.5
					"table", "set_table":
						var tb: Array = op["table"]
						var ev := 0.0
						var k_max := int(n_coins)
						for h in k_max + 1:
							var v = tb[mini(h, tb.size() - 1)]
							ev += _binom(k_max, h) / pow(2.0, k_max) * (0.0 if v is String else float(v))
						dmg = ev if op["mode"] == "set_table" else dmg + ev
			"until_tails":
				dmg = dmg + op["n"] if op.get("mode", "times") == "plus" else float(op["n"])
			"formula":
				if op["f"] in HIDDEN_FORMULAS:
					continue
				var x := AttackEffects._formula_value(g, op, ctx, me, opp, att, def)
				match op["mode"]:
					"times": dmg = op["n"] * x * w + dmg * (1.0 - w)
					"plus": dmg += mini(op["n"] * x, int(op.get("cap", 999))) * w
					"minus": dmg = maxf(0.0, dmg - op["n"] * x * w)
			"ignore":
				ign_w = ign_w or op.get("w", false)
				ign_r = ign_r or op.get("r", false)
	if dmg <= 0.0:
		return 0.0
	if not ign_w and att.types().any(func(t): return t in Abilities.weakness_types(g, def)):
		dmg *= 2.0
	if not ign_r and att.types().any(func(t): return t in def.data().get("resistances", [])):
		dmg -= 30.0
	return maxf(0.0, dmg)


static func _binom(n: int, k: int) -> float:
	var r := 1.0
	for i in k:
		r = r * (n - i) / (i + 1)
	return r
