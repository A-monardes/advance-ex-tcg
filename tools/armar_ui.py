"""Prepara las piezas de interfaz al estilo Rubí/Zafiro a partir de capturas (de cualquier
tamaño: detecta solo la grilla de píxeles y las vuelve a su tamaño de GBA).

Uso:
    python3 tools/armar_ui.py --equipo equipo.png --estados estados.png --flores flores.png
                              [--destino carpeta]
Cada imagen es opcional (se arma lo que se pueda). Destino por defecto: mundo/propios/ui/
(no se reparte con el código). Escribe:

  --equipo   la pantalla de equipo ("Choose a POKéMON."):
     marco.png + marco.json   el cuadro de texto de abajo (borde lila con esquinas redondeadas):
                              lo usan todos los cuadros de texto y menús del juego, estirado
                              como un "9-slice" ({"borde": píxeles de cada esquina})
     fondo.png                dos filas del fondo a rayas (las pantallas enteras: la ficha de
                              una carta, la mano, el registro, el resultado...)
  --estados  las "pastillas" de estado (PSN, PAR, SLP, BRN, FRZ, PkRS, FNT):
     estado_psn.png, estado_par.png, estado_slp.png, estado_brn.png  (20x8)
     estado_cnf.png  Confundido: no existe en los juegos; se arma con la forma de FRZ en
                     verde agua y las letras C N F en la misma tipografía
  --flores   la tira de 3 flores que se mueven:
     flor.png  3 cuadros de 16x16 (fondo blanco -> transparente), para las flores del
               patio cuando sopla el viento
"""
import json
import os
import sys

import numpy as np
from PIL import Image


# ---------------------------------------------------------------------------
# Grilla de píxeles
# ---------------------------------------------------------------------------

def _edges(a, axis):
    if axis == 1:
        d = np.any(a[:, 1:] != a[:, :-1], axis=2).sum(0)
    else:
        d = np.any(a[1:] != a[:-1], axis=2).sum(1)
    pos = np.flatnonzero(d)
    return pos + 1, d[pos]


def _score(pos, w, s, step=0.05):
    best = None
    for off in np.arange(0, s, step):
        r = np.mod(pos - off, s)
        r = np.minimum(r, s - r)
        sc = (r * w).sum() / w.sum()          # distancia media (en píxeles de la captura)
        if best is None or sc < best[0]:
            best = (sc, off)
    return best


def _fit(pos, w, lo, hi, step):
    best = None
    for s in np.arange(lo, hi, step):
        sc, off = _score(pos, w, s)
        if best is None or sc < best[0]:
            best = (sc, s, off)
    return best


def nativo(path):
    """La imagen a su tamaño original (un píxel de GBA = un píxel)."""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    px, wx = _edges(a[..., :3], 1)
    py, wy = _edges(a[..., :3], 0)
    # La escala más grande que explica bien todos los bordes (de 1x a 8x)
    cands = []
    for s in np.arange(1.0, 8.0, 0.05):
        sc, off = _score(px, wx, s, 0.1)
        cands.append((s, sc))
    good = [s for s, sc in cands if sc < 0.35]
    guess = max(good) if good else min(cands, key=lambda c: c[1])[0]
    _, sx, ox = _fit(px, wx, guess - 0.06, guess + 0.06, 0.0025)
    _, sy, oy = _fit(py, wy, sx * 0.995, sx * 1.005, 0.0005)
    nw = int((a.shape[1] - ox) / sx)
    nh = int((a.shape[0] - oy) / sy)
    out = np.zeros((nh, nw, 4), np.uint8)
    for j in range(nh):
        for i in range(nw):
            out[j, i] = a[min(a.shape[0] - 1, int(oy + (j + 0.5) * sy)), min(a.shape[1] - 1, int(ox + (i + 0.5) * sx))]
    print("  %s: escala %.3f -> %dx%d" % (os.path.basename(path), sx, nw, nh))
    return Image.fromarray(out, "RGBA")


