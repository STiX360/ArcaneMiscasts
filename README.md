# Arcane Misfires

Failed spells can backfire with temporary, spell-themed penalties in OpenMW.

**Version 0.1.2, beta.** A small standalone gameplay mod, not a magic overhaul.
Ordinary failed player casts have a **15% chance** of a backfire by default.
There is **no cooldown**; every detected failure gets its own roll.

Three Scripts settings toggles control failed-cast experience and start enabled:
**Experience From Failed Casts**, **Experience Only On Misfires**, and
**Use Misfire Effect's School**. Defaults award normal successful-cast progress
in the backlash effect's school only when a misfire occurs. Turn off the second
to reward every detected failed cast, including with backfires disabled;
failures without a misfire use the attempted spell's school. Turn off the third
to always use the attempted school. The first toggle off disables all such XP.

## Requirements

- Morrowind and a compatible OpenMW build. Tested on OpenMW **0.52 development**, revision `73765c58a2`; older releases are not certified.
- OpenMW's sound system must be enabled. Muting the volume is fine; `--no-sound` prevents failed-cast detection.
- No MWSE, Magicka Expanded, custom textures, models, or other mods required. Classic Morrowind is not supported.

The Lua APIs used include AnimationController, SkillProgression, Settings,
`activeSpells:add`, and magic-school failure-sound metadata. Try a disposable save
before adding the beta to an important playthrough.

## Installation

Download **Arcane-Misfires-0.1.2.zip** from the repository's Releases page, or Nexus.
GitHub's automatically generated source archives are not installable mod packages.

1. Extract the mod ZIP into its own directory. `ArcaneMisfires.esp`, `ArcaneMisfires.omwscripts`, `scripts`, and `l10n` should be directly inside it.
2. Add that directory to OpenMW's data paths and enable **both** content files after `Morrowind.esm`.
3. Fully restart OpenMW. Settings are under **Options > Scripts > Arcane Misfires**.

Example additions to your active `openmw.cfg`, preserving existing entries:

```ini
data="D:/Games/OpenMW/Mods/ArcaneMisfires"
content=ArcaneMisfires.esp
content=ArcaneMisfires.omwscripts
```

### Mod Organizer 2 With OpenMW

Install the version ZIP with **Install mod...**, enable the mod in the left-hand
list, and enable `ArcaneMisfires.esp` in **Plugins**. Your OpenMW integration must
also enable `ArcaneMisfires.omwscripts`; if it uses a generated dummy ESP, enable
`ArcaneMisfires.omwscripts.esp` too. The real `ArcaneMisfires.esp` is still required:
it contains the backfire spell records and is not a placeholder. Launch OpenMW,
not the classic Morrowind executable.

## What Happens In-Game

A successful spell behaves normally. When an ordinary spell fails, the mod may
apply one backfire related to the failed spell's effect or school. Built-in hit
sounds and visual effects accompany the temporary penalty.

| Failed spell | Possible backfire | Tier 1 / 2 / 3 magnitude | Duration, seconds |
|---|---|---|---|
| Fire damage | Cinder Recoil: Fire Damage | 1 / 2 / 3 per second | 2 / 3 / 4 |
| Frost damage | Rime Recoil: Frost Damage | 1 / 2 / 3 per second | 2 / 3 / 4 |
| Shock damage | Static Recoil: Shock Damage | 1 / 2 / 3 per second | 2 / 3 / 4 |
| Feather, movement spells; other Alteration | Leadbound Limbs: Burden | 15 / 30 / 50 | 6 / 9 / 12 |
| Night Eye, Light, concealment; other Illusion | Afterimage: Blind | 10 / 20 / 35 | 8 / 12 / 16 |
| Conjuration | Severed Invocation: Silence | On / on / on | 6 / 9 / 12 |
| Magicka effects; other Mysticism | Hollow Reservoir: Drain Magicka | 5 / 10 / 20 | 8 / 12 / 16 |
| Shield, Spell Absorption, Reflect | Fractured Ward: Weakness to Magicka | 10 / 20 / 30% | 10 / 15 / 20 |
| Other Destruction and Restoration | Arcane Exhaustion: Damage Fatigue | 5 / 10 / 15 per second | 2 / 3 / 4 |

