# Skill Tree Mod (Free Skills & Upgrades)

An [EML](https://github.com/Shirenz0/kfc-parser) mod for Enshrouded that changes the skill tree
and the upgrade costs:

- **Free skill nodes:** every node in the skill tree costs 0 skill points.
- **More skill points:** you receive 10 skill points per level (configurable).
- **Free upgrade recipes:** upgrade recipes need no materials, energy or water.

The mod only changes game data before the game starts. It does not run code while you play.

| | |
| --- | --- |
| Mod id | `free-skills` |
| Version | 3.1.0 |
| Requires | EML (Enshrouded Mod Loader), see [Installing EML](#installing-eml) |
| Works on | Game client and dedicated server (Windows, Linux with Wine/Proton) |

## Compatibility

This version was built and tested for the **early access build `ea_update_08`**.

Enshrouded 1.0 changes the skill tree (the skill tree is reset on the first 1.0 launch) and
rebalances many values. The part of this mod that restores the dismantle values
(see [What it changes](#what-it-changes)) uses hardcoded values from `ea_update_08` and must be
checked against 1.0 before it is used there. Until this README says otherwise, treat the mod as
**not verified for 1.0**.

## Installing EML

Use the EML build from our own fork, **[Shirenz0/kfc-parser](https://github.com/Shirenz0/kfc-parser)**,
branch [`compat/1.0`](https://github.com/Shirenz0/kfc-parser/tree/compat/1.0). It contains fixes
that are not (yet) in the upstream release, most importantly: EML no longer aborts the game when
something goes wrong, it logs the error, restores the original game data and lets the game start.

There are no prebuilt binaries yet, so build `dbghelp.dll` from source
(requires [Rust](https://rustup.rs) 1.88.0 or newer):

```bash
git clone https://github.com/Shirenz0/kfc-parser.git
cd kfc-parser
git checkout compat/1.0
cargo build --release -p dbghelp-proxy
```

The result is `target/release/dbghelp.dll`.

Then:

1. Copy `dbghelp.dll` into the root of your Enshrouded installation, next to `enshrouded.exe`
   (or `enshrouded_server.exe` for a dedicated server).
2. Create a `mods` directory in the same location.

On Linux (Wine/Proton) the DLL override must be enabled, for example in the Steam launch options:

```bash
WINEDLLOVERRIDES="dbghelp=native,builtin" %command%
```

For a dedicated server started with Proton, set the same `WINEDLLOVERRIDES` environment variable
for the server process (for Docker: in the container environment).

## Installing the mod

1. Copy the `free-skills` folder from this directory into the `mods` directory of the game:

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

2. Optionally adjust `config.txt` (see below).
3. Start the game. The EML log in `logs/<date>.eml.log` should contain lines like:

   ```
   [free-skills] v3.1.0 Loading...
   [free-skills] nodes=222 spp=1 upgrades=12 dismantleRestore=3
   [free-skills] Done.
   ```

**Multiplayer:** install EML and the mod on the dedicated server **and** on every player's client,
so that the server and the clients use the same values.

## Configuration

`free-skills/config.txt`:

| Setting | Default | Effect |
| --- | --- | --- |
| `enabled` | `true` | Turns the whole mod on or off. |
| `freeSkillNodeCosts` | `true` | Sets the cost of every skill tree node to 0. |
| `skillPointsPerLevel` | `10` | Skill points gained per level. Values of 0 or lower leave the game default. |
| `freeUpgradeRecipes` | `true` | Removes the material, energy and water costs of upgrade recipes. |
| `patchAllPresets` | `true` | Present in the config but currently not used by the code. |

Perk upgrade costs are intentionally **not** changed: the same fields control how many runes
you get back when dismantling items.

## What it changes

Technically the mod patches these game resources through EML:

| Resource | Change |
| --- | --- |
| `keen::SkillTreeResource`, `keen::DevSkillTreeResource` | `costs = 0` on every node with a cost |
| `keen::BalancingTable` | `skillPointsPerLevel` set to the configured value |
| `keen::RecipeRegistryResource`, `keen::DevRecipeRegistryResource` | for recipes with `isUpgrade`: input counts, `requiredEnergy`, `waterAmount` and `waterCharges` set to 0 |
| `keen::BalancingTable`, `keen::GameSettingsPresetsResource` | dismantle related values restored to the `ea_update_08` defaults, durability enabled in all presets |

The last step exists because an earlier version of the mod broke dismantling (about 4 runes
instead of about 120). It always runs last and forces the `ea_update_08` values, which is why it
has to be reviewed for every game update.

## Uninstalling

1. Remove the `free-skills` folder from `mods`.
2. Removing the mod (or `dbghelp.dll`) does not undo changes that were already applied to the
   game data. Restore the original data by letting Steam verify the game files, or with
   `emm.exe restore -g <game-dir>` from the same EML build.

Back up your saves before installing or removing the mod: skills you unlock with it stay on your
character.

## Credits and license

The original mod was published as "Free Skills & Upgrades" by "Enshrouded Mods" under the MIT
license (see `free-skills/mod.json`). This copy is maintained by
[Shirenz0](https://github.com/Shirenz0) and keeps the same license.
