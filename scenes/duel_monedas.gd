extends RefCounted
## Animación de monedas (cara o cruz)
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
	d = duel


# ===========================================================================
# Animación de monedas
# ===========================================================================
# El motor anota cada moneda en game.coin_log. Después de cada acción se muestran
# las monedas nuevas una por una: la moneda sube girando, cae y muestra el resultado.

## Devuelve true si hay monedas nuevas para mostrar.
func _check_coins() -> bool:
	if not d.animations_on or d.game.coin_log.size() <= d.coins_seen:
		d.coins_seen = d.game.coin_log.size()
		return false
	var results = d.game.coin_log.slice(d.coins_seen)
	var reasons = d.game.coin_reasons.slice(d.coins_seen)
	d.coins_seen = d.game.coin_log.size()
	d.coin_anim = {"results": results, "reasons": reasons, "i": 0, "t": 0.0,
			"per": d.COIN_TIME if results.size() <= 3 else d.COIN_TIME * 0.6}
	return true


func _update_coins(delta: float) -> void:
	d.coin_anim["t"] += delta / d.coin_anim["per"]
	if d.coin_anim["t"] >= 1.0:
		d.coin_anim["t"] = 0.0
		d.coin_anim["i"] += 1
		if d.coin_anim["i"] >= d.coin_anim["results"].size():
			var then = d.coin_anim.get("then")
			d.coin_anim = {}
			if then is Callable:
				then.call()
			elif d.anim.is_empty():
				d.ai_timer = d.AI_DELAY
				d._rebuild_menu()


## Carga las monedas (cara y cruz) de mundo/propios/monedas/moneda_NN.png y _cruz.png.
func _load_coins() -> void:
	if d._coins_loaded:
		return
	d._coins_loaded = true
	for dir_path in ["res://mundo/propios/monedas", "user://mundo/propios/monedas"]:
		for n in range(1, 100):
			var p := "%s/moneda_%02d.png" % [dir_path, n]
			if not ImgLoad.exists(p):
				break
			var heads := _load_png(p)
			var tails := _load_png(p.replace(".png", "_cruz.png"))
			if heads != null:
				d._coin_sets.append([heads, tails if tails != null else heads])
		if not d._coin_sets.is_empty():
			return


func _load_png(path: String) -> Texture2D:
	if not ImgLoad.exists(path):
		return null
	var img := ImgLoad.load(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _draw_coins() -> void:
	if d.coin_anim.is_empty():
		return
	var results: Array = d.coin_anim["results"]
	var i: int = d.coin_anim["i"]
	var t: float = d.coin_anim["t"]
	var heads: bool = results[i]
	var reason: String = d.coin_anim["reasons"][i]
	var img_coin = d.coin_pick >= 0 and d.coin_pick < d._coin_sets.size()
	var center = Vector2(d.W / 2.0, 52 if img_coin else 56)
	# Fondo oscurecido y recuadro
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0, 0, 0, 0.35))
	var spin := 0.62   # fracción del tiempo que la moneda está en el aire
	var r = 22.0 if img_coin else 13.0     # las monedas con imagen se ven más grandes (44 px)
	var jump = 8.0 if img_coin else 16.0
	var label := ""
	var face_heads := heads
	var width := 1.0
	var pos = center
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
	var shadow_w = r * (1.0 - (center.y - pos.y) / 40.0)
	d.draw_set_transform(d._base_off + center + Vector2(0, r + 4), 0, Vector2(1, 0.3))
	d.draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.4))
	d.draw_set_transform(d._base_off)
	_draw_coin_face(pos, r, maxf(width, 0.08), face_heads, reason)
	# Textos
	var title = "Coin flip" if results.size() == 1 else "Coin flip %d/%d" % [i + 1, results.size()]
	match reason:
		"burn": title = "Burn"
		"sleep": title = "Asleep: does it wake up?"
		"start": title = "Opening coin flip"
	d._text_center(14, title, d.C_LIGHT)
	var label_y = center.y + r + (3 if img_coin else 5)
	var outcome_y = label_y + 21
	if label != "":
		d._text_center(label_y, label, d.C_ACCENT if heads else d.C_LIGHT, true)
		var outcome := ""
		match reason:
			"burn": outcome = "No damage" if heads else "%d damage!" % d.game.rules.burn_damage
			"sleep": outcome = "It woke up!" if heads else "Still asleep"
			"start": outcome = "You won the coin flip!" if d.coin_anim.get("won", false) else "The opponent won the coin flip."
		if outcome != "":
			d._text_center(outcome_y, outcome, d.C_LIGHT)
	var plain: bool = d.coin_anim["reasons"].all(func(x): return x == "")
	if results.size() > 1 and plain:
		var shown = results.slice(0, i + (1 if label != "" else 0))
		var n_heads = shown.filter(func(h): return h).size()
		var x0 = d.W / 2.0 - results.size() * 5.0
		for j in results.size():
			var c = d.C_LINE
			if j < shown.size():
				c = d.C_ACCENT if results[j] else d.C_PANEL_DARK
			d.draw_circle(Vector2(x0 + j * 10 + 5, 26 if img_coin else 32), 3.0, c)
		if label != "":
			d._text_center(outcome_y, "%d heads" % n_heads, d.C_LIGHT)


