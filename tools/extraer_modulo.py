#!/usr/bin/env python3
"""Saca tramos de scenes/duel.gd a un módulo aparte (RefCounted con `d` = la pantalla de duelo).

Uso: extraer_modulo.py <modulo.gd> <var_en_duel> "<descripción>" <desde-hasta> [<desde-hasta> ...]
  Los tramos son números de línea de duel.gd (inclusive). Todo lo que se define ahí
  (func, var, const) pasa al módulo. Después:
  - en el módulo, lo que sigue siendo de duel.gd se escribe d.algo (y self -> d);
  - en duel.gd, las llamadas a lo que se fue se escriben <var_en_duel>.algo;
  - en los otros scripts, d.algo / scene.algo / duel.algo pasan a d.<var>.algo.
No cambia lo que hace el código: solo dónde vive.
"""
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DUEL = os.path.join(ROOT, "scenes", "duel.gd")

KEYWORDS = set("""if elif else for while match break continue pass return class class_name extends is in as
self signal func static const enum var breakpoint preload await yield assert void PI TAU INF NAN true false null
and or not super""".split())
BUILTIN_FUNCS = set("""len str int float bool min max mini maxi minf maxf abs absf absi floor ceil round roundf roundi
floorf floori ceilf ceili sqrt pow sin cos tan asin acos atan atan2 exp log lerp lerpf lerp_angle clamp clampi clampf
randf randi randi_range randf_range range print prints printt push_error push_warning load is_instance_valid
typeof fmod fposmod posmod sign signf signi wrapf wrapi smoothstep deg_to_rad rad_to_deg ease snapped snappedf hash
var_to_str str_to_var weakref instance_from_id randomize seed inverse_lerp move_toward pingpong is_equal_approx
is_zero_approx print_debug char type_string rid_from_int bytes_to_var var_to_bytes cubic_interpolate step_decimals
nearest_po2 linear_to_db db_to_linear is_nan is_inf error_string print_rich remap""".split())
# Miembros heredados de Node2D / CanvasItem / Node que usa duel.gd
INHERITED = set("""queue_redraw get_viewport get_viewport_rect get_tree add_child remove_child get_node get_child
get_children has_node is_inside_tree set_process set_process_input get_global_mouse_position get_local_mouse_position
position scale visible modulate self_modulate material texture_filter create_tween get_window name get_parent
draw_set_transform draw_set_transform_matrix get_canvas_transform get_global_transform z_index set_physics_process
is_processing get_process_delta_time owner process_mode""".split())


def strip_code(src):
    """Devuelve una máscara: True donde hay código (no texto ni comentario)."""
    mask = [True] * len(src)
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "#":
            j = src.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                mask[k] = False
            i = j
            continue
        if c in "\"'":
            q = c * 3 if src[i:i + 3] == c * 3 else c
            j = i + len(q)
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j:j + len(q)] == q:
                    j += len(q)
                    break
                j += 1
            for k in range(i, min(j, n)):
                mask[k] = False
            i = j
            continue
        i += 1
    return mask


IDENT = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
STR_RE = re.compile(r"\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*'")


def tokens(src):
    """(inicio, fin, nombre) de cada identificador en código (no en textos ni comentarios)."""
    mask = strip_code(src)
    out = []
    for m in IDENT.finditer(src):
        s = m.start()
        if not mask[s]:
            continue
        if s > 0 and (src[s - 1].isalnum() or src[s - 1] == "_"):
            continue
        out.append((s, m.end(), m.group()))
    return out, mask


def prev_char(src, mask, s):
    k = s - 1
    while k >= 0 and src[k] in " \t":
        k -= 1
    return src[k] if k >= 0 else ""


def top_level_defs(lines):
    """Nombres definidos arriba de todo (func, static func, var, const, signal) con su línea."""
    defs = {}
    for i, l in enumerate(lines):
        m = re.match(r"(?:static\s+)?func\s+([A-Za-z_]\w*)", l) or re.match(r"(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?var\s+([A-Za-z_]\w*)", l) \
            or re.match(r"const\s+([A-Za-z_]\w*)", l) or re.match(r"signal\s+([A-Za-z_]\w*)", l)
        if m:
            defs[m.group(1)] = i
    return defs


def func_locals(chunk):
    """Por cada func del tramo: nombres locales (parámetros, var, for, lambdas)."""
    loc = {}
    cur = None
    ls = chunk.split("\n")
    i = 0
    while i < len(ls):
        l = ls[i]
        m = re.match(r"(?:static\s+)?func\s+(\w+)\s*\(", l)
        if m:
            cur = m.group(1)
            loc[cur] = set()
            sig = l
            j = i
            while sig.count("(") > sig.count(")") and j + 1 < len(ls):
                j += 1
                sig += " " + ls[j]
            params = sig[sig.index("(") + 1:]
            depth = 1
            buf = ""
            for ch in params:
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        break
                buf += ch
            for p in re.split(r",(?![^()\[\]{}]*[)\]}])", buf):
                p = p.strip()
                if p:
                    loc[cur].add(re.match(r"\w+", p).group())
            i = j + 1
            continue
        if l and not l[0].isspace() and not l.startswith("#"):
            cur = None
        if cur is not None:
            code = l.split("#")[0]
            for v in re.findall(r"\bvar\s+(\w+)", code):
                loc[cur].add(v)
            for v in re.findall(r"\bfor\s+(\w+)\s+in\b", code):
                loc[cur].add(v)
            for ps in re.findall(r"\bfunc\s*\(([^)]*)\)", code):
                for p in ps.split(","):
                    p = p.strip()
                    if p:
                        loc[cur].add(re.match(r"\w+", p).group())
        i += 1
    return loc


