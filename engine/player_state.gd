class_name PlayerState
extends RefCounted
## Todo lo que pertenece a un jugador.

var deck_log: Array = []   # compartido con Game.deck_log (robos y barajadas, para animar)
var index := 0
var deck: Array[String] = []
var hand: Array[String] = []
var discard: Array[String] = []
var prizes: Array[String] = []
var active: PokemonInPlay = null
var active2: PokemonInPlay = null   # segundo Activo (solo en batallas dobles)
var bench: Array[PokemonInPlay] = []
var turns_taken := 0
var mulligans := 0
var mull_hands: Array = []   # las manos que mostró al rival en cada mulligan (para verlas en pantalla)
var mull_bonus := 0          # cartas extra que puede robar por los mulligans del rival (elige cuántas)

# Límites por turno
var energy_attached := false
var supporter_played := false
var flags := {}                 # efectos sobre el jugador: {"no_supporter": turno hasta el que dura}
var stadium_played := false
var retreated := false
var turn_flags := {}            # p.ej. {"heal_dance": true}


func reset_turn_limits() -> void:
	energy_attached = false
	supporter_played = false
	stadium_played = false
	retreated = false
	turn_flags.clear()


const ACTIVE2 := -3      # lugar del segundo Activo (-2 ya se usa como "sin objetivo")

## -1 = Activo, -3 = segundo Activo (dobles), 0..n = Banca
func slot(i: int) -> PokemonInPlay:
	if i == -1:
		return active
	if i == ACTIVE2:
		return active2
	return bench[i] if i >= 0 and i < bench.size() else null


func slot_of(p: PokemonInPlay) -> int:
	if p == active:
		return -1
	if p == active2:
		return ACTIVE2
	return bench.find(p)


static func is_active_slot(s: int) -> bool:
	return s == -1 or s == ACTIVE2


## Los Activos que hay (uno o dos).
func actives() -> Array[PokemonInPlay]:
	var out: Array[PokemonInPlay] = []
	if active != null:
		out.append(active)
	if active2 != null:
		out.append(active2)
	return out


func is_active(p: PokemonInPlay) -> bool:
	return p != null and (p == active or p == active2)


## Intercambia los dos Activos de lugar (para que el segundo actúe como "el" Activo).
func swap_actives() -> void:
	var t := active
	active = active2
	active2 = t


func all_in_play() -> Array[PokemonInPlay]:
	var out: Array[PokemonInPlay] = []
	if active != null:
		out.append(active)
	if active2 != null:
		out.append(active2)
	for b in bench:
		if b != null:
			out.append(b)
	return out


func slots() -> Array[int]:
	var out: Array[int] = []
	if active != null:
		out.append(-1)
	if active2 != null:
		out.append(ACTIVE2)
	for i in bench.size():
		out.append(i)
	return out


func draw(n: int = 1) -> int:
	var drawn := 0
	for i in n:
		if deck.is_empty():
			break
		hand.append(deck.pop_back())
		drawn += 1
	if drawn > 0:
		deck_log.append({"k": "draw", "p": index, "ids": hand.slice(hand.size() - drawn)})
	return drawn


func count_in_play(pred: Callable) -> int:
	return all_in_play().filter(pred).size()
