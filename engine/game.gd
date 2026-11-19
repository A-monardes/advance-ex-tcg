class_name Game
extends RefCounted
## Motor de reglas. No sabe nada de pantallas ni de input: la UI, la IA y
## (más adelante) un servidor online usan la misma interfaz:
##
##   var g := Game.new(mazo_a, mazo_b, semilla)
##   g.start()
##   while g.phase != "over":
##       var acciones := g.legal_actions()   # para el jugador g.actor()
##       g.apply(acciones[elegida])
##
## Las acciones son Dictionary con una clave "t" (tipo). Con la misma semilla y
## las mismas acciones la partida se repite exactamente (repeticiones, red, tests).

signal changed

const TYPE_ES := {"Fire": "Fire", "Water": "Water", "Grass": "Grass", "Lightning": "Lightning", "Psychic": "Psychic",
		"Fighting": "Fighting", "Darkness": "Darkness", "Metal": "Metal", "Colorless": "Colorless"}
const COND_ES := {"asleep": "Asleep", "confused": "Confused", "paralyzed": "Paralyzed",
		"poisoned": "Poisoned", "burned": "Burned"}
const MAX_LOG := 400

var rules: RuleSet
var players: Array[PlayerState] = []
var rng := RandomNumberGenerator.new()
var current := 0
var first_player := 0
var turn_number := 0
var phase := "setup"            # setup | main | choice | over
var winner := -1                # 0, 1, o 2 = empate
var coin_winner := -1           # quién ganó la moneda inicial
## Estadísticas para la pantalla de resultados: daño de ataques y KO de cada jugador, y daño
## hecho por cada uno de sus Pokémon (clave: el Pokémon en juego; "id" es su carta de arriba).
var stats := [{"dmg": 0, "kos": 0, "by": {}}, {"dmg": 0, "kos": 0, "by": {}}]
var ask_first := false          # true: el ganador de la moneda elige si empieza (fase "first")
var win_reason := ""
var log_lines: Array[String] = []
var body_events: Array = []     # [PokemonInPlay, nombre]: Poké-Bodies que actuaron (para la mesa)
var coin_log: Array[bool] = []  # todas las monedas tiradas (para la animación)
var coin_reasons: Array[String] = []
var deck_log: Array = []        # [{"k": "shuffle"|"draw", "p", "ids"}] para las animaciones
var checkup_log: Array = []     # [{"p", "mon", "kind", "dmg"}] daño de veneno/quemadura entre turnos (para la mesa)
var checkup_mark := -1           # cuántos body_events había al empezar el chequeo (los de antes son del ataque)
var ko_log: Array = []          # [{"p", "slot", "id", "name"}] Pokémon fuera de combate, para la animación
var prize_log: Array = []       # [{"p", "id", "n", "of", "left"}] Premios tomados, para la animación
var evolve_log: Array = []      # [{"p", "mon", "from", "to"}] para la animación   # motivo de cada moneda: "", "burn", "sleep"
var sudden_death := 0           # cuántas veces se pasó a Muerte Súbita en este duelo
var sudden_death_enabled := true   # las copias de la IA no la juegan (cuentan el empate)
var _sudden_pending := false
var _decks: Array = []          # mazos originales (para la Muerte Súbita)
var stadium := ""               # carta de Estadio en juego
var stadium_owner := -1

var _setup_player := 0
var _choices: Array = []        # [{"p", "kind": "promote"|"switch"|"ask", "prompt", "options", "cb"}]
var _after_choices := ""        # "end_turn" | "next_turn" | ""
var _insert_pos := -1           # para que las preguntas encadenadas vayan primero
## Batallas dobles: qué jugadores tienen ahora los Activos intercambiados (el segundo Activo
## puesto en el lugar del primero) mientras se resuelve una acción. Así todo el texto de las
## cartas ("your Active Pokémon", "the Defending Pokémon") vale para el que actúa o recibe.
var _ctx := [false, false]


func _init(deck_a: Array[String], deck_b: Array[String], seed_value: int = 0, rule_set: RuleSet = null) -> void:
	rules = rule_set if rule_set != null else RuleSet.ex_2005()
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	_decks = [deck_a.duplicate(), deck_b.duplicate()]
	for i in 2:
		var p := PlayerState.new()
		p.index = i
		p.deck_log = deck_log
		p.deck = (deck_a if i == 0 else deck_b).duplicate()
		players.append(p)


## Copia de la partida para que la IA simule jugadas. Con viewer >= 0 la copia solo
## "sabe" lo que ese jugador sabe: se mezclan su mazo y sus Premios, y la mano del rival
## se reparte al azar entre las cartas que no ve; además cambia la semilla, así no sabe
## qué saldrá en las monedas. Las elecciones pendientes no se copian.
func clone(viewer: int = -1) -> Game:
	var hide := viewer >= 0
	var empty: Array[String] = []
	var c := Game.new(empty, empty, 1, rules.copy())
	c._bench_before_stump = _bench_before_stump
	c.rng.seed = rng.seed
	c.rng.state = rng.state
	if hide:
		c.rng.randomize()
	c.current = current
	c.first_player = first_player
	c.coin_winner = coin_winner
	c.stats = stats.duplicate(true)
	c.turn_number = turn_number
	c.phase = phase if phase != "choice" else "main"
	c.winner = winner
	c.win_reason = win_reason
	c.sudden_death = sudden_death
	c.sudden_death_enabled = false
	c.stadium = stadium
	c.stadium_owner = stadium_owner
	c._setup_player = _setup_player
	for i in 2:
		var src := players[i]
		var p := c.players[i]
		p.deck = src.deck.duplicate()
		p.hand = src.hand.duplicate()
		p.discard = src.discard.duplicate()
		p.prizes = src.prizes.duplicate()
		p.active = src.active.copy() if src.active != null else null
		p.active2 = src.active2.copy() if src.active2 != null else null
		var b: Array[PokemonInPlay] = []
		for x in src.bench:
			b.append(x.copy() if x != null else null)
		p.bench = b
		p.turns_taken = src.turns_taken
		p.mulligans = src.mulligans
		p.mull_bonus = src.mull_bonus
		p.mull_hands = src.mull_hands.duplicate(true)
		p.energy_attached = src.energy_attached
		p.supporter_played = src.supporter_played
		p.flags = src.flags.duplicate()
		p.stadium_played = src.stadium_played
		p.retreated = src.retreated
		p.turn_flags = src.turn_flags.duplicate(true)
		if hide:
			# Cartas que el que mira no conoce: mazo y Premios (y la mano, si es del rival)
			var pool: Array[String] = p.deck.duplicate()
			pool.append_array(p.prizes)
			var hand_n := p.hand.size()
			if i != viewer:
				pool.append_array(p.hand)
			c.shuffle(pool)
			var np := p.prizes.size()
			p.prizes = pool.slice(0, np)
			if i != viewer:
				p.hand = pool.slice(np, np + hand_n)
				p.deck = pool.slice(np + hand_n)
			else:
				p.deck = pool.slice(np)
	c.deck_log.clear()
	return c


# ===========================================================================
# Batallas dobles: contexto
# ===========================================================================

func is_doubles() -> bool:
	return rules.doubles


## Pone los Activos de cada jugador en el orden pedido (want[i] = true: el segundo Activo
## del jugador i ocupa el lugar del primero).
func set_ctx(want: Array) -> void:
	for i in 2:
		if bool(_ctx[i]) != bool(want[i]):
			players[i].swap_actives()
			_ctx[i] = bool(want[i])


## Ejecuta f con los Activos ordenados según ctx y después los deja como estaban.
func with_ctx(ctx, f: Callable) -> void:
	if ctx == null or not (ctx is Array) or (not ctx[0] and not ctx[1]):
		f.call()
		return
	var prev: Array = _ctx.duplicate()
	set_ctx(ctx)
	f.call()
	set_ctx(prev)


