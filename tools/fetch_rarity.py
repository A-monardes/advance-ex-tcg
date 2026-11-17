#!/usr/bin/env python3
"""Baja la rareza de cada carta (Common, Uncommon, Rare, Rare Holo, Rare Holo EX...) desde
pokemon-tcg-data y la guarda en data/rarezas.json. La usan los sobres de la campaña.
Uso: python3 tools/fetch_rarity.py"""
import json, pathlib, urllib.request
BASE = "https://raw.githubusercontent.com/PokemonTCG/pokemon-tcg-data/master/cards/en/"
OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "rarezas.json"
# Las Black Star Promos vienen todas como "Promo": en el juego todas brillan como holo,
# menos las que solo existen en reverse holo (lista de Elite Fourum), que llevan ese brillo.
PROMO_REVERSE = {3, 8, 10}
PROMO_HOLO = set(range(1, 28)) - PROMO_REVERSE
out = {}
for s in ["ex1", "ex2", "ex3", "ex4", "ex5", "ex6", "ex7", "ex8", "ex9", "pop1", "ecard1", "ecard2", "ecard3", "np"]:
    with urllib.request.urlopen(BASE + s + ".json") as r:
        for c in json.load(r):
            rar = c.get("rarity", "") or ""
            if s == "np":
                n = int(c["number"]) if c["number"].isdigit() else 0
                if not 1 <= n <= 27:
                    continue
                rar = "Promo Holo" if n in PROMO_HOLO else ("Promo Reverse" if n in PROMO_REVERSE else "Promo")
                if rar == "Promo Holo" and c["name"].endswith(" ex"):
                    rar = "Promo Holo EX"           # brillo arcoíris, como las ex de los sets
            out[c["id"]] = rar
OUT.write_text(json.dumps(out, indent=0, ensure_ascii=False))
print(len(out), "cartas")
