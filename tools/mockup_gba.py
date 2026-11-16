"""Maqueta de la mesa de duelo con estética GBA (240x160, píxel exacto).
Uso: python3 tools/mockup_gba.py carpeta_salida
Genera mock_menu.png y mock_ataque.png (x1 y x4)."""
import sys, os, json
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import gba_font as F

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
W, H = 240, 160

CARDS = {c["id"]: c for c in json.load(open(os.path.join(ROOT, "data/cards_adv.json")))}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# --- Paleta (colores de 15 bits, como la GBA) -----------------------------------
def c15(c):
    return tuple((v >> 3) << 3 for v in c)


TEXT = rgb("#484850"); SHADOW = rgb("#d0d0c8")
INK = rgb("#202838")
WHITE = rgb("#f8f8f8")
FRAME_OUT = rgb("#283858"); FRAME_MID = rgb("#6890d0"); FRAME_HI = rgb("#a8c8f8")
YELLOW = rgb("#f8d830"); YELLOW_D = rgb("#c09810"); YELLOW_L = rgb("#f8f0a0")
TYPE = {  # base, oscuro, claro
    "Fire": ("#f86838", "#b83010", "#f8b088"), "Water": ("#4890f8", "#1850b0", "#98c8f8"),
    "Grass": ("#50c048", "#207820", "#a8e888"), "Lightning": ("#f8d020", "#b08800", "#f8f090"),
    "Psychic": ("#b060d0", "#703090", "#e0a8f0"), "Fighting": ("#c87838", "#804818", "#f0b888"),
    "Darkness": ("#585870", "#282838", "#9898b0"), "Metal": ("#a0a8b8", "#606878", "#e0e8f0"),
    "Colorless": ("#e0d8c8", "#988f80", "#f8f8f0"),
}
TYPE = {k: tuple(rgb(x) for x in v) for k, v in TYPE.items()}
HP_G = (rgb("#70f8a8"), rgb("#58d080")); HP_Y = (rgb("#f8e038"), rgb("#c8a808")); HP_R = (rgb("#f85838"), rgb("#a84048"))


def rect(d, x, y, w, h, c):
    if w > 0 and h > 0:
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def outline(d, x, y, w, h, c):
    d.rectangle([x, y, x + w - 1, y + h - 1], outline=c)