## Contextos posibles para el jugador que actúa (me) y su rival: [me_cambiado, rival_cambiado]
## indexado por jugador. Solo se cambia si hay segundo Activo.
func _ctx_list(me: PlayerState, with_opp: bool) -> Array:
	var out: Array = []
	var opp := other(me)
	for ms in ([false, true] if me.active2 != null else [false]):
		for os in ([false, true] if with_opp and opp.active2 != null else [false]):
			var c := [false, false]
			c[me.index] = ms
			c[opp.index] = os
			out.append(c)
	return out


func has_pending_choices() -> bool:
	return not _choices.is_empty()


# ===========================================================================
# Consultas
# ===========================================================================

func current_player() -> PlayerState:
	return players[current]


func opponent_player() -> PlayerState:
	return players[1 - current]


func other(p: PlayerState) -> PlayerState:
	return players[1 - p.index]


func owner_of(mon: PokemonInPlay) -> PlayerState:
	for pl in players:
		if mon == pl.active or mon in pl.bench:
			return pl
	return players[0]


func stadium_name() -> String:
	return CardDB.card_name(stadium) if stadium != "" else ""


## Jugador que tiene que decidir ahora (-1 si terminó la partida).
func actor() -> int:
	match phase:
		"setup": return _setup_player
		"first": return coin_winner
		"choice": return _choices[0]["p"]
		"main": return current
	return -1


func pending_choice_kind() -> String:
	return _choices[0]["kind"] if phase == "choice" else ""


func pending_prompt() -> String:
	if phase != "choice":
		return ""
	match _choices[0]["kind"]:
		"promote": return "New Active Pokémon"
		"promote2": return "Second Active Pokémon"
		"switch": return "Switch Active Pokémon"
	return _choices[0]["prompt"]


static func validate_deck(deck: Array[String], r: RuleSet = null) -> Array[String]:
	if r == null:
		r = RuleSet.ex_2005()
	var errors: Array[String] = []
	if deck.size() != r.deck_size:
		errors.append("The deck has %d cards (it must have %d)." % [deck.size(), r.deck_size])
	var counts := {}
	var stars := 0
	var basics := 0
	for id in deck:
		if CardDB.get_card(id).is_empty():
			errors.append("Unknown card: " + id)
			continue
		if CardDB.is_basic_pokemon(id):
			basics += 1
		if CardDB.is_star(id):
			stars += 1
		if not CardDB.is_basic_energy(id):
			var n := CardDB.card_name(id)
			counts[n] = counts.get(n, 0) + 1
	for n in counts:
		if counts[n] > r.max_copies:
			errors.append("More than %d copies of %s." % [r.max_copies, n])
	if stars > 1:
		errors.append("Only 1 Pokémon Star is allowed per deck.")
	var bad := r.illegal_cards(deck)
	if not bad.is_empty():
		var shown: Array = bad.slice(0, 3).map(func(c): return "%s (%s)" % [CardDB.card_name(c), CardDB.set_of(c)])
		errors.append("Not legal in %s: %s%s." % [r.season, ", ".join(shown), " and %d more" % (bad.size() - 3) if bad.size() > 3 else ""])
	if basics == 0:
		errors.append("The deck needs at least one Basic Pokémon.")
	return errors


# ===========================================================================
# Inicio de partida
# ===========================================================================

## Moneda inicial. Según la época (ver RuleSet.coin_winner_chooses): hasta 2003 el que
## gana la moneda empieza; en 2004-2005 el que la gana elige si empieza o no. Con
## ask_first = true esa elección es una acción ("first"); si no, el ganador empieza.
func start() -> void:
	for p in players:
		shuffle(p.deck)
	coin_winner = 0 if rng.randi() % 2 == 0 else 1
	if rules.coin_winner_chooses and ask_first:
		log_msg("Opening coin flip: Player %d wins and chooses who goes first." % (coin_winner + 1))
		phase = "first"
		changed.emit()
		return
	_deal(coin_winner)


## Reparte las manos (con mulligans) y empieza la preparación.
func _deal(first: int) -> void:
	first_player = first
	log_msg("Opening coin flip: Player %d goes first." % (first_player + 1))
	for p in players:
		p.draw(rules.hand_size)
		while not p.hand.any(func(c): return CardDB.is_basic_pokemon(c)):
			p.mulligans += 1
			p.mull_hands.append(p.hand.duplicate())     # se muestra al rival antes de barajar
			log_msg("Player %d has no Basic Pokémon: mulligan." % (p.index + 1))
			p.deck.append_array(p.hand)
			p.hand.clear()
			shuffle(p.deck)
			p.draw(rules.hand_size)
	for p in players:
		# Por cada mulligan del rival se puede robar 1 carta extra: el jugador elige cuántas (al empezar su preparación).
		p.mull_bonus = mini(other(p).mulligans, p.deck.size())
	phase = "setup"
	_setup_player = first_player
	changed.emit()


# ===========================================================================
# Acciones legales
# ===========================================================================

func legal_actions() -> Array:
	match phase:
		"first": return [{"t": "first", "me": true}, {"t": "first", "me": false}]
		"setup": return _setup_actions()
		"choice": return _choice_actions()
		"main": return _main_actions()
	return []


func _setup_actions() -> Array:
	var me := players[_setup_player]
	var out: Array = []
	if me.mull_bonus > 0:
		for n in range(me.mull_bonus, -1, -1):
			out.append({"t": "mull_draw", "n": n})
		return out
	var seen := {}
	for h in me.hand.size():
		var id := me.hand[h]
		if not CardDB.is_basic_pokemon(id) or seen.has(id):
			continue
		seen[id] = true
		if me.active == null:
			out.append({"t": "setup_active", "h": h})
		else:
			if rules.doubles and me.active2 == null:
				out.append({"t": "setup_active2", "h": h})
			if me.bench.size() < rules.bench_size:
				out.append({"t": "setup_bench", "h": h})
	if me.active != null:
		out.append({"t": "setup_done"})
	return out


func _choice_actions() -> Array:
	var c: Dictionary = _choices[0]
	var out: Array = []
	if c["kind"] == "ask":
		for i in c["options"].size():
			out.append({"t": "choose", "i": i})
		return out
	var p := players[c["p"]]
	for b in p.bench.size():
		out.append({"t": "choose", "b": b})
		if c["kind"] == "switch" and p.active2 != null:
			out.append({"t": "choose", "b": b, "act": PlayerState.ACTIVE2})   # cambiar el segundo Activo
	return out


