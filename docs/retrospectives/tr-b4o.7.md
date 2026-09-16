# tr-b4o.7 — two inventory.add calls in one scene test fail the gate with orphan nodes

## What happened
All tests in `tests/night/collapse_scene_test.gd` passed, but `scripts/gate-fast` exited 101. gdUnit4 reported "Detected 2 possible orphan nodes" after one test, which added three kinds of item with synchronous `inventory.add` calls.

## Why
`Beach` shows a `RisingLine` ("+n Kind") on every add. `RisingLine.show_over` replaces the previous line with `remove_child` followed by `queue_free`. The replaced node is out of the tree until the end of the frame, so a test that adds twice in a row and never yields leaves one orphan for each replaced line.

## Cost
About 15 minutes, and four scratch suite runs to bisect it.

## Prevent by
A scene suite that adds more than one item in a row should `await await_idle_frame()` before it ends. The alternative is for `RisingLine.show_over` to free the old line straight away instead of `remove_child` plus `queue_free`. This could go in `.cerebro/traps.md`.

## Seen before
No.