## Monedas originales. Normal: cara = estrella (dorado), cruz = anillo (plateado).
## Quemadura: moneda roja con una llamita del lado de la cruz (la cruz quema).
## Dormido: moneda azul con "zzz" del lado de la cruz (con cruz sigue dormido).
func _draw_coin_face(pos: Vector2, r: float, width: float, heads: bool, reason: String = "") -> void:
	if d.coin_pick >= 0 and d.coin_pick < d._coin_sets.size():
		# La moneda de esta partida: la imagen de la cara o de la cruz, achicada a lo ancho al girar
		var tex: Texture2D = d._coin_sets[d.coin_pick][0 if heads else 1]
		d.draw_set_transform(d._base_off + pos, 0, Vector2(width, 1))
		d.draw_texture_rect(tex, Rect2(-r, -r, r * 2, r * 2), false)
		d.draw_set_transform(d._base_off)
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
	d.draw_set_transform(d._base_off + pos, 0, Vector2(width, 1))
	d.draw_circle(Vector2.ZERO, r, dark)
	d.draw_circle(Vector2.ZERO, r - 1.5, base)
	if width > 0.35:
		match reason:
			"burn":
				if heads:
					d.draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
				else:
					_draw_small_flame(Vector2(0, 1), r * 0.62)
			"sleep":
				if heads:
					d.draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
				else:
					var c := Color("#f0f0ff")
					d.draw_string(d.font, Vector2(-7, 4), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, d.FONT_SIZE, c)
					d.draw_string(d.font, Vector2(-2, 1), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, d.FONT_SIZE, c)
					d.draw_string(d.font, Vector2(2, -2), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, d.FONT_SIZE, c)
			_:
				if heads:
					d.anim_ataques._draw_burst(Vector2.ZERO, r * 0.6, Color("#fff0a0"), 5)
				else:
					d.draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 20, dark, 2.0)
	d.draw_set_transform(d._base_off)


## Llamita simple (centrada en c, alto aproximado 2*s).
func _draw_small_flame(c: Vector2, s: float) -> void:
	var outer = PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.55, -s * 0.15), c + Vector2(s * 0.6, s * 0.4),
			c + Vector2(s * 0.3, s * 0.8), c + Vector2(-s * 0.3, s * 0.8), c + Vector2(-s * 0.6, s * 0.4),
			c + Vector2(-s * 0.45, -s * 0.1), c + Vector2(-s * 0.15, s * 0.15)])
	d.draw_colored_polygon(outer, Color("#ffd040"))
	var inner = PackedVector2Array([c + Vector2(0, -s * 0.3), c + Vector2(s * 0.3, s * 0.35), c + Vector2(0, s * 0.7),
			c + Vector2(-s * 0.3, s * 0.35)])
	d.draw_colored_polygon(inner, Color("#fff8d0"))
