## Mini pelea al estilo Mystery Dungeon: al atacar, la mesa se oscurece y aparecen los dos
## Pokémon con sus sprites de SpriteCollab. El atacante hace su animación (un golpe físico o
## un disparo, según el tipo del ataque), el defensor la de daño (si queda KO, se hunde), con el
## efecto del tipo encima y el número. Tu Pokémon abajo a la izquierda mirando arriba a la
## derecha (fila 4 de las hojas) y el rival arriba a la derecha mirando abajo a la izquierda
## (fila 8).
##
## Recursos (carpeta propia, fuera de git), una carpeta por especie tal como viene de
## SpriteCollab (python tools/importar_pmd.py la arma desde las carpetas numeradas):
##   mundo/propios/pmd/<especie>/AnimData.xml
##   mundo/propios/pmd/<especie>/<Anim>-Anim.png, -Shadow.png, -Offsets.png
##     Anim: Idle, Hurt, Hop y las de ataque que nombra data/ataques_pmd.json
## Si a alguno de los dos le falta Idle, ese ataque se ve en la mesa como siempre.
## Se activa en Options ("Battles: Mini"). Z la saltea.
class_name MiniBattle
extends RefCounted

const SpecialFX := preload("res://scenes/special_fx.gd")
const DIR := "res://mundo/propios/pmd"

const ROW_ME := 3        # arriba-derecha
const ROW_OPP := 7       # abajo-izquierda
const GROUND_ME := Vector2(104, 82)     # dónde pisa cada uno (punto de la sombra)
const GROUND_OPP := Vector2(140, 54)

const T_IN := 0.25       # se oscurece la mesa
const T_PRE := 0.35      # los dos quietos antes del ataque
const T_TRAVEL := 0.2    # lo que tarda el disparo en llegar
const T_STREAM := 0.3    # cuánto dura el chorro de un disparo
const T_HURT := 0.85     # después del golpe
const T_FAINT := 0.75    # extra si queda KO
const T_OUT := 0.25      # vuelve la mesa
const FX_FRAME := 0.05   # cada cuadro de los efectos de Mystery Dungeon (se ven enteros, la escena se alarga)
const TICK := 1.0 / 60.0

# Qué animación usa cada ataque: data/ataques_pmd.json (por nombre, por palabras, por defecto)
const RULES_PATH := "res://data/ataques_pmd.json"
const STATUS_COL := {"Asleep": Color("#a0b8ff"), "Confused": Color("#f0a0e0"), "Paralyzed": Color("#f8e060"),
		"Poisoned": Color("#c080f0"), "Burned": Color("#f87850")}
static var _rules := {}
static var _fams := {}
const FAMS_PATH := "res://data/familias_pmd.json"

static var _species := {}    # especie -> Dictionary de animaciones (vacío si no hay carpeta)


# ---------------------------------------------------------------------------
# Carga de las hojas
# ---------------------------------------------------------------------------

## La carpeta de una carta (o "" si no hay): prueba los nombres de BattleScene.species().
## Los Pokémon Dark buscan primero la versión shiny (carpeta <especie>_shiny).
## Dónde está un archivo de la especie: en el proyecto (res://) o, en la versión web, en
## user://pmd, donde PmdWeb los baja a medida que hacen falta.
const USER_DIR := "user://pmd"

static func path(sp: String, file: String) -> String:
	var r := "%s/%s/%s" % [DIR, sp, file]
	if ImgLoad.exists(r) or ResourceLoader.exists(r):
		return r
	return "%s/%s/%s" % [USER_DIR, sp, file]


static func has_file(sp: String, file: String) -> bool:
	var p := path(sp, file)
	return ImgLoad.exists(p) or ResourceLoader.exists(p)


## La especie ya bajada en la web: se olvida lo que se había armado sin ella.
static func forget(sp: String) -> void:
	_species.erase(sp)


static func folder(card_id: String) -> String:
	for sp in BattleScene.species(CardDB.card_name(card_id)):
		var n: String = sp.trim_suffix("#shiny") + ("_shiny" if sp.ends_with("#shiny") else "")
		if has_file(n, "AnimData.xml"):
			return n
	return ""


static func _load_rules() -> Dictionary:
	if _rules.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
		_rules = j if j is Dictionary else {"por_defecto": {}}
	return _rules


## ¿La especie tiene esta animación? (sin cargar las hojas)
static func has_anim(sp: String, name: String) -> bool:
	var info: Dictionary = _data(sp)["_xml"]["anims"].get(name, {})
	if info.is_empty():
		return false
	var src: String = info.get("copy", name)
	return has_file(sp, src + "-Anim.png")


## ¿La animación lleva al Pokémon hacia el rival? (su sombra se corre más de 12 px)
static func moves(sp: String, name: String) -> bool:
	var an := _anim(sp, name)
	if an.is_empty() or not an.has(ROW_ME):
		return false
	var sh: Array = an[ROW_ME]["sh"]
	for v in sh:
		if (v - sh[0]).length() > 12.0:     # un disparo da a lo sumo un pasito (~8 px); un golpe, 14 o más
			return true
	return false


