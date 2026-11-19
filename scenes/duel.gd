extends Node2D
## Pantalla de duelo estilo GBA (240x160). Solo dibuja y lee el teclado:
## todas las reglas viven en engine/. El jugador humano es el Jugador 1.
##
## Controles: Flechas = mover · Z / Enter = aceptar · X / Esc = volver
##            Tab = registro · C = ver carta · ←/→ en el título = cambiar opción

const W := 240
const H := 160
const FONT_SIZE := 10   # letra pixel propia (fonts/gba.fnt): celdas de 10 px
const TEXT_BASE := 8    # línea de base del texto, desde el borde de arriba del renglón
const TEXT_H := 10      # alto que ocupa un renglón de texto en los recuadros
const LINE := 13        # renglones del cuadro de texto (como en los juegos de GBA)
const LINE_S := 11      # renglones de las listas (registro, mano, fichas)
const BOX_Y := 112
const VISIBLE_LINES := 3
const AI_DELAY := 1.1      # pausa entre jugadas de la IA (Z la adelanta)
const INFO_IMG := 40       # imagen en la ficha de carta
const BANNER_W := 76       # arte completo (apaisado) arriba a la derecha de la ficha
const BANNER_H := 50
const SET_TOTAL := {"ex1": 109, "ex2": 100, "ex3": 97, "ex4": 95, "ex5": 101, "ecard1": 165, "ecard2": 147, "ecard3": 144}
const INFO_GAP := 5        # espacio entre ataques (y habilidades) en la ficha
const MENU_IMG := 40       # imagen junto al menú (igual que en la ficha)
const MENU_LINES := 3      # opciones visibles (la 4ª línea son las teclas)
const PORTRAIT := 30
const HD_SCALE := 4        # en modo "Nítido" las imágenes tienen 4 veces más píxeles (30x30 -> 120x120)
const SETTINGS_PATH := "user://ajustes.cfg"
const SPRITE_DIRS := ["res://sprites", "user://sprites"]
const C_POWER := Color("#8c1c1c")    # Poké-Power: rojo oscuro
const C_BODY := Color("#1c6a2c")     # Poké-Body: verde oscuro
const ANIM_TIME := 1.0
const ANIM_IMPACT := 0.55
const ENERGY_TIME := 0.7    # segundos por Energía unida
const MARQUEE_HOLD := 0.9   # pausa al principio y al final del texto que se desplaza
const MARQUEE_STEP := 0.11  # segundos por letra
const SHUFFLE_TIME := 0.9
const DRAW_FLY := 0.45     # segundos que tarda cada carta robada en llegar a la mano
# Robo de 1 o 2 cartas tuyas: cada una sale del mazo al centro, se ve en primer plano y va a la mano
const CU_IN := 0.32
const CU_HOLD := 0.85
const CU_OUT := 0.32
const CU_MAX := 2          # con más cartas (la mano inicial, Professor Birch...) se ve el robo de siempre
const PRIZE_TIME := 2.0
const KO_TIME := 1.6
const TRAINER_TIME := 1.4  # carta de Entrenador mostrada en la mesa       # animación de fuera de combate
const BANNER_TIME := 1.2   # cartel de "¡Tu turno!"
const ANIM_SPEEDS := [1.0, 1.7, 2.6]
const ANIM_SPEED_NAMES := ["Normal", "Fast", "Very fast"]    # segundos por Premio (Z lo acelera)
const EVO_TIME := 1.4      # segundos por evolución
const EVO_FLASH := 0.68    # momento del destello final (fracción)
const COIN_TIME := 1.5     # segundos por moneda
const COIN_FAST := 0.25    # con Z

# Paleta estilo GBA: colores vivos, de 15 bits.
const C_BG := Color("#283858")
const C_FIELD := Color("#6c9cf0")
const C_LINE := Color("#405080")
const C_PANEL := Color("#f8f8f8")
const C_PANEL_DARK := Color("#d0d0c8")
const C_TEXT := Color("#484850")
const C_LIGHT := Color("#f8f8f8")
const C_DIM := Color("#8890a0")
const C_KEYS := Color("#8890a0")
const C_ACCENT := Color("#f8d030")
const C_SOURCE := Color("#58b0f0")   # Pokémon de donde sale algo (Energía que se mueve, retirada)
const C_HP_OK := Color("#58d080")
const C_HP_LOW := Color("#e04030")
const C_INK := Color("#202838")         # contornos
const C_SHADOW_L := Color("#d0d0c8")    # sombra de la letra oscura
const C_SHADOW_D := Color("#283048")    # sombra de la letra clara
const C_FRAME_OUT := Color("#283858")
const C_FRAME_MID := Color("#6890d0")
const C_FRAME_HI := Color("#a8c8f8")
const C_YELLOW := Color("#f8d830")      # borde de las cartas EX
const C_YELLOW_D := Color("#c09810")
const C_YELLOW_L := Color("#f8f0a0")
const TYPE_DARK := {"Fire": Color("#b83010"), "Water": Color("#1850b0"), "Grass": Color("#207820"),
		"Lightning": Color("#b08800"), "Psychic": Color("#703090"), "Fighting": Color("#804818"),
		"Darkness": Color("#282838"), "Metal": Color("#606878"), "Colorless": Color("#988f80")}
const TYPE_LIGHT := {"Fire": Color("#f8b088"), "Water": Color("#98c8f8"), "Grass": Color("#a8e888"),
		"Lightning": Color("#f8f090"), "Psychic": Color("#e0a8f0"), "Fighting": Color("#f0b888"),
		"Darkness": Color("#9898b0"), "Metal": Color("#e0e8f0"), "Colorless": Color("#f8f8f0")}
const TABLE_DIRS := ["res://fondos", "user://fondos"]   # fondos de mesa (PNG); se pueden agregar
const TABLE_NAMES := {"bosque": "Forest", "sabana": "Savanna", "desierto": "Desert", "ciudad": "City",
		"risco": "Cliff", "volcan": "Volcano", "nieve": "Snow", "cueva": "Cave", "playa": "Beach",
		"fondo marino": "Seafloor", "rio": "River", "cielo": "Sky", "lunares": "Polka Dots",
		"maquina": "Machine", "baldosas": "Tiles", "estrellas": "Stars", "liso": "Plain"}
# Fondos para distinguir: turnos del registro (alternados) y fichas de cada jugador.
const C_BAND := [Color("#f8f8f8"), Color("#e0e8f8")]
const C_MINE_BG := Color("#d8e4f8")
const C_OPP_BG := Color("#f8dcd4")
const C_STADIUM_BG := Color("#f0ecc0")
const TYPE_COLORS := {
	"Fire": Color("#f86838"), "Water": Color("#4890f8"), "Grass": Color("#50c048"),
	"Lightning": Color("#f8d020"), "Psychic": Color("#b060d0"), "Fighting": Color("#c87838"),
	"Darkness": Color("#585870"), "Metal": Color("#a0a8b8"), "Colorless": Color("#e0d8c8"),
	"*": Color("#f070c0"),
}
const CATEGORY := {
	"bench": "Pokémon", "evolve": "Pokémon", "send_out": "Pokémon", "energy": "Energy", "trainer": "Trainer",
	"power": "Poké-Power", "retreat": "Retreat", "attack": "Attack", "end": "End turn",
}
const CATEGORY_ORDER := ["Attack", "Poké-Power", "Pokémon", "Energy", "Trainer", "Retreat", "End turn"]
const TYPE_ES := {"Fire": "Fire", "Water": "Water", "Grass": "Grass", "Lightning": "Lightning", "Psychic": "Psychic",
		"Fighting": "Fighting", "Darkness": "Darkness", "Metal": "Metal", "Colorless": "Colorless"}

var font: Font
var hd := false              # siempre a píxel exacto (240x160 agrandado, como una GBA)
var table_style := 0         # diseño de la mesa: índice en table_styles (0 = Clásica)
var table_styles: Array = []  # [[nombre, ruta]]; la primera es la Clásica (rojo y azul)
const FONT_PATH := "res://fonts/gba.fnt"      # letra pixel propia (tools/gba_font.py)
var font_bold: Font
var mode := "title"          # title | duel | editor
const DeckEditorScript := preload("res://scenes/deck_editor.gd")
const CampaignScript := preload("res://scenes/campaign.gd")
var campaign                 # pantallas de la campaña (scenes/campaign.gd)
var campaign_rival := ""     # rival de la campaña del duelo en curso ("" = duelo libre)
var reverse_ids := {}        # cartas tuyas que tenés en reverse holo (campaña): se ven con brillo en el marco
const SoundScript := preload("res://scenes/sound.gd")
const SpecialFX := preload("res://scenes/special_fx.gd")
var snd                      # sonido (scenes/sound.gd)
var arte: ArteHD             # arte de las cartas en alta (ficha y galería)
var pmd_web: PmdWeb          # versión web: baja los sprites de PMD que hacen falta
var gallery_id := ""         # carta en la vista de galería ("" = cerrada)
var sq_edit := false         # en la galería (solo desde el editor): ajustando el cuadrado chico
var _hd_tex := {}            # clave -> Texture2D del arte grande (banner y galería)
var sfx_level := 2           # volumen de efectos: 0 apagado … 3 alto
var music_level := 2         # volumen de la música
var over_sound_done := false
var editor                   # editor de mazos (scenes/deck_editor.gd)
var title_msg := ""
var title_row := 0           # fila elegida en el menú principal (ver _draw_title)
const TITLE_ITEMS := ["Campaign", "Options", "Edit decks", "Free duel", "Online duel"]
const TITLE_ROWS := 5
var duel_row := 0            # fila elegida en el armado del duelo libre (title_view "duel")
const DUEL_ROWS := 6
## La campaña está en desarrollo: en el juego publicado aparece como "coming soon" y no se
## puede entrar. Desde el editor de Godot sí, para seguir trabajándola.
var CAMPAIGN_ON := OS.has_feature("editor")
var title_view := ""          # "" menú principal | "options" | "duel" (armado del duelo libre)
var opt_cursor := 0
var my_deck := 0
var opp_deck := 1
var season_idx := 0            # temporada elegida (RuleSet.SEASONS): sets legales y reglas de ese año
var doubles_mode := false      # duelo libre en batalla doble (2 contra 2)

var game: Game
var ai: SimpleAI
var human := 0
# --- Partida en línea (engine/net_link.gd + scenes/online.gd) ---
# Los dos juegos calculan la misma partida: misma semilla, mismos mazos, y cada uno le pasa
# al otro el número de cada acción que elige (su lugar en game.legal_actions()).
var net: NetLink = null          # null = partida local contra la IA
var net_in := 0                  # acciones del rival ya aplicadas
var net_out := 0                 # acciones tuyas ya mandadas
var net_lost := ""               # se cortó la conexión o se perdió la sincronía: mensaje
var online                       # pantalla de "Online duel" (scenes/online.gd)
var ai_timer := 0.0

var menu_level := "root"     # root | list
var menu_items: Array = []   # [{label, action?, category?}]
var cursor := 0
var scroll := 0
var category := ""
var menu_turn := -1          # turno al que pertenece el menú (al cambiar, vuelve al principal)
var show_log := false
var log_scroll := 0
var info_lines: Array = []   # si no está vacío, se muestra la ficha de una carta
var info_offset := 0
var info_more := false       # la ficha sigue más abajo (se calcula al dibujarla)
var info_nav: Array = []     # fichas vecinas para ◀▶: Callables que devuelven las líneas
var info_nav_i := 0
var info_nav_sync := Callable()   # mueve el cursor de donde se abrió (mano, mesa, editor)
var info_attach: Array = []       # [jugador, lugar] si la ficha es de un Pokémon en juego
var info_stack: Array = []        # fichas de las que se vino (Z en un Pokémon -> sus cartas unidas)
var board_view := false      # recorrer la mesa (tecla B)
var board_sel := [0, -1]     # [jugador, casilla]: -1 = Activo, 0..4 = Banca
var pile_view := ""          # "" | "hand" (tecla M) | "discard" (tecla D)
var pile_side := 0           # descarte: 0 = el tuyo, 1 = el del rival
var hand_cursor := 0
# Pantallas de la preparación: "mull" (las manos de los mulligans, la tuya y la del rival)
# y "hand" (tu mano, para poner el Activo y la Banca). X la cierra y M la vuelve a abrir.
var setup_screen := ""
var setup_cursor := 0
var mull_page := 0
var _mull_shown := false
var _setup_closed := false
var anim := {}               # animación de ataque en curso
var animations_on := true
var energy_anim: Array = []  # Energías que se están uniendo: [{"p", "mon", "id", "from", "t"}]
var marquee_t0 := {}         # texto que se desplaza: clave -> momento en que empezó
var prize_anim: Array = []   # Premios por mostrar: entradas de game.prize_log + "t"
var prize_seen := 0
var prize_cursor := 0
var trainer_anim := {}        # Entrenador que se acaba de jugar: {"id", "p", "dest", "t"}
var power_anim := {}          # Poké-Power: el Pokémon sale con su sprite de PMD y actúa (ver _start_power_anim)
var _last_power := {}         # el último Poder mostrado (si se repite en el turno, va la versión corta)
var supporter_table := [{}, {}]   # Supporter jugado este turno por cada jugador: {"id", "turn"}
var ko_anim: Array = []       # [{"p", "slot", "id", "name", "t"}]
var check_anim: Array = []    # daño de veneno/quemadura entre turnos, después del ataque: [{"p", "mon", "kind", "dmg", "t"}]
var checkup_seen := 0
var hp_hold := {}             # Pokémon -> PS que se siguen mostrando hasta que se vea su daño de veneno/quemadura
var ko_seen := 0
var banner := {}              # cartel de cambio de turno: {"p", "turn", "t"}
var rival_intro := {}         # presentación del rival al empezar un duelo de la campaña: {"t", "rival", "me"}
const RIVAL_INTRO_TIME := 1.9
var rival_sprite := ""        # el personaje del mapa del rival (para la pantalla del final)
var ex_shine := {}            # Pokémon ex recién llegados a la mesa: PokemonInPlay -> {"t", "snd"}
var ex_seen := {}             # PokemonInPlay -> carta de arriba ya anunciada (para no repetir el brillo)
const EX_SHINE_TIME := 0.9
var results_t := 0.0          # tiempo en la pantalla del final (para los saltos de los personajes)
var turn_seen := 0
var sudden_seen := 0          # Muertes Súbitas ya anunciadas
var intro := ""               # moneda inicial: "call" (elegir cara o cruz), "coin" (girando) o ""
var paused := false           # menú de pausa (P / Start, o X en el menú principal)
var pause_cursor := 0
var pause_view := ""          # "" | "controls" | "quit"
var quit_yes := false
const PAUSE_ITEMS := ["Resume", "Animations", "Battles", "Sound FX", "Music", "Table", "Controls", "Concede"]
var anim_speed := 0           # índice en ANIM_SPEEDS
var battle_mode := 1          # al atacar: 0 en la mesa, 1 mini pelea (Mystery Dungeon)
const BATTLE_MODES := ["Off", "Mini"]
var ai_level := 3             # dificultad del rival: 1 Principiante … 5 Experto
var hp_shown := {}           # Pokémon -> PS que se muestran (bajan de a poco hasta los reales)
var deck_anim: Array = []    # barajadas y robos por mostrar: entradas de game.deck_log + "t", "dur"
var deck_seen := 0
var evo_anim := {}           # evolución en curso: {"list", "i", "t"}
var evo_seen := 0
var coin_anim := {}          # monedas por mostrar: {"results", "i", "t", "per"}
var coins_seen := 0
var _coin_sets: Array = []   # monedas de mundo/propios/monedas/: [cara, cruz] (tools/armar_monedas.py)
var _coins_loaded := false
var coin_pick := -1          # la moneda de esta partida (al azar; -1 = la moneda dibujada de siempre)
var vs_anim := {}            # cara a cara de rivales: {"t", "a", "b", "title", "ca", "cb"}
var vs_seen := {}            # cara a cara ya mostrados en esta partida
var move_anim: Array = []    # Pokémon que cambian de lugar: [{"items": [...], "t", "dur", "text"}]
const MOVE_TIME := 0.5       # bajar a la Banca desde la mano
const SWAP_TIME := 0.65      # retirarse / pasar al puesto Activo
var _sprites := {}           # id de carta -> Texture2D (o null si no hay imagen)


var title_attract := false      # la escena animada con "PRESS START" (solo al abrir el juego)
var title_scene := TitleScene.new()
var _attract_t := 0.0


func _ready() -> void:
	randomize()
	title_scene.pick()          # sin escenas propias (como en la web) queda solo el fondo y el logo
	title_attract = true        # siempre: ahí va el aviso de proyecto de fans
	if not CAMPAIGN_ON:
		title_row = TITLE_ROWS - 1        # "Free duel"
	font = _load_pixel_font()
	_load_settings()
	CardDB.load_db()
	editor = DeckEditorScript.new(self)
	online = load("res://scenes/online.gd").new(self)
	campaign = CampaignScript.new(self)
	snd = SoundScript.new()
	add_child(snd)
	snd.set_levels(sfx_level, music_level)
	if OS.has_feature("web"):
		# En el navegador la ventana es la página: escala libre (no solo enteros), centrada
		get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	pmd_web = PmdWeb.new()
	add_child(pmd_web)
	arte = ArteHD.new()
	add_child(arte)
	arte.listo.connect(_on_arte_listo)
	RenderingServer.set_default_clear_color(C_BG)


# ===========================================================================
# Flujo
# ===========================================================================

func _start_duel() -> void:
	var names := Decks.names()
	campaign_rival = ""
	reverse_ids = {}
	_begin_duel(Decks.get_deck(names[my_deck]), Decks.get_deck(names[opp_deck]), ai_level,
			"Your deck: %s. Opponent: %s." % [names[my_deck], names[opp_deck]])


## Duelo de la campaña contra un rival de la Liga.
func start_campaign_duel(mine: Array[String], theirs: Array[String], level: int, rival_id: String) -> void:
	campaign_rival = rival_id
	reverse_ids = {}
	for id in campaign.st.reverse:
		if campaign.st.reverse[id] > 0:
			reverse_ids[id] = true
	var rv: Dictionary = campaign.st.rival(rival_id)
	_begin_duel(mine, theirs, level, "Campaign: duel against %s." % rv.get("nombre", rival_id))
	var rsprite := ""
	for n in campaign.world.npcs:
		if str(n["def"].get("rival", "")) == rival_id:
			rsprite = str(n["sprite"])
	rival_intro = {"t": 0.0, "rival": str(rv.get("nombre", rival_id)), "deck": str(rv.get("mazo", "")),
			"me": campaign.st.player_name if campaign.st.player_name != "" else "You", "sprite": rsprite}
	rival_sprite = rsprite


## Partida en línea: los dos juegos la arman igual (mazo del que creó la sala primero).
func start_net_duel(link: NetLink, decks: Array, seed_value: int, season: int, doubles: bool) -> void:
	net = link
	net_in = 0
	net_out = 0
	net_lost = ""
	campaign_rival = ""
	reverse_ids = {}
	season_idx = season
	doubles_mode = doubles
	var a: Array[String] = []
	var b: Array[String] = []
	a.assign(decks[0])
	b.assign(decks[1])
	_begin_duel(a, b, ai_level, "Online duel · room %s." % link.room, seed_value)
	human = link.you


func _begin_duel(mine: Array[String], theirs: Array[String], level: int, intro_line: String, seed_value: int = 0) -> void:
	if seed_value == 0:
		_net_close()
		human = 0
	var rules := RuleSet.from_season(season_idx)
	if doubles_mode and campaign_rival == "":
		rules = RuleSet.make_doubles(rules)
	game = Game.new(mine, theirs, seed_value, rules)
	pmd_web.want_cards(mine + theirs)          # web: baja los sprites de PMD de los dos mazos
	snd.jingle(["comenzar_partida"])      # la música del duelo arranca cuando termina
	game.log_msg(intro_line)
	game.log_msg("Rules: " + rules.name)
	ai = SimpleAI.new(0, level)
	game.ask_first = true
	game.start()
	mode = "duel"
	show_log = false
	info_lines = []
	info_stack.clear()
	menu_level = "root"
	coins_seen = game.coin_log.size()
	coin_anim = {}
	_load_coins()
	coin_pick = randi() % _coin_sets.size() if not _coin_sets.is_empty() else -1    # una moneda al azar
	vs_anim = {}
	vs_seen = {}
	move_anim = []
	anim = {}
	evo_anim = {}
	evo_seen = game.evolve_log.size()
	prize_seen = game.prize_log.size()
	prize_anim = []
	hp_shown = {}
	ko_anim = []
	ko_seen = game.ko_log.size()
	check_anim = []
	checkup_seen = game.checkup_log.size()
	hp_hold = {}
	ex_shine = {}
	ex_seen = {}
	rival_sprite = ""
	results_t = 0.0
	trainer_anim = {}
	power_anim = {}
	_last_power = {}
	_body_pops = []
	_body_pop = {}
	supporter_table = [{}, {}]
	banner = {}
	turn_seen = 0
	sudden_seen = 0
	setup_screen = ""
	setup_cursor = 0
	mull_page = 0
	_mull_shown = false
	_setup_closed = false
	over_sound_done = false
	deck_seen = game.deck_log.size()
	deck_anim = []
	energy_anim = []
	intro = "call"          # primero, la moneda inicial: cara o cruz
	_rebuild_menu()


## Al empezar: cada uno baraja y roba su mano (los mulligans no se repiten en pantalla).
func _queue_opening_anims() -> void:
	deck_seen = game.deck_log.size()
	if not animations_on:
		return
	for i in 2:
		deck_anim.append({"k": "shuffle", "p": i, "t": 0.0, "dur": SHUFFLE_TIME})
	for i in 2:
		var ids: Array = game.players[i].hand.slice(0, game.rules.hand_size)
		deck_anim.append({"k": "draw", "p": i, "ids": ids, "t": 0.0, "dur": _draw_duration(ids.size())})


## Elegiste cara o cruz: gira la moneda y se ve quién la ganó.
func _opening_call(heads: bool) -> void:
	var won := game.coin_winner == human
	intro = "coin"
	menu_items.clear()
	var after := func():
		intro = ""
		if game.phase == "setup":      # reglas 2003: el ganador empieza
			_queue_opening_anims()
		ai_timer = AI_DELAY
		_rebuild_menu()
	if animations_on:
		coin_anim = {"results": [heads if won else not heads], "reasons": ["start"], "i": 0, "t": 0.0, "per": COIN_TIME,
				"then": after, "won": won, "label": "You chose %s." % ("heads" if heads else "tails")}
	else:
		after.call()


func _process(delta_real: float) -> void:
	var delta: float = delta_real * ANIM_SPEEDS[anim_speed]   # velocidad de las animaciones
	_update_trans(delta_real)
	if net != null:
		_net_poll()
	if mode == "title" and title_view == "online":
		online.update(delta_real)
	if mode == "title" and title_attract:
		_attract_t += delta_real
	if mode == "campaign":
		campaign.update(delta_real)
	if mode == "duel" and paused:
		_update_music()
		queue_redraw()
		return
	var was_info := bool(_slides.get("info", {}).get("open", false))
	_slide_step("info", not info_lines.is_empty(), delta_real)
	_slide_step("hand", pile_view != "", delta_real)
	_slide_step("log", show_log, delta_real)
	if was_info and info_lines.is_empty() and not _last_info.is_empty():
		_info_ghost = _last_info          # se cerró la ficha: sale deslizándose hacia abajo
		_info_ghost_t = 0.0
	_last_info = info_lines
	if _info_ghost_t >= 0.0:
		_info_ghost_t += minf(delta_real, 1.0 / 30.0) / SLIDE_TIME
		if _info_ghost_t >= 1.0 or not info_lines.is_empty():
			_info_ghost_t = -1.0
			_info_ghost = []
	if mode == "duel" and not rival_intro.is_empty():
		rival_intro["t"] += minf(delta_real, 1.0 / 30.0)
		if rival_intro["t"] >= RIVAL_INTRO_TIME:
			rival_intro = {}
	if mode == "duel" and game != null:
		_update_hp(delta)
		if game.phase == "main" and game.current == human and game.turn_number != menu_turn and menu_level != "root":
			menu_level = "root"            # turno nuevo: el menú principal desde el primer cuadro
			category = ""
			menu_items.clear()
	if mode == "duel" and game.ko_log.size() > ko_seen:
		for e in game.ko_log.slice(ko_seen):
			if animations_on:
				var d: Dictionary = e.duplicate()
				d["t"] = 0.0
				ko_anim.append(d)
		ko_seen = game.ko_log.size()
	if mode == "duel" and game != null:
		if not _waiting_human():
			idle_since = Time.get_ticks_msec() / 1000.0
		_update_ex_shine(delta)
		if _results_showing():
			results_t += delta_real
	if mode == "duel" and game.sudden_death > sudden_seen:
		# Muerte Súbita: partida nueva con los mismos mazos y 1 Premio
		sudden_seen = game.sudden_death
		turn_seen = 0
		vs_seen = {}
		supporter_table = [{}, {}]
		trainer_anim = {}
		power_anim = {}
		menu_level = "root"
		board_view = false
		pile_view = ""
		banner = {"p": -1, "turn": 0, "t": 0.0, "sudden": true}
		_rebuild_menu()
	if mode == "duel" and game.turn_number > turn_seen and game.phase in ["main", "choice"] and not banner.get("sudden", false):
		turn_seen = game.turn_number
		if animations_on:
			banner = {"p": game.current, "turn": game.turn_number, "t": 0.0}
	if mode == "duel" and game.prize_log.size() > prize_seen:
		for e in game.prize_log.slice(prize_seen):
			if animations_on:
				var d: Dictionary = e.duplicate()
				d["t"] = 0.0
				d["choose"] = e["p"] == human and net == null     # vos elegís cuál de tus Premios boca abajo tomar
				prize_anim.append(d)
		prize_seen = game.prize_log.size()
	if mode == "duel" and game.deck_log.size() > deck_seen:
		for e in game.deck_log.slice(deck_seen):
			if animations_on:
				var d: Dictionary = e.duplicate()
				d["t"] = 0.0
				d["dur"] = SHUFFLE_TIME if d["k"] == "shuffle" else _draw_duration(d["ids"].size())
				if d["k"] == "draw" and d["p"] == human and d["ids"].size() <= CU_MAX and game.phase != "setup":
					d["closeup"] = true
					d["dur"] = d["ids"].size() * (CU_IN + CU_HOLD + CU_OUT)
				deck_anim.append(d)
		deck_seen = game.deck_log.size()
	_update_music()
	if mode == "duel":
		_anim_sounds()
	_update_body_pop(delta)
	if not power_anim.is_empty():
		_update_power(delta)
	elif not trainer_anim.is_empty():
		_update_trainer(delta)
	elif not coin_anim.is_empty():
		_update_coins(delta)
	elif not evo_anim.is_empty():
		_update_evo(delta)
	elif not anim.is_empty():
		_update_anim(delta)
	elif not check_anim.is_empty():
		_update_check(delta)
	elif not ko_anim.is_empty():
		_update_ko(delta)
	elif not move_anim.is_empty():
		move_anim[0]["t"] += delta / float(move_anim[0]["dur"])
		if move_anim[0]["t"] >= 1.0:
			move_anim.pop_front()
			if move_anim.is_empty():
				ai_timer = AI_DELAY
				_rebuild_menu()
	elif not energy_anim.is_empty():
		_update_energy(delta)
	elif not prize_anim.is_empty():
		_update_prize(delta)
	elif not banner.is_empty():
		banner["t"] += delta / (BANNER_TIME * (2.5 if banner.get("sudden", false) else 1.0))
		if banner["t"] >= 1.0:
			banner = {}
			_rebuild_menu()
	elif not deck_anim.is_empty():
		_update_deck(delta)
	elif not vs_anim.is_empty():
		vs_anim["t"] += delta / SpecialFX.VS_TIME
		if vs_anim["t"] >= 1.0:
			vs_anim = {}
			_rebuild_menu()
	elif mode == "duel" and _check_vs():
		pass
	elif mode == "duel" and _check_setup_screen():
		pass
	elif mode == "duel" and game.phase != "over" and game.actor() != human and not board_view and intro == "" and not paused and setup_screen == "":
		if net != null:
			_net_remote_step()
		else:
			ai_timer -= delta
			if ai_timer <= 0.0:
				ai_timer = AI_DELAY
				_do(ai.choose(game))
	queue_redraw()


## Mandás tu acción: su número en la lista de acciones posibles (las dos partidas tienen la
## misma lista) y una huella del estado, para notar si las partidas se separaron.
func _net_send_action(action: Dictionary) -> void:
	var i := game.legal_actions().find(action)
	if i < 0:
		net_lost = "Desync: your move isn't in the list (bug). The game can't go on."
		return
	net.send({"k": "act", "n": net_out, "i": i, "h": _net_hash()})
	net_out += 1


## Toca jugar al rival: si ya llegó su acción, se aplica como si la hubiera hecho la IA.
func _net_remote_step() -> void:
	if net_lost != "":
		return
	for j in net.inbox.size():
		var m: Dictionary = net.inbox[j]
		if str(m.get("k", "")) != "act":
			continue
		net.inbox.remove_at(j)
		if int(m.get("n", -1)) != net_in or int(m.get("h", 0)) != _net_hash():
			net_lost = "Desync: the two games no longer match. The game can't go on."
			return
		var acts := game.legal_actions()
		var i := int(m.get("i", -1))
		if i < 0 or i >= acts.size():
			net_lost = "Desync: the opponent's move doesn't exist here."
			return
		net_in += 1
		_do(acts[i])
		return


## Huella del estado: lo que tiene que dar igual en las dos computadoras.
func _net_hash() -> int:
	var parts: Array = [game.turn_number, game.phase, game.current, game.actor(), game.stadium]
	for p in game.players:
		parts.append([p.hand.size(), p.deck.size(), p.prizes.size(), p.discard.size(),
				p.all_in_play().map(func(x): return [x.top(), x.damage, x.energy.size()])])
	return hash(var_to_str(parts)) & 0x3fffffff


func _net_poll() -> void:
	net.poll()
	if mode != "duel":
		return
	for j in range(net.inbox.size() - 1, -1, -1):
		if str(net.inbox[j].get("k", "")) == "concede" and game.phase != "over":
			net.inbox.remove_at(j)
			game.concede(1 - human)
	if net.status in ["closed", "error"] and net_lost == "" and game.phase != "over":
		net_lost = net.error if net.error != "" else "Connection lost."


func _net_close() -> void:
	if net != null:
		net.close()
	net = null
	net_lost = ""


## Aplica una acción. Si la jugada tira monedas, primero se ven las monedas y recién
## después pasa lo que tenga que pasar: el resultado se calcula antes en una copia de la
## partida (el motor es determinista, así que las monedas de la copia son las reales).
func _do(action: Dictionary) -> void:
	if net != null and game.actor() == human:
		_net_send_action(action)
	if not animations_on:
		_apply_now(action)
		return
	var coins := _preview_coins(action)
	match action["t"]:
		"attack":
			if not coins.is_empty():
				_show_coins(coins, func(): _start_attack_anim(action, coins[0].size()), _attack_label(action))
			else:
				_start_attack_anim(action, 0)
		"power":
			var then := func():
				if not coins.is_empty():
					_show_coins(coins, func(): _apply_now(action, coins[0].size()), "")
				else:
					_apply_now(action)
			if not _start_power_anim(action, then):
				then.call()
		"trainer":
			_start_trainer_anim(action)
			var label := "%s %s." % ["You play" if game.actor() == human else "The opponent plays",
					CardDB.card_name(game.players[game.actor()].hand[action["h"]])]
			# La carta se muestra en la mesa, después las monedas y al final el efecto.
			trainer_anim["then"] = func():
				if not coins.is_empty():
					_show_coins(coins, func(): _apply_now(action, coins[0].size()), label)
				else:
					_apply_now(action)
		_:
			if not coins.is_empty():
				_show_coins(coins, func(): _apply_now(action, coins[0].size()), "")
			else:
				_apply_now(action)


## Aplica la acción en el motor y prepara las animaciones de lo que cambió.
func _apply_now(action: Dictionary, coins_shown: int = 0) -> void:
	var before := _snapshot()
	var start := game.coin_log.size()
	game.body_events.clear()
	game.checkup_mark = -1
	game.apply(action)
	_collect_body_events()
	if coins_shown > 0:
		coins_seen = start + coins_shown     # esas monedas ya se mostraron
	if action["t"] == "first" and game.phase == "setup":
		_queue_opening_anims()
	_after_apply(before)
	ai_timer = AI_DELAY
	_rebuild_menu()


## Monedas que va a tirar la acción: [resultados, motivos], o [] si no tira ninguna.
## De un ataque, Entrenador o Poké-Power se adelantan solo sus monedas; las del cambio de
## turno que viene después (Dormido, Quemado) se ven en su momento, después del ataque.
func _preview_coins(action: Dictionary) -> Array:
	if game.phase != "main" or not action["t"] in ["attack", "trainer", "power", "end"]:
		return []
	var sim := game.clone()
	sim.apply(action)
	var n := sim.coin_log.size()
	if action["t"] != "end":
		n = 0
		while n < sim.coin_log.size() and sim.coin_reasons[n] == "":
			n += 1
	if n == 0:
		return []
	return [sim.coin_log.slice(0, n), sim.coin_reasons.slice(0, n)]


func _show_coins(coins: Array, then: Callable, label: String) -> void:
	var results: Array = coins[0]
	coin_anim = {"results": results, "reasons": coins[1], "i": 0, "t": 0.0, "then": then, "label": label,
			"per": COIN_TIME if results.size() <= 3 else COIN_TIME * 0.6}


func _attack_label(action: Dictionary) -> String:
	var box := [""]
	game.with_ctx(action.get("ctx", null), func():
		var att := game.current_player()
		box[0] = "%s used %s!" % [att.active.display_name(), att.active.attacks()[action["a"]]["name"]])
	return box[0]


## Estado antes de una acción, para saber qué animar después.
func _snapshot() -> Dictionary:
	return {"energy": _energy_snapshot(), "places": _places(), "phase": game.phase,
			"piles": [[game.players[0].discard.duplicate(), game.players[0].hand.duplicate()],
					[game.players[1].discard.duplicate(), game.players[1].hand.duplicate()]]}


func _after_apply(before: Dictionary) -> void:
	_check_coins()
	_check_evolutions()
	_check_energy(before["energy"])
	_check_recovered(before["piles"])
	_check_moves(before)


## Cartas que pasaron de la pila de descarte a la mano: vuelan del descarte a la mano.
func _check_recovered(piles: Array) -> void:
	if not animations_on:
		return
	for pi in 2:
		var lost: Array = piles[pi][0].duplicate()
		for c in game.players[pi].discard:
			lost.erase(c)
		var gained: Array = game.players[pi].hand.duplicate()
		for c in piles[pi][1]:
			gained.erase(c)
		var ids: Array = []
		for c in gained:
			if c in lost:
				lost.erase(c)
				ids.append(c)
		if not ids.is_empty():
			deck_anim.append({"k": "recover", "p": pi, "ids": ids, "t": 0.0, "dur": _draw_duration(ids.size()) + 0.3})


func _rebuild_menu() -> void:
	menu_items.clear()
	cursor = 0
	scroll = 0
	if intro == "call":
		menu_level = "list"
		menu_items.append({"label": "Heads", "call": true})
		menu_items.append({"label": "Tails", "call": false})
		return
	if intro != "" or game.phase == "over" or game.actor() != human:
		return
	var actions := game.legal_actions()
	if game.phase != "main":
		menu_level = "list"
		for a in actions:
			menu_items.append({"label": game.describe(a), "action": a})
		return
	if game.turn_number != menu_turn:
		# Turno nuevo: siempre se arranca desde el menú principal de la mesa
		menu_turn = game.turn_number
		menu_level = "root"
		category = ""
	if menu_level == "confirm_end":
		menu_items.append({"label": "You can still attack. End your turn anyway?", "confirm": true})
		menu_items.append({"label": "No, go back", "confirm": false})
		cursor = 1
		return
	if menu_level == "list":
		for a in actions:
			if CATEGORY.get(a["t"], "") == category:
				menu_items.append({"label": _label(a), "action": a})
		if not menu_items.is_empty():
			return
		menu_level = "root"
	var cats := {}
	for a in actions:
		cats[CATEGORY.get(a["t"], "?")] = true
	for c in CATEGORY_ORDER:
		if cats.has(c):
			menu_items.append({"label": c, "category": c})


func _label(a: Dictionary) -> String:
	if a["t"] == "attack":
		var box := [""]
		game.with_ctx(a.get("ctx", null), func():
			var atk: Dictionary = game.current_player().active.attacks()[a["a"]]
			box[0] = atk.get("damage_text", ""))
		var dmg: String = box[0]
		return game.describe(a) + ("  " + dmg if dmg != "" else "")
	return game.describe(a)


# ===========================================================================
# Input
# ===========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		idle_since = Time.get_ticks_msec() / 1000.0     # tocaste algo: el Activo deja de esperar
	if event is InputEventJoypadButton and event.pressed:
		_joypad(event)
		return
	if not (event is InputEventKey and event.pressed):
		return
	if not _trans.is_empty():
		return
	var k: int = event.keycode
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	var back := k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE]
	if mode == "duel" and not rival_intro.is_empty():
		if (accept or back) and not event.echo and rival_intro["t"] > 0.3:
			rival_intro["t"] = maxf(rival_intro["t"], RIVAL_INTRO_TIME - 0.25)    # Z la apura
		return
	if mode == "title":
		if title_attract:
			if (accept or k == KEY_ESCAPE) and not event.echo:
				title_attract = false
				snd.play("accept")
			return
		if title_view == "online":
			online.input(event)
			return
		_title_input(k, accept and not event.echo)
		return
	if mode == "campaign":
		if not info_lines.is_empty():      # la ficha de una carta (p. ej. desde un sobre)
			_info_keys(k, accept, back, event.echo)
			return
		campaign.input(event)
		return
	if mode == "editor":
		if not info_lines.is_empty():
			_info_keys(k, accept, back, event.echo)
			return
		_editor_sound(k, event.echo)
		editor.input(event)
		return
	if net_lost != "":
		if accept and not event.echo:
			_net_close()
			_go(func(): mode = "title")
		return
	if paused:
		_pause_input(k, accept and not event.echo, back and not event.echo)
		return
	if k == KEY_P and not event.echo and game.phase != "over" and intro == "":
		_open_pause()
		return
	if not power_anim.is_empty():
		if accept and not event.echo:
			power_anim["t"] = maxf(power_anim["t"], power_anim["dur"] - 0.2)    # Z adelanta
		return
	if not trainer_anim.is_empty():
		if accept and not event.echo:
			trainer_anim["t"] = maxf(trainer_anim["t"], 0.72)    # Z adelanta
		return
	if not coin_anim.is_empty():
		if accept and not event.echo:
			coin_anim["per"] = minf(coin_anim["per"], COIN_FAST)   # Z acelera las monedas
		return
	if not evo_anim.is_empty():
		return
	if not vs_anim.is_empty():
		if accept and not event.echo:
			vs_anim["t"] = maxf(vs_anim["t"], 0.86)     # Z lo saltea
		return
	if _deck_showing():
		if accept and not event.echo:
			deck_anim[0]["t"] = deck_anim[0]["dur"]     # Z la saltea
		return
	if _prize_showing() and prize_anim[0].get("choose", false):
		var n := _prize_pile_size(prize_anim[0]["p"])
		if k in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			snd.play("move")
		match k:
			KEY_LEFT: prize_cursor = maxi(0, prize_cursor - 1)
			KEY_RIGHT: prize_cursor = mini(n - 1, prize_cursor + 1)
			KEY_UP: prize_cursor = maxi(0, prize_cursor - 2) if prize_cursor >= 2 else prize_cursor
			KEY_DOWN: prize_cursor = prize_cursor + 2 if prize_cursor + 2 < n else prize_cursor
		if accept and not event.echo:
			_pick_prize(prize_cursor)
		return
	if not prize_anim.is_empty() and anim.is_empty() and energy_anim.is_empty():
		if accept and not event.echo:
			prize_anim[0]["t"] = maxf(prize_anim[0]["t"], 0.82)   # Z adelanta
		return
	if accept and not event.echo and _deck_showing() and deck_anim[0].get("closeup", false):
		# Z: la carta que se está mirando se va ya a la mano
		var per := CU_IN + CU_HOLD + CU_OUT
		var t0: float = deck_anim[0]["t"]
		var i := int(t0 / per)
		deck_anim[0]["t"] = maxf(t0, i * per + CU_IN + CU_HOLD)
		return
	if anim.get("scene", false) and accept and not event.echo:
		if anim.get("mini", false):
			MiniBattle.skip(anim)
		else:
			BattleScene.skip(anim)     # Z saltea la escena de batalla
		return
	if not anim.is_empty() or not energy_anim.is_empty() or not ko_anim.is_empty() or not check_anim.is_empty() or not move_anim.is_empty():
		return
	if _banner_showing():
		if accept and not event.echo:
			banner["t"] = maxf(banner["t"], 0.85)
		return
	if not info_lines.is_empty():
		_info_keys(k, accept, back, event.echo)
		return
	if game.phase == "over":
		if accept and not event.echo and _results_showing():
			snd.play("ok")
			if campaign_rival != "":
				var won: bool = game.winner == human
				_go(func():
					mode = "campaign"
					campaign.after_duel(won))
			else:
				_net_close()
				_go(func(): mode = "title")
		return
	if setup_screen != "":
		_setup_input(k, accept and not event.echo, back and not event.echo, event.echo)
		return
	if pile_view != "":
		_nav_sound(k, false, back and not event.echo)
		_hand_input(k, accept and not event.echo, back)
		return
	if board_view:
		_nav_sound(k, false, back and not event.echo)
		_board_input(k, accept and not event.echo, back, event.echo)
		return
	if k in [KEY_B, KEY_M, KEY_D, KEY_C] and not event.echo:
		snd.play("ok")
	if k == KEY_TAB and not event.echo:
		snd.play("ok" if not show_log else "back")
	if k == KEY_B and not event.echo:
		board_view = true
		board_sel = [human, -1]
		show_log = false
		return
	if k == KEY_M and not event.echo and _setup_hand_ok():
		setup_screen = "hand"         # en la preparación, M vuelve a la pantalla de la mano
		_setup_closed = false
		return
	if (k == KEY_M or k == KEY_D) and not event.echo:
		pile_view = "hand" if k == KEY_M else "discard"
		pile_side = 0
		hand_cursor = 0
		show_log = false
		return
	if k == KEY_TAB and not event.echo:
		show_log = not show_log
		log_scroll = 0
		return
	if k == KEY_C and not event.echo:
		_open_cursor_info()
		return
	if show_log:
		if k == KEY_UP:
			log_scroll = mini(log_scroll + 1, maxi(0, game.log_lines.size() - LOG_LINES_FULL))
		elif k == KEY_DOWN:
			log_scroll = maxi(0, log_scroll - 1)
		elif back:
			show_log = false
		return
	if game.actor() != human and intro != "call":
		if accept and not event.echo:
			ai_timer = minf(ai_timer, 0.05)     # Z: que la IA siga sin esperar
		return
	if menu_items.is_empty():
		return
	_nav_sound(k, accept and not event.echo, back and not event.echo and menu_level in ["list", "confirm_end"])
	if back and not event.echo and menu_level == "root" and game.phase == "main":
		_open_pause()        # X en el menú principal: pausa
		return
	if menu_level == "root" and game.phase == "main" and k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		# Opciones en dos columnas: ◀▶ cambia de columna, ▲▼ de fila
		var n := menu_items.size()
		match k:
			KEY_UP: cursor = cursor - 2 if cursor >= 2 else cursor
			KEY_DOWN: cursor = cursor + 2 if cursor + 2 < n else cursor
			KEY_LEFT: cursor = cursor - 1 if cursor % 2 == 1 else cursor
			KEY_RIGHT: cursor = cursor + 1 if cursor % 2 == 0 and cursor + 1 < n else cursor
		marquee_t0.clear()
		return
	if k == KEY_UP:
		cursor = (cursor - 1 + menu_items.size()) % menu_items.size()
		marquee_t0.clear()
	elif k == KEY_DOWN:
		cursor = (cursor + 1) % menu_items.size()
		marquee_t0.clear()
	elif back and menu_level in ["list", "confirm_end"] and game.phase == "main":
		menu_level = "root"
		_rebuild_menu()
	elif accept and not event.echo:
		var item: Dictionary = menu_items[cursor]
		if item.has("call"):
			_opening_call(item["call"])
			return
		if item.has("category"):
			if item["category"] == "End turn":
				if game.legal_actions().any(func(a): return a["t"] == "attack"):
					menu_level = "confirm_end"      # todavía podés atacar: preguntar antes
					_rebuild_menu()
				else:
					menu_level = "root"
					_do({"t": "end"})
					return
			else:
				category = item["category"]
				menu_level = "list"
		elif item.has("confirm"):
			menu_level = "root"
			if item["confirm"]:
				_do({"t": "end"})
				return
		else:
			ai_timer = AI_DELAY
			if item["action"].get("t", "") in ["attack", "end", "trainer"]:
				# Atacar o terminar: el próximo turno arranca en el menú principal.
				# Un Trainer también vuelve al menú principal (no se queda en la lista).
				menu_level = "root"
				category = ""
			_do(item["action"])
			return
		_rebuild_menu()
	if cursor < scroll:
		scroll = cursor
	elif cursor >= scroll + MENU_LINES:
		scroll = cursor - MENU_LINES + 1


func _title_input(k: int, accept: bool) -> void:
	var n := Decks.names().size()
	my_deck = clampi(my_deck, 0, n - 1)
	opp_deck = clampi(opp_deck, 0, n - 1)
	title_msg = ""
	if title_view == "options":
		# Opciones: Animación, Efectos, Música y Mesa (las mismas de la pausa)
		match k:
			KEY_UP, KEY_DOWN:
				opt_cursor = (opt_cursor + (1 if k == KEY_DOWN else 5)) % 6
				snd.play("move")
			KEY_LEFT, KEY_RIGHT:
				if opt_cursor < 5:
					_pause_change(opt_cursor + 1, 1 if k == KEY_RIGHT else -1)
					snd.play("ok")
			KEY_X, KEY_ESCAPE, KEY_BACKSPACE:
				title_view = ""
				snd.play("back")
		if accept:
			if opt_cursor == 5:         # Card art: bajar el arte de todas las cartas
				arte.download_all()
			else:
				_pause_change(opt_cursor + 1, 1)
			snd.play("ok")
		return
	if title_view == "duel":
		_duel_setup_input(k, accept, n)
		return
	if title_view == "online":
		return       # la maneja online.input (necesita el evento entero para escribir)
	match k:
		KEY_UP:
			title_row = (title_row + TITLE_ROWS - 1) % TITLE_ROWS
			snd.play("move")
		KEY_DOWN:
			title_row = (title_row + 1) % TITLE_ROWS
			snd.play("move")
	if not accept:
		return
	match title_row:
		0:
			if not CAMPAIGN_ON:
				snd.play("error")
				return
			snd.play("ok")
			_go(func():
				mode = "campaign"
				campaign.open())
		1:
			snd.play("ok")
			title_view = "options"
			opt_cursor = 0
		2:
			snd.play("ok")
			_go(func():
				mode = "editor"
				editor.open())
		3:
			snd.play("ok")
			title_view = "duel"
			duel_row = DUEL_ROWS - 1        # el cursor arranca en "Start duel!"
		4:
			snd.play("ok")
			title_view = "online"
			online.open()


## Armado del duelo libre: mazos, dificultad, formato y tipo de batalla.
func _duel_setup_input(k: int, accept: bool, n: int) -> void:
	match k:
		KEY_UP:
			duel_row = (duel_row + DUEL_ROWS - 1) % DUEL_ROWS
			snd.play("move")
		KEY_DOWN:
			duel_row = (duel_row + 1) % DUEL_ROWS
			snd.play("move")
		KEY_X, KEY_ESCAPE, KEY_BACKSPACE:
			title_view = ""
			snd.play("back")
			return
		KEY_LEFT, KEY_RIGHT:
			var d := 1 if k == KEY_RIGHT else -1
			if duel_row < DUEL_ROWS - 1:
				snd.play("move")
			match duel_row:
				0: my_deck = (my_deck + d + n) % n
				1: opp_deck = (opp_deck + d + n) % n
				2:
					ai_level = (ai_level - 1 + d + 5) % 5 + 1
					_save_settings()
				3:
					season_idx = (season_idx + d + RuleSet.SEASONS.size()) % RuleSet.SEASONS.size()
					_save_settings()
				4: doubles_mode = not doubles_mode      # batalla simple o doble (2 contra 2)
	if not accept:
		return
	if duel_row < DUEL_ROWS - 1:
		duel_row = DUEL_ROWS - 1
		snd.play("move")
		return
	var names := Decks.names()
	var fmt_rules := RuleSet.from_season(season_idx)
	for pair in [[my_deck, "Your deck"], [opp_deck, "The opponent's deck"]]:
		var errs := Game.validate_deck(Decks.get_deck(names[pair[0]]), fmt_rules)
		if not errs.is_empty():
			title_msg = "%s is not valid: %s" % [pair[1], errs[0]]
			snd.play("error")
			return
	snd.play("ok")
	campaign_rival = ""
	_go(_start_duel)


# ===========================================================================
# Fichas de cartas (tecla C)
# ===========================================================================

func _info_for_cursor() -> Array:
	var me := game.players[human]
	if menu_items.is_empty() or menu_level == "root" and game.phase == "main":
		var lines: Array = []
		if me.active != null:
			lines.append({"section": "YOUR ACTIVE", "bg": C_MINE_BG})
			lines.append_array(_card_lines(me.active.top(), me.active))
		var opp := game.players[1 - human]
		if opp.active != null:
			lines.append({"section": "OPPONENT'S ACTIVE", "bg": C_OPP_BG})
			lines.append_array(_card_lines(opp.active.top(), opp.active))
		if game.stadium != "":
			lines.append({"section": "STADIUM", "bg": C_STADIUM_BG})
			lines.append_array(_card_lines(game.stadium, null))
		return lines
	var a: Dictionary = menu_items[cursor].get("action", {})
	if a.is_empty():      # opciones que no son jugadas (cara o cruz, confirmar fin de turno)
		return []
	if a.has("h") and a["t"] != "choose":
		var actor_p := game.players[game.actor()]
		return _card_lines(actor_p.hand[a["h"]], null)
	if a["t"] == "attack" or a["t"] == "power":
		return _card_lines(me.active.top() if a["t"] == "attack" else me.slot(a["s"]).top(), null)
	if a["t"] in ["retreat", "choose"] and a.has("b"):
		var p := game.players[game.actor()].bench[a["b"]]
		return _card_lines(p.top(), p)
	var opt: Dictionary = game.choice_options()[a["i"]] if a.has("i") else {}
	if opt.has("id") and opt["id"] != "":
		return _card_lines(opt["id"], null)
	return []


func _card_lines(id: String, p: PokemonInPlay) -> Array:
	var c := CardDB.get_card(id)
	# Cabecera (imagen + datos básicos), cuerpo (habilidades, ataques...) y pie (debilidad,
	# resistencia, retirada): _draw_info los dibuja en paneles separados.
	var lines: Array = [{"img": id, "head": true}]
	lines.append({"row": [["bold", c.get("name", "?")], ["dim", "  " + id]]})
	if CardDB.is_pokemon(id):
		lines.append(", ".join(c.get("subtypes", [])))
		var tr: Array = [["text", "HP %d  " % int(c.get("hp", 0))]]
		for t in c.get("types", []):
			tr.append(["icon", t])
			tr.append(["text", TYPE_ES.get(t, t) + " "])
		lines.append({"row": tr})
		var from := str(c.get("evolves_from", c.get("evolvesFrom", "")))
		if from != "":
			lines.append({"text": "From " + from, "color": C_DIM})
		lines.append({"body": true})
		if p != null:
			lines.append("Damage %d · Energy %d %s" % [p.damage, Energy.total(p), p.conditions_text()])
			lines.append(_attached_text(p))
		for ab in c.get("abilities", []):
			lines.append({"gap": INFO_GAP})
			var col: Color = C_POWER if ab["kind"] == "Poké-Power" else C_BODY
			lines.append({"row": [["bold", ab["kind"] + ": ", col], ["bold", ab["name"], col]]})
			lines.append_array(_para(str(ab["text"]), col))
		_attack_lines(lines, c)
		# Herramienta y MT unidas, con su imagen y su texto
		if p != null:
			for extra in [[p.tool, "ATTACHED TOOL"], [p.tm, "ATTACHED TECHNICAL MACHINE"]]:
				if extra[0] != "":
					lines.append({"sub": extra[1]})
					var sub_lines: Array = _card_lines(extra[0], null)
					lines.append_array(sub_lines.filter(func(l): return not (l is Dictionary and (l.has("head") or l.has("body") or l.has("foot")))))
		lines.append({"foot": true})
		var wr: Array = [["text", "Weakness "]]
		for t in c.get("weaknesses", []):
			wr.append(["icon", t])
		if c.get("weaknesses", []).is_empty():
			wr.append(["text", "-"])
		wr.append(["text", "   Resistance "])
		for t in c.get("resistances", []):
			wr.append(["icon", t])
		if c.get("resistances", []).is_empty():
			wr.append(["text", "-"])
		wr.append(["text", "   Retreat "])
		for i in int(c.get("retreat", 0)):
			wr.append(["icon", "Colorless"])
		if int(c.get("retreat", 0)) == 0:
			wr.append(["text", "0"])
		lines.append({"row": wr})
	else:
		lines.append(", ".join(c.get("subtypes", [])) if not c.get("subtypes", []).is_empty() else str(c.get("supertype", "")))
		lines.append({"body": true})
		lines.append_array(_para(str(c.get("text", "")).replace("You can play only one Supporter card each turn. When you play this card, put it next to your Active Pokémon. When your turn ends, discard this card. ", "")))
		# MT y Estadios que dan un ataque (Rocket's Tricky Gym, Holon Lake...): el ataque con su costo
		_attack_lines(lines, c)
	return lines


## Los ataques de la carta en la ficha: costo con íconos, nombre, daño y texto.
func _attack_lines(lines: Array, c: Dictionary) -> void:
	for atk in c.get("attacks", []):
		lines.append({"gap": INFO_GAP})
		var row: Array = []
		for t in atk.get("cost", []):
			row.append(["icon", t])
		if atk.get("cost", []).is_empty():
			row.append(["text", "(no cost)"])
		row.append(["bold", "  " + atk["name"]])
		row.append(["text", "  " + atk.get("damage_text", "")])
		lines.append({"row": row})
		if str(atk.get("text", "")) != "":
			lines.append_array(_para(str(atk["text"]), C_TEXT))


## Un párrafo de la ficha partido en renglones del ancho del panel del medio, para que
## ▲▼ lo recorra de a un renglón aunque no entre entero.
func _para(text: String, col: Color = C_TEXT) -> Array:
	var out: Array = []
	for l in _wrap(_type_marks(text), W - 22.0):
		var plain := str(l)
		var i := plain.find(ICON_MARK)
		while i >= 0:                  # los íconos se vuelven a poner al dibujar
			plain = plain.substr(0, i) + plain.substr(i + 2)
			i = plain.find(ICON_MARK)
		out.append({"text": plain, "color": col})
	return out


# ===========================================================================
# Dibujo
# ===========================================================================

func _draw() -> void:
	_draw_screen()
	if mode == "duel" and anim.get("scene", false) and not anim.get("waiting", false):
		if anim.get("mini", false):
			MiniBattle.draw(self, anim)
		else:
			BattleScene.draw(self, anim)
	if mode == "duel" and net != null:
		_draw_net_overlay()
	_draw_trans()
	if gallery_id != "":
		_draw_gallery()


## En línea: "Esperando al rival…" mientras elige, o el aviso si se cortó la conexión.
func _draw_net_overlay() -> void:
	if net_lost != "":
		var r := Rect2(20, 48, W - 40, 50)
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.45))
		_frame(r)
		_text_fit(Vector2(r.position.x + 9, r.position.y + 7), "ONLINE DUEL", C_DIM, r.size.x - 18)
		_text_scroll(Vector2(r.position.x + 9, r.position.y + 20), net_lost, C_TEXT, r.size.x - 18, "netlost")
		_text(Vector2(r.position.x + 9, r.position.y + 33), "Z: back to the title", Color("#c03028"))
		return
	if game.phase != "over" and game.actor() != human and anim.is_empty() and coin_anim.is_empty():
		var dots := ".".repeat(1 + int(Time.get_ticks_msec() / 400) % 3)
		var txt := "Waiting for the opponent" + dots
		var w := _text_w("Waiting for the opponent...") + 10
		var r := Rect2((W - w) / 2.0, 1, w, 12)
		draw_rect(r, Color(0.06, 0.08, 0.18, 0.8))
		_text(r.position + Vector2(5, 0), txt, Color("#f8f8f8"))


func _draw_screen() -> void:
	if mode == "title":
		_draw_title()
		return
	if mode == "editor":
		editor.draw()
		if not info_lines.is_empty():
			_draw_slid(_slide_off("info") * H, _draw_info)
		return
	if mode == "campaign":
		campaign.draw()
		if not info_lines.is_empty():
			_draw_slid(_slide_off("info") * H, _draw_info)
		return
	var me := game.players[human]
	var opp := game.players[1 - human]
	var quake := _table_shake()
	if quake != Vector2.ZERO:
		_base_off = quake
		draw_set_transform(_base_off)
	_draw_table()
	if game.stadium != "" and table_style == 0:     # con un fondo temático no se superpone
		if _stage_name() == "":       # sin fondo de Ranger: el tenue de siempre
			_draw_stadium_background(game.stadium)
	var dbl := _dbl() or doubles_preview
	if dbl:
		_draw_doubles_board(opp, me)
	else:
		for pl: PlayerState in [opp, me]:
			_draw_bench_cards(pl)
			_draw_counters(pl)
	_draw_supporters_on_table()
	_layout_stadium_tab()
	if game.stadium != "" and not dbl and not _stadium_layout.get("reserve", false):
		_draw_stadium_card(game.stadium)
	for pl: PlayerState in ([] if dbl else [opp, me]):
		var off := _anim_offset(pl.index) + _idle_bob(pl)
		if pl.active != null and _is_moving(pl.active):
			_outline(_card_rect(pl.index), C_LINE if pl == me else Color("#c87060"))
		elif pl.active != null:
			var ir := Rect2(_info_rect(pl.index).position + _hp_shake(pl.active), INFO_SIZE)
			# Pestaña del Poké-Body: la tuya asoma arriba del cuadro (va detrás de él) y
			# la del rival cuelga abajo (va delante, sobre el borde)
			if not _dbl() and pl.index == human:
				_draw_body_tab(ir, pl.active, false)
			_draw_info_box(ir, pl.active)
			if not _dbl() and pl.index != human:
				_draw_body_tab(ir, pl.active, true)
			_draw_big_card(Rect2(_card_rect(pl.index).position + off, CARD_SIZE), pl.active)
			_draw_status_fx(pl)
			_draw_hit_flash(pl)
		else:
			_outline(_card_rect(pl.index), C_LINE if pl == me else Color("#c87060"))
	_draw_moves()
	_draw_anim()
	_draw_check()
	_draw_ko()
	_draw_evo()
	_draw_ex_shine()
	_draw_target_highlight()
	if quake != Vector2.ZERO:
		_base_off = Vector2.ZERO
		draw_set_transform(Vector2.ZERO)
	if menu_level == "confirm_end" and game.actor() == human:
		draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.45))     # la mesa se oscurece mientras pregunta
	if _results_showing():
		_draw_results()
		return
	_draw_stadium_tab()
	_draw_textbox()
	_draw_energy_anim()
	_draw_trainer_anim()
	_draw_power_anim()
	_draw_prize()
	_draw_banner()
	_draw_deck_anim()
	_draw_coins()
	if not vs_anim.is_empty():
		SpecialFX.draw_vs(self, vs_anim)
	_draw_rival_intro()
	if show_log:
		_draw_slid(_slide_off("log") * H, _draw_full_log)
	if pile_view != "":
		_draw_slid(_slide_off("hand") * H, _draw_hand)
	if setup_screen != "" and move_anim.is_empty() and deck_anim.is_empty():
		_draw_setup_screen()
	if not info_lines.is_empty():
		_draw_slid(_slide_off("info") * H, _draw_info)
	elif _info_ghost_t >= 0.0:
		var keep := info_lines
		info_lines = _info_ghost
		_draw_slid(pow(_info_ghost_t, 2) * H, _draw_info)
		info_lines = keep
	if paused:
		_draw_pause()


var _tsize := FONT_SIZE      # tamaño de letra actual (algunos lugares usan uno más chico)


## Íconos de tipo dentro del texto: "¤" + una letra (ver TYPE_MARK). _type_marks() los pone
## delante de cada nombre de tipo ("Fire Energy" -> ícono + "Fire Energy").
const ICON_MARK := "¤"
const ICON_W := 11          # lo que ocupa un ícono dentro del texto (10 px + 1 de aire)
const TYPE_MARK := {"G": "Grass", "R": "Fire", "W": "Water", "L": "Lightning", "P": "Psychic",
		"F": "Fighting", "D": "Darkness", "M": "Metal", "C": "Colorless"}
var _type_rx: RegEx = null


func _type_marks(s: String) -> String:
	if _type_rx == null:
		_type_rx = RegEx.new()
		_type_rx.compile("\\b(Grass|Fire|Water|Lightning|Psychic|Fighting|Darkness|Metal|Colorless)\\b")
	var out := ""
	var at := 0
	for m in _type_rx.search_all(s):
		var t := m.get_string(1)
		var code := ""
		for k in TYPE_MARK:
			if TYPE_MARK[k] == t:
				code = k
		out += s.substr(at, m.get_start() - at) + ICON_MARK + code + t
		at = m.get_end()
	return out + s.substr(at)


func _text(pos: Vector2, s: String, color: Color = C_TEXT, width: float = -1) -> void:
	if s.contains(ICON_MARK):
		var x := pos.x
		var parts := s.split(ICON_MARK)
		for i in parts.size():
			var part: String = parts[i]
			if i > 0 and part.length() > 0:
				_draw_energy_icon(Vector2(x + 5, pos.y + 4.5), 10, TYPE_MARK.get(part.substr(0, 1), "Colorless"))
				x += ICON_W
				part = part.substr(1)
			if part != "":
				_text(Vector2(x, pos.y), part, color)
				x += _text_w(part)
		return
	var p := (pos + Vector2(0, TEXT_BASE)).floor()
	s = _px(s)
	# Sombra de los juegos de GBA: a la derecha, abajo y en diagonal.
	var sh := C_SHADOW_D if color.get_luminance() > 0.72 else C_SHADOW_L
	sh.a = color.a
	for o: Vector2 in [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		draw_string(font, p + o, s, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, sh)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)


## Texto al doble de tamaño (títulos y carteles).
func _text_big(pos: Vector2, s: String, color: Color) -> void:
	draw_set_transform(_base_off + pos.floor(), 0, Vector2(2, 2))
	_text(Vector2.ZERO, s, color)
	draw_set_transform(_base_off)


func _text_center(y: float, s: String, color: Color, big: bool = false) -> void:
	var w := _text_w(s) * (2 if big else 1)
	if big:
		_text_big(Vector2(floor((W - w) / 2.0), y), s, color)
	else:
		_text(Vector2(floor((W - w) / 2.0), y), s, color)


## Parte el texto en renglones que entren en el ancho.
func _wrap(s: String, width: float) -> Array:
	var out: Array = []
	for para in s.split("\n"):
		var line := ""
		for word in para.split(" "):
			var cand := word if line == "" else line + " " + word
			if _text_w(cand) <= width or line == "":
				line = cand
			else:
				out.append(line)
				line = word
		out.append(line)
	return out


## Dibuja un texto con renglones partidos; devuelve el alto usado.
func _text_wrap(pos: Vector2, s: String, width: float, color: Color = C_TEXT) -> float:
	var lines := _wrap(s, width)
	for i in lines.size():
		_text(pos + Vector2(0, i * LINE_S), lines[i], color)
	return lines.size() * LINE_S


func _px(s: String) -> String:
	return s


# ===========================================================================
# Mesa estilo GBA: cartas EX, recuadros de batalla y contadores con íconos
# ===========================================================================
# Arriba el rival (fondo rojo), abajo vos (fondo azul). Cada Activo es una carta
# grande con su recuadro de nombre y PS; la Banca son cartas chiquitas con los PS en
# números; los Premios se ven como dorsos y el mazo, la mano y el descarte con íconos.

const CARD_SIZE := Vector2(42, 52)
const MINI_SIZE := Vector2(20, 26)
const INFO_SIZE := Vector2(78, 40)
const HP_COLORS := [[Color("#70f8a8"), Color("#58d080")], [Color("#f8e038"), Color("#c8a808")], [Color("#f85838"), Color("#a84048")]]

var _table_tex: Texture2D = null
var _art := {}


## En dobles, cada jugador tiene dos Activos: dbl_focus dice cuál es "el" Activo para las
## animaciones (el que ataca, el que recibe el golpe).
var dbl_focus := [0, 0]

func _dbl() -> bool:
	return game != null and game.rules.doubles and mode == "duel"


func _card_rect(player: int) -> Rect2:
	if _dbl():
		return _dbl_card_rect(player, dbl_focus[player])
	return Rect2(Vector2(4, 58) if player == human else Vector2(194, 1), CARD_SIZE)


func _art_rect(player: int) -> Rect2:
	if _dbl():
		return Rect2(_card_rect(player).position + Vector2(2, 2), Vector2(22, 22))
	return _portrait_rect(_card_rect(player).position).grow(-1)


func _info_rect(player: int) -> Rect2:
	if _dbl():
		return _dbl_info_rect(player, dbl_focus[player])
	return Rect2(Vector2(51, 70) if player == human else Vector2(111, 6), INFO_SIZE)


func _bench_rect(player: int, i: int) -> Rect2:
	if _dbl():
		return _dbl_bench_rect(player, i)
	return Rect2(Vector2(131 + i * 22, 79) if player == human else Vector2(4 + i * 22, 2), MINI_SIZE)


func _counters_pos(player: int) -> Vector2:
	if _dbl():
		return Vector2(4, 87) if player == human else Vector2(W - 4 - 46, 1)
	return Vector2(190, 59) if player == human else Vector2(4, 36)


## Tipos del Pokémon que tienen color propio (uno o dos: los del Team Aqua/Magma son dobles).
func _mon_types(m: PokemonInPlay) -> Array:
	var out: Array = []
	for ty in m.types():
		if TYPE_DARK.has(ty) and not ty in out:
			out.append(ty)
	if out.is_empty():
		out.append("Colorless")
	return out.slice(0, 2)


## Relleno del color del tipo. Con doble tipo, partido en diagonal: el primer tipo arriba a
## la izquierda y el segundo abajo a la derecha, con una costura clara. light = la línea de
## brillo de arriba (como en el marco de las cartas).
func _fill_types(r: Rect2, m: PokemonInPlay, light: bool = false) -> void:
	var ts := _mon_types(m)
	var c1: Color = TYPE_COLORS[ts[0]]
	if ts.size() == 1:
		draw_rect(r, c1)
		if light:
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), TYPE_LIGHT[ts[0]])
		return
	# Dos tipos: degradé suave en diagonal, del primero (arriba a la izquierda) al segundo.
	var c2: Color = TYPE_COLORS[ts[1]]
	var span := maxf(1.0, r.size.x + r.size.y - 2.0)
	var step := 2 if r.size.x > 8 else int(r.size.x)
	for y in int(r.size.y):
		var yy := r.position.y + y
		var x := 0
		while x < int(r.size.x):
			var w := mini(step, int(r.size.x) - x)
			var k := clampf((x + w / 2.0 + y) / span, 0.0, 1.0)
			var c := c1.lerp(c2, k)
			if light and y == 0:
				c = TYPE_LIGHT[ts[0]].lerp(TYPE_LIGHT[ts[1]], k)
			draw_rect(Rect2(r.position.x + x, yy, w, 1), c)
			x += w


func _main_type(id: String) -> String:
	var t := CardDB.types(id)
	return t[0] if not t.is_empty() and TYPE_DARK.has(t[0]) else "Colorless"


## Contorno de 1 píxel (sin medio píxel de desfase).
func _outline(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), c)
	draw_rect(Rect2(r.position, Vector2(1, r.size.y)), c)
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), c)


# ===========================================================================
# Interfaz al estilo Rubí/Zafiro (piezas de mundo/propios/ui/, tools/armar_ui.py)
# ===========================================================================
# marco.png   el cuadro de texto (borde lila redondeado), estirado como 9-slice
# fondo.png   los dos colores del fondo a rayas de las pantallas enteras
# estado_*.png las pastillas PSN / PAR / SLP / BRN / CNF de la ficha del Pokémon
# Sin esas imágenes se dibuja el estilo de siempre. Los colores de la caja crema y de
# las pestañas verdes son los de la pantalla de movimientos de Rubí/Zafiro.

const UI_DIRS := ["res://mundo/propios/ui", "user://mundo/propios/ui"]
const C_PAGE_BOX := Color("#f8f0c8")       # interior de las cajas (crema)
const C_PAGE_LINE := Color("#e8a0f8")      # su borde (lila)
const C_PAGE_EDGE := Color("#889828")      # borde del fondo a rayas
const C_PAGE_DARK := Color("#283030")
const TAB_GREENS := [Color("#689000"), Color("#609818"), Color("#60a830"), Color("#58b848"), Color("#58c860"), Color("#58d878")]
const C_TAB_SHADOW := Color("#706860")
var _ui_cache := {}


func _ui_tex(name: String) -> Texture2D:
	if not _ui_cache.has(name):
		var tex: Texture2D = null
		for dir in UI_DIRS:
			var p: String = "%s/%s.png" % [dir, name]
			if tex == null and ImgLoad.exists(p):
				var img := ImgLoad.load(p)
				if img != null and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
		_ui_cache[name] = tex
	return _ui_cache[name]


## Dibuja una textura estirada sin deformar las esquinas (c = píxeles de cada esquina).
func _nine(tex: Texture2D, r: Rect2, c: float) -> void:
	var sz := tex.get_size()
	var xs := [r.position.x, r.position.x + c, r.end.x - c, r.end.x]
	var ys := [r.position.y, r.position.y + c, r.end.y - c, r.end.y]
	var us := [0.0, c, sz.x - c, sz.x]
	var vs := [0.0, c, sz.y - c, sz.y]
	for j in 3:
		for i in 3:
			var dst := Rect2(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
			if dst.size.x <= 0 or dst.size.y <= 0:
				continue
			draw_texture_rect_region(tex, dst, Rect2(us[i], vs[j], us[i + 1] - us[i], vs[j + 1] - vs[j]))


## Pantalla entera al estilo de los menús de Rubí/Zafiro: fondo a rayas verde oliva y una
## caja crema con borde lila donde va el contenido (devuelve el rectángulo de la caja).
func _page(r: Rect2, box: Rect2 = Rect2()) -> Rect2:
	var stripes := _ui_tex("fondo")
	if stripes == null:
		_frame(r)
		return r.grow(-4)
	var img := stripes.get_image()
	var c0: Color = img.get_pixel(0, 0)
	var c1: Color = img.get_pixel(0, 1)
	draw_rect(r, c1)
	var y := r.position.y
	while y < r.end.y:
		draw_rect(Rect2(r.position.x, y, r.size.x, 1), c0)
		y += 2
	_outline(r, C_PAGE_EDGE.darkened(0.25))
	_outline(r.grow(-1), C_PAGE_EDGE)
	if box.size.x <= 0:
		box = r.grow(-4)
	_cream_box(box)
	return box


## Fondo de las pantallas de menú (campaña, mazos, nombre): las rayas de Rubí/Zafiro o, sin
## ellas, el diseño de mesa apagado de siempre.
func _menu_bg() -> void:
	var stripes := _ui_tex("fondo")
	if stripes != null:
		var img := stripes.get_image()
		draw_rect(Rect2(0, 0, W, H), img.get_pixel(0, 1))
		for y in range(0, H, 2):
			draw_rect(Rect2(0, y, W, 1), img.get_pixel(0, 0))
		return
	draw_rect(Rect2(0, 0, W, H), C_BG)
	if _table_tex == null:
		_table_tex = ImageTexture.create_from_image(_table_image())
	draw_texture_rect(_table_tex, Rect2(0, 0, W, H), false, Color(1, 1, 1, 0.35))


## Caja crema con borde lila y esquinas redondeadas (como las de la pantalla de movimientos).
func _cream_box(b: Rect2) -> void:
	draw_rect(Rect2(b.position + Vector2(1, 0), Vector2(b.size.x - 2, b.size.y)), C_PAGE_LINE)
	draw_rect(Rect2(b.position + Vector2(0, 1), Vector2(b.size.x, b.size.y - 2)), C_PAGE_LINE)
	draw_rect(Rect2(b.position + Vector2(1, 1), b.size - Vector2(2, 2)), C_PAGE_BOX)
	draw_rect(Rect2(b.position.x + 1, b.end.y - 1, b.size.x - 2, 1), C_PAGE_LINE.darkened(0.3))


## Pestaña verde con el título (como "MOVES" o "DESCRIPTION"): los bordes se degradan.
func _tab(pos: Vector2, w: float, title: String, h: float = TEXT_H + 1) -> void:
	var n := TAB_GREENS.size()
	for i in n:
		draw_rect(Rect2(pos.x + i * 2, pos.y, 2, h), TAB_GREENS[i])
		draw_rect(Rect2(pos.x + w - (i + 1) * 2, pos.y, 2, h), TAB_GREENS[i])
	draw_rect(Rect2(pos.x + n * 2, pos.y, w - n * 4, h), TAB_GREENS[n - 1])
	var tp := (pos + Vector2(n * 2 + 2, roundf((h - TEXT_H) / 2.0))).floor() + Vector2(0, TEXT_BASE)
	var t := _px(title)
	for o: Vector2 in [Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		draw_string(font, tp + o, t, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, C_TAB_SHADOW)
	draw_string(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)


## Ayuda de abajo en las pantallas enteras: sobre las rayas va en blanco.
func _page_hint(pos: Vector2, t: String) -> void:
	_text(pos, t, Color.WHITE if _ui_tex("fondo") != null else C_DIM)


## Recuadro de texto: el de Rubí/Zafiro (marco.png) o, sin él, el marco azul de siempre.
func _frame(r: Rect2) -> void:
	var tex := _ui_tex("marco")
	if tex != null and r.size.x >= 15 and r.size.y >= 15:
		_nine(tex, r, 7)
		return
	draw_rect(r, C_FRAME_OUT)
	draw_rect(r.grow(-1), C_FRAME_MID)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), C_FRAME_HI)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(1, r.size.y - 2)), C_FRAME_HI)
	draw_rect(r.grow(-3), C_FRAME_OUT)
	draw_rect(r.grow(-4), C_PANEL)


func _draw_table() -> void:
	if _table_tex == null:
		_table_tex = ImageTexture.create_from_image(_table_image())
	# Con un Estadio en juego, la mesa toma su fondo (con un fundido al entrar y al salir)
	var st := _stage_name()
	if st != _stage_bg:
		_stage_prev = _stage_bg
		_stage_bg = st
		_stage_t0 = Time.get_ticks_msec() / 1000.0
	var k := clampf((Time.get_ticks_msec() / 1000.0 - _stage_t0) / STADIUM_FADE, 0.0, 1.0)
	var prev := _stage_tex(_stage_prev)
	var cur := _stage_tex(_stage_bg)
	if k < 1.0:
		draw_texture(prev if prev != null else _table_tex, Vector2.ZERO)
		draw_texture(cur if cur != null else _table_tex, Vector2.ZERO, Color(1, 1, 1, k))
	else:
		draw_texture(cur if cur != null else _table_tex, Vector2.ZERO)


# ---------------------------------------------------------------------------
# Fondos por Estadio (mundo/propios/estadios/<nombre>.png, 240 x 112; de Pokémon Ranger)
# ---------------------------------------------------------------------------

const STADIUM_DIR := "res://mundo/propios/estadios"
const STADIUM_FADE := 0.6
var _stage_bg := ""        # el Estadio cuyo fondo se ve ("" = la mesa de siempre)
var _stage_prev := ""
var _stage_t0 := -10.0
var _stage_cache := {}


## El Estadio en juego si tiene un fondo (si no, "": queda la mesa elegida en las opciones).
func _stage_name() -> String:
	if game == null or mode != "duel":
		return ""
	var n := game.stadium_name()
	if n == "" or _stage_tex(n) == null:
		return ""
	return n


func _stage_tex(name: String) -> Texture2D:
	if name == "":
		return null
	if not _stage_cache.has(name):
		var path := "%s/%s.png" % [STADIUM_DIR, name.to_lower().replace("'", "").replace(" ", "_")]
		var tex: Texture2D = null
		if ImgLoad.exists(path):
			tex = ImageTexture.create_from_image(_table_image(path))
		_stage_cache[name] = tex
	return _stage_cache[name]


## Diseños de mesa: la Clásica y los PNG de fondos/ (ordenados por nombre de archivo).
func _find_table_styles() -> void:
	table_styles = [["Classic", ""]]
	var seen := {}
	for dir in TABLE_DIRS:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		# En el juego exportado (y en la web) la carpeta lista "x.png.import" / "x.png.remap"
		# en vez del PNG: se les saca esa terminación (ImgLoad carga la versión importada).
		var files: Array = []
		for f0: String in DirAccess.get_files_at(dir):
			var f1 := f0.trim_suffix(".import").trim_suffix(".remap")
			if not files.has(f1):
				files.append(f1)
		files.sort()
		for f: String in files:
			if not f.get_extension().to_lower() in ["png", "jpg", "webp"]:
				continue
			var base := f.get_basename()
			var rx := RegEx.new()
			rx.compile("^\\d+_")
			base = rx.sub(base, "").replace("_", " ")
			var name: String = TABLE_NAMES.get(base, base.capitalize() if base == base.to_lower() else base)
			if not seen.has(name):
				seen[name] = true
				table_styles.append([name, dir.path_join(f)])


## Fondo de la mesa. Clásica: rojo coral del lado rival y azul del tuyo. Con un dibujo de
## fondos/, el lado del rival se oscurece un poco para distinguir las dos mitades.
func _table_image(path_override := "") -> Image:
	var img := Image.create(W, BOX_Y, false, Image.FORMAT_RGB8)
	var path: String = table_styles[table_style][1] if table_style < table_styles.size() else ""
	if path_override != "":
		path = path_override
	var pic: Image = null
	if path != "" and ImgLoad.exists(path):
		pic = ImgLoad.load(path)
	if pic != null and not pic.is_empty():
		pic.convert(Image.FORMAT_RGB8)
		if pic.get_width() != W or pic.get_height() != BOX_Y:
			# Cubrir la mesa recortando lo que sobre
			var sc := maxf(float(W) / pic.get_width(), float(BOX_Y) / pic.get_height())
			pic.resize(maxi(W, ceili(pic.get_width() * sc)), maxi(BOX_Y, ceili(pic.get_height() * sc)), Image.INTERPOLATE_NEAREST)
			pic = pic.get_region(Rect2i((pic.get_width() - W) / 2, (pic.get_height() - BOX_Y) / 2, W, BOX_Y))
		img.blit_rect(pic, Rect2i(0, 0, W, BOX_Y), Vector2i.ZERO)
		for y in 55:
			for x in W:
				var c := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(c.r * 0.86, c.g * 0.84, c.b * 0.86))
	else:
		for y in BOX_Y:
			var top := y < 55
			var a := Color("#f0907a") if top else Color("#6c9cf0")
			var b := Color("#f8a88c") if top else Color("#84b0f8")
			for x in W:
				var on := posmod(floori((x + y) / 8.0) + floori((x - y) / 8.0), 2) == 0
				img.set_pixel(x, y, a if on else b)
	for x in W:
		img.set_pixel(x, 55, C_LIGHT)
		img.set_pixel(x, 56, Color("#384878"))
	return img


## Imagen de la carta para una ventana de w x h: recortada, con más color y reducida a
## pocos colores de 15 bits, como un sprite de GBA.
func _art_texture(id: String, w: int, h: int) -> Texture2D:
	var key := "%s|%dx%d" % [id, w, h]
	if _art.has(key):
		return _art[key]
	var tex: Texture2D = null
	var img := _load_card_image(id)
	if img != null:
		var small := _gba_art(img, w, h)
		tex = ImageTexture.create_from_image(small)
		_build_cosmos(key, id, small)
	_art[key] = tex
	return tex


func _gba_art(src: Image, w: int, h: int) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var side := float(mini(img.get_width(), img.get_height()))
	var sc := maxf(w / side, h / side)
	var cw := maxi(1, int(w / sc))
	var ch := maxi(1, int(h / sc))
	var left := (img.get_width() - cw) / 2
	var top := maxi(0, (img.get_height() - ch) / 3)
	var crop := img.get_region(Rect2i(left, top, cw, ch))
	crop.resize(w, h, Image.INTERPOLATE_LANCZOS)
	for y in h:
		for x in w:
			var c := crop.get_pixel(x, y)
			var v := Color.from_hsv(c.h, minf(1.0, c.s * 1.35), minf(1.0, c.v * 1.12))
			v = Color(clampf((v.r - 0.5) * 1.1 + 0.5, 0, 1), clampf((v.g - 0.5) * 1.1 + 0.5, 0, 1), clampf((v.b - 0.5) * 1.1 + 0.5, 0, 1), 1.0)
			crop.set_pixel(x, y, v)
	_reduce_palette(crop, 15 if w <= 16 else 24)
	return crop


## Reduce la imagen a n colores (corte por la mediana) de 15 bits.
func _reduce_palette(img: Image, n: int) -> void:
	var px: Array = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				px.append(c)
	if px.is_empty():
		return
	var boxes: Array = [px]
	while boxes.size() < n:
		var bi := -1
		var best := 0.0
		var chan := 0
		for i in boxes.size():
			var b: Array = boxes[i]
			if b.size() < 2:
				continue
			for k in 3:
				var lo := 1.0
				var hi := 0.0
				for c: Color in b:
					lo = minf(lo, c[k])
					hi = maxf(hi, c[k])
				if hi - lo > best:
					best = hi - lo
					bi = i
					chan = k
		if bi < 0:
			break
		var box: Array = boxes[bi]
		var kk := chan
		box.sort_custom(func(c1: Color, c2: Color): return c1[kk] < c2[kk])
		var mid := box.size() / 2
		boxes[bi] = box.slice(0, mid)
		boxes.append(box.slice(mid))
	var pal: Array[Color] = []
	for b: Array in boxes:
		var sum := Vector3.ZERO
		for c: Color in b:
			sum += Vector3(c.r, c.g, c.b)
		sum /= b.size()
		pal.append(Color(snappedf(sum.x, 1.0 / 31.0), snappedf(sum.y, 1.0 / 31.0), snappedf(sum.z, 1.0 / 31.0)))
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.5:
				continue
			var bestc := pal[0]
			var bd := 9.0
			for q in pal:
				var d := (c.r - q.r) * (c.r - q.r) + (c.g - q.g) * (c.g - q.g) + (c.b - q.b) * (c.b - q.b)
				if d < bd:
					bd = d
					bestc = q
			img.set_pixel(x, y, bestc)


## Activo en la mesa: el retrato cuadrado solo, sin marco de carta.
func _draw_big_card(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		_draw_card_back(r)
		return
	# El Activo se ve como retrato suelto, sin marco de carta (el tipo ya lo indica la
	# franja del cuadro de info). Ocupa el lugar de la carta, un poco más grande.
	var q := _portrait_rect(r.position.floor())
	var t := _main_type(m.top())
	draw_rect(Rect2(q.position + Vector2(2, 2), q.size), Color("#202838"))
	draw_rect(q, C_INK)
	var inner := q.grow(-1)
	var side := int(inner.size.x)
	var tex := _art_texture(m.top(), side, side)
	if tex != null:
		draw_texture(tex, inner.position)
		_draw_holo(inner, m.top(), false, _cosmos.get("%s|%dx%d" % [m.top(), side, side], {}))
	else:
		draw_rect(inner, TYPE_DARK[t])
		_draw_emblem(inner.grow(-8), t, TYPE_LIGHT[t])
	# Herramienta y MT unidas: cartitas en la esquina de abajo a la izquierda
	var k := 0
	for id in [m.tool, m.tm]:
		if id != "":
			var tr := Rect2(q.position + Vector2(3 + k * 10, q.size.y - 10), Vector2(7, 7))
			draw_rect(tr.grow(1), C_INK)
			_draw_card_image(tr, id)
			k += 1
	if m.is_ex():
		var er := Rect2(q.end - Vector2(14, 10), Vector2(13, 9))
		draw_rect(er, C_INK)
		_text(er.position + Vector2(1, -2), "ex", C_LIGHT)
	_draw_body_pop_portrait(q, m)


# ===========================================================================
# Poké-Body del Activo: una pestañita verde con su nombre pegada al cuadro de info
# ===========================================================================

## Las habilidades del Activo para su pestaña: [nombre, encendida, "body" o "power"].
## Poké-Body: encendido si funciona (anulado, por ejemplo por Toxic Gas, se ve gris; los que
## solo sirven en la Banca no van). Poké-Power: encendido si se puede usar ahora (o, en el
## turno del otro, si no está bloqueado); gris si ya se usó o está bloqueado.
func _active_body_names(m: PokemonInPlay) -> Array:
	var out: Array = []
	var pl := game.owner_of(m)
	for ab in m.abilities():
		var nm: String = ab.get("name", "")
		if ab.get("kind", "") == "Poké-Power":
			if nm == Abilities.DISCARD_FOSSIL:
				continue
			var ready := false
			if pl != null and not Abilities.power_blocked(game, pl, m):
				ready = _power_slots(pl).has(-1) if game.current == pl.index else true
			out.append([nm, ready, "power"])
			continue
		if ab.get("kind", "") != "Poké-Body":
			continue
		if str(ab.get("text", "")).to_lower().contains("on your bench"):
			continue
		out.append([nm, Abilities.body(game, m, nm), "body"])
	return out


const TAB_COLORS := {"body": [Color("#3c9848"), Color("#78d080")], "power": [Color("#d03828"), Color("#f88868")],
		"off": [Color("#8c8c94"), Color("#b0b0b8")]}


# Cuando un Poké-Body del Activo actúa (evita o reduce daño, contraataca, cura...): la
# pestaña da un saltito y se aclara, el arte se ilumina y sube su nombre.
const BODY_POP_TIME := 0.9
var _body_pops: Array = []     # en cola: [jugador, nombre]
var _body_pop := {}            # el que se ve: {"p", "name", "t"}


func _collect_body_events(attack: bool = false) -> void:
	var mark: int = game.checkup_mark if game.checkup_mark >= 0 else game.body_events.size()
	for i in game.body_events.size():
		var ev: Array = game.body_events[i]
		var early := attack and i < mark      # actuó con el golpe (no en el chequeo de después)
		if early and anim.get("scene", false) and (ev[0] == anim.get("def_mon") or ev[0] == anim.get("att_mon_s")):
			# En la pelea se ve junto al golpe, al lado de su Pokémon (aunque haya quedado KO)
			var who: int = anim["def"] if ev[0] == anim.get("def_mon") else anim["att"]
			var lst: Array = anim.get("bodies", [])
			if not lst.has([who, str(ev[1])]):
				lst.append([who, str(ev[1])])
			anim["bodies"] = lst
			continue
		for pl in game.players:
			if pl.active == ev[0] or pl.active2 == ev[0]:
				var item := [pl.index, str(ev[1]), early]
				if not _body_pops.has(item) and not (_body_pop.get("p", -1) == item[0] and _body_pop.get("name", "") == item[1]):
					_body_pops.append(item)
	game.body_events.clear()


## Avanza (se espera a que terminen el ataque y los KO, así se ve junto al resultado).
func _update_body_pop(delta: float) -> void:
	var early: bool = not anim.is_empty() and anim.get("applied", false) and not anim.get("waiting", false) \
			and not _body_pops.is_empty() and _body_pops[0].size() > 2 and _body_pops[0][2]
	if _body_pop.is_empty() and not early and (not anim.is_empty() or not ko_anim.is_empty() or not check_anim.is_empty() or not power_anim.is_empty() \
			or not banner.is_empty() or not prize_anim.is_empty()):
		return
	if _body_pop.is_empty():
		if _body_pops.is_empty():
			return
		var it: Array = _body_pops.pop_front()
		_body_pop = {"p": it[0], "name": it[1], "t": 0.0}
		snd.play("move")
	_body_pop["t"] += delta
	if _body_pop["t"] >= BODY_POP_TIME:
		_body_pop = {}


## 0..1 mientras dura el salto de ese jugador (o -1 si no hay).
func _body_pop_k(player: int) -> float:
	if _body_pop.is_empty() or _body_pop["p"] != player:
		return -1.0
	return clampf(_body_pop["t"] / BODY_POP_TIME, 0.0, 1.0)


func _draw_body_pop_portrait(q: Rect2, m: PokemonInPlay) -> void:
	var pl := game.owner_of(m) if game != null else null
	if pl == null or pl.active != m:
		return
	var k := _body_pop_k(pl.index)
	if k < 0.0:
		return
	var e := 1.0 - k
	var types := CardDB.types(m.top())
	var col: Color = TYPE_COLORS.get(types[0] if not types.is_empty() else "Colorless", Color.WHITE)
	draw_rect(q.grow(-1), Color(col.lightened(0.6), 0.45 * e * e))
	var nm: String = _body_pop["name"] + "!"
	var y := q.position.y + 10 - k * 18.0
	var x := clampf(roundf(q.get_center().x - _text_w(nm) / 2.0), 3.0, W - 3.0 - _text_w(nm))
	var a := clampf(e * 2.0, 0.0, 1.0)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_text(Vector2(x, y) + o, nm, Color(C_INK, a))
	_text(Vector2(x, y), nm, Color(1, 1, 0.75, a))


const STADIUM_SHORT := {"Team Aqua Hideout": "Aqua Hideout", "Team Magma Hideout": "Magma Hideout",
		"High Pressure System": "High Pressure", "Low Pressure System": "Low Pressure",
		"Magnetic Storm": "Mag. Storm"}
const STADIUM_RESERVE := Rect2(54, 42, 54, 12)   # entre los contadores del rival y su cuadro
var _stadium_layout := {}


## Dónde van las pestañas de Poké-Body (sin dibujarlas).
func _body_tab_rects() -> Array:
	var out: Array = []
	for pl in game.players:
		if pl.active == null:
			continue
		var names := _active_body_names(pl.active)
		if names.is_empty():
			continue
		var r := Rect2(_info_rect(pl.index).position, INFO_SIZE)
		var txt := " / ".join(names.map(func(b): return b[0]))
		var w := minf(_text_w(txt) + 10, r.size.x - 4)
		var below: bool = pl.index != human
		out.append(Rect2(r.position.x + 4, r.end.y - 1 if below else r.position.y - 11, w, 12))
	return out


## Pestaña del Estadio: en el medio de la mesa (sobre la línea que separa los lados), lo más
## centrada posible sin tocar las pestañas de Poké-Body ni los contadores; si no entra ni con
## el nombre corto, va en el hueco del rival donde está la cartita del Estadio (y la tapa).
func _layout_stadium_tab() -> void:
	_stadium_layout = {}
	if game == null or mode != "duel" or game.stadium == "" or _dbl():
		return
	var full := CardDB.card_name(game.stadium)
	var y := 50.0
	var band := Rect2(0, y, W, 12)
	var avoid := _body_tab_rects()
	for pl in game.players:
		avoid.append(Rect2(_counters_pos(pl.index), Vector2(46, 20)))
	var blocked: Array = []
	for bx in avoid:
		var g: Rect2 = bx.grow(2)
		if g.intersects(band):
			blocked.append([g.position.x, g.end.x])
	blocked.sort_custom(func(p, q): return p[0] < q[0])
	var free: Array = []
	var x0 := 2.0
	for bl in blocked:
		if bl[0] > x0:
			free.append([x0, bl[0]])
		x0 = maxf(x0, bl[1])
	if W - 2.0 > x0:
		free.append([x0, W - 2.0])
	var cx := W / 2.0
	for name in [full, STADIUM_SHORT.get(full, full)]:
		var w := _text_w(name) + 12
		var best_d := INF
		var best := Rect2()
		for f in free:
			if f[1] - f[0] >= w:
				var x := clampf(cx - w / 2.0, f[0], f[1] - w)
				var d := absf(x + w / 2.0 - cx)
				if d < best_d:
					best_d = d
					best = Rect2(roundf(x), y, w, 12)
		if best_d < INF:
			_stadium_layout = {"rect": best, "txt": name, "reserve": false}
			return
	_stadium_layout = {"rect": STADIUM_RESERVE, "txt": full, "reserve": true}


func _draw_stadium_tab() -> void:
	if _stadium_layout.is_empty() or anim.get("scene", false):
		return            # (durante la mini pelea no: la mesa queda tapada)
	var r: Rect2 = _stadium_layout["rect"]
	var txt: String = _stadium_layout["txt"]
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#283858"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), Color("#c08030"))
	draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 1), Color("#f0c070"))
	_text_scroll(r.position + Vector2(6, 1), txt, Color.WHITE, r.size.x - 10, "stadium_tab")


## Arriba del cuadro de info (tu Activo) o abajo (el del rival). Verde si funciona; gris,
## sin color, si está anulado.
func _draw_body_tab(r: Rect2, m: PokemonInPlay, below: bool) -> void:
	if _face_down(m):
		return
	var bodies := _active_body_names(m)
	if bodies.is_empty():
		return
	var on := bodies.any(func(b): return b[1])
	var txt := " / ".join(bodies.map(func(b): return b[0]))
	var w := minf(_text_w(txt) + 10, r.size.x - 4)
	var tab := Rect2(r.position.x + 4, r.end.y - 1 if below else r.position.y - 11, w, 12)
	draw_rect(Rect2(tab.position + Vector2(2, 2), tab.size), Color("#283858"))
	draw_rect(tab, C_INK)
	# Un tramo de color por habilidad (verde Poké-Body, rojo Poké-Power, gris apagada)
	var sx := tab.position.x + 1
	for i in bodies.size():
		var b: Array = bodies[i]
		var cols: Array = TAB_COLORS[b[2] if b[1] else "off"]
		var seg_w: float = _text_w(b[0]) + (5 if i == 0 else 0) + (5 if i == bodies.size() - 1 else _text_w(" / ") / 2.0 + 1)
		if i == bodies.size() - 1:
			seg_w = tab.end.x - 1 - sx
		seg_w = minf(seg_w, tab.end.x - 1 - sx)
		draw_rect(Rect2(sx, tab.position.y + 1, seg_w, tab.size.y - 2), cols[0])
		draw_rect(Rect2(sx, tab.position.y + 1, seg_w, 1), cols[1])
		sx += seg_w
	var pk := _body_pop_k(game.owner_of(m).index) if bodies.any(func(b): return b[1] and b[2] == "body") else -1.0
	if pk >= 0.0:              # el Poké-Body acaba de actuar: salta y se aclara
		var e := 1.0 - pk
		tab.position.y -= roundf(sin(minf(pk / 0.3, 1.0) * PI) * 3.0)
		draw_rect(tab, C_INK)
		draw_rect(tab.grow(-1), Color("#3c9848").lerp(Color("#c8f8b0"), e * 0.85))
	_text_scroll(tab.position + Vector2(5, 1), txt, Color.WHITE if on else Color("#d8d8e0"), w - 8, "body%d" % int(r.position.y))
	if on and animations_on:     # un destello que la cruza cada tanto
		var ph := fmod(Time.get_ticks_msec() / 1000.0 + r.position.y * 0.01, 2.5) / 0.7
		if ph < 1.0:
			var bx := tab.position.x - 8 + ph * (tab.size.x + 16)
			for yy in int(tab.size.y - 2):
				var x := bx - yy * 0.5
				var r1 := Rect2(x, tab.position.y + 1 + yy, 5, 1).intersection(tab.grow(-1))
				if r1.size.x > 0:
					draw_rect(r1, Color(1, 1, 1, 0.85))
				var r2 := Rect2(x + 7, tab.position.y + 1 + yy, 2, 1).intersection(tab.grow(-1))
				if r2.size.x > 0:
					draw_rect(r2, Color(1, 1, 1, 0.5))
		# y una estrellita que titila en la punta al terminar de pasar
		if ph >= 1.0 and ph < 1.5:
			var sp := Vector2(tab.end.x - 2, tab.position.y + 1)
			var e := 1.0 - (ph - 1.0) / 0.5
			draw_rect(Rect2(sp + Vector2(-2, 0), Vector2(5, 1)), Color(1, 1, 0.8, e))
			draw_rect(Rect2(sp + Vector2(0, -2), Vector2(1, 5)), Color(1, 1, 0.8, e))


## Retrato del Activo (46x46) dentro del lugar de la carta (42x52).
func _portrait_rect(card_pos: Vector2) -> Rect2:
	return Rect2(card_pos + Vector2(-2, 3), Vector2(46, 46))


## Preparación: los Pokémon que pone el rival van boca abajo (como en el juego real, se dan
## vuelta los de los dos recién cuando termina la preparación).
func _face_down(m: PokemonInPlay) -> bool:
	if game == null or game.phase != "setup" or mode != "duel":
		return false
	var own := game.owner_of(m)
	return own != null and own.index != human


func _draw_mini_card(r: Rect2, m: PokemonInPlay, hp_inside: bool = false) -> void:
	if _face_down(m):
		_draw_card_back(r)
		return
	var t := _main_type(m.top())
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), C_YELLOW)
	draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), C_YELLOW_D)
	_fill_types(r.grow(-2), m, true)
	if _shows_reverse(m):
		_draw_reverse(r.grow(-1), Rect2(r.position + Vector2(2, 3), Vector2(16, 16)), m.top())
	draw_rect(Rect2(r.position + Vector2(2, 3), Vector2(16, 16)), Color("#c8c8d0"))
	var tex := _art_texture(m.top(), 14, 14)
	if tex != null:
		draw_texture(tex, r.position + Vector2(3, 4))
		_draw_holo(Rect2(r.position + Vector2(3, 4), Vector2(14, 14)), m.top(), true)
	else:
		draw_rect(Rect2(r.position + Vector2(3, 4), Vector2(14, 14)), TYPE_DARK[t])
		_draw_emblem(Rect2(r.position + Vector2(5, 6), Vector2(10, 10)), t, TYPE_LIGHT[t])
	# Energías unidas
	var units: Array = Energy.units(m)
	units = units.slice(0, maxi(0, units.size() - _pending_units(m)))
	for i in mini(units.size(), 4):
		var u: Array = units[i]
		var et: String = u[0] if u.size() == 1 else "*"
		var ec: Color = TYPE_COLORS.get(et, C_LIGHT)
		var ey := 14.0 if hp_inside else 20.0     # mesa doble: arriba del número de PS
		draw_rect(Rect2(r.position + Vector2(2 + i * 4, ey), Vector2(4, 4)), C_INK)
		draw_rect(Rect2(r.position + Vector2(3 + i * 4, ey + 1), Vector2(2, 2)), ec)
	if units.size() > 4:
		draw_rect(Rect2(r.position + Vector2(18, 20), Vector2(1, 3)), C_INK)
		draw_rect(Rect2(r.position + Vector2(17, 21), Vector2(3, 1)), C_INK)
	# Herramienta / MT: la misma cartita que en el Activo, en la esquina de arriba a la
	# derecha (si tiene las dos, una al lado de la otra); y condición especial (puntito rojo)
	var k := 0
	for id in [m.tool, m.tm]:
		if id != "":
			var tr := Rect2(r.end.x - 9 - k * 9, r.position.y + 1, 7, 7)
			draw_rect(tr.grow(1), C_INK)
			_draw_card_image(tr, id)
			k += 1
	if not _condition_list(m).is_empty():
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(4, 4)), C_INK)
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, 2)), C_HP_LOW)
	# PS que le quedan, en números
	var ratio := clampf(_shown_hp(m) / max(1, m.max_hp()), 0.0, 1.0)
	var hs := str(maxi(0, roundi(_shown_hp(m))))
	var w := hs.length() * 4 + 3
	var pill := Rect2(floor(r.get_center().x - w / 2.0), r.end.y + 1, w, 7)
	if hp_inside:                  # mesa doble: el número va sobre el borde de abajo de la carta
		pill.position.y = r.end.y - 6
	draw_rect(pill, C_INK)
	_draw_tiny(pill.position + Vector2(2, 1), hs, HP_COLORS[0 if ratio > 0.5 else (1 if ratio > 0.2 else 2)][0])


func _draw_bench_cards(p: PlayerState) -> void:
	for i in game.rules.bench_size:
		var r := _bench_rect(p.index, i)
		if i >= p.bench.size() or _is_moving(p.bench[i]):
			_outline(r, C_LINE if p.index == human else Color("#c87060"))
			continue
		_draw_mini_card(r, p.bench[i])
		if not _face_down(p.bench[i]):
			_draw_bench_status(p, i, r)


## Recuadro con nombre, barra de PS, condiciones y Energías (como en las batallas de GBA).
func _draw_info_box(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		return
	var t := _main_type(m.top())
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#283858"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), Color("#f8f8e8"))
	draw_rect(Rect2(r.position.x + 1, r.end.y - 3, r.size.x - 2, 2), Color("#d8d8b8"))
	if _shows_reverse(m):
		_draw_reverse_box(Rect2(r.position + Vector2(4, 1), r.size - Vector2(5, 2)), m.top())
	_fill_types(Rect2(r.position + Vector2(1, 1), Vector2(3, r.size.y - 2)), m)
	if CardDB.card_name(m.top()).contains("★"):
		_draw_star_mark(r)
	if CardDB.is_delta(m.top()):
		_draw_delta_mark(r, m.top(), r.position.y + 19)
	var name := m.display_name()
	var ex := name.ends_with(" ex")
	if ex:
		name = name.trim_suffix(" ex")
	var avail := r.size.x - 11 - (12 if ex else 0)
	_text_scroll(r.position + Vector2(7, 1), name, C_TEXT, avail, "info%d" % int(r.position.y))
	if ex:
		_text(Vector2(r.position.x + 7 + minf(_text_w(name), avail) + 2, r.position.y + 1), "ex", Color("#c03028"))
	_draw_hp_bar(r.position + Vector2(7, 12), int(r.size.x) - 11, m)
	var conds := _condition_list(m)
	if not conds.is_empty() and not _draw_status_pill(r.position + Vector2(7, 21), conds):
		for i in conds.size():         # sin las pastillas: los símbolos dibujados
			_draw_condition_icon(r.position + Vector2(11 + i * 9, 24), conds[i])
	var hp_txt := "%d/%d" % [maxi(0, roundi(_shown_hp(m))), m.max_hp()]
	_text(Vector2(r.end.x - 5 - _text_w(hp_txt), r.position.y + 19), hp_txt, C_TEXT)
	_draw_energy(r.position + Vector2(7, 29), m)


## La δ del logo de las cartas δ (DejaVu Serif Bold Italic a 18 px), ya pasada a píxeles:
## cada dígito es la opacidad 0-9. DELTA_GLOW es la misma letra desenfocada (el brillo).
const DELTA_CORE := [
		"000000000000000000",
		"000000000000000000",
		"000000000000000000",
		"000000035676641000",
		"000000699532692000",
		"000002996000050000",
		"000004995000000000",
		"000001899653000000",
		"000003896489710000",
		"000039960039960000",
		"000189920039990000",
		"000499900049990000",
		"000699700069980000",
		"000799600089950000",
		"000699500299810000",
		"000299700699300000",
		"000038988961000000",
		"000000122000000000",
		"000000000000000000",
		"000000000000000000",
		"000000000000000000"]
const DELTA_GLOW := [
		"000000000000000000",
		"000000001111100000",
		"000000112222211000",
		"000001233333321100",
		"000012455433332100",
		"000013565432221100",
		"000024666432211000",
		"000124666543321000",
		"000135665555431000",
		"001246654456642100",
		"001356643356753100",
		"012467642357753100",
		"012567532357753100",
		"012567532357642100",
		"012466533466531000",
		"001356544455321000",
		"001234444443210000",
		"000122333221100000",
		"000011111110000000",
		"000000000000000000",
		"000000000000000000"]


## Pokémon δ: la δ del logo de las cartas, centrada debajo de la barra de PS (los números
## pasan por encima), del color del tipo que gana (con dos tipos, uno arriba y el otro
## abajo), con un brillo que late despacio y un destello que la cruza en cada vuelta.
## top: dónde termina la barra de PS.
func _draw_delta_mark(r: Rect2, id: String, top: float) -> void:
	var cols: Array = []
	for ty in CardDB.types(id):
		cols.append(TYPE_COLORS.get(ty, C_TEXT))
	if cols.is_empty():
		cols = [C_TEXT]
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(t * TAU / 1.5)       # late cada 1,5 s
	var gh: int = DELTA_CORE.size()
	var gw: int = DELTA_CORE[0].length()
	var cy := (top + 3.0 + r.end.y - 3.0) / 2.0
	var o := Vector2(roundf(r.position.x + 3 + (r.size.x - 3) / 2.0 - gw / 2.0), roundf(cy - gh / 2.0))
	var a_core := 0.30 + 0.12 * pulse
	var a_glow := 0.22 + 0.20 * pulse
	var sweep := fmod(t / 3.0, 1.0) * (gw + gh) * 1.25 - gh * 0.4     # destello: una pasada cada 3 s
	for y in gh:
		var col: Color = cols[0] if y < gh / 2 or cols.size() == 1 else cols[1]
		var rc: String = DELTA_CORE[y]
		var rg: String = DELTA_GLOW[y]
		for x in gw:
			var a := maxf(int(rc[x]) / 9.0 * a_core, int(rg[x]) / 9.0 * a_glow)
			if a <= 0.01:
				continue
			var c := Color(col, a)
			if int(rc[x]) >= 5 and absf(x + y * 0.6 - sweep) < 2.0:
				c = Color(col.lightened(0.5), minf(1.0, a + 0.4))
			draw_rect(Rect2(o + Vector2(x, y), Vector2(1, 1)), c)


## Pokémon ★: una estrella amarilla de todo el alto del recuadro, detrás del nombre y los PS,
## que late, brilla alrededor, la cruza un destello y le titilan las puntas. La silueta se
## calcula una vez por tamaño: cada píxel es [x, y, opacidad del cuerpo, del brillo].
var _star_px := {}


func _star_pixels(h: int) -> Dictionary:
	if _star_px.has(h):
		return _star_px[h]
	var rad := h / 2.0 + 1.0
	var c := Vector2(rad + 2, rad + 2)
	var poly := PackedVector2Array()
	for i in 10:
		var rr := rad if i % 2 == 0 else rad * 0.45
		var ang := -PI / 2 + i * PI / 5
		poly.append(c + Vector2(cos(ang), sin(ang)) * rr)
	var size := int(ceil(rad * 2 + 4))
	var inside := {}
	for y in size:
		for x in size:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				inside[Vector2i(x, y)] = true
	# Dos texturas blancas (cuerpo y brillo) que se tiñen al dibujar: 2 llamadas por cuadro
	var core := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var glow := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var pts: Array = []
	for y in size:
		for x in size:
			if inside.has(Vector2i(x, y)):
				core.set_pixel(x, y, Color(1, 1, 1, 1))
				pts.append(Vector2i(x, y))
				continue
			var gl := 0.0
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if inside.has(Vector2i(x + dx, y + dy)):
						gl = maxf(gl, 1.0 - (absf(dx) + absf(dy)) / 4.0)
			if gl > 0.0:
				glow.set_pixel(x, y, Color(1, 1, 1, gl))
	_star_px[h] = {"core": ImageTexture.create_from_image(core), "glow": ImageTexture.create_from_image(glow),
			"pts": pts, "c": c, "rad": rad}
	return _star_px[h]


func _draw_star_mark(r: Rect2) -> void:
	var data: Dictionary = _star_pixels(int(r.size.y - 4))
	var c: Vector2 = data["c"]
	var rad: float = data["rad"]
	var o := Vector2(roundf(r.position.x + 3 + (r.size.x - 3) / 2.0 - c.x), roundf(r.position.y + r.size.y / 2.0 + 1 - c.y))
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(t * TAU / 1.5)
	var yel := Color("#f8d030")
	draw_texture(data["glow"], o, Color(yel, 0.25 + 0.22 * pulse))
	draw_texture(data["core"], o, Color(yel, 0.30 + 0.12 * pulse))
	# Destello diagonal (una pasada cada 3 s) y puntas que titilan de a una
	var sweep := fmod(t / 3.0, 1.0) * 2.8 - 1.4
	if absf(sweep) < 1.1:
		for q: Vector2i in data["pts"]:
			if absf(((q.x - c.x) + (q.y - c.y)) / (2.0 * rad) - sweep) < 0.08:
				draw_rect(Rect2(o + Vector2(q), Vector2(1, 1)), Color("#fffac8", 0.75))
	var clip := r.grow(-1)
	for k in 5:
		if sin(t * TAU / 0.75 + k * 1.3) <= 0.6:
			continue
		var ang := -PI / 2 + k * TAU / 5
		var tip := (o + c + Vector2(cos(ang), sin(ang)) * rad * 0.95).round()
		for dd in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			if clip.has_point(tip + dd):
				draw_rect(Rect2(tip + dd, Vector2(1, 1)), Color("#fff8be"))


## Barra de PS con la etiqueta naranja: verde, amarilla o roja según lo que queda.
func _draw_hp_bar(pos: Vector2, width: int, m: PokemonInPlay) -> void:
	var shown := _shown_hp(m)
	var ratio := clampf(shown / max(1, m.max_hp()), 0.0, 1.0)
	var real := clampf(float(m.hp_left()) / max(1, m.max_hp()), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(width, 7)), C_INK)
	_draw_tiny(pos + Vector2(2, 1), "HP", Color("#f8b838"))
	var bx := pos.x + 11
	var bw := width - 12
	draw_rect(Rect2(bx, pos.y + 2, bw, 3), Color("#506858"))
	var col: Array = HP_COLORS[0 if ratio > 0.5 else (1 if ratio > 0.2 else 2)]
	var fill := roundf(bw * ratio)
	draw_rect(Rect2(bx, pos.y + 2, fill, 2), col[0])
	draw_rect(Rect2(bx, pos.y + 4, fill, 1), col[1])
	if real < ratio:   # la parte que se está perdiendo, en blanco
		var rf := roundf(bw * real)
		draw_rect(Rect2(bx + rf, pos.y + 2, fill - rf, 3), C_LIGHT)


## Dorso de carta chiquito (original, no es el dorso oficial).
func _draw_mini_back(r: Rect2) -> void:
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), Color("#3858c0"))
	var c := r.get_center().floor()
	draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), C_YELLOW)
	draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color("#c03028"))


## Premios (dorsos) y, con íconos y números, el mazo, la mano y el descarte.
func _draw_counters(p: PlayerState) -> void:
	var o := _counters_pos(p.index)
	var mine := p.index == human
	for i in 6:
		var c := o + Vector2((i % 3) * 9, (i / 3) * 10)
		if i < p.prizes.size():
			_draw_mini_back(Rect2(c, Vector2(8, 9)))
		else:
			_outline(Rect2(c, Vector2(8, 9)), C_LINE if mine else Color("#c87060"))
	var ix := o.x + 29
	var vals := [p.deck.size(), p.hand.size(), p.discard.size()]
	var cols := [Color("#3858c0"), C_LIGHT, Color("#909098")]
	for k in 3:
		var y := o.y + k * 7
		draw_rect(Rect2(ix, y, 5, 6), C_INK)
		draw_rect(Rect2(ix + 1, y + 1, 3, 4), cols[k])
		_draw_tiny(Vector2(ix + 8, y + 1), str(vals[k]), C_INK)
		_draw_tiny(Vector2(ix + 7, y), str(vals[k]), C_LIGHT)


# ===========================================================================
# Batallas dobles (2 contra 2): la mesa
# ===========================================================================
# Reglas de la época (variante "2-on-2" del reglamento EX): hasta 2 Pokémon Activos por
# jugador y 4 en la Banca (6 en juego, como siempre); un solo ataque por turno (elegís cuál
# de tus Activos ataca y a cuál de los Activos del rival); "each Defending Pokémon" afecta
# a los dos; una sola retirada por turno entre los dos Activos.
#
# Mesa de 240x112 en cuatro filas: Banca del rival (26), Activos del rival (30), tus
# Activos (30) y tu Banca (26). Cada Activo es compacto: carta de 26x28 y ficha de 82x28.

var doubles_preview := false        # maqueta de la mesa doble (mientras se arma el modo)
var mock_second: Array = [null, null]   # el segundo Activo de cada jugador en la maqueta
var mock_target := -1               # Activo del rival marcado como objetivo en la maqueta (0/1)

const DBL_CARD := Vector2(26, 28)
const DBL_INFO := Vector2(82, 28)
const DBL_BENCH := 4


## Rectángulo de la carta del Activo i (0 o 1) de un jugador en la mesa doble.
func _dbl_card_rect(player: int, i: int) -> Rect2:
	if player == human:
		return Rect2(Vector2(4 + i * 120, 57), DBL_CARD)
	return Rect2(Vector2(W - 4 - DBL_CARD.x - (1 - i) * 120, 27), DBL_CARD)


func _dbl_info_rect(player: int, i: int) -> Rect2:
	var c := _dbl_card_rect(player, i)
	if player == human:            # tu ficha a la derecha de la carta; la del rival a la izquierda
		return Rect2(c.end.x + 2, c.position.y, DBL_INFO.x, DBL_INFO.y)
	return Rect2(c.position.x - 2 - DBL_INFO.x, c.position.y, DBL_INFO.x, DBL_INFO.y)


func _dbl_bench_rect(player: int, i: int) -> Rect2:
	if player == human:
		return Rect2(Vector2(W - 4 - DBL_BENCH * 22 + 2 + i * 22, 86), MINI_SIZE)
	return Rect2(Vector2(4 + i * 22, 0), MINI_SIZE)


func _dbl_actives(p: PlayerState) -> Array:
	var out: Array = [p.active, p.active2 if p.active2 != null else mock_second[p.index]]
	return out


func _draw_doubles_board(opp: PlayerState, me: PlayerState) -> void:
	for pl: PlayerState in [opp, me]:
		var mine := pl == me
		# Banca: 4 lugares, el número de PS adentro de la carta (no hay lugar abajo)
		for i in DBL_BENCH:
			var r := _dbl_bench_rect(pl.index, i)
			if i < pl.bench.size():
				_draw_mini_card(r, pl.bench[i], true)
			else:
				_outline(r, C_LINE if mine else Color("#c87060"))
		# Premios, mazo, mano y descarte al lado de la Banca
		_draw_counters_at(pl, _counters_pos(pl.index) if _dbl() else (Vector2(W - 4 - 46, 1) if not mine else Vector2(4, 87)))
		# Los dos Activos
		var acts := _dbl_actives(pl)
		for i in 2:
			var m: PokemonInPlay = acts[i]
			var cr := _dbl_card_rect(pl.index, i)
			if m == null or _is_moving(m):
				_outline(cr, C_LINE if mine else Color("#c87060"))
				continue
			var off := Vector2.ZERO
			if i == dbl_focus[pl.index]:
				off = _anim_offset(pl.index)
			if pl.index == human:
				off += _idle_bob(pl)
			var ir := _dbl_info_rect(pl.index, i)
			_draw_compact_info(Rect2(ir.position + _hp_shake(m), ir.size), m, mine)
			_draw_compact_card(Rect2(cr.position + off, cr.size), m)
			_draw_status_fx(pl, m, Rect2(cr.position + off + Vector2(2, 2), Vector2(22, 22)))
		_draw_hit_flash(pl)
	if game.stadium != "":
		_draw_stadium_card_at(game.stadium, Vector2(112, 1))
	# Acción marcada en el menú: el Activo propio que actúa (amarillo) y el del rival que
	# recibe el ataque (rojo, titila)
	var hov := _hovered_action()
	if not hov.is_empty() and hov.has("ctx") or (not hov.is_empty() and hov["t"] in ["attack", "retreat"]):
		var c = hov.get("ctx", [false, false])
		var my_i := 1 if c[me.index] else 0
		var on := int(Time.get_ticks_msec() / 250.0) % 2 == 0
		if me.active2 != null:
			_outline(_dbl_card_rect(me.index, my_i).grow(1), Color("#f8d030"))
		if hov["t"] == "attack" and opp.active2 != null and hov.get("tg", -2) == -2:
			var op_i := 1 if c[opp.index] else 0
			for r: Rect2 in [_dbl_card_rect(opp.index, op_i), _dbl_info_rect(opp.index, op_i)]:
				_outline(r.grow(1), Color("#f85838") if on else Color("#f8d030"))
				_outline(r.grow(2), Color(0, 0, 0, 0.45))
	# Objetivo elegido: flechita roja que salta sobre el Activo del rival
	if mock_target >= 0:
		var on := int(Time.get_ticks_msec() / 250.0) % 2 == 0
		var col := Color("#f85838") if on else Color("#f8d030")
		for r: Rect2 in [_dbl_card_rect(opp.index, mock_target), _dbl_info_rect(opp.index, mock_target)]:
			_outline(r.grow(1), col)
			_outline(r.grow(2), Color(0, 0, 0, 0.45))
		# el otro Activo del rival se apaga un poco
		var other := 1 - mock_target
		for r: Rect2 in [_dbl_card_rect(opp.index, other), _dbl_info_rect(opp.index, other)]:
			draw_rect(r, Color(0, 0, 0, 0.25))


## La acción marcada en el menú de tu turno (si hay una).
func _hovered_action() -> Dictionary:
	if game == null or game.actor() != human or menu_level != "list" or cursor < 0 or cursor >= menu_items.size():
		return {}
	return menu_items[cursor].get("action", {})


## Carta compacta del Activo en la mesa doble: marco amarillo, ilustración de 22x22 y una
## franja abajo con herramienta/MT y el logo ex.
func _draw_compact_card(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		_draw_card_back(r)
		return
	r.position = r.position.floor()
	var t := _main_type(m.top())
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#202838"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), C_YELLOW)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), C_YELLOW_L)
	draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), C_YELLOW_D)
	_fill_types(r.grow(-2), m, true)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(24, 24)), Color("#e0e0e8"))
	var tex := _art_texture(m.top(), 22, 22)
	if tex != null:
		draw_texture(tex, r.position + Vector2(2, 2))
	else:
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(22, 22)), TYPE_DARK[t])
		_draw_emblem(Rect2(r.position + Vector2(6, 6), Vector2(14, 14)), t, TYPE_LIGHT[t])
	if m.tool != "" or m.tm != "":
		draw_rect(Rect2(r.position + Vector2(2, 25), Vector2(3, 2)), _card_bg(m.tool if m.tool != "" else m.tm))
	if m.is_ex():
		_draw_tiny(r.position + Vector2(r.size.x - 9, 22), "ex", C_LIGHT)


## Ficha compacta: nombre, barra de PS y abajo las Energías y los PS en números. La
## pastilla de estado va sobre el nombre, a la derecha.
func _draw_compact_info(r: Rect2, m: PokemonInPlay, mine: bool) -> void:
	if _face_down(m):
		return
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#283858"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), Color("#f8f8e8"))
	draw_rect(Rect2(r.position.x + 1, r.end.y - 3, r.size.x - 2, 2), Color("#d8d8b8"))
	_fill_types(Rect2(r.position + Vector2(1, 1), Vector2(3, r.size.y - 2)), m)
	if CardDB.card_name(m.top()).contains("★"):
		_draw_star_mark(r)
	if CardDB.is_delta(m.top()):
		_draw_delta_mark(r, m.top(), r.position.y + 17)
	var name := m.display_name()
	var ex := name.ends_with(" ex")
	if ex:
		name = name.trim_suffix(" ex")
	var conds := _condition_list(m)
	var avail := r.size.x - 11 - (12 if ex else 0) - (22 if not conds.is_empty() else 0)
	_text_fit(r.position + Vector2(7, 0), name, C_TEXT, avail)
	if ex:
		_text(Vector2(r.position.x + 7 + minf(_text_w(name), avail) + 2, r.position.y), "ex", Color("#c03028"))
	if not conds.is_empty():
		_draw_status_pill(Vector2(r.end.x - 23, r.position.y + 2), conds)
	_draw_hp_bar(r.position + Vector2(5, 10), int(r.size.x) - 8, m)
	var hp_txt := "%d/%d" % [maxi(0, roundi(_shown_hp(m))), m.max_hp()]
	var hw := _text_w(hp_txt)
	_text(Vector2(r.end.x - 4 - hw, r.position.y + 16), hp_txt, C_TEXT)
	# Energías: las que entran antes del número; si sobran, "+n"
	var units: Array = Energy.units(m)
	units = units.slice(0, maxi(0, units.size() - _pending_units(m)))
	var room := int((r.size.x - 10 - hw - 4) / 9.0)
	var shown := mini(units.size(), room if units.size() <= room else room - 1)
	for i in shown:
		var u: Array = units[i]
		_draw_energy_icon(r.position + Vector2(10 + i * 9, 21.5), 8, u[0] if u.size() == 1 else "*")
	if units.size() > shown:
		_draw_tiny(r.position + Vector2(7 + shown * 9, 19), "+%d" % (units.size() - shown), C_TEXT)


func _draw_counters_at(p: PlayerState, o: Vector2) -> void:
	var mine := p.index == human
	for i in 6:
		var c := o + Vector2((i % 3) * 9, (i / 3) * 10)
		if i < p.prizes.size():
			_draw_mini_back(Rect2(c, Vector2(8, 9)))
		else:
			_outline(Rect2(c, Vector2(8, 9)), C_LINE if mine else Color("#c87060"))
	var ix := o.x + 29
	var vals := [p.deck.size(), p.hand.size(), p.discard.size()]
	var cols := [Color("#3858c0"), C_LIGHT, Color("#909098")]
	for k in 3:
		var y := o.y + k * 7
		draw_rect(Rect2(ix, y, 5, 6), C_INK)
		draw_rect(Rect2(ix + 1, y + 1, 3, 4), cols[k])
		_draw_tiny(Vector2(ix + 8, y + 1), str(vals[k]), C_INK)
		_draw_tiny(Vector2(ix + 7, y), str(vals[k]), C_LIGHT)


func _draw_stadium_card_at(id: String, at: Vector2) -> void:
	var r := Rect2(at, Vector2(16, 20))
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), C_STADIUM_BG)
	_draw_card_image(Rect2(r.position + Vector2(2, 2), Vector2(12, 12)), id)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 15, 12, 2), C_BODY if game.stadium_owner != human else C_FRAME_MID)


## Pantalla de título animada: la escena al azar de data/titulos.json, el logo y "PRESS START".
func _draw_attract() -> void:
	draw_rect(Rect2(0, 0, W, H), C_BG)
	title_scene.draw(self, _attract_t)
	_draw_logo(4, _attract_t)
	if int(_attract_t * 2.0) % 2 == 0:
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1)]:
			_text(Vector2(floor((W - _text_w("PRESS START")) / 2.0), 47) + o, "PRESS START", Color(0.08, 0.1, 0.18))
		_text_center(47, "PRESS START", C_LIGHT)
	# Aviso de proyecto de fans (va siempre, también en la versión web)
	for i in DISCLAIMER.size():
		var line: String = DISCLAIMER[i]
		var y := H - 21 + i * 9
		for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			_text(Vector2(floor((W - _text_w(line)) / 2.0), y) + o, line, Color(0.08, 0.1, 0.18))
		_text_center(y, line, Color(0.85, 0.87, 0.92))


const DISCLAIMER := ["Free fan game. Not affiliated with Nintendo,", "Game Freak, Creatures or The Pokémon Company."]


## El logo del juego (ui/logo.png, hecho con tools/logo_juego.py). t >= 0: cada tanto lo
## cruza un brillo (ui/logo_brillo.png, una tira de cuadros del mismo tamaño).
var _logo_tex: Texture2D
var _logo_shine: Texture2D

func _draw_logo(y: float, t: float = -1.0) -> void:
	if _logo_tex == null:
		var img := ImgLoad.load("res://ui/logo.png")
		var sh := ImgLoad.load("res://ui/logo_brillo.png")
		_logo_tex = ImageTexture.create_from_image(img) if img != null else null
		_logo_shine = ImageTexture.create_from_image(sh) if sh != null else null
	if _logo_tex == null:
		_text_center(y + 8, "ADVANCE", C_LIGHT, true)
		return
	var w := _logo_tex.get_width()
	var h := _logo_tex.get_height()
	var pos := Vector2(floor((W - w) / 2.0), y)
	draw_texture(_logo_tex, pos)
	if t >= 0.0 and _logo_shine != null:
		var n := _logo_shine.get_width() / w
		var f := int(fmod(t, 4.0) / 0.035)     # pasa en ~0.7 s, cada 4 s
		if f < n:
			draw_texture_rect_region(_logo_shine, Rect2(pos, Vector2(w, h)), Rect2(f * w, 0, w, h))


func _draw_title() -> void:
	if title_attract:
		_draw_attract()
		return
	if _table_tex == null:
		_table_tex = ImageTexture.create_from_image(_table_image())
	draw_rect(Rect2(0, 0, W, H), C_BG)
	draw_texture_rect(_table_tex, Rect2(0, 0, W, H), false, Color(1, 1, 1, 0.35))
	_draw_logo(1)
	if title_view == "duel":
		_draw_duel_setup()
	elif title_view == "online":
		online.draw()
	else:
		# Menú principal: cuatro opciones
		var panel := Rect2(64, 56, 112, 70)
		_frame(panel)
		for i in TITLE_ROWS:
			var y := panel.position.y + 6 + i * 12
			var sel := i == title_row and title_view == ""
			var label: String = TITLE_ITEMS[i]
			var col: Color = Color("#c03028") if sel else C_TEXT
			if i == 0 and not CAMPAIGN_ON:
				label = "Campaign (soon)"
				col = C_DIM
			if sel:
				_text(Vector2(panel.position.x + 8, y), "▶", C_TEXT)
			_text(Vector2(panel.position.x + 18, y), label, col)
	if title_view == "options":
		var o := Rect2(40, 40, 160, 84)
		_frame(o)
		_text(Vector2(o.position.x + 9, o.position.y + 4), "OPTIONS", C_DIM)
		for i in 6:
			var y := o.position.y + 16 + i * 11
			var sel := i == opt_cursor
			if sel:
				_text(Vector2(o.position.x + 8, y), "▶", C_TEXT)
			var label: String = PAUSE_ITEMS[i + 1] if i < 5 else "Card art"
			_text(Vector2(o.position.x + 17, y), label, C_TEXT)
			var v := _pause_value(i + 1) if i < 5 else (arte.batch_text() if arte.batch_text() != "" else "Get all")
			var vs := ("◀ " + v + " ▶") if sel and i < 5 else (("Z " + v) if sel else v)
			_text(Vector2(o.end.x - 8 - _text_w(vs), y), vs, C_TEXT if sel else C_DIM)
	if title_msg != "":
		_text_scroll(Vector2(6, 149), title_msg, Color("#f8a090"), 228, "title_msg")
	elif title_view == "duel":
		_text(Vector2(6, 149), "▲▼ select · ◀▶ change · Z start · X back", C_LIGHT)
	elif title_view == "online":
		_text_scroll(Vector2(6, 149), online.keys_text(), C_LIGHT, 228, "online_keys")
	else:
		_text(Vector2(6, 149), "▲▼ select · Z accept", C_LIGHT)


## Armado del duelo libre (se entra desde "Free duel" del menú principal).
func _draw_duel_setup() -> void:
	var names := Decks.names()
	var r := RuleSet.from_season(season_idx)
	var fmt := r.name
	if not r.missing_sets().is_empty():
		fmt += " (in progress: %d/%d sets)" % [r.legal_sets.size() - r.missing_sets().size(), r.legal_sets.size()]
	my_deck = clampi(my_deck, 0, names.size() - 1)
	opp_deck = clampi(opp_deck, 0, names.size() - 1)
	if not _deck_legal(names[my_deck], r):
		fmt += " · your deck isn't legal"
	elif not _deck_legal(names[opp_deck], r):
		fmt += " · the opponent's deck isn't legal"
	var star := func(nm: String) -> String: return ("★ " if Decks.is_user(nm) else "") + nm
	var rows := [["Your deck", star.call(names[my_deck])], ["Opponent", star.call(names[opp_deck])],
			["Difficulty", "%d · %s" % [ai_level, SimpleAI.LEVEL_NAMES[ai_level - 1]]], ["Format", fmt],
			["Battle", "Doubles (2 vs 2)" if doubles_mode else "Singles"], ["", "Start duel!"]]
	var panel := Rect2(0, 44, W, 100)
	_frame(panel)
	_text(Vector2(9, 48), "FREE DUEL", C_DIM)
	for i in rows.size():
		var y := 61 + i * 12 + (3 if i == rows.size() - 1 else 0)
		var sel := i == duel_row
		if sel:
			_text(Vector2(8, y), "▶", C_TEXT)
		if rows[i][0] != "":
			_text(Vector2(17, y), rows[i][0], C_DIM)
			var val: String = rows[i][1]
			if sel:
				_text_scroll(Vector2(72, y), "◀ " + val + " ▶", C_TEXT, 158, "duel%d" % i)
			else:
				_text_fit(Vector2(72, y), val, C_TEXT, 158)
		else:
			_text(Vector2(17, y), rows[i][1], Color("#c03028") if sel else C_TEXT)


# ===========================================================================
# Retratos del Activo
# ===========================================================================
# Si existe una imagen en sprites/ (dentro del proyecto) o en user://sprites/,
# se usa esa. Se busca, en orden: <id de carta>.png, <nombre>.png y <especie>.png
# (p.ej. ex1-3.png, Blaziken.png). Se reduce a 30x30 y a la paleta de 15 bits de
# la GBA. Si no hay imagen, se dibuja un emblema del tipo.

## Llegó el arte en alta de una carta: se olvidan las versiones chicas que se habían
## armado sin él (el emblema del tipo), para que la próxima vez salgan con el arte.
func _on_arte_listo(id: String) -> void:
	_clean.erase(id)
	for cache in [_sprites, _art]:
		for k in cache.keys():
			if str(k).begins_with(id + "|"):
				cache.erase(k)
	queue_redraw()


func _load_card_image(id: String) -> Image:
	if _clean.has(id):
		return _clean[id]
	var img := _load_card_image_raw(id)
	if img != null and _is_holo(id):
		img = _remove_holo_sparkles(img)
	_clean[id] = img
	return img


# --- Cartas holo -------------------------------------------------------------
# Las imágenes escaneadas de cartas holo traen el brillo "cosmos" del papel: puntitos de
# colores sobre el fondo. Al achicarlas a tamaño GBA esos puntos quedan como ruido, así
# que en las cartas holo se limpian con un filtro de mediana antes de reducirlas.
const HOLO_FILTER := true      # false = dejar las imágenes holo tal cual
const HOLO_WORK := 120         # tamaño intermedio para limpiar (píxeles)
var _clean := {}               # id -> imagen ya limpia (o la original)
var _rarity := {}


func _rarity_of(id: String) -> String:
	if _rarity.is_empty():
		var r = JSON.parse_string(FileAccess.get_file_as_string("res://data/rarezas.json"))
		_rarity = r if r is Dictionary else {"_": ""}
	return str(_rarity.get(id, ""))


## Brillo reverse en el marco: las cartas tuyas que sacaste reverse en la campaña, y las
## que solo existen en reverse holo (Black Star Promos 3, 8 y 10), sean de quien sean.
func _shows_reverse(m: PokemonInPlay) -> bool:
	if "Reverse" in _rarity_of(m.top()):
		return true
	return reverse_ids.has(m.top()) and game != null and game.players[human].all_in_play().has(m)


func _is_holo(id: String) -> bool:
	return HOLO_FILTER and "Holo" in _rarity_of(id)


## Reverse holo: el brillo va en el marco (todo menos la ilustración), como en las cartas
## reales. De Ruby & Sapphire a Team Magma vs Team Aqua es un arcoíris parejo que corre; en
## Hidden Legends, una grilla de simbolitos de Energía que se encienden en ola.
func _draw_reverse(outer: Rect2, hole: Rect2, id: String) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var legends := id.begins_with("ex5-")
	var tc: Color = _card_bg(id)
	var x0 := int(outer.position.x)
	var x1 := int(outer.end.x)
	var hx0 := int(hole.position.x)
	var hx1 := int(hole.end.x)
	for yy in range(int(outer.position.y), int(outer.end.y)):
		var inside := yy >= int(hole.position.y) and yy < int(hole.end.y)
		var segs := [[x0, hx0], [hx1, x1]] if inside else [[x0, x1]]
		for sg in segs:
			var x: int = sg[0]
			while x < sg[1]:
				var w := mini(2, sg[1] - x)
				var glow := 0.5 + 0.5 * sin((x - yy) / 9.0 + t * 2.2)
				if legends:
					var c0 := tc.lightened(0.55)
					c0.a = 0.35 + 0.3 * glow
					draw_rect(Rect2(x, yy, w, 1), c0)
				else:
					var hue := fposmod((x + yy) / 46.0 - t * 0.35, 1.0)
					draw_rect(Rect2(x, yy, w, 1), Color.from_hsv(hue, 0.65, 1.0, 0.4 + 0.35 * glow))
				x += w
	if legends:
		# Simbolitos (rombos de 3x3) en grilla, que se encienden en ola
		for yy in range(int(outer.position.y) + 1, int(outer.end.y) - 1, 4):
			for xx in range(int(outer.position.x) + 1, int(outer.end.x) - 1, 4):
				if xx + 2 > hx0 and xx < hx1 and yy + 2 > int(hole.position.y) and yy < int(hole.end.y):
					continue
				var b := pow(maxf(0.0, sin(t * 2.6 - (xx + yy) / 7.0)), 3.0)
				var c := Color(1, 1, 1) if b > 0.6 else tc.darkened(0.15)
				c.a = 0.45 + 0.55 * b
				draw_rect(Rect2(xx + 1, yy, 1, 3), c)
				draw_rect(Rect2(xx, yy + 1, 3, 1), c)


## Reverse holo en el recuadro del nombre de tu Pokémon activo: un tinte suave de arcoíris y
## una franja de luz que lo cruza en diagonal cada tanto (en Hidden Legends, simbolitos de
## Energía de su tipo que se encienden al pasar la franja). Va detrás del texto, que sigue legible.
const REV_PERIOD := 2.4           # segundos entre una pasada y la siguiente
const REV_BAND := 16.0            # ancho de la franja (píxeles)
const REV_ICON := 9               # Hidden Legends: tamaño de cada símbolo de Energía
const REV_ICON_STEP := 13         # ...y separación entre uno y otro

func _draw_reverse_box(box: Rect2, id: String) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var legends := id.begins_with("ex5-")
	var tc: Color = _card_bg(id)
	var x0 := int(box.position.x)
	var x1 := int(box.end.x)
	var y0 := int(box.position.y)
	var y1 := int(box.end.y)
	var span := box.size.x + box.size.y + REV_BAND * 2.0
	var band_x := fmod(t, REV_PERIOD) / REV_PERIOD * (span + 40.0) - REV_BAND - 20.0
	for yy in range(y0, y1):
		var x := x0
		while x < x1:
			var w := mini(2, x1 - x)
			var d := float(x - x0) + float(yy - y0) - band_x     # distancia a la franja (diagonal)
			var k := clampf(1.0 - absf(d) / REV_BAND, 0.0, 1.0)
			if legends:
				var c0 := tc.lightened(0.6)
				c0.a = 0.3 + 0.45 * k
				draw_rect(Rect2(x, yy, w, 1), c0)
			else:
				var hue := fposmod((x + yy) / 40.0 - t * 0.3, 1.0)
				draw_rect(Rect2(x, yy, w, 1), Color.from_hsv(hue, 0.6, 1.0, 0.2 + 0.55 * k))
				if k > 0.75:
					draw_rect(Rect2(x, yy, w, 1), Color(1, 1, 1, (k - 0.75) * 1.6))
			x += w
	if legends:
		# El símbolo de Energía del tipo del Pokémon (si tiene dos tipos, se alternan), en una
		# grilla escalonada; los que cruza la franja se encienden.
		var types: Array = CardDB.types(id).filter(func(x): return TYPE_DARK.has(x))
		if types.is_empty():
			types = ["Colorless"]
		var row := 0
		for yy in range(y0 + 1, y1 - 5, REV_ICON_STEP - 2):
			var col := 0
			for xx in range(x0 + 1 + (REV_ICON_STEP / 2 if row % 2 == 1 else 0), x1 - 5, REV_ICON_STEP):
				var d := float(xx - x0) + float(yy - y0) - band_x
				var k := clampf(1.0 - absf(d) / REV_BAND, 0.0, 1.0)
				var ty: String = types[(row + col) % types.size()]
				var r := Rect2(xx, yy, REV_ICON, REV_ICON)
				var col_t: Color = TYPE_COLORS.get(ty, tc)
				# al pasar la franja, el mismo color pero más intenso (más saturado y sin transparencia)
				var vivid := Color.from_hsv(col_t.h, minf(1.0, col_t.s * 1.5 + 0.25), minf(1.0, col_t.v * 1.1))
				var c := col_t.lerp(vivid, smoothstep(0.05, 0.5, k))
				c.a = 0.6 + 0.4 * k
				var tex := _type_symbol(ty, REV_ICON)
				if tex != null:
					draw_texture_rect(tex, r, false, c)
				else:
					_draw_emblem(r, ty, c)
				col += 1
			row += 1


## Brillo animado de las cartas holo: una franja de luz que cruza la imagen cada tanto y
## algunos destellos que titilan. Las holo ex y las secretas brillan con los colores del
## arcoíris. small = solo la franja (Banca y miniaturas).
const HOLO_PERIOD := 3.4       # segundos entre pasadas de la franja
func _draw_holo(r: Rect2, id: String, small: bool = false, cosmos: Dictionary = {}) -> void:
	var rar := _rarity_of(id)
	if not ("Holo" in rar or "Secret" in rar) or r.size.x < 6:
		return
	var rainbow := "EX" in rar or "Secret" in rar
	var t := Time.get_ticks_msec() / 1000.0
	var seed := hash(id)
	if not cosmos.is_empty():
		_draw_cosmos(r, cosmos, t, seed)
	var ph := fmod(t + (seed % 1000) / 1000.0 * HOLO_PERIOD, HOLO_PERIOD) / HOLO_PERIOD
	var inner := r.grow(-1)
	# Franja diagonal: cruza en el primer 40% del ciclo y después descansa
	var k := ph / 0.4
	if k < 1.0:
		var bw := maxf(3.0, inner.size.x * 0.22)
		var span := inner.size.x + inner.size.y * 0.6 + bw * 2
		var x0 := inner.position.x - bw - inner.size.y * 0.6 + span * k
		for y in int(inner.size.y):
			var cx := x0 + y * 0.6
			var a := maxf(cx - bw / 2.0, inner.position.x)
			var b := minf(cx + bw / 2.0, inner.end.x)
			if b <= a:
				continue
			var col := Color(1, 1, 0.92, 0.28)
			if rainbow:
				col = Color.from_hsv(fmod(t * 0.35 + y / inner.size.y * 0.5, 1.0), 0.7, 1.0, 0.4)
			draw_rect(Rect2(a, inner.position.y + y, b - a, 1), col)
			var a2 := maxf(cx - bw / 6.0, inner.position.x)
			var b2 := minf(cx + bw / 6.0, inner.end.x)
			if b2 > a2:
				draw_rect(Rect2(a2, inner.position.y + y, b2 - a2, 1), Color(1, 1, 1, 0.3))
	if small or not cosmos.is_empty():
		return
	# Destellos que titilan en lugares fijos de cada carta
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := clampi(int(inner.size.x / 7.0), 2, 7) + (2 if "Secret" in rar else 0)
	for i in n:
		var p := (inner.position + Vector2(rng.randf_range(2, inner.size.x - 3), rng.randf_range(2, inner.size.y - 3))).floor()
		var tw := pow(maxf(0.0, sin(t * rng.randf_range(1.6, 2.6) + rng.randf() * TAU)), 6.0)
		if tw < 0.05:
			continue
		var c := Color(1.0, 0.95, 0.65, tw)
		if rainbow:
			c = Color.from_hsv(fmod(t * 0.5 + i * 0.17, 1.0), 0.6, 1.0, tw)
		draw_rect(Rect2(p, Vector2(1, 1)), c)
		if tw > 0.45:
			var arm := Color(c, tw * 0.6)
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2(1, 1)), arm)
			draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), arm)
			draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 1)), arm)
			draw_rect(Rect2(p + Vector2(0, 1), Vector2(1, 1)), arm)


# --- Holo "cosmos": el brillo de las cartas holo de la época ---------------------------
# Sobre la imagen ya reducida se separa el fondo del Pokémon (los colores parecidos a los
# del borde y conectados con él) y se arman capas aparte: el fondo apagado y con un tinte
# frío, y varias capas de puntitos de colores que titilan. Al dibujar, esas capas van
# encima de la imagen original: casi siempre se ve el efecto, y cada tanto se desvanece
# unos instantes y se ve la ilustración limpia, como al mover una carta de verdad.

const COSMOS_ON := 5.5        # segundos con el efecto
const COSMOS_FADE := 0.6      # segundos de transición
const COSMOS_OFF := 1.4       # segundos viendo la imagen limpia
const COSMOS_FRAMES := 6      # capas de destellos que se alternan
const COSMOS_NEAR := 0.35     # qué tan parecido al borde tiene que ser un color para ser fondo
const COSMOS_STEP := 0.18     # diferencia máxima entre vecinos al recorrer el fondo
const COSMOS_DIM := 0.6       # cuánto se apaga el fondo (0..1)
var _cosmos := {}             # clave de textura -> {"base", "spark": [..]}


func _is_holo_card(id: String) -> bool:
	var rar := _rarity_of(id)
	return "Holo" in rar or "Secret" in rar


func _build_cosmos(key: String, id: String, img: Image) -> void:
	if not _is_holo_card(id) or img.get_width() < 12:
		return
	var w := img.get_width()
	var h := img.get_height()
	# 1) Colores del borde (el fondo casi siempre llega a los bordes de la ilustración)
	var border: Array[Color] = []
	for x in w:
		for y in [1, h - 2]:
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				border.append(c)
	for y in h:
		for x in [1, w - 2]:
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				border.append(c)
	if border.is_empty():
		return
	var step := maxi(1, border.size() / 48)
	var samples: Array[Color] = []
	for i in range(0, border.size(), step):
		samples.append(border[i])
	# 2) Qué tan "de fondo" es cada píxel: distancia al color de borde más parecido
	var near := PackedFloat32Array()
	near.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var best := 9.0
			for b in samples:
				var d := absf(c.r - b.r) + absf(c.g - b.g) + absf(c.b - b.b)
				if d < best:
					best = d
			near[y * w + x] = best
	# 3) Fondo = parecido al borde Y conectado con el borde (así no se come partes del Pokémon)
	var mask := PackedFloat32Array()
	mask.resize(w * h)
	var queue: Array[int] = []
	for y in h:
		for x in w:
			if (x <= 1 or y <= 1 or x >= w - 2 or y >= h - 2) and near[y * w + x] < COSMOS_NEAR:
				mask[y * w + x] = 1.0
				queue.append(y * w + x)
	var qi := 0
	while qi < queue.size():
		var i: int = queue[qi]
		qi += 1
		var x := i % w
		var y := i / w
		for dd in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = x + dd[0]
			var ny: int = y + dd[1]
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var j := ny * w + nx
			if mask[j] == 0.0 and near[j] < COSMOS_NEAR:
				# Crece solo entre vecinos parecidos: el contorno del Pokémon frena el fondo
				var a := img.get_pixel(x, y)
				var b := img.get_pixel(nx, ny)
				if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < COSMOS_STEP:
					mask[j] = 1.0
					queue.append(j)
	# Borde suave del recorte
	var soft := PackedFloat32Array()
	soft.resize(w * h)
	for y in h:
		for x in w:
			var acc := 0.0
			var n := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var xx := clampi(x + dx, 0, w - 1)
					var yy := clampi(y + dy, 0, h - 1)
					acc += mask[yy * w + xx]
					n += 1
			soft[y * w + x] = acc / n
	# 4) Capa del fondo apagado (oscuro y frío, como el papel metalizado)
	var base := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var tint := Color(0.16, 0.12, 0.30)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var m := soft[y * w + x]
			if c.a < 0.5 or m <= 0.0:
				continue
			var dark := c.darkened(0.5).lerp(tint, 0.35)
			dark.a = COSMOS_DIM * m
			base.set_pixel(x, y, dark)
	# 5) Capas de destellos: los "redondeles" del holo cosmos de la época. Puntitos, discos,
	#    anillos y algunos círculos grandes con halo, de colores de arcoíris. Cada capa es
	#    un momento distinto: los círculos cambian de color y se prenden y apagan a destiempo,
	#    como al inclinar la carta bajo la luz.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var orbs: Array = []      # [x, y, tono, radio, anillo, fase]
	var area := float(w * h)
	var kinds := [[area / 14.0, 0.0, false], [area / 34.0, 1.2, false], [area / 85.0, 2.4, true]]
	if w >= 30:
		kinds.append([area / 300.0, 3.6, true])
		kinds.append([area / 420.0, 3.0, false])
	for kd in kinds:
		for i in int(kd[0]):
			var x := rng.randi_range(0, w - 1)
			var y := rng.randi_range(0, h - 1)
			if soft[y * w + x] < 0.6:
				continue
			orbs.append([x, y, rng.randf(), float(kd[1]), bool(kd[2]), rng.randf()])
	var sparks: Array = []
	for f in COSMOS_FRAMES:
		var layer := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var fk := float(f) / COSMOS_FRAMES
		for o in orbs:
			var r: float = o[3]
			# Brillo según el momento: cada círculo tiene su fase
			var lit := maxf(0.0, cos((fk - float(o[5])) * TAU))
			if r <= 0.0:
				lit = 1.0 if lit > 0.7 else 0.0          # los puntitos titilan
			var bright := 0.25 + 0.75 * lit
			if bright < 0.3 and r <= 0.0:
				continue
			var hue := fmod(float(o[2]) + fk * 0.35, 1.0)
			_paint_orb(layer, soft, w, h, int(o[0]), int(o[1]), r, Color.from_hsv(hue, 0.6, 1.0, bright), bool(o[4]))
		sparks.append(ImageTexture.create_from_image(layer))
	_cosmos[key] = {"base": ImageTexture.create_from_image(base), "spark": sparks}


## Un redondel del holo en la capa: r = 0 un puntito; si no, un disco (centro casi blanco
## y borde de color) o un anillo. Solo sobre el fondo de la ilustración (soft).
func _paint_orb(layer: Image, soft: PackedFloat32Array, w: int, h: int, cx: int, cy: int, r: float, col: Color, ring: bool) -> void:
	var R := int(ceilf(r + 1.0))
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x := cx + dx
			var y := cy + dy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var m := soft[y * w + x]
			if m < 0.35:
				continue
			var d := sqrt(float(dx * dx + dy * dy))
			var a := 0.0
			var c := col
			if r <= 0.0:
				a = 1.0 if d < 0.5 else 0.0
			elif ring:
				a = clampf(1.0 - absf(d - r) * 1.1, 0.0, 1.0)       # el aro
				if d < r - 0.8:
					a = maxf(a, 0.18)                              # adentro, apenas teñido
				if r >= 3.0 and d > r:
					a = maxf(a, clampf(0.35 - (d - r) * 0.3, 0.0, 1.0))   # halo
			else:
				a = clampf(r + 0.5 - d, 0.0, 1.0)
				c = col.lerp(Color(1, 1, 1, col.a), clampf(1.0 - d / maxf(r, 0.1), 0.0, 1.0) * 0.6)
			a *= col.a * m
			if a <= 0.02:
				continue
			var prev := layer.get_pixel(x, y)
			if a > prev.a:
				layer.set_pixel(x, y, Color(c.r, c.g, c.b, a))


## Cuánto se ve el efecto ahora (0 = imagen limpia, 1 = holo completo).
func _cosmos_amount(t: float, seed: int) -> float:
	var period := COSMOS_ON + COSMOS_OFF + COSMOS_FADE * 2
	var p := fmod(t + (seed % 997) / 997.0 * period, period)
	if p < COSMOS_ON:
		return 1.0
	p -= COSMOS_ON
	if p < COSMOS_FADE:
		return 1.0 - p / COSMOS_FADE
	p -= COSMOS_FADE
	if p < COSMOS_OFF:
		return 0.0
	return (p - COSMOS_OFF) / COSMOS_FADE


func _draw_cosmos(r: Rect2, cosmos: Dictionary, t: float, seed: int) -> void:
	var k := _cosmos_amount(t, seed)
	if k <= 0.0:
		return
	k = k * k * (3.0 - 2.0 * k)
	draw_texture_rect(cosmos["base"], r, false, Color(1, 1, 1, k))
	var sp: Array = cosmos["spark"]
	var f := t * 3.0 + (seed % 7)
	var i := int(f) % sp.size()
	var frac := f - floorf(f)
	draw_texture_rect(sp[i], r, false, Color(1, 1, 1, k * (1.0 - frac)))
	draw_texture_rect(sp[(i + 1) % sp.size()], r, false, Color(1, 1, 1, k * frac))


func _remove_holo_sparkles(src: Image) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	# Achicar de a mitades (promedia bien y no deja aliasing) hasta cerca de HOLO_WORK
	while img.get_width() > HOLO_WORK * 2 and img.get_height() > HOLO_WORK * 2:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var w := img.get_width()
	var h := img.get_height()
	if w > HOLO_WORK:
		var sc := float(HOLO_WORK) / maxi(w, h)
		w = maxi(1, int(w * sc))
		h = maxi(1, int(h * sc))
		img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	# Mediana 5x5 por brillo: se queda con el píxel "del medio" de cada vecindad, así los
	# puntitos sueltos desaparecen y los bordes del dibujo se mantienen.
	var px: Array[Color] = []
	var lum := PackedInt32Array()
	px.resize(w * h)
	lum.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			px[y * w + x] = c
			lum[y * w + x] = int((c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 4095.0)
	var out := img.duplicate() as Image
	var keys := PackedInt64Array()
	keys.resize(25)
	for y in h:
		for x in w:
			var n := 0
			for dy in range(-2, 3):
				var row := clampi(y + dy, 0, h - 1) * w
				for dx in range(-2, 3):
					var i := row + clampi(x + dx, 0, w - 1)
					keys[n] = lum[i] * 1048576 + i      # brillo y, abajo, de qué píxel es
					n += 1
			keys.sort()
			var m: Color = px[keys[12] % 1048576]
			m.a = px[y * w + x].a
			out.set_pixel(x, y, m)
	return out


func _load_card_image_raw(id: String) -> Image:
	var name := CardDB.card_name(id)
	var species := name.replace("Team Aqua's ", "").replace("Team Magma's ", "").replace("Rocket's ", "").trim_suffix(" ex").trim_suffix(" ★")
	for dir in SPRITE_DIRS:
		for n in [id, name, species, species.to_lower()]:
			for ext in ["png", "jpg", "webp"]:
				var path := "%s/%s.%s" % [dir, n, ext]
				if ImgLoad.exists(path):
					var img := ImgLoad.load(path)
					if img != null and not img.is_empty():
						return img
	# Sin recorte cuadrado propio: se usa el arte en alta (mundo/propios/arte o el bajado);
	# _square_crop le saca el cuadrado para la mesa y _gba_art el recuadro de la ventana.
	if arte != null and not CardDB.get_card(id).get("supertype", "") == "Energy":
		var hd := arte.image(id)
		if hd != null:
			return hd
		arte.want(id)
	return null


## Si la imagen es el arte en alta (apaisado), saca el cuadrado: toda la altura, centrado a
## lo ancho. data/recorte_cuadrado.json puede correrlo o acercarlo carta por carta:
## {"ecard1-1": {"x": 0.4, "zoom": 1.2}}  (x: dónde cae el centro, de 0 = izquierda a 1 = derecha;
## y: lo mismo de arriba a abajo; zoom: más de 1 acerca). Los cuadrados propios no se tocan.
var _sq_adjust = null

## Dónde cae el cuadrado chico dentro del arte: Rect2i en píxeles del arte.
func _square_rect(id: String, w: int, h: int) -> Rect2i:
	if _sq_adjust == null:
		var raw := FileAccess.get_file_as_string("res://data/recorte_cuadrado.json")
		var parsed = JSON.parse_string(raw) if raw != "" else null
		_sq_adjust = parsed if parsed is Dictionary else {}
	var adj: Dictionary = _sq_adjust.get(id, {}) if _sq_adjust.get(id, {}) is Dictionary else {}
	var side := int(mini(w, h) / maxf(1.0, float(adj.get("zoom", 1.0))))
	var cx := float(adj.get("x", 0.5)) * w
	var cy := float(adj.get("y", 0.5)) * h
	var x0 := clampi(int(cx - side / 2.0), 0, w - side)
	var y0 := clampi(int(cy - side / 2.0), 0, h - side)
	return Rect2i(x0, y0, side, side)


## Galería, tecla S (solo desde el editor de Godot): ajustar el cuadrado chico de la carta.
## Flechas lo mueven, Q/W lo agrandan o achican, Z guarda en data/recorte_cuadrado.json,
## X cancela, R vuelve al centro.
func _sq_edit_keys(k: int, accept: bool, back: bool) -> bool:
	var id := gallery_id
	var cur: Dictionary = (_sq_adjust if _sq_adjust is Dictionary else {}).get(id, {}).duplicate()
	var step := 0.02
	match k:
		KEY_LEFT: cur["x"] = float(cur.get("x", 0.5)) - step
		KEY_RIGHT: cur["x"] = float(cur.get("x", 0.5)) + step
		KEY_UP: cur["y"] = float(cur.get("y", 0.5)) - step
		KEY_DOWN: cur["y"] = float(cur.get("y", 0.5)) + step
		KEY_W: cur["zoom"] = minf(4.0, float(cur.get("zoom", 1.0)) * 1.1)
		KEY_Q: cur["zoom"] = maxf(1.0, float(cur.get("zoom", 1.0)) / 1.1)
		KEY_R: cur = {}
		_:
			if accept:
				_sq_save()
				sq_edit = false
				snd.play("ok")
				return true
			if back:
				_sq_adjust = null         # se vuelve a leer el archivo: descarta lo no guardado
				_forget_square(id)
				sq_edit = false
				snd.play("back")
				return true
			return false
	# que el centro no quede donde el cuadrado se saldría del arte
	var img := arte.image(id)
	if img != null:
		var w := img.get_width()
		var h := img.get_height()
		var half := mini(w, h) / maxf(1.0, float(cur.get("zoom", 1.0))) / 2.0
		cur["x"] = snappedf(clampf(float(cur.get("x", 0.5)), half / w, 1.0 - half / w), 0.001)
		cur["y"] = snappedf(clampf(float(cur.get("y", 0.5)), half / h, 1.0 - half / h), 0.001)
		cur["zoom"] = snappedf(float(cur.get("zoom", 1.0)), 0.01)
	if _sq_adjust == null:
		_square_rect(id, 1, 1)
	if cur.is_empty():
		_sq_adjust.erase(id)
	else:
		_sq_adjust[id] = cur
	_forget_square(id)
	snd.play("cursor")
	return true


func _forget_square(id: String) -> void:
	for cache in [_sprites, _art]:
		for key in cache.keys():
			if str(key).begins_with(id + "|"):
				cache.erase(key)


func _sq_save() -> void:
	var out := {}
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/recorte_cuadrado.json"))
	if raw is Dictionary and raw.has("_ayuda"):
		out["_ayuda"] = raw["_ayuda"]
	var keys: Array = _sq_adjust.keys().filter(func(x): return x != "_ayuda")
	keys.sort()
	for key in keys:
		out[key] = _sq_adjust[key]
	var f := FileAccess.open("res://data/recorte_cuadrado.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out, "  ") + "\n")


func _draw_sq_edit(id: String, img: Image, r: Rect2) -> void:
	var f := r.size.x / img.get_width()
	var sq := _square_rect(id, img.get_width(), img.get_height())
	var box := Rect2(r.position + Vector2(sq.position) * f, Vector2(sq.size) * f)
	var shade := Color(0, 0, 0, 0.55)
	draw_rect(Rect2(r.position, Vector2(box.position.x - r.position.x, r.size.y)), shade)
	draw_rect(Rect2(Vector2(box.end.x, r.position.y), Vector2(r.end.x - box.end.x, r.size.y)), shade)
	draw_rect(Rect2(Vector2(box.position.x, r.position.y), Vector2(box.size.x, box.position.y - r.position.y)), shade)
	draw_rect(Rect2(Vector2(box.position.x, box.end.y), Vector2(box.size.x, r.end.y - box.end.y)), shade)
	draw_rect(box, Color("#f8d030"), false, 1.0)
	var y := 134.0
	var own := _has_own_square(id)
	_text(Vector2(8, y), "Arrows move · Q/W size · R reset", Color("#a0a8b8"))
	_text(Vector2(8, y + 12), "Z save · X cancel" + ("  (sprites/ has its own!)" if own else ""), Color("#e8c060") if own else Color("#a0a8b8"))
	var prev := _card_texture(id, 32)
	if prev != null:
		draw_texture_rect(prev, Rect2(W - 40, y - 4, 32, 32), false)


## ¿Hay un cuadrado propio en sprites/ para esta carta? (ese manda sobre el ajuste)
func _has_own_square(id: String) -> bool:
	for d in SPRITE_DIRS:
		for n in [id, CardDB.card_name(id)]:
			var pth := "%s/%s.png" % [d, n]
			if ImgLoad.exists(pth) or ResourceLoader.exists(pth):
				return true
	return false


func _square_crop(id: String, img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	if w <= h * 1.15 and h <= w * 1.15:
		return img
	return img.get_region(_square_rect(id, w, h))


## Imagen cuadrada de la carta (menús, fichas), reducida a paleta de GBA.
func _card_texture(id: String, size: int) -> Texture2D:
	var key := "%s|%d" % [id, size]
	if _sprites.has(key):
		return _sprites[key]
	var tex: Texture2D = null
	var img := _load_card_image(id)
	if img != null:
		var small := _gba_style(_square_crop(id, img), size)
		tex = ImageTexture.create_from_image(small)
		_build_cosmos("c|" + key, id, small)
	_sprites[key] = tex
	return tex


func _gba_style(src: Image, size: int = PORTRAIT) -> Image:
	var img := src.duplicate() as Image      # la imagen original queda guardada sin tocar
	img.convert(Image.FORMAT_RGBA8)
	var scale: float = float(size) / maxi(img.get_width(), img.get_height())
	var w := maxi(1, int(img.get_width() * scale))
	var h := maxi(1, int(img.get_height() * scale))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((size - w) / 2, (size - h) / 2))
	var rad := _corner_radius(size)
	for y in size:
		for x in size:
			var c := out.get_pixel(x, y)
			if c.a < 0.5 or _outside_round(x, y, size, rad):
				out.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				out.set_pixel(x, y, Color(snappedf(c.r, 1.0 / 31.0), snappedf(c.g, 1.0 / 31.0), snappedf(c.b, 1.0 / 31.0), 1.0))
	if size <= 64:
		_reduce_palette(out, 24)
	return out


## Emblemas originales por tipo (formas geométricas simples).
func _draw_emblem(r: Rect2, type: String, c: Color) -> void:
	var p := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	match type:
		"Fire":
			draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.0), p.call(0.78, 0.4), p.call(0.82, 0.7),
					p.call(0.62, 1.0), p.call(0.38, 1.0), p.call(0.18, 0.7), p.call(0.28, 0.42), p.call(0.42, 0.58)]), c)
		"Water":
			draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.0), p.call(0.78, 0.55), p.call(0.22, 0.55)]), c)
			draw_circle(p.call(0.5, 0.64), r.size.x * 0.3, c)
		"Grass":
			draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.95), p.call(0.25, 0.35), p.call(0.95, 0.05), p.call(0.7, 0.72)]), c)
			draw_line(p.call(0.12, 0.92), p.call(0.75, 0.3), C_TEXT.lightened(0.2))
		"Lightning":
			draw_colored_polygon(PackedVector2Array([p.call(0.6, 0.0), p.call(0.2, 0.55), p.call(0.47, 0.55),
					p.call(0.35, 1.0), p.call(0.82, 0.4), p.call(0.55, 0.4), p.call(0.72, 0.0)]), c)
		"Psychic":
			draw_circle(p.call(0.5, 0.5), r.size.x * 0.48, c)
			draw_circle(p.call(0.5, 0.5), r.size.x * 0.3, c.darkened(0.6))
			draw_circle(p.call(0.5, 0.5), r.size.x * 0.13, c)
		"Fighting":
			var pts := PackedVector2Array()
			for i in 16:
				var ang := TAU * i / 16.0
				var rad := 0.5 if i % 2 == 0 else 0.28
				pts.append(p.call(0.5 + cos(ang) * rad, 0.5 + sin(ang) * rad))
			draw_colored_polygon(pts, c)
		"Darkness":
			draw_circle(p.call(0.5, 0.5), r.size.x * 0.48, c)
			draw_circle(p.call(0.68, 0.38), r.size.x * 0.4, TYPE_COLORS["Darkness"].darkened(0.45))
		"Metal":
			var pts := PackedVector2Array()
			for i in 6:
				var ang := TAU * i / 6.0 + PI / 6.0
				pts.append(p.call(0.5 + cos(ang) * 0.5, 0.5 + sin(ang) * 0.5))
			draw_colored_polygon(pts, c)
			draw_circle(p.call(0.5, 0.5), r.size.x * 0.18, TYPE_COLORS["Metal"].darkened(0.45))
		_:
			var pts := PackedVector2Array()
			for i in 10:
				var ang := TAU * i / 10.0 - PI / 2.0
				var rad := 0.5 if i % 2 == 0 else 0.22
				pts.append(p.call(0.5 + cos(ang) * rad, 0.52 + sin(ang) * rad))
			draw_colored_polygon(pts, c)


func _draw_energy(pos: Vector2, m: PokemonInPlay) -> void:
	var x := 0
	var shown: Array = Energy.units(m)
	shown = shown.slice(0, maxi(0, shown.size() - _pending_units(m)))
	for u in shown:
		var t: String = u[0] if u.size() == 1 else "*"
		_draw_energy_icon(pos + Vector2(x + 4, 3.5), 8, t)
		x += 9
		if x > 63:
			break


func _draw_textbox() -> void:
	var box := Rect2(Vector2(0, BOX_Y), Vector2(W, H - BOX_Y))
	var x := 9.0
	var y := BOX_Y + 4.0
	var tw := box.size.x - 18
	# Menú principal de tu turno: "¿Qué hará...?" y las opciones en dos columnas
	if game.phase == "main" and game.actor() == human and menu_level == "root" and not menu_items.is_empty() \
			and trainer_anim.is_empty() and power_anim.is_empty() and anim.is_empty() and not _deck_showing() and not board_view \
			and not _prize_showing() and energy_anim.is_empty() and evo_anim.is_empty() and coin_anim.is_empty() \
			and ko_anim.is_empty() and check_anim.is_empty() and move_anim.is_empty():
		_draw_command_menu()
		return
	_frame(box)
	if game.phase == "over" and not _prize_showing():
		var msg := "YOU WON!" if game.winner == human else ("Draw" if game.winner == 2 else "You lost...")
		_text(Vector2(x, y), msg, C_TEXT)
		_text_scroll(Vector2(x, y + LINE), game.win_reason, C_TEXT, tw, "over")
		_text(Vector2(x, y + LINE * 2), "Z: back to title", C_DIM)
		return
	if board_view:
		_draw_board_details(box, x, y)
		return
	if not coin_anim.is_empty() and str(coin_anim.get("label", "")) != "":
		_text_scroll(Vector2(x, y), coin_anim["label"], C_TEXT, tw, "coinlbl")
		return
	if not power_anim.is_empty():
		var whose := "Your" if power_anim["p"] == human else "The opponent's"
		_text_scroll(Vector2(x, y), "%s %s uses %s!" % [whose, power_anim["mon"], power_anim["name"]], C_TEXT, tw, "power")
		_text(Vector2(x, y + LINE), "Poké-Power", C_DIM)
		return
	if not trainer_anim.is_empty():
		var who := "You play" if trainer_anim["p"] == human else "The opponent plays"
		_text_scroll(Vector2(x, y), "%s %s." % [who, CardDB.card_name(trainer_anim["id"])], C_TEXT, tw, "trainer")
		_text(Vector2(x, y + LINE), _card_kind(trainer_anim["id"]), C_DIM)
		return
	if _deck_showing():
		_draw_deck_text(x, y, tw)
		return
	if not check_anim.is_empty() and anim.is_empty() and coin_anim.is_empty() and evo_anim.is_empty():
		var ck: Dictionary = check_anim[0]
		var whose := "" if ck["p"] == human else "Foe "
		_text_scroll(Vector2(x, y), "%s%s is hurt by %s!" % [whose, ck["mon"].display_name(), "poison" if ck["kind"] == "poison" else "its burn"], C_TEXT, tw, "chk")
		_text(Vector2(x, y + LINE), "%d damage (%s)" % [ck["dmg"], "Poisoned" if ck["kind"] == "poison" else "Burned"], C_DIM)
		return
	if not ko_anim.is_empty() and anim.is_empty() and coin_anim.is_empty() and evo_anim.is_empty():
		_text_scroll(Vector2(x, y), "%s was" % ko_anim[0]["name"], C_TEXT, tw, "ko")
		_text(Vector2(x, y + LINE), "Knocked Out!", C_TEXT)
		return
	if _prize_showing() and prize_anim[0].get("choose", false):
		var pc: Dictionary = prize_anim[0]
		var head := "Choose one of your Prize cards" + (" (%d/%d)" % [pc["n"], pc["of"]] if pc["of"] > 1 else "") + "."
		_text(Vector2(x, y), head, C_TEXT)
		_text(Vector2(x, y + LINE), "They're face down: it could be any of them.", C_DIM)
		_text(Vector2(x, y + LINE * 2), "◀▶▲▼ move · Z take", C_DIM)
		return
	if _prize_showing():
		var pz: Dictionary = prize_anim[0]
		var mine: bool = pz["p"] == human
		var head := "You took a Prize card!" if mine else "The opponent took a Prize card."
		if pz["of"] > 1:
			head += " (%d/%d)" % [pz["n"], pz["of"]]
		_text_fit(Vector2(x, y), head, C_TEXT, tw)
		if mine and pz["t"] > 0.35:
			_text_scroll(Vector2(x, y + LINE), CardDB.card_name(pz["id"]) + " goes to your hand.", C_TEXT, tw, "prize")
		var left: int = pz["left"]
		var rest := ("%d left." if mine else "%d left.") % left if left > 0 else ("No Prize cards left!" if mine else "No Prize cards left!")
		_text(Vector2(x, y + LINE * 2), rest, C_DIM)
		return
	if not move_anim.is_empty() and anim.is_empty() and ko_anim.is_empty() and check_anim.is_empty() and coin_anim.is_empty() \
			and trainer_anim.is_empty() and evo_anim.is_empty():
		var lines: Array = move_anim[0]["text"]
		for i in lines.size():
			_text_scroll(Vector2(x, y + LINE * i), lines[i], C_TEXT, tw, "mv%d" % i)
		return
	if not energy_anim.is_empty() and anim.is_empty():
		var ea: Dictionary = energy_anim[0]
		_text_scroll(Vector2(x, y), "%s was attached to" % CardDB.card_name(ea["id"]), C_TEXT, tw, "en0")
		_text_scroll(Vector2(x, y + LINE), "%s!" % ea["mon"].display_name(), C_TEXT, tw, "en1")
		if ea.get("src", "") == "discard":
			_text(Vector2(x, y + LINE * 2), "(from the discard pile)", C_DIM)
		return
	if not evo_anim.is_empty():
		var e: Dictionary = evo_anim["list"][evo_anim["i"]]
		_text_scroll(Vector2(x, y), "%s is evolving!" % e["from"], C_TEXT, tw, "evo0")
		if evo_anim["t"] >= EVO_FLASH:
			_text_scroll(Vector2(x, y + LINE), "It evolved into %s!" % e["to"], C_TEXT, tw, "evo1")
		return
	if not anim.is_empty():
		_text_scroll(Vector2(x, y), anim["label"], C_TEXT, tw, "atk")
		if anim["applied"] and anim["dmg"] > 0:
			_text(Vector2(x, y + LINE), "%d damage!" % anim["dmg"], C_TEXT)
		return
	if (game.actor() != human and intro != "call") or menu_items.is_empty():
		var n := game.log_lines.size()
		var start := maxi(0, n - VISIBLE_LINES)
		for i in range(start, n):
			_text_fit(Vector2(x, y + (i - start) * LINE), game.log_lines[i].strip_edges(), C_TEXT, tw - 10)
		if game.actor() != human and game.phase != "over":
			var bob := 1.0 if int(Time.get_ticks_msec() / 300.0) % 2 == 0 else 0.0
			_text(Vector2(box.end.x - 15, box.end.y - 15 + bob), "▼", Color("#e03828"))
		return
	_draw_list_menu()


## Menú principal estilo GBA: a la izquierda la pregunta, a la derecha las opciones en dos columnas.
func _draw_command_menu() -> void:
	var left := Rect2(0, BOX_Y, 112, H - BOX_Y)
	var right := Rect2(110, BOX_Y, W - 110, H - BOX_Y)
	_frame(left)
	_frame(right)
	var y := BOX_Y + 4.0
	var act := game.players[human].active
	_text(Vector2(9, y), "What will", C_TEXT)
	_text_scroll(Vector2(9, y + LINE), (act.display_name() if act != null else "") + " do?", C_TEXT, 94, "cmd_name")
	_text(Vector2(9, y + LINE * 2), "B table · M hand", C_DIM)
	var n := menu_items.size()
	var rows := ceili(n / 2.0)
	var lh := LINE if rows <= 3 else 10
	for i in n:
		var ox := 124 + (i % 2) * 58
		var oy := y + (i / 2) * lh
		var label: String = menu_items[i]["label"]
		if label == "End turn":
			label = "End turn"
		_text(Vector2(ox, oy), label, C_TEXT)
		if i == cursor:
			_text(Vector2(ox - 8, oy), "▶", C_TEXT)


## Listas (ataques, cartas, elecciones): opciones a la izquierda y detalles a la derecha.
func _draw_list_menu() -> void:
	var img_id := _menu_card_id()
	var split := 136 if img_id != "" else 150
	var left := Rect2(0, BOX_Y, split + 2, H - BOX_Y)
	var right := Rect2(split, BOX_Y, W - split, H - BOX_Y)
	_frame(left)
	_frame(right)
	var y := BOX_Y + 4.0
	for i in range(scroll, mini(scroll + MENU_LINES, menu_items.size())):
		var ly := y + (i - scroll) * LINE
		if i == cursor:
			_text(Vector2(8, ly), "▶", C_TEXT)
			_text_scroll(Vector2(17, ly), menu_items[i]["label"], C_TEXT, left.size.x - 32, "menu")
		else:
			_text_fit(Vector2(17, ly), menu_items[i]["label"], C_TEXT, left.size.x - 32)
	if scroll > 0:
		_text(Vector2(left.end.x - 11, y - 2), "▲", C_DIM)
	if scroll + MENU_LINES < menu_items.size():
		_text(Vector2(left.end.x - 11, y + LINE * 2 + 2), "▼", C_DIM)
	# Detalle de la opción elegida
	var rx := right.position.x + 8
	var rw := right.size.x - 14
	var title := _menu_title()
	var act: Dictionary = menu_items[cursor].get("action", {}) if cursor < menu_items.size() else {}
	if act.get("t", "") == "attack" and game.current_player().active != null:
		var box := [[]]
		game.with_ctx(act.get("ctx", null), func(): box[0] = game.current_player().active.attacks())
		var atks: Array = box[0]
		if act["a"] < atks.size():
			var atk: Dictionary = atks[act["a"]]
			_text_scroll(Vector2(rx, y), title, C_DIM, rw, "mtitle")
			var cx := rx
			for t in atk.get("cost", []):
				_draw_energy_icon(Vector2(cx + 4.5, y + LINE + 5), 9, t)
				cx += 10
			if atk.get("cost", []).is_empty():
				_text(Vector2(rx, y + LINE), "No cost", C_TEXT)
			var dmg: String = atk.get("damage_text", "")
			_text(Vector2(rx, y + LINE * 2), "Damage", C_TEXT)
			_text(Vector2(rx + _text_w("Damage") + 4, y + LINE * 2), dmg if dmg != "" else "—", Color("#c03028"))
			return
	if img_id != "":
		# Imagen a la derecha (40x40, como en la ficha) y, al lado, la pregunta o el tipo de carta
		_draw_card_image(Rect2(right.end.x - 4 - MENU_IMG, BOX_Y + 4, MENU_IMG, MENU_IMG), img_id)
		var tw := right.size.x - 14 - MENU_IMG - 2
		var info := title if game.phase != "main" else _card_kind(img_id)
		var lines := _wrap(info, tw)
		for i in mini(3, lines.size()):
			if i == 2 and lines.size() > 3:
				_text_scroll(Vector2(rx, y + i * LINE), " ".join(lines.slice(2)), C_TEXT, tw, "mtitle")
			else:
				_text_fit(Vector2(rx, y + i * LINE), lines[i], C_TEXT, tw)
		return
	# Solo la pregunta (elecciones): en varios renglones
	var lines := _wrap(title, rw)
	for i in mini(3, lines.size()):
		_text(Vector2(rx, y + i * LINE), lines[i], C_TEXT if i < 2 or lines.size() <= 3 else C_DIM)


func _menu_card_id() -> String:
	if menu_items.is_empty() or cursor >= menu_items.size():
		return ""
	var a: Dictionary = menu_items[cursor].get("action", {})
	if a.get("t", "") in ["trainer", "energy", "bench", "evolve"]:
		var hand := game.players[game.actor()].hand
		if a["h"] < hand.size():
			return hand[a["h"]]
	if a.get("t", "") == "choose" and a.has("i"):
		var opts := game.choice_options()
		if a["i"] < opts.size() and str(opts[a["i"]].get("id", "")) != "" and not CardDB.get_card(opts[a["i"]]["id"]).is_empty():
			return opts[a["i"]]["id"]
	return ""


func _draw_info() -> void:
	var r := Rect2(Vector2(0, 0), Vector2(W, H))
	_page(r, Rect2(4, 3, W - 8, H - 19))
	info_more = false
	if not info_lines.is_empty() and info_lines[0] is Dictionary and info_lines[0].has("split"):
		_draw_split_info()
	elif _info_card_start() >= 0:
		_draw_info_card()
	else:
		_info_flow(info_lines.slice(info_offset), 6.0, H - 17.0, 10.0, W - 20.0, null)
	# Ayuda abajo: solo lo que se puede hacer, y flechitas si hay más texto
	var hint: Array = []
	if info_nav.size() > 1:
		hint.append("◀▶ %d/%d" % [info_nav_i + 1, info_nav.size()])
	if (info_more or info_offset > 0) and _info_card_start() <= 0:
		hint.append("▲▼ read")      # con rótulo abajo no entra: la flechita ▼/▲ ya lo indica
	if _info_img() != "":
		hint.append("C art")
	if not info_stack.is_empty():
		hint.append("Z back")
	elif not _info_attached().is_empty():
		hint.append("Z attached")
		hint.append("X close")
	else:
		hint.append("Z close")
	var ht := " · ".join(hint)
	_page_hint(Vector2(W - 9 - _text_w(ht), H - 14), ht)
	# De quién es la carta (TU ACTIVO, RIVAL · BANCA 2, ESTADIO...): abajo a la izquierda
	var ax := 10.0
	var hi := _info_card_start()
	if hi > 0:
		var section: Dictionary = info_lines[hi - 1]
		var st: String = section["section"]
		var sr := Rect2(8, H - 15, _text_w(st) + 6, TEXT_H + 1)
		draw_rect(sr.grow(1), C_INK)
		draw_rect(sr, section.get("bg", C_MINE_BG))
		_text(sr.position + Vector2(3, 0), st, C_TEXT)
		ax = sr.end.x + 4
	if info_more and int(Time.get_ticks_msec() / 350.0) % 2 == 0:
		_text(Vector2(ax, H - 14), "▼", Color("#e03828"))
	elif info_offset > 0:
		_page_hint(Vector2(ax, H - 14), "▲")


## Si info_lines es la ficha de UNA carta (con o sin rótulo de sección delante), el índice de
## su cabecera; si no (texto suelto o varias cartas), -1.
func _info_card_start() -> int:
	var hi := _info_find("head")
	if hi < 0:
		return -1
	for i in hi:
		if not (info_lines[i] is Dictionary and info_lines[i].has("section")):
			return -1
	for i in range(hi + 1, info_lines.size()):
		if info_lines[i] is Dictionary and info_lines[i].has("head"):
			return -1
	return hi


## Índice del primer renglón marcado con key ("head", "body", "foot"), o -1.
func _info_find(key: String) -> int:
	for i in info_lines.size():
		if info_lines[i] is Dictionary and info_lines[i].has(key):
			return i
	return -1


## Dibuja renglones de la ficha de arriba hacia abajo desde y, hasta bottom, en la columna
## que empieza en x0 y mide width. Si no entran todos, deja info_more en true.
func _info_flow(lines: Array, y: float, bottom: float, x0: float, width: float, bg: Variant) -> void:
	var styled := _ui_tex("fondo") != null
	var images: Array = []        # [Rect2, id o textura] para dibujar al final
	var narrow_until := -1.0      # el texto deja lugar a la imagen hasta esta altura
	var side_w := INFO_IMG        # ancho de esa imagen
	if styled:
		bg = null                 # sobre la caja crema, las secciones se marcan con pestañas
	var drawn := 0
	for line in lines:
		if y > bottom - 9:
			info_more = true
			break
		drawn += 1
		if line is Dictionary:
			if line.has("section"):
				bg = line["bg"]
				y += 2
				if styled:            # pestaña verde, y el texto de la sección sobre la caja crema
					bg = null
					_tab(Vector2(6, y), minf(W - 12, _text_w(line["section"]) + 30), line["section"], TEXT_H + 2)
				else:
					draw_rect(Rect2(5, y, W - 10, TEXT_H + 3), Color(bg).darkened(0.12))
					_text(Vector2(x0, y + 1), line["section"], C_TEXT)
				y += TEXT_H + 3
			if line.has("gap"):      # espacio entre ataques, para que se lean mejor
				if bg != null:
					draw_rect(Rect2(5, y, W - 10, line["gap"]), bg)
				y += line["gap"]
				continue
			if line.get("img", "") != "":
				var bt := _art_banner(line["img"])
				if bt != null:            # el arte completo, apaisado, arriba a la derecha
					images.append([Rect2(W - 10 - BANNER_W, y + 2, BANNER_W, BANNER_H), bt])
					side_w = BANNER_W
					narrow_until = y + BANNER_H + 4
				else:
					images.append([Rect2(W - 52, y + 2, INFO_IMG, INFO_IMG), line["img"]])
					side_w = INFO_IMG
					narrow_until = y + INFO_IMG + 4
			if line.has("sub"):
				if y + TEXT_H + 6 > bottom:
					info_more = true
					break
				y += 3
				if bg != null:
					draw_rect(Rect2(5, y - 3, W - 10, TEXT_H + 6), bg)
				draw_line(Vector2(x0, y + 4), Vector2(W - 12, y + 4), C_PANEL_DARK)
				var lw := _text_w(line["sub"]) + 6
				draw_rect(Rect2(14, y - 1, lw, TEXT_H + 1), bg if bg != null else C_PANEL)
				_text(Vector2(17, y - 1), line["sub"], C_DIM)
				y += TEXT_H + 3
				narrow_until = -1.0
				continue
			if line.has("text"):
				var tw := width - (side_w + 8 if y < narrow_until else 0)
				if y < narrow_until and _wrap(_type_marks(line["text"]), tw).size() > 2:
					y = narrow_until      # un párrafo largo empieza debajo de la imagen, a lo ancho
					tw = width
				var th := _wrap(_type_marks(line["text"]), tw).size() * LINE_S + 1
				if y + th > bottom:
					info_more = true
					break
				if bg != null:
					draw_rect(Rect2(5, y, W - 10, th), bg)
				_text_wrap(Vector2(x0, y), _type_marks(line["text"]), tw, line.get("color", C_TEXT))
				y += th
				continue
			if line.has("row"):
				var rh := TEXT_H + 3
				if y + rh > bottom:
					info_more = true
					break
				if bg != null:
					draw_rect(Rect2(5, y, W - 10, rh), bg)
				_draw_icon_row(Vector2(x0, y), line["row"])
				y += rh
			continue
		var s: String = _type_marks(line)
		var lw := width - (side_w + 8 if y < narrow_until else 0)
		if y < narrow_until and _wrap(s, lw).size() > 2:
			y = narrow_until
			lw = width
		var h := _wrap(s, lw).size() * LINE_S + 1
		if y + h > bottom:
			info_more = true
			break
		if bg != null:
			draw_rect(Rect2(5, y, W - 10, h), bg)
		_text_wrap(Vector2(x0, y), s, lw, C_TEXT)
		y += h
	for im in images:
		var rect: Rect2 = im[0]
		if rect.end.y < bottom:
			if im[1] is Texture2D:
				draw_texture(im[1], rect.position)
			else:
				_draw_card_image(rect, im[1])


## La ficha de una carta en tres paneles: arriba la imagen con los datos básicos, en el medio
## lo que hace (habilidades, ataques: es lo único que se desplaza con ▲▼) y abajo debilidad,
## resistencia y retirada.
func _draw_info_card() -> void:
	var hi := _info_card_start()
	var bi := _info_find("body")
	var fi := _info_find("foot")
	if bi < 0:
		bi = info_lines.size()
	var id: String = info_lines[hi]["img"]
	# --- Cabecera
	var head := Rect2(6, 4, W - 12, BANNER_H + 6)
	_cream_box(head)
	var art := _art_banner(id)
	var aw := BANNER_W if art != null else INFO_IMG
	var ah := BANNER_H if art != null else INFO_IMG
	var ar := Rect2(head.end.x - 3 - aw, head.position.y + 3, aw, ah)
	if art != null:
		draw_texture(art, ar.position)
	else:
		_draw_card_image(ar, id)
	var y := head.position.y + 2.0
	var tw := ar.position.x - head.position.x - 10.0
	for line in info_lines.slice(hi + 1, bi):
		if line is Dictionary and line.has("row"):
			_draw_icon_row(Vector2(head.position.x + 5, y), line["row"])
			y += TEXT_H + 2
		elif line is Dictionary and line.has("text"):
			_text_fit(Vector2(head.position.x + 5, y), str(line["text"]), line.get("color", C_TEXT), tw)
			y += LINE_S + 1
		elif line is String:
			_text_fit(Vector2(head.position.x + 5, y), line, C_TEXT, tw)
			y += LINE_S + 1
	# --- Pie
	var foot_h := 0.0
	if fi >= 0:
		foot_h = TEXT_H + 7
		var foot := Rect2(6, H - 17 - foot_h - 1, W - 12, foot_h)
		_tab(foot.position, foot.size.x, "", foot_h)
		for line in info_lines.slice(fi + 1):
			if line is Dictionary and line.has("row"):
				_draw_icon_row(foot.position + Vector2(8, 3), _light_row(line["row"]))
	# --- Cuerpo (se desplaza)
	var body_top := head.end.y + 2
	var body_bottom := H - 17 - foot_h - 2
	var body := Rect2(6, body_top, W - 12, body_bottom - body_top)
	draw_rect(body, Color("#fbf8ec"))
	draw_rect(Rect2(body.position.x, body.position.y, body.size.x, 1), C_PAGE_LINE)
	draw_rect(Rect2(body.position.x, body.end.y - 1, body.size.x, 1), C_PAGE_LINE)
	var lines := info_lines.slice(bi + 1, fi if fi >= 0 else info_lines.size())
	_info_flow(lines.slice(info_offset), body_top + 3, body_bottom, 11.0, W - 22.0, null)


# ---------------------------------------------------------------------------
# Vista partida (C en la mesa): tus Activos a la izquierda, los del rival a la derecha
# y el Estadio abajo. En dobles, los dos Activos de cada lado, resumidos.
# ---------------------------------------------------------------------------
const SPLIT_W := 113.0

func _draw_split_info() -> void:
	var stadium_h := TEXT_H + 3.0 if game.stadium != "" else 0.0
	var bottom := H - 18.0 - (stadium_h + 2.0 if stadium_h > 0 else 0.0)
	for side in 2:
		var pl: int = human if side == 0 else 1 - human
		var x := 6.0 + side * (SPLIT_W + 2.0)
		var mons: Array = game.players[pl].actives()
		var label := ("YOUR " if side == 0 else "FOE ") + ("ACTIVES" if mons.size() > 1 else "ACTIVE")
		var lr := Rect2(x, 4, SPLIT_W, TEXT_H + 1)
		draw_rect(lr, C_MINE_BG if side == 0 else C_OPP_BG)
		draw_rect(Rect2(lr.position.x, lr.end.y, lr.size.x, 1), C_PAGE_LINE)
		_text(Vector2(x + 4, 4), label, C_TEXT)
		if mons.is_empty():
			_text(Vector2(x + 4, 20), "(no Active Pokémon)", C_DIM)
		elif mons.size() == 1:
			_split_full(game.players[pl], mons[0], x, 17.0, bottom)
		else:
			var hh := (bottom - 17.0 - 2.0) / 2.0
			for k in 2:
				_split_head(game.players[pl], mons[k], Rect2(x, 17.0 + k * (hh + 2.0), SPLIT_W, hh), true)
	if stadium_h > 0:
		var sr := Rect2(6, H - 18.0 - stadium_h, W - 12, stadium_h)
		draw_rect(sr, C_STADIUM_BG)
		draw_rect(Rect2(sr.position.x, sr.position.y, sr.size.x, 1), C_PAGE_LINE)
		_text_fit(Vector2(sr.position.x + 4, sr.position.y + 1), "STADIUM · " + CardDB.card_name(game.stadium), C_TEXT, sr.size.x - 8)


## Cabecera de un lado: retrato, nombre, PS (barra y número), energías y estado.
## compact: para dobles (sin ataques); el recuadro es todo el espacio de ese Pokémon.
func _split_head(pl: PlayerState, m: PokemonInPlay, r: Rect2, compact: bool) -> void:
	_cream_box(r)
	var id := m.top()
	var side := 30 if compact else 34
	var ar := Rect2(r.position + Vector2(3, 3), Vector2(side, side))
	draw_rect(ar.grow(1), C_INK)
	var tex := _art_texture(id, side, side)
	if tex != null:
		draw_texture(tex, ar.position)
	else:
		_draw_card_image(ar, id)
	var tx := ar.end.x + 4
	var tw := r.end.x - tx - 3
	_text_fit(Vector2(tx, r.position.y + 1), CardDB.card_name(id), C_TEXT, tw)
	_draw_hp_bar(Vector2(tx, r.position.y + 13), int(tw), m)
	var hp := "%d/%d" % [m.hp_left(), m.max_hp()]
	_draw_tiny(Vector2(r.end.x - 4 - hp.length() * 4, r.position.y + 22), hp, C_TEXT)
	# Energías unidas (íconos chicos) y estado
	var ex := tx
	var ey := r.position.y + 22
	for e in m.energy:
		var u: Array = Energy.units_of_card(e, m)
		var t: String = u[0][0] if not u.is_empty() else "Colorless"
		if not t in TYPE_COLORS:
			t = "Colorless"
		if ex + 7 > r.end.x - 4 - hp.length() * 4 - 2:
			break
		_draw_energy_icon(Vector2(ex + 3, ey + 3), 7, t)
		ex += 7
	var cond := m.conditions_text()
	if cond != "":
		var cy := ar.end.y - TEXT_H + 1 if not compact else ey + 7
		_text_fit(Vector2(tx, maxf(cy, ey + 6)), cond, Color("#c03030"), tw)
	if compact:
		# En dobles, debajo del retrato: herramienta/MT si hay
		var extra: Array = []
		if m.tool != "":
			extra.append(CardDB.card_name(m.tool))
		if m.tm != "":
			extra.append(CardDB.card_name(m.tm))
		var ty := maxf(ar.end.y + 2, r.position.y + 22 + 7 + (TEXT_H if cond != "" else 0))
		if not extra.is_empty() and ty + TEXT_H <= r.end.y:
			_text_fit(Vector2(r.position.x + 4, ty), " · ".join(extra), C_DIM, r.size.x - 8)
			ty += TEXT_H
		# Efectos (con su ícono y qué hacen), los que entren
		for rs in _effect_reasons(pl, m, -1):
			if ty + TEXT_H > r.end.y:
				break
			var no_icon := str(rs[0]).begins_with("est_poder")
			if not no_icon:
				_reason_icon(rs[0], Vector2(r.position.x + 9, ty + 4.5))
			var tx0 := r.position.x + (4 if no_icon else 16)
			_text_fit(Vector2(tx0, ty), _short_reason(rs[1], r.end.x - 4 - tx0), REASON_COL.get(rs[0], C_TEXT), r.end.x - 4 - tx0)
			ty += TEXT_H
	# El ícono animado sobre el retrato, como en la mesa
	_draw_status_fx(pl, m, ar)


## Un lado con un solo Activo: cabecera, ataques y Poké-Powers/Bodies (sin el texto largo)
## y el pie con debilidad, resistencia y retirada.
func _split_full(pl: PlayerState, m: PokemonInPlay, x: float, top: float, bottom: float) -> void:
	var c := CardDB.get_card(m.top())
	var head := Rect2(x, top, SPLIT_W, 40)
	_split_head(pl, m, head, false)
	var foot_h := TEXT_H + 4.0
	var foot := Rect2(x, bottom - foot_h, SPLIT_W, foot_h)
	var body := Rect2(x, head.end.y + 1, SPLIT_W, foot.position.y - head.end.y - 2)
	draw_rect(body, Color("#fbf8ec"))
	var y := body.position.y + 2
	var rows: Array = []
	# Primero los efectos que tiene encima (ícono + qué le pasa), después habilidades y ataques
	for rs in _effect_reasons(pl, m, -1):
		if rs[0] == "est_poder":          # "se puede usar" ya se ve en la pestaña y en la lista
			continue
		if str(rs[0]).begins_with("est_poder"):
			rows.append([[], rs[1], "", REASON_COL.get(rs[0], C_TEXT)])      # sin ícono
		else:
			rows.append([["fx", rs[0]], rs[1], "", REASON_COL.get(rs[0], C_TEXT)])
	for ab in c.get("abilities", []):
		var col: Color = C_POWER if ab["kind"] == "Poké-Power" else C_BODY
		rows.append([[], ab["name"], "", col])
	for atk in c.get("attacks", []):
		rows.append([atk.get("cost", []), atk["name"], str(atk.get("damage_text", "")), C_TEXT])
	if m.tool != "" or m.tm != "":
		var ex: Array = []
		if m.tool != "":
			ex.append(CardDB.card_name(m.tool))
		if m.tm != "":
			ex.append(CardDB.card_name(m.tm))
		rows.append([[], " · ".join(ex), "", C_DIM])
	for row in rows:
		if y + TEXT_H > body.end.y:
			break
		var rx := body.position.x + 3
		var cost: Array = row[0]
		if not cost.is_empty() and str(cost[0]) == "fx":
			_reason_icon(cost[1], Vector2(rx + 5, y + 4.5))
			_text_fit(Vector2(rx + 12, y), _short_reason(row[1], body.end.x - rx - 15), row[3], body.end.x - rx - 15)
			y += LINE_S
			continue
		for t in cost:
			_draw_energy_icon(Vector2(rx + 3, y + 4.5), 7, t)
			rx += 7
		if not cost.is_empty():
			rx += 2
		var dmg: String = row[2]
		var dw := _text_w(dmg) if dmg != "" else 0.0
		if row[3] == C_POWER or row[3] == C_BODY:
			_text_bold(Vector2(rx, y), row[1], row[3])
		else:
			_text_fit(Vector2(rx, y), row[1], row[3], body.end.x - rx - dw - 6)
		if dmg != "":
			_text(Vector2(body.end.x - 3 - dw, y), dmg, C_TEXT)
		y += LINE_S
	_tab(foot.position, foot.size.x, "", foot_h)
	var wr: Array = []
	for t in c.get("weaknesses", []):
		wr.append(["icon", t])
	var fx := foot.position.x + 7
	var fy := foot.position.y + 2
	_text_bold(Vector2(fx, fy), "W", Color.WHITE)
	fx += 8
	for t in c.get("weaknesses", []):
		_draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, t)
		fx += 9
	if c.get("weaknesses", []).is_empty():
		_text_bold(Vector2(fx, fy), "-", Color.WHITE); fx += 6
	fx += 5
	_text_bold(Vector2(fx, fy), "R", Color.WHITE)
	fx += 8
	for t in c.get("resistances", []):
		_draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, t)
		fx += 9
	if c.get("resistances", []).is_empty():
		_text_bold(Vector2(fx, fy), "-", Color.WHITE); fx += 6
	fx += 5
	_text_bold(Vector2(fx, fy), "Ret", Color.WHITE)
	fx += 18
	var rc := int(c.get("retreat", 0))
	for i in rc:
		_draw_energy_icon(Vector2(fx + 4, fy + 4.5), 8, "Colorless")
		fx += 9
	if rc == 0:
		_text_bold(Vector2(fx, fy), "0", Color.WHITE)


## El renglón de debilidad/resistencia/retirada en letra clara, para el pie verde.
func _light_row(row: Array) -> Array:
	var out: Array = []
	for part in row:
		if part[0] == "text":
			out.append(["bold", part[1], Color.WHITE])
		else:
			out.append(part)
	return out


# ===========================================================================
# Registro con turnos en franjas de colores
# ===========================================================================

## Franja (0 o 1) de cada línea del registro, según el número de turno.
func _log_bands() -> Array:
	var bands: Array = []
	bands.resize(game.log_lines.size())
	var current := -1
	var rx := RegEx.new()
	rx.compile("^— Turn (\\d+)")
	for i in game.log_lines.size():
		var m := rx.search(game.log_lines[i])
		if m != null:
			current = int(m.get_string(1)) % 2
		bands[i] = current
	# Líneas antes del primer "Turno" del registro (preparación): la franja opuesta.
	var first := -1
	for b in bands:
		if b != -1:
			first = b
			break
	for i in bands.size():
		if bands[i] == -1:
			bands[i] = 1 - first if first != -1 else 0
		else:
			break
	return bands


func _draw_log_lines(x: float, y: float, width: float, start: int, end: int, line_h: float) -> void:
	var bands := _log_bands()
	for i in range(start, end):
		var ly := y + (i - start) * line_h
		var bc: Color = C_BAND[bands[i]]
		if show_log and _ui_tex("fondo") != null and line_h == LINE_S:    # sobre la caja crema
			bc = C_PAGE_BOX if bands[i] == 0 else Color("#f0e0b0")
		draw_rect(Rect2(x - 3, ly - 1, width + 6, line_h), bc)
		_text_fit(Vector2(x, ly), game.log_lines[i].strip_edges(), C_TEXT, width)


const LOG_LINES_FULL := 11

func _draw_full_log() -> void:
	var styled := _ui_tex("fondo") != null
	_page(Rect2(Vector2.ZERO, Vector2(W, H)), Rect2(4, 14, W - 8, H - 30))
	var n := game.log_lines.size()
	var end := n - log_scroll
	var start := maxi(0, end - LOG_LINES_FULL)
	if styled:
		_tab(Vector2(6, 3), 70, "LOG")
	else:
		_text(Vector2(10, 5), "LOG", C_DIM)
	_draw_log_lines(10, 17, W - 20, start, end, LINE_S)
	_page_hint(Vector2(W - 122, H - 14), "▲▼ scroll · Tab close")


# ===========================================================================
# Preparación: manos de los mulligans y tu mano para poner el Activo y la Banca
# ===========================================================================

## La pantalla de la mano de la preparación se puede usar ahora (te toca y ya robaste las
## cartas extra del mulligan del rival, si las había).
func _setup_hand_ok() -> bool:
	return mode == "duel" and intro == "" and game.phase == "setup" and game.actor() == human \
			and game.players[human].mull_bonus == 0


## Abre sola la pantalla que corresponda (se llama cuando no hay animaciones).
func _check_setup_screen() -> bool:
	if game.phase != "setup" or intro != "":
		if setup_screen != "":
			setup_screen = ""
		return false
	if not _mull_shown:
		_mull_shown = true
		if not _mull_pages().is_empty():
			setup_screen = "mull"
			mull_page = 0
			setup_cursor = 0
			_rebuild_menu()
			return true
	if setup_screen == "mull":
		return true             # la IA espera a que termines de mirar
	if setup_screen == "" and not _setup_closed and _setup_hand_ok():
		setup_screen = "hand"
		setup_cursor = 0
		return true
	if setup_screen == "hand" and not _setup_hand_ok():
		setup_screen = ""
	return false


## Una página por mulligan: primero los tuyos, después los del rival.
func _mull_pages() -> Array:
	var pages: Array = []
	for pi in [human, 1 - human]:
		var hands: Array = game.players[pi].mull_hands
		for i in hands.size():
			pages.append({"p": pi, "i": i, "n": hands.size(), "cards": hands[i]})
	return pages


## Filas de la pantalla de la mano: tus cartas y, cuando ya hay Activo, "Done".
func _setup_rows() -> Array:
	var rows: Array = []
	var me := game.players[human]
	for h in me.hand.size():
		var id: String = me.hand[h]
		rows.append({"id": id, "dim": not CardDB.is_basic_pokemon(id)})
	if me.active != null:
		rows.append({"done": true, "label": "Done"})
	return rows


## Lo que hace Z sobre un Básico: Activo si todavía no hay, si no a la Banca.
func _setup_action_for(id: String) -> Dictionary:
	var me := game.players[human]
	var best := {}
	for a in game.legal_actions():
		if not a.has("h") or me.hand[a["h"]] != id:
			continue
		var order := ["setup_active", "setup_active2", "setup_bench"]
		if best.is_empty() or order.find(a["t"]) < order.find(best["t"]):
			best = a
	return best


func _setup_input(k: int, accept: bool, back: bool, echo: bool) -> void:
	var mull := setup_screen == "mull"
	var pages := _mull_pages()
	var rows: Array = []
	if mull:
		for id in pages[mull_page]["cards"]:
			rows.append({"id": id})
	else:
		rows = _setup_rows()
	if k == KEY_LEFT or k == KEY_RIGHT:
		snd.play("move")
		setup_cursor = clampi(setup_cursor + (1 if k == KEY_RIGHT else -1), 0, maxi(0, rows.size() - 1))
		return
	if mull and (k == KEY_UP or k == KEY_DOWN) and not echo:
		var np := clampi(mull_page + (1 if k == KEY_DOWN else -1), 0, pages.size() - 1)
		if np != mull_page:
			snd.play("move")
			mull_page = np
			setup_cursor = 0
		return
	if echo:
		return
	if back:
		snd.play("back")
		setup_screen = ""
		if mull:
			setup_cursor = 0          # sigue la preparación
		else:
			_setup_closed = true      # al menú de siempre (M la vuelve a abrir)
		_rebuild_menu()
		return
	if rows.is_empty():
		return
	var row: Dictionary = rows[clampi(setup_cursor, 0, rows.size() - 1)]
	var info := k == KEY_C
	if accept and not mull and not info:
		if row.get("done", false):
			snd.play("ok")
			setup_screen = ""
			_do({"t": "setup_done"})
			return
		var a := _setup_action_for(row["id"])
		if not a.is_empty():
			snd.play("ok")
			_do(a)
			setup_cursor = clampi(setup_cursor, 0, maxi(0, _setup_rows().size() - 1))
			return
		if not CardDB.is_basic_pokemon(row["id"]):
			info = true               # Z sobre algo que no se juega ahora: muestra la carta
		else:
			snd.play("back")          # la Banca ya está llena
			return
	if (info or accept) and row.has("id"):
		snd.play("ok")
		var entries: Array = []
		for r in rows:
			if r.has("id"):
				var rid: String = r["id"]
				entries.append(func(): return _card_lines(rid, null))
		_open_info(entries, setup_cursor, func(j: int): setup_cursor = j)


var _ok_tex: Texture2D
const SETUP_TILES := 8      # cartas a la vista en la ventana de la preparación

## Ventana chica abajo (donde va el texto), como la de los sobres: tu mano en una fila de
## cartitas, y arriba la mesa a la vista con el lugar donde va a caer el Básico titilando.
func _draw_setup_screen() -> void:
	var mull := setup_screen == "mull"
	var me := game.players[human]
	var rows: Array = []
	var tab := ""
	var mine := true
	if mull:
		var pages := _mull_pages()
		if pages.is_empty():
			return
		mull_page = clampi(mull_page, 0, pages.size() - 1)
		var pg: Dictionary = pages[mull_page]
		mine = pg["p"] == human
		for id in pg["cards"]:
			rows.append({"id": id})
		tab = ("Your mulligan" if mine else "Opponent's mulligan") + (" %d/%d ▲▼" % [mull_page + 1, pages.size()] if pages.size() > 1 else "")
	else:
		rows = _setup_rows()
		tab = "Your hand · Bench %d/%d" % [me.bench.size(), game.rules.bench_size]
	setup_cursor = clampi(setup_cursor, 0, maxi(0, rows.size() - 1))
	var sel: Dictionary = rows[setup_cursor] if not rows.is_empty() else {}
	var on := int(Time.get_ticks_msec() / 300.0) % 2 == 0
	# En la mesa: dónde va a caer el Básico marcado
	var hint := ""
	if not mull:
		if sel.get("done", false):
			hint = "Z: done"
		elif sel.has("id"):
			var a := _setup_action_for(sel["id"])
			if not a.is_empty():
				var dest := _card_rect(human) if a["t"] != "setup_bench" else _bench_rect(human, me.bench.size())
				_outline(dest.grow(1), Color("#f85838") if on else Color("#f8d030"))
				_outline(dest.grow(2), Color(0, 0, 0, 0.4))
				hint = "Z: Active" if a["t"] != "setup_bench" else "Z: Bench"
			elif CardDB.is_basic_pokemon(sel["id"]):
				hint = "Bench full"
			else:
				hint = "C: info"
	else:
		hint = "X: OK"
	# Pestaña con el título, sobre la ventana
	var tw := _text_w(tab) + 14
	var tr := Rect2(W - 4 - tw, BOX_Y - 11, tw, 12)
	draw_rect(tr, C_INK)
	draw_rect(tr.grow(-1), C_MINE_BG.darkened(0.1) if mine else C_OPP_BG.darkened(0.1))
	_text(Vector2(tr.position.x + 7, tr.position.y + 1), tab, C_TEXT)
	var box := Rect2(0, BOX_Y, W, H - BOX_Y)
	_frame(box)
	# Fila de cartitas
	var top := clampi(setup_cursor - SETUP_TILES + 1, 0, maxi(0, rows.size() - SETUP_TILES))
	for i in range(top, mini(top + SETUP_TILES, rows.size())):
		var r: Dictionary = rows[i]
		var cell := Rect2(7 + (i - top) * 28, BOX_Y + 5, 26, 26)
		if r.get("done", false):
			draw_rect(cell, C_INK)
			if _ok_tex == null:
				var oi := ImgLoad.load("res://ui/boton_ok.png")
				if oi != null:
					_ok_tex = ImageTexture.create_from_image(oi)
			if _ok_tex != null:
				draw_texture(_ok_tex, cell.position + Vector2(1, 1))     # "OK" con las letras del título
			else:
				draw_rect(cell.grow(-1), Color("#f8d8a8"))
				_text(Vector2(cell.position.x + 6, cell.position.y + 8), "OK", C_TEXT)
		else:
			var id: String = r["id"]
			draw_rect(cell, C_INK)
			draw_rect(cell.grow(-1), Color("#f8f8e8"))
			_draw_card_image(Rect2(cell.position + Vector2(2, 2), Vector2(22, 22)), id)
			if not mull and not CardDB.is_basic_pokemon(id):
				draw_rect(cell.grow(-1), Color(0.1, 0.1, 0.15, 0.5))     # no se puede poner ahora
		if i == setup_cursor:
			_outline(cell.grow(1), Color("#f85838") if on else Color("#f8d030"))
			_outline(cell.grow(2), Color(0, 0, 0, 0.4))
	if top > 0:
		_text(Vector2(1, BOX_Y + 12), "◀", C_DIM)
	if top + SETUP_TILES < rows.size():
		_text(Vector2(W - 7, BOX_Y + 12), "▶", C_DIM)
	# Debajo: la carta marcada y qué hace Z
	var y := BOX_Y + 34
	var hw := _text_w(hint)
	if sel.has("id"):
		var sid: String = sel["id"]
		var line := CardDB.card_name(sid) + " · " + _card_kind(sid)
		if CardDB.is_pokemon(sid):
			line += " · HP %d" % CardDB.hp(sid)
		_text_scroll(Vector2(9, y), line, C_TEXT, W - 30 - hw, "setup_sel")
	elif sel.get("done", false):
		_text(Vector2(9, y), "Active: " + (me.active.display_name() if me.active != null else "—"), C_TEXT)
	_text(Vector2(W - 9 - hw, y), hint, C_DIM)


# ===========================================================================
# Visor de la mano (tecla M)
# ===========================================================================

const HAND_ROWS := 10

## Filas del visor: [id, cantidad]. La mano va carta por carta; el descarte se agrupa
## (Fire Energy ×3) y muestra primero lo último que se descartó.
func _pile_rows() -> Array:
	var rows: Array = []
	if pile_view == "hand":
		for id in game.players[human].hand:
			rows.append([id, 1])
		return rows
	var pile: Array[String] = game.players[human if pile_side == 0 else 1 - human].discard
	var index := {}
	for i in range(pile.size() - 1, -1, -1):
		var id: String = pile[i]
		if index.has(id):
			rows[index[id]][1] += 1
		else:
			index[id] = rows.size()
			rows.append([id, 1])
	return rows


func _hand_input(k: int, accept: bool, back: bool) -> void:
	var rows := _pile_rows()
	if k == KEY_UP:
		hand_cursor = maxi(0, hand_cursor - 1)
	elif k == KEY_DOWN:
		hand_cursor = mini(rows.size() - 1, hand_cursor + 1)
	elif k in [KEY_LEFT, KEY_RIGHT] and pile_view == "discard":
		pile_side = 1 - pile_side
		hand_cursor = 0
	elif k == KEY_M and pile_view != "hand":
		pile_view = "hand"
		hand_cursor = 0
	elif k == KEY_D and pile_view != "discard":
		pile_view = "discard"
		pile_side = 0
		hand_cursor = 0
	elif (accept or k == KEY_C) and not rows.is_empty():
		var entries: Array = []
		for r in rows:
			var rid: String = r[0]
			entries.append(func(): return _card_lines(rid, null))
		_open_info(entries, hand_cursor, func(j: int): hand_cursor = j)
	elif back or k == KEY_M or k == KEY_D:
		pile_view = ""


func _draw_hand() -> void:
	var rows := _pile_rows()
	var styled := _ui_tex("fondo") != null
	var mine := pile_view == "hand" or pile_side == 0
	var bg := C_MINE_BG if mine else C_OPP_BG
	var total := 0
	for row in rows:
		total += row[1]
	var head := "YOUR HAND (%d)" % total if pile_view == "hand" \
			else (("YOUR DISCARD (%d)" if mine else "OPPONENT'S DISCARD (%d)") % total)
	var right := "Opponent: %d cards" % game.players[1 - human].hand.size() if pile_view == "hand" else "◀▶ switch"
	if styled:
		_page(Rect2(Vector2.ZERO, Vector2(W, H)), Rect2(4, 15, W - 8, H - 19))
		_tab(Vector2(6, 3), _text_w(head) + 26, head)
		_text(Vector2(W - 8 - _text_w(right), 3), right, Color.WHITE)
		bg = Color("#f8d8a8") if mine else Color("#f8c8c0")     # fila elegida, sobre la caja crema
	else:
		_frame(Rect2(Vector2.ZERO, Vector2(W, H)))
		draw_rect(Rect2(5, 5, W - 10, TEXT_H + 3), bg.darkened(0.12))
		_text(Vector2(10, 6), head, C_TEXT)
		_text(Vector2(W - 8 - _text_w(right) - 2, 6), right, C_TEXT)
	if rows.is_empty():
		_text(Vector2(14, 26), "No cards." if pile_view == "discard" else "You have no cards in your hand.", C_TEXT)
	hand_cursor = clampi(hand_cursor, 0, maxi(0, rows.size() - 1))
	var top := clampi(hand_cursor - HAND_ROWS + 1, 0, maxi(0, rows.size() - HAND_ROWS))
	for i in range(top, mini(top + HAND_ROWS, rows.size())):
		var id: String = rows[i][0]
		var y := 22 + (i - top) * LINE_S
		if i == hand_cursor:
			draw_rect(Rect2(6, y - 1, 154, LINE_S), bg)
			_text(Vector2(10, y), "▶", C_TEXT)
		var chip := _card_chip_color(id)
		draw_rect(Rect2(19, y + 1, 7, 7), C_INK)
		draw_rect(Rect2(20, y + 2, 5, 5), chip)
		var label := CardDB.card_name(id) + (" ×%d" % rows[i][1] if rows[i][1] > 1 else "")
		if i == hand_cursor:
			_text_scroll(Vector2(30, y), label, C_TEXT, 126, "hand_sel")
		else:
			_text_fit(Vector2(30, y), label, C_TEXT, 126)
	# Imagen de la carta seleccionada, a la derecha
	if not rows.is_empty():
		var sel: String = rows[hand_cursor][0]
		var ir := Rect2(180, 22, INFO_IMG, INFO_IMG)
		draw_rect(Rect2(ir.position + Vector2(2, 2), ir.size), Color(0, 0, 0, 0.25))
		_draw_card_image(ir, sel)
		_text_fit(Vector2(164, 66), _card_kind(sel), C_TEXT, 70)
		var sub := ""
		if CardDB.is_pokemon(sel):
			sub = "HP %d · %s" % [CardDB.hp(sel), "/".join(CardDB.types(sel).map(func(t): return TYPE_ES.get(t, t)))]
		elif CardDB.is_basic_energy(sel):
			sub = CardDB.basic_energy_type(sel)
		_text_fit(Vector2(164, 77), sub, C_TEXT, 70)
		_text_fit(Vector2(164, 88), sel, C_DIM, 70)
	if rows.size() > HAND_ROWS:
		_text(Vector2(152, 22), "▲" if top > 0 else "", C_DIM)
		_text(Vector2(152, 22 + (HAND_ROWS - 1) * LINE_S), "▼" if top + HAND_ROWS < rows.size() else "", C_DIM)
	var keys := "Z/C view card · M hand · D discard · X close"
	_text_fit(Vector2(10, H - 15), keys, C_DIM, W - 20)


func _card_chip_color(id: String) -> Color:
	if CardDB.is_pokemon(id):
		var t := CardDB.types(id)
		return TYPE_COLORS.get(t[0] if not t.is_empty() else "Colorless", C_LIGHT)
	if CardDB.is_basic_energy(id):
		return TYPE_COLORS.get(CardDB.basic_energy_type(id), C_LIGHT)
	if CardDB.is_energy(id):
		return TYPE_COLORS["*"]
	return C_PANEL_DARK


func _card_kind(id: String) -> String:
	if CardDB.is_pokemon(id):
		var st: String = ["Basic", "Stage 1", "Stage 2"][CardDB.stage(id)]
		return st + (" ex" if CardDB.is_ex(id) else "")
	if CardDB.is_energy(id):
		return ("" if CardDB.is_basic_energy(id) else "Special ") + "Energy"
	if CardDB.is_supporter(id):
		return "Supporter"
	if CardDB.is_stadium(id):
		return "Stadium"
	if CardDB.is_pokemon_tool(id):
		return "Pokémon Tool"
	if CardDB.is_tm(id):
		return "TM"
	if CardDB.is_fossil(id):
		return "Fossil"
	return "Item"


func _menu_title() -> String:
	if intro == "call":
		return "Opening coin flip: heads or tails?"
	match game.phase:
		"first":
			return "You won the coin flip! Who goes first?"
		"setup":
			return "Choose your Active Pokémon" if game.players[human].active == null else "Setup"
		"choice":
			return game.pending_prompt()
	return category if menu_level == "list" else "Turn %d" % game.turn_number


# ===========================================================================
# Animaciones de ataque (según el tipo del atacante)
# ===========================================================================
# Todo es procedural: formas simples dibujadas cuadro a cuadro.
# t va de 0 a 1. Antes de ANIM_IMPACT el ataque "viaja"; en el impacto se aplica
# la acción en el motor (baja la vida) y el defensor tiembla.

func _start_attack_anim(action: Dictionary, coins_shown: int = 0) -> void:
	if action.has("ctx"):
		# Dobles: el que ataca y el que defiende pasan a ser "el" Activo de cada uno mientras
		# se arma la animación (y la mesa los marca con dbl_focus)
		var c: Array = action["ctx"]
		dbl_focus = [1 if c[0] else 0, 1 if c[1] else 0]
		game.with_ctx(c, func(): _start_attack_anim_raw(action, coins_shown))
		return
	dbl_focus = [0, 0]
	_start_attack_anim_raw(action, coins_shown)


func _start_attack_anim_raw(action: Dictionary, coins_shown: int = 0) -> void:
	var att := game.current_player()
	var atk: Dictionary = att.active.attacks()[action["a"]]
	var def := game.other(att)
	# Objetivo real: el Activo rival, o el Pokémon de Banca elegido (p.ej. Crushing Wave).
	var target: PokemonInPlay = def.active
	var to: Vector2 = _art_rect(def.index).get_center()
	var tg: int = action.get("tg", -2)
	if tg >= 0 and tg < def.bench.size():
		target = def.bench[tg]
		to = _bench_rect(def.index, tg).get_center()
	anim = {
		"t": 0.0, "action": action, "applied": false, "dmg": 0,
		"type": _attack_type(att.active, atk),
		"att_card": att.active.top(), "atk_name": str(atk.get("name", "")),
		"atk_text": str(atk.get("text", "")), "atk_dmg_text": str(atk.get("damage_text", "")),
		"att_mon_s": att.active, "att_dmg_s": att.active.damage,
		"from": _art_rect(att.index).get_center(),
		"to": to, "att": att.index, "def": def.index,
		"hp_before": target.hp_left() if target != null else 0,
		"def_mon": target,
		"label": "%s used %s!" % [att.active.display_name(), atk["name"]],
		"coins_shown": coins_shown,
		"seed": randi(),
		"dur": ANIM_TIME, "impact": ANIM_IMPACT,
		"poison": str(atk.get("text", "")).contains("Poisoned"),
		"weak": target != null and target == def.active and not Abilities.ignores_weakness(game, target) \
				and att.active.types().any(func(ty): return ty in Abilities.weakness_types(game, target)),
	}
	# Algunos Pokémon tienen su propia animación (scenes/special_fx.gd), pero solo cuando le
	# pegan a su rival (Kyogre a Groudon, Zangoose a Seviper…) con un ataque que hace daño.
	var sig := SpecialFX.signature_against(CardDB.card_name(att.active.top()),
			CardDB.card_name(target.top()) if target != null else "")
	# Con la escena de batalla activada, el ataque al Activo se ve como en los juegos de GBA
	# (tiene prioridad sobre la animación especial de rivales).
	var hits_active: bool = mode == "duel" and target != null and target == def.active \
			and str(atk.get("damage_text", "")) != ""     # los ataques que son solo efectos, en la mesa
	# En la mini pelea también se ven los ataques que solo dejan un estado al Activo rival
	var status_only: bool = mode == "duel" and target != null and target == def.active \
			and str(atk.get("damage_text", "")) == "" and MiniBattle.leaves_status(str(atk.get("text", "")))
	# ...y los que solo curan al atacante (se ve el efecto de curación encima suyo)
	if not status_only and str(atk.get("damage_text", "")) == "" and def.active != null and not game.rules.doubles \
			and MiniBattle.heals_self(str(atk.get("text", "")), CardDB.card_name(att.active.top())):
		status_only = true
	if battle_mode == 1 and (hits_active or status_only) and MiniBattle.can_use(att.active.top(), def.active.top()):
		MiniBattle.setup(anim, att, def, atk, human)
	elif sig != "" and str(atk.get("damage_text", "")) != "":
		anim["sig"] = sig
		anim["power"] = SpecialFX.power(att.active.top())
		anim["dur"] = SpecialFX.SIG_TIME
		anim["impact"] = SpecialFX.SIG_IMPACT
		snd.play("special")


# ===========================================================================
# Pokémon que cambian de lugar
# ===========================================================================
# Bajar un Básico a la Banca, retirarse, pasar al puesto Activo después de un KO o
# por un Switch: la carta viaja de un lugar al otro en vez de aparecer de golpe.
# Se detecta comparando dónde estaba cada Pokémon antes y después de la jugada.

func _places() -> Array:
	var out := []
	for pl in game.players:
		var d := {}
		for m in pl.all_in_play():
			d[m] = -1 if m == pl.active else pl.slot_of(m)
		out.append(d)
	return out


func _is_moving(m: PokemonInPlay) -> bool:
	for b in move_anim:
		for it in b["items"]:
			if it["mon"] == m:
				return true
	return false


func _check_moves(before: Dictionary) -> void:
	if not animations_on or not before.has("places"):
		return
	if before["phase"] in ["setup", "first"] or game.phase in ["setup", "first"]:
		return      # la preparación se revela con su propia animación
	var items := []
	var texts := []
	for pi in game.players.size():
		var pl: PlayerState = game.players[pi]
		var old: Dictionary = before["places"][pi]
		var hand_before: Array = before["piles"][pi][1]
		var mine := pi == human
		for m in pl.all_in_play():
			var now: int = -1 if m == pl.active else pl.slot_of(m)
			if old.has(m):
				if old[m] == now:
					continue
				items.append({"mon": m, "p": pi, "from": _slot_rect(pi, old[m]), "kind": "swap" if now == -1 or old[m] == -1 else "shift"})
				if now == -1:
					var out_mon = null
					for o in old:
						if old[o] == -1 and o != m and pl.all_in_play().has(o):
							out_mon = o
					if out_mon != null:
						texts = ["%s returns to the Bench" % out_mon.display_name(), "and %s comes out." % m.display_name()]
					else:
						texts = ["%s moves to the Active Spot!" % m.display_name()]
			else:
				# Nuevo en juego: desde la mano (o desde el mazo, si no estaba en la mano)
				var bench_r := _slot_rect(pi, now)
				var from_hand := m.cards[0] in hand_before
				var start: Rect2
				if from_hand:
					start = Rect2(Vector2(bench_r.position.x, H + 4 if mine else -30), MINI_SIZE)
				else:
					start = Rect2(_counters_pos(pi) + Vector2(28, -6), MINI_SIZE)
				items.append({"mon": m, "p": pi, "from": start, "kind": "hand" if from_hand else "deck"})
				var who := "You put" if mine else "The opponent puts"
				var where := "on the Bench" if now >= 0 else "in the Active Spot"
				var shown := "Pokémon face down" if _face_down(m) else m.display_name()
				if texts.is_empty() or texts[0].begins_with(who):
					texts = ["%s a %s %s." % [who, shown, where]] if texts.is_empty() \
							else [texts[0].trim_suffix(".") + " and %s." % shown]
	if items.is_empty():
		return
	var swap := items.any(func(it): return it["kind"] == "swap")
	move_anim.append({"items": items, "t": 0.0, "dur": SWAP_TIME if swap else MOVE_TIME, "text": texts})
	snd.play("draw", 0.8 if swap else 1.0)


func _draw_moves() -> void:
	for bi in move_anim.size():
		var b: Dictionary = move_anim[bi]
		var t: float = b["t"] if bi == 0 else 0.0
		var k := t * t * (3.0 - 2.0 * t)
		for it in b["items"]:
			var m: PokemonInPlay = it["mon"]
			var pl: PlayerState = game.players[it["p"]]
			var slot := -1 if m == pl.active else pl.slot_of(m)
			if slot == -2:
				continue
			var to := _slot_rect(it["p"], slot)
			var from: Rect2 = it["from"]
			var size: Vector2 = from.size.lerp(to.size, k)
			var c: Vector2 = from.get_center().lerp(to.get_center(), k)
			if it["kind"] == "swap":
				# Los dos se cruzan en arcos opuestos: como van en sentidos contrarios, la
				# perpendicular de cada uno ya apunta hacia lados distintos.
				var dirv := (to.get_center() - from.get_center()).normalized()
				c += Vector2(-dirv.y, dirv.x) * sin(k * PI) * 20.0
			elif it["kind"] == "hand":
				c.y += -sin(k * PI) * 8.0 * (1.0 if it["p"] == human else -1.0)
			_draw_moving_card(Rect2(c - size / 2.0, size).abs(), m, bi == 0 and t > 0.0)
			if bi == 0 and t > 0.85:      # polvito al aterrizar
				var a := (1.0 - t) / 0.15
				for j in 4:
					var px := to.position.x + (to.size.x if j % 2 else 0.0) + (-3.0 if j % 2 == 0 else 3.0) * (1.0 - a)
					draw_rect(Rect2(Vector2(px, to.end.y - 2 - j / 2 * 3), Vector2(2, 2)), Color(1, 1, 1, a * 0.8))


## Carta en viaje: marco amarillo, color del tipo y la ilustración escalada.
func _draw_moving_card(r: Rect2, m: PokemonInPlay, shadow: bool) -> void:
	r.position = r.position.floor()
	r.size = r.size.round()
	if _face_down(m):
		_draw_card_back(r)
		return
	var t := _main_type(m.top())
	if shadow:
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), C_YELLOW)
	_fill_types(r.grow(-2), m)
	var side := floorf(minf(r.size.x - 6, r.size.y - 10))
	if side < 4:
		return
	var ar := Rect2(r.position + Vector2(floorf((r.size.x - side) / 2.0), 4), Vector2(side, side))
	var tex := _art_texture(m.top(), 36, 36)
	if tex != null:
		draw_texture_rect(tex, ar, false)
	else:
		draw_rect(ar, TYPE_DARK[t])


## Cara a cara: si los dos Activos son rivales clásicos (ver scenes/special_fx.gd) y
## todavía no se mostró en esta partida, empieza la escena. Devuelve true si empezó.
func _check_vs() -> bool:
	if not animations_on or intro != "" or game.phase not in ["main", "choice"] or game.rules.doubles:
		return false        # en las batallas dobles no hay cara a cara
	var mine: PokemonInPlay = game.players[human].active
	var theirs: PokemonInPlay = game.players[1 - human].active
	if mine == null or theirs == null:
		return false
	var r := SpecialFX.rivalry(CardDB.card_name(mine.top()), CardDB.card_name(theirs.top()))
	if r.is_empty() or vs_seen.has(r["key"]):
		return false
	vs_seen[r["key"]] = true
	vs_anim = r
	vs_anim["t"] = 0.0
	vs_anim["a"] = mine.top()
	vs_anim["b"] = theirs.top()
	snd.play("vs")
	return true


## Tipo de la animación: la primera Energía de color del costo del ataque
## (Crushing Wave cuesta Agua, aunque Swampert ex sea Lucha). Si el ataque solo
## pide Incolora, se usa el tipo del Pokémon.
func _attack_type(p: PokemonInPlay, atk: Dictionary) -> String:
	for c in atk.get("cost", []):
		if c != "Colorless" and TYPE_COLORS.has(c):
			return c
	var types := p.types()
	return types[0] if not types.is_empty() else "Colorless"


func _update_anim(delta: float) -> void:
	if anim.get("waiting", false):
		anim["waiting"] = false
		if anim.get("hit_pending", false):
			anim["hit_pending"] = false
			_hit_sound()
	if float(anim.get("stop", 0.0)) > 0.0:
		anim["stop"] = float(anim["stop"]) - delta     # golpe a la debilidad: el instante se congela
		return
	var t_before: float = anim["t"]
	anim["t"] += delta / float(anim.get("dur", ANIM_TIME))
	var imp_t := float(anim.get("impact", ANIM_IMPACT))
	if anim.get("weak", false) and t_before < imp_t and anim["t"] >= imp_t:
		anim["t"] = imp_t + 0.001
		anim["stop"] = WEAK_STOP
		snd.play("weak")
	if not anim["applied"] and anim["t"] >= float(anim.get("impact", ANIM_IMPACT)):
		anim["applied"] = true
		var mon: PokemonInPlay = anim["def_mon"]
		anim["cond_before"] = _condition_list(mon) if mon != null else []
		var before := _snapshot()
		var start := game.coin_log.size()
		game.body_events.clear()
		game.checkup_mark = -1
		var turn0 := game.turn_number
		game.apply(anim["action"])
		_collect_body_events(true)
		if anim.get("coins_shown", 0) > 0:
			coins_seen = start + int(anim["coins_shown"])     # ya se vieron antes del ataque
		_check_energy(before["energy"])
		_check_evolutions()
		_check_recovered(before["piles"])
		_check_moves(before)
		# Monedas del ataque que no se adelantaron (sin animaciones previas): antes del golpe.
		# Las del cambio de turno (Dormido, Quemado) se ven después del ataque.
		var own := false
		for i in range(coins_seen, game.coin_log.size()):
			if game.coin_reasons[i] == "":
				own = true
		if own and _check_coins():
			anim["waiting"] = true     # primero se ven las monedas, después el golpe
		if mon != null:
			# Si después del ataque hubo chequeo entre turnos, el golpe es lo que había justo
			# antes (el veneno y la quemadura se ven aparte, después)
			var hp_after := mon.hp_left()
			var ck = mon.flags.get("pre_checkup", [])
			var checked: bool = ck is Array and ck.size() == 3 and int(ck[0]) == turn0
			if checked:
				hp_after = mon.max_hp() - int(ck[1])
			anim["dmg"] = maxi(0, anim["hp_before"] - maxi(0, hp_after))
			if not game.players[anim["def"]].all_in_play().has(mon) and (not checked or hp_after <= 0):     # quedó KO con el golpe
				anim["dmg"] = anim["hp_before"]
				anim["ko"] = true
		if anim.get("mini", false):
			MiniBattle.on_applied(anim)
		if anim.get("waiting", false):
			anim["hit_pending"] = true     # suena cuando se ve el golpe, después de las monedas
		else:
			_hit_sound()
	if anim["t"] >= 1.0:
		anim = {}
		ai_timer = AI_DELAY
		_check_coins()      # las monedas del cambio de turno, si las hubo
		_rebuild_menu()


const HIT_SHAKE := 0.34      # lo que tiembla el defensor después del golpe (fracción del ataque)
const BIG_HIT := 60          # desde este daño tiembla toda la mesa
const WEAK_STOP := 0.14      # golpe a la debilidad: segundos que se congela el impacto


## Temblor de toda la mesa en los golpes fuertes.
func _table_shake() -> Vector2:
	if anim.get("scene", false):
		return Vector2.ZERO
	var weak: bool = not anim.is_empty() and anim.get("weak", false) and int(anim.get("dmg", 0)) > 0
	if anim.is_empty() or anim.get("waiting", false) or (int(anim.get("dmg", 0)) < BIG_HIT and not weak):
		return Vector2.ZERO
	var t: float = anim["t"]
	var imp: float = anim.get("impact", ANIM_IMPACT)
	var dur := 0.3 if weak else 0.18
	if t < imp or t > imp + dur:
		return Vector2.ZERO
	var k := 1.0 - (t - imp) / dur
	var amp := 3.5 if weak else 2.0
	if float(anim.get("stop", 0.0)) > 0.0:
		k = 1.0                         # mientras se congela, la mesa sigue sacudida
		t += Time.get_ticks_msec() / 1000.0
	return Vector2(round(sin(t * 110.0) * amp * k), round(cos(t * 95.0) * amp * 0.75 * k))


# Íconos de estado de Mystery Dungeon (efectos/propios/est_*.png, tools/armar_estados.py),
# animados arriba de la imagen del Pokémon. Si tiene varios, se turnan.
#   est_poder         tiene un Poké-Power que puede usar ahora
#   est_poder_negado  su Poké-Power está negado (Condición Especial, Toxic Gas, Lazy...)
#   est_aviso         el rival le puso un efecto (no puede atacar, ni retirarse, ataque bloqueado...)
#   est_escudo        recibe menos daño          est_mas / est_menos  hace más / menos daño
#   est_quemado, est_confuso, est_dormido, est_veneno; Paralizado = rayo.png
const PMD_SHOW := 1.1         # segundos que se ve cada ícono (su animación)
const PMD_GAP := 0.9          # después desaparece un momento y aparece el siguiente (o el mismo de nuevo)
var _power_cache := {}         # jugador -> slots con un Poké-Power usable (se recalcula si cambia la partida)
var _power_cache_key := []


func _power_slots(pl: PlayerState) -> Dictionary:
	var key := [game.turn_number, game.log_lines.size(), game.current, game.phase]
	if key != _power_cache_key:
		_power_cache_key = key
		_power_cache = {}
	if not _power_cache.has(pl.index):
		var slots := {}
		if game.current == pl.index and game.phase == "main":
			for a in Abilities.power_actions(game, pl):
				slots[int(a["s"])] = true
		_power_cache[pl.index] = slots
	return _power_cache[pl.index]


func _pmd_icons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	var out: Array = []
	for r in _pmd_reasons(pl, p, slot):
		if not r[0] in out:
			out.append(r[0])
	return out


const REASON_COL := {"est_aviso": Color("#b02818"), "est_escudo": Color("#2858a8"), "est_mas": Color("#1c7a2c"),
		"est_menos": Color("#806030"), "est_poder": Color("#7838a8"), "est_poder_negado": Color("#707080")}
const CONDITION_ICONS := ["est_quemado", "est_veneno", "est_dormido", "est_confuso", "rayo"]


## Los motivos sin las Condiciones Especiales (esas ya se ven en rojo al lado de la vida).
func _effect_reasons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	return _pmd_reasons(pl, p, slot).filter(func(r): return not r[0] in CONDITION_ICONS)


## Versión corta de un motivo para la vista partida (la ficha completa tiene el texto entero).
func _short_reason(t: String, width: float) -> String:
	if _text_w(t) <= width:
		return t
	for cut in [" next turn", " from attacks", " at end of next turn", ": takes less damage", " damage"]:
		if t.contains(cut) and _text_w(t.replace(cut, "")) <= width:
			return t.replace(cut, "")
	return t.replace(" next turn", "")


## Ícono de estado chiquito (unos 10 px), animado, para los renglones de explicación.
func _reason_icon(name: String, center: Vector2) -> void:
	var cell := SpecialFX.fx_cell(name)
	if cell.x <= 0:
		return
	_draw_pmd_icon(name, center, 10.0 / maxf(cell.x, cell.y))


## Lo mismo que _pmd_icons, pero con el motivo: [[ícono, "explicación"], ...] (un ícono puede
## aparecer varias veces si tiene varios motivos). Se muestra en la vista partida (C en la mesa).
func _pmd_reasons(pl: PlayerState, p: PokemonInPlay, slot: int) -> Array:
	var out: Array = []
	var t := game.turn_number
	if slot == -1:
		if p.burned:
			out.append(["est_quemado", "Burned: flip at checkup, tails = 2 damage counters"])
		if p.poison > 0:
			out.append(["est_veneno", "Poisoned: %d damage counter%s at checkup" % [p.poison, "" if p.poison == 1 else "s"]])
		match p.rotation:
			"asleep": out.append(["est_dormido", "Asleep: can't attack or retreat"])
			"confused": out.append(["est_confuso", "Confused: flip to attack"])
			"paralyzed": out.append(["rayo", "Paralyzed: can't attack or retreat"])
	for ab in p.abilities():
		if ab["kind"] != "Poké-Power":
			continue
		if Abilities.power_blocked(game, pl, p):
			out.append(["est_poder_negado", "Can't use Poké-Power: %s" % ab["name"]])
		elif _power_slots(pl).has(slot):
			out.append(["est_poder", "Can use Poké-Power: %s" % ab["name"]])
	if slot != -1:
		return out
	var f := p.flags
	if int(f.get("cant_attack", -1)) >= t:
		out.append(["est_aviso", "Can't attack next turn"])
	if int(f.get("cant_retreat", -1)) >= t:
		out.append(["est_aviso", "Can't retreat next turn"])
	if int(f.get("no_attach", -1)) >= t:
		out.append(["est_aviso", "Can't get Energy next turn"])
	if int(f.get("smokescreen", -1)) >= t:
		out.append(["est_aviso", "Must flip to attack (tails: no attack)"])
	if f.get("disabled_attack", null) is Array and int(f["disabled_attack"][1]) >= t:
		out.append(["est_aviso", "Can't use %s next turn" % str(f["disabled_attack"][0])])
	if f.has("delayed_status"):
		var ds = f["delayed_status"]
		var cond: String = str(ds[0]) if ds is Array else str(ds)
		out.append(["est_aviso", "Will be %s at end of next turn" % cond.capitalize()])
	if f.get("silver_wind", null) is Array and int(f["silver_wind"][0]) >= t:
		out.append(["est_aviso", "Takes %d more damage next turn" % int(f["silver_wind"][2])])
	if Abilities.attack_blocked(game, p):
		out.append(["est_aviso", "Can't attack (a Poké-Body blocks it)"])
	var opp := game.other(pl)
	if int(f.get("prevent_all", -1)) >= t:
		out.append(["est_escudo", "No damage or effects from attacks"])
	elif int(f.get("prevent_damage", -1)) >= t:
		out.append(["est_escudo", "No damage from attacks"])
	if int(f.get("reduce_until", -1)) >= t:
		out.append(["est_escudo", "Takes less damage next turn"])
	if CardDB.card_name(p.tool) == "Buffer Piece":
		out.append(["est_escudo", "Buffer Piece: takes 20 less damage"])
	if p.is_type("Metal") and Energy.count_named(p, "Metal Energy") > 0:
		out.append(["est_escudo", "Metal Energy: takes 10 less damage"])
	for body in ["Exoskeleton", "Hard Cocoon", "Sand Guard", "Crust", "Ice Wall", "Glowing Screen"]:
		if Abilities.body(game, p, body):
			out.append(["est_escudo", "%s: takes less damage" % body])
	if Abilities.body(game, p, "Energy Guard") and p.basic_energy_count() > 0:
		out.append(["est_escudo", "Energy Guard: takes less damage"])
	if Abilities.body(game, p, "Shell Retreat") and not p.energy.is_empty():
		out.append(["est_escudo", "Shell Retreat: takes less damage"])
	if Abilities.body(game, p, "Core Guard") and Energy.count_type(p, "Psychic") > 0:
		out.append(["est_escudo", "Core Guard: takes less damage"])
	if int(f.get("next_until", -1)) >= t:
		out.append(["est_mas", "Next attack does more damage"])
	if CardDB.card_name(p.tool) == "Strength Charm":
		out.append(["est_mas", "Strength Charm: +10 damage"])
	if (p.is_type("Darkness") or p.name_has("Dark")) and Energy.count_named(p, "Darkness Energy") > 0:
		out.append(["est_mas", "Darkness Energy: +10 damage"])
	if Abilities.active_body(game, pl, "Power Pinchers"):
		out.append(["est_mas", "Power Pinchers: does more damage"])
	if Abilities.body(game, p, "Overzealous"):
		out.append(["est_mas", "Overzealous: does more damage"])
	if Energy.count_named(p, "Double Rainbow Energy") > 0:
		out.append(["est_menos", "Double Rainbow Energy: -10 damage"])
	if Abilities.active_body(game, opp, "Intimidating Fang"):
		out.append(["est_menos", "Intimidating Fang: -10 damage"])
	return out


## Pastilla de estado de Rubí/Zafiro (mundo/propios/ui/estado_*.png) en la ficha. Si
## tiene varios estados, se turnan cada STATUS_PILL_TIME segundos. false = no hay imágenes.
const PILL_FOR := {"poisoned": "estado_psn", "paralyzed": "estado_par", "asleep": "estado_slp",
		"burned": "estado_brn", "confused": "estado_cnf"}
const STATUS_PILL_TIME := 1.5

func _draw_status_pill(pos: Vector2, conds: Array) -> bool:
	var texs: Array = []
	for c in conds:
		var tex := _ui_tex(str(PILL_FOR.get(c, "")))
		if tex == null:
			return false
		texs.append(tex)
	var i := int(Time.get_ticks_msec() / 1000.0 / STATUS_PILL_TIME) % texs.size()
	draw_texture(texs[i], pos)
	if texs.size() > 1:            # puntitos debajo: cuántos tiene y cuál se ve
		for j in texs.size():
			draw_rect(Rect2(pos.x + 22, pos.y + 1 + j * 2, 1, 1), C_TEXT if j == i else C_PANEL_DARK)
	return true


## Se ven los íconos animados de estado (están las tiras y las animaciones prendidas).
func _pmd_shown() -> bool:
	return animations_on and SpecialFX.has_fx("est_quemado") and SpecialFX.has_fx("est_veneno") \
			and SpecialFX.has_fx("est_dormido") and SpecialFX.has_fx("est_confuso") and SpecialFX.has_fx("rayo")


## local: segundos desde que apareció (la animación arranca del primer cuadro); -1 = reloj.
func _draw_pmd_icon(name: String, pos: Vector2, scale: float, local: float = -1.0, alpha: float = 1.0) -> void:
	var n := SpecialFX.fx_count(name)
	if n == 0:
		return
	var t := local if local >= 0.0 else Time.get_ticks_msec() / 1000.0
	var fr := int(t / 0.09) % n
	SpecialFX.fx_draw(self, name, fr, pos, scale, alpha)


## El ícono de estado del Activo, arriba de su imagen, con un rebotecito.
func _draw_status_fx(pl: PlayerState, mon: PokemonInPlay = null, art_r: Rect2 = Rect2()) -> void:
	var m: PokemonInPlay = mon if mon != null else pl.active
	if m == null or not animations_on:
		return
	# (el Poké-Power ya se ve en la pestaña del Activo: acá no va el ícono de las esferas)
	var icons := _pmd_icons(pl, m, -1).filter(func(n): return not n.begins_with("est_poder"))
	if icons.is_empty():
		return
	# Intermitente: se ve un rato (con su animación desde el principio), desaparece un
	# momento y vuelve (el mismo, o el siguiente si tiene varios estados)
	var now := Time.get_ticks_msec() / 1000.0
	var cycle := PMD_SHOW + PMD_GAP
	var idx := int(now / cycle) % icons.size()
	var local := fmod(now, cycle)
	if local >= PMD_SHOW:
		return
	var name: String = icons[idx]
	var art := Rect2(_art_rect(pl.index).position + _anim_offset(pl.index), _art_rect(pl.index).size)
	if art_r.size.x > 0:
		art = art_r
	var bob := roundf(sin(local * 4.0) * 1.5)
	var sc := 1.0
	if name == "rayo":
		sc = 0.6
	elif name.begins_with("est_poder"):
		sc = 2.0                         # los ojos son chiquitos (8x8)
	var pop := clampf(local / 0.08, 0.0, 1.0)            # aparece con un saltito de escala
	var fade := clampf((PMD_SHOW - local) / 0.12, 0.0, 1.0)  # y se apaga suave
	_draw_pmd_icon(name, Vector2(art.end.x - 8, art.position.y + 8 + bob), sc * (0.6 + 0.4 * pop), local, fade)
	if icons.size() > 1:                 # puntitos: cuántos estados tiene y cuál se ve
		for i in icons.size():
			var c := Color.WHITE if i == idx else Color(1, 1, 1, 0.4)
			draw_rect(Rect2(art.position.x + 2 + i * 4, art.end.y - 3, 2, 2), c)


## En la Banca: si tiene un Poké-Power que se puede usar ahora, el borde late en rojo (el
## mismo rojo de la pestaña de Poké-Power del Activo).
func _draw_bench_status(pl: PlayerState, i: int, r: Rect2) -> void:
	if not _power_slots(pl).has(i):
		return
	var a := 0.85 + 0.15 * sin(Time.get_ticks_msec() / 1000.0 * 5.0) if animations_on else 1.0
	var glow := 0.35 + 0.65 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)) if animations_on else 1.0
	_outline(r.grow(1), Color(TAB_COLORS["power"][0], a))
	_outline(r.grow(2), Color(TAB_COLORS["power"][0], a))
	_outline(r.grow(3), Color(TAB_COLORS["power"][1], glow))


## Destello blanco sobre la carta que recibe el golpe.
func _draw_hit_flash(pl: PlayerState) -> void:
	if anim.is_empty() or anim.get("waiting", false) or anim.get("scene", false) or int(anim.get("dmg", 0)) <= 0:
		return
	if pl.index != anim["def"] or not pl.is_active(anim["def_mon"]):
		return
	var t: float = anim["t"]
	var imp: float = anim.get("impact", ANIM_IMPACT)
	var weak: bool = anim.get("weak", false)
	var dur := 0.2 if weak else 0.09
	if t < imp or t > imp + dur:
		return
	var a := 1.0 - (t - imp) / dur
	var r := _portrait_rect(_card_rect(pl.index).position + _anim_offset(pl.index))
	if weak and float(anim.get("stop", 0.0)) <= 0.0:
		draw_rect(r, Color(1, 0.2, 0.15, 0.6 * a))      # debilidad: después del blanco, rojo
		draw_rect(Rect2(0, 0, W, BOX_Y), Color(1, 1, 1, 0.25 * a))
	else:
		draw_rect(r, Color(1, 1, 1, 0.8 if weak else 0.75 * a))


## Desplazamiento del Activo de un jugador: el atacante embiste, el defensor tiembla.
func _anim_offset(player: int) -> Vector2:
	if anim.is_empty() or anim.get("waiting", false) or anim.get("scene", false):
		return Vector2.ZERO
	var t: float = anim["t"]
	var imp: float = anim.get("impact", ANIM_IMPACT)
	var sig: String = anim.get("sig", "")
	if player == anim["att"] and t < imp:
		var dir: Vector2 = (anim["to"] - anim["from"]).normalized()
		var k := sin(t / imp * PI) * (6.0 if anim["type"] in ["Fighting", "Colorless", "Metal"] or sig in ["zangoose", "heracross"] else 3.0)
		return dir * k
	if player == anim["def"] and t >= imp and t < imp + HIT_SHAKE and anim["dmg"] > 0 \
			and game.players[anim["def"]].is_active(anim["def_mon"]):
		# Cuanto más daño, más fuerte tiembla (y los especiales, lo suyo)
		var amp: float = SpecialFX.shake(sig) if sig != "" else clampf(2.0 + anim["dmg"] / 15.0, 3.0, 7.0)
		if anim.get("weak", false):
			amp = maxf(amp, 9.0)
		var k := pow(1.0 - (t - imp) / HIT_SHAKE, 1.5) * amp
		return Vector2(round(sin(t * 90.0) * k), round(cos(t * 70.0) * k * 0.35))
	return Vector2.ZERO


func _draw_anim() -> void:
	if anim.is_empty() or anim.get("waiting", false) or anim.get("scene", false):
		return
	_draw_anim_fx()


## El efecto del ataque según el tipo (lo usa también la escena de batalla, con otras
## posiciones de atacante y defensor).
func _draw_anim_fx() -> void:
	var t: float = anim["t"]
	var from: Vector2 = anim["from"]
	var to: Vector2 = anim["to"]
	var c: Color = TYPE_COLORS.get(anim["type"], C_LIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = anim["seed"]
	var imp: float = anim.get("impact", ANIM_IMPACT)
	var travel := clampf(t / imp, 0.0, 1.0)     # 0..1 hasta el impacto
	var after := clampf((t - imp) / (1.0 - imp), 0.0, 1.0)   # 0..1 después
	var hit := t >= imp
	var kind: String = anim["type"]
	if anim.has("sig"):
		SpecialFX.draw_attack(self, anim, BOX_Y)
		kind = "special"
	elif anim.get("poison", false) and hit:
		# Ataques que envenenan: la nube de veneno de los sprites (si están), sobre el rival
		SpecialFX.poison_cloud(self, to, after / 0.95, 0.85)
	match kind:
		"special":
			pass
		"Fire":
			if SpecialFX.has_fx("ascuas") or SpecialFX.has_fx("fuego_golpe"):
				# Con los sprites de efectos: tres ascuas que vuelan y un golpe de fuego
				for i in 3:
					var k := clampf(travel * 1.3 - i * 0.15, 0.0, 1.0)
					if k > 0.0 and k < 1.0:
						var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 10)
						if SpecialFX.has_fx("ascuas"):
							SpecialFX.fx_draw(self, "ascuas", 5 + (int(t * 24.0) + i * 2) % 6, p, 0.9 - i * 0.12)
						else:
							draw_circle(p, 4.0 - i, c)
				if hit:
					if not SpecialFX.fire_hit(self, to, after / 0.9, 0.8):
						for i in 10:
							var ang := rng.randf() * TAU
							var p := to + Vector2(cos(ang), sin(ang)) * after * rng.randf_range(8, 18)
							draw_circle(p, (1.0 - after) * 3.0 + 0.5, c if i % 2 == 0 else Color("#ffd040"))
			else:
				# Tres bolas de fuego en fila y una explosión de llamas.
				for i in 3:
					var k := clampf(travel * 1.3 - i * 0.15, 0.0, 1.0)
					if k > 0.0 and k < 1.0:
						var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 10)
						draw_circle(p, 4.0 - i, c)
						draw_circle(p, 2.0 - i * 0.5, Color("#ffe060"))
				if hit:
					for i in 10:
						var ang := rng.randf() * TAU
						var r := after * rng.randf_range(8, 18)
						var p := to + Vector2(cos(ang), sin(ang)) * r + Vector2(0, -after * 6)
						draw_circle(p, (1.0 - after) * 3.0 + 0.5, c if i % 2 == 0 else Color("#ffd040"))
		"Water":
			# Chorro de gotas en arco y salpicadura.
			for i in 6:
				var k := clampf(travel * 1.4 - i * 0.07, 0.0, 1.0)
				if k > 0.0 and k < 1.0:
					var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 18)
					draw_circle(p, 2.5, c)
					draw_circle(p + Vector2(-0.8, -0.8), 1.0, C_LIGHT)
			if hit:
				for i in 8:
					var ang := -PI * rng.randf()
					var v := Vector2(cos(ang), sin(ang)) * rng.randf_range(10, 20)
					var p := to + v * after + Vector2(0, 20 * after * after)
					draw_circle(p, 2.0 * (1.0 - after) + 0.5, c)
		"Grass":
			# Hojas girando.
			for i in 5:
				var k := clampf(travel * 1.3 - i * 0.08, 0.0, 1.0)
				var p := from.lerp(to, k) + Vector2(0, sin(k * PI * 2.0 + i) * 6)
				if hit:
					var ang0 := rng.randf() * TAU
					p = to + Vector2(cos(ang0), sin(ang0)) * after * 16
				_draw_leaf(p, t * 20.0 + i, c)
		"Lightning":
			# Rayo que cae del cielo y destello de pantalla.
			if t > ANIM_IMPACT * 0.6:
				var pts := PackedVector2Array([Vector2(to.x + 4, 0)])
				var y := 0.0
				while y < to.y:
					y += rng.randf_range(5, 9)
					pts.append(Vector2(to.x + rng.randf_range(-6, 6), minf(y, to.y)))
				if after < 0.6 and int(t * 30) % 2 == 0:
					draw_polyline(pts, Color("#fff8a0"), 2.0)
					draw_polyline(pts, c, 1.0)
			if hit and after < 0.25:
				draw_rect(Rect2(0, 0, W, BOX_Y), Color(1, 1, 0.8, 0.5 * (1.0 - after / 0.25)))
		"Psychic":
			# Ondas que salen del atacante y anillos sobre el defensor.
			for i in 3:
				var k := fmod(travel + i * 0.33, 1.0)
				if not hit:
					draw_arc(from.lerp(to, k), 4.0 + k * 6.0, 0, TAU, 16, c, 1.0)
			if hit:
				for i in 3:
					var r := (after * 1.5 - i * 0.2) * 22.0
					if r > 0.0:
						draw_arc(to, r, 0, TAU, 24, Color(c, 1.0 - after), 1.0)
		"Fighting":
			# Embestida (ver _anim_offset) y estrella de impacto.
			if hit and after < 0.6:
				_draw_burst(to, 6.0 + after * 14.0, C_LIGHT, 8)
				_draw_burst(to, 3.0 + after * 8.0, c, 8)
		"Darkness":
			# Pantalla que se oscurece y dos tajos en X.
			draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.35 * sin(t * PI)))
			if hit:
				var k := minf(after * 3.0, 1.0)
				var a := Color(0.85, 0.75, 1.0, 1.0 - after)
				draw_line(to + Vector2(-12, -12), to + Vector2(-12, -12).lerp(Vector2(12, 12), k), a, 2.0)
				draw_line(to + Vector2(12, -12), to + Vector2(12, -12).lerp(Vector2(-12, 12), k), a, 2.0)
		"Metal":
			# Esquirlas metálicas y chispas.
			for i in 4:
				var k := clampf(travel * 1.3 - i * 0.1, 0.0, 1.0)
				if k > 0.0 and k < 1.0:
					var p := from.lerp(to, k) + Vector2(0, (i - 1.5) * 4)
					var d := (to - from).normalized() * 4
					draw_line(p - d, p + d, C_LIGHT, 2.0)
			if hit:
				for i in 8:
					var ang := rng.randf() * TAU
					var p := to + Vector2(cos(ang), sin(ang)) * after * rng.randf_range(10, 20)
					draw_rect(Rect2(p, Vector2(2, 2)), Color("#fff0a0") if i % 2 else c)
		_:
			if hit and after < 0.6:
				if SpecialFX.has_fx("estrellas"):      # tus estrellas de golpe
					SpecialFX.fx_draw(self, "estrellas", SpecialFX.fx_frame("estrellas", after / 0.6), to, 1.0, 1.0 - after)
				else:
					_draw_burst(to, 5.0 + after * 12.0, C_LIGHT, 5)
	# Golpe a la debilidad: tu explosión grande y estrellas que salen volando
	if hit and anim.get("weak", false) and anim["dmg"] > 0:
		var ke := clampf(after * 2.2, 0.0, 1.0)
		if ke < 1.0:
			if SpecialFX.has_fx("explosion"):
				SpecialFX.fx_draw(self, "explosion", SpecialFX.fx_frame("explosion", ke), to, 2.2, 1.0 - ke * 0.5)
			else:
				_draw_burst(to, 10.0 + ke * 24.0, Color("#fff0a0"), 8)
			for i in 6:
				var ang := TAU * i / 6.0 + 0.4
				var sp := to + Vector2(cos(ang), sin(ang)) * (8.0 + ke * 34.0)
				if SpecialFX.has_fx("estrellas"):
					SpecialFX.fx_draw(self, "estrellas", (i + int(ke * 8)) % 5, sp, 0.6, 1.0 - ke)
				else:
					_draw_star(sp, 3.0, ke * 3.0, Color(C_ACCENT, 1.0 - ke))
	# Número de daño flotando sobre el defensor (en la escena de batalla lo dicen la barra y
	# el mensaje, como en los juegos).
	if hit and anim["dmg"] > 0 and not anim.get("scene", false):
		# El número salta grande, rebota y sube flotando
		var txt := "-%d" % anim["dmg"]
		var weak: bool = anim.get("weak", false)
		var pop := clampf(after * 7.0, 0.0, 1.0)
		var base_sc := 3.0 if weak else 2.0
		var sc: float = base_sc + sin(pop * PI) * (1.4 if weak else 0.8) if pop < 1.0 else base_sc
		var w := _text_w(txt) * sc
		var p := to + Vector2(-w / 2.0, -26 - after * 8)
		if p.y < 4:                        # objetivo arriba de todo: el número va abajo
			p = to + Vector2(-w / 2.0, 6 + after * 5)
		p.x = clampf(p.x, 2.0, W - 2.0 - w)  # que no se salga por los costados (mesa doble)
		var col: Color = Color("#f85838") if anim["dmg"] >= BIG_HIT or weak else C_LIGHT
		col.a = clampf((1.0 - after) * 3.0, 0.0, 1.0)
		draw_set_transform(_base_off + p.round(), 0, Vector2(sc, sc))
		_text(Vector2.ZERO, txt, col)
		draw_set_transform(_base_off)
		if weak:                           # el cartel de la debilidad: grande, en el medio de la mesa
			var lbl := "WEAKNESS!"
			var lk := clampf(after * 5.0, 0.0, 1.0)
			var lsc := 2.0 + (1.0 - lk) * 1.5
			var lw := _text_w(lbl) * lsc
			var lc := Color("#f8d030") if int(Time.get_ticks_msec() / 90.0) % 2 == 0 else Color.WHITE
			lc.a = col.a
			draw_rect(Rect2(0, BOX_Y / 2.0 - 13, W, 22), Color(0.1, 0.05, 0.05, 0.55 * col.a))
			draw_set_transform(_base_off + Vector2(roundf(W / 2.0 - lw / 2.0), roundf(BOX_Y / 2.0 - 5.0 * lsc)), 0, Vector2(lsc, lsc))
			_text(Vector2.ZERO, lbl, lc)
			draw_set_transform(_base_off)


func _draw_leaf(p: Vector2, ang: float, c: Color) -> void:
	var a := Vector2(cos(ang), sin(ang)) * 4.0
	var b := Vector2(-a.y, a.x) * 0.4
	draw_colored_polygon(PackedVector2Array([p - a, p + b, p + a, p - b]), c)


func _draw_burst(center: Vector2, radius: float, c: Color, points: int) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var ang := TAU * i / (points * 2.0) - PI / 2.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, c)


# ===========================================================================
# Animación de monedas
# ===========================================================================
# El motor anota cada moneda en game.coin_log. Después de cada acción se muestran
# las monedas nuevas una por una: la moneda sube girando, cae y muestra el resultado.

## Devuelve true si hay monedas nuevas para mostrar.
func _check_coins() -> bool:
	if not animations_on or game.coin_log.size() <= coins_seen:
		coins_seen = game.coin_log.size()
		return false
	var results := game.coin_log.slice(coins_seen)
	var reasons := game.coin_reasons.slice(coins_seen)
	coins_seen = game.coin_log.size()
	coin_anim = {"results": results, "reasons": reasons, "i": 0, "t": 0.0,
			"per": COIN_TIME if results.size() <= 3 else COIN_TIME * 0.6}
	return true


func _update_coins(delta: float) -> void:
	coin_anim["t"] += delta / coin_anim["per"]
	if coin_anim["t"] >= 1.0:
		coin_anim["t"] = 0.0
		coin_anim["i"] += 1
		if coin_anim["i"] >= coin_anim["results"].size():
			var then = coin_anim.get("then")
			coin_anim = {}
			if then is Callable:
				then.call()
			elif anim.is_empty():
				ai_timer = AI_DELAY
				_rebuild_menu()


## Carga las monedas (cara y cruz) de mundo/propios/monedas/moneda_NN.png y _cruz.png.
func _load_coins() -> void:
	if _coins_loaded:
		return
	_coins_loaded = true
	for dir_path in ["res://mundo/propios/monedas", "user://mundo/propios/monedas"]:
		for n in range(1, 100):
			var p := "%s/moneda_%02d.png" % [dir_path, n]
			if not ImgLoad.exists(p):
				break
			var heads := _load_png(p)
			var tails := _load_png(p.replace(".png", "_cruz.png"))
			if heads != null:
				_coin_sets.append([heads, tails if tails != null else heads])
		if not _coin_sets.is_empty():
			return


func _load_png(path: String) -> Texture2D:
	if not ImgLoad.exists(path):
		return null
	var img := ImgLoad.load(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _draw_coins() -> void:
	if coin_anim.is_empty():
		return
	var results: Array = coin_anim["results"]
	var i: int = coin_anim["i"]
	var t: float = coin_anim["t"]
	var heads: bool = results[i]
	var reason: String = coin_anim["reasons"][i]
	var img_coin := coin_pick >= 0 and coin_pick < _coin_sets.size()
	var center := Vector2(W / 2.0, 52 if img_coin else 56)
	# Fondo oscurecido y recuadro
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.35))
	var spin := 0.62   # fracción del tiempo que la moneda está en el aire
	var r := 22.0 if img_coin else 13.0     # las monedas con imagen se ven más grandes (44 px)
	var jump := 8.0 if img_coin else 16.0
	var label := ""
	var face_heads := heads
	var width := 1.0
	var pos := center
	if t < spin:
		var k := t / spin
		pos.y -= sin(k * PI) * jump                  # sube y baja
		var phase := k * TAU * 4.0                    # 4 vueltas
		width = absf(cos(phase))
		face_heads = cos(phase * 0.5) > 0.0 if heads else cos(phase * 0.5) <= 0.0
	else:
		label = "HEADS" if heads else "TAILS"
		var bounce := sin(clampf((t - spin) / 0.15, 0.0, 1.0) * PI) * 3.0
		pos.y -= bounce
	# Sombra
	var shadow_w := r * (1.0 - (center.y - pos.y) / 40.0)
	draw_set_transform(_base_off + center + Vector2(0, r + 4), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.4))
	draw_set_transform(_base_off)
	_draw_coin_face(pos, r, maxf(width, 0.08), face_heads, reason)
	# Textos
	var title := "Coin flip" if results.size() == 1 else "Coin flip %d/%d" % [i + 1, results.size()]
	match reason:
		"burn": title = "Burn"
		"sleep": title = "Asleep: does it wake up?"
		"start": title = "Opening coin flip"
	_text_center(14, title, C_LIGHT)
	var label_y := center.y + r + (3 if img_coin else 5)
	var outcome_y := label_y + 21
	if label != "":
		_text_center(label_y, label, C_ACCENT if heads else C_LIGHT, true)
		var outcome := ""
		match reason:
			"burn": outcome = "No damage" if heads else "%d damage!" % game.rules.burn_damage
			"sleep": outcome = "It woke up!" if heads else "Still asleep"
			"start": outcome = "You won the coin flip!" if coin_anim.get("won", false) else "The opponent won the coin flip."
		if outcome != "":
			_text_center(outcome_y, outcome, C_LIGHT)
	var plain: bool = coin_anim["reasons"].all(func(x): return x == "")
	if results.size() > 1 and plain:
		var shown := results.slice(0, i + (1 if label != "" else 0))
		var n_heads := shown.filter(func(h): return h).size()
		var x0 := W / 2.0 - results.size() * 5.0
		for j in results.size():
			var c := C_LINE
			if j < shown.size():
				c = C_ACCENT if results[j] else C_PANEL_DARK
			draw_circle(Vector2(x0 + j * 10 + 5, 26 if img_coin else 32), 3.0, c)
		if label != "":
			_text_center(outcome_y, "%d heads" % n_heads, C_LIGHT)


## Monedas originales. Normal: cara = estrella (dorado), cruz = anillo (plateado).
## Quemadura: moneda roja con una llamita del lado de la cruz (la cruz quema).
## Dormido: moneda azul con "zzz" del lado de la cruz (con cruz sigue dormido).
func _draw_coin_face(pos: Vector2, r: float, width: float, heads: bool, reason: String = "") -> void:
	if coin_pick >= 0 and coin_pick < _coin_sets.size():
		# La moneda de esta partida: la imagen de la cara o de la cruz, achicada a lo ancho al girar
		var tex: Texture2D = _coin_sets[coin_pick][0 if heads else 1]
		draw_set_transform(_base_off + pos, 0, Vector2(width, 1))
		draw_texture_rect(tex, Rect2(-r, -r, r * 2, r * 2), false)
		draw_set_transform(_base_off)
		return
	var base := Color("#e8b830") if heads else Color("#c8c8d0")
	var dark := Color("#a07010") if heads else Color("#80808c")
	match reason:
		"burn":
			base = Color("#f09050") if heads else Color("#d85030")
			dark = Color("#a04020")
		"sleep":
			base = Color("#a8b8f0") if heads else Color("#6070c8")
			dark = Color("#384090")
	draw_set_transform(_base_off + pos, 0, Vector2(width, 1))
	draw_circle(Vector2.ZERO, r, dark)
	draw_circle(Vector2.ZERO, r - 1.5, base)
	if width > 0.35:
		match reason:
			"burn":
				if heads:
					draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
				else:
					_draw_small_flame(Vector2(0, 1), r * 0.62)
			"sleep":
				if heads:
					draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
				else:
					var c := Color("#f0f0ff")
					draw_string(font, Vector2(-7, 4), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, c)
					draw_string(font, Vector2(-2, 1), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, c)
					draw_string(font, Vector2(2, -2), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, c)
			_:
				if heads:
					_draw_burst(Vector2.ZERO, r * 0.6, Color("#fff0a0"), 5)
				else:
					draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
	draw_set_transform(_base_off)


## Llamita simple (centrada en c, alto aproximado 2*s).
func _draw_small_flame(c: Vector2, s: float) -> void:
	var outer := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.55, -s * 0.15), c + Vector2(s * 0.6, s * 0.4),
			c + Vector2(s * 0.3, s * 0.8), c + Vector2(-s * 0.3, s * 0.8), c + Vector2(-s * 0.6, s * 0.4),
			c + Vector2(-s * 0.45, -s * 0.1), c + Vector2(-s * 0.15, s * 0.15)])
	draw_colored_polygon(outer, Color("#ffd040"))
	var inner := PackedVector2Array([c + Vector2(0, -s * 0.3), c + Vector2(s * 0.3, s * 0.35), c + Vector2(0, s * 0.7),
			c + Vector2(-s * 0.3, s * 0.35)])
	draw_colored_polygon(inner, Color("#fff8d0"))


# ===========================================================================
# Imagen de cualquier carta: la propia (sprites/) o un ícono original
# ===========================================================================

func _draw_card_image(r: Rect2, id: String, rev: bool = false) -> void:
	var sz := int(r.size.x)
	if sz < 2:
		return      # en las animaciones que achican la carta hasta desaparecer
	if rev or (mode == "duel" and reverse_ids.has(id)):
		_draw_reverse(r.grow(3), r, id)
	if sz > 12:
		sz = int(ceil(sz / 8.0)) * 8    # tamaños redondeados: no se rehace la imagen en cada cuadro de una animación
	var tex := _card_texture(id, sz)
	_round_box(r, _card_bg(id).darkened(0.45))
	if tex != null:
		draw_texture_rect(tex, r, false)
		_draw_holo(r, id, r.size.x < 20, _cosmos.get("c|%s|%d" % [id, sz], {}))
	else:
		_draw_card_icon(r.grow(-r.size.x * 0.17), id)
	_round_box(r, Color(0, 0, 0, 0), C_TEXT)


func _card_bg(id: String) -> Color:
	if CardDB.is_pokemon(id):
		var t := CardDB.types(id)
		return TYPE_COLORS.get(t[0] if not t.is_empty() else "Colorless", C_PANEL_DARK)
	if CardDB.is_basic_energy(id):
		return TYPE_COLORS.get(CardDB.basic_energy_type(id), C_PANEL_DARK)
	if CardDB.is_energy(id):
		return TYPE_COLORS["*"]
	if CardDB.is_supporter(id):
		return Color("#d08040")
	if CardDB.is_stadium(id):
		return Color("#60a060")
	if CardDB.is_pokemon_tool(id):
		return Color("#b07050")
	if CardDB.is_tm(id):
		return Color("#6080c0")
	if CardDB.is_fossil(id):
		return Color("#a09070")
	return Color("#8890b0")


## Íconos genéricos (formas simples) por tipo de carta.
func _draw_card_icon(r: Rect2, id: String) -> void:
	var p := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var light := _card_bg(id).lightened(0.45)
	if CardDB.is_pokemon(id):
		var t := CardDB.types(id)
		_draw_emblem(r, t[0] if not t.is_empty() else "Colorless", light)
	elif CardDB.is_basic_energy(id):
		# Energía básica: disco claro con el emblema del tipo adentro.
		draw_circle(p.call(0.5, 0.5), r.size.x * 0.5, C_LIGHT)
		_draw_emblem(r.grow(-r.size.x * 0.2), CardDB.basic_energy_type(id), _card_bg(id).darkened(0.1))
	elif CardDB.is_energy(id):
		# Energía especial: anillo de colores con una estrella.
		var cols := ["Fire", "Water", "Grass", "Lightning", "Psychic", "Fighting"]
		for i in cols.size():
			draw_arc(p.call(0.5, 0.5), r.size.x * 0.45, TAU * i / 6.0, TAU * (i + 1) / 6.0, 6, TYPE_COLORS[cols[i]], 3.0)
		_draw_burst(p.call(0.5, 0.5), r.size.x * 0.25, C_LIGHT, 5)
	elif CardDB.is_supporter(id):
		# Persona genérica.
		draw_circle(p.call(0.5, 0.28), r.size.x * 0.18, light)
		draw_colored_polygon(PackedVector2Array([p.call(0.18, 1.0), p.call(0.25, 0.55), p.call(0.5, 0.48),
				p.call(0.75, 0.55), p.call(0.82, 1.0)]), light)
	elif CardDB.is_stadium(id):
		# Edificio.
		draw_colored_polygon(PackedVector2Array([p.call(0.05, 0.42), p.call(0.5, 0.05), p.call(0.95, 0.42)]), light)
		draw_rect(Rect2(p.call(0.15, 0.42), r.size * Vector2(0.7, 0.55)), light)
		draw_rect(Rect2(p.call(0.42, 0.65), r.size * Vector2(0.16, 0.32)), _card_bg(id).darkened(0.45))
	elif CardDB.is_pokemon_tool(id):
		# Baya con hoja.
		draw_circle(p.call(0.5, 0.6), r.size.x * 0.36, light)
		draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.25), p.call(0.8, 0.02), p.call(0.62, 0.3)]), TYPE_COLORS["Grass"])
	elif CardDB.is_tm(id):
		# Disco.
		draw_circle(p.call(0.5, 0.5), r.size.x * 0.5, light)
		draw_circle(p.call(0.5, 0.5), r.size.x * 0.12, _card_bg(id).darkened(0.45))
		draw_arc(p.call(0.5, 0.5), r.size.x * 0.32, 0.3, 1.4, 8, _card_bg(id), 1.0)
	elif CardDB.is_fossil(id):
		# Roca con una espiral.
		draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.7), p.call(0.25, 0.2), p.call(0.7, 0.1),
				p.call(0.95, 0.5), p.call(0.8, 0.9), p.call(0.3, 0.95)]), light)
		draw_arc(p.call(0.52, 0.52), r.size.x * 0.2, 0, TAU * 0.8, 12, _card_bg(id).darkened(0.4), 1.5)
	else:
		# Objeto: bolso con manija.
		draw_arc(p.call(0.5, 0.35), r.size.x * 0.2, PI, TAU, 8, light, 2.0)
		draw_rect(Rect2(p.call(0.12, 0.35), r.size * Vector2(0.76, 0.6)), light)
		draw_rect(Rect2(p.call(0.12, 0.52), r.size * Vector2(0.76, 0.08)), _card_bg(id).darkened(0.3))


# ===========================================================================
# Animación de evolución
# ===========================================================================
# El Pokémon parpadea en blanco cada vez más rápido, con rayos de luz girando;
# un destello final y chispas. Después de cada acción se miran las evoluciones
# nuevas en game.evolve_log (cartas en mano, Rare Candy, Poké-Powers, etc.).

func _check_evolutions() -> void:
	if game.evolve_log.size() <= evo_seen:
		return
	var list := game.evolve_log.slice(evo_seen)
	evo_seen = game.evolve_log.size()
	if animations_on:
		evo_anim = {"list": list, "i": 0, "t": 0.0}


func _update_evo(delta: float) -> void:
	evo_anim["t"] += delta / EVO_TIME
	if evo_anim["t"] >= 1.0:
		evo_anim["t"] = 0.0
		evo_anim["i"] += 1
		if evo_anim["i"] >= evo_anim["list"].size():
			evo_anim = {}
			if anim.is_empty():
				ai_timer = AI_DELAY
				_rebuild_menu()


## Rectángulo en pantalla de un Pokémon en juego (Activo: su carta grande; Banca: la cartita).
func _slot_rect(player: int, slot: int) -> Rect2:
	if _dbl() and PlayerState.is_active_slot(slot):
		return _dbl_card_rect(player, 1 if slot == PlayerState.ACTIVE2 else 0)
	if slot == -1:
		return _card_rect(player)
	return _bench_rect(player, slot)


func _draw_evo() -> void:
	if evo_anim.is_empty():
		return
	var e: Dictionary = evo_anim["list"][evo_anim["i"]]
	var pl: PlayerState = game.players[e["p"]]
	var mon: PokemonInPlay = e["mon"]
	var s := pl.slot_of(mon)
	if s == -2 or (s == -1 and pl.active != mon):
		return
	var t: float = evo_anim["t"]
	var r := _slot_rect(e["p"], s)
	if s == -1:
		r = _art_rect(e["p"])
	var c := r.get_center()
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.25 * sin(minf(t, 1.0) * PI)))
	if t < EVO_FLASH:
		var k := t / EVO_FLASH
		# Parpadeo cada vez más rápido entre la forma anterior y una silueta blanca
		var box := _slot_rect(e["p"], s)
		if sin(k * k * 70.0) > 0.0:
			draw_rect(r.grow(1), Color(1, 1, 1, 0.95))
			if s != -1:
				draw_rect(box, Color(1, 1, 1, 0.95))
		# Rayos de luz girando
		for i in 8:
			var ang := TAU * i / 8.0 + k * 4.0
			var len := 10.0 + k * 22.0
			draw_line(c + Vector2(cos(ang), sin(ang)) * 6.0, c + Vector2(cos(ang), sin(ang)) * len, Color(1, 1, 0.8, 0.4 + 0.6 * k), 1.0)
	else:
		var k := (t - EVO_FLASH) / (1.0 - EVO_FLASH)
		# Destello y anillo que se expande
		if k < 0.25:
			draw_rect(Rect2(0, 0, W, BOX_Y), Color(1, 1, 1, 0.7 * (1.0 - k / 0.25)))
		draw_arc(c, 6.0 + k * 30.0, 0, TAU, 24, Color(1, 1, 0.8, 1.0 - k), 2.0)
		# Chispas
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(e["to"])
		for i in 10:
			var ang := rng.randf() * TAU
			var p := c + Vector2(cos(ang), sin(ang)) * (8.0 + k * rng.randf_range(10, 24))
			_draw_burst(p, 2.5 * (1.0 - k) + 0.5, Color("#fff4a0"), 4)


# ===========================================================================
# Marca sobre el Pokémon al que apunta la opción del menú
# ===========================================================================
# Así, si hay dos Pokémon con el mismo nombre (Activo y Banca), se ve a cuál
# va la Energía, la evolución, la Poción, etc.

## Pokémon afectados por la opción seleccionada del menú: [[jugador, casilla, rol], ...]
## rol "target" = el que recibe el efecto; "source" = de dónde sale (Energía que se mueve,
## Pokémon que se retira). Así se puede dibujar una flecha de uno a otro.
func _menu_targets() -> Array:
	if game == null or game.actor() != human or menu_items.is_empty() or cursor >= menu_items.size():
		return []
	var a: Dictionary = menu_items[cursor].get("action", {})
	if a.is_empty():
		return []
	var me := game.actor()
	var opp := 1 - me
	# Dobles: con "ctx", "el" Activo de cada uno es el segundo
	var c = a.get("ctx", [false, false])
	var my_act := PlayerState.ACTIVE2 if c[me] else -1
	var op_act := PlayerState.ACTIVE2 if c[opp] else -1
	match a["t"]:
		"energy", "evolve":
			return [[me, a["tg"], "target"]]
		"send_out":
			return [[me, a["b"], "source"], [me, PlayerState.ACTIVE2, "target"]]
		"retreat":
			return [[me, my_act, "source"], [me, a["b"], "target"]]
		"choose":
			if a.has("b"):
				return [[me, a["b"], "target"]]
			var opts := game.choice_options()
			if a["i"] >= opts.size():
				return []
			var opt: Dictionary = opts[a["i"]]
			var side: int = opp if opt.get("opp", false) else me
			if opt.has("retreat_to"):
				return [[me, -1, "source"], [me, opt["retreat_to"], "target"]]
			if opt.has("s"):
				return [[side, opt["s"], "target"]]
			if opt.has("b"):
				return [[side, opt["b"], "target"]]
		"attack":
			var out: Array = [[me, my_act, "source"]]
			var tg: int = a["tg"]
			if tg == -2 or tg == -1:
				tg = op_act
			elif tg == PlayerState.ACTIVE2 and c[opp]:
				tg = -1                    # "el otro Activo" visto desde el contexto
			out.append([opp, tg, "target"])
			return out
		"trainer", "power":
			var p: Dictionary = a["p"]
			var power: bool = a["t"] == "power"
			var name := CardDB.card_name(game.players[me].hand[a["h"]]) if not power else str(a["n"])
			var from_slot: bool = p.has("from") and typeof(p["from"]) == TYPE_INT
			if from_slot and p.has("to"):
				return [[me, p["from"], "source"], [me, p["to"], "target"]]
			if from_slot:
				# Call for Power: hacia el que usa el poder; Metal Juncture: hacia el Activo
				return [[me, p["from"], "source"], [me, a["s"] if name == "Call for Power" else -1, "target"]]
			if p.has("tg"):
				return [[opp if name == "Energy Removal 2" else me, p["tg"], "target"]]
			if p.has("mb"):
				return [[me, p["mb"], "target"]]
			if p.has("b"):
				if power:
					return [[opp, p["b"], "target"]]          # Dragon Wind
				return [[me, -1, "source"], [me, p["b"], "target"]]   # Switch
			if power:
				return [[me, a["s"], "target"]]
	return []


func _draw_target_highlight() -> void:
	if not anim.is_empty() or not evo_anim.is_empty() or not coin_anim.is_empty() or not energy_anim.is_empty() \
			or not move_anim.is_empty():
		return
	var list: Array = [[board_sel[0], board_sel[1], "target"]] if board_view else _menu_targets()
	var valid: Array = []
	for tg in list:
		if game.players[tg[0]].slot(tg[1]) != null:
			valid.append(tg)
	if valid.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(now * 7.0)
	var src_rect := Rect2()
	var dst_rect := Rect2()
	for tg in valid:
		var r := _slot_rect(tg[0], tg[1])
		var c: Color = C_ACCENT if tg[2] == "target" else C_SOURCE
		if tg[2] == "target":
			dst_rect = r
		else:
			src_rect = r
		# Brillo: relleno que late y halo de varias capas
		draw_rect(r, Color(c, 0.2 + 0.3 * pulse))
		for g in 3:
			draw_rect(r.grow(1 + g), Color(c, (0.9 - g * 0.3) * (0.6 + 0.4 * pulse)), false, 1.0)
		draw_rect(r.grow(1), Color(1, 1, 1, 0.5 * pulse), false, 1.0)
		if tg[2] == "target" and valid.size() == 1:
			# Flechita encima (o debajo, para la Banca de arriba)
			var top := r.position.y > 20
			var x := r.get_center().x
			var bounce := 1.5 * sin(now * 7.0)
			var y := (r.position.y - 3 - bounce) if top else (r.end.y + 3 + bounce)
			var d := -1.0 if top else 1.0
			var tri := PackedVector2Array([Vector2(x - 4, y + d * 5), Vector2(x + 4, y + d * 5), Vector2(x, y)])
			draw_colored_polygon(tri, C_ACCENT)
			draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), C_TEXT, 1.0)
	# Flecha animada de origen a destino
	if src_rect.size != Vector2.ZERO and dst_rect.size != Vector2.ZERO:
		# Del centro del origen al borde del destino (así no tapa el nombre)
		var a := src_rect.get_center()
		var b := _edge_point(dst_rect, a) + (a - dst_rect.get_center()).normalized()
		var dist := a.distance_to(b)
		if dist > 4.0:
			var dir := (b - a) / dist
			var bulge := Vector2(dir.y, -dir.x) * minf(14.0, dist * 0.3)
			var pts := PackedVector2Array()
			for i in 17:
				var k := i / 16.0
				pts.append(a.lerp(b, k) + bulge * sin(k * PI))
			draw_polyline(pts, Color(C_TEXT, 0.7), 3.0)
			draw_polyline(pts, Color(1, 1, 1, 0.9), 1.0)
			# Puntos que viajan por la curva
			for j in 3:
				var k := fmod(now * 0.9 + j / 3.0, 1.0)
				var p := a.lerp(b, k) + bulge * sin(k * PI)
				draw_circle(p, 1.5, C_SOURCE.lerp(C_ACCENT, k))
			var end := pts[15]
			var tip := pts[16]
			var tdir := (tip - end).normalized()
			var n := Vector2(-tdir.y, tdir.x)
			var head := PackedVector2Array([tip, tip - tdir * 5 + n * 3.0, tip - tdir * 5 - n * 3.0])
			draw_colored_polygon(head, C_ACCENT)
			draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), C_TEXT, 1.0)


# ===========================================================================
# Recorrer la mesa (tecla B): ver en detalle cualquier Pokémon en juego
# ===========================================================================
# ←/→ se mueve entre el Activo y la Banca; ↑/↓ cambia entre tu lado y el del rival.
# Abajo se ve un resumen; Z o C abre la ficha completa. Mientras está abierto, el rival espera.

func _board_input(k: int, accept: bool, back: bool, echo: bool) -> void:
	var player: int = board_sel[0]
	var slots: Array = game.players[player].slots()
	var i := slots.find(board_sel[1])
	match k:
		KEY_LEFT, KEY_RIGHT:
			# Recorrido continuo: tus Pokémon y después los del rival (y vuelta).
			var all: Array = []
			for pl in [human, 1 - human]:
				for sl in game.players[pl].slots():
					all.append([pl, sl])
			if not all.is_empty():
				var cur := 0
				for j in all.size():
					if all[j][0] == player and all[j][1] == board_sel[1]:
						cur = j
				board_sel = all[(cur + (1 if k == KEY_RIGHT else -1) + all.size()) % all.size()]
		KEY_UP, KEY_DOWN:
			var other: int = 1 - human if k == KEY_UP else human
			var os: Array = game.players[other].slots()
			if not os.is_empty():
				var want: int = board_sel[1]
				board_sel = [other, want if want in os else os[os.size() - 1]]
	if accept or (k == KEY_C and not echo):
		var all := _board_slots()
		var cur := 0
		for j in all.size():
			if all[j][0] == board_sel[0] and all[j][1] == board_sel[1]:
				cur = j
		if not all.is_empty():
			var entries: Array = []
			for sl in all:
				var pl: int = sl[0]
				var slot: int = sl[1]
				entries.append(func(): return _board_info(pl, slot))
			_open_info(entries, cur, func(j: int): board_sel = all[j])
	elif back or (k == KEY_B and not echo):
		board_view = false


## Todos los lugares con Pokémon: los tuyos y después los del rival (el orden de ◀▶).
func _board_slots() -> Array:
	var all: Array = []
	for pl in [human, 1 - human]:
		for sl in game.players[pl].slots():
			all.append([pl, sl])
	return all


func _stadium_info() -> Array:
	if game.stadium == "":
		return ["(There's no Stadium in play anymore.)"]
	var lines: Array = [{"section": "STADIUM", "bg": C_STADIUM_BG}]
	lines.append_array(_card_lines(game.stadium, null))
	return lines


func _board_info(pl: int, slot: int) -> Array:
	var mon: PokemonInPlay = game.players[pl].slot(slot)
	if mon == null:
		return ["(There's no Pokémon here anymore.)"]
	var mine: bool = pl == human
	info_attach = [pl, slot]
	var lines: Array = [{"section": ("YOUR " if mine else "FOE ") + _place_name(slot).to_upper(),
			"bg": C_MINE_BG if mine else C_OPP_BG}]
	var card := _card_lines(mon.top(), mon)
	var bi := -1
	for i in card.size():
		if card[i] is Dictionary and card[i].has("body"):
			bi = i
			break
	if bi >= 0:
		var extra: Array = []
		for r in _effect_reasons(game.players[pl], mon, slot):
			if str(r[0]).begins_with("est_poder"):     # el Poké-Power va sin ícono, solo el texto
				extra.append({"row": [["text", r[1], REASON_COL.get(r[0], C_TEXT)]]})
			else:
				extra.append({"row": [["fx", r[0]], ["text", r[1], REASON_COL.get(r[0], C_TEXT)]]})
		for j in extra.size():
			card.insert(bi + 3 + j, extra[j])     # después de "Damage · Energy" y las energías
	lines.append_array(card)
	return lines


# ===========================================================================
# Ficha de carta: desplazarse hasta el final del texto y ◀▶ para las vecinas
# ===========================================================================

## Abre la ficha. entries: una Callable por carta vecina (devuelve sus líneas); i: la actual;
## sync: qué hacer al pasar a otra (mover el cursor de la mano, la mesa o el editor).
func _open_info(entries: Array, i: int, sync: Callable = Callable()) -> void:
	info_nav = entries
	info_nav_i = clampi(i, 0, maxi(0, entries.size() - 1))
	info_nav_sync = sync
	info_attach = []
	info_lines = entries[info_nav_i].call() if not entries.is_empty() else []
	info_offset = 0
	info_more = false


## C en la pantalla principal: la ficha de lo que marca el cursor. En el menú principal,
## los dos Activos (y el Estadio), y con ◀▶ cada Pokémon en juego.
func _open_cursor_info() -> void:
	if menu_items.is_empty() or menu_level == "root" and game.phase == "main":
		# Una página por carta, todas con el mismo formato que en el editor de mazos:
		# tu Activo, el del rival, el Estadio y después las Bancas
		var entries: Array = [func(): return [{"split": true}]]    # primero, los dos lados a la vez
		var firsts: Array = []
		for pl in [human, 1 - human]:
			if game.players[pl].active != null:
				firsts.append([pl, -1])
				var p0: int = pl
				entries.append(func(): return _board_info(p0, -1))
		if game.stadium != "":
			entries.append(func(): return _stadium_info())
		for sl in _board_slots():
			if not sl in firsts:
				var pl2: int = sl[0]
				var slot: int = sl[1]
				entries.append(func(): return _board_info(pl2, slot))
		_open_info(entries, 0)
		return
	# En una lista (mano, ataques, elegir): las vecinas son las otras opciones de la lista
	var entries: Array = []
	var saved := cursor
	var start := 0
	for j in menu_items.size():
		cursor = j
		if _info_for_cursor().is_empty():
			continue
		if j == saved:
			start = entries.size()
		var jj := j
		entries.append(func():
			var keep := cursor
			cursor = jj
			var lines := _info_for_cursor()
			cursor = keep
			return lines)
	cursor = saved
	if entries.is_empty():
		info_lines = []
		return
	var idx_map: Array = []
	for j in menu_items.size():
		cursor = j
		if not _info_for_cursor().is_empty():
			idx_map.append(j)
	cursor = saved
	_open_info(entries, start, func(n: int): cursor = idx_map[n])


func _info_input(k: int) -> void:
	match k:
		KEY_DOWN:
			if info_more:
				# En la ficha de una carta solo se desplaza el panel del medio
				# (en la vista con varias cartas, como los dos Activos y el Estadio, baja hasta el final)
				var card := _info_card_start() >= 0
				var base := _info_find("body") + 1 if card else 0
				var fi := _info_find("foot") if card else -1
				var last := (fi if fi >= 0 else info_lines.size()) - base - 1
				info_offset = mini(info_offset + 1, maxi(0, last))
				while info_offset < last and _is_gap(info_lines[base + info_offset]):
					info_offset += 1     # los espacios entre ataques no cuentan como renglón
				snd.play("move")
		KEY_UP:
			if info_offset > 0:
				var base := _info_find("body") + 1 if _info_card_start() >= 0 else 0
				info_offset -= 1
				while info_offset > 0 and _is_gap(info_lines[base + info_offset]):
					info_offset -= 1
				snd.play("move")
		KEY_LEFT, KEY_RIGHT:
			if info_nav.size() > 1:
				info_nav_i = (info_nav_i + (1 if k == KEY_RIGHT else -1) + info_nav.size()) % info_nav.size()
				info_attach = []
				info_lines = info_nav[info_nav_i].call()
				info_offset = 0
				info_more = false
				if info_nav_sync.is_valid():
					info_nav_sync.call(info_nav_i)
				snd.play("move")


## Teclas con la ficha de una carta abierta (y la galería encima, si está).
func _info_keys(k: int, accept: bool, back: bool, echo: bool) -> void:
	if gallery_id != "":
		if sq_edit and _sq_edit_keys(k, accept, back):
			return
		if k == KEY_S and not echo and OS.has_feature("editor"):
			sq_edit = true
			snd.play("ok")
			return
		if (accept or back or k == KEY_C) and not echo:
			_close_gallery()
			snd.play("back")
		return
	if k == KEY_C and not echo and _info_img() != "":
		_open_gallery(_info_img())
		snd.play("ok")
		return
	# Z en un Pokémon en juego: sus cartas unidas (Energías, Herramienta, MT)
	if accept and not echo and info_stack.is_empty() and not _info_attached().is_empty():
		_open_attached()
		snd.play("ok")
		return
	if (accept or back) and not echo and not info_stack.is_empty():
		var prev: Dictionary = info_stack.pop_back()     # vuelve a la ficha del Pokémon
		_open_info(prev["nav"], prev["i"], prev["sync"])
		info_offset = prev["offset"]
		snd.play("back")
		return
	if (accept or back or k == KEY_C) and not echo:
		info_lines = []
		info_stack.clear()
		snd.play("back")
	else:
		_info_input(k)


## Las cartas unidas al Pokémon de la ficha (cada una una vez, con cuántas hay).
func _info_attached() -> Array:
	if info_attach.is_empty() or game == null:
		return []
	var mon: PokemonInPlay = game.players[info_attach[0]].slot(info_attach[1])
	if mon == null:
		return []
	var out: Array = []          # [id, cantidad]
	for id in mon.energy + ([mon.tool] if mon.tool != "" else []) + ([mon.tm] if mon.tm != "" else []):
		var found := false
		for o in out:
			if o[0] == id:
				o[1] += 1
				found = true
		if not found:
			out.append([id, 1])
	return out


func _open_attached() -> void:
	var mon: PokemonInPlay = game.players[info_attach[0]].slot(info_attach[1])
	var mine: bool = info_attach[0] == human
	var cards := _info_attached()
	info_stack.append({"nav": info_nav, "i": info_nav_i, "sync": info_nav_sync, "offset": info_offset})
	var entries: Array = []
	for c in cards:
		var cid: String = c[0]
		var n: int = c[1]
		var head := "ON %s" % mon.display_name().to_upper() + (" · ×%d" % n if n > 1 else "")
		entries.append(func():
			var lines: Array = [{"section": head, "bg": C_MINE_BG if mine else C_OPP_BG}]
			lines.append_array(_card_lines(cid, null))
			return lines)
	_open_info(entries, 0)


# ===========================================================================
# Arte completo: banner en la ficha y vista de galería
# ===========================================================================

## El arte entero de la carta, apaisado y con colores de GBA, para arriba de la ficha.
## null si todavía no está (lo pide para la próxima) o si es una Energía.
func _art_banner(id: String) -> Texture2D:
	if CardDB.get_card(id).get("supertype", "") == "Energy":
		return null
	var key := id + "|banner"
	if _hd_tex.has(key):
		return _hd_tex[key]
	var src := arte.image(id)
	if src == null:
		arte.want(id)
		return null
	var img := _cover(src, BANNER_W, BANNER_H)
	for y in BANNER_H:
		for x in BANNER_W:
			var c := img.get_pixel(x, y)
			var v := Color.from_hsv(c.h, minf(1.0, c.s * 1.25), minf(1.0, c.v * 1.08))
			img.set_pixel(x, y, Color(v.r, v.g, v.b, 1.0))
	_reduce_palette(img, 32)
	# marco fino oscuro, como las ventanas de imagen de la mesa
	for x in BANNER_W:
		img.set_pixel(x, 0, Color("#384050"))
		img.set_pixel(x, BANNER_H - 1, Color("#384050"))
	for y in BANNER_H:
		img.set_pixel(0, y, Color("#384050"))
		img.set_pixel(BANNER_W - 1, y, Color("#384050"))
	var tex := ImageTexture.create_from_image(img)
	_hd_tex[key] = tex
	return tex


## La imagen recortada al centro para cubrir w x h sin deformar.
func _cover(src: Image, w: int, h: int) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var sc := maxf(float(w) / img.get_width(), float(h) / img.get_height())
	var cw := mini(img.get_width(), int(ceil(w / sc)))
	var ch := mini(img.get_height(), int(ceil(h / sc)))
	img = img.get_region(Rect2i((img.get_width() - cw) / 2, (img.get_height() - ch) / 2, cw, ch))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return img


## La galería: el arte grande, en píxeles de GBA como el resto del juego.
func _open_gallery(id: String) -> void:
	gallery_id = id
	arte.want(id)


func _close_gallery() -> void:
	gallery_id = ""
	sq_edit = false


## Cuántos píxeles de pantalla mide cada píxel del juego (escala entera).
func _screen_scale() -> int:
	var ws := get_window().size
	return maxi(1, int(minf(ws.x / float(W), ws.y / float(H))))


## Dónde va el arte en la galería y a qué tamaño (en píxeles del juego). Se agranda en
## múltiplos enteros de píxeles de pantalla, para que se vea nítido y nunca borroso.
func _gallery_rect(img: Image) -> Rect2:
	# Estilo GBA: el arte se reduce a píxeles de la pantalla del juego (240x160), que
	# después se agrandan como todo lo demás. Una imagen chica no se estira de más.
	var f := minf(1.0, minf(224.0 / img.get_width(), 126.0 / img.get_height()))
	var sz := (Vector2(img.get_width(), img.get_height()) * f).floor()
	return Rect2(Vector2(round((W - sz.x) / 2.0), round(4 + (126.0 - sz.y) / 2.0)), sz)


## El arte a la resolución de la pantalla (cada píxel de la imagen, un cuadrado entero de
## píxeles reales).
func _gallery_tex(id: String, img: Image, r: Rect2) -> Texture2D:
	var key := "%s|gal" % id
	if not _hd_tex.has(key):
		var small := img.duplicate() as Image
		small.resize(int(r.size.x), int(r.size.y), Image.INTERPOLATE_LANCZOS)
		_hd_tex[key] = ImageTexture.create_from_image(small)
	return _hd_tex[key]


## "EX Ruby & Sapphire · 3/109"
func _set_line(id: String) -> String:
	var c := CardDB.get_card(id)
	var set_id := id.split("-")[0]
	var s: String = ("EX " if set_id.begins_with("ex") else "") + str(c.get("set", ""))
	var n := str(c.get("number", ""))
	if SET_TOTAL.has(set_id):
		n += "/%d" % SET_TOTAL[set_id]
	return s + " · " + n


func _draw_gallery() -> void:
	var id := gallery_id
	draw_rect(Rect2(0, 0, W, H), Color("#101018"))
	var img := arte.image(id)
	if img != null:
		var r := _gallery_rect(img)
		draw_rect(r.grow(1), Color("#d8d8e0"), false, 1.0)
		draw_texture(_gallery_tex(id, img, r), r.position)
		if sq_edit:
			_draw_sq_edit(id, img, r)
			return
	else:
		var box := Rect2(W / 2.0 - 32, 30, 64, 64)
		_draw_card_image(box, id)
		var msg := "Loading art..." if arte.state(id) == "loading" else "Couldn't download the art."
		_text(Vector2(round((W - _text_w(msg)) / 2.0), 100), msg, Color("#a0a8b8"))
	var c := CardDB.get_card(id)
	var y := 134.0
	_text_fit(Vector2(8, y), _set_line(id), Color("#a0a8b8"), W - 16)
	var artist := str(c.get("artist", ""))
	if artist != "":
		_text(Vector2(8, y + 12), "Illus. " + artist, Color("#e8c060"))
	var hint := "X back"
	_text(Vector2(W - 8 - _text_w(hint), y + 12), hint, Color("#687080"))


## La carta cuya imagen muestra la ficha abierta ("" si no tiene).
func _info_img() -> String:
	for line in info_lines:
		if line is Dictionary and line.get("img", "") != "":
			return line["img"]
	return ""


func _is_gap(line: Variant) -> bool:
	return line is Dictionary and line.has("gap")


func _place_name(slot: int) -> String:
	return "Active" if slot == -1 else "Bench %d" % (slot + 1)


## "Energías: Fire ×2, Rainbow · Herramienta: ... · MT: ..."
func _attached_text(p: PokemonInPlay) -> String:
	var counts := {}
	var order: Array = []
	for e in p.energy:
		var n := CardDB.card_name(e).replace(" Energy", "")
		if not counts.has(n):
			order.append(n)
		counts[n] = counts.get(n, 0) + 1
	var parts: Array = []
	for n in order:
		parts.append(n + (" ×%d" % counts[n] if counts[n] > 1 else ""))
	var s := "Energy: " + (", ".join(parts) if not parts.is_empty() else "none")
	if p.tool != "":
		s += " · Tool: " + CardDB.card_name(p.tool)
	if p.tm != "":
		s += " · TM: " + CardDB.card_name(p.tm)
	return s


func _draw_board_details(box: Rect2, x: float, y: float) -> void:
	var mine: bool = board_sel[0] == human
	var mon: PokemonInPlay = game.players[board_sel[0]].slot(board_sel[1])
	var w := box.size.x - 18 - MENU_IMG - 6
	if mon == null:
		_text(Vector2(x, y), "There's no Pokémon here.", C_TEXT)
	else:
		_draw_card_image(Rect2(box.end.x - 4 - MENU_IMG, box.position.y + 4, MENU_IMG, MENU_IMG), mon.top())
		_text_scroll(Vector2(x, y), "%s  %d/%d HP" % [mon.display_name(), maxi(0, mon.hp_left()), mon.max_hp()], C_TEXT, w, "b0" + str(board_sel))
		var where := ("Yours · " if mine else "Opponent's · ") + _place_name(board_sel[1])
		var st := mon.conditions_text()
		_text_scroll(Vector2(x, y + LINE), where + ("  " + st if st != "" else ""), C_TEXT, w, "b1" + str(board_sel))
	_text_scroll(Vector2(x, y + LINE * 2), "◀▶ browse · ▲ opponent ▼ yours · Z card · X close", C_DIM, w, "bkeys")


# ===========================================================================
# Texto largo: recorte y desplazamiento
# ===========================================================================

func _text_w(s: String) -> float:
	if s.contains(ICON_MARK):
		var n := s.count(ICON_MARK)
		var plain := s
		for k in TYPE_MARK:
			plain = plain.replace(ICON_MARK + k, "")
		return font.get_string_size(_px(plain), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + n * ICON_W
	return font.get_string_size(_px(s), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


## Recorta el texto para que entre en el ancho (con ".." al final si no entra).
func _text_fit(pos: Vector2, s: String, color: Color, width: float) -> void:
	if _text_w(s) <= width:
		_text(pos, s, color)
		return
	var t := s
	while t.length() > 1 and _text_w(t + "..") > width:
		t = t.left(-1)
	_text(pos, t.strip_edges() + "..", color)


## Si el texto no entra, se desplaza letra por letra (pausa al principio y al final).
func _text_scroll(pos: Vector2, s: String, color: Color, width: float, key: String) -> void:
	if _text_w(s) <= width:
		_text(pos, s, color)
		return
	var max_off := 0
	while max_off < s.length() - 1 and _text_w(s.substr(max_off)) > width:
		max_off += 1
	var now := Time.get_ticks_msec() / 1000.0
	if not marquee_t0.has(key) or marquee_t0[key][1] != s:
		if marquee_t0.size() > 40:
			marquee_t0.clear()
		marquee_t0[key] = [now, s]
	var cycle := MARQUEE_HOLD * 2 + max_off * MARQUEE_STEP
	var t := fmod(now - marquee_t0[key][0], cycle)
	var off := clampi(int((t - MARQUEE_HOLD) / MARQUEE_STEP), 0, max_off)
	var sub := s.substr(off)
	while sub.length() > 1 and _text_w(sub) > width:
		sub = sub.left(-1)
	_text(pos, sub, color)


# ===========================================================================
# Animación al unir una Energía
# ===========================================================================
# Se compara qué Energías tenía cada Pokémon antes y después de cada acción, así
# funciona igual con la Energía de la mano, Poké-Powers, Entrenadores o ataques.
# La Energía vuela desde la mano (o desde el Pokémon que la cedió) y al llegar
# hace un destello del color de su tipo.

func _energy_snapshot() -> Dictionary:
	var snap := {}
	for pl in game.players:
		for m in pl.all_in_play():
			snap[m] = m.energy.duplicate()
	# Descartes (para saber si una Energía sale de la pila de descarte)
	snap["_discard"] = [game.players[0].discard.duplicate(), game.players[1].discard.duplicate()]
	return snap


func _discard_spot(player: int) -> Vector2:
	return _counters_pos(player) + Vector2(31, 17)


func _check_energy(before: Dictionary) -> void:
	if not animations_on:
		return
	var discards: Array = before.get("_discard", [[], []])
	# Energías que dejó cada Pokémon (para saber de dónde salen las que se mueven)
	var lost: Array = []
	for m in before:
		if not (m is PokemonInPlay):
			continue
		var now: Array = m.energy.duplicate()
		for e in before[m]:
			if e in now:
				now.erase(e)
			else:
				lost.append([m, e])
	# Cuántas de cada Energía salieron del descarte de cada jugador
	var from_discard := [{}, {}]
	for qi in 2:
		var cur: Array = game.players[qi].discard.duplicate()
		for e in discards[qi]:
			if e in cur:
				cur.erase(e)
			elif CardDB.is_energy(e):
				from_discard[qi][e] = from_discard[qi].get(e, 0) + 1
	for pi in game.players.size():
		var pl: PlayerState = game.players[pi]
		for m in pl.all_in_play():
			var old: Array = before.get(m, []).duplicate()
			for e in m.energy:
				if e in old:
					old.erase(e)
					continue
				var from := Vector2(W / 2.0, H - 14) if pi == human else Vector2(W - 30, 4)
				var src_kind := "hand"
				var moved := false
				for l in lost:
					if l[1] == e:
						var src: PokemonInPlay = l[0]
						for qi in game.players.size():
							if src in game.players[qi].all_in_play():
								from = _slot_rect(qi, game.players[qi].slot_of(src)).get_center()
						lost.erase(l)
						moved = true
						src_kind = "mon"
						break
				if not moved and from_discard[pi].get(e, 0) > 0:
					from_discard[pi][e] -= 1
					from = _discard_spot(pi)
					src_kind = "discard"
				energy_anim.append({"p": pi, "mon": m, "id": e, "from": from, "src": src_kind, "t": 0.0})


func _pending_units(m: PokemonInPlay) -> int:
	var n := 0
	for ea in energy_anim:
		if ea["mon"] == m:
			n += Energy.units_of_card(ea["id"], m).size()
	return n


func _update_energy(delta: float) -> void:
	var ea: Dictionary = energy_anim[0]
	ea["t"] += delta / ENERGY_TIME
	if ea["t"] >= 1.0:
		energy_anim.pop_front()
		if energy_anim.is_empty():
			ai_timer = AI_DELAY
			_rebuild_menu()


func _energy_color(id: String, t: float) -> Color:
	var name := CardDB.card_name(id)
	if "Rainbow" in name or "Multi" in name:
		return Color.from_hsv(fmod(t * 2.0, 1.0), 0.7, 1.0)
	return _card_chip_color(id)


func _draw_energy_anim() -> void:
	if energy_anim.is_empty() or not anim.is_empty():
		return
	var ea: Dictionary = energy_anim[0]
	var pl: PlayerState = game.players[ea["p"]]
	var mon: PokemonInPlay = ea["mon"]
	var slot := -1 if pl.active == mon else pl.slot_of(mon)
	if not pl.all_in_play().has(mon):
		return
	var r := _slot_rect(ea["p"], slot)
	var to := r.get_center()
	var t: float = ea["t"]
	var c := _energy_color(ea["id"], t)
	var units := Energy.units_of_card(ea["id"])
	var etype: String = "*" if units.is_empty() or units[0].size() != 1 else str(units[0][0])
	const FLY := 0.55
	if ea.get("src", "") == "discard":
		# Pilita de descarte de donde sale la Energía
		var fa := clampf(1.0 - (t - FLY) / 0.3, 0.0, 1.0) if t > FLY else 1.0
		var o: Vector2 = ea["from"]
		for i in 3:
			var pr := Rect2(o - Vector2(6, 8) + Vector2(i, -i), Vector2(12, 16))
			draw_rect(pr, Color(C_PANEL_DARK.darkened(0.15 * (2 - i)), fa))
			draw_rect(pr, Color(C_TEXT, fa), false)
	if t < FLY:
		# Vuelo en arco con estela
		var k := t / FLY
		k = k * k * (3.0 - 2.0 * k)
		for j in range(5, -1, -1):
			var kk := maxf(0.0, k - j * 0.05)
			var p: Vector2 = ea["from"].lerp(to, kk) + Vector2(0, -sin(kk * PI) * 26.0)
			var rad := 5.0 - j * 0.7
			if j == 0:                 # el ícono del tipo (tus círculos de Energía)
				_draw_energy_icon(p.round(), 12, etype)
			else:
				draw_circle(p, rad, Color(c, 0.5 - j * 0.07))
	else:
		# Llegada: brillo en el Pokémon, anillo y chispas
		var k := (t - FLY) / (1.0 - FLY)
		var a := 1.0 - k
		draw_rect(r, Color(c, 0.6 * a))
		draw_rect(r.grow(1), Color(c.lightened(0.4), a), false, 2.0)
		draw_arc(to, 5.0 + k * 20.0, 0, TAU, 24, Color(C_TEXT, a), 3.0)
		draw_arc(to, 5.0 + k * 20.0, 0, TAU, 24, Color(c.lightened(0.3), a), 1.5)
		# Tus destellos salen del lugar donde entró la Energía
		for i in 6:
			var ang := TAU * i / 6.0 + 0.3
			var p := to + Vector2(cos(ang), sin(ang)) * (6.0 + k * 18.0)
			if SpecialFX.has_fx("estrellas"):
				SpecialFX.fx_draw(self, "estrellas", 1, p, 0.3 + 0.25 * sin(k * PI), a, k * 2.0, false, c.lightened(0.5))
			else:
				var sz := 2.5 if i % 2 == 0 else 1.5
				draw_line(p - Vector2(sz, 0), p + Vector2(sz, 0), Color(1, 1, 1, a), 1.0)
				draw_line(p - Vector2(0, sz), p + Vector2(0, sz), Color(1, 1, 1, a), 1.0)
		# El ícono queda un instante en el centro, crece y se apaga
		if k < 0.6:
			var ik := k / 0.6
			var tex := _energy_texture(etype, 16)
			var d := 12.0 + ik * 6.0
			if tex != null:
				draw_texture_rect(tex, Rect2(to - Vector2(d, d) / 2.0, Vector2(d, d)), false, Color(1, 1, 1, 1.0 - ik))
			else:
				draw_circle(to, d / 2.0, Color(c, 1.0 - ik))


# ===========================================================================
# Animación al tomar un Premio
# ===========================================================================
# Una estrella grande aparece girando en el centro, con rayos y chispas, y delante
# la carta del Premio se da vuelta. Los Premios del rival se ven boca abajo.

func _prize_showing() -> bool:
	return not prize_anim.is_empty() and anim.is_empty() and energy_anim.is_empty() \
			and coin_anim.is_empty() and evo_anim.is_empty() and ko_anim.is_empty() and check_anim.is_empty() and move_anim.is_empty()


func _update_prize(delta: float) -> void:
	if prize_anim[0].get("choose", false):
		if _prize_pile_size(prize_anim[0]["p"]) <= 1:
			_pick_prize(0)        # queda uno solo: no hay nada que elegir
		return
	prize_anim[0]["t"] += delta / PRIZE_TIME
	if prize_anim[0]["t"] >= 1.0:
		prize_anim.pop_front()
		marquee_t0.erase("prize")
		if prize_anim.is_empty():
			ai_timer = AI_DELAY
			_rebuild_menu()


func _draw_star(c: Vector2, r: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := rot + TAU * i / 10.0 - PI / 2.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, col)


func _draw_prize() -> void:
	if not _prize_showing():
		return
	var pz: Dictionary = prize_anim[0]
	if pz.get("choose", false):
		_draw_prize_choice(pz)
		return
	var t: float = pz["t"]
	var mine: bool = pz["p"] == human
	var fade_in := clampf(t / 0.12, 0.0, 1.0)
	var fade_out := clampf((1.0 - t) / 0.12, 0.0, 1.0)
	var a := minf(fade_in, fade_out)
	var center := Vector2(W / 2.0, 56)
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.45 * a))
	# Estrella: aparece con rebote y gira despacio
	var k := clampf(t / 0.22, 0.0, 1.0)
	var pop := 1.0 + 2.7 * pow(k - 1.0, 3) + 1.7 * pow(k - 1.0, 2)   # ease-out-back
	var rot := t * 1.6
	var sr := 48.0 * pop * fade_out
	# Rayos detrás
	for i in 12:
		var ang := rot * 0.5 + TAU * i / 12.0
		var len := sr * (1.15 + 0.15 * sin(t * 30.0 + i))
		draw_line(center + Vector2(cos(ang), sin(ang)) * sr * 0.5, center + Vector2(cos(ang), sin(ang)) * len,
				Color(1, 0.95, 0.6, 0.55 * a), 2.0)
	_draw_star(center + Vector2(1, 2), sr, rot, Color(0, 0, 0, 0.35 * a))
	_draw_star(center, sr, rot, Color(C_TEXT, a))
	_draw_star(center, sr - 3, rot, Color(C_ACCENT, a))
	_draw_star(center + Vector2(-2, -3), (sr - 3) * 0.55, rot, Color(1, 0.97, 0.7, a))
	# Chispas que giran alrededor
	for i in 6:
		var ang := -rot * 1.3 + TAU * i / 6.0
		var p := center + Vector2(cos(ang), sin(ang)) * (sr + 8.0)
		var s := 2.0 + sin(t * 25.0 + i * 2.0)
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 1, a))
		draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 1, a))
	# Carta delante: entra desde abajo y se da vuelta
	var ck := clampf((t - 0.08) / 0.2, 0.0, 1.0)
	ck = ck * ck * (3.0 - 2.0 * ck)
	var bob := sin(t * 9.0) * 1.5
	var cc := center + Vector2(0, (1.0 - ck) * 70.0 + bob)
	if pz.has("from"):
		cc = (pz["from"] as Vector2).lerp(center, ck) + Vector2(0, bob)
	var flip := clampf((t - 0.22) / 0.16, 0.0, 1.0) if mine else 0.0
	var sx := absf(cos(flip * PI))
	var face := mine and flip >= 0.5
	var cw := 40.0 * sx
	var card := Rect2(cc - Vector2(cw / 2.0, 27), Vector2(cw, 54))
	if cw < 1.0:
		return
	draw_rect(Rect2(card.position + Vector2(2, 2), card.size), Color(0, 0, 0, 0.4 * a))
	if face:
		draw_rect(card, Color(C_PANEL, a))
		draw_rect(card, Color(C_TEXT, a), false)
		var img := Rect2(card.position + Vector2(2 * sx, 3), Vector2(36 * sx, 36))
		_draw_card_image(img, pz["id"])
		draw_rect(Rect2(card.position + Vector2(3 * sx, 42), Vector2(34 * sx, 2)), Color(_card_chip_color(pz["id"]), a))
	else:
		_draw_card_back(card, a)


## Punto del borde de r en dirección a "toward" (para que las flechas no tapen las cartas).
func _edge_point(r: Rect2, toward: Vector2) -> Vector2:
	var c := r.get_center()
	var p := c
	for i in 40:
		var q := c.lerp(toward, i / 40.0)
		if not r.grow(1).has_point(q):
			return q
		p = q
	return p


var _base_off := Vector2.ZERO        # desplazamiento de todo lo que se dibuja (ventanas que entran, temblores)
const SLIDE_TIME := 0.13             # lo que tarda una ventana en entrar o salir
var _slides := {}                    # ventana -> {"t", "open"}: ficha, mano, registro
var _info_ghost: Array = []          # la ficha que se acaba de cerrar (sale deslizándose)
var _info_ghost_t := -1.0
var _last_info: Array = []


## Avanza la animación de una ventana; devuelve cuánto le falta entrar (0 = del todo adentro).
func _slide_step(key: String, open: bool, delta: float) -> void:
	var sl: Dictionary = _slides.get(key, {"t": 1.0, "open": false})
	if open and not sl["open"]:
		sl = {"t": 0.0, "open": true}
	elif not open:
		sl = {"t": 1.0, "open": false}
	else:
		sl["t"] = minf(1.0, sl["t"] + minf(delta, 1.0 / 30.0) / SLIDE_TIME)    # un cuadro lento no la saltea
	_slides[key] = sl


func _slide_off(key: String) -> float:
	var sl: Dictionary = _slides.get(key, {"t": 1.0})
	var k: float = sl["t"]
	return 1.0 - (1.0 - pow(1.0 - k, 3))     # 1 -> 0, frenando al final


## Dibuja una ventana corrida hacia abajo (dy píxeles).
func _draw_slid(dy: float, f: Callable) -> void:
	if dy <= 0.5:
		f.call()
		return
	_base_off = Vector2(0, roundf(dy))
	draw_set_transform(_base_off)
	f.call()
	_base_off = Vector2.ZERO
	draw_set_transform(Vector2.ZERO)
var _back_levels: Array = []        # el dorso de mundo/propios/dorso_carta.png, en varios tamaños
var _back_loaded := false


## Carga el dorso (si está) y prepara copias cada vez más chicas, achicadas con buena
## calidad, para dibujarlo chiquito sin que se vea pixelado.
func _load_back() -> void:
	_back_loaded = true
	for dir_path in ["res://mundo/propios", "user://mundo/propios"]:
		var p := "%s/dorso_carta.png" % dir_path
		if not ImgLoad.exists(p):
			continue
		var img := ImgLoad.load(p)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGBA8)
		while true:
			_back_levels.append(ImageTexture.create_from_image(img))
			if img.get_width() <= 8:
				break
			img = img.duplicate()
			img.resize(maxi(1, img.get_width() / 2), maxi(1, img.get_height() / 2), Image.INTERPOLATE_LANCZOS)
		return


## Dorso de carta: la imagen de mundo/propios/dorso_carta.png (tools/armar_dorso.py) o, si no
## está, uno genérico azul con borde claro y una estrellita.
func _draw_card_back(card: Rect2, a: float = 1.0) -> void:
	if not _back_loaded:
		_load_back()
	if not _back_levels.is_empty():
		var tex: Texture2D = _back_levels[0]
		for lv in _back_levels:          # la copia más chica que no quede menor que la carta
			if (lv as Texture2D).get_width() >= absf(card.size.x):
				tex = lv
		draw_texture_rect(tex, card, false, Color(1, 1, 1, a))
		return
	draw_rect(card, Color("#2850a0", a))
	if card.size.x > 6:
		draw_rect(card.grow(-2), Color("#4070c8", a), false)
	draw_rect(card, Color(C_TEXT, a), false)
	var r := minf(card.size.x, card.size.y) * 0.3
	if r >= 2.0:
		_draw_star(card.get_center(), r, 0.0, Color(C_ACCENT, a))


# ===========================================================================
# Barajar y robar
# ===========================================================================
# El motor anota en game.deck_log cada barajada y cada robo. Se muestra un mazo
# chiquito al costado del Activo: al barajar, las dos mitades se separan y se
# intercalan; al robar, las cartas vuelan del mazo a la mano (las tuyas se dan
# vuelta en el camino; las del rival llegan boca abajo).

const DECK_CARD := Vector2(14, 19)


func _deck_spot(player: int) -> Vector2:
	return _counters_pos(player) + Vector2(31, 3)


func _hand_spot(player: int) -> Vector2:
	return Vector2(96, 116) if player == human else Vector2(150, -8)


func _draw_duration(n: int) -> float:
	return (n - 1) * _draw_stagger(n) + DRAW_FLY + 0.15


func _draw_stagger(n: int) -> float:
	return minf(0.14, 0.7 / maxf(1.0, n))


func _deck_showing() -> bool:
	return not deck_anim.is_empty() and anim.is_empty() and check_anim.is_empty() and energy_anim.is_empty() \
			and coin_anim.is_empty() and evo_anim.is_empty() and prize_anim.is_empty() and move_anim.is_empty()


func _update_deck(delta: float) -> void:
	deck_anim[0]["t"] += delta
	if deck_anim[0]["t"] >= deck_anim[0]["dur"]:
		deck_anim.pop_front()
		marquee_t0.erase("deck")
		if deck_anim.is_empty():
			ai_timer = AI_DELAY
			_rebuild_menu()


func _draw_deck_text(x: float, y: float, w: float) -> void:
	var d: Dictionary = deck_anim[0]
	var mine: bool = d["p"] == human
	if d["k"] == "shuffle":
		_text(Vector2(x, y), "Shuffling your deck..." if mine else "The opponent shuffles their deck...", C_TEXT)
		return
	var n: int = d["ids"].size()
	var what := "1 card" if n == 1 else "%d cards" % n
	var names: Array = []
	for id in d["ids"]:
		names.append(CardDB.card_name(id))
	if d["k"] == "recover":
		_text(Vector2(x, y), ("You get back " if mine else "The opponent gets back ") + what, C_TEXT)
		_text(Vector2(x, y + LINE), "from the discard pile:", C_TEXT)
		_text_scroll(Vector2(x, y + LINE * 2), ", ".join(names), C_DIM, w, "deck")
		return
	_text(Vector2(x, y), ("You draw " if mine else "The opponent draws ") + what + ".", C_TEXT)
	if mine:
		_text_scroll(Vector2(x, y + LINE), ", ".join(names), C_DIM, w, "deck")


func _draw_deck_anim() -> void:
	if not _deck_showing():
		return
	var d: Dictionary = deck_anim[0]
	var t: float = d["t"]
	var dur: float = d["dur"]
	var recover: bool = d["k"] == "recover"
	var spot := _discard_spot(d["p"]) if recover else _deck_spot(d["p"])
	var fade := clampf(minf(t, dur - t) / 0.1, 0.0, 1.0)
	if d["k"] == "shuffle":
		_draw_shuffle(spot, t / dur, fade)
		return
	if recover:
		# Pila de descarte (boca arriba) de donde salen las cartas
		for i in 3:
			var pr := Rect2(spot - DECK_CARD / 2 + Vector2(i, -i), DECK_CARD)
			draw_rect(pr, Color(C_INK, fade))
			draw_rect(pr.grow(-1), Color(Color("#a8a8b0").darkened(0.12 * (2 - i)), fade))
	else:
		# Mazo de donde salen las cartas
		for i in 3:
			_draw_card_back(Rect2(spot - DECK_CARD / 2 + Vector2(i, -i), DECK_CARD), fade)
	var ids: Array = d["ids"]
	if d.get("closeup", false):
		_draw_closeup(d, spot)
		return
	var stagger := _draw_stagger(ids.size())
	var to := _hand_spot(d["p"])
	for i in ids.size():
		var k := (t - i * stagger) / DRAW_FLY
		if k <= 0.0 or k >= 1.0:
			continue
		var e := k * k * (3.0 - 2.0 * k)
		var from := spot + Vector2(2, -2)
		var p := from.lerp(to + Vector2((i - ids.size() / 2.0) * 6.0, 0), e) + Vector2(0, -sin(e * PI) * 14.0)
		# Se da vuelta a mitad de camino (solo las tuyas)
		var sx := absf(cos(e * PI)) if d["p"] == human and not recover else 1.0
		var face: bool = recover or (d["p"] == human and e > 0.5)
		var size := DECK_CARD * (1.0 + 0.4 * sin(e * PI))
		var r := Rect2(p - Vector2(size.x * sx, size.y) / 2, Vector2(size.x * sx, size.y))
		if r.size.x < 1.0:
			continue
		draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.35))
		if face:
			draw_rect(r, C_PANEL)
			_draw_card_image(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, r.size.x - 2)), ids[i])
			draw_rect(Rect2(r.position + Vector2(1, r.size.y - 4), Vector2(r.size.x - 2, 2)), _card_chip_color(ids[i]))
			draw_rect(r, C_TEXT, false)
		else:
			_draw_card_back(r)


## Primer plano de la carta robada: sale del mazo dándose vuelta, se agranda en el centro
## (la mesa se oscurece un poco), se queda un momento y baja achicándose hasta la mano.
func _draw_closeup(d: Dictionary, spot: Vector2) -> void:
	var per := CU_IN + CU_HOLD + CU_OUT
	var t: float = d["t"]
	var i := mini(int(t / per), d["ids"].size() - 1)
	var u := t - i * per
	var id: String = d["ids"][i]
	var center := Vector2(W / 2.0, BOX_Y / 2.0 + 2.0)
	var big := 1.45
	var pos := center
	var sc := big
	var sx := 1.0
	var dim := 1.0
	if u < CU_IN:
		var e := u / CU_IN
		e = e * e * (3.0 - 2.0 * e)
		pos = spot.lerp(center, e) + Vector2(0, -sin(e * PI) * 10.0)
		sc = lerpf(0.3, big, e)
		sx = absf(cos(e * PI))            # se da vuelta en el camino
		dim = e
	elif u > CU_IN + CU_HOLD:
		var e := clampf((u - CU_IN - CU_HOLD) / CU_OUT, 0.0, 1.0)
		e = e * e
		pos = center.lerp(_hand_spot(human), e)
		sc = lerpf(big, 0.3, e)
		dim = 1.0 - e
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.35 * dim))
	var size := Vector2(48, 64) * sc
	var r := Rect2(pos - Vector2(size.x * sx, size.y) / 2.0, Vector2(size.x * sx, size.y))
	if r.size.x < 1.0:
		return
	var face := u >= CU_IN * 0.5
	if not face:
		_draw_card_back(r)
		return
	draw_rect(Rect2(r.position + Vector2(2, 3) * sc, r.size), Color(0, 0, 0, 0.35))
	_round_box(r, C_PANEL, C_TEXT)
	if sx < 0.95:
		return
	_draw_card_image(Rect2(r.position + Vector2(3, 3) * sc, Vector2(42, 42) * sc), id)
	draw_rect(Rect2(r.position.x + 3 * sc, r.position.y + 47 * sc, 42 * sc, 2), _card_chip_color(id))
	if sc > 0.8:
		_text_fit(Vector2(r.position.x + 3 * sc, r.position.y + 50 * sc), CardDB.card_name(id), C_TEXT, 42 * sc)
	# Brillo que cruza la carta cuando llega
	var g := (u - CU_IN) / 0.3
	if g > 0.0 and g < 1.0:
		var gx := r.position.x + r.size.x * g
		draw_rect(Rect2(gx - 3, r.position.y + 2, 4, r.size.y - 4), Color(1, 1, 1, 0.35 * (1.0 - g)))


## Barajada estilo riffle: dos mitades que se abren y se intercalan, dos veces.
func _draw_shuffle(spot: Vector2, u: float, fade: float) -> void:
	const N := 6
	var cycle := fmod(u * 2.0, 1.0) if u < 0.999 else 0.999
	var done := u >= 0.92
	for i in N:
		var left := i % 2 == 0
		var pos := spot
		if not done:
			if cycle < 0.35:
				# Se abren las dos mitades
				var k := cycle / 0.35
				pos += Vector2((-13.0 if left else 13.0) * k, -3.0 * sin(k * PI))
			else:
				# Las cartas caen alternadas hacia el centro
				var order := float(N - 1 - i) / N
				var k := clampf((cycle - 0.35) / 0.65 * 1.6 - order * 0.6, 0.0, 1.0)
				pos += Vector2((-13.0 if left else 13.0) * (1.0 - k), -4.0 * sin(k * PI))
		pos += Vector2(0, -i * 0.8)
		var tilt := 0.0 if done else (0.25 if left else -0.25) * sin(clampf(cycle / 0.35, 0.0, 1.0) * PI * 0.5) * (1.0 if cycle < 0.6 else 0.0)
		draw_set_transform(_base_off + pos, tilt)
		_draw_card_back(Rect2(-DECK_CARD / 2, DECK_CARD), fade)
		draw_set_transform(_base_off)
	if done:
		# Golpecito final: chispas
		var k := (u - 0.92) / 0.08
		for j in 4:
			var ang := TAU * j / 4.0 + 0.78
			var p := spot + Vector2(cos(ang), sin(ang)) * (12.0 + k * 6.0)
			draw_line(p - Vector2(2, 0), p + Vector2(2, 0), Color(1, 1, 1, 1.0 - k))
			draw_line(p - Vector2(0, 2), p + Vector2(0, 2), Color(1, 1, 1, 1.0 - k))


# ===========================================================================
# Íconos de Energía
# ===========================================================================
# Por defecto se dibuja un círculo del color del tipo con su emblema. Si en
# mundo/propios/tipos/ (tools/armar_tipos.py) o en sprites/ hay una imagen
# energy_<tipo>.png (energy_fire.png, energy_water.png...) o energia_<tipo>.png
# (energia_fuego.png...), se usa esa.

const ENERGY_FILE_ES := {"Fire": "fuego", "Water": "agua", "Grass": "planta", "Lightning": "rayo",
		"Psychic": "psiquico", "Fighting": "lucha", "Darkness": "oscuro", "Metal": "metal", "Colorless": "incoloro", "*": "arcoiris"}
var _energy_tex := {}


func _energy_texture(type: String, size: int) -> Texture2D:
	var key := "%s|%d" % [type, size]
	if _energy_tex.has(key):
		return _energy_tex[key]
	var tex: Texture2D = null
	var en := "rainbow" if type == "*" else type.to_lower()
	for dir in ["res://mundo/propios/tipos", "user://mundo/propios/tipos"] + SPRITE_DIRS:
		for n in ["energy_" + en, "energia_" + ENERGY_FILE_ES.get(type, en)]:
			for ext in ["png", "jpg", "webp"]:
				var path := "%s/%s.%s" % [dir, n, ext]
				if tex == null and ImgLoad.exists(path):
					var img := ImgLoad.load(path)
					if img != null and not img.is_empty():
						# Sin reducir la paleta: los íconos son chiquitos y conviene que se lean bien.
						img.convert(Image.FORMAT_RGBA8)
						var px := size * (HD_SCALE if hd else 1)
						img.resize(px * 4, px * 4, Image.INTERPOLATE_LANCZOS)
						img.resize(px, px, Image.INTERPOLATE_BILINEAR)
						tex = ImageTexture.create_from_image(img)
	_energy_tex[key] = tex
	return tex


## Solo el dibujo del tipo (la llama, la gota, la hoja...) sin la esfera: se toma de los íconos de
## Energía (lo oscuro del centro) y queda blanco, para pintarlo del color que haga falta.
var _symbol_tex := {}

func _type_symbol(type: String, size: int) -> Texture2D:
	var key := "%s|%d" % [type, size]
	if _symbol_tex.has(key):
		return _symbol_tex[key]
	var tex: Texture2D = null
	var en := type.to_lower()
	for dir in ["res://mundo/propios/tipos", "user://mundo/propios/tipos"] + SPRITE_DIRS:
		var path := "%s/energy_%s.png" % [dir, en]
		if tex != null or not ImgLoad.exists(path):
			continue
		var img := ImgLoad.load(path)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				var dd := Vector2(x - (w - 1) / 2.0, y - (h - 1) / 2.0).length() / (w / 2.0)
				var lum := 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
				if c.a > 0.5 and lum < 0.3 and dd < 0.7:
					out.set_pixel(x, y, Color(1, 1, 1, 1))
				else:
					out.set_pixel(x, y, Color(1, 1, 1, 0))
		var px := size * (HD_SCALE if hd else 1)
		out.resize(px, px, Image.INTERPOLATE_LANCZOS)
		tex = ImageTexture.create_from_image(out)
	_symbol_tex[key] = tex
	return tex


func _draw_energy_icon(center: Vector2, d: int, type: String) -> void:
	var r := Rect2(center - Vector2(d, d) / 2.0, Vector2(d, d))
	var tex := _energy_texture(type, d)
	if tex != null:
		draw_texture_rect(tex, r, false)
		return
	var rad := d / 2.0
	draw_circle(center, rad, C_TEXT)
	if type == "*":
		var cols := ["Fire", "Lightning", "Grass", "Water", "Psychic", "Fighting"]
		for i in 6:
			draw_arc(center, rad - 1.5, TAU * i / 6.0, TAU * (i + 1) / 6.0, 4, TYPE_COLORS[cols[i]], 2.0)
		draw_circle(center, maxf(1.0, rad - 2.5), Color.WHITE)
		return
	var tc: Color = TYPE_COLORS.get(type, C_LIGHT)
	draw_circle(center, rad - 0.8, tc)
	if d >= 7:
		var glyph := Color.WHITE if type not in ["Lightning", "Colorless", "Metal"] else C_TEXT
		var gr := r.grow(-d * 0.24)
		_draw_emblem(gr, type, glyph)


## Fila con texto e íconos: [["text", "Weakness "], ["icon", "Fire"], ...]
func _draw_icon_row(pos: Vector2, row: Array) -> void:
	var x := pos.x
	for item in row:
		if item[0] == "icon":
			_draw_energy_icon(Vector2(x + 5, pos.y + 4.5), 10, item[1])
			x += 11
		elif item[0] == "fx":
			_reason_icon(item[1], Vector2(x + 5, pos.y + 4.5))
			x += 12
		elif item[0] == "bold":
			var c: Color = item[2] if item.size() > 2 else C_TEXT
			_text_bold(Vector2(x, pos.y), item[1], c)
			x += font_bold.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		else:
			var c: Color = C_DIM if item[0] == "dim" else (item[2] if item.size() > 2 else C_TEXT)
			_text(Vector2(x, pos.y), item[1], c)
			x += _text_w(item[1])


# Dígitos de 3x5 píxeles (para los PS de la Banca)
const TINY := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "011", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	"/": ["001", "001", "010", "100", "100"],
	"H": ["101", "101", "111", "101", "101"], "P": ["111", "101", "111", "100", "100"], "S": ["111", "100", "111", "001", "111"],
	"+": ["000", "010", "111", "010", "000"],
}


func _draw_tiny(pos: Vector2, s: String, c: Color) -> void:
	var x := pos.x
	for ch in s:
		var g: Array = TINY.get(ch, [])
		for row in g.size():
			for col in 3:
				if g[row][col] == "1":
					draw_rect(Rect2(x + col, pos.y + row, 1, 1), c)
		x += 4


# ===========================================================================
# Elegir el Premio
# ===========================================================================
# Como en el juego real, los Premios están boca abajo y vos elegís cuál tomar.
# El motor ya apartó una carta al hacer el KO; si elegís otra posición, se
# intercambian (la que estaba en esa posición va a tu mano y la otra vuelve a los
# Premios), así que te llevás exactamente la carta del lugar que elegiste.

const PRIZE_CARD := Vector2(20, 27)


## Cartas boca abajo entre las que se elige: los Premios que quedan más los que se
## están tomando ahora y todavía no se eligieron.
func _prize_pile_size(player: int) -> int:
	var n: int = game.players[player].prizes.size()
	for e in prize_anim:
		if e["p"] == player and e.get("choose", false):
			n += 1
	return n


func _prize_slot_pos(i: int) -> Vector2:
	var center := Vector2(W / 2.0, 56)
	var col := i % 2
	var row := i / 2
	return center + Vector2((col - 0.5) * 26.0, (row - 1) * 31.0)


func _pick_prize(k: int) -> void:
	var pz: Dictionary = prize_anim[0]
	var pl: PlayerState = game.players[pz["p"]]
	var taken: String = pz["id"]
	if k < pl.prizes.size():
		var idx := pl.hand.rfind(taken)
		if idx >= 0:
			var chosen: String = pl.prizes[k]
			pl.hand[idx] = chosen
			pl.prizes[k] = taken
			pz["id"] = chosen
	pz["from"] = _prize_slot_pos(k)
	pz["choose"] = false
	pz["t"] = 0.08
	prize_cursor = 0


func _draw_prize_choice(pz: Dictionary) -> void:
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.5))
	var n := _prize_pile_size(pz["p"])
	prize_cursor = clampi(prize_cursor, 0, n - 1)
	var now := Time.get_ticks_msec() / 1000.0
	for i in n:
		var c := _prize_slot_pos(i)
		var sel := i == prize_cursor
		var lift := -3.0 - sin(now * 6.0) if sel else 0.0
		var r := Rect2(c - PRIZE_CARD / 2 + Vector2(0, lift), PRIZE_CARD)
		draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.4))
		_draw_card_back(r)
		if sel:
			draw_rect(r.grow(1), C_ACCENT, false, 2.0)
			var tip := Vector2(r.position.x - 3, r.get_center().y)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, -4), tip + Vector2(-5, 4)]), C_ACCENT)
	_text(Vector2(W / 2.0 + 34, 12), "PRIZES", C_LIGHT)
	_text(Vector2(W / 2.0 + 34, 23), "%d face down" % n, C_LIGHT)


# ===========================================================================
# Barra de vida animada
# ===========================================================================

func _shown_hp(m: PokemonInPlay) -> float:
	return hp_shown.get(m, float(clampi(m.hp_left(), 0, m.max_hp())))


## La ficha tiembla un momento cuando empiezan a bajar los PS (como en las batallas de GBA).
const HP_SHAKE_TIME := 0.3
var hp_drop_t := {}           # Pokémon -> cuándo empezaron a bajar sus PS (segundos)

func _hp_shake(m: PokemonInPlay) -> Vector2:
	if not hp_drop_t.has(m) or not animations_on:
		return Vector2.ZERO
	var k: float = (Time.get_ticks_msec() / 1000.0 - float(hp_drop_t[m])) / HP_SHAKE_TIME
	if k >= 1.0:
		return Vector2.ZERO
	var amp := roundf(2.0 * (1.0 - k))
	return Vector2(amp if int(k * 12.0) % 2 == 0 else -amp, 0)


func _update_hp(delta: float) -> void:
	_collect_checkup()
	var alive := {}
	for pl in game.players:
		for m in pl.all_in_play():
			alive[m] = true
			var target := float(clampi(m.hp_left(), 0, m.max_hp()))
			if hp_hold.has(m):
				target = maxf(target, minf(float(hp_hold[m]), float(m.max_hp())))
			var cur: float = hp_shown.get(m, target)
			if cur > target and not hp_drop_t.has(m):
				hp_drop_t[m] = Time.get_ticks_msec() / 1000.0
			elif cur <= target:
				hp_drop_t.erase(m)
			if cur != target:
				var step := maxf(45.0, absf(target - cur) * 2.5) * delta   # rápido al principio, frena al final
				cur = target if absf(target - cur) <= step else cur + signf(target - cur) * step
			hp_shown[m] = cur
	if hp_shown.size() > alive.size():
		for m in hp_shown.keys():
			if not alive.has(m):
				hp_shown.erase(m)
	for m in hp_hold.keys():
		if not alive.has(m):
			hp_hold.erase(m)


## Daño de veneno y quemadura del chequeo entre turnos: se ve aparte, después del ataque
## (la barra de PS se queda donde la dejó el golpe hasta que le toca).
func _collect_checkup() -> void:
	if game.checkup_log.size() <= checkup_seen:
		return
	var batch: Array = game.checkup_log.slice(checkup_seen)
	checkup_seen = game.checkup_log.size()
	if not animations_on:
		return
	for e in batch:
		var m: PokemonInPlay = e["mon"]
		if not hp_hold.has(m):
			var total := 0
			for e2 in batch:
				if e2["mon"] == m:
					total += int(e2["dmg"])
			hp_hold[m] = clampi(m.hp_left(), 0, m.max_hp()) + total
		var d: Dictionary = e.duplicate()
		d["t"] = 0.0
		check_anim.append(d)


const CHECK_TIME := 1.1


func _update_check(delta: float) -> void:
	var c: Dictionary = check_anim[0]
	if float(c["t"]) == 0.0:
		var m: PokemonInPlay = c["mon"]
		if hp_hold.has(m):
			hp_hold[m] = int(hp_hold[m]) - int(c["dmg"])
			if int(hp_hold[m]) <= m.hp_left():
				hp_hold.erase(m)
		snd.play("hit_Psychic" if c["kind"] == "poison" else "hit_Fire")
	c["t"] = float(c["t"]) + delta / CHECK_TIME
	if float(c["t"]) >= 1.0:
		check_anim.pop_front()
		if check_anim.is_empty():
			ai_timer = AI_DELAY
			_rebuild_menu()


## El Activo titila del color del estado y sube el número ("-10" violeta o naranja).
func _draw_check() -> void:
	if check_anim.is_empty() or not anim.is_empty() or not coin_anim.is_empty() or not evo_anim.is_empty():
		return
	var c: Dictionary = check_anim[0]
	var m: PokemonInPlay = c["mon"]
	var pl: PlayerState = game.players[c["p"]]
	var r := Rect2()
	if _dbl():
		r = _dbl_card_rect(pl.index, 1 if pl.active2 == m else 0)
	else:
		r = _card_rect(pl.index)
	var t: float = c["t"]
	var col := Color("#b058e0") if c["kind"] == "poison" else Color("#f87830")
	if t < 0.45 and int(t * 18.0) % 2 == 0:
		draw_rect(r, Color(col, 0.45))
	var txt := "-%d" % int(c["dmg"])
	var sc := 1.5 + (sin(clampf(t * 5.0, 0.0, 1.0) * PI) * 0.5 if t < 0.2 else 0.0)
	var w: float = _text_w(txt) * sc
	var p := r.get_center() + Vector2(-w / 2.0, -4.0 - minf(t, 0.6) * 14.0)
	var tc := Color("#fcd0ff") if c["kind"] == "poison" else Color("#ffe8a8")
	tc.a = clampf((1.0 - t) * 4.0, 0.0, 1.0)
	draw_rect(Rect2(p.round() + Vector2(-3, 0), Vector2(w + 6, 12.0 * sc)), Color(col.darkened(0.6), 0.8 * tc.a))
	draw_set_transform(_base_off + p.round(), 0, Vector2(sc, sc))
	_text(Vector2.ZERO, txt, tc)
	draw_set_transform(_base_off)


# ===========================================================================
# Herramientas, Máquinas Técnicas y Estadio en la mesa
# ===========================================================================

## Cartita del Estadio, en el lado del rival.
func _draw_stadium_card(id: String) -> void:
	var r := Rect2(88, 33, 16, 20)
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
	draw_rect(r, C_INK)
	draw_rect(r.grow(-1), C_STADIUM_BG)
	_draw_card_image(Rect2(r.position + Vector2(2, 2), Vector2(12, 12)), id)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 15, 12, 2), C_BODY if game.stadium_owner != human else C_FRAME_MID)


var _stadium_bg := {}


## Fondo tenue del Estadio: su imagen (si pusiste una en sprites/) estirada sobre la mesa,
## casi transparente. Sin imagen, una silueta grande y suave de un edificio.
func _draw_stadium_background(id: String) -> void:
	if not _stadium_bg.has(id):
		var tex: Texture2D = null
		var name := CardDB.card_name(id)
		for dir in SPRITE_DIRS:
			for n in [id, name]:
				for ext in ["png", "jpg", "webp"]:
					var path := "%s/%s.%s" % [dir, n, ext]
					if tex == null and ImgLoad.exists(path):
						var img := ImgLoad.load(path)
						if img != null and not img.is_empty():
							img.convert(Image.FORMAT_RGBA8)
							# Cubrir la mesa (240x110) recortando lo que sobre
							var bw := W * (HD_SCALE if hd else 1)
							var bh := BOX_Y * (HD_SCALE if hd else 1)
							var sc := maxf(float(bw) / img.get_width(), float(bh) / img.get_height())
							img.resize(maxi(bw, int(img.get_width() * sc)), maxi(bh, int(img.get_height() * sc)), Image.INTERPOLATE_BILINEAR)
							var crop := img.get_region(Rect2i((img.get_width() - bw) / 2, (img.get_height() - bh) / 2, bw, bh))
							tex = ImageTexture.create_from_image(crop)
		_stadium_bg[id] = tex
	var t: Texture2D = _stadium_bg[id]
	if t != null:
		draw_texture_rect(t, Rect2(0, 0, W, BOX_Y), false, Color(1, 1, 1, 0.16))
		return
	# Silueta genérica
	var c := Color(1, 1, 1, 0.05)
	var cx := W / 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 50, 50), Vector2(cx, 18), Vector2(cx + 50, 50)]), c)
	draw_rect(Rect2(cx - 40, 50, 80, 44), c)
	draw_rect(Rect2(cx - 9, 72, 18, 22), Color(0, 0, 0, 0.05))


# ===========================================================================
# Gráficos: Pixel (GBA) o Nítido
# ===========================================================================
# "Pixel" dibuja todo en 240x160 y lo agranda (como una GBA): las imágenes quedan de
# 30x30 píxeles. "Nítido" mantiene la misma pantalla pero dibuja a la resolución de la
# ventana, así las imágenes se ven con 4 veces más detalle (120x120 en el lugar del
# retrato) y el texto queda más suave.

func _apply_graphics() -> void:
	var win := get_window()
	if win != null:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	_sprites.clear()
	_energy_tex.clear()
	_stadium_bg.clear()
	_stage_cache.clear()
	_table_tex = null


func _load_settings() -> void:
	_find_table_styles()
	var cfg := ConfigFile.new()
	hd = false
	if cfg.load(SETTINGS_PATH) == OK:
		var want := str(cfg.get_value("graficos", "mesa", "Classic"))
		for i in table_styles.size():
			if table_styles[i][0] == want:
				table_style = i
		anim_speed = clampi(int(cfg.get_value("graficos", "animaciones", 0)), 0, ANIM_SPEEDS.size() - 1)
		if cfg.has_section_key("graficos", "batallas_modo"):
			battle_mode = clampi(int(cfg.get_value("graficos", "batallas_modo", 1)), 0, 1)   # la vieja "Full" pasa a Mini
		else:     # opción vieja (On/Off)
			battle_mode = 1 if bool(cfg.get_value("graficos", "batallas", true)) else 0
		ai_level = clampi(int(cfg.get_value("juego", "dificultad", 3)), 1, 5)
		var sid := str(cfg.get_value("juego", "temporada", RuleSet.SEASONS[0]["id"]))
		for i in RuleSet.SEASONS.size():
			if RuleSet.SEASONS[i]["id"] == sid:
				season_idx = i
		sfx_level = clampi(int(cfg.get_value("sonido", "efectos", 2)), 0, 3)
		music_level = clampi(int(cfg.get_value("sonido", "musica", 2)), 0, 3)
	_apply_graphics()


## ¿Todas las cartas del mazo eran legales en la temporada?
func _deck_legal(deck_name: String, r: RuleSet) -> bool:
	return r.illegal_cards(Decks.get_deck(deck_name)).is_empty()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graficos", "mesa", table_styles[table_style][0])
	cfg.set_value("graficos", "animaciones", anim_speed)
	cfg.set_value("graficos", "batallas_modo", battle_mode)
	cfg.set_value("juego", "dificultad", ai_level)
	cfg.set_value("juego", "temporada", RuleSet.SEASONS[season_idx]["id"])
	cfg.set_value("sonido", "efectos", sfx_level)
	cfg.set_value("sonido", "musica", music_level)
	cfg.save(SETTINGS_PATH)


# ===========================================================================
# Fuente
# ===========================================================================
# Roboto (SIL Open Font License, de Google Fonts), fuente variable: el texto común va
# en peso 500 (un poco más grueso que el normal, se lee mejor en tamaños chicos) y la
# negrita en 700. Los símbolos que no trae (flechas, triángulos, estrella) salen de la
# fuente común de Godot.

## Letra propia: si ponés fonts/propia.fnt (+ propia.png), se usa en lugar de la original;
## los caracteres que no tenga salen de la original. Se arma con tools/hoja_a_fuente.py.
const CUSTOM_FONT_PATHS := ["res://fonts/propia.fnt", "user://fonts/propia.fnt"]


func _load_pixel_font() -> Font:
	var f := FontFile.new()
	if f.load_bitmap_font(FONT_PATH) != OK:
		var r = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else null
		if r is FontFile:
			f = r
		else:
			font_bold = ThemeDB.fallback_font
			return ThemeDB.fallback_font
	f.fixed_size = FONT_SIZE
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.fallbacks = [ThemeDB.fallback_font]
	for path in CUSTOM_FONT_PATHS:
		if ImgLoad.exists(path):
			var c := FontFile.new()
			if c.load_bitmap_font(path) == OK:
				c.fixed_size = FONT_SIZE
				c.antialiasing = TextServer.FONT_ANTIALIASING_NONE
				c.fallbacks = [f]
				font_bold = c
				return c
	font_bold = f
	return f


## "Negrita" estilo pixel: la letra dibujada dos veces, corrida 1 píxel.
func _text_bold(pos: Vector2, s: String, color: Color = C_TEXT) -> void:
	_text(pos + Vector2(1, 0), s, color)
	_text(pos, s, color)


# ===========================================================================
# Íconos de condiciones especiales
# ===========================================================================

func _condition_list(m: PokemonInPlay) -> Array:
	var out: Array = []
	if m.rotation != "":
		out.append(m.rotation)          # asleep / confused / paralyzed
	if m.poison > 0:
		out.append("poisoned")
	if m.burned:
		out.append("burned")
	return out


func _draw_condition_icon(c: Vector2, cond: String) -> void:
	var col: Color = {"asleep": Color("#4060c0"), "confused": Color("#d0a020"), "paralyzed": Color("#e8c820"),
			"poisoned": Color("#9040b0"), "burned": Color("#e05828")}.get(cond, C_HP_LOW)
	draw_circle(c, 4.5, C_TEXT)
	draw_circle(c, 3.6, col)
	var w := Color.WHITE
	match cond:
		"asleep":       # una Z
			draw_line(c + Vector2(-2, -2), c + Vector2(2, -2), w)
			draw_line(c + Vector2(2, -2), c + Vector2(-2, 2), w)
			draw_line(c + Vector2(-2, 2), c + Vector2(2, 2), w)
		"confused":     # espiral
			draw_arc(c, 2.2, 0.0, TAU * 0.8, 8, w, 1.0)
			draw_circle(c, 0.7, w)
		"paralyzed":    # rayo
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.5, -3), c + Vector2(-1.8, 0.5), c + Vector2(0, 0.5),
					c + Vector2(-0.5, 3), c + Vector2(1.8, -0.5), c + Vector2(0, -0.5)]), C_TEXT)
		"poisoned":     # burbujas
			draw_circle(c + Vector2(-1, 1), 1.3, w)
			draw_circle(c + Vector2(1.4, -1.2), 0.9, w)
		"burned":       # llamita
			_draw_small_flame(c + Vector2(0, 0.3), 2.6)


# ===========================================================================
# Fuera de combate
# ===========================================================================
# El Pokémon parpadea en blanco, se hunde y se desvanece en polvo.

func _update_ko(delta: float) -> void:
	ko_anim[0]["t"] += delta / KO_TIME
	if ko_anim[0]["t"] >= 1.0:
		ko_anim.pop_front()
		if ko_anim.is_empty():
			ai_timer = AI_DELAY
			_rebuild_menu()


func _draw_ko() -> void:
	if ko_anim.is_empty() or not check_anim.is_empty() or not anim.is_empty() or not coin_anim.is_empty() or not evo_anim.is_empty():
		return
	var k: Dictionary = ko_anim[0]
	var t: float = k["t"]
	var active: bool = PlayerState.is_active_slot(k["slot"])
	var mine: bool = k["p"] == human
	var panel: Rect2
	var portrait := Rect2()
	if active and _dbl():
		var di := 1 if k["slot"] == PlayerState.ACTIVE2 else 0
		panel = _dbl_info_rect(k["p"], di)
		portrait = _dbl_card_rect(k["p"], di)
	elif active:
		panel = _info_rect(k["p"])
		portrait = _card_rect(k["p"])
	else:
		panel = _bench_rect(k["p"], k["slot"])
	var tc: Color = TYPE_COLORS.get(CardDB.types(k["id"])[0] if not CardDB.types(k["id"]).is_empty() else "Colorless", C_PANEL_DARK)
	if t < 0.35:
		# Parpadeo
		var on := int(t * 20) % 2 == 0
		for r: Rect2 in [panel, portrait]:
			if r.size.x > 0:
				draw_rect(r, C_PANEL if not on else Color.WHITE)
				draw_rect(r, C_TEXT, false)
		if active:
			_text_fit(panel.position + Vector2(7, 1), k["name"], C_TEXT, panel.size.x - 10)
		_draw_ko_title(t, CardDB.is_ex(k["id"]))
		return
	# Se hunde y se desvanece
	var u := (t - 0.35) / 0.65
	var a := 1.0 - u
	for r: Rect2 in [panel, portrait]:
		if r.size.x <= 0:
			continue
		var h: float = r.size.y * (1.0 - u)
		var rr := Rect2(r.position + Vector2(0, r.size.y - h), Vector2(r.size.x, h))
		draw_rect(rr, Color(C_PANEL if r == panel else tc.darkened(0.3), a))
		draw_rect(rr, Color(C_TEXT, a), false)
	# Polvo que sube
	for i in 10:
		var px := panel.position.x + fmod(i * 37.0, panel.size.x)
		var py := panel.end.y - u * (8.0 + (i % 4) * 5.0)
		draw_rect(Rect2(px, py, 1.5, 1.5), Color(1, 1, 1, a))
	if portrait.size.x > 0:
		for i in 6:
			var px := portrait.position.x + fmod(i * 11.0, portrait.size.x)
			draw_rect(Rect2(px, portrait.end.y - u * (10.0 + (i % 3) * 6.0), 1.5, 1.5), Color(1, 1, 1, a))
	if CardDB.is_ex(k["id"]):
		_draw_ex_ko_banner(u, panel.get_center() if portrait.size.x <= 0 else portrait.get_center())
	_draw_ko_title(t, CardDB.is_ex(k["id"]))


## "KNOCKED OUT!" con las letras del título: entra de golpe (grande y se achica) en el
## medio de la mesa; si era un ex, abajo aparece "2 PRIZES!".
func _draw_ko_title(t: float, ex: bool) -> void:
	var t0 := 0.2
	if t < t0:
		return
	var k := (t - t0) / (1.0 - t0)
	var fade := clampf((1.0 - k) / 0.12, 0.0, 1.0)
	var cy := BOX_Y / 2.0 - (6.0 if ex else 0.0)
	var band_h := 44.0 if ex else 28.0
	draw_rect(Rect2(0, cy - 14, W, band_h), Color(0.08, 0.02, 0.02, 0.55 * fade))
	draw_rect(Rect2(0, cy - 14, W, 1), Color("#f85838", 0.9 * fade))
	draw_rect(Rect2(0, cy - 14 + band_h - 1, W, 1), Color("#f85838", 0.9 * fade))
	_draw_pop_art("ko", Vector2(W / 2.0, cy), k / 0.1, fade)
	if ex:
		_draw_pop_art("ko_premios", Vector2(W / 2.0, cy + 18), (k - 0.25) / 0.1, fade)


## Dibuja un cartel de ui/ centrado en c: con p de 0 a 1 entra de golpe (de grande a su
## tamaño); p < 0 todavía no se ve.
func _draw_pop_art(id: String, c: Vector2, p: float, alpha: float = 1.0) -> void:
	if p < 0.0:
		return
	var tex := _banner_art(id)
	if tex == null:
		return
	var q := clampf(p, 0.0, 1.0)
	var sc := 1.0 + 1.2 * (1.0 - q) * (1.0 - q)
	var sz := Vector2(tex.get_width(), tex.get_height())
	draw_set_transform(_base_off + Vector2(roundf(c.x), roundf(c.y)), 0, Vector2(sc, sc))
	draw_texture(tex, (-sz / 2.0).round(), Color(1, 1, 1, alpha * clampf(q * 3.0, 0.0, 1.0)))
	draw_set_transform(_base_off)


## Cae un Pokémon ex: tus destellos dorados salen del lugar y un cartel "2 PRIZES!" en el
## medio de la mesa (entra grande y se acomoda, como el de la debilidad).
func _draw_ex_ko_banner(u: float, from: Vector2) -> void:
	for i in 6:
		var ang := TAU * i / 6.0 + u * 1.5
		var sp := from + Vector2(cos(ang), sin(ang)) * (6.0 + u * 30.0)
		if SpecialFX.has_fx("estrellas"):
			SpecialFX.fx_draw(self, "estrellas", 1, sp, 0.45 + 0.2 * sin(u * PI), 1.0 - u, 0.0, false, Color("#f8d860"))
		else:
			_draw_burst(sp, 3.0, Color("#f8d860", 1.0 - u), 4)
	# El texto "2 PRIZES!" va en _draw_ko_title, con las letras del título


# ===========================================================================
# Pokémon ex: brillo al llegar a la mesa
# ===========================================================================
# Cuando un Pokémon ex aparece en la mesa (lo bajás, evoluciona a ex o sube a la Banca),
# una franja de luz cruza la carta, el borde destella en dorado y saltan tus destellos.

## Nada se está animando en la mesa (para el brillo de los ex y el balanceo del Activo).
func _board_idle() -> bool:
	return anim.is_empty() and coin_anim.is_empty() and evo_anim.is_empty() and ko_anim.is_empty() and check_anim.is_empty() \
			and move_anim.is_empty() and energy_anim.is_empty() and prize_anim.is_empty() and trainer_anim.is_empty() \
			and power_anim.is_empty() and banner.is_empty() and rival_intro.is_empty() and deck_anim.is_empty() and vs_anim.is_empty() and intro == ""


func _update_ex_shine(delta: float) -> void:
	if game.phase in ["setup", "first"]:
		return                      # en la preparación las cartas todavía están boca abajo
	var live := {}
	for pl: PlayerState in game.players:
		for m: PokemonInPlay in pl.all_in_play():
			live[m] = true
			var top := m.top()
			if CardDB.is_ex(top) and str(ex_seen.get(m, "")) != top:
				if animations_on and _is_moving(m):
					continue                # todavía está llegando: brilla cuando se acomode
				ex_seen[m] = top
				if animations_on:
					ex_shine[m] = {"t": 0.0, "snd": false}
	for m in ex_seen.keys():
		if not live.has(m):
			ex_seen.erase(m)
			ex_shine.erase(m)
	if ex_shine.is_empty() or not _board_idle():
		return
	var first = ex_shine.keys()[0]          # de a uno
	var e: Dictionary = ex_shine[first]
	if not e["snd"]:
		e["snd"] = true
		snd.play("shine")
	e["t"] += delta / EX_SHINE_TIME
	if e["t"] >= 1.0:
		ex_shine.erase(first)


## Dónde está dibujado un Pokémon en la mesa (la carta grande del Activo o la de la Banca).
func _mon_rect(m: PokemonInPlay) -> Rect2:
	for pl: PlayerState in game.players:
		if _dbl() and pl.is_active(m):
			return _dbl_card_rect(pl.index, 0 if pl.active == m else 1)
		if pl.active == m:
			return _portrait_rect(_card_rect(pl.index).position + _idle_bob(pl))
		var i := pl.bench.find(m)
		if i >= 0:
			return _bench_rect(pl.index, i)
	return Rect2()


func _draw_ex_shine() -> void:
	if ex_shine.is_empty() or not _board_idle():
		return
	var m = ex_shine.keys()[0]
	var r := _mon_rect(m)
	if r.size.x <= 0:
		return
	var t: float = ex_shine[m]["t"]
	var gold := Color("#f8d030")
	# El borde destella en dorado
	var ga := sin(clampf(t / 0.5, 0.0, 1.0) * PI)
	draw_rect(r.grow(1), Color(gold, ga), false, 1.0)
	draw_rect(r.grow(2), Color(gold, ga * 0.4), false, 1.0)
	# La franja de luz cruza en diagonal (recortada a la carta)
	if t < 0.6:
		var k := t / 0.6
		var slant := r.size.y * 0.45
		var x := r.position.x - 8.0 + (r.size.x + slant + 16.0) * k
		var card := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		for band: Array in [[0.0, 6.0, 0.7], [-9.0, 2.0, 0.45]]:
			var bx: float = x + float(band[0])
			var bw: float = band[1]
			var poly := PackedVector2Array([Vector2(bx - slant, r.end.y), Vector2(bx - slant + bw, r.end.y),
					Vector2(bx + bw, r.position.y), Vector2(bx, r.position.y)])
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly, card):
				draw_colored_polygon(piece, Color(1, 1, 1, float(band[2])))
	# Destellos en las esquinas, uno detrás del otro
	var corners := [r.position + Vector2(r.size.x - 2, 3), r.position + Vector2(3, r.size.y * 0.55), r.end - Vector2(4, 3)]
	for i in corners.size():
		var st := 0.3 + i * 0.15
		if t < st or t > st + 0.45:
			continue
		var q := (t - st) / 0.45
		var sc := sin(q * PI)
		if SpecialFX.has_fx("estrellas"):
			SpecialFX.fx_draw(self, "estrellas", 1, corners[i], 0.35 + 0.4 * sc, sc, q * 1.2)
		else:
			_draw_burst(corners[i], 1.5 + 3.0 * sc, Color(1, 1, 1, sc), 4)


# ===========================================================================
# El Activo espera
# ===========================================================================
# Si es tu turno y tardás en jugar (IDLE_AFTER segundos sin tocar nada, con la mesa
# quieta), tu Activo empieza a subir y bajar un píxel, como los Pokémon de las batallas de
# GBA mientras esperan una orden. Apenas tocás una tecla, se queda quieto. Dormido o
# Paralizado no se mueve.

const BOB_PERIOD := 1.0
const IDLE_AFTER := 4.0
var idle_since := 0.0


## Es tu turno y el juego está esperando que elijas algo.
func _waiting_human() -> bool:
	return game != null and game.phase in ["main", "choice"] and game.actor() == human and _board_idle() \
			and not paused and rival_intro.is_empty()


func _idle_bob(pl: PlayerState) -> Vector2:
	if game == null or pl.index != human or pl.active == null or not animations_on or not _waiting_human():
		return Vector2.ZERO
	var now := Time.get_ticks_msec() / 1000.0
	var waited := now - idle_since - IDLE_AFTER
	if waited < 0.0:
		return Vector2.ZERO
	var conds := _condition_list(pl.active)
	if conds.has("asleep") or conds.has("paralyzed"):
		return Vector2.ZERO
	return Vector2(0, -1) if fmod(waited, BOB_PERIOD) < BOB_PERIOD * 0.5 else Vector2.ZERO


# ===========================================================================
# Cartel de cambio de turno
# ===========================================================================

func _banner_showing() -> bool:
	return not banner.is_empty() and anim.is_empty() and coin_anim.is_empty() and evo_anim.is_empty() \
			and ko_anim.is_empty() and check_anim.is_empty() and energy_anim.is_empty() and prize_anim.is_empty() and move_anim.is_empty()


## Presentación del rival: franja roja con su nombre desde la derecha, azul con el tuyo desde
## la izquierda y un VS en el medio; al final se van para los costados.
func _draw_rival_intro() -> void:
	if rival_intro.is_empty():
		return
	var t: float = rival_intro["t"]
	var into := clampf(t / 0.35, 0.0, 1.0)
	var out := clampf((t - (RIVAL_INTRO_TIME - 0.3)) / 0.3, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - into, 3)
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.55 * (1.0 - out)))
	var bh := 30.0
	var shift := (1.0 - ease_in) * W + out * W
	# Rival (arriba, desde la derecha)
	var top := Rect2(shift, 30, W, bh)
	draw_rect(top, Color("#b83828"))
	draw_rect(Rect2(top.position, Vector2(W, 2)), Color("#f08070"))
	draw_rect(Rect2(top.position + Vector2(0, bh - 2), Vector2(W, 2)), Color("#701810"))
	_text_big(Vector2(top.position.x + W - 16 - _text_w(rival_intro["rival"]) * 2, top.position.y + 3), rival_intro["rival"], Color.WHITE)
	if rival_intro["deck"] != "":
		var dk: String = rival_intro["deck"]
		_text(Vector2(top.position.x + 46, top.position.y + 10), dk, Color("#f8d0c8"))
	_draw_trainer_sprite(str(rival_intro.get("sprite", "")), Vector2(top.position.x + 10, top.end.y - 2))
	# Vos (abajo, desde la izquierda)
	var bot := Rect2(-shift, 82, W, bh)
	draw_rect(bot, Color("#2858b0"))
	draw_rect(Rect2(bot.position, Vector2(W, 2)), Color("#80a8f0"))
	draw_rect(Rect2(bot.position + Vector2(0, bh - 2), Vector2(W, 2)), Color("#102860"))
	_text_big(Vector2(bot.position.x + 16, bot.position.y + 3), rival_intro["me"], Color.WHITE)
	_draw_trainer_sprite("jugador", Vector2(bot.end.x - 42, bot.end.y - 2))
	# VS en el medio, con un golpecito de escala al aparecer
	if t > 0.3 and out < 1.0:
		var k := clampf((t - 0.3) / 0.15, 0.0, 1.0)
		var sc := 3.0 + (1.0 - k) * 2.0
		var vs_w := _text_w("VS") * sc
		draw_set_transform(_base_off + Vector2(W / 2.0 - vs_w / 2.0, 66 - 5 * sc), 0, Vector2(sc, sc))
		_text(Vector2.ZERO, "VS", Color("#f8d030", 1.0 - out))
		draw_set_transform(_base_off)


## El personaje del mapa (mundo/propios), al doble, mirando de frente; pies en `feet`.
func _draw_trainer_sprite(id: String, feet: Vector2) -> void:
	if id == "" or campaign == null:
		return
	var tex: Texture2D = campaign.world._sprite(id)
	if tex == null or tex.get_height() < 128:
		return
	var region := Rect2(0, 0, 16, 32)
	draw_texture_rect_region(tex, Rect2(feet + Vector2(0, -60), Vector2(32, 64)), region)


func _draw_banner() -> void:
	if not _banner_showing():
		return
	var t: float = banner["t"]
	var mine: bool = banner["p"] == human
	# Entra desde la izquierda, se queda y sale por la derecha
	var x := 0.0
	if t < 0.18:
		var k := t / 0.18
		x = -W * (1.0 - k * k * (3.0 - 2.0 * k))
	elif t > 0.82:
		var k := (t - 0.82) / 0.18
		x = W * k * k
	var band := Rect2(x, 39, W, 34)
	var col := Color("#3868c8") if mine else Color("#c04838")     # tu lado azul, el rival rojo
	var sudden: bool = banner.get("sudden", false)
	if sudden:
		col = Color("#6a3c9c")
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.25 * (1.0 - absf(x) / W)))
	draw_rect(band, col)
	draw_rect(Rect2(band.position + Vector2(0, 2), Vector2(W, 1)), Color(1, 1, 1, 0.5))
	draw_rect(Rect2(band.position + Vector2(0, band.size.y - 3), Vector2(W, 1)), Color(0, 0, 0, 0.3))
	var txt := "YOUR TURN!" if mine else "OPPONENT'S TURN"
	var art := "turno_tuyo" if mine else "turno_rival"
	if sudden:
		txt = "SUDDEN DEATH!"
		art = "muerte_subita"
		mine = false
	# El texto grande con las letras del título (ui/turno_*.png, de tools/logo_juego.py)
	var tex := _banner_art(art)
	if tex != null:
		draw_texture(tex, Vector2(round(x + (W - tex.get_width()) / 2.0), 42))
	else:
		var tw := _text_w(txt) * 2
		_text_big(Vector2(x + (W - tw) / 2.0, 41), txt, C_TEXT if mine else C_LIGHT)
	var sub := "Turn %d" % banner["turn"] if not sudden else "It's a tie: a new game with 1 Prize card each"
	var sp := Vector2(x + (W - _text_w(sub)) / 2.0, 61)
	_text(sp + Vector2(1, 1), sub, Color(0, 0, 0, 0.35))
	_text(sp, sub, C_LIGHT)


var _banner_tex := {}

func _banner_art(id: String) -> Texture2D:
	if not _banner_tex.has(id):
		var img := ImgLoad.load("res://ui/%s.png" % id)
		_banner_tex[id] = ImageTexture.create_from_image(img) if img != null else null
	return _banner_tex[id]


# ===========================================================================
# Esquinas redondeadas de las imágenes
# ===========================================================================

var _boxes := {}


func _corner_radius(size: float) -> int:
	return maxi(2, int(round(size * 0.12)))


## ¿El píxel (x, y) cae fuera de un cuadrado de lado `size` con esquinas de radio `rad`?
func _outside_round(x: int, y: int, size: int, rad: int) -> bool:
	var cx := -1.0
	var cy := -1.0
	if x < rad:
		cx = rad
	elif x >= size - rad:
		cx = size - rad - 1
	if y < rad:
		cy = rad
	elif y >= size - rad:
		cy = size - rad - 1
	if cx < 0.0 or cy < 0.0:
		return false
	return Vector2(x, y).distance_to(Vector2(cx, cy)) > rad + 0.3


## Recuadro con esquinas redondeadas (relleno y/o borde).
func _round_box(r: Rect2, fill: Color, border: Color = Color(0, 0, 0, 0)) -> void:
	var rad := _corner_radius(minf(r.size.x, r.size.y))
	var key := "%s|%s|%d|%s" % [fill.to_html(), border.to_html(), rad, hd]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = fill
		sb.draw_center = fill.a > 0.0
		sb.set_corner_radius_all(rad)
		sb.anti_aliasing = hd
		if border.a > 0.0:
			sb.border_color = border
			sb.set_border_width_all(1)
		_boxes[key] = sb
	draw_style_box(sb, r)


# ===========================================================================
# Entrenadores en la mesa
# ===========================================================================
# Al jugar un Entrenador, la carta sale de la mano, se agranda en el centro de la mesa
# y después va a su lugar: al descarte, al Pokémon (Herramientas y MT) o al lugar del
# Estadio. Los Supporters quedan chiquitos junto al Activo hasta que termina el turno.

# ===========================================================================
# Poké-Power: el Pokémon sale de su carta con su sprite de Mystery Dungeon, mira a la
# pantalla y hace algo según el Poder (salta, carga energía, dispara...).
# ===========================================================================

const POWER_TIME := 1.5          # la versión completa
const POWER_SHORT := 0.75        # el mismo Poder otra vez en el turno
const POWER_IN := 0.28           # lo que tarda en salir de la carta (y en volver)

## Qué hace el Poder, por su texto: energía, curación, daño, búsqueda u otro.
static func power_class(text: String) -> String:
	var t := text.to_lower()
	if t.contains("energy") and (t.contains("attach") or t.contains("move")):
		return "energy"
	if t.contains("remove") and t.contains("damage counter") or t.contains("heal"):
		return "heal"
	if (t.contains("put") or t.contains("place")) and t.contains("damage counter") or t.contains(" damage to"):
		return "damage"
	if t.contains("draw") or t.contains("search") or t.contains("look at"):
		return "search"
	return "other"


const POWER_ANIMS := {"energy": "Charge", "heal": "Charge", "damage": "Shoot", "search": "Hop", "other": "Hop"}

## Arranca la animación; devuelve false si no hay sprite para ese Pokémon (se aplica directo).
func _start_power_anim(action: Dictionary, then: Callable) -> bool:
	if action.get("n", "") == Abilities.DISCARD_FOSSIL:
		return false
	var pi := game.actor()
	var mon: PokemonInPlay = null
	var slot: int = action["s"]
	var ctx = action.get("ctx", null)
	if ctx != null and slot == -1 and game.players[pi].active2 != null and ctx[pi]:
		slot = PlayerState.ACTIVE2
	mon = game.players[pi].slot(slot)
	if mon == null:
		return false
	var id := mon.top()
	var sp := MiniBattle.folder(id)
	if sp == "" or not MiniBattle.available(id):
		return false
	var text := ""
	for ab in CardDB.get_card(id).get("abilities", []):
		if ab.get("name", "") == action["n"]:
			text = ab.get("text", "")
	var cls := power_class(text)
	var an: String = POWER_ANIMS[cls]
	if not MiniBattle.has_anim(sp, an):
		an = "Idle"
	var key := "%d|%d|%s" % [pi, game.turn_number, action["n"]]
	var short: bool = _last_power.get("key", "") == key
	_last_power = {"key": key}
	var src: Rect2
	if slot == -1:
		src = _dbl_card_rect(pi, 0) if _dbl() else _card_rect(pi)
	elif slot == PlayerState.ACTIVE2:
		src = _dbl_card_rect(pi, 1)
	else:
		src = _bench_rect(pi, slot)
	var types := CardDB.types(id)
	power_anim = {"p": pi, "id": id, "sp": sp, "anim": an, "cls": cls, "name": action["n"], "mon": mon.display_name(),
			"src": src, "t": 0.0, "dur": POWER_SHORT if short else POWER_TIME, "short": short, "then": then,
			"col": TYPE_COLORS.get(types[0] if not types.is_empty() else "Colorless", Color.WHITE)}
	return true


func _update_power(delta: float) -> void:
	power_anim["t"] += delta
	if power_anim["t"] >= power_anim["dur"]:
		var then = power_anim.get("then")
		power_anim = {}
		if then is Callable:
			then.call()


func _draw_power_anim() -> void:
	if power_anim.is_empty():
		return
	var t: float = power_anim["t"]
	var dur: float = power_anim["dur"]
	var t_in := POWER_IN * (0.6 if power_anim["short"] else 1.0)
	var kin := clampf(t / t_in, 0.0, 1.0)
	var kout := clampf((t - (dur - t_in)) / t_in, 0.0, 1.0)
	var env := minf(kin, 1.0 - kout)          # 0 → 1 → 0
	var col: Color = power_anim["col"]
	var sp: String = power_anim["sp"]
	# La mesa se oscurece y detrás aparece un círculo de luz del color del tipo
	draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.42 * env))
	var stage := Vector2(W / 2.0, BOX_Y - 24.0)        # donde pisa el Pokémon
	var glow_c := stage + Vector2(0, -26)
	for i in 4:
		var r := (16.0 + i * 9.0 + sin(t * 6.0 + i) * 2.0) * env
		draw_circle(glow_c, r, Color(col, 0.16 * env))
	draw_circle(glow_c, 13.0 * env, Color(col.lightened(0.5), 0.22 * env))
	# Sale de la carta: sube en arco, se agranda; al final vuelve igual
	var src_g: Vector2 = power_anim["src"].get_center() + Vector2(0, 8)
	var k := kin if kout <= 0.0 else 1.0 - kout
	var e := 1.0 - (1.0 - k) * (1.0 - k)
	var g := src_g.lerp(stage, e) + Vector2(0, -sin(e * PI) * 22.0)
	var sc := 1.0 + e
	# Qué anima: mientras sale y vuelve, Idle; en el medio, la acción del Poder
	var act_t := t - t_in
	var name := "Idle" if kin < 1.0 or kout > 0.0 else str(power_anim["anim"])
	var an := MiniBattle._anim(sp, name)
	var loop := name != "Shoot"
	var frame := 0
	if not an.is_empty():
		frame = MiniBattle._frame_at(an, maxf(0.0, act_t if name != "Idle" else t) / MiniBattle.TICK, loop)
		if name == "Shoot" and frame >= int(an["n"]) - 1:
			name = "Idle"
			an = MiniBattle._anim(sp, "Idle")
			frame = MiniBattle._frame_at(an, act_t / MiniBattle.TICK, true) if not an.is_empty() else 0
	draw_set_transform(_base_off + g.round(), 0, Vector2(sc, sc))
	var pts := MiniBattle._put(self, sp, name, 0, frame, Vector2.ZERO, clampf(env * 3.0, 0.0, 1.0))
	draw_set_transform(_base_off)
	var center: Vector2 = g + pts["c"] * sc
	# Efectos de la acción
	if kin >= 1.0 and kout <= 0.0:
		_draw_power_fx(power_anim["cls"], act_t, center, col)
	# Cartel abajo de la mesa: "POKé-POWER" en rojo y al lado el nombre del Poder
	var la := clampf(env * 2.5, 0.0, 1.0)
	var tag := "POKé-POWER"
	var nm: String = power_anim["name"]
	var tw := _text_w(tag) + 10
	var nw := _text_w(nm) + 14
	var rise := (1.0 - clampf(t / 0.2, 0.0, 1.0)) * 14.0
	var x0 := roundf((W - tw - nw) / 2.0)
	var y0 := BOX_Y - 13.0 + rise
	draw_rect(Rect2(x0 - 1, y0 - 1, tw + nw + 2, 13), Color(C_INK, la))
	draw_rect(Rect2(x0, y0, tw, 11), Color("#d83828", la))
	_text(Vector2(x0 + 5, y0 + 1), tag, Color(1, 1, 1, la))
	draw_rect(Rect2(x0 + tw, y0, nw, 11), Color(0.1, 0.1, 0.16, 0.9 * la))
	_text(Vector2(x0 + tw + 7, y0 + 1), nm, Color("#f8e070", la))


## Lo que pasa alrededor del Pokémon mientras usa el Poder.
func _draw_power_fx(cls: String, t: float, c: Vector2, col: Color) -> void:
	match cls:
		"energy":
			# Chispas del color del tipo que suben en espiral
			for i in 10:
				var ph := fmod(t * 1.4 + i * 0.1, 1.0)
				var ang := TAU * i / 10.0 + t * 3.0
				var p := c + Vector2(cos(ang) * (22.0 - ph * 10.0), 18.0 - ph * 46.0)
				draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(col.lightened(0.4), 1.0 - ph))
		"heal":
			# Crucecitas verdes que suben
			for i in 7:
				var ph := fmod(t * 1.1 + i * 0.143, 1.0)
				var p := c + Vector2(-20 + i * 7, 14.0 - ph * 40.0)
				var a := 1.0 - ph
				draw_rect(Rect2(p.round() + Vector2(-1, -3), Vector2(3, 7)), Color("#58d868", a))
				draw_rect(Rect2(p.round() + Vector2(-3, -1), Vector2(7, 3)), Color("#58d868", a))
		"damage":
			# Un destello que sale hacia el rival
			var k := clampf((t - 0.25) / 0.35, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				_draw_burst(c + Vector2(0, -6), 6.0 + k * 14.0, Color(col.lightened(0.3), 1.0 - k), 8)
		_:
			# Estrellitas alrededor
			for i in 6:
				var ang := TAU * i / 6.0 + t * 2.0
				var p := c + Vector2(cos(ang), sin(ang) * 0.6) * (26.0 + sin(t * 8.0 + i) * 3.0)
				var on := int(t * 10.0 + i) % 3 != 0
				if on:
					draw_rect(Rect2(p.round() + Vector2(-1, 0), Vector2(3, 1)), Color(1, 1, 0.8))
					draw_rect(Rect2(p.round() + Vector2(0, -1), Vector2(1, 3)), Color(1, 1, 0.8))


func _start_trainer_anim(action: Dictionary) -> void:
	var p := game.actor()
	var pl: PlayerState = game.players[p]
	var id: String = pl.hand[action["h"]]
	var dest := _discard_spot(p)
	var prm: Dictionary = action.get("p", {})
	if CardDB.is_pokemon_tool(id) or CardDB.is_tm(id):
		if prm.has("tg"):
			dest = _slot_rect(p, prm["tg"]).get_center()
	elif CardDB.is_stadium(id):
		dest = Vector2(96, 43)
	trainer_anim = {"id": id, "p": p, "dest": dest, "t": 0.0}


func _update_trainer(delta: float) -> void:
	trainer_anim["t"] += delta / TRAINER_TIME
	if trainer_anim["t"] >= 1.0:
		if CardDB.is_supporter(trainer_anim["id"]):
			supporter_table[trainer_anim["p"]] = {"id": trainer_anim["id"], "turn": game.turn_number}
		var then = trainer_anim.get("then")
		trainer_anim = {}
		ai_timer = AI_DELAY
		if then is Callable:
			then.call()
		_rebuild_menu()


func _draw_trainer_card(center: Vector2, sc: float, id: String, a: float) -> void:
	var size := Vector2(48, 64) * sc
	var r := Rect2(center - size / 2.0, size)
	if size.x < 3:
		return
	draw_rect(Rect2(r.position + Vector2(2, 3) * sc, r.size), Color(0, 0, 0, 0.35 * a))
	_round_box(r, Color(C_PANEL, a), Color(C_TEXT, a))
	var img := Rect2(r.position + Vector2(3, 3) * sc, Vector2(42, 42) * sc)
	_draw_card_image(img, id)
	if sc > 0.8:
		var kind_col := C_POWER if CardDB.is_supporter(id) else (C_BODY if CardDB.is_stadium(id) else C_KEYS)
		draw_rect(Rect2(r.position.x + 3 * sc, r.position.y + 47 * sc, 42 * sc, 2), Color(kind_col, a))
		_text_fit(Vector2(r.position.x + 3 * sc, r.position.y + 50 * sc), CardDB.card_name(id), Color(C_TEXT, a), 42 * sc)


func _draw_trainer_anim() -> void:
	if trainer_anim.is_empty():
		return
	var t: float = trainer_anim["t"]
	var mine: bool = trainer_anim["p"] == human
	var center := Vector2(W / 2.0, 54)
	var start := Vector2(W / 2.0, H + 20) if mine else Vector2(W / 2.0, -30)
	var pos := center
	var sc := 1.0
	if t < 0.2:
		var k := t / 0.2
		k = k * k * (3.0 - 2.0 * k)
		pos = start.lerp(center, k)
		sc = lerpf(0.4, 1.0, k)
	elif t > 0.72:
		var k := (t - 0.72) / 0.28
		k = k * k
		pos = center.lerp(trainer_anim["dest"], k)
		sc = lerpf(1.0, 0.2, k)
	else:
		pos = center + Vector2(0, sin((t - 0.2) * 12.0) * 1.0)
		# Brillo detrás de la carta
		var glow := 1.0 - absf((t - 0.46) / 0.26)
		draw_circle(center, 44.0, Color(1, 1, 0.8, 0.10 + 0.10 * glow))
		draw_circle(center, 36.0, Color(1, 1, 0.8, 0.10 + 0.10 * glow))
	if t < 0.72:
		draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.3 * minf(1.0, t / 0.2)))
	_draw_trainer_card(pos, sc, trainer_anim["id"], 1.0)


func _draw_supporters_on_table() -> void:
	for p in 2:
		var st: Dictionary = supporter_table[p]
		if st.is_empty() or st["turn"] != game.turn_number:
			continue
		var pos := Vector2(132, 58) if p == human else Vector2(64, 33)
		var r := Rect2(pos, Vector2(16, 20))
		draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
		draw_rect(r, C_INK)
		draw_rect(r.grow(-1), Color("#f8f8e8"))
		_draw_card_image(Rect2(pos + Vector2(2, 2), Vector2(12, 12)), st["id"])
		draw_rect(Rect2(pos.x + 2, pos.y + 15, 12, 2), C_POWER)


# ===========================================================================
# Sonido (ver scenes/sound.gd: ahí está cómo poner tus propios archivos)
# ===========================================================================

## Flechas = "move", aceptar = "ok", volver = "back".
func _nav_sound(k: int, accept: bool, back: bool) -> void:
	if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		snd.play("move")
	elif accept:
		snd.play("ok")
	elif back:
		snd.play("back")


func _editor_sound(k: int, echo: bool) -> void:
	if not info_lines.is_empty():
		return
	if editor.screen == "rename":
		if k in [KEY_ENTER, KEY_KP_ENTER] and not echo:
			snd.play("ok")
		elif k == KEY_ESCAPE and not echo:
			snd.play("back")
		return
	if k in [KEY_UP, KEY_DOWN, KEY_TAB, KEY_PAGEUP, KEY_PAGEDOWN]:
		snd.play("move")
	elif editor.screen == "edit" and k in [KEY_RIGHT, KEY_Z, KEY_ENTER]:
		snd.play("ok")
	elif editor.screen == "edit" and k == KEY_LEFT:
		snd.play("back")
	elif k in [KEY_LEFT, KEY_RIGHT]:
		snd.play("move")
	elif k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not echo:
		snd.play("ok")
	elif k in [KEY_X, KEY_ESCAPE] and not echo:
		snd.play("back")


## Música según la pantalla: título/editor, duelo, y al terminar la de victoria o derrota.
func _update_music() -> void:
	if mode != "duel" or game == null:
		snd.music("decks" if mode == "editor" else "title")
		return
	if game.phase != "over":
		snd.music("battle")
		return
	# Fin de la partida: cuando terminan las animaciones pendientes (el último Premio, el KO)
	if over_sound_done or not (anim.is_empty() and ko_anim.is_empty() and check_anim.is_empty() and prize_anim.is_empty() and coin_anim.is_empty()):
		return
	over_sound_done = true
	var won: bool = game.winner == human
	snd.music("win" if won else "lose")
	snd.play("win" if won else "lose")


func _hit_sound() -> void:
	var extra := _attack_extra_sounds()
	if anim["dmg"] > 0 and anim.get("atk_dmg_text", "x") == "" and snd.fx(["contador_dano"]):
		_play_later(extra, 0.35)
		return            # ataque que solo pone contadores de daño (Haunt, Damage Curse...)
	if anim["dmg"] <= 0 and not extra.is_empty():
		_play_later(extra, 0.0)
		return            # ataque sin daño: suena solo su efecto (envenenar, dormir, curar...)
	_play_later(extra, 0.35)
	if anim["dmg"] > 0:
		if anim.get("weak", false) and snd.custom_weak:
			return            # el golpe a la Debilidad ya sonó con su propio sonido (super_efectivo)
		if anim.get("att_card", "") != "" and snd.hit(MiniBattle.sound_names(anim)):
			return
		snd.play("hit_" + str(anim["type"]))
	else:
		var special := MiniBattle.special_sound(anim)       # Wrap que solo paraliza, por ejemplo
		if special != "" and snd.hit([special]):
			return
		if snd.fx(["miss"]):
			return            # el ataque no hizo nada (la moneda salió cruz, por ejemplo)
		snd.play("trainer", 0.8)      # ataque sin daño: un "fiuu" suave


## Sonidos del efecto de un ataque, ya aplicado: el estado que le quedó al defensor
## (envenenar, paralizar, quemar, confundir, dormir: Hypnosis, Yawn o canto según el ataque)
## y la curación del atacante. Solo los que tienen archivo propio en sonidos/.
func _attack_extra_sounds() -> Array:
	var out: Array = []
	var mon: PokemonInPlay = anim.get("def_mon")
	if mon != null:
		var before: Array = anim.get("cond_before", [])
		var low := str(anim.get("atk_name", "")).to_lower()
		for c in _condition_list(mon):
			if before.has(c):
				continue
			match c:
				"poisoned": out.append(["envenenar"])
				"paralyzed": out.append(["paralizar"])
				"burned": out.append(["quemar"])
				"confused": out.append(["confundir"])
				"asleep":
					if low.contains("yawn"):
						out.append(["Yawn", "Hypnosis"])
					elif low.contains("sing") or low.contains("song") or low.contains("chime") or low.contains("noise"):
						out.append(["canto", "Hypnosis"])
					else:
						out.append(["Hypnosis", "canto"])
	var am: PokemonInPlay = anim.get("att_mon_s")
	if am != null and am.damage < int(anim.get("att_dmg_s", 0)):
		out.append(["cura_en_batalla"])
	return out


## Toca los sonidos de efecto uno detrás de otro, empezando después de "delay" segundos.
func _play_later(names_list: Array, delay: float) -> void:
	var t := delay
	for names in names_list:
		if t <= 0.0:
			snd.fx(names)
		else:
			get_tree().create_timer(t).timeout.connect(func(): snd.fx(names))
		t += 0.35


## El sonido de un Poké-Power según lo que hace (unir o mover Energía, curar, buscar en el
## mazo, cambiar Pokémon u otro).
func _power_sound_names(id: String, power: String) -> Array:
	var txt := ""
	for ab in CardDB.get_card(id).get("abilities", []):
		if str(ab.get("name", "")) == power:
			txt = str(ab.get("text", "")).to_lower()
	if txt.contains("energy") and (txt.contains("attach") or txt.contains("move")):
		return ["power_unir_energia", "power_otros"]
	if txt.contains("remove") and txt.contains("damage counter") or txt.contains("heal"):
		return ["power_curar", "power_otros"]
	if txt.contains("switch"):
		return ["power_cambio_pokemon", "power_otros"]
	if txt.contains("search") or txt.contains("draw"):
		return ["power_buscar_mazo", "power_otros"]
	return ["power_otros"]


## El sonido de un Entrenador: Supporter, uno que cura (Potion...) o un objeto.
func _trainer_sound_names(id: String) -> Array:
	var subs: Array = CardDB.subtypes(id)
	if "Supporter" in subs:
		return ["usar_soporte"]
	var txt := str(CardDB.get_card(id).get("text", "")).to_lower()
	if txt.contains("remove") and txt.contains("damage counter"):
		return ["cura_con_objeto", "usar_objeto"]
	return ["usar_objeto"]


## Efectos que acompañan a cada animación, en el mismo orden en que se muestran.
func _anim_sounds() -> void:
	if not power_anim.is_empty():
		if not power_anim.has("snd"):
			power_anim["snd"] = true
			if not snd.fx(_power_sound_names(str(power_anim["id"]), str(power_anim["name"]))):
				snd.play("evolve" if not power_anim["short"] else "trainer")
	elif not trainer_anim.is_empty():
		if not trainer_anim.has("snd"):
			trainer_anim["snd"] = true
			if not snd.fx(_trainer_sound_names(str(trainer_anim["id"]))):
				snd.play("trainer")
	elif not coin_anim.is_empty():
		var i: int = coin_anim["i"]
		if coin_anim.get("snd_i", -1) != i:
			coin_anim["snd_i"] = i
			snd.play("coin")
		if coin_anim["t"] >= 0.62 and coin_anim.get("res_i", -1) != i:
			coin_anim["res_i"] = i
			snd.play("heads" if coin_anim["results"][i] else "tails")
	elif not evo_anim.is_empty():
		var j: int = evo_anim["i"]
		if evo_anim.get("snd_i", -1) != j:
			evo_anim["snd_i"] = j
			snd.play("evolve")
		if evo_anim["t"] >= EVO_FLASH and evo_anim.get("res_i", -1) != j:
			evo_anim["res_i"] = j
			snd.play("evolved")
	elif not anim.is_empty():
		pass                          # el golpe suena en _update_anim, en el impacto
	elif not ko_anim.is_empty():
		if not ko_anim[0].has("snd"):
			ko_anim[0]["snd"] = true
			snd.play("ko")
	elif not energy_anim.is_empty():
		if energy_anim[0]["t"] >= 0.5 and not energy_anim[0].has("snd"):
			energy_anim[0]["snd"] = true
			snd.play("energy")
	elif not prize_anim.is_empty():
		if not prize_anim[0].get("choose", false) and not prize_anim[0].has("snd"):
			prize_anim[0]["snd"] = true
			snd.play("prize")
	elif not banner.is_empty():
		if not banner.has("snd"):
			banner["snd"] = true
			if banner.get("sudden", false):
				snd.play("evolved")
			else:
				snd.play("turn", 1.0 if banner["p"] == human else 0.84)
	elif not deck_anim.is_empty():
		if not deck_anim[0].has("snd"):
			deck_anim[0]["snd"] = true
			snd.play("shuffle" if deck_anim[0]["k"] == "shuffle" else "draw")


# ===========================================================================
# Menú de pausa
# ===========================================================================

func _open_pause() -> void:
	paused = true
	pause_cursor = 0
	pause_view = ""
	snd.play("ok")


func _pause_value(i: int) -> String:
	match i:
		1: return ANIM_SPEED_NAMES[anim_speed]
		2: return BATTLE_MODES[battle_mode]
		3: return SoundScript.LEVEL_NAMES[sfx_level]
		4: return SoundScript.LEVEL_NAMES[music_level]
		5: return table_styles[table_style][0]
	return ""


func _pause_change(i: int, d: int) -> void:
	match i:
		1: anim_speed = (anim_speed + d + ANIM_SPEEDS.size()) % ANIM_SPEEDS.size()
		2: battle_mode = (battle_mode + d + BATTLE_MODES.size()) % BATTLE_MODES.size()
		3, 4:
			if i == 3:
				sfx_level = (sfx_level + d + 4) % 4
			else:
				music_level = (music_level + d + 4) % 4
			snd.set_levels(sfx_level, music_level)
		5:
			table_style = (table_style + d + table_styles.size()) % table_styles.size()
			_table_tex = null
		_:
			return
	_save_settings()


func _pause_input(k: int, accept: bool, back: bool) -> void:
	if pause_view == "controls":
		if accept or back or k == KEY_P:
			pause_view = ""
			snd.play("back")
		return
	if pause_view == "quit":
		if k in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			quit_yes = not quit_yes
			snd.play("move")
		elif accept:
			if quit_yes:
				paused = false
				if net != null:
					net.send({"k": "concede"})
				game.concede(human)
				snd.play("back")
			else:
				pause_view = ""
				snd.play("back")
		elif back:
			pause_view = ""
			snd.play("back")
		return
	match k:
		KEY_UP:
			pause_cursor = (pause_cursor - 1 + PAUSE_ITEMS.size()) % PAUSE_ITEMS.size()
			snd.play("move")
		KEY_DOWN:
			pause_cursor = (pause_cursor + 1) % PAUSE_ITEMS.size()
			snd.play("move")
		KEY_LEFT, KEY_RIGHT:
			_pause_change(pause_cursor, 1 if k == KEY_RIGHT else -1)
			snd.play("move")
	if accept:
		match pause_cursor:
			0:
				paused = false
				snd.play("back")
			6:
				pause_view = "controls"
				snd.play("ok")
			7:
				pause_view = "quit"
				quit_yes = false
				snd.play("ok")
			_:
				_pause_change(pause_cursor, 1)
				snd.play("ok")
	elif back or k == KEY_P:
		paused = false
		snd.play("back")


const CONTROLS := [
	["Z", "A", "Accept"], ["X", "B", "Back"], ["Arrows", "D-Pad", "Move"],
	["P", "Start", "Pause"], ["C", "X", "View card"], ["B", "Y", "View table"],
	["M", "L", "Your hand"], ["D", "R", "Discard piles"], ["Tab", "Select", "Log"],
]


func _draw_pause() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.5))
	if pause_view == "controls":
		_page(Rect2(0, 0, W, H), Rect2(4, 3, W - 8, H - 19))
		_text(Vector2(10, 5), "CONTROLS", C_DIM)
		_text(Vector2(100, 5), "Keyboard", C_DIM)
		_text(Vector2(165, 5), "Control", C_DIM)
		for i in CONTROLS.size():
			var y := 18 + i * 12
			var row: Array = CONTROLS[i]
			_text(Vector2(10, y), row[2], C_TEXT)
			_text(Vector2(100, y), row[0], Color("#c03028"))
			_text(Vector2(165, y), row[1], C_FRAME_MID.darkened(0.3))
		_page_hint(Vector2(10, H - 14), "X in the menu also pauses")
		_page_hint(Vector2(W - 10 - _text_w("Z: back"), H - 14), "Z: back")
		return
	var r := Rect2(44, 14, 152, 111)
	_frame(r)
	_text_center(r.position.y + 4, "PAUSE", C_TEXT)
	for i in PAUSE_ITEMS.size():
		var y := r.position.y + 16 + i * 11
		var sel := i == pause_cursor
		if sel:
			_text(Vector2(r.position.x + 8, y), "▶", C_TEXT)
		_text(Vector2(r.position.x + 17, y), PAUSE_ITEMS[i], Color("#c03028") if i == 7 else C_TEXT)
		var v := _pause_value(i)
		if v != "":
			var vs := ("◀ " + v + " ▶") if sel else v
			_text(Vector2(r.end.x - 8 - _text_w(vs), y), vs, C_TEXT if sel else C_DIM)
	if pause_view == "quit":
		var q := Rect2(30, 122, 180, 36)
		_frame(q)
		_text(Vector2(q.position.x + 9, q.position.y + 4), "Concede? You lose this game.", C_TEXT)
		_text(Vector2(q.position.x + 30, q.position.y + 17), "No", C_TEXT)
		_text(Vector2(q.position.x + 100, q.position.y + 17), "Yes", C_TEXT)
		_text(Vector2(q.position.x + (92 if quit_yes else 22), q.position.y + 17), "▶", C_TEXT)


# ===========================================================================
# Pantalla de resultados
# ===========================================================================

func _results_showing() -> bool:
	return mode == "duel" and game != null and game.phase == "over" and anim.is_empty() and ko_anim.is_empty() and check_anim.is_empty() \
			and prize_anim.is_empty() and coin_anim.is_empty() and evo_anim.is_empty() and energy_anim.is_empty() \
			and trainer_anim.is_empty() and move_anim.is_empty() and power_anim.is_empty()


func _draw_results() -> void:
	_page(Rect2(0, 0, W, H), Rect2(3, 3, W - 6, H - 6))
	var won := game.winner == human
	var title := "YOU WON!" if won else ("DRAW" if game.winner == 2 else "YOU LOST")
	if won:
		_draw_confetti()
	var art := "ganaste" if won else ("empate" if game.winner == 2 else "perdiste")
	if _banner_art(art) != null:
		# Cae desde arriba con un rebote; si ganaste, además late de a ratos
		var drop := clampf(results_t / 0.45, 0.0, 1.0)
		var bounce := absf(sin(drop * PI * 1.5)) * (1.0 - drop) * 14.0
		var y := 14.0 - (1.0 - drop) * 30.0 - bounce
		var beat := 1.0
		if won and results_t > 0.6:
			var ph := fmod(results_t - 0.6, 1.4)
			beat = 1.0 + 0.12 * maxf(0.0, sin(ph / 0.25 * PI)) if ph < 0.25 else 1.0
		var tex := _banner_art(art)
		var sz := Vector2(tex.get_width(), tex.get_height())
		draw_set_transform(_base_off + Vector2(W / 2.0, roundf(y)), 0, Vector2(beat, beat))
		draw_texture(tex, (-sz / 2.0).round())
		draw_set_transform(_base_off)
	else:
		_text_center(5, title, Color("#c03028") if won else C_FRAME_MID.darkened(0.3), true)
	var reason := game.win_reason
	if _text_w(reason) > W - 16:
		_text_scroll(Vector2(8, 27), reason, C_DIM, W - 16, "res_reason")
	else:
		_text_center(27, reason, C_DIM)
	for side in 2:
		var pl := human if side == 0 else 1 - human
		var x := 6 + side * 116
		var bg := C_MINE_BG if side == 0 else C_OPP_BG
		draw_rect(Rect2(x, 40, 112, 12), bg.darkened(0.1))
		_text(Vector2(x + 4, 41), "YOU" if side == 0 else "OPPONENT", C_TEXT)
		# El Pokémon que más daño hizo
		var mvp := game.mvp(pl)
		var img := Rect2(x + 2, 56, MENU_IMG, MENU_IMG)
		if mvp.is_empty():
			_draw_card_back(img)
			_text(Vector2(x + 46, 60), "No damage", C_DIM)
		else:
			_draw_card_image(img, mvp["id"])
			_text(Vector2(x + 46, 55), "Top damage:", C_DIM)
			_text_scroll(Vector2(x + 46, 66), CardDB.card_name(mvp["id"]), C_TEXT, 64, "mvp%d" % side)
			_text(Vector2(x + 46, 77), "%d damage" % mvp["dmg"], Color("#c03028"))
		var prizes := game.prize_log.filter(func(e): return e["p"] == pl).size()
		var rows := [["Prizes", prizes], ["KO", game.stats[pl]["kos"]], ["Total damage", game.stats[pl]["dmg"]]]
		for j in rows.size():
			var y := 100 + j * 12
			_text(Vector2(x + 4, y), rows[j][0], C_TEXT)
			var v := str(rows[j][1])
			_text(Vector2(x + 108 - _text_w(v), y), v, C_TEXT)
	_draw_result_trainers(won)
	_text(Vector2(8, 145), "Turns: %d" % game.turn_number, C_DIM)
	var cont := "Z: continue" if campaign_rival != "" else "Z: back to title"
	_text(Vector2(W - 8 - _text_w(cont), 145), cont, C_TEXT)


## Confeti que cae detrás de todo cuando ganás.
func _draw_confetti() -> void:
	var cols := [Color("#f85838"), Color("#f8d030"), Color("#58a8f8"), Color("#68d058"), Color("#f878c8"), Color.WHITE]
	for i in 72:
		var spd := 22.0 + float(i % 5) * 7.0
		var y := fmod(results_t * spd + float(i * 37 % 170), H + 12.0) - 8.0
		var x := fmod(float(i * 53) + sin(results_t * 2.2 + i) * 6.0, W)
		var flip := int(results_t * 6.0 + i) % 2 == 0      # gira: a veces se ve de canto
		var sz := Vector2(3, 2) if flip else Vector2(2, 3)
		draw_rect(Rect2(Vector2(roundf(x), roundf(y)), sz), cols[i % cols.size()])


## Vos y el rival a los costados del título (los personajes del mapa): el que ganó salta
## de alegría; el que perdió se queda con la cabeza gacha, más oscuro y con una gotita.
## En un empate los dos se quedan quietos.
func _draw_result_trainers(won: bool) -> void:
	if campaign == null:
		return
	var draw_game := game.winner == 2
	for side in 2:
		var id := "jugador" if side == 0 else rival_sprite
		if id == "":
			continue
		var tex: Texture2D = campaign.world._sprite(id)
		if tex == null or tex.get_height() < 128:
			continue
		var winner := not draw_game and (won == (side == 0))
		var feet := Vector2(10 if side == 0 else W - 26, 37)
		var col := 0
		var tint := Color.WHITE
		if winner:
			# Saltitos: sube y baja (parábola) con una pausa entre salto y salto
			var ph := fmod(results_t, 0.7)
			if ph < 0.4:
				var k := ph / 0.4
				feet.y -= roundf(4.0 * k * (1.0 - k) * 4.0)
				col = 1 + int(results_t / 0.7) % 2      # piernas abiertas en el aire
		elif not draw_game:
			tint = Color(0.62, 0.62, 0.78)
			feet.y += 1
		draw_rect(Rect2(feet.x + 4, 37, 8, 2), Color(0, 0, 0, 0.25))     # sombra
		var dst := Rect2(feet + Vector2(0, -29), Vector2(16, 32))
		if not winner and not draw_game:
			# Cabeza gacha: la mitad de arriba se dibuja un píxel más abajo (encima del cuerpo)
			draw_texture_rect_region(tex, Rect2(dst.position + Vector2(0, 14), Vector2(16, 18)), Rect2(0, 14, 16, 18), tint)
			draw_texture_rect_region(tex, Rect2(dst.position + Vector2(0, 2), Vector2(16, 14)), Rect2(0, 0, 16, 14), tint)
			# Gotita de sudor
			var dp := dst.position + Vector2(13 if side == 0 else 1, 9 + fmod(results_t * 3.0, 3.0))
			draw_rect(Rect2(dp, Vector2(2, 3)), Color("#88c8f8"))
			draw_rect(Rect2(dp + Vector2(0.5, -1), Vector2(1, 1)), Color("#88c8f8"))
		else:
			draw_texture_rect_region(tex, dst, Rect2(col * 16, 0, 16, 32), tint)


# ===========================================================================
# Transiciones entre pantallas (cortina de franjas, como en GBA)
# ===========================================================================

var _trans := {}     # {"t", "then", "done"}
const TRANS_TIME := 0.45


## Cierra la cortina, cambia de pantalla (then) y la vuelve a abrir.
## Transiciones de pantalla. style:
##   "bands"   franjas que se cierran y se abren (la de siempre)
##   "door"    fundido a negro, como al cruzar una puerta (con su sonido)
##   "battle"  entrada a un duelo: destellos blancos y franjas que se cruzan desde los costados
const TRANS_STYLES := {"bands": [TRANS_TIME, 0.5], "door": [0.5, 0.5], "battle": [1.25, 0.72]}


func _go(then: Callable, style: String = "bands") -> void:
	if not _trans.is_empty():
		return
	_trans = {"t": 0.0, "then": then, "done": false, "style": style}
	match style:
		"door": snd.play("door")
		"battle": snd.play("encounter")


func _update_trans(delta_real: float) -> void:
	if _trans.is_empty():
		return
	var cfg: Array = TRANS_STYLES.get(_trans.get("style", "bands"), TRANS_STYLES["bands"])
	_trans["t"] += minf(delta_real, 1.0 / 30.0) / float(cfg[0])     # un cuadro lento no la saltea
	if _trans["t"] >= float(cfg[1]) and not _trans["done"]:
		_trans["done"] = true
		_trans["then"].call()
	if _trans["t"] >= 1.0:
		_trans = {}


func _draw_trans() -> void:
	if _trans.is_empty():
		return
	var t: float = _trans["t"]
	match _trans.get("style", "bands"):
		"door":
			var a := t * 2.0 if t < 0.5 else (1.0 - t) * 2.0
			draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(a * 1.15, 0.0, 1.0)))
		"battle":
			var mid := float(TRANS_STYLES["battle"][1])
			if t < 0.3:
				# Tres destellos blancos
				var f := fmod(t / 0.1, 1.0)
				draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, 0.85 * (1.0 - f)))
			elif t < mid:
				# Franjas negras que entran alternadas desde la izquierda y la derecha
				var k := clampf((t - 0.3) / (mid - 0.3), 0.0, 1.0)
				var n := 12
				var band := H / float(n)
				for i in n:
					var w := ceilf(W * clampf(k * 1.25 - (i % 3) * 0.08, 0.0, 1.0))
					var x := 0.0 if i % 2 == 0 else W - w
					draw_rect(Rect2(x, i * band, w, ceilf(band)), C_INK)
			else:
				# Ya en el duelo: la pantalla negra se abre desde el centro
				var k := clampf((t - mid) / (1.0 - mid), 0.0, 1.0)
				var h := (H / 2.0) * (1.0 - k * k)
				draw_rect(Rect2(0, 0, W, h), C_INK)
				draw_rect(Rect2(0, H - h, W, h), C_INK)
		_:
			var k := t * 2.0 if t < 0.5 else (1.0 - t) * 2.0     # 0 -> 1 (cerrada) -> 0
			for i in 10:
				var band := H / 10.0
				var h := ceilf(band * clampf(k * 1.4 - i * 0.04, 0.0, 1.0))
				draw_rect(Rect2(0, i * band, W, h), C_INK)


# ===========================================================================
# Joystick: cruceta, A, B, Start... se traducen a las teclas
# ===========================================================================

const JOY_KEYS := {
	JOY_BUTTON_A: KEY_Z, JOY_BUTTON_B: KEY_X, JOY_BUTTON_X: KEY_C, JOY_BUTTON_Y: KEY_B,
	JOY_BUTTON_START: KEY_P, JOY_BUTTON_BACK: KEY_TAB,
	JOY_BUTTON_LEFT_SHOULDER: KEY_M, JOY_BUTTON_RIGHT_SHOULDER: KEY_D,
	JOY_BUTTON_DPAD_UP: KEY_UP, JOY_BUTTON_DPAD_DOWN: KEY_DOWN,
	JOY_BUTTON_DPAD_LEFT: KEY_LEFT, JOY_BUTTON_DPAD_RIGHT: KEY_RIGHT,
}


func _joypad(event: InputEventJoypadButton) -> void:
	if not JOY_KEYS.has(event.button_index):
		return
	var k := InputEventKey.new()
	k.pressed = true
	k.keycode = JOY_KEYS[event.button_index]
	# En el título, Start también empieza (como en las consolas)
	if mode == "title" and event.button_index == JOY_BUTTON_START:
		k.keycode = KEY_Z
	_unhandled_input(k)
