class_name TitleScene
extends RefCounted
## Escena animada de la pantalla de título: un fondo grande con una cámara que se mueve despacio,
## un detalle animado (el agua) y unos Pokémon de Mystery Dungeon que hacen algo en loop.
## Las escenas están en data/titulos.json; al abrir el juego se elige una al azar.

const SpecialFX = preload("res://scenes/special_fx.gd")
const DATA := "res://data/titulos.json"
const DIRS := {"abajo": 0, "abajo-derecha": 1, "derecha": 2, "arriba-derecha": 3, "arriba": 4,
		"arriba-izquierda": 5, "izquierda": 6, "abajo-izquierda": 7}

var scene := {}
var _tex := {}       # ruta -> Texture2D
var _anims := {}     # "especie|anim" -> {tex, w, h, durs, total, rows, sh: {fila: [Vector2...]}}


## Elige una escena al azar entre las que tienen su fondo. false si no hay ninguna.
func pick() -> bool:
	var j = JSON.parse_string(FileAccess.get_file_as_string(DATA)) if FileAccess.file_exists(DATA) else null
	if not (j is Dictionary):
		return false
	var ok: Array = []
	for e in j.get("escenas", []):
		if _image(str(e.get("fondo", ""))) != null:
			ok.append(e)
	if ok.is_empty():
		return false
	scene = ok[randi() % ok.size()]
	return true


func _image(path: String) -> Texture2D:
	if path == "":
		return null
	if not _tex.has(path):
		var img := ImgLoad.load(path)
		_tex[path] = ImageTexture.create_from_image(img) if img != null else null
	return _tex[path]


## Hoja de animación de una especie (resuelve CopyOf); {} si no la tiene.
func _anim(sp: String, name: String) -> Dictionary:
	var key := sp + "|" + name
	if _anims.has(key):
		return _anims[key]
	var out := {}
	var xml: Dictionary = MiniBattle._data(sp)["_xml"]
	var info: Dictionary = xml["anims"].get(name, {})
	var src := name
	if info.has("copy"):
		src = info["copy"]
		info = xml["anims"].get(src, info)
	var img := ImgLoad.load("%s/%s/%s-Anim.png" % [MiniBattle.DIR, sp, src])
	if img != null and int(info.get("w", 0)) > 0:
		var durs: Array = info["durs"].duplicate()
		var w := int(info["w"])
		var h := int(info["h"])
		var n := mini(img.get_width() / w, durs.size()) if not durs.is_empty() else img.get_width() / w
		if durs.is_empty():
			for i in n:
				durs.append(4)
		durs = durs.slice(0, n)
		var total := 0
		for x in durs:
			total += int(x)
		img.convert(Image.FORMAT_RGBA8)
		out = {"tex": ImageTexture.create_from_image(img), "w": w, "h": h, "durs": durs, "total": maxi(1, total),
				"rows": img.get_height() / h, "sh": {},
				"shimg": ImgLoad.load("%s/%s/%s-Shadow.png" % [MiniBattle.DIR, sp, src])}
	_anims[key] = out
	return out


## Dónde pisa en cada cuadro de una fila (el punto verde de la hoja de sombras).
func _shadows(an: Dictionary, row: int) -> Array:
	if an["sh"].has(row):
		return an["sh"][row]
	var w: int = an["w"]
	var h: int = an["h"]
	var shimg: Image = an["shimg"]
	var out: Array = []
	for c in an["durs"].size():
		var acc := Vector2.ZERO
		var cnt := 0
		if shimg != null:
			for y in h:
				for x in w:
					var px := Vector2i(c * w + x, row * h + y)
					if px.x >= shimg.get_width() or px.y >= shimg.get_height():
						continue
					var col := shimg.get_pixelv(px)
					if col.a > 0.5 and col.g > 0.8 and col.r < 0.3 and col.b < 0.3:
						acc += Vector2(x, y)
						cnt += 1
		out.append(acc / cnt if cnt > 0 else Vector2(w / 2.0, h - 4))
	an["sh"][row] = out
	return out


func _frame(an: Dictionary, ticks: float) -> int:
	var t := int(ticks) % int(an["total"])
	for i in an["durs"].size():
		if t < int(an["durs"][i]):
			return i
		t -= int(an["durs"][i])
	return 0


