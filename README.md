# TextDungeon HUD

A [MudForge](https://mudforge.org) plugin that renders TextDungeonC's always-visible character state — **Status**, **Effects**, **Slots** — as three `html` widgets fed only by the server's GMCP Feed.

## Install

Ctrl+P in MudForge → **Import** → pick `textdungeon-hud.lua` from the repo root. One file; nothing else to copy.

## Develop

```
scoop install luajit      # once; the test interpreter (Lua 5.1-compatible)
npm install               # once; luaparse, the parser MudForge itself uses
npm test                  # parse gate + LuaJIT asserts + stale-build check
npm run build             # src/ + lib/ -> textdungeon-hud.lua (commit it)
npm run deploy            # build, then copy into MudForge's watched plugins folder
```

`src/textdungeon-hud.lua` is the plugin; `lib/*.lua` are pure libraries it `require()`s; `src/widgets/*.html` (+ `shared.css`) are each widget's content. `tools/build.js` inlines all of it into the root `textdungeon-hud.lua` — edit the sources, never the built file (see `docs/adr/0001-inlined-library-build.md`).

`npm run deploy` copies the build into `%APPDATA%\com.mudforge.app\plugins\` (override with `MUDFORGE_PLUGINS_DIR` or `--install <dir>`). Desktop MudForge watches that folder and hot-reloads the plugin once it has been imported once.
