# GitHub And Nexus Releases

This uses the same release structure as Memorial Ledger: build and test once,
retain the exact ZIP, verify its SHA-256 in each publishing job, and extract the
current version's notes from `CHANGELOG.md` for both destinations.

## Ordinary Commits

`Validate And Package` runs on pushes, pull requests, and manual dispatch.
It tests on Windows and Ubuntu and retains the install-ready ZIP as an Actions
artifact. Commits alone do not publish a public release or upload to Nexus.

## First Nexus Publish

1. Create the mod page and manually upload the normal version ZIP. Do not upload the test bundle or a GitHub source archive.
2. Create the repository's GitHub environment named `nexus`.
3. Add environment secret `NEXUSMODS_API_KEY` for the owning Nexus account.
4. Add environment variables `NEXUSMODS_FILE_ID` for the initial uploaded file and `NEXUSMODS_MOD_ID` for the **API Unique Mod ID** from Nexus's Advanced dialog. This is not the number in the public page URL.
5. Set repository variable `NEXUSMODS_ENABLED` to `true` only when that setup is complete. Keep it unset beforehand; GitHub releases still work.

Never commit the key. Environment approval rules can require a review before a
Nexus upload. The official [Nexus upload action](https://github.com/Nexus-Mods/upload-action)
requires an existing mod and file; this workflow does not create the initial page.

## Future Releases

Update `VERSION` and add exactly one matching `## X.Y.Z` section with meaningful
notes in `CHANGELOG.md`. Commit the source, then push that commit and its matching
version tag. For the prepared version:

```powershell
git tag v0.1.3
git push origin main
git push origin v0.1.3
```

Set your GitHub remote before using these commands. Substitute the branch name
if the repository does not use `main`. Never reuse a published tag for changed
source. A mismatched tag, missing notes, or missing ZIP fails before publishing.
Commits alone run validation, not publication: push the matching tag separately.
For Selected branches and tags on the `nexus` environment, add a Branch rule
`main` and a Tag rule `v*`. These rules permit deployment but do not enable Nexus
uploads by themselves; the variables and secret listed above are still required.

`Publish Releases` builds the tagged source and publishes the exact archive as a
GitHub Release asset. Versions below 1.0 are marked prereleases, so link to the
Releases page rather than `/releases/latest` during beta.

When Nexus is enabled, its independent publishing job uploads the same ZIP as a
new file version, supplies only that version's changelog, and updates the mod-page
version. It does not delete or archive old files or automatically change the
primary download. GitHub publishing does not depend on Nexus credentials or approval.

## Dry Runs And Recovery

Run **Actions > Publish Releases > Run workflow** from `main`, leaving `dry_run`
checked, to test and retain a package without publishing anywhere. If the artifact
download adds an outer ZIP, extract it and use the contained mod ZIP.

For a deliberate manual Nexus-only update, uncheck `dry_run` and enter the exact
`VERSION` in `confirm_version`. This still requires Nexus to be enabled. Manual
dispatch never creates a GitHub Release.

GitHub retries verify existing assets and refuse to overwrite a different ZIP.
Nexus uploads are not guaranteed idempotent: after an ambiguous failure, inspect
the Nexus files page before rerunning that job to avoid duplicate uploads.

The repository is prepared locally; no successful live GitHub or Nexus run has
been verified for this mod yet. No credentials, page IDs, or repository remote
are inferred from another mod.
