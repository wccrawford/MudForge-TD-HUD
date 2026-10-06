# What can a MudForge html widget draw?

Research for issue #18. Verified 2026-10-06 against primary sources: the shipped web client
bundle and the in-app docs and AI plugin guide that ship with that same build. Each claim
carries a source tag defined under [Sources](#sources). Anything that reading can't settle is
listed under [Probes](#probes-for-the-desktop-client), with what to check in the client.

Build examined: **web client 2.0.3224** (`https://play.mudvault.org/version.json` →
`{"version": "2.0.3224", "buildTime": "2026-10-06T09:46:53Z"}`). The installed desktop app
(`%LOCALAPPDATA%\MudForge\mudforge.exe`, file dated 2026-09-22) embeds its **own, older**
front-end bundle. Its chunk hashes differ from the web build's (for example
`main-app-f86b9b2a3eca48dd.js` against the web build's `main-app-481fa89a0e3a572b.js`), and
its assets are compressed inside the exe, so they can't be read here. Update the desktop app
before you probe, and treat any difference from this note as version drift.

---

## TL;DR

An html widget's `content` is **not sanitized at all**. MudForge writes it verbatim into a
same-origin iframe with `document.open(); document.write(content); document.close()`. The
iframe's sandbox is `allow-scripts allow-same-origin allow-forms allow-modals allow-popups`
[HW-COMP][HW-SETPROP]. So inline SVG, `<style>`, `<script>`, `<canvas>` and inline `on*`
handlers all reach the browser as written. The docs say so outright: *"Render HTML / CSS / JS
in a sandboxed iframe"*, and *"Widget JavaScript runs with the client's own access"*
[DOCS-OVERVIEW].

So the Map window does not need to rewrite content on every step. It has three ways to move
markers, from least to most code:

1. **Bound values.** `data-mud-bind-style` calls `el.style.setProperty(prop, value)` for
   *any* CSS property except `cssText`/`behavior`, so `transform`, `left`, `top` and custom
   properties all work. `data-mud-bind-attr` calls `el.setAttribute(name, value)` for any
   attribute except `on*`, `data-mud-*`, `srcdoc`, `style` and `xmlns`, so SVG `cx`, `x`,
   `transform`, `points`, `d` and `class` all work [HW-BIND].
2. **`sendWidgetMessage` or a custom `setWidgetProperty`** into the widget's own `<script>`,
   received with `mudforge.onMessage` / `mudforge.onProperty`. The script then does whatever
   it likes to the DOM: SVG, canvas, or class flips [DOCS-MF][HW-COMP].
3. **A `type = "canvas"` widget, or `createMapperWidget()`**, if the html route turns out
   wrong. Both are first-class widget types next to `html` [RT-TYPES][DOCS-MAPPER].

On size: a user resize of an **html** widget does **not** fire the Lua `resize` event; only
canvas widgets dispatch it. Inside the iframe, the widget's own `window` gets an ordinary
`resize` event, so a `viewBox` SVG at `width:100%;height:100%` scales by itself
[GUIDE-DOCK][HW-RESIZE].

---

## The bullets in #18

### 1. Does inline SVG in `content` render, and does its `viewBox` scale to the widget?

- **Renders: yes, by reading.** No sanitizer sits between Lua and the DOM.
  `setWidgetProperty(id, "content", v)` stores `v` and dispatches
  `plugin-widget-property-change` with the value unchanged [HW-SETPROP]. The html widget
  component sets its React state to it and writes it with `s.open(); s.write(p); s.close()`
  into the iframe's document [HW-COMP]. The only DOMPurify call in the bundle belongs to an
  unrelated internal "universal widget" class (`renderHTML()` → `M.A.sanitize(e)`), not the
  plugin html widget [RT-UNIVERSAL].
- **Scales: yes, as plain browser layout.** The iframe is `className:"h-full w-full border-0"`
  inside an `h-full w-full` div, so it fills the widget body [HW-COMP]. An `<svg viewBox="…"
  width="100%" height="100%" preserveAspectRatio="xMidYMid meet">` with
  `html,body{margin:0;height:100%}` therefore tracks the widget's size without any event.
  (Nothing about SVG is special-cased; this is standard browser behaviour inside a
  full-size iframe.)
- One thing MudForge injects: unless the content mentions `scrollbar` anywhere, it adds a
  `<style id="mudforge-scrollbars">` as the first child of `<head>` to theme scrollbars
  [HW-COMP][DOCS-SETPROP]. That is harmless for an SVG that fits without scrolling.
- *Probe:* P1 (render and scale, desktop WebView2).

### 2. Can bound values reach SVG attributes, or CSS `transform` and `left`/`top`?

**Yes, both, by reading.** The binder walks
`querySelectorAll("[data-mud-bind],[data-mud-bind-style],[data-mud-bind-attr]")` on every push
and applies [HW-BIND]:

| Form | What it does | Blocked |
|---|---|---|
| `data-mud-bind="key"` | `el.textContent = value` | (text only, never HTML) |
| `data-mud-bind-style="prop:key; prop2:key2"` | `el.style.setProperty(prop, value)` | prop `csstext`, `behavior`; a value matching `/expression\s*\(\|javascript:\|vbscript:\|<\/?\w/i`; a `url(…)` whose scheme is not http/https/mailto/tel/ftp or `data:image/` |
| `data-mud-bind-attr="attr:key; …"` | `el.setAttribute(attr, value)` | attr matching `/^(on\|data-mud-)/i`, or `srcdoc`, `style`, `xmlns`; for `href`, `src`, `background`, `poster`, `formaction`, `action`, `cite`, `longdesc` and `ping` the value must pass the same URL-scheme check |

Values are stringified and cut at 50,000 characters [HW-BIND].

What that allows for a map:

- **CSS:** `data-mud-bind-style="transform:p1t"` with `p1t = "translate(84px,120px)"`, or
  `left:p1x; top:p1y`. `setProperty` takes **custom properties** too, so
  `data-mud-bind-style="--px:p1x; --py:p1y"` on one element lets a stylesheet place the marker
  with `transform: translate(calc(var(--px) * var(--cell)), …)`. That is one bound element and
  two keys per marker.
- **SVG attributes:** `data-mud-bind-attr="cx:p1cx; cy:p1cy"` on a `<circle>`, `x/y` on a
  `<rect>` or `<use>`, `transform:p1t` on a `<g>`, or `points`/`d` for a path. `setAttribute`
  without a namespace is the normal way to set these presentation attributes.
- **Classes:** `class` is not blocked, so `data-mud-bind-attr="class:c0507"` can flip a cell
  between `unseen`/`seen`/`here` and let the stylesheet do the look.
- **Cost:** each `setBoundValue(s)` push is **one** pass over **every** bound element in the
  document, whatever keys changed (`y()` iterates them all) [HW-BIND]. At ~500 bound cells plus a
  few markers that is a cheap DOM walk, but binding every cell makes every marker step pay for
  the whole grid. If cells rarely change, bind only the markers and rebuild or script the cells.
- Bound values **persist** in the host (`u.current`) and are re-applied straight after every
  content write and again 100 ms later. A rebuild keeps its bindings [HW-COMP][DOCS-BIND].
- *Probe:* P2 (bound `transform` on an SVG `<g>` and bound `cx` on a `<circle>`).

### 3. Can content carry `<script>`, `<canvas>` or event handlers? Which CSS survives?

**All of it, by reading, and the expectation in the issue is wrong.** Content is
`document.write`n raw into an iframe sandboxed with `allow-scripts allow-same-origin`
[HW-COMP], so:

- `<script>` runs. This is documented and supported: every widget gets a `window.mudforge`
  helper (`send`, `onMessage`, `onProperty`, `showMenu`, `escapeHTML`, `setAppearance`,
  `setBorder`) "present from the first line of the widget's own script" [DOCS-MF][GUIDE-MF].
- `<canvas>` with a 2D context works like on any page, because script runs.
- Inline `onclick="…"` attributes run too: no sanitizer, no CSP. The web client sends no
  `Content-Security-Policy` header or meta tag, and an `about:blank` iframe would inherit one.
  The desktop exe contains Tauri's CSP-nonce machinery (`__TAURI_SCRIPT_NONCE__` and the bare
  directive names) but no policy values (`default-src`, `'self'` and `'unsafe-inline'` are absent) [CSP]. The *bound-value* blocklist above is the only
  place `on*` is filtered. Prefer `addEventListener` in a `<script>` anyway, and
  `data-mud-action` for buttons that should reach Lua without any script [DOCS-ACTION].
- **All CSS survives**, including `<style>` blocks, `@keyframes`, `transition`, `transform` and
  custom properties.
- Trust note: the docs warn that widget JS "runs with the client's own access". Put server
  text into markup through `escapeHTML(text)`, and data for a `<script>` through
  `json.encodeForScript(t)` [DOCS-OVERVIEW][GUIDE-ESC].
- *Probe:* P3 (script and inline handler run on desktop, no CSP in WebView2).

### 4. Do `title` / hover tooltips work?

- **Nothing in MudForge removes them.** `title` is not on any blocklist, and the docs give
  `data-mud-bind-attr="title:tip"` as their own example [HW-BIND][DOCS-BIND]. While the user is
  not dragging or resizing, the overlay div over the iframe has `pointerEvents:"none"` and
  `zIndex:-1`, so hover reaches the iframe content. The overlay only switches to
  `pointerEvents:"all"` during a drag or resize [HW-COMP].
- **SVG caveat (browser rule, not MudForge):** a `title="…"` *attribute* on an SVG element
  shows no tooltip. Use a `<title>` child element instead:
  `<rect …><title data-mud-bind="t0507"></title></rect>` can even be fed by a text binding.
- Whether WebView2 shows native tooltips for elements inside the iframe can't be settled by
  reading. *Probe:* P4.

### 5. What does a content rewrite cost at ~500 cells, and does it flicker?

What reading settles [HW-COMP][DOCS-SETPROP]:

- A rewrite replaces the **whole document**: `document.open()` → `write` → `close()`. Every
  `setTimeout`/`setInterval`/`requestAnimationFrame` the old content started is cancelled
  (the client wraps the iframe's timer functions in a registry, `__mudforgeTimerRegistry`).
  DOM listeners, scroll position, focus and any JS state are gone.
- `onMessage`/`onProperty` receivers are cleared, and messages sent before the new script
  re-registers them are **dropped**. That is why the guide's pattern is `mudforge.send("ready")`
  from the widget, with Lua waiting for it [GUIDE-MF].
- Event wiring (click, keydown and so on) is re-attached 100 ms after the write.
- Setting `content` to the *same* string does nothing: it is React state, and an equal string
  does not re-render.
- The docs themselves say a content rewrite "rebuilds the whole widget — resetting the DOM,
  dropping listeners and flickering" [DOCS-BIND].

What can't be settled by reading: the wall-clock cost of a ~500-cell SVG string (Lua string
build → event → parse → layout), and whether that flicker is visible. `open/write/close` runs
in one task, so a browser normally won't paint in between, but the docs claim flicker.
*Probe:* P5.

Recommended shape, whatever P5 finds: **write content once per area** (the grid and lines),
and move markers with bound values or a script. Rewrite only when the area or viewport
changes. That also matches ADR 0002's rule that ticking widgets don't rebuild.

### 6. Which widget events are there for size?

- Widget events (Lua `registerWidgetEvent`): `click`, `doubleclick`, `action`, `mousedown`,
  `mouseup`, `mousemove`, `keydown`, `keyup`, `submit`, `resize`, `move`, `close`, and for
  html widgets also `luamsg`, `menuselect` and `menuclose` [DOCS-EVENTS][GUIDE-EVENTS].
  `resize` carries `{ width, height }`.
- **But for an html widget, a user resize does not fire Lua `resize`.** The Lua handler
  listens for the window event `plugin-widget-resize` [RT-REG]. In the bundle that event is
  dispatched only by (a) the plugin's own `resizeWidget()` call and (b) the **canvas** widget
  component (its `ResizeObserver`, font loads and font changes) [HW-RESIZE][RT-RESIZE]. The
  html widget component never dispatches it [HW-COMP]. The guide says the same about docked
  widgets: they get "their usual resize event (canvas widgets) or window resize (HTML
  widgets)" [GUIDE-DOCK].
