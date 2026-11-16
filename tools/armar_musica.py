"""Prepara una pista de música para que se repita sin cortes.

Busca dónde vuelve a empezar la canción (el loop), corta el archivo justo al final de la
primera vuelta, funde unos milisegundos en la unión para que no se note el salto, iguala el
volumen y la guarda en .ogg. Al lado deja <nombre>.json con "loop_offset": los segundos
de introducción que no se repiten (el juego vuelve a ese punto al terminar).

Uso: python3 tools/armar_musica.py archivo.wav nombre [--dest musica] [--lag segundos]
  nombre: titulo, mazos, duelo, duelo2, victoria, derrota...
  --lag: si el loop detectado sale mal, el largo de una vuelta a mano. Pasa cuando la canción
         tiene dos mitades muy parecidas: detecta la mitad y la música "se corta antes".
         Ej.: el primer duelo detectaba 57 s y la canción entera dura 113,9 s.
  --sin-loop: para pistas que suenan una sola vez (victoria, derrota).
Necesita ffmpeg y numpy. El archivo original lo mejor es que tenga dos vueltas completas.
"""
import json
import os
import subprocess
import sys

import numpy as np

SR = 44100
MEAN_DB = -20.0
FADE = 0.04


def load(path, sr):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(sr), "-f", "s16le", "-"],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.int16).astype(np.float32).reshape(-1, 2) / 32768


def spectro(mono, sr):
    hop, n = 128, 2048
    fr = np.lib.stride_tricks.sliding_window_view(mono, n)[::hop] * np.hanning(n)
    S = np.log1p(np.abs(np.fft.rfft(fr, axis=1))[:, 20:600])
    S -= S.mean(1, keepdims=True)
    S /= np.linalg.norm(S, axis=1, keepdims=True) + 1e-9
    return S, sr / hop


def find_loop(st, lag_hint=None):
    sr = 11025
    x = np.interp(np.arange(0, len(st), SR / sr), np.arange(len(st)), st.mean(1)).astype(np.float32)
    S, fps = spectro(x, sr)
    dur = len(x) / sr
    if lag_hint:
        L = lag_hint
    else:
        best = (-1, 0)
        a, W = int(min(10, dur * 0.08) * fps), int(min(20, dur * 0.15) * fps)
        for Lf in range(int(15 * fps), len(S) - a - W):
            s = (S[a:a + W] * S[a + Lf:a + Lf + W]).sum(1).mean()
            if s > best[0]:
                best = (s, Lf)
        L = best[1] / fps
        print("  vuelta detectada: %.3f s (parecido %.2f)" % (L, best[0]))
    Lf = int(round(L * fps))
    sim = (S[:len(S) - Lf] * S[Lf:]).sum(1)
    k = int(fps)
    sm = np.convolve(sim, np.ones(k) / k, "same")
    start = max(0.0, (np.argmax(sm > 0.6 * sm.max()) / fps) - 0.5)
    # afinar el largo con la onda, justo después del comienzo del loop
    a = int((start + 1.0) * sr)
    w = 2 * sr
    seg = x[a:a + w]
    best = (-2, 0)
    for d in range(-int(0.08 * sr), int(0.08 * sr)):
        b = a + int(round(L * sr)) + d
        if b < 0 or b + w > len(x):
            continue
        y = x[b:b + w]
        c = float(np.dot(seg, y) / (np.linalg.norm(seg) * np.linalg.norm(y) + 1e-9))
        if c > best[0]:
            best = (c, d)
    L += best[1] / sr
    print("  loop: empieza en %.3f s, vuelta de %.4f s (onda %.2f)" % (start, L, best[0]))
    return start, L, best[0]


def main():
    args = sys.argv[1:]
    dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "musica")
    lag = None
    once = False
    if "--dest" in args:
        i = args.index("--dest"); dest = args[i + 1]; del args[i:i + 2]
    if "--lag" in args:
        i = args.index("--lag"); lag = float(args[i + 1]); del args[i:i + 2]
    if "--sin-loop" in args:
        args.remove("--sin-loop"); once = True
    if len(args) != 2:
        print(__doc__); sys.exit(1)
    src, name = args
    st = load(src, SR)
    info = {}
    if once:
        out = st
    else:
        start, L, corr = find_loop(st, lag)
        # Si la grabación no se repite exacta (onda poco parecida), la unión se funde más largo.
        fade = FADE if corr > 0.8 else 0.15
        start = max(start, fade + 0.05)       # hace falta un poquito antes del comienzo para fundir
        s = int(round(start * SR))
        e = int(round((start + L) * SR))
        out = st[:e].copy()
        f = int(fade * SR)
        if s >= f:
            k = np.linspace(0, 1, f)[:, None]
            # en la unión: el final de la vuelta se funde con lo que suena justo antes del comienzo
            out[e - f:e] = out[e - f:e] * (1 - k) + st[s - f:s] * k
        info["loop_offset"] = round(s / SR, 4)
    # volumen parejo
    rms = np.sqrt((out ** 2).mean()) + 1e-9
    gain = 10 ** ((MEAN_DB - 20 * np.log10(rms)) / 20)
    peak = np.abs(out).max() * gain
    if peak > 0.95:
        gain *= 0.95 / peak
    out = np.clip(out * gain, -1, 1)
    os.makedirs(dest, exist_ok=True)
    tmp = os.path.join(dest, "_tmp.raw")
    (out * 32767).astype(np.int16).tofile(tmp)
    path = os.path.join(dest, name + ".ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", tmp,
                    "-c:a", "libvorbis", "-q:a", "5", path])
    os.remove(tmp)
    with open(os.path.join(dest, name + ".json"), "w") as fh:
        json.dump(info, fh)
    print("  -> %s (%.1f s) %s" % (os.path.relpath(path), len(out) / SR, info))


if __name__ == "__main__":
    main()
