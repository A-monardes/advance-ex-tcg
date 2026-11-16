"""Prepara las imágenes de la tienda de cartas: el fondo de pantalla entera y la vendedora
(Bridgette) con sus caras para parpadear y sonreír.

Uso:
    python3 tools/armar_tienda.py fondo.png hoja_bridgette.png [carpeta_destino]
Destino por defecto: mundo/propios/ (no se reparte con el código). Escribe:
    tienda_fondo.png   el fondo achicado a 240x160 (sin deformar; recorta lo que sobra)
    bridgette.png      la vendedora en 7 cuadros: normal, medio parpadeo, ojos cerrados,
                       contenta (ojos ^^ y boca abierta) y los tres primeros con la boca
                       abierta (habla), con el fondo gris transparente
    bridgette.json     tamaño de cada cuadro, dónde se dibuja en la pantalla y qué cuadro
                       es cada cara (lo lee el juego; se puede editar a mano)

La hoja de Bridgette es la de 567x673: el retrato sin ojos ni boca arriba a la izquierda
(sobre gris oscuro) y abajo 4 pares de ojos y 2 bocas. Las caras se ubican solas sobre el
retrato (se busca dónde calzan mejor el pelo y la piel de alrededor).
"""
import json
import os
import sys
from PIL import Image

W, H = 240, 160
RETRATO = (2, 2, 413, 604)                    # el retrato, sin el borde celeste
OJOS = [(2, 116), (119, 232), (235, 349), (351, 465)]   # columnas de cada par de ojos
OJOS_Y = (607, 672)
BOCAS = [(467, 515), (517, 565)]
BOCAS_Y = (607, 629)
# Qué ojos y qué boca lleva cada cuadro: normal, medio parpadeo, cerrados, contenta y
# los tres primeros otra vez con la boca abierta (para cuando habla)
CARAS = [(0, 0), (1, 0), (2, 0), (3, 1), (0, 1), (1, 1), (2, 1)]
ESCALA = 0.25                                 # tamaño en pantalla (0.25 = un cuarto)
POS = (128, 4)                                # esquina de arriba a la izquierda en pantalla


def cover(img, w, h):
    k = max(w / img.width, h / img.height)
    big = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    x0 = (big.width - w) // 2
    y0 = (big.height - h) // 2
    return big.crop((x0, y0, x0 + w, y0 + h))


def calce(base, parte, zona):
    """Dónde va `parte` sobre `base` (busca en `zona` = (x0, y0, x1, y1))."""
    import numpy as np
    b = np.asarray(base.convert("RGB")).astype(int)
    p = np.asarray(parte.convert("RGB")).astype(int)
    h, w = p.shape[:2]
    best = (-1.0, 0, 0)
    for y in range(zona[1], zona[3]):
        for x in range(zona[0], zona[2]):
            reg = b[y:y + h, x:x + w]
            if reg.shape != p.shape:
                continue
            sc = (np.abs(reg - p).sum(2) < 24).mean()
            if sc > best[0]:
                best = (sc, x, y)
    return best[1], best[2]


def transparente(img, tol=14):
    """Vuelve transparente el gris de fondo que toca el borde (no el de adentro)."""
    img = img.convert("RGBA")
    p = img.load()
    w, h = img.size
    bg = p[0, 0][:3]
    pend = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    seen = set()
    while pend:
        x, y = pend.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        r, g, b, a = p[x, y]
        if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > tol:
            continue
        seen.add((x, y))
        p[x, y] = (0, 0, 0, 0)
        pend += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return img


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "mundo", "propios")
    os.makedirs(dest, exist_ok=True)
    fondo = cover(Image.open(sys.argv[1]).convert("RGB"), W, H)
    fondo.save(os.path.join(dest, "tienda_fondo.png"))
    print("tienda_fondo.png %dx%d" % fondo.size)

    hoja = Image.open(sys.argv[2]).convert("RGB")
    retrato = hoja.crop(RETRATO)
    ojos = [hoja.crop((a, OJOS_Y[0], b, OJOS_Y[1])) for a, b in OJOS]
    bocas = [hoja.crop((a, BOCAS_Y[0], b, BOCAS_Y[1])) for a, b in BOCAS]
    zona_ojos = (40, 60, retrato.width - 120, retrato.height // 2)
    zona_boca = (80, 120, retrato.width - 50, retrato.height // 2)
    pos_ojos = [calce(retrato, o, zona_ojos) for o in ojos]
    pos_bocas = [calce(retrato, b, zona_boca) for b in bocas]
    print("ojos en", pos_ojos, "bocas en", pos_bocas)
    cw, ch = round(retrato.width * ESCALA), round(retrato.height * ESCALA)
    tira = Image.new("RGBA", (cw * len(CARAS), ch), (0, 0, 0, 0))
    for i, (o, b) in enumerate(CARAS):
        cara = retrato.copy()
        cara.paste(ojos[o], pos_ojos[o])
        cara.paste(bocas[b], pos_bocas[b])
        cara = transparente(cara).convert("RGBa").resize((cw, ch), Image.LANCZOS).convert("RGBA")
        tira.alpha_composite(cara, (i * cw, 0))
    tira.save(os.path.join(dest, "bridgette.png"))
    info = {"celda": [cw, ch], "x": POS[0], "y": POS[1],
            "normal": 0, "parpadeo": [1, 2, 1], "feliz": 3, "hablar": [4, 5, 6]}
    with open(os.path.join(dest, "bridgette.json"), "w") as f:
        json.dump(info, f, indent=2)
    print("bridgette.png %d caras de %dx%d" % (len(CARAS), cw, ch))


if __name__ == "__main__":
    main()
