# tr-eg9.4 — pause board

## A suite that pauses the tree hangs the gate on gdUnit4's `await_millis`

**What happened.** The first gate after adding `tests/pause/beach_pause_test.gd` never finished. It stopped at `test_the_clock_stands_still_while_paused`. Later, the intro suites hung the same way in `gamepad_intro_test.gd`'s `_tap`, which ends with `await_millis(50)`. The gate prints no timeout; it just sits.

**Why.** gdUnit4's `await_millis` waits on a timer that stops with `get_tree().paused`, so any wait taken while the board is open never returns.

**Cost.** About 12 minutes of gate time, over two hung runs.

**Prevent by.** In any suite that can pause the tree, wait with `await get_tree().create_timer(seconds, true).timeout`, never `await_millis`. This could go in the plan template's *Known traps*, next to "a paused tree leaks between suites".

**Seen before.** Yes, `docs/retrospectives/tr-asx.2.md`, the same hang in `autosave_test.gd`. Its proposed trap in `.cerebro/traps.md` has not been added, and this plan's tests still said `await_millis`. That is a second occurrence.

## A nested enum named like a global class does not parse

**What happened.** The plan's `enum Item` inside `PauseMenu` failed with `Value of type "PauseMenu.Item" cannot be assigned to a variable of type "Item"`, because `src/items/item.gd` declares `class_name Item`. The enum was renamed `Plank`.

**Why.** In GDScript's type hints, a global `class_name` wins over a nested enum of the same name.

**Cost.** One failed gate run, a few minutes.

**Prevent by.** Planners grep `class_name <Name>` before naming a nested enum or class in a plan.

**Seen before.** No.
