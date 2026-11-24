extends RefCounted
## La mesa: fondo y Estadio, cartas del Activo y de la Banca, recuadros de PS, Poké-Bodies, contadores y la mesa de dobles
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)

const SpecialFX := preload("res://scenes/special_fx.gd")


func _init(duel) -> void:
	d = duel


func _draw_table() -> void:
	if d._table_tex == null:
		d._table_tex = ImageTexture.create_from_image(_table_image())
	# Con un Estadio en juego, la mesa toma su fondo (con un fundido al entrar y al salir)
	var st := _stage_name()
	if st != _stage_bg:
		_stage_prev = _stage_bg
		_stage_bg = st
		_stage_t0 = Clock.ms() / 1000.0
	var k := clampf((Clock.ms() / 1000.0 - _stage_t0) / STADIUM_FADE, 0.0, 1.0)
	var prev := _stage_tex(_stage_prev)
	var cur := _stage_tex(_stage_bg)
	if k < 1.0:
		d.draw_texture(prev if prev != null else d._table_tex, Vector2.ZERO)
		d.draw_texture(cur if cur != null else d._table_tex, Vector2.ZERO, Color(1, 1, 1, k))
	else:
		d.draw_texture(cur if cur != null else d._table_tex, Vector2.ZERO)


# ---------------------------------------------------------------------------
# Entrada del Estadio: al jugarlo sube desde abajo un paisaje (pasto, olas, arena...)
# y se desvanece enseguida. En los interiores entra un marco desde los costados.
# ---------------------------------------------------------------------------

const STADIUM_ENTRY := {
	"Apricorn Forest": "entrada_pasto", "Pokémon Park": "entrada_pasto", "Giant Stump": "entrada_pasto",
	"Power Tree": "entrada_pasto", "Full Flame": "entrada_pasto", "Holon Ruins": "entrada_pasto",
	"Low Pressure System": "entrada_viento", "High Pressure System": "entrada_viento",
	"Magnetic Storm": "entrada_viento", "Holon Circle": "entrada_viento",
	"Undersea Ruins": "entrada_burbujas", "Underground Lake": "entrada_burbujas", "Holon Lake": "entrada_burbujas",
	"Team Aqua Hideout": "entrada_burbujas", "Island Cave": "entrada_burbujas",
	"Crystal Beach": "entrada_ola", "Meteor Falls": "entrada_ola",
	"Desert Ruins": "entrada_arena", "Ancient Ruins": "entrada_arena",
	"Mt. Moon": "entrada_rocas", "Team Magma Hideout": "entrada_rocas", "Cursed Stone": "entrada_rocas",
	"Strange Cave": "entrada_rocas", "Holon Legacy": "entrada_rocas",
	# Interiores: un marco que sube por los costados de la mesa
	"Battle Frontier": "marco_pokeball", "Championship Arena": "marco_pokeball", "Speed Stadium": "marco_pokeball",
	"Drake's Stadium": "marco_pokeball", "Glacia's Stadium": "marco_pokeball", "Phoebe's Stadium": "marco_pokeball",
	"Sidney's Stadium": "marco_pokeball",
	"Power Plant": "marco_ciudad", "Space Center": "marco_ciudad", "Holon Research Tower": "marco_ciudad",
	"Rocket's Hideout": "marco_rocket", "Rocket's Tricky Gym": "marco_rocket",
	"Ancient Tomb": "marco_roca", "Mystery Zone": "marco_roca", "Mirage Stadium": "marco_nubes",
}
const ENTRY_RISE := 0.3
const ENTRY_HOLD := 0.25
const ENTRY_FADE := 0.45
var _entry_card := ""      # el Estadio en juego (para notar cuando entra uno nuevo)
var _entry_fx := ""
var _entry_t0 := -10.0


func _draw_stadium_entry() -> void:
	if d.game == null or d.mode != "duel":
		return
	var card: String = d.game.stadium
	if card != _entry_card:
		_entry_card = card
		_entry_fx = STADIUM_ENTRY.get(CardDB.card_name(card), "") if card != "" else ""
		_entry_t0 = Clock.ms() / 1000.0
	if _entry_fx == "":
		return
	var t := Clock.ms() / 1000.0 - _entry_t0
	if t > ENTRY_RISE + ENTRY_HOLD + ENTRY_FADE:
		return
	var tex = SpecialFX.fx(_entry_fx)
	if tex == null:
		return
	var h: float = minf(tex.get_height(), float(d.BOX_Y))     # los marcos cubren todo el alto
	var k := clampf(t / ENTRY_RISE, 0.0, 1.0)
	var y: float = d.BOX_Y - h * (1.0 - pow(1.0 - k, 3.0))
	var a := 1.0 - clampf((t - ENTRY_RISE - ENTRY_HOLD) / ENTRY_FADE, 0.0, 1.0)
	var cut: float = (tex.get_width() - d.W) / 2.0
	if _entry_fx.begins_with("marco_"):
		# Los marcos entran desde los costados: cada mitad desde su lado
		var hw: float = d.W / 2.0
		var dx := roundf(48.0 * (1.0 - k) * (1.0 - k))      # el marco mide unos 40 píxeles de ancho
		d.draw_texture_rect_region(tex, Rect2(-dx, 0, hw, h), Rect2(cut, 0, hw, h), Color(1, 1, 1, a))
		d.draw_texture_rect_region(tex, Rect2(hw + dx, 0, hw, h), Rect2(cut + hw, 0, hw, h), Color(1, 1, 1, a))
		return
	d.draw_texture_rect_region(tex, Rect2(0, roundf(y), d.W, h), Rect2(cut, 0, d.W, h), Color(1, 1, 1, a))


# ---------------------------------------------------------------------------
# Fondos por Estadio (mundo/propios/estadios/<nombre>.png, 240 x 112; de Pokémon Ranger)
# ---------------------------------------------------------------------------

const STADIUM_DIR := "res://mundo/propios/estadios"
const STADIUM_FADE := 0.6
var _stage_bg := ""        # el Estadio cuyo fondo se ve ("" = la mesa de siempre)
var _stage_prev := ""
var _stage_t0 := -10.0


## El Estadio en juego si tiene un fondo (si no, "": queda la mesa elegida en las opciones).
func _stage_name() -> String:
	if d.game == null or d.mode != "duel":
		return ""
	var n = d.game.stadium_name()
	if n == "" or _stage_tex(n) == null:
		return ""
	return n


func _stage_tex(name: String) -> Texture2D:
	if name == "":
		return null
	if not d._stage_cache.has(name):
		var path := "%s/%s.png" % [STADIUM_DIR, name.to_lower().replace("'", "").replace(" ", "_")]
		var tex: Texture2D = null
		if ImgLoad.exists(path):
			tex = ImageTexture.create_from_image(_table_image(path))
		d._stage_cache[name] = tex
	return d._stage_cache[name]


