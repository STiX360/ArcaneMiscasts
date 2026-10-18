# Arcane Misfires: Quick In-Game Test

## Critical Failure Test

Double-click `Test-Critical-Failures.cmd` after closing other OpenMW sessions.
This starts a fresh character in a separate `arcane-critical-manual` profile
using OpenMW 0.52.0. Both backfire chance and critical chance are forced to 100%,
severity is capped at one, and Wild Intervention is enabled. Sound stays enabled
because failed-cast detection and the teleportation voice line require it.
Fourteen `AM Test - ...` spells are supplied, including Recall and both
Interventions. A shirt, trousers, shoes, ring and dagger are equipped for you.
Feather Backfire starts selected. Real saves and mod-manager profiles are unused.

1. Cast `AM Test - Feather Backfire`. Expect `Critical Failure: Leadbound Limbs`
   and Burden **150 points for 6 seconds**. Press F8 to disable criticals, wait
   for the effect to expire, then repeat: expect ordinary Burden **15 points for
   6 seconds**. F8 restores 100% criticals. Compare other effects the same way;
   tier-one Fire totals 20 damage when critical versus 2 normally. Silence is
   on/off, so its increased record magnitude has no extra gameplay effect.
2. Press F10 to refill resources and F7 to re-equip the kit. Select
   `AM Test - Recall`, then cast. Expect a wild destination, an empty equipment
   panel, all five test items still in inventory, and the original voice line
   about teleportation, being alone and naked. A delayed PASS/FAIL message
   checks equipment and inventory; confirm the voice by ear.
3. Repeat with `AM Test - Divine Intervention` and `AM Test - Almsivi Intervention`.
   Use F7 and F10 before each attempt; wait for knockdown recovery and the
   previous failure sound to finish. Airborne arrivals and fatigue loss follow
   existing Wild Intervention rules.
4. Use F8 for 0% criticals, F7 to equip gear, and repeat a teleport. Expect ordinary
   Wild Intervention with gear still equipped and no teleportation voice line.
5. At 100% criticals, disable Wild Intervention in Scripts settings and cast
   Recall. Expect critical Drain Magicka instead of teleportation, with gear
   still equipped. Re-enable Wild Intervention afterward.
6. Set critical chance to a fractional value in Scripts settings, save, reload,
   and confirm it persists. The fixture does not reset settings on reload.
7. Enable **Critical Teleport Failure - Drop All Items** in Scripts settings
   (it starts off). With critical chance at 100%, cast a teleport spell from a
   recognizable flat floor. Expect empty inventory and equipment after arrival.
   Press **F6** to return to the departure point and verify gear and loose items are on the
   same plane, including gold, consumable stacks, keys and quest items. Repeat
   indoors, on an upper floor, and outdoors. Tight spaces and large inventories
   can cause horizontal overlap; items must not form an upward pile. A missing
   nearby floor must fall back to teleporting and unequipping with inventory
   retained. Blocked teleports or missing destinations must leave items alone.
8. Enable **Immersion** (it starts off). Male Altmer should hear the voice line;
   other race/sex combinations should not. With Immersion off, all characters
   can hear it. Save/reload should preserve both new options.
9. Enable **Always Critical Teleport Miscasts When Overencumbered** and set
   critical chance to 0%, keeping backfire chance at 100%. Carry more weight
   than your capacity (or lower Strength until the inventory shows this), then
   cast each teleport test spell. Expect a critical despite the 0% critical
   chance, following the chosen drop-all and Immersion settings. At or below
   carrying capacity, or with the new option off, expect an ordinary miscast.
   Nonteleport spells must keep their normal critical chance. With backfire
   chance at 0%, no miscast should occur even while overencumbered. Save/reload
   should preserve the new option. Restore critical chance and character stats
   after testing; F10 does not restore Strength.

From the repository root, run a hidden, bounded native check of inventory removal, stack counts, and the
common drop plane in Arrille's Tradehouse and exterior Seyda Neen:

