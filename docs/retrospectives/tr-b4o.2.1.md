# tr-b4o.2.1 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-16
- **PR:** #18

## Esc did nothing in the scene tests: gdUnit4 delivered it to `_unhandled_input` twice

**What happened.** The plan put every input for `Intro` into one `_unhandled_input`. In
`tests/intro/intro_test.gd`, `simulate_key_pressed(KEY_ESCAPE)` left the pause box hidden, and Down in
the pause box wrapped straight back to where it started. Taps looked fine only because a press and a
release are both counted, so the duplicates cancelled out.

**Why.** `GdUnitSceneRunnerImpl._handle_input_event` sends the event through
`Input.parse_input_event` and then also calls `current_scene._unhandled_input(event)` directly.
Toggles such as pause and selection moves therefore run twice. This is the same cause that
tr-b4o.1 recorded.

**Cost.** One debugging cycle. The fix moved keys to `_unhandled_key_input` and recorded the change
from the plan in the PR.

**Prevent by.** Add this to `.cerebro/traps.md`, which planners read and which is still empty. It is
already recorded here once, and this plan repeated it: "a scene's root must not handle toggling
input in `_unhandled_input` or `_gui_input`; use `_unhandled_key_input`, or tests see every event
twice."

**Seen before.** tr-b4o.1.
