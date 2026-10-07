# TextDungeon HUD

A MudForge plugin that renders TextDungeonC's always-visible character state — Status, Effects, Slots — and the last page read and quest pulled up — Page, Quest — fed only by the server's GMCP Feed. Server-side terms (Condition, Footing, Focus, Round Time, Active Effect, Slot) are TextDungeonC's and are used verbatim; this glossary holds only what the widget itself introduces.

## Language

### Countdowns

**Countdown**:
A widget-side clock that drains toward an instant the Feed named (a Round Time's clear, an Active Effect's end). One concept shared by Round Time and Effects.
_Avoid_: timer, ticker

**Anchor**:
The moment a push arrived and the remaining time it carried; the Countdown drains from there on the local clock until the next push. Re-anchoring is adopting a new push's remaining in place of the old.
_Avoid_: sync, resync

**Dead-band**:
The window within which a push's remaining is close enough to the running Countdown that the push is ignored rather than re-anchored. Absorbs push jitter; a real Stack always lies outside it.
_Avoid_: threshold, tolerance, debounce

**Stack**:
A push that lengthens a running Round Time beyond its dead-band — a new charge landing on top of the old one. The bar refills to full on a Stack.
_Avoid_: extension, bump

**Clear**:
The instant a Countdown reaches zero; the Round Time bar empties on that tick and never shows `0`; the bar itself stays in place. Local Clear is authoritative — no push is waited for.
_Avoid_: expire, finish, lapse (the server's word for the same instant, seen from its side)

**Span**:
The full length a draining bar represents. For Round Time it is the remaining at the latest Stack; for an Effect it is the longest remaining ever seen for that name.
_Avoid_: total, max, duration

### Widget states

**Unfed**:
A widget that has received no Feed snapshot on the current connection — whether the world is not yet connected or the player is still at the login prompts. Shows its skeleton with empty values.
_Avoid_: empty, initial, loading

**Live**:
A widget that has received a Feed snapshot on the current connection and is still connected; its values and Countdowns are the server's.
_Avoid_: active, online

**Severed**:
A widget whose connection was lost while Live; it keeps the last-known values, Countdowns frozen where they stood, until the next connection returns it to Unfed.
_Avoid_: stale, offline, disconnected (the connection's state, not the widget's)

### Readers

**Reader**:
The Page or Quest widget: shows a document the Feed carried (`Writing.Read`, `Quest.Show`) as the server printed it, and keeps the ones before it in Recent.
_Avoid_: viewer, panel

**Recent**:
A Reader's own newest-first list of the last ten documents it was fed this connection, one per page (or contents) of a Writing, one per quest title. A document fed again moves to the head rather than appearing twice.
_Avoid_: history, log (the server's Quest Log is something else)

**On show**:
The Recent entry a Reader is displaying. A page read always goes on show; a quest goes on show when a different quest is pulled up, while a re-sent quest is refreshed in place and leaves whatever is on show alone. Only the head of a Quest Reader's Recent is kept current by the server; an older one is a snapshot as last shown.
_Avoid_: selected, current

**Turn**:
The Page Reader asking the server for the page before or after the one on show (`Page.Read`), on the side band, so no prose scrolls past and nothing is typed. It goes to the nearest page the book's contents list when they are in Recent, else to the next number. The page that answers goes on show like any page read; a refusal (`Page.Refused`) is shown over the page on show until the next click.
_Avoid_: flip, next/previous (Recent's arrows, which move through what was already read)

### Windows bar

**Windows bar**:
The widget with one button per HUD window that opens it. It only opens, never hides: MudForge tells a plugin nothing when a window is closed from its own chrome, so a toggle could not know which way to go. The bar itself is shown on every start, because MudForge cannot yet bring back a custom window the player closed.
_Avoid_: toolbar, menu

### Map window

**Plane**:
Everything one `Area.Map` carries: the cells and edges of every level of the Area the player stands in. The next `Area.Map` replaces it whole, and nothing is merged or remembered. A Delve growing, a door opening, a Depth descending and an Expedition crossing are each just a new Plane.
_Avoid_: map (the verb, the window, and the server's term), zone

**Held position**:
The newest `Area.Where` whose `here` is not on the Plane yet, kept until a Plane that holds it arrives. Only one is held. It never moves a marker: markers move only to a room that is on the Plane.
_Avoid_: pending, queued

**Level shown**:
The one level of the Plane being drawn. It is the player's level, except while Browsing. With no player position on the Plane yet, it is level 0, or the lowest level if there is no level 0.
_Avoid_: floor, layer, z (the field, not the view)

**Browsing**:
Showing a level other than the player's. It ends when the player moves (`here` changes), when a Plane for another Area arrives, or when the browsed level is gone. A member moving, or a re-sent Plane for the same Area, leaves it alone.
_Avoid_: scrolling, peeking

**No-plane reason**:
The single line a Live Map window shows instead of a drawing: no `Area.Map` this connection (not told apart from `config map off`), an Area with no cells (`rooms: {}`), or the player off the Plane (`Area.Where` without `here`). Unfed and Severed windows never show one.
_Avoid_: error, empty state, blank