func _main_actions() -> Array:
	var me := current_player()
	var opp := opponent_player()
	var out: Array = []
	var seen := {}
	for h in me.hand.size():
		var id := me.hand[h]
		if seen.has(id):
			continue
		seen[id] = true
		if CardDB.is_playable_basic(id):
			if me.bench.size() < rules.bench_size and (CardDB.is_basic_pokemon(id) or _can_play_trainer(me, id)):
				out.append({"t": "bench", "h": h})
		elif CardDB.is_evolution(id):
			if me.turns_taken > 1:
				for s in me.slots():
					var p := me.slot(s)
					if CardDB.evolves_onto(id, p.display_name()) and p.turn_played < turn_number \
							and not (s == -1 and Abilities.evolve_active_blocked(self, me)) \
							and not (not PlayerState.is_active_slot(s) and Abilities.evolve_bench_blocked(self)):
						out.append({"t": "evolve", "h": h, "tg": s})
		elif CardDB.is_energy(id):
			if not me.energy_attached:
				for s in me.slots():
					var p := me.slot(s)
					if Energy.can_attach(id, p) and p.flags.get("no_attach", -1) < turn_number \
							and Abilities.can_attach_from_hand(self, id, p):
						out.append({"t": "energy", "h": h, "tg": s})
		elif CardDB.is_trainer(id) and _can_play_trainer(me, id):
			for prm in Trainers.options(self, me, h):
				out.append({"t": "trainer", "h": h, "p": prm})
			if me.active2 != null and Trainers.uses_active(id):
				# Dobles: la misma carta sobre el segundo Activo
				var c2 := [false, false]
				c2[me.index] = true
				with_ctx(c2, func():
					for prm in Trainers.options(self, me, h):
						out.append({"t": "trainer", "h": h, "p": prm, "ctx": c2}))
	# Pokémon Holon's: también se pueden unir como Energía desde la mano
	if not me.energy_attached:
		var seen_h := {}
		for h in me.hand.size():
			var hid := me.hand[h]
			if CardDB.is_holon_energy(hid) and not seen_h.has(hid):
				seen_h[hid] = true
				for s in me.slots():
					var hp := me.slot(s)
					if Energy.can_attach(hid, hp) and hp.flags.get("no_attach", -1) < turn_number and Abilities.can_attach_from_hand(self, hid, hp):
						out.append({"t": "energy", "h": h, "tg": s})
	out.append_array(Abilities.power_actions(self, me))
	if me.active2 != null:
		# Poké-Powers del segundo Activo: se calculan con él en el lugar del Activo
		var c2 := [false, false]
		c2[me.index] = true
		with_ctx(c2, func():
			for pa in Abilities.power_actions(self, me):
				if pa["s"] == -1:
					pa["ctx"] = c2
					out.append(pa))
		out = out.filter(func(x): return not (x["t"] == "power" and x["s"] == PlayerState.ACTIVE2 and not x.has("ctx")))
	# Dobles: mandar un Pokémon de la Banca al lugar vacío de Activo
	if rules.doubles and me.active2 == null and me.active != null:
		for b in me.bench.size():
			out.append({"t": "send_out", "b": b})
	# Retirada y ataques: con cada Activo propio (y cada Activo del rival como objetivo)
	for c in _ctx_list(me, false):
		with_ctx(c, func(): out.append_array(_tag(_retreat_actions(me), c)))
	for c in _ctx_list(me, true):
		with_ctx(c, func(): out.append_array(_tag(_attack_actions(me, opp), c)))
	out.append({"t": "end"})
	return out


func _tag(actions: Array, c: Array) -> Array:
	if c[0] or c[1]:
		for x in actions:
			x["ctx"] = c
	return actions


func _retreat_actions(me: PlayerState) -> Array:
	var out: Array = []
	var a := me.active
	if a != null and not me.retreated and not me.bench.is_empty() and Abilities.can_retreat(self, me, a) \
			and a.flags.get("cant_retreat", -1) < turn_number \
			and (Energy.total(a) >= Abilities.retreat_cost(self, me, a) or CardDB.card_name(a.tool) == "Balloon Berry"):
		for b in me.bench.size():
			out.append({"t": "retreat", "b": b})
	return out


func _attack_actions(me: PlayerState, opp: PlayerState) -> Array:
	var out: Array = []
	var a := me.active
	if a != null and opp.active != null and (can_attack(a) or a.rotation == "asleep" and _can_attack_ignoring_sleep(a)):
		var attacks := a.attacks()
		for i in attacks.size():
			if not attack_usable(a, attacks[i]):
				continue
			if a.rotation == "asleep" and not usable_asleep(attacks[i]):
				continue
			var parsed := AttackEffects.parse(a.top(), attacks[i])
			var targets: Array = [-2]
			match parsed["target"]:
				"any":
					targets = opp.slots()
				"bench":
					if not opp.bench.is_empty():
						targets = range(opp.bench.size())
				"bench_undamaged":
					var ok_u: Array = range(opp.bench.size()).filter(func(b): return opp.bench[b].damage == 0)
					if not ok_u.is_empty():
						targets = ok_u
				"any_power", "any_body":
					var kind: String = "Poké-Power" if parsed["target"] == "any_power" else "Poké-Body"
					var ok_k: Array = opp.slots().filter(func(s2): return opp.slot(s2).abilities().any(func(ab): return ab["kind"] == kind))
					if ok_k.is_empty():
						continue
					targets = ok_k
				"any_damaged":
					var ok_d: Array = opp.slots().filter(func(s2): return opp.slot(s2).damage > 0)
					if not ok_d.is_empty():
						targets = ok_d
				"shock":
					var ok_s: Array = opp.slots().filter(func(s2): return opp.slot(s2).flags.get("shock_wave", false))
					if ok_s.is_empty():
						continue
					targets = ok_s
				"bench_team":
					var team: String = parsed.get("team", "")
					var ok_b: Array = range(opp.bench.size()).filter(func(b): return opp.bench[b].name_has(team))
					if not ok_b.is_empty():
						targets = ok_b
			if parsed["variable"].get("k", "") == "genetic_memory":
				# Una opción por cada ataque de las cartas que tiene debajo (y su objetivo, si elige uno)
				for ci in a.cards.size() - 1:
					var under: String = a.cards[ci]
					if not CardDB.is_pokemon(under):
						continue
					var under_atks: Array = CardDB.get_card(under).get("attacks", [])
					for j in under_atks.size():
						var ip := AttackEffects.parse(under, under_atks[j])
						var its: Array = [-2]
						if ip["target"] == "any":
							its = opp.slots()
						elif ip["target"] == "bench" and not opp.bench.is_empty():
							its = range(opp.bench.size())
						for tg in its:
							out.append({"t": "attack", "a": i, "tg": tg, "opt": {"gm_card": under, "gm_a": j}})
							if ip["optional"]:
								out.append({"t": "attack", "a": i, "tg": tg, "opt": {"gm_card": under, "gm_a": j, "gm_opt": true}})
				continue
			if parsed["variable"].get("k", "") == "copy_def":
				# Copy / Metronome: una opción por cada ataque del Pokémon Defensor (Rainbow Moves: de
				# la Banca del rival; Dark Link: de tus Pokémon "Dark")
				var srcs: Array = [opp.active.top()]
				match parsed["variable"].get("src", ""):
					"opp_bench": srcs = opp.bench.map(func(x): return x.top())
					"my_dark": srcs = me.all_in_play().filter(func(x): return x != a and x.name_has("Dark")).map(func(x): return x.top())
					"opp_all": srcs = opp.all_in_play().map(func(x): return x.top())
					"opp_delta": srcs = opp.all_in_play().filter(func(x): return CardDB.is_delta(x.top())).map(func(x): return x.top())
					"opp_hand": srcs = opp.hand.filter(func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c))
					"my_hand": srcs = me.hand.filter(func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c))
				var seen_src := {}
				for dcard in srcs:
					if seen_src.has(dcard):
						continue
					seen_src[dcard] = true
					var datks: Array = CardDB.get_card(dcard).get("attacks", []) if CardDB.is_pokemon(dcard) else []
					for j in datks.size():
						if parsed["variable"].get("needs_energy", false) and not attack_usable(a, datks[j]):
							continue
						var ip := AttackEffects.parse(dcard, datks[j])
						if ip["variable"].get("k", "") in ["copy_def", "genetic_memory"]:
							continue
						var its: Array = [-2]
						if ip["target"] == "any":
							its = opp.slots()
						elif ip["target"] == "bench" and not opp.bench.is_empty():
							its = range(opp.bench.size())
						for tg in its:
							out.append({"t": "attack", "a": i, "tg": tg, "opt": {"cp_card": dcard, "cp_a": j}})
				continue
			if parsed["variable"].get("k", "") == "hand_pick":
				# Dark Marowak (Hard Bone): qué Pokémon de la mano se descarta
				for c in Trainers._distinct(me.hand, func(c): return CardDB.is_pokemon(c)):
					out.append({"t": "attack", "a": i, "tg": -2, "opt": c})
				continue
			for tg in targets:
				if parsed["variable"].get("k", "") == "rainbow_wave":
					# Mew ★ (Rainbow Wave): una opción por cada tipo de Energía básica que tiene unida
					var tys := {}
					for e in a.energy:
						if CardDB.is_basic_energy(e):
							tys[CardDB.basic_energy_type(e)] = true
					for t in tys:
						out.append({"t": "attack", "a": i, "tg": tg, "opt": t})
					if tys.is_empty():
						out.append({"t": "attack", "a": i, "tg": tg, "opt": ""})
					continue
				if parsed["variable"].get("k", "") == "burst_choice":
					# Dragon Burst: una opción por cada tipo que tenga Energías para descartar
					var any := false
					for t in parsed["variable"]["types"]:
						if a.energy.any(func(e): return AttackEffects.burst_counts(e, t)):
							out.append({"t": "attack", "a": i, "tg": tg, "opt": t})
							any = true
					if not any:
						out.append({"t": "attack", "a": i, "tg": tg, "opt": ""})
					continue
				if not parsed["variable"].is_empty():
					# Una opción por cada cantidad de Energías (0, 1, 2...)
					var n := AttackEffects.any_energy_cards(me, a, parsed["variable"]).size()
					for k in n + 1:
						out.append({"t": "attack", "a": i, "tg": tg, "opt": k})
					continue
				out.append({"t": "attack", "a": i, "tg": tg, "opt": false})
				if parsed["optional"]:
					out.append({"t": "attack", "a": i, "tg": tg, "opt": true})
	return out


