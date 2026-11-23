extends RefCounted
## Animaciones especiales de algunos Pokémon (las demás usan la del tipo, en duel.gd).
##
##  · Ataque propio: Kyogre, Groudon, Rayquaza, Mew, Mewtwo, Zangoose, Seviper, Heracross,
##    Pinsir y los
##    iniciales de Kanto, Johto y Hoenn (con toda su línea evolutiva), solo cuando le
##    pegan a su rival. Los Básicos lo hacen más chico y las Fase 2 / ex, a todo trapo.
##  · Cara a cara: cuando dos rivales clásicos quedan como Activos (Kyogre y Groudon,
##    Zangoose y Seviper, Heracross y Pinsir, Mew y Mewtwo, Rayquaza con alguno de los dos, iniciales de
##    distinto tipo) aparece una escena corta de enfrentamiento, una vez por partida.
##
## Todo es procedural (formas, partículas y colores); los Pokémon solo aparecen con
## tus imágenes de sprites/. Para sumar uno nuevo: agregalo en SIGNATURE con una de
## las animaciones de draw_attack, y si tiene rival, en RIVALRIES.
##
## Si en efectos/propios/ hay tiras de cuadros (llama.png, ola.png, roca.png, ...; ver
## efectos/LEEME.txt), los ataques las usan en lugar de las formas dibujadas a mano.
## Cada tira es una fila de cuadros cuadrados: cuadros = ancho / alto.

const SIG_TIME := 1.7          # duración del ataque especial (s)
const SIG_IMPACT := 0.62       # momento del golpe (0..1)
const VS_TIME := 1.9           # duración del cara a cara (s)

## Especie -> animación de ataque
const SIGNATURE := {
	"Kyogre": "kyogre", "Groudon": "groudon", "Rayquaza": "rayquaza",
	"Mew": "mew", "Mewtwo": "mewtwo", "Zangoose": "zangoose", "Seviper": "seviper",
	"Charmander": "fuego1", "Charmeleon": "fuego1", "Charizard": "fuego1",
	"Bulbasaur": "planta1", "Ivysaur": "planta1", "Venusaur": "planta1",
	"Squirtle": "agua1", "Wartortle": "agua1", "Blastoise": "agua1",
	"Cyndaquil": "fuego2", "Quilava": "fuego2", "Typhlosion": "fuego2",
	"Chikorita": "planta2", "Bayleef": "planta2", "Meganium": "planta2",
	"Totodile": "agua2", "Croconaw": "agua2", "Feraligatr": "agua2",
	"Torchic": "fuego3", "Combusken": "fuego3", "Blaziken": "fuego3",
	"Treecko": "planta3", "Grovyle": "planta3", "Sceptile": "planta3",
	"Mudkip": "agua3", "Marshtomp": "agua3", "Swampert": "agua3",
	"Heracross": "heracross", "Pinsir": "pinsir",
}

## Rivales: [especie A, especie B, frase, color A, color B]
const RIVALRIES := [
	["Kyogre", "Groudon", "The sea against the land!", "#2860d8", "#d84020"],
	["Rayquaza", "Kyogre", "The sky comes down to restore order!", "#30a050", "#2860d8"],
	["Rayquaza", "Groudon", "The sky comes down to restore order!", "#30a050", "#d84020"],
	["Mew", "Mewtwo", "The original against its copy!", "#f088c0", "#8050c0"],
	["Zangoose", "Seviper", "Lifelong rivals!", "#e83838", "#7038a8"],
	["Heracross", "Pinsir", "Horn against pincers!", "#3858c8", "#a87838"],
]
const STARTER_COLORS := {"fuego": "#f06828", "agua": "#3880e8", "planta": "#40b040"}
const REGIONS := {"1": "Kanto", "2": "Johto", "3": "Hoenn"}


## "Team Aqua's Kyogre" -> "Kyogre", "Rayquaza ex" -> "Rayquaza", "Dark Celebi" -> "Celebi"
static func species(card_name: String) -> String:
	var words = card_name.split(" ", false)
	for i in range(words.size() - 1, -1, -1):
		var w = words[i]
		if w != "ex" and w != "δ" and w != "★" and w != "Star":
			return w
	return card_name


static func signature(card_name: String) -> String:
	return SIGNATURE.get(species(card_name), "")


## La animación propia solo se usa contra su rival: "" si el defensor no lo es.
static func signature_against(attacker: String, defender: String) -> String:
	if defender == "" or rivalry(attacker, defender).is_empty():
		return ""
	return signature(attacker)


## Tamaño del efecto según la fase: Básico 0.75, Fase 1 0.88, Fase 2 o ex 1.0.
static func power(card_id: String) -> float:
	if CardDB.is_ex(card_id):
		return 1.0
	return [0.75, 0.88, 1.0][clampi(CardDB.stage(card_id), 0, 2)]


## Escena de cara a cara para dos Activos, o {} si no son rivales.
## a = tu Pokémon (abajo), b = el del rival (arriba).
static func rivalry(name_a: String, name_b: String) -> Dictionary:
	var sa = species(name_a)
	var sb = species(name_b)
	for r in RIVALRIES:
		if sa == r[0] and sb == r[1]:
			return {"title": r[2], "ca": Color(r[3]), "cb": Color(r[4]), "key": r[0] + "|" + r[1]}
		if sa == r[1] and sb == r[0]:
			return {"title": r[2], "ca": Color(r[4]), "cb": Color(r[3]), "key": r[0] + "|" + r[1]}
	var fa: String = SIGNATURE.get(sa, "")
	var fb: String = SIGNATURE.get(sb, "")
	var ea = fa.rstrip("123")
	var eb = fb.rstrip("123")
	if STARTER_COLORS.has(ea) and STARTER_COLORS.has(eb) and ea != eb:
		var title = "Starter showdown!"
		if fa.right(1) == fb.right(1):
			title = "%s starter showdown!" % REGIONS[fa.right(1)]
		var key = [sa, sb]
		key.sort()
		return {"title": title, "ca": Color(STARTER_COLORS[ea]), "cb": Color(STARTER_COLORS[eb]),
				"key": "%s|%s" % key}
	return {}


# ===========================================================================
# Ataques
# ===========================================================================
# a: la animación de duel.gd ({"t", "from", "to", "seed", "power", "sig", "impact"}).
# Se dibuja sobre la mesa (240 x BOX_Y).

static func draw_attack(d, a: Dictionary, table_h: float) -> void:
	var t: float = a["t"]
	var imp: float = a.get("impact", SIG_IMPACT)
	var s = {
		"t": t,
		"travel": clampf(t / imp, 0.0, 1.0),
		"after": clampf((t - imp) / (1.0 - imp), 0.0, 1.0),
		"hit": t >= imp,
		"from": a["from"], "to": a["to"],
		"pw": float(a.get("power", 1.0)),
		"env": sin(clampf(t, 0.0, 1.0) * PI),      # sube y baja durante toda la animación
		"h": table_h,
	}
	var rng = RandomNumberGenerator.new()
	rng.seed = a["seed"]
	match a["sig"]:
		"kyogre": _kyogre(d, s, rng)
		"groudon": _groudon(d, s, rng)
		"rayquaza": _rayquaza(d, s, rng)
		"mewtwo": _mewtwo(d, s, rng)
		"mew": _mew(d, s, rng)
		"zangoose": _zangoose(d, s, rng)
		"seviper": _seviper(d, s, rng)
		"heracross": _horn_toss(d, s, rng)
		"pinsir": _pincer(d, s, rng)
		"fuego1": _flamethrower(d, s, rng)
		"fuego2": _flame_ring(d, s, rng)
		"fuego3": _blaze_kick(d, s, rng)
		"planta1": _vines(d, s, rng)
		"planta2": _petals(d, s, rng)
		"planta3": _leaf_blade(d, s, rng)
		"agua1": _bubbles(d, s, rng)
		"agua2": _water_jaws(d, s, rng)
		"agua3": _hydro_cannon(d, s, rng)


