"""Arma los efectos de la mini pelea por nombre de ataque (golpe + proyectil), a partir de
las categorías de la hoja "Efectos de ataque por nombre".

Uso:
    python3 tools/efectos_por_nombre.py <carpeta_vfx> <ataques.json>

<carpeta_vfx>  cuadros sueltos: NNNN/GGG/*.png de la carpeta move_VFX de Explorers of Sky, y las
               hojas de Red Rescue Team ya recortadas (rrt_*, rv_*, rr_*, rd_*, rg_lick, remolino...).
<ataques.json> {"Nombre del ataque": "categoria", ...} (columna Efecto de la hoja Ataques).

Escribe:
    efectos/propios/gx_<cat>.png/.json   el golpe, todos sus tramos en una sola tira.
        json: {"celda": [w, h], "ancla": [x, y], "modo": "cuerpo"|"suelo"|"atacante", "temblor": bool}
        "ancla" es el punto de la celda que va sobre el centro del defensor (cuerpo), sobre su
        sombra (suelo) o sobre el centro del atacante (atacante).
    efectos/propios/px_<cat>.png/.json   lo que viaja del atacante al defensor.
        json: {"celda", "tipo": "chorro"|"arco"|"ola"|"vuelta", "n", "ondula", "espacio",
               "vel", "desfase", "alto", "gira", "tope", "cuadros"}
        Cada partícula i va por k (0..1) del atacante al defensor; usa el cuadro
        int(k * vel + i * desfase), dando la vuelta (o quedándose en el último si "tope").
    data/ataques_efectos.json            {"ataques": {nombre en minúsculas: cat}, "categorias": {...}}
        cada categoría: {"golpe": "gx_...", "proyectil": "px_..." o "", "sonido": "agua_distancia" o "wrap"}

Las posiciones salen de la maqueta (la mini pelea a escala 1:1): el centro del defensor está
14 px arriba de su sombra.
"""
import json
import math
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_FX = os.path.join(ROOT, "efectos", "propios")
OUT_DATA = os.path.join(ROOT, "data", "ataques_efectos.json")
PIE = 14          # del centro del cuerpo a la sombra
V = ""

