extends RefCounted
## Imágenes de cartas: arte, recortes, holo y reverse holo, dorso, emblemas e íconos de Energía
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


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
	for cache in [d._sprites, d._art]:
		for k in cache.keys():
			if str(k).begins_with(id + "|"):
				cache.erase(k)
	d.queue_redraw()


func _load_card_image(id: String) -> Image:
	if _clean.has(id):
		return _clean[id]
	var img = _load_card_image_raw(id)
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
	return d.reverse_ids.has(m.top()) and d.game != null and d.game.players[d.human].all_in_play().has(m)


func _is_holo(id: String) -> bool:
	return HOLO_FILTER and "Holo" in _rarity_of(id)


## Reverse holo: el brillo va en el marco (todo menos la ilustración), como en las cartas
## reales. De Ruby & Sapphire a Team Magma vs Team Aqua es un arcoíris parejo que corre; en
## Hidden Legends, una grilla de simbolitos de Energía que se encienden en ola.
func _draw_reverse(outer: Rect2, hole: Rect2, id: String) -> void:
	var t := Clock.ms() / 1000.0
	var legends = id.begins_with("ex5-")
	var tc: Color = _card_bg(id)
	var x0 := int(outer.position.x)
	var x1 := int(outer.end.x)
	var hx0 := int(hole.position.x)
	var hx1 := int(hole.end.x)
	for yy in range(int(outer.position.y), int(outer.end.y)):
		var inside = yy >= int(hole.position.y) and yy < int(hole.end.y)
		var segs = [[x0, hx0], [hx1, x1]] if inside else [[x0, x1]]
		for sg in segs:
			var x: int = sg[0]
			while x < sg[1]:
				var w = mini(2, sg[1] - x)
				var glow = 0.5 + 0.5 * sin((x - yy) / 9.0 + t * 2.2)
				if legends:
					var c0 := tc.lightened(0.55)
					c0.a = 0.35 + 0.3 * glow
					d.draw_rect(Rect2(x, yy, w, 1), c0)
				else:
					var hue = fposmod((x + yy) / 46.0 - t * 0.35, 1.0)
					d.draw_rect(Rect2(x, yy, w, 1), Color.from_hsv(hue, 0.65, 1.0, 0.4 + 0.35 * glow))
				x += w
	if legends:
		# Simbolitos (rombos de 3x3) en grilla, que se encienden en ola
		for yy in range(int(outer.position.y) + 1, int(outer.end.y) - 1, 4):
			for xx in range(int(outer.position.x) + 1, int(outer.end.x) - 1, 4):
				if xx + 2 > hx0 and xx < hx1 and yy + 2 > int(hole.position.y) and yy < int(hole.end.y):
					continue
				var b = pow(maxf(0.0, sin(t * 2.6 - (xx + yy) / 7.0)), 3.0)
				var c = Color(1, 1, 1) if b > 0.6 else tc.darkened(0.15)
				c.a = 0.45 + 0.55 * b
				d.draw_rect(Rect2(xx + 1, yy, 1, 3), c)
				d.draw_rect(Rect2(xx, yy + 1, 3, 1), c)


## Reverse holo en el recuadro del nombre de tu Pokémon activo: un tinte suave de arcoíris y
## una franja de luz que lo cruza en diagonal cada tanto (en Hidden Legends, simbolitos de
## Energía de su tipo que se encienden al pasar la franja). Va detrás del texto, que sigue legible.
const REV_PERIOD := 2.4           # segundos entre una pasada y la siguiente
const REV_BAND := 16.0            # ancho de la franja (píxeles)
const REV_ICON := 9               # Hidden Legends: tamaño de cada símbolo de Energía
const REV_ICON_STEP := 13         # ...y separación entre uno y otro

func _draw_reverse_box(box: Rect2, id: String) -> void:
	var t := Clock.ms() / 1000.0
	var legends = id.begins_with("ex5-")
	var tc: Color = _card_bg(id)
	var x0 = int(box.position.x)
	var x1 = int(box.end.x)
	var y0 = int(box.position.y)
	var y1 = int(box.end.y)
	var span = box.size.x + box.size.y + REV_BAND * 2.0
	var band_x = fmod(t, REV_PERIOD) / REV_PERIOD * (span + 40.0) - REV_BAND - 20.0
	for yy in range(y0, y1):
		var x = x0
		while x < x1:
			var w = mini(2, x1 - x)
			var dd_ = float(x - x0) + float(yy - y0) - band_x     # distancia a la franja (diagonal)
			var k = clampf(1.0 - absf(dd_) / REV_BAND, 0.0, 1.0)
			if legends:
				var c0 := tc.lightened(0.6)
				c0.a = 0.3 + 0.45 * k
				d.draw_rect(Rect2(x, yy, w, 1), c0)
			else:
				var hue = fposmod((x + yy) / 40.0 - t * 0.3, 1.0)
				d.draw_rect(Rect2(x, yy, w, 1), Color.from_hsv(hue, 0.6, 1.0, 0.2 + 0.55 * k))
				if k > 0.75:
					d.draw_rect(Rect2(x, yy, w, 1), Color(1, 1, 1, (k - 0.75) * 1.6))
			x += w
	if legends:
		# El símbolo de Energía del tipo del Pokémon (si tiene dos tipos, se alternan), en una
		# grilla escalonada; los que cruza la franja se encienden.
		var types: Array = CardDB.types(id).filter(func(x): return d.TYPE_DARK.has(x))
		if types.is_empty():
			types = ["Colorless"]
		var row := 0
		for yy in range(y0 + 1, y1 - 5, REV_ICON_STEP - 2):
			var col := 0
			for xx in range(x0 + 1 + (REV_ICON_STEP / 2 if row % 2 == 1 else 0), x1 - 5, REV_ICON_STEP):
				var dd_ = float(xx - x0) + float(yy - y0) - band_x
				var k = clampf(1.0 - absf(dd_) / REV_BAND, 0.0, 1.0)
				var ty: String = types[(row + col) % types.size()]
				var r = Rect2(xx, yy, REV_ICON, REV_ICON)
				var col_t: Color = d.TYPE_COLORS.get(ty, tc)
				# al pasar la franja, el mismo color pero más intenso (más saturado y sin transparencia)
				var vivid := Color.from_hsv(col_t.h, minf(1.0, col_t.s * 1.5 + 0.25), minf(1.0, col_t.v * 1.1))
				var c = col_t.lerp(vivid, smoothstep(0.05, 0.5, k))
				c.a = 0.6 + 0.4 * k
				var tex := _type_symbol(ty, REV_ICON)
				if tex != null:
					d.draw_texture_rect(tex, r, false, c)
				else:
					_draw_emblem(r, ty, c)
				col += 1
			row += 1


