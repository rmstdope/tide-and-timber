# tr-bbl.2.2 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-18
- **PR:** #94

## The plan's snippet could not reach the plan's own pinned frame, for want of a float

**What happened.** The plan gave `WakeUp.getting_up_frame` as literal code —
`clampi(FALL_FRAMES - 1 - int(elapsed / span * FALL_FRAMES), 0, FALL_FRAMES - 1)` — and pinned
`getting_up_frame(0.6) == 3` in *The test plan*. Implemented exactly as written, it returns **4**.
`span` is `PUSH_UP_SECONDS + SIT_SECONDS`, and `0.4 + 0.8` is `1.2000000000000002`, not `1.2`, so
`0.6 / span * 8` is `3.9999999999999996` and `int()` floors it to 3, giving frame 4. The pinned value
was right and the snippet could not produce it. Worse, the same expression reached the right answer
by a *different* accumulation path: `tests/waking/waking_test.gd`, ticking `0.4` then `0.2` to the
same 0.6 s, came out 3 and passed. So the suite was green in one place and red in another for the
same input, which is what made it look like an arithmetic mistake of mine rather than a
representation limit.

**Why.** Established. Eight frames over a span built by adding two decimal constants: the step
boundaries are exact in decimal and not in binary, so a boundary sample lands a hair below the step
it belongs to and `int()` truncates to the step before. The fix is a 1e-6 nudge (`WakeUp.EDGE`)
before the truncation, which puts a boundary back on its own step. Notably the *forwards* direction
of the same fall never needed it: it divides by `FALL_SECONDS` = `2.0`, and every boundary is a
multiple of `0.25`, all exactly representable. One direction of one animation needed the guard and
the other provably cannot, which is not something either the plan or I would have predicted.

**Cost.** About 15 minutes, inside the bead — no hand-back, no CI cycle, caught by the plan's own
pinned test. A further ~10 minutes in the review loop: the delta round reasonably asked for a test
pinning the forwards boundary, and answering it properly meant measuring all five forwards boundaries
to show that no such test can exist, since `EDGE` never decides the answer there.

**Prevent by.** `skills/design-the-build`, where it asks for pinned values in *The test plan*: a
pinned value derived by real arithmetic from a span that is a **sum of decimal constants** should be
checked in floating point before it is written down, not just computed on paper. Concretely, a plan
that writes `int(elapsed / span * N)` with `span` built by addition is specifying a truncation whose
answer at a boundary depends on the binary representation of that sum — either the plan carries the
epsilon, or it should not pin a boundary sample as an expected value. tr-eg9.6.4.2's prevention
("any pinned test value must be derivable from the plan's own snippet") is the same rule; this run
is a case where it was derivable on paper and not in the machine, so the check has to be run, not
reasoned.

**Seen before.** `docs/retrospectives/tr-eg9.6.4.2.md`, first section — a plan whose literal code and
pinned expected values disagreed, resolved the same way, by implementing the pinned values and
recording the deviation. Second occurrence of that class.

## A plan asked for one test sweep and, four paragraphs later, for tests that contradict it

**What happened.** *The test plan* said to add `death`/`Death` to `man_art_test.gd`'s existing
`SHEETS` sweep, **and** listed six dedicated tests for the fall. Doing both is impossible. The
existing sweep's tests measure the standing figure — `test_his_shirt_has_no_sleeves` against
`TORSO_WIDTH`, `test_his_arms_and_feet_are_bare` on the bottom two rows of him,
`test_his_head_is_the_same_block_in_every_frame`, and `WORN` at 12 shirt / 12 trousers / 6 hair
pixels — and none of it survives him lying down. The plan's own band table says Down frame 6 has
**no shirt at all** (his torso is behind his own head), so adding `death` to `SHEETS` would have
failed a test the same plan specifies, on data the same plan supplies.

**Why.** Established, and visible in the plan's text: the sweep sentence describes
`man_art_test.gd`'s helpers slightly wrong too (it names a `_figure(image, frame_x, row)` helper the
file does not have; the real one is `_extent`). It reads as written from the *previous* bead's plan
rather than from the merged file, and the two halves of the paragraph were not checked against each
other.

**Cost.** Small — about 10 minutes, and no hand-back: the contradiction was visible before the first
failing test, because the dedicated tests' thresholds (16 hair / 10 trousers, versus the sweep's
12/12/6) only make sense as a separate sweep. It is recorded because the failure mode if it had
*not* been noticed is expensive: adding `death` to `SHEETS` first and then loosening the standing
figure's invariants to make it pass would have quietly weakened the guards on the four sheets
tr-bbl.2.1 shipped.

**Prevent by.** `skills/implement-bead` already says a current-source claim the plan relies on is
checked before its increment begins, and that is what caught this. The upstream half belongs in
`skills/design-the-build`: when a plan says "add X to the existing sweep at `<file>`", it should name
which of that sweep's assertions X satisfies — the sentence is a claim about merged code and about
the plan's own new data, and here it was false on both counts. A plan that lists dedicated tests
with *different thresholds* for the same artefact is already saying the sweep does not fit.

**Seen before.** `docs/retrospectives/tr-bbl.2.1.md`, second section, is the neighbouring lesson from
the same family: a plan generalising a rule from a subset of the frames it will be applied to. Same
family, different mechanism — that one was a measurement rule, this one a test-suite instruction.
