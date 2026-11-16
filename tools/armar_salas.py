"""Arma las salas nuevas de la escuela: la biblioteca y la oficina del director.

Usa como base dos cuartos de la hoja de interiores de Rubí/Zafiro/Esmeralda (1920x2864, fondo
a cuadros rosa y verde) y les agrega muebles de dos hojas de objetos:
  - "POKémapPARTS" de TimmY (fondo blanco, 712x295)
  - objetos de Rubí/Zafiro de Bacon (fondo negro, 454x462)
La alfombra de la salida sale de mundo/propios/escuela_rustboro.png (tools/armar_escuela.py).

Uso: python3 tools/armar_salas.py interiores.png objetos_timmy.png objetos_bacon.png [carpeta_salida]
Salen mundo/propios/biblioteca_escuela.png (20x12) y oficina_director.png (12x9). Las hojas no van en el repo.
Los mapas que las usan son data/mapas/biblioteca.json y data/mapas/oficina.json: si movés algo
acá, cambiá también las letras de "baldosas" para que coincidan.
"""
import os
import sys
from PIL import Image

T = 16
LIBRARY = (352, 1672, 320, 176)    # Instituto Meteorológico, 2.º piso (20x11): estantes y mesas
OFFICE = (672, 664, 304, 144)      # oficina del presidente de Devon (19x9)
OFFICE_COLS = [0, 1, 2, 3, 4, 12, 13, 14, 15, 16, 17, 18]   # columnas que se usan

# Objetos: (x, y, ancho, alto) en su hoja
TIMMY = {
    "estante_verde": (607, 13, 32, 29),
    "estante_blanco": (519, 80, 32, 31),
    "maceta_chica": (630, 50, 16, 15),
}
BACON = {
    "vitrina_trofeos": (239, 163, 24, 40),
    "diploma": (201, 145, 26, 23),
    "arbolito": (159, 177, 16, 30),
}


def cut(sheet, box, bg):
    """Recorta un objeto y borra el fondo que lo rodea (relleno desde los bordes)."""
    x, y, w, h = box
    im = sheet.crop((x - 1, y - 1, x + w + 1, y + h + 1)).convert("RGBA")
    px = im.load()
    W, H = im.size
    stack = [(i, j) for i in range(W) for j in (0, H - 1)] + [(i, j) for j in range(H) for i in (0, W - 1)]
    seen = set()
    while stack:
        i, j = stack.pop()
        if (i, j) in seen or not (0 <= i < W and 0 <= j < H):
            continue
        seen.add((i, j))
        if px[i, j][:3] == bg:
            px[i, j] = (0, 0, 0, 0)
            stack += [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)]
    return im.crop((1, 1, W - 1, H - 1))


def put(img, obj, tx, ty_bottom, dx=0, dy=0):
    """Apoya el objeto con su base en el borde de abajo de la casilla ty_bottom, desde la columna tx."""
    x = tx * T + dx + max(0, (((obj.width + T - 1) // T) * T - obj.width) // 2)
    y = (ty_bottom + 1) * T - obj.height + dy
    img.alpha_composite(obj, (x, y))


def room(sheet, box, extra_rows, copy_row):
    x, y, w, h = box
    base = sheet.crop((x, y, x + w, y + h)).convert("RGBA")
    out = Image.new("RGBA", (w, h + extra_rows * T))
    out.paste(base, (0, 0))
    row = base.crop((0, copy_row * T, w, (copy_row + 1) * T))
    for i in range(extra_rows):
        out.paste(row, (0, h + i * T))
    return out


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    inter = Image.open(sys.argv[1]).convert("RGB")
    timmy = Image.open(sys.argv[2]).convert("RGB")
    bacon = Image.open(sys.argv[3]).convert("RGB")
    here = os.path.dirname(os.path.abspath(__file__))
    dst = sys.argv[4] if len(sys.argv) > 4 else os.path.join(here, "..", "mundo", "propios")
    school = Image.open(os.path.join(dst, "escuela_rustboro.png")).convert("RGBA")
    rug = school.crop((8 * T, 15 * T, 10 * T, 16 * T))          # la alfombra de la puerta del aula
    o = {k: cut(timmy, b, (255, 255, 255)) for k, b in TIMMY.items()}
    o.update({k: cut(bacon, b, (0, 0, 0)) for k, b in BACON.items()})

    # Biblioteca: 20x12 (una fila más abajo, con la alfombra para volver al aula)
    lib = room(inter, LIBRARY, 1, 6)
    lib.paste(rug, (9 * T, 11 * T))
    put(lib, o["estante_blanco"], 17, 5)
    put(lib, o["estante_verde"], 17, 8)
    put(lib, o["arbolito"], 19, 2)
    put(lib, o["arbolito"], 19, 10)
    put(lib, o["maceta_chica"], 3, 10)
    lib.convert("RGB").save(os.path.join(dst, "biblioteca_escuela.png"))

    # Oficina del director: chica (12x9). De la oficina de Devon se toman las columnas de la
    # puerta y las vitrinas (0-4) y las del escritorio chico (12-18), y las filas 0-7;
    # abajo, una fila de piso con la alfombra para bajar a la biblioteca.
    x, y, w, h = OFFICE
    src = inter.crop((x, y, x + w, y + h)).convert("RGBA")
    cols = OFFICE_COLS
    off = Image.new("RGBA", (len(cols) * T, 9 * T))
    for i, c in enumerate(cols):
        off.paste(src.crop((c * T, 0, (c + 1) * T, 8 * T)), (i * T, 0))
        off.paste(src.crop((c * T, 8 * T, (c + 1) * T, 9 * T)), (i * T, 8 * T))
    off.paste(rug, (5 * T, 8 * T))
    put(off, o["vitrina_trofeos"], 6, 2)
    put(off, o["estante_verde"], 8, 2, dx=-4)
    put(off, o["arbolito"], 11, 2)
    put(off, o["arbolito"], 0, 7)
    put(off, o["diploma"], 4, 1, dx=2, dy=-6)
    off.convert("RGB").save(os.path.join(dst, "oficina_director.png"))
    print("biblioteca_escuela.png y oficina_director.png ->", os.path.abspath(dst))


if __name__ == "__main__":
    main()