# --- Sprites de efectos (opcionales) ----------------------------------------------------
const FX_DIRS := ["res://efectos/propios", "user://efectos/propios"]
const FX_NAMES := ["llama", "ola", "roca", "explosion", "estrellas", "zarpazo", "colmillos",
		"hoja", "anillo", "rayo", "ascuas", "fuego_golpe", "fuego_espiral", "anillo_fuego",
		"burbuja_acida", "gas_veneno", "polvo_veneno", "lodo", "soleado", "lluvia"]
static var _fx_cache := {}
static var _fx_cells := {}     # nombre -> tamaño del cuadro (si no es cuadrado: <nombre>.json)


## La tira efectos/propios/<name>.png, o null si no está.
static func fx(name: String) -> Texture2D:
	if not _fx_cache.has(name) and name.ends_with("@gris"):
		# Versión en grises de una tira, para teñirla de otro color (colmillos de veneno o de agua)
		var base = fx(name.trim_suffix("@gris"))
		var tex: Texture2D = null
		if base != null:
			var img: Image = base.get_image()
			img.convert(Image.FORMAT_RGBA8)
			for y in img.get_height():
				for x in img.get_width():
					var c = img.get_pixel(x, y)
					var v = clampf(c.get_luminance() * 1.25, 0.0, 1.0)
					img.set_pixel(x, y, Color(v, v, v, c.a))
			tex = ImageTexture.create_from_image(img)
		_fx_cache[name] = tex
	if not _fx_cache.has(name):
		var tex: Texture2D = null
		for dir_path in FX_DIRS:
			var p = "%s/%s.png" % [dir_path, name]
			if tex == null and ImgLoad.exists(p):
				var img = ImgLoad.load(p)
				if img != null and not img.is_empty() and img.get_height() > 0:
					tex = ImageTexture.create_from_image(img)
		_fx_cache[name] = tex
	return _fx_cache[name]


static func has_fx(name: String) -> bool:
	return fx(name) != null


## Tamaño de cada cuadro: cuadrado (alto x alto) salvo que haya un <nombre>.json al lado
## con {"celda": [ancho, alto]} (las pantallas de clima, por ejemplo).
static func fx_cell(name: String) -> Vector2:
	if not _fx_cells.has(name):
		var tex = fx(name.trim_suffix("@gris"))
		var cell := Vector2.ZERO
		if tex != null:
			cell = Vector2(tex.get_height(), tex.get_height())
			for dir_path in FX_DIRS:
				var p = "%s/%s.json" % [dir_path, name.trim_suffix("@gris")]
				if ImgLoad.exists(p):
					var j = JSON.parse_string(FileAccess.get_file_as_string(p))
					if j is Dictionary and j.get("celda", []) is Array and j["celda"].size() == 2:
						cell = Vector2(float(j["celda"][0]), float(j["celda"][1]))
						break
		_fx_cells[name] = cell
	return _fx_cells[name]


## Cantidad de cuadros de la tira (0 si no está).
static func fx_count(name: String) -> int:
	var tex = fx(name)
	if tex == null:
		return 0
	return maxi(1, int(tex.get_width() / maxf(1.0, fx_cell(name).x)))


## Cuadro que toca cuando la animación va por k (0..1).
static func fx_frame(name: String, k: float) -> int:
	var n = fx_count(name)
	return clampi(int(k * n), 0, maxi(0, n - 1))


## Dibuja el cuadro `frame` de la tira centrado en pos (con escala, giro, espejo y tinte).
static func fx_draw(d, name: String, frame: int, pos: Vector2, scale: float = 1.0, alpha: float = 1.0,
		rot: float = 0.0, flip: bool = false, tint: Color = Color.WHITE) -> void:
	var tex = fx(name)
	if tex == null or alpha <= 0.0 or scale <= 0.0:
		return
	var cell := fx_cell(name)
	var n = maxi(1, int(tex.get_width() / cell.x))
	frame = posmod(frame, n)
	d.draw_set_transform(d._base_off + pos.round(), rot, Vector2(-scale if flip else scale, scale))
	d.draw_texture_rect_region(tex, Rect2(-cell / 2.0, cell), Rect2(frame * cell.x, 0, cell.x, cell.y),
			Color(tint, clampf(alpha, 0.0, 1.0) * tint.a))
	d.draw_set_transform(d._base_off, 0.0, Vector2.ONE)


## Dibuja un cuadro estirado a un rectángulo (las pantallas de clima sobre toda la mesa).
static func fx_draw_rect(d, name: String, frame: int, rect: Rect2, alpha: float = 1.0) -> void:
	var tex = fx(name)
	if tex == null or alpha <= 0.0:
		return
	var cell := fx_cell(name)
	var n = maxi(1, int(tex.get_width() / cell.x))
	d.draw_texture_rect_region(tex, rect, Rect2(posmod(frame, n) * cell.x, 0, cell.x, cell.y),
			Color(1, 1, 1, clampf(alpha, 0.0, 1.0)))


## Para los tests: vuelve a buscar las tiras (por si se agregaron o borraron).
static func fx_reload() -> void:
	_fx_cache.clear()
	_fx_cells.clear()


## Temblor extra del defensor para los golpes más fuertes.
static func shake(sig: String) -> float:
	return 6.0 if sig in ["kyogre", "groudon", "rayquaza", "mewtwo", "heracross"] else 4.0


static func _tint(d, s: Dictionary, c: Color, alpha: float) -> void:
	d.draw_rect(Rect2(0, 0, 240, s["h"]), Color(c, alpha * s["env"]))


static func _flash(d, s: Dictionary, c: Color, dur: float = 0.2) -> void:
	if s["hit"] and s["after"] < dur:
		d.draw_rect(Rect2(0, 0, 240, s["h"]), Color(c, 0.7 * (1.0 - s["after"] / dur)))


