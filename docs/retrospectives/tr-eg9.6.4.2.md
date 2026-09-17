# tr-eg9.6.4.2 — retrospective

- **Implementer:** Storm
- **Date:** 2026-09-17
- **PR:** #83

## A plan's literal GDScript disagreed with the values the same plan pinned

**What happened.** The plan gave `_item_extent` as the plank's rect shifted by `HEADING_TOP`
(`Vector2(position.y - HEADING_TOP, position.y + size.y - HEADING_TOP)`) and, in the sentence
directly beside it, said "for the first of `rules.items`, x is 0 … for the last, y is
`_content_height()`". Both cannot hold: the first plank sits at y 28 and `HEADING_TOP` is 8, so the
formula gives 20, not 0. Implemented literally, three Downs at Largest produced offset 90 where the
plan's own test plan pinned 116, and the test I had written from those pinned values went red. I
implemented the prose and the pinned numbers instead of the formula, and every other number in both
new suites then matched the plan exactly.

**Why.** The formula was written for content whose top is the first plank; the extent special case
that makes the heading and the trailing line reachable was described in prose and in *Decided by me*
but never folded into the code. Nothing in the plan cross-checks its snippets against its pinned
values.

**Cost.** One debug suite and two gdUnit4 runs, about ten minutes, plus the judgement call of which
half of the plan to believe.

**Prevent by.** When a plan carries both literal code and pinned expected values for the same
function, `skills/implement-bead` already says a detail the plan missed is the implementer's to
decide — but the cheaper check is upstream: `skills/design-the-build` should require that any
pinned test value in *The test plan* be derivable from the plan's own snippet, and say that where
prose and snippet disagree the pinned values govern. That is the rule I applied here.

**Seen before.** none found

## A GDScript snippet in the plan could not compile as written

**What happened.** The plan's `ScrollWindow.draw_mark` took `canvas: CanvasItem` and called
`canvas.get_theme_default_font()`. That method is on `Control`, not `CanvasItem`, so `var font :=`
failed with "Cannot infer the type of 'font' variable because the value doesn't have a set type",
and on a bare `CanvasItem` it would have failed at runtime too. I narrowed the parameter to
`Control`, which every planned caller is.

**Why.** The snippet was written from the Godot API by name rather than compiled. The plan's
*Checked on Godot 4.7.2, headless, in a scratch project* section verified the font metrics and the
clipping behaviour, but not this signature.

**Cost.** One import-and-run cycle, a couple of minutes, and a note owed to parts 3-5 of the bead,
which may have hand-drawn lists on non-`Control` canvases.

**Prevent by.** `skills/design-the-build`: where a plan already runs a scratch project to check
engine behaviour, the new class's declared signatures should be pasted into that same scratch
project and imported once, so a snippet that cannot compile is caught before an implementer takes
the bead.

**Seen before.** none found

## The plan's list of existing tests to change was short by one, and only the full gate found it

**What happened.** *Existing tests to change* named four call sites. After both increments the four
were green, but `scripts/gate-fast` failed on
`tests/display/ui_size_menus_test.gd::test_a_grown_row_is_where_it_is_drawn`, which pinned the
hard-coded screen point `Vector2(160, 32)` for the stacked Text size row — a point that framing the
panel legitimately moves. The suite is under `tests/display/`, which the plan listed only under
"existing suites that must stay green with no other change".

**Why.** The plan located affected tests by the node paths and rects they assert. This one asserts a
screen coordinate reached through the pause layer's transform, so no grep for `%Panel` or
`Panel/Heading` finds it.

**Cost.** One full `scripts/gate-fast` cycle (about four minutes) plus the fix, and then a blocking
review finding, because my first fix derived the expected point from the row itself and made the
assertion unfalsifiable. Two extra review rounds followed from that one mistake.

**Prevent by.** Two things. For planners (`skills/design-the-build`): a plan that moves a rectangle
on screen should grep for on-screen coordinate literals as well as node paths — in this repo,
`Vector2(` inside `tests/display/` and any suite using `get_global_transform_with_canvas()`. For
implementers: when a layout change breaks a test that pins a screen coordinate, recompute the
coordinate by hand from the new layout and pin the new literal. Deriving it from the node under test
turns the assertion into an identity that can never fail, which is what the review caught.

**Seen before.** none found