## Elige la animación del ataque: [nombre, a_distancia].
## Si es a distancia o de cerca lo decide SOLO el ataque: 'por_ataque' (con o sin "Pokémon|"),
## la primera regla de 'palabras' que coincida, o 'por_defecto' (según el tipo, o estado).
## Después se busca una animación coherente: a distancia, una que no lo mueva hacia el rival
## (Shoot, SpAttack...); de cerca, una que sí (Strike, Slam...). Si no tiene ninguna así, una
## parecida, y si no, ninguna (se queda quieto si dispara, o da un empujón si golpea).
static func choose(sp: String, mon_name: String, atk_name: String, typ: String, status: bool) -> Array:
	var r := _load_rules()
	var cands: Array = []      # [[anims], distancia]
	var po: Dictionary = r.get("por_ataque", {})
	for key in ["%s|%s" % [mon_name, atk_name], atk_name]:
		if po.has(key):
			cands.append([po[key].get("anims", []), bool(po[key].get("distancia", false))])
	var low := atk_name.to_lower()
	for rule in r.get("palabras", []):
		if status and not rule.get("tambien_estado", false):
			continue
		for w in rule.get("palabras", []):
			if low.contains(str(w)):
				cands.append([rule.get("anims", []), bool(rule.get("distancia", false))])
				break
	var pd: Dictionary = r.get("por_defecto", {})
	var far: bool = typ in pd.get("tipos_a_distancia", ["Water", "Lightning", "Psychic", "Grass"])
	if status:
		cands.append([pd.get("estado", ["Shoot", "Charge", "Strike", "Attack"]), true])
	cands.append([pd.get("distancia" if far else "golpe", ["Strike", "Attack", "Shoot"]), far])
	var ranged: bool = cands[0][1]      # la naturaleza del ataque: la primera regla que coincide
	# Todas las animaciones nombradas, en orden de preferencia (primero las de su propia regla)
	var order: Array = []
	for c in cands:
		if c[1] == ranged:
			for nm in c[0]:
				if not str(nm) in order:
					order.append(str(nm))
	for nm in (["Shoot", "SpAttack", "Charge", "Sing", "Gas", "Emit"] if ranged else
			["Strike", "MultiStrike", "Slam", "Attack", "Swing", "Double", "Charge"]):
		if not nm in order:
			order.append(nm)
	for nm in order:
		if has_anim(sp, nm) and moves(sp, nm) != ranged:
			return [nm, ranged]
	if not ranged:
		for nm in order:
			if has_anim(sp, nm):
				return [nm, ranged]
	return ["", ranged]


## ¿El texto del ataque cura al propio atacante? ("Heal 30 damage from this Pokémon",
## "Remove 2 damage counters from Shuckle"...)
static func heals_self(text: String, mon_name: String) -> bool:
	var who := "(this Pok.mon|%s)" % mon_name.trim_suffix(" ex").replace("(", "\\(").replace(")", "\\)")
	var rx := RegEx.create_from_string("(Heal \\d+ damage|Remove (\\d+|all|a|1|2|3) damage counters?) from " + who)
	return rx.search(text) != null


## ¿El texto del ataque deja un estado especial al Pokémon Defensor?
static func leaves_status(text: String) -> bool:
	var rx := RegEx.create_from_string("Defending Pok.mon is now (Asleep|Confused|Paralyzed|Poisoned|Burned)")
	return rx.search(text) != null


static func available(card_id: String) -> bool:
	var f := folder(card_id)
	return f != "" and not _anim(f, "Idle").is_empty()


static func _data(sp: String) -> Dictionary:
	if _species.has(sp):
		return _species[sp]
	var out := {"_xml": _parse_xml(path(sp, "AnimData.xml"))}
	_species[sp] = out
	return out


## AnimData.xml -> {"shadow": n, "anims": {nombre: {w, h, durs, hit, ret, copy}}}
static func _parse_xml(path: String) -> Dictionary:
	var res := {"shadow": 1, "anims": {}}
	var p := XMLParser.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty() or p.open_buffer(bytes) != OK:
		return res
	var cur := {}
	var tag := ""
	while p.read() == OK:
		match p.get_node_type():
			XMLParser.NODE_ELEMENT:
				tag = p.get_node_name()
				if tag == "Anim":
					cur = {"durs": [], "hit": -1, "ret": -1}
			XMLParser.NODE_TEXT:
				var txt := p.get_node_data().strip_edges()
				if txt == "":
					continue
				match tag:
					"ShadowSize": res["shadow"] = txt.to_int()
					"Name": cur["name"] = txt
					"FrameWidth": cur["w"] = txt.to_int()
					"FrameHeight": cur["h"] = txt.to_int()
					"Duration": cur["durs"].append(maxi(1, txt.to_int()))
					"HitFrame": cur["hit"] = txt.to_int()
					"ReturnFrame": cur["ret"] = txt.to_int()
					"CopyOf": cur["copy"] = txt
			XMLParser.NODE_ELEMENT_END:
				if p.get_node_name() == "Anim" and cur.has("name"):
					res["anims"][cur["name"]] = cur
				tag = ""
	return res


## Una animación lista para dibujar (vacío si no está): textura, tamaño de celda, duraciones
## y, por fila usada, la sombra, el centro y la cabeza de cada cuadro.
static func _anim(sp: String, name: String) -> Dictionary:
	var d := _data(sp)
	if d.has(name):
		return d[name]
	var out := {}
	var info: Dictionary = d["_xml"]["anims"].get(name, {})
	var src := name
	if info.has("copy"):
		src = info["copy"]
		info = d["_xml"]["anims"].get(src, info)
	var img := ImgLoad.load(path(sp, src + "-Anim.png"))
	if img != null and not info.is_empty() and int(info.get("w", 0)) > 0:
		var w := int(info["w"])
		var h := int(info["h"])
		var cols := img.get_width() / w
		var rows := img.get_height() / h
		var durs: Array = info["durs"]
		var n := mini(cols, durs.size()) if not durs.is_empty() else cols
		if durs.is_empty():
			for i in n:
				durs.append(3)
		img.convert(Image.FORMAT_RGBA8)
		out = {"tex": ImageTexture.create_from_image(img), "w": w, "h": h, "rows": rows, "n": n,
				"durs": durs.slice(0, n), "hit": int(info["hit"]), "ret": int(info["ret"]),
				"shadow": int(d["_xml"]["shadow"])}
		var total := 0
		for x in out["durs"]:
			total += int(x)
		out["total"] = total
		var shimg := ImgLoad.load(path(sp, src + "-Shadow.png"))
		var ofimg := ImgLoad.load(path(sp, src + "-Offsets.png"))
		for row in [ROW_ME, ROW_OPP, 0]:      # 0: mirando a la pantalla (Poké-Powers)
			var r := mini(row, rows - 1)
			var sh := []
			var ce := []
			var hd := []
			for c in n:
				var cell := Rect2i(c * w, r * h, w, h)
				var s := _points(shimg, cell)
				var o := _points(ofimg, cell)
				var bb := _bbox(img, cell)
				sh.append(s.get("g", Vector2(w / 2.0, bb.end.y - 1)))
				ce.append(o.get("g", Vector2(bb.get_center())))
				hd.append(o.get("k", Vector2(bb.get_center().x, bb.position.y + 4)))
			out[row] = {"r": r, "sh": sh, "ce": ce, "hd": hd}
	d[name] = out
	return out


