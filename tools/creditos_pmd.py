"""Arma docs/creditos_sprites.md con los autores de los sprites shiny de Mystery Dungeon que usa
el juego (carpetas <especie>_shiny de mundo/propios/pmd/). Son de SpriteCollab
(github.com/PMDCollab/SpriteCollab) y los hizo la comunidad: en Mystery Dungeon solo Celebi
tiene shiny oficial. Para la futura página de créditos.

Uso: python3 tools/creditos_pmd.py   (necesita conexión a raw.githubusercontent.com)
"""
import os
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PMD = os.path.join(RAIZ, "mundo", "propios", "pmd")
NOMBRES = "https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master/credit_names.txt"
SALIDA = os.path.join(RAIZ, "docs", "creditos_sprites.md")


def main():
    quien = {}
    texto = urllib.request.urlopen(NOMBRES, timeout=30).read().decode("utf-8")
    for linea in texto.splitlines()[1:]:
        partes = linea.split("\t")
        if len(partes) >= 2:
            quien[partes[1].strip()] = (partes[0].strip(), partes[2].strip() if len(partes) > 2 else "")
    filas = []
    todos = {}
    for carpeta in sorted(os.listdir(PMD)):
        if not carpeta.endswith("_shiny"):
            continue
        cred = os.path.join(PMD, carpeta, "credits.txt")
        if not os.path.exists(cred):
            filas.append((carpeta, ["(sin credits.txt)"]))
            continue
        autores = []
        for linea in open(cred, encoding="utf-8"):
            partes = linea.rstrip("\n").split("\t")
            if len(partes) < 2:
                continue
            nombre, contacto = quien.get(partes[1].strip(), (partes[1].strip(), ""))
            if nombre not in autores:
                autores.append(nombre)
            todos.setdefault(nombre, (contacto, set()))[1].add(carpeta[:-6].replace("_", " ").title())
        filas.append((carpeta, autores))
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write("# Créditos de sprites\n\n")
        f.write("## Sprites shiny de Mystery Dungeon (Pokémon ★)\n\n")
        f.write("Los Pokémon ★ se ven shiny en la pelea. Esos sprites son de "
                "[SpriteCollab](https://github.com/PMDCollab/SpriteCollab) y los hizo la comunidad: "
                "en Mystery Dungeon solo Celebi tiene shiny oficial. Lista armada por "
                "`tools/creditos_pmd.py` a partir del `credits.txt` de cada carpeta.\n\n")
        f.write("| Pokémon | Autores |\n|---|---|\n")
        for carpeta, autores in filas:
            f.write("| %s | %s |\n" % (carpeta[:-6].replace("_", " ").title(), ", ".join(autores)))
        f.write("\n### Por autor\n\n| Autor | Contacto | Sprites |\n|---|---|---|\n")
        for nombre in sorted(todos, key=str.lower):
            contacto, sp = todos[nombre]
            f.write("| %s | %s | %s |\n" % (nombre, contacto, ", ".join(sorted(sp))))
    print("Escrito", SALIDA, "-", len(filas), "especies,", len(todos), "autores")


if __name__ == "__main__":
    main()
