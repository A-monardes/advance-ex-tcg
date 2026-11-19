extends SceneTree
## Tests del motor. Uso:
##   godot --headless --script res://tests/run_tests.gd [partidas_por_cruce]
## Sale con código 1 si algo falla.

var failures := 0
var checks := 0


func _init() -> void:
	CardDB.load_db()
	var games := 40
	if OS.get_cmdline_user_args().size() > 0:
		games = int(OS.get_cmdline_user_args()[0])
	test_decks_are_legal()
	test_energy_payment()
	test_worlds_2004_cards()
	test_player_choices()
	test_attack_parsing()
	test_weakness_resistance()
	test_swampert_ex()
	test_discard_attacks()
	test_ex_gives_two_prizes()
	test_first_turn_rules()
	test_poke_bodies()
	test_poke_powers()
	test_ecard_abilities()
	test_ecard_trainers()
	test_trainer_choices()
	test_stadium_and_tm()
	test_same_seed_same_game()
	test_last_24_attacks()
	test_sudden_death()
	test_coin_preview()
	test_opening_coin()
	test_stats()
	test_campaign()
	test_variants()
	test_special_fx()
	test_dual_type()
	test_secret_gifts()
	test_frlg_to_emerald()
	test_holon()
	test_rock_slide()
	test_delta_evolution()
	test_prize_pick()
	test_dx()
	simulate_all(games)
	print("\n%d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  FALLA: " + what)


func deck(i: int) -> Array[String]:
	# Los tests se escribieron con los mazos clásicos primero; los iniciales van aparte
	var ini := ["Blaze", "Torrent", "Overgrow"]
	var orden: Array = Decks.preset_names().filter(func(x): return not x in ini) + ini + Decks.user_names()
	return Decks.get_deck(orden[i])


func mon(id: String, energies: Array = []) -> PokemonInPlay:
	var p := PokemonInPlay.new(id, 0)
	for e in energies:
		p.energy.append(e)
	return p


func id_of(n: String) -> String:
	for sp in ["ex1", "ex2", "ex3", "ex4", "ex5"]:      # las pruebas son de la era EX
		var id := CardDB.find(n, sp)
		if id != "":
			return id
	return CardDB.find(n)


## Partida en fase principal con Activos fijos, para probar una situación concreta.
func board(my_active: String, opp_active: String, seed_value: int = 1) -> Game:
	var g := Game.new(deck(0), deck(1), seed_value)
	g.start()
	var ai := SimpleAI.new(seed_value)
	while g.phase == "setup":
		g.apply(ai.choose(g))
	g.current_player().active = mon(my_active)
	g.opponent_player().active = mon(opp_active)
	g.current_player().bench.clear()
	g.opponent_player().bench.clear()
	g.opponent_player().bench.append(mon(id_of("Mudkip")))
	g.current_player().bench.append(mon(id_of("Torchic")))
	return g


# ---------------------------------------------------------------------------

func test_decks_are_legal() -> void:
	print("Mazos predefinidos")
	for n in Decks.preset_names():
		var errs := Game.validate_deck(Decks.get_deck(n))
		check(errs.is_empty(), "%s: %s" % [n, errs])
		# Cada mazo predefinido tiene que poder jugarse en al menos una temporada
		var some := false
		for i in RuleSet.SEASONS.size():
			if RuleSet.from_season(i).illegal_cards(Decks.get_deck(n)).is_empty():
				some = true
		check(some, "%s no es legal en ninguna temporada" % n)


func test_worlds_2004_cards() -> void:
	print("Cartas de Expedition/Aquapolis/Skyridge (Mundial 2004)")
	for id in CardDB.all_ids():
		if CardDB.set_of(id).begins_with("ecard") and CardDB.is_trainer(id):
			check(Trainers.is_implemented(id), "%s está programada" % CardDB.card_name(id))
	# Copycat: baraja la mano y roba tantas como el rival
	var g := board("ex1-15", "ex2-100")
	var me := g.current_player()
	var opp := g.opponent_player()
	while opp.hand.size() < 6:
		opp.hand.append(opp.deck.pop_back())
	me.hand.append(id_of("Copycat"))
	g.apply({"t": "trainer", "h": me.hand.size() - 1, "p": {}})
	check(me.hand.size() == opp.hand.size(), "Copycat roba tantas como el rival (%d vs %d)" % [me.hand.size(), opp.hand.size()])
	# Oracle: las 2 elegidas quedan arriba, la primera arriba de todo
	g = board("ex1-15", "ex2-100", 4)
	me = g.current_player()
	me.hand.append(id_of("Oracle"))
	g.apply({"t": "trainer", "h": me.hand.size() - 1, "p": {}})
	var first: String = g.choice_options()[0]["id"]
	g.apply({"t": "choose", "i": 0})
	var second: String = g.choice_options()[g.choice_options().size() - 1]["id"]
	g.apply({"t": "choose", "i": g.choice_options().size() - 1})
	check(me.deck[-1] == first and me.deck[-2] == second, "Oracle deja las elegidas arriba en orden")
	# Underground Expedition: 2 de las 4 de abajo a la mano
	g = board("ex1-15", "ex2-100", 5)
	me = g.current_player()
	var bottom4: Array = me.deck.slice(0, 4)
	var hand_before := me.hand.size()
	me.hand.append(id_of("Underground Expedition"))
	g.apply({"t": "trainer", "h": me.hand.size() - 1, "p": {}})
	g.apply({"t": "choose", "i": 0})
	g.apply({"t": "choose", "i": 0})
	check(me.hand.size() == hand_before + 2 and bottom4.has(me.hand[-1]) and bottom4.has(me.hand[-2]), "Underground Expedition toma 2 de las 4 de abajo")
	# Boost Energy: solo a evolucionados, da 3 y se descarta al final del turno
	g = board("ex1-15", "ex2-100")
	me = g.current_player()
	me.active.cards.insert(0, "ex1-73")    # Torchic debajo: es un Pokémon evolucionado
	check(Energy.can_attach(id_of("Boost Energy"), me.active), "Boost Energy se une a un evolucionado")
	check(not Energy.can_attach(id_of("Boost Energy"), me.bench[0]), "Boost Energy no se une a un Básico")
	me.active.energy.append(id_of("Boost Energy"))
	check(Energy.total(me.active) == 3, "Boost Energy da 3 Energías")
	check(not Abilities.can_retreat(g, me, me.active), "con Boost Energy no se puede retirar")
	g.apply({"t": "end"})
	check(me.active.energy.is_empty(), "Boost Energy se descarta al final del turno")
	# Rayquaza ex - Dragon Burst: elegís Fuego o Rayo y hace 40 por cada una descartada
	g = board("ex3-97", "ex2-100")
	me = g.current_player()
	for e in ["Fire Energy", "Fire Energy", "Lightning Energy"]:
		me.active.energy.append(id_of(e))
	var opts := g.legal_actions().filter(func(x): return x["t"] == "attack" and x["a"] == 1).map(func(x): return x["opt"])
	check(opts.has("Fire") and opts.has("Lightning"), "Dragon Burst ofrece Fuego o Rayo (%s)" % [opts])
	var wl := g.opponent_player().active
	g.apply({"t": "attack", "a": 1, "tg": -2, "opt": "Fire"})
	check(wl.damage == 80 and me.active.energy.size() == 1, "Dragon Burst con 2 Fuego hace 80 (hizo %d)" % wl.damage)
	# Suicune ex - Reverse Stream: opcional, devuelve todas las básicas (50 + 10 c/u)
	g = board("ex4-94", "ex2-100")
	me = g.current_player()
	for i in 3:
		me.active.energy.append(id_of("Water Energy"))
	wl = g.opponent_player().active
	g.apply({"t": "attack", "a": 1, "tg": -2, "opt": true})
	check(wl.damage == 80 and me.active.energy.is_empty(), "Reverse Stream devolviendo 3 hace 80 (hizo %d)" % wl.damage)
	# Weakness Guard: sin Debilidad
	g = board("ex1-15", "ex2-100")
	check(not Abilities.ignores_weakness(g, g.opponent_player().active), "sin Weakness Guard hay Debilidad")
	g.opponent_player().active.tool = id_of("Weakness Guard")
	check(Abilities.ignores_weakness(g, g.opponent_player().active), "Weakness Guard quita la Debilidad")


func test_player_choices() -> void:
	print("Elecciones que antes eran automáticas")
	# Dunsparce - Strike and Run: el jugador elige qué Básicos poner en la Banca
	var g := board("ex2-60", "ex2-100")
	var me := g.current_player()
	me.bench.clear()
	g.apply({"t": "attack", "a": 0, "tg": -2, "opt": false})
	check(g.phase == "choice" and g.choice_options().any(func(o): return o["id"] == ""), "Strike and Run pregunta qué Básico (con Listo)")
	var first: String = g.choice_options()[0]["id"]
	g.apply({"t": "choose", "i": 0})
	check(me.bench.size() == 1 and me.bench[0].top() == first, "pone el Básico elegido")
	# Amnesia (Lileep): el jugador elige qué ataque bloquear
	g = board("ex2-43", "ex1-15")     # Lileep vs Blaziken (2 ataques)
	me = g.current_player()
	var opp := g.opponent_player()
	var blaz := opp.active
	g.apply({"t": "attack", "a": 0, "tg": -2, "opt": false})
	check(g.phase == "choice" and g.choice_options().size() == 2, "Amnesia pregunta cuál de los 2 ataques bloquear")
	var second_name: String = g.choice_options()[1]["name"]
	g.apply({"t": "choose", "i": 1})
	check(blaz.flags.get("disabled_attack", [""])[0] == second_name, "bloquea el ataque elegido")
	# Energy Restore: elegir qué Energías vuelven (forzando caras)
	g = board("ex1-15", "ex2-100")
	me = g.current_player()
	me.discard.append_array([id_of("Fire Energy"), id_of("Water Energy"), id_of("Grass Energy")])
	var heads_before := g.coin_log.size()
	me.hand.append(id_of("Energy Restore"))
	g.apply({"t": "trainer", "h": me.hand.size() - 1, "p": {}})
	var heads := g.coin_log.slice(heads_before).count(true)
	if heads > 0:
		check(g.phase == "choice", "Energy Restore pregunta qué Energía recuperar")
		var want: String = g.choice_options()[g.choice_options().size() - 1]["id"]
		g.apply({"t": "choose", "i": g.choice_options().size() - 1})
		check(me.hand.has(want), "recupera la elegida")
	# Desert Shaman: cada jugador elige cuántas roba
	g = board("ex1-15", "ex2-100")
	me = g.current_player()
	opp = g.opponent_player()
	me.hand.append(id_of("Desert Shaman"))
	g.apply({"t": "trainer", "h": me.hand.size() - 1, "p": {}})
	check(g.phase == "choice" and g.choice_options().size() == 5, "Desert Shaman ofrece robar de 4 a 0")
	g.apply({"t": "choose", "i": 2})        # robar 2
	check(me.hand.size() == 2, "robó las 2 elegidas")
	check(g.phase == "choice" and g.actor() == opp.index, "después elige el rival")
	g.apply({"t": "choose", "i": 0})
	check(opp.hand.size() == 4, "el rival robó 4")
	# Rare Candy: solo ofrece Fase 2
	g = board("ex1-73", "ex2-100")
	me = g.current_player()
	me.turns_taken = 3
	me.active.turn_played = 0
	me.hand.append_array([id_of("Rare Candy"), "ex1-28", "ex1-3"])   # Combusken y Blaziken
	var candy := me.hand.find(id_of("Rare Candy"))
	var opts := Trainers.options(g, me, candy)
	check(opts.size() > 0 and opts.all(func(o): return CardDB.stage(o["ev"]) == 2), "Rare Candy no ofrece Fase 1 (%s)" % [opts])
	# Mulligan: el rival elige cuántas cartas extra roba
	var g2 := Game.new(deck(0), deck(1), 1)
	g2.start()
	g2.players[1 - g2.first_player].mull_bonus = 0
	g2.players[g2.first_player].mull_bonus = 2
	var acts := g2.legal_actions()
	check(acts.size() == 3 and acts.all(func(x): return x["t"] == "mull_draw"), "con 2 mulligans del rival se elige robar 2, 1 o 0")
	var hs := g2.players[g2.first_player].hand.size()
	g2.apply({"t": "mull_draw", "n": 1})
	check(g2.players[g2.first_player].hand.size() == hs + 1, "roba la cantidad elegida")


