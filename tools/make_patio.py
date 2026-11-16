"""Patio de duelos de la Escuela de Entrenadores: pixel art original de 20x15 casillas.
Pasto, árboles alrededor, dos canchas de arena con su mesa de duelo, bancos, flores y el
techo de la escuela abajo, con las dos alfombras que vuelven adentro.

Uso: python3 tools/make_patio.py  ->  mundo/fondos/patio_escuela.png
El mapa que la usa es data/mapas/patio.json (las letras tienen que coincidir con esto).
"""
import os
import random
from PIL import Image

T = 16
COLS, ROWS = 20, 15
OUT = os.path.join(os.path.dirname(__file__), "..", "mundo", "fondos", "patio_escuela.png")

C = {
    "grass": (136, 208, 104), "grass_d": (96, 176, 80), "grass_l": (176, 232, 136),
    "out": (32, 56, 32), "leaf_d": (48, 112, 48), "leaf": (72, 152, 64), "leaf_l": (112, 192, 80),
    "leaf_h": (168, 224, 112), "trunk": (128, 88, 48), "trunk_d": (88, 56, 32),
    "sand": (232, 208, 144), "sand_d": (208, 184, 112), "sand_l": (248, 232, 176), "line": (248, 248, 240),
    "felt": (56, 136, 80), "felt_d": (40, 104, 64), "wood": (152, 96, 48), "wood_d": (104, 64, 32), "wood_l": (192, 136, 72),
    "roof": (184, 80, 56), "roof_d": (136, 56, 40), "roof_l": (224, 120, 88), "roof_o": (72, 32, 24),
    "mat": (216, 112, 72), "mat_l": (248, 176, 128), "mat_o": (120, 56, 40),
    "red": (232, 72, 72), "yellow": (248, 216, 72), "white": (248, 248, 248), "path": (216, 200, 152),
}

LAYOUT = [
    "####################",
    "####################",
    "##,,ff,,,,,,,,ff,,##",
    "##_______,,_______##",
    "##_______,,_______##",
    "##__MMM__,,__MMM__##",
    "##__MMM__,,__MMM__##",
    "##_______,,_______##",
    "##_______,,_______##",
    "##_______,,_______##",
    "##,,,,BBB,,BBB,,,,##",
    "##,,,,,,,,,,,,,,,,##",
    "##,,DD,,,,,,,,DD,,##",
    "####################",
    "####################",
]