## Diseños de mesa: la Clásica y los PNG de fondos/ (ordenados por nombre de archivo).
func _find_table_styles() -> void:
	d.table_styles = [["Classic", ""]]
	var seen := {}
	for dir in d.TABLE_DIRS:
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
			var name: String = d.TABLE_NAMES.get(base, base.capitalize() if base == base.to_lower() else base)
			if not seen.has(name):
				seen[name] = true
				d.table_styles.append([name, dir.path_join(f)])


## Fondo de la mesa. Clásica: rojo coral del lado rival y azul del tuyo. Con un dibujo de
## fondos/, el lado del rival se oscurece un poco para distinguir las dos mitades.
func _table_image(path_override := "") -> Image:
	var img = Image.create(d.W, d.BOX_Y, false, Image.FORMAT_RGB8)
	var path: String = d.table_styles[d.table_style][1] if d.table_style < d.table_styles.size() else ""
	if path_override != "":
		path = path_override
	var pic: Image = null
	if path != "" and ImgLoad.exists(path):
		pic = ImgLoad.load(path)
	if pic != null and not pic.is_empty():
		pic.convert(Image.FORMAT_RGB8)
		if pic.get_width() != d.W or pic.get_height() != d.BOX_Y:
			# Cubrir la mesa recortando lo que sobre
			var sc = maxf(float(d.W) / pic.get_width(), float(d.BOX_Y) / pic.get_height())
			pic.resize(maxi(d.W, ceili(pic.get_width() * sc)), maxi(d.BOX_Y, ceili(pic.get_height() * sc)), Image.INTERPOLATE_NEAREST)
			pic = pic.get_region(Rect2i((pic.get_width() - d.W) / 2, (pic.get_height() - d.BOX_Y) / 2, d.W, d.BOX_Y))
		img.blit_rect(pic, Rect2i(0, 0, d.W, d.BOX_Y), Vector2i.ZERO)
		for y in 55:
			for x in d.W:
				var c = img.get_pixel(x, y)
				img.set_pixel(x, y, Color(c.r * 0.86, c.g * 0.84, c.b * 0.86))
	else:
		for y in d.BOX_Y:
			var top = y < 55
			var a := Color("#f0907a") if top else Color("#6c9cf0")
			var b := Color("#f8a88c") if top else Color("#84b0f8")
			for x in d.W:
				var on = posmod(floori((x + y) / 8.0) + floori((x - y) / 8.0), 2) == 0
				img.set_pixel(x, y, a if on else b)
	for x in d.W:
		img.set_pixel(x, 55, d.C_LIGHT)
		img.set_pixel(x, 56, Color("#384878"))
	return img


## Imagen de la carta para una ventana de w x h: recortada, con más color y reducida a
## pocos colores de 15 bits, como un sprite de GBA.
func _art_texture(id: String, w: int, h: int) -> Texture2D:
	var key = "%s|%dx%d" % [id, w, h]
	if d._art.has(key):
		return d._art[key]
	var tex: Texture2D = null
	var img = d.imagenes._load_card_image(id)
	if img != null:
		var small = _gba_art(img, w, h)
		tex = ImageTexture.create_from_image(small)
		d.imagenes._build_cosmos(key, id, small)
	d._art[key] = tex
	return tex


func _gba_art(src: Image, w: int, h: int) -> Image:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var side = float(mini(img.get_width(), img.get_height()))
	var sc = maxf(w / side, h / side)
	var cw = maxi(1, int(w / sc))
	var ch = maxi(1, int(h / sc))
	var left = (img.get_width() - cw) / 2
	var top = maxi(0, (img.get_height() - ch) / 3)
	var crop = img.get_region(Rect2i(left, top, cw, ch))
	crop.resize(w, h, Image.INTERPOLATE_LANCZOS)
	for y in h:
		for x in w:
			var c = crop.get_pixel(x, y)
			var v = Color.from_hsv(c.h, minf(1.0, c.s * 1.35), minf(1.0, c.v * 1.12))
			v = Color(clampf((v.r - 0.5) * 1.1 + 0.5, 0, 1), clampf((v.g - 0.5) * 1.1 + 0.5, 0, 1), clampf((v.b - 0.5) * 1.1 + 0.5, 0, 1), 1.0)
			crop.set_pixel(x, y, v)
	_reduce_palette(crop, 15 if w <= 16 else 24)
	return crop


## Reduce la imagen a n colores (corte por la mediana) de 15 bits.
func _reduce_palette(img: Image, n: int) -> void:
	var px: Array = []
	for y in img.get_height():
		for x in img.get_width():
			var c = img.get_pixel(x, y)
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
			var c = img.get_pixel(x, y)
			if c.a <= 0.5:
				continue
			var bestc := pal[0]
			var bd := 9.0
			for q in pal:
				var dd_ = (c.r - q.r) * (c.r - q.r) + (c.g - q.g) * (c.g - q.g) + (c.b - q.b) * (c.b - q.b)
				if dd_ < bd:
					bd = dd_
					bestc = q
			img.set_pixel(x, y, bestc)


