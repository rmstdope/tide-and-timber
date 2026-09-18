# tr-eg9.6.5.3 — retrospective

- **Implementer:** Cyclops
- **Date:** 2026-09-18
- **PR:** #100

## A Control would not shrink back when Text size went down, and the obvious fix hung the engine

**What happened.** Stepping Text size from Large back to Normal left every Settings plank at its
grown height. `lay_out` computed `plank_h` of 16, assigned `plank.size`, and reading `plank.size.y`
back on the very next line gave 20. The cells were already correct — each `GrownWords` holder
reported a fresh minimum of 12 — but the plank's own `get_combined_minimum_size()` still returned
20, so `set_size` clamped. Calling `update_minimum_size()` on the `Row` and the plank first, then
reading the minimum back, changed nothing. My first fix re-queued `_lay_out` whenever a plank had
not reached its target height; that ran
`tests/settings/controls_box_scroll_test.gd::test_size_change_while_up_refits` out of memory —
`Failed method: CanvasItem::_redraw_callback. Message queue out of memory.` and a bus error.

**Why.** Established. Godot returns the *cached* combined minimum size while a deferred minimum-size
update is pending, so a child that shrank does not reach its parents until the next frame, and
`update_minimum_size()` makes the read return stale rather than forcing a recompute. The hang was a
second cause: a plank whose words genuinely need the taller rect can never reach the target, so an
unconditional re-queue never terminates.

**Cost.** About an hour: four instrumented runs of the settings suites to find the clamp, two more
to find the non-terminating re-queue, and one crashed full-gate run.

**Prevent by.** `.cerebro/traps.md` has no entries; this belongs there as one: *a Control's combined
minimum size is a cache, and a child's shrink reaches its parents only on the next frame — never
assume `size` assigned down has taken effect in the same frame, and never re-queue a layout on
"the rect is not what I asked for" without a one-shot bound.* The bead's plan already carried a
"Containers sort on the next frame" trap; this is the shrink case it does not cover, and
tr-eg9.6.5.4 and .5 lay out the same kind of grown cells, so they will meet it.

**Seen before.** None found — `grep -rl "deferred\|message queue\|cache" docs/retrospectives/`
returned nothing.

## A measured constant in the plan was wrong, and only a scene measurement caught it

**What happened.** The plan gave `MENU_HEIGHT_WITH_SAVE := 81.0` as the title menu's Normal height
with a save. Using it, `menu_top_at` treated an ungrown menu as grown and placed it at y 78 instead
of 83, failing `test_normal_text_menu_as_before`. Measuring the scene gave 84: the planks are
21 + 18 + 18 + 18 = 75 and the `Lines` separation of 3 appears three times, which the plan's figure
omits. The other two constants in the same list, 60 and 92, were right.

**Why.** Established. The plan's other measurements were taken in a scratch project against font
metrics, which is reliable; this one was arithmetic over the scene's plank heights and dropped a
separation.

**Cost.** Small — two instrumented runs — but it would have shipped a menu 5 px out of place at
Normal if the suite had asserted only the grown cases.

**Prevent by.** When a plan hands over a constant that names a rect the scene already draws, assert
it against the scene rather than only using it: `title_text_size_test.gd` now pins all three of
`MENU_HEIGHT`, `MENU_HEIGHT_WITH_SAVE` and `MENU_HEIGHT_DIMMED` against
`%Menu.get_combined_minimum_size().y` at Normal. Worth doing for the equivalent constants in
tr-eg9.6.5.4 and .5.

**Seen before.** None found.