# --- Golpe por categoría: (tramos, anclaje por tramo, temblor) ---
#   tramos: 'A+B*n@m' (A y después B; *n repite el último cuadro n veces; @m empieza en el cuadro m)
#   anclaje: "c" cuerpo, "s" suelo, "a" atacante (uno por tramo, o uno para todos)
GOLPES = {
    "puño_fuego": ("rrt_firepunch", "c"), "puño_hielo": ("mv_0221+0055", "c"),
    "puño_rayo": ("mv_0221+0215", "c"), "puño_agua": ("mv_0221+0021", "cs"),
    "patada_fuego": ("rrt_blazekick", "c"), "colmillo_rayo": ("0152", "c"),
    "colmillo_veneno": ("rv_fang+rv_cross_end", "c"), "onda_trueno": ("0042", "c"),
    "rayo_hielo": ("0159@24", "s"), "rayo_solar": ("0222", "c"), "psicorrayo": ("0171", "c"),
    "bola_sombra": ("0196", "c"), "hojas_navaja": ("0076", "c"), "hoja_espada": ("0066", "c"),
    "latigo_liana": ("0131+0131/001", "c"), "semillas": ("0154", "s"), "drenar": ("0161", "c"),
    "giro_fuego": ("rrt_firespin", "c"), "fuego_fatuo": ("rrt_wisp_hit", "c"),
    "barro": ("rv_gunk2_br", "c"), "hidrobomba": ("0103", "c"), "remolino": ("remolino+0021", "s"),
    "cascada": ("0074", "s"), "burbujas": ("0096", "c"), "ola": ("0021", "s"), "lluvia": ("0257", "s"),
    "chorro_agua": ("0073", "c"), "niebla": ("0097", "c"), "ventisca": ("0205", "s"),
    "trueno": ("0018", "s"), "chispa": ("0119", "s"), "lanzallamas": ("rrt_flamethrower_hit", "c"),
    "llamarada": ("rrt_fireblast_hit", "s"), "magma": ("rrt_blastburn", "c"),
    "ascuas": ("rrt_ember_hit", "c"), "gas_veneno": ("rv_smog", "s"), "polvo": ("rv_powder", "s"),
    "lodo": ("rv_toxic", "c"), "aguijon": ("rv_cross_end", "c"), "veneno": ("rv_cross", "c"),
    "hilo": ("mv_0135_000", "c"), "terremoto": ("0114/001", "s", True), "excavar": ("0016+0114/001", "s"),
    "arena": ("0114", "c"), "piedras": ("rr_blast", "c"), "psiquico": ("0017", "c"),
    "confusion": ("0193", "c"), "hipnosis": ("0156", "c"), "mirada": ("0046", "c"),
    "maldicion": ("0163", "c"), "sombra": ("0201", "c"), "onda_sonido": ("0211", "c"),
    "dragon_garra": ("rd_rush", "c"), "rafaga": ("0258", "s"), "estrellas": ("0228", "c"),
    "destello": ("0087", "c"), "rayo_energia": ("0192", "c"), "esfera_energia": ("0209", "c"),
    "explosion": ("0010", "a"), "metal": ("0012", "c"), "puño": ("0180", "c"),
    "patada": ("0253+0253", "c"), "pisoton": ("0002", "s", True), "mordida": ("0122", "c"),
    "lamida": ("rg_lick", "s"), "picotazo": ("0207", "c"), "cuerno": ("0101*6", "c"),
    "arañazo": ("0050", "c"), "corte": ("0166", "c"), "cola": ("0149", "c"), "ala": ("0232", "c"),
    "constriccion": ("0085", "s"), "bofetada": ("0241", "c"), "giro": ("0143", "c"),
    "rapido": ("0177", "c"), "embestida": ("0140", "c"), "derrumbe": ("rr_slide+rr_blast", "sc"),
    "tumba": ("rr_tomb", "c"), "dragon_aliento": ("rd_rage_hit", "s"), "dragon_pulso": ("rd_pulse_hit", "c"),
    "furia_dragon": ("rd_outrage", "s"), "spacial_rend": ("rd_rend", "c"), "time_bellow": ("rd_time", "c"),
    "hueso": ("0242", "c"), "pincho": ("0076", "c"),
}