## Brillo animado de las cartas holo: una franja de luz que cruza la imagen cada tanto y
## algunos destellos que titilan. Las holo ex y las secretas brillan con los colores del
## arcoíris. small = solo la franja (Banca y miniaturas).
const HOLO_PERIOD := 3.4       # segundos entre pasadas de la franja
func _draw_holo(r: Rect2, id: String, small: bool = false, cosmos: Dictionary = {}) -> void:
	if id in ICE_IDS:
		_draw_ice(r, id)
		return
	var rar = _rarity_of(id)
	if not ("Holo" in rar or "Secret" in rar) or r.size.x < 6:
		return
	var rainbow = "EX" in rar or "Secret" in rar
	var t := Clock.ms() / 1000.0
	var seed = hash(id)
	if not cosmos.is_empty():
		_draw_cosmos(r, cosmos, t, seed)
	var ph = fmod(t + (seed % 1000) / 1000.0 * HOLO_PERIOD, HOLO_PERIOD) / HOLO_PERIOD
	var inner = r.grow(-1)
	# Franja diagonal: cruza en el primer 40% del ciclo y después descansa
	var k = ph / 0.4
	if k < 1.0:
		var bw = maxf(3.0, inner.size.x * 0.22)
		var span = inner.size.x + inner.size.y * 0.6 + bw * 2
		var x0 = inner.position.x - bw - inner.size.y * 0.6 + span * k
		for y in int(inner.size.y):
			var cx = x0 + y * 0.6
			var a = maxf(cx - bw / 2.0, inner.position.x)
			var b = minf(cx + bw / 2.0, inner.end.x)
			if b <= a:
				continue
			var col := Color(1, 1, 0.92, 0.28)
			if rainbow:
				col = Color.from_hsv(fmod(t * 0.35 + y / inner.size.y * 0.5, 1.0), 0.7, 1.0, 0.4)
			d.draw_rect(Rect2(a, inner.position.y + y, b - a, 1), col)
			var a2 = maxf(cx - bw / 6.0, inner.position.x)
			var b2 = minf(cx + bw / 6.0, inner.end.x)
			if b2 > a2:
				d.draw_rect(Rect2(a2, inner.position.y + y, b2 - a2, 1), Color(1, 1, 1, 0.3))
	if small or not cosmos.is_empty():
		return
	# Destellos que titilan en lugares fijos de cada carta
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n = clampi(int(inner.size.x / 7.0), 2, 7) + (2 if "Secret" in rar else 0)
	for i in n:
		var p = (inner.position + Vector2(rng.randf_range(2, inner.size.x - 3), rng.randf_range(2, inner.size.y - 3))).floor()
		var tw = pow(maxf(0.0, sin(t * rng.randf_range(1.6, 2.6) + rng.randf() * TAU)), 6.0)
		if tw < 0.05:
			continue
		var c = Color(1.0, 0.95, 0.65, tw)
		if rainbow:
			c = Color.from_hsv(fmod(t * 0.5 + i * 0.17, 1.0), 0.6, 1.0, tw)
		d.draw_rect(Rect2(p, Vector2(1, 1)), c)
		if tw > 0.45:
			var arm = Color(c, tw * 0.6)
			d.draw_rect(Rect2(p + Vector2(-1, 0), Vector2(1, 1)), arm)
			d.draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), arm)
			d.draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 1)), arm)
			d.draw_rect(Rect2(p + Vector2(0, 1), Vector2(1, 1)), arm)


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


func _is_holo_card(id: String) -> bool:
	var rar = _rarity_of(id)
	return "Holo" in rar or "Secret" in rar


