# tr-asx.2 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-17
- **PR:** #34

## The fast gate hung, with no output, on a test that awaits while the tree is paused

**What happened.** In `tests/autosave/autosave_test.gd`, `test_enter_try_again_fails_and_shakes` pauses the tree (as the save-failed box does) and then calls `await await_millis(400)`, as the plan specified. `scripts/gate-fast` stopped at that test with no error, and I had to kill the gdUnit4 process by hand. Changing the wait to `await get_tree().create_timer(0.4, true).timeout` fixed it.
**Why.** gdUnit4's `await_millis` uses a timer that stops while the tree is paused. The wait therefore never finishes, and no gate timeout catches it.
**Cost.** About 12 minutes: a ten-minute tool timeout waiting on the hung gate, then another gate run.
**Prevent by.** Add a trap to `.cerebro/traps.md`: never `await_millis` or `await_idle_frame` while `get_tree().paused` is true; use `get_tree().create_timer(s, true)`. Planners writing tests for anything that pauses the tree should follow it too.
**Seen before.** none found

## A test on main pinned d-pad left/right as unbound, so the rebase went red

**What happened.** tr-eg9.1 merged `tests/input/gamepad_bindings_test.gd` while this PR was in review. Its `test_unused_pad_inputs_bind_nothing` and `test_by_position_a_is_bottom` pin the whole pad map. They conflicted with this bead's planned `menu_left`, `menu_right` and `menu_cancel` bindings. Git merged cleanly and only the gate caught it.
**Why.** Two beads planned in parallel both own the pad map, and neither plan named the other.
**Cost.** One rebase, one gate run and a delta review round.
**Prevent by.** A plan that adds an input action should name `tests/input/gamepad_bindings_test.gd` under files to change (`skills/plan-bead` or the traps file).
**Seen before.** none found
