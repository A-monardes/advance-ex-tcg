"""Arma el ejecutable de Windows (un solo .exe con todo adentro) para pasárselo a alguien
que no tiene Godot.

Uso:
    python3 tools/exportar_windows.py <ruta al Godot 4.3> [carpeta de salida]
Salida por defecto: build/windows/ ("EX TCG Retro.exe").

Necesita las plantillas de exportación de Godot 4.3 instaladas (en Godot: Editor > Manage
Export Templates > Download and Install).

Por qué un script y no el botón Export de Godot: el juego lee los PNG originales (cartas,
mapas, efectos, tus imágenes de mundo/propios...) y Godot, al exportar, solo mete sus
versiones convertidas. El script copia el proyecto a una carpeta temporal, marca todas
las imágenes para que entren tal cual ("keep") y exporta desde ahí, sin tocar tu proyecto.
"""
import os
import shutil
import subprocess
import sys
import tempfile

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TAL_CUAL = (".png", ".jpg", ".jpeg", ".webp", ".fnt", ".ogg", ".mp3", ".wav")
FUERA = {".git", ".godot", "build", "tests", "tools", "__pycache__"}


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    godot = sys.argv[1]
    salida = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(RAIZ, "build", "windows")
    os.makedirs(salida, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="ex_tcg_export_")
    proj = os.path.join(tmp, "ex_tcg")
    print("copiando el proyecto a", proj)
    shutil.copytree(RAIZ, proj, ignore=lambda d, names: [n for n in names if n in FUERA and d == RAIZ]
                    + [n for n in names if n.endswith(".import")])
    n = 0
    for d, _, files in os.walk(proj):
        for f in files:
            if f.lower().endswith(TAL_CUAL):
                with open(os.path.join(d, f + ".import"), "w") as fh:
                    fh.write('[remap]\n\nimporter="keep"\n')
                n += 1
    print("%d archivos marcados para ir tal cual" % n)
    print("importando...")
    subprocess.run([godot, "--headless", "--editor", "--quit", "--path", proj],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=900)
    exe = os.path.join(salida, "EX TCG Retro.exe")
    print("exportando...")
    r = subprocess.run([godot, "--headless", "--path", proj, "--export-release", "Windows", exe],
                       capture_output=True, text=True, timeout=900)
    errores = [l for l in (r.stdout + r.stderr).splitlines() if "ERROR" in l]
    for l in errores[:20]:
        print(l)
    shutil.rmtree(tmp, ignore_errors=True)
    if os.path.exists(exe):
        print("listo:", exe, "(%.1f MB)" % (os.path.getsize(exe) / 1e6))
    else:
        print("no se pudo exportar")
        sys.exit(1)


if __name__ == "__main__":
    main()