func test_energy_payment() -> void:
	print("Pago de energía")
	var fire := id_of("Fire Energy")
	var water := id_of("Water Energy")
	var rainbow := id_of("Rainbow Energy")
	var p := mon("ex1-15", [fire, water])
	check(Energy.can_pay(p, ["Fire", "Colorless"]), "Fuego+Agua paga [Fire, Colorless]")
	check(not Energy.can_pay(p, ["Fire", "Fire"]), "Fuego+Agua no paga [Fire, Fire]")
	p.energy.append(rainbow)
	check(Energy.can_pay(p, ["Fire", "Fire", "Colorless"]), "Arcoíris funciona como comodín")
	check(not Energy.can_pay(p, ["Fire", "Fire", "Fire", "Colorless"]), "no alcanza con 3 unidades para 4")
	var aqua := mon("ex4-3", [id_of("Aqua Energy")])
	check(Energy.can_pay(aqua, ["Water", "Colorless"]), "Aqua Energy provee 2")
	check(not Energy.can_attach(id_of("Aqua Energy"), mon("ex1-15")), "Aqua Energy solo en Team Aqua")


func test_attack_parsing() -> void:
	print("Traducción de textos de ataque")
	var r := AttackEffects.parse("x", {"name": "a", "text": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."})
	check(r["ops"].size() == 2 and r["ops"][1]["c"] == "heads", "moneda + parálisis con cara")
	r = AttackEffects.parse("y", {"name": "b", "text": "Flip 3 coins. This attack does 20 damage times the number of heads."})
	check(r["unknown"] == "" and r["ops"][0]["count"] == 3, "3 monedas x20")
	r = AttackEffects.parse("z", {"name": "c", "text": "Choose 1 of your opponent's Pokémon. This attack does 30 damage to that Pokémon. (Don't apply Weakness and Resistance for Benched Pokémon.)"})
	check(r["unknown"] == "" and r["target"] == "any", "ataque a cualquier Pokémon pide objetivo")
	r = AttackEffects.parse("w", {"name": "d", "text": "Flip a coin. If heads, this attack does 40 damage plus 30 more damage. If tails, the Defending Pokémon is now Paralyzed."})
	check(r["unknown"] == "" and r["ops"][2]["c"] == "tails", "cara y cruz en el mismo ataque")
	r = AttackEffects.parse("v", {"name": "e", "text": "You may discard a Fire Energy card attached to this Pokémon. If you do, the Defending Pokémon is now Burned."})
	check(r["unknown"] == "" and r["optional"], "\"You may... If you do\" genera opción")


func test_swampert_ex() -> void:
	print("Swampert ex (ex4-95)")
	var atks: Array = CardDB.get_card("ex4-95")["attacks"]
	var hp := AttackEffects.parse("ex4-95", atks[0])
	check(hp["ops"][0].get("cap", 0) == 80, "Hyper Pump suma como máximo 80")
	var cw := AttackEffects.parse("ex4-95", atks[1])
	check(cw["target"] == "any" and cw["unknown"] == "", "Crushing Wave elige objetivo")
	check(cw["ops"].any(func(o): return o["k"] == "discard_def_energy" and o.get("that", false)),
		"Crushing Wave descarta Energía del Pokémon elegido")
	# Con objetivo en la Banca, el daño va a ese Pokémon y la moneda se tira después.
	var g := board("ex4-95", "ex1-59")
	var me := g.current_player()
	for i in 3:
		me.active.energy.append(id_of("Water Energy"))
	var target := g.opponent_player().bench[0]
	target.energy.append(id_of("Water Energy"))
	var coins_before := g.coin_log.size()
	g.apply({"t": "attack", "a": 1, "tg": 0, "opt": false})
	check(target.damage == 40, "Crushing Wave hace 40 al Pokémon de Banca elegido (hizo %d)" % target.damage)
	check(g.coin_log.size() == coins_before + 1, "se tira la moneda después del daño")
	check(target.energy.size() == (0 if g.coin_log[coins_before] else 1), "con cara se descarta su Energía")


func test_discard_attacks() -> void:
	print("Ataques que descartan Energía y otros efectos")
	# Blaziken ex - Volcanic Ash: descarta 2 Fuego y hace 100 al Pokémon elegido.
	var g := board("ex4-89", "ex1-59")
	var me := g.current_player()
	for i in 4:
		me.active.energy.append(id_of("Fire Energy"))
	var target := g.opponent_player().bench[0]
	g.apply({"t": "attack", "a": 1, "tg": 0, "opt": false})
	check(target.damage == 100 or not g.players[1 - me.index].bench.has(target), "Volcanic Ash hace 100 al elegido")
	check(me.discard.filter(func(c): return CardDB.card_name(c) == "Fire Energy").size() == 2, "Volcanic Ash descarta 2 Energías de Fuego")
	# Blaziken - Fire Stream: descarta 1 Fuego y 10 a cada Pokémon en Banca.
	g = board("ex1-3", "ex1-59")
	me = g.current_player()
	for i in 3:
		me.active.energy.append(id_of("Fire Energy"))
	var bench_mon := g.opponent_player().bench[0]
	g.apply({"t": "attack", "a": 0, "tg": -2, "opt": false})
	check(me.discard.has(id_of("Fire Energy")), "Fire Stream descarta 1 Energía de Fuego")
	check(bench_mon.damage == 10, "Fire Stream hace 10 a la Banca (hizo %d)" % bench_mon.damage)
	# Retirada: con Energías distintas, el jugador elige cuál descartar.
	g = board("ex1-15", "ex2-100")     # Blaziken, retirada 2
	me = g.current_player()
	for e in ["Fire Energy", "Fighting Energy", "Water Energy"]:
		me.active.energy.append(id_of(e))
	var blaziken := me.active
	g.apply({"t": "retreat", "b": 0})
	check(g.phase == "choice" and me.active == blaziken, "la retirada pregunta qué Energía descartar antes de cambiar")
	var water := g.choice_options().map(func(o): return o["id"]).find(id_of("Water Energy"))
	g.apply({"t": "choose", "i": water})
	var fighting := g.choice_options().map(func(o): return o["id"]).find(id_of("Fighting Energy"))
	g.apply({"t": "choose", "i": fighting})
	check(me.active != blaziken and blaziken.energy == [id_of("Fire Energy")], "se descartan las elegidas y se cambia (quedó %s)" % [blaziken.energy])
	# Team Magma's Aggron - Land Stream: elegís cuántas Energías básicas descartar (50 + 20 c/u).
	g = board("ex4-7", "ex2-100")
	me = g.current_player()
	for i in 4:
		me.active.energy.append(id_of("Fighting Energy"))
	var ls := g.legal_actions().filter(func(a): return a["t"] == "attack" and a["a"] == 1)
	check(ls.size() == 5, "Land Stream ofrece descartar de 0 a 4 Energías (ofrece %d opciones)" % ls.size())
	var wailord := g.opponent_player().active
	g.apply({"t": "attack", "a": 1, "tg": -2, "opt": 2})
	check(wailord.damage == 90, "Land Stream descartando 2 hace 90 (hizo %d)" % wailord.damage)
	check(me.active.energy.size() == 2 and me.discard.filter(func(c): return CardDB.card_name(c) == "Fighting Energy").size() == 2, "Land Stream descarta 2")
	# Team Aqua's Walrein - Hydro Reverse: devuelve Agua de todos tus Pokémon (50 + 10 c/u).
	g = board("ex4-6", "ex2-100")
	me = g.current_player()
	for i in 4:
		me.active.energy.append(id_of("Water Energy"))
	me.bench[0].energy.append(id_of("Water Energy"))
	var hand_before := me.hand.size()
	wailord = g.opponent_player().active
	g.apply({"t": "attack", "a": 1, "tg": -2, "opt": 3})
	check(wailord.damage == 80, "Hydro Reverse devolviendo 3 hace 80 (hizo %d)" % wailord.damage)
	check(me.hand.size() == hand_before + 3 and me.bench[0].energy.is_empty(), "Hydro Reverse devuelve a la mano, primero desde la Banca")
	# Ninetales ex - Intense Glare: trae un Pokémon de la Banca y lo quema.
	g = board("ex5-96", "ex1-59")
	var benched := g.opponent_player().bench[0]
	g.apply({"t": "attack", "a": 0, "tg": 0, "opt": false})
	check(g.opponent_player().active == benched or g.players[1 - g.first_player].active == benched, "Intense Glare trae al Pokémon elegido")
	check(benched.burned, "y lo deja Quemado")


func test_weakness_resistance() -> void:
	print("Debilidad y resistencia")
	var g := board("ex1-15", "ex2-22")
	var blaziken := g.current_player().active
	var target := g.opponent_player().active      # Shiftry, Planta: débil a Fuego
	g.deal_attack_damage(blaziken, target, 30, true, {})
	check(target.damage == 60, "Fuego contra Planta hace x2 (60), hizo %d" % target.damage)
	var bench_target := g.opponent_player().bench[0]
	g.deal_attack_damage(blaziken, bench_target, 30, false, {})
	check(bench_target.damage == 30, "en Banca no se aplica Debilidad")


func test_ex_gives_two_prizes() -> void:
	print("Pokémon-ex otorgan 2 Premios")
	var g := board("ex1-15", "ex2-98")
	var me := g.current_player()
	g.opponent_player().active.damage = 999
	var before := me.prizes.size()
	g._check_knockouts()
	check(before - me.prizes.size() == 2, "se tomaron %d premios" % (before - me.prizes.size()))


func test_first_turn_rules() -> void:
	print("Reglas del primer turno (era EX)")
	var g := Game.new(deck(0), deck(1), 3)
	g.start()
	var ai := SimpleAI.new(3)
	var played := 0
	while g.phase == "setup":
		var a := ai.choose(g)
		if a["t"] in ["setup_active", "setup_bench"] and g.actor() == g.first_player:
			played += 1
		g.apply(a)
	var me := g.current_player()
	check(g.turn_number == 1, "turno 1")
	check(me.hand.size() == 7 - played + g.other(me).mulligans, "el primer jugador no roba")
	check(not g.legal_actions().any(func(a): return a["t"] == "evolve"), "no se evoluciona en el primer turno")
	var birch := id_of("Professor Birch")
	me.hand.append(birch)
	check(not g.legal_actions().any(func(a): return a["t"] == "trainer" and me.hand[a["h"]] == birch),
		"tras el Mundial 2004 no hay Supporters en el primer turno")


func test_poke_bodies() -> void:
	print("Poké-Bodies")
	# Exoskeleton (Kabuto): -20 de daño
	var g := board("ex1-15", id_of("Kabuto"))
	var d := g.opponent_player().active
	g.deal_attack_damage(g.current_player().active, d, 50, true, {})
	check(d.damage == 30, "Exoskeleton reduce 20 (hizo %d)" % d.damage)
	# Rough Skin (Sharpedo ex1-22): 2 contadores al atacante
	g = board("ex1-15", "ex1-22")
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 20, true, {})
	check(g.current_player().active.damage == 20, "Rough Skin pone 2 contadores")
	# Toxic Gas (Muk ex) anula Exoskeleton
	g = board("ex3-96", id_of("Kabuto"))
	check(not Abilities.body(g, g.opponent_player().active, "Exoskeleton"), "Toxic Gas anula otros Poké-Bodies")
	check(Abilities.body(g, g.current_player().active, "Toxic Gas"), "Toxic Gas sigue activo")
	# Super Suction Cups (Cradily): el rival no puede retirarse
	g = board("ex1-15", "ex1-59")
	var me := g.current_player()
	me.active.energy.append(id_of("Fire Energy"))
	me.active.energy.append(id_of("Fire Energy"))
	check(g.legal_actions().any(func(a): return a["t"] == "retreat"), "sin Cradily se puede retirar")
	g.current_player().active = mon("ex1-15", [id_of("Fire Energy"), id_of("Fire Energy")])
	var tmp := g.opponent_player().active
	g.opponent_player().active = mon("ex2-3")
	check(not g.legal_actions().any(func(a): return a["t"] == "retreat"), "Super Suction Cups impide retirarse")
	g.opponent_player().active = tmp


func test_poke_powers() -> void:
	print("Poké-Powers")
	var g := board("ex1-3", "ex1-59")     # Blaziken con Firestarter
	var me := g.current_player()
	me.discard.append(id_of("Fire Energy"))
	var acts := g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Firestarter")
	check(acts.size() == 1, "Firestarter disponible con Energía en el descarte")
	g.apply(acts[0])
	check(me.bench[0].energy.size() == 1, "Firestarter une la Energía a la Banca")
	check(not g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Firestarter"), "solo una vez por turno")
	# Una condición especial bloquea el Poké-Power
	g = board("ex1-3", "ex1-59")
	g.current_player().discard.append(id_of("Fire Energy"))
	g.current_player().active.rotation = "asleep"
	check(not g.legal_actions().any(func(a): return a["t"] == "power"), "dormido no usa Poké-Powers")
	# Lazy (Slaking activo del rival) bloquea Poké-Powers
	g = board("ex1-3", "ex1-12")
	g.current_player().discard.append(id_of("Fire Energy"))
	check(not g.legal_actions().any(func(a): return a["t"] == "power"), "Slaking bloquea Poké-Powers")


func test_ecard_abilities() -> void:
	print("Poké-Powers y Poké-Bodies e-card")
	var fire := id_of("Fire Energy")
	var water := id_of("Water Energy")
	var light := id_of("Lightning Energy")
	# Rock Body (Golem): -10; Vase Body (Shuckle): -20
	var g := board("ex1-15", "ecard1-14")
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 50, true, {"w": true, "r": true})
	check(g.opponent_player().active.damage == 40, "Rock Body reduce 10 (hizo %d)" % g.opponent_player().active.damage)
	g = board("ex1-15", "ecard3-96")
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 50, true, {"w": true, "r": true})
	check(g.opponent_player().active.damage == 30, "Vase Body reduce 20")
	# Energy Barrier (Mr. Mime): -10 por Energía básica, máximo 20
	g = board("ex1-15", "ecard2-95")
	g.opponent_player().active.energy.append_array([fire, fire, fire])
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 50, true, {"w": true, "r": true})
	check(g.opponent_player().active.damage == 30, "Energy Barrier reduce hasta 20")
	# Dark Aura (Tyranitar): todo provee Oscura; Rare Metal (Steelix): básicas proveen Metal
	g = board("ecard1-29", "ex1-15")
	g.current_player().active.energy.append_array([fire, water])
	Abilities.refresh(g)
	check(Energy.count_type(g.current_player().active, "Darkness") == 2, "Dark Aura: todo es Oscura")
	g = board("ecard3-31", "ex1-15")
	g.current_player().active.energy.append_array([fire, water])
	Abilities.refresh(g)
	check(Energy.count_type(g.current_player().active, "Metal") == 2 and Energy.count_type(g.current_player().active, "Fire") == 0,
			"Rare Metal: las básicas son Metal")
	# Extreme Speed (Arcanine): retirada -1 por Energía
	g = board("ecard2-2", "ex1-15")
	var arc := g.current_player().active
	var base := arc.base_retreat_cost()
	arc.energy.append(fire)
	check(Abilities.retreat_cost(g, g.current_player(), arc) == max(0, base - 1), "Extreme Speed baja la retirada")
	# Gluey Slime (Ariados en juego): +1 a la retirada de los Activos
	g = board("ex1-15", "ecard2-3")
	var me := g.current_player()
	check(Abilities.retreat_cost(g, me, me.active) == me.active.base_retreat_cost() + 1, "Gluey Slime suma 1")
	# Anti-Lightning (Zapdos): no se le une Rayo desde la mano
	g = board("ecard2-44", "ex1-15")
	g.current_player().hand.clear()
	g.current_player().hand.append(light)
	g.current_player().hand.append(fire)
	var en: Array = g.legal_actions().filter(func(a): return a["t"] == "energy" and a["tg"] == -1)
	check(en.size() == 1 and g.current_player().hand[en[0]["h"]] == fire, "Anti-Lightning")
	# Enervating Pollen (Gloom en juego): la Resistencia solo resta 10
	g = board("ex1-15", "ecard2-49")
	check(Abilities.resistance_value(g, 30) == 10, "Enervating Pollen deja la Resistencia en 10")
	# Dark Gaze (Umbreon Activo): la Banca no usa Poké-Powers
	g = board("ex1-15", "ecard3-32")
	g.current_player().bench[0] = mon("ex1-3")       # Blaziken con Firestarter en la Banca
	g.current_player().discard.append(fire)
	check(not g.legal_actions().any(func(a): return a["t"] == "power"), "Dark Gaze bloquea los poderes de la Banca")
	# Psymimic (Alakazam): aparecen los ataques del rival como opciones
	g = board("ecard1-1", "ex1-15")
	g.current_player().active.energy.append_array([fire, fire, fire, fire])
	Abilities.refresh(g)
	var names: Array = g.current_player().active.attacks().map(func(a): return a["name"])
	var opp_atk: String = CardDB.get_card("ex1-15")["attacks"][0]["name"]
	check(opp_atk in names, "Psymimic copia los ataques del rival (%s)" % str(names))
	var acts := g.legal_actions().filter(func(a): return a["t"] == "attack" and a["a"] >= 2)
	check(not acts.is_empty(), "Psymimic: el ataque copiado se puede usar")
	if not acts.is_empty():
		g.apply(acts[0])
		check(g.log_lines.any(func(l): return str(l).contains("Psymimic")), "Psymimic se usó")
	# Energy Connect (Ampharos): Energía básica de la Banca al Activo, varias veces
	g = board("ecard1-2", "ex1-15")
	g.current_player().bench[0].energy.append_array([light, light])
	acts = g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Energy Connect")
	check(acts.size() == 1, "Energy Connect disponible")
	g.apply(acts[0])
	check(g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Energy Connect"), "Energy Connect se repite")
	check(g.current_player().active.energy.size() == 1, "Energy Connect movió la Energía")
	# Primal Aura (Kabutops Activo): no se evoluciona en la Banca
	g = board("ex1-15", "ecard3-14")
	g.current_player().bench[0] = mon(id_of("Torchic"))
	g.current_player().turns_taken = 3
	g.current_player().hand.append(id_of("Combusken"))
	check(not g.legal_actions().any(func(a): return a["t"] == "evolve" and a["tg"] >= 0), "Primal Aura impide evolucionar la Banca")


func test_ecard_trainers() -> void:
	print("Entrenadores e-card")
	var fire := id_of("Fire Energy")
	# Fire Cube 01: solo a Pokémon de Fuego
	var g := board("ex1-15", "ex1-59")
	var me := g.current_player()
	me.hand.clear()
	me.hand.append("ecard2-122")
	var tgs: Array = g.legal_actions().filter(func(a): return a["t"] == "trainer").map(func(a): return a["p"]["tg"])
	check(tgs.all(func(t): return me.slot(t).is_type("Fire")), "Fire Cube 01 solo a Pokémon de Fuego")
	# Hyper Potion: descarta 2 Energías básicas y cura 50
	g = board("ex1-15", "ex1-59")
	me = g.current_player()
	me.hand.clear()
	me.hand.append("ecard3-127")
	me.active.damage = 60
	me.active.energy.append_array([fire, fire])
	var hp: Array = g.legal_actions().filter(func(a): return a["t"] == "trainer" and a["p"].get("n", 0) == 2 and a["p"]["tg"] == -1)
	check(hp.size() == 1, "Hyper Potion ofrece descartar 2")
	if hp.size() == 1:
		g.apply(hp[0])
		check(me.active.damage == 10 and me.active.energy.is_empty(), "Hyper Potion cura 50")
	# Underground Lake: Kabuto del descarte a la Banca, una vez por turno
	g = board("ex1-15", "ex1-59")
	me = g.current_player()
	g.stadium = "ecard3-141"
	g.stadium_owner = me.index
	me.discard.append("ecard3-37")
	var lake: Array = g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Underground Lake")
	check(lake.size() == 1, "Underground Lake disponible")
	if lake.size() == 1:
		var before := me.bench.size()
		g.apply(lake[0])
		check(me.bench.size() == before + 1, "Underground Lake pone a Kabuto en la Banca")
		check(not g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Underground Lake"), "Estadio: una vez por turno")
	# Crystal Shard: el Pokémon pasa a ser Incoloro
	var p := mon("ex1-15")
	p.tool = "ecard3-122"
	check(p.types() == ["Colorless"], "Crystal Shard lo vuelve Incoloro")
	# Memory Berry: ataques de las cartas de abajo
	p = mon(id_of("Torchic"))
	p.cards.append(id_of("Combusken"))
	var n_before := p.attacks().size()
	p.tool = "ecard2-128"
	check(p.attacks().size() > n_before, "Memory Berry suma los ataques del Básico")


func test_trainer_choices() -> void:
	print("Entrenadores con elección")
	var g := board("ex1-15", "ex1-59")
	var me := g.current_player()
	g.turn_number = 3
	me.hand.append(id_of("TV Reporter"))
	var acts := g.legal_actions().filter(func(a): return a["t"] == "trainer" and me.hand[a["h"]] == id_of("TV Reporter"))
	check(acts.size() == 1, "TV Reporter jugable")
	var before := me.hand.size()
	g.apply(acts[0])
	check(g.phase == "choice" and g.actor() == me.index, "TV Reporter pide descartar")
	g.apply(g.legal_actions()[0])
	check(me.hand.size() == before - 1 + 3 - 1, "robó 3 y descartó 1")
	check(g.phase == "main", "vuelve a la fase principal")
	# Mr. Briney's Compassion con el Activo pide un nuevo Activo
	me.supporter_played = false
	me.hand.append(id_of("Mr. Briney's Compassion"))
	var briney := g.legal_actions().filter(func(a): return a["t"] == "trainer" and CardDB.card_name(me.hand[a["h"]]) == "Mr. Briney's Compassion" and a["p"]["tg"] == -1)
	g.apply(briney[0])
	check(g.phase == "choice" and g.pending_choice_kind() == "promote", "hay que elegir nuevo Activo")


func test_stadium_and_tm() -> void:
	print("Estadios y Technical Machines")
	var g := board("ex4-3", "ex2-72")      # Team Aqua's Kyogre vs Pikachu (Rayo)
	var me := g.current_player()
	me.hand.append(id_of("Low Pressure System"))
	var acts := g.legal_actions().filter(func(a): return a["t"] == "trainer" and CardDB.card_name(me.hand[a["h"]]) == "Low Pressure System")
	g.apply(acts[0])
	check(g.opponent_player().active.max_hp() == 60, "Low Pressure System da +10 PS a Rayo")
	check(me.active.max_hp() == 100, "y no a Agua")
	me.hand.append(id_of("Team Aqua Technical Machine 01"))
	acts = g.legal_actions().filter(func(a): return a["t"] == "trainer" and CardDB.is_tm(me.hand[a["h"]]))
	g.apply(acts[0])
	check(me.active.attacks().size() == 3, "la TM agrega su ataque")
	g.apply({"t": "end"})
	check(g.players[me.index].active.tm == "", "la TM se descarta al final del turno")


func test_same_seed_same_game() -> void:
	print("Determinismo (misma semilla = misma partida)")
	var a := _play(1234, 0, 1, false)
	var b := _play(1234, 0, 1, false)
	check(a.log_lines == b.log_lines, "los registros coinciden")


func _play(seed_value: int, da: int, db: int, random_actions: bool) -> Game:
	var g := Game.new(deck(da), deck(db), seed_value)
	var ais := [SimpleAI.new(seed_value), SimpleAI.new(seed_value + 1)]
	var pick := RandomNumberGenerator.new()
	pick.seed = seed_value
	g.start()
	var steps := 0
	var steps_this_turn := 0
	var last_turn := 0
	while g.phase != "over" and steps < 6000 and g.turn_number < 200:
		var acts := g.legal_actions()
		if acts.is_empty():
			check(false, "sin acciones legales en fase %s (semilla %d)" % [g.phase, seed_value])
			break
		if g.turn_number != last_turn:
			last_turn = g.turn_number
			steps_this_turn = 0
		steps_this_turn += 1
		var a: Dictionary
		if random_actions:
			a = acts[pick.randi() % acts.size()]
			if steps_this_turn > 40 and g.phase == "main":
				a = {"t": "end"}
		else:
			a = ais[g.actor()].choose(g)
			if steps_this_turn > 80 and g.phase == "main":
				a = {"t": "end"}
		g.apply(a)
		_check_invariants(g, seed_value)
		steps += 1
	return g


func _check_invariants(g: Game, seed_value: int) -> void:
	for p in g.players:
		var n := p.deck.size() + p.hand.size() + p.discard.size() + p.prizes.size()
		for m in p.all_in_play():
			n += m.all_cards().size()
		if g.stadium != "" and g.stadium_owner == p.index:
			n += 1
		if n != 60:
			check(false, "el jugador %d tiene %d cartas en total (semilla %d)" % [p.index + 1, n, seed_value])
		if g.phase != "over" and g.phase != "setup" and p.active == null and g.pending_choice_kind() != "promote":
			check(false, "jugador %d sin Activo fuera de una elección (semilla %d)" % [p.index + 1, seed_value])


func simulate_all(games: int) -> void:
	# Mismo orden que deck(i), para que los nombres impresos sean los mazos que se juegan
	var ini := ["Blaze", "Torrent", "Overgrow"]
	var names: Array = Decks.preset_names().filter(func(x): return not x in ini) + ini + Decks.user_names()
	print("Simulación IA vs IA (%d partidas por cruce)" % games)
	var unknown_effects := 0
	for i in names.size():
		for j in range(i + 1, names.size()):
			var wins := [0, 0, 0]
			var unfinished := 0
			var turns := 0
			for k in games:
				var a := i if k % 2 == 0 else j
				var b := j if k % 2 == 0 else i
				var g := _play(5000 + k * 7 + i * 100 + j, a, b, false)
				if g.phase != "over":
					unfinished += 1
					continue
				turns += g.turn_number
				if g.winner == 2:
					wins[2] += 1
				else:
					wins[0 if (g.winner == 0) == (a == i) else 1] += 1
				unknown_effects += g.log_lines.filter(func(l): return l.contains("sin programar")).size()
			print("  %-22s %3d  vs %3d  %-22s  empates %d, sin terminar %d, %.1f turnos" % [names[i], wins[0], wins[1], names[j], wins[2], unfinished, float(turns) / max(1, games - unfinished)])
			check(unfinished == 0, "todas las partidas %s vs %s terminan" % [names[i], names[j]])
	print("  Efectos sin programar usados en las partidas: %d" % unknown_effects)
	print("Fuzz: acciones al azar")
	var fuzz_done := 0
	for k in games * 3:
		var g := _play(9000 + k, k % names.size(), (k / names.size()) % names.size(), true)
		if g.phase == "over":
			fuzz_done += 1
	print("  %d / %d partidas al azar terminaron sin errores de reglas" % [fuzz_done, games * 3])


## Un Básico sin Poké-Powers/Bodies, sin Debilidad ni Resistencia frente a esos tipos y con muchos PS.
func neutral_def(types: Array) -> String:
	var best := ""
	for id in CardDB.all_ids():
		if not CardDB.is_basic_pokemon(id):
			continue
		var c := CardDB.get_card(id)
		if not c.get("abilities", []).is_empty():
			continue
		if c.get("weaknesses", []).any(func(t): return t in types) or c.get("resistances", []).any(func(t): return t in types):
			continue
		if best == "" or int(c.get("hp", 0)) > int(CardDB.get_card(best).get("hp", 0)):
			best = id
	return best


func atk_board(att: String, energies: Array) -> Game:
	var g := board(att, neutral_def(CardDB.types(att)))
	for e in energies:
		g.current_player().active.energy.append(id_of(e + " Energy"))
	return g


func atk_index(g: Game, name: String) -> int:
	var atks := g.current_player().active.attacks()
	for i in atks.size():
		if atks[i]["name"] == name:
			return i
	return -1


## Resuelve un ataque sin terminar el turno (para mirar el resultado tal cual).
func hit(g: Game, name: String, tg: int = -2, opt = false) -> void:
	var a := g.current_player().active
	AttackEffects.resolve(g, a, a.attacks()[atk_index(g, name)], tg, opt)


func test_last_24_attacks() -> void:
	print("Los 24 ataques que faltaban")
	# Sceptile - Lizard Poison
	var g := atk_board("ex1-11", ["Grass", "Grass", "Grass", "Grass"])
	var d := g.opponent_player().active
	hit(g, "Lizard Poison")
	check(d.rotation == "asleep" and d.burned and d.poison > 0, "Lizard Poison con 4 Energías: Dormido, Quemado y Envenenado")
	g = atk_board("ex1-11", ["Grass"])
	d = g.opponent_player().active
	hit(g, "Lizard Poison")
	check(d.rotation == "asleep" and not d.burned and d.poison == 0, "Lizard Poison con 1 Energía: solo Dormido")
	g = atk_board("ex1-11", ["Grass", "Grass"])
	d = g.opponent_player().active
	hit(g, "Lizard Poison")
	check(d.rotation != "asleep" and d.poison > 0, "Lizard Poison con 2 Energías: solo Envenenado")
	# Minun / Plusle: 20, o 40 si el elegido tiene Poké-Power/Body o es ex
	g = atk_board("ex3-7", ["Lightning", "Lightning"])
	var opp := g.opponent_player()
	var with_ab := ""
	for id in CardDB.all_ids():
		if CardDB.is_basic_pokemon(id) and not CardDB.get_card(id).get("abilities", []).is_empty() and not "Lightning" in CardDB.get_card(id).get("weaknesses", []) and int(CardDB.get_card(id).get("hp", 0)) > 50:
			with_ab = id
			break
	opp.bench.append(mon(with_ab))
	hit(g, "Special Circuit", 0)
	hit(g, "Special Circuit", 1)
	check(opp.bench[0].damage == 20 and opp.bench[1].damage == 40, "Special Circuit: 20 normal, 40 con Poké-Power/Body (%d, %d)" % [opp.bench[0].damage, opp.bench[1].damage])
	g = atk_board("ex3-8", ["Lightning", "Lightning"])
	opp = g.opponent_player()
	opp.bench.append(mon("ex5-98"))     # Regirock ex
	hit(g, "Extra Circuit", 0)
	hit(g, "Extra Circuit", 1)
	check(opp.bench[0].damage == 20 and opp.bench[1].damage == 40, "Extra Circuit: 40 a un Pokémon-ex")
	# Ninjask - Quick Touch: cambia y mueve las Energías Planta elegidas
	g = atk_board("ex3-18", ["Grass", "Grass", "Water"])
	var me := g.current_player()
	var ninjask := me.active
	g.apply({"t": "attack", "a": atk_index(g, "Quick Touch"), "tg": -2, "opt": true})
	check(g.phase == "choice", "Quick Touch pregunta por quién cambiar")
	g.apply({"t": "choose", "i": 0})
	check(me.active != ninjask and me.bench.has(ninjask), "Quick Touch cambia a Ninjask")
	g.apply({"t": "choose", "i": 0})      # mover 1 Planta
	check(Energy.count_type(me.active, "Grass") == 1 and Energy.count_type(ninjask, "Water") == 1, "mueve la Energía Planta elegida al nuevo Activo")
	# Skarmory - Power Count
	g = atk_board("ex3-21", ["Metal", "Metal"])
	d = g.opponent_player().active
	hit(g, "Power Count")
	var plain := d.damage
	g = atk_board("ex3-21", ["Metal", "Metal"])
	d = g.opponent_player().active
	for i in 3:
		d.energy.append(id_of("Water Energy"))
	hit(g, "Power Count")
	check(plain == 20 and d.damage == 50, "Power Count: 20, o 50 si tus Pokémon tienen menos Energía (%d, %d)" % [plain, d.damage])
	# Grovyle - Fury Cutter
	for seed_value in 6:
		g = atk_board("ex3-31", ["Grass", "Grass"])
		d = g.opponent_player().active
		var c0 := g.coin_log.size()
		hit(g, "Fury Cutter")
		var h := g.coin_log.slice(c0).count(true)
		check(d.damage == (70 if h == 4 else 10 + 10 * h), "Fury Cutter con %d caras hace %d" % [h, d.damage])
	# Kingdra ex - Genetic Memory: usa un ataque de Seadra sin pagarlo
	g = atk_board("ex3-33", ["Water"])
	me = g.current_player()
	me.active.cards.append_array(["ex3-40", "ex3-92"])
	d = g.opponent_player().active
	var gm := g.legal_actions().filter(func(x): return x["t"] == "attack" and x.get("opt") is Dictionary)
	var names := gm.map(func(x): return CardDB.get_card(x["opt"]["gm_card"])["attacks"][x["opt"]["gm_a"]]["name"])
	check("Waterfall" in names and "Retaliate" in names, "Genetic Memory ofrece los ataques de Horsea y Seadra (%s)" % [names])
	var wf: Dictionary = gm[names.find("Waterfall")]
	var wf_dmg := int(CardDB.get_card("ex3-40")["attacks"][wf["opt"]["gm_a"]].get("damage", 0))
	hit(g, "Genetic Memory", -2, wf["opt"])
	check(d.damage == wf_dmg and wf_dmg > 0, "Genetic Memory con Waterfall hace %d (hizo %d)" % [wf_dmg, d.damage])
	check(g.describe(wf).begins_with("Genetic Memory: Waterfall"), "el menú dice qué ataque usa (%s)" % g.describe(wf))
	# Magcargo ex - Lava Flow
	g = atk_board("ex3-95", ["Fire", "Fire", "Fire", "Fire"])
	me = g.current_player()
	d = g.opponent_player().active
	var opts := g.legal_actions().filter(func(x): return x["t"] == "attack" and x["a"] == atk_index(g, "Lava Flow")).map(func(x): return x["opt"])
	check(opts == [0, 1, 2, 3, 4], "Lava Flow ofrece descartar de 0 a 4 (%s)" % [opts])
	hit(g, "Lava Flow", -2, 2)
	check(d.damage == 80 and Energy.total(me.active) == 2, "Lava Flow descartando 2 hace 80")
	# Charizard - Flame Pillar
	g = atk_board("ex3-100", ["Fire", "Fire", "Fire", "Fire"])
	me = g.current_player()
	opp = g.opponent_player()
	var mud := opp.bench[0]
	g.apply({"t": "attack", "a": atk_index(g, "Flame Pillar"), "tg": -2, "opt": true})
	check(g.phase == "choice", "Flame Pillar pregunta a qué Pokémon en Banca")
	g.apply({"t": "choose", "i": 0})
	check(mud.damage == 30 or not opp.bench.has(mud), "Flame Pillar hace 30 al Pokémon en Banca")
	check(me.discard.has(id_of("Fire Energy")), "Flame Pillar descarta 1 Energía de Fuego")
	# Team Aqua's Crawdaunt - Aqua Reverse: solo Pokémon de Team Magma
	g = atk_board("ex4-2", ["Darkness", "Darkness"])
	opp = g.opponent_player()
	opp.bench.append(mon("ex4-65"))     # Team Magma's Poochyena
	var tgs := g.legal_actions().filter(func(x): return x["t"] == "attack" and x["a"] == atk_index(g, "Aqua Reverse")).map(func(x): return x["tg"])
	check(1 in tgs and not 0 in tgs, "Aqua Reverse solo apunta a Pokémon de Team Magma (%s)" % [tgs])
	hit(g, "Aqua Reverse", 1, true)
	check(opp.active.display_name() == "Team Magma's Poochyena", "Aqua Reverse trae al Pokémon de Team Magma")
	# Team Magma's Houndoom - Magma Spurt
	g = atk_board("ex4-10", ["Fire", "Fire", "Fire"])
	me = g.current_player()
	d = g.opponent_player().active
	for c in ["Water Energy", "Potion", "Fighting Energy", "Fire Energy", "Fire Energy"]:
		me.deck.append(id_of(c))
	hit(g, "Magma Spurt")
	check(d.damage == 90, "Magma Spurt con 2 Fuego y 1 Lucha hace 90 (hizo %d)" % d.damage)
	# Team Magma's Torkoal - Magma Burn
	g = atk_board("ex4-12", ["Fire", "Fire"])
	opp = g.opponent_player()
	var n_deck := opp.deck.size()
	var n_disc := opp.discard.size()
	hit(g, "Magma Burn")
	check(opp.deck.size() == n_deck - 1 and opp.discard.size() == n_disc + 1, "Magma Burn descarta la carta de arriba del mazo rival")
	# Raichu - Kerzap
	for seed_value in 4:
		g = atk_board("ex4-13", ["Lightning", "Lightning", "Lightning"])
		me = g.current_player()
		d = g.opponent_player().active
		var c1 := g.coin_log.size()
		hit(g, "Kerzap")
		var heads: bool = g.coin_log[c1]
		check(d.damage == (80 if heads else 40) and Energy.total(me.active) == (0 if heads else 3), "Kerzap (%s) hace %d" % ["cara" if heads else "cruz", d.damage])
	# Shiftry - Push Aside
	g = atk_board("ex5-14", ["Darkness", "Darkness"])
	opp = g.opponent_player()
	opp.hand.clear()
	opp.hand.append_array([id_of("Potion"), "ex1-73"])
	g.apply({"t": "attack", "a": atk_index(g, "Push Aside"), "tg": -2, "opt": false})
	check(g.phase == "choice" and g.choice_options().size() == 1, "Push Aside solo ofrece Pokémon de la mano rival")
	g.apply({"t": "choose", "i": 0})
	check(opp.deck[0] == "ex1-73" and not opp.hand.has("ex1-73"), "Push Aside lo pone al fondo del mazo rival")
	# Chimecho - Chime (Supporter del descarte rival)
	g = atk_board("ex5-17", ["Psychic"])
	me = g.current_player()
	opp = g.opponent_player()
	me.hand.clear()
	opp.discard.append(id_of("Professor Birch"))
	g.apply({"t": "attack", "a": atk_index(g, "Chime"), "tg": -2, "opt": false})
	check(g.phase == "choice", "Chime pregunta qué Supporter usar")
	g.apply({"t": "choose", "i": 0})
	check(me.hand.size() == 6 and opp.discard.has(id_of("Professor Birch")), "Chime usa Professor Birch (roba hasta 6) y la carta queda en el descarte rival")
	# Sableye - Supernatural (Supporter de la mano rival)
	g = atk_board("ex2-10", ["Darkness"])
	me = g.current_player()
	opp = g.opponent_player()
	me.hand.clear()
	opp.hand.append(id_of("Professor Birch"))
	g.apply({"t": "attack", "a": atk_index(g, "Supernatural"), "tg": -2, "opt": false})
	check(g.phase == "choice" and g.choice_options().back()["id"] == "", "Supernatural ofrece Supporters de la mano rival (o ninguno)")
	g.apply({"t": "choose", "i": 0})
	check(me.hand.size() == 6 and opp.hand.has(id_of("Professor Birch")), "Supernatural usa el efecto y la carta queda en la mano rival")
	# Masquerain - Silver Wind: +30 en tu próximo turno
	g = atk_board("ex5-20", ["Grass", "Grass"])
	me = g.current_player()
	d = g.opponent_player().active
	hit(g, "Silver Wind")
	check(d.flags.has("silver_wind"), "Silver Wind marca al Defensor")
	var before := d.damage
	g.turn_number += 2
	g.deal_attack_damage(me.active, d, 20, true, {})
	check(d.damage - before == 50, "en tu siguiente turno el ataque hace 30 más (%d)" % (d.damage - before))
	# Swalot - Swallow Up
	g = atk_board("ex5-50", ["Grass", "Grass", "Grass"])
	d = g.opponent_player().active
	d.damage = d.max_hp() - 60
	hit(g, "Swallow Up")
	check(d.damage == d.max_hp() - 60 + 80 or d.hp_left() <= 0, "Swallow Up hace 80 si el Defensor tiene menos PS")
	g = atk_board("ex5-50", ["Grass", "Grass", "Grass"])
	d = g.opponent_player().active
	hit(g, "Swallow Up")
	check(d.damage == 50, "Swallow Up hace 50 si no (hizo %d)" % d.damage)
	# Groudon ex - Crushing Mantle
	g = atk_board("ex5-93", ["Fighting", "Fighting", "Fighting"])
	me = g.current_player()
	d = g.opponent_player().active
	me.hand.clear()
	me.hand.append_array([id_of("Fire Energy"), id_of("Water Energy"), id_of("Potion"), id_of("Grass Energy")])
	opts = g.legal_actions().filter(func(x): return x["t"] == "attack" and x["a"] == atk_index(g, "Crushing Mantle")).map(func(x): return x["opt"])
	check(opts == [0, 1, 2, 3], "Crushing Mantle ofrece descartar de 0 a 3 Energías de la mano")
	hit(g, "Crushing Mantle", -2, 3)
	check(d.damage == 80 and me.hand == [id_of("Potion")] and me.discard.size() >= 3, "Crushing Mantle descartando 3 hace 80")
	# Kyogre ex - Super Tidal Wave
	g = atk_board("ex5-94", ["Water", "Water", "Water"])
	me = g.current_player()
	d = g.opponent_player().active
	me.hand.clear()
	me.hand.append_array([id_of("Water Energy"), id_of("Potion"), id_of("Water Energy")])
	var deck_n := me.deck.size()
	hit(g, "Super Tidal Wave", -2, true)
	check(d.damage == 70 and me.hand == [id_of("Potion")] and me.deck.size() == deck_n + 2, "Super Tidal Wave: 70 con 2 Energías, que vuelven al mazo")
	# Regirock ex - Tonnage
	g = atk_board("ex5-98", ["Fighting", "Fighting", "Fighting"])
	me = g.current_player()
	d = g.opponent_player().active
	hit(g, "Tonnage", -2, true)
	check(d.damage == 80 and me.active.damage == 30, "Tonnage con la opción: 80 y 30 a sí mismo")
	g = atk_board("ex5-98", ["Fighting", "Fighting", "Fighting"])
	me = g.current_player()
	d = g.opponent_player().active
	hit(g, "Tonnage", -2, false)
	check(d.damage == 60 and me.active.damage == 0, "Tonnage sin la opción: 60")
	# Registeel ex - Steel Wave
	g = atk_board("ex5-99", ["Metal", "Metal", "Metal"])
	opp = g.opponent_player()
	opp.bench.clear()
	var same := ""
	var other := ""
	var dtype: String = opp.active.types()[0]
	for id in CardDB.all_ids():
		if CardDB.is_basic_pokemon(id) and int(CardDB.get_card(id).get("hp", 0)) >= 50:
			if same == "" and CardDB.types(id) == [dtype]:
				same = id
			elif other == "" and not dtype in CardDB.types(id):
				other = id
	opp.bench.append_array([mon(same), mon(other)])
	hit(g, "Steel Wave")
	check(opp.bench[0].damage == 20 and opp.bench[1].damage == 0, "Steel Wave: 20 solo a la Banca del mismo tipo que el Defensor")
	# Typhlosion ex - Split Blast (un solo Defensor: hace 100 y descarta 1)
	g = atk_board("ex2-99", ["Fire", "Fire", "Fire", "Fire", "Fire"])
	d = g.opponent_player().active
	hit(g, "Split Blast")
	check(d.damage == 100 and Energy.total(g.current_player().active) == 4, "Split Blast hace 100 y descarta 1 Energía")


func test_sudden_death() -> void:
	print("Muerte Súbita")
	var g := board("ex1-15", "ex2-100")
	var me := g.current_player()
	var opp := g.opponent_player()
	# A cada uno le queda 1 Premio y los dos Activos quedan fuera de combate a la vez.
	while me.prizes.size() > 1:
		me.deck.append(me.prizes.pop_back())
	while opp.prizes.size() > 1:
		opp.deck.append(opp.prizes.pop_back())
	var sim := g.clone(me.index)
	me.active.damage = me.active.max_hp()
	opp.active.damage = opp.active.max_hp()
	sim.current_player().active.damage = 999
	sim.opponent_player().active.damage = 999
	g.apply({"t": "end"})
	check(g.sudden_death == 1 and g.phase == "setup", "si los dos ganan a la vez empieza la Muerte Súbita (fase %s)" % g.phase)
	check(g.rules.prizes == 1 and g.rules.name.ends_with("Sudden Death"), "con 1 Premio cada uno")
	var ai := SimpleAI.new(3)
	while g.phase == "setup":
		g.apply(ai.choose(g))
	check(g.players.all(func(p): return p.prizes.size() == 1), "cada jugador pone 1 Premio")
	_check_invariants(g, 0)
	check(g.players.all(func(p): return p.discard.is_empty() and p.bench.size() <= 5), "la partida nueva empieza de cero")
	# Las copias que usa la IA para pensar no juegan la Muerte Súbita: cuentan el empate.
	sim.apply({"t": "end"})
	check(sim.phase == "over" and sim.winner == 2 and sim.sudden_death == 0, "en las simulaciones de la IA cuenta como empate")
	# La partida de Muerte Súbita se juega hasta el final
	var steps := 0
	while g.phase != "over" and steps < 4000:
		g.apply(ai.choose(g))
		steps += 1
	check(g.phase == "over" and g.winner != -1, "la Muerte Súbita termina con un ganador (%s)" % g.win_reason)


## La pantalla muestra la moneda ANTES de aplicar la jugada: la calcula en una copia de la
## partida. Las monedas de la copia tienen que ser exactamente las de la partida real.
func test_coin_preview() -> void:
	print("Monedas adelantadas (copia de la partida)")
	var compared := 0
	var mismatches := 0
	for seed_value in 30:
		var g := Game.new(deck(seed_value % 10), deck((seed_value + 3) % 10), seed_value + 100)
		var pick := RandomNumberGenerator.new()
		pick.seed = seed_value
		g.start()
		var steps := 0
		while g.phase != "over" and steps < 1500:
			var acts := g.legal_actions()
			var a: Dictionary = acts[pick.randi() % acts.size()]
			if g.phase == "main" and a["t"] in ["attack", "trainer", "power", "end"]:
				var sim := g.clone()
				var before := g.coin_log.size()
				sim.apply(a)
				g.apply(a)
				var real := g.coin_log.slice(before)
				if not sim.coin_log.is_empty() or not real.is_empty():
					compared += 1
					if sim.coin_log != real or sim.coin_reasons != g.coin_reasons.slice(before):
						mismatches += 1
			else:
				g.apply(a)
			steps += 1
	check(compared > 100 and mismatches == 0, "las monedas de la copia coinciden con las reales (%d jugadas con monedas, %d distintas)" % [compared, mismatches])


func test_opening_coin() -> void:
	print("Moneda inicial")
	# 2004-2007: el que gana la moneda elige si empieza
	var wins := [0, 0]
	for seed_value in range(1, 41):
		var g := Game.new(deck(0), deck(1), seed_value, RuleSet.ex_2005())
		g.ask_first = true
		g.start()
		check(g.phase == "first" and g.actor() == g.coin_winner, "con reglas 2004 el ganador elige (semilla %d)" % seed_value)
		wins[g.coin_winner] += 1
		var me_first := seed_value % 2 == 0
		g.apply({"t": "first", "me": me_first})
		var expected: int = g.coin_winner if me_first else 1 - g.coin_winner
		check(g.phase == "setup" and g.first_player == expected and g.players.all(func(p): return p.hand.size() >= 7),
				"empieza el que se eligió y se reparten las manos")
	check(wins[0] > 5 and wins[1] > 5, "la moneda la ganan los dos jugadores (%s)" % [wins])
	# 2003: el ganador empieza, sin elegir
	var g3 := Game.new(deck(0), deck(1), 7, RuleSet.ex_2003())
	g3.ask_first = true
	g3.start()
	check(g3.phase == "setup" and g3.first_player == g3.coin_winner, "con reglas 2003 el ganador de la moneda empieza")


func test_stats() -> void:
	print("Estadísticas de la partida")
	var g := atk_board("ex3-21", ["Metal", "Metal"])      # Skarmory, Power Count 20
	var me := g.current_player()
	g.apply({"t": "attack", "a": atk_index(g, "Power Count"), "tg": -2, "opt": false})
	var st: Dictionary = g.stats[me.index]
	check(st["dmg"] == 20 and g.mvp(me.index).get("id", "") == "ex3-21" and g.mvp(me.index)["dmg"] == 20,
			"cuenta el daño de los ataques y quién lo hizo (%s)" % [st])
	check(g.stats[1 - me.index]["dmg"] == 0, "el daño propio no se le cuenta al rival")
	var g2 := board("ex1-15", "ex2-100")
	g2.opponent_player().active.damage = 990
	var who := g2.current_player().index
	g2.apply({"t": "end"})
	g2.concede(who)
	check(g2.phase == "over" and g2.winner == 1 - who and g2.win_reason.contains("conceded"), "rendirse le da la victoria al rival")


func test_variants() -> void:
	print("Variantes de personajes y rivales")
	var CS = load("res://engine/campaign_state.gd")
	var c = CS.new()
	c.save_path = "user://campana_variantes.json"
	c.reset()
	c.start(0)
	# Todos los mazos de todas las variantes de rivales son válidos
	for rid in c.data["rivales"]:
		var raw: Dictionary = c.data["rivales"][rid]
		for v in raw.get("variantes", []):
			if v.has("mazo"):
				check(Decks.names().has(v["mazo"]) and Game.validate_deck(Decks.get_deck(v["mazo"])).is_empty(), "mazo de variante de %s válido: %s" % [rid, v["mazo"]])
	check(c.rival("alumno")["mazo"] == "Oasis" and int(c.rival("alumno")["nivel"]) == 1, "sin eventos: la ficha base")
	check(not c.rival("alumno").has("variantes"), "la ficha resuelta no trae la lista de variantes")
	c.beaten["jefe"] = 1
	check(int(c.rival("alumno")["nivel"]) == 2 and c.rival("alumno")["mazo"] == "Oasis", "después del director: nivel 2, mismo mazo")
	c.beaten["alumno"] = 2
	check(c.rival("alumno")["mazo"] == "FireFang" and int(c.rival("alumno")["nivel"]) == 3, "con 2 victorias: mazo nuevo")
	check(c.rival("alumno").has("hola"), "lo que la variante no trae queda como en la ficha base")
	# El premio de una victoria usa la variante de antes de esa victoria
	c.beaten = {"jefe": 1, "alumno": 1}
	c.data["rivales"]["alumno"]["variantes"][0]["dinero_revancha"] = 999
	var rw: Dictionary = c.record_win("alumno")
	check(int(rw["money"]) != 999, "el premio no usa la variante que se abre con esa misma victoria")
	c.data["rivales"]["alumno"]["variantes"][0].erase("dinero_revancha")
	# Condiciones
	c.beaten = {"alumno": 1}
	c.lost = {"alumna": 2}
	check(c.cond_met({"vencer": "alumno"}) and not c.cond_met({"vencer": ["alumno", "jefe"]}), "vencer")
	check(c.cond_met({"no_vencer": "jefe"}) and not c.cond_met({"no_vencer": "alumno"}), "no_vencer")
	check(c.cond_met({"vencidos": 1}) and not c.cond_met({"vencidos": 2}), "vencidos")
	check(c.cond_met({"perdidas": 2}, "alumna") and not c.cond_met({"perdidas": 3}, "alumna"), "perdidas")
	check(c.cond_met({"ganadas_a": {"alumno": 1}}) and not c.cond_met({"perdidas_a": {"jefe": 1}}), "ganadas_a / perdidas_a")
	check(not c.cond_met({"marca": "x"}) and c.cond_met({"sin_marca": "x"}), "sin marca")
	c.mark("x")
	check(c.cond_met({"marca": "x"}) and not c.cond_met({"sin_marca": "x"}), "con marca")
	c.money = 100
	check(c.cond_met({"dinero": 100}) and not c.cond_met({"dinero": 101}), "dinero")
	check(c.cond_met({}) and c.cond_met(null), "sin condiciones: siempre")
	c.starter = "Torrent"
	check(c.cond_met({"inicial": "Torrent"}) and c.cond_met({"inicial": "water"}), "inicial: por nombre o por tipo")
	check(not c.cond_met({"inicial": "Blaze"}) and not c.cond_met({"inicial": "Fire"}), "inicial: otro mazo no")
	check(c.cond_met({"inicial": ["Blaze", "Torrent"]}), "inicial: cualquiera de la lista")
	check(c.starter_title() == "Water", "starter_title da el tipo del inicial")
	var rg: Dictionary = c.resolve({"regalo": {"id": "r", "dar": ["hola"]}, "variantes": [{"si": {"inicial": "Water"}, "regalo": {"cartas": ["ex1-99"]}}]})
	check(rg["regalo"]["id"] == "r" and rg["regalo"]["dar"] == ["hola"] and rg["regalo"]["cartas"] == ["ex1-99"], "regalo sin id en la variante se combina con el de base")
	var rg2: Dictionary = c.resolve({"regalo": {"id": "r", "dar": ["hola"]}, "variantes": [{"si": {"inicial": "Water"}, "regalo": {"id": "otro", "cartas": ["ex1-99"]}}]})
	check(not rg2["regalo"].has("dar"), "regalo con id propio en la variante reemplaza al de base")
	# Personaje del mapa: la variante de una sola vez (con marca)
	var npc := {"frases": ["base"], "variantes": [{"si": {"sin_marca": "hola_1"}, "marcar": "hola_1", "frases": ["primera vez"]}]}
	var r1: Dictionary = c.resolve(npc)
	check(r1["frases"] == ["primera vez"] and r1["marcar"] == "hola_1", "primera vez: la variante")
	c.mark(r1["marcar"])
	check(c.resolve(npc)["frases"] == ["base"], "después: las frases de siempre")
	# Se guarda y se carga
	c.save()
	var c2 = CS.new()
	c2.save_path = "user://campana_variantes.json"
	c2.load_save()
	check(c2.marks.has("hola_1") and c2.marks.has("x"), "las marcas se guardan con la partida")
	c.reset()
	# Mazos de la campaña: 4 lugares, el activo es "deck", y una partida vieja se pasa sola
	c.reset()
	c.start(0)
	check(c.decks.size() == c.DECK_SLOTS and c.active_deck == 0, "4 lugares de mazo, el primero en uso")
	check(c.deck_size(0) == 60 and c.deck_errors().is_empty(), "el mazo inicial está en el lugar 1 y listo")
	check(c.deck_size(1) == 0 and c.deck_name(1) == "Deck 2", "los otros lugares empiezan vacíos")
	c.decks[1] = {"nombre": "Copy", "cartas": c.decks[0]["cartas"].duplicate(true)}
	c.active_deck = 1
	check(c.deck_cards() == c.deck_cards(0) and c.deck == c.decks[1]["cartas"], "el mazo en uso es el del lugar elegido")
	c.active_deck = 2
	check(not c.deck_errors().is_empty(), "un lugar vacío en uso no está listo")
	c.save()
	var raw = JSON.parse_string(FileAccess.get_file_as_string(c.save_path))
	raw.erase("mazos")
	raw.erase("mazo_activo")
	raw["deck"] = c.decks[0]["cartas"]
	var fw := FileAccess.open(c.save_path, FileAccess.WRITE)
	fw.store_string(JSON.stringify(raw))
	fw.close()
	var c3 = CS.new()
	c3.save_path = c.save_path
	c3.load_save()
	check(c3.decks.size() == c3.DECK_SLOTS and c3.active_deck == 0 and c3.deck_size(0) == 60, "una partida de antes de los mazos múltiples se pasa al lugar 1")
	c.reset()
	# Los datos de ejemplo cargan bien
	for m in ["escuela", "patio"]:
		var md = JSON.parse_string(FileAccess.get_file_as_string("res://data/mapas/%s.json" % m))
		for pdef in md["personajes"]:
			for v in pdef.get("variantes", []):
				check(v is Dictionary and v.has("si"), "variante de %s con su \"si\"" % pdef["id"])
		# Objetos: casillas "x,y" dentro del mapa, variantes con "si", regalos con cartas válidas
		var rows: Array = md["baldosas"]
		for key in md.get("objetos_casilla", {}):
			var xy: PackedStringArray = str(key).split(",")
			check(xy.size() == 2 and int(xy[1]) < rows.size() and int(xy[0]) < str(rows[int(xy[1])]).length(), "objeto de %s en una casilla del mapa: %s" % [m, key])
		var all_objs: Array = md.get("objetos", {}).values() + md.get("objetos_casilla", {}).values()
		for o in all_objs:
			for v in o.get("variantes", []):
				check(v is Dictionary and v.has("si"), "variante de objeto con su \"si\" (%s)" % m)
			if o.has("regalo"):
				for cid in o["regalo"].get("cartas", []):
					check(not CardDB.get_card(str(cid)).is_empty(), "carta escondida válida: %s" % cid)


func test_campaign() -> void:
	print("Campaña")
	var CS = load("res://engine/campaign_state.gd")
	var c = CS.new()
	c.save_path = "user://campana_prueba.json"
	c.reset()
	check(not c.is_started(), "empieza sin partida")
	c.start(0)
	check(c.is_started() and c.deck_cards().size() == 60 and c.deck_errors().is_empty(), "el mazo inicial es válido (%s)" % [c.deck_errors()])
	check(c.total_cards() > 20 and c.owned(CardDB.find("Fire Energy")) >= 60, "la colección tiene las cartas del mazo y Energías básicas sin límite")
	for rid in c.data["rivales"]:
		var r: Dictionary = c.rival(rid)
		check(Decks.names().has(r["mazo"]) and Game.validate_deck(Decks.get_deck(r["mazo"])).is_empty(), "el mazo de %s es válido" % r["nombre"])
	for st in c.data["starters"]:
		check(Decks.entries(st["deck"]).any(func(e): return e[0] == st["carta"]), "la carta de muestra de %s está en el mazo" % st["deck"])
	var map = JSON.parse_string(FileAccess.get_file_as_string("res://data/mapas/%s.json" % c.start_place()["mapa"]))
	check(map is Dictionary and map.has("baldosas"), "el mapa del inicio existe")
	var rw: Dictionary = c.record_win("alumno")
	check(rw["packs"] == int(c.rival("alumno").get("sobres", 1)) and rw["set"] == c.rival("alumno")["sobre"] and rw["first"], "la primera victoria da los sobres del rival")
	rw = c.record_win("alumno")
	check(rw["packs"] == 1 and not rw["first"], "la revancha da 1 sobre")
	check(c.gift_ready({"vencer": "alumno"}) and not c.gift_ready({"vencer": ["alumno", "alumna"]}), "requiere: vencer a uno o a varios")
	var m0: int = int(c.data.get("dinero_inicial", 0))
	c.beaten = {}
	c.money = m0
	rw = c.record_win("alumno")
	check(c.money == m0 + int(c.rival("alumno").get("dinero", 0)) and rw["money"] == int(c.rival("alumno").get("dinero", 0)), "ganar da el dinero del rival")
	var m1: int = c.money
	c.record_win("alumno")
	check(c.money == m1 + int(c.rival("alumno").get("dinero_revancha", 0)), "la revancha da su dinero")
	check(c.buy(100) and c.money == m1 + int(c.rival("alumno").get("dinero_revancha", 0)) - 100, "comprar descuenta el precio")
	check(not c.buy(999999), "sin plata no se compra")
	check(not c.shop_items("bridgette").is_empty(), "la tienda de Bridgette vende sobres")
	check(not c.rematch_available("alumno"), "sin vencer al director no hay revanchas")
	c.beaten["jefe"] = 1
	check(c.rematch_available("alumno"), "con el director vencido se abren las revanchas")
	c.record_loss("alumna")
	check(c.lost.get("alumna", 0) == 1, "se anota cuando un rival te gana")
	c.place = {"mapa": "escuela", "x": 3, "y": 4, "dir": "left"}
	c.save()
	var c3 = CS.new()
	c3.save_path = c.save_path
	check(c3.load_save() and c3.start_place()["x"] == 3 and c3.start_place()["dir"] == "left", "se guarda dónde quedaste")
	var before: int = c.total_cards()
	var pack: Array = c.open_pack("ex1")
	check(pack.size() == 9 and c.total_cards() == before + 9, "un sobre trae 9 cartas y van a la colección")
	check(pack.all(func(id): return id.begins_with("ex1-") and not CardDB.is_basic_energy(id)), "las cartas son de esa expansión")
	var ok_packs := 0
	for i in 200:
		var pk: Array = c.open_pack(["ex1", "ex2", "ex3", "ex4", "ex5"][i % 5])
		var commons: int = pk.slice(0, 4).filter(func(id): return c.rarity[id] == "Common").size()
		var rv: String = c.rarity.get(pk[c.last_reverse], "") if c.last_reverse >= 0 else "?"
		if pk.size() == 9 and commons == 4 and c.rarity.get(pk[8], "").begins_with("Rare") \
				and c.last_reverse == 7 and not rv in ["Rare Holo EX", "Rare Secret", "?"]:
			ok_packs += 1
	check(ok_packs == 200, "cada sobre: 4 comunes, una reverse holo (no ex) y una rara al final (%d/200)" % ok_packs)
	check(not c.reverse.is_empty(), "las reverse holo quedan anotadas en la colección")
	var c2 = CS.new()
	c2.save_path = c.save_path
	check(c2.load_save() and c2.beaten == c.beaten and c2.total_cards() == c.total_cards() and c2.deck == c.deck, "se guarda y se carga el progreso")
	c2.deck.append(["ex1-1", 4])
	check(not c2.deck_errors().is_empty(), "no se puede usar más copias de las que tenés")
	c.reset()


func test_special_fx() -> void:
	print("Animaciones especiales")
	var FX = load("res://scenes/special_fx.gd")
	check(FX.species("Team Aqua's Kyogre") == "Kyogre", "especie sin el Team")
	check(FX.species("Rayquaza ex") == "Rayquaza", "especie sin ex")
	check(FX.signature("Blaziken ex") == "fuego3", "Blaziken ex tiene la de fuego de Hoenn")
	check(FX.signature("Aggron") == "", "Aggron usa la del tipo")
	# Tiras de efectos opcionales (efectos/propios): sin archivo, no hay textura
	check(FX.fx("_no_existe") == null and FX.fx_count("_no_existe") == 0, "efecto que falta: null")
	DirAccess.make_dir_recursive_absolute("user://efectos/propios")
	var strip := Image.create(96, 32, false, Image.FORMAT_RGBA8)
	strip.save_png("user://efectos/propios/_prueba.png")
	FX.fx_reload()
	check(FX.fx_count("_prueba") == 3, "tira de 96x32 = 3 cuadros")
	check(FX.fx_frame("_prueba", 0.0) == 0 and FX.fx_frame("_prueba", 0.99) == 2 and FX.fx_frame("_prueba", 1.0) == 2, "cuadro según el avance")
	DirAccess.remove_absolute("user://efectos/propios/_prueba.png")
	var wide := Image.create(480, 112, false, Image.FORMAT_RGBA8)
	wide.save_png("user://efectos/propios/_pantalla.png")
	var jf := FileAccess.open("user://efectos/propios/_pantalla.json", FileAccess.WRITE)
	jf.store_string('{"celda": [240, 112]}')
	jf.close()
	FX.fx_reload()
	check(FX.fx_cell("_pantalla") == Vector2(240, 112) and FX.fx_count("_pantalla") == 2, "tira de pantallas no cuadradas (con su .json)")
	DirAccess.remove_absolute("user://efectos/propios/_pantalla.png")
	DirAccess.remove_absolute("user://efectos/propios/_pantalla.json")
	FX.fx_reload()
	check(FX.rivalry("Kyogre ex", "Team Magma's Groudon").get("title", "") != "", "Kyogre vs Groudon")
	check(FX.rivalry("Groudon ex", "Kyogre ex")["key"] == FX.rivalry("Kyogre ex", "Groudon ex")["key"], "misma clave en los dos sentidos")
	check(FX.rivalry("Seviper", "Team Magma's Zangoose").get("title", "") != "", "Zangoose vs Seviper")
	check(FX.rivalry("Torchic", "Mudkip")["title"].contains("Hoenn"), "iniciales de Hoenn")
	check(FX.rivalry("Charizard", "Mudkip")["title"] == "Starter showdown!", "iniciales de distintas regiones")
	check(FX.rivalry("Torchic", "Blaziken").is_empty(), "mismo tipo: no hay cara a cara")
	check(FX.rivalry("Kyogre ex", "Aggron").is_empty(), "sin rival")
	check(FX.power("ex1-73") < FX.power("ex4-89"), "el Básico hace el efecto más chico que el ex")
	check(FX.signature_against("Kyogre ex", "Groudon ex") == "kyogre", "Kyogre contra Groudon: animación propia")
	check(FX.signature_against("Kyogre ex", "Aggron") == "", "Kyogre contra otro: la del tipo")
	check(FX.signature_against("Torchic", "Treecko") == "fuego3", "inicial contra inicial de otro tipo")
	check(FX.signature_against("Torchic", "Combusken") == "", "inicial contra uno de su mismo tipo: la del tipo")
	check(FX.signature_against("Heracross", "Pinsir") == "heracross", "Heracross contra Pinsir")
	check(FX.rivalry("Pinsir", "Heracross")["title"] == "Horn against pincers!", "cara a cara Heracross y Pinsir")


func test_dual_type() -> void:
	print("Doble tipo (Team Aqua / Team Magma)")
	# Team Magma's Groudon es Lucha y Oscuro: le pega x2 a los débiles a cualquiera de los dos
	var g := board("ex4-9", "ex2-61")             # contra Duskull (débil a Oscuro)
	var a: PokemonInPlay = g.current_player().active
	check(a.is_type("Fighting") and a.is_type("Darkness"), "Groudon de Magma es Lucha y Oscuro")
	# Duskull es débil a Oscuro pero resiste Lucha: se aplican las dos (20 x2 - 30 = 10)
	check(g.deal_attack_damage(a, g.opponent_player().active, 20, true, {}) == 10, "Debilidad a Oscuro y Resistencia a Lucha a la vez")
	g = board("ex4-9", "ex1-30")                  # contra Electrike (débil a Lucha)
	a = g.current_player().active
	check(g.deal_attack_damage(a, g.opponent_player().active, 20, true, {}) == 40, "Debilidad a Lucha: x2")
	# Y recibe Debilidad por cualquiera de sus dos tipos (la de la carta)
	var w: Array = CardDB.get_card("ex4-9").get("weaknesses", [])
	check(not w.is_empty(), "su Debilidad sale de la carta: %s" % str(w))


func test_secret_gifts() -> void:
	print("Secret rare: no salen en sobres, son regalos")
	var CS = load("res://engine/campaign_state.gd")
	var c = CS.new()
	c.save_path = "user://campana_regalos_prueba.json"
	c.reset()
	c.start(0, "Prueba")
	var secrets := 0
	for i in 600:
		for id in c.open_pack(["ex3", "ex4", "ex5"][i % 3]):
			if c.rarity.get(id, "") == "Rare Secret":
				secrets += 1
	check(secrets == 0, "en 600 sobres de Dragon/Magma-Aqua/Hidden Legends no sale ninguna secret rare")
	check(not c.gift_ready({"vencer": "alumna"}), "el regalo espera que le ganes al rival")
	c.beaten["alumna"] = 1
	check(c.gift_ready({"vencer": "alumna"}), "con el rival vencido, el regalo está listo")
	var before: int = c.owned("ex3-98")
	check(c.give_gift("charmander_secreto", ["ex3-98"]) and c.owned("ex3-98") == before + 1, "el regalo suma la carta")
	check(not c.give_gift("charmander_secreto", ["ex3-98"]) and c.owned("ex3-98") == before + 1, "y solo se da una vez")
	c.load_save()
	check(c.gifts.has("charmander_secreto"), "queda guardado")
	c.reset()


func test_frlg_to_emerald() -> void:
	print("FireRed & LeafGreen, Team Rocket Returns, Deoxys, Emerald")
	var fire := id_of("Fire Energy")
	var water := id_of("Water Energy")
	var dark := "ex9-86"
	# Magic Odds (Mr. Mime ex): no recibe daño impar (30), sí par (40)
	var g := board("ex1-15", "ex6-110")
	var d := g.opponent_player().active
	g.deal_attack_damage(g.current_player().active, d, 30, true, {"w": true, "r": true})
	check(d.damage == 0, "Magic Odds previene 30 (hizo %d)" % d.damage)
	g.deal_attack_damage(g.current_player().active, d, 40, true, {"w": true, "r": true})
	check(d.damage == 40, "Magic Odds no previene 40")
	# Empty Shell (Shedinja): el rival no toma Premios
	g = board("ex1-15", "ex8-14")
	var prizes := g.current_player().prizes.size()
	g.opponent_player().active.damage = 999
	g._check_knockouts()
	check(g.current_player().prizes.size() == prizes, "Empty Shell: no se toman Premios")
	# Buffer (Jumpluff): con cara queda con 10 PS
	var saved := 0
	for sd in 12:
		g = board("ex1-15", "ex7-11", sd + 3)
		d = g.opponent_player().active
		g.deal_attack_damage(g.current_player().active, d, 300, true, {"w": true, "r": true})
		if d.hp_left() == 10:
			saved += 1
	check(saved > 0 and saved < 12, "Buffer salva a veces (%d/12)" % saved)
	# Snorlax (Toss and Turn): se puede usar Dormido y suma 30
	g = board("ex6-15", "ex1-15")
	var sn := g.current_player().active
	sn.energy.append_array([fire, fire, fire])
	sn.rotation = "asleep"
	var acts := g.legal_actions().filter(func(a): return a["t"] == "attack")
	check(acts.size() == 1 and sn.attacks()[acts[0]["a"]]["name"] == "Toss and Turn", "Toss and Turn se usa Dormido")
	# Dark Marowak (Hard Bone): una opción por Pokémon de la mano; sin Pokémon no hay ataque
	g = board("ex7-7", "ex1-15")
	g.current_player().active.energy.append_array([id_of("Fighting Energy"), id_of("Fighting Energy"), fire])
	g.current_player().hand.clear()
	check(not g.legal_actions().any(func(a): return a["t"] == "attack" and g.current_player().active.attacks()[a["a"]]["name"] == "Hard Bone"), "Hard Bone necesita un Pokémon en la mano")
	g.current_player().hand.append(id_of("Mudkip"))
	acts = g.legal_actions().filter(func(a): return a["t"] == "attack" and g.current_player().active.attacks()[a["a"]]["name"] == "Hard Bone")
	check(acts.size() == 1 and acts[0]["opt"] == id_of("Mudkip"), "Hard Bone ofrece descartar Mudkip")
	# Dual Armor (Rocket's Scizor ex con Metal): Oscuro y Metálico
	g = board("ex7-101", "ex1-15")
	g.current_player().active.energy.append("ex9-88")
	Abilities.refresh(g)
	check(g.current_player().active.is_type("Darkness") and g.current_player().active.is_type("Metal"), "Dual Armor")
	# Energías nuevas
	var p := mon("ex7-101", ["ex7-94"])
	check(Energy.count_type(p, "Darkness") == 1 and Energy.count_type(p, "Metal") == 1 and Energy.total(p) == 1, "Dark Metal Energy da 1 Oscura o Metálica")
	check(Energy.can_attach("ex7-95", mon("ex7-101")) and not Energy.can_attach("ex7-95", mon(id_of("Mudkip"))), "R Energy solo a Dark/Rocket's")
	check(Energy.total(mon("ex7-101", ["ex7-95"])) == 2, "R Energy da 2")
	g = board(id_of("Marshtomp"), "ex1-15")
	var mt := g.current_player().active
	mt.cards.push_front(id_of("Mudkip"))
	mt.energy.append("ex8-95")
	g.current_player().prizes.append("ex1-1")
	Abilities.refresh(g)
	check(Energy.total(mt) == 3, "Scramble Energy da 3 con más Premios (%d)" % Energy.total(mt))
	# Rocket's Hideout: +20 PS a Dark/Rocket's
	g = board("ex7-101", "ex1-15")
	g.set_stadium(g.current_player(), "ex7-87")
	Abilities.refresh(g)
	check(g.current_player().active.max_hp() == CardDB.hp("ex7-101") + 20, "Rocket's Hideout suma 20 PS")
	# Meteor Falls: el evolucionado usa los ataques de su Básico
	g = board(id_of("Marshtomp"), "ex1-15")
	g.current_player().active.cards.push_front(id_of("Mudkip"))
	g.set_stadium(g.current_player(), "ex8-89")
	Abilities.refresh(g)
	var names: Array = g.current_player().active.attacks().map(func(a): return a["name"])
	var mud_atk: String = CardDB.get_card(id_of("Mudkip"))["attacks"][0]["name"]
	check(mud_atk in names, "Meteor Falls da los ataques del Básico")
	# Space Center apaga los Poké-Bodies de los Básicos que no son ex (Drowzee se puede dormir;
	# Mr. Mime ex sigue con Magic Odds)
	g = board("ex1-15", "ex7-54")
	check(not Abilities.can_have_condition(g, g.opponent_player().active, "asleep"), "Insomnia")
	g.set_stadium(g.current_player(), "ex8-91")
	check(Abilities.can_have_condition(g, g.opponent_player().active, "asleep"), "Space Center apaga Insomnia")
	g.opponent_player().active = mon("ex6-110")
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 30, true, {"w": true, "r": true})
	check(g.opponent_player().active.damage == 0, "Space Center no afecta a los ex")
	# Sunbeam (Solrock en juego): Lunatone tiene 80 PS
	g = board("ex8-36", "ex1-15")
	g.current_player().bench[0] = mon("ex8-47")
	Abilities.refresh(g)
	check(g.current_player().active.max_hp() == 80, "Sunbeam")
	# Energy Protection (Metapod): -10 por Energía, máximo 30
	g = board("ex1-15", "ex6-39")
	g.opponent_player().active.energy.append_array([fire, fire, fire, fire])
	g.deal_attack_damage(g.current_player().active, g.opponent_player().active, 50, true, {"w": true, "r": true})
	check(g.opponent_player().active.damage == 20, "Energy Protection reduce hasta 30")
	# Dark Raticate (Dark Seed): 5 contadores al final del turno siguiente del rival
	g = board("ex7-17", "ex1-15")
	g.current_player().active.energy.append(dark)
	d = g.opponent_player().active
	hit(g, "Dark Seed")
	check(d.flags.has("delayed_counters"), "Dark Seed marca al Defensor")
	g._end_turn()
	check(d.damage == 0, "Dark Seed todavía no")
	g.apply({"t": "end"})
	check(d.damage == 50, "Dark Seed pone 5 contadores (%d)" % d.damage)
	# Strange Behavior (Slowbro): mueve contadores a sí mismo, varias veces
	g = board("ex6-14", "ex1-15")
	g.current_player().bench[0].damage = 30
	acts = g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Strange Behavior")
	check(acts.size() == 1, "Strange Behavior disponible")
	g.apply(acts[0])
	g.apply(g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Strange Behavior")[0])
	check(g.current_player().active.damage == 20 and g.current_player().bench[0].damage == 10, "Strange Behavior x2")
	# Form Change (Deoxys): cambia por otra forma del mazo y la vieja queda arriba
	g = board("ex8-16", "ex1-15")
	g.current_player().deck.append("ex8-17")
	acts = g.legal_actions().filter(func(a): return a["t"] == "power" and a["n"] == "Form Change")
	check(acts.size() == 1, "Form Change disponible")
	g.apply(acts[0])
	check(g.current_player().active.top() == "ex8-17" and g.current_player().deck[-1] == "ex8-16", "Form Change")
	check(not g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Form Change"), "Form Change una vez por turno")
	# Legendary Ascent (Articuno ex): al bajarlo, pasa a Activo y se lleva las Agua
	g = board("ex1-15", "ex1-15")
	var me := g.current_player()
	me.active.energy.append_array([water, water, fire])
	me.hand.clear()
	me.hand.append("ex6-114")
	g.apply(g.legal_actions().filter(func(a): return a["t"] == "bench")[0])
	g.apply({"t": "choose", "i": 0})        # usarlo
	while g.phase == "choice" and g.pending_prompt().contains("Energy to move"):
		var ch := g.choice_options()
		var k := 0
		for i in ch.size():
			if ch[i]["id"] != "":
				k = i
		g.apply({"t": "choose", "i": k})
	check(me.active.top() == "ex6-114" and me.active.energy.size() == 2, "Legendary Ascent (%s, %d)" % [me.active.display_name(), me.active.energy.size()])
	# Wise Aura (Medicham ex Activo): los que no son ex no usan Poké-Powers
	g = board("ex1-15", "ex9-95")
	g.current_player().active = mon("ex6-10")      # Pidgeot (Quick Search)
	check(not g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Quick Search"), "Wise Aura bloquea Quick Search")
	# Mt. Moon: menos de 70 PS no usan Poké-Powers (Mantine 70 sí)
	g = board("ex7-45", "ex1-15")
	g.current_player().bench[0].damage = 10
	g.set_stadium(g.current_player(), "ex6-94")
	check(g.legal_actions().any(func(a): return a["t"] == "power" and a["n"] == "Ripples") == (CardDB.hp("ex7-45") >= 70), "Mt. Moon")
	# Temporada 2004-05: legal hasta la promo 27 y POP 1
	var r := RuleSet.from_season(1)
	check(r.is_legal("np-27") and not r.is_legal("np-28") and r.is_legal("pop1-1") and r.is_legal("ex9-1"), "2004-05: np 1-27, POP 1, Emerald")
	check(not RuleSet.from_season(0).is_legal("np-27") and not RuleSet.from_season(0).is_legal("ex6-1"), "2003-04 no incluye np-27 ni FRLG")
	check(r.missing_sets().is_empty(), "2004-05 completa")
	# El formato rechaza mazos con cartas de afuera (las reimpresiones de Entrenadores valen)
	check(Game.validate_deck(Decks.get_deck("Blaze"), r).is_empty(), "Blaze es legal en 2004-05")
	var worlds := Game.validate_deck(Decks.get_deck("Magma Spirit (Worlds 2004)"), r)
	check(not worlds.is_empty() and worlds[-1].begins_with("Not legal"), "un mazo e-card no es legal en 2004-05 (%s)" % str(worlds))
	check(Game.validate_deck(Decks.get_deck("Magma Spirit (Worlds 2004)"), RuleSet.from_season(0)).is_empty(), "pero sí en 2003-04")
	check(r.is_legal("ecard1-157") and not r.is_legal("ecard1-1"), "Switch de Expedition vale por la reimpresión; Alakazam no")
	var frlg: Array[String] = []
	frlg.assign(Decks.get_deck("Blaze"))
	frlg[0] = "ex6-105"
	check(not Game.validate_deck(frlg, RuleSet.from_season(0)).is_empty(), "Charizard ex de FRLG no es legal en 2003-04")


func test_holon() -> void:
	print("Unseen Forces, Delta Species, Legend Maker, Holon Phantoms")
	# δ Rainbow Energy: cualquier tipo solo en Pokémon δ
	var g := board("ex13-1", "ex1-15")
	var arm := g.current_player().active
	arm.energy.append("ex13-98")
	Abilities.refresh(g)
	check(Energy.count_type(arm, "Water") == 1, "δ Rainbow da cualquier tipo a un δ")
	g = board(id_of("Mudkip"), "ex1-15")
	var mk := g.current_player().active
	mk.energy.append("ex13-98")
	Abilities.refresh(g)
	check(Energy.count_type(mk, "Water") == 0 and Energy.total(mk) == 1, "δ Rainbow da Incolora a un no-δ")
	# Holon's Castform se puede unir como Energía
	g = board(id_of("Mudkip"), "ex1-15")
	g.current_player().active.energy.append(id_of("Water Energy"))   # solo va a un Pokémon con Energía
	g.current_player().hand.append("ex13-44")
	check(g.legal_actions().any(func(a): return a["t"] == "energy" and g.current_player().hand[a["h"]] == "ex13-44"), "Holon's Castform aparece como Energía")
	# Golden Wing (Ho-Oh ex): mover Energías sin duplicar cartas
	g = board("ex1-15", "ex10-104")
	var opp := g.opponent_player()
	var ho := opp.active
	ho.energy.append_array([id_of("Fire Energy"), id_of("Fire Energy")])
	opp.bench.append(mon(id_of("Mudkip")))
	var before: int = opp.discard.size() + opp.all_in_play().reduce(func(s, x): return s + x.all_cards().size(), 0)
	g.deal_attack_damage(g.current_player().active, ho, 999, true, {"w": true, "r": true})
	g._check_knockouts()
	var guard := 0
	while g.has_pending_choices() and guard < 20:
		g.apply(g.legal_actions()[0])
		guard += 1
	var after: int = opp.discard.size() + opp.all_in_play().reduce(func(s, x): return s + x.all_cards().size(), 0)
	check(after == before, "Golden Wing no duplica cartas (%d → %d)" % [before, after])
	# Formato 2005-06: promos 34 fuera, Holon Phantoms dentro, Base de RS fuera
	var idx := -1
	for i in RuleSet.SEASONS.size():
		if RuleSet.SEASONS[i]["id"] == "2005-06":
			idx = i
	check(idx >= 0, "existe la temporada 2005-06")
	var r := RuleSet.from_season(idx)
	check(r.is_legal("ex13-1") and r.is_legal("np-35") and not r.is_legal("np-34"), "legalidad de promos 2005-06")
	check(not r.is_legal("ex4-1") and r.is_legal("ex5-1"), "Team Magma vs Team Aqua fuera, Hidden Legends dentro")


func test_dx() -> void:
	print("Crystal Guardians, Dragon Frontiers, Power Keepers")
	# Crystal Beach: Double Rainbow Energy da 1 sola Incolora
	var g := board("ex13-10", "ex1-15")
	var kd := g.current_player().active
	kd.energy.append("ex14-88")
	Abilities.refresh(g)
	check(Energy.total(kd) == 2, "Double Rainbow da 2 Energías")
	g.stadium = "ex14-75"
	Abilities.refresh(g)
	check(Energy.total(kd) == 1 and Energy.count_type(kd, "Fire") == 0, "Crystal Beach la deja en 1 Incolora")
	# Holon Legacy: los δ no tienen Debilidad
	check(not Abilities.weakness_types(g, kd).is_empty(), "Kingdra δ tiene Debilidad")
	g.stadium = "ex15-74"
	check(Abilities.weakness_types(g, kd).is_empty(), "Holon Legacy: sin Debilidad")
	# Intimidating Armor: los Básicos del rival no atacan
	g = board(id_of("Mudkip"), "ex14-89")
	check(Abilities.attack_blocked(g, g.current_player().active), "Intimidating Armor frena a un Básico")
	# Extra Liquid: los ex pagan una Incolora más
	g = board("ex14-89", "ex14-96")
	g.opponent_player().active.cards.push_front(id_of("Treecko"))     # que sea evolucionado (no Básico)
	var cost := Abilities.attack_cost(g, g.current_player().active, g.current_player().active.attacks()[0])
	check(cost.size() == 4, "Extra Liquid suma una Incolora (%d)" % cost.size())
	# Shock-wave: marca y KO
	g = board("ex15-99", "ex1-15")
	var ty := g.current_player().active
	ty.energy.append_array([id_of("Lightning Energy"), id_of("Lightning Energy"), id_of("Lightning Energy")])
	var opp := g.opponent_player()
	g.apply({"t": "attack", "a": 0, "tg": -1, "opt": false})
	while g.has_pending_choices():
		g.apply(g.legal_actions()[0])
	check(opp.active != null and opp.active.flags.get("shock_wave", false), "Electromark pone el marcador")
	# Formato 2006-07
	var idx := -1
	for i in RuleSet.SEASONS.size():
		if RuleSet.SEASONS[i]["id"] == "2006-07":
			idx = i
	var r := RuleSet.from_season(idx)
	check(r.is_legal("ex16-1") and r.is_legal("np-40") and r.is_legal("ex8-1"), "2006-07: Power Keepers, promo 40 y Deoxys")
	check(not r.is_legal("ex7-1"), "2006-07: Team Rocket Returns fuera")


func test_rock_slide() -> void:
	print("Rock Slide (Graveler): 20 al Activo y 10 a 2 de la Banca")
	var g := board("ex12-34", id_of("Torchic"))
	var gr := g.current_player().active
	gr.energy.append_array([id_of("Fighting Energy"), id_of("Fighting Energy")])
	var opp := g.opponent_player()
	opp.bench.append(mon(id_of("Wurmple")))
	var act := opp.active
	g.apply({"t": "attack", "a": 0, "tg": -2, "opt": false})
	var guard := 0
	while g.has_pending_choices() and guard < 10:
		g.apply(g.legal_actions()[0])
		guard += 1
	check(act.damage >= 20, "el Activo recibe el daño base (%d)" % act.damage)
	check(opp.bench.filter(func(x): return x.damage == 10).size() == 2, "dos de la Banca reciben 10")


func test_delta_evolution() -> void:
	print("δ no es parte del nombre al evolucionar")
	var cases := [["ex14-49", "ex14-30", "Charmander δ → Charmeleon δ"],
		["ex14-48", "ex14-30", "Charmander → Charmeleon δ"]]
	for cs in cases:
		var g := board(cs[0], id_of("Torchic"))
		g.turn_number += 2
		var me := g.current_player()
		me.turns_taken = 3
		me.active.turn_played = 0
		me.hand.append(cs[1])
		var h := me.hand.size() - 1
		var ok := g.legal_actions().any(func(a): return a.get("t") == "evolve" and a.get("h") == h)
		check(ok, cs[2])
	check(CardDB.evolves_onto("ex14-30", "Charmander δ") and not CardDB.evolves_onto("ex14-30", "Charmeleon"), "evolves_onto ignora δ")
	var dk: Array[String] = []
	for i in 3:
		dk.append("ex14-48")
		dk.append("ex14-49")
	check(Game.validate_deck(dk).any(func(e): return "copies of Charmander" in e), "4 copias: Charmander y Charmander δ cuentan juntos")


func test_prize_pick() -> void:
	print("Elegir Premio (reglas reales)")
	var g := board(id_of("Torchic"), id_of("Torchic"))
	var me := g.current_player()
	var opp := g.opponent_player()
	opp.bench.append(PokemonInPlay.new(id_of("Torchic")))
	g.prize_pick = [true, true]
	me.prizes = ["ex1-3", "ex1-19", "ex1-40", "ex1-51", "ex1-62", "ex1-73"] as Array[String]
	me.flags["faceup_prizes"] = ["ex1-19"]
	var hand0 := me.hand.size()
	opp.active.damage = 999
	g._check_knockouts()
	g._continue_after_choices()
	check(g.pending_choice_kind() == "prize" and g.actor() == me.index, "el que hace KO elige Premio primero")
	check(g.legal_actions().size() == 6, "5 Premios + quedarse con el apartado")
	g.apply({"t": "choose", "k": 1})
	check(me.hand.size() == hand0 + 1 and me.hand.has("ex1-19") and not me.prizes.has("ex1-19"), "se lleva el elegido")
	check(me.prizes.has("ex1-73") and me.prizes.size() == 5, "el apartado vuelve a los Premios")
	check(not me.flags["faceup_prizes"].has("ex1-19"), "ya no figura boca arriba")
	check(g.pending_choice_kind() == "promote" and g.actor() == opp.index, "después el rival manda su Activo")
	var g2 := board(id_of("Torchic"), id_of("Torchic"))
	g2.opponent_player().bench.append(PokemonInPlay.new(id_of("Torchic")))
	g2.opponent_player().active.damage = 999
	g2._check_knockouts()
	g2._continue_after_choices()
	check(g2.pending_choice_kind() == "promote", "la IA no elige Premio (sin prize_pick)")
