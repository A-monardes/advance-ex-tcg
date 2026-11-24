"""Genera el logo del juego (ui/logo.png) y su brillo animado (ui/logo_brillo.png).

Letras propias, gruesas y en cursiva, con relleno metálico en degradé, bisel claro arriba,
borde oscuro + borde blanco + sombra, al estilo de los nombres de las expansiones de la época
(sin copiar ninguno). Arriba ADVANCE en letras anchas y finas; abajo EX TCG.

    python3 tools/logo_juego.py
"""
import os
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, "..", "ui")

LH = 20          # alto de las letras
SESGO = 5        # cuántas filas por cada px de inclinación

TINTA = (24, 28, 56, 255)
BLANCO = (248, 248, 248, 255)
SOMBRA = (16, 20, 40, 150)

# Degradés de arriba a abajo (claro -> oscuro), con una franja brillante en el medio
ROJO = [(255, 200, 176), (255, 136, 104), (240, 80, 56), (216, 48, 40), (255, 120, 96), (192, 32, 32), (144, 16, 24)]
ORO = [(255, 252, 200), (255, 232, 120), (248, 200, 48), (232, 160, 24), (255, 216, 96), (208, 120, 16), (160, 80, 8)]


def glifo(c):
    """Letra gruesa de EX TCG como máscara 16 x 20 (sin inclinar)."""
    im = Image.new("L", (16, LH), 0)
    d = ImageDraw.Draw(im)
    if c == "E":
        for r in [(0, 0, 4, 19), (0, 0, 15, 4), (0, 8, 12, 11), (0, 15, 15, 19)]:
            d.rectangle(r, fill=255)
    elif c == "X":
        d.polygon([(0, 0), (5, 0), (15, 19), (10, 19)], fill=255)
        d.polygon([(10, 0), (15, 0), (5, 19), (0, 19)], fill=255)
    elif c == "A":
        d.polygon([(5, 0), (10, 0), (15, 7), (15, 19), (0, 19), (0, 7)], fill=255)
        d.rectangle((5, 5, 10, 8), fill=0)
        d.rectangle((5, 13, 10, 19), fill=0)
    elif c == "D":
        d.rounded_rectangle((0, 0, 15, 19), radius=7, fill=255)
        d.rectangle((0, 0, 8, 19), fill=255)
        d.rectangle((5, 5, 10, 14), fill=0)
    elif c == "V":
        d.polygon([(0, 0), (5, 0), (7, 11), (8, 11), (10, 0), (15, 0), (10, 19), (5, 19)], fill=255)
    elif c == "N":
        d.rectangle((0, 0, 4, 19), fill=255)
        d.rectangle((11, 0, 15, 19), fill=255)
        d.polygon([(0, 0), (5, 0), (15, 19), (10, 19)], fill=255)
    elif c == "T":
        d.rectangle((0, 0, 15, 4), fill=255)
        d.rectangle((5, 0, 10, 19), fill=255)
    elif c == "C":
        d.rounded_rectangle((0, 0, 15, 19), radius=7, fill=255)
        d.rectangle((5, 5, 15, 14), fill=0)
    elif c == "G":
        d.rounded_rectangle((0, 0, 15, 19), radius=7, fill=255)
        d.rectangle((5, 5, 15, 8), fill=0)
        d.rectangle((5, 9, 10, 14), fill=0)
        d.rectangle((8, 9, 15, 12), fill=255)
    return im


def glifo_adv(c):
    """Letras de ADVANCE: anchas, de trazo fino y geométricas (14 x 10), al estilo de la
    Game Boy Advance. Las A van sin travesaño."""
    im = Image.new("L", (14, 10), 0)
    d = ImageDraw.Draw(im)
    if c == "A":
        d.polygon([(5, 0), (8, 0), (13, 9), (11, 9), (6.5, 1.5), (2, 9), (0, 9)], fill=255)
    elif c == "D":
        d.rounded_rectangle((0, 0, 13, 9), radius=4, outline=255, width=2)
        d.rectangle((0, 0, 4, 1), fill=255)
        d.rectangle((0, 8, 4, 9), fill=255)
    elif c == "V":
        d.polygon([(0, 0), (2, 0), (6.5, 7.5), (11, 0), (13, 0), (8, 9), (5, 9)], fill=255)
    elif c == "N":
        d.rectangle((0, 0, 1, 9), fill=255)
        d.rectangle((12, 0, 13, 9), fill=255)
        d.polygon([(0, 0), (2, 0), (13, 9), (11, 9)], fill=255)
    elif c == "C":
        d.rounded_rectangle((0, 0, 13, 9), radius=4, outline=255, width=2)
        d.rectangle((10, 2, 13, 7), fill=0)
    elif c == "E":
        for r in [(0, 0, 1, 9), (0, 0, 13, 1), (0, 4, 11, 5), (0, 8, 13, 9)]:
            d.rectangle(r, fill=255)
    return im