func _build_cosmos(key: String, id: String, img: Image) -> void:
	if not _is_holo_card(id) or img.get_width() < 12 or id in ICE_IDS:
		return
	var w = img.get_width()
	var h = img.get_height()
	# 1) Colores del borde (el fondo casi siempre llega a los bordes de la ilustración)
	var border: Array[Color] = []
	for x in w:
		for y in [1, h - 2]:
			var c = img.get_pixel(x, y)
			if c.a > 0.5:
				border.append(c)
	for y in h:
		for x in [1, w - 2]:
			var c = img.get_pixel(x, y)
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
			var c = img.get_pixel(x, y)
			var best := 9.0
			for b in samples:
				var dd_ = absf(c.r - b.r) + absf(c.g - b.g) + absf(c.b - b.b)
				if dd_ < best:
					best = dd_
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
		var x = i % w
		var y = i / w
		for dd in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = x + dd[0]
			var ny: int = y + dd[1]
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var j = ny * w + nx
			if mask[j] == 0.0 and near[j] < COSMOS_NEAR:
				# Crece solo entre vecinos parecidos: el contorno del Pokémon frena el fondo
				var a = img.get_pixel(x, y)
				var b = img.get_pixel(nx, ny)
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
					var xx = clampi(x + dx, 0, w - 1)
					var yy = clampi(y + dy, 0, h - 1)
					acc += mask[yy * w + xx]
					n += 1
			soft[y * w + x] = acc / n
	# 4) Capa del fondo apagado (oscuro y frío, como el papel metalizado)
	var base = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var tint := Color(0.16, 0.12, 0.30)
	for y in h:
		for x in w:
			var c = img.get_pixel(x, y)
			var m = soft[y * w + x]
			if c.a < 0.5 or m <= 0.0:
				continue
			var dark = c.darkened(0.5).lerp(tint, 0.35)
			dark.a = COSMOS_DIM * m
			base.set_pixel(x, y, dark)
	# 5) Capas de destellos: los "redondeles" del holo cosmos de la época. Puntitos, discos,
	#    anillos y algunos círculos grandes con halo, de colores de arcoíris. Cada capa es
	#    un momento distinto: los círculos cambian de color y se prenden y apagan a destiempo,
	#    como al inclinar la carta bajo la luz.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var orbs: Array = []      # [x, y, tono, radio, anillo, fase]
	var area = float(w * h)
	var kinds = [[area / 14.0, 0.0, false], [area / 34.0, 1.2, false], [area / 85.0, 2.4, true]]
	if w >= 30:
		kinds.append([area / 300.0, 3.6, true])
		kinds.append([area / 420.0, 3.0, false])
	for kd in kinds:
		for i in int(kd[0]):
			var x = rng.randi_range(0, w - 1)
			var y = rng.randi_range(0, h - 1)
			if soft[y * w + x] < 0.6:
				continue
			orbs.append([x, y, rng.randf(), float(kd[1]), bool(kd[2]), rng.randf()])
	var sparks: Array = []
	for f in COSMOS_FRAMES:
		var layer = Image.create(w, h, false, Image.FORMAT_RGBA8)
		var fk = float(f) / COSMOS_FRAMES
		for o in orbs:
			var r: float = o[3]
			# Brillo según el momento: cada círculo tiene su fase
			var lit = maxf(0.0, cos((fk - float(o[5])) * TAU))
			if r <= 0.0:
				lit = 1.0 if lit > 0.7 else 0.0          # los puntitos titilan
			var bright = 0.25 + 0.75 * lit
			if bright < 0.3 and r <= 0.0:
				continue
			var hue = fmod(float(o[2]) + fk * 0.35, 1.0)
			_paint_orb(layer, soft, w, h, int(o[0]), int(o[1]), r, Color.from_hsv(hue, 0.6, 1.0, bright), bool(o[4]))
		sparks.append(ImageTexture.create_from_image(layer))
	d._cosmos[key] = {"base": ImageTexture.create_from_image(base), "spark": sparks}


## Un redondel del holo en la capa: r = 0 un puntito; si no, un disco (centro casi blanco
## y borde de color) o un anillo. Solo sobre el fondo de la ilustración (soft).
func _paint_orb(layer: Image, soft: PackedFloat32Array, w: int, h: int, cx: int, cy: int, r: float, col: Color, ring: bool) -> void:
	var R = int(ceilf(r + 1.0))
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x = cx + dx
			var y = cy + dy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var m = soft[y * w + x]
			if m < 0.35:
				continue
			var dd_ := sqrt(float(dx * dx + dy * dy))
			var a := 0.0
			var c := col
			if r <= 0.0:
				a = 1.0 if dd_ < 0.5 else 0.0
			elif ring:
				a = clampf(1.0 - absf(dd_ - r) * 1.1, 0.0, 1.0)       # el aro
				if dd_ < r - 0.8:
					a = maxf(a, 0.18)                              # adentro, apenas teñido
				if r >= 3.0 and dd_ > r:
					a = maxf(a, clampf(0.35 - (dd_ - r) * 0.3, 0.0, 1.0))   # halo
			else:
				a = clampf(r + 0.5 - dd_, 0.0, 1.0)
				c = col.lerp(Color(1, 1, 1, col.a), clampf(1.0 - dd_ / maxf(r, 0.1), 0.0, 1.0) * 0.6)
			a *= col.a * m
			if a <= 0.02:
				continue
			var prev = layer.get_pixel(x, y)
			if a > prev.a:
				layer.set_pixel(x, y, Color(c.r, c.g, c.b, a))


