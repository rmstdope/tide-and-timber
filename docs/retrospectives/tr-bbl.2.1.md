# tr-bbl.2.1 — retrospective

- **Implementer:** Storm
- **Date:** 2026-09-17
- **PR:** #89

## One failing scene test made four unrelated title tests fail with it

**What happened.** `scripts/gate-fast` reported 19 failures: the one I expected
(`tests/beach/beach_scene_test.gd::test_shift_runs_at_double_pace_with_puffs`, which this bead
changes on purpose) and four in `tests/title/title_continue_test.gd` that this bead does not touch —
`test_keep_my_island_by_click`, `..._by_enter`, `..._by_escape` and `test_wraps_over_four`, all
reporting "Continue should not be highlighted". Run alone, `title_continue_test.gd` passed all 36
cases. A throwaway clone of `main` was green, so the failures were mine, and for a while it looked
as though the man's sprite change had somehow reached the title screen.

**Why.** Established. `test_shift_runs_at_double_pace_with_puffs` presses `run` and `move_right` and
releases them in its **last two lines** (`beach_scene_test.gd:219-220`). When an assertion before
those lines fails, the test aborts and the releases never run, so both actions stay held in the
shared `Input` singleton for every suite that runs afterwards — including the title suite, whose
menu navigation then behaves as though a key were down. One genuinely failing test therefore
manufactured four fake failures in a suite six directories away, and the gate's summary gave no hint
which was the cause and which the symptom.

**Cost.** About 25 minutes: two full gate runs (166s each), a `git clone` of `main` plus a full
import and gate there to establish a baseline, and the wrong hypothesis that the sprite change had
leaked into the title screen. No CI cycles and no hand-back — it was found and understood locally.

**Prevent by.** Releasing held actions in teardown rather than in the body of the test, so an
aborted test cannot leak them: an `after_test()` in `tests/beach/beach_scene_test.gd` calling
`runner.simulate_action_release()` for `run` and every move action, or `player.release_held()`, which
already exists for exactly this purpose (`src/player/player.gd:53`). The same applies to every suite
that presses an action and releases it at the end of the body — `gathering_test.gd` and
`click_walk_test.gd` have the same shape. Worth a Refactoring bead across the suites rather than a
fix inside this one, since the leak is a property of the pattern, not of this test.

**Seen before.** None found. `grep -rl` over `docs/retrospectives/` for held input, leaked actions,
`simulate_action_release` and cross-suite interference returned nothing describing this.

## A planned art rule broke on the one animation it was not measured against

**What happened.** The plan placed each band of clothing by shifting a fixed rectangle with the
frame's bounding-box top (for the head) or bottom (for the feet). It was written against
`Idle_<facing>` frame 0 and works there. On `Collect`'s deep crouch it fails: the head-anchored shirt
slides down onto the folded legs and repaints them before the feet-anchored trousers ever see skin,
so `Collect_Down` frames 2 and 3 came out with a white shirt over the knees and **0 trouser pixels**.
The planned per-frame pixel floors caught it, but only after the art had been generated and looked
at.

**Why.** Established. The rule was derived from measurements of one animation's first frame and the
bounding boxes of the others, which capture how far the figure moves but not that a crouch compresses
the body while leaving the head its full size. Two anchors cannot express that; the head and the
torso do not fall together as the plan assumed.

**Cost.** About 40 minutes of measuring and prototyping, inside this bead — no hand-back and no CI
cycles. The replacement (a rigid 14-row head zone and a body zone that stretches) reproduces the
plan's rectangles exactly on standing frames, so nothing already agreed had to be renegotiated.

**Prevent by.** Prototyping a per-pixel art rule against **every** frame it will be applied to
before writing it into a plan or a tool — here, a ~40-line script reading the pack's PNGs reported
all 96 frames' violations in one run and made each tuning iteration a second instead of a 30-second
Godot round trip. Worth naming in `skills/design-the-build` where it says to measure the source: a
rule measured on one frame of one animation is a hypothesis, and the plan should say which frames it
was checked against. Two of the review's findings were the same lesson one level up — the invariants
I wrote to guard the rule (`at least 8 skin pixels below the shirt`, `HEAD_ROWS := 14`) were also
generalisations from a subset, and measuring them across all 96 frames showed the first reaching 0 on
a run frame and the second holding in only 68 of 72.

**Seen before.** None found.
