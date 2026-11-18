#!/usr/bin/env python3
"""Descarga las cartas desde pokemon-tcg-data y genera data/cards_adv.json
con solo los campos que usa el juego.

Por defecto baja la era ADV japonesa (ADV Expansion Pack -> Undone Seal),
que en inglés corresponde a:
  ex1 Ruby & Sapphire        (ADV Expansion Pack)
  ex2 Sandstorm              (Miracle of the Desert)
  ex3 Dragon                 (Rulers of the Heavens)
  ex4 Team Magma vs Team Aqua (Magma VS Aqua: Two Ambitions)
  ex5 Hidden Legends         (Undone Seal)

Uso:  python3 tools/fetch_cards.py              # temporada 2003-04: e-card completos + era ADV
      python3 tools/fetch_cards.py --all        # además, los 16 sets EX
"""
import json
import pathlib
import sys
import urllib.request

BASE = "https://raw.githubusercontent.com/PokemonTCG/pokemon-tcg-data/master"
ADV_SETS = [f"ex{i}" for i in range(1, 17)] + ["pop1", "pop2", "pop3", "pop4", "pop5"]  # Ruby & Sapphire ... Power Keepers, más POP Series 1-5
ALL_EX_SETS = [f"ex{i}" for i in range(1, 17)] + ["pop1"]  # ... hasta Power Keepers
# Temporada 2003-04 (Expedition-on): los tres sets e-card enteros.
ECARD_SETS = ["ecard1", "ecard2", "ecard3"]     # Expedition, Aquapolis, Skyridge
# Cartas de sets anteriores (era e-Reader) que seguían siendo legales en el Mundial 2004 y
# aparecen en los mazos de campeonato incluidos. Solo se agregan estas, no los sets enteros.
EXTRA_CARDS = {
    "ecard1": ["138", "145", "148", "149"],          # Copycat, Pokémon Nurse, Prof. Elm's Training Method, Prof. Oak's Research
    "ecard2": ["130", "136", "141", "145", "147"],   # Pokémon Fan Club, Town Volunteers, Weakness Guard, Boost Energy, Warp Energy
    "ecard3": ["123", "126", "138", "140"],          # Desert Shaman, Friend Ball, Oracle, Underground Expedition
}
# Nintendo Black Star Promos de la era EX (001-040).
PROMO_SETS = {"np": 40}
TOOL_FIX = {"Weakness Guard"}   # en esa época las herramientas no tenían el subtipo "Pokémon Tool"
OUT = pathlib.Path(__file__).resolve().parent.parent / "data" / "cards_adv.json"


def get(url):
    with urllib.request.urlopen(url) as r:
        return json.load(r)


def damage_value(text):
    """'50+' -> 50, '30x' -> 30, '' -> 0"""
    digits = "".join(c for c in (text or "") if c.isdigit())
    return int(digits) if digits else 0


def slim(card, set_info):
    c = {
        "id": card["id"],
        "name": card["name"],
        "set": set_info["name"],
        "number": card["number"],
        "supertype": card["supertype"],          # Pokémon / Trainer / Energy
        "subtypes": card.get("subtypes", []),    # Basic, Stage 1, EX, Supporter, Stadium...
        "artist": card.get("artist", ""),        # ilustrador (vista de galería)
    }
    if card["supertype"] == "Pokémon":
        c.update({
            "hp": int(card.get("hp", 0) or 0),
            "types": card.get("types", []),
            "evolves_from": card.get("evolvesFrom", ""),
            "retreat": len(card.get("retreatCost", [])),
            "weaknesses": [w["type"] for w in card.get("weaknesses", [])],
            "resistances": [r["type"] for r in card.get("resistances", [])],
            "abilities": [
                {"name": a["name"], "kind": a["type"], "text": a.get("text", "")}
                for a in card.get("abilities", [])
            ],
            "attacks": [
                {
                    "name": a["name"],
                    "cost": a.get("cost", []),
                    "damage": damage_value(a.get("damage")),
                    "damage_text": a.get("damage", ""),
                    "text": a.get("text", ""),
                }
                for a in card.get("attacks", [])
            ],
        })
    else:
        c["text"] = " ".join(card.get("rules", []))
        if card.get("hp"):                       # Fósiles: se juegan como Básicos
            c["hp"] = int(card["hp"])
        if card.get("attacks"):                  # Technical Machines
            c["attacks"] = [
                {"name": a["name"], "cost": a.get("cost", []), "damage": damage_value(a.get("damage")),
                 "damage_text": a.get("damage", ""), "text": a.get("text", "")}
                for a in card["attacks"]
            ]
    return c


def main():
    sets = {s["id"]: s for s in get(f"{BASE}/sets/en.json")}
    cards = []
    for sid in ECARD_SETS + (ALL_EX_SETS if "--all" in sys.argv else ADV_SETS):
        data = get(f"{BASE}/cards/en/{sid}.json")
        cards += [slim(c, sets[sid]) for c in data]
        print(f"{sid:5} {sets[sid]['name']:28} {len(data)} cartas")
    for sid, last in PROMO_SETS.items():
        data = [c for c in get(f"{BASE}/cards/en/{sid}.json") if c["number"].isdigit() and int(c["number"]) <= last]
        cards += [slim(c, sets[sid]) for c in data]
        print(f"{sid:5} {sets[sid]['name']:28} {len(data)} cartas")
    for c in cards:
        if c["name"] in TOOL_FIX:
            c["subtypes"] = ["Pokémon Tool"]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH = pathlib.Path(sys.argv[sys.argv.index("--out") + 1]) if "--out" in sys.argv else OUT
    OUT_PATH.write_text(json.dumps(cards, ensure_ascii=False, separators=(",", ":")))
    print(f"\nTotal: {len(cards)} cartas -> {OUT_PATH}")


if __name__ == "__main__":
    main()
