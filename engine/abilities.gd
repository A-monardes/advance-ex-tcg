class_name Abilities
extends RefCounted
## Poké-Powers (se activan) y Poké-Bodies (siempre activos) de la era ADV,
## más los efectos de Estadios, Herramientas y Energías especiales que se
## comprueban en los mismos puntos del motor.
##
## Game llama a estas funciones en cada "gancho" (cálculo de daño, retirada,
## chequeo entre turnos...). Para agregar una habilidad nueva: sumar su nombre a
## POWERS o BODIES y programarla en el gancho que corresponda.

const POWERS := [
	"Firestarter", "Energy Draw", "Psy Shadow", "Water Call", "Energy Trans", "Drive Off",
	"Lunar Eclipse", "Solar Eclipse", "Fan Away", "Chaos Flash", "Baby Evolution", "Healing Wind",
	"Dragon Wind", "Magnetic Field", "Loose Shell", "Call for Power", "Power Shift", "Magma Switch",
	"Overheat", "Auxiliary Light", "Call for Help", "Metal Juncture", "Healing Shower", "Crush Draw",
	"Heal Dance", "Temperamental Weather", "Magnetic Call", "Energy Grounding",
	# e-card (Expedition, Aquapolis, Skyridge)
	"Psymimic", "Energy Connect", "Jet Stream", "Miraculous Powder", "Burning Energy", "Moonlight",
	"Tailwind", "Major Tsunami", "Chaos Move", "Terraforming", "Soothing Aroma", "Beating Wings",
	"Plunge", "Heat Up", "Harvest Bounty", "Poison Pollen", "Bubble Turn", "Flower Supplement",
	"Happy Healing", "Super Dynamo", "Energy Return", "Sleep Pendulum", "Water Cyclone", "Ion Coating",
	"Magnetic Flow", "Earth Rage", "Backup", "Strange Tentacles", "Miracle Shift", "Dark Moon",
	"Fragrance Trap", "Scavenger Hunt", "Ancient Wind", "Energy Jump", "Energy Recharge", "Venom Spray",
	"Carry Off", "Manipulate", "Flame Vapor", "Streaming Mantle", "Attract Energy", "Evolution Helper",
	"Strange Spiral", "Good Neighbor", "Investigate", "Reconstruction", "Lolling About",
	# FireRed & LeafGreen, Team Rocket Returns, Deoxys, Emerald
	"Form Variation", "Quick Search", "Strange Behavior", "Head Trip", "Assistance", "Energy Rain",
	"Extra Energy Bomb", "Legendary Ascent", "Froth", "Black Beam", "Darkness Navigation", "Cunning",
	"Dark Trance", "Gift Exchange", "Dark Spell", "Evolutionary Light", "Fire Breath", "Ripples",
	"Psychic Trace", "Wishing Star", "Swing Dance", "Super Connectivity", "Form Change", "Happy Dance",
	"Smooth Over", "Night Vision", "Fan Action", "Magnetic Reversal", "Distortion", "Dragon Boost",
	"Lightning Burst",
	# Unseen Forces, Delta Species, Legend Maker, Holon Phantoms, POP 2-3, promos
	"3-D Reset", "Item Search", "Snappy Move", "Makeover", "Energy Evolution", "Blissful Support", "Devo Flash",
	"Golden Wing", "Nurture and Heal", "Bursting Up", "Darker Ring", "Night Cry", "Shuffle", "Final Sting",
	"Delta Charge", "Delta Heal", "Delta Control", "Delta Switch", "Metal Navigation", "Prize Shift", "Duplicate",
	"Prowl", "Evolutionary Flame", "Evolutionary Thunder", "Evolutionary Swirl", "Reactive Shift", "Shadow Curse",
	"Support Navigation", "Type Change", "Evolutionary Fan", "Nectar Pod", "Reactive Generator", "Reactive Recharge",
	"Emerge", "Power Circulation", "Shady Move", "Emerge Charge", "Delta Supply", "Dragon Curse", "Primal Light",
	"Delta Support", "Splash Back", "Psychic Vision", "Driving Howl", "Time Reversal",
	# Crystal Guardians, Dragon Frontiers, Power Keepers, POP 4-5, promos
	"Peal of Thunder", "Excavate", "Crush Chance", "Spike Storm", "Delta Sign", "Delta Transport", "Echo Draw",
	"Constrain", "Energy Recycle", "Time Travel", "Evolutionary Call", "Sharing", "Invitation", "Volunteer",
	"Dozing", "Dig Up", "Tropical Heal", "Power of Evolution", "Extra Boost", "Imprison", "Fellow Boost",
	"Type Shift", "Poison Structure", "Cursed Eyes", "Magnetic Redraw", "Chilling Breath", "Crimson Ray",
	"Yellow Ray", "Blue Ray", "Purple Ray", "Dark Ray",
]
const BODIES := [
	"Withering Dust", "Protective Dust", "Intimidating Fang", "Lazy", "Rough Skin", "Natural Remedy",
	"Hard Cocoon", "Natural Cure", "Primal Veil", "Poison Payback", "Super Suction Cups", "Rain Dish",
	"Poison Resistance", "Fire Veil", "Energy Variation", "Safeguard", "Glowing Screen", "Exoskeleton",
	"Uplifting Glow", "Primal Lock", "Power Pinchers", "Chain of Events", "Thick Skin", "Wonder Guard",
	"Sand Guard", "Energy Guard", "Levitate", "Submerge", "Conductivity", "Toxic Gas", "Power Saver",
	"Dark Lift", "Shell Retreat", "Primal Vibes", "Primal Pull", "Overzealous", "Crust", "Deep Sleep",
	"Fast Feet", "Ice Wall", "Strikes Back", "Power Diffusion", "Core Guard", "Freefloating",
	"Mark of Antiquity", "Healing Stone", "Block Dust", "Crystal Body",
	# e-card
	"Rock Body", "Dark Aura", "Extreme Speed", "Gluey Slime", "Pure Body", "Fluff", "Heavyweight",
	"Suction Cups", "Dense Body", "Anti-Lightning", "Enervating Pollen", "Lightweight", "Conductive Body",
	"Energy Barrier", "Crystal Type", "Water Immunity", "Self-healing", "Primal Aura", "Immunity",
	"Fire Immunity", "Primal Stare", "Rare Metal", "Dark Gaze", "Synchronicity", "Thick Shell",
	"Mirror Coat", "Psychoflow", "Prismatic Body", "Slippery Skin", "Vase Body",
	# FireRed & LeafGreen, Team Rocket Returns, Deoxys, Emerald, POP 1
	"Sooth Dust", "Power Gene", "Family Bonds", "Spiral", "Fiery Aura", "Rest Up", "Acid Sampler",
	"Retreat Aid", "Free Flight", "Eerie Aura", "Leaf Ride", "Energy Protection", "Floating Electrons",
	"Energy Flame", "Magic Odds", "Magic Evens", "Darkest Impulse", "Buffer", "Dragon Veil", "Holy Shield",
	"Sticky Goo", "Sand Damage", "Powder Protection", "Saturation", "Spiny", "Dark Scale", "Methane Leak",
	"Insomnia", "Knockout Gas", "Scramble", "Dense", "Darkness Veil", "Dark Condition", "Dual Armor",
	"Dark Healer", "Dark and Clear", "Darkness Guard", "Hunch", "Dark Protection", "Fast Protection",
	"Empty Shell", "Lazy Aura", "Dragon Aura", "Metallic Lift", "Tropical Motion", "Self-control",
	"Carefree", "Aqua Lift", "Moonglow", "Intimidating Pattern", "Hard Protection", "Sunbeam",
	"Vigorous Aura", "Commanding Aura", "Dragon Lift", "Blaze", "Green Essence", "Electro-guard",
	"Feathery", "Mist", "Cursed Glare", "Magma Armor", "Dark Hole", "Wise Aura", "Mystic Scale", "Rai-shield",
	# Unseen Forces ... Holon Phantoms
	"Lonesome", "Healing Aroma", "Spiral Swirl", "Burning Aura", "Intimidating Ring", "Stages of Evolution",
	"Thick Fat", "Extra-tight", "Overpowering Fang", "Silver Sparkle", "Danger Perception", "Delta Aura",
	"Delta Guard", "Delta Moon", "Binding Aura", "Delta Storm", "Body Odor", "Reversal Aura", "Beacon Protection",
	"Shining Horn", "Extra Protection", "Reactive Protection", "Ancient Shell", "Stench", "Reactive Lift",
	"Rear Sensor", "Reactive Booster", "Sol Shade", "Ancient Fang", "Luna Shade", "Pattern Distraction", "Deadlock",
	"Ancient Protection", "Reactive Colors", "Paranoid", "Reactive Aroma", "Reactive Healing", "Reactive Shield",
	"Ancient Tentacles", "Fire Remedy", "Versatile", "Icy Aura", "Delta Reactor", "Dual Aura", "Delta Reserve",
	"Hydro Barrier", "Fellowship", "Clear Body", "Delta Block", "Synchronized Lift",
	# Crystal Guardians ... Power Keepers
	"Shield Veil", "Delta Protection", "Sand Veil", "Fluffy Fur", "Water Pressure", "Hover Lift", "Chlorophyll",
	"Solid Shell", "Intimidating Armor", "Extra Noise", "Hard Rock", "Star Light", "Flotation", "Extra Liquid",
	"Dark Eyes", "Holon Veil", "Battle Aura", "Armor", "Bedhead", "Psychic Wing", "Extra Feather", "Extra Wing",
	"Extra Smoke", "Link Wing", "Rage Aura", "Synergy Effect", "Psychic Protector", "Metal Gravity",
	"Reactive Barrier", "Frenzy",
]
const REPEATABLE := ["Energy Trans", "Call for Power", "Metal Juncture", "Energy Connect", "Energy Return",
		"Water Cyclone", "Strange Behavior", "Energy Rain", "Dark Trance", "3-D Reset", "Reactive Shift"]
const ON_EVOLVE := ["Loose Shell", "Healing Shower"]
## "Cuando jugás X de tu mano para evolucionar..." (se resuelven en on_evolve_from_hand).
const EVOLVE_TRIGGER := ["Energy Recharge", "Venom Spray", "Manipulate", "Flame Vapor", "Streaming Mantle",
		"Attract Energy", "Froth", "Blissful Support", "Devo Flash", "Bursting Up", "Darker Ring", "Prowl",
		"Evolutionary Flame", "Evolutionary Thunder", "Evolutionary Swirl", "Evolutionary Fan", "Emerge Charge",
		"Peal of Thunder", "Evolutionary Call", "Dig Up", "Chilling Breath"]
## Se activan con el Pokémon en la Banca o el Activo (los demás de EVOLVE_TRIGGER, solo en el Activo).
const EVOLVE_ANYWHERE := ["Attract Energy", "Blissful Support", "Devo Flash", "Bursting Up", "Prowl",
		"Evolutionary Flame", "Evolutionary Thunder", "Evolutionary Swirl", "Evolutionary Fan", "Emerge Charge", "Darker Ring",
		"Peal of Thunder", "Evolutionary Call", "Dig Up", "Chilling Breath"]
## Al bajarlos de la mano a la Banca.
const BENCH_TRIGGER := ["Delta Switch", "Support Navigation", "Time Reversal", "Crush Chance", "Tropical Heal",
		"Cursed Eyes", "Crimson Ray", "Yellow Ray", "Blue Ray", "Purple Ray", "Dark Ray"]
const FOSSIL_LINE := ["Omanyte", "Omastar", "Kabuto", "Kabutops", "Kabutops ex"]
# no se activan desde el menú (Psymimic aparece como ataques copiados)
const TRIGGERED := ["Energy Grounding", "Psymimic", "Energy Recharge", "Venom Spray", "Manipulate",
		"Flame Vapor", "Streaming Mantle", "Attract Energy", "Froth", "Legendary Ascent", "Dragon Boost",
		"Lightning Burst", "Energy Evolution", "Golden Wing", "Delta Switch", "Shadow Curse", "Support Navigation",
		"Reactive Recharge", "Time Reversal", "Time Travel", "Crush Chance", "Tropical Heal", "Cursed Eyes",
		"Crimson Ray", "Yellow Ray", "Blue Ray", "Purple Ray", "Dark Ray"]
const NIDOS := ["Nidoran ♀", "Nidorina", "Nidoqueen", "Nidoran ♂", "Nidorino", "Nidoking"]
const DISCARD_FOSSIL := "Discard fossil"
const CASTFORMS := ["Castform", "Sunny Castform", "Rain Castform", "Snow-cloud Castform"]


static func is_implemented(ability_name: String) -> bool:
	return ability_name in POWERS or ability_name in BODIES


# ===========================================================================
# ¿Está activa?
# ===========================================================================

static func toxic_gas(g: Game) -> bool:
	for pl in g.players:
		for a in pl.actives():
			if a.has_ability("Toxic Gas"):
				return true
	return false


## Avisa que un Poké-Body acaba de actuar (la mesa lo muestra en la pestaña del Activo).
## Siempre devuelve true, para poder ponerlo al final de una condición: `... and fired(...)`.
static func fired(g: Game, p: PokemonInPlay, ability_name: String) -> bool:
	g.body_events.append([p, ability_name])
	return true


## Igual, para los que se comprueban con active_body / body_in_play (busca quién lo tiene).
static func fired_pl(g: Game, pl: PlayerState, ability_name: String) -> bool:
	for p in pl.all_in_play():
		if body(g, p, ability_name):
			g.body_events.append([p, ability_name])
			break
	return true


static func body(g: Game, p: PokemonInPlay, ability_name: String) -> bool:
	if p == null or not p.has_ability(ability_name):
		return false
	if g.players.any(func(pl): return pl.flags.get("no_bodies", -1) >= g.turn_number):   # Ancient Wind
		return false
	if _stadium_silences(g, p):
		return false
	if _bodies_silenced(g, p):
		return false
	if p.flags.get("imprison", false) or cessation(g):
		return false
	if p.is_basic() and not p.is_fossil() and ability_name != "Intimidating Armor":
		var own := g.owner_of(p)
		if own != null and active_body(g, g.other(own), "Intimidating Armor"):
			return false
	return ability_name == "Toxic Gas" or not toxic_gas(g)


## Cessation Crystal unida a un Activo (de cualquiera): nadie usa Poké-Powers ni Poké-Bodies.
static func cessation(g: Game) -> bool:
	for pl in g.players:
		for a in pl.actives():
			if CardDB.card_name(a.tool) == "Cessation Crystal" and not a.is_ex():
				return true
	return false


## Synergy Effect: cada Pokémon tiene el suyo según el Estadio de su Líder del Alto Mando.
static func synergy(g: Game, p: PokemonInPlay, stadium: String) -> bool:
	return g.stadium_name() == stadium and body(g, p, "Synergy Effect") and _ability_text(p, "Synergy Effect").contains(stadium)


## Overpowering Fang (Feraligatr ex Activo), Dual Aura (Latias δ + Latios), Energy Root.
static func _bodies_silenced(g: Game, p: PokemonInPlay) -> bool:
	if CardDB.card_name(p.tool) == "Energy Root":
		return true
	if not p.is_ex():
		for pl in g.players:
			if pl.actives().any(func(x): return x.has_ability("Overpowering Fang")):
				return true
	if p.is_evolved() and not p.is_ex():
		for pl in g.players:
			for x in pl.all_in_play():
				if x.has_ability("Dual Aura"):
					var partner := "Latios" if x.display_name().begins_with("Latias") else "Latias"
					if pl.all_in_play().any(func(y): return y.display_name().begins_with(partner)):
						return true
	return false


## Space Center (Básicos sin ex ni dueño) y Battle Frontier (evolucionados Incoloros,
## Oscuros o Metálicos) apagan Poké-Bodies; Battle Frontier también Poké-Powers.
static func _stadium_silences(g: Game, p: PokemonInPlay) -> bool:
	match g.stadium_name():
		"Space Center":
			return p.is_basic() and not p.is_ex() and not p.has_owner() and not p.is_fossil()
		"Battle Frontier":
			return p.is_evolved() and (p.is_type("Colorless") or p.is_type("Darkness") or p.is_type("Metal"))
	return false


## Poké-Body de "el" Activo (en dobles, de cualquiera de los dos Activos).
static func active_body(g: Game, pl: PlayerState, ability_name: String) -> bool:
	return body(g, pl.active, ability_name) or (pl.active2 != null and body(g, pl.active2, ability_name))


static func body_in_play(g: Game, pl: PlayerState, ability_name: String) -> bool:
	return pl.all_in_play().any(func(p): return body(g, p, ability_name))


static func body_anywhere(g: Game, ability_name: String) -> bool:
	return g.players.any(func(pl): return body_in_play(g, pl, ability_name))


static func power_blocked(g: Game, me: PlayerState, p: PokemonInPlay) -> bool:
	if not me.is_active(p) and g.players.any(func(pl): return active_body(g, pl, "Dark Gaze")):
		return true
	if g.stadium_name() == "Battle Frontier" and _stadium_silences(g, p):
		return true
	if g.stadium_name() == "Mt. Moon" and p.max_hp() < 70:
		return true
	if not p.is_ex() and g.players.any(func(pl): return active_body(g, pl, "Wise Aura")):
		return true
	if _bodies_silenced(g, p) or g.players.any(func(pl): return active_body(g, pl, "Stench")):
		return true
	if p.is_basic() and active_body(g, g.other(me), "Intimidating Ring"):
		return true
	if me.is_active(p) and p.is_basic() and not p.is_ex() and body_anywhere(g, "Rear Sensor"):
		return true
	for pair in [["Sol Shade", "Solrock", "Fire"], ["Luna Shade", "Lunatone", "Colorless"]]:
		if not p.is_ex() and p.is_type(pair[2]):
			for pl in g.players:
				if body_in_play(g, pl, pair[0]) and pl.all_in_play().any(func(x): return x.display_name() == pair[1]):
					return true
	if not CardDB.is_delta(p.top()):
		for pl in g.players:
			for x in pl.all_in_play():
				if body(g, x, "Delta Reserve") and x.energy.any(func(e): return CardDB.card_name(e).begins_with("Holon Energy")):
					return true
	if p.flags.get("imprison", false) or cessation(g):
		return true
	if p.is_ex() and body_anywhere(g, "Extra Liquid"):
		return true
	if g.stadium_name() == "Holon Legacy" and CardDB.is_delta(p.top()):
		return true
	if p.is_basic() and active_body(g, g.other(me), "Intimidating Armor"):
		return true
	return p.has_special_condition() or toxic_gas(g) or active_body(g, g.other(me), "Lazy") \
			or p.flags.get("no_powers", -1) >= g.turn_number or me.flags.get("no_powers", -1) >= g.turn_number


# ===========================================================================
# Poké-Powers: acciones legales y efecto
# ===========================================================================

