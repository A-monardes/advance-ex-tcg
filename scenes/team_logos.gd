class_name TeamLogos
## Logos de los equipos (Team Aqua, Team Magma y Team Rocket) para distinguir a sus Pokémon:
## en la pelea aparecen arriba del Pokémon y se desvanecen; en la mesa, de fondo en la ficha
## del Activo. Los arma tools/armar_equipos.py en mundo/propios/equipos/ (no se reparten con
## el código): sin esos archivos no se dibuja nada.

const DIR := "res://mundo/propios/equipos"

static var _tex := {}      # clave -> Texture2D (o null si no está el archivo)


## El equipo de una carta: "aqua", "magma", "rocket" o "" (los Dark no cuentan como Rocket).
static func team(id: String) -> String:
	if id == "":
		return ""
	var n := CardDB.card_name(id)
	if n.begins_with("Team Aqua's"):
		return "aqua"
	if n.begins_with("Team Magma's"):
		return "magma"
	if n.begins_with("Rocket's"):
		return "rocket"
	return ""


## El logo chico en pixel art (14 px de alto, con borde), para la pelea.
static func small(t: String) -> Texture2D:
	if t == "":
		return null
	if not _tex.has(t):
		var img := ImgLoad.load("%s/%s.png" % [DIR, t]) if ImgLoad.exists("%s/%s.png" % [DIR, t]) else null
		_tex[t] = ImageTexture.create_from_image(img) if img != null else null
	return _tex[t]


const TINT := {"aqua": Color("#3088d0"), "magma": Color("#c82028"), "rocket": Color("#c80000")}


## El logo a "h" píxeles de alto, de un solo color y con los bordes duros, para la ficha.
static func mark(t: String, h: int) -> Texture2D:
	if t == "" or h <= 0:
		return null
	var key := "%s@%d" % [t, h]
	if not _tex.has(key):
		var p := "%s/%s_fuente.png" % [DIR, t]
		var img := ImgLoad.load(p) if ImgLoad.exists(p) else null
		if img == null:
			_tex[key] = null
		else:
			img = img.duplicate()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(maxi(1, roundi(img.get_width() * float(h) / img.get_height())), h, Image.INTERPOLATE_LANCZOS)
			for y in img.get_height():
				for x in img.get_width():
					# De un solo color, el del equipo: las partes claras (el relleno celeste de
					# Aqua) quedan transparentes y se ve el dibujo de las líneas
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, Color(TINT[t], 1.0 if c.a > 0.5 and c.get_luminance() < 0.75 else 0.0))
			_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]
