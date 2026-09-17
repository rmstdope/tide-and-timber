# tr-hy6.5 — retrospective

- **Implementer:** Storm
- **Date:** 2026-09-17
- **PR:** #69

## CI's gate-full never started: account billing

**What happened.** `gate-full` on PR #69 reported `fail` in 17s with no steps and no log (`gh run view --log-failed`: "log not found"). The check run's annotation said: "The job was not started because recent account payments have failed or your spending limit needs to be increased." Main's own runs for #68 and tr-hy6.3 had failed the same way.
**Why.** GitHub Actions billing on the account; fixed by the navigator.
**Cost.** One question to the navigator and the wait for billing to be fixed, then an `update-branch` and a full CI cycle.
**Prevent by.** When a red job has no steps, read `gh api repos/<owner>/<repo>/check-runs/<job id>/annotations` before counting it against the Red CI budget; *Red CI* in `skills/implement-bead` could name that check.
**Seen before.** none found.

## The branch-protection query returns 403 on this plan

**What happened.** `gh api repos/rmstdope/tide-and-timber/branches/main/protection` answered HTTP 403 "Upgrade to GitHub Pro or make this repository public", so whether `strict` applies can never be read here, and every merge is catch-up-first.
**Why.** Branch protection is not available on a private repository on the free plan.
**Cost.** An `update-branch` and a CI cycle per PR, whether or not needed.
**Prevent by.** A declared answer in `.cerebro/project.conf` that *Merging* reads before calling the API.
**Seen before.** tr-b4o.3.2.

## A parse error in a new suite hangs gdUnit under `-d` with no remote debugger

**What happened.** Running one suite with `godot --headless -d --script …GdUnitCmdTool.gd` (no `--remote-debug`) against a test naming a class not yet written stopped at "Debugger Break, Reason: Parser Error" and never exited; the tool call timed out after 400s.
**Why.** `-d` enters the local debugger on a script error and waits for input.
**Cost.** About seven minutes.
**Prevent by.** Run single suites with the exact flags `scripts/gate-fast` uses (`--remote-debug tcp://127.0.0.1:0`), or give `gate-fast` an optional suite argument.
**Seen before.** none found.