- So size-aware drawing belongs **inside the widget**: a `viewBox` SVG that scales on its own,
  or `window.addEventListener("resize", …)` in the widget's script. If Lua must know the size,
  forward it with `mudforge.send("size", {w: innerWidth, h: innerHeight})`, which arrives as a
  `luamsg` event.
- App-level: `getWindowSize()` and the plugin event `on("windowResize", fn)` (debounced
  ~150 ms) cover the whole client window, not one widget [GUIDE-WINRESIZE].
- `close` now exists as a widget event (it fires on the × button). That contradicts this
  repo's earlier finding that ✕-close is undetectable. The client has moved on since then;
  re-check it against the desktop build you run.
- *Probe:* P6.

---

## Alternatives the bundle offers

- **`type = "canvas"` widget.** Valid types are exactly `canvas`, `html` and `map`
  [RT-TYPES]. The Lua drawing API includes `clear`, `drawRect`, `drawRoundedRect`,
  `drawCircle`, `drawLine`, `drawPolygon`, `drawPath` (SVG path strings), `drawText`,
  `measureText`, `save`/`restore`/`translate`/`scale` and `setClipRegion` [DOCS-CANVAS]. It
  gets real Lua `resize` events (DPR-aware: the canvas is sized `size × devicePixelRatio`)
  [HW-RESIZE]. Each redraw is `setActiveWidget(id); clear(); draw…`, so a marker step
  redraws everything from Lua. There is no DOM, so tooltips mean hit-testing `mousemove`
  yourself.
