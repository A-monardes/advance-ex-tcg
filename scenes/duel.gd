extends Node2D
## Pantalla de duelo estilo GBA (240x160). Solo dibuja y lee el teclado:
## todas las reglas viven en engine/. El jugador humano es el Jugador 1.
##
## Controles: Flechas = mover · Z / Enter = aceptar · X / Esc = volver
##            Tab = registro · C = ver carta · ←/→ en el título = cambiar opción

## Poké-Powers cuya elección ("b"/"tg") es un Pokémon del rival.
const OPP_POWERS := ["Dragon Wind", "Magnetic Flow", "Nectar Pod", "Splash Back", "Magnetic Reversal", "Dark Spell", "Distortion", "Dragon Curse", "Spike Storm", "Imprison"]
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
const C_ENERGY_RULE := Color("#28488c")   # Pokémon Holon's: su uso como Energía
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
const DuelMesaScript := preload("res://scenes/duel_mesa.gd")
var mesa = DuelMesaScript.new(self)     # La mesa: fondo y Estadio, cartas del Activo y de la Banca, recuadros de PS, Poké-Bodies, contadores y la mesa de dobles
const DuelTituloScript := preload("res://scenes/duel_titulo.gd")
var titulo = DuelTituloScript.new(self)     # Pantalla de título, menú principal y armado del duelo libre
const DuelPanelesScript := preload("res://scenes/duel_paneles.gd")
var paneles = DuelPanelesScript.new(self)     # Paneles del duelo: cuadro de texto y menús, registro, mano, recorrer la mesa, Premios, pausa y resultados
const DuelFichasScript := preload("res://scenes/duel_fichas.gd")
var fichas = DuelFichasScript.new(self)     # Fichas de cartas (C): ficha completa, vista partida de los Activos, arte en grande y galería
const DuelImagenesScript := preload("res://scenes/duel_imagenes.gd")
var imagenes = DuelImagenesScript.new(self)     # Imágenes de cartas: arte, recortes, holo y reverse holo, dorso, emblemas e íconos de Energía
const DuelAnimAtaquesScript := preload("res://scenes/duel_anim_ataques.gd")
var anim_ataques = DuelAnimAtaquesScript.new(self)     # Animaciones de ataque y de Pokémon que cambian de lugar, íconos de estado de Mystery Dungeon
const DuelAnimPokemonScript := preload("res://scenes/duel_anim_pokemon.gd")
var anim_pokemon = DuelAnimPokemonScript.new(self)     # Animaciones de los Pokémon: evolución, barra de vida, Fuera de Combate, brillo de los ex, espera, cartel de turno y daño a la Banca
const DuelAnimCartasScript := preload("res://scenes/duel_anim_cartas.gd")
var anim_cartas = DuelAnimCartasScript.new(self)     # Animaciones de cartas: unir Energía, tomar Premios, barajar y robar, Entrenadores y Poké-Powers
const DuelMonedasScript := preload("res://scenes/duel_monedas.gd")
var monedas = DuelMonedasScript.new(self)     # Animación de monedas (cara o cruz)
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
var free_cell := 5           # casilla elegida en el duelo libre (title_view "duel"; ver FREE_MOVES)
var free_popup := ""         # ventana abierta en el duelo libre: deck_me, deck_opp, diff, battle
var popup_cursor := 0
var popup_scroll := 0
## La campaña está en desarrollo: en el juego publicado aparece como "coming soon" y no se
## puede entrar. Desde el editor de Godot sí, para seguir trabajándola.
var CAMPAIGN_ON := OS.has_feature("editor")
var title_view := ""          # "" menú principal | "options" | "duel" (armado del duelo libre)
var opt_cursor := 0
var my_deck := 0
var opp_deck := 1
var season_idx := 0            # temporada elegida (RuleSet.SEASONS): sets legales y reglas de ese año
var format_upto := -1          # momento de la temporada (RuleSet.from_point): -1 = Mundial
var fmt_menu                   # pantalla para elegir el formato (scenes/format_menu.gd)
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
## Panel de Premios (tecla R): {"open", "t" 0..1 deslizamiento, "col" 0..3, "row" 0..2}.
## Columnas 0-1: Premios del rival (panel izquierdo); 2-3: los tuyos (derecho).
var prize_view := {}
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
var bench_fx: Array = []      # daño a la Banca: un estallido sobre cada carta: [{"p", "mon", "dmg", "t", "col", "rock"}]
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
	fmt_menu = load("res://scenes/format_menu.gd").new(self)
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
	if pmd_web.enabled():
		# Web: los Pokémon de la escena del título se bajan al abrir (si no, no se veían)
		pmd_web.listo.connect(func(sp: String): title_scene.forget(sp))
		for sp in title_scene.species():
			pmd_web.want(sp)
	arte = ArteHD.new()
	add_child(arte)
	arte.listo.connect(imagenes._on_arte_listo)
	RenderingServer.set_default_clear_color(C_BG)
	_setup_border.call_deferred()