# --- Sonido por categoría: (familia de sonidos/golpes/, alcance) -> <familia>_<alcance>_<debil|fuerte>.ogg;
#     ("wrap", "") es un sonido propio (sonidos/golpes/wrap.ogg) ---
SONIDOS = {
    "puño_fuego": ("fuego", "fisico"), "puño_hielo": ("hielo", "fisico"), "puño_rayo": ("electrico", "fisico"),
    "puño_agua": ("agua", "fisico"), "patada_fuego": ("fuego", "fisico"), "colmillo_fuego": ("fuego", "fisico"),
    "colmillo_hielo": ("hielo", "fisico"), "colmillo_rayo": ("electrico", "fisico"), "colmillo_veneno": ("veneno", "fisico"),
    "onda_trueno": ("electrico", "distancia"), "rayo_hielo": ("hielo", "distancia"), "rayo_solar": ("planta", "distancia"),
    "psicorrayo": ("psiquico", "distancia"), "bola_sombra": ("fantasma", "distancia"), "hojas_navaja": ("planta", "distancia"),
    "hoja_espada": ("planta", "fisico"), "latigo_liana": ("planta", "fisico"), "semillas": ("planta", "distancia"),
    "drenar": ("planta", "distancia"), "giro_fuego": ("fuego", "distancia"), "fuego_fatuo": ("fantasma", "distancia"),
    "barro": ("tierra", "distancia"), "hidrobomba": ("agua", "distancia"), "remolino": ("agua", "distancia"),
    "cascada": ("agua", "fisico"), "burbujas": ("agua", "distancia"), "ola": ("agua", "distancia"),
    "lluvia": ("agua", "distancia"), "chorro_agua": ("agua", "distancia"), "niebla": ("hielo", "distancia"),
    "ventisca": ("hielo", "distancia"), "trueno": ("electrico", "distancia"), "chispa": ("electrico", "distancia"),
    "lanzallamas": ("fuego", "distancia"), "llamarada": ("fuego", "distancia"), "magma": ("fuego", "distancia"),
    "ascuas": ("fuego", "distancia"), "gas_veneno": ("veneno", "distancia"), "polvo": ("veneno", "distancia"),
    "lodo": ("veneno", "distancia"), "aguijon": ("veneno", "distancia"), "veneno": ("veneno", "fisico"),
    "hilo": ("wrap", ""), "terremoto": ("tierra", "fisico"), "excavar": ("tierra", "fisico"),
    "arena": ("tierra", "distancia"), "piedras": ("roca", "distancia"), "psiquico": ("psiquico", "distancia"),
    "confusion": ("psiquico", "distancia"), "hipnosis": ("psiquico", "distancia"), "mirada": ("fantasma", "distancia"),
    "maldicion": ("fantasma", "distancia"), "sombra": ("siniestro", "distancia"), "onda_sonido": ("normal", "distancia"),
    "dragon_garra": ("dragon", "fisico"), "rafaga": ("volador", "distancia"), "estrellas": ("normal", "distancia"),
    "destello": ("psiquico", "distancia"), "rayo_energia": ("normal", "distancia"), "esfera_energia": ("normal", "distancia"),
    "explosion": ("normal", "fisico"), "metal": ("acero", "fisico"), "puño": ("lucha", "fisico"),
    "patada": ("lucha", "fisico"), "pisoton": ("tierra", "fisico"), "mordida": ("siniestro", "fisico"),
    "lamida": ("fantasma", "fisico"), "picotazo": ("volador", "fisico"), "cuerno": ("normal", "fisico"),
    "arañazo": ("normal", "fisico"), "corte": ("normal", "fisico"), "cola": ("normal", "fisico"),
    "ala": ("volador", "fisico"), "constriccion": ("wrap", ""), "bofetada": ("normal", "fisico"),
    "giro": ("normal", "fisico"), "rapido": ("normal", "fisico"), "embestida": ("normal", "fisico"),
    "derrumbe": ("roca", "distancia"), "tumba": ("roca", "distancia"), "dragon_aliento": ("dragon", "distancia"),
    "dragon_pulso": ("dragon", "distancia"), "furia_dragon": ("dragon", "fisico"), "spacial_rend": ("dragon", "distancia"),
    "time_bellow": ("dragon", "distancia"), "hueso": ("tierra", "fisico"), "pincho": ("veneno", "distancia"),
}


def frames(n, g="000"):
    d = os.path.join(V, n, g)
    return [Image.open(os.path.join(d, f)).convert("RGBA") for f in sorted(os.listdir(d)) if f.endswith(".png")]


def ff(n, g="000"):
    return [f.crop(f.getbbox()) for f in frames(n, g) if f.getbbox()]


def piece(n, fi=0, g="000"):
    f = frames(n, g)[fi]
    return f.crop(f.getbbox())


