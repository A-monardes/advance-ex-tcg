class_name Energy
extends RefCounted
## Cálculo de energía: qué provee cada carta y si alcanza para pagar un costo.

const ANY := "*"
const BASIC_TYPES := ["Grass", "Fire", "Water", "Lightning", "Psychic", "Fighting"]


## Devuelve una lista de "unidades" de energía; cada unidad es un Array de tipos
## que puede cubrir (ANY = cualquiera). `holder` hace falta para Multi Energy.
static func units_of_card(card_id: String, holder: PokemonInPlay = null) -> Array:
	if CardDB.is_basic_energy(card_id):
		return [[CardDB.basic_energy_type(card_id)]]
	if CardDB.is_holon_energy(card_id):
		# Holon's Magnemite/Voltorb: Incolora; Holon's Electrode/Magneton/Castform: 2 de cualquier tipo
		if CardDB.card_name(card_id) in ["Holon's Magnemite", "Holon's Voltorb"]:
			return [["Colorless"]]
		return [[ANY], [ANY]]
	match CardDB.card_name(card_id):
		"Rainbow Energy":
			return [[ANY]]
		"Multi Energy":
			# Si el Pokémon ya tiene otra Energía especial, provee solo Incolora.
			if holder != null and holder.energy.any(func(e): return e != card_id and not CardDB.is_basic_energy(e)):
				return [["Colorless"]]
			return [[ANY]]
		"Double Rainbow Energy":
			return [[ANY], [ANY]]
		"Darkness Energy":
			return [["Darkness"]]
		"Metal Energy":
			return [["Metal"]]
		"Aqua Energy":
			return [["Water", "Darkness"], ["Water", "Darkness"]]
		"Magma Energy":
			return [["Fighting", "Darkness"], ["Fighting", "Darkness"]]
		"Boost Energy":
			return [["Colorless"], ["Colorless"], ["Colorless"]]
		"Dark Metal Energy":
			return [["Darkness", "Metal"]]
		"R Energy":
			return [["Darkness"], ["Darkness"]]
		"δ Rainbow Energy":
			if holder != null and holder.flags.get("delta_rainbow", false):
				return [[ANY]]
			return [["Colorless"]]
		"React Energy":
			# Reactive Booster (Gorebyss): en Huntail y Gorebyss da 2 de cualquier tipo
			if holder != null and holder.flags.get("react_boost", false):
				return [[ANY], [ANY]]
			return [["Colorless"]]
		"Scramble Energy":
			# Si el dueño tiene más Premios que el rival (lo calcula Abilities.refresh): 3 de cualquier tipo.
			if holder != null and holder.flags.get("scramble_on", false):
				return [[ANY], [ANY], [ANY]]
			return [["Colorless"]]
	return [["Colorless"]]


static func units(p: PokemonInPlay) -> Array:
	var out: Array = []
	var modes: Array = p.flags.get("energy_as", [])
	for e in p.energy:
		var us := units_of_card(e, p)
		# Crystal Beach: las Energías especiales que dan 2 o más dan solo 1 Incolora
		if us.size() >= 2 and p.flags.get("crystal_beach", false) and CardDB.is_energy(e) and not CardDB.is_basic_energy(e):
			us = [["Colorless"]]
		for m in modes:
			us = _convert(e, us, str(m))
		out.append_array(us)
	return out


## Poké-Bodies y Poké-Powers que cambian el tipo de las Energías unidas (los calcula
## Abilities.refresh en flags["energy_as"]):
##   "all:T"    todas proveen T (Dark Aura)
##   "basic:T"  las básicas proveen T (Rare Metal, Burning Energy); "basic:*" = cualquiera (Prismatic Body)
##   "A>B"      las que proveen A pasan a proveer B (Ion Coating)
static func _convert(card_id: String, us: Array, mode: String) -> Array:
	var out: Array = []
	if mode.begins_with("all:"):
		for u in us:
			out.append([mode.substr(4)])
		return out
	if mode.begins_with("basic+:"):      # Holon Research Tower: las básicas dan su tipo y también Metal
		if not CardDB.is_basic_energy(card_id):
			return us
		return [[CardDB.basic_energy_type(card_id), mode.substr(7)]]
	if mode.begins_with("basic:"):
		if not CardDB.is_basic_energy(card_id):
			return us
		var t := mode.substr(6)
		return [[ANY if t == "*" else t]]
	var parts := mode.split(">")
	for u in us:
		out.append([parts[1]] if parts[0] in u else u)
	return out


static func total(p: PokemonInPlay) -> int:
	return units(p).size()


## Cuántas unidades pueden dar el tipo t.
static func count_type(p: PokemonInPlay, t: String) -> int:
	return units(p).filter(func(u): return t in u or ANY in u).size()


static func can_pay(p: PokemonInPlay, cost: Array) -> bool:
	var u := units(p)
	var colored: Array = []
	var colorless := 0
	for c in cost:
		if c == "Colorless":
			colorless += 1
		else:
			colored.append(c)
	if u.size() < colored.size() + colorless:
		return false
	u.sort_custom(func(a, b): return _score(a) < _score(b))
	var used: Array = []
	used.resize(u.size())
	used.fill(false)
	return _match(colored, 0, u, used)


## Unidades que sobran después de pagar el costo (para "energía no usada").
static func extra_units(p: PokemonInPlay, cost: Array, t: String = "") -> int:
	if t == "":
		return max(0, total(p) - cost.size())
	var typed := count_type(p, t)
	var typed_needed := cost.filter(func(c): return c == t).size()
	var others := total(p) - typed
	var colorless_from_typed: int = max(0, cost.filter(func(c): return c == "Colorless").size() - others)
	return max(0, typed - typed_needed - colorless_from_typed)


static func _score(unit: Array) -> int:
	return 100 if ANY in unit else unit.size()


static func _match(req: Array, i: int, u: Array, used: Array) -> bool:
	if i == req.size():
		return true
	for j in u.size():
		if not used[j] and (req[i] in u[j] or ANY in u[j]):
			used[j] = true
			if _match(req, i + 1, u, used):
				return true
			used[j] = false
	return false


static func can_attach(card_id: String, p: PokemonInPlay) -> bool:
	if CardDB.is_holon_energy(card_id):
		return units_of_card(card_id).size() == 1 or not p.energy.is_empty()
	if p.is_fossil():
		return true
	match CardDB.card_name(card_id):
		"Double Rainbow Energy":
			return p.is_evolved() and not p.is_ex()
		"Boost Energy":
			return p.is_evolved()
		"Aqua Energy":
			return p.name_has("Team Aqua")
		"Magma Energy":
			return p.name_has("Team Magma")
		"R Energy":
			return p.name_has("Dark") or p.name_has("Rocket's")
		"Scramble Energy":
			return p.is_evolved() and not p.is_ex()
	return true


static func count_named(p: PokemonInPlay, energy_name: String) -> int:
	return p.energy.filter(func(e): return CardDB.card_name(e) == energy_name).size()


## ¿La carta provee el tipo t? ("" = cualquiera)
static func card_provides(card_id: String, t: String) -> bool:
	if t == "":
		return true
	var u: Array = units_of_card(card_id)[0]
	return t in u or ANY in u
