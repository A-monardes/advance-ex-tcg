class_name SimpleAI
extends RefCounted
## IA del rival, con 5 niveles:
##   1 Principiante  la mitad de las veces juega cualquier cosa.
##   2 Fácil         puntúa las jugadas con mucho ruido, se olvida de Entrenadores y
##                   Poké-Powers y a veces elige un ataque cualquiera.
##   3 Normal        puntúa cada jugada legal y elige la mejor (prepara y después ataca).
##   4 Difícil       además prueba las mejores jugadas en una copia de la partida (sin ver
##                   cartas ocultas), juega el resto del turno y se queda con la que deja
##                   mejor la mesa (engine/ai_eval.gd).
##   5 Experto       igual que Difícil, con más simulaciones y más alternativas.
## Fuerza medida con tests/ai_levels.gd.

const AIEval := preload("res://engine/ai_eval.gd")
const LEVEL_NAMES := ["Beginner", "Easy", "Normal", "Hard", "Expert"]

var rng := RandomNumberGenerator.new()
var level := 3          # 1 Principiante · 2 Fácil · 3 Normal · 4 Difícil · 5 Experto
var noise := 0.0        # ruido en las puntuaciones (niveles bajos)
var _helper: SimpleAI = null   # IA Normal que juega "el resto" en las simulaciones
var sim_samples := 1    # simulaciones por jugada (Difícil 1, Experto más)
var sim_reply := false  # simular también el turno del rival
var sim_alternatives := 4   # alternativas a la jugada del Normal que se prueban
var sim_margin := 30.0      # cuánto mejor tiene que ser otra jugada para cambiarla
## Puntajes nuevos de Entrenadores (auditoría de la IA). Se puede apagar para comparar.
static var v2 := true

