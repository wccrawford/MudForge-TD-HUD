# TextDungeon HUD

A [MudForge](https://mudforge.org) plugin that renders TextDungeonC's always-visible character state — **Status**, **Effects**, **Slots** — plus the last page read (**Page**) and quest pulled up (**Quest**), each with a list of recent ones, and a **Windows** bar that reopens any of them, as `html` widgets fed only by the server's GMCP Feed.

## Install

**Offered by the server:** when TextDungeonC advertises the package (GMCP `Client.Package`), MudForge asks whether to install it; accept and it installs and updates itself. A copy imported by hand (below) must be removed first, or MudForge skips the packaged plugin.

**By hand:** Ctrl+P in MudForge → **Import** → pick `textdungeon-hud.lua` from the repo root. One file; nothing else to copy.

**From a package file:** Settings → Packages → **Import Package** → pick `dist/textdungeon-hud-<version>.mfp`. It goes through the same consent prompt and install path as a server-offered package, without hosting; with no advertised sha256 it is marked unverified and asks separately before installing Lua.

## Develop

```
scoop install luajit      # once; the test interpreter (Lua 5.1-compatible)
npm install               # once; luaparse, the parser MudForge itself uses
npm test                  # parse gate + LuaJIT asserts + stale-build check
npm run build             # src/ + lib/ -> textdungeon-hud.lua (commit it)
npm run deploy            # build, then copy into MudForge's watched plugins folder
npm run package           # build, then dist/<id>-<version>.mfp + dist/client-package.json
```

`src/textdungeon-hud.lua` is the plugin; `lib/*.lua` are pure libraries it `require()`s; `src/widgets/*.html` (+ `shared.css`) are each widget's content. `tools/build.js` inlines all of it into the root `textdungeon-hud.lua` — edit the sources, never the built file (see `docs/adr/0001-inlined-library-build.md`).

`npm run deploy` copies the build into `%APPDATA%\com.mudforge.app\plugins\` (override with `MUDFORGE_PLUGINS_DIR` or `--install <dir>`). Desktop MudForge watches that folder and hot-reloads the plugin once it has been imported once.

## Release

The version lives in the `plugin = { ... }` block of `src/textdungeon-hud.lua` and in `package.json`; bump both together (`npm run package` refuses a mismatch).

```
npm test && npm run package
git tag v<version> && git push origin v<version>
gh release create v<version> dist/textdungeon-hud-<version>.mfp
```

`dist/client-package.json` is then the GMCP `Client.Package` payload for TextDungeonC to send at login. Its `url` defaults to that release asset (`--url` on `tools/package.js` overrides it), and its `sha256` changes with every release, so the server's copy must be updated each time. See `docs/adr/0003-shipped-as-a-server-package.md`.
