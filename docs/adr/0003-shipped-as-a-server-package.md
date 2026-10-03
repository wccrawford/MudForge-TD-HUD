# Shipped as a MudForge server package

TextDungeonC can offer the HUD to a MudForge player itself: the server sends GMCP `Client.Package` (an HTTPS `url`, a `version`, a `sha256`) and the client asks the player before installing. `tools/package.js` builds that package from the single built `textdungeon-hud.lua` (ADR 0001): a ZIP `.mfp` holding `package.json` (`formatVersion` 1, `packageId` `com.wccrawford.textdungeon-hud`), `plugins/manifest.json` and `plugins/textdungeon-hud.lua`. The `.mfp` is this repo's whole deliverable: TextDungeonC serves it from its own web listener and builds the advertisement itself, from its own URL and the sha256 of the file it actually serves, so no hash is copied by hand between the repos (`--url` writes a ready-made advertisement for checking it, or for hosting elsewhere). The libs stay inlined rather than shipping as `libs/*.lua`: a package library loses to a same-named file library on the player's machine, and generic names like `status` and `doc` would collide; one file also keeps Ctrl+P → Import working unchanged.

## Consequences

- One version, the plugin block's, is the plugin's, the manifest's and the advertisement's; `tools/package.js` refuses to build when `package.json` disagrees. MudForge re-prompts on every login when the advertised and installed versions differ.
- `packageId` never changes, or every install is orphaned instead of updated.
- The bundle is reproducible (fixed entry order and timestamps), so a release's sha256 can be recomputed from its tag.
- The sha256 changes every release; the server computing it from the file it serves is what keeps the advertisement true. Without a sha256 the player sees an unverified-source warning and must opt in to Lua separately.
- The URL must be HTTPS: MudForge refuses anything else, so the MUD's web listener needs TLS in front of it (or a proxy that provides it).
- MudForge skips a packaged plugin whose id is already installed by hand, so a player who imported `textdungeon-hud.lua` must remove it before the package installs.
- The plugin keeps id `textdungeon-hud` either way, so widget ids, and with them saved placement, carry over.
