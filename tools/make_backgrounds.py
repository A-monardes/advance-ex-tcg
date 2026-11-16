"""Fondos de mesa originales, en pixel art de 240x110 (inspirados en temas como los
fondos de caja de PC de la 3ra generación, pero dibujados desde cero).
Uso: python3 tools/make_backgrounds.py  ->  fondos/NN_nombre.png
Podés agregar los tuyos a fondos/ (PNG de cualquier tamaño: se recorta a 240x110)."""
import os, random, math
from PIL import Image

W, H = 240, 110
OUT = os.path.join(os.path.dirname(__file__), "..", "fondos")
os.makedirs(OUT, exist_ok=True)


def C(h):
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) >> 3) << 3 for i in (0, 2, 4))


def new(bg):
    return Image.new("RGB", (W, H), C(bg))


def put(im, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        im.putpixel((x, y), C(c) if isinstance(c, str) else c)


def sprite(im, x, y, rows, pal):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in pal:
                put(im, x + i, y + j, pal[ch])


def scatter(step_x, step_y, jitter, seed):
    rnd = random.Random(seed)
    for gy in range(-step_y, H + step_y, step_y):
        off = (gy // step_y) % 2 * step_x // 2
        for gx in range(-step_x, W + step_x, step_x):
            yield gx + off + rnd.randint(-jitter, jitter), gy + rnd.randint(-jitter, jitter)


# ----------------------------------------------------------------------------- temas
def bosque():
    im = new("#70c048")
    tuft = ["..a..a..", ".ab.ab.a", "abbabbab", ".dbbdbb."]
    for x, y in scatter(16, 11, 2, 1):
        sprite(im, x, y, tuft, {"a": "#a8e070", "b": "#88d058", "d": "#58a030"})
    return im


def sabana():
    im = new("#a8d060")
    rnd = random.Random(2)
    for x in range(W):   # franja más clara arriba de cada mitad, con borde ondulado
        for top in (0, 56):
            edge = top + 18 + int(3 * math.sin(x / 9.0))
            for y in range(top, edge):
                put(im, x, y, "#c0e078")
    tuft = ["..a.....", ".a.a..a.", "a..ba.a.", ".bbbbbb."]
    for x, y in scatter(22, 14, 4, 3):
        sprite(im, x, y, tuft, {"a": "#80a838", "b": "#90b848"})
    for _ in range(140):
        put(im, rnd.randrange(W), rnd.randrange(H), "#98c050")
    return im


def desierto():
    im = new("#e8c080")
    rnd = random.Random(4)
    for k in range(-6, 12):
        for x in range(W):
            y = int(k * 18 + x * 0.35 + 5 * math.sin(x / 13.0 + k))
            for t in range(3):
                put(im, x, y + t, "#d0a058" if t < 2 else "#f0d8a0")
    for _ in range(260):
        put(im, rnd.randrange(W), rnd.randrange(H), "#d8b070")
    return im


def ciudad():
    im = new("#c8b0c0")
    # Ladrillos en cesta: bloques de 8x8 que alternan horizontales y verticales
    for by in range(0, H, 8):
        for bx in range(0, W, 8):
            horiz = ((bx // 8) + (by // 8)) % 2 == 0
            for j in range(8):
                for i in range(8):
                    x, y = bx + i, by + j
                    if horiz:
                        if j in (3, 7) or i == 7:
                            put(im, x, y, "#a088a0")
                        elif j in (0, 4):
                            put(im, x, y, "#e0d0d8")
                    else:
                        if i in (3, 7) or j == 7:
                            put(im, x, y, "#a088a0")
                        elif i in (0, 4):
                            put(im, x, y, "#e0d0d8")
    return im


def risco():
    im = new("#c0a0b8")
    for row, y0 in enumerate(range(-4, H, 9)):
        off = (row % 2) * 7
        for x0 in range(-14 + off, W, 14):
            for i in range(14):
                y = y0 + int(3 * math.sin(i / 13.0 * math.pi))
                put(im, x0 + i, y, "#a07898")
                put(im, x0 + i, y + 1, "#d8c0d0")
    return im


def volcan():
    im = new("#e08048")
    for row, y0 in enumerate(range(-4, H, 10)):
        off = (row % 2) * 9
        for x0 in range(-18 + off, W, 18):
            for i in range(18):
                y = y0 - int(4 * math.sin(i / 17.0 * math.pi))
                put(im, x0 + i, y, "#c05828")
                put(im, x0 + i, y + 1, "#f0a068")
    return im


def nieve():
    im = new("#f0f0f8")
    for y0 in range(4, H, 11):
        for x in range(W):
            y = y0 + int(2 * math.sin(x / 6.0 + y0))
            put(im, x, y, "#c8d0e8")
            put(im, x, y + 1, "#e0e4f0")
    rnd = random.Random(5)
    for _ in range(60):
        put(im, rnd.randrange(W), rnd.randrange(H), "#d8e0f0")
    return im


def cueva():
    im = new("#987028")
    rnd = random.Random(6)
    for _ in range(170):
        x, y = rnd.randrange(W), rnd.randrange(H)
        l = rnd.randint(3, 7)
        for t in range(l):
            put(im, x + t, y - t // 2, "#705010")
            put(im, x + t, y - t // 2 + 1, "#b89040")
    return im


def playa():
    im = new("#f0d890")
    rnd = random.Random(7)
    for _ in range(420):
        put(im, rnd.randrange(W), rnd.randrange(H), "#e0c070")
    shell = {"p": ["#f08898", "#c86070"], "c": ["#78c8d8", "#4898b0"], "w": ["#f8f8f0", "#c8c0a8"]}
    for x, y in scatter(30, 18, 7, 8):
        a, b = shell[rnd.choice("pcw")]
        put(im, x, y, a); put(im, x + 1, y, a); put(im, x, y + 1, b); put(im, x + 1, y + 1, b)
    return im


def fondo_marino():
    im = new("#2048a0")
    for k in range(-20, 40):
        for t in range(0, 60, 3):
            put(im, k * 12 + t, t * 2 % H + (k % 3), "#3060b8")
    rnd = random.Random(9)
    bubble = [".a.", "a.a", ".a."]
    for x, y in scatter(26, 16, 8, 10):
        sprite(im, x, y, bubble, {"a": "#78a8e8"})
    for half in (0, 56):    # coral abajo de cada mitad
        base = half + 51
        for x0 in range(4, W, 20):
            for j, w in enumerate([1, 3, 5]):
                for i in range(w):
                    put(im, x0 + 2 - w // 2 + i, base - 2 + j, "#e05868" if j < 2 else "#a83848")
    return im


def rio():
    im = new("#d8f8f8")
    for x in range(W):
        for y in range(H):
            yy = y % 55
            w1 = 7 + int(2 * math.sin(x / 7.0))
            if yy < w1 or yy > 54 - w1:
                put(im, x, y, "#a0e8f0")
            if yy < 3 or yy > 51:
                put(im, x, y, "#78d0e8")
    for x in range(0, W, 9):
        for y0 in (20, 34):
            for half in (0, 55):
                put(im, x + (y0 % 5), y0 + half, "#b8f0f0")
                put(im, x + 1 + (y0 % 5), y0 + half, "#b8f0f0")
    return im


def cielo():
    im = new("#78c8f0")
    cloud = ["...wwww....", ".wwwwwwwww.", "wwwwwwwwwww", "swwwwwwwwws", ".sssssssss."]
    for x, y in scatter(44, 20, 8, 11):
        sprite(im, x, y, cloud, {"w": "#f8f8f8", "s": "#c8e0f0"})
    return im


def lunares():
    im = new("#f0a850")
    for row, cy in enumerate(range(6, H + 12, 14)):
        off = (row % 2) * 12
        for cx in range(-12 + off, W + 12, 24):
            for y in range(cy - 6, cy + 7):
                for x in range(cx - 6, cx + 7):
                    d = (x - cx) ** 2 + (y - cy) ** 2
                    if d <= 30:
                        put(im, x, y, "#f8c878" if d > 8 else "#f8d898")
    return im


def maquina():
    im = new("#c8c8c8")
    for y in range(0, H, 2):
        for x in range(W):
            put(im, x, y, "#b8b8b8")
    for half in (0, 56):
        for x in range(W):
            put(im, x, half + 3, "#909090"); put(im, x, half + 4, "#e8e8e8")
            put(im, x, half + 50, "#909090"); put(im, x, half + 51, "#e8e8e8")
        for x0 in range(10, W, 40):
            sprite(im, x0, half + 24, [".aa.", "abba", "abba", ".aa."], {"a": "#808080", "b": "#e0e0e0"})
    return im


def baldosas():
    im = new("#b0b0b0")
    n = 12
    for by in range(0, H, n):
        for bx in range(0, W, n):
            for j in range(n):
                for i in range(n):
                    # Pirámide: cuatro caras con distinta luz
                    if j <= i and i + j < n:
                        c = "#d0d0d0"      # arriba
                    elif j > i and i + j < n:
                        c = "#b8b8b8"      # izquierda
                    elif j <= i:
                        c = "#a0a0a0"      # derecha
                    else:
                        c = "#888888"      # abajo
                    if i == n - 1 or j == n - 1:
                        c = "#707070"
                    put(im, bx + i, by + j, c)
    return im


def estrellas():
    im = new("#c0a8d8")
    star = ["..a..", ".aaa.", "aaaaa", ".a.a."]
    rnd = random.Random(12)
    for x, y in scatter(30, 18, 8, 13):
        sprite(im, x, y, star, {"a": rnd.choice(["#f8f8f8", "#f8e070", "#f8c0e0"])})
    for half in (0, 56):    # arcoíris abajo
        for k, c in enumerate(["#f86858", "#f8b040", "#f8e050", "#70d070", "#58a8f0", "#a070e0"]):
            for x in range(W):
                put(im, x, half + 46 + k, c)
    return im


def liso():
    return new("#e8e8e0")


THEMES = [("bosque", bosque), ("sabana", sabana), ("desierto", desierto), ("ciudad", ciudad),
          ("risco", risco), ("volcan", volcan), ("nieve", nieve), ("cueva", cueva), ("playa", playa),
          ("fondo_marino", fondo_marino), ("rio", rio), ("cielo", cielo), ("lunares", lunares),
          ("maquina", maquina), ("baldosas", baldosas), ("estrellas", estrellas), ("liso", liso)]

for n, (name, fn) in enumerate(THEMES):
    fn().save(os.path.join(OUT, "%02d_%s.png" % (n + 1, name)))
print(len(THEMES), "fondos en", os.path.abspath(OUT))
