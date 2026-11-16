"""Prepara los íconos de los tipos (los círculos de Energía) a partir de dos imágenes: la de
las "pastillas" de tipos (Grass, Fire, Water... cada una con su círculo a la izquierda) y la
de Incolora / arcoíris ("★ or 🌈").

Uso:
    python3 tools/armar_tipos.py pastillas.png incolora_arcoiris.png [carpeta_destino]
Destino por defecto: mundo/propios/tipos/ (no se reparte con el código). Escribe
energy_grass.png, energy_fire.png, ..., energy_colorless.png y energy_rainbow.png: cada
círculo recortado con el borde suave y fondo transparente, en su tamaño original. El juego
los achica con buena calidad al tamaño de cada lugar (la ficha de la carta, el costo de los
ataques, las Energías unidas, el texto).

Las posiciones están medidas en las imágenes de 489x171 y 103x37; si las imágenes son de
otro tamaño, se escalan.
"""
import os
import sys
from PIL import Image, ImageDraw

# tipo: (centro x, centro y, radio) en la imagen de pastillas de 489x171
PASTILLAS = {
    "grass": (23.0, 33.5, 21.0), "fire": (198.0, 33.5, 21.0), "water": (352.0, 33.5, 21.0),
    "lightning": (23.0, 90.0, 21.0), "psychic": (198.0, 90.0, 21.0), "fighting": (352.0, 90.0, 21.0),
    "darkness": (23.0, 146.5, 21.0), "metal": (198.0, 146.5, 21.0),
}
# en la imagen de 103x37 ("★ or 🌈")
EXTRA = {"colorless": (21.5, 20.5, 15.0), "rainbow": (83.5, 20.5, 15.0)}
SS = 8      # sobremuestreo del borde del círculo


def circulo(img, cx, cy, r, aro=False):
    x0, y0 = int(cx - r - 1), int(cy - r - 1)
    size = int(2 * r + 3)
    crop = img.crop((x0, y0, x0 + size, y0 + size)).convert("RGBA")
    mask = Image.new("L", (size * SS, size * SS), 0)
    ccx, ccy = (cx - x0) * SS, (cy - y0) * SS
    ImageDraw.Draw(mask).ellipse((ccx - r * SS, ccy - r * SS, ccx + r * SS, ccy + r * SS), fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    alpha = Image.new("L", (size, size), 0)
    alpha.paste(crop.getchannel("A"), (0, 0), mask)
    crop.putalpha(alpha)
    if aro:     # los íconos blancos (Incolora, arcoíris) llevan un aro gris para no perderse
        ring = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
        w = int(r * SS * 0.16)
        ImageDraw.Draw(ring).ellipse((ccx - r * SS + w / 2, ccy - r * SS + w / 2, ccx + r * SS - w / 2, ccy + r * SS - w / 2),
                                     outline=(84, 84, 96, 255), width=w)
        crop.alpha_composite(ring.resize((size, size), Image.LANCZOS))
    return crop


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "tipos")
    os.makedirs(dest, exist_ok=True)
    for path, table, base in ((sys.argv[1], PASTILLAS, (489, 171)), (sys.argv[2], EXTRA, (103, 37))):
        img = Image.open(path).convert("RGBA")
        k = img.width / base[0]
        for name, (cx, cy, r) in table.items():
            circulo(img, cx * k, cy * k, r * k, table is EXTRA).save(os.path.join(dest, "energy_%s.png" % name))
            print("energy_%s.png" % name)


if __name__ == "__main__":
    main()
