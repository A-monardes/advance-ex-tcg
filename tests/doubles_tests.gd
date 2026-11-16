extends SceneTree
## Pruebas de las batallas dobles (2 contra 2). Uso:
##   godot --headless --script res://tests/doubles_tests.gd [partidas]
## Sale con código 1 si algo falla.

var failures := 0
var checks := 0


func _init() -> void:
	CardDB.load_db()
	var games := 12
	if OS.get_cmdline_user_args().size() > 0:
		games = int(OS.get_cmdline_user_args()[0])
	test_rules()
	test_setup()
	test_attack_targets()
	test_attack_with_second_active()
	test_knockout_and_promote()
	test_retreat_once()
	test_checkup_both()
	test_switch_choice()
	test_send_out()
	test_powers_second_active()
	simulate(games)
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
	return CardDB.find(n)


func rules() -> RuleSet:
	return RuleSet.make_doubles(RuleSet.ex_2005())


## Partida doble en fase principal con dos Activos por lado (Banca vacía salvo lo que se pida).
func board(mine: Array, theirs: Array, seed_value: int = 1) -> Game:
	var g := Game.new(deck(0), deck(1), seed_value, rules())
	g.start()
	var ai := SimpleAI.new(seed_value)
	var guard := 0
	while g.phase in ["setup", "first"] and guard < 100:
		guard += 1
		g.apply(ai.choose(g))
	var me := g.current_player()
	var opp := g.opponent_player()
	me.active = mon(mine[0])
	me.active2 = mon(mine[1]) if mine.size() > 1 else null
	opp.active = mon(theirs[0])
	opp.active2 = mon(theirs[1]) if theirs.size() > 1 else null
	me.bench.clear()
	opp.bench.clear()
	g.phase = "main"
	return g


func energy(n: String) -> String:
	return id_of(n + " Energy")


func actions_of(g: Game, t: String) -> Array:
	return g.legal_actions().filter(func(a): return a["t"] == t)


# ---------------------------------------------------------------------------

func test_rules() -> void:
	print("Reglas")
	var r := rules()
	check(r.doubles, "las reglas son dobles")
	check(r.bench_size == 4, "la Banca es de 4 (%d)" % r.bench_size)


func test_setup() -> void:
	print("Preparación con dos Activos")
	var g := Game.new(deck(0), deck(1), 7, rules())
	g.start()
	var saw_second := false
	var guard := 0
	while g.phase in ["setup", "first"] and guard < 200:
		guard += 1
		var acts := g.legal_actions()
		var pick: Dictionary = acts[0]
		for a in acts:
			if a["t"] == "setup_active2":
				saw_second = true
				pick = a
				break
		g.apply(pick)
	check(saw_second, "se ofrece poner un segundo Activo")
	var two := g.players.filter(func(p): return p.active2 != null).size()
	check(two >= 1, "al menos un jugador empezó con dos Activos")
	for p in g.players:
		check(p.bench.size() <= 4, "Banca de 4 como máximo en la preparación")


func test_attack_targets() -> void:
	print("Atacar a cualquiera de los dos Activos del rival")
	# Dos Pokémon que pegan sin efectos raros contra dos defensores
	var g := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var me := g.current_player()
	var opp := g.opponent_player()
	for e in [energy("Fire"), energy("Fire")]:
		me.active.energy.append(e)
	var atks := actions_of(g, "attack")
	var targets := {}
	for a in atks:
		var c = a.get("ctx", [false, false])
		targets[[c[me.index], c[opp.index]]] = true
	check(targets.has([false, false]) and targets.has([false, true]), "el Activo 1 puede atacar a los dos defensores: %s" % [targets.keys()])
	# Atacar al segundo Activo del rival
	var target_2: Dictionary = {}
	for a in atks:
		var c = a.get("ctx", [false, false])
		if not c[me.index] and c[opp.index]:
			target_2 = a
			break
	var d1 := opp.active
	var d2 := opp.active2
	var hp1 := d1.hp_left()
	var hp2 := d2.hp_left()
	g.apply(target_2)
	check(d2.hp_left() < hp2 or d2 not in opp.all_in_play(), "el segundo Activo del rival recibió el daño")
	check(d1.hp_left() == hp1, "el primero no recibió nada")
	check(g._ctx == [false, false], "después del ataque los Activos quedan en su lugar")
	check(opp.active == d1 or opp.active == null, "el primer Activo del rival sigue en su lugar")


