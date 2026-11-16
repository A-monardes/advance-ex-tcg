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
	return [["Colorless"]]


static func units(p: PokemonInPlay) -> Array:
	var out: Array = []
	var modes: Array = p.flags.get("energy_as", [])
	for e in p.energy:
		var us := units_of_card(e, p)
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
	return true


static func count_named(p: PokemonInPlay, energy_name: String) -> int:
	return p.energy.filter(func(e): return CardDB.card_name(e) == energy_name).size()


## ¿La carta provee el tipo t? ("" = cualquiera)
static func card_provides(card_id: String, t: String) -> bool:
	if t == "":
		return true
	var u: Array = units_of_card(card_id)[0]
	return t in u or ANY in u
