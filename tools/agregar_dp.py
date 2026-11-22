#!/usr/bin/env python3
"""Agrega Diamond & Pearl (dp1) y las promos DP01-DP04 a data/cards_adv.json sin tocar lo demás.

Eran legales en el Mundial 2007 (Hawái, 10-12 de agosto). Mysterious Treasures salió el 22 de
agosto, después. Si las cartas ya están, las reemplaza (vuelve a correr sin duplicar).
DP trae dos cosas que la era EX no tenía en los datos:
  - "weakness_plus": {"Fire": 20}  debilidad +N en vez de x2 (DP1 usa +10/+20/+30).
  - "level": "X"                    Pokémon LV.X (subtipo "Level-Up").
Uso: python3 tools/agregar_dp.py
"""
import json, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from fetch_cards import BASE, get, slim

OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "cards_adv.json"
SETS = {"dp1": None, "dpp": ["DP01", "DP02", "DP03", "DP04"]}


def slim_dp(card, info):
    c = slim(card, info)
    if card["supertype"] == "Pokémon":
        plus = {}
        for w in card.get("weaknesses", []):
            v = str(w.get("value", ""))
            if v.startswith("+"):
                plus[w["type"]] = int(v[1:])
        if plus:
            c["weakness_plus"] = plus
        if card.get("level"):
            c["level"] = card["level"]
        if "Level-Up" in c["subtypes"]:
            c["text"] = " ".join(card.get("rules", []))
    if card["id"].startswith("dpp-"):
        c["id"] = "dpp-" + str(int(card["number"][2:]))
        c["number"] = str(int(card["number"][2:]))
    return c


def main():
    sets = {s["id"]: s for s in get(f"{BASE}/sets/en.json")}
    cards = json.loads(OUT.read_text())
    new = []
    for sid, only in SETS.items():
        data = get(f"{BASE}/cards/en/{sid}.json")
        if only:
            data = [c for c in data if c["number"] in only]
        new += [slim_dp(c, sets[sid]) for c in data]
        print(f"{sid:5} {sets[sid]['name']:28} {len(data)} cartas")
    ids = {c["id"] for c in new}
    cards = [c for c in cards if c["id"] not in ids] + new
    OUT.write_text(json.dumps(cards, ensure_ascii=False, separators=(",", ":")))
    print(f"Total: {len(cards)} cartas -> {OUT}")


if __name__ == "__main__":
    main()