# ===========================================================================
# Marco alrededor de la pantalla (scenes/marco_pantalla.gd)
# ===========================================================================
# Solo cuando el duelo es la escena principal (en las pruebas la pantalla queda de 240x160).

var border_on := true          # opción "Border": la pantalla va en el medio de 320x224
var _border: Node2D = null


func _setup_border() -> void:
	if get_tree() == null or get_tree().current_scene != self:
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_border = load("res://scenes/marco_pantalla.gd").new()
	_border.d = self
	layer.add_child(_border)
	_apply_border()


func _apply_border() -> void:
	if _border == null:
		return
	_border.visible = border_on
	position = _border.OFF if border_on else Vector2.ZERO
	var size := Vector2i(_border.FW, _border.FH) if border_on else Vector2i(W, H)
	get_window().content_scale_size = size
	_fit_window(size)


## En la computadora, la ventana más grande que entra en la pantalla (en múltiplos enteros).
func _fit_window(size: Vector2i) -> void:
	if OS.has_feature("web") or DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var scr := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var k := maxi(1, mini(mini((usable.size.x - 32) / size.x, (usable.size.y - 64) / size.y), 4))
	var win := get_window()
	win.size = size * k
	win.position = usable.position + (usable.size - win.size) / 2


## F11: pantalla completa (en la web la maneja el navegador).
func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		return
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if full:
		_fit_window(get_window().content_scale_size)


# ===========================================================================
# Flujo
# ===========================================================================

func _start_duel() -> void:
	var names := deck_names()
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
## Las reglas del formato elegido (temporada y momento).
func format_rules() -> RuleSet:
	return RuleSet.from_point(season_idx, format_upto)