## Snorlax (Toss and Turn): ataques que dicen que se pueden usar aunque esté Dormido.
static func usable_asleep(atk: Dictionary) -> bool:
	var t := str(atk.get("text", ""))
	return t.contains("can be used even if") and t.contains("Asleep")


func _can_attack_ignoring_sleep(a: PokemonInPlay) -> bool:
	if not a.attacks().any(func(x): return usable_asleep(x)):
		return false
	var r := a.rotation
	a.rotation = ""
	var ok := can_attack(a)
	a.rotation = r
	return ok


func can_attack(a: PokemonInPlay) -> bool:
	return a.rotation not in ["asleep", "paralyzed"] and a.flags.get("cant_attack", -1) < turn_number \
			and not Abilities.attack_blocked(self, a) and not a.is_fossil()


func attack_usable(a: PokemonInPlay, atk: Dictionary) -> bool:
	var cost: Array = Abilities.attack_cost(self, a, atk)
	for i in Abilities.extra_attack_cost(self, a):
		cost.append("Colorless")
	if not Energy.can_pay(a, cost):
		return false
	var dis = a.flags.get("disabled_attack", null)
	if dis != null and dis[0] == atk["name"] and dis[1] >= turn_number:
		return false
	if a.flags.get("no_attack_" + str(atk["name"]), -1) >= turn_number:
		return false
	return true


func _can_play_trainer(me: PlayerState, id: String) -> bool:
	if not Trainers.is_implemented(id):
		return false
	if me.flags.get("no_trainers", -1) >= turn_number:          # Psyduck, Electrike
		return false
	if me.flags.get("no_items", -1) >= turn_number and not CardDB.is_supporter(id):     # Manectric ex
		return false
	if CardDB.is_stadium(id) and Abilities.active_body(self, other(me), "Commanding Aura"):
		return false
	if CardDB.is_stadium(id) and stadium_name().contains("Holon") and Abilities.body_in_play(self, other(me), "Delta Block"):
		return false
	if CardDB.is_tm(id) and Abilities.body_anywhere(self, "Mystic Scale"):
		return false
	if CardDB.is_supporter(id):
		if me.supporter_played or Abilities.supporters_blocked(self) or me.flags.get("no_supporter", -1) >= turn_number:
			return false
		if turn_number == 1 and not rules.first_player_supporter:
			return false
		return true
	if Abilities.items_blocked(self, me):
		return false
	if CardDB.is_pokemon_tool(id) and Abilities.tools_blocked(self, me):
		return false
	if CardDB.is_stadium(id) and me.stadium_played:
		return false
	return true


# ===========================================================================
# Aplicar acciones
# ===========================================================================

func apply(a: Dictionary) -> void:
	_apply(a)
	if _sudden_pending:
		_sudden_pending = false
		_start_sudden_death()
		changed.emit()


func _apply(a: Dictionary) -> void:
	assert(phase != "over", "The game is already over")
	match a["t"]:
		"setup_active", "setup_active2", "setup_bench":
			var me := players[_setup_player]
			var id: String = me.hand[a["h"]]
			me.hand.remove_at(a["h"])
			var p := PokemonInPlay.new(id, 0)
			if a["t"] == "setup_active":
				me.active = p
			elif a["t"] == "setup_active2":
				me.active2 = p
			else:
				me.bench.append(p)
		"mull_draw":
			var me := players[_setup_player]
			me.mull_bonus = 0
			me.draw(a["n"])
			log_msg("Player %d draws %d extra card(s) for the mulligan." % [me.index + 1, a["n"]])
		"first":
			_deal(coin_winner if a["me"] else 1 - coin_winner)
		"setup_done":
			if _setup_player == first_player:
				_setup_player = 1 - first_player
			else:
				_finish_setup()
		"choose":
			var c: Dictionary = _choices.pop_front()
			var p := players[c["p"]]
			match c["kind"]:
				"promote":
					p.active = p.bench[a["b"]]
					p.bench.remove_at(a["b"])
					log_msg("Player %d sends out %s." % [p.index + 1, p.active.display_name()])
				"promote2":
					p.active2 = p.bench[a["b"]]
					p.bench.remove_at(a["b"])
					log_msg("Player %d sends out %s." % [p.index + 1, p.active2.display_name()])
				"switch":
					if a.get("act", -1) == PlayerState.ACTIVE2:
						var c2 := [false, false]
						c2[p.index] = true
						with_ctx(c2, func(): switch_active(p, a["b"]))
					else:
						switch_active(p, a["b"])
				"ask":
					var opt: Dictionary = c["options"][a["i"]]
					_insert_pos = 0
					with_ctx(c.get("ctx", null), func(): c["cb"].call(opt))
					_insert_pos = -1
			_check_knockouts()
			if phase != "over":
				_continue_after_choices()
		"bench":
			var me := current_player()
			var id: String = me.hand[a["h"]]
			me.hand.remove_at(a["h"])
			var p := PokemonInPlay.new(id, turn_number)
			me.bench.append(p)
			log_msg("Player %d puts %s on the Bench." % [me.index + 1, CardDB.card_name(id)])
			Abilities.on_basic_played(self, p)
			Abilities.on_bench_from_hand(self, me, p)
		"evolve":
			var me := current_player()
			var id: String = me.hand[a["h"]]
			me.hand.remove_at(a["h"])
			evolve(me, me.slot(a["tg"]), id)
			Abilities.on_evolve_from_hand(self, me, me.slot(a["tg"]), a["tg"])
		"energy":
			var me := current_player()
			var id: String = me.hand[a["h"]]
			me.hand.remove_at(a["h"])
			var p := me.slot(a["tg"])
			p.energy.append(id)
			me.energy_attached = true
			if p == me.active:
				me.turn_flags["attach_active"] = true      # Harvest Bounty (Venusaur)
			log_msg("Player %d attaches %s to %s." % [me.index + 1, CardDB.card_name(id), p.display_name()])
			Abilities.on_energy_from_hand(self, me, p, id)
		"trainer":
			var me := current_player()
			var id: String = me.hand[a["h"]]
			me.hand.remove_at(a["h"])
			if CardDB.is_supporter(id):
				me.supporter_played = true
				me.turn_flags["supporter_id"] = id      # Magby (Detour)
			if CardDB.is_stadium(id):
				me.stadium_played = true
			log_msg("Player %d plays %s." % [me.index + 1, CardDB.card_name(id)])
			with_ctx(a.get("ctx", null), func(): Trainers.play(self, me, id, a["p"]))
			if not (CardDB.is_pokemon_tool(id) or CardDB.is_tm(id) or CardDB.is_stadium(id)):
				me.discard.append(id)
		"power":
			with_ctx(a.get("ctx", null), func(): Abilities.use_power(self, current_player(), a["s"], a["n"], a["p"]))
			var pw := current_player()
			if pw.turn_flags.get("end_turn_after", false):
				# Energy Recycle, Fellow Boost: "...y tu turno termina" (después de las elecciones)
				pw.turn_flags.erase("end_turn_after")
				Abilities.refresh(self)
				_check_knockouts()
				if phase == "over":
					return
				_prune_choices()
				if not _choices.is_empty():
					_after_choices = "end_turn"
					phase = "choice"
				else:
					log_msg("Player %d's turn ends." % (current + 1))
					_end_turn()
				changed.emit()
				return
		"retreat":
			with_ctx(a.get("ctx", null), func(): _retreat(current_player(), a["b"]))
		"send_out":
			var me := current_player()
			me.active2 = me.bench[a["b"]]
			me.bench.remove_at(a["b"])
			log_msg("Player %d sends out %s." % [me.index + 1, me.active2.display_name()])
		"attack":
			_attack(a["a"], a["tg"], a.get("opt", false), a.get("ctx", null))
		"end":
			log_msg("Player %d ends their turn." % (current + 1))
			_end_turn()
	if phase == "main":
		Abilities.refresh(self)
		_check_knockouts()
		if phase == "main":
			_prune_choices()
			if not _choices.is_empty():
				phase = "choice"
	changed.emit()