## Poké-Powers que conviene usar siempre que se pueda.
const GOOD_POWERS := {
	"Firestarter": 35.0, "Energy Draw": 20.0, "Psy Shadow": 30.0, "Water Call": 35.0, "Fan Away": 30.0,
	"Chaos Flash": 25.0, "Baby Evolution": 50.0, "Healing Wind": 20.0, "Magnetic Field": 15.0,
	"Loose Shell": 40.0, "Overheat": 25.0, "Auxiliary Light": 20.0, "Call for Help": 30.0,
	"Healing Shower": 30.0, "Crush Draw": 25.0, "Heal Dance": 25.0, "Magnetic Call": 30.0,
	"Metal Juncture": 15.0, "Lunar Eclipse": -5.0, "Solar Eclipse": -5.0, "Drive Off": 10.0,
	"Dragon Wind": 10.0, "Energy Trans": -5.0, "Call for Power": -5.0, "Power Shift": -5.0,
	"Magma Switch": -5.0, "Temperamental Weather": -5.0,
	# e-card (las que mueven cosas propias de lugar quedan en 0 o negativo: la IA no sabe planearlas)
	"Jet Stream": 25.0, "Miraculous Powder": 30.0, "Moonlight": 10.0, "Soothing Aroma": 25.0,
	"Heat Up": 30.0, "Harvest Bounty": 30.0, "Poison Pollen": 25.0, "Flower Supplement": 25.0,
	"Happy Healing": 20.0, "Super Dynamo": 25.0, "Sleep Pendulum": 30.0, "Earth Rage": 25.0,
	"Backup": 30.0, "Strange Tentacles": -5.0, "Dark Moon": 20.0, "Fragrance Trap": 15.0,
	"Scavenger Hunt": 10.0, "Carry Off": 20.0, "Evolution Helper": 45.0, "Strange Spiral": 15.0,
	"Good Neighbor": 10.0, "Reconstruction": 20.0, "Lolling About": -5.0, "Energy Return": -10.0,
	"Energy Jump": -5.0, "Water Cyclone": -5.0, "Energy Connect": -5.0, "Miracle Shift": -5.0,
	"Beating Wings": -10.0, "Plunge": -5.0, "Bubble Turn": -10.0, "Chaos Move": 10.0,
	"Tailwind": -5.0, "Major Tsunami": -5.0, "Ancient Wind": 5.0, "Burning Energy": -5.0,
	"Ion Coating": -5.0, "Magnetic Flow": -5.0, "Terraforming": -5.0, "Investigate": -5.0,
	"Apricorn Forest": 25.0, "Undersea Ruins": -10.0, "Power Plant": 5.0, "Ancient Ruins": 20.0,
	"Mystery Zone": 5.0, "Underground Lake": 25.0,
	# Diamond & Pearl (los que eligen un blanco se ajustan en _power_score)
	"Dark Palm": 40.0, "Darkness Fan": 30.0, "Supreme Command": 35.0, "Burning Head": 30.0,
	"Forest Murmurs": 20.0, "Intense Voltage": 10.0, "ANALYZE": 5.0, "CALL": 15.0, "DRAW": 10.0,
	"BOUNCE": -10.0,
	# Resto de las eras. Los que la IA no sabe aprovechar quedan en negativo: con 0 los usaba
	# igual (el ruido del desempate los volvía positivos), aunque le hicieran mal.
	"Quick Search": 30.0, "Wishing Star": 25.0, "Swing Dance": 25.0, "Echo Draw": 25.0,
	"Delta Control": 25.0, "Invitation": 25.0, "Delta Sign": 25.0, "Evolutionary Light": 30.0,
	"Item Search": 20.0, "Night Cry": 20.0, "Primal Light": 20.0, "Power of Evolution": 20.0,
	"Emerge": 30.0, "Smooth Over": 10.0, "Excavate": 5.0, "Cunning": 5.0, "Gift Exchange": 5.0,
	"Power Circulation": 5.0, "Sharing": 10.0, "Night Vision": -1.0, "Psychic Vision": -1.0,
	"Darkness Navigation": 25.0, "Metal Navigation": 25.0, "Reactive Generator": 20.0,
	"Delta Charge": 20.0, "Delta Support": 20.0, "Super Connectivity": 15.0, "Nurture and Heal": 20.0,
	"Energy Rain": 10.0, "Delta Supply": 15.0, "Extra Boost": 15.0,
	"Ripples": 15.0, "Happy Dance": 20.0, "Delta Heal": 20.0, "Assistance": 15.0,
	"Black Beam": 25.0, "Fire Breath": 25.0, "Poison Structure": 25.0, "Imprison": 30.0,
	"Dark Spell": 20.0, "Distortion": 25.0, "Dragon Curse": 30.0, "Spike Storm": 25.0,
	"Splash Back": 40.0, "Fan Action": 15.0, "Magnetic Reversal": 15.0, "Driving Howl": 15.0,
	"Nectar Pod": 15.0, "Shady Move": 15.0,
	"Head Trip": -15.0, "Final Sting": -20.0, "Extra Energy Bomb": -10.0, "3-D Reset": -10.0,
	"Form Variation": -5.0, "Form Change": -5.0, "Duplicate": -5.0, "Shuffle": -5.0,
	"Strange Behavior": -5.0, "Dark Trance": -5.0, "Snappy Move": -5.0, "Makeover": -5.0,
	"Prize Shift": -5.0, "Reactive Shift": -5.0, "Type Change": -5.0, "Delta Transport": -5.0,
	"Constrain": -5.0, "Energy Recycle": -5.0, "Fellow Boost": -5.0, "Type Shift": -5.0,
	"Volunteer": -5.0, "Magnetic Redraw": -5.0, "Psymimic": -5.0, "Dozing": -5.0, "Psychic Trace": 0.0,
}


func _init(seed_value: int = 0, lvl: int = 3) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	level = clampi(lvl, 1, 5)
	# Difícil: 2 simulaciones por jugada, 4 alternativas. Experto: 5 simulaciones y 6
	# alternativas (más lento, más fino). Medido con tests/ai_levels.gd.
	sim_samples = 5 if level == 5 else 2
	sim_alternatives = 6 if level == 5 else 4
	sim_margin = 10.0 if level == 5 else 20.0
	sim_reply = false


func choose(g: Game) -> Dictionary:
	if g.phase == "first":
		return {"t": "first", "me": true}     # ganó la moneda: prefiere empezar
	match level:
		1: return _choose_beginner(g)
		2: return _choose_easy(g)
		4, 5:
			if g.phase == "main" and g.actor() == g.current and not g.has_pending_choices():
				return _choose_lookahead(g, level)
	return _choose_normal(g)


# ---------------------------------------------------------------------------
# Niveles bajos: errores a propósito
# ---------------------------------------------------------------------------