def sz(im, w):
    return im.resize((w, max(1, im.height * w // im.width)), Image.NEAREST)


def union_box(fs):
    box = None
    for f in fs:
        b = f.getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box


def load_segments(spec):
    out = []
    for part in spec.split("+"):
        hold = 0
        if "*" in part:
            part, hold = part.split("*")
            hold = int(hold)
        start = 0
        if "@" in part:
            part, start = part.split("@")
            start = int(start)
        if part.startswith("mv_"):
            im = Image.open(os.path.join(OUT_FX, part + ".png")).convert("RGBA")
            cw, ch = json.load(open(os.path.join(OUT_FX, part + ".json")))["celda"]
            fs = [im.crop((i * cw, 0, i * cw + cw, ch)) for i in range(im.width // cw)]
        elif "/" in part:
            fs = frames(*part.split("/"))
        else:
            fs = frames(part)
        fs = fs[start:] + [fs[-1]] * hold
        box = union_box(fs)
        out.append([f.crop(box) for f in fs])
    return out


def slug(cat):
    return cat.replace("ñ", "n")


def build_hit(cat, spec):
    tramos, anc = spec[0], spec[1]
    temblor = len(spec) > 2 and spec[2]
    segs = load_segments(tramos)
    modes = [anc[min(i, len(anc) - 1)] for i in range(len(segs))]
    placed = []     # (imagen, x, y) con el centro del cuerpo en (0, 0)
    for seg, m in zip(segs, modes):
        for f in seg:
            if m == "s":
                placed.append((f, -(f.width // 2), PIE - f.height + 2))
            else:
                placed.append((f, -(f.width // 2), -(f.height // 2)))
    x0 = min(x for _, x, _ in placed)
    y0 = min(y for _, _, y in placed)
    x1 = max(x + f.width for f, x, _ in placed)
    y1 = max(y + f.height for f, _, y in placed)
    w, h = x1 - x0, y1 - y0
    w += w % 2
    h += h % 2
    strip = Image.new("RGBA", (w * len(placed), h))
    for i, (f, x, y) in enumerate(placed):
        strip.alpha_composite(f, (i * w + x - x0, y - y0))
    modo = {"c": "cuerpo", "s": "suelo", "a": "atacante"}
    all_ground = all(m == "s" for m in modes)
    ancla = [-x0, -y0 + (PIE if all_ground else 0)]
    name = "gx_" + slug(cat)
    strip.save(os.path.join(OUT_FX, name + ".png"))
    json.dump({"celda": [w, h], "ancla": ancla, "modo": "suelo" if all_ground else modo[modes[0]] if modes[0] == "a" else "cuerpo",
               "temblor": bool(temblor)}, open(os.path.join(OUT_FX, name + ".json"), "w"))
    return name


def rrt_frames(n, idx):
    fs = frames(n)[::2]
    return [fs[i].crop(fs[i].getbbox()) for i in idx if fs[i].getbbox()]


def proyectiles():
    """Lo que viaja: (cuadros, tipo, parámetros). Igual que en la maqueta."""
    leaf = ff("0129", "000")
    snow = piece("0129", 0, "004")
    drop = piece("0129", 3, "003")
    big_drop = drop.resize((drop.width * 3 // 2, drop.height * 3 // 2), Image.NEAREST)
    bub = piece("0129", 2, "008")
    spark = piece("0099", 3, "000")
    needle = Image.open(os.path.join(V, "rv_needle.png")).convert("RGBA")
    rocks = [Image.open(os.path.join(V, "rr_rock", "%d.png" % i)).convert("RGBA") for i in range(5)]
    br = [Image.open(os.path.join(V, "rd_parts", f)).convert("RGBA")
          for f in sorted(os.listdir(os.path.join(V, "rd_parts"))) if f.startswith("breath")]
    pu = [Image.open(os.path.join(V, "rd_parts", f)).convert("RGBA")
          for f in sorted(os.listdir(os.path.join(V, "rd_parts"))) if f.startswith("pulse")]
    ola = Image.open(os.path.join(OUT_FX, "ola.png")).convert("RGBA")
    ola = ola.crop((128, 0, 256, 128))
    ola = ola.crop(ola.getbbox())
    ola = ola.resize((ola.width * 2 // 5, ola.height * 2 // 5), Image.NEAREST)
    hilo = Image.new("RGBA", (3, 3), (240, 240, 240, 255))
    fb = rrt_frames("rrt_fireblast", range(0, 6))

    def c(frs, n=1, ondula=0, espacio=0.18, vel=0.0, desfase=0, tipo="chorro", alto=0, gira=False, tope=False):
        return {"frs": frs if isinstance(frs, list) else [frs], "tipo": tipo, "n": n, "ondula": ondula,
                "espacio": espacio, "vel": vel, "desfase": desfase, "alto": alto, "gira": gira, "tope": tope}

    return {
        "onda_trueno": c(spark, 3, 0, .2),
        "rayo_hielo": c(snow, 6, 2, .1),
        "rayo_solar": c(piece("0099", 4, "000"), 14, 0, .035),
        "psicorrayo": c(sz(piece("0171", 7), 12), 7, 0, .1),
        "bola_sombra": c(sz(ff("0203")[3], 16)),
        "hojas_navaja": c(leaf, 4, 3, .2, 30, 5),
        "semillas": c(ff("0212")[0], tipo="arco", alto=14, gira=True),
        "drenar": c(ff("0161")[1], 5, 3, .15, tipo="vuelta"),
        "giro_fuego": c(fb, vel=12),
        "fuego_fatuo": c(rrt_frames("rrt_wisp", range(0, 6)), 3, 5, .3, 15),
        "barro": c(ff("rv_sludge_br")[:2], 3, 2, .2, 6),
        "hidrobomba": c(big_drop, 14, 0, .035),
        "burbujas": c(bub, 5, 4, .2),
        "ola": c(ola, tipo="ola"),
        "chorro_agua": c(drop, 8, 0, .08),
        "niebla": c(piece("0097", 3)),
        "ventisca": c(snow, 12, 6, .06),
        "chispa": c(spark, 2, 0, .3),
        "lanzallamas": c(rrt_frames("rrt_flamethrower", [0, 1, 2, 4, 6, 7, 8]), 6, 1, .1, 20, 1),
        "llamarada": c(fb, vel=12),
        "ascuas": c(rrt_frames("rrt_ember", range(0, 5)), 3, 2, .3, 4.9, tope=True),
        "gas_veneno": c(ff("rv_smog")[:3], 3, 2, .25, 3, tope=True),
        "lodo": c(ff("rv_acid"), 2, 2, .3, 8),
        "aguijon": c(needle),
        "hilo": c(hilo, 16, 1, .03),
        "arena": c(ff("0114")[0], 6, 3, .12),
        "piedras": c(rocks, tipo="arco", alto=18, vel=12),
        "hipnosis": c(sz(piece("0178", 3), 16), 3, 3, .25),
        "onda_sonido": c(sz(ff("0020")[2], 10), 4, 0, .2),
        "estrellas": c(sz(ff("0077")[1], 10), 5, 3, .15),
        "rayo_energia": c(sz(ff("0113")[3].rotate(90, expand=True), 10), 14, 0, .035),
        "esfera_energia": c(sz(ff("0175")[12], 14)),
        "rapido": c(piece("0106", 0, "002"), 3, 0, .08),
        "dragon_aliento": c(br, 4, 1, .15, 14, 1),
        "dragon_pulso": c(pu, vel=20),
        "hueso": c(ff("0011"), tipo="arco", alto=12, vel=16),
        "pincho": c(needle, 4, 2, .15),
    }


def build_proj(cat, p):
    frs = p.pop("frs")
    w = max(f.width for f in frs)
    h = max(f.height for f in frs)
    w += w % 2
    h += h % 2
    strip = Image.new("RGBA", (w * len(frs), h))
    for i, f in enumerate(frs):
        strip.alpha_composite(f, (i * w + (w - f.width) // 2, (h - f.height) // 2))
    name = "px_" + slug(cat)
    strip.save(os.path.join(OUT_FX, name + ".png"))
    p["celda"] = [w, h]
    p["cuadros"] = len(frs)
    json.dump(p, open(os.path.join(OUT_FX, name + ".json"), "w"))
    return name


def main():
    global V
    V = sys.argv[1]
    ataques = json.load(open(sys.argv[2]))
    cats = {}
    for cat, spec in GOLPES.items():
        cats[cat] = {"golpe": build_hit(cat, spec), "proyectil": ""}
    for cat, (fam, alc) in SONIDOS.items():
        if cat in cats:
            cats[cat]["sonido"] = fam if alc == "" else "%s_%s" % (fam, alc)
    for cat, p in proyectiles().items():
        cats[cat]["proyectil"] = build_proj(cat, p)
    mapa = {}
    for name, cat in sorted(ataques.items()):
        if cat in cats:
            mapa[name.lower()] = cat
    json.dump({"_ayuda": "Generado por tools/efectos_por_nombre.py desde la hoja 'Efectos de ataque por nombre'.",
               "ataques": mapa, "categorias": cats},
              open(OUT_DATA, "w"), ensure_ascii=False, indent=1, sort_keys=True)
    print(len(cats), "categorías,", len(mapa), "ataques")


if __name__ == "__main__":
    main()
