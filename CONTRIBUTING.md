# Development

Use Python 3.12. From the repository root:

```powershell
python -m pip install -r requirements-dev.txt
python tests/run_tests.py
python -m unittest discover -s tests -p test_release.py -v
python tools/package_mod.py
```

Tests run the actual Lua modules with Lua 5.1 through Lupa. `run_tests.py` builds
the normal package first; fixture tests generate their own disposable content.
Packaging generates 27 spell records from `Arcane Misfires/outcomes.json` and
creates `dist/Arcane-Misfires-<VERSION>.zip`. Generated ESPs and ZIPs are ignored
by Git. The normal archive contains only the explicitly listed gameplay files.
The build input `outcomes.json` is excluded from the installable archive.

GitHub Releases are created by `.github/workflows/nexus-upload.yml` when a
`vX.Y.Z` tag is pushed. Tag a commit containing the workflow, and ensure its
`VERSION` and changelog match the tag. The action tests and builds the mod,
then attaches only `Arcane-Misfires-X.Y.Z.zip` to the release. Test bundles,
launchers, tools, and local profiles are excluded. GitHub automatically adds
separate source archives; those are not the installable mod download.
For the Nexus environment's Selected branches and tags rules, use branch
`main` and tag pattern `v*` (wildcard syntax, not a regular expression).

For the isolated manual test bundle:

```powershell
python tools/build_arcane_test.py
.\Test-Arcane-Misfires.cmd
```

See [Testing](TESTING-ARCANE-MISFIRES.md) for engine and game-data overrides.
Engine checks require a compatible local OpenMW installation and legally owned
Morrowind data; GitHub CI runs mocked Lua and packaging checks, not the game.

For the optional Nifty Spell Pack compatibility check, supply your extracted
local copy (it is never included in the normal mod or test archives):

```powershell
python tools/verify_nifty_intervention.py --engine-root "C:/OpenMW" --game-data "D:/Morrowind/Data Files" --nifty-data "D:/Mods/NiftySpellPack"
```

Run again without `--nifty-data` to verify the built-in equivalent. Both runs use
disposable profiles and genuine failed casts of all three teleport effects.
Close other OpenMW sessions first. Results go under `reports/nifty-installed`
or `reports/nifty-absent`; the check also covers toggle-off, zero chance, and
teleport-disabled protection. `test_wild_intervention.py` covers deterministic
destination and landing rules, including the uncommon door and airborne cases.

Keep runtime changes scoped, add regression tests, and maintain `CHANGELOG.md`
for each version. State player-visible changes and upgrade warnings clearly.
Keep test fixtures out of normal packages and never include saves, credentials,
local profiles, or third-party assets. Do not edit generated ESPs directly.

No license is selected yet; do not add one without the owner's decision.