def glifo_chico(c):
    """Letras gruesas chicas (7 x 10) para el botón OK."""
    im = Image.new("L", (7, 10), 0)
    d = ImageDraw.Draw(im)
    if c == "O":
        d.rounded_rectangle((0, 0, 6, 9), radius=3, fill=255)
        d.rectangle((2, 2, 4, 7), fill=0)
    elif c == "K":
        d.rectangle((0, 0, 1, 9), fill=255)
        d.polygon([(2, 4), (5, 0), (6, 0), (6, 1), (3, 5), (2, 5)], fill=255)
        d.polygon([(2, 4), (3, 4), (6, 8), (6, 9), (5, 9), (2, 6)], fill=255)
    return im


def glifo_medio(c):
    """Letras gruesas medianas (10 x 13) para los carteles del duelo ("YOUR TURN!")."""
    anchos = {"!": 4, "'": 3, " ": 4, "I": 4, ".": 4, "W": 13}
    im = Image.new("L", (anchos.get(c, 10), 13), 0)
    d = ImageDraw.Draw(im)
    R = lambda *r: d.rectangle(r, fill=255)
    X = lambda *r: d.rectangle(r, fill=0)
    if c == "A":
        d.polygon([(3, 0), (6, 0), (9, 4), (9, 12), (0, 12), (0, 4)], fill=255)
        X(3, 3, 6, 5); X(3, 9, 6, 12)
    elif c == "D":
        d.rounded_rectangle((0, 0, 9, 12), radius=4, fill=255); R(0, 0, 4, 12); X(3, 3, 6, 9)
    elif c == "E":
        R(0, 0, 2, 12); R(0, 0, 9, 2); R(0, 5, 7, 7); R(0, 10, 9, 12)
    elif c == "H":
        R(0, 0, 2, 12); R(7, 0, 9, 12); R(0, 5, 9, 7)
    elif c == "N":
        R(0, 0, 2, 12); R(7, 0, 9, 12)
        d.polygon([(0, 0), (3, 0), (9, 12), (6, 12)], fill=255)
    elif c == "O":
        d.rounded_rectangle((0, 0, 9, 12), radius=4, fill=255); X(3, 3, 6, 9)
    elif c in ["P", "R"]:
        d.rounded_rectangle((0, 0, 9, 8), radius=3, fill=255); R(0, 0, 3, 12); X(3, 3, 6, 5)
        if c == "R":
            d.polygon([(4, 8), (7, 8), (9, 11), (9, 12), (6, 12), (3, 8)], fill=255)
    elif c == "S":
        d.rounded_rectangle((0, 0, 9, 7), radius=3, fill=255)
        d.rounded_rectangle((0, 5, 9, 12), radius=3, fill=255)
        X(3, 3, 9, 4); X(0, 8, 6, 9)
    elif c == "T":
        R(0, 0, 9, 2); R(3, 0, 6, 12)
    elif c == "U":
        d.rounded_rectangle((0, -6, 9, 12), radius=4, fill=255); X(3, 0, 6, 9)
    elif c == "Y":
        d.polygon([(0, 0), (3, 0), (5, 4), (6, 0), (9, 0), (6, 7), (3, 7)], fill=255); R(3, 6, 6, 12)
    elif c == "K":
        R(0, 0, 2, 12)
        d.polygon([(3, 5), (7, 0), (9, 0), (9, 1), (5, 6), (3, 7)], fill=255)
        d.polygon([(3, 5), (5, 5), (9, 11), (9, 12), (7, 12), (3, 7)], fill=255)
    elif c == "C":
        d.rounded_rectangle((0, 0, 9, 12), radius=4, fill=255); X(3, 3, 9, 9)
    elif c == "I":
        R(0, 0, 3, 12)
    elif c == "Z":
        R(0, 0, 9, 2); R(0, 10, 9, 12)
        d.polygon([(6, 3), (9, 3), (3, 9), (0, 9)], fill=255)
    elif c == "W":
        d.rounded_rectangle((0, -6, 12, 12), radius=4, fill=255); X(3, 0, 9, 9); R(5, 3, 7, 12)
    elif c == "L":
        R(0, 0, 2, 12); R(0, 10, 8, 12)
    elif c == "2":
        d.rounded_rectangle((0, 0, 9, 8), radius=4, fill=255); X(0, 3, 6, 12)
        d.polygon([(6, 5), (9, 5), (3, 10), (0, 10)], fill=255); R(0, 10, 9, 12)
    elif c == ".":
        R(0, 10, 3, 12)
    elif c == "!":
        R(0, 0, 3, 8); R(0, 10, 3, 12)
    elif c == "'":
        R(0, 0, 2, 4)
    return im


