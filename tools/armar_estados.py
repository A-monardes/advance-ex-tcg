"""Recorta los íconos de estado de la hoja de Mystery Dungeon ("palette / status", 344x352,
fondo verde azulado) en tiras animadas para el duelo.

Uso:
    python3 tools/armar_estados.py hoja_estados.png [carpeta_destino]
Destino por defecto: efectos/propios/ (no se reparte con el código). Escribe est_<nombre>.png
(los cuadros de la animación uno al lado del otro, fondo transparente) y est_<nombre>.json
con el tamaño de cada cuadro.

Qué fila es cada uno (y cuándo se ve en el juego):
    est_poder         ojo amarillo que se abre      tiene un Poké-Power que puede usar
    est_poder_negado  ojo cerrado con cruz roja     su Poké-Power está negado
    est_aviso         "!"                           el rival le puso un efecto (no puede atacar...)
    est_escudo        escudo                        recibe menos daño
    est_quemado       fuego                         Quemado
    est_confuso       pajaritos que giran           Confundido
    est_menos         flecha hacia abajo            hace menos daño
    est_mas           espada                        hace más daño
    est_dormido       Z                             Dormido
    est_veneno        calavera                      Envenenado
(Paralizado usa la tira de rayos, efectos/propios/rayo.png.)
"""
import json
import os
import sys
from PIL import Image

# nombre: (x0, y0, alto, ancho de cada cuadro, cantidad) en la hoja de 344x352
FILAS = {
    "poder": (104, 16, 8, 8, 12),
    "poder_negado": (104, 24, 9, 8, 14),
    "aviso": (104, 33, 14, 16, 9),
    "escudo": (104, 96, 16, 16, 13),
    "quemado": (104, 112, 17, 16, 7),
    "confuso": (104, 128, 15, 16, 8),
    "menos": (104, 193, 14, 16, 11),
    "mas": (104, 217, 15, 16, 13),
    "dormido": (104, 233, 14, 16, 10),
    "veneno": (104, 247, 16, 16, 15),
}
FONDO = (0, 120, 144)
TOL = 40


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    dest = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), "..", "efectos", "propios")
    os.makedirs(dest, exist_ok=True)
    hoja = Image.open(sys.argv[1]).convert("RGBA")
    k = hoja.width / 344.0
    if abs(k - 1.0) > 0.01:
        hoja = hoja.resize((344, round(hoja.height / k)), Image.NEAREST)
    for name, (x0, y0, h, w, n) in FILAS.items():
        tira = hoja.crop((x0, y0, x0 + w * n, y0 + h))
        px = tira.load()
        for y in range(tira.height):
            for x in range(tira.width):
                r, g, b, a = px[x, y]
                if abs(r - FONDO[0]) + abs(g - FONDO[1]) + abs(b - FONDO[2]) <= TOL:
                    px[x, y] = (0, 0, 0, 0)
        tira.save(os.path.join(dest, "est_%s.png" % name))
        with open(os.path.join(dest, "est_%s.json" % name), "w") as f:
            json.dump({"celda": [w, h]}, f)
        print("est_%s.png  %d cuadros de %dx%d" % (name, n, w, h))


if __name__ == "__main__":
    main()