static func power_actions(g: Game, me: PlayerState) -> Array:
	var out: Array = []
	for s in me.slots():
		var p := me.slot(s)
		if p.is_fossil():
			if me.bench.size() > 0 or s != -1:
				out.append({"t": "power", "s": s, "n": DISCARD_FOSSIL, "p": {}})
			continue
		for ab in p.abilities():
			var n: String = ab["name"]
			if ab["kind"] != "Poké-Power" or n not in POWERS or n in TRIGGERED or n in EVOLVE_TRIGGER:
				continue
			if power_blocked(g, me, p):
				continue
			if n not in REPEATABLE and p.power_used_turn == g.turn_number:
				continue
			if n in ON_EVOLVE and p.evolved_turn != g.turn_number:
				continue
			if n in ["Delta Sign", "Sharing"] and me.turn_flags.get("used_" + n, false):
				continue
			for prm in _options(g, me, s, p, n):
				out.append({"t": "power", "s": s, "n": n, "p": prm})
	out.append_array(Trainers.stadium_actions(g, me))
	return out


static func _options(g: Game, me: PlayerState, s: int, p: PokemonInPlay, n: String) -> Array:
	var opp := g.other(me)
	var out: Array = []
	match n:
		"Firestarter":
			if me.discard.any(func(c): return CardDB.card_name(c) == "Fire Energy"):
				for b in me.bench.size():
					out.append({"tg": b})
		"Energy Draw":
			for c in _distinct(me.hand, func(c): return CardDB.is_energy(c)):
				out.append({"pick": c})
		"Psy Shadow":
			if me.deck.any(func(c): return CardDB.card_name(c) == "Psychic Energy"):
				for t in me.slots():
					out.append({"tg": t})
		"Water Call":
			if me.hand.any(func(c): return CardDB.card_name(c) == "Water Energy"):
				out.append({})
		"Energy Trans":
			for a in me.slots():
				if me.slot(a).energy.any(func(e): return CardDB.card_name(e) == "Grass Energy"):
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b})
		"Drive Off":
			if s == -1 and not opp.bench.is_empty():
				out.append({})
		"Lunar Eclipse":
			if me.all_in_play().any(func(x): return x.display_name() == "Solrock"):
				out.append({})
		"Solar Eclipse":
			if me.all_in_play().any(func(x): return x.display_name() == "Lunatone"):
				out.append({})
		"Fan Away":
			if opp.active != null and not opp.active.energy.is_empty():
				out.append({})
		"Chaos Flash":
			if s == -1:
				out.append({})
		"Baby Evolution":
			if me.hand.any(func(c): return CardDB.card_name(c) == "Pikachu"):
				out.append({})
		"Healing Wind":
			if me.active.damage > 0:
				out.append({})
		"Dragon Wind":
			if s == -1:
				for b in opp.bench.size():
					out.append({"b": b})
		"Magnetic Field":
			if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				for c in _distinct(me.hand, func(_c): return true):
					out.append({"pick": c})
		"Loose Shell":
			if me.bench.size() < g.rules.bench_size and me.deck.any(func(c): return CardDB.card_name(c) == "Shedinja"):
				out.append({})
		"Call for Power":
			for a in me.slots():
				if a != s:
					for e in me.slot(a).energy.size():
						out.append({"from": a, "e": e})
		"Power Shift":
			for a in me.slots():
				var src := me.slot(a)
				if src.name_has("Team Aqua") and src.basic_energy_count() > 0:
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b})
		"Magma Switch":
			for a in me.slots():
				var src := me.slot(a)
				if src.name_has("Team Magma") and not src.energy.is_empty():
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b})
		"Overheat":
			for c in _distinct(me.discard, func(c): return CardDB.is_basic_energy(c)):
				out.append({"pick": c})
		"Auxiliary Light":
			for c in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
				out.append({"pick": c})
		"Call for Help":
			if s == -1:
				for c in _distinct(me.deck, func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Team Magma")):
					out.append({"pick": c})
		"Metal Juncture":
			for b in me.bench.size():
				if me.bench[b].energy.any(func(e): return CardDB.card_name(e) == "Metal Energy"):
					out.append({"from": b})
		"Healing Shower":
			out.append({})
		"Crush Draw":
			if not me.deck.is_empty():
				for t in me.slots():
					out.append({"tg": t})
		"Heal Dance":
			if not me.turn_flags.get("heal_dance", false):
				for t in me.slots():
					if me.slot(t).damage > 0:
						out.append({"tg": t})
		"Temperamental Weather":
			for c in _distinct(me.deck, func(c): return CardDB.card_name(c) in CASTFORMS and CardDB.card_name(c) != p.display_name()):
				out.append({"pick": c})
		"Magnetic Call":
			if me.bench.size() < g.rules.bench_size:
				out.append({})
		# --- e-card ---
		"Energy Connect":
			for b in me.bench.size():
				for e in _distinct(me.bench[b].energy, func(c): return CardDB.is_basic_energy(c)):
					out.append({"from": b, "id": e})
		"Jet Stream", "Sleep Pendulum", "Earth Rage", "Ancient Wind":
			if me.is_active(p) and (n != "Earth Rage" or not opp.bench.is_empty()):
				out.append({})
		"Miraculous Powder":
			if me.active.has_special_condition():
				out.append({})
		"Burning Energy", "Poison Pollen", "Ion Coating", "Carry Off", "Investigate":
			out.append({})
		"Moonlight":
			for c in _distinct(me.hand, func(_c): return true):
				out.append({"pick": c})
		"Tailwind", "Good Neighbor":
			if not me.is_active(p) and not me.turn_flags.get(n, false):
				out.append({})
		"Major Tsunami":
			if me.is_active(p):
				out.append({})
		"Chaos Move":
			if opp.prizes.size() <= 3:
				var all_s: Array = []
				for pl in [me, opp]:
					for t in pl.slots():
						all_s.append([pl.index, t])
				for a in all_s:
					if g.players[a[0]].slot(a[1]).damage > 0:
						for b in all_s:
							if b != a:
								out.append({"fp": a[0], "fs": a[1], "tp": b[0], "ts": b[1]})
		"Terraforming":
			if me.deck.size() > 1:
				out.append({})
		"Soothing Aroma":
			if me.all_in_play().any(func(x): return x.damage > 0):
				out.append({})
		"Beating Wings":
			if me.is_active(p):
				for b in me.bench.size():
					out.append({"mb": b})
		"Plunge", "Bubble Turn":
			if not me.is_active(p) and s >= 0:
				out.append({})
		"Heat Up":
			var mine := 0
			var theirs := 0
			for x in me.all_in_play():
				mine += x.energy.size()
			for x in opp.all_in_play():
				theirs += x.energy.size()
			if theirs > mine and me.deck.any(func(c): return CardDB.card_name(c) == "Fire Energy"):
				for b in me.bench.size():
					out.append({"tg": b})
		"Harvest Bounty":
			if me.turn_flags.get("attach_active", false):
				for c in _distinct(me.hand, func(c): return CardDB.is_energy(c) and Energy.can_attach(c, me.active)):
					out.append({"pick": c})
		"Flower Supplement":
			if not me.bench.is_empty() and me.hand.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Happy Healing":
			for b in me.bench.size():
				if me.bench[b].damage > 0:
					out.append({"mb": b})
		"Super Dynamo":
			if me.is_active(p) and me.discard.any(func(c): return CardDB.card_name(c) == "Lightning Energy"):
				for t in me.slots():
					out.append({"tg": t})
		"Energy Return":
			for t in me.slots():
				for e in _distinct(me.slot(t).energy, func(_c): return true):
					out.append({"from": t, "id": e})
		"Water Cyclone":
			if me.active.energy.any(func(e): return CardDB.card_name(e) == "Water Energy"):
				for b in me.bench.size():
					out.append({"mb": b})
		"Magnetic Flow":
			if me.is_active(p):
				var with_e: Array = opp.slots().filter(func(t): return not opp.slot(t).energy.is_empty())
				for i in with_e.size():
					for j in range(i + 1, with_e.size()):
						out.append({"a": with_e[i], "b": with_e[j]})
		"Backup":
			if me.hand.size() <= 2 and not me.deck.is_empty():
				out.append({})
		"Strange Tentacles":
			if opp.active != null and opp.active.energy.size() < me.active.energy.size():
				for c in _distinct(opp.discard, func(c): return CardDB.is_energy(c)):
					out.append({"pick": c})
		"Miracle Shift":
			for t in me.slots():
				for e in _distinct(me.slot(t).energy, func(c): return CardDB.is_basic_energy(c)):
					out.append({"tg": t, "id": e})
		"Dark Moon":
			if me.is_active(p) and Energy.count_named(p, "Darkness Energy") > 0 and not opp.hand.is_empty():
				out.append({})
		"Fragrance Trap":
			if not opp.bench.is_empty():
				out.append({})
		"Scavenger Hunt":
			if me.hand.size() >= 2:
				out.append({})
		"Energy Jump":
			for a in me.slots():
				for e in _distinct(me.slot(a).energy, func(_c): return true):
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b, "id": e})
		"Evolution Helper":
			if not me.is_active(p) and s >= 0:
				var base := me.active.display_name()
				for c in _distinct(me.deck, func(c): return CardDB.is_evolution(c) and CardDB.evolves_onto(c, base)):
					out.append({"pick": c})
		"Strange Spiral":
			if me.is_active(p) and p.basic_energy_count() > 0:
				out.append({})
		"Reconstruction":
			if me.hand.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Lolling About":
			if me.is_active(p) and p.damage > 0:
				out.append({})
		# --- FireRed & LeafGreen ... Emerald ---
		"Form Variation":
			if p.is_basic():
				for c in _distinct(me.discard, func(c): return CardDB.is_basic_pokemon(c) and not CardDB.is_ex(c) and CardDB.card_name(c) != "Ditto"):
					out.append({"pick": c})
		"Quick Search":
			if not me.turn_flags.get("quick_search", false) and not me.deck.is_empty():
				out.append({})
		"Strange Behavior":
			if p.hp_left() > 10:
				for t in me.slots():
					if me.slot(t) != p and me.slot(t).damage > 0:
						out.append({"from": t})
		"Head Trip":
			if not me.is_active(p) and me.active != null:
				out.append({})
		"Assistance":
			if not me.is_active(p) and me.active != null:
				for c in ["asleep", "confused", "paralyzed", "poisoned", "burned"]:
					if me.active.has_condition(c):
						out.append({"cond": c})
		"Energy Rain":
			if me.hand.any(func(c): return CardDB.card_name(c) == "Water Energy"):
				for t in me.slots():
					if can_attach_from_hand(g, CardDB.find("Water Energy"), me.slot(t)):
						out.append({"tg": t})
		"Extra Energy Bomb":
			out.append({})
		"Black Beam", "Fire Breath":
			if me.is_active(p) and opp.active != null:
				out.append({})
		"Darkness Navigation":
			if p.energy.is_empty() and me.deck.any(func(c): return CardDB.card_name(c) in ["Darkness Energy", "Dark Metal Energy"]):
				out.append({})
		"Cunning", "Smooth Over", "Swing Dance":
			if not (opp.deck if n == "Cunning" else me.deck).is_empty():
				out.append({})
		"Dark Trance":
			for a in me.slots():
				if me.slot(a).energy.any(func(e): return CardDB.card_name(e) == "Darkness Energy"):
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b})
		"Gift Exchange":
			if me.is_active(p):
				for c in _distinct(me.hand, func(_c): return true):
					out.append({"pick": c})
		"Dark Spell", "Distortion":
			if me.is_active(p):
				for t in opp.slots():
					out.append({"tg": t})
		"Evolutionary Light":
			if me.is_active(p) and me.deck.any(func(c): return CardDB.is_evolution(c)):
				out.append({})
		"Ripples":
			for t in me.slots():
				if me.slot(t) != p and me.slot(t).damage > 0:
					out.append({"tg": t})
		"Psychic Trace":
			if me.is_active(p):
				out.append({})
		"Wishing Star":
			if me.is_active(p) and not me.deck.is_empty():
				out.append({})
		"Super Connectivity":
			for c in _distinct(me.discard, func(c): return CardDB.card_name(c) in ["Psychic Energy", "Metal Energy"]):
				out.append({"pick": c})
		"Form Change":
			if not me.turn_flags.get("form_change", false) and p.is_basic():
				var cur := p.top()
				for c in _distinct(me.deck, func(c): return CardDB.card_name(c) == p.display_name() and c != cur):
					out.append({"pick": c})
		"Happy Dance":
			if not me.turn_flags.get("happy_dance", false) and me.all_in_play().any(func(x): return x.damage > 0):
				out.append({})
		"Night Vision":
			if me.is_active(p) and not opp.hand.is_empty():
				out.append({})
		"Fan Action":
			if opp.active != null and not opp.bench.is_empty():
				out.append({})
		"Magnetic Reversal":
			if me.is_active(p):
				for b in opp.bench.size():
					out.append({"b": b})
		# --- Unseen Forces ... Holon Phantoms ---
		"3-D Reset":
			for t in me.slots():
				if me.slot(t).tool != "":
					out.append({"tg": t})
		"Item Search":
			if me.deck.any(func(c): return CardDB.is_pokemon_tool(c)):
				out.append({})
		"Snappy Move":
			if not me.is_active(p) and s >= 0 and not me.turn_flags.get("snappy", false):
				out.append({})
		"Makeover":
			for t in me.slots():
				var x := me.slot(t)
				if not x.is_ex():
					for e in _distinct(x.energy, func(c): return CardDB.is_basic_energy(c)):
						if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
							out.append({"tg": t, "id": e})
		"Nurture and Heal":
			if me.hand.any(func(c): return CardDB.card_name(c) == "Grass Energy"):
				for t in me.slots():
					out.append({"tg": t})
		"Night Cry":
			if not me.is_active(p) and s >= 0 and me.deck.any(func(c): return CardDB.is_pokemon(c) and (CardDB.card_name(c).contains("Dark") or CardDB.card_name(c).contains("Rocket's"))):
				out.append({})
		"Shuffle", "Duplicate":
			if not me.turn_flags.get(n, false) and p.is_basic():
				var cur := p.top()
				for c in _distinct(me.deck, func(c): return CardDB.card_name(c) == p.display_name() and c != cur):
					out.append({"pick": c})
		"Final Sting":
			if opp.active != null:
				out.append({})
		"Delta Charge":
			if not me.bench.is_empty() and me.discard.any(func(c): return CardDB.card_name(c) == "Lightning Energy"):
				for b in me.bench.size():
					out.append({"tg": b})
		"Delta Heal":
			if not me.turn_flags.get("delta_heal", false) and me.all_in_play().any(func(x): return x.damage > 0 and CardDB.is_delta(x.top())):
				out.append({})
		"Delta Control", "Primal Light":
			if not me.deck.is_empty():
				out.append({})
		"Metal Navigation":
			if me.deck.any(func(c): return CardDB.card_name(c) == "Metal Energy"):
				out.append({})
		"Prize Shift":
			var faceup: Array = me.flags.get("faceup_prizes", [])
			if me.prizes.size() > faceup.size():
				for c in _distinct(me.hand, func(_c): return true):
					out.append({"pick": c})
		"Reactive Shift":
			for a in me.slots():
				if me.slot(a).energy.any(func(e): return CardDB.card_name(e) == "React Energy"):
					for b in me.slots():
						if b != a:
							out.append({"from": a, "to": b})
		"Type Change":
			if opp.active != null:
				out.append({})
		"Nectar Pod":
			for b in opp.bench.size():
				if CardDB.stage(opp.bench[b].top()) == 2:
					out.append({"b": b})
		"Reactive Generator":
			if not p.energy.any(func(e): return CardDB.card_name(e) == "React Energy") and me.deck.any(func(c): return CardDB.card_name(c) == "React Energy"):
				out.append({})
		"Emerge":
			if me.is_active(p) and me.deck.any(func(c): return CardDB.evolves_onto(c, p.display_name())):
				out.append({})
		"Power Circulation":
			if me.discard.any(func(c): return CardDB.is_basic_energy(c)):
				out.append({})
		"Shady Move":
			if me.is_active(p):
				var all_s: Array = []
				for pl in [me, opp]:
					for t in pl.slots():
						all_s.append([pl.index, t])
				for a in all_s:
					if g.players[a[0]].slot(a[1]).damage > 0:
						for b in all_s:
							if b != a:
								out.append({"fp": a[0], "fs": a[1], "tp": b[0], "ts": b[1]})
		"Delta Supply":
			for c in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c) or CardDB.card_name(c) == "δ Rainbow Energy"):
				for t in me.slots():
					if CardDB.is_delta(me.slot(t).top()):
						out.append({"tg": t, "id": c})
		"Dragon Curse":
			if me.is_active(p):
				for t in opp.slots():
					if CardDB.is_delta(opp.slot(t).top()):
						out.append({"tg": t})
		"Delta Support":
			if CardDB.card_name(me.turn_flags.get("supporter_id", "")).contains("Holon"):
				for c in _distinct(me.discard, func(c): return CardDB.is_basic_energy(c) or CardDB.card_name(c) == "δ Rainbow Energy"):
					out.append({"pick": c})
		"Splash Back":
			if opp.bench.size() >= 4:
				for b in opp.bench.size():
					out.append({"b": b})
		"Psychic Vision":
			if not me.is_active(p) and s >= 0:
				out.append({})
		"Driving Howl":
			if opp.active != null and not opp.bench.is_empty():
				out.append({})
		"Excavate", "Echo Draw":
			if not me.deck.is_empty():
				out.append({})
		"Spike Storm":
			if me.is_active(p):
				for t in opp.slots():
					if opp.slot(t).damage > 0:
						out.append({"tg": t})
		"Delta Sign":
			if me.deck.any(func(c): return CardDB.is_pokemon(c) and CardDB.is_delta(c)):
				out.append({})
		"Delta Transport":
			if not me.is_active(p) and me.active != null and CardDB.is_delta(me.active.top()):
				for b in me.bench.size():
					out.append({"b": b})
		"Constrain":
			if me.hand.size() > 6 or opp.hand.size() > 6:
				out.append({})
		"Energy Recycle":
			if me.discard.any(func(c): return CardDB.is_energy(c)):
				out.append({})
		"Sharing":
			for c in _distinct(opp.hand, func(c): return CardDB.is_supporter(c) and Trainers.is_implemented(c)):
				me.hand.append(c)
				var opts := Trainers.options(g, me, me.hand.size() - 1)
				me.hand.pop_back()
				for prm in opts:
					out.append({"id": c, "tp": prm})
			if out.is_empty() and not opp.hand.is_empty():
				out.append({"look": true})
		"Invitation":
			if me.deck.any(func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c)):
				out.append({})
		"Volunteer":
			if p.cards.size() >= 2 and CardDB.card_name(p.cards[-2]) == "Vulpix" \
					and me.deck.any(func(c): return CardDB.card_name(c) in ["Ninetales", "Ninetales ex"]):
				out.append({})
		"Dozing":
			if me.is_active(p):
				out.append({})
		"Power of Evolution":
			if p.is_evolved() and not me.deck.is_empty():
				out.append({})
		"Extra Boost":
			for c in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
				for t in me.slots():
					var x := me.slot(t)
					if x.is_ex() and CardDB.stage(x.top()) == 2:
						out.append({"tg": t, "id": c})
		"Fellow Boost":
			for c in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
				for t in me.slots():
					var nm := me.slot(t).display_name()
					if nm.begins_with("Latias") or nm.begins_with("Latios"):
						out.append({"tg": t, "id": c})
		"Imprison":
			if me.is_active(p):
				for t in opp.slots():
					if not opp.slot(t).flags.get("imprison", false):
						out.append({"tg": t})
		"Type Shift":
			out.append({})
		"Poison Structure":
			if g.stadium_name() == "Sidney's Stadium" and opp.active != null:
				out.append({})
		"Magnetic Redraw":
			if me.is_active(p):
				out.append({})
	return out


