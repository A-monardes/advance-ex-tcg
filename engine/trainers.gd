class_name Trainers
extends RefCounted
## Cartas de Entrenador de la era ADV. Cada carta define:
##   options(g, me, hand_idx) -> parámetros posibles (vacío = no se puede jugar ahora)
##   play(g, me, card_id, params)
## Las decisiones que dependen de algo oculto (monedas, robar, mirar el mazo)
## se piden después con g.ask(...).

const TOOLS := ["Lum Berry", "Oran Berry", "Balloon Berry", "Buffer Piece", "Strength Charm",
		"Team Aqua Belt", "Team Magma Belt", "Weakness Guard",
		"Healing Berry", "Memory Berry", "Time Shard", "Crystal Shard", "Star Piece", "EXP.ALL",
		"Curse Powder", "Energy Root", "Fluffy Berry", "Protective Orb", "Sitrus Berry", "Solid Rage",
		"Cessation Crystal", "Mysterious Shard"]
## Herramientas que no van en Pokémon-ex.
const TOOLS_NO_EX := ["Cessation Crystal", "Mysterious Shard"]
## Herramientas solo para evolucionados que no sean ex / para los que no sean ex, Dark ni con dueño.
const TOOLS_EVOLVED := ["Curse Powder", "Protective Orb", "Solid Rage"]
const TOOLS_PLAIN := ["Energy Root", "Fluffy Berry", "Sitrus Berry"]
const FOSSIL_MONS := ["Omanyte", "Kabuto", "Aerodactyl", "Aerodactyl ex", "Lileep", "Anorith"]
const TMS := ["Team Aqua Technical Machine 01", "Team Magma Technical Machine 01",
		"Ancient Technical Machine [Ice]", "Ancient Technical Machine [Rock]", "Ancient Technical Machine [Steel]",
		"Multi Technical Machine 01", "Darkness Cube 01", "Fighting Cube 01", "Fire Cube 01", "Grass Cube 01",
		"Lightning Cube 01", "Metal Cube 01", "Psychic Cube 01", "Water Cube 01",
		"Miracle Sphere α", "Miracle Sphere β", "Miracle Sphere γ",
		"Mystery Plate α", "Mystery Plate β", "Mystery Plate γ", "Mystery Plate δ"]
## Miracle Spheres: a qué tipos de Pokémon evolucionado se pueden unir.
const SPHERE_TYPES := {"Miracle Sphere α": ["Fire", "Lightning", "Fighting"],
		"Miracle Sphere β": ["Fire", "Water", "Psychic"], "Miracle Sphere γ": ["Grass", "Water", "Lightning"]}
const STADIUMS := ["High Pressure System", "Low Pressure System", "Team Aqua Hideout", "Team Magma Hideout",
		"Ancient Tomb", "Desert Ruins", "Island Cave", "Magnetic Storm",
		"Apricorn Forest", "Pokémon Park", "Undersea Ruins", "Power Plant", "Ancient Ruins", "Mirage Stadium",
		"Mystery Zone", "Underground Lake",
		"Mt. Moon", "Rocket's Hideout", "Rocket's Tricky Gym", "Meteor Falls", "Space Center", "Battle Frontier",
		"Holon Research Tower", "Holon Ruins", "Cursed Stone", "Full Flame", "Giant Stump", "Power Tree", "Strange Cave",
		"Holon Lake", "Championship Arena",
		"Crystal Beach", "Holon Circle", "Holon Legacy", "Drake's Stadium", "Glacia's Stadium", "Phoebe's Stadium",
		"Sidney's Stadium",
		# Diamond & Pearl
		"Speed Stadium"]
## Estadios con una acción "una vez por turno" (aparecen como acción del jugador).
const STADIUM_ACTIONS := ["Apricorn Forest", "Undersea Ruins", "Power Plant", "Ancient Ruins", "Mystery Zone",
		"Underground Lake", "Holon Ruins", "Power Tree", "Strange Cave", "Speed Stadium"]
const STADIUM_SLOT := -9     # "lugar" de las acciones de Estadio (no es un Pokémon)
const OTHERS := [
	"Energy Removal 2", "Energy Restore", "Energy Switch", "Lady Outing", "Poké Ball", "Pokémon Reversal",
	"PokéNav", "Professor Birch", "Energy Search", "Potion", "Switch", "Double Full Heal",
	"Lanette's Net Search", "Rare Candy", "Wally's Training", "Energy Recycle System",
	"Mr. Briney's Compassion", "TV Reporter", "Team Aqua Schemer", "Team Magma Schemer", "Archie",
	"Dual Ball", "Maxie", "Team Aqua Ball", "Team Magma Ball", "Team Aqua Conspirator",
	"Team Magma Conspirator", "Warp Point", "Life Herb", "Steven's Advice",
	# Sets anteriores, legales en el Mundial 2004 (Expedition, Aquapolis, Skyridge)
	"Copycat", "Pokémon Nurse", "Professor Elm's Training Method", "Professor Oak's Research",
	"Pokémon Fan Club", "Town Volunteers", "Desert Shaman", "Friend Ball", "Oracle", "Underground Expedition",
	# Nintendo Black Star Promos
	"Tropical Wind",
	# e-card: Objetos
	"Master Ball", "Power Charge", "Super Scoop Up", "Full Heal", "Moo-Moo Milk", "Super Energy Removal 2",
	"Fast Ball", "Hyper Potion", "Lure Ball",
	# e-card: Partidarios
	"Bill's Maintenance", "Mary's Impulse", "Forest Guardian", "Juggler", "Seer", "Traveling Salesman",
	"Relic Hunter", "Apricorn Maker", "Fisherman",
	# FireRed & LeafGreen ... Emerald, POP y promos
	"Celio's Network", "Great Ball", "PokéDex HANDY909", "Prof. Oak's Research", "VS Seeker",
	"Pokémon Retriever", "Pow! Hand Extension", "Rocket's Admin.", "Rocket's Mission", "Rocket's Poké Ball",
	"Surprise! Time Machine", "Swoop! Teleporter", "Venture Bomb", "Here Comes Team Rocket!", "Energy Charge",
	"Professor Cozmo's Discovery", "Mr. Stone's Project", "Scott", "Tropical Tidal Wave",
	# Unseen Forces ... Holon Phantoms
	"Mary's Request", "Holon Farmer", "Holon Lass", "Holon Mentor", "Holon Researcher", "Holon Scientist",
	"Holon Adventurer", "Fieldworker", "Holon Transceiver", "Holon Fossil",
	# Crystal Guardians, Dragon Frontiers, Power Keepers
	"Castaway", "Windstorm", "Island Hermit", "Old Rod",
	# Diamond & Pearl
	"Night Pokémon Center", "PlusPower", "Pokédex HANDY910is", "Professor Rowan", "Rival",
]


static func is_implemented(card_id: String) -> bool:
	var n := CardDB.card_name(card_id)
	return CardDB.is_fossil(card_id) or n in TOOLS or n in TMS or n in STADIUMS or n in OTHERS


# ===========================================================================
# Opciones
# ===========================================================================

## Dobles: cartas que hablan de "tu Activo" (se ofrecen también sobre el segundo Activo).
const USES_ACTIVE := ["Switch", "Wally's Training", "Double Full Heal"]

static func uses_active(id: String) -> bool:
	return CardDB.card_name(id) in USES_ACTIVE


