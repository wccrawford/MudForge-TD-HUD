# TextDungeon HUD

A MudForge plugin that renders TextDungeonC's always-visible character state — Status, Effects, Slots — fed only by the server's GMCP Feed. Server-side terms (Condition, Footing, Focus, Round Time, Active Effect, Slot) are TextDungeonC's and are used verbatim; this glossary holds only what the widget itself introduces.

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
The instant a Countdown reaches zero; the Round Time bar vanishes on that tick and never shows `0`. Local Clear is authoritative — no push is waited for.
_Avoid_: expire, finish, lapse (the server's word for the same instant, seen from its side)

**Span**:
The full length a draining bar represents. For Round Time it is the remaining at the latest Stack; for an Effect it is the longest remaining ever seen for that name.
_Avoid_: total, max, duration
