"""Arma el patio de duelos de la escuela con las baldosas de exteriores de Esmeralda (la hoja
de "Tilesets ripped from Pokemon Emerald": 11 columnas de 128 píxeles). Usa el pasto, los
árboles y las flores del tileset general, la arena para las canchas y el techo azul de
Ciudad Férrica para la escuela. Las alfombras de las puertas se dibujan encima (son las de
tools/make_patio.py). Las mesas de duelo y los bancos salen de la hoja de piezas
"POKémapPARTS" (la mesa larga con tapete verde y el banco largo de madera); sin esa hoja, se usan
los dibujados de tools/make_patio.py.

Uso:
    python3 tools/armar_patio.py hoja_exteriores.png [salida.png] [--piezas pokemapparts.png]
Salida por defecto: mundo/propios/patio_escuela.png (tiene prioridad sobre el patio original
de mundo/fondos/ y no se reparte con el código).

El mapa que la usa es data/mapas/patio.json (las letras de "baldosas" tienen que coincidir
con LAYOUT de tools/make_patio.py).
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_patio as mp

T = 16
GRASS = [(1, 0), (1, 0)]
FLOWERS = (4, 0)
TREE_TOP, TREE_BOTTOM = (6, 1), (6, 2)
SAND = {  # arena con borde redondeado sobre pasto (3x3)
    "tl": (0, 35), "t": (1, 35), "tr": (2, 35),
    "l": (0, 36), "c": (1, 36), "r": (2, 36),
    "bl": (0, 37), "b": (1, 37), "br": (2, 37),
}
# Piezas de la hoja POKémapPARTS (712x295): caja (x0, y0, x1, y1) sobre fondo blanco
PIEZA_MESA = (447, 119, 491, 150)      # mesa larga con tapete verde, 44x31 (3 casillas)
PIEZA_BANCO = (506, 50, 554, 66)       # banco largo de madera, 48x16 (3 casillas)
ROOF = {"top": [(29, 4), (30, 4), (31, 4)], "mid": [(29, 5), (30, 5), (31, 5)]}


def main():
    args = sys.argv[1:]
    parts = None
    if "--piezas" in args:
        i = args.index("--piezas")
        parts = Image.open(args[i + 1]).convert("RGBA")
        del args[i:i + 2]
    if len(args) < 1:
        print(__doc__)
        sys.exit(1)
    sys.argv = [sys.argv[0]] + args
    sheet = Image.open(sys.argv[1]).convert("RGB")
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "patio_escuela.png")
    L = mp.LAYOUT
    rows, cols = len(L), len(L[0])
    img = Image.new("RGB", (cols * T, rows * T))

    def tile(c, r):
        return sheet.crop((c * T, r * T, (c + 1) * T, (r + 1) * T))

    def put(tc, x, y):
        img.paste(tile(*tc), (x * T, y * T))

    # Pasto y flores
    for y in range(rows):
        for x in range(cols):
            put(GRASS[(x * 7 + y * 13) % 5 == 0], x, y)
            if L[y][x] == "f":
                put(FLOWERS, x, y)

    def sand_rect(x0, y0, w, h):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                v = "t" if y == y0 else ("b" if y == y0 + h - 1 else "")
                hz = "l" if x == x0 else ("r" if x == x0 + w - 1 else "")
                key = (v + hz) if (v or hz) else "c"
                put(SAND[key], x, y)

    # Canchas de arena y caminitos hasta las alfombras
    for x0 in (2, 11):
        sand_rect(x0, 3, 7, 7)
    for x0 in (4, 14):
        sand_rect(x0, 10, 2, 2)
    # Líneas blancas de las canchas: borde, mitad y círculo del medio
    import math
    line = (248, 248, 240)

    def rect(x, y, w, h):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                img.putpixel((xx, yy), line)
    for x0 in (2, 11):
        x, y, w, h = x0 * T, 3 * T, 7 * T, 7 * T
        for yy in (y + 6, y + h - 8):
            rect(x + 6, yy, w - 12, 2)
        for xx in (x + 6, x + w - 8):
            rect(xx, y + 6, 2, h - 12)
        rect(x + 6, y + h // 2 - 1, w - 12, 2)
        for a in range(0, 360, 2):
            rect(int(round(x + w / 2 + 20 * math.cos(math.radians(a)))), int(round(y + h / 2 + 20 * math.sin(math.radians(a)))), 2, 2)
    # Árboles: arriba de todo y a los costados (cada árbol ocupa 1x2)
    for x in range(cols):
        put(TREE_TOP, x, 0)
        put(TREE_BOTTOM, x, 1)
    for x in (0, 1, cols - 2, cols - 1):
        for y in range(2, rows - 1, 2):
            put(TREE_TOP, x, y)
            put(TREE_BOTTOM, x, y + 1)
        put(TREE_TOP, x, rows - 1)
    # Techo de la escuela (abajo)
    for i, x in enumerate(range(2, cols - 2)):
        k = 0 if x == 2 else (2 if x == cols - 3 else 1)
        put(ROOF["top"][k], x, rows - 2)
        put(ROOF["mid"][k], x, rows - 1)
    # Alfombras (y mesas y bancos si no hay hoja de piezas): el dibujo de make_patio, pegado
    # encima sin su fondo
    drawn = Image.open(os.path.join(os.path.dirname(__file__), "..", "mundo", "fondos", "patio_escuela.png")).convert("RGB")
    plain = mp_background()
    copy = "D" if parts is not None else "MBD"
    if parts is not None:
        mesa, banco = pieza(parts, PIEZA_MESA), pieza(parts, PIEZA_BANCO)
        for letter, img_p in (("M", mesa), ("B", banco)):
            for x0, y0, w in grupos(L, letter):
                if y0 + 1 < len(L) and L[y0 + 1][x0] == letter:
                    continue           # la pieza se apoya en la fila de abajo del mueble
                # centrada en las casillas, apoyada en el borde de abajo
                px0 = x0 * T + (w * T - img_p.width) // 2
                py0 = (y0 + 1) * T - img_p.height
                base = img.convert("RGBA")
                base.alpha_composite(img_p, (px0, py0))
                img = base.convert("RGB")
    for y in range(rows):
        for x in range(cols):
            if L[y][x] in copy:
                box = (x * T, (y - (1 if L[y][x] == "M" else 0)) * T, (x + 1) * T, (y + 1) * T)
                a = drawn.crop(box)
                b = plain.crop(box)
                pa, pb = a.load(), b.load()
                for yy in range(a.height):
                    for xx in range(a.width):
                        if pa[xx, yy] != pb[xx, yy]:
                            img.putpixel((box[0] + xx, box[1] + yy), pa[xx, yy])
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    img.save(out_path)
    print("Patio %dx%d -> %s" % (cols, rows, os.path.abspath(out_path)))


def pieza(hoja, caja):
    """Recorta una pieza de la hoja y vuelve transparente el blanco que la rodea (solo el de
    afuera: los brillos blancos de adentro quedan)."""
    c = hoja.crop(caja).convert("RGBA")
    p = c.load()
    w, h = c.size
    pend = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    seen = set()
    while pend:
        x, y = pend.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        r, g, b, a = p[x, y]
        if a > 0 and not (r > 245 and g > 245 and b > 245):
            continue
        seen.add((x, y))
        p[x, y] = (0, 0, 0, 0)
        pend += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return c


def grupos(L, letter):
    """Tramos horizontales de una letra en el mapa: [(x0, y, ancho), ...]."""
    out = []
    for y, row in enumerate(L):
        x = 0
        while x < len(row):
            if row[x] == letter:
                x0 = x
                while x < len(row) and row[x] == letter:
                    x += 1
                out.append((x0, y, x - x0))
            else:
                x += 1
    return out


def mp_background():
    """El patio de make_patio sin mesas, bancos ni alfombras (para saber qué es dibujo)."""
    saved = mp.LAYOUT
    mp.LAYOUT = [r.replace("M", "_").replace("B", ",").replace("D", ",") for r in saved]
    tmp = os.path.join(os.path.dirname(os.path.abspath(mp.OUT)), "_patio_sin_cosas.png")
    old_out = mp.OUT
    mp.OUT = tmp
    try:
        mp.main(objects=False)
        return Image.open(tmp).convert("RGB")
    finally:
        mp.OUT = old_out
        mp.LAYOUT = saved
        if os.path.exists(tmp):
            os.remove(tmp)


if __name__ == "__main__":
    main()
