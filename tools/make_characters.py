"""Personajes originales del mundo, en pixel art estilo GBA (cuadros de 16x32).
Uso: python3 tools/make_characters.py  ->  mundo/personajes/<id>.png

Cada PNG mide 48x128: 3 columnas (quieto, paso 1, paso 2) x 4 filas (abajo, arriba,
izquierda, derecha), cuadros de 16x32 con fondo transparente. Los pies quedan en la
fila 29 del cuadro. Podés reemplazar cualquiera por uno tuyo del mismo formato.

Las plantillas usan letras para cada parte; cada personaje elige colores y peinado.
Las sombras y brillos salen solos de cada color base, y el contorno toma un tono oscuro
del color que tiene al lado (como en los juegos de GBA, que casi no usan negro puro).
"""
import os
from PIL import Image

W, H = 16, 32
OUT = os.path.join(os.path.dirname(__file__), "..", "mundo", "personajes")
os.makedirs(OUT, exist_ok=True)

# Letras: O contorno · H/h/L pelo (base/sombra/brillo) · S/s piel · W/E ojo (blanco/pupila)
#         C/c/G ropa de arriba · A/a detalle (cuello, cinturón) · P/p pantalón · B/b zapatos
#         Q/q/R gorra o capucha · M boca

DOWN = [
    "................",
    "................",
    "................",
    "......OOOO......",
    "....OOHHHHOO....",
    "...OHHLLHHHHO...",
    "..OHHLHHHHHHhO..",
    "..OHHHHHHHHHhO..",
    ".OHHHHHHHHHHhhO.",
    ".OHhHHhHHhHHhhO.",
    ".OhHSShSShSShhO.",
    ".OhSSSSSSSSSShO.",
    ".OhSWESSSSWEShO.",
    ".OOSWESSSSWESOO.",
    "..OSSSSSSSSSsO..",
    "...OsSSMMSSsO...",
    "....OOssssOO....",
    "...OOAAAAAAOO...",
    "..OCGCAAAACccO..",
    "..OCGCCCCCCccO..",
    ".OCGOCCCCCCOccO.",
    ".OSsOCCCCCCOSsO.",
    ".OOOOCCCCCcOOOO.",
    "...OAAAAAAAAO...",
    "...OPPPPPPPpO...",
    "...OPPPPOPPpO...",
    "...OPPPO.OPpO...",
    "...OPPpO.OPpO...",
    "...OBBbO.OBbO...",
    "...OOOOO.OOOO...",
    "................",
    "................",
]

UP = [
    "................",
    "................",
    "................",
    "......OOOO......",
    "....OOHHHHOO....",
    "...OHHLLHHHHO...",
    "..OHHLHHHHHHhO..",
    "..OHHHHHHHHHhO..",
    ".OHHHHHHHHHHhhO.",
    ".OHHHHHHHHHHhhO.",
    ".OhHHHHHHHHHhhO.",
    ".OhHHHHHHHHHhhO.",
    ".OhhHHHHHHHhhhO.",
    ".OOhhHHHHHhhhOO.",
    "..OOhhhhhhhhOO..",
    "...OOsssssssO...",
    "....OOssssOO....",
    "...OOCCCCCCOO...",
    "..OCGCCCCCCccO..",
    "..OCGCCCCCCccO..",
    ".OCGOCCCCCCOccO.",
    ".OSsOCCCCCCOSsO.",
    ".OOOOCCCCCcOOOO.",
    "...OAAAAAAAAO...",
    "...OPPPPPPPpO...",
    "...OPPPPOPPpO...",
    "...OPPPO.OPpO...",
    "...OPPpO.OPpO...",
    "...OBBbO.OBbO...",
    "...OOOOO.OOOO...",
    "................",
    "................",
]

LEFT = [
    "................",
    "................",
    "................",
    "......OOOO......",
    "....OOHHHHOO....",
    "...OHHLLHHHHO...",
    "..OHHLHHHHHHhO..",
    "..OHHHHHHHHHhO..",
    "..OHHHHHHHHHhhO.",
    ".OHHhHHHHHHhhhO.",
    ".OSShSSHHHHhhhO.",
    "OSSSSSSsHHHhhO..",
    "OSWESSSsHHhhhO..",
    ".OWESSSSsHhhO...",
    "..OSSSSSsHhO....",
    "..OMSSSsOOO.....",
    "...OOssssO......",
    "....OOAAAOO.....",
    "....OCGCCcO.....",
    "....OCGCCcO.....",
    "....OCGCCcO.....",
    "....OSsOCcO.....",
    "....OOOCccO.....",
    "....OAAAAAO.....",
    ".....OPPPpO.....",
    ".....OPPPpO.....",
    ".....OPPPpO.....",
    ".....OPPPpO.....",
    "....OBBBbbO.....",
    "....OOOOOOO.....",
    "................",
    "................",
]

