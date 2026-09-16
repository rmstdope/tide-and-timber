# tr-b4o.3.2 — retrospective

- **Implementer:** Cyclops
- **Date:** 2026-09-16
- **PR:** #20

## The branch-protection call the merge step relies on returns 403

**What happened.** `skills/implement-bead`, *Merging*, reads `required_status_checks.strict` from
`gh api repos/rmstdope/tide-and-timber/branches/main/protection`. The call failed with HTTP 403:
"Upgrade to GitHub Pro or make this repository public to enable this feature."

**Why.** GitHub does not offer branch protection for private repositories on a free plan, so the
setting the skill reads does not exist here.

**Cost.** None this time, because the head was not `BEHIND`. The skill reads a failed call as `strict:
true`, so every `BEHIND` head in this repository will be caught up and wait for another CI run, even
though nothing enforces it.

**Prevent by.** Declare in `.cerebro/project.conf` (or `CLAUDE.md`, *Development practices*) whether a
`BEHIND` head may merge, so implementers do not have to probe an API this plan cannot answer.

**Seen before.** None found.
