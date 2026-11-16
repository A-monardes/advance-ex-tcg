"""Prepara las monedas del duelo a partir de imágenes de monedas (por ejemplo las de 192x192
con fondo transparente). En cada partida el juego elige una al azar.

Uso:
    python3 tools/armar_monedas.py moneda1.png moneda2.png ... [--destino carpeta] [--tam 44]
Destino por defecto: mundo/propios/monedas/ (no se reparte con el código). Por cada imagen
escribe moneda_01.png (la cara: la imagen tal cual) y moneda_01_cruz.png (la cruz: la misma
moneda en gris y más oscura), recortadas justo al borde de la moneda y achicadas con buena
calidad al tamaño con que se ven en el juego (--tam, 44 píxeles por defecto). Borra las
monedas que hubiera antes en la carpeta.
"""
import glob
import os
import sys
from PIL import Image


def recorte_moneda(im):
    """El cuadrado justo alrededor de la moneda (sin la sombrita suave de alrededor)."""
    a = im.getchannel("A").point(lambda v: 255 if v > 200 else 0)
    box = a.getbbox() or (0, 0, im.width, im.height)
    cx, cy = (box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0
    half = max(box[2] - box[0], box[3] - box[1]) / 2.0
    return im.crop((round(cx - half), round(cy - half), round(cx + half), round(cy + half)))


def achicar(im, tam):
    return im.convert("RGBa").resize((tam, tam), Image.LANCZOS).convert("RGBA")


def cruz(im):
    """La misma moneda en gris y un poco más oscura."""
    gris = im.convert("LA").convert("RGBA")
    px = gris.load()
    for y in range(gris.height):
        for x in range(gris.width):
            r, g, b, a = px[x, y]
            v = int(r * 0.78)
            px[x, y] = (v, v, int(v * 1.04) if v * 1.04 < 255 else 255, a)
    return gris


def main():
    args = sys.argv[1:]
    dest = os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "monedas")
    tam = 44
    if "--destino" in args:
        i = args.index("--destino")
        dest = args[i + 1]
        del args[i:i + 2]
    if "--tam" in args:
        i = args.index("--tam")
        tam = int(args[i + 1])
        del args[i:i + 2]
    if not args:
        print(__doc__)
        sys.exit(1)
    os.makedirs(dest, exist_ok=True)
    for old in glob.glob(os.path.join(dest, "moneda_*.png")):
        os.remove(old)
    for n, path in enumerate(args, 1):
        im = recorte_moneda(Image.open(path).convert("RGBA"))
        cara = achicar(im, tam)
        cara.save(os.path.join(dest, "moneda_%02d.png" % n))
        cruz(cara).save(os.path.join(dest, "moneda_%02d_cruz.png" % n))
    print("%d monedas de %dx%d -> %s" % (len(args), tam, tam, os.path.abspath(dest)))


if __name__ == "__main__":
    main()
