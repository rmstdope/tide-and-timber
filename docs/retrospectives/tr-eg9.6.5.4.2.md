# tr-eg9.6.5.4.2 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-18
- **PR:** #99

## A Label's stale minimum width silently clamped the narrower box, and the plan's trap list warned only about height

**What happened.** With `AUTOWRAP_WORD_SMART` set and `size = Vector2(72, 16)` assigned in the same
`_layout()` call, the cost label came back 104 units wide — the unwrapped string's width — so it
never wrapped and the list stayed 88 tall instead of 145. `Control.set_size` clamps to
`get_combined_minimum_size()`, and that minimum was still the pre-autowrap one, because the Label had
not re-shaped yet. Only a scratch test printing `get_combined_minimum_size()` showed it; the
assertion failures on their own read as "the wrap counter is broken", which sent me looking in the
wrong place first.

**Why.** Established. Setting `autowrap_mode` marks the Label's shaping dirty but does not recompute
the minimum size before the next `set_size` in the same call. `src/hud/spoken_line.gd:48` already
carried the fix and the comment for exactly this — `update_minimum_size()` after every
`autowrap_mode` change — so the project had solved it once before and the knowledge sat in one file
rather than in the plan or a trap list.

**Cost.** About 25 minutes: one wrong hypothesis about `wrapped_lines`, one scratch debug suite
written and deleted, two extra single-suite runs.

**Prevent by.** The bead's *Known traps* section warned that a font-size override lags one frame for
`get_line_height()` and `get_minimum_size()`, and told me to measure through the font — which I did,
and which was not enough, because the lag also bites the *write* path through `set_size`'s clamp.
Planners writing a Godot layout bead that changes `autowrap_mode` or a font size and then assigns
`Control.size` should name `update_minimum_size()` and cite `src/hud/spoken_line.gd:48`, the way they
already cite the read-path trap.

**Seen before.** none found.

## The plan's expected `list.size` was the unframed size for the three cases where the list scrolls

**What happened.** `test_largest_ui_and_text_wraps_the_cost` asserted `list.size == Vector2(156, 145)`
as the plan's geometry table gives it, and got `(156, 88)`. At UI Largest with Text Largest the grown
list is 145 units tall at scale 2, taller than the screen, so `frame()` scrolls it and `size` becomes
the framed window; `list_size()` is the whole list. Three of the nine size pairs in the table are in
that position.

**Why.** Established. The plan's table was computed as layout geometry and `list.size` was used as
the name for it, but `_place()` ends in `_frame()`, which is tr-eg9.6.4.5.1's owner of the final
`size`. The plan's own scene test asserted only `size.x` for the same case, so the table and the
scene test disagreed with each other.

**Cost.** About 10 minutes and one extra suite run, once the first symptom was understood.

**Prevent by.** A geometry table in a plan for a view that can scroll should say which function each
column is read from — `list_size()` for the laid-out box, `size` for what survives framing — rather
than naming one field for both. The tests now assert `list_size()` and `scrolls` for those three
pairs.

**Seen before.** none found.
