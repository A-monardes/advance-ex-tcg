#!/usr/bin/env python3
"""Compara dos carpetas de capturas (tests/golden_shots.gd).

Uso: comparar_capturas.py base nueva [ruido]
  ruido: otra carpeta con la base sacada de nuevo; los píxeles que cambian entre base y
  ruido (brillos, cursores que parpadean) no se cuentan.
"""
import sys, os
from PIL import Image, ImageChops

base, nueva = sys.argv[1], sys.argv[2]
ruido = sys.argv[3] if len(sys.argv) > 3 else None
mal = 0
for f in sorted(os.listdir(base)):
    if not f.endswith(".png"):
        continue
    a = Image.open(os.path.join(base, f)).convert("RGB")
    pb = os.path.join(nueva, f)
    if not os.path.exists(pb):
        print(f"FALTA  {f}")
        mal += 1
        continue
    b = Image.open(pb).convert("RGB")
    d = ImageChops.difference(a, b).convert("L").point(lambda v: 255 if v else 0)
    if ruido and os.path.exists(os.path.join(ruido, f)):
        r = ImageChops.difference(a, Image.open(os.path.join(ruido, f)).convert("RGB")).convert("L").point(lambda v: 255 if v else 0)
        d = ImageChops.subtract(d, r)
    n = sum(1 for v in d.getdata() if v)
    print(("ok     " if n == 0 else "DISTINTA") + f" {f}  ({n} px)")
    if n:
        mal += 1
        d.save(os.path.join(nueva, "diff_" + f))
print("todo igual" if mal == 0 else f"{mal} distinta(s)")
sys.exit(1 if mal else 0)
