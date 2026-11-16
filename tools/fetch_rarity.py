#!/usr/bin/env python3
"""Baja la rareza de cada carta (Common, Uncommon, Rare, Rare Holo, Rare Holo EX...) desde
pokemon-tcg-data y la guarda en data/rarezas.json. La usan los sobres de la campaña.
Uso: python3 tools/fetch_rarity.py"""
import json, pathlib, urllib.request
BASE = "https://raw.githubusercontent.com/PokemonTCG/pokemon-tcg-data/master/cards/en/"
OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "rarezas.json"
out = {}
for s in ["ex1", "ex2", "ex3", "ex4", "ex5"]:
    with urllib.request.urlopen(BASE + s + ".json") as r:
        for c in json.load(r):
            out[c["id"]] = c.get("rarity", "")
OUT.write_text(json.dumps(out, indent=0, ensure_ascii=False))
print(len(out), "cartas")
