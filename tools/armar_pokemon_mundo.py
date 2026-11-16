"""Recorta Pokémon del mapa de la hoja "Pokemon Overworld sprites" (ripeada por Guille,
de Anoe; editada por Team Aqua Grunt Chrisean; 388x391, fondo verde azulado) al formato de
los personajes del mapa: 48x128, 3 columnas (quieto, paso 1, paso 2) x 4 filas (abajo,
arriba, izquierda, derecha) de 16x32.
La hoja trae un solo cuadro por dirección: al caminar dan un saltito de 1 píxel.
Uso: python3 tools/armar_pokemon_mundo.py hoja.png [carpeta_salida]
Sale mundo/propios/pkmn_<especie>.png. La hoja no va en el repo."""
import sys, os
from PIL import Image

SRC = sys.argv[1]
DST = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), '..', 'mundo', 'propios')
BG = (0, 128, 128)
# especie: (frente, de costado mirando a la derecha, de espaldas) como (x, y, ancho, alto)
POKEMON = {
    "azurill": ((17, 119, 15, 12), (35, 118, 15, 13), (54, 119, 15, 13)),
    "skitty": ((88, 207, 12, 14), (105, 207, 15, 14), (124, 207, 12, 14)),
}

sheet = Image.open(SRC).convert('RGBA')


def cut(box):
    x, y, w, h = box
    im = sheet.crop((x, y, x + w, y + h))
    px = im.load()
    for j in range(h):
        for i in range(w):
            if px[i, j][:3] == BG:
                px[i, j] = (0, 0, 0, 0)
    return im


for sp, (front, side, back) in POKEMON.items():
    f, s, b = cut(front), cut(side), cut(back)
    rows = [f, b, s.transpose(Image.FLIP_LEFT_RIGHT), s]      # abajo, arriba, izquierda, derecha
    out = Image.new('RGBA', (48, 128), (0, 0, 0, 0))
    for r, im in enumerate(rows):
        for c in range(3):
            hop = 1 if c == 1 else 0                           # paso 1: un píxel más arriba
            x = c * 16 + (16 - im.width) // 2
            y = r * 32 + 30 - im.height - hop                  # pies en la fila 29
            out.paste(im, (x, y), im)
    os.makedirs(DST, exist_ok=True)
    out.save(os.path.join(DST, 'pkmn_%s.png' % sp))
    print('pkmn_%s.png' % sp)
