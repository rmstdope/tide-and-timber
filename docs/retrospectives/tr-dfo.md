# tr-dfo

## CI "failed" in seconds because GitHub Actions billing blocked the job

**What happened:** PR #72's `gate-full` check went red after 7s. `gh run view --log-failed` said "log not found"; only the run's annotation explained it: "The job was not started because recent account payments have failed or your spending limit needs to be increased." Other open PRs (tr-bbl.1, tr-eg9.6.3.2) failed the same way in 9–13s.

**Why:** the account's Actions billing had failed; nothing in the code.

**Cost:** one wait for the navigator to fix billing, and one re-run. No fix attempts spent.

**Prevent by:** `skills/implement-bead`, *Red CI* — when `--log-failed` finds no log, read `gh run view <run>` annotations before treating it as a test failure; a job under ~15s with no log is infrastructure.

**Seen before:** no.
