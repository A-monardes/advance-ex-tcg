"""Copia las carpetas de SpriteCollab al proyecto para la mini pelea (Options > Battles: Mini).

Uso:
  python tools/importar_pmd.py <carpeta_origen> [especie]

- Con especie: <carpeta_origen> es UNA carpeta de SpriteCollab (la que trae AnimData.xml)
  y se copia como mundo/propios/pmd/<especie>/.
    python tools/importar_pmd.py C:/Users/yo/Downloads/sprite swampert
- Sin especie: <carpeta_origen> tiene adentro una carpeta por especie, ya renombradas
  con el nombre que usa el juego (blaziken, swampert, mr_mime, nidoran_f, deoxys_ataque...).
    python tools/importar_pmd.py C:/Users/yo/Downloads/pmd

Solo copia lo que usa el juego (AnimData.xml, credits.txt y las hojas Anim/Shadow/Offsets de
Idle, Walk, Hurt, Hop, Sleep y las que nombra data/ataques_pmd.json, resolviendo CopyOf), así ocupa poco.
Al final muestra qué especies de mundo/propios/batalla/pokemon/LISTA.txt todavía no tienen carpeta.
"""
import os
import shutil
import sys
import xml.etree.ElementTree as ET

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, "mundo", "propios", "pmd")
LISTA = os.path.join(RAIZ, "mundo", "propios", "batalla", "pokemon", "LISTA.txt")
REGLAS = os.path.join(RAIZ, "data", "ataques_pmd.json")
BASICAS = ["Idle", "Walk", "Hurt", "Hop", "Sleep", "Attack", "Strike", "Shoot", "Charge"]


def usadas():
    """Idle/Walk/Hurt/Hop/Sleep más todas las animaciones que nombra data/ataques_pmd.json."""
    nombres = list(BASICAS)
    try:
        import json
        with open(REGLAS, encoding="utf-8") as f:
            r = json.load(f)
        listas = [v.get("anims", []) for v in r.get("por_ataque", {}).values()]
        listas += [v.get("anims", []) for v in r.get("palabras", [])]
        listas += [v for k, v in r.get("por_defecto", {}).items() if k != "tipos_a_distancia"]
        for l in listas:
            nombres += [n for n in l if n not in nombres]
    except (OSError, ValueError):
        pass
    return nombres


USADAS = usadas()


def copias_de(xml_path):
    """Nombre de animación -> hoja de la que es copia (CopyOf), o ella misma."""
    try:
        raiz = ET.parse(xml_path).getroot()
    except (ET.ParseError, OSError):
        return {}
    return {a.findtext("Name"): (a.findtext("CopyOf") or a.findtext("Name")) for a in raiz.iter("Anim")}


def animaciones(xml_path):
    """Nombres de hoja que hay que copiar (resolviendo CopyOf)."""
    copias = {}
    try:
        raiz = ET.parse(xml_path).getroot()
    except (ET.ParseError, OSError):
        return set(USADAS)
    for a in raiz.iter("Anim"):
        nombre = a.findtext("Name")
        copia = a.findtext("CopyOf")
        if nombre:
            copias[nombre] = copia or nombre
    return {copias.get(n, n) for n in USADAS}


def importar(origen, especie):
    xml = os.path.join(origen, "AnimData.xml")
    if not os.path.isfile(xml):
        print(f"  {especie}: no tiene AnimData.xml, la salteo ({origen})")
        return False
    dst = os.path.join(DESTINO, especie)
    os.makedirs(dst, exist_ok=True)
    shutil.copy2(xml, dst)
    if os.path.isfile(os.path.join(origen, "credits.txt")):
        shutil.copy2(os.path.join(origen, "credits.txt"), dst)
    copiadas = 0
    for an in sorted(animaciones(xml)):
        for parte in ("Anim", "Shadow", "Offsets"):
            f = os.path.join(origen, f"{an}-{parte}.png")
            if os.path.isfile(f):
                shutil.copy2(f, dst)
                copiadas += 1
    fuentes = copias_de(xml)
    falta = [n for n in ("Idle", "Hurt")
             if not os.path.isfile(os.path.join(dst, f"{fuentes.get(n, n)}-Anim.png"))]
    aviso = f"  (le falta: {', '.join(falta)})" if falta else ""
    print(f"  {especie}: {copiadas} hojas{aviso}")
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    origen = sys.argv[1]
    if len(sys.argv) >= 3:
        importar(origen, sys.argv[2].lower())
    else:
        for nombre in sorted(os.listdir(origen)):
            carpeta = os.path.join(origen, nombre)
            if os.path.isdir(carpeta):
                importar(carpeta, nombre.lower())
    if os.path.isfile(LISTA):
        with open(LISTA, encoding="utf-8") as f:
            especies = [l.strip() for l in f if l.strip() and " " not in l.strip() and ":" not in l]
        faltan = [e for e in especies
                  if not os.path.isfile(os.path.join(DESTINO, e, "AnimData.xml"))]
        print(f"\nCon carpeta: {len(especies) - len(faltan)} de {len(especies)} especies.")
        if faltan:
            print("Faltan: " + ", ".join(faltan))


if __name__ == "__main__":
    main()
