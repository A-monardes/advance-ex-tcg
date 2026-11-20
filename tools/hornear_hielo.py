"""Hornea el holo "cracked ice" (Regi ex de Hidden Legends y aves ex de FireRed &
LeafGreen) como hojas de cuadros RGBA en ui/: es una capa que va encima del arte, no
depende de la imagen. 72 cuadros (6 s a 12 cuadros/s) en bucle, 12 por fila.
Uso: python3 tools/hornear_hielo.py
"""
import numpy as np, colorsys
from PIL import Image

def shards(size, n, seed):
    """Esquirlas irregulares: semillas al azar con distinto "peso" (unas crecen más que
    otras), bordes deformados y algunas fracturas largas que cruzan y parten pedazos."""
    rng = np.random.default_rng(seed)
    pts = rng.uniform(0, size, (n, 2))
    wgt = rng.gamma(1.6, size / 28, n)                 # tamaños muy dispares
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    # deformación: bordes quebrados en vez de rectos
    amp = size / 30
    wx = xx + amp * (np.sin(yy * 9 / size + rng.uniform(0, 6)) + 0.4 * np.sin((yy * 1.7 + xx) * 14 / size + rng.uniform(0, 6)))
    wy = yy + amp * (np.sin(xx * 8 / size + rng.uniform(0, 6)) + 0.4 * np.sin((xx * 1.3 - yy) * 13 / size + rng.uniform(0, 6)))
    # distancia estirada en una dirección por semilla: esquirlas alargadas y angulosas
    ang = rng.uniform(0, np.pi, n)
    st = rng.uniform(1.0, 2.2, n)
    dx = wx[..., None] - pts[:, 0]
    dy = wy[..., None] - pts[:, 1]
    u = dx * np.cos(ang) + dy * np.sin(ang)
    v = -dx * np.sin(ang) + dy * np.cos(ang)
    d = np.abs(u) * st + np.abs(v) + 0.0 * v       # métrica tipo rombo: bordes rectos
    d = d - wgt
    srt = np.sort(d, axis=2)
    cell = np.argmin(d, axis=2)
    crack = (srt[..., 1] - srt[..., 0]) < max(0.8, size / 100)
    # fracturas largas
    nl = 3 + size // 40
    extra = np.zeros((size, size), np.int64)
    for i in range(nl):
        p0 = rng.uniform(0, size, 2)
        th = rng.uniform(0, np.pi)
        side = (xx - p0[0]) * np.sin(th) - (yy - p0[1]) * np.cos(th)
        side = side + amp * 0.4 * np.sin((xx * np.cos(th) + yy * np.sin(th)) * 10 / size + i)
        extra = extra * 2 + (side > 0)
    cid = cell * (2 ** nl) + extra
    _, cell = np.unique(cid, return_inverse=True)
    cell = cell.reshape(size, size)
    # grietas: borde entre dos pedazos distintos (línea limpia de 1 píxel)
    crack = np.zeros((size, size), bool)
    crack[:, :-1] |= cell[:, :-1] != cell[:, 1:]
    crack[:-1, :] |= cell[:-1, :] != cell[1:, :]
    # pedacitos sueltos de pocos píxeles se pegan al vecino (ruido)
    m = cell.max() + 1
    # centro de cada pedazo para la franja de luz
    cnt = np.bincount(cell.ravel(), minlength=m)
    cxs = np.bincount(cell.ravel(), xx.ravel(), m) / np.maximum(cnt, 1)
    cys = np.bincount(cell.ravel(), yy.ravel(), m) / np.maximum(cnt, 1)
    pts2 = np.stack([cxs, cys], 1)
    phase = rng.uniform(0, 1, m)
    hue = rng.uniform(0, 1, m)      # arcoíris: cada esquirla de un color
    return cell, crack, pts2, phase, hue



FPS, SECS, COLS = 12, 6.0, 12
N = int(FPS * SECS)


def overlay(sh, t, size):
    cell, crack, pts, phase, hue = sh
    per = 3.0
    k = (t % per) / per / 0.55
    sw = -0.3 + 1.6 * k
    diag = (pts[:, 0] / size + pts[:, 1] / size * 0.6) / 1.6
    near = np.exp(-((diag - sw) / 0.12) ** 2) if k < 1 else np.zeros(len(pts))
    glint = 0.5 + 0.5 * np.cos(2 * np.pi * (t * 0.5 + phase))
    bright = np.clip(0.25 * glint ** 3 + 0.9 * near, 0, 1)
    tint = np.array([colorsys.hsv_to_rgb(h % 1, 0.7, 1.0) for h in hue + t / SECS])
    b = bright[cell]
    rgb = tint[cell]
    a = 0.15 + 0.36 * b
    ca = 0.16 + 0.5 * b
    cr = crack
    rgb = np.where(cr[..., None], np.array([0.96, 0.98, 1.0]), rgb)
    a = np.where(cr, ca, a)
    return np.dstack([rgb, a])


def bake(size, n, seed, path):
    sh = shards(size, n, seed)
    rows = N // COLS
    sheet = np.zeros((rows * size, COLS * size, 4), np.float32)
    for f in range(N):
        o = overlay(sh, f / FPS, size)
        r, c = divmod(f, COLS)
        sheet[r * size:(r + 1) * size, c * size:(c + 1) * size] = o
    Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8), "RGBA").save(path, optimize=True)
    return sh



if __name__ == "__main__":
    bake(96, 55, 7, "ui/holo_hielo_96.png")
    bake(48, 22, 7, "ui/holo_hielo_48.png")
