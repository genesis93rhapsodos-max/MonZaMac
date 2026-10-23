#!/bin/bash
# rodada automática: IN="quadro:BOTÃO:duração,..." (LARECOMP_INPUT), T=timeout s; nome = Teste
# para sozinha após 25 s sem quadros novos (stacks via gdb no log); log em za-tools/auto.log, quadros em build/frame_*.png
S=$HOME/recomp/za-tools
cd $HOME/recomp/LASRecomp
rm -f build/frame_*.png build/pass_*.png
export LARECOMP_INPUT="$IN" LARECOMP_KBD_AUTO=Teste LARECOMP_SCREENSHOT_EVERY=${SHOT:-60} LARECOMP_WAIT_DUMP=10 LARECOMP_PROF_SVC=1 \
    LARECOMP_SKIP_WHY=1 LD_LIBRARY_PATH=$PWD/build/deps/lib
timeout ${T:-300} gdb -q -batch -x $S/hang.gdb --args ./build/lasrecomp extracted --play > $S/auto.log 2>&1 &
G=$!
sleep 40; last=""; stuck=0
while kill -0 $G 2>/dev/null; do
    cur=$(grep -a "^\[vk\] t=" $S/auto.log | tail -1 | cut -c1-30)
    if [ "$cur" = "$last" ]; then stuck=$((stuck+5)); else stuck=0; last="$cur"; fi
    if [ $stuck -ge 25 ]; then echo "HANG em: $cur"; kill -INT $(pgrep -x lasrecomp); sleep 15; break; fi
    sleep 5
done
wait $G 2>/dev/null
echo "fim: $(grep -a '^\[vk\] t=' $S/auto.log | tail -1 | cut -c1-40)"; grep -a -m3 "FATAL\|received signal SIG[^I]" $S/auto.log
ls $HOME/recomp/LASRecomp/build/frame_*.png 2>/dev/null | tail -1