func start_net_duel(link: NetLink, decks: Array, seed_value: int, season: int, doubles: bool, upto: int = -1) -> void:
	net = link
	net_in = 0
	net_out = 0
	net_lost = ""
	campaign_rival = ""
	reverse_ids = {}
	season_idx = season
	format_upto = upto
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
	var rules := format_rules() if campaign_rival == "" else RuleSet.from_season(season_idx)
	if doubles_mode and campaign_rival == "":
		rules = RuleSet.make_doubles(rules)
	game = Game.new(mine, theirs, seed_value, rules)
	# Elegís qué Premio tomar (reglas reales). En línea eligen los dos, cada uno en su compu.
	game.prize_pick = [true, true] if net != null else [human == 0, human == 1]
	pmd_web.want_cards(mine + theirs)          # web: baja los sprites de PMD de los dos mazos
	snd.jingle(["comenzar_partida"])      # la música del duelo arranca cuando termina
	game.log_msg(intro_line)
	game.log_msg("Rules: " + rules.name)
	ai = SimpleAI.new(0, level)
	game.ask_first = true
	game.start()
	mode = "duel"
	prize_view = {}
	show_log = false
	info_lines = []
	info_stack.clear()
	menu_level = "root"
	coins_seen = game.coin_log.size()
	coin_anim = {}
	monedas._load_coins()
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
		deck_anim.append({"k": "draw", "p": i, "ids": ids, "t": 0.0, "dur": anim_cartas._draw_duration(ids.size())})


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
	if not prize_view.is_empty():
		prize_view["t"] = clampf(prize_view["t"] + (1.0 if prize_view["open"] else -1.0) * delta_real / PV_TIME, 0.0, 1.0)
		if not prize_view["open"] and prize_view["t"] <= 0.0:
			prize_view = {}
	if mode == "duel" and paused:
		_update_music()
		queue_redraw()
		return
	var was_info := bool(_slides.get("info", {}).get("open", false))
	anim_cartas._slide_step("info", not info_lines.is_empty(), delta_real)
	anim_cartas._slide_step("hand", pile_view != "", delta_real)
	anim_cartas._slide_step("log", show_log, delta_real)
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
		anim_pokemon._update_hp(delta)
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
		if not anim_pokemon._waiting_human():
			idle_since = Clock.ms() / 1000.0
		anim_pokemon._update_ex_shine(delta)
		if paneles._results_showing():
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
		for j in range(prize_seen, game.prize_log.size()):
			var e: Dictionary = game.prize_log[j]
			# Vos elegís cuál de tus Premios tomar (el motor espera esa elección)
			var pick: bool = e.get("pick", false) and e["p"] == human
			if animations_on or pick:
				var d: Dictionary = e.duplicate()
				d["t"] = 0.0
				d["log"] = j
				d["choose"] = pick
				d["quick"] = not animations_on      # sin animaciones: solo el selector
				prize_anim.append(d)
		prize_seen = game.prize_log.size()
	if mode == "duel" and game.deck_log.size() > deck_seen:
		for e in game.deck_log.slice(deck_seen):
			if animations_on:
				var d: Dictionary = e.duplicate()
				d["t"] = 0.0
				d["dur"] = SHUFFLE_TIME if d["k"] == "shuffle" else anim_cartas._draw_duration(d["ids"].size())
				if d["k"] == "draw" and d["p"] == human and d["ids"].size() <= CU_MAX and game.phase != "setup":
					d["closeup"] = true
					d["dur"] = d["ids"].size() * (CU_IN + CU_HOLD + CU_OUT)
				deck_anim.append(d)
		deck_seen = game.deck_log.size()
	_update_music()
	if mode == "duel":
		_anim_sounds()
	mesa._update_body_pop(delta)
	if not power_anim.is_empty():
		anim_cartas._update_power(delta)
	elif not trainer_anim.is_empty():
		anim_cartas._update_trainer(delta)
	elif not coin_anim.is_empty():
		monedas._update_coins(delta)
	elif not evo_anim.is_empty():
		anim_pokemon._update_evo(delta)
	elif not anim.is_empty():
		anim_ataques._update_anim(delta)
	elif not bench_fx.is_empty():
		anim_pokemon._update_bench_fx(delta)
	elif not check_anim.is_empty():
		anim_pokemon._update_check(delta)
	elif not ko_anim.is_empty():
		anim_pokemon._update_ko(delta)
	elif not move_anim.is_empty():
		move_anim[0]["t"] += delta / float(move_anim[0]["dur"])
		if move_anim[0]["t"] >= 1.0:
			move_anim.pop_front()
			if move_anim.is_empty():
				ai_timer = AI_DELAY
				_rebuild_menu()
	elif not energy_anim.is_empty():
		anim_cartas._update_energy(delta)
	elif not prize_anim.is_empty():
		anim_cartas._update_prize(delta)
	elif not banner.is_empty():
		banner["t"] += delta / (BANNER_TIME * (2.5 if banner.get("sudden", false) else 1.0))
		if banner["t"] >= 1.0:
			banner = {}
			_rebuild_menu()
	elif not deck_anim.is_empty():
		anim_cartas._update_deck(delta)
	elif not vs_anim.is_empty():
		vs_anim["t"] += delta / SpecialFX.VS_TIME
		if vs_anim["t"] >= 1.0:
			vs_anim = {}
			_rebuild_menu()
	elif mode == "duel" and anim_ataques._check_vs():
		pass
	elif mode == "duel" and _check_setup_screen():
		pass
	elif mode == "duel" and game.pending_choice_kind() == "prize" and game.actor() == human:
		anim_cartas._ensure_prize_picker()
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
			# Ataques que no le hacen daño a nadie (buscar, robar, unir Energía...): como un
			# Poké-Power, el Pokémon sale de su carta y da dos saltos
			var style := anim_ataques._attack_style(action)
			if style == "effect" and anim_ataques._start_effect_attack(action, coins):
				return
			if style == "bench" and battle_mode == 1:
				# Solo le pega a la Banca: se aplica ya (y se elige a quién) y después el atacante
				# se gira y dispara a la carta elegida (ver _check_bench_hits)
				_bench_shot = anim_pokemon._bench_shot_info(action)
				if not coins.is_empty():
					_show_coins(coins, func(): _apply_now(action, coins[0].size()), _attack_label(action))
				else:
					_apply_now(action)
				return
			if not coins.is_empty():
				_show_coins(coins, func(): anim_ataques._start_attack_anim(action, coins[0].size()), _attack_label(action))
			else:
				anim_ataques._start_attack_anim(action, 0)
		"power":
			var then := func():
				if not coins.is_empty():
					_show_coins(coins, func(): _apply_now(action, coins[0].size()), "")
				else:
					_apply_now(action)
			if not anim_cartas._start_power_anim(action, then):
				then.call()
		"trainer":
			anim_cartas._start_trainer_anim(action)
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
	mesa._collect_body_events()
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
	return {"energy": anim_cartas._energy_snapshot(), "places": anim_ataques._places(), "phase": game.phase, "bench": anim_pokemon._bench_damage(),
			"piles": [[game.players[0].discard.duplicate(), game.players[0].hand.duplicate()],
					[game.players[1].discard.duplicate(), game.players[1].hand.duplicate()]]}


