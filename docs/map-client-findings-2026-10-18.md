# Rooms, names and Wards in a client: findings

For TextDungeonC, to carry into `docs/evidence/map-client/` beside
`first-client-findings-2026-10-06.md`. It covers the five keys that
`docs/map-client-handoff.md`, *Rooms, names and Wards*, added to `Area.Map`
(`room`, `names`, `ward`, `wards`, `leads`; server 0.20.0). It lists which
keys the client used, what was seen live and what only in hand-written
fixtures, where the data and the handoff differ, and what is wished for. It
is written in the HUD repo because nothing is written in TextDungeonC from
here.

**The client:** the TextDungeon HUD's Map window, MudForge plugin `v0.7.0`, in
MudForge 2.0.3701 against `arrs:4000` (world `prism`) on 2026-10-18. It is
the same client as the first findings. It draws one level of the current
plane from `Area.Map` and now follows the player at a fixed zoom, with
dragging and zooming. The packages it read are kept as Lua fixtures in
`tests/fixtures/map/` (the `*_named` planes and `seq_delve_names`), captured
by `tools/mapcap.lua`.

**Walked live:** Gildhythe (a Town with two levels, and the Stopper inside
it), the Band House (a Building), the Bottle Shallows (a Wilds), the Lees
(Depth 1, growing), the Spit Cut (an Expedition member), and a Group with a
second player. Captured but not walked in the window: the Green Road, the
Tally Glass, the Glassfall, the Ochre Fringe and the Ringing Rows.

## Keys

### Used: all five

Each key draws something:

- **`room`**: a Room of two or more Cells is drawn as one faded shape: its
  parts' bounding box, or a band along the diagonal for a run whose parts
  don't fill their box. Each Cell keeps a dot, its exits and its tooltip. A
  Cell with no `room` is drawn as before.
- **`names`**: the Room's name is the first line of every Cell's tooltip, and
  the Room you stand in is named in the window's header. A name is drawn on
  the map only beside a Room of two or more Cells.
- **`ward`** / **`wards`**: a tint and a dashed outline per Ward, a legend
  row, and the Ward in the tooltip and the header. A Ward with no Cells gets
  a hollow swatch in the legend.
- **`leads`**: a label at the stub's tip, drawn only where it covers nothing.
  Otherwise the Lead is in the stub's and the Cell's tooltip
  (`north: to the Green Road`).

Two choices differ from the handoff's *What to draw*. The handoff leaves
drawing to the client, so neither is a request:

- **Lines between a Room's Cells are kept.** The handoff says "no lines
  between its cells". The window keeps each Cell's dot and its exits over
  the faded shape. You and your Group are placed by Cell, and a Delve's `?`
  stubs and doors hang off Cells, so the Cells stay visible. The user chose
  this over a plain rectangle.
- **Not every Room or stub is labelled.** One-Cell Rooms get no label on the
  map, which covers every live Room today (see *Names repeat in a Wilds*).
  A Lead label that would cover a tile, a stair mark or another label is
  left to the tooltip.

### Seen live

- **`names`, on every plane.** There is one entry per Cell, since each
  Location is its own Room. The keys are exactly the map ids. A copy names
  only the Rooms entered: the Lees, Depth 1, went from 1 name to 9 as it
  grew. The names are Location names, so they carry a part's suffix (the
  header read `Landing Street, by the Stopper`).
- **`leads`, in every authored Area, on every leaving exit seen.** The kinds
  were:
  - gates to the next Area (the Mere Road, the Sand Road);
  - Buildings, by their door noun (`walkyard` → "The Walk Yard");
  - an Owned vault (`vault` → "Your Strongbox");
  - an Expedition's mouth (`in` → "the Gilt Stand");
  - `up` / `down` to another Area (the Glassfall's `up` → "the Melted
    Galleries").

  One Cell can lead two ways (the Tally Glass, northeast and south). No copy
  had any `leads`, as the handoff says.
- **The Cells are unchanged.** Gildhythe matches its 2026-10-06 capture key
  for key, apart from `names` and `leads`.

### Not seen live

- **`room`, `ward` and `wards`: nowhere, Depths included.** The user says the
  Worlds on `arrs:4000` were redeployed but not regenerated, and no Area file
  in `march`, `prism`, `underlay` or `vesper` declares Rooms or Wards. So the
  shapes, the band, the Ward shading, the legend and the header's Ward were
  drawn only from three hand-written fixtures. Each one is marked synthetic and
  cites the handoff line it follows:
  - `plane_synthetic_town_rooms`: 1 × 3 and 2 × 2 Rooms, a Room whose id
    isn't its lowest part, a diagonal run, a leaf shop, three Wards with
    one that has no Cells, Leads to a Building, a gate and a Ward's Wilds,
    and a stair.
  - `plane_synthetic_ward_wilds`: that Ward as its own Area.
  - `plane_synthetic_delve_rooms`: a Delve Room entered whole, with names
    only for the Rooms entered.
- **Non-ASCII names.** No captured or walked name had any.
- **`back`**, still. No owned place was entered.

## Where the data and the handoff differ

**Nothing contradicted the handoff.** Where the server sends less than the
handoff promises, that is a server bug to fix, but none was found. These places are worth a line, because
a mapper reading the handoff alone would expect something else.

1. **`leads` covers more kinds of exit than the handoff lists.** The handoff
   lists "a Building, a dangerous Ward's Wilds, a Delve's mouth, the gate to
   the next Area". Live data also had `up` / `down` to another Area and an
   Owned vault's door. ADR 0058's wording ("the place a leaving exit of an
   authored Area enters") covers both, so this is a gap in the handoff's
   list, not a contradiction.
2. **Names repeat heavily in a Wilds.** Gildhythe has 38 Cells and 38
   distinct names. The Ochre Fringe has 50 Cells, 14 names and 3 stems ("the
   Green Edge", "the Green Edge, the …"). That looks deliberate, since a
   Wilds' plain cells share their part's name. But a mapper that labels every
   one-Cell Room on the map gets a cluttered, repetitive picture until a
   World is regenerated with Rooms. Names run up to 41 characters. Worth a
   line under `names`.
3. **The Expedition's way back out has no Lead.** The Spit Cut's first Cell
   has `leaves: ["south"]`, with no `leads` and no `back`, so the window can
   only say "south leaves this map". That is the contract: an Expedition is
   a copy, not an authored Area, and "inside a Delve a leaving exit is never
   named". It's noted because it was the one leaving stub on the walk with
   no name. The Expedition's mouth outside does carry a Lead.

## Wished for

- **A World regenerated with Rooms and Wards** on `arrs:4000`, or a small one
  that declares a few, so that `room`, `ward` and `wards` can be walked live.
  The window draws them only from the fixtures above.
- **Nothing else is wished for to draw the plane.**

## Not checked

- **Names against the `map` verb.** The handoff says every name in the
  package is one that `map` or `map key` prints. This walk didn't compare
  them.

## Client-side only, not for the server

These are MudForge facts, kept in the HUD repo:

- Every string from Lua reaches a widget page as Latin-1, so the client sends
  non-ASCII as `&#NNN;` entities and `\uXXXX` escapes.
- MudForge's `string.gsub` returns no count.
- Arrays don't cross between Lua and a page intact.

None of them bears on the package.
