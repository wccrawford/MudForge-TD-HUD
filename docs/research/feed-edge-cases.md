# Feed edge cases the widget must tolerate

Answers issue #4. Read-only investigation of the Rust server repo at
`D:\Projects\TextDungeonC` (`main` @ `8bf0e94`, 2026-09-11). Every path below
is relative to that repo. Nothing there was edited.

The feed is projected by `WorldStore::feed_snapshot`
(`crates/engine/src/feed.rs:371-539`) and serialised by `packages_of`
(`crates/server/src/session.rs:258-303`). Each package is pushed only when
its value (with `now_ms` stripped) differs from what the Session last sent
(`FeedDiff::changed`, `crates/server/src/session.rs:480-497`;
`without_now_ms`, `:456-462`).

---

## 1. Can an Active Effect have no end?

**No. `ends_at_ms` is always present, always a positive integer, and always
strictly greater than `now_ms` in the same payload.**

- `ActiveEffect.expires_at_ms` is a plain `u64`, not an `Option`
  (`crates/engine/src/stats.rs:217-233`); `expires_at_ms()` returns it directly
  (`:274-276`). There is no "permanent" sentinel: no `u64::MAX`, no zero
  special-case anywhere in `crates/engine/src`.
- Every constructor computes it as `now + duration_ms`: spells
  (`crates/engine/src/cast.rs:328`), consumables (`consume.rs:347`),
  maneuvers (`maneuver.rs:316`), the death-weakness debuff
  (`defeat.rs:273-281`, `DEATH_WEAKNESS_MS = 300_000`, `defeat.rs:52`).
  The durable-boundary copy re-uses the stored instant
  (`crates/engine/src/entity.rs:2229-2233`).
- The content schema does not forbid `duration_ms: 0`
  (`crates/engine/src/content/schema.rs:180-190`, no validation in
  `loader.rs`), but such an effect expires at the instant it lands:
  `is_expired_at` is `now_ms >= expires_at_ms` (`stats.rs:294-296`) and
  both `status` and the feed list only `active.live(now)`, which filters on
  that (`stats.rs:322-326`; feed at `feed.rs:434-450`; status at
  `legibility.rs:337-358`). So an effect with `ends_at_ms <= now_ms` is
  **never** in `Char.Effects`.
- Wire shape: `{"effects":[{"name":..., "ends_at_ms":<u64>}, ...],
  "now_ms":<u64>}` (`session.rs:262-276`). Hidden effects are omitted
  (`feed.rs:441`), exactly as `status` omits them (`legibility.rs:346`).

**What `status` prints:** `  <name> (<N>s)` with
`N = remaining_ms(now).div_ceil(1_000)` (`legibility.rs:340-354`;
`remaining_ms` saturates at 0, `stats.rs:299-301`). Because only live
effects are listed, `N >= 1` always; `(0s)` never prints. There is no
"permanent" wording. An expiring effect is silent: nothing announces it in
prose (`ActiveEffects::apply` is the only pruning point, `stats.rs:335-347`),
and the feed simply drops it from the list on the next render
(ADR 0058, `docs/adr/0058-the-out-of-band-feed.md:559-562`).

**Widget implication:** treat `ends_at_ms` as required; count down from
`ends_at_ms - now_ms` and expect the entry to vanish on a later push. Guard
against `ends_at_ms <= now_ms` defensively anyway (clock skew), but it is
not a server state.

---

## 2. What `status` prints that `Char.Vitals` does not carry

`do_status` is at `crates/engine/src/legibility.rs:264-361`. `Char.Vitals`
carries exactly: `condition`, `footing`, `focus`, `power` (only while held),
`standing`, `encumbrance`, plus the borrowed scalars `hp`/`maxhp`,
`mana`/`maxmana` (`feed.rs:139-167`; `vitals_payload`,
`session.rs:373-406`).

Printed by `status` but **not** in `Char.Vitals`:

