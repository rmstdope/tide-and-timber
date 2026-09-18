# tr-eg9.6.5.4.3 — retrospective

- **Implementer:** Rogue
- **Date:** 2026-09-18
- **PR:** #102

## The plan's own layout pseudocode drew the box larger than Text size Normal, and only the review caught it

**What happened.** The plan gave `choose_layout` as literal code: walk `n` from `roundi(total * k)`
down to `roundi(ui * k)`, returning the first rung that fits. Built exactly as written, it passed
every test the plan listed. The cold-read review then pointed out the floor is `rel 1.0` only when
`ui * k` is whole. Pinning that showed a worse case than the review stated: at Text size **Normal**
with `ui 5/3, k 1`, the loop *starts* at the rounded-up rung and draws `rel 1.2`, larger than Normal,
which the bead's binding split decision forbids. The same plan's panel-width sum
(`hw + RING_GAP + RING_SIZE`) also left the ring 3 units off the plank at `rel 2, ui 1`, because the
hold row is centred on 160 and the ring hangs off one side; the plan's worked number for that test
(`panel.size.x == 296`) had been reasoned from `"Press a new button"` while the test it names feeds
`"Press a new key"`.

**Why.** The plan's pseudocode and arithmetic were not executed before being filed. Its test sweep
for the floor (`test_text_normal_always_fits`) exercised `layout_at` at a fractional `ui`, but never
`choose_layout` there, so the rounding path had no test that could go red.

**Cost.** One extra review round and one fix commit (`d903d39`), plus one gate run spent probing
which rungs fit. No hand-back. Had the review not asked, a player on a window whose `k` makes
`ui * k` fractional would have seen the waiting box larger at Text size Normal than before.

**Prevent by.** In `skills/design-the-build`, *The test plan*: when a plan gives a function as
literal code, it names a test that calls **that** function (not only its helpers) at every input
the plan says must hold an invariant — here `choose_layout` at a fractional `ui * k` — and runs the
code once headless before filing, checking each worked number against the input its test actually
feeds.

**Seen before.** `tr-b4o.6.1` (a plan's cell arithmetic wrong, not run) and `tr-bbl.2.2` (a plan's
snippet could not reach its own pinned value). Third instance of plan arithmetic or literal code
that was not executed before filing.