## Activo en la mesa: el retrato cuadrado solo, sin marco de carta.
func _draw_big_card(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		d.anim_cartas._draw_card_back(r)
		return
	# El Activo se ve como retrato suelto, sin marco de carta (el tipo ya lo indica la
	# franja del cuadro de info). Ocupa el lugar de la carta, un poco más grande.
	var q = _portrait_rect(r.position.floor())
	var t = d._main_type(m.top())
	d.draw_rect(Rect2(q.position + Vector2(2, 2), q.size), Color("#202838"))
	d.draw_rect(q, d.C_INK)
	var inner = q.grow(-1)
	var side = int(inner.size.x)
	var tex = _art_texture(m.top(), side, side)
	if tex != null:
		d.draw_texture(tex, inner.position)
		d.imagenes._draw_holo(inner, m.top(), false, d._cosmos.get("%s|%dx%d" % [m.top(), side, side], {}))
	else:
		d.draw_rect(inner, d.TYPE_DARK[t])
		d.imagenes._draw_emblem(inner.grow(-8), t, d.TYPE_LIGHT[t])
	# Herramienta y MT unidas: cartitas en la esquina de abajo a la izquierda
	var k := 0
	for id in [m.tool, m.tm]:
		if id != "":
			var tr = Rect2(q.position + Vector2(3 + k * 10, q.size.y - 10), Vector2(7, 7))
			d.draw_rect(tr.grow(1), d.C_INK)
			d.imagenes._draw_card_image(tr, id)
			k += 1
	if m.is_ex():
		var er = Rect2(q.end - Vector2(14, 10), Vector2(13, 9))
		d.draw_rect(er, d.C_INK)
		d._text(er.position + Vector2(1, -2), "ex", d.C_LIGHT)
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
	var pl = d.game.owner_of(m)
	for ab in m.abilities():
		var nm: String = ab.get("name", "")
		if ab.get("kind", "") == "Poké-Power":
			if nm == Abilities.DISCARD_FOSSIL:
				continue
			var ready := false
			if pl != null and not Abilities.power_blocked(d.game, pl, m):
				ready = d.anim_ataques._power_slots(pl).has(-1) if d.game.current == pl.index else true
			out.append([nm, ready, "power"])
			continue
		if ab.get("kind", "") != "Poké-Body":
			continue
		if str(ab.get("text", "")).to_lower().contains("on your bench"):
			continue
		out.append([nm, Abilities.body(d.game, m, nm), "body"])
	return out




# Cuando un Poké-Body del Activo actúa (evita o reduce daño, contraataca, cura...): la
# pestaña da un saltito y se aclara, el arte se ilumina y sube su nombre.
const BODY_POP_TIME := 0.9


func _collect_body_events(attack: bool = false) -> void:
	var mark: int = d.game.checkup_mark if d.game.checkup_mark >= 0 else d.game.body_events.size()
	for i in d.game.body_events.size():
		var ev: Array = d.game.body_events[i]
		var early = attack and i < mark      # actuó con el golpe (no en el chequeo de después)
		if early and d.anim.get("scene", false) and (ev[0] == d.anim.get("def_mon") or ev[0] == d.anim.get("att_mon_s")):
			# En la pelea se ve junto al golpe, al lado de su Pokémon (aunque haya quedado KO)
			var who: int = d.anim["def"] if ev[0] == d.anim.get("def_mon") else d.anim["att"]
			var lst: Array = d.anim.get("bodies", [])
			if not lst.has([who, str(ev[1])]):
				lst.append([who, str(ev[1])])
			d.anim["bodies"] = lst
			continue
		for pl in d.game.players:
			if pl.active == ev[0] or pl.active2 == ev[0]:
				var item = [pl.index, str(ev[1]), early]
				if not d._body_pops.has(item) and not (d._body_pop.get("p", -1) == item[0] and d._body_pop.get("name", "") == item[1]):
					d._body_pops.append(item)
	d.game.body_events.clear()


## Avanza (se espera a que terminen el ataque y los KO, así se ve junto al resultado).
func _update_body_pop(delta: float) -> void:
	var early: bool = not d.anim.is_empty() and d.anim.get("applied", false) and not d.anim.get("waiting", false) \
			and not d._body_pops.is_empty() and d._body_pops[0].size() > 2 and d._body_pops[0][2]
	if d._body_pop.is_empty() and not early and (not d.anim.is_empty() or not d.ko_anim.is_empty() or not d.check_anim.is_empty() or not d.power_anim.is_empty() \
			or not d.banner.is_empty() or not d.prize_anim.is_empty()):
		return
	if d._body_pop.is_empty():
		if d._body_pops.is_empty():
			return
		var it: Array = d._body_pops.pop_front()
		d._body_pop = {"p": it[0], "name": it[1], "t": 0.0}
		d.snd.play("move")
	d._body_pop["t"] += delta
	if d._body_pop["t"] >= BODY_POP_TIME:
		d._body_pop = {}


## 0..1 mientras dura el salto de ese jugador (o -1 si no hay).
func _body_pop_k(player: int) -> float:
	if d._body_pop.is_empty() or d._body_pop["p"] != player:
		return -1.0
	return clampf(d._body_pop["t"] / BODY_POP_TIME, 0.0, 1.0)


func _draw_body_pop_portrait(q: Rect2, m: PokemonInPlay) -> void:
	var pl = d.game.owner_of(m) if d.game != null else null
	if pl == null or pl.active != m:
		return
	var k = _body_pop_k(pl.index)
	if k < 0.0:
		return
	var e = 1.0 - k
	var types := CardDB.types(m.top())
	var col: Color = d.TYPE_COLORS.get(types[0] if not types.is_empty() else "Colorless", Color.WHITE)
	d.draw_rect(q.grow(-1), Color(col.lightened(0.6), 0.45 * e * e))
	var nm: String = d._body_pop["name"] + "!"
	var y = q.position.y + 10 - k * 18.0
	var x = clampf(roundf(q.get_center().x - d._text_w(nm) / 2.0), 3.0, d.W - 3.0 - d._text_w(nm))
	var a = clampf(e * 2.0, 0.0, 1.0)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		d._text(Vector2(x, y) + o, nm, Color(d.C_INK, a))
	d._text(Vector2(x, y), nm, Color(1, 1, 0.75, a))


const STADIUM_SHORT := {"Team Aqua Hideout": "Aqua Hideout", "Team Magma Hideout": "Magma Hideout",
		"High Pressure System": "High Pressure", "Low Pressure System": "Low Pressure",
		"Magnetic Storm": "Mag. Storm"}
const STADIUM_RESERVE := Rect2(54, 42, 54, 12)   # entre los contadores del rival y su cuadro


## Dónde van las pestañas de Poké-Body (sin dibujarlas).
func _body_tab_rects() -> Array:
	var out: Array = []
	for pl in d.game.players:
		if pl.active == null:
			continue
		var names = _active_body_names(pl.active)
		if names.is_empty():
			continue
		var r = Rect2(d._info_rect(pl.index).position, d.INFO_SIZE)
		var txt = " / ".join(names.map(func(b): return b[0]))
		var w = minf(d._text_w(txt) + 10, r.size.x - 4)
		var below: bool = pl.index != d.human
		out.append(Rect2(r.position.x + 4, r.end.y - 1 if below else r.position.y - 11, w, 12))
	return out


## Pestaña del Estadio: en el medio de la mesa (sobre la línea que separa los lados), lo más
## centrada posible sin tocar las pestañas de Poké-Body ni los contadores; si no entra ni con
## el nombre corto, va en el hueco del rival donde está la cartita del Estadio (y la tapa).
func _layout_stadium_tab() -> void:
	d._stadium_layout = {}
	if d.game == null or d.mode != "duel" or d.game.stadium == "" or d._dbl():
		return
	var full = CardDB.card_name(d.game.stadium)
	var y := 50.0
	var band = Rect2(0, y, d.W, 12)
	var avoid := _body_tab_rects()
	for pl in d.game.players:
		avoid.append(Rect2(d._counters_pos(pl.index), Vector2(46, 20)))
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
	if d.W - 2.0 > x0:
		free.append([x0, d.W - 2.0])
	var cx = d.W / 2.0
	for name in [full, STADIUM_SHORT.get(full, full)]:
		var w = d._text_w(name) + 12
		var best_d := INF
		var best := Rect2()
		for f in free:
			if f[1] - f[0] >= w:
				var x = clampf(cx - w / 2.0, f[0], f[1] - w)
				var dd_ = absf(x + w / 2.0 - cx)
				if dd_ < best_d:
					best_d = dd_
					best = Rect2(roundf(x), y, w, 12)
		if best_d < INF:
			d._stadium_layout = {"rect": best, "txt": name, "reserve": false}
			return
	d._stadium_layout = {"rect": STADIUM_RESERVE, "txt": full, "reserve": true}


func _draw_stadium_tab() -> void:
	if d._stadium_layout.is_empty() or d.anim.get("scene", false):
		return            # (durante la mini pelea no: la mesa queda tapada)
	var r: Rect2 = d._stadium_layout["rect"]
	var txt: String = d._stadium_layout["txt"]
	d.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#283858"))
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), Color("#c08030"))
	d.draw_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, 1), Color("#f0c070"))
	d._text_scroll(r.position + Vector2(6, 1), txt, Color.WHITE, r.size.x - 10, "stadium_tab")


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
	var w = minf(d._text_w(txt) + 10, r.size.x - 4)
	var tab = Rect2(r.position.x + 4, r.end.y - 1 if below else r.position.y - 11, w, 12)
	d.draw_rect(Rect2(tab.position + Vector2(2, 2), tab.size), Color("#283858"))
	d.draw_rect(tab, d.C_INK)
	# Un tramo de color por habilidad (verde Poké-Body, rojo Poké-Power, gris apagada)
	var sx = tab.position.x + 1
	for i in bodies.size():
		var b: Array = bodies[i]
		var cols: Array = d.TAB_COLORS[b[2] if b[1] else "off"]
		var seg_w: float = d._text_w(b[0]) + (5 if i == 0 else 0) + (5 if i == bodies.size() - 1 else d._text_w(" / ") / 2.0 + 1)
		if i == bodies.size() - 1:
			seg_w = tab.end.x - 1 - sx
		seg_w = minf(seg_w, tab.end.x - 1 - sx)
		d.draw_rect(Rect2(sx, tab.position.y + 1, seg_w, tab.size.y - 2), cols[0])
		d.draw_rect(Rect2(sx, tab.position.y + 1, seg_w, 1), cols[1])
		sx += seg_w
	var pk = _body_pop_k(d.game.owner_of(m).index) if bodies.any(func(b): return b[1] and b[2] == "body") else -1.0
	if pk >= 0.0:              # el Poké-Body acaba de actuar: salta y se aclara
		var e = 1.0 - pk
		tab.position.y -= roundf(sin(minf(pk / 0.3, 1.0) * PI) * 3.0)
		d.draw_rect(tab, d.C_INK)
		d.draw_rect(tab.grow(-1), Color("#3c9848").lerp(Color("#c8f8b0"), e * 0.85))
	d._text_scroll(tab.position + Vector2(5, 1), txt, Color.WHITE if on else Color("#d8d8e0"), w - 8, "body%d" % int(r.position.y))
	if on and d.animations_on:     # un destello que la cruza cada tanto
		var ph = fmod(Clock.ms() / 1000.0 + r.position.y * 0.01, 2.5) / 0.7
		if ph < 1.0:
			var bx = tab.position.x - 8 + ph * (tab.size.x + 16)
			for yy in int(tab.size.y - 2):
				var x = bx - yy * 0.5
				var r1 = Rect2(x, tab.position.y + 1 + yy, 5, 1).intersection(tab.grow(-1))
				if r1.size.x > 0:
					d.draw_rect(r1, Color(1, 1, 1, 0.85))
				var r2 = Rect2(x + 7, tab.position.y + 1 + yy, 2, 1).intersection(tab.grow(-1))
				if r2.size.x > 0:
					d.draw_rect(r2, Color(1, 1, 1, 0.5))
		# y una estrellita que titila en la punta al terminar de pasar
		if ph >= 1.0 and ph < 1.5:
			var sp = Vector2(tab.end.x - 2, tab.position.y + 1)
			var e = 1.0 - (ph - 1.0) / 0.5
			d.draw_rect(Rect2(sp + Vector2(-2, 0), Vector2(5, 1)), Color(1, 1, 0.8, e))
			d.draw_rect(Rect2(sp + Vector2(0, -2), Vector2(1, 5)), Color(1, 1, 0.8, e))


