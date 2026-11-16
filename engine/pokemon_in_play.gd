class_name PokemonInPlay
extends RefCounted
## Un Pokémon en juego: la pila de cartas (básico + evoluciones), energías,
## herramienta, contadores de daño y condiciones especiales.

var cards: Array[String] = []   # de abajo (básico) hacia arriba (evolución actual)
var energy: Array[String] = []
var tool := ""                  # Pokémon Tool
var tool_turn := 0              # turno en que se unió la herramienta
var tm := ""                    # Technical Machine
var damage := 0
var rotation := ""              # "", "asleep", "confused", "paralyzed"
var rotation_turn := 0          # turno en que se aplicó (para quitar Paralyzed)
var poison := 0                 # contadores por chequeo; 0 = no envenenado
var burned := false
var turn_played := 0            # turno en que entró en juego o evolucionó
var evolved_turn := -1          # turno de la última evolución (Poké-Powers al evolucionar)
var power_used_turn := -1       # Poké-Power "una vez por turno"
var hp_bonus := 0               # p.ej. Low Pressure System
var type_override: Array = []   # p.ej. Kecleon, Lunatone/Solrock
var flags := {}                 # efectos de ataques: {"cant_retreat": turno, ...}


func _init(base_card: String = "", turn: int = 0) -> void:
	if base_card != "":
		cards.append(base_card)
	turn_played = turn


## Copia independiente (para que la IA simule jugadas sin tocar la partida real).
func copy() -> PokemonInPlay:
	var c := PokemonInPlay.new()
	c.cards = cards.duplicate()
	c.energy = energy.duplicate()
	c.tool = tool
	c.tool_turn = tool_turn
	c.tm = tm
	c.damage = damage
	c.rotation = rotation
	c.rotation_turn = rotation_turn
	c.poison = poison
	c.burned = burned
	c.turn_played = turn_played
	c.evolved_turn = evolved_turn
	c.power_used_turn = power_used_turn
	c.hp_bonus = hp_bonus
	c.type_override = type_override.duplicate()
	c.flags = flags.duplicate(true)
	return c


func top() -> String:
	return cards[-1]


func data() -> Dictionary:
	return CardDB.get_card(top())


func display_name() -> String:
	return CardDB.card_name(top())


func max_hp() -> int:
	return int(data().get("hp", 0)) + hp_bonus


func hp_left() -> int:
	return max_hp() - damage


func types() -> Array:
	if CardDB.card_name(tool) == "Crystal Shard":
		return ["Colorless"]
	if not type_override.is_empty():
		return type_override
	if is_fossil():
		return ["Colorless"]
	return data().get("types", [])


func is_type(t: String) -> bool:
	return t in types()


func is_ex() -> bool:
	return CardDB.is_ex(top())


func is_fossil() -> bool:
	return CardDB.is_fossil(top())


func has_owner() -> bool:
	return CardDB.has_owner(top())


func name_has(s: String) -> bool:
	return display_name().contains(s)


func is_evolved() -> bool:
	return cards.size() > 1


func is_basic() -> bool:
	return not is_evolved()


## Ataques propios + el de la Technical Machine, si tiene.
func attacks() -> Array:
	var out: Array = data().get("attacks", []).duplicate()
	if tm != "":
		out.append_array(CardDB.get_card(tm).get("attacks", []))
	out.append_array(flags.get("extra_attacks", []))    # Psymimic (Alakazam): ataques copiados
	if CardDB.card_name(tool) == "Memory Berry":
		# Memory Berry: los ataques de las cartas de abajo (Básico y Fase 1)
		for i in cards.size() - 1:
			var c := cards[i]
			if CardDB.is_pokemon(c):
				for atk in CardDB.get_card(c).get("attacks", []):
					var copy: Dictionary = atk.duplicate()
					copy["src"] = c
					out.append(copy)
	return out


func abilities() -> Array:
	return data().get("abilities", [])


func has_ability(ability_name: String) -> bool:
	for a in abilities():
		if a["name"] == ability_name:
			return true
	return false


func base_retreat_cost() -> int:
	return int(data().get("retreat", 0))


func has_special_condition() -> bool:
	return rotation != "" or poison > 0 or burned


func clear_conditions() -> void:
	rotation = ""
	poison = 0
	burned = false


## Saca los efectos de ataques (al retirarse, evolucionar, etc.).
func clear_attack_effects() -> void:
	flags.clear()


func has_condition(cond: String) -> bool:
	match cond:
		"asleep", "confused", "paralyzed": return rotation == cond
		"poisoned": return poison > 0
		"burned": return burned
	return false


func apply_condition(cond: String, turn: int, poison_counters: int = 1) -> void:
	match cond:
		"asleep", "confused", "paralyzed":
			rotation = cond
			rotation_turn = turn
		"poisoned":
			poison = max(poison, poison_counters)
		"burned":
			burned = true


func conditions_text() -> String:
	var parts: Array[String] = []
	match rotation:
		"asleep": parts.append("Asleep")
		"confused": parts.append("Confused")
		"paralyzed": parts.append("Paralyzed")
	if poison > 0:
		parts.append("Poisoned")
	if burned:
		parts.append("Burned")
	return ", ".join(parts)


## Todas las cartas que se descartan si queda fuera de combate.
func all_cards() -> Array[String]:
	var out: Array[String] = []
	out.append_array(cards)
	out.append_array(energy)
	if tool != "":
		out.append(tool)
	if tm != "":
		out.append(tm)
	return out


func basic_energy_count() -> int:
	return energy.filter(func(e): return CardDB.is_basic_energy(e)).size()


func special_energy_count() -> int:
	return energy.size() - basic_energy_count()
