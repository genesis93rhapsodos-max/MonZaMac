#!/bin/bash
# Pokémon Z-A com o teclado: setas = d-pad, Enter = A, Backspace = B, P = Plus, M = Minus (WASD = analógico, K/J/L/I = A/B/X/Y)
# log em za-tools/play.log, screenshot a cada 120 quadros em LASRecomp/build/frame_*.png
# roda sob o gdb (hang.gdb): num travamento, `kill -INT $(pgrep -x lasrecomp)` põe os stacks de todas as threads no log
S=$HOME/recomp/za-tools
cd $HOME/recomp/LASRecomp
rm -f build/frame_*.png
export LARECOMP_SETTINGS=$S/za.ini LARECOMP_SCREENSHOT_EVERY=${SHOT:-120} LARECOMP_WAIT_DUMP=${WAIT:-10} LARECOMP_PROF_SVC=1 LARECOMP_SKIP_WHY=1 LD_LIBRARY_PATH=$PWD/build/deps/lib
gdb -q -batch -x $S/hang.gdb --args ./build/lasrecomp extracted --play > $S/play.log 2>&1
echo "rc=$?"
