"""Convierte una hoja de letras pixel (una imagen con filas de caracteres) en una fuente
para el juego: fonts/propia.fnt + fonts/propia.png. Si esos archivos existen, el juego los
usa en lugar de la letra original (los caracteres que falten salen de la original).

Uso:
    python3 tools/hoja_a_fuente.py hoja.png descripcion.json [carpeta_destino]

descripcion.json dice dónde está cada fila de letras en la hoja:
{
  "tinta": 300,            # un píxel es letra si R+G+B es menor que esto (oscuro)
  "ignorar": ["#00c8b8"],  # colores oscuros que NO son letra (marcos, adornos)
  "espacio": 4,            # avance del espacio
  "separacion": 2,         # píxeles entre letra y letra
  "filas": [
    {"y": [268, 276], "x": [20, 207], "arriba": 268, "letras": "ABCDEFGHIJKLMNOPQRSTUVWXYZ"},
    ...
  ]
}
  y       primera y última fila de píxeles de esa línea (con tildes y colas)
  x       desde dónde hasta dónde mirar
  arriba  la fila donde empiezan las mayúsculas (para alinear todas las líneas)
  letras  los caracteres en orden; cada letra es un bloque de columnas con tinta separado
          por columnas vacías. Un "_" saltea un bloque (algo que no querés), y "{2}x"
          junta 2 bloques en la letra x (para signos de dos partes, como las comillas).

Las letras se guardan sin la sombra de la hoja: el juego dibuja su propia sombra.
"""
import json
import os
import re
import sys
from PIL import Image

CELL_H = 10      # alto de la celda de la fuente del juego (fila 1 = arriba de las mayúsculas)


def hexcol(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def parse_letters(spec):
    out = []
    i = 0
    while i < len(spec):
        m = re.match(r"\{(\d+)\}", spec[i:])
        if m:
            n = int(m.group(1))
            i += len(m.group(0))
            out.append((spec[i], n))
        else:
            out.append((spec[i], 1))
        i += 1
    return out


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    sheet = Image.open(sys.argv[1]).convert("RGB")
    cfg = json.load(open(sys.argv[2], encoding="utf-8"))
    dest = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(__file__), "..", "fonts")
    limit = cfg.get("tinta", 300)
    skip = {hexcol(c) for c in cfg.get("ignorar", [])}
    gap = cfg.get("separacion", 2)

    def ink(x, y):
        c = sheet.getpixel((x, y))
        return sum(c) < limit and c not in skip

    glyphs = {}      # char -> (rows: list of str '#'/'.', top_offset)
    for row in cfg["filas"]:
        y0, y1 = row["y"]
        x0, x1 = row["x"]
        top = row["arriba"]
        # Bloques de columnas con tinta
        blocks = []
        start = None
        for x in range(x0, x1 + 1):
            has = x <= x1 - 1 and any(ink(x, y) for y in range(y0, y1 + 1))
            if has and start is None:
                start = x
            if not has and start is not None:
                blocks.append((start, x - 1))
                start = None
        letters = parse_letters(row["letras"])
        bi = 0
        for ch, n in letters:
            if bi + n > len(blocks):
                print("  ¡Faltan bloques en la fila %s para '%s'!" % (row["y"], ch))
                break
            bx0 = blocks[bi][0]
            bx1 = blocks[bi + n - 1][1]
            bi += n
            if ch == "_":
                continue
            bm = []
            for y in range(y0, y1 + 1):
                bm.append("".join("#" if ink(x, y) else "." for x in range(bx0, bx1 + 1)))
            # Recortar filas vacías arriba y abajo
            first = next(i for i, r in enumerate(bm) if "#" in r)
            last = max(i for i, r in enumerate(bm) if "#" in r)
            rel_top = y0 + first - top          # fila donde empieza la tinta, relativa a "arriba"
            bm = bm[first:last + 1]
            # Tildes de las mayúsculas: si hay un hueco entre la tilde y la letra por encima de
            # "arriba", se saca ese hueco para que la tilde quede pegada (cabe en la celda).
            if rel_top < -1:
                gap_row = -1 - rel_top           # índice de la fila justo encima de "arriba"
                if 0 <= gap_row < len(bm) and "#" not in bm[gap_row]:
                    bm = bm[:gap_row] + bm[gap_row + 1:]
                    rel_top += 1
            glyphs[ch] = (bm, rel_top)
        if bi < len(blocks):
            print("  fila %s: sobran %d bloques (se ignoran)" % (row["y"], len(blocks) - bi))

    # Armar la imagen y el .fnt (formato BMFont de texto, igual que fonts/gba.fnt)
    chars = sorted(glyphs)
    pad = 1
    sheet_w = 256
    x = y = 0
    row_h = 0
    places = {}
    for ch in chars:
        bm, _ = glyphs[ch]
        w = len(bm[0])
        h = len(bm)
        if x + w + pad > sheet_w:
            x = 0
            y += row_h + pad
            row_h = 0
        places[ch] = (x, y)
        x += w + pad
        row_h = max(row_h, h)
    sheet_h = y + row_h + 1
    out = Image.new("RGBA", (sheet_w, max(8, sheet_h)), (0, 0, 0, 0))
    lines = []
    for ch in chars:
        bm, rel_top = glyphs[ch]
        px, py = places[ch]
        for j, r in enumerate(bm):
            for i, c in enumerate(r):
                if c == "#":
                    out.putpixel((px + i, py + j), (255, 255, 255, 255))
        w = len(bm[0])
        lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15"
                     % (ord(ch), px, py, w, len(bm), rel_top + 1, w + gap))
    lines.append("char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                 % cfg.get("espacio", 4))
    os.makedirs(dest, exist_ok=True)
    out.save(os.path.join(dest, "propia.png"))
    with open(os.path.join(dest, "propia.fnt"), "w", encoding="utf-8") as f:
        f.write('info face="Propia" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0\n' % CELL_H)
        f.write("common lineHeight=11 base=8 scaleW=%d scaleH=%d pages=1 packed=0\n" % (sheet_w, out.height))
        f.write('page id=0 file="propia.png"\n')
        f.write("chars count=%d\n" % len(lines))
        f.write("\n".join(lines) + "\n")
    print("%d letras -> %s" % (len(lines), os.path.abspath(os.path.join(dest, "propia.fnt"))))


if __name__ == "__main__":
    main()