def var_blocks(lines):
    """Líneas que ocupa cada var/const de arriba de todo (con sus renglones de continuación)."""
    out = {}
    i = 0
    while i < len(lines):
        m = re.match(r"(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?(?:var|const)\s+(\w+)", lines[i])
        if m:
            j = i
            def clean(s):
                s = STR_RE.sub('""', s)
                return s.split("#")[0]
            code = clean(lines[i])
            bal = sum(code.count(c) for c in "([{") - sum(code.count(c) for c in ")]}")
            while (bal > 0 or code.rstrip().endswith("\\")) and j + 1 < len(lines) and (lines[j + 1][:1] in "\t )]}" ):
                j += 1
                code = clean(lines[j])
                bal += sum(code.count(c) for c in "([{") - sum(code.count(c) for c in ")]}")
            out[m.group(1)] = (i, j)
            i = j + 1
            continue
        i += 1
    return out


def main():
    mod_path, var_name, desc = sys.argv[1], sys.argv[2], sys.argv[3]
    ranges = []
    for r in sys.argv[4:]:
        a, b = r.split("-")
        ranges.append((int(a), int(b)))
    src = open(DUEL, encoding="utf-8").read()
    lines = src.split("\n")
    all_defs = top_level_defs(lines)
    taken = set()
    for a, b in ranges:
        for i in range(a - 1, b):
            taken.add(i)
    # var/const del tramo que se usan fuera de él se quedan en duel.gd
    vb = var_blocks(lines)
    outside = "\n".join(l for i, l in enumerate(lines) if i not in taken)
    others_txt = ""
    for base, _, files in os.walk(ROOT):
        rel = os.path.relpath(base, ROOT)
        if rel.startswith("scenes") or rel.startswith("tests"):
            for fn in files:
                if fn.endswith(".gd") and fn != "duel.gd":
                    others_txt += open(os.path.join(base, fn), encoding="utf-8").read()
    kept_here = []
    for name, (a, b) in vb.items():
        if a in taken and (re.search(r"(?<![\w.])" + name + r"\b", outside) or re.search(r"\.\s*" + name + r"\b", others_txt)):
            for i in range(a, b + 1):
                taken.discard(i)
            kept_here.append(name)
    if kept_here:
        print("se quedan en duel.gd (se usan afuera):", ", ".join(kept_here))
    moved_lines = [lines[i] for i in sorted(taken)]
    kept_lines = [l for i, l in enumerate(lines) if i not in taken]
    moved_defs = {n for n, i in all_defs.items() if i in taken}
    for bad in ["_ready", "_process", "_draw", "_unhandled_input", "_input", "_notification", "_init"]:
        if bad in moved_defs:
            sys.exit("no se puede mover " + bad)
    duel_members = (set(all_defs) - moved_defs)

    # --- Módulo: prefijar lo que queda en duel.gd ---
    chunk = "\n".join(moved_lines)
    locs = func_locals(chunk)
    toks, mask = tokens(chunk)
    # en qué función está cada posición
    func_at = []
    cur = None
    pos = 0
    starts = []
    for l in moved_lines:
        m = re.match(r"(?:static\s+)?func\s+(\w+)", l)
        if m:
            cur = m.group(1)
        elif l and not l[0].isspace() and not l.startswith("#"):
            cur = None
        starts.append((pos, cur))
        pos += len(l) + 1
    def func_of(p):
        f = None
        for s, c in starts:
            if s > p:
                break
            f = c
        return f
    unknown = set()
    shadow = set()
    out = []
    last = 0
    for s, e, name in toks:
        pc = prev_char(chunk, mask, s)
        if pc == "." or pc == "$" or pc == "@":
            continue
        f = func_of(s)
        if f is not None and name == "d" and "d" in locs.get(f, set()):
            out.append(chunk[last:s])
            out.append("dd_")          # una variable local "d" chocaría con la pantalla de duelo
            last = e
            continue
        if f is not None and name in locs.get(f, set()):
            if name in duel_members:
                shadow.add(f + ":" + name)
            continue
        rep = None
        if name == "self":
            rep = "d"
        elif name in moved_defs:
            rep = None
        elif name in duel_members or name in INHERITED or name.startswith("draw_"):
            # línea de definición de la func: no tocar el nombre
            rep = "d." + name
        elif name in KEYWORDS or name in BUILTIN_FUNCS or name[0].isupper():
            rep = None
        else:
            # ¿es una definición de var/const/func del propio tramo o un nombre de parámetro con tipo?
            unknown.add(name)
        if rep:
            out.append(chunk[last:s])
            out.append(rep)
            last = e
    out.append(chunk[last:])
    mod_code = "".join(out)
    # "var x := d.algo" no se puede inferir (d no tiene tipo): pasa a "var x = d.algo", y
    # también las que dependen de esas (hasta que no cambie nada).
    untyped = {"d", "dd_"}
    while True:
        changed = [False]
        def untype(m):
            rhs = m.group(3)
            code = rhs.split("#")[0]
            names = set(re.findall(r"(?<![\w.])([A-Za-z_]\w*)", code))
            if names & untyped:
                untyped.add(m.group(2))
                changed[0] = True
                return m.group(1) + m.group(2) + " = " + rhs
            return m.group(0)
        mod_code = re.sub(r"(^[ \t]*(?:var|const)\s+)(\w+)\s*:=\s*(.*)$", untype, mod_code, flags=re.M)
        if not changed[0]:
            break
    # "func d.x(" no puede pasar: las defs se excluyen por estar en moved_defs.
    header = f"""extends RefCounted
## {desc}
## (Sacado de scenes/duel.gd: `d` es la pantalla de duelo; lo que sigue viviendo ahí se escribe d.algo.)

var d       # la pantalla de duelo (duel.gd)


func _init(duel) -> void:
\td = duel


"""
    open(os.path.join(ROOT, mod_path), "w", encoding="utf-8").write(header + mod_code.strip("\n") + "\n")
    for l in mod_code.split("\n"):
        if re.match(r"(?:@\w+\s+)?var\s", l) and "d." in l.split("#")[0]:
            print("OJO, var del módulo que usa d. al crearse:", l.strip())

    # --- duel.gd: lo que se fue pasa a <var>.algo ---
    rest = "\n".join(kept_lines)
    rtoks, rmask = tokens(rest)
    rlocs = func_locals(rest)
    rstarts = []
    pos = 0
    cur = None
    for l in kept_lines:
        m = re.match(r"(?:static\s+)?func\s+(\w+)", l)
        if m:
            cur = m.group(1)
        elif l and not l[0].isspace() and not l.startswith("#"):
            cur = None
        rstarts.append((pos, cur))
        pos += len(l) + 1
    out = []
    last = 0
    import bisect
    keys = [s for s, _ in rstarts]
    for s, e, name in rtoks:
        if name not in moved_defs:
            continue
        pc = prev_char(rest, rmask, s)
        if pc in ".$@":
            continue
        i = bisect.bisect_right(keys, s) - 1
        f = rstarts[i][1] if i >= 0 else None
        if f and name in rlocs.get(f, set()):
            continue
        out.append(rest[last:s])
        out.append(var_name + "." + name)
        last = e
    out.append(rest[last:])
    rest = "".join(out)
    # la variable del módulo, junto a las otras (después de los preload)
    mod_class = os.path.splitext(os.path.basename(mod_path))[0]
    const_name = "".join(p.capitalize() for p in mod_class.split("_")) + "Script"
    decl = f'const {const_name} := preload("res://{mod_path}")\nvar {var_name} = {const_name}.new(self)     # {desc}\n'
    anchor = rest.find("const SpecialFX")
    nl = rest.find("\n", anchor) + 1
    rest = rest[:nl] + decl + rest[nl:]
    open(DUEL, "w", encoding="utf-8").write(re.sub(r"\n{4,}", "\n\n\n", rest))

    # --- otros scripts ---
    others = []
    for base, _, files in os.walk(ROOT):
        rel = os.path.relpath(base, ROOT)
        if not (rel.startswith("scenes") or rel.startswith("tests")):
            continue
        for fn in files:
            p = os.path.join(base, fn)
            if fn.endswith(".gd") and p not in (DUEL, os.path.join(ROOT, mod_path)):
                others.append(p)
    pat = re.compile(r"\b(d|scene|duel)\.(" + "|".join(sorted(moved_defs, key=len, reverse=True)) + r")\b") if moved_defs else None
    touched = []
    for p in others:
        t = open(p, encoding="utf-8").read()
        if pat is None:
            break
        t2 = pat.sub(lambda m: f"{m.group(1)}.{var_name}.{m.group(2)}", t)
        if t2 != t:
            open(p, "w", encoding="utf-8").write(t2)
            touched.append(os.path.relpath(p, ROOT))
    print("movidos:", len(moved_defs), "nombres; líneas:", len(moved_lines))
    print("otros scripts tocados:", ", ".join(touched) or "-")
    leftovers = sorted(u for u in unknown if u not in moved_defs)
    print("nombres sin resolver en el módulo (revisar):", ", ".join(leftovers))
    print("locales que tapan miembros de duel (revisar):", ", ".join(sorted(shadow)) or "-")


main()