## Principiante: muchas veces juega cualquier cosa (pero casi nunca pasa el turno sin motivo).
func _choose_beginner(g: Game) -> Dictionary:
	var actions := g.legal_actions()
	if rng.randf() < 0.5:
		var not_end := actions.filter(func(a): return a["t"] != "end")
		var pool := not_end if not not_end.is_empty() else actions
		return pool[rng.randi() % pool.size()]
	noise = 40.0
	var a := _choose_normal(g)
	noise = 0.0
	return a


## Fácil: juega como Normal pero con bastante ruido, a veces se olvida de sus Entrenadores
## y Poké-Powers, y a veces elige un ataque cualquiera.
func _choose_easy(g: Game) -> Dictionary:
	noise = 60.0
	var a := _choose_normal(g)
	noise = 0.0
	var acts := g.legal_actions()
	if a.get("t", "") in ["trainer", "power"] and rng.randf() < 0.4:
		var others := acts.filter(func(x): return x["t"] not in ["trainer", "power"])
		if not others.is_empty():
			var prep := others.filter(func(x): return x["t"] not in ["attack", "end"])
			var b := _best(g, prep)
			if not b.is_empty() and b["score"] > 0.0:
				return b["action"]
			a = _best(g, others.filter(func(x): return x["t"] in ["attack", "end"]))["action"]
	if a.get("t", "") == "attack" and rng.randf() < 0.35:
		var atks := acts.filter(func(x): return x["t"] == "attack")
		return atks[rng.randi() % atks.size()]
	return a


# ---------------------------------------------------------------------------
# Niveles altos: simular en una copia de la partida
# ---------------------------------------------------------------------------

## Difícil: prueba cada jugada en una copia y se queda con la que deja mejor la mesa;
##          prepara mientras mejore y recién después ataca o termina.
## Experto: por cada jugada posible simula el resto de su turno (con la IA Normal) y
##          evalúa cómo queda todo al empezar el turno del rival (2 muestras, porque no
##          sabe qué va a robar ni qué saldrá en las monedas).
func _choose_lookahead(g: Game, lvl: int) -> Dictionary:
	if _helper == null:
		_helper = SimpleAI.new(rng.randi() + 1, 3)
	var me := g.current
	var actions := g.legal_actions()
	var base: Dictionary = _choose_normal(g)
	if actions.size() == 1:
		return base
	# Candidatas: la jugada del Normal y las mejores alternativas según la heurística
	var ranked: Array = []
	for a in actions:
		ranked.append([score(g, a), a])
	ranked.sort_custom(func(x, y): return x[0] > y[0])
	var cands: Array = [base]
	var limit := sim_alternatives
	for x in ranked:
		if cands.size() > limit:
			break
		if x[1] != base:
			cands.append(x[1])
	# Siempre considerar atacar con cada ataque y terminar el turno
	for a in actions:
		if a["t"] in ["attack", "end"] and a not in cands:
			cands.append(a)
	# v2: no retirarse a un Pokémon que ni con la Energía del turno que viene puede pegar si
	# el Activo puede atacar ahora (la copia lo elegía para "aguantar" y perdía turnos).
	if v2 and retreat_filter:
		cands = cands.filter(func(a): return a == base or not _pointless_retreat(g, a))
		if cands.is_empty():
			return base
	var values: Array = []
	# v2: las mismas semillas para todas las jugadas (misma "suerte" en cada muestra): así la
	# diferencia entre jugadas no es ruido de las monedas y del robo.
	var seeds: Array = []
	for k in sim_samples:
		seeds.append(rng.randi() % 2000000000 + 1 if v2 else 0)
	for a in cands:
		var v := 0.0
		for k in sim_samples:
			v += _simulate(g, a, me, true, sim_reply, seeds[k])
		values.append(v / sim_samples)
	# Se cambia la jugada del Normal solo si otra es claramente mejor
	var best_i := 0
	for i in range(1, cands.size()):
		if values[i] > values[best_i]:
			best_i = i
	if best_i != 0 and values[best_i] > values[0] + sim_margin:
		if debug_dev:
			print("  [IA] cambia %s (%.0f) por %s (%.0f)" % [_desc(g, base), values[0], _desc(g, cands[best_i]), values[best_i]])
		return cands[best_i]
	return base


static var debug_dev := false
static var retreat_filter := true