def palabra(texto, paleta, esp=2, letra=glifo, sesgo=SESGO):
    """Arma la palabra inclinada y la pinta con el degradé."""
    glifos = [letra(ch) for ch in texto]       # cada letra puede tener su propio ancho
    gh = glifos[0].height
    ancho = sum(g.width + esp for g in glifos) + gh // sesgo + 2
    masc = Image.new("L", (ancho, gh), 0)
    x = 0
    for g in glifos:
        gw = g.width
        for yy in range(gh):
            dx = (gh - 1 - yy) // sesgo
            fila = g.crop((0, yy, gw, yy + 1))
            masc.paste(255, (x + dx, yy), fila)
        x += gw + esp
    im = Image.new("RGBA", (ancho, gh), (0, 0, 0, 0))
    px, m = im.load(), masc.load()
    for yy in range(gh):
        col = paleta[min(len(paleta) - 1, yy * len(paleta) // gh)]
        for xx in range(ancho):
            if m[xx, yy]:
                c = col
                if yy == 0 or not m[xx, yy - 1]:          # bisel: borde de arriba más claro
                    c = tuple(min(255, v + 60) for v in col)
                elif xx == 0 or not m[xx - 1, yy]:        # borde izquierdo apenas más claro
                    c = tuple(min(255, v + 28) for v in col)
                px[xx, yy] = c + (255,)
    return im, masc


def contorno(masc, n=1):
    """La máscara agrandada n px en las 8 direcciones."""
    w, h = masc.size
    src = masc.load()
    out = Image.new("L", (w, h), 0)
    o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y]:
                for dy in range(-n, n + 1):
                    for dx in range(-n, n + 1):
                        if 0 <= x + dx < w and 0 <= y + dy < h:
                            o[x + dx, y + dy] = 255
    return out


def con_bordes(img, masc, pad=2):
    """La palabra con borde oscuro, borde blanco y sombra; devuelve (imagen, máscara de letras)."""
    w, h = img.width + pad * 2, img.height + pad * 2
    letras = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    m = Image.new("L", (w, h), 0)
    letras.alpha_composite(img, (pad, pad))
    m.paste(masc, (pad, pad), masc)
    b1 = contorno(m, 1)
    b2 = contorno(b1, 1)
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (w, h), SOMBRA), (2, 2), b2)
    out.paste(Image.new("RGBA", (w, h), BLANCO), (0, 0), b2)
    out.paste(Image.new("RGBA", (w, h), TINTA), (0, 0), b1)
    out.alpha_composite(letras)
    mm = Image.new("L", out.size, 0)
    mm.paste(m, (0, 0))
    return out, mm


# Plateado azulado para ADVANCE
PLATA = [(248, 252, 255), (208, 220, 255), (152, 172, 240), (112, 128, 224), (184, 200, 255), (88, 96, 200), (64, 64, 168)]


