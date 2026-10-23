# MonZaMac

*Pokémon Legends: Z-A on macOS (Apple Silicon, Metal).*

A native macOS port of **Pokémon Legends: Z-A** (Nintendo Switch, v2.0.2 + the Mega Dimension DLC) built by **static
recompilation**: the game's ARM64 code is translated ahead of time into C and compiled for the Mac, and the Switch's
operating system and GPU (NVN) are reimplemented in the runtime. No emulator runs at play time.

> **You need your own copy of the game.** No game files, code, assets or fonts are included in this repository.

## Status

Work in progress. It boots, goes through the intro and reaches Lumiose City.

Working:
- Rendering on Metal: environment, walls, characters (GPU skinning through transform feedback), lighting, GPU-driven
  culling (indirect draws), text, dialogue and UI
- Audio, the game's menus, saves
- Controller and keyboard input

Known issues:
- The player's legs are posed wrongly while walking
- Occasional stalls at startup (restart the game)

## Building and running

Requirements: macOS on Apple Silicon, Xcode command line tools, SDL3 and FFmpeg (Homebrew).

1. Put your own game files in `extracted/`: `extracted/exefs/` (`main`, `main.npdm`, `rtld`, `sdk`) and `extracted/romfs/`
   + `extracted/romfs.bin`, extracted from your own copy of the game. Keys stay local (`.keys/`, never committed).
2. Build: `make B=build/za202 GEN=generated-202 -j8` (generates and compiles the recompiled game code; the first build
   takes a while).
3. Run: `./build/za202/lasrecomp extracted --play`. The log goes to the terminal; redirect it to a file to keep it.

Keyboard: WASD move, arrows d-pad, Enter = A, Backspace = B, K = talk, Q / E = L / R. F1 opens the in-game menu.

## Layout

- `runtime/` - the runtime: kernel, HLE services, loader, UI
- `runtime/nvn/` - the NVN-to-Metal backend: `maxwell/translate.c` (Maxwell shader to MSL), `renderer.m` (command
  executor), `metal.m` (window and presentation)
- `tools/` - the recompiler (`gen.py`, `lifter.py`) and game-specific tooling (`tools/za/`)

Debug aids: `LARECOMP_*` environment variables (see `runtime/nvn/renderer.m`); `touch build/dumpframe` captures a frame.

## Credits and license

MonZaMac is a fork of **[LAS Recomp](https://github.com/peiikai/LASRecomp)** by **Peiikai**, whose recompiler, runtime
and NVN/Maxwell shader work it builds on (made for *The Legend of Zelda: Link's Awakening*), and of its Pokémon Z-A
fork. Contributors and third-party components are listed in [docs/LASRecomp-README.md](docs/LASRecomp-README.md#credits).

The code is under the [MIT License](LICENSE) (LAS Recomp © Peiikai; the additions under the same license). This is a fan
project, not affiliated with, endorsed by or sponsored by Nintendo, Game Freak or The Pokémon Company.