## Puntos de color de una celda de Shadow/Offsets: g verde (sombra / centro), k negro (cabeza).
static func _points(img: Image, cell: Rect2i) -> Dictionary:
	var out := {}
	if img == null or cell.end.x > img.get_width() or cell.end.y > img.get_height():
		return out
	var acc := {"g": [Vector2.ZERO, 0], "k": [Vector2.ZERO, 0]}
	for y in cell.size.y:
		for x in cell.size.x:
			var c := img.get_pixel(cell.position.x + x, cell.position.y + y)
			if c.a < 0.5:
				continue
			var key := ""
			if c.g > 0.8 and c.r < 0.2 and c.b < 0.2:
				key = "g"
			elif c.r < 0.2 and c.g < 0.2 and c.b < 0.2:
				key = "k"
			if key != "":
				acc[key][0] += Vector2(x, y)
				acc[key][1] += 1
	for k in acc:
		if acc[k][1] > 0:
			out[k] = acc[k][0] / float(acc[k][1])
	return out


static func _bbox(img: Image, cell: Rect2i) -> Rect2:
	var sub := img.get_region(cell)
	var r := sub.get_used_rect()
	if r.size == Vector2i.ZERO:
		return Rect2(Vector2(0, 0), Vector2(cell.size))
	return Rect2(r)


## Cuadro de una animación a los `ticks` (1/60 s) de empezada.
static func _frame_at(an: Dictionary, ticks: float, loop: bool) -> int:
	var t := fmod(ticks, float(an["total"])) if loop else minf(ticks, float(an["total"]) - 0.01)
	for i in an["n"]:
		t -= float(an["durs"][i])
		if t < 0.0:
			return i
	return int(an["n"]) - 1


static func _ticks_to(an: Dictionary, frame: int) -> int:
	var s := 0
	for i in mini(frame, an["n"]):
		s += int(an["durs"][i])
	return s


# ---------------------------------------------------------------------------
# Animación de ataque
# ---------------------------------------------------------------------------

static func can_use(att_id: String, def_id: String) -> bool:
	return available(att_id) and available(def_id)


## Prepara la animación de ataque para verse como mini pelea.
static func setup(a: Dictionary, att: PlayerState, def: PlayerState, atk: Dictionary, human: int) -> void:
	var asp := folder(att.active.top())
	var dsp := folder(def.active.top())
	var typ: String = a.get("type", "Colorless")
	var status: bool = str(atk.get("damage_text", "")) == ""     # ataque que solo deja un estado (o solo cura)
	var heal_only: bool = status and not leaves_status(str(atk.get("text", "")))
	var pick := choose(asp, CardDB.card_name(att.active.top()).trim_suffix(" ex"), str(atk.get("name", "")), typ, status)
	var kind: String = "" if heal_only else pick[0]
	var ranged: bool = false if heal_only else pick[1]
	a["m_heal_only"] = heal_only
	a["m_att_mon"] = att.active
	a["m_att_dmg0"] = att.active.damage
	a["m_att_cond0"] = att.active.conditions_text()
	a["m_att_ck0"] = att.active.flags.get("pre_checkup", [])
	var me_att: bool = att.index == human
	a["m_status"] = status
	a["m_atk_name"] = str(atk.get("name", ""))
	a["m_cond0"] = def.active.conditions_text()
	a["m_sleep0"] = def.active.rotation == "asleep"
	a["scene"] = true
	a["mini"] = true
	a["m_att"] = asp
	a["m_def"] = dsp
	a["m_kind"] = kind
	a["m_ranged"] = ranged
	# Golpe físico con una animación que no se mueve de su lugar (Charge, Rotate...):
	# el atacante igual se acerca al rival y vuelve, para que se vea como un golpe
	a["m_lunge"] = not a["m_ranged"] and kind != "" and _reach(asp, kind, ROW_ME if me_att else ROW_OPP) < 6.0
	a["m_row_att"] = ROW_ME if me_att else ROW_OPP
	a["m_row_def"] = ROW_OPP if me_att else ROW_ME
	a["m_g_att"] = GROUND_ME if me_att else GROUND_OPP
	a["m_g_def"] = GROUND_OPP if me_att else GROUND_ME
	a["printed"] = int(str(atk.get("damage_text", "0")).to_int())
	# Tiempos: el golpe cae en el HitFrame del ataque (o a los 2/3 si no lo dice)
	var an := _anim(asp, kind) if kind != "" else {}
	var hit_s := 0.3
	var atk_s := 0.5
	if not an.is_empty():
		var hf: int = an["hit"] if int(an["hit"]) >= 0 else int(an["n"]) * 2 / 3
		hit_s = _ticks_to(an, hf) * TICK
		atk_s = float(an["total"]) * TICK
	var start := T_IN + T_PRE
	var impact := start + hit_s
	if a["m_ranged"]:
		impact += T_TRAVEL
		atk_s += T_STREAM
	a["m_start"] = start
	a["m_atk_len"] = atk_s
	a["m_hit_s"] = hit_s
	var dur := maxf(impact + T_HURT, start + atk_s + 0.2) + T_OUT
	a["dur"] = dur
	a["impact"] = impact / dur
	a["m_impact"] = impact


const HEAL_DELAY := 0.25   # la curación aparece un poco después del golpe
const RECOIL_DELAY := 0.5  # lo que le pasa al atacante (Rough Skin...) llega después del golpe

