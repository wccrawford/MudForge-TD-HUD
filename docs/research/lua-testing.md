# Lua test harness for the pure `lib/` module

Resolves issue #3 (part of #1). Question: least-friction way to unit-test a
pure Lua 5.1 module on Windows so that it runs under a stock interpreter *and*
loads inside MudForge's luaparse-to-JS runtime; and whether MudForge has a test
runner.

Research date: 2026-09-11. Machine checked: Windows 11, scoop + chocolatey +
winget present, Node 24.19.0 present, **no Lua interpreter of any kind
installed** (`where lua lua5.1 luajit busted luarocks` all miss; `scoop list`
and `winget list --name lua` show nothing). Nothing was installed for this
research except two npm packages (`luaparse`, `fengari`) into a scratch
directory.

## Recommendation

**Plain `assert` scripts, run by LuaJIT, plus a `luaparse` parse gate. Do not
adopt busted (yet).**

| Step | Command (PowerShell, from repo root) | Why |
|------|--------------------------------------|-----|
| Install interpreter | `scoop install luajit` | Single portable `luajit.exe` from the msys2 mingw64 package (scoop main bucket manifest, v2.1.x, `bin: bin\luajit.exe`). LuaJIT is "fully upwards-compatible with Lua 5.1" [S6]. No installer, no admin, no compiler. |
| Run the tests | `luajit tests/run.lua` | Runner is 8 lines of stock Lua (see Minimal example). Non-zero exit on the first failing `assert` because `lua.c` returns `EXIT_FAILURE` on an unprotected error [S5]; `run.lua` calls `os.exit(1)` explicitly so this holds under LuaJIT too. |
| Parse gate (MudForge oracle) | `node tools/parse-gate.js lib/*.lua` (script below) | MudForge parses source with **luaparse** [S1 header, §3]. luaparse's default `luaVersion` is `'5.1'` [S7]. Running the same parser locally rejects exactly what MudForge rejects at load time (verified table in Restrictions checklist). |

Why not the other interpreter options:

- `scoop install lua` is **Lua 5.5.0** and `winget install DEVCOM.Lua` is
  **5.4.6** (queried 2026-09-11). Both accept `goto`, `//`, bitwise ops and
  integer subtype, so a green test run proves nothing about MudForge
  compatibility, and 5.4/5.5 semantics (integer/float split) differ from 5.1.
- Strict PUC Lua 5.1.5 exists only as "Lua for Windows" 5.1.5-52
  (`scoop install lua-for-windows`, `winget install rjpcomputing.luaforwindows`,
  `choco install lua`). It is a 2018-era Inno Setup installer, 32-bit,
  "batteries included" (bundles an old LuaRocks 2.x as `luarocks.bat`). It is
  the most faithful 5.1 oracle but the heaviest install. Use it only if LuaJIT's
  extra permissiveness (below) becomes a problem in practice - the parse gate
  already covers that.
- LuaJIT accepts, by default, some things MudForge and PUC 5.1 reject:
  `goto`/`::labels::`, `\x41` and `\z` string escapes, and a built-in `bit`
  library [S6]. That is why the luaparse gate is part of the recommendation and
  not optional.

Why not busted:

