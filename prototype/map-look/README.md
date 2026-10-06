# PROTOTYPE — Map window look (wayfinder map #17, ticket "What the Map looks like")

Throwaway. Three structurally different looks for the Map window, drawn from the
captured `Area.Map` / `Area.Where` fixtures (`tests/fixtures/map/`).

| Variant | Plane | Terrain without colour | Header / holds |
|---|---|---|---|
| **A — Tiles** | terrain-filled squares with gaps, thick bridges, thin diagonals | fill pattern per terrain | bar on top; holds as a footer |
| **B — Nodes and lines** | small nodes on thick lines, like a transit map; stubs run off with a chevron | node shape (square inside/city, triangle forest/hills, diamond water/swamp, …) | overlay tag in the map's corner; holds as a side column |
| **C — Floor plan** | walled rooms that nearly touch; an exit is a gap in the wall, a door sits in the gap | a glyph in the room's corner | title bar with level steps; holds as one summary line |

Common to all three: you are yellow, the Group coral, `back` cyan, doors orange;
up/down marks are faint when the stair `leaves` the map (a Depth) or is
`unexplored`; a leave with no compass word (`vault`, `walkyard`, `out`) is a
direction-less corner mark, named in the room's tooltip.

## Look in a browser

`luajit prototype/map-look/fixtures-to-js.lua > prototype/map-look/fixtures.js`
(already done), then serve the folder (`python -m http.server 8731` in it) and open
`preview.html`. `?variant=A|B|C`, the yellow bar or ←/→ switch looks. Click a room
to stand there, shift+click to put Rei there. The window resizes from its corner.
"gallery" draws every captured plane at once.

## Look in MudForge against the live feed

`node prototype/map-look/build-lua.js` writes `map-look-prototype.lua`. Import it
with a world open and connected to `arrs:4000`. It opens one widget, "Map
(prototype)", with A/B/C and ▼/▲ buttons along its bottom, and sends `Core.Hello`
so it fills at once. Then type `map` in the same room and compare.

## Verdict (2026-10-06)

**A — Tiles, texture** wins, after one round of changes asked for by the user:

- textures are drawn inside each tile's own `translate()`, so a 6-unit pattern
  starts at every 12-unit tile's corner and lines up (the first cut was anchored to
  the SVG and looked like a mismatched grid);
- city is brick, inside an inner frame (no texture), cave scattered rock; water,
  swamp, field, forest and hills kept their first patterns;
- compass and diagonal lines both 2.6 (were 4 and 1.6), stubs the same, arrowheads larger;
- up/down are white corner triangles, half outside the tile on a dark outline;
  hollow when the stair `leaves` (Depths), hollow and dashed when `unexplored`;
  a direction-less leave is a white ↗ disc on the top-left corner (cyan for `back`);
  unexplored stubs end in a ringed "?"; doors and Group dots larger; corner marks
  draw over the you ring.

B was readable but boring; C's glyphs and up/down marks didn't stand out. D (one
motif per tile) lost to A. All four are kept here only as the primary source.