## Después del golpe: estados nuevos, curación del atacante, y la escena se alarga para que
## el efecto se vea entero (y, si quedó KO, para que tiemble y se desvanezca).
static func on_applied(a: Dictionary) -> void:
	# Estados nuevos que dejó el ataque (para mostrarlos en vez del número)
	if not a.has("m_conds"):
		var before: Array = str(a.get("m_cond0", "")).split(", ", false)
		var mon: PokemonInPlay = a.get("def_mon")
		var now: Array = mon.conditions_text().split(", ", false) if mon != null else []
		a["m_conds"] = now.filter(func(c): return not c in before)
	if not a.has("m_healed"):
		var am: PokemonInPlay = a.get("m_att_mon")
		# El atacante también puede salir lastimado: Rough Skin, Strikes Back, daño a sí mismo...
		# (si después hubo chequeo entre turnos, se compara con cómo estaba justo antes)
		var dmg_now: int = am.damage if am != null else 0
		var cond_now: String = am.conditions_text() if am != null else ""
		var ck = am.flags.get("pre_checkup", []) if am != null else []
		if ck is Array and ck.size() == 3 and ck != a.get("m_att_ck0", []):
			dmg_now = int(ck[1])
			cond_now = str(ck[2])
		a["m_healed"] = maxi(0, int(a.get("m_att_dmg0", 0)) - dmg_now) if am != null else 0
		a["m_recoil"] = maxi(0, dmg_now - int(a.get("m_att_dmg0", 0))) if am != null else 0
		# ...o con un estado (Poison Payback, Fire Veil, ataques que lo confunden)
		var b0: Array = str(a.get("m_att_cond0", "")).split(", ", false)
		var an: Array = cond_now.split(", ", false)
		a["m_att_conds"] = an.filter(func(c): return not c in b0)
	if a.get("m_len_done", false):
		return
	a["m_len_done"] = true
	# La escena dura lo necesario para que el efecto del golpe (y la curación) se vean enteros
	var old := float(a["dur"])
	var need := float(a["m_impact"]) + T_HURT
	var mv := move_effect(a)
	if mv != "" and (int(a.get("dmg", 0)) > 0 or special_effect(a) != ""):
		need = maxf(need, float(a["m_impact"]) + SpecialFX.fx_count(mv) * FX_FRAME + 0.2)
	var cure := str(_load_fams().get("curacion", ""))
	if int(a["m_healed"]) > 0 and SpecialFX.has_fx(cure):
		need = maxf(need, float(a["m_impact"]) + HEAL_DELAY + SpecialFX.fx_count(cure) * FX_FRAME + 0.2)
	if int(a.get("m_recoil", 0)) > 0 or not a.get("m_att_conds", []).is_empty():
		need = maxf(need, float(a["m_impact"]) + RECOIL_DELAY + 1.1)
	if a.get("ko", false):
		need += T_FAINT
	var new := maxf(old, need + T_OUT)
	if new <= old:
		return
	a["t"] = float(a["t"]) * old / new
	a["impact"] = float(a["m_impact"]) / new
	a["dur"] = new


## Z: salta casi al final (el golpe se aplica igual en el próximo cuadro).
static func skip(a: Dictionary) -> void:
	a["stop"] = 0.0
	var dur := float(a["dur"])
	a["t"] = maxf(float(a["t"]), (dur - 0.08) / dur)


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

## Dibuja un cuadro anclado: la celda queda fija (por el primer cuadro) y la sombra se mueve
## con el Pokémon. Devuelve {centro, cabeza} en pantalla.
## Cuánto se desplaza la sombra en una animación (0 = no se mueve de su lugar).
static func _reach(sp: String, name: String, row: int) -> float:
	var an := _anim(sp, name)
	if an.is_empty() or not an.has(row):
		return 0.0
	var sh: Array = an[row]["sh"]
	var m := 0.0
	for v in sh:
		m = maxf(m, (v - sh[0]).length())
	return m


static func _put(d, sp: String, name: String, row: int, frame: int, ground: Vector2,
		alpha: float = 1.0, dx: float = 0.0, visible: bool = true, sink: float = 0.0) -> Dictionary:
	var an := _anim(sp, name)
	if an.is_empty():
		an = _anim(sp, "Idle")
		frame = 0
	if an.is_empty():
		return {"c": ground + Vector2(0, -12), "h": ground + Vector2(0, -20)}
	var R: Dictionary = an[row]
	frame = clampi(frame, 0, int(an["n"]) - 1)
	var idle := _anim(sp, "Idle")
	var anchor: Vector2 = (idle[row]["sh"][0] if not idle.is_empty() else R["sh"][0])
	# La celda de esta animación se centra igual que la de Idle (SpriteCollab las centra en
	# el mismo punto), así que el ancla se corrige por la diferencia de tamaño de celda.
	if not idle.is_empty():
		anchor += Vector2((an["w"] - idle["w"]) / 2.0, (an["h"] - idle["h"]) / 2.0)
	var o: Vector2 = (ground - anchor + Vector2(dx, 0)).round()
	var sh: Vector2 = o + R["sh"][frame]
	if alpha > 0.3 and sink <= 0.0:
		var rr: float = [5.0, 7.0, 9.0][clampi(int(an["shadow"]), 0, 2)]
		_ellipse(d, sh, Vector2(rr, rr * 0.3), Color(0, 0, 0, 0.45 * alpha))
	if visible:
		var w := float(an["w"])
		var h := float(an["h"]) - sink
		if h > 0:
			d.draw_texture_rect_region(an["tex"], Rect2(o, Vector2(w, h)),
					Rect2(frame * w, int(R["r"]) * float(an["h"]), w, h), Color(1, 1, 1, alpha))
	return {"c": o + R["ce"][frame], "h": o + R["hd"][frame]}


