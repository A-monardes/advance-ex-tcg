#!/bin/bash
# extraer.sh modulo.gd var "descripción" "Sección 1" "Sección 2"...  (y arregla las inferencias de tipo)
cd "$(dirname "$0")/.."
mod=$1; v=$2; desc=$3; shift 3
python3 tools/extraer_modulo.py "$mod" "$v" "$desc" $(python3 tools/secciones.py "$@") || exit 1
G=/home/claude/tools/Godot_v4.3-stable_linux.x86_64
for i in $(seq 1 30); do
  errs=$(timeout 60 $G --headless --path . --check-only -s "$mod" 2>&1 | grep -oE 'Cannot infer the type of "[A-Za-z_0-9]+"' | grep -oE '"[^"]+"' | tr -d '"' | sort -u)
  [ -z "$errs" ] && break
  for n in $errs; do sed -i -E "s/^([ \t]*var[ \t]+$n)[ \t]*:=/\1 =/" "$mod"; done
done
timeout 60 $G --headless --path . --check-only -s "$mod" 2>&1 | grep "SCRIPT ERROR" | head -5
timeout 60 $G --headless --path . --check-only -s scenes/duel.gd 2>&1 | grep "SCRIPT ERROR" | grep -v "Could not\|Cannot infer the type of \"Duel" | head -5