## Cuánto se ve el efecto ahora (0 = imagen limpia, 1 = holo completo).
func _cosmos_amount(t: float, seed: int) -> float:
	var period := COSMOS_ON + COSMOS_OFF + COSMOS_FADE * 2
	var p = fmod(t + (seed % 997) / 997.0 * period, period)
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
	var k = _cosmos_amount(t, seed)
	if k <= 0.0:
		return
	k = k * k * (3.0 - 2.0 * k)
	d.draw_texture_rect(cosmos["base"], r, false, Color(1, 1, 1, k))
	var sp: Array = cosmos["spark"]
	var f = t * 3.0 + (seed % 7)
	var i = int(f) % sp.size()
	var frac = f - floorf(f)
	d.draw_texture_rect(sp[i], r, false, Color(1, 1, 1, k * (1.0 - frac)))
	d.draw_texture_rect(sp[(i + 1) % sp.size()], r, false, Color(1, 1, 1, k * frac))


func _remove_holo_sparkles(src: Image) -> Image:
	var img = src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	# Achicar de a mitades (promedia bien y no deja aliasing) hasta cerca de HOLO_WORK
	while img.get_width() > HOLO_WORK * 2 and img.get_height() > HOLO_WORK * 2:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var w = img.get_width()
	var h = img.get_height()
	if w > HOLO_WORK:
		var sc = float(HOLO_WORK) / maxi(w, h)
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
			var c = img.get_pixel(x, y)
			px[y * w + x] = c
			lum[y * w + x] = int((c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 4095.0)
	var out = img.duplicate() as Image
	var keys := PackedInt64Array()
	keys.resize(25)
	for y in h:
		for x in w:
			var n := 0
			for dy in range(-2, 3):
				var row = clampi(y + dy, 0, h - 1) * w
				for dx in range(-2, 3):
					var i = row + clampi(x + dx, 0, w - 1)
					keys[n] = lum[i] * 1048576 + i      # brillo y, abajo, de qué píxel es
					n += 1
			keys.sort()
			var m: Color = px[keys[12] % 1048576]
			m.a = px[y * w + x].a
			out.set_pixel(x, y, m)
	return out


func _load_card_image_raw(id: String) -> Image:
	var name = CardDB.card_name(id)
	var species = name.replace("Team Aqua's ", "").replace("Team Magma's ", "").replace("Rocket's ", "").trim_suffix(" ex").trim_suffix(" ★")
	for dir in d.SPRITE_DIRS:
		for n in [id, CardDB.file_id(id), name, species, species.to_lower()]:
			for ext in ["png", "jpg", "webp"]:
				var path = "%s/%s.%s" % [dir, n, ext]
				if ImgLoad.exists(path):
					var img = ImgLoad.load(path)
					if img != null and not img.is_empty():
						return img
	# Sin recorte cuadrado propio: se usa el arte en alta (mundo/propios/arte o el bajado);
	# _square_crop le saca el cuadrado para la mesa y _gba_art el recuadro de la ventana.
	if d.arte != null and not CardDB.get_card(id).get("supertype", "") == "Energy":
		var hd = d.arte.image(id)
		if hd != null:
			return hd
		d.arte.want(id)
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
	var side = int(mini(w, h) / maxf(1.0, float(adj.get("zoom", 1.0))))
	var cx = float(adj.get("x", 0.5)) * w
	var cy = float(adj.get("y", 0.5)) * h
	var x0 = clampi(int(cx - side / 2.0), 0, w - side)
	var y0 = clampi(int(cy - side / 2.0), 0, h - side)
	return Rect2i(x0, y0, side, side)


## Galería, tecla S (solo desde el editor de Godot): ajustar el cuadrado chico de la carta.
## Flechas lo mueven, Q/W lo agrandan o achican, Z guarda en data/recorte_cuadrado.json,
## X cancela, R vuelve al centro.
func _sq_edit_keys(k: int, accept: bool, back: bool) -> bool:
	var id = d.gallery_id
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
				d.sq_edit = false
				d.snd.play("ok")
				return true
			if back:
				_sq_adjust = null         # se vuelve a leer el archivo: descarta lo no guardado
				_forget_square(id)
				d.sq_edit = false
				d.snd.play("back")
				return true
			return false
	# que el centro no quede donde el cuadrado se saldría del arte
	var img = d.arte.image(id)
	if img != null:
		var w = img.get_width()
		var h = img.get_height()
		var half = mini(w, h) / maxf(1.0, float(cur.get("zoom", 1.0))) / 2.0
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
	d.snd.play("cursor")
	return true


func _forget_square(id: String) -> void:
	for cache in [d._sprites, d._art]:
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
	var f = r.size.x / img.get_width()
	var sq = _square_rect(id, img.get_width(), img.get_height())
	var box = Rect2(r.position + Vector2(sq.position) * f, Vector2(sq.size) * f)
	var shade := Color(0, 0, 0, 0.55)
	d.draw_rect(Rect2(r.position, Vector2(box.position.x - r.position.x, r.size.y)), shade)
	d.draw_rect(Rect2(Vector2(box.end.x, r.position.y), Vector2(r.end.x - box.end.x, r.size.y)), shade)
	d.draw_rect(Rect2(Vector2(box.position.x, r.position.y), Vector2(box.size.x, box.position.y - r.position.y)), shade)
	d.draw_rect(Rect2(Vector2(box.position.x, box.end.y), Vector2(box.size.x, r.end.y - box.end.y)), shade)
	d.draw_rect(box, Color("#f8d030"), false, 1.0)
	var y := 134.0
	var own = _has_own_square(id)
	d._text(Vector2(8, y), "Arrows move · Q/W size · R reset", Color("#a0a8b8"))
	d._text(Vector2(8, y + 12), "Z save · X cancel" + ("  (sprites/ has its own!)" if own else ""), Color("#e8c060") if own else Color("#a0a8b8"))
	var prev = _card_texture(id, 32)
	if prev != null:
		d.draw_texture_rect(prev, Rect2(d.W - 40, y - 4, 32, 32), false)


## ¿Hay un cuadrado propio en sprites/ para esta carta? (ese manda sobre el ajuste)
func _has_own_square(id: String) -> bool:
	for dd_ in d.SPRITE_DIRS:
		for n in [id, CardDB.file_id(id), CardDB.card_name(id)]:
			var pth = "%s/%s.png" % [dd_, n]
			if ImgLoad.exists(pth) or ResourceLoader.exists(pth):
				return true
	return false


func _square_crop(id: String, img: Image) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	if w <= h * 1.15 and h <= w * 1.15:
		return img
	return img.get_region(_square_rect(id, w, h))


## Imagen cuadrada de la carta (menús, fichas), reducida a paleta de GBA.
func _card_texture(id: String, size: int) -> Texture2D:
	var key = "%s|%d" % [id, size]
	if d._sprites.has(key):
		return d._sprites[key]
	var tex: Texture2D = null
	var img = _load_card_image(id)
	if img != null:
		var small = _gba_style(_square_crop(id, img), size)
		tex = ImageTexture.create_from_image(small)
		_build_cosmos("c|" + key, id, small)
	d._sprites[key] = tex
	return tex


func _gba_style(src: Image, size: int = d.PORTRAIT) -> Image:
	var img = src.duplicate() as Image      # la imagen original queda guardada sin tocar
	img.convert(Image.FORMAT_RGBA8)
	var scale: float = float(size) / maxi(img.get_width(), img.get_height())
	var w = maxi(1, int(img.get_width() * scale))
	var h = maxi(1, int(img.get_height() * scale))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((size - w) / 2, (size - h) / 2))
	var rad := _corner_radius(size)
	for y in size:
		for x in size:
			var c = out.get_pixel(x, y)
			if c.a < 0.5 or _outside_round(x, y, size, rad):
				out.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				out.set_pixel(x, y, Color(snappedf(c.r, 1.0 / 31.0), snappedf(c.g, 1.0 / 31.0), snappedf(c.b, 1.0 / 31.0), 1.0))
	if size <= 64:
		d.mesa._reduce_palette(out, 24)
	return out