func _after_apply(before: Dictionary) -> void:
	monedas._check_coins()
	anim_pokemon._check_evolutions()
	anim_cartas._check_energy(before["energy"])
	_check_recovered(before["piles"])
	anim_ataques._check_moves(before)
	anim_pokemon._check_bench_hits(before)


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
			deck_anim.append({"k": "recover", "p": pi, "ids": ids, "t": 0.0, "dur": anim_cartas._draw_duration(ids.size()) + 0.3})


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
	if game.pending_choice_kind() == "prize":
		return            # se elige en el selector de Premios
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
		idle_since = Clock.ms() / 1000.0     # tocaste algo: el Activo deja de esperar
	if event is InputEventJoypadButton and event.pressed:
		_joypad(event)
		return
	if not (event is InputEventKey and event.pressed):
		return
	if not _trans.is_empty():
		return
	var k: int = event.keycode
	if k == KEY_F11 and not event.echo:
		_toggle_fullscreen()
		return
	var accept := k in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	var back := k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE]
	if mode == "duel" and not rival_intro.is_empty():
		if (accept or back) and not event.echo and rival_intro["t"] > 0.3:
			rival_intro["t"] = maxf(rival_intro["t"], RIVAL_INTRO_TIME - 0.25)    # Z la apura
		return
	if mode == "title":
		if title_attract:
			if (accept or k == KEY_ESCAPE) and not event.echo:
				snd.play("accept")
				_go(func(): title_attract = false, "iris")
			return
		if title_view == "online":
			online.input(event)
			return
		if title_view == "format":
			fmt_menu.input(k, accept and not event.echo, k in [KEY_X, KEY_ESCAPE, KEY_BACKSPACE] and not event.echo)
			return
		titulo._title_input(k, accept and not event.echo)
		return
	if mode == "campaign":
		if not info_lines.is_empty():      # la ficha de una carta (p. ej. desde un sobre)
			fichas._info_keys(k, accept, back, event.echo)
			return
		campaign.input(event)
		return
	if mode == "editor":
		if not info_lines.is_empty():
			fichas._info_keys(k, accept, back, event.echo)
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
		paneles._pause_input(k, accept and not event.echo, back and not event.echo)
		return
	if k == KEY_P and not event.echo and game.phase != "over" and intro == "":
		paneles._open_pause()
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
	if anim_cartas._deck_showing():
		if accept and not event.echo:
			deck_anim[0]["t"] = deck_anim[0]["dur"]     # Z la saltea
		return
	if anim_cartas._prize_showing() and prize_anim[0].get("choose", false):
		var n := paneles._prize_pile_size(prize_anim[0]["p"])
		if k in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			snd.play("move")
		match k:
			KEY_LEFT: prize_cursor = maxi(0, prize_cursor - 1)
			KEY_RIGHT: prize_cursor = mini(n - 1, prize_cursor + 1)
			KEY_UP: prize_cursor = maxi(0, prize_cursor - 2) if prize_cursor >= 2 else prize_cursor
			KEY_DOWN: prize_cursor = prize_cursor + 2 if prize_cursor + 2 < n else prize_cursor
		if accept and not event.echo:
			paneles._pick_prize(prize_cursor)
		return
	if not prize_anim.is_empty() and anim.is_empty() and energy_anim.is_empty():
		if accept and not event.echo:
			prize_anim[0]["t"] = maxf(prize_anim[0]["t"], 0.82)   # Z adelanta
		return
	if accept and not event.echo and anim_cartas._deck_showing() and deck_anim[0].get("closeup", false):
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
	if anim_pokemon._banner_showing():
		if accept and not event.echo:
			banner["t"] = maxf(banner["t"], 0.85)
		return
	if not info_lines.is_empty():
		fichas._info_keys(k, accept, back, event.echo)
		return
	if game.phase == "over":
		if accept and not event.echo and paneles._results_showing():
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
		paneles._hand_input(k, accept and not event.echo, back)
		return
	if board_view:
		_nav_sound(k, false, back and not event.echo)
		paneles._board_input(k, accept and not event.echo, back, event.echo)
		return
	if not prize_view.is_empty() and prize_view["open"]:
		paneles._prize_view_input(k, accept and not event.echo, (back or k == KEY_R) and not event.echo)
		return
	if k == KEY_R and not event.echo and paneles._prizes_revealed():
		paneles._open_prize_view()
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
		fichas._open_cursor_info()
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
		paneles._open_pause()        # X en el menú principal: pausa
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


const FREE_MOVES := {      # casilla -> [arriba, abajo, izquierda, derecha]
	0: [0, 1, 0, 3], 1: [0, 2, 1, 3], 2: [1, 2, 2, 3],
	3: [3, 3, 0, 4], 4: [4, 5, 3, 4], 5: [4, 5, 3, 5],
}


# ===========================================================================
# Dibujo
# ===========================================================================