- **`createMapperWidget(name, opts)`** embeds MudForge's own map renderer read-only. It needs
  rooms fed through `addMapRoom`/`setMapExit`/`setPlayerRoom` into the session's map store,
  which would mix TextDungeon's map into the user's MUD map data [DOCS-MAPPER]. Probably not
  a fit, but it exists.

---

## Probes for the desktop client

Each probe is a few lines of Lua in a scratch plugin, run in the desktop app (updated to
current). The agent can't run these.

**P1. SVG renders and scales.**
```lua
local w = createWidget({ type = "html", name = "probe-svg", size = { width = 300, height = 300 } })
setWidgetProperty(w, "content", [[
<style>html,body{margin:0;height:100%;background:#111}</style>
<svg viewBox="0 0 210 230" width="100%" height="100%" preserveAspectRatio="xMidYMid meet">
  <rect x="0" y="0" width="210" height="230" fill="none" stroke="#888"/>
  <line x1="5" y1="5" x2="205" y2="225" stroke="#c84"/>
  <circle cx="105" cy="115" r="6" fill="#4cf"/>
</svg>]])
```
Check that the box, diagonal and dot draw, and that resizing the widget by its corner scales
them (the diagonal stays corner to corner).

**P2. Bound values move SVG and CSS.** Add to P1's SVG
`<g data-mud-bind-attr="transform:gt"><circle r="4" fill="#f44"/></g>`,
`<circle r="4" fill="#4f4" data-mud-bind-attr="cx:cx; cy:cy"/>` and
`<circle r="4" fill="#ff4" data-mud-bind-style="transform:ct"/>`, then run
`setBoundValues(w, { gt = "translate(30,40)", cx = 60, cy = 80, ct = "translate(90px,120px)" })`
from an alias. Check that all three dots land where they should with no flicker of the rest.