## Emblemas originales por tipo (formas geométricas simples).
func _draw_emblem(r: Rect2, type: String, c: Color) -> void:
	var p = func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	match type:
		"Fire":
			d.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.0), p.call(0.78, 0.4), p.call(0.82, 0.7),
					p.call(0.62, 1.0), p.call(0.38, 1.0), p.call(0.18, 0.7), p.call(0.28, 0.42), p.call(0.42, 0.58)]), c)
		"Water":
			d.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.0), p.call(0.78, 0.55), p.call(0.22, 0.55)]), c)
			d.draw_circle(p.call(0.5, 0.64), r.size.x * 0.3, c)
		"Grass":
			d.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.95), p.call(0.25, 0.35), p.call(0.95, 0.05), p.call(0.7, 0.72)]), c)
			d.draw_line(p.call(0.12, 0.92), p.call(0.75, 0.3), d.C_TEXT.lightened(0.2))
		"Lightning":
			d.draw_colored_polygon(PackedVector2Array([p.call(0.6, 0.0), p.call(0.2, 0.55), p.call(0.47, 0.55),
					p.call(0.35, 1.0), p.call(0.82, 0.4), p.call(0.55, 0.4), p.call(0.72, 0.0)]), c)
		"Psychic":
			d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.48, c)
			d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.3, c.darkened(0.6))
			d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.13, c)
		"Fighting":
			var pts := PackedVector2Array()
			for i in 16:
				var ang = TAU * i / 16.0
				var rad = 0.5 if i % 2 == 0 else 0.28
				pts.append(p.call(0.5 + cos(ang) * rad, 0.5 + sin(ang) * rad))
			d.draw_colored_polygon(pts, c)
		"Darkness":
			d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.48, c)
			d.draw_circle(p.call(0.68, 0.38), r.size.x * 0.4, d.TYPE_COLORS["Darkness"].darkened(0.45))
		"Metal":
			var pts := PackedVector2Array()
			for i in 6:
				var ang = TAU * i / 6.0 + PI / 6.0
				pts.append(p.call(0.5 + cos(ang) * 0.5, 0.5 + sin(ang) * 0.5))
			d.draw_colored_polygon(pts, c)
			d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.18, d.TYPE_COLORS["Metal"].darkened(0.45))
		_:
			var pts := PackedVector2Array()
			for i in 10:
				var ang = TAU * i / 10.0 - PI / 2.0
				var rad = 0.5 if i % 2 == 0 else 0.22
				pts.append(p.call(0.5 + cos(ang) * rad, 0.52 + sin(ang) * rad))
			d.draw_colored_polygon(pts, c)