static func options(g: Game, me: PlayerState, hand_idx: int) -> Array:
	var id := me.hand[hand_idx]
	var n := CardDB.card_name(id)
	var opp := g.other(me)
	var out: Array = []
	if n in TOOLS:
		for s in me.slots():
			var p := me.slot(s)
			if n == "EXP.ALL" and (p.is_ex() or p.has_owner()):
				continue
			if n in TOOLS_EVOLVED and (not p.is_evolved() or p.is_ex()):
				continue
			if n in TOOLS_PLAIN and (p.is_ex() or p.name_has("Dark") or p.has_owner()):
				continue
			if n in TOOLS_NO_EX and p.is_ex():
				continue
			if p.tool == "" and (not n.begins_with("Team Aqua") or p.name_has("Team Aqua")) \
					and (not n.begins_with("Team Magma") or p.name_has("Team Magma")):
				out.append({"tg": s})
		return out
	if n in TMS:
		for s in me.slots():
			var p := me.slot(s)
			if p.tm != "" or p.is_fossil():
				continue
			if n.begins_with("Ancient") and (not p.is_evolved() or p.is_ex() or p.has_owner()) \
					and not Abilities.body(g, p, "Synchronicity"):
				continue
			if n.begins_with("Team Aqua") and not p.name_has("Team Aqua"):
				continue
			if n.begins_with("Team Magma") and not p.name_has("Team Magma"):
				continue
			if not tm_fits(g, n, p):
				continue
			out.append({"tg": s})
		return out
	if n in STADIUMS:
		if g.stadium_name() != n:
			out.append({})
		return out
	match n:
		"Potion":
			for s in me.slots():
				if me.slot(s).damage > 0:
					out.append({"tg": s})
		"Night Pokémon Center", "PlusPower":
			for s in me.slots():
				out.append({"tg": s})
		"Pokédex HANDY910is", "Rival":
			if not me.deck.is_empty():
				out.append({})
		"Professor Rowan":
			if me.hand.size() >= 2:     # la carta misma + al menos otra
				var others: Array = me.hand.duplicate()
				others.remove_at(hand_idx)
				for pick in _distinct(others, func(_c): return true):
					out.append({"pick": pick})
		"Life Herb":
			for s in me.slots():
				var p := me.slot(s)
				if not p.is_ex() and (p.damage > 0 or p.has_special_condition()):
					out.append({"tg": s})
		"Switch":
			for b in me.bench.size():
				out.append({"b": b})
		"Energy Search":
			for pick in _distinct(me.deck, func(c): return CardDB.is_basic_energy(c)):
				out.append({"pick": pick})
		"Energy Removal 2":
			for s in opp.slots():
				var seen := {}
				var p := opp.slot(s)
				for e in p.energy.size():
					if not seen.has(p.energy[e]):
						seen[p.energy[e]] = true
						out.append({"tg": s, "e": e})
		"Energy Restore":
			if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Energy Switch":
			for a in me.slots():
				var seen := {}
				for e in me.slot(a).energy.size():
					var c: String = me.slot(a).energy[e]
					if CardDB.is_basic_energy(c) and not seen.has(c):
						seen[c] = true
						for b in me.slots():
							if b != a:
								out.append({"from": a, "e": e, "to": b})
		"Energy Recycle System":
			var basics := me.discard.filter(func(c): return CardDB.is_basic_energy(c))
			for pick in _distinct(me.discard, func(c): return CardDB.is_basic_energy(c)):
				out.append({"mode": "hand", "pick": pick})
			if basics.size() >= 3:
				out.append({"mode": "deck"})
		"Pokémon Reversal":
			# ecard1-146 / ex6-97 / ex10-88: vos elegís el Pokémon de la Banca; ex1-87: elige el rival
			if str(CardDB.get_card(id).get("text", "")).contains("your opponent switches"):
				if not opp.bench.is_empty():
					out.append({})
			else:
				for bi in opp.bench.size():
					out.append({"b": bi})
		"Warp Point":
			if not opp.bench.is_empty() or not me.bench.is_empty():
				out.append({})
		"Double Full Heal":
			if me.active.has_special_condition():
				out.append({})
		"Rare Candy":
			if me.turns_taken > 1:
				for s in me.slots():
					var p := me.slot(s)
					if p.is_evolved() or p.is_fossil() or p.turn_played == g.turn_number:
						continue
					if s == -1 and Abilities.evolve_active_blocked(g, me):
						continue
					# La carta permite Fase 1 o Fase 2, pero para una Fase 1 no tiene sentido (es igual
					# que evolucionar normalmente), así que solo se ofrecen las Fase 2.
					for ev in _distinct(me.hand, func(c): return _candy_fits(c, p) and CardDB.stage(c) == 2):
						out.append({"tg": s, "ev": ev})
		"Wally's Training":
			var a := me.active
			if me.turns_taken > 1 and a.turn_played < g.turn_number and not Abilities.evolve_active_blocked(g, me):
				for pick in _distinct(me.deck, func(c): return CardDB.evolves_onto(c, a.display_name())):
					out.append({"pick": pick})
		"Mr. Briney's Compassion":
			for s in me.slots():
				if not me.slot(s).is_ex() and (s != -1 or not me.bench.is_empty()):
					out.append({"tg": s})
		"Team Aqua Schemer", "Team Magma Schemer":
			for pick in _distinct(me.hand, func(c): return CardDB.is_pokemon(c)):
				out.append({"pick": pick})
		"Archie":
			if me.bench.size() < g.rules.bench_size:
				for pick in _distinct(me.deck, func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Team Aqua")):
					out.append({"pick": pick})
		"Maxie":
			if me.bench.size() < g.rules.bench_size:
				for pick in _distinct(me.hand, func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Team Magma")):
					out.append({"pick": pick, "from": "hand"})
				for pick in _distinct(me.discard, func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Team Magma")):
					out.append({"pick": pick, "from": "discard"})
		"Steven's Advice":     # ex5-92: no con más de 7 (contando esta); ex16-83: no con 7 o más
			if me.hand.size() <= (6 if str(CardDB.get_card(id).get("text", "")).contains("7 or more") else 7):
				out.append({})
		"Professor Birch", "Lady Outing", "Lanette's Net Search", "TV Reporter", "Poké Ball", "Dual Ball", \
				"Team Aqua Ball", "Team Magma Ball", "Team Aqua Conspirator", "Team Magma Conspirator":
			out.append({})
		"PokéNav":
			if not me.deck.is_empty():
				out.append({})
		"Copycat", "Professor Oak's Research", "Prof. Oak's Research", "Desert Shaman", "Rocket's Admin.", \
				"Here Comes Team Rocket!", "Professor Cozmo's Discovery", "Venture Bomb", "Tropical Tidal Wave":
			out.append({})
		"Celio's Network", "Rocket's Poké Ball", "PokéDex HANDY909":
			if not me.deck.is_empty():
				out.append({})
		"Great Ball":
			if me.bench.size() < g.rules.bench_size and not me.deck.is_empty():
				out.append({})
		"VS Seeker":
			if me.discard.any(func(c): return CardDB.is_supporter(c)):
				out.append({})
		"Pokémon Retriever":
			if me.discard.any(func(c): return CardDB.is_pokemon(c)):
				out.append({})
		"Energy Charge":
			if me.discard.any(func(c): return CardDB.is_energy(c)):
				out.append({})
		"Pow! Hand Extension":
			if me.prizes.size() > opp.prizes.size() and opp.active != null:
				if not opp.active.energy.is_empty() and not opp.bench.is_empty():
					out.append({"mode": "move"})
				for b in opp.bench.size():
					out.append({"mode": "gust", "b": b})
		"Rocket's Mission":
			for pick in _distinct(me.hand, func(_c): return true):
				out.append({"pick": pick})
		"Surprise! Time Machine":
			for s in me.slots():
				if me.slot(s).is_evolved():
					out.append({"tg": s})
		"Swoop! Teleporter":
			if me.deck.any(func(c): return CardDB.is_basic_pokemon(c) and not CardDB.is_ex(c)):
				for s in me.slots():
					var p := me.slot(s)
					if p.is_basic() and not p.is_ex() and not p.is_fossil():
						out.append({"tg": s})
		"Mr. Stone's Project":
			var ok := _stone_pred(id)
			if me.deck.any(ok):
				out.append({"from": "deck"})
			if me.discard.any(ok):
				out.append({"from": "discard"})
		"Scott":
			if me.deck.any(func(c): return CardDB.is_supporter(c) or CardDB.is_stadium(c)):
				out.append({})
		"Mary's Request", "Fieldworker":
			if not me.deck.is_empty():
				out.append({})
		"Holon Farmer", "Holon Lass", "Holon Mentor", "Holon Researcher", "Holon Scientist", "Holon Adventurer":
			# Hay que descartar otra carta de la mano
			var others: Array = me.hand.duplicate()
			others.remove_at(hand_idx)
			for pick in _distinct(others, func(_c): return true):
				out.append({"pick": pick})
		"Holon Transceiver":
			var hs := func(c): return CardDB.is_supporter(c) and CardDB.card_name(c).contains("Holon")
			if me.deck.any(hs):
				out.append({"from": "deck"})
			if me.discard.any(hs):
				out.append({"from": "discard"})
		"Holon Fossil":
			if me.bench.size() < g.rules.bench_size:
				out.append({})
		"Castaway":
			if me.deck.any(func(c): return CardDB.is_supporter(c) or CardDB.is_pokemon_tool(c) or CardDB.is_basic_energy(c)):
				out.append({})
		"Windstorm":
			if g.stadium != "" or g.players.any(func(pl): return pl.all_in_play().any(func(x): return x.tool != "")):
				out.append({})
		"Island Hermit":
			out.append({})
		"Old Rod":
			if not me.discard.is_empty():
				out.append({})

		"Professor Elm's Training Method", "Friend Ball", "Oracle", "Underground Expedition":
			if not me.deck.is_empty():
				out.append({})
		"Pokémon Fan Club":
			if me.bench.size() < g.rules.bench_size:
				out.append({})
		"Tropical Wind", "Mary's Impulse", "Super Energy Removal 2":
			out.append({})
		"Master Ball", "Fast Ball", "Forest Guardian", "Seer", "Traveling Salesman", "Relic Hunter", "Apricorn Maker":
			if not me.deck.is_empty():
				out.append({})
		"Power Charge":
			if me.discard.any(func(c): return CardDB.is_energy(c)):
				out.append({})
		"Super Scoop Up":
			for s in me.slots():
				if s != -1 or not me.bench.is_empty():
					out.append({"tg": s})
		"Full Heal":
			if me.active.has_special_condition():
				out.append({})
		"Moo-Moo Milk":
			for s in me.slots():
				if me.slot(s).damage > 0:
					out.append({"tg": s})
		"Hyper Potion":
			for s in me.slots():
				var p := me.slot(s)
				if p.damage > 0:
					for k in [1, 2]:
						if p.basic_energy_count() >= k:
							out.append({"tg": s, "n": k})
		"Lure Ball":
			if me.discard.any(func(c): return CardDB.is_evolution(c)):
				out.append({})
		"Bill's Maintenance":
			if me.hand.size() > 1:          # además de esta carta
				out.append({})
		"Juggler":
			if me.hand.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Fisherman":
			if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Town Volunteers":
			if me.discard.any(func(c): return Trainers._volunteer_ok(c)):
				out.append({})
		"Pokémon Nurse":
			for s in me.slots():
				if me.slot(s).damage > 0:
					out.append({"tg": s})
	return out


# ===========================================================================
# Efectos
# ===========================================================================

static func play(g: Game, me: PlayerState, card_id: String, prm: Dictionary) -> void:
	var opp := g.other(me)
	var n := CardDB.card_name(card_id)
	if n in TOOLS:
		var p := me.slot(prm["tg"])
		p.tool = card_id
		p.tool_turn = g.turn_number
		return
	if n in TMS:
		me.slot(prm["tg"]).tm = card_id
		return
	if n in STADIUMS:
		g.set_stadium(me, card_id)
		return
	match n:
		"Potion":
			var p := me.slot(prm["tg"])
			p.damage = max(0, p.damage - 20)
		"Night Pokémon Center":
			var p := me.slot(prm["tg"])
			var heads := g.flip_many(2)
			if heads == 2:
				p.damage = 0
				g.log_msg("  Removes all damage counters from %s." % p.display_name())
			elif heads == 0:
				me.discard.append_array(p.energy)
				p.energy.clear()
				g.log_msg("  Discards all Energy attached to %s." % p.display_name())
		"PlusPower":     # DP: se une al Pokémon y se descarta al final del turno (+10 al Activo rival)
			var p := me.slot(prm["tg"])
			var pp: Array = p.flags.get("plus_power", [0, -1])
			p.flags["plus_power"] = [(int(pp[0]) if int(pp[1]) == g.turn_number else 0) + 1, g.turn_number]
			g.log_msg("  PlusPower is attached to %s." % p.display_name())
		"Pokédex HANDY910is":
			var top: Array = []
			for i in mini(2, me.deck.size()):
				top.append(me.deck.pop_back())
			g.ask(me.index, "Pokédex HANDY910is: card to your hand", _card_options(_distinct(top, func(_c): return true), false), func(o):
				var rest := top.duplicate()
				rest.erase(o["id"])
				me.hand.append(o["id"])
				for c in rest:
					me.deck.push_front(c)     # al fondo del mazo
				g.log_msg("  Takes 1 card and puts %d on the bottom of the deck." % rest.size()))
		"Professor Rowan":
			if me.hand.has(prm["pick"]):
				me.hand.erase(prm["pick"])
				_hand_to_deck(g, me)
				me.hand.append(prm["pick"])
				g.log_msg("  Keeps %s and shuffles the rest of the hand into the deck." % CardDB.card_name(prm["pick"]))
				me.draw(4)
		"Rival":
			var top: Array = []
			for i in mini(5, me.deck.size()):
				top.append(me.deck.pop_back())
			g.log_msg("  Reveals: " + ", ".join(top.map(func(c): return CardDB.card_name(c))))
			_rival_pick(g, me, opp, top, [], mini(3, top.size()))
		"Master Ball":
			var top: Array = me.deck.slice(maxi(0, me.deck.size() - 7))
			var cands := _distinct(top, func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c))
			g.log_msg("  Looks at the top %d cards." % top.size())
			if cands.is_empty():
				g.shuffle(me.deck)
			else:
				var opts := _card_options(cands, false)
				opts.append({"label": "None", "id": "", "ai": 0.0})
				g.ask(me.index, "Master Ball: choose a Pokémon", opts, func(o):
					if o["id"] != "":
						_deck_to_hand(g, me, o["id"])
					else:
						g.shuffle(me.deck))
		"Power Charge":
			if g.flip():
				chain(g, me.index, "Power Charge: Energy to shuffle into your deck", 2,
						func(picked):
							var left: Array = me.discard.duplicate()
							for c in picked:
								left.erase(c)
							return _distinct(left, func(c): return CardDB.is_energy(c)), false,
						func(id):
							me.discard.erase(id)
							me.deck.append(id),
						func(): g.shuffle(me.deck))
		"Super Scoop Up":
			if g.flip():
				var t := me.slot(prm["tg"])
				if t != null:
					g.return_to_hand(me, t)
		"Full Heal":
			me.active.clear_conditions()
		"Moo-Moo Milk":
			var heads := g.flip_many(2)
			var t := me.slot(prm["tg"])
			t.damage = max(0, t.damage - 20 * heads)
		"Super Energy Removal 2":
			var heads := g.flip_many(2)
			var who: PokemonInPlay = opp.active if heads == 2 else (me.active if heads == 0 else null)
			var owner := opp if heads == 2 else me
			if who != null and not who.energy.is_empty():
				owner.discard.append_array(who.energy)
				who.energy.clear()
				g.log_msg("  All Energy attached to %s is discarded." % who.display_name())
		"Fast Ball":
			var shown := 0
			for i in range(me.deck.size() - 1, -1, -1):
				shown += 1
				if CardDB.is_evolution(me.deck[i]):
					var c: String = me.deck[i]
					me.deck.remove_at(i)
					me.hand.append(c)
					g.log_msg("  Reveals %d card(s) and takes %s." % [shown, CardDB.card_name(c)])
					break
			g.shuffle(me.deck)
		"Hyper Potion":
			var t := me.slot(prm["tg"])
			var k: int = prm["n"]
			for i in k:
				var e := ""
				for x in range(t.energy.size() - 1, -1, -1):
					if CardDB.is_basic_energy(t.energy[x]):
						e = t.energy[x]
						t.energy.remove_at(x)
						break
				me.discard.append(e)
			t.damage = max(0, t.damage - (30 if k == 1 else 50))
		"Lure Ball":
			var heads := g.flip_many(3)
			chain(g, me.index, "Lure Ball: Evolution card to your hand", heads,
					func(picked):
						var left: Array = me.discard.duplicate()
						for c in picked:
							left.erase(c)
						return _distinct(left, func(c): return CardDB.is_evolution(c)), false,
					func(id):
						me.discard.erase(id)
						me.hand.append(id),
					func(): pass)
		"Bill's Maintenance":
			g.ask(me.index, "Bill's Maintenance: card to shuffle into your deck", _card_options(me.hand, true).map(func(o):
					o["ai"] = -float(o["ai"])
					return o), func(o):
				if o["id"] in me.hand:
					me.hand.erase(o["id"])
					me.deck.append(o["id"])
					g.shuffle(me.deck)
					me.draw(3))
		"Mary's Impulse":
			var heads := 0
			while g.flip():
				heads += 1
			me.draw(2 * heads)
		"Forest Guardian":
			g.shuffle(me.deck)
			var top: Array = me.deck.slice(maxi(0, me.deck.size() - 7))
			g.ask(me.index, "Forest Guardian: choose 1 card", _card_options(top, true), func(o):
				_deck_to_hand(g, me, o["id"]))
		"Juggler":
			var thrown: Array = []
			chain(g, me.index, "Juggler: basic Energy to discard", 2,
					func(picked):
						var left: Array = me.hand.duplicate()
						for c in picked:
							left.erase(c)
						return _distinct(left, func(c): return CardDB.is_basic_energy(c)), true,
					func(id):
						me.hand.erase(id)
						me.discard.append(id)
						thrown.append(id),
					func():
						if thrown.size() == 1:
							me.draw(3)
						elif thrown.size() == 2:
							me.draw(5))
		"Seer":
			var found := 0
			for i in range(me.deck.size() - 1, maxi(-1, me.deck.size() - 7), -1):
				if CardDB.is_basic_energy(me.deck[i]):
					me.hand.append(me.deck[i])
					me.deck.remove_at(i)
					found += 1
			g.log_msg("  Takes %d basic Energy card(s)." % found)
			g.shuffle(me.deck)
		"Traveling Salesman":
			_pick_sequence(g, me, "Traveling Salesman: TM or Pokémon Tool", 2,
					func(_p): return _distinct(me.deck, func(c): return CardDB.is_tm(c) or CardDB.is_pokemon_tool(c)), [])
		"Relic Hunter":
			_pick_sequence(g, me, "Relic Hunter: Supporter or Stadium", 2,
					func(_p): return _distinct(me.deck, func(c): return CardDB.is_supporter(c) or CardDB.is_stadium(c)), [])
		"Apricorn Maker":
			_pick_sequence(g, me, "Apricorn Maker: Ball card", 2,
					func(_p): return _distinct(me.deck, func(c): return CardDB.is_trainer(c) and CardDB.card_name(c).contains("Ball")), [])
		"Fisherman":
			chain(g, me.index, "Fisherman: basic Energy to your hand", 4,
					func(picked):
						var left: Array = me.discard.duplicate()
						for c in picked:
							left.erase(c)
						return _distinct(left, func(c): return CardDB.is_basic_energy(c)), false,
					func(id):
						me.discard.erase(id)
						me.hand.append(id),
					func(): pass)
		"Tropical Wind":
			var heads := g.flip()
			for pl in [me, opp]:
				for p in pl.actives():
					if heads:
						p.damage = max(0, p.damage - 20)
					else:
						g.try_condition(p, "asleep")
		"Life Herb":
			if g.flip():
				var p := me.slot(prm["tg"])
				p.clear_conditions()
				p.damage = max(0, p.damage - 60)
		"Switch":
			g.switch_active(me, prm["b"])
		"Energy Search", "Wally's Training":
			if n == "Wally's Training":
				me.deck.erase(prm["pick"])
				g.evolve(me, me.active, prm["pick"])
				g.shuffle(me.deck)
			else:
				_deck_to_hand(g, me, prm["pick"])
		"Energy Removal 2":
			if g.flip():
				var p := opp.slot(prm["tg"])
				var e: String = p.energy[prm["e"]]
				p.energy.remove_at(prm["e"])
				opp.discard.append(e)
				g.log_msg("  Discards %s from %s." % [CardDB.card_name(e), p.display_name()])
		"Energy Restore":
			var heads := g.flip_many(3)
			chain(g, me.index, "Energy Restore: basic Energy to your hand", heads,
					func(_p): return _distinct(me.discard, func(c): return CardDB.is_basic_energy(c)), false,
					func(id):
						me.discard.erase(id)
						me.hand.append(id)
						g.log_msg("  Gets back %s." % CardDB.card_name(id)),
					func(): pass)
		"Energy Switch":
			var from := me.slot(prm["from"])
			var e: String = from.energy[prm["e"]]
			from.energy.remove_at(prm["e"])
			me.slot(prm["to"]).energy.append(e)
		"Energy Recycle System":
			if prm["mode"] == "hand":
				me.discard.erase(prm["pick"])
				me.hand.append(prm["pick"])
			else:
				for i in 3:
					me.deck.append(Abilities._take(me.discard, func(c): return CardDB.is_basic_energy(c)))
				g.shuffle(me.deck)
		"Pokémon Reversal":
			if g.flip():
				if prm.has("b"):
					if prm["b"] < opp.bench.size():
						g.switch_active(opp, prm["b"])
				else:
					g.queue_choice(opp.index, "switch")
		"Warp Point":
			if not opp.bench.is_empty():
				g.queue_choice(opp.index, "switch")
			if not me.bench.is_empty():
				g.queue_choice(me.index, "switch")
		"Double Full Heal":
			me.active.clear_conditions()
		"Rare Candy":
			me.hand.erase(prm["ev"])
			g.evolve(me, me.slot(prm["tg"]), prm["ev"])
		"Professor Birch":
			me.draw(max(0, 6 - me.hand.size()))
		"Steven's Advice":
			me.draw(opp.all_in_play().size())
		"TV Reporter":
			me.draw(3)
			if not me.hand.is_empty():
				g.ask(me.index, "Discard 1 card", _card_options(me.hand, true), func(o):
					me.hand.erase(o["id"])
					me.discard.append(o["id"]))
		"Team Aqua Schemer", "Team Magma Schemer":
			me.hand.erase(prm["pick"])
			me.discard.append(prm["pick"])
			var team := "Team Aqua" if n.begins_with("Team Aqua") else "Team Magma"
			me.draw(4 if CardDB.card_name(prm["pick"]).contains(team) else 3)
		"Mr. Briney's Compassion":
			g.return_to_hand(me, me.slot(prm["tg"]))
		"Archie":
			me.deck.erase(prm["pick"])
			_bench_as_basic(g, me, prm["pick"])
			g.shuffle(me.deck)
		"Maxie":
			if prm["from"] == "hand":
				me.hand.erase(prm["pick"])
			else:
				me.discard.erase(prm["pick"])
			_bench_as_basic(g, me, prm["pick"])
		"Poké Ball":
			if g.flip():
				_ask_from_deck(g, me, "Choose a Pokémon", func(c): return CardDB.is_pokemon(c))
			else:
				g.log_msg("  Didn't find anything.")
		"Dual Ball":
			var heads := g.flip_many(2)
			# ecard1-139: "other than a Baby Pokémon card"
			var no_baby := str(CardDB.get_card(card_id).get("text", "")).contains("other than a Baby")
			_ask_repeat(g, me, heads, "Choose a Basic Pokémon", func(c): return CardDB.is_basic_pokemon(c) and not (no_baby and CardDB.is_baby(c)))
		"Team Aqua Ball", "Team Magma Ball":
			var team := "Team Aqua" if n.begins_with("Team Aqua") else "Team Magma"
			if g.flip():
				_ask_from_deck(g, me, "Choose a " + team + " Pokémon", func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains(team))
			else:
				_ask_from_deck(g, me, "Choose a " + team + " Basic Pokémon", func(c): return CardDB.is_basic_pokemon(c) and CardDB.card_name(c).contains(team))
		"Lady Outing":
			var fn := func(picked: Array) -> Array:
				var types := picked.map(func(c): return CardDB.basic_energy_type(c))
				return Trainers._distinct(me.deck, func(c): return CardDB.is_basic_energy(c) and CardDB.basic_energy_type(c) not in types)
			_pick_sequence(g, me, "Energy (different types)", 3, fn, [])
		"Lanette's Net Search":
			var fn := func(picked: Array) -> Array:
				var types := picked.map(func(c): return Trainers._first_type(c))
				return Trainers._distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c) and not CardDB.is_baby(c) and Trainers._first_type(c) not in types)
			_pick_sequence(g, me, "Basic Pokémon (different types)", 3, fn, [])
		"Team Aqua Conspirator", "Team Magma Conspirator":
			var team := "Team Aqua" if n.begins_with("Team Aqua") else "Team Magma"
			var fn := func(_picked: Array) -> Array:
				return Trainers._distinct(me.deck, func(c): return CardDB.is_basic_energy(c) \
						or (CardDB.is_basic_pokemon(c) and CardDB.card_name(c).contains(team)))
			_pick_sequence(g, me, team + " Basic Pokémon or Energy", 2, fn, [])
		"Copycat":
			_hand_to_deck(g, me)
			me.draw(opp.hand.size())
		"Professor Oak's Research", "Prof. Oak's Research":
			_hand_to_deck(g, me)
			me.draw(5)
		"Mary's Request":
			me.draw(1)
			if not me.all_in_play().any(func(x): return CardDB.stage(x.top()) == 2):
				me.draw(2)
		"Fieldworker":
			me.draw(3)
			if not opp.deck.is_empty():
				g.ask(opp.index, "Fieldworker: draw a card?", [{"label": "Draw a card", "d": true, "ai": 1.0}, {"label": "Don't draw", "d": false, "ai": 0.0}], func(o):
					if o["d"]:
						opp.draw(1))
		"Holon Farmer", "Holon Lass", "Holon Mentor", "Holon Researcher", "Holon Scientist", "Holon Adventurer":
			if not me.hand.has(prm["pick"]):
				return
			me.hand.erase(prm["pick"])
			me.discard.append(prm["pick"])
			g.log_msg("  Discards %s." % CardDB.card_name(prm["pick"]))
			_holon_supporter(g, me, opp, n, prm["pick"])
		"Castaway":
			var fn := func(picked: Array) -> Array:
				var kinds := picked.map(func(c): return Trainers._castaway_kind(c))
				return Trainers._distinct(me.deck, func(c): return Trainers._castaway_kind(c) != "" and Trainers._castaway_kind(c) not in kinds)
			_pick_sequence(g, me, "Castaway: Supporter, Pokémon Tool, basic Energy", 3, fn, [])
		"Windstorm":
			_windstorm(g, me, 2)
		"Island Hermit":
			var faceup: Array = me.flags.get("faceup_prizes", [])
			var shown := 0
			for i in me.prizes.size():
				if shown < 2 and not faceup.has(me.prizes[i]):
					faceup.append(me.prizes[i])
					shown += 1
			me.flags["faceup_prizes"] = faceup
			if shown > 0:
				g.log_msg("  Turns %d Prize card(s) face up." % shown)
			me.draw(2)
		"Old Rod":
			var h := g.flip_many(2)
			var pred := Callable()
			if h == 2:
				pred = func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c)
			elif h == 0:
				pred = func(c): return CardDB.is_trainer(c)
			if pred.is_valid():
				var cands := _distinct(me.discard, pred)
				if not cands.is_empty():
					g.ask(me.index, "Old Rod: card to your hand", _card_options(cands, false), func(o):
						if me.discard.has(o["id"]):
							me.discard.erase(o["id"])
							me.hand.append(o["id"]))
		"Holon Transceiver":
			var hs := func(c): return CardDB.is_supporter(c) and CardDB.card_name(c).contains("Holon")
			if prm["from"] == "deck":
				_ask_from_deck(g, me, "Holon Transceiver: Holon Supporter", hs)
			else:
				g.ask(me.index, "Holon Transceiver: Holon Supporter", _card_options(_distinct(me.discard, hs), false), func(o):
					if me.discard.has(o["id"]):
						me.discard.erase(o["id"])
						me.hand.append(o["id"]))
		"Holon Fossil":
			if g.flip():
				var cands := _distinct(me.deck, func(c): return CardDB.card_name(c) in FOSSIL_MONS)
				if cands.is_empty():
					g.shuffle(me.deck)
				else:
					g.ask(me.index, "Holon Fossil: Pokémon for your Bench", _card_options(cands, false), func(o):
						if me.deck.has(o["id"]) and me.bench.size() < g.rules.bench_size:
							me.deck.erase(o["id"])
							me.bench.append(PokemonInPlay.new(o["id"], g.turn_number))
						g.shuffle(me.deck))
			else:
				var cands := _distinct(me.hand, func(c): return CardDB.card_name(c) in FOSSIL_MONS)
				if not cands.is_empty():
					g.ask(me.index, "Holon Fossil: Pokémon from your hand to your Bench", _card_options(cands, false), func(o):
						if me.hand.has(o["id"]) and me.bench.size() < g.rules.bench_size:
							me.hand.erase(o["id"])
							me.bench.append(PokemonInPlay.new(o["id"], g.turn_number)))
		"Celio's Network":
			_ask_from_deck(g, me, "Celio's Network: Pokémon (not ex)", func(c): return CardDB.is_pokemon(c) and not CardDB.is_ex(c) and not CardDB.is_fossil(c))
		"Great Ball":
			var cands := _distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c) and not CardDB.is_ex(c))
			if cands.is_empty():
				g.log_msg("  Didn't find anything.")
				g.shuffle(me.deck)
			else:
				g.ask(me.index, "Great Ball: Basic Pokémon to your Bench", _card_options(cands, false), func(o):
					if me.deck.has(o["id"]) and me.bench.size() < g.rules.bench_size:
						me.deck.erase(o["id"])
						me.bench.append(PokemonInPlay.new(o["id"], g.turn_number))
						g.log_msg("  Puts %s on the Bench." % CardDB.card_name(o["id"]))
					g.shuffle(me.deck))
		"PokéDex HANDY909":
			g.shuffle(me.deck)
			var top: Array = []
			for i in mini(6, me.deck.size()):
				top.append(me.deck.pop_back())
			_rearrange_top(g, me, top, "PokéDex")
		"VS Seeker":
			g.ask(me.index, "VS Seeker: Supporter to your hand", _card_options(_distinct(me.discard, func(c): return CardDB.is_supporter(c)), false), func(o):
				if me.discard.has(o["id"]):
					me.discard.erase(o["id"])
					me.hand.append(o["id"]))
		"Pokémon Retriever":
			retriever(g, me, func(c): return CardDB.is_pokemon(c))
		"Pow! Hand Extension":
			if prm["mode"] == "gust":
				if prm["b"] < opp.bench.size():
					g.switch_active(opp, prm["b"])
			else:
				var d := opp.active
				var opts: Array = []
				for e in _distinct(d.energy, func(_c): return true):
					for b in opp.bench.size():
						opts.append({"label": "%s → %s" % [CardDB.card_name(e).replace(" Energy", ""), opp.bench[b].display_name()], "id": e, "b": b, "opp": true, "ai": 1.0})
				g.ask(me.index, "Pow! Hand Extension: move an Energy", opts, func(o):
					if opp.active == d and d.energy.has(o["id"]) and o["b"] < opp.bench.size():
						d.energy.erase(o["id"])
						opp.bench[o["b"]].energy.append(o["id"]))
		"Rocket's Admin.":
			for pl in [me, opp]:
				_hand_to_deck(g, pl)
				pl.draw(pl.prizes.size())
		"Rocket's Mission":
			if me.hand.has(prm["pick"]):
				me.hand.erase(prm["pick"])
				me.discard.append(prm["pick"])
				var nm := CardDB.card_name(prm["pick"])
				me.draw(4 if CardDB.is_pokemon(prm["pick"]) and (nm.contains("Dark") or nm.contains("Rocket's")) else 3)
		"Rocket's Poké Ball":
			_ask_from_deck(g, me, "Rocket's Poké Ball: Pokémon with Dark in its name", func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Dark"))
		"Surprise! Time Machine":
			var t := me.slot(prm["tg"])
			var cs: Array[String] = t.pop_stage()
			var c: String = cs[-1]
			me.deck.append_array(cs)
			t.clear_conditions()
			g.log_msg("  %s goes back into the deck." % CardDB.card_name(c))
			var nm := t.display_name()
			var evos := _distinct(me.deck, func(x): return CardDB.evolves_onto(x, nm))
			if evos.is_empty():
				g.shuffle(me.deck)
			else:
				g.ask(me.index, "Surprise! Time Machine: Evolution card", _card_options(evos, false), func(o):
					if me.deck.has(o["id"]) and me.all_in_play().has(t):
						me.deck.erase(o["id"])
						g.evolve(me, t, o["id"])
					g.shuffle(me.deck))
		"Swoop! Teleporter":
			var t := me.slot(prm["tg"])
			var cands := _distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c) and not CardDB.is_ex(c))
			g.ask(me.index, "Swoop! Teleporter: new Basic Pokémon", _card_options(cands, false), func(o):
				if me.deck.has(o["id"]) and me.all_in_play().has(t) and t.is_basic():
					me.deck.erase(o["id"])
					me.discard.append(t.cards[0])
					t.cards[0] = o["id"]
					g.log_msg("  %s takes its place." % CardDB.card_name(o["id"]))
				g.shuffle(me.deck))
		"Venture Bomb":
			var pl := opp if g.flip() else me
			var opts: Array = []
			for s in pl.slots():
				var mine := pl == me
				opts.append({"label": pl.slot(s).display_name(), "s": s, "opp": not mine,
						"ai": float(pl.slot(s).hp_left()) if mine else (100.0 if pl.slot(s).hp_left() <= 10 else 1.0)})
			g.ask(me.index, "Venture Bomb: 1 damage counter on...", opts, func(o):
				var t := pl.slot(o["s"])
				if t != null:
					t.damage += 10
					g.log_msg("  1 damage counter on %s." % t.display_name()))
		"Here Comes Team Rocket!":
			for pl in [me, opp]:
				pl.flags["prizes_face_up"] = true
			g.log_msg("  Prize cards are now played face up.")
		"Energy Charge":
			if g.flip():
				chain(g, me.index, "Energy Charge: Energy to shuffle into your deck", 2,
						func(picked):
							var left: Array = me.discard.duplicate()
							for c in picked:
								left.erase(c)
							return _distinct(left, func(c): return CardDB.is_energy(c)), false,
						func(id):
							me.discard.erase(id)
							me.deck.append(id),
						func(): g.shuffle(me.deck))
		"Professor Cozmo's Discovery":
			if g.flip():
				for i in mini(3, me.deck.size()):
					me.hand.append(me.deck.pop_front())
				g.log_msg("  Draws the bottom 3 cards.")
			else:
				me.draw(2)
		"Mr. Stone's Project":
			var ok := _stone_pred(card_id)
			if prm["from"] == "deck":
				_pick_sequence(g, me, "Mr. Stone's Project: Basic card", 2, func(_p): return _distinct(me.deck, ok), [])
			else:
				chain(g, me.index, "Mr. Stone's Project: Basic card", 2,
						func(picked):
							var left: Array = me.discard.duplicate()
							for c in picked:
								left.erase(c)
							return _distinct(left, ok), true,
						func(id):
							me.discard.erase(id)
							me.hand.append(id),
						func(): pass)
		"Scott":
			_pick_sequence(g, me, "Scott: Supporter or Stadium", 3,
					func(_p): return _distinct(me.deck, func(c): return CardDB.is_supporter(c) or CardDB.is_stadium(c)), [])
		"Tropical Tidal Wave":
			var heads := g.flip()
			var pl := opp if heads else me
			for x in pl.all_in_play():
				AttackEffects._strip_trainers(pl, x)
			if g.stadium != "" and g.stadium_owner == pl.index:
				g.discard_stadium()
			g.log_msg("  All Trainer cards %s in play are discarded." % ("the opponent has" if heads else "the player has"))

		"Desert Shaman":
			_hand_to_deck(g, me)
			_ask_draw_up_to(g, me, 4, func():
				Trainers._hand_to_deck(g, opp)
				Trainers._ask_draw_up_to(g, opp, 4, func(): pass))
		"Pokémon Nurse":
			var p := me.slot(prm["tg"])
			p.damage = 0
			me.discard.append_array(p.energy)
			p.energy.clear()
			g.log_msg("  %s is fully healed and discards its Energy." % p.display_name())
		"Professor Elm's Training Method":
			_ask_from_deck(g, me, "Choose an Evolution card", func(c): return CardDB.is_evolution(c))
		"Friend Ball":
			var types := {}
			for x in opp.all_in_play():
				for t in x.types():
					types[t] = true
			_ask_from_deck(g, me, "Pokémon of the same type as an opponent's Pokémon",
					func(c): return CardDB.is_pokemon(c) and CardDB.types(c).any(func(t): return types.has(t)))
		"Pokémon Fan Club":
			_fan_club(g, me, 2)
		"Town Volunteers":
			chain(g, me.index, "Town Volunteers: card to the deck", 5,
					func(_p): return _distinct(me.discard, func(c): return Trainers._volunteer_ok(c)), false,
					func(id):
						me.discard.erase(id)
						me.deck.append(id)
						g.log_msg("  Shuffles %s into the deck." % CardDB.card_name(id)),
					func(): g.shuffle(me.deck))
		"Oracle":
			_oracle(g, me, [])
		"Underground Expedition":
			var bottom: Array = me.deck.slice(0, mini(4, me.deck.size()))
			g.log_msg("  Looks at the bottom 4 cards of the deck.")
			_underground(g, me, bottom, 0)
		"PokéNav":
			var top: Array = []
			for i in min(3, me.deck.size()):
				top.append(me.deck[me.deck.size() - 1 - i])
			var ok := top.filter(func(c): return CardDB.is_pokemon(c) or CardDB.is_energy(c))
			g.log_msg("  Looks at: " + ", ".join(top.map(func(c): return CardDB.card_name(c))))
			if not ok.is_empty():
				g.ask(me.index, "PokéNav: choose 1", _card_options(ok, false), func(o):
					var i := me.deck.rfind(o["id"])
					me.deck.remove_at(i)
					me.hand.append(o["id"]))