## Retrato del Activo (46x46) dentro del lugar de la carta (42x52).
func _portrait_rect(card_pos: Vector2) -> Rect2:
	return Rect2(card_pos + Vector2(-2, 3), Vector2(46, 46))


## Preparación: los Pokémon que pone el rival van boca abajo (como en el juego real, se dan
## vuelta los de los dos recién cuando termina la preparación).
func _face_down(m: PokemonInPlay) -> bool:
	if d.game == null or d.game.phase != "setup" or d.mode != "duel":
		return false
	var own = d.game.owner_of(m)
	return own != null and own.index != d.human


func _draw_mini_card(r: Rect2, m: PokemonInPlay, hp_inside: bool = false) -> void:
	if _face_down(m):
		d.anim_cartas._draw_card_back(r)
		return
	var t = d._main_type(m.top())
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), d.C_YELLOW)
	d.draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), d.C_YELLOW_D)
	d._fill_types(r.grow(-2), m, true)
	if d.imagenes._shows_reverse(m):
		d.imagenes._draw_reverse(r.grow(-1), Rect2(r.position + Vector2(2, 3), Vector2(16, 16)), m.top())
	d.draw_rect(Rect2(r.position + Vector2(2, 3), Vector2(16, 16)), Color("#c8c8d0"))
	var tex := _art_texture(m.top(), 14, 14)
	if tex != null:
		d.draw_texture(tex, r.position + Vector2(3, 4))
		d.imagenes._draw_holo(Rect2(r.position + Vector2(3, 4), Vector2(14, 14)), m.top(), true)
	else:
		d.draw_rect(Rect2(r.position + Vector2(3, 4), Vector2(14, 14)), d.TYPE_DARK[t])
		d.imagenes._draw_emblem(Rect2(r.position + Vector2(5, 6), Vector2(10, 10)), t, d.TYPE_LIGHT[t])
	# Energías unidas
	var units: Array = Energy.units(m)
	units = units.slice(0, maxi(0, units.size() - d.anim_cartas._pending_units(m)))
	for i in mini(units.size(), 4):
		var u: Array = units[i]
		var et: String = u[0] if u.size() == 1 else "*"
		var ec: Color = d.TYPE_COLORS.get(et, d.C_LIGHT)
		var ey := 14.0 if hp_inside else 20.0     # mesa doble: arriba del número de PS
		d.draw_rect(Rect2(r.position + Vector2(2 + i * 4, ey), Vector2(4, 4)), d.C_INK)
		d.draw_rect(Rect2(r.position + Vector2(3 + i * 4, ey + 1), Vector2(2, 2)), ec)
	if units.size() > 4:
		d.draw_rect(Rect2(r.position + Vector2(18, 20), Vector2(1, 3)), d.C_INK)
		d.draw_rect(Rect2(r.position + Vector2(17, 21), Vector2(3, 1)), d.C_INK)
	# Herramienta / MT: la misma cartita que en el Activo, en la esquina de arriba a la
	# derecha (si tiene las dos, una al lado de la otra); y condición especial (puntito rojo)
	var k := 0
	for id in [m.tool, m.tm]:
		if id != "":
			var tr = Rect2(r.end.x - 9 - k * 9, r.position.y + 1, 7, 7)
			d.draw_rect(tr.grow(1), d.C_INK)
			d.imagenes._draw_card_image(tr, id)
			k += 1
	if not _condition_list(m).is_empty():
		d.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(4, 4)), d.C_INK)
		d.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, 2)), d.C_HP_LOW)
	# PS que le quedan, en números
	var ratio = clampf(d.anim_pokemon._shown_hp(m) / max(1, m.max_hp()), 0.0, 1.0)
	var hs = str(maxi(0, roundi(d.anim_pokemon._shown_hp(m))))
	var w = hs.length() * 4 + 3
	var pill = Rect2(floor(r.get_center().x - w / 2.0), r.end.y + 1, w, 7)
	if hp_inside:                  # mesa doble: el número va sobre el borde de abajo de la carta
		pill.position.y = r.end.y - 6
	d.draw_rect(pill, d.C_INK)
	d.imagenes._draw_tiny(pill.position + Vector2(2, 1), hs, d.HP_COLORS[0 if ratio > 0.5 else (1 if ratio > 0.2 else 2)][0])