## Dibuja la escena en el momento t (segundos desde que se abrió el título).
func draw(d: CanvasItem, t: float) -> void:
	var bg := _image(str(scene.get("fondo", "")))
	if bg == null:
		return
	var dur := maxf(1.0, float(scene.get("duracion", 12)))
	var tl := fmod(t, dur)
	var cam: Dictionary = scene.get("camara", {})
	var cpos := Vector2(float(cam.get("x", 0)) + float(cam.get("paneo", 0)) * sin(TAU * t / dur),
			float(cam.get("y", 0))).round()
	# Destellos (relámpagos): el fondo pasa por sus versiones más claras un instante
	var flash := -1.0
	var de: Dictionary = scene.get("destellos", {})
	if not de.is_empty():
		var seq: Array = de.get("secuencia", [3, 5, 4, 5, 4, 3, 2, 1])
		var paso := float(de.get("paso", 0.05))
		var fondos: Array = de.get("fondos", [])
		for m in de.get("momentos", []):
			var k := tl - float(m)
			if k >= 0.0 and k < seq.size() * paso:
				var idx := int(seq[int(k / paso)]) - 1
				if idx >= 0 and idx < fondos.size() and _image(str(fondos[idx])) != null:
					bg = _image(str(fondos[idx]))
				flash = k
	d.draw_texture(bg, -cpos)
	# Detalles animados del fondo (el agua, las nubes...): "agua" y/o la lista "animados"
	var anims: Array = scene.get("animados", []).duplicate()
	if scene.has("agua"):
		anims.append(scene["agua"])
	for ag in anims:
		var tira := _image(str(ag.get("tira", "")))
		if tira == null:
			continue
		var n := maxi(1, int(ag.get("cuadros", 1)))
		var fw := tira.get_width() / n
		var f := int(t * float(ag.get("fps", 8))) % n
		var orden: Array = ag.get("orden", [])        # orden de cuadros propio (p. ej. ida y vuelta)
		if not orden.is_empty():
			f = clampi(int(orden[int(t * float(ag.get("fps", 8))) % orden.size()]), 0, n - 1)
		var p: Array = ag.get("pos", [0, 0])
		d.draw_texture_rect_region(tira, Rect2(Vector2(p[0], p[1]) - cpos, Vector2(fw, tira.get_height())),
				Rect2(f * fw, 0, fw, tira.get_height()))
	_draw_layers(d, t, cpos, false)
	# Actores, de atrás hacia adelante
	var list: Array = []
	for a in scene.get("actores", []):
		var sp := str(a.get("especie", ""))
		var flies := bool(a.get("vuela", false))
		for st in a.get("pasos", []):
			if tl >= float(st[0]) and tl < float(st[1]):
				var from := Vector2(st[4][0], st[4][1])
				var to := Vector2(st[5][0], st[5][1]) if st.size() > 5 else from
				var k := (tl - float(st[0])) / maxf(0.001, float(st[1]) - float(st[0]))
				var pos := from.lerp(to, k)
				if flies:     # los que vuelan se mecen un poco arriba y abajo
					pos.y += sin(tl * 5.0 + float(a.get("fase", 0))) * 3.0
				list.append([pos, sp, str(st[2]), int(DIRS.get(str(st[3]), 0)), tl - float(st[0]), flies])
				break
	list.sort_custom(func(x, y): return x[0].y < y[0].y)
	_draw_effects(d, tl, cpos, true)
	for it in list:
		var an := _anim(it[1], it[2])
		if an.is_empty():
			an = _anim(it[1], "Idle")
		if an.is_empty():
			continue
		var row := mini(int(it[3]), int(an["rows"]) - 1)
		var sh := _shadows(an, row)
		var fr := _frame(an, it[4] * 60.0)
		var o: Vector2 = (it[0] - cpos - sh[0]).round()
		var sp_pos: Vector2 = o + sh[fr]
		if not it[5]:
			_shadow(d, sp_pos)
		d.draw_texture_rect_region(an["tex"], Rect2(o, Vector2(an["w"], an["h"])),
				Rect2(fr * int(an["w"]), row * int(an["h"]), an["w"], an["h"]))


	_draw_effects(d, tl, cpos, false)
	_draw_layers(d, t, cpos, true)
	if flash >= 0.0 and flash < 0.12:
		d.draw_rect(Rect2(0, 0, 240, 160), Color(1, 1, 0.9, 0.22 * (1.0 - flash / 0.12)))


## Capas que se repiten en horizontal y se deslizan (niebla...): {"tira", "y", "vel" (px/s),
## "paralaje" (cuánto sigue a la cámara, 1 = como el fondo), "delante" (sobre los Pokémon)}.
func _draw_layers(d: CanvasItem, t: float, cpos: Vector2, front: bool) -> void:
	for ly in scene.get("capas", []):
		if bool(ly.get("delante", false)) != front:
			continue
		var tex := _image(str(ly.get("tira", "")))
		if tex == null:
			continue
		var w := float(tex.get_width())
		var x := fmod(float(ly.get("vel", 0)) * t - cpos.x * float(ly.get("paralaje", 1.0)), w)
		if x > 0:
			x -= w
		var y := float(ly.get("y", 0)) - cpos.y
		while x < 240:
			d.draw_texture(tex, Vector2(round(x), round(y)))
			x += w


## Efectos de la escena: [momento, efecto, [x, y]] con un efecto de efectos/propios (mv_0119...)
## o {"t", "tira", "cuadros", "pos", "fps", "atras"} con una tira propia. atras = detrás de los Pokémon.
func _draw_effects(d: CanvasItem, tl: float, cpos: Vector2, behind: bool) -> void:
	for e in scene.get("efectos", []):
		var t0: float
		var pos: Vector2
		var fps := 20.0
		var back := false
		if e is Array:
			t0 = float(e[0])
			pos = Vector2(e[2][0], e[2][1])
			if e.size() > 3:
				fps = float(e[3])
		else:
			t0 = float(e.get("t", 0))
			pos = Vector2(e["pos"][0], e["pos"][1])
			fps = float(e.get("fps", 20))
			back = bool(e.get("atras", false))
		if back != behind:
			continue
		var fr := int((tl - t0) * fps)
		if fr < 0:
			continue
		if e is Array:
			var name := str(e[1])
			if SpecialFX.has_fx(name) and fr < SpecialFX.fx_count(name):
				SpecialFX.fx_draw(d, name, fr, pos - cpos)
		else:
			var tira := _image(str(e.get("tira", "")))
			var n := maxi(1, int(e.get("cuadros", 1)))
			if tira != null and fr < n:
				var fw := tira.get_width() / n
				d.draw_texture_rect_region(tira, Rect2((pos - cpos).round(), Vector2(fw, tira.get_height())),
						Rect2(fr * fw, 0, fw, tira.get_height()))


func _shadow(d: CanvasItem, c: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(c + Vector2(cos(a) * 6.0, sin(a) * 2.0))
	d.draw_colored_polygon(pts, Color(0.08, 0.25, 0.08, 0.4))