# ===========================================================================
# Ayudantes
# ===========================================================================

## Elecciones encadenadas: hasta max_n cartas, de a una. cands_fn(elegidas) da las opciones;
## on_pick(id) se llama con cada elegida y on_done() al terminar. Con allow_stop aparece "Listo".
static func chain(g: Game, player: int, prompt: String, max_n: int, cands_fn: Callable, allow_stop: bool,
		on_pick: Callable, on_done: Callable, picked: Array = []) -> void:
	var cands: Array = cands_fn.call(picked) if picked.size() < max_n else []
	if cands.is_empty():
		on_done.call()
		return
	var opts := _card_options(cands, false)
	if allow_stop:
		opts.append({"label": "Done", "id": "", "ai": 0.0})
	var title := prompt if max_n <= 1 else "%s (%d/%d)" % [prompt, picked.size() + 1, max_n]
	g.ask(player, title, opts, func(o):
		if o["id"] == "":
			on_done.call()
			return
		on_pick.call(o["id"])
		Trainers.chain(g, player, prompt, max_n, cands_fn, allow_stop, on_pick, on_done, picked + [o["id"]]))


static func _hand_to_deck(g: Game, pl: PlayerState) -> void:
	pl.deck.append_array(pl.hand)
	pl.hand.clear()
	g.shuffle(pl.deck)