## Retirada (o Switch) a un Pokémon que no va a poder pegar, dejando un Activo que sí puede.
func _pointless_retreat(g: Game, a: Dictionary) -> bool:
	var me: PlayerState = g.players[g.actor()]
	var opp := g.other(me)
	if me.active == null or opp.active == null:
		return false
	var b := -1
	if a["t"] == "retreat":
		b = int(a["b"])
	elif a["t"] == "trainer" and CardDB.card_name(me.hand[a["h"]]) == "Switch" and a.get("p", {}).has("b"):
		b = int(a["p"]["b"])
	if b < 0 or b >= me.bench.size():
		return false
	if not g.can_attack(me.active) or AIEval.best_damage(g, me.active, opp.active, 0) == 0:
		return false
	return AIEval.best_damage(g, me.bench[b], opp.active, 1) == 0


func _desc(g: Game, a: Dictionary) -> String:
	var me: PlayerState = g.players[g.actor()]
	match a["t"]:
		"trainer", "bench", "evolve", "energy":
			return "%s %s%s" % [a["t"], CardDB.card_name(me.hand[a["h"]]), (" -> " + me.slot(a["tg"]).display_name()) if a.has("tg") and me.slot(a["tg"]) != null else ""]
		"attack":
			return "attack " + me.active.attacks()[a["a"]]["name"]
		"retreat":
			return "retreat -> " + me.bench[a["b"]].display_name()
		"power":
			return "power " + str(a["n"])
	return a["t"]


func _simulate(g: Game, a: Dictionary, me: int, rollout: bool, reply: bool = false, sim_seed: int = 0) -> float:
	var c := g.clone(me, sim_seed)
	if sim_seed != 0:
		_helper.rng.seed = sim_seed
	c.apply(a)
	_settle(c)
	if rollout:
		_play_turn(c, me)
		# Experto: también juega el turno del rival y el siguiente propio (con la IA Normal)
		if reply and c.phase == "main" and c.current != me:
			_play_turn(c, c.current)
			_settle(c)
			if c.phase == "main" and c.current == me:
				_play_turn(c, me)
	return AIEval.evaluate(c, me)


func _play_turn(c: Game, who: int) -> void:
	var steps := 0
	while c.phase == "main" and c.current == who and steps < 30:
		c.apply(_helper.choose(c))
		_settle(c)
		steps += 1


## Resuelve las elecciones pendientes de la simulación con la IA Normal.
func _settle(c: Game) -> void:
	var guard := 0
	while (c.phase == "choice" or c.phase == "setup") and guard < 40:
		c.apply(_helper._choose_normal(c))
		guard += 1


func _choose_normal(g: Game) -> Dictionary:
	var actions := g.legal_actions()
	# Primero todo lo que convenga hacer antes de atacar (atacar termina el turno).
	var prep := actions.filter(func(a): return a["t"] not in ["attack", "end"])
	var best := _best(g, prep)
	if not best.is_empty() and (g.phase != "main" or best["score"] > 0.0):
		return best["action"]
	# Atacar o terminar: sin ruido (ni los niveles bajos pasan el turno pudiendo atacar)
	var keep := noise
	noise = 0.0
	var fin := _best(g, actions.filter(func(a): return a["t"] in ["attack", "end"]))
	noise = keep
	return fin["action"]


func _best(g: Game, actions: Array) -> Dictionary:
	var out := {}
	for a in actions:
		var base := score(g, a)
		# El ruido de los niveles bajos solo reordena las jugadas buenas: no vuelve atractiva una mala.
		var s := base + rng.randf() * (0.1 + (noise if base > 0.0 else 0.0))
		if out.is_empty() or s > out["score"]:
			out = {"action": a, "score": s}
	return out


func score(g: Game, a: Dictionary) -> float:
	if not a.has("ctx"):
		return _score_raw(g, a)
	var box := [0.0]                 # dobles: se mira con el Activo que actúa en el lugar de "el" Activo
	g.with_ctx(a["ctx"], func(): box[0] = _score_raw(g, a))
	return box[0]


