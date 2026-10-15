# Enshrouded Mods

A collection of mods for [Enshrouded](https://store.steampowered.com/app/1203620/Enshrouded/),
maintained by [Shirenz0](https://github.com/Shirenz0).

All mods in this repository are written for **EML (Enshrouded Mod Loader)**, a Lua-based mod
loader that patches the game data before the game starts. We use and maintain our own EML build:
**[Shirenz0/kfc-parser](https://github.com/Shirenz0/kfc-parser)**, branch
[`compat/1.0`](https://github.com/Shirenz0/kfc-parser/tree/compat/1.0).

## Mods

| Mod | Folder | Description | Status |
| --- | --- | --- | --- |
| Skill Tree Mod | [`Skill Tree Mod`](Skill%20Tree%20Mod) | Free skill tree nodes, more skill points per level and free upgrade recipes | Tested on `ea_update_08`, not yet verified for 1.0 |

Every mod folder has its own README with details, configuration and compatibility notes.

## Requirements

- Enshrouded (game client or dedicated server, Windows or Linux with Wine/Proton).
- EML built from [Shirenz0/kfc-parser](https://github.com/Shirenz0/kfc-parser) branch `compat/1.0`.

Our EML branch contains fixes that are not in the upstream release yet. The most important one
for players: if EML or a mod fails (for example after a game update), the error is logged, the
original game data is restored from EML's backup where possible, and the game starts without
mods instead of crashing.

## Installing EML

There are no prebuilt binaries yet, so build `dbghelp.dll` from source
(requires [Rust](https://rustup.rs) 1.88.0 or newer):

```bash
git clone https://github.com/Shirenz0/kfc-parser.git
cd kfc-parser
git checkout compat/1.0
cargo build --release -p dbghelp-proxy
```

1. Copy `target/release/dbghelp.dll` into the root of your Enshrouded installation, next to
   `enshrouded.exe` (or `enshrouded_server.exe` for a dedicated server).
2. Create a `mods` directory in the same location.

On Linux (Wine/Proton) enable the DLL override, for example in the Steam launch options:

```bash
WINEDLLOVERRIDES="dbghelp=native,builtin" %command%
```

EML writes its log to `logs/<date>.eml.log` in the game directory.

## Installing a mod

Each mod folder in this repository contains the actual mod folder (with a `mod.json` and a
`src/mod.lua`). Copy that inner folder into the `mods` directory of the game, for example:

```
Enshrouded/
  enshrouded.exe
  dbghelp.dll
  mods/
    free-skills/
      mod.json
      config.txt
      src/mod.lua
```

For multiplayer, install EML and the same mods on the dedicated server and on every player's
client.

## Before you install

- **Back up your saves.** Changes made with mods (for example unlocked skills) stay on your
  character.
- **Game updates:** after an update, check the status column above and the README of each mod
  before playing with mods enabled.
- **Uninstalling:** removing a mod or `dbghelp.dll` does not undo changes that were already
  applied to the game data. Let Steam verify the game files, or run
  `emm.exe restore -g <game-dir>` from the same EML build.

## Repository layout

```
<Mod Name>/
  README.md        what the mod does, configuration, compatibility
  <mod-id>/        the EML mod, copied as-is into <game>/mods/
    mod.json
    src/mod.lua
```

## License

Each mod keeps its own license, stated in its README and `mod.json`.