## "Robá hasta N cartas": el jugador elige cuántas.
static func _ask_draw_up_to(g: Game, pl: PlayerState, n: int, then: Callable) -> void:
	var opts: Array = []
	for k in range(mini(n, pl.deck.size()), -1, -1):
		opts.append({"label": "Draw %d" % k, "n": k, "ai": float(k)})
	g.ask(pl.index, "Desert Shaman: how many cards do you draw?", opts, func(o):
		pl.draw(o["n"])
		g.log_msg("  Player %d draws %d." % [pl.index + 1, o["n"]])
		then.call())


static func _volunteer_ok(c: String) -> bool:
	return CardDB.is_pokemon(c) or CardDB.is_basic_energy(c)


static func _volunteer_rank(c: String) -> int:
	if CardDB.is_evolution(c):
		return 0
	return 1 if CardDB.is_pokemon(c) else 2


## Pokémon Fan Club: hasta 2 Básicos del mazo a la Banca, de a uno.
static func _fan_club(g: Game, me: PlayerState, left: int) -> void:
	var cands := _distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c))
	if left <= 0 or cands.is_empty() or me.bench.size() >= g.rules.bench_size:
		g.shuffle(me.deck)
		return
	var opts := _card_options(cands, false)
	opts.append({"label": "Done", "id": "", "ai": 0.0})
	g.ask(me.index, "Pokémon Fan Club: Basic Pokémon to the Bench (%d/2)" % (3 - left), opts, func(o):
		if o["id"] == "":
			g.shuffle(me.deck)
			return
		me.deck.erase(o["id"])
		me.bench.append(PokemonInPlay.new(o["id"], g.turn_number))
		g.log_msg("  %s goes to the Bench." % CardDB.card_name(o["id"]))
		Trainers._fan_club(g, me, left - 1))


