extends Node2D
## Marco alrededor de la pantalla, como el del Super Game Boy o el de las GBA en otras
## consolas: la pantalla del juego (240x160) va en el medio de una de 320x224. En una pelea
## común el borde es negro; cuando dos rivales clásicos quedan como Activos (ver
## SpecialFX.screen_frame) aparece con un fundido el marco de su juego, y se va igual
## cuando uno de los dos deja de ser el Activo.
##
## Los marcos son PNG de 320x224 con el centro transparente, en
## mundo/propios/marcos_pantalla/ (red, green, blue, gold, silver, oras, hoenn). Si falta
## alguno, ese queda negro.

const FW := 320
const FH := 224
const OFF := Vector2(40, 32)        # dónde va la pantalla del juego adentro del marco
const DIRS := ["res://mundo/propios/marcos_pantalla", "user://mundo/propios/marcos_pantalla"]
const FADE := 0.6                   # segundos del fundido

var d                               # la escena del duelo
var cur := ""                       # marco que se ve (o se está yendo)
var alpha := 0.0
var _tex := {}


func _process(delta: float) -> void:
	if not visible:
		return
	var want := _wanted()
	var a0 := alpha
	if want != cur:
		alpha = maxf(0.0, alpha - delta / FADE)       # primero se va el que estaba
		if alpha <= 0.0:
			cur = want
	elif cur != "":
		alpha = minf(1.0, alpha + delta / FADE)
	if alpha != a0:
		queue_redraw()


## El marco que corresponde ahora: solo en la mesa de un duelo de a uno, con los dos
## Activos rivales.
func _wanted() -> String:
	if d == null or d.mode != "duel" or d.game == null or d.game.rules.doubles:
		return ""
	var mine: PokemonInPlay = d.game.players[d.human].active
	var theirs: PokemonInPlay = d.game.players[1 - d.human].active
	if mine == null or theirs == null:
		return ""
	var f: String = d.SpecialFX.screen_frame(CardDB.card_name(mine.top()), CardDB.card_name(theirs.top()))
	return f if _frame_tex(f) != null else ""


func _frame_tex(name: String) -> Texture2D:
	if name == "":
		return null
	if not _tex.has(name):
		var tex: Texture2D = null
		for dir in DIRS:
			var p: String = "%s/%s.png" % [dir, name]
			if tex == null and ImgLoad.exists(p):
				var img := ImgLoad.load(p)
				if img != null and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
		_tex[name] = tex
	return _tex[name]


func _draw() -> void:
	# Negro alrededor de la pantalla (lo que el juego dibuje de más queda tapado)
	var c := Color.BLACK
	draw_rect(Rect2(0, 0, FW, OFF.y), c)
	draw_rect(Rect2(0, OFF.y + 160, FW, FH - OFF.y - 160), c)
	draw_rect(Rect2(0, OFF.y, OFF.x, 160), c)
	draw_rect(Rect2(OFF.x + 240, OFF.y, FW - OFF.x - 240, 160), c)
	var tex := _frame_tex(cur)
	if tex != null and alpha > 0.0:
		draw_texture(tex, Vector2.ZERO, Color(1, 1, 1, alpha))