func _draw_energy(pos: Vector2, m: PokemonInPlay) -> void:
	var x := 0
	var shown: Array = Energy.units(m)
	shown = shown.slice(0, maxi(0, shown.size() - d.anim_cartas._pending_units(m)))
	for u in shown:
		var t: String = u[0] if u.size() == 1 else "*"
		_draw_energy_icon(pos + Vector2(x + 4, 3.5), 8, t)
		x += 9
		if x > 63:
			break


# ===========================================================================
# Imagen de cualquier carta: la propia (sprites/) o un ícono original
# ===========================================================================

func _draw_card_image(r: Rect2, id: String, rev: bool = false) -> void:
	var sz = int(r.size.x)
	if sz < 2:
		return      # en las animaciones que achican la carta hasta desaparecer
	if rev or (d.mode == "duel" and d.reverse_ids.has(id)):
		_draw_reverse(r.grow(3), r, id)
	if sz > 12:
		sz = int(ceil(sz / 8.0)) * 8    # tamaños redondeados: no se rehace la imagen en cada cuadro de una animación
	var tex = _card_texture(id, sz)
	_round_box(r, _card_bg(id).darkened(0.45))
	if tex != null:
		d.draw_texture_rect(tex, r, false)
		if d.mode != "editor":     # en el editor de mazos el brillo distrae: solo en los duelos
			_draw_holo(r, id, r.size.x < 20, d._cosmos.get("c|%s|%d" % [id, sz], {}))
	else:
		_draw_card_icon(r.grow(-r.size.x * 0.17), id)
	_round_box(r, Color(0, 0, 0, 0), d.C_TEXT)


func _card_bg(id: String) -> Color:
	if CardDB.is_pokemon(id):
		var t = CardDB.types(id)
		return d.TYPE_COLORS.get(t[0] if not t.is_empty() else "Colorless", d.C_PANEL_DARK)
	if CardDB.is_basic_energy(id):
		return d.TYPE_COLORS.get(CardDB.basic_energy_type(id), d.C_PANEL_DARK)
	if CardDB.is_energy(id):
		return d.TYPE_COLORS["*"]
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
	var p = func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var light = _card_bg(id).lightened(0.45)
	if CardDB.is_pokemon(id):
		var t = CardDB.types(id)
		_draw_emblem(r, t[0] if not t.is_empty() else "Colorless", light)
	elif CardDB.is_basic_energy(id):
		# Energía básica: disco claro con el emblema del tipo adentro.
		d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.5, d.C_LIGHT)
		_draw_emblem(r.grow(-r.size.x * 0.2), CardDB.basic_energy_type(id), _card_bg(id).darkened(0.1))
	elif CardDB.is_energy(id):
		# Energía especial: anillo de colores con una estrella.
		var cols := ["Fire", "Water", "Grass", "Lightning", "Psychic", "Fighting"]
		for i in cols.size():
			d.draw_arc(p.call(0.5, 0.5), r.size.x * 0.45, TAU * i / 6.0, TAU * (i + 1) / 6.0, 6, d.TYPE_COLORS[cols[i]], 3.0)
		d.anim_ataques._draw_burst(p.call(0.5, 0.5), r.size.x * 0.25, d.C_LIGHT, 5)
	elif CardDB.is_supporter(id):
		# Persona genérica.
		d.draw_circle(p.call(0.5, 0.28), r.size.x * 0.18, light)
		d.draw_colored_polygon(PackedVector2Array([p.call(0.18, 1.0), p.call(0.25, 0.55), p.call(0.5, 0.48),
				p.call(0.75, 0.55), p.call(0.82, 1.0)]), light)
	elif CardDB.is_stadium(id):
		# Edificio.
		d.draw_colored_polygon(PackedVector2Array([p.call(0.05, 0.42), p.call(0.5, 0.05), p.call(0.95, 0.42)]), light)
		d.draw_rect(Rect2(p.call(0.15, 0.42), r.size * Vector2(0.7, 0.55)), light)
		d.draw_rect(Rect2(p.call(0.42, 0.65), r.size * Vector2(0.16, 0.32)), _card_bg(id).darkened(0.45))
	elif CardDB.is_pokemon_tool(id):
		# Baya con hoja.
		d.draw_circle(p.call(0.5, 0.6), r.size.x * 0.36, light)
		d.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.25), p.call(0.8, 0.02), p.call(0.62, 0.3)]), d.TYPE_COLORS["Grass"])
	elif CardDB.is_tm(id):
		# Disco.
		d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.5, light)
		d.draw_circle(p.call(0.5, 0.5), r.size.x * 0.12, _card_bg(id).darkened(0.45))
		d.draw_arc(p.call(0.5, 0.5), r.size.x * 0.32, 0.3, 1.4, 8, _card_bg(id), 1.0)
	elif CardDB.is_fossil(id):
		# Roca con una espiral.
		d.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.7), p.call(0.25, 0.2), p.call(0.7, 0.1),
				p.call(0.95, 0.5), p.call(0.8, 0.9), p.call(0.3, 0.95)]), light)
		d.draw_arc(p.call(0.52, 0.52), r.size.x * 0.2, 0, TAU * 0.8, 12, _card_bg(id).darkened(0.4), 1.5)
	else:
		# Objeto: bolso con manija.
		d.draw_arc(p.call(0.5, 0.35), r.size.x * 0.2, PI, TAU, 8, light, 2.0)
		d.draw_rect(Rect2(p.call(0.12, 0.35), r.size * Vector2(0.76, 0.6)), light)
		d.draw_rect(Rect2(p.call(0.12, 0.52), r.size * Vector2(0.76, 0.08)), _card_bg(id).darkened(0.3))