## Oracle: elegís 2 cartas del mazo; se baraja el resto y quedan arriba (la primera elegida, arriba de todo).
## Las elegidas siguen en el mazo hasta el final (así nunca quedan "en el aire").
static func _oracle(g: Game, me: PlayerState, chosen: Array) -> void:
	var avail: Array = me.deck.duplicate()
	for c in chosen:
		avail.erase(c)
	if chosen.size() >= 2 or avail.is_empty():
		for c in chosen:
			me.deck.erase(c)
		g.shuffle(me.deck)
		for i in range(chosen.size() - 1, -1, -1):
			me.deck.append(chosen[i])     # el final del Array es el tope del mazo
		g.log_msg("  Puts %d cards on top of the deck." % chosen.size())
		return
	var prompt := "Oracle: card for the very top" if chosen.is_empty() else "Oracle: second card"
	g.ask(me.index, prompt, _card_options(_distinct(avail, func(_c): return true), false), func(o):
		Trainers._oracle(g, me, chosen + [o["id"]]))


## Underground Expedition: de las 4 de abajo, 2 a la mano; el resto queda abajo.
static func _underground(g: Game, me: PlayerState, bottom: Array, taken: int) -> void:
	if taken >= 2 or bottom.is_empty():
		return
	g.ask(me.index, "Underground Expedition: choose 1 (%d/2)" % (taken + 1), _card_options(_distinct(bottom, func(_c): return true), false), func(o):
		var i := me.deck.find(o["id"])
		if i >= 0 and i < 4:
			me.deck.remove_at(i)
			me.hand.append(o["id"])
		var rest := bottom.duplicate()
		rest.erase(o["id"])
		Trainers._underground(g, me, rest, taken + 1))