# --- Fondo de la mesa -----------------------------------------------------------
def table(img):
    px = img.load()
    for y in range(112):
        for x in range(W):
            if y < 55:      # lado rival: rojo coral a cuadros en diagonal
                a, b = rgb("#f0907a"), rgb("#f8a88c")
            else:           # tu lado: azul
                a, b = rgb("#6c9cf0"), rgb("#84b0f8")
            px[x, y] = a if ((x + y) // 8 + (x - y) // 8) % 2 == 0 else b
    d = ImageDraw.Draw(img)
    rect(d, 0, 55, W, 1, WHITE)
    rect(d, 0, 56, W, 1, rgb("#384878"))


# --- Imagen de carta reducida a paleta GBA ---------------------------------------
def art(card_id, w, h):
    p = os.path.join(ROOT, "sprites", card_id + ".png")
    if not os.path.exists(p):
        return None
    im = Image.open(p).convert("RGB")
    s = min(im.size)
    sc = max(w / s, h / s)
    cw, ch = int(w / sc), int(h / sc)
    left = (im.size[0] - cw) // 2
    top = max(0, (im.size[1] - ch) // 3)
    im = im.crop((left, top, left + cw, top + ch)).resize((w, h), Image.LANCZOS)
    from PIL import ImageEnhance
    im = ImageEnhance.Color(im).enhance(1.35)
    im = ImageEnhance.Brightness(im).enhance(1.12)
    im = ImageEnhance.Contrast(im).enhance(1.1)
    im = im.quantize(colors=15, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    return im.point(lambda v: (v >> 3) << 3)


def card_types(cid):
    return CARDS[cid].get("types", ["Colorless"])


# --- Carta en miniatura (Banca) ----------------------------------------------------
def mini_card(img, x, y, cid, dmg=0):
    d = ImageDraw.Draw(img)
    base, dark, light = TYPE[card_types(cid)[0]]
    rect(d, x, y, 20, 26, INK)
    rect(d, x + 1, y + 1, 18, 24, YELLOW)
    rect(d, x + 1, y + 24, 18, 1, YELLOW_D)
    rect(d, x + 2, y + 2, 16, 22, base)
    rect(d, x + 2, y + 2, 16, 1, light)
    a = art(cid, 14, 12)
    rect(d, x + 2, y + 4, 16, 14, rgb("#c8c8d0"))
    if a:
        img.paste(a, (x + 3, y + 5))
    # franja de texto de la carta
    for i in range(3):
        rect(d, x + 4, y + 19 + i * 2, 12 - (i * 3) % 7, 1, dark)
    # PS en barra debajo
    hp = int(CARDS[cid]["hp"])
    hp_bar(img, x, y + 27, 20, hp - dmg, hp, small=True)


def hp_bar(img, x, y, w, cur, mx, small=False):
    d = ImageDraw.Draw(img)
    k = max(0.0, cur / mx)
    col = HP_G if k > 0.5 else (HP_Y if k > 0.2 else HP_R)
    if small:
        rect(d, x, y, w, 4, INK)
        rect(d, x + 1, y + 1, w - 2, 2, rgb("#506858"))
        fill = round((w - 2) * k)
        rect(d, x + 1, y + 1, fill, 1, col[0])
        rect(d, x + 1, y + 2, fill, 1, col[1])
        return
    # Como en las batallas de GBA: etiqueta "PS" y barra
    rect(d, x, y, w, 7, INK)
    # letras P y S chiquitas en naranja
    org = rgb("#f8b838")
    pp = ["###", "#.#", "###", "#..", "#.."]
    ss = ["###", "#..", "###", "..#", "###"]
    lab = Image.new("RGB", (8, 5), INK)
    lp = lab.load()
    for j in range(5):
        for i in range(3):
            if pp[j][i] == "#": lp[i, j] = org
            if ss[j][i] == "#": lp[i + 4, j] = org
    img.paste(lab, (x + 2, y + 1))
    bx = x + 11
    bw = w - 12
    rect(d, bx, y + 2, bw, 3, rgb("#506858"))
    fill = round(bw * k)
    rect(d, bx, y + 2, fill, 2, col[0])
    rect(d, bx, y + 4, fill, 1, col[1])


# --- Carta grande (Activo) ------------------------------------------------------
def big_card(img, x, y, cid):
    d = ImageDraw.Draw(img)
    base, dark, light = TYPE[card_types(cid)[0]]
    w, h = 40, 52
    rect(d, x + 2, y + 2, w, h, rgb("#202838"))          # sombra
    rect(d, x, y, w, h, INK)
    rect(d, x + 1, y + 1, w - 2, h - 2, YELLOW)
    rect(d, x + 1, y + 1, w - 2, 1, YELLOW_L)
    rect(d, x + 1, y + h - 2, w - 2, 1, YELLOW_D)
    rect(d, x + 3, y + 3, w - 6, h - 6, base)
    rect(d, x + 3, y + 3, w - 6, 1, light)
    # ventana de la ilustración con marco plateado
    rect(d, x + 4, y + 8, 32, 26, rgb("#e0e0e8"))
    rect(d, x + 4, y + 33, 32, 1, rgb("#8888a0"))
    a = art(cid, 30, 24)
    if a:
        img.paste(a, (x + 5, y + 9))
    # banda del nombre y del texto
    rect(d, x + 5, y + 5, 16, 1, dark)
    rect(d, x + 28, y + 5, 7, 1, rgb("#c03028"))
    for i in range(4):
        rect(d, x + 6, y + 37 + i * 3, 28 - (i * 7) % 12, 1, dark)
    if "ex" in CARDS[cid].get("subtypes", []):
        F.draw(img, x + 27, y + 39, "ex", rgb("#f8f8f8"), rgb("#383848"))


def energy_icon(img, x, y, t):
    d = ImageDraw.Draw(img)
    base, dark, light = TYPE[t]
    shape = [".###.", "#####", "#####", "#####", ".###."]
    for j, row in enumerate(shape):
        for i, c in enumerate(row):
            if c == "#":
                img.putpixel((x + i + 1, y + j + 1), dark)
    for j, row in enumerate(shape):
        for i, c in enumerate(row):
            if c == "#":
                img.putpixel((x + i, y + j), base)
    img.putpixel((x + 1, y + 1), light)
    img.putpixel((x + 2, y + 1), light)
    img.putpixel((x + 1, y + 2), light)


# --- Recuadros estilo GBA -------------------------------------------------------
def frame(img, x, y, w, h):
    d = ImageDraw.Draw(img)
    rect(d, x, y, w, h, FRAME_OUT)
    rect(d, x + 1, y + 1, w - 2, h - 2, FRAME_MID)
    rect(d, x + 1, y + 1, w - 2, 1, FRAME_HI)
    rect(d, x + 1, y + 1, 1, h - 2, FRAME_HI)
    rect(d, x + 3, y + 3, w - 6, h - 6, FRAME_OUT)
    rect(d, x + 4, y + 4, w - 8, h - 8, WHITE)


def info_box(img, x, y, cid, dmg, energies, mine):
    """Recuadro de nombre y PS como en las batallas de GBA."""
    d = ImageDraw.Draw(img)
    w, h = 78, 34
    rect(d, x + 2, y + 2, w, h, rgb("#28385880"[:7]))
    rect(d, x, y, w, h, INK)
    rect(d, x + 1, y + 1, w - 2, h - 2, rgb("#f8f8e8"))
    rect(d, x + 1, y + h - 3, w - 2, 2, rgb("#d8d8b8"))
    # pestaña con el color del tipo
    base, dark, light = TYPE[card_types(cid)[0]]
    rect(d, x + 1, y + 1, 3, h - 2, base)
    name = CARDS[cid]["name"]
    F.draw(img, x + 7, y + 1, name.replace(" ex", ""), TEXT, SHADOW)
    if name.endswith(" ex"):
        nx = x + 7 + F.width(name.replace(" ex", "")) + 3
        F.draw(img, nx, y + 1, "ex", rgb("#c03028"), rgb("#f0c0b0"))
    hp = int(CARDS[cid]["hp"])
    hp_bar(img, x + 7, y + 12, w - 11, hp - dmg, hp)
    # PS en números y Energías
    F.draw(img, x + w - 5 - F.width("%d/%d" % (hp - dmg, hp)), y + 20, "%d/%d" % (hp - dmg, hp), TEXT, SHADOW)
    for i, t in enumerate(energies):
        energy_icon(img, x + 7 + i * 7, y + 22, t)


def card_back(img, x, y):
    d = ImageDraw.Draw(img)
    rect(d, x, y, 8, 10, INK)
    rect(d, x + 1, y + 1, 6, 8, rgb("#3858c0"))
    rect(d, x + 2, y + 3, 4, 4, rgb("#f8c838"))
    rect(d, x + 3, y + 4, 2, 2, rgb("#c03028"))


def counters(img, x, y, prizes, deck, hand, disc):
    for i in range(6):
        cx, cy = x + (i % 3) * 9, y + (i // 3) * 11
        if i < prizes:
            card_back(img, cx, cy)
        else:
            d = ImageDraw.Draw(img)
            outline(d, cx, cy, 8, 10, rgb("#405080"))
    # mazo, mano y descarte con número
    ix = x + 30
    icons = [("MAZO", deck), ("MANO", hand), ("DESC", disc)]
    for k, (lab, n) in enumerate(icons):
        yy = y + k * 7
        F.draw(img, ix, yy - 1, "", None)
        d = ImageDraw.Draw(img)
        rect(d, ix, yy, 5, 6, INK)
        rect(d, ix + 1, yy + 1, 3, 4, [rgb("#3858c0"), rgb("#f8f8f8"), rgb("#909098")][k])
        F.draw(img, ix + 7, yy, "%d" % n, WHITE, INK, small=True)


def textbox(img, lines, arrow=True):
    frame(img, 0, 112, W, 48)
    for i, l in enumerate(lines):
        F.draw(img, 9, 116 + i * 13, l, TEXT, SHADOW)
    if arrow:
        F.draw(img, 224, 141, "▼", rgb("#e03828"), rgb("#f0a898"))


def scene():
    img = Image.new("RGB", (W, H))
    table(img)
    # Rival
    for i, (cid, dmg) in enumerate([("ex1-59", 0), ("ex1-40", 30), ("ex1-48", 0), ("ex1-99", 0)]):
        mini_card(img, 4 + i * 22, 3, cid, dmg)
    d = ImageDraw.Draw(img)
    outline(d, 4 + 4 * 22, 3, 20, 26, rgb("#c87060"))
    counters(img, 4, 34, 3, 38, 6, 9)
    info_box(img, 112, 8, "ex1-13", 50, ["Water", "Water", "Water", "Colorless"], False)
    big_card(img, 196, 1, "ex1-13")
    # Vos
    big_card(img, 4, 58, "ex4-89")
    info_box(img, 49, 74, "ex4-89", 40, ["Fire", "Fire", "Fire"], True)
    for i, (cid, dmg) in enumerate([("ex1-73", 0), ("ex1-27", 20), ("ex1-61", 0)]):
        mini_card(img, 130 + i * 22, 80, cid, dmg)
    for i in range(3, 5):
        outline(d, 130 + i * 22, 80, 20, 26, rgb("#5070c0"))
    counters(img, 190, 59, 4, 31, 5, 12)
    return img


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))
    img.resize((W * 4, H * 4), Image.NEAREST).save(os.path.join(OUT, name + "_x4.png"))


# Pantalla 1: menú principal (¿Qué hará...?)
img = scene()
frame(img, 0, 112, 112, 48)
F.draw(img, 9, 117, "¿Qué hará", TEXT, SHADOW)
F.draw(img, 9, 130, "Blaziken ex?", TEXT, SHADOW)
frame(img, 110, 112, 130, 48)
opts = [["Atacar", "Energía"], ["Pokémon", "Entrenador"], ["Retirar", "Fin turno"]]
for r, row in enumerate(opts):
    for c, o in enumerate(row):
        ox, oy = 124 + c * 58, 116 + r * 13
        F.draw(img, ox, oy, o, TEXT, SHADOW)
F.draw(img, 116, 116, "▶", TEXT, SHADOW)
save(img, "mock_menu")

# Pantalla 2: elegir ataque (como el cuadro de movimientos)
img = scene()
frame(img, 0, 112, 152, 48)
F.draw(img, 16, 117, "Blaze Kick", TEXT, SHADOW)
F.draw(img, 16, 130, "Volcanic Ash", TEXT, SHADOW)
F.draw(img, 8, 117, "▶", TEXT, SHADOW)
frame(img, 150, 112, 90, 48)
F.draw(img, 158, 117, "Costo", TEXT, SHADOW)
energy_icon(img, 192, 119, "Fire")
energy_icon(img, 199, 119, "Colorless")
F.draw(img, 158, 130, "Daño", TEXT, SHADOW)
F.draw(img, 190, 130, "30+", rgb("#c03028"), rgb("#f0c0b0"))
F.draw(img, 158, 143 - 1, "C: ver carta", rgb("#808890"), rgb("#e0e0e0"))
save(img, "mock_ataque")

# Pantalla 3: mensaje durante el turno
img = scene()
textbox(img, ["¡Blaziken ex usa Blaze Kick!", "Swampert recibe 60 de daño."])
save(img, "mock_mensaje")
print("ok")