static func use_power(g: Game, me: PlayerState, s: int, n: String, prm: Dictionary) -> void:
	if prm.get("stadium", false):
		Trainers.use_stadium(g, me, n, prm)
		return
	var p := me.slot(s)
	var opp := g.other(me)
	if n == DISCARD_FOSSIL:
		g.log_msg("Player %d discards %s." % [me.index + 1, p.display_name()])
		g.remove_from_play(me, p, false)
		return
	g.log_msg("%s uses %s." % [p.display_name(), n])
	if n not in REPEATABLE:
		p.power_used_turn = g.turn_number
	match n:
		"Firestarter":
			var e := _take(me.discard, func(c): return CardDB.card_name(c) == "Fire Energy")
			me.bench[prm["tg"]].energy.append(e)
		"Energy Draw":
			me.hand.erase(prm["pick"])
			me.discard.append(prm["pick"])
			me.draw(3)
		"Psy Shadow":
			var e := _take(me.deck, func(c): return CardDB.card_name(c) == "Psychic Energy")
			var t := me.slot(prm["tg"])
			t.energy.append(e)
			t.damage += 20
			g.shuffle(me.deck)
		"Water Call":
			var e := _take(me.hand, func(c): return CardDB.card_name(c) == "Water Energy")
			me.active.energy.append(e)
			on_energy_from_hand(g, me, me.active, e)
		"Energy Trans":
			_move_energy(me.slot(prm["from"]), me.slot(prm["to"]), func(e): return CardDB.card_name(e) == "Grass Energy", 1)
		"Drive Off":
			g.queue_choice(opp.index, "switch")
		"Lunar Eclipse":
			p.type_override = ["Darkness"]
			p.flags["type_until"] = g.turn_number
		"Solar Eclipse":
			p.type_override = ["Fire"]
			p.flags["type_until"] = g.turn_number
		"Fan Away":
			if g.flip():
				var e: String = opp.active.energy.pop_back()
				opp.hand.append(e)
				g.log_msg("  %s returns to the opponent's hand." % CardDB.card_name(e))
		"Chaos Flash":
			if g.flip():
				g.try_condition(opp.active, "confused")
		"Baby Evolution":
			var pika := _take(me.hand, func(c): return CardDB.card_name(c) == "Pikachu")
			g.evolve(me, p, pika)
			p.damage = 0
		"Healing Wind":
			me.active.damage = max(0, me.active.damage - 10)
		"Dragon Wind":
			g.switch_active(opp, prm["b"])
		"Magnetic Field":
			me.hand.erase(prm["pick"])
			var pool: Array = me.discard.duplicate()     # sin la carta recién descartada
			me.discard.append(prm["pick"])
			Trainers.chain(g, me.index, "Magnetic Field: basic Energy to your hand", 2,
					func(picked):
						var left := pool.duplicate()
						for c in picked:
							left.erase(c)
						return Trainers._distinct(left, func(c): return CardDB.is_basic_energy(c)), true,
					func(id):
						me.discard.erase(id)
						me.hand.append(id)
						g.log_msg("  Gets back %s." % CardDB.card_name(id)),
					func(): pass)
		"Loose Shell":
			var sh := _take(me.deck, func(c): return CardDB.card_name(c) == "Shedinja")
			me.bench.append(PokemonInPlay.new(sh, g.turn_number))
			g.shuffle(me.deck)
		"Call for Power":
			var src := me.slot(prm["from"])
			p.energy.append(src.energy[prm["e"]])
			src.energy.remove_at(prm["e"])
		"Power Shift":
			_move_energy(me.slot(prm["from"]), me.slot(prm["to"]), func(e): return CardDB.is_basic_energy(e), 99)
		"Magma Switch":
			_move_energy(me.slot(prm["from"]), me.slot(prm["to"]), func(_e): return true, 1)
		"Overheat":
			me.discard.erase(prm["pick"])
			p.energy.append(prm["pick"])
			p.damage += 20
		"Auxiliary Light":
			me.hand.erase(prm["pick"])
			p.energy.append(prm["pick"])
			p.damage += 20
		"Call for Help":
			me.deck.erase(prm["pick"])
			me.hand.append(prm["pick"])
			g.shuffle(me.deck)
		"Metal Juncture":
			_move_energy(me.bench[prm["from"]], me.active, func(e): return CardDB.card_name(e) == "Metal Energy", 1)
		"Healing Shower":
			for pl in g.players:
				for x in pl.all_in_play():
					if not x.is_ex():
						x.damage = 0
		"Crush Draw":
			var top: String = me.deck[-1]
			g.log_msg("  Reveals %s." % CardDB.card_name(top))
			if CardDB.is_basic_energy(top):
				me.deck.pop_back()
				me.slot(prm["tg"]).energy.append(top)
		"Heal Dance":
			var t := me.slot(prm["tg"])
			t.damage = max(0, t.damage - 20)
			me.turn_flags["heal_dance"] = true
		"Temperamental Weather":
			me.deck.erase(prm["pick"])
			me.deck.append(p.cards[0])
			p.cards[0] = prm["pick"]
			g.shuffle(me.deck)
		"Magnetic Call":
			if g.flip():
				var i := g.best_in_deck(me, func(c): return CardDB.is_basic_pokemon(c) and "Metal" in CardDB.types(c))
				if i != -1:
					var id: String = me.deck[i]
					me.deck.remove_at(i)
					me.bench.append(PokemonInPlay.new(id, g.turn_number))
					g.log_msg("  Puts %s on the Bench." % CardDB.card_name(id))
				g.shuffle(me.deck)
		# --- e-card ---
		"Energy Connect":
			var src: PokemonInPlay = me.bench[prm["from"]]
			src.energy.erase(prm["id"])
			me.active.energy.append(prm["id"])
			g.log_msg("  Moves %s to %s." % [CardDB.card_name(prm["id"]), me.active.display_name()])
		"Jet Stream":
			if g.flip():
				if not p.energy.is_empty():
					var e: String = p.energy.pop_back()
					me.discard.append(e)
					g.log_msg("  Discards %s." % CardDB.card_name(e))
				if opp.active != null and not opp.active.energy.is_empty():
					_ask_discard_energy(g, me, opp, opp.active, "Jet Stream: discard an Energy")
		"Miraculous Powder":
			me.active.clear_conditions()
		"Burning Energy":
			me.flags["burning"] = g.turn_number
		"Moonlight":
			me.hand.erase(prm["pick"])
			me.deck.append(prm["pick"])
			Trainers._ask_from_deck(g, me, "Moonlight: basic Energy to your hand", func(c): return CardDB.is_basic_energy(c))
		"Tailwind":
			me.active.flags["free_retreat"] = g.turn_number
		"Major Tsunami":
			if not opp.bench.is_empty():
				g.queue_choice(opp.index, "switch")
			if not me.bench.is_empty():
				g.queue_choice(me.index, "switch")
		"Chaos Move":
			var from: PokemonInPlay = g.players[prm["fp"]].slot(prm["fs"])
			var to: PokemonInPlay = g.players[prm["tp"]].slot(prm["ts"])
			from.damage -= 10
			to.damage += 10
			g.log_msg("  Moves 1 damage counter from %s to %s." % [from.display_name(), to.display_name()])
		"Terraforming":
			var top: Array = []
			for i in mini(4, me.deck.size()):
				top.append(me.deck.pop_back())
			_rearrange(g, me, top, [])
		"Soothing Aroma":
			if g.flip():
				for x in me.all_in_play():
					x.damage = max(0, x.damage - 10)
		"Beating Wings":
			var x: PokemonInPlay = me.bench[prm["mb"]]
			g.log_msg("  %s is shuffled into the deck." % x.display_name())
			me.bench.remove_at(prm["mb"])
			me.deck.append_array(x.all_cards())
			g.shuffle(me.deck)
		"Plunge":
			if g.flip():
				p.energy.append_array(me.active.energy)
				me.active.energy.clear()
				g.switch_active(me, me.bench.find(p))
		"Heat Up":
			var e := _take(me.deck, func(c): return CardDB.card_name(c) == "Fire Energy")
			me.bench[prm["tg"]].energy.append(e)
			g.shuffle(me.deck)
		"Harvest Bounty":
			me.hand.erase(prm["pick"])
			me.active.energy.append(prm["pick"])
			g.log_msg("  Attaches %s to %s." % [CardDB.card_name(prm["pick"]), me.active.display_name()])
			on_energy_from_hand(g, me, me.active, prm["pick"])
		"Poison Pollen":
			if g.flip() and opp.active != null:
				g.try_condition(opp.active, "poisoned")
		"Bubble Turn":
			if g.flip():
				g.return_to_hand(me, p)
		"Flower Supplement":
			if g.flip():
				var opts: Array = []
				for e in _distinct(me.hand, func(c): return CardDB.is_basic_energy(c)):
					for b in me.bench.size():
						opts.append({"label": "%s → %s" % [CardDB.card_name(e), me.bench[b].display_name()], "id": e, "b": b, "ai": 1.0})
				g.ask(me.index, "Flower Supplement: attach a basic Energy", opts, func(o):
					if o["id"] in me.hand and o["b"] < me.bench.size():
						me.hand.erase(o["id"])
						me.bench[o["b"]].energy.append(o["id"])
						on_energy_from_hand(g, me, me.bench[o["b"]], o["id"]))
		"Happy Healing":
			if g.flip():
				var t: PokemonInPlay = me.bench[prm["mb"]]
				t.damage = max(0, t.damage - 10 * Energy.total(p))
		"Super Dynamo":
			if g.flip():
				var e := _take(me.discard, func(c): return CardDB.card_name(c) == "Lightning Energy")
				me.slot(prm["tg"]).energy.append(e)
		"Energy Return":
			me.slot(prm["from"]).energy.erase(prm["id"])
			me.hand.append(prm["id"])
		"Sleep Pendulum":
			g.try_condition(opp.active, "asleep")
		"Water Cyclone":
			_move_energy(me.active, me.bench[prm["mb"]], func(e): return CardDB.card_name(e) == "Water Energy", 1)
		"Ion Coating":
			me.active.flags["ion"] = g.turn_number
		"Magnetic Flow":
			if g.flip():
				var a := opp.slot(prm["a"])
				var b := opp.slot(prm["b"])
				g.ask(me.index, "Magnetic Flow: Energy from %s" % a.display_name(), _energy_options(a), func(o1):
					g.ask(me.index, "Magnetic Flow: Energy from %s" % b.display_name(), _energy_options(b), func(o2):
						if opp.all_in_play().has(a) and opp.all_in_play().has(b) and o1["id"] in a.energy and o2["id"] in b.energy:
							a.energy.erase(o1["id"])
							b.energy.erase(o2["id"])
							a.energy.append(o2["id"])
							b.energy.append(o1["id"])
							g.log_msg("  Switches %s and %s." % [CardDB.card_name(o1["id"]), CardDB.card_name(o2["id"])])))
		"Earth Rage":
			if g.flip():
				for x in opp.bench:
					x.damage += 10
		"Backup":
			me.draw(3 - me.hand.size())
		"Strange Tentacles":
			opp.discard.erase(prm["pick"])
			opp.active.energy.append(prm["pick"])
			g.log_msg("  Attaches %s to %s." % [CardDB.card_name(prm["pick"]), opp.active.display_name()])
		"Miracle Shift":
			var t := me.slot(prm["tg"])
			t.energy.erase(prm["id"])
			me.discard.append(prm["id"])
			var cands := _distinct(me.discard, func(c): return CardDB.is_basic_energy(c))
			g.ask(me.index, "Miracle Shift: basic Energy to attach", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.discard and me.all_in_play().has(t):
					me.discard.erase(o["id"])
					t.energy.append(o["id"]))
		"Dark Moon":
			var n_max := Energy.count_named(p, "Darkness Energy")
			var taken: Array = []
			Trainers.chain(g, me.index, "Dark Moon: card to shuffle into the deck", n_max,
					func(picked):
						var left: Array = opp.hand.duplicate()
						for c in picked:
							left.erase(c)
						return left, true,
					func(id):
						opp.hand.erase(id)
						opp.deck.append(id)
						taken.append(id),
					func():
						g.shuffle(opp.deck)
						opp.draw(taken.size())
						g.log_msg("  The opponent shuffles %d card(s) and draws %d." % [taken.size(), taken.size()]))
		"Fragrance Trap":
			if g.flip():
				var opts: Array = []
				for b in opp.bench.size():
					opts.append({"label": opp.bench[b].display_name(), "b": b, "ai": 1.0})
				g.ask(me.index, "Fragrance Trap: new Defending Pokémon", opts, func(o):
					if o["b"] < opp.bench.size():
						g.switch_active(opp, o["b"]))
		"Scavenger Hunt":
			Trainers.chain(g, me.index, "Scavenger Hunt: card to put into your deck", 2,
					func(picked):
						var left: Array = me.hand.duplicate()
						for c in picked:
							left.erase(c)
						return Trainers._distinct(left, func(_c): return true), false,
					func(id):
						me.hand.erase(id)
						me.deck.append(id),
					func(): Trainers._ask_from_deck(g, me, "Scavenger Hunt: Energy to your hand", func(c): return CardDB.is_energy(c)))
		"Ancient Wind":
			me.flags["no_bodies"] = g.turn_number
		"Energy Jump":
			me.slot(prm["from"]).energy.erase(prm["id"])
			me.slot(prm["to"]).energy.append(prm["id"])
			g.log_msg("  Moves %s." % CardDB.card_name(prm["id"]))
		"Carry Off":
			if g.flip():
				var cands := _distinct(opp.hand, func(c): return CardDB.is_pokemon(c))
				g.log_msg("  Looks at the opponent's hand.")
				g.ask(me.index, "Carry Off: card to shuffle into the opponent's deck", Trainers._card_options(cands, false), func(o):
					if o["id"] in opp.hand:
						opp.hand.erase(o["id"])
						opp.deck.append(o["id"])
						g.shuffle(opp.deck))
		"Evolution Helper":
			me.deck.erase(prm["pick"])
			g.evolve(me, me.active, prm["pick"])
			g.shuffle(me.deck)
		"Strange Spiral":
			var e := _take(p.energy, func(c): return CardDB.is_basic_energy(c))
			me.discard.append(e)
			g.try_condition(opp.active, "confused")
		"Good Neighbor":
			me.turn_flags["Good Neighbor"] = true
			if g.flip():
				for pl in g.players:
					if pl.active != null:
						pl.active.damage = max(0, pl.active.damage - 20)
		"Investigate":
			var seen: Array = []
			for i in mini(2, me.deck.size()):
				seen.append(CardDB.card_name(me.deck[-1 - i]))
			g.log_msg("  Top of the deck: %s." % ", ".join(seen))
		"Reconstruction":
			Trainers._ask_from_deck(g, me, "Reconstruction: Omanyte or Kabuto", func(c): return CardDB.card_name(c) in ["Omanyte", "Kabuto"])
			var cands := _distinct(me.hand, func(c): return CardDB.is_basic_energy(c))
			g.ask(me.index, "Reconstruction: basic Energy into your deck", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.hand:
					me.hand.erase(o["id"])
					me.deck.append(o["id"])
					g.shuffle(me.deck))
		"Lolling About":
			p.damage = max(0, p.damage - 10)
			g.try_condition(p, "asleep")
		# --- FireRed & LeafGreen ... Emerald ---
		"Form Variation":
			me.discard.erase(prm["pick"])
			me.discard.append(p.cards[0])
			p.cards[0] = prm["pick"]
			g.log_msg("  Ditto becomes %s." % CardDB.card_name(prm["pick"]))
		"Quick Search":
			me.turn_flags["quick_search"] = true
			Trainers._ask_from_deck(g, me, "Quick Search: any card", func(_c): return true)
		"Strange Behavior":
			var src := me.slot(prm["from"])
			src.damage -= 10
			p.damage += 10
			g.log_msg("  Moves 1 damage counter from %s to %s." % [src.display_name(), p.display_name()])
		"Head Trip":
			g.try_condition(me.active, "confused")
		"Assistance":
			var t := me.active
			match prm["cond"]:
				"poisoned": t.poison = 0
				"burned": t.burned = false
				_: t.rotation = ""
			g.log_msg("  %s is no longer %s." % [t.display_name(), Game.COND_ES[prm["cond"]]])
		"Energy Rain":
			var e := _take(me.hand, func(c): return CardDB.card_name(c) == "Water Energy")
			var t := me.slot(prm["tg"])
			t.energy.append(e)
			t.damage += 10
			g.log_msg("  Attaches Water Energy to %s." % t.display_name())
			on_energy_from_hand(g, me, t, e)
		"Extra Energy Bomb":
			p.damage = p.max_hp()      # cuenta como quedar Fuera de Combate (el rival toma sus Premios)
			g.ask(me.index, "Extra Energy Bomb", [{"label": "Search your discard pile for Energy", "ai": 1.0}], func(_o):
				attach_from_pile(g, me, me.discard, 5, func(c): return CardDB.is_energy(c),
						func(x): return not x.is_ex(), "Extra Energy Bomb", false))
		"Black Beam":
			g.try_condition(opp.active, "poisoned")
		"Fire Breath":
			if g.flip():
				g.try_condition(opp.active, "burned")
		"Darkness Navigation":
			var cands := _distinct(me.deck, func(c): return CardDB.card_name(c) in ["Darkness Energy", "Dark Metal Energy"])
			g.ask(me.index, "Darkness Navigation: Energy to attach", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.deck and me.all_in_play().has(p):
					me.deck.erase(o["id"])
					p.energy.append(o["id"])
				g.shuffle(me.deck))
		"Cunning":
			var top: String = opp.deck[-1]
			g.ask(me.index, "Cunning: top card is %s" % CardDB.card_name(top), [
					{"label": "Shuffle the opponent's deck", "shuffle": true, "ai": 0.5},
					{"label": "Leave it there", "shuffle": false, "ai": 0.4}], func(o):
				if o["shuffle"]:
					g.shuffle(opp.deck)
					g.log_msg("  Shuffles the opponent's deck."))
		"Dark Trance":
			_move_energy(me.slot(prm["from"]), me.slot(prm["to"]), func(e): return CardDB.card_name(e) == "Darkness Energy", 1)
		"Gift Exchange":
			me.hand.erase(prm["pick"])
			me.deck.append(prm["pick"])
			g.shuffle(me.deck)
			me.draw(1)
		"Dark Spell":
			if g.flip():
				var t := opp.slot(prm["tg"])
				if t != null:
					t.damage += 10
					g.log_msg("  1 damage counter on %s." % t.display_name())
		"Distortion":
			var t := opp.slot(prm["tg"])
			if t != null:
				t.damage += 10
				g.log_msg("  1 damage counter on %s." % t.display_name())
		"Evolutionary Light":
			Trainers._ask_from_deck(g, me, "Evolutionary Light: Evolution card", func(c): return CardDB.is_evolution(c))
		"Ripples":
			var t := me.slot(prm["tg"])
			t.damage = max(0, t.damage - 10)
		"Psychic Trace":
			Trainers._hand_to_deck(g, me)
			me.draw(opp.hand.size())
		"Wishing Star":
			var top: Array = me.deck.slice(maxi(0, me.deck.size() - 5))
			g.ask(me.index, "Wishing Star: choose 1 card", Trainers._card_options(top, true), func(o):
				var i := me.deck.rfind(o["id"])
				if i != -1:
					me.deck.remove_at(i)
					me.hand.append(o["id"])
				g.shuffle(me.deck))
			g.try_condition(p, "asleep")
		"Swing Dance":
			me.draw(1)
		"Super Connectivity":
			me.discard.erase(prm["pick"])
			me.active.energy.append(prm["pick"])
			me.active.damage += 10
			g.log_msg("  Attaches %s to %s." % [CardDB.card_name(prm["pick"]), me.active.display_name()])
		"Form Change":
			me.turn_flags["form_change"] = true
			me.deck.erase(prm["pick"])
			var old: String = p.cards[0]
			p.cards[0] = prm["pick"]
			g.shuffle(me.deck)
			me.deck.append(old)
			g.log_msg("  Deoxys changes form; the old card goes on top of the deck.")
		"Happy Dance":
			me.turn_flags["happy_dance"] = true
			for x in me.all_in_play():
				x.damage = max(0, x.damage - 10)
		"Smooth Over":
			g.ask(me.index, "Smooth Over: card to put on top of your deck", Trainers._card_options(me.deck, true), func(o):
				var i := me.deck.find(o["id"])
				if i != -1:
					me.deck.remove_at(i)
					g.shuffle(me.deck)
					me.deck.append(o["id"])
					g.log_msg("  Puts a card on top of the deck."))
		"Night Vision":
			g.log_msg("  Opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
		"Fan Action":
			g.queue_choice(opp.index, "switch")
		"Magnetic Reversal":
			if g.flip() and prm["b"] < opp.bench.size():
				g.switch_active(opp, prm["b"])
		# --- Unseen Forces ... Holon Phantoms ---
		"3-D Reset":
			var t := me.slot(prm["tg"])
			me.hand.append(t.tool)
			g.log_msg("  %s returns to the hand." % CardDB.card_name(t.tool))
			t.tool = ""
		"Item Search":
			Trainers._ask_from_deck(g, me, "Item Search: Pokémon Tool", func(c): return CardDB.is_pokemon_tool(c))
		"Snappy Move":
			me.turn_flags["snappy"] = true
			me.draw(1)
			var cards := p.all_cards()
			me.bench.erase(p)
			for c in cards:
				if c != p.cards[0]:
					me.discard.append(c)
			me.deck.insert(0, p.cards[0])
			g.log_msg("  Aipom goes to the bottom of the deck.")
		"Makeover":
			var t := me.slot(prm["tg"])
			t.energy.erase(prm["id"])
			var cands := _distinct(me.discard, func(c): return CardDB.is_basic_energy(c))
			me.discard.append(prm["id"])
			g.ask(me.index, "Makeover: basic Energy to attach", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.discard and me.all_in_play().has(t):
					me.discard.erase(o["id"])
					t.energy.append(o["id"]))
		"Nurture and Heal":
			var e := _take(me.hand, func(c): return CardDB.card_name(c) == "Grass Energy")
			var t := me.slot(prm["tg"])
			t.energy.append(e)
			t.damage = max(0, t.damage - 10)
			on_energy_from_hand(g, me, t, e)
		"Night Cry":
			Trainers._ask_from_deck(g, me, "Night Cry: Dark or Rocket's Pokémon", func(c): return CardDB.is_pokemon(c) and (CardDB.card_name(c).contains("Dark") or CardDB.card_name(c).contains("Rocket's")))
		"Shuffle", "Duplicate":
			me.turn_flags[n] = true
			me.deck.erase(prm["pick"])
			var old: String = p.cards[0]
			p.cards[0] = prm["pick"]
			g.shuffle(me.deck)
			me.deck.append(old)
			g.log_msg("  Switches with another %s; the old card goes on top of the deck." % p.display_name())
		"Final Sting":
			p.damage = p.max_hp()
			var d := opp.active
			g.try_condition(d, "paralyzed")
			g.try_condition(d, "poisoned")
			if d.poison > 0:
				d.poison = 2
		"Delta Charge":
			var e := _take(me.discard, func(c): return CardDB.card_name(c) == "Lightning Energy")
			me.bench[prm["tg"]].energy.append(e)
		"Delta Heal":
			me.turn_flags["delta_heal"] = true
			for x in me.all_in_play():
				if CardDB.is_delta(x.top()):
					x.damage = max(0, x.damage - 10)
		"Delta Control":
			var top: Array = []
			for i in mini(4, me.deck.size()):
				top.append(me.deck[me.deck.size() - 1 - i])
			g.ask(me.index, "Delta Control: choose 1 card", Trainers._card_options(top, true), func(o):
				var i := me.deck.rfind(o["id"])
				if i != -1:
					me.deck.remove_at(i)
					me.hand.append(o["id"])
				for j in mini(3, me.deck.size()):
					me.deck.insert(0, me.deck.pop_back()))
		"Primal Light":
			Trainers._ask_from_deck(g, me, "Primal Light: basic Energy", func(c): return CardDB.is_basic_energy(c))
		"Metal Navigation":
			var e := _take(me.deck, func(c): return CardDB.card_name(c) == "Metal Energy")
			p.energy.append(e)
			g.shuffle(me.deck)
		"Prize Shift":
			var faceup: Array = me.flags.get("faceup_prizes", [])
			var down: Array = []
			for i in me.prizes.size():
				if not faceup.has(me.prizes[i]):
					down.append(i)
			var k: int = down[g.rng.randi_range(0, down.size() - 1)]
			var took: String = me.prizes[k]
			me.hand.erase(prm["pick"])
			me.prizes[k] = prm["pick"]
			faceup.append(prm["pick"])
			me.flags["faceup_prizes"] = faceup
			me.hand.append(took)
			g.log_msg("  Puts %s as a face-up Prize card and takes a Prize card." % CardDB.card_name(prm["pick"]))
		"Reactive Shift":
			_move_energy(me.slot(prm["from"]), me.slot(prm["to"]), func(e): return CardDB.card_name(e) == "React Energy", 1)
		"Type Change":
			p.type_override = opp.active.types().duplicate()
			p.flags["type_until"] = g.turn_number
		"Nectar Pod", "Splash Back":
			if prm["b"] < opp.bench.size():
				if n == "Nectar Pod":
					g.switch_active(opp, prm["b"])
				else:
					g.return_to_hand(opp, opp.bench[prm["b"]])
		"Reactive Generator":
			var e := _take(me.deck, func(c): return CardDB.card_name(c) == "React Energy")
			p.energy.append(e)
			g.shuffle(me.deck)
		"Emerge":
			if g.flip():
				var evo := _take(me.deck, func(c): return CardDB.evolves_onto(c, p.display_name()))
				if evo != "":
					g.evolve(me, p, evo)
				g.shuffle(me.deck)
		"Power Circulation":
			var cands := _distinct(me.discard, func(c): return CardDB.is_basic_energy(c))
			g.ask(me.index, "Power Circulation: basic Energy for the top of your deck", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.discard:
					me.discard.erase(o["id"])
					me.deck.append(o["id"])
					if me.all_in_play().has(p):
						p.damage += 10)
		"Shady Move":
			var from: PokemonInPlay = g.players[prm["fp"]].slot(prm["fs"])
			var to: PokemonInPlay = g.players[prm["tp"]].slot(prm["ts"])
			from.damage -= 10
			to.damage += 10
			g.log_msg("  Moves 1 damage counter from %s to %s." % [from.display_name(), to.display_name()])
		"Delta Supply":
			var t := me.slot(prm["tg"])
			me.hand.erase(prm["id"])
			t.energy.append(prm["id"])
			on_energy_from_hand(g, me, t, prm["id"])
		"Dragon Curse":
			var t := opp.slot(prm["tg"])
			if t != null:
				t.damage += 20
		"Delta Support":
			me.discard.erase(prm["pick"])
			me.hand.append(prm["pick"])
		"Psychic Vision":
			g.log_msg("  Opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
		"Driving Howl":
			g.queue_choice(opp.index, "switch")
		"Excavate":
			var top: String = me.deck[-1]
			g.ask(me.index, "Excavate: top card is %s" % CardDB.card_name(top), [
					{"label": "Leave it on top", "d": false, "ai": Trainers._ai_value(top)},
					{"label": "Discard it", "d": true, "ai": 2.0}], func(o):
				if o["d"] and not me.deck.is_empty() and me.deck[-1] == top:
					me.discard.append(me.deck.pop_back())
					g.log_msg("  Discards the top card of the deck."))
		"Echo Draw":
			me.draw(1)
		"Spike Storm":
			var t := opp.slot(prm["tg"])
			if t != null:
				t.damage += 10
		"Delta Sign":
			me.turn_flags["used_Delta Sign"] = true
			Trainers._ask_from_deck(g, me, "Delta Sign: Pokémon with δ", func(c): return CardDB.is_pokemon(c) and CardDB.is_delta(c))
		"Delta Transport":
			if prm["b"] < me.bench.size():
				g.switch_active(me, prm["b"])
		"Constrain":
			_constrain(g, me, opp)
		"Energy Recycle":
			attach_from_pile(g, me, me.discard, 3, func(c): return CardDB.is_energy(c), func(_x): return true, "Energy Recycle", false)
			me.turn_flags["end_turn_after"] = true
		"Sharing":
			me.turn_flags["used_Sharing"] = true
			g.log_msg("  Opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
			if prm.has("id") and opp.hand.has(prm["id"]):
				g.log_msg("  Uses the effect of %s." % CardDB.card_name(prm["id"]))
				Trainers.play(g, me, prm["id"], prm["tp"])
		"Invitation":
			Trainers._ask_from_deck(g, me, "Invitation: Basic Pokémon or Evolution card", func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c))
		"Volunteer":
			p.damage = maxi(0, p.damage - 40)
			me.discard.append(p.cards.pop_back())
			var evo := _take(me.deck, func(c): return CardDB.card_name(c) in ["Ninetales", "Ninetales ex"])
			if evo != "":
				g.evolve(me, p, evo)
			g.shuffle(me.deck)
		"Dozing":
			p.damage = maxi(0, p.damage - 20)
			p.rotation = ""
			g.try_condition(p, "asleep")
		"Power of Evolution":
			me.hand.append(me.deck.pop_front())
			g.log_msg("  Draws the bottom card of the deck.")
		"Extra Boost", "Fellow Boost":
			var t := me.slot(prm["tg"])
			if t != null and me.hand.has(prm["id"]):
				me.hand.erase(prm["id"])
				t.energy.append(prm["id"])
				g.log_msg("  Attaches %s to %s." % [CardDB.card_name(prm["id"]), t.display_name()])
				on_energy_from_hand(g, me, t, prm["id"])
				if n == "Fellow Boost":
					me.turn_flags["end_turn_after"] = true
		"Imprison":
			var t := opp.slot(prm["tg"])
			if t != null:
				t.flags["imprison"] = true
				g.log_msg("  Puts an Imprison marker on %s." % t.display_name())
		"Type Shift":
			var m := RegEx.create_from_string("type is (\\w+)").search(_ability_text(p, "Type Shift"))
			p.type_override = [m.get_string(1) if m != null else "Colorless"]
			p.flags["type_until"] = g.turn_number
		"Poison Structure":
			if opp.active != null:
				g.try_condition(opp.active, "poisoned")
		"Magnetic Redraw":
			for pl in [me, opp]:
				pl.deck.append_array(pl.hand)
				pl.hand.clear()
				g.shuffle(pl.deck)
				pl.draw(4)
	dark_eyes(g, me, p)


## Dark Eyes (Shiftry ex): el Pokémon del rival que usa un Poké-Power recibe 2 contadores.
static func dark_eyes(g: Game, me: PlayerState, p: PokemonInPlay) -> void:
	var opp := g.other(me)
	if body_in_play(g, opp, "Dark Eyes") and me.all_in_play().has(p) and fired_pl(g, opp, "Dark Eyes"):
		p.damage += 20
		g.log_msg("  Dark Eyes: 2 damage counters on %s." % p.display_name())


## Constrain (Delcatty ex): cada jugador descarta hasta quedarse con 6 cartas (primero vos).
static func _constrain(g: Game, me: PlayerState, opp: PlayerState) -> void:
	for pl in [me, opp]:
		var extra: int = pl.hand.size() - 6
		if extra > 0:
			Trainers.chain(g, pl.index, "Constrain: discard (keep 6)", extra,
					func(_picked): return Trainers._distinct(pl.hand, func(_c): return true), false,
					func(id):
						if pl.hand.has(id):
							pl.hand.erase(id)
							pl.discard.append(id),
					func(): pass)


static func _energy_options(p: PokemonInPlay) -> Array:
	var out: Array = []
	for e in _distinct(p.energy, func(_c): return true):
		out.append({"label": CardDB.card_name(e), "id": e, "ai": 0.0 if CardDB.is_basic_energy(e) else 1.0})
	return out


## El jugador elige una Energía del Pokémon (de "owner") y se descarta.
static func _ask_discard_energy(g: Game, me: PlayerState, owner: PlayerState, p: PokemonInPlay, prompt: String) -> void:
	g.ask(me.index, prompt, _energy_options(p), func(o):
		if owner.all_in_play().has(p) and o["id"] in p.energy:
			p.energy.erase(o["id"])
			owner.discard.append(o["id"])
			g.log_msg("  Discards %s from %s." % [CardDB.card_name(o["id"]), p.display_name()]))


## Terraforming: el jugador vuelve a poner las cartas de a una, de abajo hacia arriba
## (la última elegida queda arriba de todo).
static func _rearrange(g: Game, me: PlayerState, cards: Array, placed: Array) -> void:
	if cards.size() <= 1:
		me.deck.append_array(cards)
		return
	var opts: Array = []
	for c in Trainers._distinct(cards, func(_c): return true):
		opts.append({"label": CardDB.card_name(c), "id": c, "ai": -Trainers._ai_value(c)})
	g.ask(me.index, "Terraforming: card to put down first (%d left)" % cards.size(), opts, func(o):
		var rest: Array = cards.duplicate()
		rest.erase(o["id"])
		me.deck.append(o["id"])
		Abilities._rearrange(g, me, rest, placed + [o["id"]]))


static func _move_energy(from: PokemonInPlay, to: PokemonInPlay, pred: Callable, count: int) -> void:
	var moved := 0
	for i in range(from.energy.size() - 1, -1, -1):
		if moved >= count:
			break
		if pred.call(from.energy[i]):
			to.energy.append(from.energy[i])
			from.energy.remove_at(i)
			moved += 1


static func _take(pile: Array[String], pred: Callable) -> String:
	for i in range(pile.size() - 1, -1, -1):
		if pred.call(pile[i]):
			var c := pile[i]
			pile.remove_at(i)
			return c
	return ""


static func _distinct(cards: Array[String], pred: Callable) -> Array:
	var seen := {}
	for c in cards:
		if pred.call(c):
			seen[c] = true
	return seen.keys()


# ===========================================================================
# Daño
# ===========================================================================

## Prevención total del daño (y de los efectos, ver blocks_effects).
static func prevents_damage(g: Game, attacker: PokemonInPlay, target: PokemonInPlay, is_active: bool) -> bool:
	var owner := g.owner_of(target)
	if target.flags.get("prevent_all", -1) >= g.turn_number:
		return true
	if target.flags.get("prevent_damage", -1) >= g.turn_number:
		return true
	if body(g, target, "Safeguard") and attacker.is_ex() and fired(g, target, "Safeguard"):
		return true
	if body(g, target, "Wonder Guard") and (attacker.is_ex() or attacker.is_evolved()) and fired(g, target, "Wonder Guard"):
		return true
	if _fluff(g, attacker, target):
		return true
	if _shielded(g, attacker, target):
		return true
	if body(g, target, "Hard Protection") and g.owner_of(attacker) == owner and fired(g, target, "Hard Protection"):
		return true
	if body(g, target, "Extra-tight") and attacker.is_ex() and g.owner_of(attacker) != owner and fired(g, target, "Extra-tight"):
		return true
	if owner != null and g.owner_of(attacker) != owner:
		if _benched_delta_guard(g, owner, target):
			return true
		if attacker.is_ex() and synergy(g, target, "Phoebe's Stadium") and fired(g, target, "Synergy Effect"):
			return true
		if attacker.is_ex() and CardDB.card_name(target.tool) == "Mysterious Shard" and not target.is_ex():
			return true
	if not is_active:
		if owner != null and g.owner_of(attacker) != owner and body_in_play(g, owner, "Sand Veil") and fired_pl(g, owner, "Sand Veil"):
			return true
		if body(g, target, "Submerge"):
			return true
		if body(g, target, "Feathery") and g.owner_of(attacker) != owner and fired(g, target, "Feathery"):
			return true
		if active_body(g, owner, "Power Diffusion"):
			return true
	return false


static func blocks_effects(g: Game, attacker: PokemonInPlay, target: PokemonInPlay) -> bool:
	if target.flags.get("prevent_all", -1) >= g.turn_number:
		return true
	var t_owner := g.owner_of(target)
	if t_owner != null and g.owner_of(attacker) != t_owner:
		if _benched_delta_guard(g, t_owner, target):
			return true
		if attacker.is_ex() and CardDB.card_name(target.tool) == "Mysterious Shard" and not target.is_ex():
			return true
		if body(g, target, "Reactive Barrier") and target.energy.any(func(e): return CardDB.card_name(e) == "React Energy") \
				and fired(g, target, "Reactive Barrier"):
			return true
	if body(g, target, "Protective Dust") and fired(g, target, "Protective Dust") \
			or body(g, target, "Crystal Body") and fired(g, target, "Crystal Body"):
		return true
	if body(g, target, "Safeguard") and attacker.is_ex() and fired(g, target, "Safeguard"):
		return true
	if body(g, target, "Wonder Guard") and (attacker.is_ex() or attacker.is_evolved()) and fired(g, target, "Wonder Guard"):
		return true
	if body(g, target, "Immunity") and g.owner_of(attacker) != g.owner_of(target) and fired(g, target, "Immunity"):
		return true
	if _shielded(g, attacker, target):
		return true
	if g.owner_of(attacker) != g.owner_of(target):
		if stages(g, target, "Jynx") or holon(target, "Holon Energy WP", "Water"):
			return true
		if body(g, target, "Darkness Veil") and Energy.count_type(target, "Darkness") > 0 and fired(g, target, "Darkness Veil"):
			return true
		if body(g, target, "Dragon Aura") and target.energy.any(func(e): return CardDB.card_name(e) == "Fire Energy") \
				and target.energy.any(func(e): return CardDB.card_name(e) == "Lightning Energy") and fired(g, target, "Dragon Aura"):
			return true
	return _fluff(g, attacker, target)


## Solid Shell de Cloyster δ: tus Pokémon δ de la Banca no reciben nada de los ataques rivales.
static func _benched_delta_guard(g: Game, owner: PlayerState, target: PokemonInPlay) -> bool:
	if owner.is_active(target) or not CardDB.is_delta(target.top()):
		return false
	for x in owner.all_in_play():
		if body(g, x, "Solid Shell") and _ability_text(x, "Solid Shell").contains("Benched") and fired(g, x, "Solid Shell"):
			return true
	return false


## Protecciones contra un tipo de atacante que frenan daño y efectos (Holy Shield, Fast
## Protection, Advanced Armor, Psychic Shield).
static func _shielded(g: Game, attacker: PokemonInPlay, target: PokemonInPlay) -> bool:
	if g.owner_of(attacker) == g.owner_of(target):
		return false
	if target.flags.get("prevent_ex", -1) >= g.turn_number and attacker.is_ex():
		return true
	if target.flags.get("prevent_evolved", -1) >= g.turn_number and attacker.is_evolved():
		return true
	if body(g, target, "Holy Shield") and attacker.name_has("Dark") and fired(g, target, "Holy Shield"):
		return true
	if body(g, target, "Fast Protection") and attacker.is_basic() and fired(g, target, "Fast Protection"):
		return true
	var owner := g.owner_of(target)
	if body(g, target, "Beacon Protection") and attacker.name_has("Dark") and owner.all_in_play().any(func(x): return x.display_name() == "Volbeat") \
			and fired(g, target, "Beacon Protection"):
		return true
	if body(g, target, "Extra Protection") and attacker.is_ex() and owner.all_in_play().any(func(x): return x.display_name() == "Illumise") \
			and fired(g, target, "Extra Protection"):
		return true
	if attacker.is_ex() and target.display_name() == "Tentacruel" and owner.all_in_play().any(func(x): return body(g, x, "Reactive Shield") \
			and x.energy.any(func(e): return CardDB.card_name(e) == "React Energy")):
		return true
	return false


## Efectos de las Holon Energy (FF, GL, WP): solo si el Pokémon no es ex y tiene la básica que corresponde.
static func holon(p: PokemonInPlay, holon_name: String, basic: String) -> bool:
	if p == null or p.is_ex():
		return false
	return p.energy.any(func(e): return CardDB.card_name(e) == holon_name) and p.energy.any(func(e): return CardDB.card_name(e) == basic + " Energy")


## "Stages of Evolution": cada carta tiene un efecto distinto (y solo si está evolucionada).
static func stages(g: Game, p: PokemonInPlay, who: String) -> bool:
	return p.is_evolved() and p.display_name() == who and body(g, p, "Stages of Evolution")


## Fluff (Jumpluff): si ya tenía daño, una moneda por ataque; con cara se previene todo.
static func _fluff(g: Game, attacker: PokemonInPlay, target: PokemonInPlay) -> bool:
	if not body(g, target, "Fluff") or g.owner_of(attacker) == g.owner_of(target):
		return false
	var key := "%d|%s" % [g.turn_number, attacker.get_instance_id()]
	var memo: Array = target.flags.get("fluff", ["", false])
	if memo[0] != key:
		memo = [key, target.damage > 0 and g.flip()]
		target.flags["fluff"] = memo
	return memo[1] and fired(g, target, "Fluff")


## Modificadores antes de Debilidad/Resistencia.
static func pre_wr_bonus(g: Game, attacker: PokemonInPlay, target: PokemonInPlay, is_active: bool) -> int:
	var bonus := 0
	var att_owner := g.owner_of(attacker)
	var tgt_owner := g.owner_of(target)
	if is_active:
		if attacker.is_type("Darkness") or attacker.name_has("Dark"):
			bonus += 10 * Energy.count_named(attacker, "Darkness Energy")
		if body(g, attacker, "Power Pinchers") and fired(g, attacker, "Power Pinchers"):
			bonus += 10
		if body(g, attacker, "Overzealous") and tgt_owner.all_in_play().any(func(x): return x.is_ex()) \
				and fired(g, attacker, "Overzealous"):
			bonus += 30
	if active_body(g, tgt_owner, "Intimidating Fang") and fired_pl(g, tgt_owner, "Intimidating Fang"):
		bonus -= 10
	if is_active:
		bonus += 10 * Energy.count_named(attacker, "R Energy")
		if attacker.display_name() in NIDOS and body_in_play(g, att_owner, "Power Gene") and fired_pl(g, att_owner, "Power Gene"):
			bonus += 10
		for nm in ["Hunch", "Blaze", "Water Pressure"]:
			if body(g, attacker, nm) and attacker.hp_left() <= 40 and fired(g, attacker, nm):
				bonus += 40
		if tgt_owner.is_active(target) and g.players.any(func(pl): return active_body(g, pl, "Vigorous Aura")):
			bonus += 10
	var w = attacker.flags.get("weaken", null)
	if w != null and w[1] >= g.turn_number:
		bonus -= int(w[0])
	if att_owner != tgt_owner:
		if body(g, attacker, "Danger Perception") and attacker.hp_left() <= 60 and is_active and fired(g, attacker, "Danger Perception"):
			bonus += 40
		if stages(g, attacker, "Hitmonlee"):
			bonus += 20
		if is_active and body(g, attacker, "Reversal Aura") and att_owner.prizes.size() > tgt_owner.prizes.size():
			bonus += 20
		if is_active and body(g, attacker, "Ancient Fang") and att_owner.all_in_play().any(func(x): return x.display_name() in ["Kabuto", "Kabutops", "Kabutops ex"]):
			bonus += 20
		if is_active and body(g, attacker, "Paranoid") and attacker.rotation == "confused":
			bonus += 50
		if is_active and CardDB.is_delta(attacker.top()) and g.stadium_name().contains("Holon") and body_in_play(g, att_owner, "Delta Reactor"):
			bonus += 10
		if is_active and CardDB.card_name(attacker.tool) == "Solid Rage" and att_owner.prizes.size() > tgt_owner.prizes.size():
			bonus += 20
		if is_active and CardDB.is_delta(attacker.top()):
			for x in att_owner.all_in_play():
				if body(g, x, "Battle Aura") and fired(g, x, "Battle Aura"):
					bonus += 10
		var s2ex := attacker.is_ex() and CardDB.stage(attacker.top()) == 2
		if is_active and s2ex:
			for x in att_owner.all_in_play():
				if body(g, x, "Extra Feather") and fired(g, x, "Extra Feather"):
					bonus += 10
		if target.is_ex() and CardDB.stage(target.top()) == 2 and body_in_play(g, tgt_owner, "Extra Smoke") and fired_pl(g, tgt_owner, "Extra Smoke"):
			bonus -= 10
		if is_active and body(g, attacker, "Frenzy"):
			var txt := _ability_text(attacker, "Frenzy")
			var rivals := ["Groudon", "Kyogre", "Rayquaza"].filter(func(nm): return txt.contains(nm + ","))
			if tgt_owner.all_in_play().any(func(x): return x.display_name().trim_suffix(" ex") in rivals or x.display_name() in rivals) \
					and fired(g, attacker, "Frenzy"):
				bonus += 40
		if attacker.is_ex() and active_body(g, tgt_owner, "Lazy Aura") and fired_pl(g, tgt_owner, "Lazy Aura"):
			bonus -= 30
		if active_body(g, tgt_owner, "Intimidating Pattern") and fired_pl(g, tgt_owner, "Intimidating Pattern"):
			bonus -= 20
	return bonus


## Debilidades que cuentan (Dragon Veil, Dark Condition, Electro-guard, Dark Hole las sacan).
static func weakness_types(g: Game, target: PokemonInPlay) -> Array:
	var w: Array = target.data().get("weaknesses", []).duplicate()
	if w.is_empty():
		return w
	if g.stadium_name() == "Holon Legacy" and CardDB.is_delta(target.top()):
		return []
	if g.stadium_name() == "Glacia's Stadium" and target.is_type("Water") and not target.is_ex():
		return []
	if target.flags.get("no_weakness", -1) >= g.turn_number or stages(g, target, "Jynx") or holon(target, "Holon Energy FF", "Fire") \
			or CardDB.card_name(target.tool) == "Protective Orb":
		return []
	var tow := g.owner_of(target)
	if tow != null:
		if target.is_type("Water") and tow.all_in_play().any(func(x): return body(g, x, "Hydro Barrier") and x.energy.any(func(e): return CardDB.card_name(e).begins_with("Holon Energy"))):
			return []
		if target.display_name() in FOSSIL_LINE and body_in_play(g, tow, "Ancient Protection"):
			return []
	var owner := g.owner_of(target)
	if owner != null:
		if owner.is_active(target) and (body_in_play(g, owner, "Dragon Veil") or body_in_play(g, owner, "Shield Veil")):
			return []
		if owner.bench.any(func(x): return body(g, x, "Dark Hole")):
			w.erase("Darkness")
	if body(g, target, "Dark Condition") and Energy.count_type(target, "Darkness") > 0:
		return []
	if body(g, target, "Electro-guard") and Energy.count_type(target, "Lightning") > 0:
		return []
	return w


static func ignores_weakness(g: Game, target: PokemonInPlay) -> bool:
	if CardDB.card_name(target.tool) == "Weakness Guard":
		return true
	return g.stadium_name() == "Ancient Tomb" and not target.is_ex() and not target.has_owner()


## Cuánto resta la Resistencia (Enervating Pollen de Gloom la deja en 10).
static func resistance_value(g: Game, base: int) -> int:
	if body_anywhere(g, "Enervating Pollen"):
		return mini(base, 10)
	return base


static func _is_baby(id: String) -> bool:
	return "Baby" in CardDB.get_card(id).get("subtypes", [])


static func ignores_resistance(g: Game, attacker: PokemonInPlay, target: PokemonInPlay = null) -> bool:
	if body_anywhere(g, "Withering Dust"):
		return true
	if target != null and g.owner_of(target) != null and active_body(g, g.other(g.owner_of(target)), "Tropical Motion"):
		return true
	if holon(attacker, "Holon Energy FF", "Fighting"):
		return true
	if attacker.display_name() in FOSSIL_LINE and g.owner_of(attacker) != null and body_in_play(g, g.owner_of(attacker), "Ancient Tentacles"):
		return true
	return g.stadium_name() == "Magnetic Storm" and (attacker.is_type("Psychic") or attacker.is_type("Fighting"))


## Modificadores después de Debilidad/Resistencia. Devuelve el daño final.
static func post_wr(g: Game, attacker: PokemonInPlay, target: PokemonInPlay, is_active: bool, dmg: int, ignore_fx: bool) -> int:
	var tgt_owner := g.owner_of(target)
	if is_active and CardDB.card_name(attacker.tool) == "Strength Charm" and dmg > 0:
		dmg += 10
		attacker.flags["discard_tool"] = g.turn_number
	dmg -= 10 * Energy.count_named(attacker, "Double Rainbow Energy")
	if ignore_fx:
		return dmg
	if target.is_type("Metal"):
		dmg -= 10 * Energy.count_named(target, "Metal Energy")
	if body(g, target, "Exoskeleton") and fired(g, target, "Exoskeleton"):
		dmg -= 20
	if body(g, target, "Hard Cocoon") and dmg > 0 and g.flip() and fired(g, target, "Hard Cocoon"):
		dmg -= 30
	if body(g, target, "Sand Guard") and dmg > 0 and g.flip() and fired(g, target, "Sand Guard"):
		dmg -= 20
	if body(g, target, "Energy Guard") and target.basic_energy_count() > 0 and fired(g, target, "Energy Guard"):
		dmg -= 10
	if body(g, target, "Shell Retreat") and not target.energy.is_empty() and fired(g, target, "Shell Retreat"):
		dmg -= 10
	if body(g, target, "Core Guard") and Energy.count_type(target, "Psychic") > 0 and fired(g, target, "Core Guard"):
		dmg -= 10
	if body(g, target, "Crust") and attacker.is_basic() and fired(g, target, "Crust"):
		dmg -= 30
	if body(g, target, "Ice Wall") and attacker.special_energy_count() > 0 and fired(g, target, "Ice Wall"):
		dmg -= 40
	if body(g, target, "Glowing Screen") and (attacker.is_type("Fighting") or attacker.is_type("Darkness")) \
			and tgt_owner.all_in_play().any(func(x): return x.display_name() == "Volbeat") and fired(g, target, "Glowing Screen"):
		dmg -= 30
	if body(g, target, "Rock Body") and fired(g, target, "Rock Body"):
		dmg -= 10
	if body(g, target, "Vase Body") and fired(g, target, "Vase Body"):
		dmg -= 20
	if body(g, target, "Thick Shell") and attacker.is_evolved() and fired(g, target, "Thick Shell"):
		dmg -= 10
	if body(g, target, "Dense Body") and attacker.is_basic() and not _is_baby(attacker.top()) and fired(g, target, "Dense Body"):
		dmg -= 20
	if body(g, target, "Energy Barrier") and target.basic_energy_count() > 0 and fired(g, target, "Energy Barrier"):
		dmg -= 10 * mini(2, target.basic_energy_count())
	if CardDB.card_name(target.tool) == "Buffer Piece":
		dmg -= 20
	var att_owner := g.owner_of(attacker)
	var opp_attack := att_owner != tgt_owner
	if body(g, target, "Energy Protection") and fired(g, target, "Energy Protection"):
		dmg -= mini(30, 10 * Energy.total(target))
	if body(g, target, "Powder Protection") and attacker.has_owner() and fired(g, target, "Powder Protection"):
		dmg -= 40
	if body(g, target, "Dense") and attacker.is_evolved():
		var txt := _ability_text(target, "Dense")
		if (opp_attack or not txt.contains("opponent's")) and fired(g, target, "Dense"):
			dmg -= _first_int(txt, 10)
	if opp_attack and body(g, target, "Darkness Guard") and Energy.count_type(target, "Darkness") > 0 and fired(g, target, "Darkness Guard"):
		dmg -= 10
	if opp_attack and body(g, target, "Dark Protection") and fired(g, target, "Dark Protection"):
		dmg -= mini(20, 10 * Energy.count_type(target, "Darkness"))
	if body(g, target, "Mist") and CardDB.stage(attacker.top()) == 2 and fired(g, target, "Mist"):
		dmg -= 30
	if opp_attack and body(g, target, "Rai-shield") and attacker.is_ex() and fired(g, target, "Rai-shield"):
		dmg -= 30
	if opp_attack and stages(g, target, "Electabuzz") and attacker.special_energy_count() > 0:
		dmg -= 40
	if body(g, target, "Thick Fat") and (attacker.is_type("Fire") or attacker.is_type("Water")) and fired(g, target, "Thick Fat"):
		dmg -= 30
	if opp_attack and body(g, target, "Reversal Aura") and att_owner.is_active(attacker) and tgt_owner.prizes.size() > att_owner.prizes.size():
		dmg -= 20
	if opp_attack and body(g, target, "Reactive Protection"):
		dmg -= 10 * target.energy.filter(func(e): return CardDB.card_name(e) == "React Energy").size()
	if body(g, target, "Ancient Shell") and tgt_owner.all_in_play().any(func(x): return x.display_name() in ["Omanyte", "Omastar"]):
		dmg -= 20
	if opp_attack and attacker.is_ex() and holon(target, "Holon Energy GL", "Lightning"):
		dmg -= 10
	if target.flags.get("reduce_until", -1) >= g.turn_number:
		dmg -= int(target.flags.get("reduce_by", 0))
	if opp_attack and CardDB.is_delta(attacker.top()) and body(g, target, "Delta Protection") and fired(g, target, "Delta Protection"):
		dmg -= 40
	if body(g, target, "Solid Shell") and _ability_text(target, "Solid Shell").contains("reduced by 10") and fired(g, target, "Solid Shell"):
		dmg -= 10
	if body(g, target, "Armor") and att_owner.hand.size() >= 5 and fired(g, target, "Armor"):
		dmg -= 30
	if target.display_name() == "Groudon ex" and tgt_owner.all_in_play().any(func(x): return body(g, x, "Hard Rock") and Energy.total(x) <= 1) \
			and fired_pl(g, tgt_owner, "Hard Rock"):
		dmg -= 20
	if opp_attack and synergy(g, target, "Glacia's Stadium") and fired(g, target, "Synergy Effect"):
		dmg -= 30
	if opp_attack and g.stadium_name() == "Drake's Stadium" and target.is_type("Colorless") and tgt_owner.is_active(target):
		dmg -= 10
	if opp_attack and dmg > 0 and body(g, target, "Psychic Protector") and not tgt_owner.hand.is_empty():
		dmg -= _psychic_protector(g, tgt_owner, target, dmg)
	return dmg


## Psychic Protector (Flygon ex): descarta hasta 4 cartas de la mano y baja 10 por cada una.
## Se decide solo: las justas para no quedar Fuera de Combate (si con 4 no alcanza, ninguna).
static func _psychic_protector(g: Game, owner: PlayerState, target: PokemonInPlay, dmg: int) -> int:
	var need := int(ceil(float(dmg - target.hp_left() + 1) / 10.0))
	if need <= 0 or need > mini(4, owner.hand.size()):
		return 0
	var hand := owner.hand.duplicate()
	hand.sort_custom(func(a, b): return Trainers._ai_value(a) < Trainers._ai_value(b))
	for i in need:
		owner.hand.erase(hand[i])
		owner.discard.append(hand[i])
	fired(g, target, "Psychic Protector")
	g.log_msg("  Psychic Protector: discards %d card(s) to reduce the damage." % need)
	return need * 10


## Poké-Bodies que reaccionan cuando el Activo recibe daño de un ataque.
static func after_damaged(g: Game, attacker: PokemonInPlay, target: PokemonInPlay) -> void:
	var tgt_owner := g.owner_of(target)
	if not tgt_owner.is_active(target):
		return
	if body(g, target, "Rough Skin") and fired(g, target, "Rough Skin"):
		attacker.damage += 20
		g.log_msg("  Rough Skin: 2 damage counters on %s." % attacker.display_name())
	if body(g, target, "Strikes Back") and fired(g, target, "Strikes Back"):
		attacker.damage += 10
		g.log_msg("  Strikes Back: 1 damage counter on %s." % attacker.display_name())
	if body(g, target, "Fluffy Fur") and g.owner_of(attacker) != tgt_owner and fired(g, target, "Fluffy Fur"):
		g.try_condition(attacker, "asleep")
	if body(g, target, "Poison Payback") and fired(g, target, "Poison Payback"):
		g.try_condition(attacker, "poisoned")
	if body(g, target, "Fire Veil") and fired(g, target, "Fire Veil"):
		g.try_condition(attacker, "burned")
	if stages(g, target, "Hitmontop"):
		attacker.damage += 20
		g.log_msg("  Stages of Evolution: 2 damage counters on %s." % attacker.display_name())
	if body(g, target, "Silver Sparkle") and fired(g, target, "Silver Sparkle") and g.flip() and not attacker.energy.is_empty():
		var att_owner := g.owner_of(attacker)
		var e: String = attacker.energy.pop_back()
		att_owner.hand.append(e)
		g.log_msg("  Silver Sparkle: %s returns to the opponent's hand." % CardDB.card_name(e))
	if body(g, target, "Spiny") and fired(g, target, "Spiny"):
		var h := 0
		while g.flip():
			h += 1
		if h > 0:
			attacker.damage += 10 * h
			g.log_msg("  Spiny: %d damage counter(s) on %s." % [h, attacker.display_name()])


## Ajustes al daño final (Magic Odds / Magic Evens de Mr. Mime ex).
static func final_damage(g: Game, attacker: PokemonInPlay, target: PokemonInPlay, dmg: int) -> int:
	if dmg > 0 and dmg % 10 == 0:
		var odd := (dmg / 10) % 2 == 1
		if odd and body(g, target, "Magic Odds") and fired(g, target, "Magic Odds"):
			return 0
		if not odd and body(g, target, "Magic Evens") and fired(g, target, "Magic Evens"):
			return 0
	return dmg


## El daño de un ataque rival lo deja Fuera de Combate: Buffer, Dark Scale, Knockout Gas.
static func on_would_ko(g: Game, attacker: PokemonInPlay, target: PokemonInPlay) -> void:
	var owner := g.owner_of(target)
	if body(g, target, "Buffer") and fired(g, target, "Buffer") and g.flip():
		target.damage = target.max_hp() - 10
		g.log_msg("  Buffer: %s holds on with 10 HP!" % target.display_name())
		return
	_ko_powers(g, owner, attacker, target)
	if owner == null or not owner.is_active(target):
		return
	if body(g, target, "Spiral Swirl") and fired(g, target, "Spiral Swirl"):
		g.try_condition(attacker, "confused")
	if CardDB.card_name(target.tool) == "Curse Powder" and target.is_evolved() and not target.is_ex():
		attacker.damage += 30
		g.log_msg("  Curse Powder: 3 damage counters on %s." % attacker.display_name())
	if body(g, target, "Dark Scale") and fired(g, target, "Dark Scale"):
		attacker.damage += 30
		g.log_msg("  Dark Scale: 3 damage counters on %s." % attacker.display_name())
	if body(g, target, "Knockout Gas") and fired(g, target, "Knockout Gas"):
		g.try_condition(attacker, "confused")
		g.try_condition(attacker, "poisoned")


## Quemadura entre turnos: Fiery Aura (Rapidash Activo) la sube a 4 contadores.
static func burn_damage(g: Game, base: int) -> int:
	if g.stadium_name() == "Full Flame" or g.players.any(func(pl): return active_body(g, pl, "Fiery Aura") and fired_pl(g, pl, "Fiery Aura")):
		return 40
	return base


static func _ability_text(p: PokemonInPlay, ability_name: String) -> String:
	for a in p.abilities():
		if a["name"] == ability_name:
			return str(a["text"])
	return ""


static func _first_int(text: String, fallback: int) -> int:
	var m := RegEx.create_from_string("reduced by (\\d+)").search(text)
	return int(m.get_string(1)) if m != null else fallback


static func can_have_condition(g: Game, p: PokemonInPlay, cond: String) -> bool:
	if p.is_fossil() or body(g, p, "Thick Skin") and fired(g, p, "Thick Skin"):
		return false
	if cond == "poisoned" and body(g, p, "Poison Resistance") and fired(g, p, "Poison Resistance"):
		return false
	var immune := {"Insomnia": ["asleep"], "Self-control": ["paralyzed"], "Carefree": ["confused"],
			"Magma Armor": ["asleep", "paralyzed"], "Clear Body": ["asleep", "confused", "paralyzed", "poisoned", "burned"]}
	for nm in immune:
		if cond in immune[nm] and body(g, p, nm) and fired(g, p, nm):
			return false
	if body(g, p, "Dark and Clear") and Energy.count_type(p, "Darkness") > 0 and fired(g, p, "Dark and Clear"):
		return false
	if holon(p, "Holon Energy GL", "Grass"):
		return false
	if g.stadium_name() == "Sidney's Stadium" and p.is_type("Darkness") and cond in ["asleep", "confused", "paralyzed"]:
		return false
	var owner := g.owner_of(p)
	if owner != null and owner.is_active(p) and Energy.count_type(p, "Grass") > 0 and body_in_play(g, owner, "Green Essence") \
			and fired_pl(g, owner, "Green Essence"):
		return false
	return true


# ===========================================================================
# Retirada, ataques y cartas bloqueadas
# ===========================================================================

static func retreat_cost(g: Game, me: PlayerState, p: PokemonInPlay) -> int:
	if body(g, p, "Uplifting Glow") and me.all_in_play().any(func(x): return x.display_name() == "Illumise"):
		return 0
	if body(g, p, "Levitate") and p.basic_energy_count() > 0:
		return 0
	if body(g, p, "Dark Lift") and Energy.count_type(p, "Darkness") > 0:
		return 0
	if body(g, p, "Freefloating") and p.energy.is_empty():
		return 0
	if p.flags.get("free_retreat", -1) >= g.turn_number:                      # Tailwind (Dragonite)
		return 0
	if body(g, p, "Psychoflow") and Energy.count_named(p, "Psychic Energy") > 0:
		return 0
	var opp_active := g.other(me).active
	if body(g, p, "Slippery Skin") and opp_active != null and opp_active.is_evolved():
		return 0
	if body(g, p, "Free Flight") and p.energy.is_empty() \
			or (body(g, p, "Leaf Ride") or body(g, p, "Floating Electrons")) and not p.energy.is_empty() \
			or body(g, p, "Metallic Lift") and Energy.count_type(p, "Metal") > 0 \
			or body(g, p, "Aqua Lift") and Energy.count_type(p, "Water") > 0 \
			or body(g, p, "Scramble") and opp_active != null and opp_active.is_ex():
		return 0
	if p.display_name() in NIDOS and p.display_name() != "Nidoqueen" and body_in_play(g, me, "Family Bonds"):
		return 0
	if p.display_name() == "Solrock" and body_in_play(g, me, "Moonglow"):
		return 0
	if not p.is_ex() and not _is_baby(p.top()) and body_in_play(g, me, "Dragon Lift"):
		return 0
	if CardDB.card_name(p.tool) == "Fluffy Berry" or holon(p, "Holon Energy WP", "Psychic"):
		return 0
	if p.is_type("Water") and not p.is_ex() and me.all_in_play().any(func(x): return body(g, x, "Reactive Lift") and x.energy.any(func(e): return CardDB.card_name(e) == "React Energy")):
		return 0
	if body(g, p, "Psychic Wing") and Energy.count_type(p, "Psychic") > 0:
		return 0
	if p.is_ex() and CardDB.stage(p.top()) == 2 and body_in_play(g, me, "Extra Wing"):
		return 0
	if (p.display_name().begins_with("Latias") or p.display_name().begins_with("Latios")) and body_in_play(g, me, "Link Wing"):
		return 0
	if p.display_name() == "Kyogre ex" and me.all_in_play().any(func(x): return body(g, x, "Flotation") and Energy.total(x) <= 1):
		return 0
	if body(g, p, "Synchronized Lift"):
		var need := ["Articuno ex", "Moltres ex", "Zapdos ex"]
		need.erase(p.display_name())
		if need.all(func(nm): return me.all_in_play().any(func(x): return x.display_name() == nm)):
			return 0
	var cost := p.base_retreat_cost()
	if body(g, p, "Extreme Speed"):
		cost -= p.energy.size()
	if body(g, p, "Lightweight"):
		cost -= Energy.count_named(p, "Grass Energy")
	if body(g, p, "Conductive Body"):
		cost -= me.bench.filter(func(x): return x.display_name() == "Magnemite").size()
	if body(g, p, "Heavyweight") and Energy.count_named(p, "Grass Energy") > 0:
		cost += 2
	if me.is_active(p) and body_anywhere(g, "Gluey Slime"):
		cost += 1
	if me.is_active(p) and active_body(g, g.other(me), "Sticky Goo"):
		cost += 2
	if me.is_active(p) and g.other(me).all_in_play().any(func(x): return stages(g, x, "Wobbuffet")):
		cost += 1
	if me.is_active(p) and not p.is_ex() and not _is_baby(p.top()) and me.bench.any(func(x): return body(g, x, "Retreat Aid")):
		cost -= 2
	if p.display_name() in ["Jigglypuff", "Wigglytuff", "Wigglytuff ex", "Igglybuff"] and body_in_play(g, me, "Hover Lift"):
		cost -= 1
	match g.stadium_name():
		"High Pressure System":
			if p.is_type("Fire") or p.is_type("Water"):
				cost -= 1
		"Phoebe's Stadium":
			if p.is_type("Psychic"):
				cost -= 2
		"Team Aqua Hideout":
			if not p.name_has("Team Aqua"):
				cost += 1
	return max(0, cost)


static func can_retreat(g: Game, me: PlayerState, p: PokemonInPlay) -> bool:
	if p.is_fossil():
		return false
	if p.energy.any(func(e): return CardDB.card_name(e) == "Boost Energy"):
		return false
	if active_body(g, g.other(me), "Super Suction Cups"):
		return false
	if p.rotation == "confused" and active_body(g, g.other(me), "Spiral"):
		return false
	if p.rotation in ["asleep", "paralyzed"] and not body(g, p, "Fast Feet"):
		return false
	return true


static func attack_blocked(g: Game, p: PokemonInPlay) -> bool:
	var own := g.owner_of(p)
	if own != null:
		var opp := g.other(own)
		if p.is_basic() and not p.is_fossil():
			if active_body(g, opp, "Intimidating Ring") or active_body(g, opp, "Intimidating Armor"):
				return true
			if opp.all_in_play().size() == 1 and body(g, opp.all_in_play()[0], "Shining Horn"):
				return true
		if p.display_name() == "Dunsparce" and active_body(g, opp, "Deadlock"):
			return true
	if body(g, p, "Power Saver"):
		var team := "Team Magma" if p.name_has("Team Magma") else "Team Aqua"
		var count := 0
		for pl in g.players:
			count += pl.count_in_play(func(x): return x.name_has(team))
		if count <= 3:
			return true
	if p.display_name() in ["Kyogre ex", "Rayquaza ex"]:
		for pl in g.players:
			if active_body(g, pl, "Mark of Antiquity"):
				return true
	return false


static func extra_attack_cost(g: Game, p: PokemonInPlay) -> int:
	if p.is_evolved():
		for pl in g.players:
			if active_body(g, pl, "Primal Pull"):
				return 1
	return 0


static func supporters_blocked(g: Game) -> bool:
	return g.players.any(func(pl): return active_body(g, pl, "Primal Veil"))


static func items_blocked(g: Game, me: PlayerState) -> bool:
	var opp := g.other(me)
	if body_in_play(g, opp, "Lonesome") and opp.all_in_play().size() < me.all_in_play().size():
		return true
	return active_body(g, opp, "Block Dust")


static func tools_blocked(g: Game, me: PlayerState) -> bool:
	return body_in_play(g, g.other(me), "Primal Lock")


static func evolve_active_blocked(g: Game, me: PlayerState) -> bool:
	return active_body(g, g.other(me), "Primal Vibes") or active_body(g, g.other(me), "Primal Stare") \
			or body_in_play(g, g.other(me), "Binding Aura")


## Primal Aura (Kabutops Activo, de cualquiera): nadie evoluciona Pokémon de la Banca.
static func evolve_bench_blocked(g: Game) -> bool:
	return g.players.any(func(pl): return active_body(g, pl, "Primal Aura"))


## Energías que no se pueden unir desde la mano (Anti-Lightning, Water/Fire Immunity).
static func can_attach_from_hand(g: Game, card_id: String, p: PokemonInPlay) -> bool:
	var n := CardDB.card_name(card_id)
	if n == "Lightning Energy" and body(g, p, "Anti-Lightning"):
		return false
	if n == "Water Energy" and body(g, p, "Water Immunity"):
		return false
	if n == "Fire Energy" and body(g, p, "Fire Immunity"):
		return false
	var owner := g.owner_of(p)
	if owner != null and owner.is_active(p) and not CardDB.is_basic_energy(card_id) and n not in ["Darkness Energy", "Metal Energy"] \
			and active_body(g, g.other(owner), "Cursed Glare"):
		return false
	if owner != null and p.rotation == "asleep" and body_in_play(g, g.other(owner), "Binding Aura"):
		return false
	return true


# ===========================================================================
# Eventos
# ===========================================================================

## Se une una Energía desde la mano (normal o con un Poké-Power).
static func on_energy_from_hand(g: Game, me: PlayerState, p: PokemonInPlay, card_id: String) -> void:
	var n := CardDB.card_name(card_id)
	if CardDB.card_name(card_id) == "Rainbow Energy":
		p.damage += 10
	if n == "Warp Energy" and p == me.active and not me.bench.is_empty():
		g.log_msg("  Warp Energy: %s switches with a Benched Pokémon." % p.display_name())
		g.queue_choice(me.index, "switch")
	if body(g, p, "Natural Cure") and n == "Fire Energy" and fired(g, p, "Natural Cure"):
		p.clear_conditions()
		g.log_msg("  Natural Cure: %s recovers from its Special Conditions." % p.display_name())
	if body(g, p, "Natural Remedy") and n == "Water Energy" and fired(g, p, "Natural Remedy"):
		p.damage = max(0, p.damage - 10)
	if body(g, p, "Self-healing") and n == _body_energy(p, "Self-healing") and fired(g, p, "Self-healing"):
		p.clear_conditions()
		g.log_msg("  Self-healing: %s recovers from its Special Conditions." % p.display_name())
	if body(g, p, "Crystal Type") and CardDB.is_basic_energy(card_id) \
			and CardDB.basic_energy_type(card_id) in ["Water", "Lightning", "Psychic"] and fired(g, p, "Crystal Type"):
		p.type_override = [CardDB.basic_energy_type(card_id)]
		p.flags["type_until"] = g.turn_number
	if body(g, p, "Pure Body") and n == _body_energy(p, "Pure Body") and fired(g, p, "Pure Body"):
		_ask_discard_energy(g, me, me, p, "Pure Body: discard an Energy from %s" % p.display_name())
	if g.stadium_name() == "Pokémon Park" and not me.is_active(p) and p.damage > 0 and not me.turn_flags.get("park", false):
		me.turn_flags["park"] = true
		p.damage -= 10
		g.log_msg("  Pokémon Park: removes 1 damage counter from %s." % p.display_name())
	if body_in_play(g, g.other(me), "Conductivity"):
		p.damage += 10
		g.log_msg("  Conductivity: 1 damage counter on %s." % p.display_name())
	if g.stadium_name() == "Island Cave" and (p.is_type("Water") or p.is_type("Fighting") or p.is_type("Metal")):
		p.clear_conditions()
	if n == "Heal Energy" and not p.is_ex():
		p.damage = max(0, p.damage - 10)
		p.clear_conditions()
		g.log_msg("  Heal Energy: %s recovers." % p.display_name())
	if n == "Water Energy" and body(g, p, "Saturation") and fired(g, p, "Saturation"):
		var m := RegEx.create_from_string("and (\\d+) damage counter").search(_ability_text(p, "Saturation"))
		p.clear_conditions()
		p.damage = max(0, p.damage - 10 * (int(m.get_string(1)) if m != null else 1))
	var opp_pl := g.other(me)
	if not CardDB.is_basic_energy(card_id) and body_in_play(g, opp_pl, "Delta Moon") and not me.turn_flags.get("delta_moon", false):
		me.turn_flags["delta_moon"] = true
		p.damage += 10
		g.log_msg("  Delta Moon: 1 damage counter on %s." % p.display_name())
	if n == "React Energy" and body(g, p, "Reactive Healing") and fired(g, p, "Reactive Healing"):
		p.damage = 0
	if n == "Fire Energy" and body(g, p, "Fire Remedy") and fired(g, p, "Fire Remedy"):
		p.damage = max(0, p.damage - 10)
		p.clear_conditions()
	if n == "Cyclone Energy" and me.is_active(p) and opp_pl.active != null and not opp_pl.bench.is_empty():
		g.log_msg("  Cyclone Energy: the opponent switches the Defending Pokémon.")
		g.queue_choice(opp_pl.index, "switch")
	if CardDB.is_holon_energy(card_id) and Energy.units_of_card(card_id).size() == 2:
		# Holon's Electrode/Magneton/Castform: se devuelve a la mano otra Energía de ese Pokémon
		var others: Array = _distinct(p.energy, func(e): return e != card_id)
		if not others.is_empty():
			g.ask(me.index, "%s: Energy to return to your hand" % CardDB.card_name(card_id), Trainers._card_options(others, false).map(func(o):
					o["ai"] = -float(o["ai"])
					return o), func(o):
				if p.energy.has(o["id"]):
					p.energy.erase(o["id"])
					me.hand.append(o["id"]))
	if p.has_ability("Energy Evolution") and not power_blocked(g, me, p) and (CardDB.is_energy(card_id) or CardDB.is_holon_energy(card_id)):
		var et := CardDB.basic_energy_type(card_id) if CardDB.is_basic_energy(card_id) else ""
		var evos := _distinct(me.deck, func(c): return CardDB.evolves_onto(c, p.display_name()) and (et == "" or et in CardDB.types(c)))
		if not evos.is_empty() and et != "":
			var opts := Trainers._card_options(evos, false)
			opts.append({"label": "Don't evolve", "id": "", "ai": 0.0})
			g.ask(me.index, "Energy Evolution: evolve %s?" % p.display_name(), opts, func(o):
				if o["id"] != "" and me.deck.has(o["id"]) and me.all_in_play().has(p):
					me.deck.erase(o["id"])
					g.evolve(me, p, o["id"])
					g.shuffle(me.deck))
	if n == "Darkness Energy" and p.has_ability("Lightning Burst") and not power_blocked(g, me, p) \
			and g.other(me).active != null and not g.other(me).bench.is_empty():
		var opp := g.other(me)
		g.ask(me.index, "Lightning Burst: switch the Defending Pokémon?", [
				{"label": "Use Lightning Burst", "use": true, "ai": 1.0}, {"label": "Don't use it", "use": false, "ai": 0.0}], func(o):
			if o["use"] and not opp.bench.is_empty():
				g.log_msg("%s uses Lightning Burst." % p.display_name())
				g.queue_choice(opp.index, "switch"))


## "To attach a Fire Energy card..." / "Whenever you attach a Fire Energy card...": qué Energía nombra el texto.
static func _body_energy(p: PokemonInPlay, ability_name: String) -> String:
	for a in p.abilities():
		if a["name"] == ability_name:
			var m := RegEx.create_from_string("attach an? (\\w+) Energy card").search(str(a["text"]))
			if m != null:
				return m.get_string(1) + " Energy"
	return ""


## Mirror Coat (Wobbuffet): si queda Envenenado o Quemado por el ataque del rival, el
## Pokémon Defensor (el que ataca) queda igual.
static func on_condition(g: Game, p: PokemonInPlay, cond: String) -> void:
	if cond not in ["poisoned", "burned"] or not body(g, p, "Mirror Coat"):
		return
	var owner := g.owner_of(p)
	if owner == null or owner.index == g.current or g.phase != "main" and g.phase != "choice":
		return
	var att := g.current_player().active
	if att != null and att != p and fired(g, p, "Mirror Coat"):
		g.log_msg("  Mirror Coat!")
		g.try_condition(att, cond)


## Poké-Powers que se activan al evolucionar desde la mano (Skyridge).
static func on_evolve_from_hand(g: Game, me: PlayerState, p: PokemonInPlay, slot: int) -> void:
	var opp := g.other(me)
	if body_in_play(g, opp, "Darkest Impulse") and fired_pl(g, opp, "Darkest Impulse"):
		p.damage += 20
		g.log_msg("  Darkest Impulse: 2 damage counters on %s." % p.display_name())
	for ab in p.abilities():
		var n: String = ab["name"]
		if ab["kind"] != "Poké-Power" or n not in EVOLVE_TRIGGER or power_blocked(g, me, p):
			continue
		if n not in EVOLVE_ANYWHERE and not PlayerState.is_active_slot(slot):
			continue
		if n == "Froth":
			g.log_msg("%s uses Froth." % p.display_name())
			for x in opp.actives():
				g.try_condition(x, "paralyzed")
			continue
		if n == "Venom Spray":
			g.log_msg("%s uses Venom Spray." % p.display_name())
			if opp.active != null:
				g.try_condition(opp.active, "paralyzed")
				g.try_condition(opp.active, "poisoned")
			continue
		var opts := [{"label": "Use " + n, "use": true, "ai": 1.0}, {"label": "Don't use it", "use": false, "ai": 0.0}]
		g.ask(me.index, "%s: use %s?" % [p.display_name(), n], opts, func(o):
			if o["use"] and me.all_in_play().has(p):
				g.log_msg("%s uses %s." % [p.display_name(), n])
				_evolve_power(g, me, p, n)
				Abilities.dark_eyes(g, me, p))


static func _evolve_power(g: Game, me: PlayerState, p: PokemonInPlay, n: String) -> void:
	var opp := g.other(me)
	match n:
		"Peal of Thunder":
			var top: Array[String] = []
			for i in mini(5, me.deck.size()):
				top.append(me.deck.pop_back())
			g.log_msg("  Looks at the top %d cards: %s." % [top.size(), ", ".join(top.map(func(c): return CardDB.card_name(c)))])
			var en := top.filter(func(c): return CardDB.is_energy(c))
			var rest := top.filter(func(c): return not CardDB.is_energy(c))
			me.discard.append_array(rest)
			if en.is_empty():
				return
			var opts: Array = []
			for sl in me.slots():
				opts.append({"label": me.slot(sl).display_name(), "s": sl, "ai": 2.0 if sl == -1 else 1.0})
			opts.append({"label": "Discard them", "s": -99, "ai": 0.0})
			g.ask(me.index, "Peal of Thunder: attach %d Energy to..." % en.size(), opts, func(o):
				var t := me.slot(o["s"]) if o["s"] != -99 else null
				if t == null:
					me.discard.append_array(en)
					return
				t.energy.append_array(en)
				g.log_msg("  Attaches %d Energy to %s." % [en.size(), t.display_name()]))
		"Evolutionary Call":
			Trainers._pick_sequence(g, me, "Evolutionary Call: Pokémon", 3,
					func(_picked): return Trainers._distinct(me.deck, func(c): return CardDB.is_pokemon(c) and not CardDB.is_fossil(c)), [])
		"Dig Up":
			Trainers.chain(g, me.index, "Dig Up: Pokémon Tool to your hand", 2,
					func(_picked): return Trainers._distinct(me.discard, func(c): return CardDB.is_pokemon_tool(c)), true,
					func(id):
						if me.discard.has(id):
							me.discard.erase(id)
							me.hand.append(id),
					func(): pass)
		"Chilling Breath":
			opp.flags["no_trainers"] = g.turn_number + 1
			g.log_msg("  The opponent can't play Trainer cards during their next turn.")
		"Energy Recharge":
			var heads := g.flip_many(3)
			_attach_from_discard(g, me, p, heads, "Energy Recharge")
		"Manipulate":
			var cands := _distinct(me.discard, func(c): return CardDB.is_basic_pokemon(c) and not _is_baby(c))
			if cands.is_empty() or me.bench.size() >= g.rules.bench_size:
				return
			g.ask(me.index, "Manipulate: Basic Pokémon to your Bench", Trainers._card_options(cands, false), func(o):
				if o["id"] in me.discard and me.bench.size() < g.rules.bench_size:
					me.discard.erase(o["id"])
					var np := PokemonInPlay.new(o["id"], g.turn_number)
					me.bench.append(np)
					g.log_msg("  Puts %s on the Bench." % CardDB.card_name(o["id"]))
					_attach_from_discard(g, me, np, g.flip_many(3), "Manipulate"))
		"Flame Vapor":
			var heads := g.flip_many(2)
			for i in heads:
				if opp.active != null and not opp.active.energy.is_empty():
					_ask_discard_energy(g, me, opp, opp.active, "Flame Vapor: discard an Energy")
		"Streaming Mantle":
			for pl in [me, opp]:
				for i in mini(3, pl.deck.size()):
					pl.discard.append(pl.deck.pop_back())
				for i in 3:
					var e := _take(pl.discard, func(c): return CardDB.is_basic_energy(c))
					if e != "":
						pl.deck.append(e)
				g.shuffle(pl.deck)
			g.log_msg("  Both players discard the top 3 cards and shuffle 3 basic Energy into their decks.")
		"Blissful Support":
			Trainers.chain(g, me.index, "Blissful Support: Pokémon to heal (discards its Energy)", 99,
					func(picked):
						var out: Array = []
						for x in me.all_in_play():
							if x.damage > 0 and x not in picked:
								out.append(x)
						return out, true,
					func(x):
						me.discard.append_array(x.energy)
						x.energy.clear()
						x.damage = 0
						g.log_msg("  %s is healed." % x.display_name()),
					func(): pass)
		"Devo Flash":
			var opts: Array = []
			for b in opp.bench.size():
				if opp.bench[b].is_evolved():
					opts.append({"label": opp.bench[b].display_name(), "b": b, "opp": true, "ai": float(CardDB.stage(opp.bench[b].top()))})
			if not opts.is_empty():
				g.ask(me.index, "Devo Flash: Pokémon to devolve", opts, func(o):
					if o["b"] < opp.bench.size() and opp.bench[o["b"]].is_evolved():
						var x: PokemonInPlay = opp.bench[o["b"]]
						opp.hand.append(x.cards.pop_back())
						x.clear_conditions())
		"Bursting Up":
			var n_f := opp.bench.size()
			var fires: Array = me.slots().filter(func(sl): return me.slot(sl).is_type("Fire"))
			if n_f > 0 and not fires.is_empty():
				var opts: Array = []
				for sl in fires:
					opts.append({"label": me.slot(sl).display_name(), "s": sl, "ai": 1.0 if sl == -1 else 0.5})
				g.ask(me.index, "Bursting Up: Fire Pokémon to attach up to %d Fire Energy" % n_f, opts, func(o):
					var t := me.slot(o["s"])
					for i in n_f:
						var e := _take(me.deck, func(c): return CardDB.card_name(c) == "Fire Energy")
						if e == "" or t == null:
							break
						t.energy.append(e)
					g.shuffle(me.deck))
		"Darker Ring":
			if opp.active != null and not opp.bench.is_empty():
				var opts: Array = []
				for b in opp.bench.size():
					opts.append({"label": opp.bench[b].display_name(), "b": b, "opp": true, "ai": float(-opp.bench[b].hp_left())})
				g.ask(me.index, "Darker Ring: new Defending Pokémon", opts, func(o):
					if o["b"] < opp.bench.size():
						g.switch_active(opp, o["b"]))
		"Prowl":
			Trainers._ask_from_deck(g, me, "Prowl: any card", func(_c): return true)
		"Evolutionary Flame":
			if opp.active != null:
				g.try_condition(opp.active, "burned")
				g.try_condition(opp.active, "confused")
		"Evolutionary Thunder":
			for x in opp.all_in_play():
				x.damage += 10
		"Evolutionary Swirl":
			Trainers._hand_to_deck(g, opp)
			Trainers._ask_draw_up_to(g, opp, 4, func(): pass)
		"Evolutionary Fan":
			var opts: Array = []
			for x in me.all_in_play():
				if x.is_evolved() and x != p and not x.display_name().begins_with("Shiftry"):
					opts.append({"label": x.display_name(), "mon": x, "ai": float(x.damage)})
			if not opts.is_empty():
				opts.append({"label": "Don't return any", "mon": null, "ai": 0.0})
				g.ask(me.index, "Evolutionary Fan: Pokémon to return to your hand", opts, func(o):
					if o["mon"] != null and me.all_in_play().has(o["mon"]) and (me.all_in_play().size() > 1):
						g.return_to_hand(me, o["mon"]))
		"Emerge Charge":
			attach_from_pile(g, me, me.discard, 2, func(c): return CardDB.is_energy(c), func(x): return x == p, "Emerge Charge", false)
		"Attract Energy":
			Trainers.chain(g, me.index, "Attract Energy: basic Energy to move", 99,
					func(_picked):
						var out: Array = []
						for x in me.all_in_play():
							if x != p:
								for e in x.energy:
									if CardDB.is_basic_energy(e) and e not in out:
										out.append(e)
						return out, true,
					func(id):
						if not me.all_in_play().has(p):
							return
						for x in me.all_in_play():
							if x != p and id in x.energy:
								x.energy.erase(id)
								p.energy.append(id)
								g.log_msg("  Moves %s from %s." % [CardDB.card_name(id), x.display_name()])
								return,
					func(): pass)


## Une hasta n Energías básicas del descarte al Pokémon, elegidas de a una.
static func _attach_from_discard(g: Game, me: PlayerState, p: PokemonInPlay, n: int, what: String) -> void:
	Trainers.chain(g, me.index, what + ": basic Energy to attach", n,
			func(_picked): return _distinct(me.discard, func(c): return CardDB.is_basic_energy(c)), false,
			func(id):
				if id in me.discard and me.all_in_play().has(p):
					me.discard.erase(id)
					p.energy.append(id),
			func(): pass)


static func on_basic_played(g: Game, p: PokemonInPlay) -> void:
	if g.stadium_name() == "Team Magma Hideout" and not p.name_has("Team Magma") and not p.is_fossil():
		p.damage += 10


## Moneda(s) para despertarse: Relicanth obliga a sacar dos caras.
static func wake_up(g: Game, p: PokemonInPlay) -> bool:
	if g.players.any(func(pl): return active_body(g, pl, "Deep Sleep") and fired_pl(g, pl, "Deep Sleep")):
		return g.flip("sleep") and g.flip("sleep")
	return g.flip("sleep")


## Efectos "entre turnos" de Poké-Bodies, Herramientas y Estadios.
static func between_turns(g: Game) -> void:
	for pl in g.players:
		var opp := g.other(pl)
		for a in pl.actives():
			if body(g, a, "Extra Noise"):
				var hit := false
				for x in opp.all_in_play():
					if x.is_ex():
						x.damage += 10
						hit = true
				if hit and fired(g, a, "Extra Noise"):
					g.log_msg("  Extra Noise: 1 damage counter on each of the opponent's Pokémon-ex.")
		for p in pl.all_in_play():
			if body(g, p, "Bedhead") and p.rotation == "asleep" and opp.active != null and fired(g, p, "Bedhead"):
				opp.active.damage += 20
				g.log_msg("  Bedhead: 2 damage counters on %s." % opp.active.display_name())
			if synergy(g, p, "Drake's Stadium") and p.damage > 0 and fired(g, p, "Synergy Effect"):
				p.damage -= 10
			if body(g, p, "Rain Dish") or body(g, p, "Healing Stone"):
				if p.damage > 0:
					fired(g, p, "Rain Dish" if body(g, p, "Rain Dish") else "Healing Stone")
				p.damage = max(0, p.damage - 10)
			match CardDB.card_name(p.tool):
				"Healing Berry":
					if p.hp_left() <= 20 and p.damage > 0:
						p.damage = max(0, p.damage - 30)
						g.log_msg("  Healing Berry: %s recovers 3 damage counters." % p.display_name())
						_discard_tool(pl, p, g)
				"Star Piece":
					if not pl.is_active(p) and p.damage >= 20:
						var nm := p.display_name()
						var evos := Trainers._distinct(pl.deck, func(c): return CardDB.evolves_onto(c, nm))
						if not evos.is_empty():
							var piece := p.tool
							p.tool = ""
							pl.discard.append(piece)
							g.log_msg("  Star Piece: %s evolves." % nm)
							var best: String = evos[0]
							for c in evos:
								if CardDB.hp(c) > CardDB.hp(best):
									best = c
							pl.deck.erase(best)
							g.evolve(pl, p, best)
							g.shuffle(pl.deck)
				"Lum Berry":
					if p.has_special_condition():
						p.clear_conditions()
						_discard_tool(pl, p, g)
				"Oran Berry":
					if p.damage >= 20:
						p.damage -= 20
						_discard_tool(pl, p, g)
				"Sitrus Berry":
					if p.damage >= 30:
						p.damage -= 30
						_discard_tool(pl, p, g)
				"Team Aqua Belt", "Team Magma Belt":
					if pl.is_active(p):
						var nm := p.display_name()
						var evos := Trainers._distinct(pl.deck, func(c): return CardDB.evolves_onto(c, nm))
						if not evos.is_empty():
							var belt := p.tool
							p.tool = ""            # se descarta igual; así no se vuelve a activar mientras elegís
							pl.discard.append(belt)
							g.log_msg("  %s: searches for an Evolution card." % CardDB.card_name(belt))
							g.ask(pl.index, "%s: choose the Evolution card" % CardDB.card_name(belt), Trainers._card_options(evos, false), func(o):
								if pl.deck.has(o["id"]) and pl.all_in_play().has(p):
									pl.deck.erase(o["id"])
									g.evolve(pl, p, o["id"])
								g.shuffle(pl.deck))
			if g.stadium_name() == "Desert Ruins" and p.is_ex() and p.max_hp() >= 100:
				p.damage += 10
			if body(g, p, "Dark Healer") and Energy.count_type(p, "Darkness") > 0 and p.damage > 0 and fired(g, p, "Dark Healer"):
				p.damage -= 10
			if pl.is_active(p) and p.rotation == "asleep" and body(g, p, "Rest Up") and p.damage > 0 and fired(g, p, "Rest Up"):
				p.damage = max(0, p.damage - 20)
	# Unseen Forces ... Holon Phantoms
	var once_aroma := [false, false]
	for pl in g.players:
		var opp2 := g.other(pl)
		if active_body(g, pl, "Healing Aroma") and fired_pl(g, pl, "Healing Aroma"):
			for q in g.players:
				for x in q.all_in_play():
					if not x.is_ex():
						x.damage = max(0, x.damage - 10)
		if active_body(g, pl, "Burning Aura") and fired_pl(g, pl, "Burning Aura"):
			for q in g.players:
				for x in q.actives():
					x.damage += 10
		if active_body(g, pl, "Delta Storm") and fired_pl(g, pl, "Delta Storm"):
			for x in opp2.all_in_play():
				if x.is_ex():
					x.damage += 10
		if active_body(g, pl, "Body Odor") and fired_pl(g, pl, "Body Odor"):
			for x in opp2.all_in_play():
				if x.abilities().any(func(ab): return ab["kind"] == "Poké-Body"):
					x.damage += 10
		if active_body(g, pl, "Icy Aura") and fired_pl(g, pl, "Icy Aura"):
			for q in g.players:
				for x in q.actives():
					if not x.is_type("Water"):
						x.damage += 10
		if not once_aroma[pl.index] and pl.all_in_play().any(func(x): return body(g, x, "Reactive Aroma") and x.energy.any(func(e): return CardDB.card_name(e) == "React Energy")):
			once_aroma[pl.index] = true
			for x in pl.all_in_play():
				if not x.is_ex() and x.energy.any(func(e): return CardDB.card_name(e) == "React Energy"):
					x.damage = max(0, x.damage - 10)
		if g.stadium_name() == "Cursed Stone":
			for x in pl.all_in_play():
				if x.abilities().any(func(ab): return ab["kind"] == "Poké-Power"):
					x.damage += 10
	# Poké-Bodies del Activo que actúan entre turnos
	for pl in g.players:
		var opp := g.other(pl)
		if active_body(g, pl, "Sooth Dust") and fired_pl(g, pl, "Sooth Dust"):
			for x in pl.all_in_play():
				x.damage = max(0, x.damage - 10)
		if active_body(g, pl, "Acid Sampler") and fired_pl(g, pl, "Acid Sampler"):
			for x in opp.actives():
				x.damage += 10
		if active_body(g, pl, "Sand Damage") and fired_pl(g, pl, "Sand Damage"):
			for x in opp.bench:
				if x.is_basic() and not x.is_fossil():
					x.damage += 10
		if active_body(g, pl, "Eerie Aura") and fired_pl(g, pl, "Eerie Aura"):
			for q in g.players:
				for x in q.actives():
					if x.rotation == "asleep":
						x.damage += 20
		if active_body(g, pl, "Methane Leak") and fired_pl(g, pl, "Methane Leak"):
			for q in g.players:
				for x in q.actives():
					if x.poison > 0:
						x.damage += 10


static func _discard_tool(pl: PlayerState, p: PokemonInPlay, g: Game) -> void:
	g.log_msg("  %s is discarded from %s." % [CardDB.card_name(p.tool), p.display_name()])
	pl.discard.append(p.tool)
	p.tool = ""


## Lanturn (Energy Grounding): cuando un Pokémon propio queda KO por un ataque rival.
static func on_knocked_out(g: Game, owner: PlayerState, discarded: Array[String]) -> void:
	if g.current == owner.index:
		return
	# EXP.ALL: 1 Energía básica del Pokémon KO pasa al que tiene EXP.ALL (y se descarta EXP.ALL)
	for x in owner.all_in_play():
		if CardDB.card_name(x.tool) == "EXP.ALL" and x.hp_left() > 0:
			for c in discarded:
				if CardDB.is_basic_energy(c) and c in owner.discard:
					owner.discard.erase(c)
					x.energy.append(c)
					g.log_msg("  EXP.ALL: %s gets %s." % [x.display_name(), CardDB.card_name(c)])
					_discard_tool(owner, x, g)
					break
			break
	for p in owner.all_in_play():
		if p.has_ability("Energy Grounding") and not power_blocked(g, owner, p) and p.power_used_turn != g.turn_number:
			for c in discarded:
				if CardDB.is_basic_energy(c) and c in owner.discard:
					owner.discard.erase(c)
					p.energy.append(c)
					p.power_used_turn = g.turn_number
					g.log_msg("  Energy Grounding: %s gets back %s." % [p.display_name(), CardDB.card_name(c)])
					return


## Recalcula efectos estáticos (tipos, PS extra, herramientas prohibidas).
static func refresh(g: Game) -> void:
	# Holon Veil (Ampharos δ): los Pokémon de su dueño cuentan como δ
	var veil := {}
	for pl in g.players:
		if body_in_play(g, pl, "Holon Veil"):
			for pile in [pl.deck, pl.hand, pl.discard]:
				for c in pile:
					if CardDB.is_pokemon(c):
						veil[c] = true
			for x in pl.all_in_play():
				for c in x.cards:
					veil[c] = true
	CardDB.veil_delta = veil
	for pl in g.players:
		var opp := g.other(pl)
		var lock := body_in_play(g, opp, "Primal Lock")
		for p in pl.all_in_play():
			p.hp_bonus = 0
			if g.stadium_name() == "Low Pressure System" and (p.is_type("Grass") or p.is_type("Lightning")):
				p.hp_bonus = 10
			if g.stadium_name() == "Rocket's Hideout" and (p.name_has("Dark") or p.name_has("Rocket's")):
				p.hp_bonus += 20
			if stages(g, p, "Hitmonchan"):
				p.hp_bonus += 30
			if CardDB.card_name(p.tool) == "Energy Root":
				p.hp_bonus += 20
			var tn := CardDB.card_name(p.tool)
			if tn in ["Curse Powder", "Protective Orb", "Solid Rage"] and (p.is_basic() or p.is_ex()) \
					or tn in ["Energy Root", "Fluffy Berry", "Sitrus Berry"] and (p.is_ex() or p.name_has("Dark") or p.has_owner()):
				_discard_tool(pl, p, g)
			p.flags["react_boost"] = p.display_name() in ["Huntail", "Gorebyss"] and pl.all_in_play().any(func(x): return body(g, x, "Reactive Booster"))
			p.flags["delta_rainbow"] = CardDB.is_delta(p.top())
			p.flags["crystal_beach"] = g.stadium_name() == "Crystal Beach"
			if g.stadium_name() == "Sidney's Stadium" and p.is_type("Darkness") and p.rotation != "":
				p.rotation = ""
			if CardDB.card_name(p.tool) == "Mysterious Shard" and p.tool_turn < g.turn_number - 1 and g.current == pl.index:
				_discard_tool(pl, p, g)
			if CardDB.card_name(p.tool) in ["Cessation Crystal", "Mysterious Shard"] and p.is_ex():
				_discard_tool(pl, p, g)
			if p.display_name() == "Lunatone" and body_in_play(g, pl, "Sunbeam"):
				p.hp_bonus = maxi(p.hp_bonus, 80 - CardDB.hp(p.top()))
			if p.energy.any(func(e): return CardDB.card_name(e) == "Scramble Energy"):
				p.flags["scramble_on"] = pl.prizes.size() > opp.prizes.size()
			if body_anywhere(g, "Mystic Scale") and p.tm != "":
				g.log_msg("  Mystic Scale: %s is discarded." % CardDB.card_name(p.tm))
				pl.discard.append(p.tm)
				p.tm = ""
			if p.flags.get("type_until", -1) < g.turn_number and p.flags.has("type_until"):
				p.flags.erase("type_until")
				p.type_override = []
			if body(g, p, "Energy Variation"):
				var ts := {}
				for e in p.energy:
					if CardDB.is_basic_energy(e):
						ts[CardDB.basic_energy_type(e)] = true
				p.type_override = ts.keys() if not ts.is_empty() else []
			if body(g, p, "Reactive Colors") and p.energy.any(func(e): return CardDB.card_name(e) == "React Energy"):
				p.type_override = ["Grass", "Fire", "Water", "Lightning", "Psychic", "Fighting"]
			if body(g, p, "Dual Armor"):
				var need := "Metal" if p.display_name().contains("Scizor") else "Grass"
				var both: Array = ["Darkness", "Metal"] if need == "Metal" else ["Grass", "Darkness"]
				p.type_override = both if Energy.count_type(p, need) > 0 else []
			if lock and p.tool != "":
				_discard_tool(pl, p, g)
			var modes: Array = []
			if body(g, p, "Dark Aura"):
				modes.append("all:Darkness")
			if body(g, p, "Energy Flame") or stages(g, p, "Magmar"):
				modes.append("all:Fire")
			if g.stadium_name() == "Holon Research Tower" and CardDB.is_delta(p.top()):
				modes.append("basic+:Metal")
			if p.is_type("Grass") and body_in_play(g, pl, "Chlorophyll"):
				modes.append("Colorless>Grass")
			if body(g, p, "Rare Metal"):
				modes.append("basic:Metal")
			if body(g, p, "Prismatic Body"):
				modes.append("basic:*")
			if pl.flags.get("burning", -1) >= g.turn_number:
				modes.append("basic:Fire")
			if p.flags.get("ion", -1) >= g.turn_number and pl.is_active(p):
				modes.append("Lightning>Water")
			if modes.is_empty():
				p.flags.erase("energy_as")
			else:
				p.flags["energy_as"] = modes
			p.flags.erase("extra_attacks")
			var stad_extra := _stadium_attacks(g, pl, p)
			if not stad_extra.is_empty():
				p.flags["extra_attacks"] = stad_extra
			if p.has_ability("Psymimic") and pl.is_active(p) and g.current == pl.index \
					and p.power_used_turn != g.turn_number and not power_blocked(g, pl, p):
				var extra: Array = []
				for x in opp.all_in_play():
					var src := x.top()
					var atks: Array = CardDB.get_card(src).get("attacks", [])
					for atk in atks:
						var v: String = AttackEffects.parse(src, atk)["variable"].get("k", "")
						if v in ["copy_def", "genetic_memory"]:
							continue
						var copy: Dictionary = atk.duplicate()
						copy["src"] = src
						copy["psymimic"] = true
						extra.append(copy)
				if not extra.is_empty():
					p.flags["extra_attacks"] = extra


## Ataques que da el Estadio: Meteor Falls (los de la carta Básica o Fase 1 de un Activo
## evolucionado que no sea ex) y Rocket's Tricky Gym (su ataque, para los "Dark"/"Rocket's").
static func _stadium_attacks(g: Game, pl: PlayerState, p: PokemonInPlay) -> Array:
	var out: Array = []
	if not pl.is_active(p):
		return out
	# Versatile (Mew ex): los ataques de todos los Pokémon en juego; Fellowship (Bellossom δ): los de su familia
	var shares := body(g, p, "Versatile")
	var family := body(g, p, "Fellowship")
	if shares or family:
		var seen := {}
		for q in g.players:
			if family and q != pl:
				continue
			for x in q.all_in_play():
				if x == p or seen.has(x.top()):
					continue
				if family and x.display_name() not in ["Oddish", "Gloom", "Vileplume", "Vileplume ex", "Bellossom"] and not x.display_name().begins_with("Bellossom"):
					continue
				seen[x.top()] = true
				for atk in CardDB.get_card(x.top()).get("attacks", []):
					var copy: Dictionary = atk.duplicate()
					copy["src"] = x.top()
					out.append(copy)
	match g.stadium_name():
		"Meteor Falls":
			if p.is_evolved() and not p.is_ex():
				for i in p.cards.size() - 1:
					var c := p.cards[i]
					if CardDB.is_pokemon(c):
						for atk in CardDB.get_card(c).get("attacks", []):
							var copy: Dictionary = atk.duplicate()
							copy["src"] = c
							out.append(copy)
		"Holon Lake":
			if CardDB.is_delta(p.top()):
				for atk in CardDB.get_card(g.stadium).get("attacks", []):
					var copy: Dictionary = atk.duplicate()
					copy["src"] = g.stadium
					out.append(copy)
		"Rocket's Tricky Gym":
			if p.name_has("Dark") or p.name_has("Rocket's"):
				for atk in CardDB.get_card(g.stadium).get("attacks", []):
					var copy: Dictionary = atk.duplicate()
					copy["src"] = g.stadium
					out.append(copy)
	return out


## Un Pokémon de la mano entra a la Banca: Legendary Ascent (Articuno/Moltres/Zapdos ex) y
## Dragon Boost (Rayquaza ex).
static func on_bench_from_hand(g: Game, me: PlayerState, p: PokemonInPlay) -> void:
	for ab in p.abilities():
		var n: String = ab["name"]
		if ab["kind"] != "Poké-Power" or power_blocked(g, me, p):
			continue
		if n in BENCH_TRIGGER:
			var opts2 := [{"label": "Use " + n, "use": true, "ai": 1.0}, {"label": "Don't use it", "use": false, "ai": 0.0}]
			g.ask(me.index, "%s: use %s?" % [p.display_name(), n], opts2, func(o):
				if not o["use"]:
					return
				g.log_msg("%s uses %s." % [p.display_name(), n])
				Abilities._bench_power(g, me, p, n)
				Abilities.dark_eyes(g, me, p))
			continue
		if n not in ["Legendary Ascent", "Dragon Boost"]:
			continue
		var etype := ""
		var m := RegEx.create_from_string("basic (\\w+) Energy").search(str(ab["text"]))
		if n == "Legendary Ascent" and m != null:
			etype = m.get_string(1)
		var opts := [{"label": "Use " + n, "use": true, "ai": 1.0}, {"label": "Don't use it", "use": false, "ai": 0.0}]
		g.ask(me.index, "%s: use %s?" % [p.display_name(), n], opts, func(o):
			if not o["use"] or not me.bench.has(p):
				return
			g.log_msg("%s uses %s." % [p.display_name(), n])
			if n == "Legendary Ascent":
				if me.active == null:
					return
				g.switch_active(me, me.bench.find(p))
			Abilities._gather_energy(g, me, p, func(e): return CardDB.is_basic_energy(e) and (etype == "" or CardDB.basic_energy_type(e) == etype), n))
		return


## Mover Energías de tus otros Pokémon a p, de a una (con "Listo").
static func _gather_energy(g: Game, me: PlayerState, p: PokemonInPlay, pred: Callable, what: String) -> void:
	Trainers.chain(g, me.index, what + ": Energy to move", 99,
			func(_picked):
				var out: Array = []
				for x in me.all_in_play():
					if x != p:
						for e in x.energy:
							if pred.call(e) and e not in out:
								out.append(e)
				return out, true,
			func(id):
				if not me.all_in_play().has(p):
					return
				for x in me.all_in_play():
					if x != p and id in x.energy:
						x.energy.erase(id)
						p.energy.append(id)
						g.log_msg("  Moves %s from %s." % [CardDB.card_name(id), x.display_name()])
						return,
			func(): pass)


## Une hasta n cartas de una pila (mazo o descarte) a tus Pokémon, de a una: primero la
## carta, después a quién (target_ok filtra los Pokémon que la pueden recibir).
static func attach_from_pile(g: Game, me: PlayerState, pile: Array[String], n: int, pred: Callable,
		target_ok: Callable, what: String, shuffle_after: bool) -> void:
	var targets: Array = me.slots().filter(func(sl): return target_ok.call(me.slot(sl)))
	var cands := _distinct(pile, pred)
	if n <= 0 or cands.is_empty() or targets.is_empty():
		if shuffle_after:
			g.shuffle(me.deck)
		return
	var opts: Array = []
	for c in cands:
		for sl in targets:
			opts.append({"label": "%s → %s" % [CardDB.card_name(c).replace(" Energy", ""), me.slot(sl).display_name()],
					"id": c, "s": sl, "ai": 1.0 if sl == -1 else 0.6})
	opts.append({"label": "Done", "id": "", "s": 0, "ai": 0.0})
	g.ask(me.index, "%s (%d left)" % [what, n], opts, func(o):
		if o["id"] == "":
			if shuffle_after:
				g.shuffle(me.deck)
			return
		var t := me.slot(o["s"])
		if t != null and pile.has(o["id"]):
			pile.erase(o["id"])
			t.energy.append(o["id"])
			g.log_msg("  Attaches %s to %s." % [CardDB.card_name(o["id"]), t.display_name()])
		Abilities.attach_from_pile(g, me, pile, n - 1, pred, target_ok, what, shuffle_after))


## Golden Wing, Shadow Curse y Reactive Recharge: Poké-Powers que se usan cuando el ataque
## del rival lo va a dejar Fuera de Combate (el jugador elige si usarlos).
static func _ko_powers(g: Game, owner: PlayerState, attacker: PokemonInPlay, target: PokemonInPlay) -> void:
	if owner == null or power_blocked(g, owner, target):
		return
	var opp := g.other(owner)
	if target.has_ability("Time Travel"):
		# Siempre conviene usarlo: con cara no queda KO (lo resuelve Game._check_knockouts)
		g.log_msg("%s uses Time Travel." % target.display_name())
		if g.flip():
			target.flags["time_travel"] = g.turn_number
		dark_eyes(g, owner, target)
	for nm in ["Golden Wing", "Shadow Curse", "Reactive Recharge"]:
		if not target.has_ability(nm):
			continue
		var energies: Array = target.energy.duplicate() if nm == "Golden Wing" else target.energy.filter(func(e): return CardDB.card_name(e) == "React Energy")
		if nm != "Shadow Curse" and (energies.is_empty() or owner.all_in_play().size() < 2):
			continue
		var opts := [{"label": "Use " + nm, "use": true, "ai": 1.0}, {"label": "Don't use it", "use": false, "ai": 0.0}]
		g.ask(owner.index, "%s: use %s?" % [target.display_name(), nm], opts, func(o):
			if not o["use"]:
				return
			g.log_msg("%s uses %s." % [target.display_name(), nm])
			if nm == "Shadow Curse":
				var opts2: Array = []
				for sl in opp.slots():
					opts2.append({"label": opp.slot(sl).display_name(), "s": sl, "opp": true, "ai": 100.0 if opp.slot(sl).hp_left() <= 30 else 1.0})
				g.ask(owner.index, "Shadow Curse: 3 damage counters on...", opts2, func(o2):
					var t := opp.slot(o2["s"])
					if t != null:
						t.damage += 30)
				return
			var limit := 2 if nm == "Golden Wing" else 99
			Abilities._rescue_energy(g, owner, target, energies, limit))


## Mueve Energías de un Pokémon que va a quedar KO a tus otros Pokémon, de a una.
static func _rescue_energy(g: Game, me: PlayerState, from: PokemonInPlay, left_cards: Array, limit: int) -> void:
	if limit <= 0 or left_cards.is_empty():
		return
	var opts: Array = []
	for e in _distinct(left_cards, func(_c): return true):
		for x in me.all_in_play():
			if x != from:
				opts.append({"label": "%s → %s" % [CardDB.card_name(e).replace(" Energy", ""), x.display_name()], "id": e, "mon": x, "ai": 1.0})
	if opts.is_empty():
		return
	opts.append({"label": "Done", "id": "", "mon": null, "ai": 0.0})
	g.ask(me.index, "Move Energy before the Knock Out", opts, func(o):
		if o["id"] == "":
			return
		# Si el KO ya se procesó, las Energías están en la pila de descarte (el objeto viejo conserva copias).
		var src_pile: Array = from.energy if me.all_in_play().has(from) and from.energy.has(o["id"]) else me.discard
		if src_pile.has(o["id"]) and me.all_in_play().has(o["mon"]):
			src_pile.erase(o["id"])
			o["mon"].energy.append(o["id"])
		var rest: Array = left_cards.duplicate()
		rest.erase(o["id"])
		Abilities._rescue_energy(g, me, from, rest, limit - 1))


## Delta Switch (Mewtwo δ): mover Energías básicas entre tus otros Pokémon, de a una.
static func _shuffle_energy(g: Game, me: PlayerState, except: PokemonInPlay) -> void:
	var opts: Array = []
	for a in me.all_in_play():
		for e in _distinct(a.energy, func(c): return CardDB.is_basic_energy(c)):
			for b in me.all_in_play():
				if b != a and b != except:
					opts.append({"label": "%s: %s → %s" % [CardDB.card_name(e).replace(" Energy", ""), a.display_name(), b.display_name()],
							"id": e, "a": a, "b": b, "ai": 0.0})
	if opts.is_empty():
		return
	opts.push_front({"label": "Done", "id": "", "ai": 1.0})
	g.ask(me.index, "Delta Switch: move a basic Energy", opts, func(o):
		if o["id"] == "":
			return
		if o["a"].energy.has(o["id"]):
			o["a"].energy.erase(o["id"])
			o["b"].energy.append(o["id"])
		Abilities._shuffle_energy(g, me, except))


## Costo de un ataque después de efectos (Delta Aura de Latias δ / Latios δ).
static func attack_cost(g: Game, p: PokemonInPlay, atk: Dictionary) -> Array:
	var cost: Array = atk.get("cost", []).duplicate()
	if body(g, p, "Delta Aura"):
		var partner := "Latios" if p.display_name().begins_with("Latias") else "Latias"
		var own := g.owner_of(p)
		var txt := _ability_text(p, "Delta Aura")
		if own != null and txt.contains(str(atk.get("name", ""))) and own.all_in_play().any(func(x): return x.display_name().begins_with(partner)):
			cost = ["Lightning", "Metal", "Colorless"]
	var nm := str(atk.get("name", ""))
	var own2 := g.owner_of(p)
	if own2 != null:
		var opp2 := g.other(own2)
		if body(g, p, "Star Light") and _ability_text(p, "Star Light").contains(nm) \
				and opp2.all_in_play().any(func(x): return x.is_ex() or (x.is_evolved() and CardDB.stage(x.top()) == 2)):
			cost.erase("Colorless")
		if body(g, p, "Rage Aura") and _ability_text(p, "Rage Aura").contains(nm) and own2.prizes.size() > opp2.prizes.size():
			cost = cost.filter(func(c): return c != "Colorless")
	if p.is_ex() and body_anywhere(g, "Extra Liquid"):
		cost.append("Colorless")
	return cost


static func _bench_power(g: Game, me: PlayerState, p: PokemonInPlay, n: String) -> void:
	var opp := g.other(me)
	match n:
		"Crush Chance":
			if g.stadium != "":
				g.discard_stadium()
		"Tropical Heal":
			for x in me.all_in_play():
				x.rotation = ""
				x.poison = 0
				x.burned = false
				x.flags.erase("imprison")
				x.flags.erase("shock_wave")
		"Cursed Eyes":
			var all: Array = opp.slots().filter(func(sl): return opp.slot(sl).damage > 0)
			var opts: Array = []
			for a in all:
				for b in opp.slots():
					if b != a:
						opts.append({"label": "%s → %s" % [opp.slot(a).display_name(), opp.slot(b).display_name()], "a": a, "b": b, "opp": true,
								"ai": 50.0 if opp.slot(b).hp_left() <= 30 else 1.0})
			if not opts.is_empty():
				g.ask(me.index, "Cursed Eyes: move 3 damage counters", opts, func(o):
					var fa := opp.slot(o["a"])
					var tb := opp.slot(o["b"])
					if fa != null and tb != null:
						var k := mini(30, fa.damage)
						fa.damage -= k
						tb.damage += k)
		"Crimson Ray", "Yellow Ray", "Blue Ray", "Purple Ray":
			for pl in [me, opp]:
				for a in pl.actives():
					match n:
						"Crimson Ray":
							g.try_condition(a, "burned")
						"Purple Ray":
							g.try_condition(a, "confused")
						"Yellow Ray":
							a.damage += 10
						"Blue Ray":
							a.rotation = ""
							a.poison = 0
							a.burned = false
							a.damage = maxi(0, a.damage - 30)
		"Dark Ray":
			if not opp.hand.is_empty():
				var c: String = opp.hand[g.rng.randi_range(0, opp.hand.size() - 1)]
				opp.hand.erase(c)
				opp.discard.append(c)
				g.log_msg("  Discards %s from the opponent's hand." % CardDB.card_name(c))
		"Support Navigation":
			Trainers._ask_from_deck(g, me, "Support Navigation: Supporter", func(c): return CardDB.is_supporter(c))
		"Time Reversal":
			if not me.discard.is_empty():
				g.ask(me.index, "Time Reversal: card for the top of your deck", Trainers._card_options(Trainers._distinct(me.discard, func(_c): return true), false), func(o2):
					if me.discard.has(o2["id"]):
						me.discard.erase(o2["id"])
						me.deck.append(o2["id"]))
		"Delta Switch":
			_shuffle_energy(g, me, p)