## Restricciones de las Technical Machines e-card (Cubes: tipo; Miracle Spheres: evolucionado
## de ciertos tipos). Synchronicity (Xatu) acepta cualquiera.
static func tm_fits(g: Game, tm_name: String, p: PokemonInPlay) -> bool:
	if Abilities.body(g, p, "Synchronicity"):
		return true
	if tm_name.ends_with(" Cube 01"):
		return p.is_type(tm_name.trim_suffix(" Cube 01"))
	if SPHERE_TYPES.has(tm_name):
		return p.is_evolved() and SPHERE_TYPES[tm_name].any(func(t): return p.is_type(t))
	return true


## Acciones de los Estadios "una vez por turno" (Aquapolis, Skyridge).
static func stadium_actions(g: Game, me: PlayerState) -> Array:
	var n := g.stadium_name()
	if n not in STADIUM_ACTIONS or me.turn_flags.get("stadium_used", false):
		return []
	var full := me.bench.size() >= g.rules.bench_size
	var prms: Array = []
	match n:
		"Apricorn Forest":
			if not full and me.hand.any(func(c): return CardDB.is_basic_energy(c)):
				prms.append({})
		"Undersea Ruins":
			if me.all_in_play().any(func(x): return x.is_evolved()):
				prms.append({})
		"Power Plant":
			if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				for c in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
					prms.append({"pick": c})
		"Ancient Ruins":
			if not me.supporter_played and not me.deck.is_empty():
				prms.append({})
		"Mystery Zone":
			if me.hand.any(func(c): return CardDB.is_evolution(c)):
				prms.append({})
		"Holon Ruins":
			if not me.deck.is_empty() and me.all_in_play().any(func(x): return CardDB.is_delta(x.top())):
				prms.append({})
		"Power Tree":
			if not me.discard.any(func(c): return CardDB.is_energy(c) and not CardDB.is_basic_energy(c)) \
					and me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				prms.append({})
		"Strange Cave":
			if not full:
				for c in _distinct(me.hand, func(c): return CardDB.card_name(c) in FOSSIL_MONS):
					prms.append({"pick": c})
		"Speed Stadium":
			if not me.deck.is_empty():
				prms.append({})
		"Underground Lake":
			if not full:
				for c in _distinct(me.discard, func(c): return CardDB.card_name(c) in ["Omanyte", "Kabuto"]):
					prms.append({"pick": c})
	var out: Array = []
	for prm in prms:
		prm["stadium"] = true
		out.append({"t": "power", "s": STADIUM_SLOT, "n": n, "p": prm})
	return out