**P3. Script, canvas and inline handlers run.** Content:
`<canvas id="c" width="100" height="50"></canvas><button onclick="mudforge.send('inline',{})">x</button><script>document.getElementById('c').getContext('2d').fillRect(10,10,30,30);mudforge.send('ready',{})</script>`,
with `registerWidgetEvent(w, "luamsg", function(m) print(m.event) end)`. Check that a
filled square shows, `ready` prints on load and `inline` prints on click. If either is
missing, open devtools (F12, if enabled) and look for a CSP violation.

**P4. Tooltips.** Content: `<div title="html tip">hover div</div>` and an SVG
`<rect width="50" height="50"><title>svg tip</title></rect>`. Hover each for about a second.
Check that WebView2 shows both native tooltips.

**P5. Rewrite cost and flicker at ~500 cells.** In Lua, build a 21×23 grid as SVG (`<rect>`
per cell plus a `<line>` per neighbour, about 1,400 elements), then from an alias rewrite it
20 times on a 100 ms timer, nudging one rect each time. Time the Lua side with `os.clock()`
around building the string and `setWidgetProperty`, and watch for a blank or white frame
during the rewrites. Compare against moving one bound marker 20 times (P2 style).

**P6. Which resize signals arrive.** On an html widget, register Lua `resize`, and in content
add `<script>addEventListener('resize',()=>mudforge.send('size',{w:innerWidth,h:innerHeight}))</script>`.
Drag-resize the widget, then dock it into the Dynamic layout and resize the tile. Reading
predicts that the Lua `resize` handler never prints and `luamsg size` prints on every change.

---

## Sources

All bundle files are from `https://play.mudvault.org/_next/static/chunks/`, build 2.0.3224.