# Piernas al caminar (filas 23 a 29)
DOWN_STEP = [
    "...OAAAAAAAAO...",
    "...OPPPPPPPpO...",
    "...OPPPPOPPpO...",
    "...OPPPO.OPpO...",
    "...OBBbO.OPpO...",
    "...OOOOO.OBbO...",
    ".........OOOO...",
]
LEFT_STEP = [
    "....OAAAAAO.....",
    ".....OPPPpO.....",
    "....OPPOPPpO....",
    "...OPPO.OPpO....",
    "..OBPO...OPpO...",
    ".OBBbO...OBbO...",
    ".OOOO....OOOO...",
]
# Brazos al caminar (filas 20 a 22): una mano adelante y la otra atrás
DOWN_ARMS_STEP = [
    ".OCGOCCCCCCOccO.",
    ".OCGOCCCCCCOSsO.",
    ".OSsOCCCCCcOOOO.",
]
LEFT_ARMS_STEP = [
    "...OCGOCCcO.....",
    "..OSsOOCccO.....",
    "...OO.OCccO.....",
]


def frames_for(dir_):
    """Tres cuadros: quieto, paso 1, paso 2 (el paso 2 es el 1 con las piernas al revés)."""
    base = {"down": DOWN, "up": UP, "left": LEFT}[dir_]
    stand = [list(r) for r in base]
    step1 = [list(r) for r in base]
    if dir_ in ("down", "up"):
        for i, r in enumerate(DOWN_STEP):
            step1[23 + i] = list(r)
        for i, r in enumerate(DOWN_ARMS_STEP):
            step1[20 + i] = list(r)
        step2 = [list(r) for r in step1]
        for i in range(20, 30):          # piernas y brazos espejados (la cabeza no)
            step2[i] = step1[i][::-1]
            step2[i] = [_mirror_shade(ch) for ch in step2[i]]
    else:
        for i, r in enumerate(LEFT_STEP):
            step1[23 + i] = list(r)
        for i, r in enumerate(LEFT_ARMS_STEP):
            step1[20 + i] = list(r)
        step2 = [list(r) for r in base]
        # Paso 2 de costado: el cuerpo baja un píxel (balanceo)
        step2 = [list("." * W)] + step2[:-1]
    return [stand, step1, step2]


def _mirror_shade(ch):
    return ch     # (se deja igual: la luz viene de arriba a la izquierda)


# ----------------------------------------------------------------------------- peinados
def apply_style(rows, dir_, style):
    rows = [list(r) for r in rows]
    if style == "long":
        # Pelo largo hasta los hombros
        if dir_ == "down":
            for y in (14, 15, 16, 17):
                for x in (1, 2, 13, 14):
                    if rows[y][x] in ".O":
                        rows[y][x] = "h" if x in (2, 13) else "O"
            rows[18][1] = "O"; rows[18][14] = "O"
        elif dir_ == "up":
            for y in range(14, 19):
                for x in range(2, 14):
                    rows[y][x] = "h" if x in (2, 13) else ("H" if 4 <= x <= 10 else "h")
                rows[y][1] = "O"; rows[y][14] = "O"
            for x in range(1, 15):
                rows[19][x] = "O" if rows[19][x] in "Cc." else rows[19][x]
        else:
            for y in range(13, 19):
                for x in range(9, 14):
                    if rows[y][x] in ".O" or (y >= 15 and rows[y][x] in "sSO"):
                        rows[y][x] = "h"
                rows[y][14] = "O" if rows[y][14] == "." else rows[y][14]
                if rows[y][13] == "h" and rows[y][14] == ".":
                    rows[y][14] = "O"
            for x in range(9, 15):
                if rows[19][x] == ".":
                    rows[19][x] = "O"
    if style == "cap":
        # Gorra: corona arriba y visera hacia adelante
        for y in range(3, 9):
            for x in range(16):
                if rows[y][x] == "H":
                    rows[y][x] = "Q"
                elif rows[y][x] == "h":
                    rows[y][x] = "q"
                elif rows[y][x] == "L":
                    rows[y][x] = "R"
        if dir_ == "down":
            rows[8] = list(".OqQQQQQQQQQqqO.")
            rows[9] = list("OqqqqqqqqqqqqqqO")
            rows[6][7] = "A"; rows[6][8] = "A"; rows[5][7] = "A"; rows[5][8] = "A"   # emblema
        elif dir_ == "left":
            rows[8] = list("..OQQQQQQQQQqqO.")
            rows[9] = list("OqqqqqHHHHHhhhO.")
            rows[6][6] = "A"; rows[5][6] = "A"
    if style == "hood":
        # Capucha que cubre la cabeza y los costados de la cara
        for y in range(3, 17):
            for x in range(16):
                if rows[y][x] in "HL":
                    rows[y][x] = "Q"
                elif rows[y][x] == "h":
                    rows[y][x] = "q"
        if dir_ == "down":
            for y in (10, 11, 12, 13, 14):
                rows[y][2] = "q"; rows[y][13] = "q"
            rows[10] = list(".OqQQQQQQQQQqqO.")
            for x in (3, 12):
                rows[11][x] = "q"
        elif dir_ == "left":
            rows[10] = list(".OQQQQQQQQQqqqO.")
            for y in (11, 12, 13, 14):
                for x in range(7, 14):
                    if rows[y][x] in "Hhs":
                        rows[y][x] = "q"
    if style == "spiky":
        # Pelo parado
        if dir_ in ("down", "up"):
            rows[2] = list("...O..O..O..O...")
            rows[3] = list("..OHOOHOOHOOHO..")
            rows[4] = list("...OHHHHHHHHO...")
        else:
            rows[2] = list("......O..O..O...")
            rows[3] = list(".....OHOOHOOHO..")
            rows[4] = list("....OHHHHHHHHO..")
    return rows