static func use_stadium(g: Game, me: PlayerState, n: String, prm: Dictionary) -> void:
	me.turn_flags["stadium_used"] = true
	g.log_msg("Player %d uses %s." % [me.index + 1, n])
	match n:
		"Speed Stadium":
			var heads := 0
			while g.flip():
				heads += 1
			me.draw(heads)
			g.log_msg("  %d heads: draws %d card(s)." % [heads, heads])
		"Apricorn Forest":
			if not g.flip():
				return
			var opts: Array = []
			for e in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
				opts.append({"label": CardDB.card_name(e), "id": e, "ai": 1.0})
			g.ask(me.index, "Apricorn Forest: show a basic Energy", opts, func(o):
				var t := CardDB.basic_energy_type(o["id"])
				var cands := _distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c) and t in CardDB.types(c))
				if cands.is_empty() or me.bench.size() >= g.rules.bench_size:
					g.log_msg("  Didn't find anything.")
					g.shuffle(me.deck)
					return
				g.ask(me.index, "Apricorn Forest: Basic Pokémon to your Bench", _card_options(cands, false), func(o2):
					me.deck.erase(o2["id"])
					me.bench.append(PokemonInPlay.new(o2["id"], g.turn_number))
					g.log_msg("  Puts %s on the Bench." % CardDB.card_name(o2["id"]))
					g.shuffle(me.deck)))
		"Undersea Ruins":
			if not g.flip():
				return
			var opts: Array = []
			for x in me.all_in_play():
				if x.is_evolved():
					opts.append({"label": x.display_name(), "mon": x, "ai": -1.0})
			g.ask(me.index, "Undersea Ruins: Pokémon to devolve", opts, func(o):
				var x: PokemonInPlay = o["mon"]
				if x.is_evolved():
					var cs: Array[String] = x.pop_stage()
					var c: String = cs[-1]
					me.discard.append_array(cs)
					x.clear_conditions()
					g.log_msg("  %s is discarded (devolves)." % CardDB.card_name(c)))
		"Power Plant":
			me.hand.erase(prm["pick"])
			me.discard.append(prm["pick"])
			g.ask(me.index, "Power Plant: basic Energy to your hand",
					_card_options(_distinct(me.discard, func(c): return CardDB.is_basic_energy(c)), false), func(o):
				if o["id"] in me.discard:
					me.discard.erase(o["id"])
					me.hand.append(o["id"]))
		"Ancient Ruins":
			g.log_msg("  Reveals the hand: " + ", ".join(me.hand.map(func(c): return CardDB.card_name(c))))
			if not me.hand.any(func(c): return CardDB.is_supporter(c)):
				me.draw(1)
		"Mystery Zone":
			_ask_from_deck(g, me, "Mystery Zone: basic Energy to your hand", func(c): return CardDB.is_basic_energy(c))
			var evos := _distinct(me.hand, func(c): return CardDB.is_evolution(c))
			g.ask(me.index, "Mystery Zone: Evolution card into your deck", _card_options(evos, false).map(func(o):
					o["ai"] = -float(o["ai"])
					return o), func(o):
				if o["id"] in me.hand:
					me.hand.erase(o["id"])
					me.deck.append(o["id"])
					g.shuffle(me.deck))
		"Holon Ruins":
			me.draw(1)
			g.ask(me.index, "Holon Ruins: discard a card", _card_options(me.hand, true).map(func(o):
					o["ai"] = -float(o["ai"])
					return o), func(o):
				if me.hand.has(o["id"]):
					me.hand.erase(o["id"])
					me.discard.append(o["id"]))
		"Power Tree":
			g.ask(me.index, "Power Tree: basic Energy to your hand", _card_options(_distinct(me.discard, func(c): return CardDB.is_basic_energy(c)), false), func(o):
				if me.discard.has(o["id"]):
					me.discard.erase(o["id"])
					me.hand.append(o["id"]))
		"Strange Cave":
			me.hand.erase(prm["pick"])
			me.bench.append(PokemonInPlay.new(prm["pick"], g.turn_number))
			g.log_msg("  %s goes to the Bench." % CardDB.card_name(prm["pick"]))
		"Underground Lake":
			me.discard.erase(prm["pick"])
			var np := PokemonInPlay.new(prm["pick"], g.turn_number)
			me.bench.append(np)
			g.log_msg("  %s goes to the Bench." % CardDB.card_name(prm["pick"]))


static func _first_type(c: String) -> String:
	var t := CardDB.types(c)
	return t[0] if not t.is_empty() else ""


static func _candy_fits(evo_id: String, basic: PokemonInPlay) -> bool:
	if not CardDB.is_evolution(evo_id):
		return false
	var from := CardDB.evolves_from(evo_id)
	if CardDB.stage(evo_id) == 1:
		return CardDB.evolves_onto(evo_id, basic.display_name())
	var stage1 := CardDB.find(from)
	return stage1 != "" and CardDB.evolves_onto(stage1, basic.display_name())


static func _distinct(cards: Array, pred: Callable) -> Array:
	var seen := {}
	for c in cards:
		if pred.call(c):
			seen[c] = true
	return seen.keys()


static func _card_options(cards: Array, distinct: bool) -> Array:
	var out: Array = []
	var list := _distinct(cards, func(_c): return true) if distinct else cards
	for c in list:
		out.append({"label": CardDB.card_name(c), "id": c, "ai": _ai_value(c)})
	return out


## Valor aproximado de una carta para que la IA elija qué buscar o qué descartar.
static func _ai_value(c: String) -> float:
	if CardDB.is_pokemon(c):
		return 3.0 + CardDB.stage(c) + (1.0 if CardDB.is_ex(c) else 0.0)
	if CardDB.is_supporter(c):
		return 2.5
	if CardDB.is_energy(c):
		return 2.0
	return 1.0


static func _deck_to_hand(g: Game, me: PlayerState, card_id: String) -> void:
	var i := me.deck.find(card_id)
	if i != -1:
		me.deck.remove_at(i)
		me.hand.append(card_id)
		g.log_msg("  Searches for %s." % CardDB.card_name(card_id))
	g.shuffle(me.deck)


static func _ask_from_deck(g: Game, me: PlayerState, prompt: String, pred: Callable) -> void:
	var cands := _distinct(me.deck, pred)
	if cands.is_empty():
		g.log_msg("  Didn't find anything.")
		g.shuffle(me.deck)
		return
	g.ask(me.index, prompt, _card_options(cands, false), func(o): Trainers._deck_to_hand(g, me, o["id"]))


static func _ask_repeat(g: Game, me: PlayerState, times: int, prompt: String, pred: Callable) -> void:
	if times <= 0:
		g.shuffle(me.deck)
		return
	var cands := _distinct(me.deck, pred)
	if cands.is_empty():
		g.shuffle(me.deck)
		return
	g.ask(me.index, prompt, _card_options(cands, false), func(o):
		Trainers._deck_to_hand(g, me, o["id"])
		Trainers._ask_repeat(g, me, times - 1, prompt, pred))


