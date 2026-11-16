# Junta los archivos propios (que no están en git) para la versión web, en partes.
# Se corre en la PC del usuario (python3 tools/armar_assets_web.py base, y sprites I N);
# deja build/assets_web_*.zip, que tools/publicar_web.sh suma a la exportación.
import os, io, sys, zipfile
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # la carpeta del proyecto
part = sys.argv[1]
if part == "base":
    out = os.path.join(root, "build", "assets_web_base.zip")
    skip = {os.path.join("mundo", "propios", "arte"), os.path.join("mundo", "propios", "cartas")}
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for base in ["mundo/propios", "sonidos", "musica", "efectos/propios"]:
            for dp, dn, fn in os.walk(os.path.join(root, base)):
                rel = os.path.relpath(dp, root)
                if any(rel == s or rel.startswith(s + os.sep) for s in skip):
                    continue
                for f in fn:
                    if not f.endswith(".import"):
                        z.write(os.path.join(dp, f), os.path.join(rel, f).replace(os.sep, "/"))
        for f in os.listdir(os.path.join(root, "fonts")):
            if f.startswith("propia"):
                z.write(os.path.join(root, "fonts", f), "fonts/" + f)
else:
    from PIL import Image
    i, n = int(sys.argv[2]), int(sys.argv[3])
    sp = os.path.join(root, "sprites")
    files = sorted(f for f in os.listdir(sp) if f.lower().endswith(".png"))[i::n]
    out = os.path.join(root, "build", "assets_web_sprites_%d.zip" % i)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_STORED) as z:
        for f in files:
            im = Image.open(os.path.join(sp, f)).convert("RGBA")
            im.thumbnail((160, 160), Image.LANCZOS)
            b = io.BytesIO(); im.save(b, "PNG")
            z.writestr("sprites/" + f, b.getvalue())
print(out, os.path.getsize(out) // 1024, "KB")
