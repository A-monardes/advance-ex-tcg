#!/bin/bash
# Exporta la versión web desde una copia limpia de main y la sube a gh-pages.
# Uso (desde la sesión de Claude): exporta main con el perfil "Web" en una copia limpia
# (más los archivos propios de build/assets_web.zip: música, sonidos, sprites, escenas)
# La página queda en https://a-monardes.github.io/advance-ex-tcg/
set -e
cd /home/claude/web_src && git checkout -q --detach main 2>/dev/null || (cd /home/claude/ex_tcg && git worktree add -q --detach /home/claude/web_src main)
cd /home/claude/web_src && git checkout -q --detach $(git -C /home/claude/ex_tcg rev-parse main)
# Los archivos propios del usuario (música, sonidos, sprites, escenas...): no están en git,
# vienen de build/assets_web.zip de su carpeta y se suman solo a la exportación
# Los sprites de PMD no van al paquete: quedan sueltos en la página (pmd/) y data/pmd_web.json
# dice qué archivos tiene cada especie (el juego los baja con PmdWeb).
if [ -f /home/claude/web_assets.zip ]; then
  python3 - <<'PY'
import zipfile, json, os
z = zipfile.ZipFile('/home/claude/web_assets.zip')
pre = 'mundo/propios/pmd/'
man = {}
for i in z.infolist():
    if i.is_dir():
        continue
    if i.filename.startswith(pre):
        rest = i.filename[len(pre):]
        sp, _, f = rest.partition('/')
        if f and '/' not in f:
            man.setdefault(sp, []).append(f)
            dst = os.path.join('/home/claude/pages/pmd', sp, f)
            if not os.path.exists(dst) or os.path.getsize(dst) != i.file_size:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                open(dst, 'wb').write(z.read(i))
    else:
        z.extract(i, '/home/claude/web_src')
json.dump(man, open('/home/claude/web_src/data/pmd_web.json', 'w'), ensure_ascii=False)
print(len(man), 'especies de PMD')
PY
fi
G=/home/claude/tools/Godot_v4.3-stable_linux.x86_64
timeout 1500 $G --headless --import >/dev/null 2>&1 || true
rm -rf /home/claude/web_out && mkdir -p /home/claude/web_out
timeout 600 $G --headless --export-release "Web" /home/claude/web_out/index.html >/dev/null 2>&1
git -C /home/claude/web_src clean -fdxq -e .godot
# El paquete del juego cambia de nombre en cada versión, así el navegador no usa uno viejo de su caché
SHA=$(git -C /home/claude/ex_tcg rev-parse --short main)
mv /home/claude/web_out/index.pck /home/claude/web_out/index-$SHA.pck
sed -i "s/\"index.pck\"/\"index-$SHA.pck\"/; s/const GODOT_CONFIG = {/const GODOT_CONFIG = {\"mainPack\":\"index-$SHA.pck\",/" /home/claude/web_out/index.html
cd /home/claude/pages && git rm -q -r --cached . >/dev/null 2>&1 || true
find /home/claude/pages -maxdepth 1 -type f ! -name .nojekyll -delete
cp /home/claude/web_out/* /home/claude/pages/
git add -A && git -c user.name=Agustin -c user.email="$(git -C /home/claude/ex_tcg config user.email)" commit -qm "Versión web ($(git -C /home/claude/ex_tcg rev-parse --short main))

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01QVrjYtuAkSAqcLL782mo1u"
timeout 500 git push -q origin gh-pages
echo "subido"