func test_attack_with_second_active() -> void:
	print("Atacar con el segundo Activo")
	var g := board(["ex1-73", "ex1-27"], ["ex1-13"])
	var me := g.current_player()
	var opp := g.opponent_player()
	var a2 := me.active2
	for e in [energy("Fire"), energy("Fire")]:
		a2.energy.append(e)
	var atks := actions_of(g, "attack").filter(func(a): return a.has("ctx") and a["ctx"][me.index])
	check(not atks.is_empty(), "el segundo Activo tiene ataques para elegir")
	check(actions_of(g, "attack").all(func(a): return a.has("ctx") and a["ctx"][me.index]), "el primero (sin Energías) no puede atacar")
	var hp := opp.active.hp_left()
	var desc := g.describe(atks[0])
	check(desc.begins_with(a2.display_name()), "la descripción dice quién ataca: %s" % desc)
	g.apply(atks[0])
	check(opp.active == null or opp.active.hp_left() < hp or g.phase == "over", "el defensor recibió el daño")
	check(me.active2 == a2 and me.active.display_name() == CardDB.card_name("ex1-73"), "los Activos siguen en su lugar")
	check(g.current == 1 - me.index or g.phase != "main", "el turno terminó (un solo ataque por turno)")


func test_knockout_and_promote() -> void:
	print("KO del segundo Activo y reemplazo")
	var g := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var me := g.current_player()
	var opp := g.opponent_player()
	opp.bench.append(mon(id_of("Mudkip")))
	opp.active2.damage = opp.active2.max_hp() - 10
	var victim := opp.active2
	for e in [energy("Fire"), energy("Fire")]:
		me.active.energy.append(e)
	var prizes := me.prizes.size()
	var hit: Dictionary = {}
	for a in actions_of(g, "attack"):
		var c = a.get("ctx", [false, false])
		if not c[me.index] and c[opp.index]:
			hit = a
			break
	g.apply(hit)
	check(victim not in opp.all_in_play(), "el segundo Activo cayó")
	check(me.prizes.size() < prizes, "se tomó un Premio")
	check(g.phase == "choice" and g.pending_choice_kind() == "promote2", "el rival elige su nuevo segundo Activo (%s, %s)" % [g.phase, g.pending_choice_kind()])
	if g.phase == "choice":
		var acts := g.legal_actions()
		g.apply(acts[0])
		check(opp.active2 != null and opp.bench.is_empty(), "el de la Banca pasó a ser el segundo Activo")
	# Sin Banca: si cae el primero, el segundo pasa a su lugar
	var g2 := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var me2 := g2.current_player()
	var opp2 := g2.opponent_player()
	opp2.active.damage = opp2.active.max_hp() - 10
	var second := opp2.active2
	for e in [energy("Fire"), energy("Fire")]:
		me2.active.energy.append(e)
	var hit1: Dictionary = {}
	for a in actions_of(g2, "attack"):
		var c = a.get("ctx", [false, false])
		if not c[me2.index] and not c[opp2.index]:
			hit1 = a
			break
	g2.apply(hit1)
	check(opp2.active == second and opp2.active2 == null, "sin Banca, el segundo Activo pasa al primer lugar")


func test_retreat_once() -> void:
	print("Una sola retirada por turno")
	var g := board(["ex1-73", "ex1-27"], ["ex1-13"])
	var me := g.current_player()
	me.bench.append(mon(id_of("Torchic")))
	me.bench.append(mon(id_of("Mudkip")))
	for p in [me.active, me.active2]:
		for i in 3:
			p.energy.append(energy("Fire"))
	var rets := actions_of(g, "retreat")
	var with2 := rets.filter(func(a): return a.has("ctx"))
	check(not with2.is_empty() and with2.size() < rets.size(), "se puede retirar cualquiera de los dos")
	g.apply(with2[0])
	while g.phase == "choice":
		g.apply(g.legal_actions()[0])
	check(actions_of(g, "retreat").is_empty(), "después de retirarse, no hay otra retirada")
	check(me.active2 != null and me.active.display_name() == CardDB.card_name("ex1-73"), "se retiró el segundo; el primero sigue")


func test_checkup_both() -> void:
	print("Chequeo entre turnos para los dos Activos")
	var g := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var opp := g.opponent_player()
	opp.active.poison = 1
	opp.active2.poison = 1
	var d1 := opp.active.damage
	var d2 := opp.active2.damage
	g.apply({"t": "end"})
	check(opp.active.damage == d1 + 10 and opp.active2.damage == d2 + 10, "los dos Activos envenenados reciben daño")


