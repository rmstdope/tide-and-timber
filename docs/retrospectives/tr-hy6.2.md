# tr-hy6.2 — retrospective

## A clean rebase left a duplicate `var debug` that would not parse

### What happened
Sibling pages tr-hy6.4 and tr-hy6.3 merged while this PR was open. Each one added a `var debug: DebugMenu = %Pause.debug_menu()` block to the end of `_ready` in `src/intro/intro.gd` and `src/waking/waking.gd`, and this bead added its own. Git reported a conflict in `waking.gd` only. It merged `intro.gd` without complaint, leaving two `var debug` declarations. Every intro suite then failed to parse, and GitHub showed the PR as `CONFLICTING DIRTY` twice.

### Why
Every page child of tr-hy6 appends rows through the same few lines in each scene's `_ready`. That makes those lines a hot spot for parallel children, and git cannot tell that two declarations with the same name break the script.

### Cost
Two local rebases, one extra full gate run, and one extra review round, because the seam tests had to move after Items gained its own rows.

### Prevent by
When a bead's plan has several parallel children adding rows to the same scene's `_ready`, the planner could name the single `if debug != null:` block that every child adds to. After any rebase that touches `intro.gd` or `waking.gd`, run the gate before pushing, even if git reported no conflict.

### Seen before
Nothing like it in `docs/retrospectives/`.

## The fast gate went red in `title_continue_test` again

### What happened
After the second rebase, `scripts/gate-fast` failed 5 tests in `tests/title/title_continue_test.gd`, and the save text it read back was garbled (`"0.41"`). The same suite passed on `origin/main` right afterwards, and it passed on the branch when rerun.

### Why
Not established. It matches the likely cause in tr-eg9.6.6: worktrees share one `user://` directory.

### Cost
Two extra suite runs.

### Prevent by
The same as tr-eg9.6.6: give each worktree's gate its own `user://` directory.

### Seen before
`docs/retrospectives/tr-eg9.6.6.md`.

## CI did not start because of billing

### What happened
The `gate-full` job on `e1dfad5` did not start. The annotation said "recent account payments have failed or your spending limit needs to be increased". The navigator fixed the billing, and the same run then passed.

### Why
GitHub Actions billing on the account.

### Cost
One wait on the navigator.

### Prevent by
Read the annotations in `gh run view <id>` before `--log-failed`. A job with no steps means nothing ran, so there is no log to read.

### Seen before
Nothing like it in `docs/retrospectives/`.
