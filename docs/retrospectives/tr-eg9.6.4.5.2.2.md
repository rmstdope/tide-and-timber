# tr-eg9.6.4.5.2.2 — the shared `user://` collision, this time reported as a blocking review finding

## What happened

The review sub-agent's cold read returned one **BLOCKING** finding: `scripts/gate-fast` was
intermittently red on this head (2 of 5 runs) and green on `main` (4 of 4), failing in
`tests/title/title_box_stack_test.gd::test_up_down_do_nothing_side_by_side` and
`tests/title/title_continue_test.gd::test_new_game_asks_first` / `::test_box_highlight_moves`, all
of the shape "the Start over box never opened". It recommended against merging and named two
suspected leaks out of the new `tests/title/title_box_scroll_test.gd`.

Neither lead was the cause. The gate ran 5/5 green for me on the same head. The failures are the
already-known shared-`user://` collision: the reviewer ran its five gates while my own gate runs
were in flight, and every Godot process for this project resolves to the same
`~/Library/Application Support/Godot/app_userdata/Tide and Timber`, so the title suites' fixtures
under `user://test_saves` — which `after_test` wipes at the shared root — were deleted out from
under each other.

Two concurrent `res://tests/title` runs reproduce it on demand:

- on this head: 20 and 56 failures, including both suites the reviewer named;
- on `main` (`07708e3`), in a clean clone untouched by this PR: 35 and 52 failures, the same shapes.

That `main` fails identically is what settles it: the collision is pre-existing and the change is
not implicated.

## Why

The known cause (see *Seen before*), reached by a new route. What is new is not the collision but
**who tripped it**: a review sub-agent is a second agent with a shell in the same checkout, and
nothing told it that running the gate concurrently — with the implementer, or with its own earlier
run — is what produces this exact failure. It then reported the result as blocking, in good faith
and with careful evidence, including a control run on `main` that happened to be serial and green.

## Cost

About forty minutes, and one whole review round. Reproducing and disproving the finding took three
serial gate runs, two concurrent title runs in the worktree and two more in a fresh clone of `main`,
plus the clone itself. The round that raised it also had to be answered in full and followed by a
delta round, which is the larger cost: a false blocking finding is not free even when it is
correctly dismissed.

## Prevent by

Telling a review sub-agent that a gate it runs must be **serial** — one Godot process against this
project at a time — because the implementer is very likely gating in the same checkout at the same
moment. I said exactly that in this bead's delta-round prompt and the round came back clean, but it
is a sentence I had to think of myself. It belongs in `skills/implement-bead`'s *Getting the review*
or in `agents/reviewer.md`, beside the rest of the reviewer's checklist.

Note what does **not** cover this case. `882f385` ("one Godot `user://` directory per checkout, so
parallel gate-fast runs stop colliding", tr-0cr, PR #91) landed on `main` during this pass and is
the standing fix the three earlier retrospectives asked for: `scripts/gate-fast` now writes a
temporary `override.cfg` naming a user data directory **derived from the checkout's absolute path**.
That ends the collision between *different* worktrees, which is what every earlier sighting was. It
does not end this one: the implementer and the review sub-agent it spawns share a single checkout,
so they still resolve to one `user://` and still delete each other's `user://test_saves`. Per
checkout is not per run. Whether to narrow it further — a directory per gate invocation, or a lock
that makes a second concurrent gate wait — is the navigator's call, and worth a bead now that the
first fix has shown where its edge is.

This branch was based on a `main` older than `882f385`, so none of the runs described above had even
the per-checkout isolation; the branch is rebased onto it before merge.

## Seen before

Yes, three times, and this is the fourth: `docs/retrospectives/tr-eg9.6.4.3.md`,
`docs/retrospectives/tr-eg9.6.4.5.1.md`, `docs/retrospectives/tr-eg9.6.6.md` and
`docs/retrospectives/tr-hy6.2.md` all record the same shared-`user://` collision, and
`docs/retrospectives/tr-0cr.md` records the fix for it. This sighting is worth its own file for two
reasons the others do not carry: it cost a **review round** rather than only gate time, and it is
the first that the landed per-checkout fix would not have prevented.
