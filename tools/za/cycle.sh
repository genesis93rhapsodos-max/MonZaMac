#!/bin/bash
# build + boot Pokémon Z-A once; log in $S/run.log
S=$HOME/recomp/za-tools
cd $HOME/recomp/LASRecomp
rm -f build/obj/tools/gamelib_entry.o build/rt/gamelib.o build/rt/gamebuild.o  # (they embed GAMELIB_ID, which make does not track)
make -j18 DEPS=$PWD/build/deps GENARCH=-march=x86-64-v3 GENOPT=${GENOPT:--O0} > $S/build.log 2>&1 || { grep -E "error" $S/build.log | head -20; exit 1; }
LD_LIBRARY_PATH=$PWD/build/deps/lib timeout ${T:-60} ./build/lasrecomp extracted --play $EXTRA > $S/run.log 2>&1
echo "rc=$? linhas=$(wc -l < $S/run.log)"
