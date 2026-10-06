# PROTOTYPE — Map window level control (wayfinder map #17, ticket "How the player steps between levels")

Throwaway. Four structurally different ways to step between levels, all on look A
"Tiles" (`../map-look/render.js`, with small hooks added for this prototype):

| Variant | Where | How |
|---|---|---|
| **A — Stepper** | right of the header bar | `▼ Level n of m ▲`; the ends are disabled; while Browsing the text turns cyan and the line under the plane offers "back to you" |
| **B — Chips** | right of the header bar | a numbered chip per level, the shown one filled; yellow dot = you, coral = a Group member |
| **C — Ladder** | a strip down the plane's right edge | the same chips stacked, highest level on top; the header keeps "Level n of m" |
| **D — Click the stairs** | on the plane | no buttons: click a white up/down corner mark to show the level it leads to; "↩ yours" in the header while Browsing |

Common to all four: a 1-level plane shows no control at all. A Depth is one level
per plane (its stairs `leaves` the map, drawn hollow), so it shows no control either:
the Area name already says "Depth n". Every clickable part carries
`data-mud-action="level"` with `data-mud-data` = the level's `z` or `mine`, so the
click goes to Lua, which owns Browsing (moving or a new Area ends it).

## Look in a browser

Serve `prototype/` (`python -m http.server 8731` in it) and open
`map-levels/preview.html`. `?variant=A|B|C|D`, the yellow bar or ←/→ switch
controls. The planes worth trying: Gildhythe and Stubbing (two levels; you start
beside a stair, Rei is upstairs in Gildhythe), the Lees depths (one level, stairs
leave). Click a room to stand there, shift+click to move Rei.

## Look in MudForge against the live feed

`node prototype/map-levels/build-lua.js` writes `map-levels-prototype.lua`. Import it
with a world connected to `arrs:4000`, then walk to Gildhythe or Stubbing.