# --- Kyogre: lluvia torrencial y una ola enorme que rompe sobre el rival -------------
static func _kyogre(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var t: float = s["t"]
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var h: float = s["h"]
	_tint(d, s, Color("#102870"), 0.5)
	if has_fx("lluvia"):     # la lluvia de Mystery Dungeon, sobre toda la mesa
		var n := fx_count("lluvia")
		fx_draw_rect(d, "lluvia", 6 + int(t * 34.0) % maxi(1, n - 12), Rect2(0, 0, 240, h), minf(1.0, s["env"] * 2.0))
	else:
		for i in 40:     # lluvia en diagonal
			var x = fmod(rng.randf() * 260.0 + t * 260.0, 260.0) - 10.0
			var y = fmod(rng.randf() * h + t * 520.0, h + 10.0) - 10.0
			d.draw_line(Vector2(x, y), Vector2(x - 3, y + 7), Color("#a8d0f8", 0.8 * s["env"]), 1.0)
	if has_fx("ola"):
		_wave_sprite(d, s)
	else:
		_wave_drawn(d, s, rng)
	if s["hit"]:     # rompe: salpicadura grande
		for i in 18:
			var ang = -PI * rng.randf()
			var v = Vector2(cos(ang), sin(ang)) * rng.randf_range(14, 34) * s["pw"]
			var p: Vector2 = to + v * s["after"] + Vector2(0, 30 * s["after"] * s["after"])
			d.draw_circle(p, 2.5 * (1.0 - s["after"]) + 0.6, Color("#f0f8ff") if i % 3 == 0 else Color("#58a8f8"))
	_flash(d, s, Color("#c8e8ff"))


## La ola dibujada a mano (si no está efectos/propios/ola.png).
static func _wave_drawn(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var t: float = s["t"]
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var h: float = s["h"]
	# La ola avanza del atacante al defensor y crece hasta taparlo
	# Una pared de agua: detrás del frente es alta y pareja, adelante cae de golpe.
	var dirx = 1.0 if to.x >= from.x else -1.0
	var wx: float = lerpf(from.x - dirx * 30.0, to.x + dirx * 6.0, s["travel"])
	var top = clampf(h - to.y + 4.0, 30.0, h - 4.0)      # la cresta llega a la altura del rival
	var amp: float = top * (0.45 + 0.55 * s["travel"]) * (1.0 - s["after"] * 0.85)
	var pts = PackedVector2Array()
	var crest = PackedVector2Array()
	for xi in range(-4, 248, 3):
		var x = float(xi)
		var ahead = (x - wx) * dirx          # > 0: delante del frente
		var g = exp(-pow(ahead / 7.0, 2.0)) if ahead > 0.0 else 0.8 + 0.2 * exp(-pow(ahead / 26.0, 2.0))
		var y = h - 4.0 - amp * g - 2.0 * sin(x / 7.0 + t * 14.0) * g
		pts.append(Vector2(x, y))
		crest.append(Vector2(x, y))
	pts.append(Vector2(248, h))
	pts.append(Vector2(-4, h))
	d.draw_colored_polygon(pts, Color("#1848b8", 0.9))
	for k in 3:     # franjas más claras dentro de la ola
		var band = PackedVector2Array()
		for q in crest:
			band.append(q + Vector2(0, 8 + k * 12))
		d.draw_polyline(band, Color("#3068d0", 0.8), 1.0)
	d.draw_polyline(crest, Color("#58b8f8"), 3.0)
	d.draw_polyline(crest, Color("#f0f8ff"), 1.0)
	# Rulo de espuma en el frente
	var tip = Vector2(wx, h - 4.0 - amp)
	for i in 14:
		var ang = rng.randf() * PI + (0.0 if dirx > 0 else PI) - PI / 2.0
		var p = tip + Vector2(cos(ang) * dirx, sin(ang)) * rng.randf_range(2, 9)
		d.draw_rect(Rect2(p.floor(), Vector2(2, 2)), Color("#f8f8f8"))


## La ola de la tira: sube desde abajo, crece hasta la altura del rival y rompe sobre él.
static func _wave_sprite(d, s: Dictionary) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var h: float = s["h"]
	var right = to.x >= from.x
	var tr: float = s["travel"]
	var af: float = s["after"]
	var ease = 1.0 - pow(1.0 - tr, 2.0)
	# Alto del contenido de la ola en la tira: la mitad de abajo del cuadro (64 de 128)
	var target = (h + 6.0 - to.y + 10.0) / 64.0
	var sc: float = lerpf(0.55, target, ease) * lerpf(0.85, 1.0, s["pw"])
	var bottom: float = h + 6.0 + af * af * 70.0
	var x: float = lerpf(from.x + (-40.0 if right else 40.0), to.x + (6.0 if right else -6.0), ease)
	var bob = sin(s["t"] * 18.0) * 1.5
	var alpha = 1.0 - maxf(0.0, af - 0.55) / 0.45
	# Una ola más oscura detrás, un poco corrida, para que tenga cuerpo
	fx_draw(d, "ola", 1 if right else 0, Vector2(x - (18.0 if right else -18.0), bottom - 64.0 * sc * 0.92 + 6.0),
			sc * 0.92, alpha * 0.8, 0.0, false, Color("#7080d0"))
	fx_draw(d, "ola", 1 if right else 0, Vector2(x, bottom - 64.0 * sc + bob), sc, alpha)
	if s["hit"] and has_fx("anillo"):
		for i in 3:
			var k = clampf(af * 2.2 - i * 0.25, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				fx_draw(d, "anillo", 2 + fx_frame("anillo", k) % 3, to + Vector2((i - 1) * 16, 6 - i % 2 * 10), 0.9 * s["pw"])

# --- Groudon: sol abrasador, la tierra se agrieta y estalla magma -------------------
static func _groudon(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	_tint(d, s, Color("#c84008"), 0.4)
	if has_fx("soleado"):    # el sol de Mystery Dungeon cruzando la mesa
		fx_draw_rect(d, "soleado", fx_frame("soleado", clampf(s["t"] * 1.05, 0.0, 0.999)), Rect2(0, 0, 240, s["h"]),
				minf(1.0, s["env"] * 2.5))
	# Sol dibujado (si no está la tira del clima soleado)
	if not has_fx("soleado"):
		var sun = Vector2(120, 10)
		var r: float = 10.0 + 6.0 * s["env"]
		for i in 12:
			var ang = TAU * i / 12.0 + s["t"] * 2.0
			d.draw_line(sun + Vector2(cos(ang), sin(ang)) * (r + 2), sun + Vector2(cos(ang), sin(ang)) * (r + 7),
					Color("#f8e058", s["env"]), 2.0)
		d.draw_circle(sun, r, Color("#f8a820", s["env"]))
		d.draw_circle(sun, r * 0.65, Color("#f8f0a0", s["env"]))
	# Grieta que corre por el suelo
	var pts = PackedVector2Array([from])
	var n = 12
	for i in range(1, n + 1):
		var k = float(i) / n
		if k > s["travel"]:
			break
		pts.append(from.lerp(to, k) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)))
	if pts.size() > 1:
		d.draw_polyline(pts, Color("#501008"), 4.0)
		d.draw_polyline(pts, Color("#f87820"), 2.0)
		d.draw_polyline(pts, Color("#f8e870"), 1.0)
	if s["hit"]:
		var af: float = s["after"]
		for i in 3:      # columnas de magma
			var x: float = to.x + (i - 1) * 12.0 * s["pw"]
			var hh = (36.0 + i * 6.0) * s["pw"] * sin(minf(af * 1.6, 1.0) * PI * 0.5) * (1.0 - maxf(0.0, af - 0.6) * 2.5)
			if hh > 1.0:
				var w = 7.0 - absf(i - 1) * 2.0
				d.draw_rect(Rect2(x - w / 2, to.y + 14 - hh, w, hh), Color("#f05818"))
				d.draw_rect(Rect2(x - w / 4, to.y + 14 - hh, w / 2, hh), Color("#f8d048"))
		if has_fx("explosion") and af < 0.75:
			fx_draw(d, "explosion", fx_frame("explosion", af / 0.75), to + Vector2(0, 4), 1.2 * s["pw"])
		if has_fx("llama"):
			for i in 3:      # el magma prende fuego arriba de cada columna
				var k = clampf(af * 1.6 - i * 0.12, 0.0, 1.0)
				if k > 0.0 and af < 0.85:
					fx_draw(d, "llama", int(s["t"] * 22.0) + i * 3, to + Vector2((i - 1) * 14.0 * s["pw"], 2.0 - 10.0 * k),
							(0.45 + 0.15 * (1 - absi(i - 1))) * s["pw"], 1.0 - maxf(0.0, af - 0.6) / 0.25)
		for i in 12:     # piedras que vuelan
			var v = Vector2(rng.randf_range(-1, 1), -rng.randf_range(0.6, 1.2)) * 40.0 * s["pw"]
			var p: Vector2 = to + v * af + Vector2(0, 60 * af * af)
			if has_fx("roca"):
				fx_draw(d, "roca", 1 + i % 5, p, 0.7, 1.0, af * 6.0 * (1 if i % 2 else -1))
			else:
				d.draw_rect(Rect2(p.floor(), Vector2(3, 3)), Color("#784020") if i % 2 else Color("#f87820"))
	_flash(d, s, Color("#f8c060"))


# --- Rayquaza: una cinta verde baja en espiral desde el cielo y cae un rayo ----------
static func _rayquaza(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var t: float = s["t"]
	_tint(d, s, Color("#082818"), 0.55)
	# Vetas de viento
	for i in 14:
		var y = rng.randf() * s["h"]
		var x = fmod(rng.randf() * 300.0 + t * 400.0, 300.0) - 30.0
		d.draw_line(Vector2(x, y), Vector2(x + 18, y), Color("#c8f0d0", 0.35 * s["env"]), 1.0)
	if not s["hit"]:
		# Cinta: la cabeza baja en espiral hasta el defensor, el cuerpo la sigue
		var seg = 22
		for j in range(seg, -1, -1):
			var k: float = s["travel"] - j * 0.025
			if k < 0.0:
				continue
			var rad = (1.0 - k) * 34.0 + 4.0
			var ang = k * TAU * 1.6
			var p = Vector2(to.x + cos(ang) * rad, lerpf(-10.0, to.y, k) + sin(ang) * rad * 0.35)
			var w = 3.5 * s["pw"] * (1.0 - j / float(seg + 4)) + 1.0
			d.draw_circle(p, w, Color("#30a050"))
			if j % 4 == 0:
				d.draw_circle(p, w * 0.5, Color("#f8e048"))
	else:
		var af: float = s["after"]
		var bw: float = (10.0 * s["pw"]) * (1.0 - af)
		if bw > 0.5:     # rayo de luz vertical
			d.draw_rect(Rect2(to.x - bw / 2, 0, bw, to.y + 6), Color("#f8f8c0", 0.9))
			d.draw_rect(Rect2(to.x - bw / 4, 0, bw / 2, to.y + 6), Color("#ffffff"))
		for i in 3:      # anillos de onda expansiva
			var r = (af * 1.4 - i * 0.18) * 40.0 * s["pw"]
			if r > 0.0:
				d.draw_arc(to, r, 0, TAU, 32, Color("#78f0a0", maxf(0.0, 1.0 - af)), 2.0)
		if has_fx("explosion") and af < 0.7:
			fx_draw(d, "explosion", fx_frame("explosion", af / 0.7), to, 1.3 * s["pw"], 1.0, 0.0, false, Color("#c8ffc8"))
		if has_fx("estrellas"):
			for i in 6:      # destellos que salen despedidos
				var ang = TAU * i / 6.0 + 0.4
				var p = to + Vector2(cos(ang), sin(ang) * 0.7) * (10.0 + af * 40.0) * s["pw"]
				fx_draw(d, "estrellas", 1 + (i + int(af * 10.0)) % 4, p, 0.55 * (1.0 - af * 0.5), 1.0 - af)
	if not s["hit"] and has_fx("rayo"):
		for i in 3:          # relámpagos que caen alrededor mientras baja
			var k = fmod(s["travel"] * 2.5 + i * 0.33, 1.0)
			var x = to.x + (i - 1) * 34.0
			fx_draw(d, "rayo", fx_frame("rayo", k), Vector2(x, lerpf(-6.0, to.y - 8.0, k)), 0.8, 1.0 - k * 0.5, PI / 2.0)
	_flash(d, s, Color("#e8ffe8"), 0.25)


# --- Mewtwo: concentra una esfera oscura, la lanza y distorsiona la pantalla ----------
static func _mewtwo(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	_tint(d, s, Color("#300848"), 0.55)
	var tr: float = s["travel"]
	if not s["hit"]:
		var charge = clampf(tr / 0.6, 0.0, 1.0)
		var p = from if tr < 0.6 else from.lerp(to, (tr - 0.6) / 0.4)
		var r: float = (3.0 + 6.0 * charge) * s["pw"]
		for i in 8:      # partículas que se juntan
			var ang = TAU * i / 8.0 + s["t"] * 9.0
			var dist = (1.0 - charge) * 26.0 + r + 2.0
			d.draw_rect(Rect2((p + Vector2(cos(ang), sin(ang)) * dist).floor(), Vector2(2, 2)), Color("#d898f8"))
		d.draw_circle(p, r + 2, Color("#a058e0"))
		d.draw_circle(p, r, Color("#281038"))
		d.draw_arc(p, r, 0, TAU, 16, Color("#f0c8ff"), 1.0)
	else:
		var af: float = s["after"]
		for i in 6:      # bandas de distorsión
			var y = fmod(rng.randf() * s["h"] + af * 80.0, s["h"])
			d.draw_rect(Rect2(0, y, 240, 2), Color("#e0a0ff", 0.4 * (1.0 - af)))
		for i in 4:
			var r = (af * 1.5 - i * 0.15) * 34.0 * s["pw"]
			if r > 0.0:
				d.draw_arc(to, r, 0, TAU, 28, Color("#c070f8") if i % 2 == 0 else Color("#ffffff"), 1.0)
		if has_fx("explosion") and af < 0.7:
			fx_draw(d, "explosion", fx_frame("explosion", af / 0.7), to, 1.25 * s["pw"], 1.0, 0.0, false, Color("#d8a0ff"))
	_flash(d, s, Color("#f0d0ff"))


# --- Mew: burbujas rosadas que encierran al rival y estallan en destellos -------------
static func _mew(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	_tint(d, s, Color("#f8b0d8"), 0.3)
	for i in 7:
		var k = clampf(s["travel"] * 1.3 - i * 0.05, 0.0, 1.0)
		if k > 0.0 and k < 1.0:
			var p = from.lerp(to, k) + Vector2(sin(k * 9.0 + i) * 8.0, -sin(k * PI) * 14.0)
			d.draw_arc(p, 3.0 + i % 3, 0, TAU, 12, Color("#f888c8"), 1.0)
			d.draw_rect(Rect2(p + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)
	if s["hit"]:
		var af: float = s["after"]
		if af < 0.45:
			var r: float = 18.0 * s["pw"] * (1.0 + af * 0.3)
			d.draw_circle(to, r, Color("#f8b8e0", 0.35))
			d.draw_arc(to, r, 0, TAU, 28, Color("#f878c0"), 1.0)
		else:
			for i in 12:
				var ang = rng.randf() * TAU
				var p = to + Vector2(cos(ang), sin(ang)) * (af - 0.45) * 50.0
				if has_fx("estrellas"):
					fx_draw(d, "estrellas", 1 + (i + int(af * 12.0)) % 4, p, 0.75 * (1.2 - af), 1.0,
							0.0, false, Color("#ffd0f0"))
				else:
					d.anim_ataques._draw_burst(p, 3.0 * (1.0 - af) + 1.0, Color("#fff0f8"), 4)


# --- Zangoose: tres zarpazos rojos y una cruz -----------------------------------------
static func _zangoose(d, s: Dictionary, _rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	if not s["hit"]:
		if s["travel"] > 0.5:     # destello en las garras antes de saltar
			d.anim_ataques._draw_burst(from + Vector2(6, -6), 6.0 * (s["travel"] - 0.5) * 2.0, Color("#ffffff"), 4)
		return
	var af: float = s["after"]
	var L = 24.0 * s["pw"] + 6.0
	for i in 3:
		var k = clampf(af * 4.0 - i * 0.5, 0.0, 1.0)
		if k <= 0.0:
			continue
		var off = Vector2((i - 1) * 8, 0)
		var a: Vector2 = to + off + Vector2(-L / 2, -L / 2)
		var b: Vector2 = a.lerp(to + off + Vector2(L / 2, L / 2), k)
		var fade = 1.0 - maxf(0.0, af - 0.6) / 0.4
		d.draw_line(a, b, Color("#c01818", fade), 5.0)
		d.draw_line(a, b, Color("#ffffff", fade), 2.0)
	if has_fx("zarpazo"):
		# Dos zarpazos de la tira (uno y después otro espejado) sobre las marcas rojas
		for i in 2:
			var k = clampf((af - i * 0.28) / 0.5, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				fx_draw(d, "zarpazo", fx_frame("zarpazo", k), to + Vector2((i * 2 - 1) * 3, 0), 1.7 * s["pw"],
						1.0, 0.0, i == 1, Color("#ffd0c8"))
	if af > 0.45:
		var k = clampf((af - 0.45) * 4.0, 0.0, 1.0)
		var a = to + Vector2(L / 2 + 2, -L / 2 - 2)
		d.draw_line(a, a.lerp(to + Vector2(-L / 2 - 2, L / 2 + 2), k), Color("#f8f8f8", 1.0 - af), 2.0)
	_flash(d, s, Color("#ffd8d8"), 0.15)


# --- Seviper: una onda venenosa serpentea hasta el rival y lo muerde -------------------
static func _seviper(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var dirv: Vector2 = (to - from).normalized()
	var nrm = Vector2(-dirv.y, dirv.x)
	if not s["hit"]:
		var seg = 18
		for j in range(seg, -1, -1):
			var k: float = s["travel"] - j * 0.03
			if k < 0.0:
				continue
			var p = from.lerp(to, k) + nrm * sin(k * 14.0) * 7.0 * s["pw"]
			d.draw_circle(p, 2.6 - j * 0.08, Color("#6030a0") if j % 3 else Color("#e8c838"))
			if j % 6 == 0 and has_fx("burbuja_acida"):      # burbujas de ácido que va dejando
				fx_draw(d, "burbuja_acida", 3 + j / 6, p + nrm * 5.0, 0.45, 0.9, 0.0, false, Color("#e0a0ff"))
	else:
		var af: float = s["after"]
		var close = clampf(af * 3.0, 0.0, 1.0)
		if has_fx("colmillos"):
			_fangs(d, to, close, 1.0 - maxf(0.0, af - 0.5) * 2.0, s["pw"], Color("#c080ff"))
		for sgn in ([] if has_fx("colmillos") else [-1.0, 1.0]):     # colmillos que se cierran
			var base: Vector2 = to + Vector2(0, sgn * (16.0 - 10.0 * close))
			var tip: Vector2 = base + Vector2(0, -sgn * 8.0)
			for dx in [-5.0, 5.0]:
				d.draw_colored_polygon(PackedVector2Array([base + Vector2(dx - 2, 0), base + Vector2(dx + 2, 0),
						tip + Vector2(dx, 0)]), Color("#f8f8f8", 1.0 - maxf(0.0, af - 0.5) * 2.0))
		if af > 0.25 and poison_cloud(d, to, (af - 0.25) / 0.75, 1.1 * s["pw"]):
			pass          # después de la mordida, la nube de veneno del juego
		elif not has_fx("gas_veneno"):
			for i in 10:      # burbujas de veneno
				var p = to + Vector2(rng.randf_range(-14, 14), 10 - af * rng.randf_range(20, 40))
				d.draw_circle(p, 1.5 + (i % 2), Color("#b058e0", 1.0 - af))


## Golpe de fuego de la tira fuego_golpe (bola -> llamarada -> corona de fuego que se apaga),
## a lo largo de k (0..1). Devuelve false si no está la tira.
static func fire_hit(d, p: Vector2, k: float, scale: float) -> bool:
	if not has_fx("fuego_golpe") or k >= 1.0:
		return has_fx("fuego_golpe")
	fx_draw(d, "fuego_golpe", fx_frame("fuego_golpe", k), p + Vector2(0, -4), scale)
	return true


## Nube de veneno de la tira gas_veneno que crece y se deshace sobre p, a lo largo de k.
static func poison_cloud(d, p: Vector2, k: float, scale: float) -> bool:
	if not has_fx("gas_veneno") or k >= 1.0:
		return has_fx("gas_veneno")
	fx_draw(d, "gas_veneno", fx_frame("gas_veneno", k), p, scale)
	if has_fx("lodo") and k > 0.4:      # gotitas que suben
		fx_draw(d, "lodo", fx_frame("lodo", (k - 0.4) / 0.6), p + Vector2(10, -6), scale * 0.8, 0.9)
	return true


## Colmillos de la tira que se cierran sobre p (close 0 = abiertos, 1 = mordida).
static func _fangs(d, p: Vector2, close: float, alpha: float, pw: float, tint: Color) -> void:
	var gap: float = (18.0 - 13.0 * close) * pw
	fx_draw(d, "colmillos@gris", 0, p + Vector2(0, -gap), 1.1 * pw, alpha, 0.0, false, tint)
	fx_draw(d, "colmillos@gris", 0, p + Vector2(0, gap), 1.1 * pw, alpha, PI, false, tint)


# --- Heracross: carga con el cuerno y lanza al rival por el aire ----------------------
static func _horn_toss(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var dirv: Vector2 = (to - from).normalized()
	var nrm = Vector2(-dirv.y, dirv.x)
	if not s["hit"]:
		# Carga: líneas de velocidad detrás de una punta que avanza
		var head = from.lerp(to, s["travel"] * s["travel"])
		for i in 7:
			var off = nrm * (i - 3) * 3.0
			var tail = head - dirv * (14.0 + rng.randf() * 14.0) * s["pw"]
			d.draw_line(tail + off, head + off * 0.4 - dirv * 3.0, Color("#a8c0f8", 0.9), 2.0)
		var tip = head + dirv * 10.0 * s["pw"]
		d.draw_colored_polygon(PackedVector2Array([tip, head + nrm * 6.0 * s["pw"], head - nrm * 6.0 * s["pw"]]), Color("#2840a8"))
		d.draw_line(head, tip, Color("#d0e0ff"), 1.0)
		return
	var af: float = s["after"]
	# Golpe hacia arriba: arco que sube y estrella en el punto más alto
	var arc_h: float = 46.0 * s["pw"]
	var up = -1.0 if to.y > 50.0 else 0.6     # arriba del todo no hay lugar: lo lanza hacia el centro
	var k = clampf(af * 2.0, 0.0, 1.0)
	var pts = PackedVector2Array()
	for i in 11:
		var q = k * i / 10.0
		pts.append(to + Vector2(sin(q * PI * 0.5) * 16.0 * (1.0 if dirv.x >= 0 else -1.0), sin(q * PI * 0.5) * arc_h * up))
	if pts.size() > 1 and af < 0.75:
		d.draw_polyline(pts, Color("#203890", 1.0 - af), 7.0)
		d.draw_polyline(pts, Color("#5878e0", 1.0 - af), 4.0)
		d.draw_polyline(pts, Color("#f0f4ff", 1.0 - af), 1.0)
	if has_fx("explosion") and af < 0.6:
		fx_draw(d, "explosion", fx_frame("explosion", af / 0.6), to, 0.9 * s["pw"], 1.0, 0.0, false, Color("#c0d0ff"))
	elif af < 0.5:
		d.anim_ataques._draw_burst(to, (6.0 + af * 16.0) * s["pw"], Color("#ffffff"), 6)
		d.anim_ataques._draw_burst(to, (3.0 + af * 9.0) * s["pw"], Color("#5878e0"), 6)
	if af > 0.3:
		var top = pts[pts.size() - 1]
		if has_fx("estrellas"):
			fx_draw(d, "estrellas", 1 + int(af * 14.0) % 3, top, 0.8 * (1.1 - af), 1.0, 0.0, false, Color("#fff080"))
		else:
			d.anim_ataques._draw_burst(top, 9.0 * (1.0 - af) + 2.0, Color("#f8e048"), 5)
	_flash(d, s, Color("#e0e8ff"), 0.15)


# --- Pinsir: dos pinzas que se cierran y aprietan --------------------------------------
static func _pincer(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var r: float = 30.0 * s["pw"]
	var open: float
	var center: Vector2
	if not s["hit"]:
		center = from.lerp(to, s["travel"])
		open = 1.0
		r *= 0.6 + 0.4 * s["travel"]
	else:
		center = to
		open = 1.0 - clampf(s["after"] * 4.0, 0.0, 1.0)
	var fade = 1.0 - maxf(0.0, s["after"] - 0.6) / 0.4
	var gap = 0.25 + 0.55 * open          # ángulo de apertura de cada pinza
	for sgn in [-1.0, 1.0]:
		var c = center + Vector2(sgn * r * 0.55, 0)
		var a0 = (PI if sgn > 0 else 0.0) - gap * sgn
		var pts = PackedVector2Array()
		for i in 9:
			var a = a0 + (PI * 0.5 + gap) * sgn * -1.0 * i / 8.0
			pts.append(c + Vector2(cos(a), sin(a)) * r * 0.7)
		d.draw_polyline(pts, Color("#503010", fade), 8.0)
		d.draw_polyline(pts, Color("#c89850", fade), 5.0)
		d.draw_polyline(pts, Color("#f0d8a0", fade), 1.0)
		# Púas hacia adentro
		for i in [2, 4, 6]:
			var p: Vector2 = pts[i]
			d.draw_line(p, p + (center - p).normalized() * 5.0, Color("#f8f0d8", fade), 2.0)
	if s["hit"] and open <= 0.0:
		var af: float = s["after"]
		for i in 6:      # líneas de presión
			var ang = TAU * i / 6.0 + 0.3
			var p1 = to + Vector2(cos(ang), sin(ang)) * (r * 0.6 + af * 8.0)
			d.draw_line(p1, p1 + Vector2(cos(ang), sin(ang)) * 7.0, Color("#ffffff", fade), 2.0)
		if has_fx("explosion") and af > 0.25 and af < 0.75:
			fx_draw(d, "explosion", fx_frame("explosion", (af - 0.25) / 0.5), to, 0.8 * s["pw"], 1.0, 0.0, false, Color("#fff0c0"))
	_flash(d, s, Color("#fff0d0"), 0.12)


# --- Iniciales de fuego ----------------------------------------------------------------
## Kanto: un lanzallamas continuo que se abre en abanico.
static func _flamethrower(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var reach: float = s["travel"] if not s["hit"] else 1.0
	var fade: float = 1.0 - s["after"]
	if has_fx("fuego_espiral"):
		# Lanzallamas del juego: llamas en espiral que vuelan una tras otra y estallan
		if not s["hit"] or s["after"] < 0.3:
			for i in 6:
				var k = clampf(reach * 1.25 - i * 0.12, 0.0, 1.0)
				if k > 0.0 and k < 1.0:
					var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 6.0 * (i % 2 * 2 - 1))
					fx_draw(d, "fuego_espiral", int(s["t"] * 30.0) + i * 2, p, (0.55 + 0.35 * k) * s["pw"])
		if s["hit"]:
			fire_hit(d, to, s["after"] / 0.9, 1.15 * s["pw"])
		_flash(d, s, Color("#ffd080"), 0.12)
		return
	if has_fx("llama"):
		# Chorro de llamas de la tira: chicas en la boca, grandes al llegar
		var order = []
		for i in 16:
			order.append(fmod(rng.randf() + s["t"] * 2.2, 1.0))
		order.sort()
		for i in order.size():
			var k: float = order[i] * reach
			var p = from.lerp(to, k) + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * k * 7.0 * s["pw"]
			fx_draw(d, "llama", int(s["t"] * 24.0) + i, p, (0.22 + 0.42 * k) * s["pw"], fade)
		if s["hit"]:
			fx_draw(d, "llama", int(s["t"] * 20.0), to + Vector2(0, -2), 1.0 * s["pw"],
					1.0 - maxf(0.0, s["after"] - 0.5) * 2.0)
		_flash(d, s, Color("#ffd080"), 0.12)
		return
	for i in 34:
		var k = fmod(rng.randf() + s["t"] * 3.0, 1.0) * reach
		var spread = k * 9.0 * s["pw"]
		var p = from.lerp(to, k) + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
		var c = Color("#f8e050") if k < 0.3 else (Color("#f88020") if k < 0.7 else Color("#d83010"))
		d.draw_circle(p, (1.5 + k * 2.5) * s["pw"], Color(c, fade))
	_flash(d, s, Color("#ffd080"), 0.12)


## Johto: un anillo de llamas alrededor del atacante y una onda de fuego.
static func _flame_ring(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var tr: float = s["travel"]
	if has_fx("anillo_fuego"):
		# Anillo de llamas (Blast Burn): gira alrededor del atacante, viaja y estalla en el rival
		if not s["hit"]:
			var center = from if tr < 0.45 else from.lerp(to, (tr - 0.45) / 0.55)
			fx_draw(d, "anillo_fuego", int(s["t"] * 18.0) % 3, center, (0.35 + 0.25 * minf(1.0, tr / 0.45)) * s["pw"])
		else:
			var af: float = s["after"]
			var n := fx_count("anillo_fuego")
			fx_draw(d, "anillo_fuego", 3 + int(af * (n - 3)), to, 0.9 * s["pw"], 1.0 - maxf(0.0, af - 0.75) * 4.0)
		_flash(d, s, Color("#ffd080"), 0.15)
		return
	if not s["hit"]:
		var ring = clampf(tr / 0.5, 0.0, 1.0)
		var center = from if tr < 0.5 else from.lerp(to, (tr - 0.5) / 0.5)
		var r: float = 6.0 + 10.0 * ring * s["pw"]
		if has_fx("llama"):
			for i in 8:
				var ang = TAU * i / 8.0 + s["t"] * 8.0
				var p = center + Vector2(cos(ang), sin(ang) * 0.75) * (r + 2.0)
				fx_draw(d, "llama", int(s["t"] * 24.0) + i, p, 0.32 * s["pw"])
			_flash(d, s, Color("#ffd080"), 0.15)
			return
		for i in 14:
			var ang = TAU * i / 14.0 + s["t"] * 8.0
			var p = center + Vector2(cos(ang), sin(ang)) * r
			d.draw_circle(p, 2.5, Color("#f86818"))
			d.draw_circle(p + Vector2(0, -1), 1.2, Color("#f8e060"))
	elif has_fx("llama"):
		var af: float = s["after"]
		for i in 3:      # tres llamaradas que brotan debajo del rival
			var k = clampf(af * 2.5 - i * 0.2, 0.0, 1.0)
			if k > 0.0:
				var p = to + Vector2((i - 1) * 15.0 * s["pw"], 8.0 - 8.0 * sin(k * PI * 0.5))
				fx_draw(d, "llama", int(s["t"] * 22.0) + i * 2, p, (0.6 + 0.25 * (1 - absi(i - 1))) * s["pw"],
						1.0 - maxf(0.0, af - 0.6) / 0.4)
	else:
		var af: float = s["after"]
		for i in 16:
			var x = to.x + rng.randf_range(-12, 12) * s["pw"]
			var hh = rng.randf_range(10, 26) * s["pw"] * sin(minf(af * 2.0, 1.0) * PI * 0.5) * (1.0 - af)
			d.draw_line(Vector2(x, to.y + 14), Vector2(x, to.y + 14 - hh), Color("#f87020") if i % 2 else Color("#f8d040"), 2.0)
	_flash(d, s, Color("#ffd080"), 0.15)


## Hoenn: una patada envuelta en fuego que deja una estela en arco.
static func _blaze_kick(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var seg = 16
	for j in range(seg, -1, -1):
		var k: float = (s["travel"] if not s["hit"] else 1.0) - j * 0.04
		if k < 0.0 or (s["hit"] and s["after"] > 0.35):
			continue
		var p = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 26.0 * s["pw"])
		var w = (4.0 - j * 0.2) * s["pw"]
		if w > 0.5:
			d.draw_circle(p, w, Color("#f05010"))
			d.draw_circle(p, w * 0.55, Color("#f8e058"))
	if s["hit"]:
		var af: float = s["after"]
		if has_fx("fuego_golpe"):
			fire_hit(d, to, af / 0.85, 1.3 * s["pw"])
		elif has_fx("explosion"):
			if af < 0.8:
				fx_draw(d, "explosion", fx_frame("explosion", af / 0.8), to, 1.2 * s["pw"])
		else:
			d.anim_ataques._draw_burst(to, (8.0 + af * 18.0) * s["pw"], Color("#f8f0a0", 1.0 - af), 8)
			d.anim_ataques._draw_burst(to, (5.0 + af * 12.0) * s["pw"], Color("#f06020", 1.0 - af), 8)
		for i in 10:
			var ang = rng.randf() * TAU
			var p = to + Vector2(cos(ang), sin(ang)) * af * rng.randf_range(14, 28)
			d.draw_rect(Rect2(p.floor(), Vector2(2, 2)), Color("#f8d040"))
	_flash(d, s, Color("#fff0c0"), 0.12)


# --- Iniciales de planta ---------------------------------------------------------------
## Kanto: dos lianas que se estiran y dan un latigazo.
static func _vines(d, s: Dictionary, _rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var reach: float = s["travel"] if not s["hit"] else 1.0 - s["after"]
	var dirv: Vector2 = (to - from).normalized()
	var nrm = Vector2(-dirv.y, dirv.x)
	for sgn in [-1.0, 1.0]:
		var pts = PackedVector2Array()
		for i in 13:
			var k = reach * i / 12.0
			pts.append(from.lerp(to, k) + nrm * sgn * sin(k * PI) * 12.0 * s["pw"] + nrm * sin(k * 10.0 + s["t"] * 10.0) * 2.0)
		d.draw_polyline(pts, Color("#287820"), 3.0)
		d.draw_polyline(pts, Color("#68c840"), 1.0)
		for i in range(2, 13, 4):
			if has_fx("hoja"):
				fx_draw(d, "hoja", int(s["t"] * 10.0) + i, pts[i], 0.9, 1.0, 0.0, sgn < 0)
			else:
				d.anim_ataques._draw_leaf(pts[i], s["t"] * 6.0 + i, Color("#58b838"))
	if s["hit"] and s["after"] < 0.5:
		if has_fx("zarpazo"):     # el latigazo
			fx_draw(d, "zarpazo", fx_frame("zarpazo", s["after"] / 0.5), to, 1.1 * s["pw"], 1.0, 0.0, false, Color("#b0ff90"))
		else:
			d.anim_ataques._draw_burst(to, (6.0 + s["after"] * 14.0) * s["pw"], Color("#e8f8c0"), 6)


## Johto: hojas y pétalos que giran alrededor y caen en remolino.
static func _petals(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	for i in 15:
		var ph = TAU * i / 15.0
		var center: Vector2
		var r: float
		if not s["hit"]:
			center = from.lerp(to, s["travel"])
			r = 18.0 * s["pw"]
		else:
			center = to
			r = (20.0 - 14.0 * s["after"]) * s["pw"]
		var ang: float = ph + s["t"] * 10.0
		var p = center + Vector2(cos(ang), sin(ang) * 0.6) * r
		if i % 3 == 0:
			d.draw_circle(p, 2.5, Color("#f8a0c0"))
			d.draw_circle(p, 1.0, Color("#f8f0a0"))
		elif has_fx("hoja"):
			fx_draw(d, "hoja", int(ang * 1.5) + i, p, 0.9, 1.0, 0.0, i % 2 == 0,
					Color.WHITE if i % 2 else Color("#ffff90"))
		else:
			d.anim_ataques._draw_leaf(p, ang * 2.0, Color("#78d048") if i % 2 else Color("#f8e870"))
	if s["hit"] and s["after"] > 0.5:
		for i in 8:
			var a = rng.randf() * TAU
			d.draw_rect(Rect2((to + Vector2(cos(a), sin(a)) * (s["after"] - 0.5) * 40.0).floor(), Vector2(2, 2)), Color("#fff8d0"))


## Hoenn: dos hojas en forma de cuchilla que cortan en cruz.
static func _leaf_blade(d, s: Dictionary, _rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	if not s["hit"]:
		for i in 2:
			var k = clampf(s["travel"] * 1.2 - i * 0.15, 0.0, 1.0)
			if k > 0.0 and k < 1.0:
				var p = from.lerp(to, k) + Vector2(0, (i * 2 - 1) * sin(k * PI) * 12.0)
				var ang: float = s["t"] * 24.0 + i * PI
				d.draw_arc(p, 9.0 * s["pw"], ang, ang + PI * 0.8, 8, Color("#40c040"), 4.0)
				d.draw_arc(p, 9.0 * s["pw"], ang, ang + PI * 0.8, 8, Color("#d8f8a0"), 1.0)
		return
	var af: float = s["after"]
	var r: float = 24.0 * s["pw"]
	if has_fx("hoja"):      # hojas que saltan del corte
		for i in 6:
			var ang = -PI * (0.1 + 0.8 * i / 5.0)
			var p = to + Vector2(cos(ang), sin(ang)) * (6.0 + af * 30.0) + Vector2(0, 24.0 * af * af)
			fx_draw(d, "hoja", i + int(af * 12.0), p, 0.9, 1.0 - af, 0.0, i < 3)
	for i in 2:
		var k = clampf(af * 3.0 - i * 0.4, 0.0, 1.0)
		if k <= 0.0:
			continue
		var start = -PI * 0.75 if i == 0 else -PI * 0.25
		var sweep = (PI * 0.5) * k * (1.0 if i == 0 else -1.0)
		var c = Vector2(to.x + (i * 2 - 1) * -8.0, to.y + 8)
		var fade = 1.0 - maxf(0.0, af - 0.6) / 0.4
		d.draw_arc(c, r, start, start + sweep, 14, Color("#208020", fade), 6.0)
		d.draw_arc(c, r, start, start + sweep, 14, Color("#78e050", fade), 3.0)
		d.draw_arc(c, r, start, start + sweep, 14, Color("#f0fff0", fade), 1.0)
	_flash(d, s, Color("#e0ffe0"), 0.12)


# --- Iniciales de agua -----------------------------------------------------------------
## Kanto: una ráfaga de burbujas que revientan.
static func _bubbles(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	for i in 16:
		var delay = i * 0.035
		var k = clampf((s["travel"] - delay) / (1.0 - 0.55), 0.0, 1.0)
		var off = Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		if k <= 0.0:
			continue
		if not s["hit"] or s["after"] < 0.3:
			var p = from.lerp(to + off, k) + Vector2(0, -sin(k * PI) * rng.randf_range(4, 16))
			var r = (3.0 + i % 3 * 1.5) * s["pw"]
			d.draw_circle(p, r, Color("#a8dcf8", 0.45))
			d.draw_arc(p, r, 0, TAU, 12, Color("#3890e8"), 1.0)
			d.draw_rect(Rect2(p + Vector2(-r * 0.5, -r * 0.5), Vector2(1, 1)), Color.WHITE)
		elif has_fx("anillo"):     # cada burbuja revienta en un anillo de agua
			var kp = clampf((s["after"] - 0.3 - (i % 4) * 0.05) / 0.5, 0.0, 1.0)
			if kp > 0.0 and kp < 1.0:
				fx_draw(d, "anillo", 2 + fx_frame("anillo", kp) % 3, to + off, 0.45 * s["pw"])
		else:
			var a = rng.randf() * TAU
			d.draw_rect(Rect2((to + off + Vector2(cos(a), sin(a)) * s["after"] * 12.0).floor(), Vector2(2, 2)), Color("#e0f4ff"))


## Johto: dos mandíbulas de agua que se cierran sobre el rival.
static func _water_jaws(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	if not s["hit"]:
		var p = from.lerp(to, s["travel"])
		for i in 8:
			d.draw_circle(p - (to - from).normalized() * i * 4.0, 4.5 - i * 0.45, Color("#3878e0"))
			d.draw_circle(p - (to - from).normalized() * i * 4.0, 2.0 - i * 0.2, Color("#c0e0ff"))
		return
	var af: float = s["after"]
	var open = 1.0 - clampf(af * 3.5, 0.0, 1.0)
	var r: float = 22.0 * s["pw"]
	var fade = 1.0 - maxf(0.0, af - 0.5) * 2.0
	if has_fx("colmillos"):
		_fangs(d, to, 1.0 - open, fade, s["pw"], Color("#80c0ff"))
		if has_fx("anillo") and af > 0.3 and af < 0.9:
			fx_draw(d, "anillo", 2 + fx_frame("anillo", (af - 0.3) / 0.6) % 3, to, 1.0 * s["pw"])
		return
	d.draw_arc(to + Vector2(0, -4 - open * 8), r, PI * 0.15, PI * 0.85, 12, Color("#3070d8", fade), 4.0)
	d.draw_arc(to + Vector2(0, 4 + open * 8), r, -PI * 0.85, -PI * 0.15, 12, Color("#3070d8", fade), 4.0)
	for i in 4:      # dientes
		var x = to.x - 9 + i * 6
		d.draw_colored_polygon(PackedVector2Array([Vector2(x, to.y - 4 - open * 8 + r * 0.2), Vector2(x + 3, to.y - 4 - open * 8 + r * 0.2),
				Vector2(x + 1.5, to.y + 2 - open * 8 + r * 0.2)]), Color("#f0f8ff", fade))
	if af > 0.3:
		for i in 10:
			var a = -PI * rng.randf()
			var p = to + Vector2(cos(a), sin(a)) * (af - 0.3) * 40.0 + Vector2(0, 20 * af * af)
			d.draw_circle(p, 1.5, Color("#78b8f8"))


## Hoenn: un chorro a presión en espiral, con salpicadura de barro.
static func _hydro_cannon(d, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var to: Vector2 = s["to"]
	var from: Vector2 = s["from"]
	var dirv: Vector2 = (to - from).normalized()
	var nrm = Vector2(-dirv.y, dirv.x)
	var reach: float = s["travel"] if not s["hit"] else 1.0
	var w: float = 4.0 * s["pw"] * (1.0 - s["after"])
	if w > 0.4:
		var head = from.lerp(to, reach)
		d.draw_line(from, head, Color("#2058c0"), w * 2.0)
		d.draw_line(from, head, Color("#78c0f8"), w)
		for i in 8:     # anillos de la espiral
			var k = fmod(i / 8.0 + s["t"] * 2.0, 1.0) * reach
			var p = from.lerp(to, k)
			d.draw_line(p - nrm * (w + 2), p + nrm * (w + 2), Color("#e0f4ff"), 1.0)
	if s["hit"]:
		var af: float = s["after"]
		for i in 16:
			var a = -PI * rng.randf()
			var v = Vector2(cos(a), sin(a)) * rng.randf_range(12, 30) * s["pw"]
			var p: Vector2 = to + v * af + Vector2(0, 26 * af * af)
			d.draw_circle(p, 2.2 * (1.0 - af) + 0.6, Color("#906838") if i % 3 == 0 else Color("#58a0f0"))
		if has_fx("anillo") and af < 0.8:
			fx_draw(d, "anillo", fx_frame("anillo", af / 0.8), to, 1.5 * s["pw"])
		if has_fx("roca"):      # piedras de barro que salen despedidas
			for i in 4:
				var a = -PI * (0.2 + 0.2 * i)
				var p: Vector2 = to + Vector2(cos(a), sin(a)) * af * 34.0 * s["pw"] + Vector2(0, 40 * af * af)
				fx_draw(d, "roca", 2 + i, p, 0.6, 1.0 - af, af * 5.0)
	_flash(d, s, Color("#d8f0ff"), 0.12)


# ===========================================================================
# Cara a cara
# ===========================================================================
# v: {"t" (0..1), "a", "b" (ids de carta: el tuyo y el del rival), "title", "ca", "cb"}

static func draw_vs(d, v: Dictionary) -> void:
	var t: float = v["t"]
	var slide = 1.0
	if t < 0.14:
		var k = t / 0.14
		slide = k * k * (3.0 - 2.0 * k)
	elif t > 0.86:
		var k = (t - 0.86) / 0.14
		slide = 1.0 - k * k
	var dx = (1.0 - slide) * 260.0
	d.draw_rect(Rect2(0, 0, 240, 160), Color(0, 0, 0, 0.55 * slide))
	var ca: Color = v["ca"]
	var cb: Color = v["cb"]
	# Dos paneles en diagonal: el tuyo entra desde la izquierda (abajo), el rival desde la derecha (arriba)
	d.draw_colored_polygon(PackedVector2Array([Vector2(-dx, 34), Vector2(150 - dx, 34), Vector2(110 - dx, 126),
			Vector2(-dx, 126)]), ca.darkened(0.15))
	d.draw_colored_polygon(PackedVector2Array([Vector2(150 + dx, 34), Vector2(240 + dx, 34), Vector2(240 + dx, 126),
			Vector2(110 + dx, 126)]), cb.darkened(0.15))
	# Líneas de velocidad
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in 10:
		var y = 38.0 + rng.randf() * 84.0
		var x = fmod(rng.randf() * 160.0 + t * 500.0, 160.0)
		d.draw_line(Vector2(x - 40 - dx, y), Vector2(x - 20 - dx, y), Color(ca.lightened(0.45), 0.7), 1.0)
		var y2 = 38.0 + rng.randf() * 84.0
		var x2 = 240.0 - fmod(rng.randf() * 160.0 + t * 500.0, 160.0)
		d.draw_line(Vector2(x2 + 20 + dx, y2), Vector2(x2 + 40 + dx, y2), Color(cb.lightened(0.45), 0.7), 1.0)
	# Bordes blancos
	d.draw_rect(Rect2(-dx, 32, 240, 2), Color.WHITE)
	d.draw_rect(Rect2(dx, 126, 240, 2), Color.WHITE)
	d.draw_line(Vector2(150, 34), Vector2(110, 126), Color(1, 1, 1, slide), 2.0)
	# Pokémon
	_vs_mon(d, Vector2(20 - dx, 56), v["a"], ca)
	_vs_mon(d, Vector2(164 + dx, 42), v["b"], cb)
	# "VS" con un destello cuando llega
	if t > 0.16 and t < 0.9:
		var k = clampf((t - 0.16) / 0.08, 0.0, 1.0)
		if k < 1.0 or int(t * 20) % 6 != 0:
			d.anim_ataques._draw_burst(Vector2(130, 80), 14.0 + 6.0 * (1.0 - k), Color("#f8e048"), 10)
			d.anim_ataques._draw_burst(Vector2(130, 80), 9.0 + 4.0 * (1.0 - k), Color("#f88828"), 10)
		d._text_big(Vector2(130 - d._text_w("VS"), 70), "VS", Color.WHITE)
	# Frase abajo
	if t > 0.22 and t < 0.88:
		var title: String = v["title"]
		d.draw_rect(Rect2(0, 132, 240, 16), Color(0, 0, 0, 0.6))
		d._text(Vector2((240 - d._text_w(title)) / 2.0, 135), title, Color.WHITE)


static func _vs_mon(d, pos: Vector2, id: String, c: Color) -> void:
	var size = 48
	var r = Rect2(pos, Vector2(size, size))
	d.draw_rect(r.grow(2), Color.WHITE)
	d.draw_rect(r, c.darkened(0.45))
	var tex: Texture2D = d.mesa._art_texture(id, size, size)
	if tex != null:
		d.draw_texture_rect(tex, r, false)
	else:
		d.draw_circle(r.get_center(), 14, c.lightened(0.2))
		d._text(r.get_center() + Vector2(-3, -6), "?", Color.WHITE)
	var name = CardDB.card_name(id)
	if d._text_w(name) > 72:
		name = species(name)
	var nx = pos.x + size / 2.0 - d._text_w(name) / 2.0
	d._text(Vector2(clampf(nx, pos.x - 18, 236 - d._text_w(name)), pos.y + size + 3), name, Color.WHITE)