func _draw_bench_cards(p: PlayerState) -> void:
	for i in d.game.rules.bench_size:
		var r = d._bench_rect(p.index, i)
		if i >= p.bench.size() or d.anim_ataques._is_moving(p.bench[i]):
			d._outline(r, d.C_LINE if p.index == d.human else Color("#c87060"))
			continue
		_draw_mini_card(r, p.bench[i])
		if not _face_down(p.bench[i]):
			d.anim_ataques._draw_bench_status(p, i, r)


## Recuadro con nombre, barra de PS, condiciones y Energías (como en las batallas de GBA).
func _draw_info_box(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		return
	var t = d._main_type(m.top())
	var dk := _draw_box_bg(r, m)
	var tc: Color = DARK_TEXT if dk else d.C_TEXT
	if d.imagenes._shows_reverse(m):
		d.imagenes._draw_reverse_box(Rect2(r.position + Vector2(4, 1), r.size - Vector2(5, 2)), m.top())
	d._fill_types(Rect2(r.position + Vector2(1, 1), Vector2(3, r.size.y - 2)), m)
	if CardDB.card_name(m.top()).contains("★"):
		_draw_star_mark(r)
	if CardDB.is_delta(m.top()):
		_draw_delta_mark(r, m.top(), r.position.y + 19)
	_draw_team_mark(r, m.top(), 8)
	var name := m.display_name()
	var ex := name.ends_with(" ex")
	if ex:
		name = name.trim_suffix(" ex")
	var avail = r.size.x - 11 - (12 if ex else 0)
	d._text_scroll(r.position + Vector2(7, 1), name, tc, avail, "info%d" % int(r.position.y))
	if ex:
		d._text(Vector2(r.position.x + 7 + minf(d._text_w(name), avail) + 2, r.position.y + 1), "ex", DARK_EX if dk else Color("#c03028"))
	_draw_hp_bar(r.position + Vector2(7, 12), int(r.size.x) - 11, m)
	var conds := _condition_list(m)
	if not conds.is_empty() and not d.anim_ataques._draw_status_pill(r.position + Vector2(7, 21), conds):
		for i in conds.size():         # sin las pastillas: los símbolos dibujados
			_draw_condition_icon(r.position + Vector2(11 + i * 9, 24), conds[i])
	var hp_txt = "%d/%d" % [maxi(0, roundi(d.anim_pokemon._shown_hp(m))), m.max_hp()]
	d._text(Vector2(r.end.x - 5 - d._text_w(hp_txt), r.position.y + 19), hp_txt, tc)
	d.imagenes._draw_energy(r.position + Vector2(7, 29), m)


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
		cols.append(d.TYPE_COLORS.get(ty, d.C_TEXT))
	if cols.is_empty():
		cols = [d.C_TEXT]
	var t := Clock.ms() / 1000.0
	var pulse = 0.5 + 0.5 * sin(t * TAU / 1.5)       # late cada 1,5 s
	var gh: int = DELTA_CORE.size()
	var gw: int = DELTA_CORE[0].length()
	var cy = (top + 3.0 + r.end.y - 3.0) / 2.0
	var o = Vector2(roundf(r.position.x + 3 + (r.size.x - 3) / 2.0 - gw / 2.0), roundf(cy - gh / 2.0))
	var a_core = 0.30 + 0.12 * pulse
	var a_glow = 0.22 + 0.20 * pulse
	var sweep = fmod(t / 3.0, 1.0) * (gw + gh) * 1.25 - gh * 0.4     # destello: una pasada cada 3 s
	for y in gh:
		var col: Color = cols[0] if y < gh / 2 or cols.size() == 1 else cols[1]
		var rc: String = DELTA_CORE[y]
		var rg: String = DELTA_GLOW[y]
		for x in gw:
			var a = maxf(int(rc[x]) / 9.0 * a_core, int(rg[x]) / 9.0 * a_glow)
			if a <= 0.01:
				continue
			var c = Color(col, a)
			if int(rc[x]) >= 5 and absf(x + y * 0.6 - sweep) < 2.0:
				c = Color(col.lightened(0.5), minf(1.0, a + 0.4))
			d.draw_rect(Rect2(o + Vector2(x, y), Vector2(1, 1)), c)


## Recuadro del Activo: crema con borde tinta; el de los Pokémon Dark, en negativo (gris
## violáceo oscuro con letra clara) y con un poco de humo que sube del borde de abajo, como
## en la pelea. Devuelve si es Dark.
const DARK_BOX := Color("#3c3644")
const DARK_STRIP := Color("#2e2a36")
const DARK_EDGE := Color("#686078")
const DARK_TEXT := Color("#f0ecdc")
const DARK_EX := Color("#f87860")


func _draw_box_bg(r: Rect2, m: PokemonInPlay) -> bool:
	var dk := MiniBattle.is_dark(m.top())
	d.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#283858"))
	d.draw_rect(r, DARK_EDGE if dk else d.C_INK)
	d.draw_rect(r.grow(-1), DARK_BOX if dk else Color("#f8f8e8"))
	d.draw_rect(Rect2(r.position.x + 1, r.end.y - 3, r.size.x - 2, 2), DARK_STRIP if dk else Color("#d8d8b8"))
	if dk:
		_draw_box_smoke(r)
	return dk


## Humo del recuadro Dark: unas pocas partículas que suben del borde de abajo y se apagan en
## 4 pasos (va detrás del texto, la barra y las Energías).
func _draw_box_smoke(r: Rect2) -> void:
	var t := Clock.ms() / 1000.0
	var inner := r.grow(-2)
	for i in 9:
		var ph := fmod(t * 0.33 + i * 0.37 + i * i * 0.053, 1.0)
		if ph > 0.45:          # cada partícula está viva menos de la mitad del ciclo
			continue
		var f := ph / 0.45
		var sd := absf(fmod(sin(i * 12.9898) * 43758.5453, 1.0))
		var x := roundf(inner.position.x + 4 + sd * (inner.size.x - 8) + sin(t * 3.0 + i * 1.3) * 1.2)
		var y := roundf(inner.end.y - 1 - f * inner.size.y * 0.7)
		var sz := 2.0 if f < 0.6 and i % 3 != 0 else 1.0
		var col := Color("#9c8cac") if f < 0.5 else Color("#7a6e88")
		col.a = [0.7, 0.6, 0.4, 0.2][mini(3, int(f * 4.0))]
		var px := Rect2(Vector2(x, y), Vector2(sz, sz)).intersection(inner)
		if px.has_area():
			d.draw_rect(px, col)


## Pokémon de Team Aqua, Team Magma o Rocket's: el logo del equipo de fondo, detrás del nombre
## y los PS, latiendo suave como la δ y la ★. "pad": cuánto más bajo que el recuadro.
func _draw_team_mark(r: Rect2, id: String, pad: int) -> void:
	var tex := TeamLogos.mark(TeamLogos.team(id), int(r.size.y) - pad)
	if tex == null:
		return
	var pulse = 0.5 + 0.5 * sin(Clock.ms() / 1000.0 * TAU / 1.5)
	var o = Vector2(roundf(r.position.x + 3 + (r.size.x - 3) / 2.0 - tex.get_width() / 2.0),
			roundf(r.position.y + (r.size.y - tex.get_height()) / 2.0))
	d.draw_texture(tex, o, Color(1, 1, 1, 0.24 + 0.10 * pulse))


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
	var o = Vector2(roundf(r.position.x + 3 + (r.size.x - 3) / 2.0 - c.x), roundf(r.position.y + r.size.y / 2.0 + 1 - c.y))
	var t := Clock.ms() / 1000.0
	var pulse = 0.5 + 0.5 * sin(t * TAU / 1.5)
	var yel := Color("#f8d030")
	d.draw_texture(data["glow"], o, Color(yel, 0.25 + 0.22 * pulse))
	d.draw_texture(data["core"], o, Color(yel, 0.30 + 0.12 * pulse))
	# Destello diagonal (una pasada cada 3 s) y puntas que titilan de a una
	var sweep = fmod(t / 3.0, 1.0) * 2.8 - 1.4
	if absf(sweep) < 1.1:
		for q: Vector2i in data["pts"]:
			if absf(((q.x - c.x) + (q.y - c.y)) / (2.0 * rad) - sweep) < 0.08:
				d.draw_rect(Rect2(o + Vector2(q), Vector2(1, 1)), Color("#fffac8", 0.75))
	var clip = r.grow(-1)
	for k in 5:
		if sin(t * TAU / 0.75 + k * 1.3) <= 0.6:
			continue
		var ang = -PI / 2 + k * TAU / 5
		var tip = (o + c + Vector2(cos(ang), sin(ang)) * rad * 0.95).round()
		for dd in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			if clip.has_point(tip + dd):
				d.draw_rect(Rect2(tip + dd, Vector2(1, 1)), Color("#fff8be"))


## Barra de PS con la etiqueta naranja: verde, amarilla o roja según lo que queda.
func _draw_hp_bar(pos: Vector2, width: int, m: PokemonInPlay) -> void:
	var shown = d.anim_pokemon._shown_hp(m)
	var ratio = clampf(shown / max(1, m.max_hp()), 0.0, 1.0)
	var real := clampf(float(m.hp_left()) / max(1, m.max_hp()), 0.0, 1.0)
	d.draw_rect(Rect2(pos, Vector2(width, 7)), d.C_INK)
	d.imagenes._draw_tiny(pos + Vector2(2, 1), "HP", Color("#f8b838"))
	var bx := pos.x + 11
	var bw := width - 12
	d.draw_rect(Rect2(bx, pos.y + 2, bw, 3), Color("#506858"))
	var col: Array = d.HP_COLORS[0 if ratio > 0.5 else (1 if ratio > 0.2 else 2)]
	var fill = roundf(bw * ratio)
	d.draw_rect(Rect2(bx, pos.y + 2, fill, 2), col[0])
	d.draw_rect(Rect2(bx, pos.y + 4, fill, 1), col[1])
	if real < ratio:   # la parte que se está perdiendo, en blanco
		var rf = roundf(bw * real)
		d.draw_rect(Rect2(bx + rf, pos.y + 2, fill - rf, 3), d.C_LIGHT)


## Dorso de carta chiquito (original, no es el dorso oficial).
func _draw_mini_back(r: Rect2) -> void:
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), Color("#3858c0"))
	var c = r.get_center().floor()
	d.draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), d.C_YELLOW)
	d.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color("#c03028"))