func _draw() -> void:
	_draw_screen()
	if mode == "duel" and anim.get("scene", false) and not anim.get("waiting", false):
		if anim.get("mini", false):
			# Golpes que sacuden la pantalla (Earthquake, Stomp): la mini pelea tiembla
			var q := MiniBattle.quake(anim)
			_base_off = q
			draw_set_transform(q)
			MiniBattle.draw(self, anim)
			_base_off = Vector2.ZERO
			draw_set_transform(Vector2.ZERO)
		else:
			BattleScene.draw(self, anim)
	if mode == "duel" and net != null:
		_draw_net_overlay()
	_draw_trans()
	if gallery_id != "":
		fichas._draw_gallery()


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
		var dots := ".".repeat(1 + int(Clock.ms() / 400) % 3)
		var txt := "Waiting for the opponent" + dots
		var w := _text_w("Waiting for the opponent...") + 10
		var r := Rect2((W - w) / 2.0, 1, w, 12)
		draw_rect(r, Color(0.06, 0.08, 0.18, 0.8))
		_text(r.position + Vector2(5, 0), txt, Color("#f8f8f8"))


func _draw_screen() -> void:
	if mode == "title":
		titulo._draw_title()
		return
	if mode == "editor":
		editor.draw()
		if not info_lines.is_empty():
			anim_cartas._draw_slid(anim_cartas._slide_off("info") * H, fichas._draw_info)
		return
	if mode == "campaign":
		campaign.draw()
		if not info_lines.is_empty():
			anim_cartas._draw_slid(anim_cartas._slide_off("info") * H, fichas._draw_info)
		return
	var me := game.players[human]
	var opp := game.players[1 - human]
	var quake := anim_ataques._table_shake()
	if quake != Vector2.ZERO:
		_base_off = quake
		draw_set_transform(_base_off)
	mesa._draw_table()
	if game.stadium != "" and table_style == 0:     # con un fondo temático no se superpone
		if mesa._stage_name() == "":       # sin fondo de Ranger: el tenue de siempre
			mesa._draw_stadium_background(game.stadium)
	var dbl := _dbl() or doubles_preview
	if dbl:
		mesa._draw_doubles_board(opp, me)
	else:
		for pl: PlayerState in [opp, me]:
			mesa._draw_bench_cards(pl)
			mesa._draw_counters(pl)
	anim_cartas._draw_supporters_on_table()
	mesa._layout_stadium_tab()
	if game.stadium != "" and not dbl and not _stadium_layout.get("reserve", false):
		mesa._draw_stadium_card(game.stadium)
	for pl: PlayerState in ([] if dbl else [opp, me]):
		var off := anim_ataques._anim_offset(pl.index) + anim_pokemon._idle_bob(pl)
		if pl.active != null and anim_ataques._is_moving(pl.active):
			_outline(_card_rect(pl.index), C_LINE if pl == me else Color("#c87060"))
		elif pl.active != null:
			var ir := Rect2(_info_rect(pl.index).position + anim_pokemon._hp_shake(pl.active), INFO_SIZE)
			# Pestaña del Poké-Body: la tuya asoma arriba del cuadro (va detrás de él) y
			# la del rival cuelga abajo (va delante, sobre el borde)
			if not _dbl() and pl.index == human:
				mesa._draw_body_tab(ir, pl.active, false)
			mesa._draw_info_box(ir, pl.active)
			if not _dbl() and pl.index != human:
				mesa._draw_body_tab(ir, pl.active, true)
			mesa._draw_big_card(Rect2(_card_rect(pl.index).position + off, CARD_SIZE), pl.active)
			anim_ataques._draw_status_fx(pl)
			anim_ataques._draw_hit_flash(pl)
		else:
			_outline(_card_rect(pl.index), C_LINE if pl == me else Color("#c87060"))
	anim_ataques._draw_moves()
	anim_ataques._draw_anim()
	mesa._draw_stadium_entry()
	anim_pokemon._draw_check()
	anim_pokemon._draw_bench_fx()
	anim_pokemon._draw_ko()
	anim_pokemon._draw_evo()
	anim_pokemon._draw_ex_shine()
	paneles._draw_target_highlight()
	if quake != Vector2.ZERO:
		_base_off = Vector2.ZERO
		draw_set_transform(Vector2.ZERO)
	if menu_level == "confirm_end" and game.actor() == human:
		draw_rect(Rect2(0, 0, W, BOX_Y), Color(0, 0, 0, 0.45))     # la mesa se oscurece mientras pregunta
	if paneles._results_showing():
		paneles._draw_results()
		return
	mesa._draw_stadium_tab()
	paneles._draw_prize_hint()
	paneles._draw_prize_view()
	paneles._draw_textbox()
	anim_cartas._draw_energy_anim()
	anim_cartas._draw_trainer_anim()
	anim_cartas._draw_power_anim()
	anim_cartas._draw_prize()
	anim_pokemon._draw_banner()
	anim_cartas._draw_deck_anim()
	monedas._draw_coins()
	if not vs_anim.is_empty():
		SpecialFX.draw_vs(self, vs_anim)
	anim_pokemon._draw_rival_intro()
	if show_log:
		anim_cartas._draw_slid(anim_cartas._slide_off("log") * H, paneles._draw_full_log)
	if pile_view != "":
		anim_cartas._draw_slid(anim_cartas._slide_off("hand") * H, paneles._draw_hand)
	if setup_screen != "" and move_anim.is_empty() and deck_anim.is_empty():
		_draw_setup_screen()
	if not info_lines.is_empty():
		anim_cartas._draw_slid(anim_cartas._slide_off("info") * H, fichas._draw_info)
	elif _info_ghost_t >= 0.0:
		var keep := info_lines
		info_lines = _info_ghost
		anim_cartas._draw_slid(pow(_info_ghost_t, 2) * H, fichas._draw_info)
		info_lines = keep
	if paused:
		paneles._draw_pause()


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
				imagenes._draw_energy_icon(Vector2(x + 5, pos.y + 4.5), 10, TYPE_MARK.get(part.substr(0, 1), "Colorless"))
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
		return mesa._dbl_card_rect(player, dbl_focus[player])
	return Rect2(Vector2(4, 58) if player == human else Vector2(194, 1), CARD_SIZE)


