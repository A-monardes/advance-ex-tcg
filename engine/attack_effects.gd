class_name AttackEffects
extends RefCounted
## Convierte el texto de un ataque en operaciones ("ops") y las ejecuta.
##
## Cómo funciona el traductor:
##  1. Normaliza el texto (el nombre del Pokémon pasa a ser NAME, se quitan aclaraciones).
##  2. Reconoce construcciones de varias oraciones ("Flip 3 coins. This attack does 20 damage
##     times the number of heads.").
##  3. Separa el resto en oraciones. Cada oración puede empezar con una condición
##     ("If heads, ", "If the Defending Pokémon is Pokémon-ex, ", "If you do, "...) y
##     luego tiene una cláusula ("the Defending Pokémon is now Paralyzed.").
##     Condición + cláusula se combinan libremente, así una misma cláusula sirve
##     para muchas cartas.
## Lo que no se reconoce queda en "unknown": el ataque se puede usar igual (hace su
## daño base) y el informe de cobertura muestra qué falta.

const STATUS := {"Asleep": "asleep", "Confused": "confused", "Paralyzed": "paralyzed",
		"Poisoned": "poisoned", "Burned": "burned"}
const ST := "(Asleep|Burned|Confused|Paralyzed|Poisoned)"
## Operaciones que se resuelven antes de hacer el daño principal.
const PRE := ["return_all_basic", "burst_choice", "any_energy", "coin", "flips", "until_tails", "nothing", "bonus", "set_base", "formula", "ignore",
		"discard_self", "heal_def", "strip_def_trainers", "base_or_extra", "gust", "mill_count", "tidal", "mill_both_bonus",
		"discard_bonus", "bonus_table", "discard_one_bonus", "lava_choice", "discard_to_counters"]

static var _multi: Array = []
static var _conds: Array = []
static var _clauses: Array = []
static var _cache: Dictionary = {}


# ===========================================================================
# Traductor
# ===========================================================================

static func parse(card_id: String, attack: Dictionary) -> Dictionary:
	var key := card_id + "|" + str(attack.get("name", ""))
	if _cache.has(key):
		return _cache[key]
	if _clauses.is_empty():
		_build()
	var t := str(attack.get("text", ""))
	t = t.replace(CardDB.card_name(card_id), "NAME").replace("this Pokémon", "NAME") \
			.replace("the Pokémon using this attack", "NAME")
	t = _re("\\([^)]*\\)").sub(t, "", true)
	t = t.replace(" .", ".").replace("Pokémon .", "Pokémon.").replace(" ,", ",")
	t = _re("\\s+").sub(t, " ", true).strip_edges()
	t = t.replace("; if tails, ", ". If tails, ").replace("; if heads, ", ". If heads, ")

	var ops: Array = []
	var unknown: Array[String] = []
	# 1) construcciones de varias oraciones
	for rule in _multi:
		var rx: RegEx = rule[0]
		var m := rx.search(t)
		while m != null:
			_append(ops, rule[1].call(m), {})
			t = (t.substr(0, m.get_start()) + t.substr(m.get_end())).strip_edges()
			m = rx.search(t)
	# 2) oración por oración
	for sentence in _split(t):
		var s := sentence
		var cond := {}
		var progress := true
		while progress:
			progress = false
			for c in _conds:
				var m: RegExMatch = c[0].search(s)
				if m != null:
					cond.merge(c[1].call(m), true)
					s = s.substr(m.get_end())
					progress = true
					break
		if s == "":
			continue
		s = s[0].to_upper() + s.substr(1)
		var matched := false
		for c in _clauses:
			var m: RegExMatch = c[0].search(s)
			if m != null:
				_append(ops, c[1].call(m), cond)
				matched = true
				break
		if not matched:
			unknown.append(sentence)
	# Monedas: cada op condicionada a cara/cruz apunta a la última moneda anterior.
	var coins := -1
	for op in ops:
		if op["k"] == "coin":
			coins += 1
		if op.get("c", "") in ["heads", "tails"]:
			op["coin_ref"] = coins
	var target := ""
	var team := ""
	var optional := false
	for op in ops:
		if op.has("needs"):
			target = op["needs"]
			team = op.get("team", "")
		if op.get("optional", false):
			optional = true
	# "You can't add more than N damage in this way" limita la fórmula anterior.
	var cleaned: Array = []
	for op in ops:
		if op["k"] == "cap":
			for j in range(cleaned.size() - 1, -1, -1):
				if cleaned[j]["k"] == "formula":
					cleaned[j]["cap"] = op["n"]
					break
		elif op["k"] == "snipe_mod":
			for j in range(cleaned.size() - 1, -1, -1):
				if cleaned[j]["k"] == "snipe":
					cleaned[j]["if"] = op["if"]
					cleaned[j]["n_if"] = op["n"]
					break
		else:
			cleaned.append(op)
	ops = cleaned
	var variable := {}
	for op in ops:
		if op["k"] in ["any_energy", "burst_choice", "genetic_memory", "copy_def"]:
			variable = op
	var result := {"ops": ops, "unknown": " ".join(unknown), "target": target, "team": team, "optional": optional, "variable": variable}
	_cache[key] = result
	return result


static func _append(ops: Array, op, cond: Dictionary) -> void:
	var list: Array = op if op is Array else [op]
	for o in list:
		if o == null:
			continue
		var d: Dictionary = o.duplicate()
		for k in cond:
			if not d.has(k):
				d[k] = cond[k]
		ops.append(d)


static func _split(t: String) -> Array[String]:
	var out: Array[String] = []
	if t == "":
		return out
	var parts := _re("(?<=\\.)\\s+").sub(t, "\n", true).split("\n")
	for p in parts:
		if p.strip_edges() != "":
			out.append(p.strip_edges())
	return out


static func is_fully_supported(card_id: String, attack: Dictionary) -> bool:
	return parse(card_id, attack)["unknown"] == ""


static func needs_target(card_id: String, attack: Dictionary) -> String:
	return parse(card_id, attack)["target"]


static func _re(p: String) -> RegEx:
	var r := RegEx.new()
	r.compile(p)
	return r


static func _n(s: String) -> int:
	if s in ["a", "an", ""]:
		return 1
	if s == "all":
		return 99
	return int(s)


static func _m(p: String, f: Callable) -> void:
	_multi.append([_re(p), f])


## Igual que _m, pero se prueba antes que todas las demás (textos que una regla más
## general partiría mal).
static func _mf(p: String, f: Callable) -> void:
	_multi.push_front([_re(p), f])


static func _c(p: String, f: Callable) -> void:
	_conds.append([_re("^" + p), f])


static func _k(p: String, f: Callable) -> void:
	_clauses.append([_re("^" + p + "$"), f])


static func _st(m: RegExMatch, i: int) -> String:
	return STATUS[m.get_string(i)]


