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
| Version | 3.2.0 |
| Requires | EML (Enshrouded Mod Loader), see [Installing EML](#installing-eml) |
| Works on | Game client and dedicated server (Windows, Linux with Wine/Proton) |

## Compatibility

Tested on the **early access build `ea_update_08`**. Not yet verified on Enshrouded 1.0.

Version 3.2.0 is prepared for game updates:

- The skill tree, skill point and recipe changes are generic and also apply to new nodes and
  recipes.
- If a resource type or field no longer exists in a newer game version, the mod skips it and
  writes a warning to the EML log instead of failing, for example:
  `[free-skills] No skill tree nodes were changed, the skill tree data may have changed in this game version`.
- The old dismantle value restore (hardcoded `ea_update_08` values) is now **off by default**,
  so it no longer overwrites the rebalanced values of newer game versions.

Enshrouded 1.0 resets the skill tree on the first launch, so spend your skill points again after
updating.

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
   [free-skills] v3.2.0 Loading...
   [free-skills] nodes=222 spp=1 upgrades=12
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
| `restoreDismantleValues` | `false` | Forces the `ea_update_08` dismantle and perk values and enables durability in all game presets. Only for `ea_update_08`; leave it off on newer game versions. |

Perk upgrade costs are intentionally **not** changed: the same fields control how many runes
you get back when dismantling items.

## What it changes

Technically the mod patches these game resources through EML:

| Resource | Change |
| --- | --- |
| `keen::SkillTreeResource`, `keen::DevSkillTreeResource` | `costs = 0` on every node with a cost |
| `keen::BalancingTable` | `skillPointsPerLevel` set to the configured value |
| `keen::RecipeRegistryResource`, `keen::DevRecipeRegistryResource` | for recipes with `isUpgrade`: input counts, `requiredEnergy`, `waterAmount` and `waterCharges` set to 0 |
| `keen::BalancingTable`, `keen::GameSettingsPresetsResource` | only with `restoreDismantleValues=true`: dismantle related values set to the `ea_update_08` defaults, durability enabled in all presets |

The dismantle restore was added because an earlier version of the mod broke dismantling (about
4 runes instead of about 120). EML always patches from the original game data, so values changed
by older versions of the mod cannot persist, and the restore is no longer needed by default.

## Changelog

- **3.2.0**: dismantle value restore is opt-in (`restoreDismantleValues`, default off); missing
  resource types and fields are skipped with a warning instead of failing; warnings when a
  feature changed nothing; removed the unused `patchAllPresets` setting.
- **3.1.0**: original release by "Enshrouded Mods".

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
