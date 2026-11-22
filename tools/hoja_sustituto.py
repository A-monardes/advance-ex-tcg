#!/usr/bin/env python3
"""Convierte la hoja del sustituto (Red Rescue Team) en una carpeta de sprites como las de
SpriteCollab: mundo/propios/pmd/sustituto/ con AnimData.xml, Idle, Hurt y Sleep.

La hoja (mundo/propios/sustituto_hoja.png, 128x96, fondo de color liso) tiene 4 filas:
  1 y 2: los dos cuadros de Idle, en 5 direcciones (abajo, abajo-izq, izq, arriba-izq, arriba)
  3:     dos cuadros acostado (Sleep)
  4:     Hurt en las 5 direcciones (con las gotitas)
Las direcciones que miran a la derecha se arman espejando las de la izquierda, en el orden
de filas de SpriteCollab: 0 abajo, 1 abajo-der, 2 der, 3 arriba-der, 4 arriba, 5 arriba-izq,
6 izq, 7 abajo-izq.
Uso: python3 tools/hoja_sustituto.py
"""
import pathlib
from PIL import Image, ImageOps

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "mundo/propios/sustituto_hoja.png"
OUT = ROOT / "mundo/propios/pmd/sustituto"
CW, CH = 40, 40          # celda de cada cuadro


def sprites(img, y0, y1):
    """Los sprites de una franja, de izquierda a derecha (separados por columnas vacías)."""
    band = img.crop((0, y0, img.width, y1))
    cols = [band.crop((x, 0, x + 1, band.height)).getbbox() is not None for x in range(band.width)]
    out, s = [], None
    for x, c in enumerate(cols + [False]):
        if c and s is None:
            s = x
        elif not c and s is not None:
            part = band.crop((s, 0, x, band.height))
            out.append(part.crop(part.getbbox()))
            s = None
    return out


def cell(spr):
    """El sprite centrado y apoyado abajo en una celda (los pies a 4 px del borde)."""
    c = Image.new("RGBA", (CW, CH))
    c.alpha_composite(spr, ((CW - spr.width) // 2, CH - 4 - spr.height))
    return c


def eight(five):
    """5 direcciones de la hoja (abajo, abajo-izq, izq, arriba-izq, arriba) -> las 8 de
    SpriteCollab (abajo, abajo-der, der, arriba-der, arriba, arriba-izq, izq, abajo-izq)."""
    m = lambda s: ImageOps.mirror(s)
    d, dl, l, ul, u = five
    return [d, m(dl), m(l), m(ul), u, ul, l, dl]


def sheet(frames_by_dir):
    """frames_by_dir: 8 filas (direcciones) x n cuadros."""
    n = len(frames_by_dir[0])
    img = Image.new("RGBA", (CW * n, CH * 8))
    for r, row in enumerate(frames_by_dir):
        for c, spr in enumerate(row):
            img.alpha_composite(cell(spr), (c * CW, r * CH))
    return img


def main():
    img = Image.open(SRC).convert("RGBA")
    bg = img.getpixel((0, 0))
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y] == bg:
                px[x, y] = (0, 0, 0, 0)
    idle1, idle2 = sprites(img, 0, 23), sprites(img, 23, 45)     # las filas están separadas
    sleep, hurt = sprites(img, 45, 67), sprites(img, 67, 96)     # por una línea vacía
    assert len(idle1) == len(idle2) == len(hurt) == 5 and len(sleep) == 2, (len(idle1), len(idle2), len(sleep), len(hurt))
    OUT.mkdir(parents=True, exist_ok=True)
    d1, d2, dh = eight(idle1), eight(idle2), eight(hurt)
    sheet([[d1[r], d2[r]] for r in range(8)]).save(OUT / "Idle-Anim.png")
    sheet([[dh[r]] for r in range(8)]).save(OUT / "Hurt-Anim.png")
    sheet([[sleep[0], sleep[1]] for _ in range(8)]).save(OUT / "Sleep-Anim.png")
    anim = lambda name, durs: (
        "\t\t<Anim>\n\t\t\t<Name>%s</Name>\n\t\t\t<FrameWidth>%d</FrameWidth>\n\t\t\t<FrameHeight>%d</FrameHeight>\n"
        "\t\t\t<Durations>\n%s\t\t\t</Durations>\n\t\t</Anim>\n" % (name, CW, CH, "".join("\t\t\t\t<Duration>%d</Duration>\n" % d for d in durs)))
    copy = lambda name, src: "\t\t<Anim>\n\t\t\t<Name>%s</Name>\n\t\t\t<CopyOf>%s</CopyOf>\n\t\t</Anim>\n" % (name, src)
    xml = ('<?xml version="1.0" ?>\n<AnimData>\n\t<ShadowSize>1</ShadowSize>\n\t<Anims>\n'
           + anim("Idle", [30, 30]) + anim("Hurt", [24]) + anim("Sleep", [30, 30]) + copy("Walk", "Idle")
           + "\t</Anims>\n</AnimData>\n")
    (OUT / "AnimData.xml").write_text(xml)
    (OUT / "credits.txt").write_text("Sustituto de Pokémon Mystery Dungeon: Red Rescue Team (hoja aportada por el usuario).\n")
    print("listo:", OUT)


if __name__ == "__main__":
    main()