static func _build() -> void:
	# --- 1) Construcciones de varias oraciones -------------------------------
	# Ataques de una sola carta
	_m("If 1 Energy is attached to NAME, the Defending Pokémon is now Asleep\\..*Asleep, Burned, and Poisoned\\.",
		func(_m): return {"k": "lizard_poison"})     # Sceptile
	_m("Look at your opponent's hand\\. You may use the effect of a Supporter card you find there as the effect of this attack\\.",
		func(_m): return {"k": "use_supporter", "from": "opp_hand", "may": true})     # Sableye
	_m("Search your opponent's discard pile for a Supporter card and use the effect of that card as the effect of this attack\\.",
		func(_m): return {"k": "use_supporter", "from": "opp_discard", "may": false})     # Chimecho
	_m("You may switch NAME with 1 of your Benched Pokémon\\. If you do, you may move any number of (\\w+) Energy cards attached to NAME to the new Active Pokémon\\.",
		func(m): return {"k": "quick_touch", "etype": m.get_string(1), "optional": true})     # Ninjask
	_m("Count the amount of Energy attached to all of your Pokémon and all of your opponent's Pokémon\\. If your Pokémon have less Energy than your opponent's, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(1)), "c": "less_total_energy"})     # Skarmory
	_m("Flip (\\d+) coins\\. If all of them are heads, this attack does \\d+ damage plus (\\d+) more damage\\. If not, this attack does \\d+ damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "all": int(m.get_string(2)), "n": int(m.get_string(3)), "mode": "all_or_each"})     # Grovyle
	_m("Use any attack from NAME's Basic Pokémon card or Stage 1 Evolution card\\.",
		func(_m): return {"k": "genetic_memory"})     # Kingdra ex
	_m("Before doing damage, you may choose 1 of your opponent's Benched Pokémon that has (Team \\w+) in its name and switch it with 1 of the Defending Pokémon\\.(?: Your opponent chooses the Defending Pokémon to switch\\.)?",
		func(m): return {"k": "gust", "needs": "bench_team", "team": m.get_string(1), "optional": true})     # Team Aqua's Crawdaunt
	_m("Discard the top (\\d+) cards from your deck\\. This attack does (\\d+) damage times the number of (\\w+) and (\\w+) basic Energy cards discarded in this way\\.",
		func(m): return {"k": "mill_count", "count": int(m.get_string(1)), "n": int(m.get_string(2)), "types": [m.get_string(3), m.get_string(4)]})     # Team Magma's Houndoom
	_m("Discard the top card from your opponent's deck, and flip a coin\\.",
		func(_m): return [{"k": "mill_opp", "n": 1}, {"k": "coin"}])     # Team Magma's Torkoal
	_m("Look at your opponent's hand and choose 1 Basic Pokémon or Evolution card you find there\\. Your opponent puts it at the bottom of his or her deck\\.",
		func(_m): return {"k": "push_aside"})     # Shiftry
	_m("Before doing damage, count the remaining HP of the Defending Pokémon and NAME\\. If the Defending Pokémon has fewer remaining HP than NAME's, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(1)), "c": "def_fewer_hp"})     # Swalot
	_m("You may discard from your hand as many Energy cards as you like\\. If you do, this attack does (\\d+) damage plus (\\d+) more damage for each Energy card you discarded\\.",
		func(m): return {"k": "any_energy", "mode": "hand_discard", "etype": "", "base": int(m.get_string(1)), "per": int(m.get_string(2))})     # Groudon ex
	_m("You may show your hand to your opponent\\. If you do, this attack does \\d+ damage plus (\\d+) more damage for each Energy card in your hand\\. After doing damage, shuffle the Energy cards back into your deck\\.",
		func(m): return {"k": "tidal", "per": int(m.get_string(1)), "optional": true})     # Kyogre ex
	_m("Flip (\\d+) coins\\. This attack does (\\d+) damages? times the number of heads\\.",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": int(m.get_string(2)), "mode": "times"})
	_m("Flip (\\d+) coins\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": int(m.get_string(3)), "mode": "plus"})
	_m("Flip a coin until you get tails\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "until_tails", "n": int(m.get_string(1))})
	_m("Flip a coin until you get tails\\. For each heads, search your discard pile for a basic Energy card and attach it to NAME\\.",
		func(_m): return {"k": "until_tails_attach"})
	_m("Flip a coin for each Energy attached to (?:NAME|all of your Active Pokémon)\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "flips", "count": "self_energy", "n": int(m.get_string(1)), "mode": "times"})
	_m("Flip a number of coins equal to the amount of Energy attached to NAME\\. This attack does (\\d+) damage times the number of heads\\. You can't flip more than (\\d+) coins in this way\\.",
		func(m): return {"k": "flips", "count": "self_energy", "cap": int(m.get_string(2)), "n": int(m.get_string(1)), "mode": "times"})
	_m("Flip a coin for each of your Pokémon in play\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "flips", "count": "my_pokemon", "n": int(m.get_string(1)), "mode": "times"})
	_m("Flip a coin\\. If heads, choose 1 of your opponent's Pokémon\\. This attack does (\\d+) damage to that Pokémon\\.",
		func(m): return [{"k": "coin"}, {"k": "snipe", "n": int(m.get_string(1)), "needs": "any", "c": "heads"}])
	# "Cualquier cantidad" de Energías: el jugador elige cuántas desde el menú (una opción por cantidad).
	_m("You may discard any number of basic Energy cards attached to NAME(?: when you use this attack)?\\. If you do, this attack does (\\d+) damage plus (\\d+) more damage for each basic Energy card you discarded\\.",
		func(m): return {"k": "any_energy", "mode": "discard", "etype": "", "base": int(m.get_string(1)), "per": int(m.get_string(2))})
	_m("You may return any number of basic (\\w+) Energy cards attached to all of your Pokémon to your hand\\. If you do, this attack does (\\d+) damage plus (\\d+) more damage for each Energy you returned\\.",
		func(m): return {"k": "any_energy", "mode": "return", "etype": m.get_string(1), "base": int(m.get_string(2)), "per": int(m.get_string(3))})
	_m("You may return all basic Energy cards attached to NAME to your hand\\. If you do, this attack does (\\d+) damage plus (\\d+) more damage for each basic Energy card you returned\\.",
		func(m): return {"k": "return_all_basic", "base": int(m.get_string(1)), "per": int(m.get_string(2)), "optional": true})
	_m("Discard either all (\\w+) Energy or all (\\w+) Energy attached to NAME\\. This attack does (\\d+) damage times the amount of \\w+ or \\w+ Energy discarded\\.",
		func(m): return {"k": "burst_choice", "types": [m.get_string(1), m.get_string(2)], "n": int(m.get_string(3))})
	_m("You may move an Energy card attached to that Pokémon to another of your opponent's Pokémon\\.",
		func(_m): return {"k": "flip_energy", "optional": true, "phase": "post"})
	_m("Switch 1 of your opponent's Benched Pokémon with 1 of the Defending Pokémon\\. Your opponent chooses the Defending Pokémon to switch\\.",
		func(_m): return {"k": "gust", "needs": "bench"})
	_m("Before using this effect, you may switch the Defending Pokémon with 1 of your opponent's Benched Pokémon, if any\\.",
		func(_m): return {"k": "gust", "needs": "bench", "optional": true})
	_m("Before doing damage, you may (?:choose 1 of your opponent's Benched Pokémon and switch it with 1 of the Defending Pokémon|switch 1 of your opponent's Benched Pokémon with 1 of the Defending Pokémon)\\.(?: Your opponent chooses the Defending Pokémon to switch\\.)?",
		func(_m): return {"k": "gust", "needs": "bench", "optional": true})
	_m("Count the number of Basic Pokémon or Evolution cards in your discard pile\\. Put that many damage counters on the Defending Pokémon\\. You can't put more than (\\d+) damage counters on the Defending Pokémon in this way\\.",
		func(m): return {"k": "counters", "to": "def", "per": "my_discard_pokemon", "n": 1, "cap": int(m.get_string(1))})
	_m("Put 1 damage counter, plus 1 more damage counter for each damage counter on NAME, on the Defending Pokémon\\.",
		func(_m): return {"k": "counters", "to": "def", "per": "self_counters_plus1", "n": 1})
	_m("Both NAME and the Defending Pokémon are now Knocked Out\\. If NAME has any Special Energy cards attached to it, this attack does nothing\\.",
		func(_m): return {"k": "mass_destruction"})
	_m("If the number of cards in your opponent's hand is at least (\\d+), choose a number of cards there, without looking, until your opponent has (\\d+) cards left\\. Have your opponent discard the cards you chose\\.",
		func(m): return {"k": "opp_hand_trim", "min": int(m.get_string(1)), "keep": int(m.get_string(2)), "to": "discard"})
	_m("If the number of cards in your opponent's hand is at least (\\d+), look at his or her hand\\. Choose a number of cards there until your opponent has (\\d+) cards left in his or her hand and have your opponent shuffle the cards you chose into his or her deck\\.",
		func(m): return {"k": "opp_hand_trim", "min": int(m.get_string(1)), "keep": int(m.get_string(2)), "to": "deck"})
	_m("If your opponent has any Evolved Pokémon in play, choose 1 of them and flip a coin\\. If heads, remove the highest Stage Evolution card on that Pokémon and have your opponent shuffle it into his or her deck\\.",
		func(_m): return {"k": "time_spiral"})
	_m("Search your deck for Silcoon and Beautifly, or Cascoon and Dustox cards\\. Show 1 card or both cards of a pair to your opponent and put them into your hand\\.",
		func(_m): return {"k": "wurmple"})
	_m("Search your deck for a Basic Pokémon card or Evolution card for each Energy attached to NAME, show them to your opponent, and put them into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "pokemon", "n": -1})
	_m("Search your deck for ([\\w ,]+?),? or (any Basic Pokémon|[A-Z]\\w+) and put (as many of them as you like|up to (\\d+) of them) onto your Bench\\.(?: Shuffle your deck afterward\\.)?(?: Treat the new Benched Pokémon as Basic Pokémon\\.)?",
		func(m):
			var names: Array = []
			for part in (m.get_string(1) + ", " + m.get_string(2)).split(","):
				var nm: String = part.strip_edges()
				if nm.begins_with("or "):
					nm = nm.substr(3)
				if nm != "" and nm != "any Basic Pokémon":
					names.append(nm)
			return {"k": "bench_search", "n": int(m.get_string(4)) if m.get_string(4) != "" else 5, "type": "", "team": "",
					"names": names, "any_basic": m.get_string(2) == "any Basic Pokémon"})
	_m("Search your discard pile for up to (\\d+) basic Energy cards and attach them to 1 of your Pokémon\\. Put 1 damage counter on that Pokémon for each Energy card attached in this way\\.",
		func(m): return {"k": "energy_retrieval", "n": int(m.get_string(1))})
	_m("Look at your opponent's hand\\. You may have your opponent shuffle a Supporter card you find there into his or her deck\\. If you do, your opponent draws a card\\.",
		func(_m): return {"k": "scam"})
	_m("Discard (a|an|\\d+) (\\w+ )?Energy(?: cards?)? attached to NAME and then choose 1 of your opponent's Pokémon\\. This attack does (\\d+) damage to that Pokémon\\.",
		func(m): return [{"k": "discard_self", "count": _n(m.get_string(1)), "etype": m.get_string(2).strip_edges()},
				{"k": "snipe", "n": int(m.get_string(3)), "needs": "any"}])
	_m("Choose 1 of your opponent's (Benched )?Pokémon\\. This attack does (\\d+) damage to that Pokémon\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(2)), "needs": "bench" if m.get_string(1) != "" else "any"})
	_m("Choose 1 of your opponent's Pokémon\\. This attack does (\\d+) damage for each Colorless Energy in that Pokémon's Retreat Cost to that Pokémon\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "per_retreat": true, "needs": "any"})
	_m("Choose (\\d+) of your opponent's Benched Pokémon\\. This attack does (\\d+) damage to each of those Pokémon\\.",
		func(m): return {"k": "multi_bench", "count": int(m.get_string(1)), "n": int(m.get_string(2))})
	_m("If the Defending Pokémon tries to attack during your opponent's next turn, your opponent flips a coin\\. If tails, that attack does nothing\\.",
		func(_m): return {"k": "flag_def", "flag": "smokescreen"})
	_m("Choose 1 of the Defending Pokémon's attacks\\. That Pokémon can't use that attack during your opponent's next turn\\.",
		func(_m): return {"k": "disable_attack"})
	_m("Choose 1 card from your opponent's hand without looking\\. Look at the card you chose, then have your opponent shuffle that card into his or her deck\\.",
		func(_m): return {"k": "opp_hand_random", "to": "deck"})
	_m("Count the number of cards in your opponent's hand\\. Put that many damage counters on the Defending Pokémon\\.",
		func(_m): return {"k": "counters", "to": "def", "per": "opp_hand", "n": 1})
	_m("Flip a coin\\. If heads, choose 1 Special Condition\\. The Defending Pokémon is now affected by that Special Condition\\.",
		func(_m): return [{"k": "coin"}, {"k": "choose_condition", "c": "heads"}])
	_m("Choose 1 Special Condition\\. The Defending Pokémon is now affected by that Special Condition\\.",
		func(_m): return {"k": "choose_condition"})
	_m("Flip a coin\\. If heads, choose 1 Energy attached to the Defending Pokémon\\. Your opponent returns that card to his or her hand\\.",
		func(_m): return [{"k": "coin"}, {"k": "return_def_energy", "c": "heads"}])
	_m("Flip a coin\\. If heads, look at your opponent's hand and choose 1 card\\. Your opponent discards the card you chose\\.",
		func(_m): return [{"k": "coin"}, {"k": "opp_hand_pick", "c": "heads"}])
	_m("Discard all of your opponent's Trainer cards in play\\. If you do, prevent all effects, including damage, done to NAME during your opponent's next turn\\.",
		func(_m): return {"k": "ice_generator"})
	_m("Discard the top card from your deck\\. If that card is a basic Energy card, attach it to NAME\\.",
		func(_m): return {"k": "top_energy"})
	_m("Shuffle your hand into your deck\\. Draw up to (\\d+) cards\\.",
		func(m): return {"k": "shuffle_draw", "n": int(m.get_string(1))})
	_m("Remove (\\d+) damage counters? from each of your Pokémon\\. Remove no damage counters from NAME\\.",
		func(m): return {"k": "heal_mine", "n": int(m.get_string(1)), "skip_self": true})
	_m("Flip 2 coins\\. If both of them are heads, the Defending Pokémon is Knocked Out\\.",
		func(_m): return {"k": "double_coin_ko"})
	_m("Flip (\\d+) coins\\. For each heads, choose 1 of y?o?u?r? ?opponent's Pokémon and put (\\d+) damage counters? on that Pokémon\\.",
		func(m): return {"k": "distribute", "flips": int(m.get_string(1)), "n": int(m.get_string(2))})
	_m("Remove (\\d+) damage counters from each of your Pokémon that has Grass Energy attached\\. If that Pokémon has less than \\d+ damage counters, remove all of them\\.",
		func(m): return {"k": "heal_mine", "n": int(m.get_string(1)), "grass_only": true})
	_m("(?:After your attack, )?[Rr]emove from NAME the number of damage counters equal to the damage you did to the Defending Pokémon\\. If NAME has fewer damage counters than that, remove all of them\\.",
		func(_m): return {"k": "drain"})

	# --- 2a) Condiciones al principio de una oración -------------------------
	_c("If heads, ", func(_m): return {"c": "heads"})
	_c("If tails, ", func(_m): return {"c": "tails"})
	_c("If you do, ", func(_m): return {"c": "did"})
	_c("If either of the coins is heads, ", func(_m): return {"c": "any_heads"})
	_c("Before doing damage, ", func(_m): return {"phase": "pre"})
	_c("(?:After doing damage|After your attack), ", func(_m): return {"phase": "post"})
	_c("If the Defending Pokémon is (?:a )?Pokémon-ex, ", func(_m): return {"c": "def_ex"})
	_c("If the Defending Pokémon is an Evolved Pokémon, ", func(_m): return {"c": "def_evolved"})
	_c("If any of your opponent's Active Pokémon are Evolved Pokémon, ", func(_m): return {"c": "def_evolved"})
	_c("If the Defending Pokémon (?:already )?has any damage counters on it, ", func(_m): return {"c": "def_damaged", "at": 1})
	_c("If the Defending Pokémon already has at least (\\d+) damage counters on it, ", func(m): return {"c": "def_damaged", "at": int(m.get_string(1))})
	_c("If the Defending Pokémon is affected by a Special Condition, ", func(_m): return {"c": "def_status"})
	_c("If the Defending Pokémon is " + ST + ", ", func(m): return {"c": "def_cond", "cond": _st(m, 1)})
	_c("If the Defending Pokémon has any Special Energy cards attached to it, ", func(_m): return {"c": "def_special"})
	_c("If the Defending Pokémon has (?:any|a) Poké-Powers? or Poké-Bod(?:y|ies), ", func(_m): return {"c": "def_ability"})
	_c("If the Defending Pokémon has (Team Aqua|Team Magma) in its name, ", func(m): return {"c": "def_team", "team": m.get_string(1)})
	_c("If the Defending Pokémon is ([A-Z][\\w-]+), ", func(m): return {"c": "def_name", "name": m.get_string(1)})
	_c("If you have more Prize cards left than your opponent, ", func(_m): return {"c": "more_prizes"})
	_c("If you have more cards in your hand than your opponent, ", func(_m): return {"c": "more_hand"})
	_c("If you have the same number of cards in your hand as your opponent, ", func(_m): return {"c": "same_hand"})
	_c("If ([A-Z][\\w ]+?) is in play, ", func(m): return {"c": "stadium", "name": m.get_string(1)})
	_c("If your opponent has any Evolved Pokémon in play, ", func(_m): return {"c": "opp_evolved"})
	_c("If your opponent has any Pokémon-ex in play, ", func(_m): return {"c": "opp_ex"})
	_c("If NAME has less Energy attached to it than the Defending Pokémon, ", func(_m): return {"c": "less_energy"})
	_c("If NAME and the Defending Pokémon have the same amount of Energy attached to them, ", func(_m): return {"c": "same_energy"})
	_c("If NAME and the Defending Pokémon have a different amount of Energy attached to them, ", func(_m): return {"c": "diff_energy"})
	_c("If you don't have any Benched Pokémon, ", func(_m): return {"c": "no_bench"})

	# --- 2b) Cláusulas ---------------------------------------------------------
	# Sin efecto en duelos de un solo Pokémon Activo (Seaking, Typhlosion ex)
	_k("Move 1 Energy card attached to the Defending Pokémon to the other Defending Pokémon\\.", func(_m): return null)
	_k("If your opponent has more than 1 Defending Pokémon, you may do \\d+ damage to each of them instead\\.", func(_m): return null)
	_k("If you choose Pokémon that has a Poké-Power or Poké-Body, this attack does (\\d+) damage instead\\.",
		func(m): return {"k": "snipe_mod", "if": "ability", "n": int(m.get_string(1))})     # Minun
	_k("If you choose Pokémon-ex, this attack does (\\d+) damage instead\\.",
		func(m): return {"k": "snipe_mod", "if": "ex", "n": int(m.get_string(1))})     # Plusle
	_k("Choose 1 of your opponent's Benched Pokémon and do (\\d+) damage to that Pokémon\\.",
		func(m): return {"k": "bench_pick_dmg", "n": int(m.get_string(1))})     # Charizard
	_k("This attack does (\\d+) damage plus (\\d+) more damage to the Defending Pokémon and discard all (\\w+) Energy cards attached to NAME\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "discard_self", "count": 99, "etype": m.get_string(3)}])     # Raichu
	_k("During your next turn, if an attack does damage to the Defending Pokémon, that attack does (\\d+) more damage\\.",
		func(m): return {"k": "silver_wind", "n": int(m.get_string(1))})     # Masquerain
	_k("You may do (\\d+) damage plus (\\d+) more damage\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(2)), "optional": true})     # Regirock ex
	_k("Does (\\d+) damage to each of your opponent's Benched Pokémon of the same type as the Defending Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench_same_type"})     # Registeel ex
	# Monedas y daño
	_k("Flip a coin\\.", func(_m): return {"k": "coin"})
	_k("Flip (\\d+) coins\\.", func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": 0, "mode": "none"})
	_k("This attack does nothing\\.", func(_m): return {"k": "nothing"})
	_k("This attack does (\\d+) damage plus (\\d+) more damage(?: to the Defending Pokémon)?\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(2))})
	_k("This attack(?:'s base damage is| does) (\\d+)(?: damage)? instead of (\\d+)\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(1))})
	_k("This attack does (\\d+) damage to the Defending Pokémon\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(1))})
	_k("(?:This attack does|Does) (\\d+) damage to each Defending Pokémon\\.",
		func(m): return {"k": "base_or_extra", "n": int(m.get_string(1))})
	_k("This attack does (\\d+) damage and the Defending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "set_base", "n": int(m.get_string(1))}, {"k": "status", "conds": [_st(m, 2)], "who": "def"}])
	_k("This attack does (\\d+) damage to each Defending Pokémon, and each Defending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "set_base", "n": int(m.get_string(1))}, {"k": "status", "conds": [_st(m, 2)], "who": "def"}])
	_k("This attack's damage (?:isn't|is not) affected by ([^.]+)\\.",
		func(m):
			var s: String = m.get_string(1)
			return {"k": "ignore", "w": s.contains("Weakness"), "r": s.contains("Resistance"),
					"fx": s.contains("Poké-Bodies") or s.contains("other effects")})
	# Fórmulas de daño
	_k("Does (\\d+) damage plus (\\d+) more damage for each damage counter on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each damage counter on all of your Active Pokémon\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(2)), "mode": "plus"})
	_k("(?:This attack does|Does) (\\d+) damage (?:times the number of|for each) damage counters? on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage minus (\\d+) damage for each damage counter on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(2)), "mode": "minus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each damage counter on the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_counters", "n": int(m.get_string(2)), "mode": "plus"})
	_k("This attack does (\\d+) damage times the number of damage counters on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the amount of Energy attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the amount of Energy attached to (?:NAME|all of your Active Pokémon)\\.",
		func(m): return {"k": "formula", "f": "self_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the amount of Energy attached to all of your Pokémon\\.",
		func(m): return {"k": "formula", "f": "my_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the total amount of Energy attached to all Pokémon in play\\.",
		func(m): return {"k": "formula", "f": "all_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the total amount of Energy attached to NAME and the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "both_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage times the number of basic Energy cards attached to (?:all of the Active Pokémon|NAME and the Defending Pokémon)\\.",
		func(m): return {"k": "formula", "f": "both_basic_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each (\\w+ )?Energy attached to NAME\\.",
		func(m): return {"k": "formula", "f": "self_energy", "etype": m.get_string(3).strip_edges(), "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each Energy attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage minus (\\d+) damage for each Energy attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy", "n": int(m.get_string(2)), "mode": "minus"})
	_k("(?:This attack does|Does) (\\d+) damage plus (\\d+) more damage for each (basic |\\w+ )?Energy attached to NAME but not used to pay for this attack's Energy cost\\.(?: You can't add more than (\\d+) damage in this way\\.)?",
		func(m):
			var et: String = m.get_string(3).strip_edges()
			return {"k": "formula", "f": "extra_energy", "etype": "" if et == "basic" else et, "n": int(m.get_string(2)),
					"mode": "plus", "cap": int(m.get_string(4)) if m.get_string(4) != "" else 999})
	_k("You can't add more than (\\d+) damage in this way\\.", func(m): return {"k": "cap", "n": int(m.get_string(1))})
	_k("Does (\\d+) damage plus (\\d+) more damage for each card in your opponent's hand\\.",
		func(m): return {"k": "formula", "f": "opp_hand", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each of your Benched Pokémon\\.",
		func(m): return {"k": "formula", "f": "my_bench", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each Colorless Energy in the Defending Pokémon's Retreat Cost\\.",
		func(m): return {"k": "formula", "f": "def_retreat", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each type of basic Energy(?: card)? attached to NAME\\.",
		func(m): return {"k": "formula", "f": "self_energy_types", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each type of basic Energy attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy_types", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each Psychic Energy in play\\.",
		func(m): return {"k": "formula", "f": "psychic_in_play", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each Darkness Pokémon in play\\.",
		func(m): return {"k": "formula", "f": "darkness_pokemon", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) damage times the number of Pokémon in play with Team Magma in its name\\.",
		func(m): return {"k": "formula", "f": "team_magma", "n": int(m.get_string(1)), "mode": "times"})
	_k("Does (\\d+) damage plus (\\d+) more damage for each Special Energy card in your opponent's discard pile\\.",
		func(m): return {"k": "formula", "f": "opp_discard_special", "n": int(m.get_string(2)), "mode": "plus"})
	_k("Does (\\d+) more damage plus (\\d+) more damage for each Energy attached to all of your opponent's Pokémon\\.",
		func(m): return {"k": "formula", "f": "opp_energy", "n": int(m.get_string(2)), "mode": "plus"})
	# Condiciones especiales
	_k("(?:The|Each) Defending Pokémon is now " + ST + "(?: and " + ST + ")?\\.",
		func(m): return {"k": "status", "conds": [_st(m, 1)] + ([_st(m, 2)] if m.get_string(2) != "" else []), "who": "def"})
	_k("The Defending Pokémon is now " + ST + ", and can't retreat until the end of your opponent's next turn\\.",
		func(m): return [{"k": "status", "conds": [_st(m, 1)], "who": "def"}, {"k": "flag_def", "flag": "cant_retreat"}])
	_k("Both (?:NAME and the Defending Pokémon|the Defending Pokémon and NAME) are now " + ST + "\\.",
		func(m): return [{"k": "status", "conds": [_st(m, 1)], "who": "def"}, {"k": "status", "conds": [_st(m, 1)], "who": "self"}])
	_k("NAME is now " + ST + "\\.", func(m): return {"k": "status", "conds": [_st(m, 1)], "who": "self"})
	_k("At the end of your opponent's next turn, the Defending Pokémon is now " + ST + "\\.",
		func(m): return {"k": "delayed_status", "cond": _st(m, 1)})
	_k("Put (\\d+) damage counters instead of 1 on the Defending Pokémon between turns\\.",
		func(m): return {"k": "poison_counters", "n": int(m.get_string(1))})
	_k("The Defending Pokémon is Knocked Out\\.", func(_m): return {"k": "ko_def"})
	# Efectos para el turno siguiente
	_k("The Defending Pokémon can't retreat (?:until the end of|during) your opponent's next turn\\.",
		func(_m): return {"k": "flag_def", "flag": "cant_retreat"})
	_k("(?:The|Each) Defending Pokémon can't attack during your opponent's next turn\\.",
		func(_m): return {"k": "flag_def", "flag": "cant_attack"})
	_k("Your opponent can't attach Energy cards from his or her hand to the Defending Pokémon during his or her next turn\\.",
		func(_m): return {"k": "flag_def", "flag": "no_attach"})
	_k("NAME can't attack during your next turn\\.", func(_m): return {"k": "flag_self", "flag": "cant_attack", "turns": 2})
	_k("NAME can't use ([\\w ]+) during your next turn\\.",
		func(m): return {"k": "flag_self", "flag": "no_attack_" + m.get_string(1), "turns": 2})
	_k("Prevent all effects of an attack, including damage, done to NAME during your opponent's next turn\\.",
		func(_m): return {"k": "flag_self", "flag": "prevent_all", "turns": 1})
	_k("Prevent all damage done to NAME during your opponent's next turn\\.",
		func(_m): return {"k": "flag_self", "flag": "prevent_damage", "turns": 1})
	_k("(?:During your opponent's next turn, any damage done to NAME by attacks is reduced by (\\d+)|Damage done to NAME by an opponent's attack is reduced by (\\d+) during your opponent's next turn)\\.",
		func(m): return {"k": "reduce_self", "n": int(m.get_string(1) + m.get_string(2))})
	# Energía del Defensor
	_k("(?:Discard|Your opponent discards) (a|an|\\d+) Energy(?: card)?(?:, if any,)? attached to (the Defending Pokémon|that Pokémon)\\.",
		func(m): return {"k": "discard_def_energy", "count": _n(m.get_string(1)), "that": m.get_string(2) == "that Pokémon"})
	_k("Discard an Energy card from each Defending Pokémon\\.", func(_m): return {"k": "discard_def_energy", "count": 1})
	_k("Discard a Special Energy card, if any, attached to the Defending Pokémon\\.",
		func(_m): return {"k": "discard_def_energy", "count": 1, "special": true})
	_k("Choose an Energy card attached to the Defending Pokémon and put that card at the bottom of your opponent's deck\\.",
		func(_m): return {"k": "def_energy_to_deck"})
	_k("Discard all Trainer cards attached to the Defending Pokémon\\.", func(_m): return {"k": "strip_def_trainers"})
	# Energía propia
	_k("Discard (a|an|\\d+|all) (?:basic )?(\\w+ )?Energy(?: cards?)? attached to NAME( or this attack does nothing)?\\.",
		func(m): return {"k": "discard_self", "count": _n(m.get_string(1)), "etype": m.get_string(2).strip_edges(),
				"or_nothing": m.get_string(3) != ""})
	_k("Discard a (\\w+) Energy(?: card)? and a (\\w+) Energy(?: card)? attached to NAME\\.",
		func(m): return [{"k": "discard_self", "count": 1, "etype": m.get_string(1)}, {"k": "discard_self", "count": 1, "etype": m.get_string(2)}])
	_k("Discard a (\\w+) Energy(?: card)? attached to NAME and then discard an Energy card attached to the Defending Pokémon\\.",
		func(m): return [{"k": "discard_self", "count": 1, "etype": m.get_string(1)}, {"k": "discard_def_energy", "count": 1}])
	_k("Discard a (\\w+) Energy(?: card)? attached to NAME and your opponent switches the Defending Pokémon with 1 of his or her Benched Pokémon, if any\\.",
		func(m): return [{"k": "discard_self", "count": 1, "etype": m.get_string(1)}, {"k": "opp_switch"}])
	_k("You may discard (a|an|\\d+|all) (?:basic )?(\\w+ )?Energy(?: cards?)? attached to NAME\\.",
		func(m): return {"k": "discard_self", "count": _n(m.get_string(1)), "etype": m.get_string(2).strip_edges(), "optional": true})
	# Daño propio y curación
	_k("NAME does (\\d+) damage to itself(?:, and don't apply Weakness and Resistance to this damage)?\\.",
		func(m): return {"k": "self_damage", "n": int(m.get_string(1))})
	_k("Put (\\d+) damage counters? on NAME\\.", func(m): return {"k": "self_damage", "n": 10 * int(m.get_string(1))})
	_k("Remove (\\d+|all) damage counters? from NAME\\.", func(m): return {"k": "heal_self", "n": _n(m.get_string(1))})
	_k("Remove (\\d+) damage counters? from each of your (?:Active )?Pokémon(?:, including NAME)?\\.",
		func(m): return {"k": "heal_mine", "n": int(m.get_string(1))})
	_k("Remove (\\d+) damage counters? from each of your Active Pokémon\\.",
		func(m): return {"k": "heal_self", "n": int(m.get_string(1))})
	_k("Remove (\\d+) damage counters? from 1 of your Pokémon\\.", func(m): return {"k": "heal_one", "n": int(m.get_string(1))})
	_k("Remove all Special Conditions and (\\d+) damage counters from NAME\\.",
		func(m): return [{"k": "heal_self", "n": int(m.get_string(1))}, {"k": "clear_self"}])
	_k("Remove (\\d+) damage counters from the Defending Pokémon\\.", func(m): return {"k": "heal_def", "n": int(m.get_string(1))})
	# Daño a otros Pokémon
	_k("Does (\\d+) damage to (?:1|\\d+) of your opponent's Benched Pokémon\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "bench"})
	_k("Does (\\d+) damage to 1 of your opponent's Pokémon\\.", func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "any"})
	_k("(?:This attack does|Does) (\\d+) damage to each of your opponent's Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_all"})
	_k("(?:This attack does|Does) (\\d+) damage to each of your opponent's Benched Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench"})
	_k("Does (\\d+) damage to each of your opponent's Benched Pokémon that has any damage counters on it\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench_damaged"})
	_k("Does (\\d+) damage to each Benched Pokémon\\.", func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_bench"})
	_k("Does (\\d+) damage to each Benched Pokémon that has Energy cards attached to it\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_bench_energy"})
	_k("Does (\\d+) damage to each of your Benched Pokémon\\.", func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "my_bench"})
	_k("Does (\\d+) damage to each Active Pokémon\\.", func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_active"})
	_k("Put (\\d+) damage counters? on (?:the|each) Defending Pokémon\\.",
		func(m): return {"k": "counters", "to": "def", "n": int(m.get_string(1))})
	_k("Put a total of (\\d+) damage counters on all Defending Pokémon in any way you like\\.",
		func(m): return {"k": "counters", "to": "def", "n": int(m.get_string(1))})
	_k("Put (\\d+) damage counters? on each of your opponent's (Benched )?Pokémon( that already has damage counters on it)?\\.",
		func(m): return {"k": "counters", "to": "opp_bench" if m.get_string(2) != "" else ("opp_damaged" if m.get_string(3) != "" else "opp_all"), "n": int(m.get_string(1))})
	_k("Put (\\d+) damage counters? on 1 of your opponent's Pokémon\\.",
		func(m): return {"k": "counters", "to": "target", "n": int(m.get_string(1)), "needs": "any"})
	_k("Put (\\d+) damage counters on your opponent's Pokémon in any way you like\\.",
		func(m): return {"k": "distribute", "flips": 0, "n": 1, "total": int(m.get_string(1))})
	_k("Put damage counters on the Defending Pokémon until it is (\\d+) HP away from being Knocked Out\\.",
		func(m): return {"k": "set_def_hp", "n": int(m.get_string(1))})
	# Cambios de Pokémon
	_k("Your opponent switches the Defending Pokémon with 1 of his or her Benched Pokémon(?:, if any)?\\.",
		func(_m): return {"k": "opp_switch"})
	_k("(?:You )?[Ss]witch NAME with 1 of your Benched Pokémon(?:, if any)?\\.", func(_m): return {"k": "self_switch"})
	_k("You may switch NAME with 1 of your Benched Pokémon\\.", func(_m): return {"k": "self_switch", "optional": true})
	_k("Your opponent returns the Defending Pokémon and all cards attached to it to his or her hand\\.",
		func(_m): return {"k": "return_def"})
	_k("Remove the highest Stage Evolution card from each of them and put those cards back into his or her hand\\.",
		func(_m): return {"k": "devolve_opp"})
	# Mazo, mano y descarte
	_k("Draw (a|\\d+) cards?\\.", func(m): return {"k": "draw", "n": _n(m.get_string(1))})
	_k("Draw cards until you have the same number of cards in your hand as your opponent has in his or her hand\\.",
		func(_m): return {"k": "draw_to_opp"})
	_k("Draw a number of cards up to the number of your opponent's Basic Pokémon in play\\.",
		func(_m): return {"k": "draw_opp_basics"})
	_k("Shuffle your deck afterward\\.", func(_m): return null)
	_k("Search your deck for (?:up to (\\d+)|a) (Grass |Colorless )?Basic Pokémon(?: or (?:a )?Basic Pokémon with (Team Aqua|Team Magma) in its name)? and put (?:it|them) onto your Bench\\.",
		func(m): return {"k": "bench_search", "n": _n(m.get_string(1)), "type": m.get_string(2).strip_edges(), "team": m.get_string(3)})
	_k("Search your deck for (\\w+) Basic Pokémon and put as many of them as you like onto your Bench\\.",
		func(m): return {"k": "bench_search", "n": 5, "type": m.get_string(1), "team": ""})
	_k("Search your deck for NAME and put as many of them as you like onto your Bench\\.",
		func(_m): return {"k": "bench_search", "n": 5, "type": "", "team": "", "same": true})
	_k("Search your deck for a card that evolves from NAME and put it on NAME\\.", func(_m): return {"k": "self_evolve"})
	_k("Search your deck for an Evolution card, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "evolution", "n": 1})
	_k("Search your deck for a Trainer card, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "trainer", "n": 1})
	_k("Search your deck for up to (\\d+) cards and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "any", "n": int(m.get_string(1))})
	_k("(?:[Ss]earch your deck for any|[Pp]ick any) (\\d+) card (?:from your deck )?and put it into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "any", "n": int(m.get_string(1))})
	_k("Search your deck for (\\d+) basic Energy cards, show them to your opponent, and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "basic_energy", "n": int(m.get_string(1))})
	_k("Search your deck for up to (\\d+) different types of basic Energy cards, show them to your opponent, and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "energy_types", "n": int(m.get_string(1))})
	_k("Search your deck for a Basic Pokémon and a basic Energy card, show them to your opponent, and put them into your hand\\.",
		func(_m): return [{"k": "search_hand", "filter": "basic", "n": 1}, {"k": "search_hand", "filter": "basic_energy", "n": 1}])
	_k("Search your deck for up to (\\d+) cards that evolve from NAME, show them to your opponent, and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "evolves_from_self", "n": int(m.get_string(1))})
	_k("Search your deck for Pokémon that has Team Aqua in its name, show up to (\\d+) of them to your opponent, and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "team_aqua", "n": int(m.get_string(1))})
	_k("Search your discard pile for (?:up to (\\d+)|a) basic Energy cards?, show (?:it|them) to your opponent, and put (?:it|them) into your hand\\.",
		func(m): return {"k": "recover", "filter": "basic_energy", "n": _n(m.get_string(1))})
	_k("Put any (\\d+) card from your discard pile into your hand\\.",
		func(m): return {"k": "recover", "filter": "any", "n": int(m.get_string(1))})
	_k("Search your discard pile for a Stadium card, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "recover", "filter": "stadium", "n": 1})
	_k("Choose 1 card from your opponent's hand without looking and discard it\\.",
		func(_m): return {"k": "opp_hand_random", "to": "discard"})
	_k("You may discard any Stadium card in play\\.", func(_m): return {"k": "discard_stadium", "optional": true})
	# Unir Energías
	_k("Attach (?:a|an) (basic |\\w+ )?Energy card from your hand to NAME\\.",
		func(m): return {"k": "attach", "from": "hand", "etype": m.get_string(1).strip_edges(), "to": "self", "n": 1})
	_k("Attach a basic Energy card from your hand to 1 of your Pokémon\\.",
		func(_m): return {"k": "attach", "from": "hand", "etype": "basic", "to": "any", "n": 1})
	_k("Attach (?:a|an|(\\d+)) (?:basic )?(\\w+ )?Energy card from your discard pile to (NAME|your Active Pokémon)\\.",
		func(m): return {"k": "attach", "from": "discard", "etype": m.get_string(2).strip_edges(), "to": "self", "n": _n(m.get_string(1))})
	_k("Attach up to (\\d+) (?:basic )?Energy cards from your discard pile to NAME\\.",
		func(m): return {"k": "attach", "from": "discard", "etype": "", "to": "self", "n": int(m.get_string(1))})
	_k("Search your discard pile for (?:a|an|(\\d+)) (basic |\\w+ )?Energy cards? and attach (?:it|them) to NAME\\.",
		func(m): return {"k": "attach", "from": "discard", "etype": m.get_string(2).strip_edges(), "to": "self", "n": _n(m.get_string(1))})
	_k("Search your deck for (?:a|an) (basic |\\w+ )?Energy card and attach it to (NAME|1 of your Pokémon)\\.",
		func(m): return {"k": "attach", "from": "deck", "etype": m.get_string(1).strip_edges(), "to": "self" if m.get_string(2) == "NAME" else "any", "n": 1})
	_k("Search your deck for up to (\\d+) (\\w+) Energy cards and attach them to NAME\\.",
		func(m): return {"k": "attach", "from": "deck", "etype": m.get_string(2), "to": "self", "n": int(m.get_string(1))})
	_k("Attach a (\\w+) Energy card from your hand to any of your Pokémon\\.",
		func(m): return {"k": "attach", "from": "hand", "etype": m.get_string(1), "to": "any", "n": 1})
	_k("You may move a (\\w+) Energy card attached to NAME to 1 of your Benched Pokémon\\.",
		func(m): return {"k": "move_energy_bench", "etype": m.get_string(1), "optional": true})
	_k("The new Defending Pokémon is now " + ST + "(?: and " + ST + ")?\\.",
		func(m): return {"k": "status", "conds": [_st(m, 1)] + ([_st(m, 2)] if m.get_string(2) != "" else []), "who": "def"})
	_k("This attack does (\\d+) damage to the new Defending Pokémon\\.", func(m): return {"k": "set_base", "n": int(m.get_string(1))})
	_k("Attach up to (\\d+) (\\w+)(?: or (\\w+))? Energy cards? from your hand to your Pokémon(?: in any way you like)?\\.",
		func(m): return {"k": "attach_multi", "n": int(m.get_string(1)),
				"types": [m.get_string(2)] + ([m.get_string(3)] if m.get_string(3) != "" else []), "active_only": false})
	_k("Attach any number of basic Energy cards from your hand to your Pokémon in any way you like\\.",
		func(_m): return {"k": "attach_multi", "n": 99, "types": [], "active_only": false})
	_k("If you have (\\w+) Energy cards in your hand, attach as many \\w+ Energy cards as you like to any of your Active Pokémon\\.",
		func(m): return {"k": "attach_multi", "n": 99, "types": [m.get_string(1)], "active_only": true})
	_k("Move 1 Energy card attached to NAME to another of your Pokémon and remove (\\d+) damage counters from that Pokémon\\.",
		func(m): return {"k": "fruition", "n": int(m.get_string(1))})
	_k("Search your deck for a Stadium card and play it\\.", func(_m): return {"k": "search_stadium"})
	_k("Search your deck for a card that evolves from 1 of your Pokémon and put it on that Pokémon\\.",
		func(_m): return {"k": "make_a_wish"})
	_k("During your next turn, (\\w[\\w ]*?)'s base damage is (\\d+) instead of \\d+, and (\\w[\\w ]*?)'s base damage is (\\d+) instead of \\d+\\.",
		func(m): return {"k": "next_turn", "base": {m.get_string(1): int(m.get_string(2)), m.get_string(3): int(m.get_string(4))}})
	_k("During your next turn, base damage of NAME's (\\w[\\w ]*?) (?:is )?attack is (\\d+) instead of \\d+\\.",
		func(m): return {"k": "next_turn", "base": {m.get_string(1): int(m.get_string(2))}})
	_k("During your next turn, (\\w[\\w ]*?) does (\\d+) damage plus (\\d+) more damage\\.",
		func(m): return {"k": "next_turn", "bonus_attack": {m.get_string(1): int(m.get_string(3))}})
	_k("During your next turn, if any of your current Active Pokémon does damage to any Defending Pokémon, this attack does (\\d+) more damage\\.",
		func(m): return {"k": "next_turn", "bonus_all": int(m.get_string(1))})
	# Technical Machines
	_k("Choose up to (\\d+) basic Energy cards attached to 1 of your opponent's Pokémon and attach them to the Defending Pokémon\\.",
		func(m): return {"k": "steel_generator", "n": int(m.get_string(1))})
	_build_ecard()


## Redacciones de la era e-card (Expedition, Aquapolis, Skyridge): casi todas son variantes de
## frases que ya se entienden, con otras palabras.
static func _build_ecard() -> void:
	# Monedas: variantes de "Flip N coins. This attack does X times/plus..."
	_m("Flip (\\d+) coins\\. This attack does (\\d+)(?: damages?)? times the number of heads\\.?",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": int(m.get_string(2)), "mode": "times"})
	_m("Flip (\\d+) coins\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.?",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": int(m.get_string(3)), "mode": "plus"})
	_m("Flip a coin until you get tails\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "until_tails", "n": int(m.get_string(2)), "mode": "plus"})
	_m("Flip a number of coins equal to the (?:amount|number) of (\\w+ )?Energy (?:cards )?attached to NAME\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "flips", "count": "self_energy", "etype": m.get_string(1).strip_edges(), "n": int(m.get_string(2)), "mode": "times"})
	_m("Flip a number of coins equal to the (?:amount|number) of (\\w+ )?Energy (?:cards )?attached to NAME\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "flips", "count": "self_energy", "etype": m.get_string(1).strip_edges(), "n": int(m.get_string(3)), "mode": "plus"})
	_m("Flip a number of coins equal to the number of damage counters on the Defending Pokémon\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "flips", "count": "def_counters", "n": int(m.get_string(2)), "mode": "plus"})
	_m("Flip a number of coins equal to the number of Energy cards attached to the Defending Pokémon\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "flips", "count": "def_energy", "n": int(m.get_string(1)), "mode": "times"})
	_m("Flip a number of coins equal to the amount of Energy attached to all of of your Benched Pokémon\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "flips", "count": "bench_energy", "n": int(m.get_string(2)), "mode": "plus"})
	_m("Flip (\\d+) coins\\. If you get 1 heads, this attack does (\\d+) damage plus (\\d+) more damage\\. If you get 2 heads, this attack does \\d+ damage plus (\\d+) more damage\\. If you get 3 heads, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": 0, "mode": "table",
				"table": [0, int(m.get_string(3)), int(m.get_string(4)), int(m.get_string(5))]})
	_m("Flip 2 coins\\. If both are heads, this attack does (\\d+) damage plus (\\d+) more damage\\. If both are tails, this attack does nothing\\. If 1 is heads and 1 is tails, this attack just does \\d+ damage\\.",
		func(m): return {"k": "flips", "count": 2, "n": 0, "mode": "table", "table": ["nothing", 0, int(m.get_string(2))]})
	_m("Flip 2 coins\\. If 1 of them is heads, this attack does (\\d+) damage\\. If both are heads, this attack does (\\d+) damage\\. If both are tails, the Defending Pokémon is now Confused\\.",
		func(m): return [{"k": "flips", "count": 2, "n": 0, "mode": "set_table", "table": [0, int(m.get_string(1)), int(m.get_string(2))]},
				{"k": "status", "conds": ["confused"], "who": "def", "c": "all_tails"}])
	# Condiciones con dos o más monedas
	_c("If (?:both of them|both coins) are heads, ", func(_m): return {"c": "all_heads"})
	_c("If both (?:of them )?are tails, ", func(_m): return {"c": "all_tails"})
	_c("If either of them is heads, ", func(_m): return {"c": "any_heads"})
	_c("If either (?:of them )?is tails, ", func(_m): return {"c": "any_tails"})
	_c("If you get at least 1 heads, ", func(_m): return {"c": "any_heads"})
	_c("If any of them are heads, ", func(_m): return {"c": "any_heads"})
	_c("If you get 2 or more heads, ", func(_m): return {"c": "heads_at_least", "n": 2})
	_k("If heads this attack does (\\d+) damage plus (\\d+) more damage\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(2)), "c": "heads"})
	# Debilidad y Resistencia
	_k("Don't apply (Weakness and Resistance|Weakness or Resistance|Resistance|Weakness)(?: for this attack)?\\.",
		func(m):
			var s: String = m.get_string(1)
			return {"k": "ignore", "w": s.contains("Weakness"), "r": s.contains("Resistance")})
	# Protección
	_k("(?:[Dd]uring your opponent's next turn, )?[Pp]revent all effects of attacks, including damage, done to NAME(?: during your opponent's next turn)?\\.",
		func(_m): return {"k": "flag_self", "flag": "prevent_all", "turns": 1})
	_k("[Pp]revent all damage done by attacks to NAME during your opponent's next turn\\.",
		func(_m): return {"k": "flag_self", "flag": "prevent_damage", "turns": 1})
	# Fórmulas
	_k("This attack does (\\d+) damage plus (\\d+) more damage for each Energy card attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy", "n": int(m.get_string(2)), "mode": "plus"})
	_k("This attack does (\\d+) damage times the number of Energy cards attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("This attack does (\\d+) damage plus (\\d+) more damage for each damage counter on (NAME|the Defending Pokémon)\\.",
		func(m): return {"k": "formula", "f": "own_counters" if m.get_string(3) == "NAME" else "def_counters", "n": int(m.get_string(2)), "mode": "plus"})
	_k("(?:This attack does|Does) (\\d+) damage plus (\\d+) (?:more )?damage for each Energy attached to NAME but not used to pay for this attack's Energy [Cc]ost\\.",
		func(m): return {"k": "formula", "f": "extra_energy", "n": int(m.get_string(2)), "mode": "plus"})
	_k("This attack does (\\d+) damage plus (\\d+) more damage for each Colorless Energy in the Defending Pokémon's Retreat Cost\\.(?: Damage is calculated using the Defending Pokémon's Retreat Cost [^.]*\\.)?",
		func(m): return {"k": "formula", "f": "def_retreat", "n": int(m.get_string(2)), "mode": "plus"})
	_k("If NAME has (\\d+) or more damage counters on it, this attack's base damage is (\\d+)\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(2)), "c": "self_damaged", "at": int(m.get_string(1))})
	_k("If there are (\\d+) or more damage counters on NAME, this attack's base damage is (\\d+) instead of \\d+\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(2)), "c": "self_damaged", "at": int(m.get_string(1))})
	_k("If [th]?here are no damage counters on the Defending Pokémon, this attack's base damage is (\\d+) instead of \\d+\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(1)), "c": "def_undamaged"})
	_k("If NAME and the Defending Pokémon don't have the same number of Energy cards attached to them, this attack's base damage is (\\d+) instead of \\d+\\.",
		func(m): return {"k": "set_base", "n": int(m.get_string(1)), "c": "diff_energy"})
	# Daño a la Banca
	_k("If your opponent has any Benched Pokémon, choose 1 of them and this attack does (\\d+) damage to it\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "bench"})
	_k("(?:[Cc]hoose 1 of your opponent's Benched Pokémon and )?this attack does (\\d+) damage to (?:it|that Pokémon)\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "bench"})
	_k("If your opponent has any Benched Pokémon, flip a coin\\.", func(_m): return {"k": "coin", "needs_opp_bench": true})
	_k("[Cc]hoose 1 of them and this attack does (\\d+) damage to it\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "bench", "c": "heads"})
	_m("If your opponent has any Benched Pokémon, choose up to (\\d+) of them\\. This attack does (\\d+) damage to each of them\\.",
		func(m): return {"k": "multi_bench", "count": int(m.get_string(1)), "n": int(m.get_string(2))})
	_m("Choose 1 of your opponent's Pokémon(?: in play| is play)\\. This attack does (\\d+) damage to that Pokémon\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "any"})
	_k("(?:This attack also does|Does) (\\d+) damage to each (?:of your own )?Benched Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_bench"})
	_k("Does (\\d+) damage to each of your own Benched Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "my_bench"})
	_k("This attack does (\\d+) damage to each Pokémon on each player's Bench\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_bench"})
	_k("This attack does (\\d+) damage to each Benched Pokémon with at least 1 Energy card attached to it\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_bench_energy"})
	_k("This attack does (\\d+) damage to each of your opponent's Benched Pokémon that are the same type as the Defending Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench_same_type"})
	_k("[Tt]his attack does (\\d+) damage to each of your Pokémon in play\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "my_all"})
	# Cambiar Pokémon
	_k("(?:[Cc]hoose 1 of your opponent's Benched Pokémon and switch (?:the Defending Pokémon with it|it with the Defending Pokémon))\\.",
		func(_m): return {"k": "gust", "needs": "bench"})
	_k("If your opponent has any Benched Pokémon, choose 1 of them and switch it with the Defending Pokémon\\.",
		func(_m): return {"k": "gust", "needs": "bench"})
	_k("[Cc]hoose 1 of your opponent's Benched Pokémon and switch the Defending Pokémon with it\\.",
		func(_m): return {"k": "gust", "needs": "bench", "phase": "post"})
	_k("Before doing damage, you may choose 1 of your opponent's Benched Pokémon and switch it with the Defending Pokémon\\.",
		func(_m): return {"k": "gust", "needs": "bench", "optional": true})
	_k("If your opponent has any Benched Pokémon, he or she chooses 1 of them and switches the Defending Pokémon with it\\.",
		func(_m): return {"k": "opp_switch"})
	_k("Then, your opponent switches the Defending Pokémon with 1 of his or her Benched Pokémon, if any\\.",
		func(_m): return {"k": "opp_switch"})
	_k("Then, choose 1 of your Benched Pokémon and switch NAME with it\\.", func(_m): return {"k": "self_switch"})
	_k("[Ss]witch NAME with 1 of your Benched Pokémon\\.(?#dup)", func(_m): return {"k": "self_switch"})
	_k("If both coins are heads, switch NAME with 1 of your Benched Pokémon\\.", func(_m): return {"k": "self_switch", "c": "all_heads"})
	_k("[Ss]witch NAME with 1 of your Benched Pokémon, if any\\.", func(_m): return {"k": "self_switch"})
	# Estados
	_m("If heads, choose a Special Condition\\. The Defending Pokémon is now affected by that Special Condition\\.",
		func(_m): return {"k": "choose_condition", "c": "heads"})
	_k("[Uu]ntil the end of your opponent's next turn the Defending Pokémon can't attack or retreat\\.",
		func(_m): return [{"k": "flag_def", "flag": "cant_attack"}, {"k": "flag_def", "flag": "cant_retreat"}])
	# Curación
	_k("Remove a damage counter from NAME\\.", func(_m): return {"k": "heal_self", "n": 1})
	_k("If there are any damage counters on NAME, remove 1 of them\\.", func(_m): return {"k": "heal_self", "n": 1})
	_k("For each heads, remove 1 damage counter (?:on|from) NAME\\.", func(_m): return {"k": "heal_self", "n": 1, "per_heads": true})
	# Energía
	_k("Attach (\\d+) basic Energy cards from your discard pile to NAME\\.",
		func(m): return {"k": "attach", "from": "discard", "etype": "", "to": "self", "n": int(m.get_string(1))})
	_k("[Pp]ut a basic Energy card from your discard pile into your hand\\.",
		func(_m): return {"k": "recover", "filter": "basic_energy", "n": 1})
	_k("[Dd]iscard 1 Energy card attached to the Defending Pokémon, if any\\.",
		func(_m): return {"k": "discard_def_energy", "count": 1})
	_k("[Dd]iscard a Special Energy card attached to the Defending Pokémon\\.",
		func(_m): return {"k": "discard_def_energy", "count": 1, "special": true})
	_k("Discard (?:1|a|an) (\\w+) Energy card attached to NAME in order to use this attack\\.",
		func(m): return {"k": "discard_self", "count": 1, "etype": m.get_string(1), "or_nothing": true})
	# Mazo y mano
	_k("Each player discards the top (\\d+) cards from his or her deck\\.",
		func(m): return [{"k": "mill_opp", "n": int(m.get_string(1))}, {"k": "mill_self", "n": int(m.get_string(1))}])
	_k("Search your deck for a Supporter card, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "supporter", "n": 1})
	_k("[Ss]earch your deck for a card that evolves from NAME, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "evolves_from_self", "n": 1})
	_k("If tails this attack does nothing\\.", func(_m): return {"k": "nothing", "c": "tails"})
	_k("If either of them is tails, this attack does nothing\\.", func(_m): return {"k": "nothing", "c": "any_tails"})
	_k("[Tt]his attack does (\\d+) damage and the [Dd]efending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "set_base", "n": int(m.get_string(1))}, {"k": "status", "conds": [_st(m, 2)], "who": "def"}])
	_k("[Tt]his attack does (\\d+) damage plus (\\d+) more damage and the Defending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "status", "conds": [_st(m, 3)], "who": "def"}])
	# --- tanda 2 ---
	_m("If there are any (\\w+) Energy cards? in your discard pile, flip a coin\\. If heads, attach 1 of them to NAME\\.",
		func(m): return [{"k": "coin"}, {"k": "attach", "from": "discard", "etype": m.get_string(1), "to": "self", "n": 1, "c": "heads"}])
	_m("Choose 1 of the Defending Pokémon's attacks\\. [\\w-]+ copies that attack\\. This attack does nothing if NAME doesn't have the Energy necessary to use that attack\\.",
		func(_m): return {"k": "copy_def", "needs_energy": true})
	_m("Flip a coin\\. If heads, choose 1 of the Defending Pokémon's attacks\\. [\\w-]+ copies that attack except for its Energy cost\\. NAME performs that attack\\.",
		func(_m): return {"k": "copy_def", "needs_energy": false, "coin": true})
	_m("Choose 1 of your opponent's Pokémon\\. Count the number of Energy cards attached to that Pokémon\\. Put that many damage counters on the Pokémon\\.",
		func(_m): return {"k": "counters", "to": "target", "n": 0, "per": "target_energy", "needs": "any"})
	_m("Choose 1 of your opponent's Benched Pokémon\\. This attack does (\\d+) damage times the amount of (\\w+) Energy attached to NAME(?: to that Pokémon)?\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "per_self_etype": m.get_string(2), "needs": "bench"})
	_m("Look at your opponent's hand\\. This attack does (\\d+) damage times the number of Energy cards there\\.",
		func(m): return {"k": "formula", "f": "opp_hand_energy", "n": int(m.get_string(1)), "mode": "times"})
	_m("Count the number of (?:your )?Pokémon (?:you have )?in play with damage counters on them\\. Put that many damage counters on the Defending Pokémon\\.",
		func(_m): return {"k": "counters", "to": "def", "n": 0, "per": "my_damaged"})
	_m("Count the number of Pokémon on your Bench\\. This attack does (\\d+) times that number of damage to the Defending Pokémon, and NAME does \\d+ times that number of damage to itself\\.",
		func(m): return [{"k": "formula", "f": "my_bench", "n": int(m.get_string(1)), "mode": "times"}, {"k": "self_damage", "n": 0, "per": "my_bench", "each": int(m.get_string(1))}])
	_m("This attack does (\\d+) damage plus (\\d+) damage times the number of your opponent's Benched Pokémon minus the number of your Benched Pokémon\\.",
		func(m): return {"k": "formula", "f": "bench_diff_opp", "n": int(m.get_string(2)), "mode": "plus"})
	_m("This attack does (\\d+) damage plus (\\d+) damage times the number of your Benched Pokémon minus the number of your opponent's Benched Pokémon\\.",
		func(m): return {"k": "formula", "f": "bench_diff_mine", "n": int(m.get_string(2)), "mode": "plus"})
	_m("Flip a coin,? If heads, this attack does (\\d+) damage to each of your opponent's Benched Pokémon\\. If tails, this attack does \\d+ damage to each of your Benched Pokémon\\.",
		func(m): return [{"k": "coin"}, {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench", "c": "heads"}, {"k": "spread", "n": int(m.get_string(1)), "scope": "my_bench", "c": "tails"}])
	_m("For each heads, do (\\d+) damage to each of your opponent's Benched Pokémon\\. For each tails, do \\d+ damage to each of your own Benched Pokémon\\.",
		func(m): return {"k": "spread_heads", "n": int(m.get_string(1))})
	_m("For each Benched Pokémon, flip a coin\\. If heads, this attack does (\\d+) damage to that Pokémon\\.",
		func(m): return {"k": "spread_coin", "n": int(m.get_string(1))})
	_m("Before doing damage, you may flip a coin\\. If heads, this attack does (\\d+) damage\\.(?: If tails, this attack does nothing\\.)?(?: If not, this attack does (\\d+) damage\\.)?",
		func(m): return [{"k": "coin", "optional": true}, {"k": "set_base", "n": int(m.get_string(1)), "c": "heads", "optional": true},
				{"k": "nothing", "c": "tails", "optional": true}])
	_m("Look at the top (\\d+) cards of your deck, and then choose 1 of those cards and put it into your hand\\. Shuffle the rest into your deck afterward\\.",
		func(m): return {"k": "top_pick", "n": int(m.get_string(1))})
	_m("You may discard up to (\\d+) cards from your hand\\. If you do, draw that many cards\\.",
		func(m): return {"k": "hand_cycle", "n": int(m.get_string(1))})
	_m("Your opponent discards the top card from his or her deck\\. Then you remove a damage counter from NAME\\.",
		func(_m): return [{"k": "mill_opp", "n": 1}, {"k": "heal_self", "n": 1}])
	_m("Each player discards? the top card of his or her deck\\. This attack does (\\d+) damage plus (\\d+) more damage for each (\\w+) Energy card discarded in this way\\.",
		func(m): return {"k": "mill_both_bonus", "per": int(m.get_string(2)), "etype": m.get_string(3)})
	_m("Search your deck for a Basic Pokémon card named NAME or ([\\w ♂♀]+) and put it onto your Bench\\.",
		func(m): return {"k": "bench_search", "n": 1, "type": "", "team": "", "names": [m.get_string(1)], "same": true})
	_m("Search your deck for a Baby Pokémon or Basic Pokémon card and put it onto your Bench\\.",
		func(_m): return {"k": "bench_search", "n": 1, "type": "", "team": ""})
	_m("Search your discard pile for a Baby Pokémon, Basic Pokémon, Evolution card, or basic Energy card, show it to your opponent, and then put it into your hand\\.",
		func(_m): return {"k": "recover", "filter": "pokemon_or_basic_energy", "n": 1})
	_m("Search your deck for a Technical Machine or Pokémon Tool card, show it to your opponent, and put it into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "tm_or_tool", "n": 1})
	_m("If heads, search your deck for a (\\w+) Energy card and attach it to 1 of your Benched Pokémon\\.",
		func(m): return {"k": "attach", "from": "deck", "etype": m.get_string(1), "to": "bench", "n": 1, "c": "heads"})
	_m("Attach up to (\\d+) (\\w+) Energy cards from your hand to NAME\\.",
		func(m): return {"k": "attach_hand_self", "n": int(m.get_string(1)), "etype": m.get_string(2)})
	_m("Attach any number of basic Energy cards from your hand to NAME\\.",
		func(_m): return {"k": "attach_hand_self", "n": 99, "etype": ""})
	_m("Attach a basic Energy card from your discard pile to 1 of your Pokémon\\.",
		func(_m): return {"k": "attach", "from": "discard", "etype": "", "to": "any", "n": 1})
	_k("[Tt]ake a basic Energy card attached to 1 of your Pokémon and attach it to another of your Pokémon\\.",
		func(_m): return {"k": "move_energy_any"})
	_k("If you have any Benched Pokémon and if there are any basic Energy cards attached to NAME, take 1 of those Energy cards and attach it to 1 of those Pokémon\\.",
		func(_m): return {"k": "move_energy_bench", "etype": ""})
	_k("[Tt]he Defending Pokémon can't use any Poké-Powers until the end of your opponent's next turn\\.",
		func(_m): return {"k": "flag_def", "flag": "no_powers"})
	_k("[Dd]uring your opponent's next turn, NAME can't become affected by a Special Condition\\.",
		func(_m): return {"k": "flag_self", "flag": "no_conditions", "turns": 1})
	_k("[Yy]our opponent can't play Supporter cards during his or her next turn\\.",
		func(_m): return {"k": "opp_flag", "flag": "no_supporter"})
	_k("[Yy]our opponent can't attach Energy cards from his or her hand to his or her Active Pokémon during his or her next turn\\.",
		func(_m): return {"k": "flag_def", "flag": "no_attach"})
	_k("[Dd]iscard 1 Energy card attached to 1 of your opponent's Pokémon\\.",
		func(_m): return {"k": "discard_opp_any_energy"})
	_k("[Cc]hoose a card from your discard pile and put it on top of your deck\\.",
		func(_m): return {"k": "discard_to_top"})
	_k("[Cc]hoose a Trainer card from your discard pile, show it to your opponent, and then shuffle it into your deck\\.",
		func(_m): return {"k": "discard_to_deck", "filter": "trainer"})
	_k("Shuffle a basic Energy card from your discard pile into your deck\\.",
		func(_m): return {"k": "discard_to_deck", "filter": "basic_energy"})
	_k("If your opponent has any Benched Pokémon, this attack does (\\d+) damage to each of them\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench"})
	_k("[Tt]his attack does (\\d+) damage to each of your opponent's Benched Pokémon, if any\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "opp_bench"})
	_k("[Tt]his attack does (\\d+) damage to each Pokémon with a Poké-Body or Poké-Power\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "all_ability"})
	_k("[Tt]his attack does (\\d+) damage plus (\\d+) more damage and does (\\d+) damage to each of your opponent's Benched Pokémon, if any\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "spread", "n": int(m.get_string(3)), "scope": "opp_bench"}])
	_k("[Tt]his attack does (\\d+) damage times the number of Energy attached to NAME and the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "both_energy", "n": int(m.get_string(1)), "mode": "times"})
	_k("[Tt]his attack does (\\d+) damage times the number of Pokémon you have in play\\.",
		func(m): return {"k": "formula", "f": "my_pokemon", "n": int(m.get_string(1)), "mode": "times"})
	_k("[Tt]his attack does (\\d+) damage times the number of damage counters on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(1)), "mode": "times"})
	_k("[Tt]his attack does (\\d+) damage plus (\\d+) more damage for each Special Energy card attached to the Defending Pokémon\\.",
		func(m): return {"k": "formula", "f": "def_special", "n": int(m.get_string(2)), "mode": "plus"})
	_k("[Tt]his attack does (\\d+) damage plus (\\d+) more damage for each ([\\w ,]+?),? and ([\\w-]+) on your Bench\\.",
		func(m): return {"k": "formula", "f": "bench_named", "names": (m.get_string(3) + ", " + m.get_string(4)).replace("NAME", "SELF").split(", "), "n": int(m.get_string(2)), "mode": "plus"})
	_k("Damage from this attack is reduced by (\\d+) for each damage counter on NAME\\.",
		func(m): return {"k": "formula", "f": "own_counters", "n": int(m.get_string(1)), "mode": "minus"})
	_k("If the Defending Pokémon isn't (Asleep|Burned|Confused|Paralyzed|Poisoned), this attack does nothing\\.",
		func(m): return {"k": "nothing", "c": "def_not_cond", "cond": _st(m, 1)})
	_k("If this attack damages the Defending Pokémon, remove 1 damage counter from NAME, if it has any\\.",
		func(_m): return {"k": "heal_self", "n": 1, "if_dealt": true})
	_k("Put a damage counter on (NAME|the Defending Pokémon)(?: for each heads)?\\.",
		func(m): return {"k": "self_damage", "n": 10, "per_heads": m.get_string(0).contains("each heads")} if m.get_string(1) == "NAME" else {"k": "counters", "to": "def", "n": 1})
	_k("[Cc]hoose 1 of your opponent's Pokémon\\. Put a damage counter on that Pokémon\\.",
		func(_m): return {"k": "counters", "to": "target", "n": 1, "needs": "any"})
	_k("For each tails, discard 1 Energy card attached to NAME\\.",
		func(_m): return {"k": "discard_self", "count": 0, "per_tails": true, "etype": ""})
	_k("For each heads, search your deck for a basic Energy card\\. Show those cards to your opponent, and then put them into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "basic_energy", "n": 0, "per_heads": true})
	_k("For each heads, remove 1 damage counter from each of your Pokémon\\. If a Pokémon has fewer damage counters than the number of heads, remove all of them\\.",
		func(_m): return {"k": "heal_mine", "n": 1, "per_heads": true})
	_k("Remove (\\d+) damage counters from NAME for each Energy attached to it\\. If it has fewer damage counters than that, remove all of them\\.",
		func(m): return {"k": "heal_self", "n": int(m.get_string(1)), "per_energy": true})
	_k("Remove (\\d+) damage counters from NAME and each Pokémon that's the same type as NAME\\.",
		func(m): return {"k": "heal_mine", "n": int(m.get_string(1)), "same_type": true})
	_k("Choose 1 of your Pokémon with an Energy card attached to it\\. Remove 1 damage counter from that Pokémon\\.",
		func(_m): return {"k": "heal_one", "n": 1})
	_k("Discard an Energy card attached to NAME and flip a coin\\.", func(_m): return [{"k": "discard_self", "count": 1, "etype": ""}, {"k": "coin"}])
	_k("Look at the top (\\d+) cards of your opponent's deck\\. Put them back in the same order\\.", func(_m): return null)
	_k("If your opponent has no Benched Pokémon, ignore this effect\\.", func(_m): return null)
	_k("If you have no Benched Pokémon, ignore this effect\\.", func(_m): return null)
	_k("Damage is calculated using the Defending Pokémon's Retreat Cost after applying effects to the Retreat Cost\\.", func(_m): return null)
	_k("[Tt]hen, flip a coin\\.", func(_m): return {"k": "coin", "phase": "post"})
	_k("[Tt]his attack can't be used during your next turn\\.", func(_m): return {"k": "flag_self", "flag": "no_attack_ATTACK", "turns": 2})

	# --- tanda 3: ataques de una sola carta ---
	_m("Flip 2 coins\\. If 1 of them is tails, discard 2 Energy cards attached to NAME\\. If both are tails, discard all Energy cards attached to NAME\\.",
		func(_m): return [{"k": "flips", "count": 2, "n": 0, "mode": "none", "phase": "post"}, {"k": "discard_tail_table", "phase": "post"}])     # Charizard
	_m("Count the number of Pokémon you have in play with damage counters on them\\. Flip a coin\\. If heads, this attack does (\\d+) damage plus (\\d+) more damage for each of those Pokémon\\.",
		func(m): return [{"k": "coin"}, {"k": "formula", "f": "my_damaged", "n": int(m.get_string(2)), "mode": "plus", "c": "heads"}])     # Machamp
	_m("Discard all (\\w+) Energy cards attached to NAME\\. This attack does (\\d+) damage plus (\\d+) more damage for each (?:card|Energy card) discarded (?:this|in this) way\\.",
		func(m): return {"k": "discard_bonus", "etype": m.get_string(1), "per": int(m.get_string(3)), "mode": "plus"})     # Ninetales, Pikachu
	_m("Discard all (\\w+) Energy cards attached to NAME\\. Flip a number of coins equal to the number of \\w+ Energy cards you discarded\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "discard_bonus", "etype": m.get_string(1), "per": int(m.get_string(3)), "mode": "flips"})     # Lanturn
	_m("You may discard any number of (\\w+) Energy cards attached to NAME when you use this attack\\. If you do, flip a number of coins equal to the number of \\w+ Energy cards you discarded\\. This attack does (\\d+) damage plus (\\d+) more damage for each heads\\.",
		func(m): return {"k": "any_energy", "mode": "discard_flips", "etype": m.get_string(1), "base": int(m.get_string(2)), "per": int(m.get_string(3))})     # Arcanine
	_m("Discard any number of Energy cards attached to any of your Pokémon\\. Flip a number of coins equal to the number of Energy cards discarded this way\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "any_energy", "mode": "discard_all_flips", "etype": "", "base": 0, "per": int(m.get_string(1))})     # Exeggutor
	_m("You may flip a coin\\. If heads, discard all (\\w+) Energy cards attached to NAME\\. This attack does (\\d+) damage plus (\\d+) more damage for each Energy card discarded in this way\\.",
		func(m): return [{"k": "coin", "optional": true}, {"k": "discard_bonus", "etype": m.get_string(1), "per": int(m.get_string(3)), "mode": "plus", "c": "heads", "optional": true}])     # Raikou
	_m("You may flip a coin\\. If heads, discard a (\\w+) Energy card attached to NAME and the Defending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "coin", "optional": true}, {"k": "discard_self", "count": 1, "etype": m.get_string(1), "c": "heads", "optional": true},
				{"k": "status", "conds": [_st(m, 2)], "who": "def", "c": "heads", "optional": true}])     # Entei
	_m("Flip a coin\\. If heads, discard a (\\w+) Energy card attached to NAME and this attack does (\\d+) damage plus (\\d+) more damage\\.",
		func(m): return [{"k": "coin"}, {"k": "discard_self", "count": 1, "etype": m.get_string(1), "c": "heads"}, {"k": "bonus", "n": int(m.get_string(3)), "c": "heads"}])     # Rapidash
	_m("This attack does (\\d+) damage plus (\\d+) damage for each (\\w+) Energy attached to NAME\\. Flip a coin\\. If tails, NAME does (\\d+) damage to itself for each \\w+ Energy attached to it\\.",
		func(m): return [{"k": "formula", "f": "self_energy", "etype": m.get_string(3), "n": int(m.get_string(2)), "mode": "plus"}, {"k": "coin"},
				{"k": "self_damage", "n": 0, "per": "self_etype", "etype": m.get_string(3), "each": int(m.get_string(4)), "c": "tails"}])     # Lanturn
	_m("Flip a number of coins equal to the amount of (\\w+) Energy attached to NAME\\. If any of them are heads, the Defending Pokémon is now " + ST + " and " + ST + "\\.",
		func(m): return [{"k": "flips", "count": "self_energy", "etype": m.get_string(1), "n": 0, "mode": "none"}, {"k": "status", "conds": [_st(m, 2), _st(m, 3)], "who": "def", "c": "any_heads"}])     # Muk
	_m("Choose 1 of your opponent's Benched Pokémon\\. Flip (\\d+) coins\\. This attack does (\\d+) damage times the number of heads to that Pokémon\\. Don't apply Weakness and Resistance\\.",
		func(m): return [{"k": "flips", "count": int(m.get_string(1)), "n": 0, "mode": "none"}, {"k": "snipe", "n": int(m.get_string(2)), "per_heads": true, "needs": "bench"}])     # Marowak
	_m("Return NAME and all basic Energy cards attached to it to your hand\\. If you have no Benched Pokémon, this attack does nothing\\.",
		func(_m): return {"k": "return_self"})     # Aipom
	_m("Search your deck for a card that evolves from NAME\\. Attach it to NAME\\. This counts as evolving NAME\\.",
		func(_m): return {"k": "evolve_from_deck"})     # Paras
	_m("Put an? (\\w+) from your hand onto NAME\\. This counts as evolving NAME\\.",
		func(m): return {"k": "evolve_from_hand", "name": m.get_string(1)})     # Omanyte
	_m("Look at the top 3 cards of your opponent's deck\\. Put them back in the same order\\.", func(_m): return {"k": "peek_opp", "n": 3})
	_m("Look at the top 3 cards of either player's deck and rearrange them as you like\\.", func(_m): return {"k": "peek_opp", "n": 3})
	_m("Look at a number of cards on top of your opponent's deck equal to the number of Energy cards attached to the Defending Pokémon\\. Put those cards in any order, and then put them back on top of your opponent's deck\\.",
		func(_m): return {"k": "peek_opp", "n": 0})
	_m("Look at your opponent's hand\\. Choose all Technical Machine and Pokémon Tool cards there and put them into his or her deck\\. Your opponent shuffles the deck afterward\\.",
		func(_m): return {"k": "opp_hand_to_deck", "filter": "tm_or_tool", "all": true})     # Sneasel
	_m("If heads, look at your opponent's hand\\. If he or she has any (Trainer|Energy) cards there, choose 1 of them\\. Y?o?u?r? ?opponent shuffles that card into his or her deck\\.",
		func(m): return {"k": "opp_hand_to_deck", "filter": "trainer" if m.get_string(1) == "Trainer" else "energy", "c": "heads"})     # Persian, Meowth, Stantler
	_m("If you get 1 heads, this attack does (\\d+) damage plus (\\d+) more damage\\. If you get 2 heads, this attack does \\d+ damage plus (\\d+) more damage\\. If you get 3 heads, this attack does \\d+ damage plus (\\d+) more damage\\. If you get 4 heads, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "bonus_table", "table": [0, int(m.get_string(2)), int(m.get_string(3)), int(m.get_string(4)), int(m.get_string(5))]})     # Beedrill
	_m("Discard an Energy card attached to NAME in order to use this attack\\. If the discarded card is a (\\w+) Energy card, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "discard_one_bonus", "etype": m.get_string(1), "n": int(m.get_string(2))})     # Flareon
	_m("You may discard a (\\w+) or (\\w+) basic Energy card attached to NAME\\. If you discard a \\w+ Energy card in this way, the Defending Pokémon is now " + ST + "\\. If you discard a \\w+ Energy card in this way, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return [{"k": "lava_choice", "a": m.get_string(1), "b": m.get_string(2), "cond": _st(m, 3), "n": int(m.get_string(4)), "optional": true},
				{"k": "lava_status"}])     # Magcargo
	_m("You may discard all (\\w+) Energy cards attached to NAME when you use this attack\\. If you do, put damage counters equal to the amount of Energy cards removed in this way on any number of your opponent's Benched Pokémon in the way you like\\.",
		func(m): return {"k": "discard_to_counters", "etype": m.get_string(1), "optional": true})     # Magneton
	_m("If NAME and the Defending Pokémon don't have the same number of Energy cards attached to them, the player controlling the Active Pokémon with the fewest number of Energy cards attached to it switches 1 of his or her Benched Pokémon with his or her Active Pokémon\\.",
		func(_m): return {"k": "bounce_off"})     # Magneton
	_m("Move 2 (\\w+) Energy cards attached to NAME to 1 or 2 of your Benched Pokémon\\.",
		func(m): return [{"k": "move_energy_bench", "etype": m.get_string(1)}, {"k": "move_energy_bench", "etype": m.get_string(1)}])     # Politoed
	_m("If the Defending Pokémon has any (basic )?Energy cards attached to it, flip a coin\\. If heads, choose 1 of those Energy cards and move it to 1 of your opponent's Benched Pokémon\\.",
		func(m): return [{"k": "coin"}, {"k": "move_def_energy", "c": "heads", "basic": m.get_string(1) != ""}])     # Vaporeon, Magnemite
	_m("Flip a coin\\. If heads, choose an Energy card attached to the Defending Pokémon\\. Your opponent moves that card to 1 of his or her other Pokémon\\.",
		func(_m): return [{"k": "coin"}, {"k": "move_def_energy", "c": "heads"}])     # Elekid
	_m("If the Defending Pokémon has any Energy cards attached to it, flip a coin\\. If heads, choose 1 of those Energy cards and discard it\\.",
		func(_m): return [{"k": "coin"}, {"k": "discard_def_energy", "count": 1, "c": "heads"}])     # Natu
	_m("If the Defending Pokémon isn't Knocked Out by the damage from this attack, you may choose 1 of your opponent's Benched Pokémon and switch the Defending Pokémon with it\\.",
		func(_m): return {"k": "gust_after", "optional": true})     # Hypno
	_m("Before doing damage, you may choose 1 of your opponent's Benched Pokémon( with no damage counters on it)? and switch (?:the Defending Pokémon with it|it with the Defending Pokémon)\\.",
		func(m): return {"k": "gust", "needs": "bench_undamaged" if m.get_string(1) != "" else "bench", "optional": true})     # Scizor, Omanyte
	_m("During your next turn, NAME's (\\w[\\w ]*?) attack's base damage is (\\d+)\\.",
		func(m): return {"k": "next_turn", "base": {m.get_string(1): int(m.get_string(2))}})     # Machoke
	_m("Flip 2 coins\\. If either is heads, this attack does (\\d+) damage times the number of damage counters on NAME\\.",
		func(m): return [{"k": "flips", "count": 2, "n": 0, "mode": "none"}, {"k": "formula", "f": "own_counters", "n": int(m.get_string(1)), "mode": "times", "c": "any_heads"},
				{"k": "set_base", "n": 0, "c": "all_tails"}])     # Wobbuffet
	_m("Choose 1 of your opponent's Pokémon that has a damage counter on it\\. This attack does (\\d+) damage to that Pokémon\\.",
		func(m): return {"k": "snipe", "n": int(m.get_string(1)), "needs": "any_damaged"})     # Murkrow
	_m("Flip a coin\\. If heads, this attack does (\\d+) damage to the Defending Pokémon\\. If tails and your opponent has any Benched Pokémon, choose 1 of them and this attack does \\d+ damage to it\\.",
		func(m): return [{"k": "coin"}, {"k": "set_base", "n": int(m.get_string(1)), "c": "heads"}, {"k": "snipe", "n": int(m.get_string(1)), "needs": "bench", "c": "tails"}])     # Stantler
	_m("If the Defending Pokémon already has any damage counters on it, this attack does \\d+ damage plus (\\d+) more damage\\. If not, this attack does \\d+ damage\\.",
		func(m): return {"k": "bonus", "n": int(m.get_string(1)), "c": "def_damaged", "at": 1})     # Ursaring
	# Black Star Promos (np)
	_k("Discard an Energy card attached to NAME and draw (\\d+) cards\\.",                   # Jirachi np-21
		func(m): return [{"k": "discard_self", "count": 1, "etype": ""}, {"k": "draw", "n": int(m.get_string(1))}])
	_m("Your opponent switches each Defending Pokémon with his or her Benched Pokémon\\. If your opponent has only 1 Benched Pokémon, you choose the Defending Pokémon to switch\\.",
		func(_m): return {"k": "opp_switch"})                                                     # Chimecho np-24
	_k("Does (\\d+) damage to your Benched Pokémon\\.",
		func(m): return {"k": "spread", "n": int(m.get_string(1)), "scope": "my_bench"})
	# Textos de dos oraciones que las reglas generales partían mal
	_mf("Choose 1 of your opponent's Benched Pokémon\\. Flip (\\d+) coins\\. This attack does (\\d+) damage times the number of heads to that Pokémon\\. Don't apply Weakness and Resistance\\.",
		func(m): return [{"k": "flips", "count": int(m.get_string(1)), "n": 0, "mode": "none"}, {"k": "snipe", "n": int(m.get_string(2)), "per_heads": true, "needs": "bench"}])     # Marowak
	_mf("Flip (\\d+) coins\\. If you get 1 heads, this attack does (\\d+) damage plus (\\d+) more damage\\. If you get 2 heads, this attack does \\d+ damage plus (\\d+) more damage\\. If you get 3 heads, this attack does \\d+ damage plus (\\d+) more damage\\. If you get 4 heads, this attack does \\d+ damage plus (\\d+) more damage\\.",
		func(m): return {"k": "flips", "count": int(m.get_string(1)), "n": 0, "mode": "table",
				"table": [0, int(m.get_string(3)), int(m.get_string(4)), int(m.get_string(5)), int(m.get_string(6))]})     # Beedrill
	_mf("For each heads, search your deck for a basic Energy card\\. Show those cards to your opponent, and then put them into your hand\\.",
		func(_m): return {"k": "search_hand", "filter": "basic_energy", "n": 0, "per_heads": true})     # Togepi
	_mf("For each heads, remove 1 damage counter from each of your Pokémon\\. If a Pokémon has fewer damage counters than the number of heads, remove all of them\\.",
		func(_m): return {"k": "heal_mine", "n": 1, "per_heads": true})     # Venomoth
	_mf("Remove (\\d+) damage counters from NAME for each Energy attached to it\\. If it has fewer damage counters than that, remove all of them\\.",
		func(m): return {"k": "heal_self", "n": int(m.get_string(1)), "per_energy": true})     # Staryu
	_mf("Choose 1 of your opponent's Pokémon\\. Put a damage counter on that Pokémon\\.",
		func(_m): return {"k": "counters", "to": "target", "n": 1, "needs": "any"})     # Murkrow
	_mf("Choose 1 of your Pokémon with an Energy card attached to it\\. Remove (\\d+) damage counters? from that Pokémon\\.",
		func(m): return {"k": "heal_one", "n": int(m.get_string(1)), "with_energy": true})     # Igglybuff
	# Technical Machines e-card: Cubes 01, Miracle Spheres y Mystery Plates
	_k("Discard any Trainer cards attached to the Defending Pokémon\\.", func(_m): return {"k": "strip_def_trainers"})
	_m("Flip a number of coins equal to the number of damage counters on NAME\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return {"k": "flips", "count": "self_counters", "n": int(m.get_string(1)), "mode": "times"})     # Fighting Cube 01
	_m("Discard all (\\w+) Energy cards attached to NAME\\. Then, flip a number of coins equal to the number of Energy cards discarded that way\\. This attack does (\\d+) damage times the number of heads\\.",
		func(m): return [{"k": "set_base", "n": 0}, {"k": "discard_bonus", "etype": m.get_string(1), "per": int(m.get_string(2)), "mode": "flips"}])     # Lightning Cube 01
	_c("If NAME has (\\w+) and (\\w+) basic Energy cards attached to it, ",
		func(m): return {"c": "has_basic_types", "types": [m.get_string(1), m.get_string(2)]})
	_c("If your opponent has (\\d+) or more Prizes, ", func(m): return {"c": "opp_prizes_min", "cn": int(m.get_string(1))})
	_c("If your opponent has only 1 Prize, ", func(_m): return {"c": "opp_prizes_eq", "cn": 1})
	_c("If your opponent has exactly (\\d+) Prizes, ", func(m): return {"c": "opp_prizes_eq", "cn": int(m.get_string(1))})
	_k("This attack does (\\d+) damage plus (\\d+) more damage and remove (\\d+) damage counters from the Pokémon that .+ is attached to\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "heal_self", "n": int(m.get_string(3))}])
	_k("This attack does (\\d+) damage plus (\\d+) more damage and the Defending Pokémon is now " + ST + "\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "status", "conds": [_st(m, 3)], "who": "def"}])
	_k("This attack does (\\d+) damage plus (\\d+) more damage and lets you put 1 damage counter on each of your opponent's Benched Pokémon\\.",
		func(m): return [{"k": "bonus", "n": int(m.get_string(2))}, {"k": "spread", "n": 10, "scope": "opp_bench"}])
	_k("Choose an Energy card attached to the Defending Pokémon, if any, and your opponent shuffles that card into his or her deck\\.",
		func(_m): return {"k": "def_energy_shuffle", "n": 1})
	_k("The Defending Pokémon is now Burned, Paralyzed, and Poisoned\\.",
		func(_m): return {"k": "status", "conds": ["burned", "paralyzed", "poisoned"], "who": "def"})
	_m("If your opponent has only 1 Prize, choose 2 Energy cards attached to the Defending Pokémon\\. Your opponent shuffles those cards into his or her deck\\.",
		func(_m): return {"k": "def_energy_shuffle", "n": 2, "c": "opp_prizes_eq", "cn": 1})
	_m("If your opponent has exactly (\\d+) Prizes, choose 1 of your opponent's Evolved Pokémon\\. Your opponent puts the top card on that Evolved Pokémon on the bottom of his or her deck\\.",
		func(m): return {"k": "devolve_bottom", "c": "opp_prizes_eq", "cn": int(m.get_string(1))})
	_k("Shuffle your hand into your deck and then draw (\\d+) cards\\.", func(m): return {"k": "shuffle_draw", "n": int(m.get_string(1))})
	_k("Search your deck for up to (\\d+) basic Energy cards, show them to your opponent, and put them into your hand\\.",
		func(m): return {"k": "search_hand", "filter": "basic_energy", "n": int(m.get_string(1))})
	_k("Remove all damage counters from 1 of your Pokémon\\.", func(_m): return {"k": "heal_one", "n": 999})



# ===========================================================================
# Resolución
# ===========================================================================

## Energías que se pueden usar en un ataque de "cualquier cantidad" (Land Stream, Hydro Reverse).
static func any_energy_cards(me: PlayerState, attacker: PokemonInPlay, op: Dictionary) -> Array:
	var out: Array = []   # [[Pokémon, id]], primero la Banca para no vaciar al Activo
	if op["mode"] == "hand_discard":     # Crushing Mantle: Energías de la mano ([null, id])
		for e in me.hand:
			if CardDB.is_energy(e):
				out.append([null, e])
		return out
	var holders: Array = [attacker] if op["mode"] in ["discard", "discard_flips"] else me.bench.filter(func(x): return x != null) + [me.active]
	for h in holders:
		for e in h.energy:
			if op["mode"] == "discard_all_flips":
				out.append([h, e])
				continue
			if CardDB.is_basic_energy(e) and (op["etype"] == "" or CardDB.basic_energy_type(e) == op["etype"]):
				out.append([h, e])
	return out


static func resolve(g: Game, attacker: PokemonInPlay, attack: Dictionary, target: int, opt, src_id: String = "") -> void:
	var me: PlayerState = g.current_player()
	var opp: PlayerState = g.opponent_player()
	var defender: PokemonInPlay = opp.active
	var parsed := parse(src_id if src_id != "" else attacker.top(), attack)
	# Genetic Memory (Kingdra ex): usa un ataque de la carta Básica o Fase 1 que tiene debajo, sin pagarlo.
	if parsed["variable"].get("k", "") == "genetic_memory":
		if opt is Dictionary and opt.has("gm_card"):
			var inner: Dictionary = CardDB.get_card(opt["gm_card"])["attacks"][int(opt["gm_a"])]
			g.log_msg("  Uses %s from %s." % [inner["name"], CardDB.card_name(opt["gm_card"])])
			resolve(g, attacker, inner, target, opt.get("gm_opt", false), opt["gm_card"])
		return
	# Copy / Mini-Metronome: usa un ataque del Pokémon Defensor.
	if parsed["variable"].get("k", "") == "copy_def":
		if opt is Dictionary and opt.has("cp_card"):
			if parsed["variable"].get("coin", false) and not g.flip():
				g.log_msg("  The attack does nothing.")
				return
			var inner: Dictionary = CardDB.get_card(opt["cp_card"])["attacks"][int(opt["cp_a"])]
			g.log_msg("  Copies %s." % inner["name"])
			resolve(g, attacker, inner, target, opt.get("cp_opt", false), opt["cp_card"])
		return
	if parsed["unknown"] != "":
		g.log_msg("  (effect not implemented: \"%s\")" % parsed["unknown"])
	var ops: Array = parsed["ops"]
	var base := int(attack.get("damage", 0))
	# Efectos "durante tu próximo turno" de un ataque anterior (Stockpile, Focus Energy...).
	if attacker.flags.get("next_until", -1) >= g.turn_number:
		var nb: Dictionary = attacker.flags.get("next_base", {})
		if nb.has(attack["name"]):
			base = nb[attack["name"]]
		base += int(attacker.flags.get("next_bonus_attack", {}).get(attack["name"], 0))
		if base > 0:
			base += int(attacker.flags.get("next_bonus_all", 0))
	var ctx := {"coins": [], "heads": 0, "flips": 0, "did": false, "opt": opt, "dmg": base, "base": base,
			"ignore": {}, "target": target, "dealt": 0, "attack": attack}

	for op in ops:
		if _phase(op) != "pre" or not _cond_ok(g, op, ctx, me, opp, attacker, defender):
			continue
		if _pre(g, op, ctx, me, opp, attacker, defender) == false:
			g.log_msg("  The attack does nothing.")
			return
	defender = opp.active    # puede haber cambiado (ataques que traen a un Pokémon de la Banca)

	if ctx["dmg"] > 0 and defender != null:
		ctx["dealt"] = g.deal_attack_damage(attacker, defender, ctx["dmg"], true, ctx["ignore"])

	for op in ops:
		if _phase(op) != "post" or not _cond_ok(g, op, ctx, me, opp, attacker, defender):
			continue
		_post(g, op, ctx, me, opp, attacker, defender)


static func _phase(op: Dictionary) -> String:
	if op.has("phase"):
		return op["phase"]
	return "pre" if op["k"] in PRE else "post"


static func _cond_ok(g: Game, op: Dictionary, ctx: Dictionary, me: PlayerState, opp: PlayerState,
		attacker: PokemonInPlay, d: PokemonInPlay) -> bool:
	if op.get("optional", false) and not ctx["opt"]:
		return false
	var c: String = op.get("c", "")
	match c:
		"":
			return true
		"heads", "tails":
			var i: int = op.get("coin_ref", -1)
			if i < 0 or i >= ctx["coins"].size():
				return false
			return ctx["coins"][i] == (c == "heads")
		"did": return ctx["did"]
		"any_heads": return ctx["heads"] > 0 or ctx["coins"].has(true)
		"all_heads": return ctx.get("flips", 0) > 0 and ctx["heads"] == ctx["flips"]
		"all_tails": return ctx.get("flips", 0) > 0 and ctx["heads"] == 0
		"any_tails": return ctx.get("flips", 0) > 0 and ctx["heads"] < ctx["flips"]
		"heads_at_least": return ctx["heads"] >= int(op.get("n", 1))
		"self_damaged": return attacker.damage >= 10 * int(op.get("at", 1))
		"def_undamaged": return d != null and d.damage == 0
		"def_not_cond": return d == null or not d.has_condition(op["cond"])
		"def_ex": return d != null and d.is_ex()
		"def_evolved": return d != null and d.is_evolved()
		"def_damaged": return d != null and d.damage >= 10 * int(op.get("at", 1))
		"def_status": return d != null and d.has_special_condition()
		"def_cond":
			if d == null:
				return false
			match op["cond"]:
				"poisoned": return d.poison > 0
				"burned": return d.burned
				_: return d.rotation == op["cond"]
		"def_special": return d != null and d.special_energy_count() > 0
		"def_ability": return d != null and not d.abilities().is_empty()
		"def_team": return d != null and d.name_has(op["team"])
		"def_name": return d != null and d.display_name() == op["name"]
		"more_prizes": return me.prizes.size() > opp.prizes.size()
		"more_hand": return me.hand.size() > opp.hand.size()
		"same_hand": return me.hand.size() == opp.hand.size()
		"stadium": return g.stadium_name() == op["name"]
		"opp_evolved": return opp.all_in_play().any(func(x): return x.is_evolved())
		"opp_ex": return opp.all_in_play().any(func(x): return x.is_ex())
		"less_energy": return d != null and Energy.total(attacker) < Energy.total(d)
		"same_energy": return d != null and Energy.total(attacker) == Energy.total(d)
		"diff_energy": return d != null and Energy.total(attacker) != Energy.total(d)
		"no_bench": return me.bench.is_empty()
		"has_basic_types":
			for t in op["types"]:
				if not attacker.energy.any(func(e): return CardDB.card_name(e) == str(t) + " Energy"):
					return false
			return true
		"opp_prizes_min": return opp.prizes.size() >= int(op["cn"])
		"opp_prizes_eq": return opp.prizes.size() == int(op.get("cn", op.get("n", 0)))
		"less_total_energy":
			var mine := 0
			var theirs := 0
			for p in me.all_in_play():
				mine += Energy.total(p)
			for p in opp.all_in_play():
				theirs += Energy.total(p)
			return mine < theirs
		"def_fewer_hp": return d != null and d.hp_left() < attacker.hp_left()
	return false


## Devuelve false si el ataque no hace nada.
static func _pre(g: Game, op: Dictionary, ctx: Dictionary, me: PlayerState, opp: PlayerState,
		a: PokemonInPlay, d: PokemonInPlay) -> bool:
	match op["k"]:
		"return_all_basic":
			var back: Array = a.energy.filter(func(e): return CardDB.is_basic_energy(e))
			for e in back:
				a.energy.erase(e)
				me.hand.append(e)
			g.log_msg("  Returns %d Energy card(s) to the hand." % back.size())
			ctx["dmg"] = op["base"] + op["per"] * back.size()
		"burst_choice":
			var t: String = ctx["opt"] if ctx["opt"] is String else ""
			var gone: Array = a.energy.filter(func(e): return t != "" and burst_counts(e, t))
			for e in gone:
				a.energy.erase(e)
				me.discard.append(e)
			if t != "":
				g.log_msg("  Discards %d %s Energy." % [gone.size(), Game.TYPE_ES.get(t, t)])
			ctx["dmg"] = op["n"] * gone.size()
		"any_energy":
			var k: int = int(ctx["opt"]) if ctx["opt"] is int else 0
			var cards := any_energy_cards(me, a, op)
			k = mini(k, cards.size())
			for i in k:
				var h = cards[i][0]
				var e: String = cards[i][1]
				if h == null:      # de la mano
					me.hand.erase(e)
				else:
					h.energy.erase(e)
				if op["mode"] in ["discard", "hand_discard", "discard_flips", "discard_all_flips"]:
					me.discard.append(e)
				else:
					me.hand.append(e)
			if k > 0:
				g.log_msg("  %s %d Energy card(s)." % [{"discard": "Discards", "hand_discard": "Discards from hand"}.get(op["mode"], "Returns to hand"), k])
			if op["mode"] in ["discard_flips", "discard_all_flips"]:
				ctx["dmg"] = op["base"] + op["per"] * g.flip_many(k)
			else:
				ctx["dmg"] = op["base"] + op["per"] * k
		"coin":
			ctx["coins"].append(g.flip())
		"flips":
			var count = op["count"]
			if count is String:
				match count:
					"self_energy":
						var et: String = op.get("etype", "")
						count = Energy.total(a) if et == "" else Energy.count_type(a, et)
					"my_pokemon": count = me.all_in_play().size()
					"def_counters": count = d.damage / 10 if d != null else 0
					"self_counters": count = a.damage / 10
					"def_energy": count = Energy.total(d) if d != null else 0
					"bench_energy":
						count = 0
						for b in me.bench:
							count += Energy.total(b)
			count = min(int(count), int(op.get("cap", 99)))
			var heads := g.flip_many(count)
			ctx["heads"] = heads
			ctx["flips"] = count
			match op["mode"]:
				"times": ctx["dmg"] = op["n"] * heads
				"plus": ctx["dmg"] += op["n"] * heads
				"all_or_each": ctx["dmg"] += op["all"] if heads == count else op["n"] * heads
				"table", "set_table":          # lo que pasa según cuántas caras salieron
					var tb: Array = op["table"]
					var v = tb[mini(heads, tb.size() - 1)]
					if v is String and v == "nothing":
						return false
					if op["mode"] == "table":
						ctx["dmg"] += int(v)
					else:
						ctx["dmg"] = int(v)
		"until_tails":
			var heads := 0
			while g.flip():
				heads += 1
			ctx["heads"] = heads
			if op.get("mode", "times") == "plus":
				ctx["dmg"] += op["n"] * heads
			else:
				ctx["dmg"] = op["n"] * heads
		"nothing":
			return false
		"discard_bonus":
			var n_d := 0
			for e in a.energy.duplicate():
				if CardDB.card_name(e) == op["etype"] + " Energy":
					a.energy.erase(e)
					me.discard.append(e)
					n_d += 1
			g.log_msg("  Discards %d Energy card(s)." % n_d)
			ctx["dmg"] += op["per"] * (g.flip_many(n_d) if op["mode"] == "flips" else n_d)
		"bonus_table":
			var tb: Array = op["table"]
			ctx["dmg"] += int(tb[mini(ctx["heads"], tb.size() - 1)])
		"discard_one_bonus":
			if a.energy.is_empty():
				return false
			var e1: String = a.energy[0]
			for e in a.energy:
				if CardDB.card_name(e) == op["etype"] + " Energy":
					e1 = e
			a.energy.erase(e1)
			me.discard.append(e1)
			if CardDB.card_name(e1) == op["etype"] + " Energy":
				ctx["dmg"] += op["n"]
		"lava_choice":
			if ctx["opt"]:
				for et in [op["b"], op["a"]]:      # Lucha primero: daño seguro; si no hay, Fuego
					var ee := ""
					for e in a.energy:
						if CardDB.card_name(e) == et + " Energy":
							ee = e
					if ee != "":
						a.energy.erase(ee)
						me.discard.append(ee)
						if et == op["a"]:
							ctx["lava_cond"] = op["cond"]
						else:
							ctx["dmg"] += op["n"]
						break
		"discard_to_counters":
			if ctx["opt"]:
				var n_c := 0
				for e in a.energy.duplicate():
					if CardDB.card_name(e) == op["etype"] + " Energy":
						a.energy.erase(e)
						me.discard.append(e)
						n_c += 1
				if n_c > 0 and not opp.bench.is_empty():
					AttackEffects._ask_bench_counters(g, me, opp, n_c)
		"mill_both_bonus":
			for pl in [opp, me]:
				if not pl.deck.is_empty():
					var c: String = pl.deck.pop_back()
					pl.discard.append(c)
					g.log_msg("  Discards %s from the top of the deck." % CardDB.card_name(c))
					if CardDB.card_name(c) == op["etype"] + " Energy":
						ctx["dmg"] += op["per"]
		"bonus":
			ctx["dmg"] += op["n"]
			if op.get("optional", false):
				ctx["did"] = true
		"set_base":
			ctx["dmg"] = op["n"]
		"base_or_extra":
			if ctx["base"] == 0:
				ctx["dmg"] = op["n"]
		"formula":
			var x := _formula_value(g, op, ctx, me, opp, a, d)
			match op["mode"]:
				"times": ctx["dmg"] = op["n"] * x
				"plus": ctx["dmg"] += min(op["n"] * x, int(op.get("cap", 999)))
				"minus": ctx["dmg"] = max(0, ctx["dmg"] - op["n"] * x)
		"ignore":
			ctx["ignore"] = op
		"discard_self":
			if op.get("per_tails", false):
				var o2: Dictionary = op.duplicate()
				o2["count"] = ctx["flips"] - ctx["heads"]
				if o2["count"] <= 0:
					return true
				_discard_own_energy(me, a, o2)
				return true
			var ok := _discard_own_energy(me, a, op)
			ctx["did"] = ok
			if not ok and op.get("or_nothing", false):
				return false
		"heal_def":
			if d != null:
				d.damage = max(0, d.damage - 10 * op["n"])
		"gust":
			var t: PokemonInPlay = opp.slot(ctx["target"]) if ctx["target"] >= 0 else null
			if t != null and opp.active != null:
				g.log_msg("  %s moves to the Active Spot." % t.display_name())
				g.switch_active(opp, ctx["target"])
				ctx["target"] = -2
		"strip_def_trainers":
			if d != null:
				_strip_trainers(opp, d)
		"mill_count":
			var hits := 0
			var seen: Array = []
			for i in op["count"]:
				if me.deck.is_empty():
					break
				var c: String = me.deck.pop_back()
				me.discard.append(c)
				seen.append(CardDB.card_name(c))
				if CardDB.is_basic_energy(c) and CardDB.basic_energy_type(c) in op["types"]:
					hits += 1
			g.log_msg("  Discards from the deck: %s." % ", ".join(seen))
			ctx["dmg"] = op["n"] * hits
		"tidal":
			var es: Array = me.hand.filter(func(c): return CardDB.is_energy(c))
			g.log_msg("  Shows their hand: %s." % ", ".join(me.hand.map(func(c): return CardDB.card_name(c))))
			ctx["dmg"] += op["per"] * es.size()
			for e in es:
				me.hand.erase(e)
				me.deck.append(e)
			if not es.is_empty():
				g.log_msg("  Shuffles %d Energy card(s) into the deck." % es.size())
				g.shuffle(me.deck)
	return true


static func _formula_value(g: Game, op: Dictionary, ctx: Dictionary, me: PlayerState, opp: PlayerState,
		a: PokemonInPlay, d: PokemonInPlay) -> int:
	match op["f"]:
		"opp_hand_energy": return opp.hand.filter(func(c): return CardDB.is_energy(c)).size()
		"my_damaged": return me.all_in_play().filter(func(p): return p.damage > 0).size()
		"bench_diff_opp": return maxi(0, opp.bench.size() - me.bench.size())
		"bench_diff_mine": return maxi(0, me.bench.size() - opp.bench.size())
		"my_pokemon": return me.all_in_play().size()
		"def_special": return d.special_energy_count() if d != null else 0
		"bench_named":
			var names: Array = []
			for x in op["names"]:
				names.append(a.display_name() if x == "SELF" else str(x))
			return me.bench.filter(func(p): return p.display_name() in names).size()
		"own_counters": return a.damage / 10
		"def_counters": return d.damage / 10 if d != null else 0
		"def_energy": return Energy.total(d) if d != null else 0
		"self_energy":
			var et: String = op.get("etype", "")
			return Energy.total(a) if et == "" else Energy.count_type(a, et)
		"my_energy":
			var n := 0
			for p in me.all_in_play():
				n += Energy.total(p)
			return n
		"all_energy", "opp_energy":
			var n := 0
			for pl in (g.players if op["f"] == "all_energy" else [opp]):
				for p in pl.all_in_play():
					n += Energy.total(p)
			return n
		"both_energy": return Energy.total(a) + (Energy.total(d) if d != null else 0)
		"both_basic_energy": return a.basic_energy_count() + (d.basic_energy_count() if d != null else 0)
		"extra_energy": return Energy.extra_units(a, ctx["attack"].get("cost", []), op.get("etype", ""))
		"opp_hand": return opp.hand.size()
		"my_bench": return me.bench.size()
		"def_retreat": return d.base_retreat_cost() if d != null else 0
		"self_energy_types": return _energy_types(a)
		"def_energy_types": return _energy_types(d) if d != null else 0
		"psychic_in_play":
			var n := 0
			for pl in g.players:
				for p in pl.all_in_play():
					n += Energy.count_type(p, "Psychic")
			return n
		"darkness_pokemon":
			var n := 0
			for pl in g.players:
				n += pl.count_in_play(func(p): return p.is_type("Darkness"))
			return n
		"team_magma":
			var n := 0
			for pl in g.players:
				n += pl.count_in_play(func(p): return p.name_has("Team Magma"))
			return n
		"opp_discard_special":
			return opp.discard.filter(func(c): return CardDB.is_energy(c) and not CardDB.is_basic_energy(c)).size()
	return 0


static func _energy_types(p: PokemonInPlay) -> int:
	var ts := {}
	for e in p.energy:
		if CardDB.is_basic_energy(e):
			ts[CardDB.basic_energy_type(e)] = true
	return ts.size()


static func _post(g: Game, op: Dictionary, ctx: Dictionary, me: PlayerState, opp: PlayerState,
		a: PokemonInPlay, d: PokemonInPlay) -> void:
	var blocked := d != null and Abilities.blocks_effects(g, a, d)
	match op["k"]:
		"coin":
			ctx["coins"].append(g.flip())
		"lava_status":
			if ctx.has("lava_cond") and d != null:
				g.try_condition(d, ctx["lava_cond"])
		"status":
			if op["who"] == "self":
				for c in op["conds"]:
					g.try_condition(a, c)
			elif d != null and not blocked:
				for c in op["conds"]:
					g.try_condition(d, c)
		"poison_counters":
			if d != null and d.poison > 0:
				d.poison = op["n"]
		"delayed_status":
			if d != null and not blocked:
				d.flags["delayed_status"] = [op["cond"], g.turn_number + 1]
		"ko_def":
			if d != null and not blocked:
				d.damage = d.max_hp()
				g.log_msg("  %s is Knocked Out!" % d.display_name())
		"double_coin_ko":
			if g.flip_many(2) == 2 and d != null and not blocked:
				d.damage = d.max_hp()
		"set_def_hp":
			if d != null and not blocked and d.hp_left() > op["n"]:
				d.damage = d.max_hp() - op["n"]
		"flag_def":
			if d != null and not blocked:
				d.flags[op["flag"]] = g.turn_number + 1
		"flag_self":
			a.flags[str(op["flag"]).replace("ATTACK", str(ctx["attack"].get("name", "")))] = g.turn_number + int(op.get("turns", 1))
		"reduce_self":
			a.flags["reduce_by"] = op["n"]
			a.flags["reduce_until"] = g.turn_number + 1
		"disable_attack":
			if d != null and not blocked and not d.attacks().is_empty():
				var opts: Array = []
				for atk in d.attacks():
					opts.append({"label": "%s (%s)" % [atk["name"], atk.get("damage_text", "") if atk.get("damage_text", "") != "" else "—"],
							"name": atk["name"], "ai": float(int(atk.get("damage", 0)))})
				var until := g.turn_number + 1
				g.ask(me.index, "Which attack of %s do you block?" % d.display_name(), opts, func(o):
					d.flags["disabled_attack"] = [o["name"], until]
					g.log_msg("  %s can't use %s." % [d.display_name(), o["name"]]))
		"flip_energy":
			var src := opp.slot(ctx["target"])
			if src != null and src.hp_left() > 0 and not src.energy.is_empty() and opp.all_in_play().size() > 1:
				var opts: Array = []
				for e in _distinct_list(src.energy):
					for s2 in opp.slots():
						if opp.slot(s2) != src:
							opts.append({"label": "%s → %s" % [CardDB.card_name(e).replace(" Energy", ""), g.slot_name(opp, s2)],
									"id": e, "s": s2, "opp": true, "ai": 1.0 if s2 != -1 else 0.2})
				g.ask(me.index, "Energy Flip: move an Energy from %s" % src.display_name(), opts, func(o):
					var to := opp.slot(o["s"])
					if to != null and src.energy.has(o["id"]) and opp.all_in_play().has(src):   # si quedó KO, no hay nada que mover
						src.energy.erase(o["id"])
						to.energy.append(o["id"])
						g.log_msg("  Moves %s to %s." % [CardDB.card_name(o["id"]), to.display_name()]))
		"discard_def_energy":
			var t := d
			if op.get("that", false) and opp.slot(ctx["target"]) != null:
				t = opp.slot(ctx["target"])
			if t != null and not Abilities.blocks_effects(g, a, t):
				for i in op["count"]:
					_discard_defender_energy(g, opp, t, op.get("special", false))
		"mass_destruction":
			if a.special_energy_count() > 0:
				g.log_msg("  It has Special Energy: the attack does nothing.")
			else:
				a.damage = a.max_hp()
				if d != null and not blocked:
					d.damage = d.max_hp()
		"opp_hand_trim":
			if opp.hand.size() >= op["min"]:
				while opp.hand.size() > op["keep"]:
					var i := g.rng.randi_range(0, opp.hand.size() - 1)
					if op["to"] == "deck":
						# Se eligen mirando: las cartas más valiosas.
						var best := 0
						for j in opp.hand.size():
							if Trainers._ai_value(opp.hand[j]) > Trainers._ai_value(opp.hand[best]):
								best = j
						i = best
					var c: String = opp.hand[i]
					opp.hand.remove_at(i)
					if op["to"] == "deck":
						opp.deck.append(c)
					else:
						opp.discard.append(c)
					g.log_msg("  The opponent loses %s." % CardDB.card_name(c))
				if op["to"] == "deck":
					g.shuffle(opp.deck)
		"time_spiral":
			var evolved := opp.all_in_play().filter(func(x): return x.is_evolved())
			if not evolved.is_empty():
				evolved.sort_custom(func(x, y): return x.cards.size() > y.cards.size())
				var t: PokemonInPlay = evolved[0]
				if g.flip():
					var c: String = t.cards.pop_back()
					opp.deck.append(c)
					g.shuffle(opp.deck)
					t.clear_conditions()
					g.log_msg("  %s devolves." % CardDB.card_name(c))
		"wurmple":
			for pair in [["Silcoon", "Beautifly"], ["Cascoon", "Dustox"]]:
				var found := false
				for nm in pair:
					var i := me.deck.find(CardDB.find(nm)) if CardDB.find(nm) != "" else -1
					for j in me.deck.size():
						if CardDB.card_name(me.deck[j]) == nm:
							i = j
							break
					if i != -1:
						me.hand.append(me.deck[i])
						me.deck.remove_at(i)
						g.log_msg("  Searches for %s." % nm)
						found = true
				if found:
					break
			g.shuffle(me.deck)
		"energy_retrieval":
			var opts: Array = []
			for sl in me.slots():
				opts.append({"label": me.slot(sl).display_name(), "s": sl, "ai": 1.0 if sl == -1 else 0.5})
			var n: int = op["n"]
			g.ask(me.index, "Attach Energy from the discard pile to...", opts, func(o):
				var t := me.slot(o["s"])
				for i in n:
					var e := Abilities._take(me.discard, func(c): return CardDB.is_basic_energy(c))
					if e == "":
						break
					t.energy.append(e)
					t.damage += 10)
		"attach_multi":
			_ask_attach_multi(g, me, op["types"], op["n"], op["active_only"])
		"fruition":
			if not a.energy.is_empty() and me.all_in_play().size() > 1:
				var opts: Array = []
				for sl in me.slots():
					if me.slot(sl) != a:
						opts.append({"label": me.slot(sl).display_name(), "s": sl, "ai": float(me.slot(sl).damage)})
				var n: int = op["n"]
				g.ask(me.index, "Move 1 Energy to...", opts, func(o):
					var t := me.slot(o["s"])
					t.energy.append(a.energy.pop_back())
					t.damage = max(0, t.damage - 10 * n))
		"search_stadium":
			var cands := Trainers._distinct(me.deck, func(c): return CardDB.is_stadium(c))
			if not cands.is_empty():
				g.ask(me.index, "Choose a Stadium", Trainers._card_options(cands, false), func(o):
					me.deck.erase(o["id"])
					g.set_stadium(me, o["id"])
					g.log_msg("  Plays %s." % CardDB.card_name(o["id"]))
					g.shuffle(me.deck))
		"make_a_wish":
			var opts: Array = []
			for sl in me.slots():
				var p := me.slot(sl)
				for c in Trainers._distinct(me.deck, func(x): return CardDB.evolves_from(x) == p.display_name()):
					opts.append({"label": "%s → %s" % [p.display_name(), CardDB.card_name(c)], "s": sl, "id": c, "ai": 2.0})
			if not opts.is_empty():
				g.ask(me.index, "Evolve", opts, func(o):
					me.deck.erase(o["id"])
					g.evolve(me, me.slot(o["s"]), o["id"])
					g.shuffle(me.deck))
		"scam":
			g.log_msg("  Looks at the opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
			for i in opp.hand.size():
				if CardDB.is_supporter(opp.hand[i]):
					var c: String = opp.hand[i]
					opp.hand.remove_at(i)
					opp.deck.append(c)
					g.shuffle(opp.deck)
					opp.draw(1)
					g.log_msg("  %s goes back into the opponent's deck; the opponent draws 1." % CardDB.card_name(c))
					break
		"next_turn":
			a.flags["next_until"] = g.turn_number + 2
			if op.has("base"):
				a.flags["next_base"] = op["base"]
			if op.has("bonus_attack"):
				a.flags["next_bonus_attack"] = op["bonus_attack"]
			if op.has("bonus_all"):
				a.flags["next_bonus_all"] = op["bonus_all"]
		"return_def_energy":
			if d != null and not blocked and not d.energy.is_empty():
				var e: String = d.energy.pop_back()
				opp.hand.append(e)
				g.log_msg("  %s returns to the opponent's hand." % CardDB.card_name(e))
		"opp_hand_pick":
			if not opp.hand.is_empty():
				g.log_msg("  Looks at the opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
				g.ask(me.index, "Choose a card to discard", Trainers._card_options(opp.hand, true), func(o):
					opp.hand.erase(o["id"])
					opp.discard.append(o["id"]))
		"def_energy_to_deck":
			if d != null and not blocked and not d.energy.is_empty():
				var e: String = d.energy.pop_back()
				opp.deck.insert(0, e)
				g.log_msg("  %s goes to the bottom of the opponent's deck." % CardDB.card_name(e))
		"self_damage":
			var sd: int = op["n"]
			if op.get("per", "") == "my_bench":
				sd = op["each"] * me.bench.size()
			if op.get("per", "") == "self_etype":
				sd = op["each"] * Energy.count_type(a, op["etype"])
			if op.get("per_heads", false):
				sd *= ctx["heads"] + ctx["coins"].count(true)
			a.damage += sd
			g.log_msg("  %s does %d damage to itself." % [a.display_name(), sd])
		"heal_self":
			if op.get("if_dealt", false) and ctx["dealt"] <= 0:
				return
			var hn: int = op["n"] * (ctx["heads"] if op.get("per_heads", false) else 1)
			if op.get("per_energy", false):
				hn = op["n"] * Energy.total(a)
			a.damage = max(0, a.damage - 10 * hn)
		"clear_self":
			a.clear_conditions()
		"heal_mine":
			for p in me.all_in_play():
				if op.get("skip_self", false) and p == a:
					continue
				if op.get("grass_only", false) and Energy.count_type(p, "Grass") == 0:
					continue
				if op.get("same_type", false) and p != a and not p.types().any(func(t): return t in a.types()):
					continue
				var hm: int = op["n"] * (ctx["heads"] if op.get("per_heads", false) else 1)
				p.damage = max(0, p.damage - 10 * hm)
		"heal_one":
			var worst: PokemonInPlay = null
			for p in me.all_in_play():
				if op.get("with_energy", false) and p.energy.is_empty():
					continue
				if worst == null or p.damage > worst.damage:
					worst = p
			if worst != null:
				worst.damage = max(0, worst.damage - 10 * op["n"])
		"drain":
			a.damage = max(0, a.damage - ctx["dealt"])
		"snipe":
			var t: PokemonInPlay = opp.slot(ctx["target"])
			if t != null:
				var n: int = op["n"]
				match op.get("if", ""):
					"ability":
						if not t.abilities().is_empty():
							n = op["n_if"]
					"ex":
						if t.is_ex():
							n = op["n_if"]
				if op.get("per_retreat", false):
					n *= t.base_retreat_cost()
				if op.get("per_heads", false):
					n *= ctx["heads"]
				if op.has("per_self_etype"):
					n *= Energy.count_type(a, op["per_self_etype"])
				g.deal_attack_damage(a, t, n, t == opp.active, ctx["ignore"])
		"multi_bench":
			_ask_bench_targets(g, me, opp, a, op["count"], op["n"], ctx["ignore"])
		"spread":
			for t in _spread_targets(op["scope"], me, opp):
				var is_opp_active: bool = t == opp.active
				g.deal_attack_damage(a, t, op["n"], is_opp_active, ctx["ignore"] if is_opp_active else {})
		"counters":
			var n: int = op["n"]
			match op.get("per", ""):
				"opp_hand": n = opp.hand.size()
				"my_discard_pokemon": n = me.discard.filter(func(c): return CardDB.is_pokemon(c)).size()
				"self_counters_plus1": n = 1 + a.damage / 10
				"target_energy":
					var tt: PokemonInPlay = opp.slot(ctx["target"]) if ctx["target"] >= 0 or ctx["target"] == -1 else opp.active
					n = Energy.total(tt) if tt != null else 0
				"my_damaged": n = me.all_in_play().filter(func(p): return p.damage > 0).size()
			if op.has("cap"):
				n = mini(n, op["cap"])
			for t in _counter_targets(op["to"], opp, ctx["target"]):
				if not Abilities.blocks_effects(g, a, t):
					t.damage += 10 * n
					g.log_msg("  %d damage counter(s) on %s." % [n, t.display_name()])
		"distribute":
			var total: int = op.get("total", 0)
			if op["flips"] > 0:
				total = g.flip_many(op["flips"]) * op["n"]
			_ask_counters(g, me, opp, a, total)
		"opp_switch":
			if d != null and not blocked and not opp.bench.is_empty():
				g.queue_choice(opp.index, "switch")
		"self_switch":
			if not me.bench.is_empty():
				g.queue_choice(me.index, "switch")
		"return_def":
			if d != null and not blocked and not opp.bench.is_empty():
				g.return_to_hand(opp, d)
		"devolve_opp":
			for p in opp.all_in_play():
				if p.is_evolved():
					var c: String = p.cards.pop_back()
					opp.hand.append(c)
					p.clear_conditions()
					g.log_msg("  %s devolves." % CardDB.card_name(c))
		"strip_def_trainers":
			if d != null:
				_strip_trainers(opp, d)
		"def_energy_shuffle":
			if d != null and not blocked and not d.energy.is_empty():
				for i in mini(int(op["n"]), d.energy.size()):
					var e: String = d.energy.pop_back()
					opp.deck.append(e)
					g.log_msg("  %s is shuffled into the opponent's deck." % CardDB.card_name(e))
				g.shuffle(opp.deck)
		"devolve_bottom":
			var evos: Array = opp.all_in_play().filter(func(x): return x.is_evolved())
			if not evos.is_empty():
				var opts: Array = []
				for x in evos:
					opts.append({"label": x.display_name(), "mon": x, "ai": float(CardDB.stage(x.top()))})
				g.ask(me.index, "Choose an Evolved Pokémon to devolve", opts, func(o):
					var x: PokemonInPlay = o["mon"]
					if x.is_evolved():
						var c: String = x.cards.pop_back()
						opp.deck.insert(0, c)
						x.clear_conditions()
						g.log_msg("  %s goes to the bottom of the deck." % CardDB.card_name(c)))
		"draw":
			me.draw(op["n"])
		"draw_to_opp":
			me.draw(max(0, opp.hand.size() - me.hand.size()))
		"draw_opp_basics":
			me.draw(opp.count_in_play(func(p): return p.is_basic()))
		"shuffle_draw":
			me.deck.append_array(me.hand)
			me.hand.clear()
			g.shuffle(me.deck)
			me.draw(op["n"])
		"bench_search":
			var pred := func(c): return CardDB.is_basic_pokemon(c)
			if op.has("names"):
				var names: Array = op["names"].map(func(x): return a.display_name() if x == "NAME" else x)
				var any_basic: bool = op.get("any_basic", false)
				pred = func(c): return CardDB.is_pokemon(c) and (CardDB.card_name(c) in names or (any_basic and CardDB.is_basic_pokemon(c)))
			elif op.get("same", false):
				var nm := a.display_name()
				pred = func(c): return CardDB.card_name(c) == nm
			elif op["type"] != "":
				var ty: String = op["type"]
				var team: String = op["team"]
				pred = func(c): return CardDB.is_basic_pokemon(c) and (ty in CardDB.types(c) or (team != "" and CardDB.card_name(c).contains(team)))
			# El jugador elige qué Pokémon poner (de a uno, "Listo" para parar: dice "hasta").
			Trainers.chain(g, me.index, "Choose a Pokémon for the Bench", op["n"],
					func(_p): return Trainers._distinct(me.deck, pred) if me.bench.size() < g.rules.bench_size else [], true,
					func(id):
						me.deck.erase(id)
						me.bench.append(PokemonInPlay.new(id, g.turn_number))
						g.log_msg("  Puts %s on the Bench." % CardDB.card_name(id)),
					func(): g.shuffle(me.deck))
		"self_evolve":
			var nm := a.display_name()
			var idx := g.best_in_deck(me, func(c): return CardDB.evolves_from(c) == nm)
			if idx != -1:
				var evo: String = me.deck[idx]
				me.deck.remove_at(idx)
				g.evolve(me, a, evo)
			g.shuffle(me.deck)
		"search_hand":
			var sn: int = Energy.total(a) if op["n"] == -1 else op["n"]
			if op.get("per_heads", false):
				sn = ctx["heads"] + ctx["coins"].count(true)
			_ask_search(g, me, a, op["filter"], sn, [])
		"recover":
			_ask_recover(g, me, op["filter"], op["n"])
		"opp_hand_random":
			if not opp.hand.is_empty():
				var i := g.rng.randi_range(0, opp.hand.size() - 1)
				var c: String = opp.hand[i]
				opp.hand.remove_at(i)
				if op["to"] == "deck":
					opp.deck.append(c)
					g.shuffle(opp.deck)
				else:
					opp.discard.append(c)
				g.log_msg("  The opponent loses %s from their hand." % CardDB.card_name(c))
		"discard_stadium":
			g.discard_stadium()
		"attach":
			_attach(g, me, a, op)
		"until_tails_attach":
			while g.flip():
				var e := Abilities._take(me.discard, func(c): return CardDB.is_basic_energy(c))
				if e == "":
					break
				a.energy.append(e)
		"top_energy":
			if not me.deck.is_empty():
				var c: String = me.deck.pop_back()
				g.log_msg("  Discards %s from the deck." % CardDB.card_name(c))
				if CardDB.is_basic_energy(c):
					a.energy.append(c)
				else:
					me.discard.append(c)
		"move_energy_bench":
			if not me.bench.is_empty():
				var et: String = op["etype"]
				var idx := -1
				for i in a.energy.size():
					if CardDB.card_name(a.energy[i]) == et + " Energy" or (et == "" and CardDB.is_basic_energy(a.energy[i])):
						idx = i
				if idx != -1:
					var e: String = a.energy[idx]
					var opts: Array = []
					for b in me.bench.size():
						opts.append({"label": me.bench[b].display_name(), "b": b, "ai": float(-Energy.total(me.bench[b]))})
					g.ask(me.index, "Move %s to..." % CardDB.card_name(e), opts, func(o):
						a.energy.erase(e)
						me.bench[o["b"]].energy.append(e))
		"choose_condition":
			if d != null and not blocked:
				var opts: Array = []
				for k in STATUS:
					opts.append({"label": Game.COND_ES[STATUS[k]], "cond": STATUS[k], "ai": 2.0 if k == "Paralyzed" else 1.0})
				g.ask(me.index, "Choose a Special Condition", opts, func(o): g.try_condition(d, o["cond"]))
		"ice_generator":
			var any := false
			for p in opp.all_in_play():
				if p.tool != "" or p.tm != "":
					_strip_trainers(opp, p)
					any = true
			if g.stadium_owner == opp.index and g.stadium != "":
				g.discard_stadium()
				any = true
			if any:
				a.flags["prevent_all"] = g.turn_number + 1
		"lizard_poison":
			if d != null and not blocked:
				var e := Energy.total(a)
				var conds: Array = []
				match e:
					0: conds = []
					1: conds = ["asleep"]
					2: conds = ["poisoned"]
					3: conds = ["asleep", "poisoned"]
					_: conds = ["asleep", "burned", "poisoned"]
				for c in conds:
					g.try_condition(d, c)
		"use_supporter":
			_use_supporter(g, me, opp, op)
		"quick_touch":
			if not me.bench.is_empty() and me.active == a:
				var opts: Array = []
				for b in me.bench.size():
					opts.append({"label": "Switch with " + me.bench[b].display_name(), "b": b, "ai": float(me.bench[b].hp_left())})
				var et: String = op["etype"]
				g.ask(me.index, "Quick Touch: switch with which Pokémon?", opts, func(o):
					if me.active != a:
						return
					g.switch_active(me, o["b"])
					Trainers.chain(g, me.index, "Move %s Energy to the new Active Pokémon" % Game.TYPE_ES.get(et, et), 99,
							func(_p): return Trainers._distinct(a.energy, func(e): return CardDB.is_basic_energy(e) and CardDB.basic_energy_type(e) == et) if me.bench.has(a) else [],
							true,
							func(id):
								a.energy.erase(id)
								me.active.energy.append(id)
								g.log_msg("  Moves %s to %s." % [CardDB.card_name(id), me.active.display_name()]),
							func(): pass))
		"bench_pick_dmg":
			if not opp.bench.is_empty():
				_ask_bench_targets(g, me, opp, a, 1, op["n"], {})
		"discard_tail_table":
			var tails: int = ctx["flips"] - ctx["heads"]
			if tails >= 1:
				var o3 := {"count": 99 if tails >= 2 else 2, "etype": ""}
				_discard_own_energy(me, a, o3)
		"return_self":
			if not me.bench.is_empty() and me.active == a:
				var keep: Array = a.energy.filter(func(e): return not CardDB.is_basic_energy(e))
				a.energy = a.energy.filter(func(e): return CardDB.is_basic_energy(e))
				me.discard.append_array(keep)
				g.return_to_hand(me, a)
		"evolve_from_deck":
			var evo := Abilities._take(me.deck, func(c): return CardDB.evolves_from(c) == a.display_name())
			if evo != "":
				g.evolve(me, a, evo)
			g.shuffle(me.deck)
		"evolve_from_hand":
			var evo2 := Abilities._take(me.hand, func(c): return CardDB.card_name(c) == op["name"] and CardDB.evolves_from(c) != "")
			if evo2 != "":
				g.evolve(me, a, evo2)
		"peek_opp":
			pass      # mirar el mazo del rival no cambia nada para la IA ni la partida
		"opp_hand_to_deck":
			var pred2 := _search_pred(op["filter"], a, [])
			if op["filter"] == "energy":
				pred2 = func(c): return CardDB.is_energy(c)
			var found: Array = opp.hand.filter(pred2)
			if op.get("all", false):
				for c in found:
					opp.hand.erase(c)
					opp.deck.append(c)
				if not found.is_empty():
					g.shuffle(opp.deck)
					g.log_msg("  %d card(s) shuffled into the opponent's deck." % found.size())
			elif not found.is_empty():
				g.ask(me.index, "Shuffle into the opponent's deck", Trainers._card_options(Trainers._distinct(found, func(_c): return true), false), func(o):
					opp.hand.erase(o["id"])
					opp.deck.append(o["id"])
					g.shuffle(opp.deck))
		"bounce_off":
			if d != null and Energy.total(a) != Energy.total(d):
				var loser: PlayerState = me if Energy.total(a) < Energy.total(d) else opp
				if not loser.bench.is_empty():
					g.queue_choice(loser.index, "switch")
		"move_def_energy":
			if d != null and not opp.bench.is_empty():
				var es: Array = d.energy.filter(func(e): return not op.get("basic", false) or CardDB.is_basic_energy(e))
				if not es.is_empty():
					var opts5: Array = []
					for e in _distinct_list(es):
						for b in opp.bench.size():
							opts5.append({"label": "%s → %s" % [CardDB.card_name(e).replace(" Energy", ""), opp.bench[b].display_name()], "id": e, "b": b, "opp": true, "ai": 1.0})
					g.ask(me.index, "Move an Energy from %s" % d.display_name(), opts5, func(o):
						if opp.all_in_play().has(d) and d.energy.has(o["id"]) and o["b"] < opp.bench.size():
							d.energy.erase(o["id"])
							opp.bench[o["b"]].energy.append(o["id"]))
		"gust_after":
			if ctx["opt"] and opp.active != null and opp.active.hp_left() > 0 and not opp.bench.is_empty():
				var opts6: Array = []
				for b in opp.bench.size():
					opts6.append({"label": opp.bench[b].display_name(), "b": b, "opp": true, "ai": float(-opp.bench[b].hp_left())})
				g.ask(me.index, "Switch the Defending Pokémon with...", opts6, func(o):
					if o["b"] < opp.bench.size():
						g.switch_active(opp, o["b"]))
		"spread_heads":
			var hh: int = g.flip_many(2) if ctx["flips"] == 0 else int(ctx["heads"])
			var tt: int = (2 if ctx["flips"] == 0 else int(ctx["flips"])) - hh
			for t in opp.bench:
				g.deal_attack_damage(a, t, op["n"] * hh, false, {})
			for t in me.bench:
				g.deal_attack_damage(a, t, op["n"] * tt, false, {})
		"spread_coin":
			for t in opp.bench + me.bench:
				if g.flip():
					g.deal_attack_damage(a, t, op["n"], false, {})
		"top_pick":
			var top: Array = me.deck.slice(maxi(0, me.deck.size() - op["n"]))
			if not top.is_empty():
				g.ask(me.index, "Take 1 card", Trainers._card_options(top, false), func(o):
					me.deck.erase(o["id"])
					me.hand.append(o["id"])
					g.shuffle(me.deck))
		"hand_cycle":
			var opts2: Array = [{"label": "Don't discard", "n": 0, "ai": 0.5}]
			for k2 in range(1, mini(op["n"], me.hand.size()) + 1):
				opts2.append({"label": "Discard %d, draw %d" % [k2, k2], "n": k2, "ai": 0.0})
			g.ask(me.index, "Discard cards?", opts2, func(o):
				AttackEffects._hand_cycle(g, me, o["n"], o["n"]))
		"attach_hand_self":
			for i in op["n"]:
				var e := Abilities._take(me.hand, func(c): return CardDB.is_basic_energy(c) and (op["etype"] == "" or CardDB.card_name(c) == op["etype"] + " Energy"))
				if e == "":
					break
				a.energy.append(e)
				Abilities.on_energy_from_hand(g, me, a, e)
		"move_energy_any":
			var opts3: Array = []
			for s1 in me.slots():
				var p1 := me.slot(s1)
				for e in p1.energy:
					if not CardDB.is_basic_energy(e):
						continue
					for s2 in me.slots():
						if s2 != s1:
							opts3.append({"label": "%s: %s → %s" % [CardDB.card_name(e).replace(" Energy", ""), p1.display_name(), me.slot(s2).display_name()],
									"a": s1, "b": s2, "id": e, "ai": 1.0 if s2 == -1 else 0.2})
			if not opts3.is_empty():
				opts3.append({"label": "Don't move", "a": 0, "b": 0, "id": "", "ai": 0.0})
				g.ask(me.index, "Move an Energy", opts3, func(o):
					if o["id"] != "" and me.slot(o["a"]) != null and me.slot(o["b"]) != null:
						me.slot(o["a"]).energy.erase(o["id"])
						me.slot(o["b"]).energy.append(o["id"]))
		"opp_flag":
			opp.flags[op["flag"]] = g.turn_number + 1
		"discard_opp_any_energy":
			var opts4: Array = []
			for s1 in opp.slots():
				var p1 := opp.slot(s1)
				for e in p1.energy:
					opts4.append({"label": "%s (%s)" % [CardDB.card_name(e), p1.display_name()], "s": s1, "id": e, "ai": 1.0 if s1 == -1 else 0.5})
			if not opts4.is_empty():
				g.ask(me.index, "Discard an Energy", opts4, func(o):
					var p2 := opp.slot(o["s"])
					if p2 != null and p2.energy.has(o["id"]):
						p2.energy.erase(o["id"])
						opp.discard.append(o["id"]))
		"discard_to_top":
			if not me.discard.is_empty():
				g.ask(me.index, "Put on top of your deck", Trainers._card_options(Trainers._distinct(me.discard, func(_c): return true), false), func(o):
					me.discard.erase(o["id"])
					me.deck.append(o["id"]))
		"discard_to_deck":
			var cands := Trainers._distinct(me.discard, _search_pred(op["filter"], a, []))
			if not cands.is_empty():
				g.ask(me.index, "Shuffle into your deck", Trainers._card_options(cands, false), func(o):
					me.discard.erase(o["id"])
					me.deck.append(o["id"])
					g.shuffle(me.deck))
		"mill_self":
			for i in op["n"]:
				if me.deck.is_empty():
					break
				var c: String = me.deck.pop_back()
				me.discard.append(c)
				g.log_msg("  Discards %s from the top of the deck." % CardDB.card_name(c))
		"mill_opp":
			for i in op["n"]:
				if opp.deck.is_empty():
					break
				var c: String = opp.deck.pop_back()
				opp.discard.append(c)
				g.log_msg("  Discards %s from the opponent's deck." % CardDB.card_name(c))
		"push_aside":
			if not opp.hand.is_empty():
				g.log_msg("  Looks at the opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
				var cands := Trainers._distinct(opp.hand, func(c): return CardDB.is_basic_pokemon(c) or CardDB.is_evolution(c))
				if not cands.is_empty():
					g.ask(me.index, "Push Aside: card to the bottom of the opponent's deck", Trainers._card_options(cands, false), func(o):
						if opp.hand.has(o["id"]):
							opp.hand.erase(o["id"])
							opp.deck.insert(0, o["id"])
							g.log_msg("  %s goes to the bottom of the opponent's deck." % CardDB.card_name(o["id"])))
		"silver_wind":
			if d != null and not blocked:
				d.flags["silver_wind"] = [g.turn_number + 2, me.index, op["n"]]
		"steel_generator":
			if d != null:
				var src: PokemonInPlay = null
				for p in opp.bench:
					if src == null or p.basic_energy_count() > src.basic_energy_count():
						src = p
				if src != null:
					for i in op["n"]:
						var e := Abilities._take(src.energy, func(c): return CardDB.is_basic_energy(c))
						if e != "":
							d.energy.append(e)


static func _spread_targets(scope: String, me: PlayerState, opp: PlayerState) -> Array[PokemonInPlay]:
	var out: Array[PokemonInPlay] = []
	match scope:
		"opp_all": out.append_array(opp.all_in_play())
		"opp_bench": out.append_array(opp.bench)
		"opp_bench_damaged": out.append_array(opp.bench.filter(func(p): return p.damage > 0))
		"all_bench":
			out.append_array(me.bench)
			out.append_array(opp.bench)
		"all_bench_energy":
			out.append_array(me.bench.filter(func(p): return not p.energy.is_empty()))
			out.append_array(opp.bench.filter(func(p): return not p.energy.is_empty()))
		"my_bench": out.append_array(me.bench)
		"my_all": out.append_array(me.all_in_play())
		"all_ability":
			for p in opp.all_in_play() + me.all_in_play():
				if not p.abilities().is_empty():
					out.append(p)
		"opp_bench_same_type":
			var ts: Array = opp.active.types() if opp.active != null else []
			out.append_array(opp.bench.filter(func(p): return p.types().any(func(t): return t in ts)))
		"all_active":
			out.append(opp.active)
			out.append(me.active)
	return out


static func _counter_targets(to: String, opp: PlayerState, target: int) -> Array[PokemonInPlay]:
	var out: Array[PokemonInPlay] = []
	match to:
		"def": out.append(opp.active)
		"opp_all": out.append_array(opp.all_in_play())
		"opp_bench": out.append_array(opp.bench)
		"opp_damaged": out.append_array(opp.all_in_play().filter(func(p): return p.damage > 0))
		"target":
			if opp.slot(target) != null:
				out.append(opp.slot(target))
	return out


static func _discard_own_energy(me: PlayerState, p: PokemonInPlay, op: Dictionary) -> bool:
	var et: String = op["etype"]
	var count: int = op["count"]
	var removed := 0
	for i in range(p.energy.size() - 1, -1, -1):
		if removed >= count:
			break
		var e := p.energy[i]
		if Energy.card_provides(e, et) or (et == "basic" and CardDB.is_basic_energy(e)):
			me.discard.append(e)
			p.energy.remove_at(i)
			removed += 1
	return removed > 0 if count == 99 else removed >= count


static func _discard_defender_energy(g: Game, opp: PlayerState, d: PokemonInPlay, special_only: bool) -> void:
	for i in range(d.energy.size() - 1, -1, -1):
		var e := d.energy[i]
		if special_only and CardDB.is_basic_energy(e):
			continue
		opp.discard.append(e)
		d.energy.remove_at(i)
		g.log_msg("  Discards %s from %s." % [CardDB.card_name(e), d.display_name()])
		return


static func _strip_trainers(owner: PlayerState, p: PokemonInPlay) -> void:
	if p.tool != "":
		owner.discard.append(p.tool)
		p.tool = ""
	if p.tm != "":
		owner.discard.append(p.tm)
		p.tm = ""


static func _attach(g: Game, me: PlayerState, a: PokemonInPlay, op: Dictionary) -> void:
	var et: String = op["etype"]
	var pile: Array[String] = me.hand if op["from"] == "hand" else (me.discard if op["from"] == "discard" else me.deck)
	var pred := func(c) -> bool:
		if not CardDB.is_energy(c):
			return false
		if et == "":
			return true
		if et == "basic":
			return CardDB.is_basic_energy(c)
		return CardDB.card_name(c) == et + " Energy"
	for i in op["n"]:
		var e := Abilities._take(pile, pred)
		if e == "":
			break
		if op["to"] == "self":
			a.energy.append(e)
			if op["from"] == "hand":
				Abilities.on_energy_from_hand(g, me, a, e)
		else:
			# La carta vuelve a la pila hasta que se elige (así nunca queda "en el aire").
			pile.append(e)
			var opts: Array = []
			var energies: Array = [e]
			if op["from"] == "hand":    # de la mano: el jugador elige cuál
				energies = Trainers._distinct(pile, pred)
			for c in energies:
				for s in me.slots():
					if op["to"] == "bench" and s == -1:
						continue
					var lbl := me.slot(s).display_name()
					if energies.size() > 1:
						lbl = "%s → %s" % [CardDB.card_name(c).replace(" Energy", ""), lbl]
					opts.append({"label": lbl, "s": s, "id": c, "ai": 1.0 if s == -1 else 0.5})
			var from_hand: bool = op["from"] == "hand"
			g.ask(me.index, "Attach %s to..." % ("Energy" if energies.size() > 1 else CardDB.card_name(e)), opts, func(o):
				var t := me.slot(o["s"])
				if t != null and pile.has(o["id"]):
					pile.erase(o["id"])
					t.energy.append(o["id"])
					if from_hand:
						Abilities.on_energy_from_hand(g, me, t, o["id"]))
	if op["from"] == "deck":
		g.shuffle(me.deck)


static func _search_pred(filter: String, a: PokemonInPlay, picked: Array) -> Callable:
	match filter:
		"evolution": return func(c): return CardDB.is_evolution(c)
		"pokemon": return func(c): return CardDB.is_pokemon(c)
		"trainer": return func(c): return CardDB.is_trainer(c)
		"basic": return func(c): return CardDB.is_basic_pokemon(c)
		"basic_energy": return func(c): return CardDB.is_basic_energy(c)
		"energy_types":
			var types := picked.map(func(c): return CardDB.basic_energy_type(c))
			return func(c): return CardDB.is_basic_energy(c) and CardDB.basic_energy_type(c) not in types
		"evolves_from_self":
			var nm := a.display_name()
			return func(c): return CardDB.evolves_from(c) == nm
		"team_aqua": return func(c): return CardDB.is_pokemon(c) and CardDB.card_name(c).contains("Team Aqua")
		"stadium": return func(c): return CardDB.is_stadium(c)
		"supporter": return func(c): return CardDB.is_supporter(c)
		"tm_or_tool": return func(c): return CardDB.is_pokemon_tool(c) or CardDB.is_tm(c)
		"pokemon_or_basic_energy": return func(c): return CardDB.is_pokemon(c) or CardDB.is_basic_energy(c)
	return func(_c): return true


static func _ask_search(g: Game, me: PlayerState, a: PokemonInPlay, filter: String, left: int, picked: Array) -> void:
	if left <= 0:
		g.shuffle(me.deck)
		return
	var cands := Trainers._distinct(me.deck, _search_pred(filter, a, picked))
	if cands.is_empty():
		g.shuffle(me.deck)
		return
	var opts := Trainers._card_options(cands, false)
	opts.append({"label": "Done", "id": "", "ai": 0.0})
	g.ask(me.index, "Search your deck", opts, func(o):
		if o["id"] == "":
			g.shuffle(me.deck)
			return
		me.deck.erase(o["id"])
		me.hand.append(o["id"])
		AttackEffects._ask_search(g, me, a, filter, left - 1, picked + [o["id"]]))


static func _ask_recover(g: Game, me: PlayerState, filter: String, left: int) -> void:
	if left <= 0:
		return
	var cands := Trainers._distinct(me.discard, _search_pred(filter, null, []))
	if cands.is_empty():
		return
	g.ask(me.index, "Take from the discard pile", Trainers._card_options(cands, false), func(o):
		me.discard.erase(o["id"])
		me.hand.append(o["id"])
		AttackEffects._ask_recover(g, me, filter, left - 1))


static func _ask_bench_targets(g: Game, me: PlayerState, opp: PlayerState, a: PokemonInPlay, left: int, n: int,
		ignore: Dictionary, chosen: Array = []) -> void:
	if left <= 0:
		return
	var opts: Array = []
	for b in opp.bench.size():
		if b not in chosen:
			var p := opp.bench[b]
			opts.append({"label": p.display_name(), "b": b, "opp": true, "ai": 100.0 if p.hp_left() <= n else float(p.damage)})
	if opts.is_empty():
		return
	g.ask(me.index, "Choose a Benched Pokémon", opts, func(o):
		var p := opp.bench[o["b"]]
		g.deal_attack_damage(a, p, n, false, ignore)
		AttackEffects._ask_bench_targets(g, me, opp, a, left - 1, n, ignore, chosen + [o["b"]]))


static func _ask_counters(g: Game, me: PlayerState, opp: PlayerState, a: PokemonInPlay, left: int) -> void:
	if left <= 0:
		return
	var opts: Array = []
	for s in opp.slots():
		var p := opp.slot(s)
		opts.append({"label": "%s (%d PS)" % [p.display_name(), p.hp_left()], "s": s, "opp": true,
				"ai": 100.0 if p.hp_left() <= 10 else 10.0 - p.hp_left() / 10.0})
	g.ask(me.index, "Put 1 damage counter (%d left)" % left, opts, func(o):
		var p := opp.slot(o["s"])
		if p != null and not Abilities.blocks_effects(g, a, p):
			p.damage += 10
		AttackEffects._ask_counters(g, me, opp, a, left - 1))



## Unir varias Energías de la mano (Energy Shower, Speed Growth, Drizzle...): de a una, con "Listo".
static func _ask_attach_multi(g: Game, me: PlayerState, types: Array, left: int, active_only: bool) -> void:
	if left <= 0:
		return
	var cands := Trainers._distinct(me.hand, func(c):
		if not CardDB.is_energy(c):
			return false
		if types.is_empty():
			return CardDB.is_basic_energy(c)
		return CardDB.basic_energy_type(c) in types)
	if cands.is_empty():
		return
	var opts: Array = []
	for c in cands:
		for sl in ([-1] if active_only else me.slots()):
			opts.append({"label": "%s → %s" % [CardDB.card_name(c).replace(" Energy", ""), me.slot(sl).display_name()],
					"id": c, "s": sl, "ai": 1.0 if sl == -1 else 0.6})
	opts.append({"label": "Done", "id": "", "ai": 0.0})
	g.ask(me.index, "Attach Energy (%s)" % ("no limit" if left >= 99 else "%d left" % left), opts, func(o):
		if o["id"] == "":
			return
		me.hand.erase(o["id"])
		me.slot(o["s"]).energy.append(o["id"])
		AttackEffects._ask_attach_multi(g, me, types, left - 1, active_only))


## Dragon Burst: Energías de ese tipo que se descartan (básicas, o especiales que dan solo ese tipo).
static func burst_counts(e: String, t: String) -> bool:
	if CardDB.is_basic_energy(e):
		return CardDB.basic_energy_type(e) == t
	return false


static func _distinct_list(arr: Array) -> Array:
	var out: Array = []
	for x in arr:
		if x not in out:
			out.append(x)
	return out


## Sableye (Supernatural) y Chimecho (Chime): usar el efecto de un Supporter del rival,
## que se queda donde estaba (en su mano o en su pila de descarte).
static func _use_supporter(g: Game, me: PlayerState, opp: PlayerState, op: Dictionary) -> void:
	var src: Array = opp.hand if op["from"] == "opp_hand" else opp.discard
	if op["from"] == "opp_hand":
		g.log_msg("  Looks at the opponent's hand: " + ", ".join(opp.hand.map(func(c): return CardDB.card_name(c))))
	var opts: Array = []
	for id in Trainers._distinct(src, func(c): return CardDB.is_supporter(c) and Trainers.is_implemented(c)):
		# Las opciones del Supporter se calculan como si estuviera en tu mano (y se saca enseguida).
		var had := me.hand.has(id)
		me.hand.append(id)
		var prms := Trainers.options(g, me, me.hand.size() - 1)
		me.hand.pop_back()
		for prm in prms:
			if prm.get("pick", "") == id and not had:
				continue
			opts.append({"label": _supporter_label(g, me, id, prm), "id": id, "prm": prm, "ai": 1.0 + Trainers._ai_value(id)})
	if opts.is_empty():
		g.log_msg("  There's no Supporter that can be used.")
		return
	if op["may"]:
		opts.append({"label": "Don't use any", "id": "", "ai": 0.0})
	g.ask(me.index, "Use the effect of...", opts, func(o):
		if o["id"] == "":
			return
		g.log_msg("  Uses the effect of %s." % CardDB.card_name(o["id"]))
		Trainers.play(g, me, o["id"], o["prm"]))


static func _supporter_label(g: Game, me: PlayerState, id: String, prm: Dictionary) -> String:
	var s := CardDB.card_name(id)
	if prm.has("pick"):
		s += " (" + CardDB.card_name(prm["pick"]) + ")"
	if prm.has("tg"):
		s += " → " + g.slot_name(me, prm["tg"])
	if prm.has("b"):
		s += " → " + g.slot_name(me, prm["b"])
	return s


static func _hand_cycle(g: Game, me: PlayerState, left: int, draw: int) -> void:
	if left <= 0 or me.hand.is_empty():
		for i in draw:
			if not me.deck.is_empty():
				me.hand.append(me.deck.pop_back())
		return
	g.ask(me.index, "Discard a card", Trainers._card_options(Trainers._distinct(me.hand, func(_c): return true), false), func(o):
		me.hand.erase(o["id"])
		me.discard.append(o["id"])
		AttackEffects._hand_cycle(g, me, left - 1, draw))


## Pone n contadores de daño en la Banca del rival, de a uno, donde elija el jugador.
static func _ask_bench_counters(g: Game, me: PlayerState, opp: PlayerState, left: int) -> void:
	if left <= 0 or opp.bench.is_empty():
		return
	var opts: Array = []
	for b in opp.bench.size():
		var p := opp.bench[b]
		opts.append({"label": "%s (%d HP left)" % [p.display_name(), p.hp_left()], "b": b, "opp": true, "ai": 100.0 if p.hp_left() <= 10 else float(p.damage)})
	g.ask(me.index, "Put a damage counter (%d left)" % left, opts, func(o):
		if o["b"] < opp.bench.size():
			opp.bench[o["b"]].damage += 10
		AttackEffects._ask_bench_counters(g, me, opp, left - 1))
