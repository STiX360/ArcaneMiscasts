# Arcane Misfires 0.1.2 Validation

- 27 automated tests pass in Python 3.12 with Lua 5.1, executing the actual mod
  modules rather than a translated implementation.
- Lua coverage includes failure detection, success-before/after-release,
  interrupted casts, stale/restarted sounds, enchanted items, powers, changed
  selection, paused updates, consecutive independent rolls, settings, save/load state, all school
  fallbacks, elemental routing, numeric validation, sound-disabled fail-closed
  behaviour, and equip-animation isolation.
- Binary tests inspect all 27 TES3 SPEL records and check the archive against
  every source file. No meshes, textures, or sound files are redistributed.
- An isolated real OpenMW 0.52.0 build (revision 73765c58a2) exits successfully,
  resolves all 27 effect IDs and
  executes genuine player casts. Confirmed failed Feather produces tier-one
  Burden; successful casting and insufficient magicka cause no backfire;
  disabling stops new backfires; Burden expires; failed Fire produces tier-three
  recoil and health damage. Normal resistance remains effective.
- Test config, generated fixture plugin, logs, cache and user data are under
  `reports/arcane-engine-check`. Installed POTI configuration and player saves
  are not altered. Full engine output: `arcane-engine-check/result.txt`.

Remaining acceptance checks: full POTI load order, real-save reload of an active
backfire, effect and sound presentation, custom casting animations, player-made
multi-school/autocalculated spells, and long-play balance. This is a first
playable standalone implementation, not complete parity with Miscast Enhanced.

## Timing Revision

The user confirmed all nine backfires working in the 0.1.0 manual test, then
reported that two-second Silence largely elapsed during cast recovery.
Version 0.1.1 changes Silence and Burden to 6/9/12 seconds, Blind and Drain
Magicka to 8/12/16, and Weakness to Magicka to 10/15/20. Magnitudes, total damage,
chance and default cooldown are unchanged. The previous release ZIPs are retained
for comparison. New backfires use the updated plugin; existing active effects
should be allowed to expire before comparing versions.

Regression tests fix the new duration targets and preserve elemental/fatigue
damage budgets. The expanded engine test checks a genuine failed Conjuration
cast still has active mild Silence after casting recovery, then expires normally.
Player acceptance of the revised balance remains outstanding.

## Cooldown Removal

Version 0.1.2 removes the cooldown gate, setting, translation and serialized
timer. Each confirmed failure gets an independent configured-chance roll, even
with an earlier backfire active. Existing effect stacking rules are unchanged.
Old version-one saves still restore supported settings; their cooldown and
remaining-time fields are ignored and omitted from new saves.

The Lua tests now cover consecutive successful 15% rolls and ignored legacy
cooldowns. The engine scenario requires two consecutive failed casts to produce
two backfires less than eight seconds apart. The normal chance remains 15%.

## Silence Behaviour Correction

The user reported that Silence still allowed casting attempts. The earlier
explanation incorrectly implied an input/animation lock: native OpenMW Silence
sets ordinary spell success chance to zero, but still permits attempts. The
previous duration check proved an active Silence effect, not prevented success.

The engine scenario now attempts the normally guaranteed-success control spell
while silenced, verifies its release animation and failure sound with no effect
applied, waits for Silence to expire, and verifies the same spell succeeds again.
Backfires are disabled during these control attempts so they cannot introduce
extra penalties. The manual guide now includes this distinguishing check.

## Manual Test Launcher

`Test-Arcane-Misfires.cmd` starts an isolated fresh character outdoors in Seyda
Neen. The setup provides eleven spells, guaranteed-failure ordinary spell setup,
100% backfire chance, no cooldown, severity one, and ample resources. F9 empties
magicka; F10 refills resources. Setup runs once per fresh game and does not reset
settings or resources when loading a test save. The ordinary release ZIP is
unchanged; test fixtures are only in the separate test bundle.

Nine manual-fixture and package tests pass. A separate hidden engine smoke run
confirms the eleven spells are learned, Fire is selected, the casting stance
is ready, magic skills and Willpower are zero, resources are refilled, and test
settings are applied. The engine exits successfully without Lua errors.
Log: `../.runtime/arcane-misfires-smoke-profile/openmw.log`.