## Elegir varias cartas del mazo de a una, con opción "Listo".
static func _pick_sequence(g: Game, me: PlayerState, prompt: String, max_n: int, cands_fn: Callable, picked: Array) -> void:
	var cands: Array = cands_fn.call(picked) if picked.size() < max_n else []
	if cands.is_empty():
		g.shuffle(me.deck)
		return
	var opts := _card_options(cands, false)
	opts.append({"label": "Done", "id": "", "ai": 0.0})
	g.ask(me.index, "%s (%d/%d)" % [prompt, picked.size() + 1, max_n], opts, func(o):
		if o["id"] == "":
			g.shuffle(me.deck)
			return
		me.deck.erase(o["id"])
		me.hand.append(o["id"])
		g.log_msg("  Searches for %s." % CardDB.card_name(o["id"]))
		Trainers._pick_sequence(g, me, prompt, max_n, cands_fn, picked + [o["id"]]))


## Archie y Maxie: el Pokémon entra a la Banca "como si fuera Básico".
static func _bench_as_basic(g: Game, me: PlayerState, card_id: String) -> void:
	var p := PokemonInPlay.new(card_id, g.turn_number)
	if CardDB.stage(card_id) == 2:
		p.damage = 20
	me.bench.append(p)
	g.log_msg("  %s goes to the Bench." % CardDB.card_name(card_id))


static func _castaway_kind(c: String) -> String:
	if CardDB.is_supporter(c):
		return "supporter"
	if CardDB.is_pokemon_tool(c):
		return "tool"
	if CardDB.is_basic_energy(c):
		return "energy"
	return ""


## Windstorm: descartar hasta n Herramientas o Estadios en juego (de cualquiera), de a uno.
static func _windstorm(g: Game, me: PlayerState, n: int) -> void:
	if n <= 0:
		return
	var opts: Array = []
	if g.stadium != "":
		opts.append({"label": "Stadium: " + g.stadium_name(), "st": true, "ai": 1.0 if g.stadium_owner != me.index else -1.0})
	for pl in g.players:
		for x in pl.all_in_play():
			if x.tool != "":
				opts.append({"label": "%s (%s)" % [CardDB.card_name(x.tool), x.display_name()], "mon": x, "pl": pl.index,
						"opp": pl.index != me.index, "ai": 2.0 if pl.index != me.index else -2.0})
	if opts.is_empty():
		return
	opts.append({"label": "Done", "done": true, "ai": 0.0})
	g.ask(me.index, "Windstorm: discard (%d left)" % n, opts, func(o):
		if o.get("done", false):
			return
		if o.get("st", false):
			g.discard_stadium()
		else:
			var x: PokemonInPlay = o["mon"]
			var pl: PlayerState = g.players[o["pl"]]
			if pl.all_in_play().has(x) and x.tool != "":
				pl.discard.append(x.tool)
				g.log_msg("  Discards %s." % CardDB.card_name(x.tool))
				x.tool = ""
		Trainers._windstorm(g, me, n - 1))


## Mr. Stone's Project: ex9-79 busca "Basic cards" (Básicos y Energías básicas); ex13-88 y
## ex15-77, solo Energías básicas.
static func _stone_pred(card_id: String) -> Callable:
	if str(CardDB.get_card(card_id).get("text", "")).contains("basic Energy cards"):
		return func(c): return CardDB.is_basic_energy(c)
	return func(c): return Trainers._is_basic_card(c)


static func _is_basic_card(c: String) -> bool:
	return CardDB.is_basic_pokemon(c) or CardDB.is_basic_energy(c)


## Pokémon Retriever / Dark Aid: 1 carta del descarte a la mano, o 3 al mazo.
static func retriever(g: Game, me: PlayerState, pred: Callable) -> void:
	var cands := _distinct(me.discard, pred)
	if cands.is_empty():
		return
	var opts: Array = []
	for c in cands:
		opts.append({"label": "To your hand: " + CardDB.card_name(c), "id": c, "ai": _ai_value(c)})
	if me.discard.filter(pred).size() >= 3:
		opts.append({"label": "Shuffle 3 into your deck", "id": "", "ai": 0.5})
	g.ask(me.index, "Choose", opts, func(o):
		if o["id"] != "":
			if me.discard.has(o["id"]):
				me.discard.erase(o["id"])
				me.hand.append(o["id"])
			return
		Trainers.chain(g, me.index, "Card to shuffle into your deck", 3,
				func(picked):
					var left: Array = me.discard.duplicate()
					for c in picked:
						left.erase(c)
					return Trainers._distinct(left, pred), false,
				func(id):
					me.discard.erase(id)
					me.deck.append(id),
				func(): g.shuffle(me.deck)))


## Volver a poner cartas arriba del mazo en el orden que quieras (la última elegida, arriba de todo).
static func _rearrange_top(g: Game, me: PlayerState, cards: Array, what: String) -> void:
	if cards.size() <= 1:
		me.deck.append_array(cards)
		return
	var opts: Array = []
	for c in _distinct(cards, func(_c): return true):
		opts.append({"label": CardDB.card_name(c), "id": c, "ai": -_ai_value(c)})
	g.ask(me.index, "%s: card to put down first (%d left)" % [what, cards.size()], opts, func(o):
		var rest: Array = cards.duplicate()
		rest.erase(o["id"])
		me.deck.append(o["id"])
		Trainers._rearrange_top(g, me, rest, what))


## Los Partidarios Holon (después de descartar la carta que piden).
static func _holon_supporter(g: Game, me: PlayerState, opp: PlayerState, n: String, discarded: String) -> void:
	match n:
		"Holon Scientist":
			me.draw(maxi(0, opp.hand.size() - me.hand.size()))
		"Holon Adventurer":
			me.draw(4 if CardDB.is_pokemon(discarded) and CardDB.is_delta(discarded) else 3)
		"Holon Mentor":
			_pick_sequence(g, me, "Holon Mentor: Basic Pokémon (100 HP or less)", 3,
					func(_p): return _distinct(me.deck, func(c): return CardDB.is_basic_pokemon(c) and CardDB.hp(c) <= 100), [])
		"Holon Researcher":
			_ask_from_deck(g, me, "Holon Researcher: Metal Energy or δ Pokémon",
					func(c): return CardDB.card_name(c) == "Metal Energy" or (CardDB.is_pokemon(c) and CardDB.is_delta(c) and not CardDB.is_fossil(c)))
		"Holon Lass":
			var n_look := me.prizes.size() + opp.prizes.size()
			var top: Array = me.deck.slice(maxi(0, me.deck.size() - n_look))
			g.log_msg("  Looks at the top %d cards." % top.size())
			chain(g, me.index, "Holon Lass: Energy to your hand", 99,
					func(picked):
						var left: Array = top.duplicate()
						for c in picked:
							left.erase(c)
						return _distinct(left, func(c): return CardDB.is_energy(c)), true,
					func(id):
						var i := me.deck.rfind(id)
						if i != -1:
							me.deck.remove_at(i)
							me.hand.append(id),
					func(): g.shuffle(me.deck))
		"Holon Farmer":
			chain(g, me.index, "Holon Farmer: basic Energy to your deck", 3,
					func(picked):
						var left: Array = me.discard.duplicate()
						for c in picked:
							left.erase(c)
						return _distinct(left, func(c): return CardDB.is_basic_energy(c)), true,
					func(id):
						me.discard.erase(id)
						me.deck.append(id),
					func():
						Trainers.chain(g, me.index, "Holon Farmer: Pokémon to your deck", 3,
								func(picked):
									var left: Array = me.discard.duplicate()
									for c in picked:
										left.erase(c)
									return Trainers._distinct(left, func(c): return CardDB.is_pokemon(c)), true,
								func(id):
									me.discard.erase(id)
									me.deck.append(id),
								func(): g.shuffle(me.deck)))


## Rival (DP): el rival elige 3 de las 5 cartas reveladas; esas van a la mano y las otras
## vuelven al mazo, que se baraja.
static func _rival_pick(g: Game, me: PlayerState, opp: PlayerState, top: Array, picked: Array, n: int) -> void:
	if picked.size() >= n:
		for c in picked:
			top.erase(c)
		me.hand.append_array(picked)
		me.deck.append_array(top)
		g.shuffle(me.deck)
		g.log_msg("  The opponent chooses: " + ", ".join(picked.map(func(c): return CardDB.card_name(c))))
		return
	var left := top.duplicate()
	for c in picked:
		left.erase(c)
	var opts: Array = []
	for c in _distinct(left, func(_c): return true):
		opts.append({"label": CardDB.card_name(c), "id": c, "ai": -_ai_value(c)})
	g.ask(opp.index, "Rival: card for your opponent (%d/%d)" % [picked.size() + 1, n], opts, func(o):
		Trainers._rival_pick(g, me, opp, top, picked + [o["id"]], n))
