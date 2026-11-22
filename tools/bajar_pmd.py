"""Baja de SpriteCollab (github.com/PMDCollab/SpriteCollab) los sprites de Mystery Dungeon que
faltan para la mini pelea, con los mismos archivos que copia importar_pmd.py.

Uso: python3 tools/bajar_pmd.py            # todas las especies de las cartas sin carpeta
     python3 tools/bajar_pmd.py abra mew   # solo esas

Los Pokémon ★ usan la versión shiny (carpeta <especie>_shiny, de la variante 0000/0001 de
SpriteCollab): también se bajan las que falten. Esos shinies los hizo la comunidad (en Mystery
Dungeon solo Celebi tiene uno oficial): sus autores quedan en credits.txt de cada carpeta y en
docs/creditos_sprites.md (tools/creditos_pmd.py).

Necesita conexión a raw.githubusercontent.com. El número de la Pokédex sale de
data/cards_adv.json (o de una tabla de nombres si la carta no lo trae).
"""
import json
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from importar_pmd import usadas  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, "mundo", "propios", "pmd")
BASE = "https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master/sprite/%04d/"
POKEDEX = "https://raw.githubusercontent.com/fanzeyi/pokemon.json/master/pokedex.json"


# Formas que no salen del nombre de la carta (MiniBattle.FORMA_CARTA dice qué carta usa cuál):
# carpeta -> (número de la Pokédex, subcarpeta de SpriteCollab)
FORMAS_PMD = {"deoxys_ataque": (386, "0001/"), "deoxys_defensa": (386, "0002/"),
              "deoxys_velocidad": (386, "0003/")}


def folder_name(card_name):
    """Igual que BattleScene.species() (sin las formas especiales)."""
    n = card_name
    for pre in ("Team Aqua's ", "Team Magma's ", "Rocket's ", "Holon's "):
        if n.startswith(pre):
            n = n[len(pre):]
    n = " ".join(n.replace("δ", "").split())
    if n.endswith(" ★"):
        n = n[:-2]
    if n.startswith("Dark "):
        n = n[5:]
    if n.endswith(" ex"):
        n = n[:-3]
    if n.endswith(" LV.X"):
        n = n[:-5]
    if n.startswith("Unown ["):
        n = "Unown"
    n = n.lower().replace("♀", "_f").replace("♂", "_m")
    for ch in ".'’:":
        n = n.replace(ch, "")
    return n.replace(" ", "_").replace("-", "_")


def get(url):
    with urllib.request.urlopen(url, timeout=30) as r:
        return r.read()


def main():
    cards = json.load(open(os.path.join(RAIZ, "data", "cards_adv.json"), encoding="utf-8"))
    dex = {}
    for p in json.loads(get(POKEDEX)):
        key = folder_name(p["name"]["english"].replace("Nidoran♀", "Nidoran ♀").replace("Nidoran♂", "Nidoran ♂"))
        dex[key] = p["id"]
    want = {}
    for c in cards:
        if c["supertype"] != "Pokémon":
            continue
        n = folder_name(c["name"])
        if n not in dex:
            continue
        want[n] = dex[n]
        if "★" in c["name"]:
            want[n + "_shiny"] = dex[n]
    for f, (num, _) in FORMAS_PMD.items():
        want[f] = num
    only = sys.argv[1:]
    names = sorted(n for n in want if (n in only if only else not os.path.exists(os.path.join(DESTINO, n, "AnimData.xml"))))
    sin_dex = sorted({folder_name(c["name"]) for c in cards if c["supertype"] == "Pokémon"} - set(dex))
    if sin_dex:
        print("Sin número de Pokédex (se saltean):", ", ".join(sin_dex))
    need = usadas()
    for n in names:
        url = BASE % want[n] + ("0000/0001/" if n.endswith("_shiny") else FORMAS_PMD.get(n, (0, ""))[1])
        try:
            xml = get(url + "AnimData.xml")
        except Exception as e:  # noqa: BLE001
            print("%-12s #%d: sin sprites (%s)" % (n, want[n], e))
            continue
        out = os.path.join(DESTINO, n)
        os.makedirs(out, exist_ok=True)
        open(os.path.join(out, "AnimData.xml"), "wb").write(xml)
        try:
            open(os.path.join(out, "credits.txt"), "wb").write(get(url + "credits.txt"))
        except Exception:  # noqa: BLE001
            pass
        root = ET.fromstring(xml)
        anims = {}
        for a in root.iter("Anim"):
            anims[a.findtext("Name")] = a.findtext("CopyOf") or a.findtext("Name")
        files = set()
        for name in need:
            if name in anims:
                src = anims[name]
                for kind in ("Anim", "Shadow", "Offsets"):
                    files.add("%s-%s.png" % (src, kind))
        got = 0
        for f in sorted(files):
            try:
                open(os.path.join(out, f), "wb").write(get(url + f))
                got += 1
            except Exception:  # noqa: BLE001
                pass
        print("%-12s #%-4d %d archivos" % (n, want[n], got))


if __name__ == "__main__":
    main()
