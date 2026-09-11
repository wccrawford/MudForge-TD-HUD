# MudForge plugin dev loop and API essentials

Research for issue #2 (part of #1). Verified 2026-09-11 against primary sources only;
every claim carries a source tag defined in [Sources](#sources). Anything not backed by a
primary source is listed under [Unconfirmed](#unconfirmed) rather than guessed.

Client build examined: web client `play.mudvault.org` build **1.2.2384**, which is the same
version string as the latest desktop release `v1.2.2384` (2026-09-10) [GH-REL]. The desktop
app is the same Next.js front end wrapped in Tauri [GH-README], so the front-end code paths
quoted below are what the Windows desktop app runs; only the Rust (Tauri) side is invisible.

---

## Dev loop

### TL;DR

1. **Import once.** `Ctrl+P` → Plugin Manager → *Installed* → **Import** → pick your `.lua`
   file. The browser-style file picker reads the file's *content*; MudForge only remembers the
   file's basename as `sourcePath`, never the directory [APP-IMPORT].
2. **Desktop copies it into its own plugins folder.** On desktop (Tauri) the import handler
   then calls the native `write_plugin_file { pluginName, source }` and logs
   `Wrote "<name>.lua" to plugins folder for hot-reload` [APP-IMPORT]. The exact folder path is
   not exposed in the front end (see Unconfirmed).
3. **Hot-reload watches that copy, not your original.** The desktop back end emits a
   `plugin-file-changed { name, path, source, kind }` event; the front end finds the loaded
   plugin whose `name` equals the file stem (case-insensitive) or whose `sourcePath` ends with
   `<name>.lua`, and if it is enabled, does `unloadPlugin` → `loadPlugin` with the new source
   [APP-HOTRELOAD]. Deletions are ignored, disabled plugins are skipped [APP-HOTRELOAD].
4. **So edit the copy, or re-import.** Use the per-plugin **"Open in external text editor
   (changes hot-reload automatically)"** button (desktop only) — it calls `get_plugin_path`
   (falling back to `write_plugin_file`) and then `open_path`, which reveals where the
   watched copy lives [APP-EXTEDIT]. Alternatively re-run **Import** after each change: an
   import whose `plugin.name` (or filename stem) matches an installed plugin *updates* it in
   place (unload → replace script → reload) instead of creating a duplicate [APP-IMPORT].
5. **Errors and output go to the terminal.** Plugin errors print in red with the Lua line
   number (load, timers, trigger/alias callbacks, widget/event handlers, doAfter, GMCP,
   file I/O); the F12 console gets the full error [HELP-ERRORS]. `print`/`echo`/`utilprint`/
   `tprint` print to the terminal [G§6][G§22]. Library `print()` goes to the debug log only
   [G§16].

### Installing / loading a plugin from a file (desktop, Windows)

- Open the Plugin Manager with `Ctrl+P` [DOCS-PLUGINS][DOCS-SHORTCUTS][HELP-PM].
- Tabs in the current build: **Installed** (enable, disable, configure, edit, remove),
  **Browse** (repositories), **Updates**, **Repositories**, **Editor** ("write a plugin from
  scratch or from a template"), **Settings** [HELP-PM]. The older mudforge.org docs page lists
  the manager as Browse / Install / Configure / **Reload ("Refresh plugin code")**
  [DOCS-PLUGINS]; no button literally titled "Reload" exists in the 1.2.2384 UI strings
  [APP-UI].
- **Import** is a hidden `<input type="file" accept=".lua,.json,.txt">` [APP-UI]. The handler:
  - refuses if no world is open: *"No world yet — connect and name your world (or load a
    world file) before importing plugins. Plugins are saved per world"* [APP-IMPORT];
  - reads the file with `FileReader`; for `.lua`/`.txt` it parses a top-level
    `plugin = { ... }` table with luaparse to get `name`, `version`, `author`,
    `description`; plugin name falls back to the filename minus extension [APP-IMPORT][APP-META];
  - matches an existing plugin by id (if supplied) else by exact `name`; on match it unloads
    (if enabled), replaces `script`, sets `enabled = true`, reloads; otherwise creates a new
    plugin with `id = crypto.randomUUID()` [APP-IMPORT];
  - stores `sourcePath = <file basename>` [APP-IMPORT];
  - on desktop only (`isTauri && !mobile` [APP-ISTAURI]) then calls
    `invoke("write_plugin_file", { pluginName, source })` [APP-IMPORT].
- Per-plugin actions on the Installed tab (from UI strings): enable/disable toggle, **Edit**
  (built-in editor), **Open in external text editor** (desktop only), **Reinstall**
  (`"Reinstall from <sourcePath>"` or `"No source path - select file to reinstall"`),
  **Export as .lua file**, Uninstall [APP-UI].
- Plugins and their state are saved *per world* and travel inside the `.mfw` export
  ("Installed plugins and plugin data") [DOCS-WORLDS]. The storage layout is
  `worlds/<world>/plugins/<id>.lua` plus `plugins/manifest.json` and
  `plugins/<id>.state.json` [APP-STORAGE].

### Can it be pointed at a path and re-read, or must it be re-imported?

- **Pointing at an arbitrary path: no.** Import only ever receives the file *content* and
  basename; the front end never learns or stores the source directory [APP-IMPORT].
- **Reinstall** re-fetches only when `sourcePath` starts with `http://`/`https://`. For a
  local file it logs *"needs file re-selection (local path: …)"* and opens the file picker
  again [APP-REINSTALL]. So Reinstall is effectively "Import again" for local files.
- **Re-read from disk: yes, but only from MudForge's own plugins folder** on desktop, via the
  file watcher described next. Edits to the file you originally imported from (e.g. inside
  this repo) are *not* seen unless that file *is* the copy in the plugins folder.

### How hot-reload works (desktop)

Front-end handler, verbatim behaviour [APP-HOTRELOAD]:

```text
on Tauri event "plugin-file-changed" { name, path, source, kind }:
  log "[hot-reload] Plugin file <kind>: "<name>" at <path>"
  if kind == "removed"        -> ignore
  find loaded plugin p where p.name.toLowerCase() == name.toLowerCase()
                          or p.sourcePath endsWith "<name>.lua"
  if none                     -> log "No loaded plugin matches", ignore
  if not p.enabled            -> log "is disabled, skipping reload"
  else unloadPlugin(p.id); p.script = source; loadPlugin(p)
       emit "plugin-hot-reloaded" | "plugin-hot-reload-failed" { name, error }
```

- The listener is only installed when `isTauri()` is true; on the web it logs
  *"Tauri event API not available for hot-reload"* [APP-HOTRELOAD].
- The plugin's `name` must equal the file stem for the match (the copy is written as
  `<pluginName>.lua` by `write_plugin_file`) [APP-IMPORT][APP-HOTRELOAD]. Keep
  `plugin.name` stable and filesystem-friendly.
- Libraries hot-reload the same way (`library-file-changed`), and every loaded plugin that
  `require()`d that library is unloaded and reloaded [APP-LIBRELOAD]. The in-app help states
  it for libs: *"drop .lua files into the app data libs/ folder. Hot-reload is automatic — save
  the file and the next require() picks it up"* [HELP-LIBS][DOCS-LIBS]. The AI guide also says
  desktop builds *"auto-discover .lua files in the user's libs directory"* [G§16].
- A reload runs the full lifecycle: `onDisable` → `cleanup` then `init` → `onEnable`
  [G§2][DOCS-LIFECYCLE]. Triggers, aliases, timers, widget handlers and `on()` listeners are
  released automatically on unload, so re-registering at top level is safe across reloads
  [G§2][DOCS-EVENTS]. `setVariable` values persist across reloads when
  `settings.saveState` is true (default); `saveTable` always persists [G§9].

### Where errors and output surface

| What | Where | Source |
|---|---|---|
| Lua parse error / load failure | Terminal, red, with Lua line number; F12 console gets the full error | [HELP-ERRORS] |
| Runtime errors in timers, trigger/alias callbacks, widget/event handlers, doAfter, GMCP, file I/O | Same — terminal in red + console; "Always on" | [HELP-ERRORS] |
| Failed plugin in Plugin Manager | Installed row shows an **Error** badge; popover "Plugin failed to load" with `line N  <source line>` (`lastErrorLine`, `lastErrorLineContent`) | [APP-ERRBADGE] |
| `print(msg)` | Terminal, in the user's print color (plain text) | [G§6][DOCS-OUTPUT] |
| `echo(text, color?)` | Terminal; inside a trigger callback it renders in place after the matched line | [G§6][DOCS-OUTPUT] |
| `utilprint(msg)` | Terminal, interprets `$`/`@` color codes | [G§6] |
| `tprint(t)` | Terminal, recursive table dump | [G§22] |
| Library-scope `print()` | Debug log only, not the terminal | [G§16] |
| `io.write(...)` (top-level) | JS console, not the terminal | [G§3] |
| Transpiler errors, `settings.debugMode = true` verbose logs | Browser/F12 console | [G§22] |
| Runaway loop | Script stopped with *"This script ran too long and was stopped"*; limit 1/5/10/30 s in Plugin Manager → Settings → Runaway plugin guard (on by default) | [HELP-SETTINGS] |
| "Enable plugin debugging" | Plugin Manager → Settings; plugin-only verbose logging to the debug log | [HELP-SETTINGS] |
| Session log | Settings → Logging (level debug/info/warn/error, auto-download) | [DOCS-SETTINGS] |

Lua 5.1 source is parsed by `luaparse` and transpiled to JS at load time; there is no Lua
VM. 5.2+ syntax (`goto`, `//`, bitwise ops, `_ENV`) is rejected at parse time [G-HEAD][G§17].
Unknown globals compile to `_G.<name>` and surface as *"attempt to call a nil value"* [G§21].

### Web client vs desktop

| Concern | Desktop (Tauri, Windows) | Web (play.mudvault.org) | Source |
|---|---|---|---|
| Import from file | Yes (browser-style picker, content only) | Same | [APP-IMPORT] |
| Copy written to app plugins folder | Yes (`write_plugin_file`) | No (`isTauri` gate) | [APP-IMPORT] |
| Hot-reload on file save | Yes, for the copy in the plugins folder | No listener | [APP-HOTRELOAD] |
| "Open in external text editor" | Shown | Hidden | [APP-EXTEDIT] |
| Libraries from a folder | app data `libs/` folder, hot-reload | Bundled + repository installs only | [HELP-LIBS][DOCS-LIBS] |
| Themes from a folder | `{appDataDir}/themes/` | Bundled only | [G§4] |
| Real filesystem `io.*` | Opt-in per plugin (File System Access permission), home-folder scope | Not available | [G§3] |
| HTTP | Direct | Server-side proxy; loopback/private ranges blocked | [G§13] |
| Plugin/variable persistence | Storage engine = real files | IndexedDB (localStorage fallback) | [G§9] |
| Error/print surfacing | Terminal + console (same front end) | Same | [HELP-ERRORS] |

### Proposed README section

```markdown
## Developing the plugin (desktop MudForge, Windows)

MudForge (v1.2.2384+) loads plugins from the Plugin Manager (`Ctrl+P`).

**First install**
1. Connect to (or load) a world first — plugins are saved per world and the
   importer refuses to run without one.
2. `Ctrl+P` → *Installed* → **Import** → choose `textdungeon-hud.lua`.
   The plugin is identified by the `name` in its `plugin = { ... }` table;
   re-importing a file with the same name updates the installed plugin in place.

**Edit / reload loop**
- On desktop, Import also writes a copy named `<plugin.name>.lua` into
  MudForge's own plugins folder and watches it. Saving that copy hot-reloads
  the plugin (unload → reload; `init()` runs again) with no clicking.
- To find that copy, use the plugin's **"Open in external text editor"**
  button in *Installed* — it opens the watched file in your default editor.
  Either edit there and copy back into the repo when done, or keep editing the
  repo file and press **Import** again after each change (Reinstall for a
  local file just reopens the picker).
- Keep `plugin.name` stable and filesystem-safe: the hot-reload match is
  `plugin.name == file stem` (case-insensitive).

**Seeing what happened**
- Parse and runtime errors print to the terminal in red with the Lua line
  number; the failing plugin also shows an **Error** badge with the line in
  *Installed*. Press `F12` for the full stack.
- `print()`, `echo()`, `utilprint()`, `tprint()` all print to the terminal.
- Plugin Manager → *Settings*: "Enable plugin debugging" for verbose logs;
  "Runaway plugin guard" (on by default) stops infinite loops after the limit
  you pick (1, 5, 10 or 30 s) with "This script ran too long and was stopped".

**Web client (play.mudvault.org)**: Import works the same, but there is no
plugins folder and no hot-reload — re-Import after every change.
```

---

## API essentials

Lua 5.1 syntax, transpiled to JS by luaparse at load; one runtime (`NextGenPluginRuntime`);
`engineType` is ignored [G-HEAD][G§1].

### Plugin shape and lifecycle

```lua
plugin = {                     -- plain global table, no `local`, no `return plugin`
  id = "textdungeon-hud", name = "TextDungeon HUD", version = "0.1.0",
  author = "…", description = "…",
  settings = { saveState = true },   -- debugMode = true for verbose logs
}
function init() … end          -- on load/enable; deferred until first widget canvas is ready (or 2 s)
function onEnable() … end      -- right after init and on re-enable
function onConnect(sessionId) … end
function onDisconnect(sessionId) … end
function onLine(sessionId, rawLine, cleanLine) … end   -- return false to discard the line
function onCommand(sessionId, command) … end          -- return false to discard (before aliases)
function onSend(sessionId, text) … end                -- return false to block
function onSaveState(sessionId) … end                 -- before world save (Ctrl+Alt+S / autosave)
function onDisable() … end     -- on unload, before cleanup
function cleanup() … end       -- triggers/aliases/timers/widget handlers/on() listeners auto-released
```

Sources: [G§0][G§2][DOCS-LIFECYCLE]. MUSHclient aliases (`OnPluginInstall`, `OnPluginConnect`,
…) and camelCase `onPlugin*` are accepted for every hook [G§2].

Metadata parsing on import uses only a top-level `plugin = { … }` assignment with string
literal values [APP-META].

### Widgets — `createWidget(config) → widgetId`

| Field | Notes | Source |
|---|---|---|
| `type` | `"canvas"` (default) / `"html"` / `"enhanced-text"`; alias `renderMode` | [G§4] |
| `name` (or `title`) | Widget id is derived from `pluginId + name`; `name` defaults to `"widget"`, so **two widgets without distinct names collapse into one** (second call returns the first id). `title` is the chrome title, falls back to `name`. | [G§4][DOCS-WIDGETS] |
| `position = {x=, y=}` | **Only** way to place it; top-level `x`/`y` are ignored. Default `{200,150}` — widgets without positions stack. User's saved placement in the world file overrides `config.position` on later loads. | [G§4][G§21] |
| `size = {width=, height=}` | Default 400×300; top-level `width`/`height` used only if `size` absent | [G§4] |
| `visible`, `resizable`, `movable` | booleans, default true | [G§4][DOCS-WIDGETS] |
| `zIndex` | capped at 49 at creation | [G§4] |
| `scrollable` | for html / enhanced-text | [G§4] |
| `template` | html type, default `"<div>{{content}}</div>"` | [G§4] |
| `content` | html markup at creation ("or the content property at creation") | [HELP-PLUGINS] |
| `transparent = true` | no frame fill / backdrop blur | [G§4][DOCS-WIDGETS] |
| `appearance = { … }` | plugin-default appearance fields (same keys as `setWidgetAppearance`, fonts excluded) | [G§4] |
| `properties = { … }` | custom props for `getWidgetProperty` | [G§4] |

Control: `showWidget(id, force?)`, `hideWidget(id, force?)` (pass `force=true` for
user-initiated toggles; otherwise a widget the user hid in the Plugin Manager stays hidden),
`destroyWidget`, `moveWidget(id,x,y)`, `resizeWidget(id,w,h)`, `setWidgetZOrder` (0–49),
`getWindowSize() → {width,height}` + `on("windowResize", fn)` (debounced ~150 ms)
[G§4][DOCS-WIDGETS].

`setWidgetProperty(id, prop, value)` — documented props: `"title"`, `"x"`, `"y"`, `"width"`,
`"height"`, and **`"content"`** (html markup for html widgets). `getWidgetProperty(id, prop)`
also reads `"visible"` [DOCS-WIDGETS]. A `"content"` rewrite replaces the whole iframe
document and kills any `setInterval`/`setTimeout`/`requestAnimationFrame` the widget's own JS
started [HELP-PLUGINS].

`widgetInfo(id, n)`: the AI guide and the Widgets API page publish **different** tables for
n=1..21 (guide: 1/2 original x/y, 3/4 current w/h, 7 visible, 15/16 current x/y, 18 owning
plugin, 20 id, 21 canvas ready; API page: 1/2 x/y, 3/4 w/h, 7 visible, 9 title, 15 z-order).
Treat only the overlap (1–4, 7) as reliable [G§4][DOCS-WIDGETS].

### HTML widget events

`registerWidgetEvent(id, event, cb)`; `cb` receives ONE table [DOCS-WIDGETS]. Events:
`click`, `doubleclick`, `action`, `mousedown`, `mouseup`, `mousemove`, `keydown`, `keyup`,
`submit`, `resize`, `move`, `close`, plus `menuselect`/`menuclose` for host context menus
[DOCS-WIDGETS] (the AI guide lists only click/mousedown/mouseup/mousemove/resize/move [G§4]).
Click/key events carry `targetId`, `targetTag`, `targetText`, `targetValue`, `targetName`,
`dataset` (camelCased `data-*`); `mousemove` carries only `x`/`y` [DOCS-WIDGETS].
`data-mud-action="…"` (+ optional `data-mud-data`) on any element fires an `action` event
with `e.action`, `e.data`, `e.dataset`, `e.targetId`; the same fields also ride on `click`
[DOCS-WIDGETS]. `unregisterWidgetEvent(id, event, cb?)` [G§4].

### Reactive binding (no rebuild, no widget JS)

Markup [HELP-PLUGINS][DOCS-WIDGETS]:

```html
<span data-mud-bind="hp">?</span>                       <!-- textContent, never HTML -->
<div  data-mud-bind-style="width:hpPct; opacity:fade"></div>  <!-- style props -->
<div  data-mud-bind-attr="title:tip; value:txt"></div>   <!-- attributes; safe src/href ok -->
```

Blocked on bound values: script/navigation sinks (`onclick`, `srcdoc`) and `javascript:`/
`file:` URLs [HELP-PLUGINS].

Feeding keys [DOCS-WIDGETS][HELP-PLUGINS]:

```lua
setBoundValue(id, key, value)            -- nil → "", numbers/bools via tostring
setBoundValues(id, { k1 = v1, k2 = v2 }) -- one DOM pass
bindWidgetVariable(id, key, varName [, scope])  -- follows setVariable(varName, …); pushes current value at bind time; unbindWidget(id) to stop
bindWidgetGMCP(id, key, package [, path])       -- e.g. ("hp", "Char.Vitals", "hp"); pushes at bind time and on every update
```

All three feed the same keys and can be mixed; values persist, so a later `"content"`
rewrite re-hydrates bindings automatically; bindings are torn down on plugin unload
[DOCS-WIDGETS][HELP-PLUGINS]. Alternative push path: `sendWidgetMessage(id, table)` delivered
to `window.mudforge.onMessage(fn)` inside the widget [DOCS-WIDGETS].

Canonical HUD example (verbatim from the docs) [DOCS-PLUGINS][HELP-PLUGINS]:

```lua
local hud = createWidget({ type = "html", title = "Vitals" })
setWidgetProperty(hud, "content", [[
  <style>.bar{height:10px;background:#222;border-radius:5px}
         .fill{height:100%;border-radius:5px;transition:width .2s ease}</style>
  HP <span data-mud-bind="hp">?</span>/<span data-mud-bind="maxhp">?</span>
  <div class="bar"><div class="fill" style="background:#c0392b"
       data-mud-bind-style="width:hpPct" data-mud-bind-attr="title:hpTip"></div></div>
  MP <span data-mud-bind="mp">?</span>
]])
bindWidgetGMCP(hud, "hp",    "Char.Vitals", "hp")
bindWidgetGMCP(hud, "maxhp", "Char.Vitals", "maxhp")
bindWidgetVariable(hud, "mp", "mana")
onGMCPUpdate("Char.Vitals", function(v)
  local pct = math.floor(v.hp / v.maxhp * 100)
  setBoundValues(hud, { hpPct = pct .. "%", hpTip = v.hp .. "/" .. v.maxhp })
end)
```

### Appearance — `setWidgetAppearance(id, settings)`

Flat table; omitted fields unchanged; `nil` clears an appearance field to theme default
[G§4]. Fields: `showTitleBar`, `autoHideSettingsCog`, `movable`, `resizable`, `fontFamily`
(bundled key e.g. `"fira-code"` or `"system:<name>"`), `fontSize` (6–96), `fontWeight`,
`zIndex` (0–9999), `titleTextColor`, `titleBackgroundColor`, `titleGradient`,
`backgroundColor`, `backgroundGradient`, `backgroundOpacity` (0–1, fill only),
`backgroundImageSize`, `borderColor`, `borderWidth` (0–32), `borderRadius` (0–64),
`borderStyle`, `borderShadow`, `borderGradient`, `borderAnimation`
(`pulse|rotate|rainbow|marching-ants|none`), `borderImagePreset`
(`neon-glow|steel-bevel|ornate-gold|pixel-frame`) [G§4]. Background *images* and custom
border images are settings-UI only [G§4][DOCS-SETTINGS]. From inside the widget:
`window.mudforge.setAppearance({...})` / `setBorder({...})` or a
`<meta name="mudforge-appearance">` tag [HELP-PLUGINS].

### GMCP

```lua
getGMCPData(pkg?) → table|nil        -- e.g. getGMCPData("Char.Vitals"); no arg = all packages
onGMCPUpdate(pkg, function(data) … end)   -- current session only
onGMCPUpdateGlobal(pkg, function(data, sessionId) … end)
sendGMCP(pkg, data?) → boolean       -- table is JSON-encoded; needs desktop or bridge connection
getCurrentRoom(), getAllGMCPData(), getGMCPDataFromSession(sid, pkg?)  -- legacy but callable
```

[G§11][DOCS-GMCP]. MSDP: `getMSDPVariable`, `getAllMSDPVariables`, `onMSDPChange(name, cb)`,
`onMSDPChangeGlobal` [G§11].

### Timers

```lua
addTimer(intervalMs, callback, repeating?) → timerId   -- repeating default false
removeTimer(timerId)
setTimeout(fn, ms) / clearTimeout(id)   -- available, but prefer addTimer (engine tracks + cleans up)
getCurrentTime() → ms
```

Rate limits per plugin: burst 100, sustained 30/s, hard ceiling 500 live timers;
`addTimer` returns `""` when a limit is hit. Firing rate is not capped (16 ms loops are fine)
[G§8][DOCS-TIMERS]. **Timers do not run while disconnected** — `addTimer` returns `""` and
warns in the terminal when called disconnected [G§8]. Use one repeating timer instead of one
per line/frame [G§8]. MUSHclient `DoAfter(seconds, cmd)`, `DoAfterSpecial`, `EnableTimer`
exist [DOCS-TIMERS].

### Events, MUD I/O, triggers (brief)

- `on(event, cb)`, `emit(event, data?)` (sync, all plugins incl. self), `off()`; built-ins
  `connected`, `disconnected`, `line {text, clean, sessionId}`, `windowResize` [G§14][DOCS-EVENTS].
- `send(cmd)`, `echo(text, color?)`, `print`, `utilprint` (`$R`, `$x214`, `$Xff8800` codes),
  `tprint`, `hyperlink` [G§6].
- `addTrigger(pattern, cb, isRegexBool | {type="regex", oneShot=, priority=, group=})`;
  default is **substring** (wildcard if `*`/`?`), regex is **JavaScript** regex; callback
  `(captures, line, wildcards, rawLine)` [G§1][G§7]. `addAlias(jsRegex, "", function(matches) …)`
  [G§20]. `registerCommand(name, handler(argsString), description?)` [G§15].
- Persistence: `setVariable`/`getVariable` (strings only), `saveTable`/`loadTable` for
  structured data; optional `"global"` scope [G§9].

### `require()` and library sandbox

- `require("name")`: flat names only, `^[a-zA-Z0-9_-]+$`, ≤ 64 chars; each plugin gets its
  own instance; repeated requires cached; circular → error [G§1][G§16].
- Library scope has **no** plugin API (no `send`/`echo`/`addTrigger`/`createWidget`/drawing/
  timers/GMCP/variables/`io`/`os`/`setTimeout`); inject via `lib.init({ echo = echo, … })`
  [G§1][G§16]. Smaller stdlib in libraries: `string.find` plain-only, `string.gmatch/gsub/
  match` use **JS regex**, `gsub` returns a tuple, `string.trim` added; `table.unpack`
  missing (use `unpack`); `math` lacks `cosh/sinh/tanh/frexp/ldexp/modf` [G§16].
- Library `print()` → debug log only [G§16]. Optional `library = { name=, version=, … }`
  header table for listing [HELP-LIBS].

### Lua 5.1 / transpile gotchas

- No `goto`, `//`, bitwise `& | ~ << >>`, `_ENV`, `\z`, `\xNN`, integer subtype [G§17].
- `unpack` is not a plugin-scope global — use `table.unpack` [G§3]. `math.randomseed` is a
  no-op [G§3]. `string.format` lacks `%u %q %b %n` [G§17].
- `#t` undefined with holes; `ipairs` stops at first nil; `pairs` order unspecified;
  `1 == "1"` is false [G§17].
- Blocked: `debug`, `loadstring`, `load`, `dofile`, `loadfile`, `package` [G§3]. `io`/`os`
  are restricted stubs (pseudo-files via the storage engine unless the desktop File System
  Access permission is on) [G§3].
- Lua-pattern → regex converter does not recurse into `[…]` classes (`[%d%a]` fails) [G§21].
- Older builds failed with *"identifier has already been declared"* for a top-level `local`
  named after a client function; current builds load it, but a top-level `local` still
  shadows that client function for the rest of the plugin [HELP-DECLARED].

---

## Sources

All fetched 2026-09-11. Local copies live in the session scratchpad (not committed).

| Tag | Source |
|---|---|
| G-HEAD, G§n | `https://mudforge.org/docs/ai-plugin-guide.md` (needs a browser User-Agent), header and section *n* (§22 "Debugging your plugin", §15 `registerCommand`, §16 `require()`, §17 gotchas) |
| DOCS-PLUGINS | `https://mudforge.org/#/docs/plugins`, rendered from `https://mudforge.org/assets/DocsPage-Chi8NU6v.js`, function `cd()` ("Plugin System" / "Plugin Manager" / "Reactive Data Binding") |
| DOCS-WIDGETS | same bundle, `Nd()` — "Widget Functions" API page (`createWidget`, `setWidgetProperty`, `registerWidgetEvent`, `data-mud-action`, `sendWidgetMessage`, `setBoundValue(s)`, `bindWidgetVariable`, `bindWidgetGMCP`, `unbindWidget`, `widgetInfo`) |
| DOCS-TIMERS / DOCS-GMCP / DOCS-OUTPUT / DOCS-LIFECYCLE / DOCS-EVENTS | same bundle, `kd()` Timer Functions, `Cd()` GMCP/MSDP Functions, `yd()` Output Functions, `Rd()` Plugin Communication incl. "Named Lifecycle Callbacks" and "Event System" |
| DOCS-LIBS / DOCS-WORLDS / DOCS-SETTINGS / DOCS-SHORTCUTS | same bundle, `dd()` Libraries ("Installing Libraries — Desktop (Tauri): drop .lua files into your app data libs/ folder. Hot-reload is automatic."), `ld()` World Files, `od()` Settings (Logging), `ud()` Keyboard Shortcuts (`Ctrl+P` Open Plugin Manager) |
| HELP-PM, HELP-PLUGINS, HELP-SETTINGS, HELP-LIBS, HELP-ERRORS, HELP-DECLARED | In-app help pages compiled into the web client bundle `https://play.mudvault.org/_next/static/chunks/4639.a03e38d038123b4e.js` (build 1.2.2384): Plugins page ("Plugin Manager — Open with Ctrl+P: Installed / Browse / Updates / Repositories / Editor / Settings", "Plugin Settings", HTML widget and Reactive Data Binding sections), Libraries page, and the help search-index entries `Plugin Errors & Debugging` (verbatim: "Plugin errors print to the terminal automatically in red with the Lua line number — covering top-level load, timers, trigger/alias callbacks & scripts, widget & event handlers, doAfter, GMCP, and file I/O. Always on; F12 console also gets the full error.") and `already been declared` |
| APP-UI, APP-EXTEDIT, APP-ERRBADGE | same chunk, Plugin Manager component: `<input type="file" accept=".lua,.json,.txt">`; button titles `"Open in external text editor (changes hot-reload automatically)"` (rendered only when the desktop check passes; handler invokes Tauri `get_plugin_path` → `write_plugin_file` fallback → `open_path`), `"Reinstall from <sourcePath>"` / `"No source path - select file to reinstall"`, `"Export as .lua file"`; Error badge popover "Plugin failed to load" with `lastErrorLine` / `lastErrorLineContent` |
| APP-IMPORT, APP-REINSTALL, APP-HOTRELOAD, APP-LIBRELOAD, APP-STORAGE, APP-ISTAURI, APP-META | `https://play.mudvault.org/_next/static/chunks/5980-2f10df9f7276a845.js` (build 1.2.2384): plugin import handler (`=== IMPORT PLUGIN START ===`, `sourcePath: "<fileName>"`, `[LUA BRANCH]`, `write_plugin_file` → `Wrote "<name>.lua" to plugins folder for hot-reload`); reinstall (`needsFileSelect`, "needs file re-selection (local path: …)"); Tauri `listen("plugin-file-changed", …)` handler (`[hot-reload] …` log lines, `plugin-hot-reloaded` / `plugin-hot-reload-failed` events); `listen("library-file-changed", …)`; storage paths `worlds/<world>/plugins/*.lua`, `plugins/manifest.json`, `plugins/<id>.state.json`; desktop check = `isTauri && !(iPhone|iPad|iPod|Android)`; metadata parser walks the luaparse AST for a top-level `plugin = { … }` assignment |
| GH-README, GH-REL | `https://github.com/Coffee-Nerd/MudForge` README ("This is the public home of MudForge — downloads, release notes, and issue tracking. The app source is maintained privately"; "Lua plugin system with a built-in editor, live syntax checking"; "MudForge is built with Next.js + Tauri") and `gh release view v1.2.2384` (2026-09-10; Windows assets `MudForge_1.2.2384_x64-setup.exe` / `.msi`). Issue search for "plugin", "reload", "load from file": only one issue exists in the repo (#1, unrelated GPU launch bug). Related repos `Coffee-Nerd/MudForge-Plugins` (README only) and `Coffee-Nerd/mudforge-docs` (older Nextra docs, last push 2026-01-26, no Plugin Manager install docs) were checked and add nothing on the dev loop. |

Note on precedence: the mudforge.org docs bundle and the in-app help disagree on the Plugin
Manager tab list (Browse/Install/Configure/Reload vs Installed/Browse/Updates/Repositories/
Editor/Settings). The in-app help ships inside the 1.2.2384 client, so it is treated as
current.

---

## Unconfirmed

Could not be confirmed from a primary source; verify on a real Windows install before
relying on it.

1. **Exact path of the desktop plugins folder.** The front end only calls Tauri
   `write_plugin_file` / `get_plugin_path`; the Rust side is closed source. The AI guide says
   the themes folder `{appDataDir}/themes/` "mirrors `libs`/`plugins`" [G§4], and the libs
   folder is described as "your app data `libs/` folder" [HELP-LIBS], which *suggests*
   `{appDataDir}/plugins/` (on Windows Tauri's appDataDir is typically
   `%APPDATA%\<bundle-id>\`), but neither the folder name nor the bundle id is documented.
   Use the "Open in external text editor" button to discover it.
2. **Filename sanitization of the watched copy.** `write_plugin_file` receives
   `pluginName` (the `plugin.name`, e.g. with spaces); whether the Rust side writes
   `"TextDungeon HUD.lua"` verbatim or slugifies it is unknown. The hot-reload match compares
   the event's `name` to `plugin.name` case-insensitively, so a sanitized filename could break
   matching. Safest: use a name that is already filesystem-safe (e.g. `textdungeon-hud`).
3. **Whether symlinks/junctions in the plugins folder are followed** by the file watcher.
   Not documented anywhere.
4. **Whether a hot-reload shows a toast/terminal notice.** The front end emits
   `plugin-hot-reloaded` / `plugin-hot-reload-failed` on the internal event bus and writes
   `[hot-reload] …` lines to the plugin debug log; no UI consumer of those events was found in
   the bundle, so a successful reload may be silent apart from your own `print` in `init()`.
5. **Whether the built-in Editor's "Save Plugin" reloads a running plugin.** The editor
   toasts `Plugin "<name>" saved successfully!` and hands the record to the manager; the
   reload path after that was not traced.
6. **Whether the desktop app has a native (Tauri) file dialog for Import** that would give a
   real path. The Import handler seen uses a DOM `<input type="file">` even on desktop, so
   `sourcePath` is a basename; but a separate desktop-only path could exist in code not
   examined.
7. **The "Reload: Refresh plugin code" item on mudforge.org's Plugin Manager list.** No
   matching button title exists in the 1.2.2384 UI strings; it may be the enable/disable
   toggle, the Reinstall button, or stale documentation.
8. **`widgetInfo` numbering** — the two official sources disagree (see API essentials).
9. **Behaviour of `plugin.id` on hot-reload.** Import assigns `crypto.randomUUID()` as the
   stored plugin id and hot-reload preserves the existing record, but whether the `id` in the
   Lua `plugin` table is used for anything beyond `getPluginId()` display was not verified.
