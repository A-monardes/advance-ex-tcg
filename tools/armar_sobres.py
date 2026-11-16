"""Prepara las imágenes de los sobres de cada expansión (ex1 a ex5): se ven en la tienda al
marcar un sobre y en la animación de abrir un sobre.

Uso:
    python3 tools/armar_sobres.py ex1.png ex2.png ex3.png ex4.png ex5.png [--destino carpeta]
Una imagen por expansión, en orden (ex1 Ruby & Sapphire ... ex5 Hidden Legends). A cada una
se le puede pegar un recorte en píxeles de la imagen original, para quedarse con una parte:
    ex4.png:0,0,1410,1890      (x0,y0,x1,y1)
Lo que no entra en la proporción del sobre se recorta del centro.

Destino por defecto: mundo/propios/ (no se reparte con el código). Escribe, por expansión:
    sobre_ex1.png         60x84   (la tienda)
    sobre_ex1_grande.png  80x112  (la animación al abrirlo)
El juego les dibuja alrededor el envoltorio (los bordes plateados arriba y abajo).
"""
import os
import sys
from PIL import Image

SETS = ["ex1", "ex2", "ex3", "ex4", "ex5"]
SIZES = {"": (60, 84), "_grande": (80, 112)}


def cover(img, w, h):
    k = max(w / img.width, h / img.height)
    big = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    x0 = (big.width - w) // 2
    y0 = (big.height - h) // 2
    return big.crop((x0, y0, x0 + w, y0 + h))


def main():
    args = sys.argv[1:]
    dest = os.path.join(os.path.dirname(__file__), "..", "mundo", "propios")
    if "--destino" in args:
        i = args.index("--destino")
        dest = args[i + 1]
        del args[i:i + 2]
    if not args:
        print(__doc__)
        sys.exit(1)
    os.makedirs(dest, exist_ok=True)
    for set_id, arg in zip(SETS, args):
        path, _, box = arg.partition(":")
        img = Image.open(path).convert("RGB")
        if box:
            img = img.crop(tuple(int(v) for v in box.split(",")))
        for suffix, (w, h) in SIZES.items():
            cover(img, w, h).save(os.path.join(dest, "sobre_%s%s.png" % (set_id, suffix)))
        print("%s <- %s" % (set_id, arg))


if __name__ == "__main__":
    main()