static func _ellipse(d, c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var ang := TAU * i / 16.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	d.draw_colored_polygon(pts, col)


## Reposo: Idle, o Sleep si está dormido (y la especie la tiene).
static func _rest(d, sp: String, row: int, s: float, g: Vector2, alpha: float, sleeping: bool) -> Dictionary:
	if sleeping:
		var sl := _anim(sp, "Sleep")
		if not sl.is_empty():
			return _put(d, sp, "Sleep", row, _frame_at(sl, s / TICK, true), g, alpha)
	return _put(d, sp, "Idle", row, _idle_frame(sp, s), g, alpha)


static func _idle_frame(sp: String, s: float) -> int:
	var an := _anim(sp, "Idle")
	return 0 if an.is_empty() else _frame_at(an, s / TICK, true)


static func draw(d, a: Dictionary) -> void:
	var dur := float(a["dur"])
	var s := float(a["t"]) * dur
	var imp := float(a["m_impact"])
	var start := float(a["m_start"])
	var asp: String = a["m_att"]
	var dsp: String = a["m_def"]
	var ra: int = a["m_row_att"]
	var rd: int = a["m_row_def"]
	var ga: Vector2 = a["m_g_att"]
	var gd: Vector2 = a["m_g_def"]
	var fade := clampf(s / T_IN, 0.0, 1.0) * clampf((dur - s) / T_OUT, 0.0, 1.0)
	d.draw_rect(Rect2(0, 0, d.W, d.BOX_Y), Color(0.04, 0.05, 0.12, 0.72 * fade))
	var applied: bool = a.get("applied", false)
	var dmg := int(a.get("dmg", 0))
	var ko: bool = a.get("ko", false)
	# En los ataques de estado el daño del chequeo entre turnos (veneno, quemadura) no cuenta
	var landed: bool = applied and ((dmg > 0 and not a.get("m_status", false)) or ko)
	var after := s - imp
	# Dormido: antes del golpe según cómo estaba; después, según cómo quedó
	var mon: PokemonInPlay = a.get("def_mon")
	var sleeping: bool = a.get("m_sleep0", false)
	if applied and mon != null:
		sleeping = mon.rotation == "asleep"
	# --- Defensor: quieto (o durmiendo), daño (titila y tiembla) o KO (se hunde) ---
	var dpos := {}
	if s >= imp and landed:
		var hu := _anim(dsp, "Hurt")
		var shake := (2.0 if int(after * 30.0) % 2 == 0 else -2.0) if after < 0.3 else 0.0
		var blink := after < 0.3 and int(after * 16.0) % 2 == 1
		if ko and after > 0.35:
			# KO: se queda en Hurt temblando a sacudones y al final se desvanece
			var k := after - 0.35
			var tremble := (1.0 if int(k * 24.0) % 2 == 0 else -1.0) if fmod(k, 0.45) < 0.3 else 0.0
			var ko_a := clampf(1.0 - (k - (T_HURT + T_FAINT - 0.35 - 0.4)) / 0.35, 0.0, 1.0)
			dpos = _put(d, dsp, "Hurt", rd, int(hu.get("n", 1)) - 1, gd, fade * ko_a, tremble)
		elif not hu.is_empty() and after < T_HURT - 0.15 or ko:
			dpos = _put(d, dsp, "Hurt", rd, _frame_at(hu, after / TICK, false) if not hu.is_empty() else 0,
					gd, fade, shake, not blink)
		else:
			dpos = _rest(d, dsp, rd, s, gd, fade, sleeping)
	elif s >= imp and applied and not a.get("m_conds", []).is_empty():
		# Quedó con un estado: un respingo corto
		var hu := _anim(dsp, "Hurt")
		var shake := (1.0 if int(after * 30.0) % 2 == 0 else -1.0) if after < 0.25 else 0.0
		if not hu.is_empty() and after < 0.3:
			dpos = _put(d, dsp, "Hurt", rd, 0, gd, fade, shake)
		else:
			dpos = _rest(d, dsp, rd, s, gd, fade, sleeping)
	elif s >= imp and applied and (sleeping or a.get("m_heal_only", false)):
		dpos = _rest(d, dsp, rd, s, gd, fade, true)     # dormido no esquiva: sigue durmiendo
	elif s >= imp and applied:
		# Sin daño: lo esquiva saltando (Hop), o con un paso al costado si no tiene
		var ho := _anim(dsp, "Hop")
		var k2 := s - imp
		if not ho.is_empty() and k2 / TICK < float(ho["total"]) * 2:
			dpos = _put(d, dsp, "Hop", rd, _frame_at(ho, k2 / TICK, true), gd, fade)
		else:
			var side := sin(clampf(k2 / 0.45, 0.0, 1.0) * PI) * 9.0
			dpos = _put(d, dsp, "Idle", rd, 0, gd, fade, -side if rd == ROW_ME else side)
	else:
		dpos = _rest(d, dsp, rd, s, gd, fade, sleeping)
	# --- Atacante ---
	var kind: String = a["m_kind"]
	var apos := {}
	var k := s - start
	var an := _anim(asp, kind) if kind != "" else {}
	if k >= 0.0 and k < float(a["m_atk_len"]) and not an.is_empty():
		var ticks := k / TICK
		var fr := _frame_at(an, ticks, false)
		if a["m_ranged"]:
			# El disparo: los cuadros después del HitFrame se repiten mientras dura el chorro
			var hit_t := float(a["m_hit_s"]) / TICK
			var n: int = an["n"]
			var hf: int = clampi(int(an["hit"]) if int(an["hit"]) >= 0 else n * 2 / 3, 0, n - 1)
			var loop_a := mini(hf + 1, n - 1)
			var loop_b := maxi(loop_a, n - 2)
			if ticks >= hit_t and ticks < hit_t + T_STREAM / TICK and loop_b > loop_a:
				var span := _ticks_to(an, loop_b + 1) - _ticks_to(an, loop_a)
				var tt := _ticks_to(an, loop_a) + fmod(ticks - hit_t, float(maxi(1, span)))
				fr = _frame_at(an, tt, false)
			elif ticks >= hit_t + T_STREAM / TICK:
				fr = _frame_at(an, ticks - T_STREAM / TICK, false)
		var g_at := ga
		if a.get("m_lunge", false):
			# Se acerca hasta el golpe y vuelve después
			var hit_s := maxf(0.05, float(a["m_hit_s"]))
			var back := maxf(0.05, float(a["m_atk_len"]) - hit_s)
			var pr := clampf(k / hit_s, 0.0, 1.0) if k < hit_s else 1.0 - clampf((k - hit_s) / back, 0.0, 1.0)
			g_at = ga + (gd - ga) * 0.55 * sin(pr * PI / 2.0)
		apos = _put(d, asp, kind, ra, fr, g_at, fade)
	elif kind == "" and k >= 0.0 and k < 0.5 and not a.get("m_heal_only", false) and not a["m_ranged"]:
		# Sin animación de ataque: un empujón hacia el rival
		var push := sin(clampf(k / 0.5, 0.0, 1.0) * PI) * 8.0
		var dir := (gd - ga).normalized()
		apos = _put(d, asp, "Idle", ra, 0, ga + dir * push, fade)
	else:
		var rk := s - imp - RECOIL_DELAY
		var hurt_att: bool = applied and rk >= 0.0 and rk < 0.45 \
				and (int(a.get("m_recoil", 0)) > 0 or not a.get("m_att_conds", []).is_empty())
		if hurt_att and has_anim(asp, "Hurt"):
			var shake := (2.0 if int(rk * 30.0) % 2 == 0 else -2.0) if rk < 0.3 else 0.0
			var blink := int(rk * 16.0) % 2 == 1 and int(a.get("m_recoil", 0)) > 0 and rk < 0.3
			apos = _put(d, asp, "Hurt", ra, _frame_at(_anim(asp, "Hurt"), rk / TICK, false), ga, fade, shake, not blink)
		else:
			apos = _put(d, asp, "Idle", ra, _idle_frame(asp, s), ga, fade)
	# --- Efectos ---
	if a["m_ranged"]:
		_draw_stream(d, a, s, apos["h"], dpos["c"])
	if s >= imp and applied:
		if not landed and special_effect(a) != "":
			var sfx := special_effect(a)
			var sfr := int(after / FX_FRAME)
			if sfr < SpecialFX.fx_count(sfx):
				SpecialFX.fx_draw(d, sfx, sfr, dpos["c"])
		if landed:
			_draw_hit(d, a, after, dpos["c"])
			_draw_number(d, a, after, dpos["c"])
		elif not a.get("m_conds", []).is_empty():
			_draw_status(d, a, after, dpos["c"])
		elif not a.get("m_heal_only", false):
			_draw_miss(d, after, dpos["c"])
		# El atacante se cura: efecto encima suyo y "+20" en verde
		if int(a.get("m_healed", 0)) > 0 and apos.has("c"):
			_draw_heal(d, a, after - HEAL_DELAY, apos["c"])
		# El atacante sale lastimado: su número y, después, el estado que le quedó
		var rk2 := after - RECOIL_DELAY
		if apos.has("c") and rk2 >= 0.0:
			if int(a.get("m_recoil", 0)) > 0:
				_draw_number(d, a, rk2, apos["c"], int(a["m_recoil"]))
				rk2 -= 0.5
			if not a.get("m_att_conds", []).is_empty() and rk2 >= 0.0:
				_draw_status(d, a, rk2, apos["c"], a["m_att_conds"])


static func _draw_heal(d, a: Dictionary, k: float, c: Vector2) -> void:
	if k < 0.0:
		return
	var cure := str(_load_fams().get("curacion", ""))
	if SpecialFX.has_fx(cure):
		var fr := int(k / FX_FRAME)
		if fr < SpecialFX.fx_count(cure):
			SpecialFX.fx_draw(d, cure, fr, c)
	var txt := "+%d" % int(a["m_healed"])
	var p := c + Vector2(-d._text_w(txt) / 2.0, -26 - minf(k, 1.0) * 6.0)
	p.x = clampf(p.x, 2.0, d.W - 2.0 - d._text_w(txt))
	p.y = maxf(p.y, 2.0)
	var al := clampf((1.6 - k) * 3.0, 0.0, 1.0)
	d._text(p.round() + Vector2(1, 1), txt, Color(0.08, 0.08, 0.16, al))
	d._text(p.round(), txt, Color(0.45, 1.0, 0.5, al))


## Lo que viaja de la boca del atacante al defensor en los ataques a distancia.
static func _draw_stream(d, a: Dictionary, s: float, src: Vector2, dst: Vector2) -> void:
	var t0 := float(a["m_start"]) + float(a["m_hit_s"])
	var typ: String = a["type"]
	var n := 10
	for b in n:
		var born := t0 + b * (T_STREAM / n)
		var k := (s - born) / T_TRAVEL
		if k < 0.0 or k > 1.0:
			continue
		var p := src.lerp(dst, k) + Vector2(0, sin(b * 1.7) * 2.0)
		var ang := (dst - src).angle()
		match typ:
			"Water":
				SpecialFX.fx_draw(d, "burbuja_acida", 6 + b % 3, p, 0.9)
			"Fire":
				SpecialFX.fx_draw(d, "ascuas", (b + int(s * 20.0)) % 12, p, 0.8)
			"Grass":
				SpecialFX.fx_draw(d, "hoja", b % 5, p, 1.0, 1.0, ang + s * 8.0)
			"Lightning":
				SpecialFX.fx_draw(d, "rayo", (b + int(s * 24.0)) % 7, p, 0.6, 1.0, ang)
			"Psychic":
				SpecialFX.fx_draw(d, "anillo", 1 + b % 3, p, 0.6, 1.0, 0.0, false, Color("#e0a0ff"))
			_:
				SpecialFX.fx_draw(d, "estrellas", b % 5, p, 0.5)


## El golpe sobre el defensor: un efecto por tipo, más fuerte desde 50 de daño.
static func _load_fams() -> Dictionary:
	if _fams.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(FAMS_PATH)) if ImgLoad.exists(FAMS_PATH) else null
		_fams = j if j is Dictionary else {"familias": {}}
	return _fams


