#!/usr/bin/env python3
"""Rangos de líneas de las secciones de scenes/duel.gd cuyo título contiene el texto dado."""
import sys, os
L = open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scenes", "duel.gd"), encoding="utf-8").read().split("\n")
heads = [i for i, l in enumerate(L) if (l.startswith("# ====") or l.startswith("# ----")) and i + 2 < len(L) and L[i + 2][:6] == l[:6]]
out = []
import re
for want in sys.argv[1:]:
    if re.fullmatch(r"\d+-\d+", want):
        out.append(want)
        continue
    for k, s in enumerate(heads):
        if want in L[s + 1]:
            e = heads[k + 1] - 1 if k + 1 < len(heads) else len(L) - 1
            while e > s and L[e].strip() == "":
                e -= 1
            out.append(f"{s + 1}-{e + 1}")
            break
    else:
        sys.exit("no encontré: " + want)
print(" ".join(out))
