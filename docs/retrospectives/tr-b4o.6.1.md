# tr-b4o.6.1 — retrospective

- **Implementer:** Wolverine
- **Date:** 2026-09-16
- **PR:** #27

## CI never started, and "no checks reported" ran a CI wait into its timeout

**What happened.** After the review, I waited for CI with a loop polling `gh pr checks 27`. It printed "no checks reported" until the 590 s tool timeout. Meanwhile tr-b4o.3.2 and tr-b4o.5.3 had merged, both editing `beach.gd`, `beach.tscn` and `project.godot`. The PR had become `DIRTY`, so GitHub started no `pull_request` run.
**Why.** GitHub starts no `pull_request` workflow run for a head that conflicts with main. I went into the CI wait without first checking whether the PR could merge, because nothing had been pushed since the PR was opened.
**Cost.** About 10 minutes of wall-clock, and one killed background command.
**Prevent by.** In `skills/implement-bead`, *Merging*: run the merge-state check before *every* CI wait, and treat "no checks reported" as a conflict, not as pending.
**Seen before.** tr-b4o.5.3.

## One of the plan's cell calculations was wrong, so a scene test could not pass as written

**What happened.** The plan's `test_e_while_placing_does_not_take_things` puts him at `cell_base((88,13)) + (-16,-2)` and says that is cell (87,12). It is (1400,222), which is cell (87,13), so the RIGHT-facing outline covers the driftwood and is red. I changed the test to face LEFT and recorded the change in the PR body.
**Why.** The plan's arithmetic was not checked by running it: `cell_base` is the bottom of the cell, so -2 px stays in the same row.
**Cost.** One extra gate run, about 3 minutes.
**Prevent by.** In `skills/design-the-build`, *The test plan*: evaluate every cell or pixel position a scene test depends on with `BeachLayout` in a headless one-liner before writing it in.
**Seen before.** none found.
