# tr-b4o.5.3

## A conflicting pull request gets no CI run, and the CI wait hung on it

**What happened:** PR #23 was opened while tr-b4o.3.2 (which also edits `src/player/player.gd`) merged. GitHub started no `pull_request` run for the conflicting head, so `gh pr checks 23` printed "no checks reported". My CI-wait loop polled for a pending or finished check that never came, and hit the 590 s tool timeout.

**Why:** GitHub Actions does not run `pull_request` workflows for a PR whose merge commit can't be built (a conflict). `mergeable` read `UNKNOWN` at the time, not `CONFLICTING`.

**Cost:** about 10 minutes and one wasted wait call.

**Prevent by:** in `skills/implement-bead`, *Merging*: run the merge-state check before *every* CI wait, not only after a push that raced main. Treat "no checks reported" for over a minute as a sign of a conflict, and rebase.

**Seen before:** no.

## The plan's out-of-reach test clicked the item bar

**What happened:** `test_click_deep_water_stops_at_edge_cant_reach` in the plan clicked world (1480, 330) with the man at (1480, 244). On screen that is y≈176, which lies on the item bar (y 157 and below), so the bar took the click and the walker never saw it.

**Why:** the plan checked the world geometry, but not where the point lands on the 320x180 screen under the HUD.

**Cost:** one debugging round. The test now clicks (1480, 300).

**Prevent by:** in `skills/design-the-build`, the test plan: for every click test point, check that its screen position misses the HUD.

**Seen before:** no.