func _finish_setup() -> void:
	for p in players:
		for i in rules.prizes:
			if not p.deck.is_empty():
				p.prizes.append(p.deck.pop_back())
	log_msg("Prize cards are set. The duel begins!")
	current = first_player
	_begin_turn()


func _begin_turn() -> void:
	var me := current_player()
	turn_number += 1
	me.turns_taken += 1
	me.reset_turn_limits()
	phase = "main"
	Abilities.refresh(self)
	log_msg("— Turn %d: Player %d —" % [turn_number, current + 1])
	if turn_number == 1 and not rules.first_player_draws:
		return
	if me.deck.is_empty():
		_game_over(1 - current, "Player %d can't draw a card." % (current + 1))
		return
	me.draw(1)


func _attack(index: int, target: int, opt, ctx = null) -> void:
	with_ctx(ctx, func(): _resolve_attack(index, target, opt))
	_check_knockouts()
	if phase == "over":
		return
	_prune_choices()
	if not _choices.is_empty():
		_after_choices = "end_turn"
		phase = "choice"
	else:
		_end_turn()


## El ataque en sí (con los Activos ya ordenados: el que ataca y el que defiende en el
## lugar de "el" Activo de cada uno).
func _resolve_attack(index: int, target: int, opt) -> void:
	var me := current_player()
	var attacker := me.active
	var atk: Dictionary = attacker.attacks()[index]
	if rules.doubles and other(me).active != null:
		log_msg("%s uses %s on %s." % [attacker.display_name(), atk["name"], other(me).active.display_name()])
	else:
		log_msg("%s uses %s." % [attacker.display_name(), atk["name"]])
	var does_nothing := false
	if attacker.rotation == "confused" and not flip():
		attacker.damage += rules.confusion_self_damage
		log_msg("  It's Confused and hurts itself for %d damage!" % rules.confusion_self_damage)
		does_nothing = true
	elif attacker.flags.get("smokescreen", -1) >= turn_number and not flip():
		log_msg("  The attack failed.")
		does_nothing = true
	elif attacker.is_basic() and not attacker.is_fossil() and Abilities.active_body(self, other(me), "Pattern Distraction") and not flip():
		log_msg("  Pattern Distraction: the attack does nothing.")
		does_nothing = true
	attacker.flags["attacked_turn"] = turn_number
	if stadium_name() == "Holon Circle" and not does_nothing:
		log_msg("  Holon Circle: the attack ends.")
		discard_stadium()
		does_nothing = true
	if atk.get("psymimic", false):
		attacker.power_used_turn = turn_number
		log_msg("  Psymimic: copies %s from %s." % [atk["name"], CardDB.card_name(atk["src"])])
	if not does_nothing:
		AttackEffects.resolve(self, attacker, atk, target, opt, str(atk.get("src", "")))


func _end_turn() -> void:
	var me := current_player()
	# Cartas que se descartan al final del turno propio
	for p in me.all_in_play():
		if p.tm != "":
			me.discard.append(p.tm)
			p.tm = ""
		if CardDB.card_name(p.tool) in ["Memory Berry", "Crystal Shard"] and p.flags.get("attacked_turn", -1) == turn_number:
			log_msg("  %s is discarded from %s." % [CardDB.card_name(p.tool), p.display_name()])
			me.discard.append(p.tool)
			p.tool = ""
		for i in range(p.energy.size() - 1, -1, -1):
			if CardDB.card_name(p.energy[i]) in ["Aqua Energy", "Magma Energy", "R Energy"]:
				me.discard.append(p.energy[i])
				p.energy.remove_at(i)
		if p.flags.get("discard_tool", -1) == turn_number and p.tool != "":
			me.discard.append(p.tool)
			p.tool = ""
	for pl in players:
		for p in pl.all_in_play():
			var ds = p.flags.get("delayed_status", null)
			if ds != null and ds[1] == turn_number:
				try_condition(p, ds[0])
				p.flags.erase("delayed_status")
			var dc = p.flags.get("delayed_counters", null)
			if dc != null and dc[1] == turn_number:
				p.damage += 10 * int(dc[0])
				log_msg("  %d damage counters on %s." % [int(dc[0]), p.display_name()])
				p.flags.erase("delayed_counters")
			# Boost Energy se descarta al final del turno en que se unió (y si deja de estar evolucionado).
			for i in range(p.energy.size() - 1, -1, -1):
				if CardDB.card_name(p.energy[i]) == "Boost Energy":
					pl.discard.append(p.energy[i])
					p.energy.remove_at(i)
			if CardDB.card_name(p.tool) in ["Buffer Piece", "Weakness Guard"] and pl.index != current and p.tool_turn < turn_number:
				pl.discard.append(p.tool)
				p.tool = ""
	if stadium_name() == "Championship Arena" and me.hand.size() >= 8:
		var extra := me.hand.size() - 7
		Trainers.chain(self, me.index, "Championship Arena: discard down to 7", extra,
				func(_p): return Trainers._distinct(me.hand, func(_c): return true), false,
				func(cid):
					me.hand.erase(cid)
					me.discard.append(cid),
				func(): pass)
	_checkup()
	_check_knockouts()
	if phase == "over":
		return
	current = 1 - current
	_prune_choices()
	if not _choices.is_empty():
		_after_choices = "next_turn"
		phase = "choice"
	else:
		_begin_turn()


## Chequeo entre turnos: veneno, quemadura, sueño, parálisis y efectos de cartas.
func _checkup() -> void:
	# Cómo estaba cada Activo justo antes del chequeo (la mini batalla separa así lo que
	# le hizo el ataque, como Rough Skin, del veneno o la quemadura de entre turnos)
	checkup_mark = body_events.size()
	for p in players:
		for a in p.actives():
			a.flags["pre_checkup"] = [turn_number, a.damage, a.conditions_text()]
	for p in players:
		for a in p.actives():
			_checkup_one(p, a)
	Abilities.between_turns(self)


func _checkup_one(p: PlayerState, a: PokemonInPlay) -> void:
	if true:
		if a.poison > 0:
			a.damage += 10 * a.poison
			log_msg("  %s takes %d Poison damage." % [a.display_name(), 10 * a.poison])
			checkup_log.append({"p": p.index, "mon": a, "kind": "poison", "dmg": 10 * a.poison})
		if a.burned and not flip("burn"):
			var bd := Abilities.burn_damage(self, rules.burn_damage)
			a.damage += bd
			log_msg("  %s takes %d Burn damage." % [a.display_name(), bd])
			checkup_log.append({"p": p.index, "mon": a, "kind": "burn", "dmg": bd})
		if a.rotation == "asleep" and Abilities.wake_up(self, a):
			a.rotation = ""
			log_msg("  %s woke up." % a.display_name())
		elif a.rotation == "paralyzed" and p.index == current and a.rotation_turn < turn_number:
			a.rotation = ""
			log_msg("  %s is no longer Paralyzed." % a.display_name())