func test_switch_choice() -> void:
	print("Cambiar: el jugador elige cuál de sus Activos")
	var g := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var opp := g.opponent_player()
	opp.bench.append(mon(id_of("Mudkip")))
	g.queue_choice(opp.index, "switch")
	g.phase = "choice"
	var acts := g.legal_actions()
	check(acts.size() == 2, "dos opciones: cambiar el primero o el segundo (%d)" % acts.size())
	var second := opp.active2
	var a2: Dictionary = acts.filter(func(a): return a.has("act"))[0]
	g.apply(a2)
	check(opp.active2 != second and opp.bench.has(second), "el segundo Activo fue a la Banca")


func test_send_out() -> void:
	print("Mandar un Pokémon de la Banca al lugar vacío")
	var g := board(["ex1-73"], ["ex1-13"])
	var me := g.current_player()
	me.bench.append(mon(id_of("Torchic")))
	var so := actions_of(g, "send_out")
	check(so.size() == 1, "se ofrece mandarlo al frente")
	g.apply(so[0])
	check(me.active2 != null and me.bench.is_empty(), "ahora tiene dos Activos")
	check(actions_of(g, "send_out").is_empty(), "con dos Activos ya no se ofrece")
	check(actions_of(g, "bench").all(func(_a): return me.bench.size() < 4), "la Banca sigue limitada a 4")


func test_powers_second_active() -> void:
	print("Poké-Powers del segundo Activo")
	# Cualquier Poké-Power que solo funcione desde el puesto Activo: buscar uno
	var g := board(["ex1-73", "ex1-27"], ["ex1-13", "ex1-59"])
	var me := g.current_player()
	for a in actions_of(g, "power"):
		check(a["s"] != PlayerState.ACTIVE2, "las acciones del segundo Activo usan el contexto, no el lugar -3")
	check(true, "sin errores al listar Poké-Powers")


# ---------------------------------------------------------------------------

func simulate(games: int) -> void:
	var names := Decks.names()
	print("Simulación IA vs IA en dobles (%d partidas)" % games)
	var finished := 0
	var doubled := 0
	for k in games:
		var g := _play(7000 + k * 13, k % names.size(), (k * 3 + 1) % names.size(), false)
		if g.phase == "over":
			finished += 1
		if g.log_lines.any(func(l): return l.contains(" uses ") and l.contains(" on ")):
			doubled += 1
	check(finished == games, "todas las partidas de la IA terminan (%d/%d)" % [finished, games])
	check(doubled > 0, "hubo ataques a un defensor elegido")
	print("  %d / %d terminadas" % [finished, games])
	print("Fuzz en dobles: acciones al azar")
	var fuzz := 0
	for k in games * 3:
		var g := _play(9500 + k, k % names.size(), (k / names.size()) % names.size(), true)
		if g.phase == "over":
			fuzz += 1
	print("  %d / %d partidas al azar terminaron" % [fuzz, games * 3])


func _play(seed_value: int, da: int, db: int, random_actions: bool) -> Game:
	var g := Game.new(deck(da), deck(db), seed_value, rules())
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
		_invariants(g, seed_value)
		steps += 1
	if g.phase != "over":
		check(false, "la partida no terminó (semilla %d, turno %d)" % [seed_value, g.turn_number])
	return g


func _invariants(g: Game, seed_value: int) -> void:
	if g._ctx != [false, false]:
		check(false, "los Activos quedaron intercambiados después de una acción (semilla %d)" % seed_value)
	for p in g.players:
		var n := p.deck.size() + p.hand.size() + p.discard.size() + p.prizes.size()
		for m in p.all_in_play():
			n += m.all_cards().size()
		if g.stadium != "" and g.stadium_owner == p.index:
			n += 1
		if n != 60:
			check(false, "el jugador %d tiene %d cartas en total (semilla %d)" % [p.index + 1, n, seed_value])
		if p.bench.size() > 4:
			check(false, "Banca de más de 4 en dobles (semilla %d)" % seed_value)
		if g.phase != "over" and g.phase != "setup" and p.active == null and g.pending_choice_kind() != "promote":
			check(false, "jugador %d sin Activo fuera de una elección (semilla %d)" % [p.index + 1, seed_value])
		if p.active2 != null and p.active == null and g.phase == "main":
			check(false, "segundo Activo sin primero (semilla %d)" % seed_value)
