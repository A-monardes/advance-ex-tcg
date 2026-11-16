"""Recorta tiras de efectos de hojas de animaciones de ataques "sueltas" (cuadros sobre un
color de fondo, sin paneles), como las de fuego y veneno de Rubí/Zafiro o las de clima de
Mystery Dungeon. Complementa a tools/hoja_a_efectos.py (que es para hojas con paneles).

Uso:
    python3 tools/hoja_ataques_a_efectos.py hoja.png descripcion.json [carpeta_destino]
Destino por defecto: efectos/propios/ (no se reparte con el código).

descripcion.json (ver tools/efectos_fuego.json, efectos_veneno.json, efectos_soleado.json y
efectos_lluvia.json, que traen las posiciones de las hojas originales):
{
  "fondo": "#008080",        color de fondo (se vuelve transparente; las rayas magenta
  "tolerancia": 30,          que marcan capas en algunas hojas también se borran)
  "tiras": [
    {"nombre": "ascuas", "celda": 24, "cajas": [[x0, y0, x1, y1], ...]},
        cuadros puestos a mano, cada uno se centra en una celda cuadrada
    {"nombre": "fuego_golpe", "celda": 48, "paso": [83, 478, 34, 62, 9]},
        cuadros pegados de ancho fijo: x, y, ancho, alto, cantidad
    {"nombre": "lluvia", "pantallas": [8, 8, 248, 168, 240, 112, 61, 5]}
        pantallas enteras en grilla: x, y, paso_x, paso_y, ancho, alto, cantidad, columnas
  ]
}
"cajas" y "paso" se pueden combinar (primero las cajas). Con "pantallas", las celdas no son
cuadradas: al lado del PNG se escribe <nombre>.json con el tamaño, que el juego lee solo.
"""
import json
import os
import sys
from PIL import Image


def hexcol(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    sheet = Image.open(sys.argv[1]).convert("RGBA")
    cfg = json.load(open(sys.argv[2], encoding="utf-8"))
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "efectos", "propios")
    os.makedirs(dest, exist_ok=True)
    bg = hexcol(cfg.get("fondo", "#000000"))
    tol = int(cfg.get("tolerancia", 30))

    def key(box):
        c = sheet.crop(tuple(box))
        p = c.load()
        for y in range(c.height):
            for x in range(c.width):
                r, g, b, a = p[x, y]
                magenta = r > 150 and b > 150 and g < 80
                if magenta or a == 0 or abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= tol:
                    p[x, y] = (0, 0, 0, 0)
        return c

    for t in cfg["tiras"]:
        name = t["nombre"]
        if "pantallas" in t:
            x0, y0, sx, sy, w, h, n, cols = t["pantallas"]
            out = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
            for i in range(n):
                cx, cy = x0 + (i % cols) * sx, y0 + (i // cols) * sy
                out.alpha_composite(key((cx, cy, cx + w, cy + h)), (i * w, 0))
            out.save(os.path.join(dest, name + ".png"))
            with open(os.path.join(dest, name + ".json"), "w") as f:
                json.dump({"celda": [w, h]}, f)
            print("%-16s %d pantallas de %dx%d" % (name, n, w, h))
            continue
        boxes = [tuple(b) for b in t.get("cajas", [])]
        if "paso" in t:
            x, y, w, h, n = t["paso"]
            boxes += [(x + i * w, y, x + (i + 1) * w, y + h) for i in range(n)]
        size = int(t["celda"])
        out = Image.new("RGBA", (size * len(boxes), size), (0, 0, 0, 0))
        for i, b in enumerate(boxes):
            c = key(b)
            bb = c.getbbox()
            if bb is None:
                continue
            c = c.crop(bb)
            if c.width > size or c.height > size:
                c.thumbnail((size, size), Image.NEAREST)
            out.alpha_composite(c, (i * size + (size - c.width) // 2, (size - c.height) // 2))
        out.save(os.path.join(dest, name + ".png"))
        print("%-16s %d cuadros de %dx%d" % (name, len(boxes), size, size))


if __name__ == "__main__":
    main()
