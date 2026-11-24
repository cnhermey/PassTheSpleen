# Pass the Spleen

WoW: Forever addon by cnhermey: when an Undead uses Cannibalize, they yell a
line; other Undead in the party with the addon yell a matching reaction.
Folder, TOC and globals are `PassTheSpleen`. Player's install:
`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\PassTheSpleen\`.
Follow the `wow-forever-addon-dev` skill's conventions.

Lines are in `S.LINES` and reactions in `S.REACTIONS` (same order) in
`Spleen.lua`. Don't start a line with "NAME: " (chat already shows the
speaker). Reactions match the caster's line by text, so a changed line keeps
its old wording in `S.OLD_LINES` for players on older versions.

## Releasing (automatic)

Every update ships as a release, and GitHub builds it, not Claude: sessions
can't create releases or push tags.

1. Bump `## Version: X.Y.Z` in `PassTheSpleen.toc` and the README title
   `# Pass the Spleen (vX.Y.Z)` (patch for fixes, minor for features).
2. Add `## X.Y.Z (YYYY-MM-DD)` at the top of `CHANGELOG.md` with bullets
   written for players. This section becomes the release notes.
3. Commit and push to `main`. `.github/workflows/release.yml` then zips the
   addon as `PassTheSpleen/` and creates release `vX.Y.Z` with
   `PassTheSpleen-vX.Y.Z.zip`. It skips a version that already has a release.
4. Copy the changed files into the player's AddOns folder too, as usual.

After pushing, check the run:
`gh api repos/cnhermey/PassTheSpleen/actions/runs --jq '.workflow_runs[0] | {status, conclusion, html_url}'`
and the release: `gh api repos/cnhermey/PassTheSpleen/releases/latest --jq '{tag_name, html_url}'`.

The same workflow uploads the zip to CurseForge (Forever, game version
1.60.1) once `CF_API_KEY` is a repository secret and PassTheSpleen.toc has
`## X-Curse-Project-ID: <id>`; until then that step skips.

Files that shouldn't be in the zip go in `.gitattributes` as `export-ignore`.