```powershell
python tools/verify_critical_inventory.py --engine-root 'C:/Modlists/POTI/.OpenMW' --game-data 'D:/Steam/steamapps/common/Morrowind/Data Files'
```

This invokes the actual Wild Intervention handler in disposable profiles; it
does not cast a spell or establish long-session, modlist or save/reload safety.
Sound stays enabled to exercise critical arrival handling; volume is muted.
Evidence is written to `.runtime/critical-drop-interior/result.txt` and
`.runtime/critical-drop-exterior/result.txt`. The manual fixture's drop-all
arrival check verifies empty equipment/inventory; inspect the departure floor
yourself for clipping with unusual item models.

F6 returns you to the latest critical teleport's departure cell, exact position,
and facing, without changing gear or inventory. The bookmark persists in test
saves and is replaced by the next critical teleport. Before your first critical
teleport, F6 displays a message instead. Inspect/pick up dropped items before
using F7, which can create replacement test gear if you left the originals behind.
F7 restores the five-item kit without duplicating existing inventory items; F8 switches
critical chance between 0% and 100%. F9 empties magicka; F10 refills resources.
These keys are ignored in menus. Logs are in
`.runtime/arcane-critical-manual-profile/openmw.log`; saves stay under
`.runtime/arcane-critical-manual-user-data`. Voice playback, blocked-teleport
areas and Nifty-installed compatibility remain manual checks. The ordinary
fixture's `-SmokeTest` does not establish critical gameplay correctness.

To prepare this profile without starting the game:

```powershell
.\Test-Critical-Failures.cmd -PrepareOnly
```

## Ordinary Miscast Test

Close other OpenMW instances, then double-click `Test-Arcane-Misfires.cmd`.
No mod-manager installation or console setup is needed. The launcher uses the
POTI-installed OpenMW 0.52 engine and Steam Morrowind plus both expansions, but
does not load or modify the POTI profile or real saves.

You start outdoors in Seyda Neen with Fire selected and casting readied.
OpenMW's normal spell-ready and cast controls still apply. The character has
500 health, 2,000 magicka and fourteen spells named `AM Test - ...` in the magic
menu. All six magic skills, Willpower and Luck are zero to make the ordinary
200-cost test spells reliably fail. This deliberately unusual character is
only for testing, not balance evaluation.

Backfire chance starts at 100%, with no cooldown, and severity capped at one.
Critical chance starts at 0% in this ordinary fixture for repeatable comparisons.
Music is muted; spell sounds stay enabled. The game remains open for manual
play. Every launcher run starts a fresh character; test saves can be reopened
through the game's Load menu.

## Quick Checks

### Failed-Cast Experience

All three experience toggles start on. The fixture displays `Test XP: <school>
+<amount> use points` whenever a magic skill receives experience, and records it
in the test log. These are normal skill-use points, not skill levels or percent.
The character's very low skills can level up quickly; this is expected. Open the
character menu and hover over a skill to inspect its progress.

Use `AM Test - Restoration Backfire` for the following checks: its attempted
school is Restoration, but its Fatigue Damage misfire belongs to Destruction.
Keep maximum severity at one and use F10 to refill resources as needed. Wait
for the casting-failure sound to finish between attempts.

| Experience From Failed Casts | Experience Only On Misfires | Use Misfire Effect's School | Backfire chance | Expected XP on failure |
| --- | --- | --- | --- | --- |
| On | On | On | 100% | Destruction, once |
| On | On | Off | 100% | Restoration, once |
| On | On | On | 0% | None |
| On | Off | On | 0% | Restoration, once |
| On | Off | On | 100% | Destruction, once |
| On | Off | Off | 100% | Restoration, once |
| Off | Either | Either | 100% or 0% | None |

