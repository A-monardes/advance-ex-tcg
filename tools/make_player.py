"""Protagonista original, dibujado a mano píxel por píxel en el estilo de los juegos de GBA
(Ruby/Sapphire), sin copiar ningún personaje:
  - cuadro de 16x32, unos 23 píxeles de alto, cabeza grande y cuerpo corto
  - contorno de color según el material: marrón oscuro en el pelo, marrón rojizo en la piel,
    casi negro en la ropa (como en GBA, donde el contorno no es un negro parejo)
  - sombreado de 2-3 tonos con luz de arriba a la izquierda
  - pelo en punta asimétrico, vincha roja con las puntas atadas atrás, orejas que asoman
  - campera verde agua con cierre blanco, mochila amarilla, zapatillas blancas y rojas
  - caminata de 3 cuadros con brazos que se balancean

Uso: python3 tools/make_player.py  ->  mundo/personajes/jugador.png
(make_characters.py lo llama solo). Cada letra de las plantillas es un color de PAL.
"""
import os
from PIL import Image

PAL = {
 "O": "#101018",            # contorno de la ropa (casi negro)
 "N": "#182038",            # líneas internas oscuras (ojos, pliegues)
 "Q": "#3a2018",            # contorno del pelo (marrón muy oscuro)
 "H": "#7a4a30", "L": "#b07848", "D": "#523020",     # pelo
 "U": "#844038",            # contorno de la piel (marrón rojizo)
 "S": "#ffd0b0", "s": "#f0b088", "t": "#d08868",     # piel
 "R": "#e84040", "r": "#a82830",                       # vincha
 "C": "#30a8a0", "c": "#1d7470", "X": "#78d8c8", "Z": "#f8f8f0", "z": "#b8c0c8",  # campera
 "P": "#3a4878", "p": "#262f52",                       # short
 "B": "#f8f8f8", "b": "#c0c8d0", "K": "#e84040",       # zapatillas (blanco y rojo)
 "Y": "#f8c040", "y": "#c08828",                       # mochila
}
def render(rows, w=16):
    im = Image.new("RGBA", (w, len(rows)), (0,0,0,0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r))
        for x, ch in enumerate(r):
            if ch in PAL:
                h = PAL[ch].lstrip('#')
                im.putpixel((x, y), tuple(int(h[i:i+2], 16) for i in (0,2,4)) + (255,))
    return im

HAIR = [
 "........Q.......",
 "..Q....QLQ.QQ...",
 "..QLQ.QLLHQLHQ..",
 "..QHLQLLHHLHHDQ.",
 ".QHLLHHHHHHHHDQ.",
 ".QHHLHHHHHHHDDQ.",
 ".QRRRRRRRRRRRrQ.",
]
FACE_DOWN = [
 ".QDHSSSSSSSHDDQ.",
 "..USSSSSSSSSSU..",
 ".UsSNSSSSSSNssU.",
 ".UtSNSSSSSSNStU.",
 "..UsSSSttSSsU...",
 "...UUssssUU.....",
 ".....OttttO.....",
]
BODY_DOWN = [
 "....OCZZZZCO....",
 "...OXCCZZCCcO...",
 "..OXOCCZCCcOcO..",
 "..OSOCCZCCcOtO..",
 "..OOOcCZCccOOO..",
 "....OPPPPPpO....",
]
LEGS_DOWN = ["....OPpOOPpO....", "...OKBbO.OBbKO..", "...OOOOO.OOOOO..", "................"]
STEP_DOWN_BODY = {2: "..OSOCCZCCcOcO..", 3: "..OOOCCZCCcOcO..", 4: "....OcCZCccOtO..", 5: "....OPPPPPpOOO.."}
STEP_DOWN_LEGS = ["....OPpOOPpO....", "....OPpO.OKBbO..", "...OKBbO.OOOOO..", "...OOOOO........"]

