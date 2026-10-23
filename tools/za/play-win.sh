#!/bin/bash
# Windows: Pokémon Z-A com o teclado (setas = d-pad, Enter = A, Backspace = B, P = Plus, M = Minus; WASD = analógico,
# K/J/L/I = A/B/X/Y). Log em za-tools/play.log, SHOT=<n>: screenshot a cada n quadros em build/frame_*.png (custa um engasgo)
S=$(cd "$(dirname "$0")" && pwd)
cd "$S/../LASRecomp" 2>/dev/null || cd "$S/../.." || exit 1  # (from za-tools/ or LASRecomp/tools/za/)
# EXE=build/o1/lasrecomp.exe also takes that build's game library
[ -n "$EXE" ] && [ -z "$LARECOMP_GAME_LIB" ] && export LARECOMP_GAME_LIB="$PWD/$(dirname "$EXE")/lasgame.dll"
export PATH="/c/msys64/ucrt64/bin:/c/msys64/usr/bin:$PATH"
rm -f build/frame_*.png
export LARECOMP_SETTINGS=$S/za.ini LARECOMP_SCREENSHOT_EVERY=${SHOT:-0} LARECOMP_WAIT_DUMP=${WAIT:-10} LARECOMP_PROF_SVC=1 LARECOMP_SKIP_WHY=1
./${EXE:-build/lasrecomp.exe} extracted --play > "$S/play.log" 2>&1
echo "rc=$?"
