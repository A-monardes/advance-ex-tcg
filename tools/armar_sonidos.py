"""Prepara efectos de sonido para el juego: los pasa a mono, recorta el silencio del principio y
del final, iguala el volumen (promedio a -16 dB, sin pasar el pico de -1,5 dB) y los guarda en .ogg.

Uso: python3 tools/armar_sonidos.py archivo1.wav archivo2.mp3 ... [--dest carpeta] [--max segundos]
  --max: recorta los más largos a esa duración, con un fundido al final (golpes: --max 1.5).
Por defecto van a sonidos/golpes/ (los golpes de la mini pelea: <familia>_<fisico|distancia>_<debil|fuerte>,
y super_efectivo). Para otros efectos usá --dest sonidos. El nombre sale del archivo (sin el prefijo
"xxxxxxxx-" que agrega el chat al subirlos). Necesita ffmpeg.
"""
import os
import re
import subprocess
import sys

MEAN_DB = -16.0      # volumen promedio buscado (así suenan parejos los cortos y los largos)
PEAK_DB = -1.5       # ...sin que el pico pase de acá


def run(args):
    return subprocess.run(args, capture_output=True, text=True)


def levels(path):
    out = run(["ffmpeg", "-i", path, "-af", "volumedetect", "-f", "null", "-"]).stderr
    mean = re.search(r"mean_volume: (-?[\d.]+) dB", out)
    peak = re.search(r"max_volume: (-?[\d.]+) dB", out)
    return (float(mean.group(1)) if mean else -20.0), (float(peak.group(1)) if peak else 0.0)


def main():
    args = sys.argv[1:]
    dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sonidos", "golpes")
    max_len = None
    if "--max" in args:
        i = args.index("--max")
        max_len = float(args[i + 1])
        del args[i:i + 2]
    if "--dest" in args:
        i = args.index("--dest")
        dest = args[i + 1]
        del args[i:i + 2]
    if not args:
        print(__doc__)
        sys.exit(1)
    os.makedirs(dest, exist_ok=True)
    for src in args:
        name = os.path.splitext(os.path.basename(src))[0]
        name = re.sub(r"^[0-9a-f]{8}-", "", name)
        name = re.sub(r"^metal_", "acero_", name)      # la familia del tipo Acero se llama "acero"
        tmp = os.path.join(dest, "_tmp_%s.wav" % name)
        # mono + sin silencio al principio y al final
        trim = ("silenceremove=start_periods=1:start_threshold=-50dB,"
                "areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse")
        run(["ffmpeg", "-v", "error", "-y", "-i", src, "-ac", "1", "-af", trim, tmp])
        if max_len:
            # recorta a max_len segundos con un fundido al final (los golpes no deben durar más
            # que la animación)
            dur = float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", tmp]).stdout or 0)
            if dur > max_len:
                fade = min(0.3, max_len / 3)
                tmp2 = tmp + ".2.wav"
                run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-t", str(max_len), "-af",
                     "afade=t=out:st=%.3f:d=%.3f" % (max_len - fade, fade), tmp2])
                os.replace(tmp2, tmp)
        mean, peak = levels(tmp)
        gain = min(MEAN_DB - mean, PEAK_DB - peak)
        out = os.path.join(dest, name + ".ogg")
        run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-af", "volume=%.2fdB" % gain,
             "-c:a", "libvorbis", "-q:a", "6", out])
        os.remove(tmp)
        print("%-32s %+.1f dB -> %s" % (name, gain, os.path.relpath(out)))


if __name__ == "__main__":
    main()
