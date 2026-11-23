"""Prepara los logos de los equipos (Team Aqua, Team Magma, Team Rocket) que se ven en la pelea
(arriba del Pokémon al empezar, y se desvanecen) y de fondo en la ficha del Activo.

Uso:
    python3 tools/armar_equipos.py --aqua aqua.png --magma magma.png --rocket rocket.png [--destino carpeta]
Destino por defecto: mundo/propios/equipos/ (no se reparte con el código). Por cada equipo escribe:
  <equipo>.png         el logo en pixel art de 14 píxeles de alto, con los colores del logo
                       reducidos a su paleta y un borde oscuro de 1 píxel (la pelea).
  <equipo>_fuente.png  el logo recortado, sin fondo, de 256 píxeles de alto (de ahí el juego
                       saca la marca de agua de la ficha, al tamaño que haga falta).
Si la imagen trae fondo blanco (el logo de Magma), se vuelve transparente el blanco que toca
los bordes (también el hueco del arco, que llega al borde de abajo).
"""
import argparse
import os
from collections import deque

import numpy as np
from PIL import Image

ALTO = 14
ALTO_FUENTE = 256
BORDE = (24, 16, 24)
# Colores de cada logo (el pixel art usa solo estos)
PALETA = {
    "aqua": [(35, 31, 32), (229, 244, 252), (85, 184, 232)],
    "magma": [(35, 25, 28), (208, 24, 31), (70, 48, 54)],
    "rocket": [(200, 0, 0)],
}


def sin_fondo_blanco(im):
    """El blanco conectado a los bordes pasa a transparente."""
    rgb = np.array(im.convert("RGB")).astype(int)
    alfa = np.array(im.getchannel("A"))
    blanco = (rgb.min(2) > 235) & (alfa > 0)
    h, w = blanco.shape
    visto = np.zeros_like(blanco)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if blanco[y, x] and not visto[y, x]:
                visto[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if blanco[y, x] and not visto[y, x]:
                visto[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < w and blanco[yy, xx] and not visto[yy, xx]:
                visto[yy, xx] = True
                q.append((yy, xx))
    alfa = np.where(visto, 0, alfa).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb.astype(np.uint8), alfa]), "RGBA")


def cargar(ruta):
    im = Image.open(ruta).convert("RGBA")
    if im.getpixel((0, 0))[3] > 0:          # fondo opaco: se saca el blanco
        im = sin_fondo_blanco(im)
    return im.crop(im.getbbox())


def pixel_art(im, equipo):
    ancho = round(im.width * ALTO / im.height)
    chico = np.array(im.convert("RGBa").resize((ancho, ALTO), Image.LANCZOS).convert("RGBA")).astype(float)
    pal = np.array(PALETA[equipo], float)
    out = np.zeros((ALTO + 2, ancho + 2, 4), np.uint8)
    for y in range(ALTO):
        for x in range(ancho):
            if chico[y, x, 3] > 110:
                i = int(np.argmin(((pal - chico[y, x, :3]) ** 2).sum(1)))
                out[y + 1, x + 1] = list(map(int, pal[i])) + [255]
    lleno = out[:, :, 3] > 0
    anillo = np.zeros_like(lleno)
    anillo[1:] |= lleno[:-1]
    anillo[:-1] |= lleno[1:]
    anillo[:, 1:] |= lleno[:, :-1]
    anillo[:, :-1] |= lleno[:, 1:]
    anillo &= ~lleno
    out[anillo] = list(BORDE) + [255]
    return Image.fromarray(out, "RGBA")


def main():
    ap = argparse.ArgumentParser()
    for e in PALETA:
        ap.add_argument("--" + e, required=True)
    ap.add_argument("--destino", default=os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "equipos"))
    args = ap.parse_args()
    os.makedirs(args.destino, exist_ok=True)
    for e in PALETA:
        im = cargar(getattr(args, e))
        pixel_art(im, e).save(os.path.join(args.destino, e + ".png"))
        ancho = round(im.width * ALTO_FUENTE / im.height)
        im.resize((ancho, ALTO_FUENTE), Image.LANCZOS).save(os.path.join(args.destino, e + "_fuente.png"))
        print("listo:", e)


if __name__ == "__main__":
    main()