| `status` line | Where | Fed anywhere? |
|---|---|---|
| `You are channeling <spell>.` (open Channel) | `legibility.rs:376-383` | **No.** `feed.rs:429-431` says "No preparation here, deliberately". |
| `Bound: <vessel> (<fullness>), ...` | `legibility.rs:399-414` | **No.** |
| `Type "abilities" for what you have learned...` | `legibility.rs:30-31, 330` | No (static text). |
| `Mitigation:` + `  <type>: <N> protection, <M>% absorption` per damage type | `legibility.rs:335, 442-466` | **No.** |
| `Effects:` + `  <name> (<N>s)` | `legibility.rs:337-358` | Yes, but in `Char.Effects`, and as an end-instant in ms rather than remaining whole seconds. |

Also note:

- `status` does **not** print Round Time (ADR 0058 `:916-918`); Round Time
  is only on the `Roundtime: N sec.` trailer, the `[N sec.] >` prompt, and
  `Char.RoundTime`.
- **Discrepancy in the ADR:** ADR 0058 `:190-197` lists "mitigation" and
  "an open preparation's spell name, phase and locked target" under *"Fed,
  about the reader"*. The code does not feed either (`feed.rs:139-167` has
  no such fields; `feed.rs:429-431` refuses preparation). Trust the code:
  the widget must not promise mitigation or channeling state from the feed.
- `Char.Vitals.condition.max` is the constant `CONDITION_MAX = 100`
  (`crates/engine/src/stats.rs:10`; `feed.rs:385`). `footing.max` is the
  constant `FOOTING_MAX = 100.0` (`crates/engine/src/footing.rs:10`;
  `feed.rs:388-392`). `focus.max` is the **live** per-Character ceiling
  (`feed.rs:395-407`) and can change between pushes.

---

## 3. Band ladders

`Band::of_table` (`feed.rs:70-81`) reads each table top-down, picks the
first row whose threshold the value is `>=`, and reports
`tier = index + 1`, `of = table.len()`. **Tier 1 is best; larger is worse;
the last row is the floor** (threshold `0` or `-inf`, so the read saturates
at the bottom rung). Names are the exact `&'static str` from the tables and
reach the wire verbatim (`session.rs:417-427`).

### Condition — `of: 5`
`crates/engine/src/condition.rs:47-53`; value is the raw whole number
0..=100 (`feed.rs:380`).

| tier | name | value >= |
|---|---|---|
| 1 | `Unhurt` | 80 |
| 2 | `Wounded` | 55 |
| 3 | `Badly Wounded` | 30 |
| 4 | `Gravely Wounded` | 10 |
| 5 | `Dying` | 0 |

### Footing — `of: 5`
`crates/engine/src/legibility.rs:119-125`; banded over
`footing_value / FOOTING_MAX` (`feed.rs:390`).

| tier | name | fraction >= |
|---|---|---|
| 1 | `steady` | 0.8 |
| 2 | `a bit unsteady` | 0.5 |
| 3 | `unsteady` | 0.25 |
| 4 | `badly off-balance` | 0.05 |
| 5 | `about to fall` | -inf |

### Focus — `of: 5`
`legibility.rs:133-139`; banded over `focus_value / focus_ceiling` (live
ceiling, `feed.rs:401`).

| tier | name | fraction >= |
|---|---|---|
| 1 | `sharp` | 0.8 |
| 2 | `clear` | 0.5 |
| 3 | `clouded` | 0.25 |
| 4 | `frayed` | 0.05 |
| 5 | `spent` | -inf |