func _score_raw(g: Game, a: Dictionary) -> float:
	var me: PlayerState = g.players[g.actor()]
	var opp := g.other(me)
	match a["t"]:
		"setup_active", "setup_active2":
			return float(CardDB.hp(me.hand[a["h"]])) - (50.0 if CardDB.is_ex(me.hand[a["h"]]) else 0.0) \
					+ (10.0 if a["t"] == "setup_active2" else 0.0)
		"send_out":
			var so := me.bench[a["b"]]
			return 45.0 + _best_attack_damage(g, so) * 0.5 + so.hp_left() * 0.1
		"setup_bench":
			return 5.0 if me.bench.size() < 3 else -1.0
		"setup_done":
			return 0.0
		"mull_draw":
			return float(a["n"])
		"choose":
			if a.has("k"):
				return 1.0 if a["k"] == me.prizes.size() else 0.0   # Premio: boca abajo da lo mismo
			if a.has("i"):
				return float(g.choice_options()[a["i"]].get("ai", 0.0))
			var p := me.bench[a["b"]]
			if g.pending_choice_kind() == "switch" and me.index != g.current:
				return -float(Energy.total(p)) * 20.0 - p.hp_left()   # el rival elige: el peor posible
			# Mandar al frente al que pueda pegar más ya mismo (y aguante)
			return _best_attack_damage(g, p) * 1.5 + Energy.total(p) * 8.0 + p.hp_left() * 0.5
		"bench":
			if CardDB.is_fossil(me.hand[a["h"]]):
				return 10.0 if me.bench.size() < 3 else -5.0
			return 40.0 if me.bench.size() < 3 else 5.0
		"evolve":
			return 60.0
		"energy":
			return _energy_score(g, me, a)
		"trainer":
			return _trainer_score(g, me, a)
		"power":
			if a["n"] == Abilities.DISCARD_FOSSIL:
				return -10.0
			return _power_score(g, me, opp, a)
		"retreat":
			var target := me.bench[a["b"]]
			var my_dmg := _best_attack_damage(g, me.active)
			var stuck: bool = not g.can_attack(me.active) or my_dmg == 0
			var target_dmg := _best_attack_damage(g, target)
			if opp.active != null and my_dmg >= opp.active.hp_left():
				return -10.0          # mejor atacar: lo noquea
			if (me.active.hp_left() <= 20 or stuck) and target_dmg > 0 and target.hp_left() > 40:
				return 30.0
			# Si el Activo va a caer el turno que viene y el de la Banca pega más, retirarse
			if opp.active != null and AIEval.best_damage(g, opp.active, me.active, 1) >= me.active.hp_left() \
					and target_dmg > my_dmg and target.hp_left() > AIEval.best_damage(g, opp.active, target, 1):
				return 25.0
			return -10.0
		"attack":
			return 20.0 + _attack_value(g, me, opp, a)
		"end":
			return 0.0
	return 0.0


## Puntaje de un Poké-Power: el de la tabla, ajustado por el blanco que elige.
func _power_score(g: Game, me: PlayerState, opp: PlayerState, a: Dictionary) -> float:
	var base: float = GOOD_POWERS.get(a["n"], 0.0)
	var prm: Dictionary = a.get("p", {})
	match a["n"]:
		"Supreme Command":
			return base + float(prm.get("n", 0))       # mejor 2 cartas que 1
		"Dark Palm":
			# El que más le cuesta perder: Energías unidas y Fases encima
			var x := opp.bench[int(prm["b"])] if int(prm.get("b", -1)) in range(opp.bench.size()) else null
			return base + (Energy.total(x) * 6.0 + (x.cards.size() - 1) * 8.0 if x != null else 0.0)
		"Forest Murmurs":
			# Traer al frente al que se puede noquear (o al más débil) y no a uno que pega fuerte
			var x := opp.bench[int(prm["b"])] if int(prm.get("b", -1)) in range(opp.bench.size()) else null
			if x == null or me.active == null:
				return base
			var dmg := AIEval.best_damage(g, me.active, x, 0)
			return base + (30.0 if dmg >= x.hp_left() else 0.0) - x.hp_left() * 0.1 - _best_attack_damage(g, x) * 0.2
		"Dark Spell", "Distortion", "Dragon Curse", "Spike Storm":
			# Contadores de daño: al que quede noqueado, si no al Activo (el que pelea)
			var t: int = int(prm.get("tg", -9))
			var x := opp.slot(t) if t != -9 else null
			if x == null:
				return base
			var n := 2 if a["n"] == "Dragon Curse" else 1
			if x.hp_left() <= n * 10:
				return base + 30.0
			return base + (5.0 if PlayerState.is_active_slot(t) else 0.0) - x.hp_left() * 0.02
		"Psychic Trace":
			# Barajar la mano y robar tantas como tiene el rival: solo si se gana en cartas
			return (opp.hand.size() - me.hand.size()) * 6.0 - 3.0
		"Dozing":
			# Se cura 20 y se duerme: solo si está bastante lastimado
			return 15.0 if me.active != null and me.active.damage >= 40 else -5.0
		"Intense Voltage":
			# Mover Energía al Electivire solo si es el Activo (el que ataca)
			return base if me.active != null and me.active.display_name() == "Electivire" else -5.0
	return base