func _art_rect(player: int) -> Rect2:
	if _dbl():
		return Rect2(_card_rect(player).position + Vector2(2, 2), Vector2(22, 22))
	return mesa._portrait_rect(_card_rect(player).position).grow(-1)


func _info_rect(player: int) -> Rect2:
	if _dbl():
		return mesa._dbl_info_rect(player, dbl_focus[player])
	return Rect2(Vector2(51, 70) if player == human else Vector2(111, 6), INFO_SIZE)


func _bench_rect(player: int, i: int) -> Rect2:
	if _dbl():
		return mesa._dbl_bench_rect(player, i)
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
		_table_tex = ImageTexture.create_from_image(mesa._table_image())
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


## Marco de texto de cada fondo de mesa (ui/marcos/, de Rubí/Zafiro/Esmeralda y RojoFuego/
## VerdeHoja). La clave es el nombre del archivo del fondo sin el número; la Clásica y los
## fondos que no están acá usan el marco de siempre (marco.png).
const FRAME_BY_TABLE := {"bosque": "rse_19", "sabana": "frlg_04", "desierto": "rse_14",
		"ciudad": "rse_16", "risco": "frlg_07", "volcan": "frlg_03", "nieve": "rse_11",
		"cueva": "rse_17", "playa": "frlg_06", "fondo marino": "frlg_05", "rio": "rse_06",
		"cielo": "rse_09", "lunares": "frlg_09", "maquina": "rse_04", "baldosas": "frlg_08",
		"estrellas": "rse_12", "liso": "frlg_02", "nostalgia": "rse_02", "pika": "rse_18",
		"johto": "rse_08", "kimono": "rse_07", "torchic": "rse_05", "dusclops": "rse_01",
		"zigzagoon": "rse_10", "whiscash": "frlg_01", "azumarill": "rse_13"}
var _frame_for := -1           # table_style para el que se eligió _frame_name
var _frame_name := "marco"


func _table_frame() -> String:
	if _frame_for != table_style:
		_frame_for = table_style
		_frame_name = "marco"
		if table_style > 0 and table_style < table_styles.size():
			var base: String = String(table_styles[table_style][1]).get_file()
			base = base.trim_suffix(".import").trim_suffix(".remap").get_basename()
			var rx := RegEx.new()
			rx.compile("^\\d+_")
			base = rx.sub(base, "").replace("_", " ")
			if FRAME_BY_TABLE.has(base) and _ui_tex("marcos/" + FRAME_BY_TABLE[base]) != null:
				_frame_name = "marcos/" + FRAME_BY_TABLE[base]
	return _frame_name


var _inset_cache := {}


## Píxeles de borde de un marco: desde el costado izquierdo hasta el blanco del centro.
func _frame_inset(name: String, tex: Texture2D) -> float:
	if not _inset_cache.has(name):
		var img := tex.get_image()
		var y := img.get_height() / 2
		var x := img.get_width() / 2
		var c := img.get_pixel(x, y)
		while x > 0 and img.get_pixel(x - 1, y) == c:
			x -= 1
		_inset_cache[name] = float(x)
	return _inset_cache[name]


