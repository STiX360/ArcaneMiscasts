# Changelog

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
