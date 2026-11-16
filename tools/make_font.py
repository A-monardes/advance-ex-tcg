"""Genera fonts/gba.png + fonts/gba.fnt (BMFont de texto) desde tools/gba_font.py.
Uso: python3 tools/make_font.py"""
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import gba_font as F

OUT = os.path.join(os.path.dirname(__file__), "..", "fonts")
chars = sorted(F.G.keys(), key=ord)
cols = 16
cw = max(len(F.G[c][0]) for c in chars) + 1
rows = (len(chars) + cols - 1) // cols
img = Image.new("RGBA", (cols * cw, rows * F.H), (0, 0, 0, 0))
lines = []
for n, ch in enumerate(chars):
    g = F.G[ch]
    x0, y0 = (n % cols) * cw, (n // cols) * F.H
    for j, row in enumerate(g):
        for i, c in enumerate(row):
            if c == "#":
                img.putpixel((x0 + i, y0 + j), (255, 255, 255, 255))
    w = len(g[0])
    lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                 % (ord(ch), x0, y0, w, F.H, w + 1))
img.save(os.path.join(OUT, "gba.png"))
with open(os.path.join(OUT, "gba.fnt"), "w", encoding="utf-8") as f:
    f.write('info face="EX GBA" size=10 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0\n')
    f.write("common lineHeight=11 base=8 scaleW=%d scaleH=%d pages=1 packed=0\n" % img.size)
    f.write('page id=0 file="gba.png"\n')
    f.write("chars count=%d\n" % len(lines))
    f.write("\n".join(lines) + "\n")
print(len(chars), "glifos", img.size)
