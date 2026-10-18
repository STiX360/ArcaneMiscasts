# Critical inventory validation

Validated 2026-10-18 using the POTI-installed OpenMW 0.52.0 executable at
`C:/Modlists/POTI/.OpenMW/openmw.exe`, with vanilla Steam Morrowind and expansions
in disposable profiles. The installed POTI profile and real saves were not used.
Sound was enabled to exercise the critical arrival handler, with master volume
muted. No third-party assets are bundled.

`tools/verify_critical_inventory.py` invoked the actual global Wild Intervention
handler with the drop option on. Both exterior Seyda Neen and the interior of
Arrille's Tradehouse passed: the player teleported, inventory became empty, and
all eight original item stacks remained in the departure cell at the same Z
coordinate. Equipped clothing and weapon, unequipped items, a three-potion stack,
and 1,000 gold were included. OpenMW changes dropped gold's pile-model record;
the test accounts for this and verifies the original currency amount.

Raw logs are under `.runtime/critical-drop-interior/result.txt` and
`.runtime/critical-drop-exterior/result.txt`. These generated profiles and logs
are excluded from normal packages.

Deterministic Lua tests additionally cover disabled defaults, saved settings,
noncritical behavior, blocked teleports, absent destinations, missing floors,
stale drop plans, floor heights, wall checks, and the Immersion race/sex matrix.
Missing or stale floor plans now fall back to teleporting and unequipping, with
inventory retained; this fallback is covered by deterministic Lua regression tests.

The native check directly invokes the intervention event: it does not prove the
full failed-cast detector path or settings persistence in a real save. The prior
critical test's user-reported success covers the original critical gameplay.
Upper-floor interiors, unusual item meshes, dense inventories, quest-script
interactions, manual save/reload, and a full modlist still require playtesting.
Items use checked shared-height positions; horizontal mesh overlap remains
possible and this validation does not claim clipping is impossible for all assets.
