#!/bin/bash
# Exporta la versión web desde una copia limpia de main y la sube a gh-pages.
# Uso (desde la sesión de Claude): exporta main con el perfil "Web" en una copia limpia
# (sin arte, sprites ni sonidos de la carpeta local) y lo sube a la rama gh-pages.
# La página queda en https://a-monardes.github.io/advance-ex-tcg/
set -e
cd /home/claude/web_src && git checkout -q --detach main 2>/dev/null || (cd /home/claude/ex_tcg && git worktree add -q --detach /home/claude/web_src main)
cd /home/claude/web_src && git checkout -q --detach $(git -C /home/claude/ex_tcg rev-parse main)
G=/home/claude/tools/Godot_v4.3-stable_linux.x86_64
timeout 300 $G --headless --import >/dev/null 2>&1 || true
rm -rf /home/claude/web_out && mkdir -p /home/claude/web_out
timeout 600 $G --headless --export-release "Web" /home/claude/web_out/index.html >/dev/null 2>&1
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
