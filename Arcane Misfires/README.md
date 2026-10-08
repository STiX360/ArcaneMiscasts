# Arcane Misfires

Failed spells can backfire with temporary, spell-themed penalties in OpenMW.
Beta release. Requires compatible OpenMW 0.52 development APIs and Morrowind;
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
Successful spells, powers, scrolls, enchanted items, no-magicka attempts, and
unreleased interrupted casts are excluded. NPCs are unaffected.

Possible results: Fire/Frost/Shock Damage, Damage Fatigue, Burden, Blind, Silence,
Drain Magicka, or Weakness to Magicka. Spell record cost selects tier 1 below 15,
tier 2 at 15-39, and tier 3 at 40+, limited by the severity setting. Stats affect
normal casting success, not the backfire roll after a detected failure.

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

Inspired by Miscast Enhanced by OperatorJack:
https://www.nexusmods.com/morrowind/mods/47948
Independently written; not an official port or exact recreation. No original mod
code, text, assets, or record data are included. No repository license selected yet.