**Silence blocks successful ordinary spells, not casting attempts or animations.**
You can still attempt a spell and spend magicka. **Blind affects accuracy**, not
screen brightness. Neither effect adds an input lock or a custom screen shader.

Elemental recoil deals a nominal total of **2 / 6 / 12 damage** before resistance
and weakness; it can kill a low-health player. Fatigue damage totals **10 / 30 / 60**
and can knock down an exhausted character. Expiration does not heal damage dealt.

### Chance And Severity

Character skills, Willpower, Luck, and fatigue influence whether casting succeeds
through the engine's normal rules. They do not directly change the mod's 15%
roll once a failure has been detected. Better casting ability therefore means
fewer opportunities to backfire, not a smaller penalty for the same failed spell.

The spell record's cost determines the starting severity: **below 15** is tier 1,
**15-39** is tier 2, and **40 or more** is tier 3. The severity setting caps this
tier. This is the exposed record cost, not a separate reimplementation of the
engine's casting-cost formula. Enable/disable, chance, severity cap, and feedback
settings are available in the Scripts settings page.

Normal resistance is preserved. Backfires cannot be reflected or absorbed. The
same outcome and tier does not stack its magnitude; different outcomes or tiers
can coexist. For multi-effect spells, the detected failure school and strongest
recognised effect in that school choose one result. Unrecognised effects use a
school fallback. No backfire spells are added to your learned-spell list.

Powers, scrolls, enchanted items, successful casts, insufficient-magicka attempts,
and interrupted casts that never release are excluded. NPCs are unaffected.

## Saves, Updates, And Removal

Settings belong to the player save. Pending cast detection is discarded on load;
OpenMW owns the active temporary effects. Real-playthrough save/reload coverage
is still outstanding, so keep a backup.

For an update, replace the existing installation; do not enable a second copy.
Keep the same content filenames and fully restart OpenMW. Already-active effects
may retain their old duration until they expire. Version 0.1.2 ignores saved
cooldown fields from earlier versions.

To remove, disable backfires in settings, wait **at least 25 unpaused seconds**,
then save and disable both content files. Do not remove the spell-record plugin
while its effects are active. Existing damage still requires normal recovery.

## Compatibility And Testing

The mod observes cast animations, release keys, and newly started school failure
sounds; there is no dedicated Lua spell-failed event. Mods changing these signals
need testing. A rapid repeat whose failure sound never stops may be missed.
The detector deliberately favours missed failures over penalising unrelated actions.

All nine backfires have been checked in the isolated in-game test. Automated Lua
and engine checks cover detection, exclusions, consecutive failures, and Silence
followed by restored successful casting. Full modlist compatibility, real-save
reload, and longer-session balance testing remain outstanding.

The separate **Arcane-Misfires-Test** ZIP starts an isolated test character with
100% backfire chance. It is not the normal gameplay download and must not be
enabled in a real save. See [Testing](TESTING-ARCANE-MISFIRES.md) and the
[validation report](reports/arcane-misfires-validation.md).

## Development

[Contributing](CONTRIBUTING.md) covers builds and tests.
[Publishing](NEXUS-PUBLISHING.md) documents the GitHub/Nexus release process.
[Changelog](CHANGELOG.md) supplies the release notes for both services.

## Credits And License

Inspired by the failed-cast backlash idea in
[Miscast Enhanced by OperatorJack](https://www.nexusmods.com/morrowind/mods/47948).
Independently written, not an official port or a one-to-one recreation. No original
mod code, text, meshes, textures, sounds, or record data are included.

No repository license has been selected yet.
