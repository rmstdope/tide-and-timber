# tr-asx.3 — the plan named `_unhandled_input` on a scene root for the third time

## gdUnit4 handled every simulated key twice on the title screen again

**What happened.** The plan moved `TitleScreen` from `_unhandled_key_input` to `_unhandled_input` so the controller's A and B would reach it. That broke 42 title tests: Down moved twice and wrapped back, and Enter on Quit called quit four times. The fix was to handle input in `_input` instead, which `Autosave`'s box already uses.

**Why.** `GdUnitSceneRunnerImpl._handle_input_event` (`addons/gdUnit4/src/core/GdUnitSceneRunnerImpl.gd:572-586`) pushes each event through `Input.parse_input_event` and then also calls `_unhandled_input` directly on the scene root.

**Cost.** About ten minutes of confusion, plus a deviation the reviewer flagged.

**Prevent by.** A `.cerebro/traps.md` entry, which the planner reads: "never handle input in `_unhandled_input` or `_gui_input` on the root of a scene that `scene_runner` loads; use `_input` or `_unhandled_key_input`." The retrospectives alone have not reached the planner.

**Seen before.** `tr-b4o.1.md` and `tr-b4o.2.1.md`, the same symptom both times.

## `scene_runner(node)` does not free the node it is given

**What happened.** `tests/waking/waking_resume_test.gd` instantiates the scene, sets `resume_data`, and hands the node to `scene_runner`. All 5 tests passed with 1555 orphans, which would have failed the gate.

**Why.** The runner frees only a scene it loaded from a path (`_scene_auto_free`, `GdUnitSceneRunnerImpl.gd:59,99`). The plan cited `scene_runner` accepting a `Node` but not that the test must free it.

**Cost.** One extra suite run. The fix was `auto_free(...)` around the instance.

**Prevent by.** The same traps entry: "wrap a node passed to `scene_runner` in `auto_free`."

**Seen before.** Nothing like it.