func _energy_score(g: Game, me: PlayerState, a: Dictionary) -> float:
	var p := me.slot(a["tg"])
	var id: String = me.hand[a["h"]]
	var temporary := CardDB.card_name(id) in ["Aqua Energy", "Magma Energy"]
	var before := _usable_attacks(g, p)
	p.energy.append(id)
	var after := _usable_attacks(g, p)
	var useful := _helps_cost(p, id)
	p.energy.pop_back()
	if temporary:
		return 60.0 if a["tg"] == -1 and after > before else -20.0
	# El Activo primero si todavía no puede atacar: si no, se queda recibiendo golpes.
	var act := me.active
	var active_ready := act != null and _best_attack_damage(g, act) > 0
	if a["tg"] == -1:
		if not active_ready:
			if after > before:
				return 70.0 + rng.randf()
			if useful:
				return 55.0 + rng.randf()
		else:
			# Ya puede atacar: seguir cargándolo si se acerca a un ataque mejor
			if after > before:
				return 50.0 + rng.randf()
			if useful:
				return 42.0 + rng.randf()
		return 5.0 + rng.randf()
	# Banca: preparar al reemplazo (más si el Activo ya está listo)
	var big := 4.0 if p.is_evolved() or p.is_ex() else 0.0
	if after > before:
		return (40.0 if active_ready else 30.0) + big + rng.randf()
	if useful:
		return (28.0 if active_ready else 20.0) + big + rng.randf()
	return 5.0 + rng.randf()


func _usable_attacks(g: Game, p: PokemonInPlay) -> int:
	var n := 0
	for atk in p.attacks():
		if g.attack_usable(p, atk):
			n += 1
	return n


## ¿La Energía ayuda a pagar algún ataque que todavía no se puede usar?
func _helps_cost(p: PokemonInPlay, id: String) -> bool:
	var provided: Array = Energy.units_of_card(id, p)[0]
	for atk in p.attacks():
		var cost: Array = atk.get("cost", [])
		if Energy.can_pay(p, cost):
			continue
		for c in cost:
			if c == "Colorless" or c in provided or Energy.ANY in provided:
				return true
	return false


func _trainer_score(g: Game, me: PlayerState, a: Dictionary) -> float:
	var id: String = me.hand[a["h"]]
	var name := CardDB.card_name(id)
	var p: Dictionary = a["p"]
	if name in Trainers.TOOLS:
		return 15.0 if p["tg"] == -1 else 8.0
	if name in Trainers.TMS:
		return -5.0
	if name in Trainers.STADIUMS:
		return 10.0 if g.stadium == "" or g.stadium_owner != me.index else -5.0
	match name:
		"Professor Birch":
			return 50.0 if me.hand.size() <= 4 else -5.0
		"Steven's Advice":
			return 45.0 if me.hand.size() <= 3 else -5.0
		"TV Reporter", "Team Aqua Schemer", "Team Magma Schemer":
			return 40.0 if me.hand.size() <= 5 else -5.0
		"Rare Candy", "Wally's Training":
			return 70.0
		"Archie", "Maxie":
			return 55.0
		"Lanette's Net Search", "Team Aqua Conspirator", "Team Magma Conspirator":
			return 35.0 if me.bench.size() < 3 else 10.0
		"Lady Outing":
			return 30.0 if me.hand.filter(func(c): return CardDB.is_energy(c)).size() < 2 else -5.0
		"Energy Search":
			return 25.0 if not me.hand.any(func(c): return CardDB.is_energy(c)) else -5.0
		"Poké Ball", "Dual Ball", "Team Aqua Ball", "Team Magma Ball", "PokéNav":
			return 20.0
		"Potion":
			return 25.0 if me.slot(p["tg"]).damage >= 20 else -5.0
		"Life Herb":
			return 30.0 if me.slot(p["tg"]).damage >= 50 else -5.0
		"Energy Removal 2":
			return 25.0 if p["tg"] == -1 else 10.0
		"Pokémon Reversal", "Warp Point":
			return 5.0
		"Double Full Heal":
			return 30.0
		"Switch":
			return 30.0 if me.active.rotation in ["asleep", "paralyzed"] else -10.0
		"Energy Restore", "Energy Recycle System":
			return 10.0 if me.hand.filter(func(c): return CardDB.is_energy(c)).is_empty() else -5.0
		"Mr. Briney's Compassion":
			return 20.0 if me.slot(p["tg"]).hp_left() <= 30 else -10.0
		"Copycat":
			return 45.0 if g.other(me).hand.size() >= me.hand.size() + 3 else -5.0
		"Professor Oak's Research":
			return 45.0 if me.hand.size() <= 3 else -5.0
		"Desert Shaman":
			return 35.0 if me.hand.size() <= 2 and g.other(me).hand.size() >= 5 else -5.0
		"Professor Elm's Training Method":
			return 40.0 if me.all_in_play().any(func(x): return x.is_basic()) else 5.0
		"Pokémon Fan Club":
			return 35.0 if me.bench.size() < 3 else 10.0
		"Oracle", "Underground Expedition":
			return 25.0 if me.hand.size() <= 4 else -5.0
		"Friend Ball":
			return 20.0
		"Town Volunteers":
			return 15.0 if me.deck.size() < 15 else -5.0
		"Pokémon Nurse":
			return 30.0 if me.slot(p["tg"]).damage >= 60 and me.slot(p["tg"]).energy.size() <= 1 else -10.0
	if v2:
		return _trainer_score_v2(g, me, id, name, p)
	return -10.0