## Familia de efectos del atacante: el primero de sus tipos de los juegos que va con el tipo
## de la carta (Onix, carta Lucha -> roca; Arbok, carta Planta -> veneno), o la de la carta.
static func family(sp: String, card_type: String) -> String:
	var f := _load_fams()
	var key := sp.trim_suffix("_shiny")
	if key.begins_with("castform"):
		key = "castform"
	var t2f: Dictionary = f.get("tipo_a_familia", {})
	var fams: Dictionary = f.get("familias", {})
	for t in f.get("especies", {}).get(key, []):
		var fam: String = t2f.get(t, "")
		if fams.has(fam) and card_type in fams[fam].get("carta", []):
			return fam
	return str(f.get("por_carta", {}).get(card_type, "normal"))


## Nombres del sonido del golpe, del más preciso al más general: la familia del atacante
## (tierra, volador...), de cerca ("fisico") o a distancia, y débil o fuerte según el daño
## (mismo corte que los efectos). Ej.: ["tierra_fisico_fuerte", "tierra_fisico_debil", ...].
## Primero la combinación exacta en cada familia del Pokémon, después las parecidas.
## Sirve también sin mini pelea (con la escena en la mesa): lo calcula desde la carta.
static func sound_names(a: Dictionary) -> Array:
	var card: String = a.get("att_card", "")
	var sp: String = a.get("m_att", "")
	if sp == "" and card != "":
		sp = folder(card)
	var typ: String = a.get("type", "Colorless")
	# Todas las familias del Pokémon que van con el tipo del ataque; "normal" al final
	# (así Swellow, Normal/Volador, usa los golpes de volador si están).
	var fams: Array = []
	var f := _load_fams()
	var key := sp.trim_suffix("_shiny")
	if key.begins_with("castform"):
		key = "castform"
	for t in f.get("especies", {}).get(key, []):
		var fm: String = f.get("tipo_a_familia", {}).get(t, "")
		if fm != "" and typ in f.get("familias", {}).get(fm, {}).get("carta", []) and not fams.has(fm):
			fams.append(fm)
	fams.sort_custom(func(x, y): return x != "normal" and y == "normal")
	var main := family(sp, typ)
	if not fams.has(main):
		fams.append(main)
	var ranged: bool
	if a.has("m_ranged"):
		ranged = a["m_ranged"]
	else:
		ranged = choose(sp, CardDB.card_name(card).trim_suffix(" ex"), str(a.get("atk_name", "")), typ, false)[1]
	var strong := int(a.get("dmg", 0)) >= int(f.get("corte", 50))
	var r1 := "distancia" if ranged else "fisico"
	var r2 := "fisico" if ranged else "distancia"
	var s1 := "fuerte" if strong else "debil"
	var s2 := "debil" if strong else "fuerte"
	var out: Array = []
	var special := special_sound(a)
	if special != "":
		out.append(special)
	for combo in [[r1, s1], [r1, s2], [r2, s1], [r2, s2]]:
		for fm in fams:
			out.append("%s_%s_%s" % [fm, combo[0], combo[1]])
	return out


