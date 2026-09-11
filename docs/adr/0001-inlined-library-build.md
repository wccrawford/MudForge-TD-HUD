# The pure lib is inlined into the plugin by a build step

MudForge's `require()` resolves libraries from a separate app-data `libs/` folder (undocumented path), so shipping `lib/` as real libraries would make every manual install a two-folder job with a red "attempt to call a nil value" when the lib is missing. We keep `lib/*.lua` shaped as genuine libraries — each returns a table, holds no globals, obeys the library-sandbox restrictions, and is `require()`d by name from `src/textdungeon-hud.lua` and from tests — but `tools/build.js` prepends a `__libs` table and a local `require` shim and emits a single `textdungeon-hud.lua`, committed at the repo root, so Ctrl+P → Import of one file is the whole install. Source files are never rewritten, so the same files can be promoted to a real `libs/` folder in a future `.mfp` package without edits.

## Consequences

- The lib never runs in MudForge's library sandbox, only in plugin scope (a superset); the library restrictions are enforced by the luaparse gate and by discipline, not by the runtime.
- The lib reads no clock and no global — `now_ms` is always an argument and there is no `lib.init()` — so every branch is a plain `assert` test under LuaJIT.
- `npm test` fails when the committed build is stale.