# ===========================================================================
# Íconos de Energía
# ===========================================================================
# Por defecto se dibuja un círculo del color del tipo con su emblema. Si en
# mundo/propios/tipos/ (tools/armar_tipos.py) o en sprites/ hay una imagen
# energy_<tipo>.png (energy_fire.png, energy_water.png...) o energia_<tipo>.png
# (energia_fuego.png...), se usa esa.

const ENERGY_FILE_ES := {"Fire": "fuego", "Water": "agua", "Grass": "planta", "Lightning": "rayo",
		"Psychic": "psiquico", "Fighting": "lucha", "Darkness": "oscuro", "Metal": "metal", "Colorless": "incoloro", "*": "arcoiris"}


func _energy_texture(type: String, size: int) -> Texture2D:
	var key = "%s|%d" % [type, size]
	if d._energy_tex.has(key):
		return d._energy_tex[key]
	var tex: Texture2D = null
	var en = "rainbow" if type == "*" else type.to_lower()
	for dir in ["res://mundo/propios/tipos", "user://mundo/propios/tipos"] + d.SPRITE_DIRS:
		for n in ["energy_" + en, "energia_" + ENERGY_FILE_ES.get(type, en)]:
			for ext in ["png", "jpg", "webp"]:
				var path = "%s/%s.%s" % [dir, n, ext]
				if tex == null and ImgLoad.exists(path):
					var img = ImgLoad.load(path)
					if img != null and not img.is_empty():
						# Sin reducir la paleta: los íconos son chiquitos y conviene que se lean bien.
						img.convert(Image.FORMAT_RGBA8)
						var px = size * (d.HD_SCALE if d.hd else 1)
						img.resize(px * 4, px * 4, Image.INTERPOLATE_LANCZOS)
						img.resize(px, px, Image.INTERPOLATE_BILINEAR)
						tex = ImageTexture.create_from_image(img)
	d._energy_tex[key] = tex
	return tex


## Solo el dibujo del tipo (la llama, la gota, la hoja...) sin la esfera: se toma de los íconos de
## Energía (lo oscuro del centro) y queda blanco, para pintarlo del color que haga falta.
var _symbol_tex := {}

func _type_symbol(type: String, size: int) -> Texture2D:
	var key = "%s|%d" % [type, size]
	if _symbol_tex.has(key):
		return _symbol_tex[key]
	var tex: Texture2D = null
	var en := type.to_lower()
	for dir in ["res://mundo/propios/tipos", "user://mundo/propios/tipos"] + d.SPRITE_DIRS:
		var path = "%s/energy_%s.png" % [dir, en]
		if tex != null or not ImgLoad.exists(path):
			continue
		var img = ImgLoad.load(path)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGBA8)
		var w = img.get_width()
		var h = img.get_height()
		var out = Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var c = img.get_pixel(x, y)
				var dd = Vector2(x - (w - 1) / 2.0, y - (h - 1) / 2.0).length() / (w / 2.0)
				var lum = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
				if c.a > 0.5 and lum < 0.3 and dd < 0.7:
					out.set_pixel(x, y, Color(1, 1, 1, 1))
				else:
					out.set_pixel(x, y, Color(1, 1, 1, 0))
		var px = size * (d.HD_SCALE if d.hd else 1)
		out.resize(px, px, Image.INTERPOLATE_LANCZOS)
		tex = ImageTexture.create_from_image(out)
	_symbol_tex[key] = tex
	return tex


func _draw_energy_icon(center: Vector2, dd_: int, type: String) -> void:
	var r = Rect2(center - Vector2(dd_, dd_) / 2.0, Vector2(dd_, dd_))
	var tex = _energy_texture(type, dd_)
	if tex != null:
		d.draw_texture_rect(tex, r, false)
		return
	var rad = dd_ / 2.0
	d.draw_circle(center, rad, d.C_TEXT)
	if type == "*":
		var cols := ["Fire", "Lightning", "Grass", "Water", "Psychic", "Fighting"]
		for i in 6:
			d.draw_arc(center, rad - 1.5, TAU * i / 6.0, TAU * (i + 1) / 6.0, 4, d.TYPE_COLORS[cols[i]], 2.0)
		d.draw_circle(center, maxf(1.0, rad - 2.5), Color.WHITE)
		return
	var tc: Color = d.TYPE_COLORS.get(type, d.C_LIGHT)
	d.draw_circle(center, rad - 0.8, tc)
	if dd_ >= 7:
		var glyph = Color.WHITE if type not in ["Lightning", "Colorless", "Metal"] else d.C_TEXT
		var gr = r.grow(-dd_ * 0.24)
		_draw_emblem(gr, type, glyph)


