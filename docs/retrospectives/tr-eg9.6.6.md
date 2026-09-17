# tr-eg9.6.6 — the fast gate went red locally in `title_continue_test`, in code the bead never touched

## What happened
The first `scripts/gate-fast` run after the green step reported 5 failures in `tests/title/title_continue_test.gd`. The save file text it read back was garbled, e.g. `{"game_version": "0.01","version":0 1}` and `"0.40"`/`20`. A rerun without changes was fully green (1042/1042).

## Why
Not established. The garbled text looks like two writers to the same file at once. The likeliest cause is another fleet session's gate writing the same `user://` save while this one ran, since every worktree shares one Godot user-data directory for this project.

## Cost
One extra full gate run (about 2 minutes) and reading the XML report.

## Prevent by
`scripts/gate-fast` could point `user://` at a per-worktree directory, e.g. a per-run `--user-data-dir` or an app-name override, so parallel implementers' suites don't share save files.

## Seen before
Nothing like it in `docs/retrospectives/`.
