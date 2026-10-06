# The first client reading `Area.Map`: findings

For TextDungeonC, to carry into `docs/evidence/`. The handoff
(`docs/map-client-handoff.md`, *What is measured, and what is not*) asks the
first mapper written from it to note three things: a field it never used, a
field it wished for, and any place where the package disagreed with the `map`
verb. This note is that record. It is written in the HUD repo because nothing
is written in TextDungeonC from here.

**The client:** the TextDungeon HUD's Map window, MudForge plugin `v0.4.0`,
running in MudForge against `arrs:4000` (world `prism`) on 2026-10-06. It
draws one level of the current plane as SVG from `Area.Map` and places you and
your Group from `Area.Where`. It remembers nothing after you leave an Area.
The packages it read are kept as Lua fixtures in `tests/fixtures/map/`
(11 planes and 10 sequences in arrival order), captured by `tools/mapcap.lua`.

**Walked live:** Gildhythe (a Town with two levels), the Mere Road (21 × 11,
negative on both axes), `config map off` / `on`, the Spit Cut (a Delve, growing
room by room, and its vault door opening), the crossing to the Stopper Vaults
and back (`jarvaults`), and the Lees (Depth 1, then the descent to Depth 2).
The Bottle Shallows, the Canopy Loft and Stubbing were captured but not walked
in the window.

## Fields

### Used: all of them

Every field in the package drew something of its own: `area`, `region`,
`x`/`y`/`z`, `terrain`, `exits`, `leaves`, `back`, `unexplored`, `doors`
(`name` and `closed`), `holds`, `here` and `members`.

The deferred item *Measuring a client reading `Area.Map`* asks whether the
four edge forms should simplify. From this client: **no.** Each one drew
differently, and none could be derived from another:

- **`exits`** draw a line to the target's cell, or a stair mark when the target
  is on another `z`.
- **`leaves`** draw a stub with an arrowhead, or a corner mark when the word
  isn't a compass word (`vault`, `walkyard`, `out`).
- **`back`** draws the same stub as a leave, in another colour.
- **`unexplored`** draws a dashed stub ending in a `?`.

Positioning by the target's cell, never by the word, worked everywhere:
`in`/`out` interiors and door nouns needed no special case.

### Never seen live

These were drawn and tested only from hand-written fixtures built from the
contract:

- **`back`.** No owned place was entered.
- **`rooms: {}`.** No pos-less Area was found.
- **An `Area.Where` without `here`.**
- **`members` with someone in another room.** The Group sequence has a member
  sharing your room (`{"Rei": "247"}` with `here: "247"`), but the window was
  walked solo.

### Wished for

- **A signal that `config map` is off.** `config map off` sends nothing, so the
  client keeps the last plane and can't tell that it is stale. The handoff asks
  a mapper to "say why in its own UI" when it gets no `Area.Map`. A mapper that
  had a plane before can only do that by parsing the prose of the `config`
  reply. Some cheap form would do: an `Area.Map` of `{}`, an `Area.Where` of
  `{}`, or a field saying it's off. The window can show its "no map" reason
  (which names `config map on`) only when it holds no plane at all, for example
  after a login or a plugin reload while the map is off. `config map on`
  re-sends at once, as documented.
- **Nothing else was wished for to draw the plane.** Room names (for hover) are
  still an open design question on the client. If they're wanted, keying them
  by `Area.Where.here` from the same burst as `Room.Info` works everywhere,
  including in copies (see below). So this is not a request.

## Where the package or the handoff surprised us

None of these breaks the contract. Each is a place where the handoff's wording
led to a different expectation than what arrived.

1. **Login sends the plane twice, identically.** On login the full push
   (`Room.Info`, `Area.Map`, `Area.Where`) arrives, and 10 ms later a second
   `Room.Info`, `Area.Map` and `Area.Where` follow from the `look`. The two
   `Area.Map` payloads are equal field for field (`seq_login.lua`, seq 104 and
   122). The handoff says "the server only sends a package when its value
   changed", so this looks like a login path that skips the value-diff. It is
   harmless, since a snapshot replacing an equal snapshot changes nothing.