- `luarocks install busted` [S3] pulls in `luasystem`, which is a C module built
  from `src/core.c` etc. (its rockspec `build.type = 'builtin'` with `sources`)
  [S4]. On Windows that means LuaRocks needs a C compiler *and* the Lua
  headers/import library matching the interpreter ("To compile many Lua
  packages, you will also need a C compiler" [S3b]). This machine has no MSVC
  `cl`; it has a 32-bit msys2 gcc and Strawberry Perl's gcc, neither wired to a
  Lua SDK.
- `scoop install luarocks` declares `depends: lua`, i.e. scoop's 5.5.0, and its
  generated `config.lua` pins `lua_version` to that (manifest `pre_install`), so
  busted would run under 5.5, not 5.1.
- busted's value (describe/it, rich asserts, TAP output) is not needed for a
  handful of pure functions. Revisit if the lib grows past a few files.

Optional lint (not evaluated in depth): `scoop install luacheck` (v1.2.0
standalone exe in scoop main) can flag undefined globals; whether it enforces
5.1-only syntax was not verified.

### `tools/parse-gate.js`

```js
// node tools/parse-gate.js lib/*.lua tests/*.lua   -> exit 1 on first parse error
// Requires: npm install --save-dev luaparse   (MudForge's own parser, default luaVersion '5.1')
const fs = require("fs");
const luaparse = require("luaparse");
let bad = 0;
for (const f of process.argv.slice(2)) {
  try { luaparse.parse(fs.readFileSync(f, "utf8"), { luaVersion: "5.1" }); console.log("ok  ", f); }
  catch (e) { bad++; console.error("FAIL", f, "-", e.message); }
}
process.exit(bad ? 1 : 0);
```

Note on the luaparse CLI (`npx luaparse -q -f file.lua`): it works and exits
1 on a parse error, but after reading `-f` files it **also waits on stdin**, so
it hangs in a terminal unless stdin is closed (`< /dev/null` in bash). That is
why a 6-line Node script is recommended over the CLI.

## Minimal example

Layout (repo root):

```
lib/hud_core.lua          <- pure module; copied verbatim to MudForge's libs dir as hud_core.lua
tests/hud_core_test.lua   <- plain asserts
tests/run.lua             <- runner
tools/parse-gate.js       <- above
```

`lib/hud_core.lua` - obeys every restriction in the checklist below. Note the
manual zero-padding: library-scope `string.format` is "basic - no
width/padding/alignment" [S1 §16], so `%02d` cannot be relied on there.

```lua
-- lib/hud_core.lua  (installed into MudForge as libs/hud_core.lua)
-- Pure Lua 5.1. No plugin API, no Lua patterns, no string.format widths.
local M = {}
local _api = {}            -- injected by the consuming plugin (guide s16)

function M.init(apis)      -- plugin calls: hud_core.init({ echo = echo })
  _api = apis or {}
end

-- 0..1 fraction of an effect's remaining time
function M.fraction(remaining, total)
  if total == nil or total <= 0 then return 0 end
  local f = remaining / total
  if f < 0 then return 0 end
  if f > 1 then return 1 end
  return f
end

-- band -> colour; thresholds are fractions
function M.band(f)
  if f > 0.5 then return "green" end
  if f > 0.2 then return "yellow" end
  return "red"
end

-- mm:ss with manual zero-padding (library string.format has no widths)
local function pad2(n)
  if n < 10 then return "0" .. n end
  return "" .. n
end

function M.mmss(seconds)
  if seconds < 0 then seconds = 0 end
  seconds = math.floor(seconds)
  local m = math.floor(seconds / 60)   -- no `//` in 5.1
  local s = seconds - m * 60
  return pad2(m) .. ":" .. pad2(s)
end

return M
```

`tests/hud_core_test.lua`:

```lua
-- run: luajit tests/hud_core_test.lua   (from repo root)
package.path = "lib/?.lua;" .. package.path   -- stock Lua only; MudForge has no package.*
local core = require("hud_core")

local function eq(got, want, label)
  assert(got == want, label .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
end

eq(core.fraction(5, 10), 0.5, "fraction half")
eq(core.fraction(15, 10), 1, "fraction clamps high")
eq(core.fraction(-1, 10), 0, "fraction clamps low")
eq(core.fraction(1, 0), 0, "fraction zero total")
eq(core.band(0.9), "green", "band green")
eq(core.band(0.3), "yellow", "band yellow")
eq(core.band(0.1), "red", "band red")
eq(core.mmss(0), "00:00", "mmss zero")
eq(core.mmss(65), "01:05", "mmss 65")
eq(core.mmss(600), "10:00", "mmss 600")
eq(core.mmss(-3), "00:00", "mmss negative")
eq(core.mmss(59.9), "00:59", "mmss floors")

print("hud_core_test: OK")
```

`tests/run.lua`:

```lua
-- run every listed test file; exit 1 on first failure.
local files = { "hud_core_test" }   -- explicit list: stock Lua has no directory listing
for _, name in ipairs(files) do
  local ok, err = pcall(dofile, "tests/" .. name .. ".lua")
  if not ok then io.stderr:write("FAIL " .. name .. ": " .. tostring(err) .. "\n"); os.exit(1) end
end
print("all tests passed")
```

`tests/*` may freely use `dofile`, `os.exit`, `io.stderr`, `package.path` -
those are blocked *inside MudForge* [S1 §1 rule 4, §3 "Not provided"] but the
test files never ship to MudForge; only `lib/` does.

Verification performed on this example (no Lua interpreter available here):

- All three files pass `luaparse.parse(src, { luaVersion: "5.1" })`
  (luaparse 0.3.1) and a deliberately broken file (`7 // 2`) fails with exit 1.
- The suite was executed under **fengari** (a Lua VM in JS; Lua 5.3 semantics)
  via Node: prints `hud_core_test: OK` / `all tests passed`, exit 0; with one
  expectation altered it prints `FAIL ... mmss 65: expected 01:06, got 01:05`,
  exit 1. Execution under real LuaJIT / PUC 5.1 is **unconfirmed** (nothing
  installed) - see Unconfirmed.

## Restrictions checklist

Everything under `lib/` must satisfy all of these. "Guide" = [S1].

**Syntax (rejected at parse time by MudForge; enforce with the parse gate)**

| Rule | Source | luaparse 5.1 result (verified 0.3.1) |
|------|--------|--------------------------------------|
| No `goto` / `::label::` | Guide header, §1 rule 6, §17, §19 | rejected |
| No integer division `//` | same | rejected |
| No bitwise `& \| ~ << >>` | same | rejected |
| No `_ENV` | same | **accepted** by luaparse (plain identifier in 5.1) - MudForge must reject it elsewhere, or the guide overstates; either way do not use it |
| No `\z` escape, no `\xNN` hex escape | Guide §17 | **accepted** by luaparse 0.3.1 - see Unconfirmed; do not use them |
| No integer subtype (all numbers are doubles) | Guide §17 | n/a |
| `break` only as last statement of a block (5.1 rule) | Lua 5.1 grammar | rejected mid-block |
| Lua 5.1 only otherwise; `function obj:method()` fine | Guide §17 | - |

**Module shape and `require`**

- File is `libs/<name>.lua`; `<name>` must match `^[a-zA-Z0-9_-]+$` and be at
  most 64 chars for top-level `require`; nested `require` inside a library
  skips the length cap but keeps the regex. No paths, extensions or dots
  (`require("a/b")`, `require("a.lua")`, `require("a.b")` are all invalid).
  [Guide §1 rule 7, §16, §19]
- The module is a chunk that builds a local table and `return`s it (template
  in Guide §16). No `module(...)`, no globals.
- Each consuming plugin gets its own independent execution of the library;
  repeated `require` within a plugin returns the same instance; circular
  requires throw. [Guide §16]
- What `require("hud_core")` resolves to:
  - **MudForge web**: `/public/libs/hud_core.lua`, and it must be listed in
    `/public/libs/manifest.json`. **MudForge desktop (Tauri)**: `.lua` files
    are auto-discovered in "the user's libs directory" (location not stated in
    the guide - see Unconfirmed). Package-installed libs (`.mfp` `libs/<name>.lua`)
    also resolve, with file-based libs taking precedence. There is **no
    `package` table** and no `package.path` in MudForge [Guide §3 "Not provided"].
  - **Stock Lua 5.1 / LuaJIT**: `require` searches `package.path`, whose
    default on Windows is `.\?.lua;!\lua\?.lua;!\lua\?\init.lua;!\?.lua;!\?\init.lua`
    where `!` is the executable's directory [S2 luaconf.h]; `LUA_PATH` env var
    overrides it and `;;` expands to the default [S2 manual §5.3]. So from the
    repo root a bare `require("hud_core")` would look for `.\hud_core.lua`, not
    `lib\hud_core.lua` - the test prepends `lib/?.lua;` (or run with
    `$env:LUA_PATH = "lib/?.lua;;"`).
  - Dotted names map to directories in stock Lua, but MudForge forbids dots, so
    never rely on that.

**Sandbox: what the library can and cannot touch** [Guide §1 rule 5, §16 table]

- No plugin API at all: no `send`, `echo`, `print`-to-terminal, `addTrigger`,
  `addTimer`, `createWidget`, drawing, `setVariable`/`saveTable`, GMCP/MSDP,
  session APIs, MUSHclient compat, `io`, `os`, `setTimeout`. Anything needed
  must be injected by the plugin via an explicit `lib.init({ ... })` and used
  guardedly (`if _api.echo then ...`). Library `print` goes to the debug log
  only.
- Blocked everywhere (plugin and library): `debug`, `loadstring`, `load`,
  `dofile`, `loadfile`, `package`. [Guide §1 rule 4, §3]
- Available: `type tostring tonumber pairs ipairs unpack select error assert
  pcall xpcall rawget rawset rawequal rawlen`, `json`, `http`, nested
  `require`, `_G` (the library context itself).
- `unpack` is a top-level global **in library scope** but **not** in plugin
  scope (which has `table.unpack` instead); `table.unpack` is missing in
  library scope. Safest: do not use either in `lib/`.

**Stdlib subsets in library scope (smaller than plugin scope)** [Guide §16]

- `math`: `pi huge abs acos asin atan atan2 ceil cos deg exp floor fmod log
  log10 max min pow rad random randomseed sin sqrt tan`. Missing: `cosh sinh
  tanh frexp ldexp modf`. `math.randomseed` is a no-op.
- `string`: `byte char find format gmatch gsub len lower upper match rep
  reverse sub trim`. Semantics differ from real Lua:
  `find` is **plain-text only** (no Lua patterns); `gmatch`/`gsub`/`match`
  take **JS regex**, not Lua patterns; `gsub` returns a `[result, count]`
  tuple; `format` is "basic - no width/padding/alignment". Therefore the lib
  must not use Lua patterns or `%02d`/`%-5s`-style formats; do any real
  pattern work in the plugin and pass results in.
- `table`: `insert remove sort concat maxn` only. Missing: `getn setn foreach
  foreachi pack unpack`.
- General 5.1 gotchas [Guide §17]: `#t` undefined with holes; `pairs` order
  unspecified; `==` does not coerce (`1 == "1"` is false); strings are
  immutable and not indexable (`s[1]`); `string.format` supports
  `%s %d %i %o %x %X %e %E %f %F %g %G %c %%` only (no `%u %q %b %n`).

Practical rule for the lib: pure arithmetic, table work, `..` concatenation,
`math.floor`, `string.sub`/`rep`/`len`/`byte`/`char`, and plain `string.find`
with the `plain` flag. Anything beyond that is a portability risk between the
three environments (PUC 5.1, LuaJIT, MudForge library sandbox).

## MudForge test runner?

**No.** Evidence:

- The plugin guide [S1] contains no test-runner API. Its only "test" mentions
  are (a) the header's note that a claim is "Verified by
  `tests/unit/integration/single-runtime.test.ts`" - that is MudForge's own
  internal TypeScript suite, not something exposed to plugin authors - and
  (b) a built-in library named `test-utils`, described as "Minimal helpers used
  by the test suite" (§16 table).
- The docs site bundle (`docs.js`, grepped for `test`) has the same single
  entry: `test-utils` - "Minimal test library for verifying the require
  system". No busted, luaunit, "test runner" or "unit test" strings appear in
  `docs.js`, `site.js` or the guide.
- The guide's debugging section (§22) offers only `tprint`, `print`,
  `debugMode = true` console logs and the browser DevTools console.

So testing has to happen outside MudForge, which is exactly why the lib must be
pure and injected via `init`.

## Sources

- [S1] MudForge "AI Plugin & Library Authoring Guide", https://mudforge.org/docs/ai-plugin-guide.md
  (local copy dated 2026-09-11). Cited sections: header, §1 Hard rules, §3
  Runtime environment, §16 `require()` system, §17 Lua 5.1 gotchas, §18.5,
  §19 Common pitfalls, §22 Debugging. Docs site bundle `docs.js` from
  https://mudforge.org/ (Libraries & require() page; Built-in Libraries table).
- [S2] Lua 5.1 Reference Manual, https://www.lua.org/manual/5.1/manual.html -
  §5.3 `require` / `package.path` / `LUA_PATH` (";;" replaced by default path),
  §5.1 `assert`/`error`, §6 stand-alone `lua [options] [script [args]]`.
  `luaconf.h` 5.1, https://www.lua.org/source/5.1/luaconf.h.html - `LUA_PATH_DEFAULT`
  Windows branch and the `!` convention.
- [S3] busted docs, https://lunarmodules.github.io/busted/ - install
  `luarocks install busted`; supports `lua >= 5.1` and `LuaJIT >= 2.0.0`;
  default file pattern `_spec`; `-m/--lpath` default `./src/?.lua;...`;
  `--lua=LUA` interpreter option. `busted-scm-1.rockspec` (GitHub
  lunarmodules/busted) - dependency list incl. `luasystem`, `lua-term`, `penlight`.
- [S3b] LuaRocks Windows install docs,
  https://github.com/luarocks/luarocks/blob/master/docs/installation_instructions_for_windows.md -
  single-binary zip requires an existing Lua; "To compile many Lua packages,
  you will also need a C compiler" (MSVC or MinGW). https://luarocks.org/ quick start.
- [S4] `luasystem-scm-0.rockspec` (GitHub lunarmodules/luasystem) - `build.type
  = 'builtin'` with C `sources`; README: "Supports Unix, Windows, MacOS, Lua >= 5.1 and luajit >= 2.0.0".
- [S5] `lua.c` 5.1, https://www.lua.org/source/5.1/lua.c.html - `return (status
  || s.status) ? EXIT_FAILURE : EXIT_SUCCESS;`.
- [S6] LuaJIT extensions, https://luajit.org/extensions.html - "fully
  upwards-compatible with Lua 5.1"; `goto`, `\x`, `\z` enabled by default;
  built-in `bit` module.
- [S7] luaparse, https://github.com/fstirlitz/luaparse - `luaVersion` option
  `'5.1' | '5.2' | '5.3' | 'LuaJIT'`, default `'5.1'`; CLI flags. Local
  verification with luaparse 0.3.1 (table above).
- Package managers, queried 2026-09-11 without installing: `scoop search lua`
  (`lua` 5.5.0, `luajit` 2.1.x, `lua-for-windows` 5.1.5-52, `luarocks` 3.13.0,
  `luacheck` 1.2.0) and `scoop cat` of those manifests; `winget search lua`
  (`DEVCOM.Lua` 5.4.6, `DEVCOM.LuaJIT` 2.1, `rjpcomputing.luaforwindows`
  5.1.5.52); `choco search --exact` (`Lua` 5.1.5.52, `luarocks` 2.4.4, no luajit).

## Unconfirmed

1. **Nothing was executed under a real LuaJIT or PUC Lua 5.1** on this machine
   (none installed, and the ticket said not to install). The example passed
   luaparse 5.1 and ran green under fengari (Lua 5.3 semantics). First action
   after `scoop install luajit`: `luajit tests/run.lua`.
2. **Which luaparse version/options MudForge actually uses.** The guide says
   `\z` and `\xNN` escapes and `_ENV` are rejected; luaparse 0.3.1 with
   `luaVersion: '5.1'` accepts all three. Either MudForge post-checks these, or
   the guide overstates. Treat them as forbidden regardless.
3. **Desktop libs directory path.** The guide only says Tauri builds
   "auto-discover `.lua` files in the user's libs directory"; the exact folder
   (and whether it is under `~/MudForge/`, like `plugin-files`) is not
   documented in the sources read. Needed for the install/reload step in the
   dev loop (separate ticket).
4. **Number-to-string formatting parity.** MudForge transpiles to JS; whether
   `tostring(x)`/`..` on non-integer doubles matches Lua's `%.14g` (e.g.
   `0.1 + 0.2`) was not verified. The example floors before concatenating to
   sidestep this; keep doing that in `lib/`.
5. **busted on this machine.** Not attempted. Expected blockers (C module
   `luasystem`, no Lua SDK/MSVC, scoop luarocks pinned to Lua 5.5) are inferred
   from manifests and rockspecs, not from a failed install.
6. **luacheck 5.1-syntax enforcement** and the luaparse CLI's stdin behaviour in
   an interactive PowerShell (hang observed under bash without `</dev/null`;
   the tool's own stdin was null here so PowerShell was not a fair test).
