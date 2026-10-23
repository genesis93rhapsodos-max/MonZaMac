#!/bin/bash
# Windows build (MSYS2 UCRT64 toolchain); log em za-tools/build.log. GEN=1 roda make gen antes.
S=$(cd "$(dirname "$0")" && pwd)
cd "$S/../LASRecomp" 2>/dev/null || cd "$S/../.." || exit 1  # (from za-tools/ or LASRecomp/tools/za/)
export PATH="/c/msys64/ucrt64/bin:/c/msys64/usr/bin:$PATH"
[ -n "$GEN" ] && { make gen > "$S/gen.log" 2>&1 || { tail -5 "$S/gen.log"; exit 1; }; }
rm -f build/obj/tools/gamelib_entry.o build/rt/gamelib.o build/rt/gamebuild.o  # (embed GAMELIB_ID, not tracked by make)
make -j$(nproc) GENARCH=-march=x86-64-v3 GENOPT=${GENOPT:--O0} > "$S/build.log" 2>&1 || { grep -E "error" "$S/build.log" | head -20; exit 1; }
echo build ok