### Standing — `of: 5` (bare band, no `cur`/`max`)
`crates/engine/src/standing.rs:51-57`; over the raw Standing number
(`feed.rs:420`). Note the direction: **Master is tier 1** ("larger is
worse" here means "less accomplished").

| tier | name | value >= |
|---|---|---|
| 1 | `Master` | 20 |
| 2 | `Expert` | 15 |
| 3 | `Journeyman` | 10 |
| 4 | `Apprentice` | 5 |
| 5 | `Novice` | 0 |

### Held power — `of: 4` (has `cur`, **no `max` key**)
`legibility.rs:147-152`; over the raw held amount (`feed.rs:413`). Present
only while power is held (`feed.rs:408-419`; `session.rs:401-403`). The
`max` key is absent, never `null` (`session.rs:417-427`).

| tier | name | amount >= |
|---|---|---|
| 1 | `a great charge` | 24.0 |
| 2 | `a considerable charge` | 12.0 |
| 3 | `a moderate charge` | 6.0 |
| 4 | `a slight charge` | -inf |

All tables are marked "provisional" in their doc comments
(`legibility.rs:117-118, 130-131, 145-146`; `standing.rs:46-50`), so key
tier colours on `tier`/`of`, not on the name strings.

### Rounding of `cur` / `max`

- **Condition**: whole `u32` already; `cur = condition_value`, `max = 100`
  (`feed.rs:379-386`). No rounding.
- **Footing and Focus**: `meter_figures(value, ceiling)`
  (`crates/engine/src/prose.rs:106-119`), the same call `status` uses
  (`legibility.rs:299-300`):
  - `max = round(ceiling)`, clamped `>= 0`; a ceiling of 0 reads `0/0`.
  - `cur = round(value)`, then **reserved ends**: if `cur <= 0` but
    `value > 0` -> `1`; if `cur >= max` but `value < ceiling` -> `max - 1`;
    finally clamped to `0..=max`. So `cur == 0` means truly empty and
    `cur == max` means exactly full; `59.6/60` reads `59/60`.
- **Held power**: `meter_figure(value)` (`prose.rs:73-80`): `round(value)`,
  with `0` bumped to `1` when `value > 0`. No ceiling.
- **Encumbrance**: `(ratio * 100.0).round() as i64` (`feed.rs:428`),
  identical to `status` (`legibility.rs:317-320`). A plain integer percent,
  not a band.
- `hp`/`maxhp` = `condition.cur`/`condition.max`; `mana`/`maxmana` =
  `focus.cur`/`focus.max` (`session.rs:388-401`).

---

## 4. `Char.RoundTime` semantics

Wire: `{"clears_at_ms":<u64>, "now_ms":<u64>}` (`session.rs:292-298`).
Engine: `RoundTimeRead` (`feed.rs:331-348`), populated at `feed.rs:523-530`:

```rust
clears_at_ms: self.get(character)
    .and_then(|data| data.round_time())
    .map(|round_time| round_time.clears_at_ms())
    .unwrap_or(0),
```

- **Login / never acted: `clears_at_ms: 0`.** A Character with no
  `RoundTime` component reads `0` (`feed.rs:528`), deliberately not `now`
  (`feed.rs:517-522`; ADR 0058 `:707-715`; test
  `crates/engine/tests/output/150_feed_projection.rs:407-425`). The durable
  save path clears the component (`strip_transient_state`,
  `crates/engine/src/entity.rs:2220`, called from
  `crates/server/src/durable/record.rs:203, 252`), so a Character restored
  on login always starts at `0` even if they logged out mid-Round-Time.
- **Free verb: no change, no push.** `base_round_time_ms` returns `None`
  for `VerbTier::Free` (`crates/engine/src/round_time.rs:511-513`); the
  Free tier is skipped by the gate entirely (`interaction.rs:896-900`) and
  `add_round_time` is only called when a cost exists
  (`interaction.rs:1163-1166`). The payload is therefore identical to the
  last one and `FeedDiff` suppresses it. (Other packages may still ride the
  same write — e.g. `look` after moving.)
- **Charged verb:** `add_round_time` sets
  `clears_at_ms = max(existing, now) + ms` (`round_time.rs:743-752`) —
  Round Times **stack**, so a new push can extend an existing end rather
  than replace it. One `Char.RoundTime` push rides that verb's reply,
  ordered *prose, prompt, feed* (test
  `crates/server/tests/output/32_the_feed_push_rides_the_prose.rs:443-489`;
  charged verbs always ship the package, `:520-525`).
- **At the instant RT clears: nothing is pushed.** Expiry is lazy
  (`round_time.rs:183-201`: "Nothing sweeps or decrements it"). The only
  writers of the component are `add_round_time` (`round_time.rs:751`) and
  `strip_transient_state` (`entity.rs:2220`). A lapsed clock keeps the past
  instant, so `clears_at_ms` **can be a past, non-zero value**; the sweep
  re-renders every second but the value is unchanged, so the diff drops it.
  The next push comes only when the next charged verb sets a new end, or
  on a full re-push (`DO GMCP` agreed / `Core.Hello`, `FeedDiff::forget`,
  `session.rs:503-506`). The in-flight tracker names this as a bug: "nothing
  announces the lapse today, in any mode"
  (`.scratch/rt-as-movement/issues/01-roundtime-per-second-cadence.md:96-102`).
- **The 1-second sweep** (`crates/server/src/world/actor.rs:454-497`):
  `push_elapsed()` (wall-clock delta, `:534-539`), `store.advance(1)`,
  deliver its prose, repop areas, then `sweep_feed` for **every attached
  Session** — a whole `feed_snapshot` each, diffed at the Session. It never
  touches Round Time. Two nuances: it fires immediately on attach
  (`tokio::time::interval` semantics, ADR 0058 `:1145-1147`), and it skips a
  Session whose delivery channel has fewer than `FEED_SWEEP_RESERVE = 8`
  free slots (`actor.rs:23-40`). An idle Session receives zero bytes
  (`32_the_feed_push_rides_the_prose.rs:545-571`).
- `now_ms` is World-elapsed ms, wall-derived (`actor.rs:534-539`). The
  `DO GMCP` re-push path (`WorldMessage::FeedSnapshot`, `actor.rs:646-648`)
  does **not** call `push_elapsed` first, so that one snapshot's `now_ms`
  may be stale by up to a sweep (noted at ticket 01 `:202-208`).

**Widget rule today:** clear iff `clears_at_ms == 0 || clears_at_ms <=
now_ms`. Anchor a local countdown to `clears_at_ms - now_ms` at receipt and
let it reach zero on its own — no push will tell you.

---

## 5. `Char.Items` slots

Wire: `{"slots":[{"slot":<string>, "instance":<u64|null>,
"item":<string|null>}, ...]}` (`session.rs:277-291`). Both `instance` and
`item` keys are **always present**, `null` when the slot is empty
(server test `28_the_feed_projection_reaches_the_wire.rs:151-160`).

**Order** = the Race definition's declared slot order, kinds de-duplicated
in first-seen order, then instances `0..count` within each kind
(`WorldStore::slot_instances`, `crates/engine/src/store.rs:1902-1940`).
Labels come from `slot_labels` (`crates/engine/src/inventory.rs:36-56`):
the kind label, suffixed with ` 1`, ` 2`... **only when the kind has more
than one instance**; bare otherwise. Kind labels:
`Head Body Legs Feet Hands Hand Waist Back Neck Finger Tail Wing Horn Nose
Ear` (`inventory.rs:9-27`).

For the player Race `villager` (`crates/server/content/definitions/races.ron`
and `data/content/definitions/races.ron`, identical slot lists, lines
14-27) the 12 slots are, in order:

```
Head, Body, Legs, Feet, Hands, Hand 1, Hand 2, Waist, Back, Neck, Finger 1, Finger 2
```

`Hands` (worn, armour) and `Hand 1`/`Hand 2` (wielding) are distinct kinds.
The order is content-defined, so key on `slot` strings rather than array
index. A Race with no slots yields an empty `slots` array (`store.rs:1904-1910`).

- **`instance`**: the occupant's per-boot `EntityId` flattened as
  `(index << 32) | generation` (`feed.rs:548-550`). Valid for this boot
  only; never persisted. It is a `u64`, so in principle above JavaScript's
  2^53 safe range if the entity index ever exceeds ~2^21 — parse as a
  string/BigInt or accept the (tiny) risk. An item occupying several
  instances of one kind (a `SlotRef` carries an instance list,
  `crates/engine/src/slots.rs:75`) repeats the **same** `instance` and
  `item` in each of those slots (`store.rs:1912-1921`).
- **`item`**: `name_of(id)` — the printed name verbatim, including a
  Stack's leading count (ADR 0058 `:221-225`). **It omits the ` (kept)` and
  ` (unfinished)` markers** that the `inventory` verb appends beside the
  name (`inventory.rs:87-111` vs `feed.rs:460`), so `Char.Items.item` is
  the typeable name and not the full `inventory` line.
- Container contents are never included (`feed.rs:210-216`; test
  `150_feed_projection.rs:553-595`).

---

## 6. In-flight "push RT every second under a config option" work

**Yes — planned in detail, not yet in code.** The tracker is
`.scratch/rt-as-movement/` (map at `.scratch/rt-as-movement/map.md`), a
wayfinder map whose destination is "a decision ... plus a spec ready to
hand to an implementation effort" — "It plans; it does not build"
(`map.md:7-19`). The last four commits on `main` touch only that tracker:

- `3b46b14` Chart the way to a Round Time gauge MudForge can draw
- `8f78f91` Lock the push instants to the Round Time, not to the sweep
- `088b391` Put the Round Time cadence behind a dial, and make the lapse
  announce itself
- `8bf0e94` Put MudForge's gauge in front of a human, and it held

No source file mentions `seconds_left`, `config roundtime`, or
`maxmovement` (grep of `crates/`), and `feed.rs:523-530` still has the
`unwrap_or(0)`-only shape. Ticket 05 (write the spec + ADR amendments) is
`open`, blocked on 03, 04, 07, 08 (`issues/05-spec-and-amendments.md:3-5`).

**Decided field shape** (ticket 01, `Status: resolved`,
`issues/01-roundtime-per-second-cadence.md`):

1. **`clears_at_ms` becomes "zero or a future instant, never a past one"**
   (`:96-125`). A lapsed Round Time will report `0`, so `5200 -> 0` is a
   value change the existing diff ships — the lapse push arrives on the
   next sweep tick (up to 1 s late). Lapsed and never-acted become
   indistinguishable.
2. **`config roundtime off|extremes|active`**, an Account Preference,
   default `extremes` (`:127-157`):
   - `off`: `Char.RoundTime` **omitted from the package set entirely**.
   - `extremes`: two pushes per charge (set, then lapse via the sweep).
     Payload unchanged: `{clears_at_ms, now_ms}`.
   - `active`: a push at every whole-second crossing, phase-locked to the
     RT's end (a 5.2 s charge pushes at t = 0.2, 1.2, ..., 5.2), driven by
     a per-Session timer (`:159-219`).
3. **New field `seconds_left`, present only at `active`** (`:221-253`):
   `seconds_left = (clears_at_ms - now_ms).div_ceil(1000)`, whole seconds
   rounded up, matching the `Roundtime: N sec.` prose. Absent at
   `extremes`/`off`.
4. A separate opt-in `config movement rt|off` (default off) publishes
   `movement`/`maxmovement` on **`Char.Vitals`** as a view of Round Time
   for MudForge's stock MV gauge (`map.md:5-16, 61-79`; ticket 01 `:255-300`):
   never acted `1/1`; owed `movement = maxmovement - seconds_left` (steps
   only at `active`; binary empty/full at `extremes`); clear
   `max/max` standing until the next charge. `RoundTimeRead` gains the
   charge's span as a Rust field that stays off the wire. Ticket 08 (open)
   asks whether `maxmove` also rides.
5. `config gmcp auto|off` (ticket 06, resolved): `off` sends `IAC WONT
   GMCP` at login.

**Widget implications:** tolerate `Char.RoundTime` being absent from a
session altogether; tolerate an optional `seconds_left`; do not depend on
`clears_at_ms` staying non-zero after a lapse (today it does; after ticket
01 lands it becomes `0`); and never treat a past `clears_at_ms` as an
error.

---

## Sources

All in `D:\Projects\TextDungeonC` at `8bf0e94`:

- `CLAUDE.md`, `CONTEXT.md`, `docs/glossary/output.md`,
  `docs/glossary/character.md` (Active Effect, `:90-91`),
  `docs/glossary/action.md`
- `docs/adr/0058-the-out-of-band-feed.md` (esp. `:157-197, 443-516,
  550-567, 599-616, 653-715, 759-773, 1136-1147`)
- `crates/engine/src/feed.rs` (whole file; snapshot at `:371-539`)
- `crates/engine/src/legibility.rs:110-152, 264-466`
- `crates/engine/src/prose.rs:60-119`
- `crates/engine/src/condition.rs:47-53`, `standing.rs:51-57`,
  `stats.rs:10, 201-347`, `footing.rs:10`
- `crates/engine/src/round_time.rs:183-201, 480-513, 735-752`
- `crates/engine/src/interaction.rs:885-900, 1161-1166`
- `crates/engine/src/entity.rs:2207-2240`
- `crates/engine/src/inventory.rs:1-120`, `store.rs:1897-1940`,
  `slots.rs:75`
- `crates/engine/src/{cast.rs:328, consume.rs:347, maneuver.rs:316,
  defeat.rs:52, 260-290}`, `content/schema.rs:180-190`
- `crates/server/src/session.rs:243-303, 373-515`
- `crates/server/src/world/actor.rs:17-40, 454-497, 534-539, 646-648,
  900-945`
- `crates/server/src/durable/record.rs:203, 252`
- `crates/server/content/definitions/races.ron:14-27`,
  `data/content/definitions/races.ron:14-27`
- `crates/engine/tests/output/150_feed_projection.rs`
- `crates/server/tests/output/28_the_feed_projection_reaches_the_wire.rs`,
  `32_the_feed_push_rides_the_prose.rs`
- `.scratch/rt-as-movement/map.md`, `issues/01-*.md` through `08-*.md`
  (read only; the working tree had an uncommitted edit to
  `issues/07-what-off-leaves-on-screen.md` which was not read into this
  report)
- `git log --oneline -25` on `main`

## Unconfirmed

- **Which `races.ron` the running server loads.** The Docker image copies
  `crates/server/content` (`Dockerfile:35, 77`); `data/content` differs only
  in a rat modifier and comments. Slot lists are identical in both, so the
  slot order above holds either way, but a non-Docker launch path was not
  traced.
- **Whether a two-handed weapon actually exists in shipped content** — the
  repeated-`instance` behaviour is read from `slot_instances`' mechanics,
  not observed on the wire.
- **`entity_number` exceeding 2^53** — theoretical; no evidence entity
  indices approach 2^21 in practice.
- **Timing of the planned change.** Ticket 01 is resolved but tickets 03,
  04, 05, 07, 08 are open/in-progress; no implementation branch exists in
  the repo (`git branch -a` shows only `prototype/*`, `research/*`,
  `ticket-cleanup`). Field names (`seconds_left`, `movement`,
  `maxmovement`) are settled in the tracker but may still move before the
  ADR amendment lands.
- **The ADR 0058 "mitigation / preparation fed" claim** (`:190-197`) versus
  the code that does not feed them — reported as a doc/code discrepancy;
  not raised with the TextDungeonC maintainers.