## Premios (dorsos) y, con íconos y números, el mazo, la mano y el descarte.
func _draw_counters(p: PlayerState) -> void:
	var o = d._counters_pos(p.index)
	var mine = p.index == d.human
	for i in 6:
		var c = o + Vector2((i % 3) * 9, (i / 3) * 10)
		if i < p.prizes.size():
			_draw_mini_back(Rect2(c, Vector2(8, 9)))
		else:
			d._outline(Rect2(c, Vector2(8, 9)), d.C_LINE if mine else Color("#c87060"))
	var ix = o.x + 29
	var vals := [p.deck.size(), p.hand.size(), p.discard.size()]
	var cols := [Color("#3858c0"), d.C_LIGHT, Color("#909098")]
	for k in 3:
		var y = o.y + k * 7
		d.draw_rect(Rect2(ix, y, 5, 6), d.C_INK)
		d.draw_rect(Rect2(ix + 1, y + 1, 3, 4), cols[k])
		d.imagenes._draw_tiny(Vector2(ix + 8, y + 1), str(vals[k]), d.C_INK)
		d.imagenes._draw_tiny(Vector2(ix + 7, y), str(vals[k]), d.C_LIGHT)


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

var mock_second: Array = [null, null]   # el segundo Activo de cada jugador en la maqueta
var mock_target := -1               # Activo del rival marcado como objetivo en la maqueta (0/1)

const DBL_CARD := Vector2(26, 28)
const DBL_INFO := Vector2(82, 28)
const DBL_BENCH := 4


## Rectángulo de la carta del Activo i (0 o 1) de un jugador en la mesa doble.
func _dbl_card_rect(player: int, i: int) -> Rect2:
	if player == d.human:
		return Rect2(Vector2(4 + i * 120, 57), DBL_CARD)
	return Rect2(Vector2(d.W - 4 - DBL_CARD.x - (1 - i) * 120, 27), DBL_CARD)


func _dbl_info_rect(player: int, i: int) -> Rect2:
	var c := _dbl_card_rect(player, i)
	if player == d.human:            # tu ficha a la derecha de la carta; la del rival a la izquierda
		return Rect2(c.end.x + 2, c.position.y, DBL_INFO.x, DBL_INFO.y)
	return Rect2(c.position.x - 2 - DBL_INFO.x, c.position.y, DBL_INFO.x, DBL_INFO.y)


func _dbl_bench_rect(player: int, i: int) -> Rect2:
	if player == d.human:
		return Rect2(Vector2(d.W - 4 - DBL_BENCH * 22 + 2 + i * 22, 86), d.MINI_SIZE)
	return Rect2(Vector2(4 + i * 22, 0), d.MINI_SIZE)


