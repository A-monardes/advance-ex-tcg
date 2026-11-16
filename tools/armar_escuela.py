"""Arma el fondo de la Escuela de Entrenadores grande (18x16 casillas) a partir de la hoja
de interiores de Rubí/Zafiro/Esmeralda que tengas (la que tiene "Rustboro City"), usando
las piezas de la escuela original de 12x11: paredes, puertas del fondo, pizarrón, pupitres,
escritorio y alfombra (y una maceta del cuarto de al lado).

Uso:
    python3 tools/armar_escuela.py hoja_interiores.png [salida.png]
Salida por defecto: mundo/propios/escuela_rustboro.png (no se reparte con el código).

El mapa que la usa es data/mapas/escuela.json: si cambiás algo acá (dónde van los pupitres,
las macetas...), cambiá también las letras de "baldosas" para que coincidan.
"""
import os
import sys
from PIL import Image

T = 16
SRC = (1136, 456, 1328, 632)      # la escuela original en la hoja (12x11 casillas)
PLANT = (1344, 584, 1360, 616)     # maceta del cuarto de al lado (1x2 casillas)
PLANT_FLOOR = {(136, 136, 136), (216, 208, 80), (176, 176, 160)}
COLS, ROWS = 18, 16

# Pared (filas 0-3): qué columna de la escuela original va en cada columna nueva.
# 0 borde izq · 1-2 puerta · 3 columna con reloj · 4-7 pizarrón · 8 columna · 9-10 puerta · 11 borde der
WALL = [0, 1, 2, 3, 8, 8, 8, 4, 5, 6, 7, 8, 8, 8, 8, 9, 10, 11]
DESK_COLS = [2, 4, 6, 11, 13, 15]          # pupitres (con su silla abajo)
DESK_ROWS = [5, 8, 11]                     # con una fila libre entre cada hilera para pasar
BOOK_DESKS = {(4, 5), (13, 8)}             # pupitres con un libro abierto
TEACHER_DESK = (8, 4)                      # escritorio del maestro (2 casillas)
RUG = (8, 15)                              # alfombra de la entrada (2 casillas): va a la tienda
RUG_LIBRARY = (3, 15)                      # alfombra que va a la biblioteca
PLANTS = [(1, 14), (16, 14), (5, 3), (12, 3)]   # macetas (casilla de arriba de las 2)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    sheet = Image.open(sys.argv[1]).convert("RGBA")
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "escuela_rustboro.png")
    src = sheet.crop(SRC)
    floor = src.crop((5 * T, 7 * T, 6 * T, 8 * T))          # baldosa de piso limpia
    floor_l = src.crop((0, 7 * T, T, 8 * T))                 # piso con la sombra de la pared izquierda
    floor_r = src.crop((11 * T, 7 * T, 12 * T, 8 * T))

    def tile(c, r):
        return src.crop((c * T, r * T, (c + 1) * T, (r + 1) * T))

    def obj(box):
        """Recorta un objeto de la escuela original sacando el piso que tiene alrededor."""
        x0, y0, x1, y1 = box
        im = src.crop(box)
        fp = floor.load()
        p = im.load()
        for y in range(im.height):
            for x in range(im.width):
                if p[x, y][:3] == fp[(x0 + x) % T, (y0 + y) % T][:3]:
                    p[x, y] = (0, 0, 0, 0)
        return im

    img = Image.new("RGBA", (COLS * T, ROWS * T), (0, 0, 0, 255))
    # Piso
    for r in range(4, ROWS):
        for c in range(COLS):
            img.paste(floor_l if c == 0 else (floor_r if c == COLS - 1 else floor), (c * T, r * T))
    # Pared, con la franja naranja y la primera fila de piso
    for c, sc in enumerate(WALL):
        img.paste(src.crop((sc * T, 0, (sc + 1) * T, 4 * T)), (c * T, 0))
    # Pupitres (pupitre + silla)
    desk = obj((1 * T, 5 * T, 2 * T, 7 * T))
    desk_book = obj((3 * T, 5 * T, 4 * T, 7 * T))
    for r in DESK_ROWS:
        for c in DESK_COLS:
            img.alpha_composite(desk_book if (c, r) in BOOK_DESKS else desk, (c * T, r * T))
    # Escritorio del maestro: asoma un poco sobre la fila de arriba, como en el original
    td = obj((5 * T, 53, 7 * T, 6 * T))
    img.alpha_composite(td, (TEACHER_DESK[0] * T, 53 + (TEACHER_DESK[1] - 4) * T))
    # Alfombra de la entrada
    for rug in (RUG, RUG_LIBRARY):
        for i in range(2):
            img.paste(tile(5 + i, 10), ((rug[0] + i) * T, rug[1] * T))
    # Macetas
    plant = sheet.crop(PLANT)
    pp = plant.load()
    stack = [(x, y) for x in range(plant.width) for y in (0, plant.height - 1)] + \
            [(x, y) for y in range(plant.height) for x in (0, plant.width - 1)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < plant.width and 0 <= y < plant.height):
            continue
        seen.add((x, y))
        if pp[x, y][:3] in PLANT_FLOOR:
            pp[x, y] = (0, 0, 0, 0)
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    # Restos sueltos (la planta de al lado asoma por los bordes): fuera los pedacitos chicos
    seen = set()
    for y in range(plant.height):
        for x in range(plant.width):
            if pp[x, y][3] == 0 or (x, y) in seen:
                continue
            comp, stack = [], [(x, y)]
            seen.add((x, y))
            while stack:
                a, b = stack.pop()
                comp.append((a, b))
                for q in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                    if 0 <= q[0] < plant.width and 0 <= q[1] < plant.height and q not in seen and pp[q][3] > 0:
                        seen.add(q)
                        stack.append(q)
            if len(comp) < 12:
                for q in comp:
                    pp[q] = (0, 0, 0, 0)
    for y in range(plant.height):          # la columna del borde izquierdo es de la vecina
        pp[0, y] = (0, 0, 0, 0)
    for c, r in PLANTS:
        img.alpha_composite(plant, (c * T, r * T))
    # La primera media fila es el techo: negro, como en el juego
    for y in range(8):
        for x in range(img.width):
            img.putpixel((x, y), (0, 0, 0, 255))
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    img.convert("RGB").save(out_path)
    print("Escuela de %dx%d casillas -> %s" % (COLS, ROWS, os.path.abspath(out_path)))


if __name__ == "__main__":
    main()