## Entrenadores que la tabla de arriba no conocía (antes quedaban en -10 y casi nunca se
## jugaban). Primero por nombre; si no, por lo que dice la carta.
func _trainer_score_v2(g: Game, me: PlayerState, id: String, name: String, p: Dictionary) -> float:
	var hand := me.hand.size()
	var no_energy := not me.hand.any(func(c): return CardDB.is_energy(c))
	var bench_room: bool = me.bench.size() < g.rules.bench_size
	var opp := g.other(me)
	var tgt: PokemonInPlay = me.slot(int(p["tg"])) if p.has("tg") else null
	match name:
		"Prof. Oak's Research":
			return 45.0 if hand <= 3 else -5.0
		"Bill's Maintenance":
			return 30.0 if hand <= 5 else 5.0
		"Fieldworker", "Mary's Request":
			return 40.0 if hand <= 5 else 10.0
		"Professor Cozmo's Discovery":
			return 30.0 if hand <= 4 else 5.0
		"Rocket's Mission", "Holon Adventurer", "Juggler":
			return 30.0 if hand <= 5 else 5.0
		"Holon Scientist":
			return 35.0 if opp.hand.size() >= hand + 2 else -5.0
		"Master Ball", "Celio's Network", "Rocket's Poké Ball", "Fast Ball", "Holon Researcher", "Holon Mentor", "Scott", \
				"Forest Guardian", "Castaway", "Holon Transceiver", "VS Seeker":
			return 25.0
		"Great Ball":
			return 30.0 if bench_room else -10.0
		"Moo-Moo Milk":
			return 20.0 if tgt != null and tgt.damage >= 30 else -5.0
		"Hyper Potion", "Night Pokémon Center":
			return 20.0 if tgt != null and tgt.damage >= 50 else -10.0
		"Full Heal":
			return 25.0
		"Fisherman", "Holon Lass":
			return 25.0 if no_energy else 0.0
		"Power Charge", "Energy Charge", "Pokémon Retriever", "Lure Ball", "Old Rod":
			return 8.0
	# Por el texto de la carta (Objetos y Partidarios que no tienen puntaje propio)
	var txt := str(CardDB.get_card(id).get("text", ""))
	if CardDB.is_supporter(id) and txt.contains("draw"):
		return 35.0 if hand <= 4 else 0.0
	if txt.contains("Search your deck for") and (txt.contains("Pokémon") or txt.contains("Evolution")):
		return 20.0
	if txt.contains("basic Energy") and txt.contains("into your hand"):
		return 20.0 if no_energy else -5.0
	if txt.begins_with("Remove") and txt.contains("damage counter"):
		return 15.0 if tgt != null and tgt.damage >= 30 else -5.0
	return 2.0 if not CardDB.is_supporter(id) else 5.0     # que la búsqueda en copia la pueda probar


