"""Baldosas originales del mundo (16x16), en pixel art estilo GBA.
Uso: python3 tools/make_world.py  ->  mundo/baldosas.png
(los personajes: tools/make_characters.py)

Podés reemplazar baldosas.png por tu propia fila de baldosas de 16x16, en el orden de
TILES (abajo).
"""
import os
from PIL import Image

T = 16
ROOT = os.path.join(os.path.dirname(__file__), "..", "mundo")
os.makedirs(os.path.join(ROOT, "personajes"), exist_ok=True)


def C(h):
    h = h.lstrip("#")
    return tuple((int(h[i:i + 2], 16) >> 3) << 3 for i in (0, 2, 4)) + (255,)


def tile(bg=None):
    return Image.new("RGBA", (T, T), C(bg) if bg else (0, 0, 0, 0))


def px(im, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        im.putpixel((x, y), C(c) if isinstance(c, str) else c)


def rect(im, x, y, w, h, c):
    for j in range(y, y + h):
        for i in range(x, x + w):
            px(im, i, j, c)


def art(im, x, y, rows, pal):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in pal:
                px(im, x + i, y + j, pal[ch])


# ----------------------------------------------------------------------------- baldosas
def floor(variant=0):
    """Baldosas de piedra cálida de 8x8 con bisel (luz arriba a la izquierda)."""
    im = tile("#e0b888")
    for by in (0, 8):
        for bx in (0, 8):
            base = ["#e8c498", "#e0bc90", "#e8c094", "#dcb88c"][(bx // 8 + by // 4 + variant) % 4]
            rect(im, bx, by, 8, 8, base)
            rect(im, bx, by, 7, 1, "#f0d4a8")
            rect(im, bx, by + 7, 8, 1, "#cca074")
            rect(im, bx + 7, by, 1, 8, "#cca074")
    if variant == 1:     # piedrita gastada
        rect(im, 3, 10, 2, 1, "#c89c70"); px(im, 11, 4, "#c89c70"); px(im, 12, 5, "#d0a878")
    if variant == 2:     # grieta finita
        for x, y in ((9, 2), (10, 3), (10, 4), (11, 5)):
            px(im, x, y, "#b88c60")
    return im


def floor2():
    im = tile("#f0d8b0")
    rect(im, 0, 15, 16, 1, "#c8a070")
    rect(im, 15, 0, 1, 16, "#c8a070")
    rect(im, 4, 4, 8, 8, "#e8c090")
    rect(im, 6, 6, 4, 4, "#f86838")
    rect(im, 7, 7, 2, 2, "#f8c048")
    return im


def carpet():
    im = tile("#c83030")
    rect(im, 0, 0, 2, 16, "#f8c048")
    rect(im, 14, 0, 2, 16, "#f8c048")
    rect(im, 2, 0, 1, 16, "#882020")
    rect(im, 13, 0, 1, 16, "#882020")
    for y in (3, 11):
        rect(im, 6, y, 4, 2, "#e04838")
    return im


def wall_top():
    im = tile("#503028")
    rect(im, 0, 0, 16, 1, "#683830")
    for x in range(0, 16, 4):
        px(im, x + 1, 8, "#603830")
    return im


def wall_face():
    im = tile("#a85838")
    for y in range(0, 16, 4):
        rect(im, 0, y, 16, 1, "#c87850")
        off = 0 if (y // 4) % 2 == 0 else 4
        for x in range(off, 16, 8):
            rect(im, x, y + 1, 1, 3, "#884028")
    rect(im, 0, 0, 16, 2, "#683830")
    rect(im, 0, 14, 16, 2, "#704028")
    return im


def emblem():
    im = wall_face()
    rect(im, 3, 2, 10, 12, "#f8c048")
    rect(im, 4, 3, 8, 10, "#882020")
    art(im, 5, 4, ["..a...", "..aa..", ".aaa.a", ".abaaa", "aabbaa", ".abba.", "..aa.."],
        {"a": "#f86818", "b": "#f8e060"})
    return im


def lava(frame):
    im = tile("#e04010")
    for y in range(16):
        for x in range(16):
            v = (x * 3 + y * 5 + frame * 7) % 11
            if v < 2:
                px(im, x, y, "#f8a020")
            elif v == 5:
                px(im, x, y, "#b02808")
    for i, (x, y) in enumerate([(3, 4), (11, 9), (6, 12)]):
        if (i + frame) % 2 == 0:
            rect(im, x, y, 2, 2, "#f8e060")
    return im


def brazier(frame):
    im = floor()
    rect(im, 3, 10, 10, 4, "#585868")
    rect(im, 4, 14, 8, 2, "#383848")
    rect(im, 3, 10, 10, 1, "#9898a8")
    flames = [["...a.a...", "..aaba..a", ".aabbaaa.", ".abbbba..", "aabbbbaa."],
              ["..a..a...", "..aaa.a..", ".aabbaa..", "aabbbbaa.", ".abbbbaa."]][frame]
    art(im, 3, 5, flames, {"a": "#f86818", "b": "#f8e060"})
    return im


def railing():
    im = floor()
    rect(im, 0, 6, 16, 3, "#a86828")
    rect(im, 0, 6, 16, 1, "#d89848")
    for x in (1, 13):
        rect(im, x, 6, 2, 9, "#885020")
        rect(im, x, 6, 1, 9, "#b87838")
    rect(im, 0, 14, 16, 2, "#c8a070")
    return im


def table():
    im = floor()
    rect(im, 0, 3, 16, 10, "#885020")
    rect(im, 0, 3, 16, 1, "#b87838")
    rect(im, 1, 4, 14, 7, "#38884a")
    rect(im, 3, 6, 4, 3, "#f8f8f0")      # carta sobre la mesa
    rect(im, 9, 5, 3, 4, "#f8f8f0")
    rect(im, 1, 13, 2, 3, "#603818")
    rect(im, 13, 13, 2, 3, "#603818")
    return im


def shelf():
    im = tile("#704020")
    rect(im, 0, 0, 16, 1, "#986038")
    for y in (5, 10, 15):
        rect(im, 1, y, 14, 1, "#503018")
    cols = ["#c83030", "#3868c8", "#f8c048", "#48a040", "#a050c0", "#f0f0f0"]
    for row, y in enumerate((1, 6, 11)):
        x = 1
        k = row
        while x < 15:
            w = 2 if (x + row) % 3 else 1
            rect(im, x, y, w, 4, cols[k % len(cols)])
            x += w + (1 if (x % 5 == 0) else 0)
            k += 1
    return im


def plant():
    im = floor()
    rect(im, 4, 10, 8, 5, "#c86838")
    rect(im, 4, 10, 8, 1, "#e89058")
    art(im, 2, 1, ["...a..a...", "..aba.ab..", ".abba.bba.", "abbbaabbba", ".abbbbbba.", "..abbbba..",
                   "...abba...", "....aa...."], {"a": "#286828", "b": "#58b048"})
    return im


def pc():
    im = floor()
    rect(im, 2, 2, 12, 9, "#a8a8b8")
    rect(im, 3, 3, 10, 6, "#285080")
    rect(im, 4, 4, 5, 1, "#78c8f8")
    rect(im, 4, 6, 7, 1, "#58a8e8")
    rect(im, 1, 11, 14, 4, "#888898")
    rect(im, 1, 11, 14, 1, "#c8c8d8")
    rect(im, 3, 13, 10, 1, "#585868")
    return im


def door():
    im = tile("#6878a8")
    for y in range(1, 16, 3):
        rect(im, 1, y, 14, 1, "#8898c8")
    rect(im, 0, 0, 16, 1, "#485888")
    return im


# El orden importa: es el índice de cada baldosa en baldosas.png (scenes/overworld.gd)
TILES = [("piso", floor()), ("piso2", floor2()), ("alfombra", carpet()), ("pared_arriba", wall_top()),
         ("pared", wall_face()), ("emblema", emblem()), ("lava0", lava(0)), ("lava1", lava(1)),
         ("brasero0", brazier(0)), ("brasero1", brazier(1)), ("baranda", railing()), ("mesa", table()),
         ("biblioteca", shelf()), ("planta", plant()), ("pc", pc()), ("salida", door()),
         ("piso_b", floor(1)), ("piso_c", floor(2))]

sheet = Image.new("RGBA", (T * len(TILES), T))
for i, (_, im) in enumerate(TILES):
    sheet.paste(im, (i * T, 0))
sheet.save(os.path.join(ROOT, "baldosas.png"))


# Los personajes están en tools/make_characters.py (cuadros de 16x32).
print(len(TILES), "baldosas en", os.path.abspath(ROOT))