func _dbl_actives(p: PlayerState) -> Array:
	var out: Array = [p.active, p.active2 if p.active2 != null else mock_second[p.index]]
	return out


func _draw_doubles_board(opp: PlayerState, me: PlayerState) -> void:
	for pl: PlayerState in [opp, me]:
		var mine = pl == me
		# Banca: 4 lugares, el número de PS adentro de la carta (no hay lugar abajo)
		for i in DBL_BENCH:
			var r = _dbl_bench_rect(pl.index, i)
			if i < pl.bench.size():
				_draw_mini_card(r, pl.bench[i], true)
			else:
				d._outline(r, d.C_LINE if mine else Color("#c87060"))
		# Premios, mazo, mano y descarte al lado de la Banca
		_draw_counters_at(pl, d._counters_pos(pl.index) if d._dbl() else (Vector2(d.W - 4 - 46, 1) if not mine else Vector2(4, 87)))
		# Los dos Activos
		var acts = _dbl_actives(pl)
		for i in 2:
			var m: PokemonInPlay = acts[i]
			var cr = _dbl_card_rect(pl.index, i)
			if m == null or d.anim_ataques._is_moving(m):
				d._outline(cr, d.C_LINE if mine else Color("#c87060"))
				continue
			var off := Vector2.ZERO
			if i == d.dbl_focus[pl.index]:
				off = d.anim_ataques._anim_offset(pl.index)
			if pl.index == d.human:
				off += d.anim_pokemon._idle_bob(pl)
			var ir = _dbl_info_rect(pl.index, i)
			_draw_compact_info(Rect2(ir.position + d.anim_pokemon._hp_shake(m), ir.size), m, mine)
			_draw_compact_card(Rect2(cr.position + off, cr.size), m)
			d.anim_ataques._draw_status_fx(pl, m, Rect2(cr.position + off + Vector2(2, 2), Vector2(22, 22)))
		d.anim_ataques._draw_hit_flash(pl)
	if d.game.stadium != "":
		_draw_stadium_card_at(d.game.stadium, Vector2(112, 1))
	# Acción marcada en el menú: el Activo propio que actúa (amarillo) y el del rival que
	# recibe el ataque (rojo, titila)
	var hov := _hovered_action()
	if not hov.is_empty() and hov.has("ctx") or (not hov.is_empty() and hov["t"] in ["attack", "retreat"]):
		var c = hov.get("ctx", [false, false])
		var my_i = 1 if c[me.index] else 0
		var on := int(Clock.ms() / 250.0) % 2 == 0
		if me.active2 != null:
			d._outline(_dbl_card_rect(me.index, my_i).grow(1), Color("#f8d030"))
		if hov["t"] == "attack" and opp.active2 != null and hov.get("tg", -2) == -2:
			var op_i = 1 if c[opp.index] else 0
			for r: Rect2 in [_dbl_card_rect(opp.index, op_i), _dbl_info_rect(opp.index, op_i)]:
				d._outline(r.grow(1), Color("#f85838") if on else Color("#f8d030"))
				d._outline(r.grow(2), Color(0, 0, 0, 0.45))
	# Objetivo elegido: flechita roja que salta sobre el Activo del rival
	if mock_target >= 0:
		var on := int(Clock.ms() / 250.0) % 2 == 0
		var col := Color("#f85838") if on else Color("#f8d030")
		for r: Rect2 in [_dbl_card_rect(opp.index, mock_target), _dbl_info_rect(opp.index, mock_target)]:
			d._outline(r.grow(1), col)
			d._outline(r.grow(2), Color(0, 0, 0, 0.45))
		# el otro Activo del rival se apaga un poco
		var other := 1 - mock_target
		for r: Rect2 in [_dbl_card_rect(opp.index, other), _dbl_info_rect(opp.index, other)]:
			d.draw_rect(r, Color(0, 0, 0, 0.25))


## La acción marcada en el menú de tu turno (si hay una).
func _hovered_action() -> Dictionary:
	if d.game == null or d.game.actor() != d.human or d.menu_level != "list" or d.cursor < 0 or d.cursor >= d.menu_items.size():
		return {}
	return d.menu_items[d.cursor].get("action", {})


## Carta compacta del Activo en la mesa doble: marco amarillo, ilustración de 22x22 y una
## franja abajo con herramienta/MT y el logo ex.
func _draw_compact_card(r: Rect2, m: PokemonInPlay) -> void:
	if _face_down(m):
		d.anim_cartas._draw_card_back(r)
		return
	r.position = r.position.floor()
	var t = d._main_type(m.top())
	d.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color("#202838"))
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), d.C_YELLOW)
	d.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), d.C_YELLOW_L)
	d.draw_rect(Rect2(r.position.x + 1, r.end.y - 2, r.size.x - 2, 1), d.C_YELLOW_D)
	d._fill_types(r.grow(-2), m, true)
	d.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(24, 24)), Color("#e0e0e8"))
	var tex := _art_texture(m.top(), 22, 22)
	if tex != null:
		d.draw_texture(tex, r.position + Vector2(2, 2))
	else:
		d.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(22, 22)), d.TYPE_DARK[t])
		d.imagenes._draw_emblem(Rect2(r.position + Vector2(6, 6), Vector2(14, 14)), t, d.TYPE_LIGHT[t])
	if m.tool != "" or m.tm != "":
		d.draw_rect(Rect2(r.position + Vector2(2, 25), Vector2(3, 2)), d.imagenes._card_bg(m.tool if m.tool != "" else m.tm))
	if m.is_ex():
		d.imagenes._draw_tiny(r.position + Vector2(r.size.x - 9, 22), "ex", d.C_LIGHT)


## Ficha compacta: nombre, barra de PS y abajo las Energías y los PS en números. La
## pastilla de estado va sobre el nombre, a la derecha.
func _draw_compact_info(r: Rect2, m: PokemonInPlay, mine: bool) -> void:
	if _face_down(m):
		return
	var dk := _draw_box_bg(r, m)
	var tc: Color = DARK_TEXT if dk else d.C_TEXT
	d._fill_types(Rect2(r.position + Vector2(1, 1), Vector2(3, r.size.y - 2)), m)
	if CardDB.card_name(m.top()).contains("★"):
		_draw_star_mark(r)
	if CardDB.is_delta(m.top()):
		_draw_delta_mark(r, m.top(), r.position.y + 17)
	_draw_team_mark(r, m.top(), 6)
	var name := m.display_name()
	var ex := name.ends_with(" ex")
	if ex:
		name = name.trim_suffix(" ex")
	var conds := _condition_list(m)
	var avail = r.size.x - 11 - (12 if ex else 0) - (22 if not conds.is_empty() else 0)
	d._text_fit(r.position + Vector2(7, 0), name, tc, avail)
	if ex:
		d._text(Vector2(r.position.x + 7 + minf(d._text_w(name), avail) + 2, r.position.y), "ex", DARK_EX if dk else Color("#c03028"))
	if not conds.is_empty():
		d.anim_ataques._draw_status_pill(Vector2(r.end.x - 23, r.position.y + 2), conds)
	_draw_hp_bar(r.position + Vector2(5, 10), int(r.size.x) - 8, m)
	var hp_txt = "%d/%d" % [maxi(0, roundi(d.anim_pokemon._shown_hp(m))), m.max_hp()]
	var hw = d._text_w(hp_txt)
	d._text(Vector2(r.end.x - 4 - hw, r.position.y + 16), hp_txt, tc)
	# Energías: las que entran antes del número; si sobran, "+n"
	var units: Array = Energy.units(m)
	units = units.slice(0, maxi(0, units.size() - d.anim_cartas._pending_units(m)))
	var room = int((r.size.x - 10 - hw - 4) / 9.0)
	var shown = mini(units.size(), room if units.size() <= room else room - 1)
	for i in shown:
		var u: Array = units[i]
		d.imagenes._draw_energy_icon(r.position + Vector2(10 + i * 9, 21.5), 8, u[0] if u.size() == 1 else "*")
	if units.size() > shown:
		d.imagenes._draw_tiny(r.position + Vector2(7 + shown * 9, 19), "+%d" % (units.size() - shown), tc)


