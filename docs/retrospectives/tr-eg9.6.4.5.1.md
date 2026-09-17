# tr-eg9.6.4.5.1 — `title_continue_test` again, and this time it fails on `main` too

## What happened

`scripts/gate-fast` went red twice on this branch in `tests/title/title_continue_test.gd`, in code
the bead never touched. The clearest failure was
`test_older_save_continues_with_nothing_said`, which compares the `meta.json` text before and after
Continue and printed two strings that are **character-for-character identical** in the report:

```
Expecting:
 '{"game_version":"0.0","version":0}'
but was
 '{"game_version":"0.0","version":0}'
```

Running that one suite in isolation, four times in each checkout:

- in this worktree: 2 failures, then 9 failures + 2 errors, then 1 failure, then green;
- in the shared `main` checkout, unmodified: green, green, green, then 1 failure.

So it is not branch-specific and not caused by this change. Repeated whole-gate runs on the branch
were green (1593/1593) on three of five attempts.

## Why

Not established, but the same cause as tr-eg9.6.6 and tr-hy6.2, with one piece of evidence they did
not have: **it reproduces on an unmodified `main`**. Every worktree of this project shares one Godot
`user://` directory, so any other fleet session running `scripts/gate-fast` at the same time writes
the same `user://test_saves` tree. The identical-looking strings above are what a partially rewritten
file looks like once the difference is in bytes the report renders the same way, and the
`ERROR: Could not create directory: 'user://test_saves/blocked/slot'` lines in the same run are the
same collision showing plainly.

## Cost

About twenty minutes: five whole-gate runs and eight isolated suite runs across two checkouts to
establish that the failure was pre-existing and not mine, plus the judgement call not to "fix" it.

## Prevent by

Giving each gate run its own user data directory, so concurrent fleet sessions cannot share
`user://`. `scripts/gate-fast` passes no `--user-data-dir`; adding one derived from the worktree
(alongside the existing `--path "$repo"`), or setting `application/config/use_custom_user_dir` per
run, would isolate them. This is the third sighting and the first with cross-checkout evidence, so
it is a bead for the navigator to rank, not something to change from an implementation pass.

## Seen before

Yes, twice: `docs/retrospectives/tr-eg9.6.6.md` and `docs/retrospectives/tr-hy6.2.md`, both recording
the same suite with garbled save text and both closing "not established".