func _check_knockouts() -> void:
	var prize_win := [false, false]
	var ko2 := [false, false]        # dobles: cayó el segundo Activo
	for p in players:
		for s in p.slots():
			var mon := p.slot(s)
			if mon == null or mon.hp_left() > 0:
				continue
			if mon.flags.get("time_travel", -1) == turn_number:
				# Time Travel (Celebi ★): no queda KO; sus cartas unidas al descarte y él al fondo del mazo
				var star := mon.top()
				var rest := mon.all_cards()
				rest.erase(star)
				p.discard.append_array(rest)
				p.deck.push_front(star)
				log_msg("  %s is not Knocked Out and goes to the bottom of the deck." % mon.display_name())
				if s == -1:
					p.active = null
				elif s == PlayerState.ACTIVE2:
					p.active2 = null
				else:
					p.bench[s] = null
				continue
			log_msg("%s is Knocked Out!" % mon.display_name())
			ko_log.append({"p": p.index, "slot": s, "id": mon.top(), "name": mon.display_name()})
			var cards := mon.all_cards()
			if CardDB.card_name(mon.tool) == "Time Shard" and current != p.index:
				# Time Shard: hasta 2 Energías básicas vuelven a la mano
				var back := 0
				for e in mon.energy.duplicate():
					if back < 2 and CardDB.is_basic_energy(e):
						cards.erase(e)
						p.hand.append(e)
						back += 1
				if back > 0:
					log_msg("  Time Shard: %d basic Energy card(s) go back to the hand." % back)
			p.discard.append_array(cards)
			if s == -1:
				p.active = null
			elif s == PlayerState.ACTIVE2:
				p.active2 = null
				ko2[p.index] = true
			else:
				p.bench[s] = null
			if mon.is_fossil():
				continue    # los Fósiles no cuentan como Pokémon KO
			var taker := other(p)
			stats[taker.index]["kos"] += 1
			var n: int = min(2 if mon.is_ex() else 1, taker.prizes.size())
			if Abilities.body(self, mon, "Empty Shell"):
				n = 0
			for i in n:
				var prize: String = taker.prizes.pop_back()
				taker.hand.append(prize)
				prize_log.append({"p": taker.index, "id": prize, "n": i + 1, "of": n, "left": taker.prizes.size()})
			log_msg("  Player %d takes %d Prize card(s)." % [taker.index + 1, n])
			if taker.prizes.is_empty():
				prize_win[taker.index] = true
			Abilities.on_knocked_out(self, p, cards)
		var kept: Array[PokemonInPlay] = []
		for x in p.bench:
			if x != null:
				kept.append(x)
		p.bench = kept
		# Dobles: si cayó el primer Activo y no hay Banca, el segundo pasa a su lugar
		if p.active == null and p.active2 != null and p.bench.is_empty():
			p.active = p.active2
			p.active2 = null
	var no_pokemon := [false, false]
	for p in players:
		if p.active == null and p.bench.is_empty():
			no_pokemon[p.index] = true
	var wins := [prize_win[0] or no_pokemon[1], prize_win[1] or no_pokemon[0]]
	if wins[0] and wins[1]:
		if sudden_death_enabled:
			_sudden_pending = true      # al terminar la acción empieza la Muerte Súbita
			_game_over(2, "Both players win at once: Sudden Death!")
		else:
			_game_over(2, "Draw.")
		return
	for i in 2:
		if wins[i]:
			_game_over(i, "Took all of their Prize cards." if prize_win[i] else "The opponent has no Pokémon left in play.")
			return
	for p in players:
		if p.active == null and not _choices.any(func(c): return c["p"] == p.index and c["kind"] == "promote"):
			_choices.push_front({"p": p.index, "kind": "promote"})
		if rules.doubles and ko2[p.index] and not _choices.any(func(c): return c["p"] == p.index and c["kind"] == "promote2"):
			_choices.append({"p": p.index, "kind": "promote2"})


## Quita elecciones que ya no tienen sentido (p.ej. cambiar sin Banca).
func _prune_choices() -> void:
	_choices = _choices.filter(func(c):
		var p: PlayerState = players[c["p"]]
		match c["kind"]:
			"switch": return p.active != null and not p.bench.is_empty()
			"promote": return p.active == null and not p.bench.is_empty()
			"promote2": return p.active != null and p.active2 == null and not p.bench.is_empty()
		return not c["options"].is_empty())


func _continue_after_choices() -> void:
	_prune_choices()
	if not _choices.is_empty():
		phase = "choice"
		return
	var nxt := _after_choices
	_after_choices = ""
	phase = "main"
	match nxt:
		"end_turn": _end_turn()
		"next_turn": _begin_turn()


## Muerte Súbita (reglas de la era EX): si los dos jugadores ganan a la vez, se juega
## una partida nueva con los mismos mazos, en la que cada uno pone 1 solo Premio.
## Se vuelve a tirar la moneda para ver quién empieza. Si vuelve a haber empate, otra más.
func _start_sudden_death() -> void:
	sudden_death += 1
	var r := RuleSet.new()
	for prop in ["bench_size", "hand_size", "deck_size", "max_copies", "first_player_draws",
			"first_player_supporter", "coin_winner_chooses", "confusion_self_damage", "burn_damage", "weakness_multiplier", "resistance_value", "doubles"]:
		r.set(prop, rules.get(prop))
	r.name = rules.name.split(" · ")[0] + " · Sudden Death"
	r.prizes = 1
	rules = r
	log_msg("=== SUDDEN DEATH! New game with 1 Prize card each ===")
	players.clear()
	for i in 2:
		var p := PlayerState.new()
		p.index = i
		p.deck_log = deck_log
		var d: Array[String] = []
		d.assign(_decks[i])
		p.deck = d
		players.append(p)
	stadium = ""
	stadium_owner = -1
	current = 0
	turn_number = 0
	winner = -1
	win_reason = ""
	_choices.clear()
	_after_choices = ""
	_insert_pos = -1
	_ctx = [false, false]
	start()


## El jugador abandona la partida: gana el otro.
func concede(player: int) -> void:
	if phase != "over":
		_game_over(1 - player, "Player %d conceded." % (player + 1))
		changed.emit()


## El Pokémon de ese jugador que más daño hizo con ataques: {"id", "dmg"} o {}.
func mvp(player: int) -> Dictionary:
	var best := {}
	for e: Dictionary in stats[player]["by"].values():
		if best.is_empty() or e["dmg"] > best["dmg"]:
			best = e
	return best


func _game_over(who: int, reason: String) -> void:
	phase = "over"
	winner = who
	win_reason = reason
	log_msg("END: " + ("Draw" if who == 2 else "Player %d wins" % (who + 1)) + ". " + reason)


# ===========================================================================
# Utilidades usadas por los efectos
# ===========================================================================

func log_msg(s: String) -> void:
	log_lines.append(s)
	if log_lines.size() > MAX_LOG:
		log_lines.pop_front()


## reason: "" (normal), "burn" (quemadura) o "sleep" (despertarse). Solo cambia la animación.
func flip(reason: String = "") -> bool:
	var heads := rng.randi() % 2 == 0
	coin_log.append(heads)
	coin_reasons.append(reason)
	log_msg("  Coin: " + ("HEADS" if heads else "TAILS"))
	return heads


func flip_many(n: int) -> int:
	var heads := 0
	for i in n:
		if flip():
			heads += 1
	return heads


func shuffle(arr: Array[String]) -> void:
	for p in players:
		if is_same(arr, p.deck):
			deck_log.append({"k": "shuffle", "p": p.index})
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## Pide al jugador que elija entre "options" (cada una con "label" y opcionalmente
## "ai" = qué tan buena le parece a la IA). Al elegir se llama a cb(opción).
func ask(player_index: int, prompt: String, options: Array, cb: Callable) -> void:
	if options.is_empty():
		return
	var c := {"p": player_index, "kind": "ask", "prompt": prompt, "options": options, "cb": cb}
	if _ctx[0] or _ctx[1]:
		c["ctx"] = _ctx.duplicate()      # la respuesta se resuelve con los Activos en el mismo orden
	if _insert_pos >= 0:
		_choices.insert(_insert_pos, c)
		_insert_pos += 1
	else:
		_choices.append(c)