func _best_attack_damage(g: Game, p: PokemonInPlay) -> int:
	var best := 0
	for atk in p.attacks():
		if g.attack_usable(p, atk):
			best = max(best, int(atk.get("damage", 0)))
	return best


func _attack_value(g: Game, me: PlayerState, opp: PlayerState, a: Dictionary) -> float:
	var atk: Dictionary = me.active.attacks()[a["a"]]
	var ops: Array = AttackEffects.parse(me.active.top(), atk)["ops"]
	var opt = a.get("opt", false)
	if opt is Dictionary and opt.has("gm_card"):     # Genetic Memory: se evalúa el ataque elegido
		atk = CardDB.get_card(opt["gm_card"])["attacks"][int(opt["gm_a"])]
		ops = AttackEffects.parse(opt["gm_card"], atk)["ops"]
		opt = opt.get("gm_opt", false)
	var dmg := float(atk.get("damage", 0))
	var value := 0.0
	# v2: el daño sale de AIEval.attack_estimate (mira las condiciones de verdad: si el Defensor
	# no es ex, "+40 si es ex" no suma; si no está dormido, Dream Eater no hace nada).
	var est := v2 and not (a.get("opt", false) is Dictionary)
	if est:
		dmg = AIEval.attack_estimate(g, me.active, atk, opp.active)
	for op in ops:
		if op.get("optional", false) and not opt:
			continue
		var c: String = op.get("c", "")
		var weight := 0.5 if c in ["heads", "tails", "any_heads"] else 1.0
		if c == "did" and not opt:
			continue
		if est and c not in ["", "did", "heads", "tails", "any_heads", "any_tails", "all_heads", "all_tails", "heads_at_least"] \
				and not AttackEffects._cond_ok(g, op, {"coins": [], "heads": 0, "flips": 0, "did": true, "opt": opt}, me, opp, me.active, opp.active):
			continue
		if est and op["k"] in ["bonus", "set_base", "flips", "until_tails", "nothing", "formula"]:
			continue
		match op["k"]:
			"burst_choice":
				var t: String = opt if opt is String else ""
				dmg = op["n"] * me.active.energy.filter(func(e): return AttackEffects.burst_counts(e, t)).size()
			"return_all_basic":
				if opt:
					var nb := me.active.energy.filter(func(e): return CardDB.is_basic_energy(e)).size()
					dmg = op["base"] + op["per"] * nb
					value -= 5.0 * nb
			"any_energy":
				var k: int = opt if opt is int else 0
				dmg = op["base"] + op["per"] * k
				value -= 6.0 * k     # perder Energías tiene un costo
			"bonus": dmg += op["n"] * weight
			"set_base": dmg = op["n"] * weight + dmg * (1.0 - weight)
			"flips":
				if op["mode"] == "times":
					dmg = op["n"] * float(op["count"] if op["count"] is int else 2) * 0.5
				elif op["mode"] == "plus":
					dmg += op["n"] * float(op["count"] if op["count"] is int else 2) * 0.5
				elif op["mode"] == "all_or_each":
					dmg += op["n"] * float(op["count"]) * 0.5
			"until_tails": dmg = op["n"]
			"nothing": dmg *= 0.5
			"formula": dmg += op["n"]
			"status": value += 10.0 * weight
			"draw": value += 4.0 * op["n"]
			"snipe":
				var t := opp.slot(a["tg"])
				if t != null:
					value += op["n"] * weight + (100.0 if t.hp_left() <= op["n"] else 0.0)
			"spread": value += op["n"] * 0.5
			"self_damage": value -= op["n"] * 0.5
			"discard_self":
				if not op.get("optional", false):
					value -= 8.0 * min(op["count"], 4)
				else:
					value -= 6.0
			"heal_self": value += 5.0 * op["n"] if me.active.damage > 0 else 0.0
			"attach": value += 15.0
			"bench_search", "search_hand": value += 10.0
	var d := opp.active
	if dmg > 0 and not est:
		var types := me.active.types()
		if types.any(func(t): return t in d.data().get("weaknesses", [])):
			dmg *= 2
		if types.any(func(t): return t in d.data().get("resistances", [])):
			dmg -= 30
	if dmg > 0 and dmg >= d.hp_left():
		value += 100.0 * (2 if d.is_ex() else 1)
	return dmg + value
