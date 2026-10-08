# Arcane Misfires: Quick In-Game Test

Close other OpenMW instances, then double-click `Test-Arcane-Misfires.cmd`.
No mod-manager installation or console setup is needed. The launcher uses the
POTI-installed OpenMW 0.52 engine and Steam Morrowind plus both expansions, but
does not load or modify the POTI profile or real saves.

You start outdoors in Seyda Neen with Fire selected and casting readied.
OpenMW's normal spell-ready and cast controls still apply. The character has
500 health, 2,000 magicka and eleven spells named `AM Test - ...` in the magic
menu. All six magic skills, Willpower and Luck are zero to make the ordinary
200-cost test spells reliably fail. This deliberately unusual character is
only for testing, not balance evaluation.

Backfire chance starts at 100%, with no cooldown, and severity capped at one.
Music is muted; spell sounds stay enabled. The game remains open for manual
play. Every launcher run starts a fresh character; test saves can be reopened
through the game's Load menu.

## Quick Checks

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
