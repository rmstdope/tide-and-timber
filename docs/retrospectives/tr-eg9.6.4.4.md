# tr-eg9.6.4.4 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-17
- **PR:** #84

## `simulate_mouse_move` takes window coordinates, not the 320x180 canvas coordinates every rect is in

**What happened.** Two new tests drove a pointer at a plank scrolled out of its clip, to prove a hidden
plank is out of the pointer's reach. Both passed `get_global_rect().get_center()` — canvas
coordinates — straight to `runner.simulate_mouse_move()`. The suites run a 640x360 window over the
320x180 base with `CONTENT_SCALE_MODE_CANVAS_ITEMS`, so the viewport's final transform is 2x and
every point was delivered at half its intended place. On the title, (160, 172) arrived at (80, 86),
inside New Game, and hovered it; I read the resulting highlight change as gdUnit synthesising a menu
step and wrote that into a PR comment. On the Paused board the halved point landed on nothing, so
that test passed while measuring nothing at all.

**Why.** `simulate_mouse_move` is documented in window space; `get_global_rect()` and
`get_global_transform_with_canvas()` are canvas space. Nothing in either name says which, and the two
agree exactly when the window is 320x180, which is the size most suites in this repository use. These
two suites resize to 640x360 to reach Large and Largest, so they are among the few where the
factor is not 1.

**Cost.** About 40 minutes across four probe runs to attribute the highlight change, a wrong
explanation posted to the PR, and one extra review round and CI cycle (about 6 minutes) to correct
it. The review sub-agent caught it by noticing the two sibling tests disagreed; I had accepted
"that looks like gdUnit" and would have merged a test that measured nothing.

**Prevent by.** A `.cerebro/traps.md` entry the planner reads: "`simulate_mouse_move` /
`simulate_mouse_button_pressed` take window coordinates. A suite that resizes the root away from
320x180 must convert: `get_tree().root.get_final_transform() * canvas_point`. Emitting `gui_input` on
the node instead tests the handler, not whether the pointer can reach it." The conversion helper is
`_to_window()` in `tests/pause/pause_scroll_test.gd` and `tests/title/title_scroll_test.gd`.

**Seen before.** None found for the coordinate spaces. `tr-asx.3` and `tr-b4o.1` are the neighbouring
`scene_runner` traps.

## A second `scene_runner` inside one test leaks a scene that changes an unrelated suite's layout

**What happened.** To cover a four-plank Paused board I built a second waking scene inside one test,
on top of the one `before_test` already made, because `Pause.debug_tools` must be set before the
scene is built. Both suites passed alone. Run in one process,
`tests/title/title_scroll_test.gd::test_moving_down_scrolls_and_wraps` failed with scroll offsets 17
and 38 instead of 9 and 30.

**Why.** The runner frees only the scene it loaded itself, so the `before_test` waking scene stayed in
the tree with its item bar. `HintLift` lifts a `MenuStrip` above whatever item bar it finds, so the
*title's* strip lifted 16 units it should not have, `MenuStrip.screen_top()` returned 136 instead of
152, and the whole scrolling band shrank by 8. A leaked scene from one suite silently re-laid out
another suite's screen.

**Cost.** One full gate run (about 3 minutes) plus the isolation runs to prove each suite passed
alone, and one extra commit and CI cycle. It would have been much worse merged: the two suites only
collide in the full gate, so it would have read as an intermittent CI failure in a file the bead
barely touched.

**Prevent by.** Same `.cerebro/traps.md` entry as `tr-asx.3`'s, extended: "never build a second scene
inside a test whose `before_test` already built one — the first is not freed. When a suite needs a
different static (`Pause.debug_tools`), give it its own suite file that sets it in `before_test`."
`tests/pause/pause_scroll_four_planks_test.gd` is the shape to copy.

**Seen before.** `tr-asx.3` — `scene_runner` frees only what it loaded from a path. Same root cause,
different symptom: there it was orphan nodes, here it was another suite's geometry.

## The `title_continue_test` gate flake reproduced on unmodified `main`

**What happened.** The first full `scripts/gate-fast` run after my first increment reported failures
in `tests/title/title_box_stack_test.gd` and `tests/title/title_continue_test.gd`, neither of which
my diff touched. To find out whether I had caused it, I cloned `main` into the scratchpad and ran the
full gate there twice: the second run failed with exactly the same two tests
(`test_up_down_do_nothing_side_by_side`, `test_start_over_fades_to_a_new_game_and_keeps_the_save`).
It recurred once more on my branch later, and every other run was green.

**Why.** Not established. `test_start_over_fades_to_a_new_game_and_keeps_the_save` waits
`await_millis(1300)` on a `FADE_SECONDS` tween, so it is real-time sensitive and fails when the
machine is loaded — several fleet sessions were gating at once. That is consistent with what I saw
but I did not prove it.

**Cost.** About 12 minutes: two full gate runs on a clean `main` clone to establish it was not mine,
plus the report parsing.

**Prevent by.** These two tests want the same treatment the rest of the suite gets for time: drive
the tween through the runner rather than sleeping on it, or assert on the tween's completion signal
instead of a wall-clock budget. Until then, the standing answer is what I did — reproduce on a clean
`main` clone before believing a failure is yours.

**Seen before.** `tr-eg9.6.6` — the same suite, `tests/title/title_continue_test.gd`, red once and
green on rerun, cause not established there either. That run blamed a shared `user://` directory; the
failing test names here are different, so this may be a second, time-based flake in the same file.
Two files now name this suite.
