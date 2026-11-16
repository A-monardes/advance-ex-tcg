#!/usr/bin/env python3
"""Lista los sprites de batalla que faltan en mundo/propios/batalla/pokemon/.

Por cada especie de las cartas hacen falta <especie>_frente.png y <especie>_espalda.png
(64x64, fondo transparente). Uso:  python tools/sprites_batalla_faltantes.py
"""
import json
import pathlib
import re

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CARPETA = RAIZ / "mundo" / "propios" / "batalla" / "pokemon"
FORMAS = {"Rain Castform": "castform_rain", "Snow-cloud Castform": "castform_snow",
          "Sunny Castform": "castform_sun"}


def especie(nombre):
    """El mismo nombre de archivo que busca el juego (scenes/battle_scene.gd)."""
    n = re.sub(r"^(Team Aqua's|Team Magma's) ", "", nombre)
    n = re.sub(r"^Dark ", "", n)
    n = re.sub(r" ex$", "", n)
    if n in FORMAS:
        return FORMAS[n]
    n = n.lower().replace("♀", "_f").replace("♂", "_m")
    n = re.sub(r"[.'’:]", "", n)
    return re.sub(r"[ \-]+", "_", n)


def main():
    cartas = json.loads((RAIZ / "data" / "cards_adv.json").read_text(encoding="utf-8"))
    especies = sorted({especie(c["name"]) for c in cartas if c["supertype"] == "Pokémon"})
    faltan = []
    for e in especies:
        for lado in ("frente", "espalda"):
            if not (CARPETA / f"{e}_{lado}.png").exists():
                faltan.append(f"{e}_{lado}.png")
    hay = len(especies) * 2 - len(faltan)
    print(f"Sprites de batalla: {hay} de {len(especies) * 2} ({len(especies)} especies)")
    if faltan:
        print("Faltan:")
        for f in faltan:
            print("  " + f)
    else:
        print("¡Están todos!")


if __name__ == "__main__":
    main()