# ----------------------------------------------------------------------------- color
def hx(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    """k < 0 oscurece (y enfría un poco), k > 0 aclara (y calienta un poco)."""
    r, g, b = c
    if k < 0:
        f = 1 + k
        return (int(r * f), int(g * f), int(min(255, b * f + 18 * -k)))
    return (int(r + (255 - r) * k), int(g + (255 - g) * k * 0.95), int(b + (255 - b) * k * 0.8))


def gba(c):
    return tuple((v >> 3) << 3 for v in c)


def palette(p):
    hair = hx(p["pelo"]); skin = hx(p.get("piel", "#f8c8a0")); top = hx(p["ropa"])
    acc = hx(p.get("detalle", "#383848")); pants = hx(p["pantalon"]); shoes = hx(p.get("zapatos", "#484050"))
    cap = hx(p.get("gorra", p["ropa"]))
    return {
        "H": hair, "h": shade(hair, -0.3), "L": shade(hair, 0.35),
        "S": skin, "s": shade(skin, -0.18), "W": (248, 248, 248), "E": hx(p.get("ojos", "#283040")),
        "M": shade(skin, -0.32),
        "C": top, "c": shade(top, -0.28), "G": shade(top, 0.3),
        "A": acc, "a": shade(acc, -0.3),
        "P": pants, "p": shade(pants, -0.28),
        "B": shoes, "b": shade(shoes, -0.3),
        "Q": cap, "q": shade(cap, -0.3), "R": shade(cap, 0.35),
    }


def render(rows, pal):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in pal:
                im.putpixel((x, y), gba(pal[ch]) + (255,))
    # Contorno: el tono más oscuro del vecino, bien oscurecido (nada de negro puro)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != "O":
                continue
            best = None
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and rows[ny][nx] in pal and rows[ny][nx] not in "WE":
                    c = pal[rows[ny][nx]]
                    if best is None or sum(c) < sum(best):
                        best = c
            col = (40, 32, 48) if best is None else shade(best, -0.72)
            im.putpixel((x, y), gba(col) + (255,))
    return im


def character(name, style="short", **p):
    pal = palette(p)
    sheet = Image.new("RGBA", (W * 3, H * 4), (0, 0, 0, 0))
    for row, d in enumerate(["down", "up", "left"]):
        for col, fr in enumerate(frames_for(d)):
            im = render(apply_style(fr, d, style), pal)
            sheet.paste(im, (col * W, row * H))
            if d == "left":
                sheet.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (col * W, 3 * H))
    sheet.save(os.path.join(OUT, name + ".png"))


# Personajes originales del Club Brasa (y los reclutas, para más adelante)
character("tomas", "spiky", pelo="#906038", ropa="#e85830", detalle="#f8d040", pantalon="#485060")
character("lucia", "long", pelo="#d05028", ropa="#f8d048", detalle="#c83030", pantalon="#784830",
          zapatos="#683020")
character("mara", "long", pelo="#e83820", ropa="#902820", detalle="#f8c048", pantalon="#302838",
          zapatos="#f8c048", ojos="#802010")
character("ayudante", "short", pelo="#383038", ropa="#f0f0f8", detalle="#3878c8", pantalon="#5070a0")
character("aprendiz", "spiky", pelo="#f0c030", ropa="#58a8e8", detalle="#f8f8f8", pantalon="#384868")
character("recluta_magma", "hood", pelo="#583020", ropa="#c83028", detalle="#383038", pantalon="#383038",
          gorra="#c83028")
character("recluta_aqua", "hood", pelo="#283048", ropa="#2860c0", detalle="#f8f8f8", pantalon="#283048",
          gorra="#2860c0")
# El protagonista está dibujado a mano aparte (tools/make_player.py)
import runpy
runpy.run_path(os.path.join(os.path.dirname(__file__), "make_player.py"), run_name="__main__")
print("personajes en", os.path.abspath(OUT))