## Fila con texto e íconos: [["text", "Weakness "], ["icon", "Fire"], ...]
func _draw_icon_row(pos: Vector2, row: Array) -> void:
	var x := pos.x
	for item in row:
		if item[0] == "icon":
			_draw_energy_icon(Vector2(x + 5, pos.y + 4.5), 10, item[1])
			x += 11
		elif item[0] == "fx":
			d.anim_ataques._reason_icon(item[1], Vector2(x + 5, pos.y + 4.5))
			x += 12
		elif item[0] == "bold":
			var c: Color = item[2] if item.size() > 2 else d.C_TEXT
			d._text_bold(Vector2(x, pos.y), item[1], c)
			x += d.font_bold.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, d.FONT_SIZE).x
		else:
			var c: Color = d.C_DIM if item[0] == "dim" else (item[2] if item.size() > 2 else d.C_TEXT)
			d._text(Vector2(x, pos.y), item[1], c)
			x += d._text_w(item[1])


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
	# Letras (renglones chicos: "LEGAL TO USE", nombre del formato...)
	"A": ["010", "101", "111", "101", "101"],
	"B": ["110", "101", "110", "101", "110"],
	"C": ["011", "100", "100", "100", "011"],
	"D": ["110", "101", "101", "101", "110"],
	"E": ["111", "100", "110", "100", "111"],
	"F": ["111", "100", "110", "100", "100"],
	"G": ["011", "100", "101", "101", "011"],
	"I": ["111", "010", "010", "010", "111"],
	"J": ["001", "001", "001", "101", "010"],
	"K": ["101", "101", "110", "101", "101"],
	"L": ["100", "100", "100", "100", "111"],
	"M": ["101", "111", "111", "101", "101"],
	"N": ["110", "101", "101", "101", "101"],
	"O": ["010", "101", "101", "101", "010"],
	"Q": ["010", "101", "101", "110", "011"],
	"R": ["110", "101", "110", "101", "101"],
	"T": ["111", "010", "010", "010", "010"],
	"U": ["101", "101", "101", "101", "111"],
	"V": ["101", "101", "101", "101", "010"],
	"W": ["101", "101", "111", "111", "101"],
	"X": ["101", "101", "010", "101", "101"],
	"Y": ["101", "101", "010", "010", "010"],
	"Z": ["111", "001", "010", "100", "111"],
	".": ["000", "000", "000", "000", "010"],
	"-": ["000", "000", "111", "000", "000"],
	"·": ["000", "000", "010", "000", "000"],
	"(": ["010", "100", "100", "100", "010"],
	"&": ["010", "101", "010", "101", "011"], "\'": ["010", "010", "000", "000", "000"],
	")": ["010", "001", "001", "001", "010"],
}


func _draw_tiny(pos: Vector2, s: String, c: Color) -> void:
	var x := pos.x
	for ch in s:
		var g: Array = TINY.get(ch, [])
		for row in g.size():
			for col in 3:
				if g[row][col] == "1":
					d.draw_rect(Rect2(x + col, pos.y + row, 1, 1), c)
		x += 4
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
	var rad = _corner_radius(minf(r.size.x, r.size.y))
	var key = "%s|%s|%d|%s" % [fill.to_html(), border.to_html(), rad, d.hd]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = fill
		sb.draw_center = fill.a > 0.0
		sb.set_corner_radius_all(rad)
		sb.anti_aliasing = d.hd
		if border.a > 0.0:
			sb.border_color = border
			sb.set_border_width_all(1)
		_boxes[key] = sb
	d.draw_style_box(sb, r)
# ===========================================================================
# Holo "cracked ice"
# ===========================================================================
# Las Regi ex de Hidden Legends y las aves ex de FireRed & LeafGreen tienen la lámina de
# "hielo quebrado": esquirlas irregulares de colores del arcoíris que destellan cada una a
# su ritmo, con una franja de luz que las cruza. La animación está horneada en
# ui/holo_hielo_96.png y _48.png (tools/hornear_hielo.py): 72 cuadros en 6 filas de 12,
# una capa transparente que va encima del arte de la carta.

const ICE_IDS := ["ex5-97", "ex5-98", "ex5-99", "ex6-114", "ex6-115", "ex6-116"]
const ICE_FPS := 12.0
const ICE_FRAMES := 72
var _ice_sheets := {}


func _draw_ice(r: Rect2, id: String) -> void:
	if r.size.x < 6:
		return
	var s = 96 if r.size.x >= 60 else 48
	if not _ice_sheets.has(s):
		_ice_sheets[s] = load("res://ui/holo_hielo_%d.png" % s)
	var tex: Texture2D = _ice_sheets[s]
	if tex == null:
		return
	# Cada carta arranca en otro momento y tres de ellas van traspuestas: no se ven iguales
	var h: int = absi(hash(id))
	var f = (int(Clock.ms() / 1000.0 * ICE_FPS) + h % ICE_FRAMES) % ICE_FRAMES
	var src = Rect2((f % 12) * s, (f / 12) * s, s, s)
	d.draw_texture_rect_region(tex, r, src, Color.WHITE, (h / 7) % 2 == 0)
