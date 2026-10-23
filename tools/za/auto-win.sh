#!/bin/bash
# Windows (Git Bash) version of auto.sh: IN="quadro:BOTÃO:duração,..." (LARECOMP_INPUT), T=timeout s, SHOT=, EXTRA env
# vars go straight through (ex.: LARECOMP_DEBUG_FRAME=800). Sem gdb/timeout do MSYS (travam a janela): roda o .exe
# direto e o encerra com taskkill após T s ou 25 s sem quadros novos. Log em za-tools/auto.log, quadros em build/frame_*.png
S=$(cd "$(dirname "$0")" && pwd)
cd "$S/../LASRecomp" 2>/dev/null || cd "$S/../.." || exit 1  # (from za-tools/ or LASRecomp/tools/za/)
# EXE=build/o1/lasrecomp.exe also takes that build's game library
[ -n "$EXE" ] && [ -z "$LARECOMP_GAME_LIB" ] && export LARECOMP_GAME_LIB="$PWD/$(dirname "$EXE")/lasgame.dll"
export PATH="/c/msys64/ucrt64/bin:/c/msys64/usr/bin:$PATH"
rm -f build/frame_*.png build/pass_*.png
# tests play on a scratch copy of the save (the game autosaves): build/testsave, fresh from save/ each run
# (TESTSAVE_KEEP=1: carry on from the previous run's scratch save)
[ -z "$TESTSAVE_KEEP" ] && { rm -rf build/testsave; mkdir -p build/testsave; cp -r save/save_0 build/testsave/; }
export LARECOMP_SAVE_DIR=$PWD/build/testsave
export LARECOMP_SETTINGS=$S/za.ini LARECOMP_INPUT="$IN" LARECOMP_KBD_AUTO=Teste LARECOMP_SCREENSHOT_EVERY=${SHOT:-60} LARECOMP_WAIT_DUMP=10 LARECOMP_PROF_SVC=1 \
    LARECOMP_SKIP_WHY=1
./${EXE:-build/lasrecomp.exe} extracted --play > "$S/auto.log" 2>&1 &
G=$!
start=$SECONDS; last=""; stuck=0
while kill -0 $G 2>/dev/null; do
    sleep 5
    if [ $((SECONDS - start)) -ge ${T:-300} ]; then echo "timeout ${T:-300}s"; break; fi
    [ $((SECONDS - start)) -lt 40 ] && continue
    cur=$(grep -a "^\[vk\] t=" "$S/auto.log" | tail -1 | cut -c1-30)
    if [ "$cur" = "$last" ]; then stuck=$((stuck+5)); else stuck=0; last="$cur"; fi
    if [ $stuck -ge 25 ]; then echo "HANG em: $cur"; break; fi
done
taskkill //F //IM lasrecomp.exe > /dev/null 2>&1
wait $G 2>/dev/null
echo "fim: $(grep -a '^\[vk\] t=' "$S/auto.log" | tail -1 | cut -c1-40)"; grep -a -m3 "FATAL\|EXCEPTION\|access violation" "$S/auto.log"
ls build/frame_*.png 2>/dev/null | tail -1
