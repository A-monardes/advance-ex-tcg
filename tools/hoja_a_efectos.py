"""Recorta una hoja de efectos de ataque (paneles con un color de fondo liso) en tiras para
el juego: efectos/propios/<nombre>.png. Si esas tiras existen, los ataques especiales de
scenes/special_fx.gd las usan; si no, dibujan los efectos a mano.

Uso:
    python3 tools/hoja_a_efectos.py hoja.png descripcion.json [carpeta_destino]

descripcion.json (ver tools/efectos_ejemplo.json):
{
  "paneles": {
    "llama": {"buscar": [140, 1285, 190, 1550], "fondo": ["#60c0c0"], "alto": 32},
    ...
  },
  "grandes": {
    "ola": {"cuadros": [[130, 1732, 258, 1796], [130, 1796, 258, 1860]], "fondo": ["#689088", "#6058f8"],
            "borrar": [[0, 96, 0, 128, 16]]}
  }
}
  paneles  un panel = un rectángulo de color liso con los cuadros uno debajo del otro.
           buscar  zona donde está el panel (x0, y0, x1, y1); se toma el área más grande
                   del color de fondo y su rectángulo.
           fondo   colores que se vuelven transparentes (el primero es el del panel).
           alto    alto de cada cuadro (el ancho es el del panel).
  grandes  cuadros sueltos (rectángulos exactos), para efectos más grandes que un panel.
           Cada cuadro se centra abajo en un cuadrado. "borrar": [cuadro, x0, y0, x1, y1]
           limpia restos de otros dibujos.

Las tiras salen con cuadros cuadrados uno al lado del otro (cuadros = ancho / alto).
Son para tu copia: no se reparten con el código (.gitignore).
"""
import json
import os
import sys
from collections import deque
from PIL import Image


def hexcol(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    im = Image.open(sys.argv[1]).convert("RGB")
    px = im.load()
    cfg = json.load(open(sys.argv[2], encoding="utf-8"))
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "efectos", "propios")
    os.makedirs(dest, exist_ok=True)

    def panel(box, bg):
        x0, y0, x1, y1 = box
        seen = set()
        best = []
        for y in range(y0, y1):
            for x in range(x0, x1):
                if (x, y) in seen or px[x, y] != bg:
                    continue
                q = deque([(x, y)])
                seen.add((x, y))
                pts = []
                while q:
                    a, b = q.popleft()
                    pts.append((a, b))
                    for c, d in ((a + 1, b), (a - 1, b), (a, b + 1), (a, b - 1)):
                        if x0 <= c < x1 and y0 <= d < y1 and (c, d) not in seen and px[c, d] == bg:
                            seen.add((c, d))
                            q.append((c, d))
                if len(pts) > len(best):
                    best = pts
        if not best:
            return None
        xs = [p[0] for p in best]
        ys = [p[1] for p in best]
        return min(xs), min(ys), max(xs) + 1, max(ys) + 1

    def key(box, bgs):
        x0, y0, x1, y1 = box
        c = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        for y in range(y0, y1):
            for x in range(x0, x1):
                if px[x, y] not in bgs:
                    c.putpixel((x - x0, y - y0), px[x, y] + (255,))
        return c

    def save(name, cells, size, bottom=False):
        out = Image.new("RGBA", (size * len(cells), size), (0, 0, 0, 0))
        for i, c in enumerate(cells):
            y = size - c.height if bottom else (size - c.height) // 2
            out.paste(c, (i * size + (size - c.width) // 2, y))
        out.save(os.path.join(dest, name + ".png"))
        print("%-10s %d cuadros de %dx%d" % (name, len(cells), size, size))

    for name, p in cfg.get("paneles", {}).items():
        bgs = [hexcol(c) for c in p["fondo"]]
        box = panel(p["buscar"], bgs[0])
        if box is None:
            print("%-10s ¡no encontré el color de fondo %s!" % (name, p["fondo"][0]))
            continue
        x0, y0, x1, y1 = box
        ch = p.get("alto", x1 - x0)
        cells = []
        for i in range(round((y1 - y0) / ch)):
            c = key((x0, y0 + i * ch, x1, min(y1, y0 + (i + 1) * ch)), bgs)
            if c.getbbox():
                cells.append(c)
        save(name, cells, max(x1 - x0, ch))
    for name, g in cfg.get("grandes", {}).items():
        bgs = [hexcol(c) for c in g["fondo"]]
        cells = [key(tuple(b), bgs) for b in g["cuadros"]]
        for i, x0, y0, x1, y1 in g.get("borrar", []):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    cells[i].putpixel((x, y), (0, 0, 0, 0))
        save(name, cells, max(max(c.width, c.height) for c in cells), bottom=True)


if __name__ == "__main__":
    main()
