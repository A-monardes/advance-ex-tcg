"""Prepara el dorso de las cartas a partir de una imagen del dorso oficial. Por defecto la
deja tal cual (con el logo); con --sin-logo le saca los dos logos "POKéMON" (se tapan con el
fondo de alrededor) y deja el borde, los rayos de colores, la Poké Ball y las esferas.

Uso:
    python3 tools/armar_dorso.py dorso.png [salida.png] [--sin-logo]
Salida por defecto: mundo/propios/dorso_carta.png (no se reparte con el código). El juego lo
usa en todas las cartas boca abajo; sin esa imagen dibuja un dorso genérico.

Pensado para la imagen de 380x526 (logos amarillos arriba y abajo, esferas en las esquinas).
--sin-logo necesita opencv-python y numpy (pip install opencv-python numpy).
"""
import os
import sys



def esquinas_transparentes(path):
    """Las esquinas blancas de afuera del borde redondeado quedan transparentes."""
    from PIL import Image, ImageDraw
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    for xy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        r, g, b, a = im.getpixel(xy)
        if r > 230 and g > 230 and b > 200:
            ImageDraw.floodfill(im, xy, (0, 0, 0, 0), thresh=60)
    im.save(path)


def main():
    args = [a for a in sys.argv[1:] if a != "--sin-logo"]
    if not args:
        print(__doc__)
        sys.exit(1)
    out_path = args[1] if len(args) > 1 else os.path.join(os.path.dirname(__file__), "..", "mundo", "propios", "dorso_carta.png")
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    if "--sin-logo" not in sys.argv:
        from PIL import Image
        Image.open(args[0]).convert("RGBA").save(out_path)
        esquinas_transparentes(out_path)
        print("Dorso -> %s" % os.path.abspath(out_path))
        return
    import cv2
    import numpy as np
    im = cv2.imread(args[0])
    h, w = im.shape[:2]
    sx, sy = w / 380.0, h / 526.0          # las posiciones están medidas en la imagen de 380x526

    def X(v):
        return int(round(v * sx))

    def Y(v):
        return int(round(v * sy))

    b, g, r = [im[:, :, i].astype(int) for i in range(3)]
    yellow = (r > 170) & (g > 130) & (b < 130)
    band = np.zeros((h, w), bool)          # las dos franjas de los logos
    band[Y(28):Y(172), X(22):X(358)] = True
    band[Y(352):Y(487), X(22):X(358)] = True
    m = (yellow & band).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((21, 21), np.uint8))
    m = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (33, 33)))   # + el contorno azul
    for x, y in [(331, 152), (49, 372)]:   # las ®
        cv2.circle(m, (X(x), Y(y)), X(11), 255, -1)
    m[~band] = 0
    for cx, cy in [(45, 45), (335, 45), (45, 482), (335, 482)]:   # las esferas de las esquinas quedan
        cv2.circle(m, (X(cx), Y(cy)), X(25), 0, -1)
    out = cv2.inpaint(im, m, 25, cv2.INPAINT_TELEA)
    blur = cv2.GaussianBlur(out, (0, 0), 6)
    feather = cv2.GaussianBlur(m.astype(np.float32) / 255.0, (0, 0), 5)[:, :, None]
    res = (out * (1 - feather) + blur * feather).astype(np.uint8)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    cv2.imwrite(out_path, res)
    esquinas_transparentes(out_path)
    print("Dorso %dx%d -> %s" % (w, h, os.path.abspath(out_path)))


if __name__ == "__main__":
    main()