def _cerca(c, ref, tol=24):
    return sum(abs(int(c[k]) - ref[k]) for k in range(3)) <= tol


# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

BORDE_OSCURO = (40, 48, 48)
BLANCO = (248, 248, 248)


def marco_y_fondo(img, dest):
    """El cuadro de texto de abajo a la izquierda y las rayas del fondo."""
    a = img.convert("RGB")
    w, h = a.size
    # Buscar el cuadro: la fila de borde oscuro más baja que cruza más de media pantalla
    px = a.load()
    box = None
    for y in range(h - 1, h // 2, -1):
        xs = [x for x in range(w) if _cerca(px[x, y], BORDE_OSCURO, 12)]
        if len(xs) > w * 0.5:
            # el borde de abajo del cuadro; ahora el de arriba (misma columna, subiendo)
            cx = (xs[0] + xs[-1]) // 2
            y0 = y - 1
            while y0 > 0 and not _cerca(px[cx, y0], BORDE_OSCURO, 12):
                y0 -= 1
            ym = (y0 + y) // 2
            x0 = cx
            while x0 > 0 and not _cerca(px[x0, ym], BORDE_OSCURO, 12):
                x0 -= 1
            x1 = cx
            while x1 + 1 < w and not _cerca(px[x1, ym], BORDE_OSCURO, 12):
                x1 += 1
            box = (x0, y0, x1, y)
            break
    if box is None:
        print("  no encontré el cuadro de texto")
        return
    x0, y0, x1, y1 = box
    c = 7                                   # esquina: borde de 4 + la curva de adentro
    m = Image.new("RGBA", (2 * c + 1, 2 * c + 1), (0, 0, 0, 0))
    crop = img.crop((x0, y0, x1 + 1, y1 + 1)).convert("RGBA")
    cw, ch = crop.size
    m.paste(crop.crop((0, 0, c, c)), (0, 0))
    m.paste(crop.crop((cw - c, 0, cw, c)), (c + 1, 0))
    m.paste(crop.crop((0, ch - c, c, ch)), (0, c + 1))
    m.paste(crop.crop((cw - c, ch - c, cw, ch)), (c + 1, c + 1))
    mx, my = cw // 2, ch // 2
    m.paste(crop.crop((mx, 0, mx + 1, c)), (c, 0))
    m.paste(crop.crop((mx, ch - c, mx + 1, ch)), (c, c + 1))
    m.paste(crop.crop((0, my, c, my + 1)), (0, c))
    m.paste(crop.crop((cw - c, my, cw, my + 1)), (c + 1, c))
    m.putpixel((c, c), BLANCO + (255,))
    # Esquinas de afuera redondeadas: lo que está antes del borde oscuro, transparente
    mp = m.load()
    n = 2 * c + 1
    for yy in list(range(c)) + list(range(c + 1, n)):
        for lado in (range(0, c), range(n - 1, c, -1)):
            for xx in lado:
                if _cerca(mp[xx, yy], BORDE_OSCURO, 12):
                    break
                mp[xx, yy] = (0, 0, 0, 0)
    # En los bordes rectos, lo que queda más adentro del borde es interior blanco (ahí
    # podría haber quedado un pedacito de letra)
    for k in range(5, c):
        m.putpixel((c, k), BLANCO + (255,))
        m.putpixel((c, 2 * c - k), BLANCO + (255,))
        m.putpixel((k, c), BLANCO + (255,))
        m.putpixel((2 * c - k, c), BLANCO + (255,))
    m.save(os.path.join(dest, "marco.png"))
    with open(os.path.join(dest, "marco.json"), "w") as f:
        json.dump({"borde": c, "relleno": 4}, f)
    print("  marco.png (cuadro de %dx%d)" % (cw, ch))
    # Fondo a rayas: los dos colores más comunes justo arriba del cuadro (filas alternadas)
    from collections import Counter
    cnt = Counter()
    for y in range(max(0, y0 - 24), y0 - 2):
        for x in range(x0 + 8, min(w, x0 + 60)):
            cnt[px[x, y]] += 1
    dos = [c for c, _ in cnt.most_common(2)]
    if len(dos) == 2:
        # qué color va en las filas pares
        par = Counter(px[x0 + 20, y] for y in range(max(0, y0 - 24), y0 - 2) if y % 2 == 0).most_common(1)[0][0]
        otro = dos[1] if dos[0] == par else dos[0]
        f = Image.new("RGBA", (8, 2))
        for xx in range(8):
            f.putpixel((xx, 0), par + (255,))
            f.putpixel((xx, 1), otro + (255,))
        f.save(os.path.join(dest, "fondo.png"))
        print("  fondo.png", par, otro)


# C, N y F de 4x6 (la N y la F se toman de las pastillas; la C no existe en ninguna)
LETRA_C = [".##.", "#..#", "#...", "#...", "#..#", ".##."]


def _pastillas(img):
    """[(caja)] de cada pastilla: tiras de 8 de alto separadas por el fondo."""
    a = np.asarray(img.convert("RGB")).astype(int)
    bg = a[0, 0]
    mask = np.abs(a - bg).sum(2) > 30
    out = []
    h, w = mask.shape
    for y0 in range(0, h - 7, 8):
        band = mask[y0:y0 + 8]
        cols = band.any(0)
        x = 0
        while x < w:
            if cols[x]:
                x1 = x
                while x1 + 1 < w and cols[x1 + 1]:
                    x1 += 1
                if x1 - x >= 10:
                    out.append((x, y0, x1 + 1, y0 + 8))
                x = x1 + 1
            else:
                x += 1
    return out


def estados(img, dest):
    boxes = _pastillas(img)
    # Orden de la hoja: PSN, PAR, SLP, FRZ arriba; BRN, PkRS, FNT abajo
    arriba = [b for b in boxes if b[1] == min(bb[1] for bb in boxes)]
    abajo = [b for b in boxes if b not in arriba]
    names = dict(zip(["psn", "par", "slp", "frz"], arriba))
    names.update(dict(zip(["brn", "pkrs", "fnt"], abajo)))
    piezas = {}
    for k, b in names.items():
        p = img.crop(b).convert("RGBA")
        bg = p.getpixel((0, 0))
        px = p.load()
        for y in range(p.height):
            for x in range(p.width):
                if _cerca(px[x, y], bg[:3], 30):
                    px[x, y] = (0, 0, 0, 0)
        # recorte justo a la pastilla
        bb = p.getbbox()
        p = p.crop(bb)
        piezas[k] = p
        if k in ("psn", "par", "slp", "brn"):
            p.save(os.path.join(dest, "estado_%s.png" % k))
            print("  estado_%s.png %dx%d" % (k, p.width, p.height))
    if "frz" in piezas and "psn" in piezas:
        cnf = _pastilla_cnf(piezas["frz"], piezas["psn"])
        cnf.save(os.path.join(dest, "estado_cnf.png"))
        print("  estado_cnf.png %dx%d (armada)" % cnf.size)


def _letras(p):
    """Columnas de letras blancas de una pastilla: [(x0, x1)]."""
    px = p.load()
    cols = [any(_cerca(px[x, y], BLANCO, 12) and px[x, y][3] > 0 for y in range(p.height)) for x in range(p.width)]
    out = []
    x = 0
    while x < p.width:
        if cols[x]:
            x1 = x
            while x1 + 1 < p.width and cols[x1 + 1]:
                x1 += 1
            out.append((x, x1))
            x = x1 + 1
        else:
            x += 1
    return out


def _pastilla_cnf(frz, psn):
    base = frz.copy()
    px = base.load()
    # Teñir de verde agua (manteniendo los dos tonos: el de las esquinas y el del cuerpo)
    tonos = {}
    for y in range(base.height):
        for x in range(base.width):
            r, g, b, a = px[x, y]
            if a == 0 or _cerca((r, g, b), BLANCO, 12):
                continue
            lum = (r + g + b) / 3.0
            tonos[(r, g, b)] = lum
    claro = max(tonos, key=tonos.get)
    cuerpo = min(tonos, key=tonos.get)
    nuevo = {claro: (120, 208, 184), cuerpo: (72, 176, 152)}
    letras_frz = _letras(base)
    for y in range(base.height):
        for x in range(base.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if _cerca((r, g, b), BLANCO, 12):
                px[x, y] = nuevo[cuerpo] + (255,)
            elif (r, g, b) in nuevo:
                px[x, y] = nuevo[(r, g, b)] + (255,)
    # Letras: C (dibujada), N (de PSN), F (de FRZ), en las mismas columnas que F R Z
    f_cols = letras_frz[0]
    lps = _letras(psn)
    n_cols = lps[-1]
    top = 1
    xs = [c[0] for c in letras_frz[:3]] if len(letras_frz) >= 3 else [4, 9, 14]
    for j, row in enumerate(LETRA_C):
        for i, ch in enumerate(row):
            if ch == "#":
                px[xs[0] + i, top + j] = BLANCO + (255,)
    pp = psn.load()
    for y in range(psn.height):
        for x in range(n_cols[0], n_cols[1] + 1):
            if _cerca(pp[x, y], BLANCO, 12):
                px[xs[1] + x - n_cols[0], y] = BLANCO + (255,)
    fp = frz.load()
    for y in range(frz.height):
        for x in range(f_cols[0], f_cols[1] + 1):
            if _cerca(fp[x, y], BLANCO, 12):
                px[xs[2] + x - f_cols[0], y] = BLANCO + (255,)
    return base


def flores(img, dest):
    a = img.convert("RGBA")
    px = a.load()
    for y in range(a.height):
        for x in range(a.width):
            r, g, b, al = px[x, y]
            if r > 240 and g > 240 and b > 240:
                px[x, y] = (0, 0, 0, 0)
    # Separar las flores por columnas vacías
    cols = [any(px[x, y][3] > 0 for y in range(a.height)) for x in range(a.width)]
    grupos = []
    x = 0
    while x < a.width:
        if cols[x]:
            x1 = x
            while x1 + 1 < a.width and cols[x1 + 1]:
                x1 += 1
            grupos.append((x, x1))
            x = x1 + 1
        else:
            x += 1
    # Columnas que se tocan (hojas que se pegan): repartir en 3 partes iguales
    if len(grupos) != 3:
        paso = a.width / 3.0
        grupos = [(round(i * paso), round((i + 1) * paso) - 1) for i in range(3)]
    tira = Image.new("RGBA", (16 * len(grupos), 16), (0, 0, 0, 0))
    for i, (x0, x1) in enumerate(grupos):
        f = a.crop((x0, 0, x1 + 1, a.height))
        bb = f.getbbox()
        f = f.crop(bb)
        tira.alpha_composite(f, (i * 16 + (16 - f.width) // 2, 15 - f.height))
    tira.save(os.path.join(dest, "flor.png"))
    print("  flor.png %d cuadros de 16x16" % len(grupos))


def main():
    args = sys.argv[1:]
    opts = {}
    dest = os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "ui")
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            opts[args[i][2:]] = args[i + 1]
            i += 2
        else:
            i += 1
    if "destino" in opts:
        dest = opts.pop("destino")
    if not opts:
        print(__doc__)
        sys.exit(1)
    os.makedirs(dest, exist_ok=True)
    if "equipo" in opts:
        marco_y_fondo(nativo(opts["equipo"]), dest)
    if "estados" in opts:
        estados(nativo(opts["estados"]), dest)
    if "flores" in opts:
        flores(nativo(opts["flores"]), dest)
    print("->", os.path.abspath(dest))


if __name__ == "__main__":
    main()