BACK = [
 ".QHHHHHRrHHHHDQ.",
 "..QHHHHrRrHHDQ..",
 ".UQDHHHrHrHDDQU.",
 ".UsQDDDHDHDDQsU.",
 "...QQDDDDDDQQ...",
 "....UUssssUU....",
 ".....OttttO.....",
]
BODY_UP = [
 "....OCCCCCCO....",
 "...OXCYYYYCcO...",
 "..OXOYyyyyYOcO..",
 "..OSOYyyyyYOtO..",
 "..OOOcYYYYcOOO..",
 "....OPPPPPpO....",
]
LEGS_UP = ["....OPpOOPpO....", "...OKBbO.ObBKO..", "...OOOOO.OOOOO..", "................"]
STEP_UP_LEGS = ["....OPpOOPpO....", "....OPpO.ObBKO..", "...OKBbO.OOOOO..", "...OOOOO........"]

HAIR_LEFT = [
 ".........Q......",
 "....Q...QLQ.Q...",
 "....QLQQLLHQLQ..",
 "...QLLLHHHLHHDQ.",
 "..QLHHHHHHHHHDQ.",
 ".QHHHHHHHHHHDDQ.",
 ".QRRRRRRRRRRRrQ.",
]
FACE_LEFT = [
 ".QHSSSHHHHHHrRQ.",
 "USSSSSSUHHHDrrQ.",
 "USNSSSSUsHDDQrr.",
 ".UNSSSSSUHDDQ.r.",
 ".USSttSsUDQQ....",
 "..UUssssUU......",
 "....OttO........",
]
BODY_LEFT = [
 "....OCZCCOY.....",
 "...OCCZCcOYy....",
 "...OCOXCcOYyO...",
 "...OCOSOcOYyO...",
 "....OOOOcOYO....",
 "....OPPPpO......",
]
LEGS_LEFT = ["....OPpPpO......", "...OKBBbO.......", "...OOOOOO.......", "................"]
STEP_LEFT_BODY = {2: "...OSOXCcOYyO...", 3: "...OOOCCcOYyO...", 4: "....OcOSOOYO...."}
STEP_LEFT_LEGS = ["...OPpOPPpO.....", "..OKBbO.OBbKO...", "..OOOOO.OOOOO...", "................"]

def build(head, face, body, legs, body_over=None):
    b = list(body)
    if body_over:
        for k, v in body_over.items():
            b[k] = v
    return head + face + b + legs

def place(rows, shift_ref):
    out = ["." * 16] * (32 - len(rows)) + rows
    out = out[shift_ref:] + ["." * 16] * shift_ref if shift_ref > 0 else out
    return out

def frames():
    down = [build(HAIR, FACE_DOWN, BODY_DOWN, LEGS_DOWN),
            build(HAIR, FACE_DOWN, BODY_DOWN, STEP_DOWN_LEGS, STEP_DOWN_BODY)]
    down.append([r if i < 15 else r[::-1].replace("K", "\0").replace("\0", "K") for i, r in enumerate(down[1])])
    up = [build(HAIR, BACK, BODY_UP, LEGS_UP), build(HAIR, BACK, BODY_UP, STEP_UP_LEGS)]
    up.append([r if i < 15 else r[::-1] for i, r in enumerate(up[1])])
    left = [build(HAIR_LEFT, FACE_LEFT, BODY_LEFT, LEGS_LEFT),
            build(HAIR_LEFT, FACE_LEFT, BODY_LEFT, STEP_LEFT_LEGS, STEP_LEFT_BODY),
            build(HAIR_LEFT, FACE_LEFT, BODY_LEFT, LEGS_LEFT)]
    return down, up, left

def sheet():
    down, up, left = frames()
    S = Image.new("RGBA", (48, 128), (0, 0, 0, 0))
    for row, frs in enumerate([down, up, left]):
        # pies del cuadro quieto en la fila 29; los pasos usan el mismo corrimiento
        stand = frs[0]
        last = max(i for i, r in enumerate(stand) if r.strip("."))
        top = 29 - last
        for col, f in enumerate(frs):
            im = render(f)
            S.paste(im, (col * 16, row * 32 + top))
            if row == 2:
                S.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (col * 16, 96 + top))
    return S



if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "mundo", "personajes", "jugador.png")
    sheet().save(out)
    print("protagonista en", os.path.abspath(out))