## Sonido propio de un ataque por su nombre ('sonido' en 'efecto_por_palabra': Wrap, Bind...).
static func special_sound(a: Dictionary) -> String:
	var low := str(a.get("atk_name", a.get("m_atk_name", ""))).to_lower()
	for rule in _load_fams().get("efecto_por_palabra", []):
		if str(rule.get("sonido", "")) == "":
			continue
		for w in rule.get("palabras", []):
			if low.contains(str(w)):
				return str(rule["sonido"])
	return ""


## El efecto de Mystery Dungeon del golpe (tira mv_XXXX), o "" si no hay tiras.
## Ataques con un efecto propio sin importar el tipo (Wrap, Bind... -> los anillos de Wrap).
static func special_effect(a: Dictionary) -> String:
	var low := str(a.get("m_atk_name", "")).to_lower()
	for rule in _load_fams().get("efecto_por_palabra", []):
		for w in rule.get("palabras", []):
			if low.contains(str(w)) and SpecialFX.has_fx(str(rule.get("efecto", ""))):
				return str(rule["efecto"])
	return ""


static func move_effect(a: Dictionary) -> String:
	if a.has("m_fx"):
		return a["m_fx"]
	var f := _load_fams()
	var fam: Dictionary = f.get("familias", {}).get(family(a.get("m_att", ""), a.get("type", "Colorless")), {})
	var slot := ("distancia_" if a.get("m_ranged", false) else "golpe_") \
			+ ("fuerte" if int(a.get("dmg", 0)) >= int(f.get("corte", 50)) else "debil")
	var low := str(a.get("m_atk_name", "")).to_lower()
	for w in f.get("palabras_mordida", []):
		if low.contains(str(w)):
			slot = "mordida"
	var name: String = fam.get(slot, "")
	var special := special_effect(a)
	if special != "":
		name = special
	if name == "" or not SpecialFX.has_fx(name):
		name = ""
	if a.get("applied", false):
		a["m_fx"] = name          # ya se sabe el daño: queda fijo
	return name