func _draw_counters_at(p: PlayerState, o: Vector2) -> void:
	var mine = p.index == d.human
	for i in 6:
		var c = o + Vector2((i % 3) * 9, (i / 3) * 10)
		if i < p.prizes.size():
			_draw_mini_back(Rect2(c, Vector2(8, 9)))
		else:
			d._outline(Rect2(c, Vector2(8, 9)), d.C_LINE if mine else Color("#c87060"))
	var ix = o.x + 29
	var vals := [p.deck.size(), p.hand.size(), p.discard.size()]
	var cols := [Color("#3858c0"), d.C_LIGHT, Color("#909098")]
	for k in 3:
		var y = o.y + k * 7
		d.draw_rect(Rect2(ix, y, 5, 6), d.C_INK)
		d.draw_rect(Rect2(ix + 1, y + 1, 3, 4), cols[k])
		d.imagenes._draw_tiny(Vector2(ix + 8, y + 1), str(vals[k]), d.C_INK)
		d.imagenes._draw_tiny(Vector2(ix + 7, y), str(vals[k]), d.C_LIGHT)


func _draw_stadium_card_at(id: String, at: Vector2) -> void:
	var r := Rect2(at, Vector2(16, 20))
	d.draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), d.C_STADIUM_BG)
	d.imagenes._draw_card_image(Rect2(r.position + Vector2(2, 2), Vector2(12, 12)), id)
	d.draw_rect(Rect2(r.position.x + 2, r.position.y + 15, 12, 2), d.C_BODY if d.game.stadium_owner != d.human else d.C_FRAME_MID)

# ===========================================================================
# Herramientas, Máquinas Técnicas y Estadio en la mesa
# ===========================================================================

## Cartita del Estadio, en el lado del rival.
func _draw_stadium_card(id: String) -> void:
	var r := Rect2(88, 33, 16, 20)
	d.draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color("#202838"))
	d.draw_rect(r, d.C_INK)
	d.draw_rect(r.grow(-1), d.C_STADIUM_BG)
	d.imagenes._draw_card_image(Rect2(r.position + Vector2(2, 2), Vector2(12, 12)), id)
	d.draw_rect(Rect2(r.position.x + 2, r.position.y + 15, 12, 2), d.C_BODY if d.game.stadium_owner != d.human else d.C_FRAME_MID)




## Fondo tenue del Estadio: su imagen (si pusiste una en sprites/) estirada sobre la mesa,
## casi transparente. Sin imagen, una silueta grande y suave de un edificio.
func _draw_stadium_background(id: String) -> void:
	if not d._stadium_bg.has(id):
		var tex: Texture2D = null
		var name := CardDB.card_name(id)
		for dir in d.SPRITE_DIRS:
			for n in [id, name]:
				for ext in ["png", "jpg", "webp"]:
					var path = "%s/%s.%s" % [dir, n, ext]
					if tex == null and ImgLoad.exists(path):
						var img = ImgLoad.load(path)
						if img != null and not img.is_empty():
							img.convert(Image.FORMAT_RGBA8)
							# Cubrir la mesa (240x110) recortando lo que sobre
							var bw = d.W * (d.HD_SCALE if d.hd else 1)
							var bh = d.BOX_Y * (d.HD_SCALE if d.hd else 1)
							var sc = maxf(float(bw) / img.get_width(), float(bh) / img.get_height())
							img.resize(maxi(bw, int(img.get_width() * sc)), maxi(bh, int(img.get_height() * sc)), Image.INTERPOLATE_BILINEAR)
							var crop = img.get_region(Rect2i((img.get_width() - bw) / 2, (img.get_height() - bh) / 2, bw, bh))
							tex = ImageTexture.create_from_image(crop)
		d._stadium_bg[id] = tex
	var t: Texture2D = d._stadium_bg[id]
	if t != null:
		d.draw_texture_rect(t, Rect2(0, 0, d.W, d.BOX_Y), false, Color(1, 1, 1, 0.16))
		return
	# Silueta genérica
	var c := Color(1, 1, 1, 0.05)
	var cx = d.W / 2.0
	d.draw_colored_polygon(PackedVector2Array([Vector2(cx - 50, 50), Vector2(cx, 18), Vector2(cx + 50, 50)]), c)
	d.draw_rect(Rect2(cx - 40, 50, 80, 44), c)
	d.draw_rect(Rect2(cx - 9, 72, 18, 22), Color(0, 0, 0, 0.05))
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
			"poisoned": Color("#9040b0"), "burned": Color("#e05828")}.get(cond, d.C_HP_LOW)
	d.draw_circle(c, 4.5, d.C_TEXT)
	d.draw_circle(c, 3.6, col)
	var w := Color.WHITE
	match cond:
		"asleep":       # una Z
			d.draw_line(c + Vector2(-2, -2), c + Vector2(2, -2), w)
			d.draw_line(c + Vector2(2, -2), c + Vector2(-2, 2), w)
			d.draw_line(c + Vector2(-2, 2), c + Vector2(2, 2), w)
		"confused":     # espiral
			d.draw_arc(c, 2.2, 0.0, TAU * 0.8, 8, w, 1.0)
			d.draw_circle(c, 0.7, w)
		"paralyzed":    # rayo
			d.draw_colored_polygon(PackedVector2Array([c + Vector2(0.5, -3), c + Vector2(-1.8, 0.5), c + Vector2(0, 0.5),
					c + Vector2(-0.5, 3), c + Vector2(1.8, -0.5), c + Vector2(0, -0.5)]), d.C_TEXT)
		"poisoned":     # burbujas
			d.draw_circle(c + Vector2(-1, 1), 1.3, w)
			d.draw_circle(c + Vector2(1.4, -1.2), 0.9, w)
		"burned":       # llamita
			d.monedas._draw_small_flame(c + Vector2(0, 0.3), 2.6)
