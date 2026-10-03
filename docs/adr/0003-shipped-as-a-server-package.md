# Shipped as a MudForge server package

TextDungeonC can offer the HUD to a MudForge player itself: the server sends GMCP `Client.Package` (an HTTPS `url`, a `version`, a `sha256`) and the client asks the player before installing. `tools/package.js` builds that package from the single built `textdungeon-hud.lua` (ADR 0001): a ZIP `.mfp` holding `package.json` (`formatVersion` 1, `packageId` `com.wccrawford.textdungeon-hud`), `plugins/manifest.json` and `plugins/textdungeon-hud.lua`, plus `dist/client-package.json`, the advertisement to send. The libs stay inlined rather than shipping as `libs/*.lua`: a package library loses to a same-named file library on the player's machine, and generic names like `status` and `doc` would collide; one file also keeps Ctrl+P → Import working unchanged.

## Consequences

- One version, the plugin block's, is the plugin's, the manifest's and the advertisement's; `tools/package.js` refuses to build when `package.json` disagrees. MudForge re-prompts on every login when the advertised and installed versions differ.
- `packageId` never changes, or every install is orphaned instead of updated.
- The bundle is reproducible (fixed entry order and timestamps), so a release's sha256 can be recomputed from its tag.
- The sha256 changes every release, so the server's advertisement must change with it. Without a sha256 the player sees an unverified-source warning and must opt in to Lua separately.
- MudForge skips a packaged plugin whose id is already installed by hand, so a player who imported `textdungeon-hud.lua` must remove it before the package installs.
- The plugin keeps id `textdungeon-hud` either way, so widget ids, and with them saved placement, carry over.
