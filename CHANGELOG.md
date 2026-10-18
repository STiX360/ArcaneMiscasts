# Changelog

## 1.1.0

- Added Always Critical Teleport Miscasts When Overencumbered, off by default. Triggered miscasts of spells containing Recall or either Intervention become critical when current encumbrance exceeds carrying capacity, even with critical chance at 0%. The normal backfire chance and enable toggle still apply. The setting persists in saves; existing saves default to off.
- Forced criticals respect the existing Wild Intervention, Drop All Items and Immersion settings. With Wild Intervention disabled, they use ordinary critical backlash instead. Successful casts and nonteleport spells are unaffected.

## 1.0.0

- First stable release, including configurable Critical Failures. By default, 1% of triggered miscasts are critical (0.15% of detected failed casts with the default 15% miscast chance). Set critical chance to 0% to disable them.
- Ordinary critical backlash has 10 times the selected tier's magnitude with unchanged duration. Silence remains an on/off effect.
- With Wild Intervention enabled, teleport criticals follow the built-in destination and landing rules, then unequip all gear and play Morrowind's original male High Elf teleportation voice line on successful arrival. Noncritical miscasts still prefer Nifty Spell Pack's spell when available.
- Added Critical Teleport Failure - Drop All Items, off by default. This leaves the entire inventory, including gold, keys and quest items, at the departure point. Item stacks remain intact and use checked floor positions at one height. Large inventories may overlap horizontally. Missing or stale floor checks fall back to teleporting and unequipping, keeping the inventory; blocked teleports and unavailable destinations leave items untouched.
- Added Immersion, off by default, to restrict the teleportation voice line to male Altmer characters. All new settings persist in saves; existing saves receive the 1% critical chance and disabled optional toggles.
- Added an isolated Critical Failure test with guaranteed criticals, three teleport spells, gear and inventory checks, comparison controls, and F6 to return to the latest departure point. Native OpenMW checks verify inventory drops indoors and outdoors. Test fixtures are excluded from the installable release.
- Upgrade by replacing the existing mod and enabling the same two content files. The updated ESP is required for the critical spell records; fully restart OpenMW after updating.

## 0.1.4

- Added Wild Intervention On Teleport Miscasts, enabled by default. Recall, Divine Intervention, and Almsivi Intervention miscasts prefer Nifty Spell Pack's spell when available, otherwise use an independently implemented equivalent. Unchecking the toggle restores normal backlash; the usual chance roll still applies.
- The built-in intervention matches Nifty 1.0.0's connected-exterior, dry-ground, door-detour, landing, airborne-arrival, fatigue, and teleport-permission rules without requiring or bundling Nifty files.

## 0.1.3

- Added Experience From Failed Casts, Experience Only On Misfires, and Use Misfire Effect's School to the Scripts settings page. All three default to on.
- Misfires award normal successful-cast skill progress in the backlash effect's school by default. Settings can reward all detected failures or use the attempted spell's school instead.
- Failed-cast experience settings persist in saves; existing saves receive the enabled defaults. Successful spells retain normal progression without extra experience.
- Added an in-game experience readout and a toggle test matrix to the isolated manual test. Verified a real Restoration failure awards normal Destruction progress from its backlash.
- Installable release ZIPs contain only the plugin, script manifest, Lua scripts, translations, and installation README; build inputs and test tools are excluded.

## 0.1.2

- Removed the backfire cooldown and its setting. Each confirmed failed cast receives an independent chance roll, even with a previous backlash active.
- Old saved cooldown values are ignored. Default chance, severity magnitudes, and damage totals are unchanged.
- Verified consecutive failures and ordinary spell failure during Silence, followed by successful casting after expiration.
- Added repository build, test, and release automation; clarified installation, exclusions, and temporary effect behaviour.

## 0.1.1

- Extended temporary non-damage penalties so the failed-cast animation consumes less of their useful duration.
- Silence now lasts 6 / 9 / 12 seconds. Other temporary penalty timings were also adjusted without increasing elemental or fatigue damage totals.
- Improved the isolated test fixture and Silence control-spell checks.

## 0.1.0

- Initial standalone OpenMW beta with nine spell-themed backfire outcomes and three severity tiers.
- Added failed-cast detection, exclusions, configurable chance and severity, and an isolated manual test bundle.