2. **In an Expedition copy, `Room.Info.num` is the template room's number and
   not the map id.** In `jarvaults`, `Room.Info.num` was `690` and `708`, while
   `Area.Where.here` was `d12` and `d13`. The handoff says an authored room's id
   equals its `num`, that `Room.Info` never carries a lettered id, and that a
   Depth room's `num` is `0`. All of that holds, but it never says that a
   copy's `Room.Info.num` is a real number that names a **different** room. A
   client that keys anything by `Room.Info.num` (names, notes, the "joining
   Areas" graph the handoff suggests) gets a plausible but wrong id there, and
   it may collide with an authored room. **`Area.Where.here` was the only
   reliable locator.** Worth a line in *`Area.Where`* or in *Joining Areas*.
3. **Depth stairs are `leaves: ["up"]` / `["down"]`, not `exits`.** Depths
   also carry no `terrain` and no `region`. All of this is allowed. But
   *Levels* says "mark a room with an up or down exit", and a mapper reading
   that as `exits` only would draw no stairs in a Depth. The window marks a
   stair from `leaves` too (hollow, since it leaves the plane). Worth a line
   in *Levels, Delves…*.
4. **A door changing state re-sends `Area.Map` alone**, with no `Room.Info` or
   `Area.Where`, even when the door is in a room the player isn't in. Working
   the windlass at `d11` opened the vault door at `d12`, and the Lees' wax seal
   did the same. This is consistent with *snapshot, never delta*. It's noted
   because a client that redraws only on `Area.Where` would miss it.
5. **`quit` and a re-login on the same connection send nothing in between.**
   Nothing arrives between `Goodbye!` and the new push, and MudForge's
   `onDisconnect` doesn't fire, so the old plane stays drawn until the new one
   lands. That's a short window and harmless here. It's noted because the
   handoff talks only about GMCP being re-agreed.

Seen as documented:

- **Order.** In about 3,000 captured entries, an `Area.Where` never arrived
  before the `Area.Map` that holds its `here`. The window holds one anyway, as
  the handoff says to.
- **Level changes.** Changing levels moves only `Area.Where`.
- **Delves.** A Delve re-sends in full for each room entered, about 400 ms apart
  while walking.
- **Expedition members.** They use lettered ids that continue across members
  (the Stopper Vaults starts at `d13`). Members are crossed through `leaves`
  plus a `doors` entry, and walking back re-sends the earlier member as
  explored.
- **Resync.** `Core.Hello` re-sent everything every time the plugin was
  reloaded mid-session. The window relies on it.

## Where the drawing and the `map` verb disagreed

The window was screenshotted next to `map` in the same room in three Areas.
**In no case did the window disagree with the package.** Both differences
found are in the verb.

- **The Mere Road** (you on the top room) agrees: the rooms, the line of the
  road, the north leave on your room, and the east leave below it (`o--->`).
  The verb is clipped ("more: SW"), so only its visible part could be
  compared. Under Fit, the window shows the whole 21 × 11 road, which matches
  the verb's count.
- **The Spit Cut** (a Delve, 2 × 6 explored) agrees: the unexplored `?` to the
  northwest, the six rooms, your room and the south leave.
- **Gildhythe** (10 × 12, two levels) agrees on the layout, the `X` crossing and
  the east leave. Two things differ:
  1. **The verb draws `===`, which its legend calls "door", on every link into
     an interior (`#`).** The package has **no `doors`** in Gildhythe (0 entries
     in `plane_gildhythe.lua`): those links are plain `exits` with the word
     `out`. Either the verb invents a door that the package doesn't carry, or the
     legend's "door" means "a link into an interior". One of the two should
     change.
  2. **The verb hides stairs on interior rooms.** Rooms 238, 228 and 231 are
     inside and have `up` to z 1. The verb shows them as `#` with no `^`. The
     window marks them with up triangles, because the package's `exits` reach
     z 1. When the verb chooses a glyph, the interior `#` seems to win over
     `^`, so a text-only player can't see those stairs on level 0.

The handoff says "the package is never richer than the verb". Point 2 breaks
that from the verb's side: the stairs are in the package and missing from the
picture.

## Client-side only, not for the server

These are MudForge facts, kept in the HUD repo: `next` is missing from its
plugin sandbox, a bare `"0"` click value may be dropped, and the resize grip's
hit area is wider than it draws. None of them bears on the package.
