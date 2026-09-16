# tr-b4o.1 — retrospective

## gdUnit4's scene runner delivers a simulated key to `_unhandled_input` twice

**What happened.** The plan put keyboard handling in `TitleScreen._unhandled_input`. In the tests, every
`simulate_key_pressed(KEY_DOWN)` moved the highlight two steps. With only two choices this wraps back to
the start, so the wrap tests failed as if the input was never seen.

**Why.** gdUnit4 6.2.1's `GdUnitSceneRunnerImpl._handle_input_event`
(`addons/gdUnit4/src/core/GdUnitSceneRunnerImpl.gd:569-587`) sends the event through
`Input.parse_input_event` + `flush_buffered_events`, which reaches the scene through the viewport. It
*then also* calls `current_scene._unhandled_input(event)` (and `_gui_input`) directly. A root scene
that handles its own input therefore gets every simulated event twice.

**Cost.** One debugging cycle. The handler moved to `_unhandled_key_input`, which only normal dispatch
reaches, and the change was recorded as a deviation on PR #13. Joypad input (tr-eg9.2) will need a
different callback, such as `_input`.

**Prevent by.** Planners of scene-runner tests (`skills/plan-bead`, and the gdUnit4 notes a plan cites)
should not name `_unhandled_input` or `_gui_input` on the root node of a scene that
`scene_runner` loads. Alternatively, a trap entry in `.cerebro/traps.md`.

**Seen before.** No.