def main():
    os.makedirs(SALIDA, exist_ok=True)
    adv, madv = palabra("ADVANCE", PLATA, esp=4, letra=glifo_adv, sesgo=3)
    ex, mex = palabra("EX", ROJO)
    tcg, mtcg = palabra("TCG", ORO)
    sep = 6
    # EX TCG en una sola tira
    et = Image.new("RGBA", (ex.width + sep + tcg.width, LH), (0, 0, 0, 0))
    met = Image.new("L", et.size, 0)
    et.alpha_composite(ex, (0, 0)); met.paste(mex, (0, 0), mex)
    et.alpha_composite(tcg, (ex.width + sep, 0)); met.paste(mtcg, (ex.width + sep, 0), mtcg)

    a_img, a_m = con_bordes(adv, madv)
    e_img, e_m = con_bordes(et, met)
    W = max(a_img.width, e_img.width)
    ya, ye = 0, a_img.height - 4          # EX TCG se monta un poco sobre ADVANCE
    H = ye + e_img.height
    logo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    xa, xe = (W - a_img.width) // 2, (W - e_img.width) // 2
    logo.alpha_composite(a_img, (xa, ya)); mask.paste(a_m, (xa, ya), a_m)
    logo.alpha_composite(e_img, (xe, ye)); mask.paste(e_m, (xe, ye), e_m)
    logo.save(os.path.join(SALIDA, "logo.png"))

    # Brillo: una franja diagonal que recorre solo las letras (tira de cuadros)
    N = 20
    tira = Image.new("RGBA", (W * N, H), (0, 0, 0, 0))
    m = mask.load()
    for f in range(N):
        pos = -12 + f * (W + 24) / (N - 1)
        cuadro = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        p = cuadro.load()
        for y in range(H):
            for x in range(W):
                if m[x, y]:
                    k = x - pos + y * 0.5
                    if 0 <= k < 3:
                        p[x, y] = (255, 255, 255, 200)
                    elif 3 <= k < 5:
                        p[x, y] = (255, 255, 255, 90)
        tira.paste(cuadro, (f * W, 0))
    tira.save(os.path.join(SALIDA, "logo_brillo.png"))
    print("logo", W, "x", H)


def boton_ok():
    """ui/boton_ok.png (24 x 24): "OK" dorado como el título, sobre un botón rojo."""
    ok, mok = palabra("OK", ORO, esp=1, letra=glifo_chico, sesgo=5)
    w, h = ok.width + 2, ok.height + 2
    m = Image.new("L", (w, h), 0)
    m.paste(mok, (1, 1), mok)
    borde = contorno(m, 1)
    img = Image.new("RGBA", (w + 1, h + 1), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (w, h), (64, 8, 16, 200)), (1, 1), borde)     # sombra
    img.paste(Image.new("RGBA", (w, h), TINTA), (0, 0), borde)
    img.alpha_composite(ok, (1, 1))
    b = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(b)
    for y in range(24):          # fondo rojo en degradé, más claro arriba
        k = y / 23
        d.line((0, y, 23, y), fill=(int(240 - 90 * k), int(88 - 56 * k), int(64 - 32 * k), 255))
    d.line((0, 0, 23, 0), fill=(255, 168, 136, 255))
    b.alpha_composite(img, ((24 - img.width + 1) // 2, (24 - img.height + 1) // 2))
    b.save(os.path.join(SALIDA, "boton_ok.png"))
    print("ok", img.size)


def boton_duelo():
    """ui/boton_duelo.png: "DUEL!" dorado como el título (las letras medianas de los carteles),
    con borde oscuro y sombra, sin fondo: el juego lo pone sobre un botón rojo como el del OK."""
    w, m = palabra("DUEL!", ORO, esp=1, letra=glifo_medio, sesgo=4)
    mm = Image.new("L", (w.width + 2, w.height + 2), 0)
    mm.paste(m, (1, 1), m)
    borde = contorno(mm, 1)
    img = Image.new("RGBA", (mm.width + 1, mm.height + 1), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", mm.size, (64, 8, 16, 200)), (1, 1), borde)     # sombra
    img.paste(Image.new("RGBA", mm.size, TINTA), (0, 0), borde)
    img.alpha_composite(w, (1, 1))
    img.save(os.path.join(SALIDA, "boton_duelo.png"))
    print("duelo", img.size)


def carteles():
    """Los carteles del duelo (turno, KO, resultado), con las letras del título."""
    for nombre, texto, paleta in [("turno_tuyo", "YOUR TURN!", ORO), ("turno_rival", "OPPONENT'S TURN", PLATA),
            ("muerte_subita", "SUDDEN DEATH!", ORO), ("ko", "KNOCKED OUT!", ROJO), ("ko_premios", "2 PRIZES!", ORO),
            ("ganaste", "YOU WON!", ORO), ("perdiste", "YOU LOST...", PLATA), ("empate", "DRAW", PLATA)]:
        w, m = palabra(texto, paleta, esp=1, letra=glifo_medio, sesgo=4)
        img, _ = con_bordes(w, m, pad=2)
        img.save(os.path.join(SALIDA, nombre + ".png"))
        print(nombre, img.size)


if __name__ == "__main__":
    main()
    boton_ok()
    boton_duelo()
    carteles()
