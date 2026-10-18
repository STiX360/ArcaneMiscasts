# Arcane Misfires

Failed spells can backfire with temporary, spell-themed penalties in OpenMW.
Version 1.0.0, stable. Requires compatible OpenMW 0.52 development APIs and Morrowind;
classic Morrowind/MWSE is not supported. No other mods or custom assets required.

## Install

Extract this ZIP into its own mod directory. Add that directory to OpenMW's data
paths, then enable both ArcaneMisfires.esp and ArcaneMisfires.omwscripts after
Morrowind.esm. Restart OpenMW. Settings: Options > Scripts > Arcane Misfires.

```ini
data="D:/Games/OpenMW/Mods/ArcaneMisfires"
content=ArcaneMisfires.esp
content=ArcaneMisfires.omwscripts
```

MO2 users must run OpenMW and enable the real ArcaneMisfires.esp plus the script
manifest through their OpenMW integration. A generated script dummy ESP, if used,
does not replace the real spell-record plugin.

## Gameplay

Default chance: 15% per confirmed failed ordinary player spell, with no cooldown.

Critical Failure chance defaults to 1% of triggered miscasts (0.15% of detected
failed casts with default settings). Configure it from 0% to 100% in Scripts
settings; existing saves receive 1%. Critical backlash has 10 times its normal
magnitude at the chosen tier, with unchanged duration. Silence is an on/off
effect, so a larger magnitude does not increase its practical effect.

With Wild Intervention enabled, teleport criticals instead use the built-in
Wild Intervention rules, even when Nifty is installed. Successful arrival
unequips all gear and plays the original High Elf teleportation voice line.
Items stay in the inventory. Blocked or failed teleports do neither. Turning
Wild Intervention off restores ordinary backlash with 10 times magnitude on
criticals. The voice uses Morrowind's own audio; no audio files are bundled.

Two additional Scripts settings default to off. Critical Teleport Failure -
Drop All Items moves the entire inventory, including gold, keys and quest items,
to the departure floor before a critical teleport. Item stacks stay intact.
Short floor and wall checks select nearby positions on one common plane;
ground snapping is disabled, and large inventories can overlap horizontally
instead of forming a vertical pile. If no safe nearby floor is found or the floor
check is stale, teleport normally and only unequip gear, keeping all items in
inventory. Blocked teleports or unavailable destinations
also leave items untouched. Immersion restricts the voice line to male High Elf
(Altmer) characters. Both options persist with the player save.

The Scripts settings page includes three experience toggles, all on by default:
Experience From Failed Casts, Experience Only On Misfires, and Use Misfire
Effect's School. By default, misfires award normal successful-cast skill progress
in the backlash effect's school. Disable the second toggle to reward every
detected failure (including when backfires are disabled); failures without a
misfire use the attempted spell's school. Disable the third to always use the
attempted school. Disabling the first stops all failed-cast experience.
Successful spells, powers, scrolls, enchanted items, no-magicka attempts, and
unreleased interrupted casts are excluded. NPCs are unaffected.

Possible results: Fire/Frost/Shock Damage, Damage Fatigue, Burden, Blind, Silence,
Drain Magicka, or Weakness to Magicka. Spell record cost selects tier 1 below 15,
tier 2 at 15-39, and tier 3 at 40+, limited by the severity setting. Stats affect
normal casting success, not the backfire roll after a detected failure.

Wild Intervention On Teleport Miscasts defaults to on. When Nifty Spell Pack's
NiftySpellPack.omwaddon and spell are available, teleport miscasts use its Wild
Intervention. Otherwise an independently implemented built-in equivalent is
used. Turning the toggle off restores the usual backlash. Chance still applies;
the severity cap does not scale Wild Intervention. No Nifty files are required.

The built-in version follows Nifty 1.0.0's rules: find the current or connected
exterior (up to ten load doors), sample up to twenty cells at grid distance 2-6,
and try sixteen dry terrain positions per cell. Regionless cells are excluded.
It has a 20% chance of arriving through an unlocked, unscripted load door, and
a further 20% chance of reversed orientation. Exterior arrivals use a 9x9 ray
grid across 1000 units to find the lowest dry collision surface (lowest wet hit
if none are dry), with a 5% chance of arriving 250-1000 units above it. Fatigue
becomes a random integer from -15 to 5 unless in god mode. Teleport-disabled
areas and destinations that cannot be resolved cause the intervention to fail.
Knockdown and falling damage are possible.

Silence lasts 6/9/12 seconds and prevents successful ordinary spells, not attempts
or animations. Blind affects accuracy, not brightness. Normal resistance applies;
backfires cannot be reflected or absorbed. Same outcome/tier magnitudes do not
stack; different outcomes or tiers can coexist. Elemental recoil totals 2/6/12
damage before resistance; fatigue damage totals 10/30/60. Damage can be dangerous
at low health or fatigue and is not healed when effects expire.

The sound system must stay enabled: muted volume is fine, --no-sound is not.
Detection observes animations and new school failure sounds. Sound/animation
replacers need testing, and very rapid repeat failures may be missed. Tested with
OpenMW 0.52 development revision 73765c58a2 in an isolated fixture. Full modlist,
real-save reload, and longer-session balance checks remain outstanding.

## Update Or Remove

Replace the existing mod when updating; never enable two copies. Restart OpenMW.
Old saved cooldowns are ignored. Active effects may keep earlier timings until
expiration. Settings are saved with the player; pending cast detection is not.

Before removal, disable backfires, wait at least 25 unpaused seconds, save, then
disable both content files. Keep a backup save. Do not remove active spell records.

## Credits

Wild Intervention rule set and optional original spell: Nifty Spell Pack
https://www.nexusmods.com/morrowind/mods/58691
The built-in equivalent is independently implemented.

Inspired by Miscast Enhanced by OperatorJack:
https://www.nexusmods.com/morrowind/mods/47948
Independently written; not an official port or exact recreation. No original mod
code, text, assets, or record data are included. No repository license selected yet.
