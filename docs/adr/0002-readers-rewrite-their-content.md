# The reader widgets rewrite their content whole

The Status, Effects and Slots widgets set their content once and flip a fixed pool of rows with bound values (wayfinder #6), because they tick and a rebuild would flicker and drop bindings. The Page and Quest widgets show documents of any length whose lines are lists of roled Spans with hanging indents (`Writing.Read`, `Quest.Show`, ADR 0058 on the server), and a pool of lines times Spans times keys would be large and still clip. So `lib/pages.lua` and `lib/quests.lua` each return their widget's whole markup from `html()`, and the wiring sets it as `content` (after the styles in `src/widgets/reader.html`) on every change. The Windows bar's `lib/bar.lua` is built the same way but never changes, so it is set once. None of them ticks: a change is a feed push or a click, so a rebuild is rare and nothing runs inside the widget to be stopped by it.

## Consequences

- Fed text reaches markup only through `doc.escape`, and a Span's role only through a fixed list of the server's twelve Role names, since content is HTML rather than bound text.
- Clicks come back through `data-mud-action` / `data-mud-data` and the widget's `action` event; the libs' `act()` answers what to send, a command typed for the player or a side-band request (the Page's `Page.Read`, which prints nothing), so navigation is plain `assert` tests.
- A rewrite resets the widget's scroll to the top, which is wanted for a new page and accepted for a Recent click.
- Bound values are not used in these widgets, so the lost-first-push re-push (#6) does not apply to them.
- Every widget takes its own font (its settings cog) from `getWidgetFont` and sizes in `em` from it; MudForge does not carry that font into an html widget's content. The readers and the bar write it into their markup; the bound widgets take it as bound style keys on their root. No event announces a font change to an html widget, so the tick re-reads every widget's font once a second and re-applies only a changed one.