Also disable backfires with the first XP toggle on and the second off: failed
casts should still award Restoration experience. With the second on, disabling
backfires should give no failed-cast experience. Test Guaranteed Success while
not silenced: it should award ordinary Alteration experience exactly once,
regardless of the failed-cast toggles. F9 insufficient-magicka attempts, powers,
and interrupted casts must award no failed-cast XP. Save and reload with the
three XP toggles off, confirm they remain off, then restore your preferred values.

`-SmokeTest` also casts a failing Restoration test spell and verifies that its
misfire awards Destruction progress using OpenMW's normal successful-cast gain.

### Backfire Behaviour

1. Cast the selected `AM Test - Fire Recoil`. Expect a casting failure followed
   by `Miscast: Cinder Recoil`, a Fire Damage effect, and a small health loss.
2. Select Frost or Shock Recoil and repeat. Their corresponding elemental
   effects should appear. Allow the previous failure sound to finish before
   casting again; very rapid retries can intentionally be ignored by detection.
3. Try Feather, Night Eye, Conjuration, Mysticism, Shield and Restoration
   Backfire spells. Expect Burden, Blind, Silence, Drain Magicka, Weakness to
   Magicka and fatigue damage respectively. Wait for Silence to expire before
   trying another spell. Blind affects accuracy, not screen brightness.
   In 0.1.1, mild Silence lasts six seconds. It prevents successful spells, not
   cast attempts or animations. To check it, trigger Conjuration Backfire, open
   Scripts settings and disable new backfires (this leaves existing Silence
   active), then select `AM Test - Guaranteed Success` while paused. Close the
   menu and cast immediately: it should animate but fail, with no Feather
   effect. After Silence expires, the same spell should succeed and briefly
   apply Feather. Re-enable backfires afterward. The other ordinary test spells
   cannot prove this restriction because they already fail even without Silence.
4. Select `AM Test - Guaranteed Success`. It should succeed with no backfire.
   This guarantee applies only when not silenced: native Silence overrides it.
   `AM Test - Power Exclusion` should also produce no backfire and follows the
   game's once-per-day power restriction.
5. Press F9 outside menus to empty magicka, then try an ordinary test spell.
   Expect insufficient-magicka feedback but no new backfire. Press F10 to refill
   health, magicka and fatigue. Refilling does not remove active magic effects.
6. In Esc > Options > Scripts > Arcane Misfires, raise maximum severity to two
   or three and repeat a test spell. Each ordinary test spell costs 200, so its
   backlash uses the chosen severity cap. Consecutive confirmed failures can
   both cause backfires: there is no cooldown or cooldown setting in 0.1.2.
   The normal gameplay chance remains 15%; this character uses 100% for testing.
7. Disable backfires in that settings page: test spells should still fail, but
   cause no new backlash. Existing effects should expire normally.
8. Save while a backfire is active, reload, and check that the existing effect
   continues without creating a duplicate. Chosen mod settings should persist.
   F10 refills resources after any punishing test; it does not reset settings.

F9/F10 are test-only controls and are ignored while menus are open. They are not
part of the normal mod. They do not require any modifier keys.

## Files and Overrides

- Settings, logs and storage: `.runtime/arcane-misfires-manual-profile`.
- Test saves, screenshots and cache: `.runtime/arcane-misfires-manual-user-data`.
- Log: `.runtime/arcane-misfires-manual-profile/openmw.log`.
- The test plugin and script are not included in the normal installable mod ZIP.
  Never enable them in your real modlist or copy real saves into the test profile.

The test ZIP includes this whole directory layout. Extract it to a writable
folder before launching; do not launch directly from inside the ZIP.

For different install paths:

```powershell
.\Test-Arcane-Misfires.cmd -Engine 'C:\Other OpenMW\openmw.exe' -GameData 'D:\Other Morrowind\Data Files'
```

`-PrepareOnly` writes and validates the isolated profile without starting the
game. `-SmokeTest` verifies the manual fixture in a separate, hidden disposable
game and quits automatically. It never uses the manual test saves or settings.