| Tag | Source |
|---|---|
| HW-COMP | `919.5b53e183e79ec7fb.js`, html widget component `Cv` (≈ offset 1,741,500–1,758,000): `useState(n\|\|"<h1>Loading...</h1>")`; listeners for `plugin-widget-property-change` (content → state), `plugin-widget-bind`, `plugin-widget-message`, `widget-drag-*`, `widget-resize-*`; `window.mudforge` object; timer registry wrap; `s.open(),…,s.write(p),s.close()`; scrollbar `<style id="mudforge-scrollbars">` unless `/scrollbar/i.test(p)`; event wiring after `setTimeout(…,100)`; `<iframe … sandbox:"allow-scripts allow-same-origin allow-forms allow-modals allow-popups" className:"h-full w-full border-0">`; overlay div `pointerEvents: f\|\|v ? "all" : "none"` |
| HW-BIND | same chunk, just before `Cv`: `Cm=/^(on\|data-mud-)/i`, `Ch=new Set(["srcdoc","style","xmlns"])`, `Cp=new Set(["href","src","background","poster","formaction","action","cite","longdesc","ping"])`, `Cg=new Set(["csstext","behavior"])`, URL check `Cf` (http/https/mailto/tel/ftp, `data:image/` only), binder `y()` → `textContent` / `style.setProperty` / `setAttribute`, values cut at `5e4` chars |
| HW-RESIZE | same chunk, `PluginCanvasWidget` (≈ offset 1,724,000–1,739,000): `ResizeObserver` on the canvas parent, DPR sizing, `plugin-widget-resize` dispatched on size, font-ready and font change; `k6="__mudforgeTimerRegistry"` and `k8()` clear |
| HW-SETPROP | `6394-f0838baa19dc94bd.js` ≈ offset 343,228: `setWidgetProperty` stores `properties[n]=i` and dispatches `plugin-widget-property-change` with the value unchanged; the runtime wrapper ≈ 191,014 only checks the target |
| RT-REG | `6394-…js` ≈ 187,477: `registerWidgetEvent` listens on `"plugin-widget-".concat(event)` |
| RT-RESIZE | `6394-…js` ≈ 190,352 and 342,137 (`resizeWidget` dispatches `plugin-widget-resize`), ≈ 234,452 (`requestImageRedraw`, canvas only) |
| RT-TYPES | `6394-…js` ≈ 120,000: `F=["canvas","html","map"]`; error text *"Use "canvas" or "html" — or createMapperWidget() for a map."* |
| RT-UNIVERSAL | `6394-…js` ≈ 103,866: internal `renderHTML(){… this.htmlElement.innerHTML=M.A.sanitize(e)}`, the bundle's only DOMPurify call (DOMPurify itself is chunk `4341-505ac7f10b396aaf.js`) |
| DOCS-OVERVIEW | `7586.d4667446f13f96c8.js` (in-app API docs) ≈ 247,971–251,500: "HTML Widgets — Render HTML / CSS / JS in a sandboxed iframe…"; "A content rewrite is a clean slate…"; "Always escape text from the server. Widget JavaScript runs with the client's own access…" |
| DOCS-SETPROP | same chunk ≈ 566,766 `setWidgetProperty` section: "HTML widget timers on rebuild", "HTML widget scrollbars" |
| DOCS-EVENTS | same chunk ≈ 568,944 `registerWidgetEvent` section (event list, `close` semantics, `targetId`/`dataset` fields) |
| DOCS-ACTION | same chunk ≈ 573,987 `data-mud-action` section |
| DOCS-BIND | same chunk ≈ 578,504 `setBoundValue(s)` section: "Unlike content (which rebuilds the whole widget — resetting the DOM, dropping listeners and flickering)…"; "Values persist, so even a full content rebuild re-hydrates its bindings"; bind-attr blocks `onclick`, `srcdoc`, `javascript:`, `file:` |
| DOCS-MF | same chunk ≈ 608,684 "HTML widgets: window.mudforge" |
| DOCS-CANVAS | same chunk ≈ 512,076–553,818: drawing API titles (`clear`, `drawRect` … `getPixel`) |
| DOCS-MAPPER | same chunk ≈ 866,621 `createMapperWidget(name, opts?)` |
| GUIDE-* | `https://play.mudvault.org/docs/ai-plugin-guide.md` (fetched 2026-10-06): DOCK = "Docked widgets" paragraph (≈ line 407: "resize event (canvas widgets) or window resize (HTML widgets)"); EVENTS = widget event list and shapes (≈ 560–585); MF = "HTML widget JavaScript — window.mudforge" and "Wait for the widget before you talk to it" (≈ 590–640); ESC = escaping note (≈ 417); WINRESIZE = `getWindowSize` + `windowResize` (≈ 508–530) |
| CSP | `curl -I https://play.mudvault.org/` returns no `Content-Security-Policy`, and `index.html` has no CSP meta; `mudforge.exe` contains `__TAURI_SCRIPT_NONCE__` and bare directive names (`script-src`, `style-src`) but no policy values (`default-src`, `'self'` and `'unsafe-inline'` are absent) (an absent string is weaker evidence than a present one, hence P3) |