def main(objects=True):
    rng = random.Random(7)
    img = Image.new("RGB", (COLS * T, ROWS * T), C["grass"])
    px = img.load()

    def put(x, y, c):
        if 0 <= x < img.width and 0 <= y < img.height:
            px[x, y] = C[c] if isinstance(c, str) else c

    def rect(x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                put(xx, yy, c)

    # Pasto con matitas
    for ty in range(ROWS):
        for tx in range(COLS):
            for i in range(3):
                x = tx * T + rng.randrange(1, 14)
                y = ty * T + rng.randrange(2, 14)
                put(x, y, "grass_d")
                put(x + 2, y, "grass_d")
                put(x + 1, y + 1, "grass_d")
                put(x + 1, y - 1, "grass_l")
    # Caminito de las alfombras a las canchas
    for cx in (4, 14):
        rect(cx * T, 10 * T, 2 * T, 2 * T, "path")
        for i in range(14):
            put(cx * T + rng.randrange(2 * T), 10 * T + rng.randrange(2 * T), "sand_d")
    # Canchas
    for x0 in (2, 11):
        x, y, w, h = x0 * T, 3 * T, 7 * T, 7 * T
        rect(x, y, w, h, "sand")
        for i in range(70):
            put(x + rng.randrange(w), y + rng.randrange(h), "sand_d" if i % 3 else "sand_l")
        rect(x, y, w, 1, "sand_d")
        rect(x, y + h - 1, w, 1, "sand_l")
        # líneas blancas: borde, mitad y círculo del medio
        for yy in (y + 4, y + h - 5):
            rect(x + 4, yy, w - 8, 2, "line")
        for xx in (x + 4, x + w - 6):
            rect(xx, y + 4, 2, h - 8, "line")
        rect(x + 4, y + h // 2 - 1, w - 8, 2, "line")
        cx, cy, r = x + w // 2, y + h // 2, 22
        for a in range(0, 360, 2):
            import math
            px_ = int(round(cx + r * math.cos(math.radians(a))))
            py_ = int(round(cy + r * math.sin(math.radians(a))))
            rect(px_, py_, 2, 2, "line")
    # Mesas de duelo (2x1): madera con paño verde y dos cartas encima
    for tx in ((4, 13) if objects else ()):
        x, y = tx * T + 8, 6 * T
        rect(x + 1, y + 3, 30, 12, "wood_d")
        rect(x + 2, y + 2, 28, 10, "wood")
        rect(x + 2, y + 2, 28, 1, "wood_l")
        rect(x + 4, y + 4, 24, 6, "felt")
        rect(x + 4, y + 9, 24, 1, "felt_d")
        rect(x + 8, y + 5, 4, 3, "white")
        rect(x + 20, y + 5, 4, 3, "white")
        rect(x + 3, y + 12, 2, 4, "wood_d")
        rect(x + 27, y + 12, 2, 4, "wood_d")
    # Bancos (3x1)
    for tx in ((6, 11) if objects else ()):
        x, y = tx * T, 10 * T
        rect(x + 1, y + 4, 46, 6, "wood_d")
        rect(x + 2, y + 4, 44, 4, "wood")
        rect(x + 2, y + 4, 44, 1, "wood_l")
        rect(x + 3, y + 10, 2, 4, "wood_d")
        rect(x + 43, y + 10, 2, 4, "wood_d")
    # Flores
    for ty in range(ROWS):
        for tx in range(COLS):
            if LAYOUT[ty][tx] == "f":
                for i in range(4):
                    fx = tx * T + 2 + (i % 2) * 7 + rng.randrange(2)
                    fy = ty * T + 3 + (i // 2) * 7 + rng.randrange(2)
                    col = "red" if (tx + i) % 2 else "yellow"
                    put(fx + 1, fy, col)
                    put(fx, fy + 1, col)
                    put(fx + 2, fy + 1, col)
                    put(fx + 1, fy + 2, col)
                    put(fx + 1, fy + 1, "white")
                    put(fx + 1, fy + 3, "leaf")
    # Alfombras de las puertas de atrás
    for tx in ((4, 14) if objects else ()):
        x, y = tx * T, 12 * T
        rect(x + 1, y + 3, 30, 12, "mat_o")
        rect(x + 2, y + 4, 28, 10, "mat")
        for yy in range(y + 5, y + 13, 2):
            for xx in range(x + 3 + (yy // 2) % 2, x + 29, 2):
                put(xx, yy, "mat_l")
    # Techo de la escuela (abajo)
    y0 = 13 * T
    rect(2 * T, y0, 16 * T, 2 * T, "roof")
    for yy in range(y0 + 4, y0 + 2 * T, 6):
        rect(2 * T, yy, 16 * T, 1, "roof_d")
        for xx in range(2 * T + (yy // 6 % 2) * 6, 18 * T, 12):
            rect(xx, yy - 3, 1, 3, "roof_d")
    rect(2 * T, y0, 16 * T, 2, "roof_o")
    rect(2 * T, y0 + 2, 16 * T, 1, "roof_l")
    # Hueco de cada puerta en el alero, arriba de la alfombra
    for tx in (4, 14):
        rect(tx * T + 4, y0, 24, 3, (56, 40, 40))
    # Árboles redondos (2x2) en los bordes
    def tree(x, y):
        rect(x + 13, y + 22, 6, 9, "trunk")
        rect(x + 13, y + 22, 2, 9, "trunk_d")
        rows = [(10, 22), (6, 26), (4, 28), (3, 29), (2, 30), (2, 30), (2, 30), (2, 30), (2, 30),
                (2, 30), (3, 29), (3, 29), (4, 28), (5, 27), (6, 26), (8, 24), (11, 21)]
        for i, (a, b) in enumerate(rows):
            yy = y + 2 + i
            put(x + a - 1, yy, "out")
            put(x + b, yy, "out")
            for xx in range(x + a, x + b):
                d = (xx - x - 16) ** 2 + (yy - y - 9) ** 2
                c = "leaf_d" if (xx - x) + (yy - y) > 34 else ("leaf" if d > 60 else "leaf_l")
                if (xx * 7 + yy * 3) % 11 == 0 and c != "leaf_d":
                    c = "leaf_h"
                put(xx, yy, c)
        for xx in range(x + 10, x + 22):
            put(xx, y + 1, "out")
        for xx in range(x + 11, x + 21):
            put(xx, y + 19, "out")
    for ty in range(0, 2, 2):
        for tx in range(0, COLS, 2):
            tree(tx * T, ty * T)
    for ty in range(2, 13, 2):
        for tx in (0, COLS - 2):
            tree(tx * T, ty * T)
    for tx in (0, COLS - 2):          # esquinas de abajo
        tree(tx * T, 13 * T)
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    img.save(OUT)
    print("Patio %dx%d -> %s" % (COLS, ROWS, os.path.abspath(OUT)))


if __name__ == "__main__":
    main()