## Recuadro de texto: el del fondo de mesa elegido, el de Rubí/Zafiro (marco.png) o, sin
## ninguno, el marco azul de siempre.
func _frame(r: Rect2) -> void:
	var name := _table_frame()
	var tex := _ui_tex(name)
	if tex != null and name != "marco" and r.size.x >= 16 and r.size.y >= 16:
		# Los bordes gruesos se corren hacia afuera para que el blanco de adentro quede donde
		# estaba el del marco de siempre (5 px) y el texto no toque el borde.
		var sz := tex.get_size()
		_nine(tex, r.grow(maxf(0.0, _frame_inset(name, tex) - 5.0)), minf(8.0, floorf(sz.x / 2.0) - 2.0))
		return
	tex = _ui_tex("marco")
	if tex != null and r.size.x >= 15 and r.size.y >= 15:
		_nine(tex, r, 7)
		return
	draw_rect(r, C_FRAME_OUT)
	draw_rect(r.grow(-1), C_FRAME_MID)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), C_FRAME_HI)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(1, r.size.y - 2)), C_FRAME_HI)
	draw_rect(r.grow(-3), C_FRAME_OUT)
	draw_rect(r.grow(-4), C_PANEL)


var _stage_cache := {}
const TAB_COLORS := {"body": [Color("#3c9848"), Color("#78d080")], "power": [Color("#d03828"), Color("#f88868")],
		"off": [Color("#8c8c94"), Color("#b0b0b8")]}
var _body_pops: Array = []     # en cola: [jugador, nombre]
var _body_pop := {}            # el que se ve: {"p", "name", "t"}
var _stadium_layout := {}
var doubles_preview := false        # maqueta de la mesa doble (mientras se arma el modo)

## Fondo intercalado de las listas y menús: los renglones impares un poco más oscuros, así
## cada opción se distingue de la de al lado. i es el número de renglón (desde 0).
const C_STRIPE := Color(0.16, 0.22, 0.42, 0.09)

func _stripe(r: Rect2, i: int) -> void:
	if i % 2 == 1:
		draw_rect(r, C_STRIPE)


var _cosmos := {}             # clave de textura -> {"base", "spark": [..]}


const LOG_LINES_FULL := 11


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
				entries.append(func(): return fichas._card_lines(rid, null))
		fichas._open_info(entries, setup_cursor, func(j: int): setup_cursor = j)


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
	var on := int(Clock.ms() / 300.0) % 2 == 0
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
			imagenes._draw_card_image(Rect2(cell.position + Vector2(2, 2), Vector2(22, 22)), id)
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
		var line := CardDB.card_name(sid) + " · " + paneles._card_kind(sid)
		if CardDB.is_pokemon(sid):
			line += " · HP %d" % CardDB.hp(sid)
		_text_scroll(Vector2(9, y), line, C_TEXT, W - 30 - hw, "setup_sel")
	elif sel.get("done", false):
		_text(Vector2(9, y), "Active: " + (me.active.display_name() if me.active != null else "—"), C_TEXT)
	_text(Vector2(W - 9 - hw, y), hint, C_DIM)


const REASON_COL := {"est_aviso": Color("#b02818"), "est_escudo": Color("#2858a8"), "est_mas": Color("#1c7a2c"),
		"est_menos": Color("#806030"), "est_poder": Color("#7838a8"), "est_poder_negado": Color("#707080")}


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
	var now := Clock.ms() / 1000.0
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


var _base_off := Vector2.ZERO        # desplazamiento de todo lo que se dibuja (ventanas que entran, temblores)
const SLIDE_TIME := 0.13             # lo que tarda una ventana en entrar o salir
var _slides := {}                    # ventana -> {"t", "open"}: ficha, mano, registro
var _info_ghost: Array = []          # la ficha que se acaba de cerrar (sale deslizándose)
var _info_ghost_t := -1.0
var _last_info: Array = []


var _energy_tex := {}


var _stadium_bg := {}


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
	mesa._find_table_styles()
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
		border_on = bool(cfg.get_value("graficos", "marco", true))
		ai_level = clampi(int(cfg.get_value("juego", "dificultad", 3)), 1, 5)
		var sid := str(cfg.get_value("juego", "temporada", RuleSet.SEASONS[0]["id"]))
		for i in RuleSet.SEASONS.size():
			if RuleSet.SEASONS[i]["id"] == sid:
				season_idx = i
		format_upto = clampi(int(cfg.get_value("juego", "temporada_hasta", -1)), -1, RuleSet.SEASONS[season_idx].get("steps", []).size() - 1)
		sfx_level = clampi(int(cfg.get_value("sonido", "efectos", 2)), 0, 3)
		music_level = clampi(int(cfg.get_value("sonido", "musica", 2)), 0, 3)
	_apply_graphics()