func queue_choice(player_index: int, kind: String) -> void:
	var c := {"p": player_index, "kind": kind}
	if _insert_pos >= 0:
		_choices.insert(_insert_pos, c)
		_insert_pos += 1
	else:
		_choices.append(c)


func choice_options() -> Array:
	return _choices[0].get("options", []) if phase == "choice" else []


func try_condition(p: PokemonInPlay, cond: String) -> void:
	if not Abilities.can_have_condition(self, p, cond) or p.flags.get("no_conditions", -1) >= turn_number:
		return
	p.apply_condition(cond, turn_number)
	log_msg("  %s is now %s." % [p.display_name(), COND_ES[cond]])
	Abilities.on_condition(self, p, cond)


## Índice en el mazo de la "mejor" carta que cumpla pred (más PS), o -1.
func best_in_deck(p: PlayerState, pred: Callable) -> int:
	var best := -1
	var best_hp := -1
	for i in p.deck.size():
		var id := p.deck[i]
		if pred.call(id):
			var hp := CardDB.hp(id)
			if hp > best_hp:
				best = i
				best_hp = hp
	return best


func switch_active(p: PlayerState, bench_idx: int) -> void:
	var old := p.active
	p.active = p.bench[bench_idx]
	p.bench[bench_idx] = old
	old.clear_conditions()
	old.clear_attack_effects()
	log_msg("Player %d switches %s with %s." % [p.index + 1, old.display_name(), p.active.display_name()])


func evolve(me: PlayerState, p: PokemonInPlay, card_id: String) -> void:
	var before := p.display_name()
	p.cards.append(card_id)
	p.turn_played = turn_number
	p.evolved_turn = turn_number
	p.power_used_turn = -1
	var keep_burn := p.burned and stadium_name() == "Full Flame"
	p.clear_conditions()
	p.burned = keep_burn
	p.clear_attack_effects()
	p.type_override = []
	evolve_log.append({"p": me.index, "mon": p, "from": before, "to": CardDB.card_name(card_id)})
	log_msg("%s evolved into %s!" % [before, CardDB.card_name(card_id)])


## Saca un Pokémon del juego sin KO (Fósil descartado). Si era el Activo, hay que elegir otro.
func remove_from_play(pl: PlayerState, p: PokemonInPlay, to_hand: bool) -> void:
	var cards := p.all_cards()
	if to_hand:
		pl.hand.append_array(cards)
	else:
		pl.discard.append_array(cards)
	if p == pl.active:
		pl.active = null
	elif p == pl.active2:
		pl.active2 = null
	else:
		pl.bench.erase(p)


func return_to_hand(pl: PlayerState, p: PokemonInPlay) -> void:
	log_msg("  %s returns to the hand." % p.display_name())
	remove_from_play(pl, p, true)


func set_stadium(me: PlayerState, card_id: String) -> void:
	discard_stadium()
	stadium = card_id
	stadium_owner = me.index
	if CardDB.card_name(card_id) == "Giant Stump":
		_bench_before_stump = rules.bench_size
		rules.bench_size = mini(rules.bench_size, 3)
		for pl in [me, other(me)]:      # primero el que lo jugó
			while pl.bench.size() > rules.bench_size:
				var x: PokemonInPlay = pl.bench.pop_back()
				pl.discard.append_array(x.all_cards())
				log_msg("  Giant Stump: %s is discarded." % x.display_name())


var _bench_before_stump := -1


func discard_stadium() -> void:
	if _bench_before_stump > 0:
		rules.bench_size = _bench_before_stump
		_bench_before_stump = -1
	if stadium != "":
		players[stadium_owner].discard.append(stadium)
		log_msg("  %s is discarded." % CardDB.card_name(stadium))
	stadium = ""
	stadium_owner = -1


func _retreat(me: PlayerState, bench_idx: int) -> void:
	var a := me.active
	if stadium_name() == "Mirage Stadium" and not flip():
		me.retreated = true
		log_msg("  Mirage Stadium: %s can't retreat this turn." % a.display_name())
		return
	if CardDB.card_name(a.tool) == "Balloon Berry":
		me.discard.append(a.tool)
		a.tool = ""
	else:
		me.retreated = true
		_pay_retreat(me, bench_idx, Abilities.retreat_cost(self, me, a))
		return
	me.retreated = true
	_retreat_switch(me, bench_idx)


## Descarta Energías del Activo para retirarse. Si hay Energías distintas, el jugador
## elige cuál descartar (una por vez); el cambio se hace cuando el costo está pagado.
func _pay_retreat(me: PlayerState, bench_idx: int, left: int) -> void:
	var a := me.active
	var total := 0
	for e in a.energy:
		total += Energy.units_of_card(e, a).size()
	var kinds: Array = []
	for e in a.energy:
		if e not in kinds:
			kinds.append(e)
	if left <= 0 or a.energy.is_empty() or kinds.size() == 1 or total <= left:
		# Sin nada que elegir: se descarta lo necesario.
		while left > 0 and not a.energy.is_empty():
			var e: String = a.energy.pop_back()
			left -= Energy.units_of_card(e, a).size()
			me.discard.append(e)
		_retreat_switch(me, bench_idx)
		return
	var needed: Array = []     # tipos que usan los ataques del que se retira (para la IA)
	for atk in a.attacks():
		needed.append_array(atk.get("cost", []))
	var opts: Array = []
	for e in kinds:
		var units := Energy.units_of_card(e, a).size()
		var label := CardDB.card_name(e) + (" (counts as %d)" % units if units > 1 else "")
		var value := 0.0 if not CardDB.is_basic_energy(e) else (0.5 if CardDB.basic_energy_type(e) in needed else 1.0)
		opts.append({"label": label, "id": e, "retreat_to": bench_idx, "ai": value})
	ask(me.index, "Retreat: discard Energy (%d left)" % left, opts, func(o):
		a.energy.erase(o["id"])
		me.discard.append(o["id"])
		_pay_retreat(me, bench_idx, left - Energy.units_of_card(o["id"], a).size()))


## El cambio al retirarse. Suction Cups (Octillery rival Activo): el que se retira
## descarta todas sus Energías al ir a la Banca.
func _retreat_switch(me: PlayerState, bench_idx: int) -> void:
	var a := me.active
	var hp_before := a.hp_left()
	switch_active(me, bench_idx)
	if hp_before >= 40 and Abilities.body_in_play(self, other(me), "Metal Gravity") and Abilities.fired_pl(self, other(me), "Metal Gravity"):
		a.damage += 30
		log_msg("  Metal Gravity: 3 damage counters on %s." % a.display_name())
	if Abilities.active_body(self, other(me), "Suction Cups") and not a.energy.is_empty() \
			and Abilities.fired_pl(self, other(me), "Suction Cups"):
		me.discard.append_array(a.energy)
		a.energy.clear()
		log_msg("  Suction Cups: %s discards all its Energy." % a.display_name())


