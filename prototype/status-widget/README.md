# PROTOTYPE — Status widget look (wayfinder ticket #5)

Throwaway. Three structurally different takes on the Status widget, all driving
the **same bound markup** (`data-mud-bind*`) so the winner lifts straight into
the real plugin.

| Variant | Shape | Default size |
|---|---|---|
| **A — Stacked meters** (**winner**) | Label / bar-with-word / numbers per row, RT bar under, standing + enc + power footer | 240×132 |
| **B — Prompt strip** | One wide line of three word-pills (numbers as tooltip), power/standing/enc at right, thin RT line below with seconds | 540×62 |
| **C — Word-led** | Band words are the display, hairline bars beneath, numbers in the caption, RT as a big numeral + vertical column | 200×172 |

## Look without MudForge

Open `preview.html` in a browser (`python -m http.server` in this folder if
`file://` is blocked). `?variant=A|B|C`, the yellow bar, or ←/→ switch. The
buttons fake `Char.Vitals` / `Char.RoundTime` pushes; the state dump under the
widget shows the package and every bound key.

## Look in MudForge against the real feed

`node build-lua.js` regenerates `textdungeon-hud-prototype.lua` from the
`<template>`s in `preview.html`. Import that `.lua` (Ctrl+P → Installed →
Import) with a world open and connected to local TextDungeonC; it mounts all
three variants as separate widgets, bound to live `Char.Vitals` and
`Char.RoundTime`. Edit `preview.html`, rebuild, re-import.

## Verdict (2026-09-11)

**A — Stacked meters** wins. Applied here: Focus row above Footing; tier ramp
starts at red like MudForge's built-in gauge (5 red → 4 red-orange → 3 orange →
2 yellow → 1 green). Tooltips via `data-mud-bind-attr="title:…"` and tier
colours via `data-mud-bind-attr="data-tier:…"` both confirmed working in
MudForge. B and C are kept only as the primary source of the comparison.
