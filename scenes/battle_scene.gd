## Escena de batalla al estilo Rubí/Zafiro: al atacar, la mesa da paso a una pantalla con
## los fondos y los sprites de batalla de GBA. Tu Pokémon de espalda abajo a la izquierda,
## el rival de frente arriba a la derecha, cajas de PS, el mensaje del ataque, el efecto
## del tipo (el mismo de la mesa), el golpe, la barra que baja y, si queda KO, se hunde.
##
## Recursos (carpeta propia, fuera de git):
##   mundo/propios/batalla/fondos/<fondo>.png             240x112 (grass, sea, cave...)
##   mundo/propios/batalla/pokemon/<especie>_frente.png    64x64
##   mundo/propios/batalla/pokemon/<especie>_espalda.png   64x64
## Si falta el sprite, se ve el arte de la carta enmarcado; si falta el fondo, uno liso.
## Se activa en Options ("Battles"); no se usa en dobles. Z la saltea.
class_name BattleScene
extends RefCounted

const SpecialFX := preload("res://scenes/special_fx.gd")

const DUR := 3.1          # segundos que dura la escena
const IMPACT := 1.55      # segundos hasta el golpe
const FX_LEAD := 0.55     # el efecto del tipo arranca este tiempo antes del golpe (dura 1 s)
const DIR := "res://mundo/propios/batalla"
const SPR := 64

const FONDO_POR_TIPO := {
	"Grass": "grass", "Water": "sea", "Fire": "land2", "Lightning": "grass2",
	"Psychic": "arena5", "Fighting": "cave", "Darkness": "arena2", "Metal": "arena3",
	"Colorless": "grass3", "Dragon": "arena4",
}
const FORMAS := {"Rain Castform": "castform_rain", "Snow-cloud Castform": "castform_snow",
		"Sunny Castform": "castform_sun"}

# Dónde va cada uno (en la pantalla de 240x160; el fondo ocupa las primeras 112 filas)
const FRONT_POS := Vector2(144, 8)     # sprite del rival, de frente
const BACK_POS := Vector2(40, 48)      # sprite tuyo, de espalda
const ENEMY_BOX := Vector2(10, 14)
const PLAYER_BOX := Vector2(126, 72)

static var _tex := {}      # ruta -> Texture2D (o null si no existe)


## Prepara la animación de ataque para verse como escena de batalla.
static func setup(a: Dictionary, att: PlayerState, def: PlayerState, atk: Dictionary) -> void:
	var t: Array = def.active.types()
	a["scene"] = true
	a["dur"] = DUR
	a["impact"] = IMPACT / DUR
	a["att_id"] = att.active.top()
	a["def_id"] = def.active.top()
	a["att_name"] = att.active.display_name().to_upper()
	a["def_name"] = def.active.display_name().to_upper()
	a["att_hp"] = att.active.hp_left()
	a["att_max"] = att.active.max_hp()
	a["def_max"] = def.active.max_hp()
	a["atk_name"] = str(atk.get("name", ""))
	a["fondo"] = FONDO_POR_TIPO.get(t[0] if not t.is_empty() else "Colorless", "grass")
	var at: Array = att.active.types()
	a["atk_type"] = at[0] if not at.is_empty() else "Colorless"
	a["printed"] = int(str(atk.get("damage_text", "0")).to_int())   # "50+" -> 50, "10×" -> 10


## Z: salta casi al final (el golpe se aplica igual en el próximo cuadro).
static func skip(a: Dictionary) -> void:
	a["stop"] = 0.0
	a["t"] = maxf(float(a["t"]), (DUR - 0.12) / DUR)


## Nombres de archivo a probar para el sprite de una carta, del más específico al general.
static func species(card_name: String) -> Array:
	var n := card_name
	var dark := false
	for pre in ["Team Aqua's ", "Team Magma's "]:
		if n.begins_with(pre):
			n = n.substr(pre.length())
	if n.begins_with("Dark "):
		n = n.substr(5)
		dark = true
	if n.ends_with(" ex"):
		n = n.left(n.length() - 3)
	if FORMAS.has(n):
		return [FORMAS[n]]
	n = n.to_lower().replace("♀", "_f").replace("♂", "_m")
	for ch in [".", "'", "’", ":"]:
		n = n.replace(ch, "")
	n = n.replace(" ", "_").replace("-", "_")
	return [n + "#shiny", n] if dark else [n]