## Daño de un ataque. Devuelve el daño final hecho.
func deal_attack_damage(attacker: PokemonInPlay, target: PokemonInPlay, base: int, is_active: bool, ignore: Dictionary) -> int:
	if target == null or base <= 0:
		return 0
	if Abilities.prevents_damage(self, attacker, target, is_active):
		log_msg("  %s takes no damage!" % target.display_name())
		return 0
	var dmg := base + Abilities.pre_wr_bonus(self, attacker, target, is_active)
	if is_active:
		if not ignore.get("w", false) and not Abilities.ignores_weakness(self, target) \
				and attacker.types().any(func(t): return t in Abilities.weakness_types(self, target)):
			dmg *= rules.weakness_multiplier
		if not ignore.get("r", false) and not Abilities.ignores_resistance(self, attacker, target) \
				and attacker.types().any(func(t): return t in target.data().get("resistances", [])):
			dmg -= Abilities.resistance_value(self, rules.resistance_value)
	dmg = Abilities.post_wr(self, attacker, target, is_active, dmg, ignore.get("fx", false))
	# Silver Wind (Masquerain): +30 al Pokémon marcado, durante el turno siguiente de quien atacó
	var sw = target.flags.get("silver_wind", null)
	if is_active and sw != null and sw[0] >= turn_number and sw[1] == current and dmg > 0:
		dmg += int(sw[2])
	dmg = max(0, dmg)
	if not ignore.get("fx", false):
		dmg = Abilities.final_damage(self, attacker, target, dmg)
	var was_alive := target.hp_left() > 0
	target.damage += dmg
	if was_alive and target.hp_left() <= 0 and owner_of(target) != owner_of(attacker):
		Abilities.on_would_ko(self, attacker, target)
	log_msg("  %s takes %d damage (%d/%d HP)." % [target.display_name(), dmg, max(0, target.hp_left()), target.max_hp()])
	var att_pl := owner_of(attacker)
	if dmg > 0 and att_pl != owner_of(target):
		var st: Dictionary = stats[att_pl.index]
		st["dmg"] += dmg
		var key := attacker.get_instance_id()
		var e: Dictionary = st["by"].get(key, {"id": attacker.top(), "dmg": 0})
		e["id"] = attacker.top()      # si evolucionó, se ve la forma actual
		e["dmg"] += dmg
		st["by"][key] = e
	if dmg > 0 and owner_of(target) != owner_of(attacker):
		Abilities.after_damaged(self, attacker, target)
	return dmg


# ===========================================================================
# Textos
# ===========================================================================

## Nombre de un Pokémon en juego; si hay otro con el mismo nombre, se aclara dónde está.
func slot_name(pl: PlayerState, s: int) -> String:
	var mon := pl.slot(s)
	if mon == null:
		return "?"
	var n := mon.display_name()
	if pl.all_in_play().filter(func(x): return x.display_name() == n).size() > 1:
		n += " (Active)" if s == -1 else (" (Active 2)" if s == PlayerState.ACTIVE2 else " (Bench %d)" % (s + 1))
	return n


## Texto legible de una acción (para menús y registros). En dobles, las acciones de un
## Activo (ataques, retiradas...) dicen cuál actúa y contra cuál.
func describe(a: Dictionary) -> String:
	if not rules.doubles:
		return _describe_raw(a)
	var box := [""]
	with_ctx(a.get("ctx", null), func():
		var me: PlayerState = players[actor()] if actor() >= 0 else current_player()
		var opp := other(me)
		var t: String = _describe_raw(a)
		match a["t"]:
			"attack":
				t = "%s: %s" % [_act_label(me, a), t]
				if a["tg"] == -2 and opp.active2 != null and opp.active != null:
					t += " → " + _act_label(opp, a)
			"retreat":
				if me.active2 != null:
					t = "Retreat %s for %s" % [me.active.display_name(), slot_name(me, a["b"])]
		box[0] = t)
	return box[0]


## Nombre de "el" Activo de un jugador dentro del contexto de una acción; si sus dos
## Activos se llaman igual, se aclara cuál es (izquierda/derecha según el lugar real).
func _act_label(pl: PlayerState, a: Dictionary) -> String:
	var n := pl.active.display_name()
	if pl.active2 != null and pl.active2.display_name() == n:
		var swapped: bool = a.get("ctx", [false, false])[pl.index]
		n += " (2)" if swapped else " (1)"
	return n


func _describe_raw(a: Dictionary) -> String:
	var who := actor()
	var me: PlayerState = players[who] if who >= 0 else current_player()
	var opp := other(me)
	match a["t"]:
		"setup_active": return "Active: " + CardDB.card_name(me.hand[a["h"]])
		"setup_active2": return "2nd Active: " + CardDB.card_name(me.hand[a["h"]])
		"send_out": return "Send out " + slot_name(me, a["b"])
		"setup_bench": return "Bench: " + CardDB.card_name(me.hand[a["h"]])
		"setup_done": return "Done"
		"first": return "I'll go first" if a["me"] else "Opponent goes first"
		"mull_draw": return "Draw %d extra card(s) (opponent's mulligan)" % a["n"] if a["n"] > 0 else "Don't draw extra cards"
		"choose":
			if a.has("i"):
				return _choices[0]["options"][a["i"]]["label"]
			if a.has("act") and phase == "choice":
				var cp: PlayerState = players[_choices[0]["p"]]
				return "%s ⇄ %s" % [cp.active2.display_name() if cp.active2 != null else "?", slot_name(cp, a["b"])]
			if rules.doubles and phase == "choice" and _choices[0]["kind"] == "switch":
				var cp: PlayerState = players[_choices[0]["p"]]
				if cp.active2 != null:
					return "%s ⇄ %s" % [cp.active.display_name(), slot_name(cp, a["b"])]
			return slot_name(me, a["b"])
		"bench": return "Bench " + CardDB.card_name(me.hand[a["h"]])
		"evolve": return "%s → %s" % [slot_name(me, a["tg"]), CardDB.card_name(me.hand[a["h"]])]
		"energy": return "%s → %s" % [CardDB.card_name(me.hand[a["h"]]).replace(" Energy", ""), slot_name(me, a["tg"])]
		"trainer":
			var n := CardDB.card_name(me.hand[a["h"]])
			var s := n
			var p: Dictionary = a["p"]
			if p.has("pick"):
				s += " (" + CardDB.card_name(p["pick"]) + ")"
			if p.has("mode") and p["mode"] == "deck":
				s += " (3 to the deck)"
			if p.has("tg"):
				var owner := opp if n == "Energy Removal 2" else me
				s += " → " + slot_name(owner, p["tg"])
				if p.has("e"):
					s += " (" + CardDB.card_name(owner.slot(p["tg"]).energy[p["e"]]).replace(" Energy", "") + ")"
			if p.has("b"):
				s += " → " + slot_name(me, p["b"])
			if p.has("ev"):
				s += " → " + CardDB.card_name(p["ev"])
			if p.has("to"):
				s += ": %s → %s" % [slot_name(me, p["from"]), slot_name(me, p["to"])]
			return s
		"power":
			var s: String = a["n"]
			var p: Dictionary = a["p"]
			if a["n"] == Abilities.DISCARD_FOSSIL:
				return s + " (" + slot_name(me, a["s"]) + ")"
			if p.has("pick"):
				s += " (" + CardDB.card_name(p["pick"]) + ")"
			if p.has("tg"):
				s += " → " + slot_name(me, p["tg"])
			if p.has("id"):
				s += " (" + CardDB.card_name(p["id"]) + ")"
			if p.has("b"):
				s += " → " + slot_name(opp, p["b"])
			if p.has("mb"):
				s += " → " + slot_name(me, p["mb"])
			if p.has("to"):
				s += ": %s → %s" % [slot_name(me, p["from"]), slot_name(me, p["to"])]
			elif p.has("from"):
				s += " ← " + slot_name(me, p["from"])
			return s
		"retreat": return "Retreat for " + slot_name(me, a["b"])
		"attack":
			var atk: Dictionary = me.active.attacks()[a["a"]]
			var s: String = atk["name"]
			if a["tg"] != -2 and opp.slot(a["tg"]) != null:
				s += " → " + slot_name(opp, a["tg"])
			if a.get("opt", false) is String and a["opt"] != "":
				s += " (discard %s)" % TYPE_ES.get(a["opt"], a["opt"])
			elif a.get("opt", false) is int:
				var v: Dictionary = AttackEffects.parse(me.active.top(), atk)["variable"]
				s += " (%s %d)" % [{"discard": "discard", "hand_discard": "discard from hand"}.get(v.get("mode", ""), "return"), a["opt"]]
			elif a.get("opt", false) is Dictionary and a["opt"].has("gm_card"):
				var under_atk: Dictionary = CardDB.get_card(a["opt"]["gm_card"])["attacks"][int(a["opt"]["gm_a"])]
				s = "%s: %s" % [atk["name"], under_atk["name"]] + s.substr(atk["name"].length())
				if a["opt"].get("gm_opt", false):
					s += " (+option)"
			elif a.get("opt", false):
				s += " (+option)"
			return s
		"end": return "End turn"
	return str(a)
