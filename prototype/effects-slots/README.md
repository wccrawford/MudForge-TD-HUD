# PROTOTYPE — Effects and Slots widget look (wayfinder ticket #6)

Throwaway. Three structurally different takes on each of the **Effects** and
**Slots** widgets, all driving the **same bound markup** (`data-mud-bind*`) so
the winners lift straight into the real plugin. Pick one of each — they are
independent.

## Effects

| Variant | Shape | Default size |
|---|---|---|
| **A — Timer rows** | Name left, `mm:ss` right, a hairline under each row draining toward expiry | 240×132 |
| **B — Chips** | Wrapping pills `Name 0:42`, the pill border carries urgency | 240×92 |
| **C — Ladder** | Time-led: big tabular time in a left column, name beside; soonest on top and brightest | 240×118 |

Common to all three: soonest first, `mm:ss` (whole seconds, rounded up, as
`status` prints), time and bar turn **red under 5 s**, `No effects` when the
list is empty. There is no name-only case — the feed research (#4) found
`ends_at_ms` is always present.

## Slots

| Variant | Shape | Default size |
|---|---|---|
| **A — Ledger** | One row per slot in feed (Race) order, `label │ item`; empties dimmed with a dash | 240×192 |
| **B — Paperdoll** | Tiles anchored to a 3-column body grid by slot label; unknown kinds (Tail, Wing, Horn…) flow into the gaps | 240×150 |
| **C — Held / Worn** | The hands as two big boxes up top, everything worn as one dense running line | 240×140 |

Every slot is shown, empties dimmed (`data-empty="1"`). "Held" means the
`Hand`/`Hand N` kind; `Hands` (armour) is worn.

## The list question: fixed pools, never a rebuild

Every variant is a **fixed pool** of rows — 10 effects, 16 slots (+4 held) —
present from the one and only `content` set. A feed push only flips per-row
bound values (`e3d = "none"` hides a row; `s7g = "2/1"` anchors a tile), so
`setWidgetProperty(id, "content", …)` is never called again, no binding is
ever lost, and the widget never flickers. The preview's state dump counts
content sets to make this visible.

Trade-off: the pool is a hard cap. An 11th effect only shows as `+N more`
(and only if the ten rows above it fit the widget height). The map's
"Long Effects lists" fog owns what to do about that; the fallback of
rewriting `content` with a bigger pool relies on MudForge re-hydrating
bindings from persisted values, which the docs promise but this prototype
does **not** exercise.

## Look without MudForge

Open `preview.html` in a browser (`python -m http.server` in this folder if
`file://` is blocked). `?effects=A|B|C&slots=A|B|C`, the yellow bar, ←/→
(Effects) and Shift+←/→ (Slots) switch. The buttons fake `Char.Effects` /
`Char.Items` pushes — including a 12-effect overflow, a two-handed weapon
(same `instance` in both hands), long item names, a Race with Tail/Wings/Horn,
and a Race with no slots. The state dump under the widgets shows the packages
and every bound key.

## Look in MudForge against the real feed

`node build-lua.js` regenerates `textdungeon-hud-effects-slots-prototype.lua`
from the `<template>`s in `preview.html`. Import that `.lua` (Ctrl+P →
Installed → Import) with a world open and connected to local TextDungeonC; it
mounts all six variants as separate widgets (Effects down the left, Slots in
a second column), bound to live `Char.Effects` and `Char.Items`. Edit
`preview.html`, rebuild, re-import.

The generated Lua passes the luaparse 5.1 gate (#3). One thing to confirm in
MudForge that the browser can't: Ladder (Effects C) binds the `class`
attribute via `data-mud-bind-attr="class:eNc"` — if MudForge blocks that,
the "top row brighter" emphasis silently disappears.