static func _draw_hit(d, a: Dictionary, after: float, c: Vector2) -> void:
	# Efecto de Mystery Dungeon según la familia del atacante (si están las tiras)
	var mv := move_effect(a)
	if mv != "":
		var n := SpecialFX.fx_count(mv)
		var fr := int(after / FX_FRAME)
		if fr < n:
			SpecialFX.fx_draw(d, mv, fr, c)
		return
	var typ: String = a["type"]
	var big := int(a.get("dmg", 0)) >= 50
	var k := clampf(after / 0.6, 0.0, 1.0)
	var al := 1.0 - maxf(0.0, k - 0.7) / 0.3
	if big and SpecialFX.has_fx("explosion") and after < 0.4:
		var tint: Color = {"Grass": Color("#c8ffc8"), "Water": Color("#c8e8ff"), "Psychic": Color("#e0a0ff"),
				"Darkness": Color("#b080e0")}.get(typ, Color.WHITE)
		SpecialFX.fx_draw(d, "explosion", SpecialFX.fx_frame("explosion", after / 0.4), c, 1.3, 1.0, 0.0, false, tint)
	match typ:
		"Fire":
			SpecialFX.fx_draw(d, "fuego_golpe", SpecialFX.fx_frame("fuego_golpe", k), c + Vector2(0, -4), 1.0 if big else 0.8, al)
		"Water":
			SpecialFX.fx_draw(d, "ola", 0, c + Vector2(4, -8 + after * 10.0), 0.4 if big else 0.3, 1.0 - k)
			for b in 3:
				SpecialFX.fx_draw(d, "burbuja_acida", maxi(0, 5 - int(after * 15.0)),
						c + Vector2(-8 + b * 8, -2 + (b % 2) * 6), 0.45)
		"Grass":
			for i in (6 if big else 4):
				var ang := TAU * i / (6.0 if big else 4.0) + 0.3
				SpecialFX.fx_draw(d, "hoja", i % 5, c + Vector2(cos(ang), sin(ang)) * (4.0 + k * 18.0), 1.0, al, ang + k * 6.0)
		"Lightning":
			for i in (3 if big else 2):
				SpecialFX.fx_draw(d, "rayo", (i * 2 + int(after * 24.0)) % 7, c + Vector2((i - 1) * 8, -4 + (i % 2) * 6),
						0.8, al, 1.2 + i * 0.6)
		"Psychic":
			SpecialFX.fx_draw(d, "anillo", SpecialFX.fx_frame("anillo", k), c, 1.2 if big else 0.9, 1.0, 0.0, false, Color("#e0a0ff"))
		"Darkness":
			SpecialFX.fx_draw(d, "colmillos", 0 if after < 0.15 else 1, c, 1.0 if big else 0.8, al, 0.0, false, Color("#c8a0f0"))
		"Metal":
			for i in 4:
				var ang := TAU * i / 4.0 + 0.8
				SpecialFX.fx_draw(d, "estrellas", (i + int(after * 12.0)) % 5, c + Vector2(cos(ang), sin(ang)) * (4.0 + k * 14.0), 0.6, al)
		"Fighting":
			if not big:
				SpecialFX.fx_draw(d, "explosion", SpecialFX.fx_frame("explosion", minf(1.0, after / 0.35)), c, 0.8, al)
			for i in (4 if big else 0):
				var ang := TAU * i / 4.0 + 0.5
				SpecialFX.fx_draw(d, "roca", 3 + i % 3, c + Vector2(cos(ang), sin(ang)) * (6.0 + k * 16.0), 0.8, al)
		_:
			SpecialFX.fx_draw(d, "zarpazo", SpecialFX.fx_frame("zarpazo", minf(1.0, after / 0.35)), c, 1.0 if big else 0.8, al)
			if typ == "Dragon":
				SpecialFX.fx_draw(d, "llama", int(after * 20.0) % 8, c + Vector2(0, 6), 0.5, al)


static func _draw_number(d, a: Dictionary, after: float, c: Vector2, amount: int = -1) -> void:
	var recoil := amount >= 0
	if not recoil:
		amount = int(a["dmg"])
	var txt := "-%d" % amount
	var weak: bool = a.get("weak", false) and not recoil
	var pop := clampf(after * 7.0, 0.0, 1.0)
	var base_sc := 2.0 if weak else 1.5
	var sc: float = base_sc + sin(pop * PI) * 0.6 if pop < 1.0 else base_sc
	var w: float = d._text_w(txt) * sc
	var p := c + Vector2(-w / 2.0, -26 - minf(after, 1.0) * 8.0)
	p.y = maxf(p.y, 2.0)
	p.x = clampf(p.x, 2.0, d.W - 2.0 - w)
	var col: Color = Color("#f85838") if amount >= 60 or weak else Color("#f8e060")
	col.a = clampf((1.2 - after) * 3.0, 0.0, 1.0)
	d.draw_set_transform(d._base_off + p.round(), 0, Vector2(sc, sc))
	d._text(Vector2.ZERO, txt, col)
	d.draw_set_transform(d._base_off)


## El estado que quedó: un destello del color del estado y su nombre ("Asleep!").
static func _draw_status(d, a: Dictionary, after: float, c: Vector2, conds: Array = []) -> void:
	if conds.is_empty():
		conds = a["m_conds"]
	var col: Color = STATUS_COL.get(conds[0], Color.WHITE)
	var k := clampf(after / 0.6, 0.0, 1.0)
	SpecialFX.fx_draw(d, "anillo", SpecialFX.fx_frame("anillo", k), c, 1.0, 1.0 - k * 0.5, 0.0, false, col)
	for i in 4:
		var ang := TAU * i / 4.0 + after * 3.0
		SpecialFX.fx_draw(d, "estrellas", (i + int(after * 12.0)) % 5, c + Vector2(cos(ang), sin(ang) * 0.5) * 12.0 + Vector2(0, -14), 0.5, 1.0 - k, 0.0, false, col)
	var txt: String = "%s!" % conds[0]
	var p := c + Vector2(-d._text_w(txt) / 2.0, -28 - minf(after, 1.0) * 6.0)
	p.x = clampf(p.x, 2.0, d.W - 2.0 - d._text_w(txt))
	p.y = maxf(p.y, 2.0)
	var tc := col
	tc.a = clampf((1.3 - after) * 3.0, 0.0, 1.0)
	d._text(p.round() + Vector2(1, 1), txt, Color(0.08, 0.08, 0.16, tc.a))
	d._text(p.round(), txt, tc)


static func _draw_miss(d, after: float, c: Vector2) -> void:
	var txt := "Miss!"
	var p := c + Vector2(-d._text_w(txt) / 2.0, -26 - minf(after, 1.0) * 6.0)
	d._text(p.round(), txt, Color(1, 1, 1, clampf((1.0 - after) * 3.0, 0.0, 1.0)))