## Los mazos para elegir en el formato actual: los predefinidos de esa temporada (los que no
## dicen formato, si sus cartas son legales; los de la campaña no) y todos los del jugador. Con muchos mazos
## predefinidos la lista completa no sirve, así que se filtra; se guarda por formato.
var _deck_names_cache := {}


func deck_names() -> Array:
	var r := format_rules()
	var key := "%s/%d/%d" % [r.season, format_upto, Decks.user_names().size()]
	if not _deck_names_cache.has(key):
		var out: Array = []
		for nm in Decks.preset_names():
			if Decks.is_campaign(nm):
				continue
			var f := Decks.format_of(nm)
			if (f == "" or f == r.season) and _deck_legal(nm, r):
				out.append(nm)
		out.append_array(Decks.user_names())
		_deck_names_cache = {key: out}
	return _deck_names_cache[key]


## ¿Todas las cartas del mazo eran legales en la temporada?
func _deck_legal(deck_name: String, r: RuleSet) -> bool:
	return r.illegal_cards(Decks.get_deck(deck_name)).is_empty()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graficos", "mesa", table_styles[table_style][0])
	cfg.set_value("graficos", "animaciones", anim_speed)
	cfg.set_value("graficos", "batallas_modo", battle_mode)
	cfg.set_value("graficos", "marco", border_on)
	cfg.set_value("juego", "dificultad", ai_level)
	cfg.set_value("juego", "temporada", RuleSet.SEASONS[season_idx]["id"])
	cfg.set_value("juego", "temporada_hasta", format_upto)
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


var idle_since := 0.0


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
		for c in mesa._condition_list(mon):
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
# Transiciones entre pantallas (cortina de franjas, como en GBA)
# ===========================================================================

var _trans := {}     # {"t", "then", "done"}
const TRANS_TIME := 0.45


## Cierra la cortina, cambia de pantalla (then) y la vuelve a abrir.
## Transiciones de pantalla. style:
##   "bands"   franjas que se cierran y se abren (la de siempre)
##   "door"    fundido a negro, como al cruzar una puerta (con su sonido)
##   "battle"  entrada a un duelo: destellos blancos y franjas que se cruzan desde los costados
const TRANS_STYLES := {"bands": [TRANS_TIME, 0.5], "door": [0.5, 0.5], "battle": [1.25, 0.72], "iris": [1.0, 0.5]}


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


## Negro afuera de un círculo de radio r, con un borde de grises que se esfuma hacia adentro.
## Se dibuja por renglones para que quede en píxeles enteros.
const IRIS_RIM := [Color("#383838"), Color("#606060"), Color("#888888"), Color("#b0b0b0")]


func _draw_iris(c: Vector2, r: float) -> void:
	var rings: Array = [[INF, C_INK]]       # [radio exterior, color], de afuera hacia adentro
	var step := minf(3.0, r / 4.0)          # al cerrarse del todo no queda gris
	for i in IRIS_RIM.size():
		rings.append([r + (IRIS_RIM.size() - i) * step, IRIS_RIM[i]])
	for y in H:
		var dy := absf(y + 0.5 - c.y)
		for j in rings.size():
			var ro: float = rings[j][0]
			var ri: float = rings[j + 1][0] if j + 1 < rings.size() else r
			if ri <= 0.0:
				ri = 0.0
			var col: Color = rings[j][1]
			var hw_in := sqrt(maxf(ri * ri - dy * dy, 0.0)) if dy < ri else 0.0
			var hw_out := float(W) if is_inf(ro) else (sqrt(maxf(ro * ro - dy * dy, 0.0)) if dy < ro else 0.0)
			if hw_out <= hw_in:
				continue
			var a := roundf(c.x - hw_out)
			var b := roundf(c.x - hw_in)
			if b > a:
				draw_rect(Rect2(a, y, b - a, 1), col)
			a = roundf(c.x + hw_in)
			b = roundf(c.x + hw_out)
			if b > a:
				draw_rect(Rect2(a, y, b - a, 1), col)


func _draw_trans() -> void:
	if _trans.is_empty():
		return
	var t: float = _trans["t"]
	match _trans.get("style", "bands"):
		"iris":
			# Un círculo que se cierra sobre la pantalla y se vuelve a abrir (Pokémon Pinball)
			var k := t * 2.0 if t < 0.5 else (1.0 - t) * 2.0
			k = clampf(k * 1.15, 0.0, 1.0)
			_draw_iris(Vector2(W / 2.0, H / 2.0), (1.0 - k) * 160.0)
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
	JOY_BUTTON_RIGHT_STICK: KEY_R,
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


const PV_TIME := 0.18
var _bench_shot := {}          # ataque a la Banca que espera saber a quién le pegó (para el disparo)