static func sprite(card_id: String, front: bool) -> Texture2D:
	var side := "frente" if front else "espalda"
	for sp in species(CardDB.card_name(card_id)):
		var names: Array = []
		if sp.ends_with("#shiny"):
			var base: String = sp.trim_suffix("#shiny")
			names = ["%s_%s_shiny" % [base, side], "%s_shiny_%s" % [base, side]]
		else:
			names = ["%s_%s" % [sp, side]]
		for nm in names:
			var tex := _load("%s/pokemon/%s.png" % [DIR, nm])
			if tex != null:
				return tex
	return null


static func _load(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var tex: Texture2D = null
	if ImgLoad.exists(path):
		var img := ImgLoad.load(path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_tex[path] = tex
	return tex


static func _ease(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return 1.0 - (1.0 - k) * (1.0 - k)


static func draw(d, a: Dictionary) -> void:
	var s := float(a["t"]) * DUR                       # segundos desde que empezó
	var me_att: bool = a["att"] == d.human
	var front_id: String = a["def_id"] if me_att else a["att_id"]
	var back_id: String = a["att_id"] if me_att else a["def_id"]
	# Entrada: las plataformas llegan desde los costados (el rival por la izquierda)
	var k := _ease((s - 0.12) / 0.45)
	var off_e := roundf(-176.0 * (1.0 - k))
	var off_p := roundf(176.0 * (1.0 - k))
	_draw_backdrop(d, a, off_e, off_p)
	# Embestida del atacante y golpe al defensor
	var lunge := 0.0
	var l0 := IMPACT - 0.5
	if s > l0 and s < l0 + 0.28:
		lunge = sin((s - l0) / 0.28 * PI) * 9.0
	var hit: bool = s >= IMPACT and s < IMPACT + (0.6 if _big(a) else 0.45) and int(a.get("dmg", 0)) > 0
	var amp := 4.0 if _big(a) else 2.0
	var shake := (amp if int(s * 30.0) % 2 == 0 else -amp) if hit else 0.0
	var blink := hit and int(s * 16.0) % 2 == 0
	var sink := 0.0
	if a.get("ko", false) and s > IMPACT + 0.95:
		sink = minf(float(SPR), (s - IMPACT - 0.95) * 170.0)
	var fpos := FRONT_POS + Vector2(off_e, 0)
	var bpos := BACK_POS + Vector2(off_p, 0)
	if me_att:
		bpos += Vector2(lunge, -lunge * 0.5)
		fpos.x += shake
	else:
		fpos += Vector2(-lunge, lunge * 0.5)
		bpos.x += shake
	var front_hit := me_att
	if not (blink and front_hit):
		_draw_mon(d, front_id, true, fpos, sink if front_hit else 0.0)
	if not (blink and not front_hit):
		_draw_mon(d, back_id, false, bpos, sink if not front_hit else 0.0)
	# El efecto del ataque, con las tiras de efectos/propios: uno para golpes de menos de 50
	# y otro más fuerte para 50 o más
	var fc := FRONT_POS + Vector2(32, 34)
	var bc := BACK_POS + Vector2(32, 30)
	_draw_attack_fx(d, a, s, bc if me_att else fc, fc if me_att else bc)
	var landed: bool = a.get("applied", false) and int(a.get("dmg", 0)) > 0
	if landed and s >= IMPACT and s < IMPACT + (0.12 if _big(a) else 0.07):
		d.draw_rect(Rect2(0, 0, d.W, 112), Color(1, 1, 1, 0.7 if _big(a) else 0.5))
	# Cajas de PS
	var kb := _ease((s - 0.45) / 0.22)
	var def_hp := float(a.get("hp_before", 0))
	if s >= IMPACT and a.get("applied", false):
		var drain := clampf((s - IMPACT - 0.12) / 0.6, 0.0, 1.0)
		def_hp -= float(a.get("dmg", 0)) * drain
	var f_hp: float = def_hp if me_att else float(a["att_hp"])
	var b_hp: float = float(a["att_hp"]) if me_att else def_hp
	var f_max: int = a["def_max"] if me_att else a["att_max"]
	var b_max: int = a["att_max"] if me_att else a["def_max"]
	_hp_box(d, ENEMY_BOX + Vector2(roundf(-120.0 * (1.0 - kb)), 0), a["def_name"] if me_att else a["att_name"], f_hp, f_max)
	_hp_box(d, PLAYER_BOX + Vector2(roundf(120.0 * (1.0 - kb)), 0), a["att_name"] if me_att else a["def_name"], b_hp, b_max)
	# Mensaje
	var msg := ""
	var t0 := 0.5
	if s >= IMPACT + 0.9:
		t0 = IMPACT + 0.9
		var dmg := int(a.get("dmg", 0))
		if a.get("ko", false):
			msg = ("Foe " if me_att else "") + str(a["def_name"]) + " fainted!"
		elif dmg == 0:
			msg = "But it missed!"
		elif a.get("weak", false):
			msg = "It's super effective!"
		else:
			msg = "%s took %d damage." % [a["def_name"], dmg]
	elif s >= 0.5:
		msg = "%s used %s!" % [a["att_name"], a["atk_name"]]
	_textbox(d, msg.left(maxi(0, int((s - t0) * 45.0))))
	# Franjas al entrar y fundido al salir
	if s < 0.22:
		var p := s / 0.22
		for yy in range(0, d.H, 8):
			var ww := roundf(d.W * (1.0 - p))
			if (yy / 8) % 2 == 1:
				d.draw_rect(Rect2(0, yy, ww, 8), Color("#101018"))
			else:
				d.draw_rect(Rect2(d.W - ww, yy, ww, 8), Color("#101018"))
	if s > DUR - 0.18:
		d.draw_rect(Rect2(0, 0, d.W, d.H), Color(0.06, 0.06, 0.09, clampf((s - (DUR - 0.18)) / 0.18, 0.0, 1.0)))


static func _draw_backdrop(d, a: Dictionary, off_e: float, off_p: float) -> void:
	d.draw_rect(Rect2(0, 0, d.W, d.H), Color("#101018"))
	var bg := _load("%s/fondos/%s.png" % [DIR, a.get("fondo", "grass")])
	if bg == null:
		bg = _load("%s/fondos/grass.png" % DIR)
	if bg == null:
		# Sin fondos: cielo liso y dos plataformas ovaladas
		d.draw_rect(Rect2(0, 0, d.W, 112), Color("#e8f0d8"))
		_ellipse(d, Vector2(176 + off_e, 64), Vector2(42, 9), Color("#a8d088"))
		_ellipse(d, Vector2(72 + off_p, 110), Vector2(56, 10), Color("#a8d088"))
		return
	d.draw_texture(bg, Vector2.ZERO)
	if off_e == 0.0 and off_p == 0.0:
		return
	# Mientras entran, las franjas de cada plataforma se corren (el resto del fondo, quieto)
	d.draw_texture_rect_region(bg, Rect2(0, 40, 240, 40), Rect2(0, 30, 240, 10))
	d.draw_texture_rect_region(bg, Rect2(off_e, 40, 240, 40), Rect2(0, 40, 240, 40))
	d.draw_texture_rect_region(bg, Rect2(0, 92, 240, 20), Rect2(0, 82, 240, 10))
	d.draw_texture_rect_region(bg, Rect2(off_p, 92, 240, 20), Rect2(0, 92, 240, 20))


static func _ellipse(d, c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var ang := TAU * i / 24.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	d.draw_colored_polygon(pts, col)


## El sprite de batalla (o, si no hay, el arte de la carta enmarcado). sink: cuánto se
## hundió al quedar KO (se recorta desde abajo, como en los juegos).
static func _draw_mon(d, id: String, front: bool, pos: Vector2, sink: float) -> void:
	if sink >= SPR:
		return
	var tex := sprite(id, front)
	if tex != null:
		var h := float(SPR) - sink
		d.draw_texture_rect_region(tex, Rect2(pos + Vector2(0, sink), Vector2(SPR, h)), Rect2(0, 0, SPR, h))
		return
	var r := Rect2(pos + Vector2(10, 10 if front else 14), Vector2(44, 44))
	var h2 := r.size.y - sink * 44.0 / SPR
	if h2 <= 0:
		return
	var art: Texture2D = d._art_texture(id, 40, 40)
	d.draw_rect(Rect2(r.position + Vector2(0, r.size.y - h2), Vector2(r.size.x, h2)), Color("#384050"))
	if art != null:
		d.draw_texture_rect_region(art, Rect2(r.position + Vector2(2, 2 + (r.size.y - h2)), Vector2(40, maxf(0, h2 - 4))),
				Rect2(0, 0, 40, maxf(0, h2 - 4)))


## Caja de PS al estilo R/S (crema con borde oscuro y la punta en diagonal).
static func _hp_box(d, p: Vector2, name: String, hp: float, max_hp: int) -> void:
	var w := 104.0
	var h := 34.0
	var pts := PackedVector2Array([p + Vector2(2, 0), p + Vector2(w - 7, 0), p + Vector2(w, 7),
			p + Vector2(w, h - 1), p + Vector2(2, h - 1), p + Vector2(0, h - 3), p + Vector2(0, 2)])
	d.draw_colored_polygon(pts, Color("#384840"))
	var inner := PackedVector2Array([p + Vector2(2, 1), p + Vector2(w - 7.5, 1), p + Vector2(w - 1, 7.5),
			p + Vector2(w - 1, h - 2), p + Vector2(2, h - 2), p + Vector2(1, h - 3), p + Vector2(1, 2)])
	d.draw_colored_polygon(inner, Color("#f8f8d8"))
	d.draw_line(p + Vector2(3, h - 3), p + Vector2(w - 2, h - 3), Color("#d0d0a8"))
	d._text(p + Vector2(7, 2), name, Color("#404040"))
	var bx := p + Vector2(w - 62, 15)
	d.draw_rect(Rect2(bx + Vector2(-15, -1), Vector2(68, 6)), Color("#506860"))
	d._text(bx + Vector2(-14, -4), "HP", Color("#f8c040"))
	var frac := clampf(hp / maxf(1.0, float(max_hp)), 0.0, 1.0)
	var col := Color("#70f8a8") if frac > 0.5 else (Color("#f8e038") if frac > 0.2 else Color("#f85838"))
	d.draw_rect(Rect2(bx, Vector2(52, 4)), Color("#404040"))
	if frac > 0.0:
		d.draw_rect(Rect2(bx, Vector2(maxf(1.0, roundf(52.0 * frac)), 4)), col)
	var num := "%d/%d" % [maxi(0, int(ceil(hp))), max_hp]
	d._text(p + Vector2(w - 8 - d._text_w(num), 21), num, Color("#404040"))


static func _textbox(d, msg: String) -> void:
	d.draw_rect(Rect2(0, 112, d.W, 48), Color("#283040"))
	d.draw_rect(Rect2(2, 114, d.W - 4, 44), Color("#506080"))
	d.draw_rect(Rect2(5, 117, d.W - 10, 38), Color("#303850"))
	d._text(Vector2(12, 124), msg, Color("#f8f8f8"))


## ¿Golpe fuerte? Por el daño que hizo (o, antes del golpe, el que dice la carta).
static func _big(a: Dictionary) -> bool:
	if a.get("applied", false):
		return int(a.get("dmg", 0)) >= 50
	return int(a.get("printed", 0)) >= 50


const TINT := {"Psychic": Color("#e0a0ff"), "Darkness": Color("#b080e0"), "Metal": Color("#d0d8e8")}


## El ataque en dos partes: lo que sale del atacante antes del golpe y lo que le pasa al
## defensor cuando pega. A: centro del atacante, D: centro del defensor.
static func _draw_attack_fx(d, a: Dictionary, s: float, A: Vector2, D: Vector2) -> void:
	var typ: String = a.get("atk_type", "Colorless")
	var big := _big(a)
	var t0 := IMPACT - 0.45
	# 1) Antes del golpe: algo viaja del atacante al defensor
	if s >= t0 and s < IMPACT:
		var k := (s - t0) / 0.45
		var p := A.lerp(D, k)
		match typ:
			"Fire":
				SpecialFX.fx_draw(d, "fuego_golpe", int(k * 2.0), p, 1.2 if big else 0.9)
				if big:
					SpecialFX.fx_draw(d, "ascuas", int(s * 20.0), p + Vector2(-8, 4), 1.0)
			"Water":
				for i in (5 if big else 3):
					var q := A.lerp(D, clampf(k - i * 0.1, 0.0, 1.0)) + Vector2(0, sin(s * 18.0 + i) * 4.0)
					SpecialFX.fx_draw(d, "burbuja_acida", 4 + i % 3, q, 0.6)
			"Grass":
				for i in (6 if big else 3):
					var q := A.lerp(D, clampf(k - i * 0.08, 0.0, 1.0)) + Vector2(0, sin(s * 14.0 + i * 2.0) * 6.0)
					SpecialFX.fx_draw(d, "hoja", int(s * 14.0) + i, q, 1.0, 1.0, s * 6.0 + i)
			"Fighting":
				SpecialFX.fx_draw(d, "roca", 0, p + Vector2(0, -sin(k * PI) * 18.0), 0.8 if big else 0.6, 1.0, s * 8.0)
			"Lightning":
				if big:
					SpecialFX.fx_draw(d, "rayo", int(s * 18.0), A + Vector2(sin(s * 40.0) * 6.0, -14), 0.9, 1.0, PI / 2.0)
			"Psychic", "Darkness":
				if big:
					SpecialFX.fx_draw(d, "anillo", SpecialFX.fx_frame("anillo", k), A, 1.3, 1.0, 0.0, false, TINT[typ])
			_:
				if big:
					SpecialFX.fx_draw(d, "estrellas", int(s * 16.0), A + Vector2(8, -10), 0.8)
	# 2) El golpe (solo si pegó)
	if not a.get("applied", false) or s < IMPACT:
		return
	var h := (s - IMPACT) / (0.6 if big else 0.45)
	if h >= 1.0:
		return
	if int(a.get("dmg", 0)) <= 0:      # no hizo daño: un soplido y nada más
		SpecialFX.fx_draw(d, "estrellas", 4, D + Vector2(0, -6), 0.8, 1.0 - h)
		return
	match typ:
		"Fire":
			if big:
				SpecialFX.fx_draw(d, "llama", int(s * 20.0), D + Vector2(0, 6), 2.0, 1.0 - h * 0.5)
				SpecialFX.fx_draw(d, "anillo_fuego", SpecialFX.fx_frame("anillo_fuego", h), D, 1.3)
			else:
				SpecialFX.fx_draw(d, "fuego_golpe", 2 + SpecialFX.fx_frame("fuego_golpe", h * 0.75), D, 1.3)
		"Water":
			if big:
				var x := lerpf(D.x + 50.0, D.x - 30.0, h)
				SpecialFX.fx_draw(d, "ola", 0, Vector2(x, D.y - 4), 0.75, 1.0 - maxf(0.0, h - 0.7) * 3.0)
			for i in (4 if big else 2):
				SpecialFX.fx_draw(d, "burbuja_acida", SpecialFX.fx_frame("burbuja_acida", h), D + Vector2((i - 1) * 12, (i % 2) * 8 - 4), 0.9)
		"Grass":
			var n := 14 if big else 4
			for i in n:
				var ring := 1.0 + float(i % 2) * 0.6 if big else 1.0
				var ang := TAU * i / n + s * (7.0 if big else 3.0) * (1.0 if i % 2 == 0 else -1.0)
				var rr := ((8.0 + h * 26.0) * ring) if big else (6.0 + h * 14.0)
				SpecialFX.fx_draw(d, "hoja", i + int(s * 12.0), D + Vector2(cos(ang), sin(ang)) * rr, 1.4 if big else 1.0, 1.0 - h * 0.8, ang)
		"Lightning":
			for i in (3 if big else 1):
				SpecialFX.fx_draw(d, "rayo", SpecialFX.fx_frame("rayo", h), D + Vector2((i - 1) * 14, -6 + i * 3), 1.6 if big else 1.3, 1.0, PI / 2.0)
			if big:
				SpecialFX.fx_draw(d, "explosion", SpecialFX.fx_frame("explosion", h), D, 1.6)
		"Psychic":
			SpecialFX.fx_draw(d, "anillo", SpecialFX.fx_frame("anillo", h), D, 2.0 if big else 1.3, 1.0, 0.0, false, TINT["Psychic"])
			if big:
				for i in 4:
					SpecialFX.fx_draw(d, "estrellas", int(s * 18.0) + i, D + Vector2(cos(i * 1.6), sin(i * 1.6)) * (12.0 + h * 18.0), 0.8, 1.0 - h)
		"Fighting":
			if big:
				for i in 5:
					var fall := clampf(h * 1.6 - i * 0.12, 0.0, 1.0)
					SpecialFX.fx_draw(d, "roca", i % 4, D + Vector2((i - 2) * 11, -40.0 + fall * 44.0), 0.8, 1.0, i)
				SpecialFX.fx_draw(d, "explosion", SpecialFX.fx_frame("explosion", h), D + Vector2(0, 6), 1.5)
			else:
				SpecialFX.fx_draw(d, "estrellas", 1 + int(h * 3.0), D, 1.0, 1.0 - h)
		"Darkness":
			SpecialFX.fx_draw(d, "colmillos", 0 if h < 0.5 else 1, D, 2.2 if big else 1.4, 1.0 - maxf(0.0, h - 0.6) * 2.5, 0.0, false, TINT["Darkness"])
			if big:
				SpecialFX.fx_draw(d, "zarpazo", SpecialFX.fx_frame("zarpazo", h), D, 1.6)
		_:   # Colorless, Metal
			if big:
				SpecialFX.fx_draw(d, "explosion", SpecialFX.fx_frame("explosion", h), D, 1.8)
				for i in 3:
					SpecialFX.fx_draw(d, "estrellas", int(s * 18.0) + i, D + Vector2((i - 1) * 16, -8 + (i % 2) * 14), 0.9, 1.0 - h)
			else:
				SpecialFX.fx_draw(d, "zarpazo", SpecialFX.fx_frame("zarpazo", h), D, 1.4, 1.0, 0.0, false, TINT.get(typ, Color.WHITE))
